# Imagen de herramientas DevOps

Imagen Docker con un conjunto curado de herramientas IaC/DevOps (Terraform, Packer, Ansible,
AWS CLI, Google Cloud SDK, Pulumi y más), construida con **Packer + Ansible** sobre `ubuntu:22.04`.

> Versión en inglés: [Readme.md](Readme.md)

---

## Cómo funciona

Packer arranca un contenedor `ubuntu:22.04` limpio, lo provisiona con Ansible y hace commit del
resultado como `devops:latest` (más una etiqueta con marca temporal `devops:YYYYMMDD-hhmmss`). No
existe Dockerfile; la definición completa de la imagen vive en `packer/devops.pkr.hcl` y en los
roles de Ansible bajo `ansible/roles/`.

En tiempo de ejecución, el entrypoint del contenedor (`/opt/docker-entrypoint.sh`) remapea el
usuario interno `devops` (UID/GID `1000`) al `PUID`/`PGID` que el host pasa como variable de
entorno, y luego cede la ejecución a `gosu devops bash -l`. Esto permite que la misma imagen
funcione para cualquier usuario del host sin necesidad de reconstruirla.

---

## Requisitos

Las siguientes herramientas deben estar disponibles en tu estación de trabajo antes de construir
la imagen.

| Herramienta | Notas |
|---|---|
| **Python 3.10** | Fijado en `.python-version`; gestionado por `uv` |
| **uv** | Gestiona el virtualenv de Python y ejecuta Ansible + Packer |
| **Task** | Ejecutor de tareas; ver [taskfile.dev](https://taskfile.dev/installation/) |
| **Docker** | El motor debe estar en ejecución |

> **Packer no se instala de forma global.** Se invoca mediante `uv run packer`, de modo que
> corre dentro del virtualenv del proyecto donde también está disponible `ansible-playbook`. No
> añadas una instalación de Packer a nivel de sistema.

---

## Instalación

### Python 3.10

Instala Python 3.10 para tu plataforma y asegúrate de que sea la versión activa, o deja que `uv`
lo gestione automáticamente al ejecutar `uv venv`.

### uv

**macOS — MacPorts**
```shell
sudo port selfupdate && sudo port install uv
```

**macOS — Homebrew**
```shell
brew install uv
```

**Cualquier plataforma (script de instalación)**
```shell
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Task

Sigue las instrucciones de instalación para tu plataforma en la
[página de instalación de Taskfile](https://taskfile.dev/installation/).

### Docker

Instala Docker Desktop (macOS/Windows) o Docker Engine (Linux) desde
[docs.docker.com/get-docker](https://docs.docker.com/get-docker/).

---

## Construcción de la imagen

```shell
# 1. Clona el repositorio
git clone <url-del-repo>
cd devops

# 2. Crea el virtualenv e instala las dependencias (Ansible 7, ruff, certifi)
uv venv && uv sync

# 3. Construye la imagen
task build
```

`task build` llama primero a `task init` (descarga los plugins de Packer) y luego ejecuta
`uv run packer build packer/devops.pkr.hcl`.

---

## Desarrollo y mantenimiento

Usa `task build:debug` al iterar sobre roles de Ansible. En modo debug, si Ansible falla, Packer
hace una pausa y muestra el prompt `[a]bort / [r]etry`. Corrige el rol que falla y pulsa `r` para
reintentar sin tener que reiniciar toda la construcción desde cero.

```shell
task build:debug
```

### Estructura del proyecto

```
.
├── Taskfile.yaml                        # Ejecutor de tareas raíz (build, build:debug, init)
├── pyproject.toml                       # Deps Python: ansible~=7.6, ruff, certifi
├── packer/
│   └── devops.pkr.hcl                   # Definición de la construcción Packer
├── ansible/
│   ├── playbooks/
│   │   ├── devops.yml                   # Playbook principal (orden de roles)
│   │   └── filter_plugins/
│   │       └── sort_versions.py         # Filtro personalizado: sort_versions (packaging.version)
│   └── roles/
│       ├── ansible/                     # Instala Ansible 7 + colección AWS
│       ├── awscli2/                     # AWS CLI v2
│       ├── clean-up/                    # Elimina artefactos de construcción
│       ├── google-cloud-sdk/            # gcloud CLI
│       ├── hashicorp-tool/              # Rol compartido: Terraform + Packer (dentro de la imagen)
│       ├── image-config/                # Entrypoint, locale, zona horaria
│       ├── pulumi/                      # Pulumi CLI + completado bash
│       ├── python-modules/              # Paquetes pip adicionales via uv
│       ├── starship/                    # Prompt Starship
│       ├── user-config/                 # Usuario devops, sudoers, .bashrc, .bash_profile
│       └── uv/                          # uv dentro de la imagen
└── docker-compose/                      # Configuración de ejecución (ver docker-compose/Léeme.md)
```

> **Nota sobre la ruta de roles:** `ansible/playbooks/roles/` es un enlace simbólico a
> `ansible/roles/`. Edita siempre los archivos bajo `ansible/roles/`.

---

## Notas de ejecución

- El usuario de la imagen es `devops` (UID/GID `1000` en tiempo de construcción).
- Pasa `PUID` y `PGID` en tiempo de ejecución (lo hace automáticamente `docker-compose/compose.yml`
  a partir del `$UID`/`$GID` del host). Por defecto es `1000` si no se especifican.
- Para abrir un shell: `docker compose exec -u devops devops bash -l`
- Locale: `es_ES.UTF-8`. Prompt: Starship con `APP_ENV` visible.
- Las claves SSH que coincidan con `~/.ssh/*ami*` se añaden automáticamente a `ssh-agent` al
  iniciar sesión a través de `.bashrc`.

---

## Linting

```shell
uv run ruff check .
uv run ruff format .
```

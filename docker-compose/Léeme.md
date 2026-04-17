# Uso de la imagen con Docker Compose

> Versión en inglés: [Readme.md](Readme.md)

Una vez construida la imagen, puede ejecutarse mediante Docker Compose utilizando los archivos de
configuración de este directorio. Cada archivo controla un aspecto distinto del comportamiento del
contenedor.

---

## Configuración inicial

### 1. Establecer el nombre del proyecto

Edita `Taskfile.yml` y asigna a la variable `PROJECT` un identificador corto para tu proyecto.
Este nombre se usa como nombre del proyecto Docker Compose (visible en la salida de `docker ps` y
en el prompt dentro del contenedor).

```yaml
vars:
  PROJECT: miproyecto
```

### 2. Configurar las variables de entorno

Rellena `my_env_vars.env` con los valores de tu entorno:

```shell
# Contexto de plataforma
APP_ENV=<nombre-del-proyecto>

# Credenciales AWS
AWS_ACCESS_KEY_ID=<access-key-id>
AWS_SECRET_ACCESS_KEY=<secret-access-key>
AWS_DEFAULT_REGION=<region>          # p. ej. eu-west-1

# Zona horaria (formato base de datos IANA tz)
TZ=<zona-horaria>                    # p. ej. Europe/Madrid
```

> `my_env_vars.env` no se commitea al repositorio. Mantenlo fuera del control de versiones.

### 3. Crear el enlace simbólico `src`

El directorio `src` debe existir como un enlace simbólico que apunte al repositorio de tu proyecto
IaC:

```shell
ln -s /ruta/a/tu/proyecto-iac docker-compose/src
```

Este directorio se monta como `/home/devops/src` dentro del contenedor.

### 4. Crear `config.cnf`

`config.cnf` se monta como el archivo de configuración del cliente SSH (`~/.ssh/config`) dentro
del contenedor. Créalo (puede estar vacío) o rellénalo con tus alias de host SSH:

```shell
touch docker-compose/config.cnf
```

---

## Volúmenes montados

| Ruta en el host | Ruta en el contenedor | Notas |
|---|---|---|
| `config.cnf` | `/home/devops/.ssh/config` | Configuración del cliente SSH |
| `~/.ssh/hiberus/hda/` | `/home/devops/.ssh/hiberus/hda` | Claves SSH (solo lectura) |
| `~/.ssh/apps` | `/home/devops/.ssh/apps` | Claves SSH (solo lectura) |
| `src` | `/home/devops/src` | Enlace simbólico al repositorio IaC |
| `tmp` | `/home/devops/tmp` | Espacio temporal de trabajo |

---

## Tareas disponibles

Ejecuta estos comandos desde el directorio `docker-compose/` (o pasa `-d docker-compose/` a Task).

| Comando | Descripción |
|---|---|
| `task up` | Inicia el contenedor en segundo plano |
| `task sh` | Abre un shell en el contenedor en ejecución |
| `task up sh` | Flujo habitual: inicia el contenedor y abre un shell |
| `task down` | Detiene y elimina el contenedor |
| `task prune` | Detiene, elimina el contenedor y borra los volúmenes asociados |
| `task restart` | Reinicia todos los contenedores del proyecto |
| `task restart:cont` | Reinicia un contenedor concreto (por defecto: `devops`; sobreescribe con `CONTAINER=<nombre>`) |

Para abrir un shell manualmente sin Task:

```shell
docker compose -p <PROJECT> exec -u devops devops bash -l
```

---

## Remapeo de usuario (PUID / PGID)

`compose.yml` pasa el `$UID` y `$GID` del usuario del host al contenedor como `PUID` y `PGID`.
El entrypoint remapea el usuario interno `devops` a estos valores para que los archivos creados
dentro del contenedor sean propiedad de tu usuario del host. No es necesario reconstruir la imagen
al cambiar de usuario.

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

# Zona horaria (formato base de datos IANA tz)
TZ=<zona-horaria>                    # p. ej. Europe/Madrid
```

> `my_env_vars.env` no se commitea al repositorio. Mantenlo fuera del control de versiones.
>
> Las credenciales AWS **no** se definen aqui. Utiliza los mecanismos estandar de AWS
> (`~/.aws/credentials`, `AWS_PROFILE`, roles IAM, etc.) y montalos en el contenedor
> si es necesario.

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

## Modos de uso

La imagen puede utilizarse de dos formas en funcion del flujo de trabajo:

### A) Un contenedor por proyecto (recomendado)

Cada proyecto IaC tiene su propia copia del directorio `docker-compose/` (o un enlace simbolico)
con su propio `Taskfile.yml`, `my_env_vars.env` y enlace simbolico `src`. Esto proporciona
aislamiento total: variables de entorno, configuracion SSH y espacio temporal independientes por
proyecto.

```
~/proyectos/
  proyecto-alfa/          # repo IaC
  proyecto-beta/          # repo IaC
  devops/                 # este repo (imagen construida)
    docker-compose/       # plantilla

~/compose/
  alfa/                   # copia de docker-compose/
    Taskfile.yml          # PROJECT: alfa
    my_env_vars.env       # APP_ENV=alfa
    src -> ~/proyectos/proyecto-alfa
    config.cnf
  beta/                   # copia de docker-compose/
    Taskfile.yml          # PROJECT: beta
    my_env_vars.env       # APP_ENV=beta
    src -> ~/proyectos/proyecto-beta
    config.cnf
```

Cada contenedor se ejecuta de forma independiente:

```shell
cd ~/compose/alfa && task up sh   # entrar en el contenedor alfa
cd ~/compose/beta && task up sh   # entrar en el contenedor beta
```

### B) Un unico contenedor para todos los proyectos

Una sola instancia de `docker-compose/` sirve a todos los proyectos. El enlace simbolico `src`
apunta al directorio padre que contiene todos los repos IaC, o se montan repos individuales como
volumenes adicionales en `compose.yml`.

```
~/proyectos/
  proyecto-alfa/
  proyecto-beta/

docker-compose/
  Taskfile.yml            # PROJECT: devops
  my_env_vars.env         # APP_ENV=compartido
  src -> ~/proyectos      # montar el directorio padre
  config.cnf
```

Dentro del contenedor, todos los proyectos estan disponibles bajo `/home/devops/src/`:

```shell
cd ~/src/proyecto-alfa
cd ~/src/proyecto-beta
```

Alternativamente, se pueden anadir montajes adicionales en `compose.yml`:

```yaml
volumes:
  - ~/proyectos/proyecto-alfa:/home/devops/alfa
  - ~/proyectos/proyecto-beta:/home/devops/beta
```

> Elige **un contenedor por proyecto** cuando los proyectos necesiten distintas variables de
> entorno, claves SSH o perfiles AWS. Elige **un unico contenedor** cuando los proyectos
> compartan la misma configuracion y prefieras cambiar entre ellos sin salir del shell.

---

## Volumenes montados

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

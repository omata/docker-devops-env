# Uso de la imagen con docker compose

Luego de generar la imagen se puede usar del entorno a través de docker compose, mediante la configuración en varios ficheros que luego permitirán levantarlo con parámetros específicos para cada proyecto.

# Configuraciones

## Taskfile

En el archivo `docker-compose/Taskfile.yml` se debe establecer la variable `PROJECT` con el nombre del proyecto. Debe ser corto ya que se usará en el prompt dentro del contenedor.

## Variables de entorno

En el archivo `docker-compose/my_env_vars.env` se deben establecer las variables de entorno necesarias para poder acceder a la nubes de AWS.

```shell
## Environment variables file for Docker Ansible proyects.
# Defines environment variables for platform context.
APP_ENV=<nombre del proyecto>
AWS_ACCESS_KEY_ID=<llave de acceso>
AWS_SECRET_ACCESS_KEY=<llave de acceso secreta>
AWS_DEFAULT_REGION=<region de aws>
TZ=<zona horaria en formato base de datos tz>
```

> NOTA: Estas variables de entorno son necesarias para algunas herramientas como ansible que obtiene estos valores usando este mecanismo.

## Docker

En el archivo `docker-compose/compose.yml` se deben establecer los volúmenes necesarios para poder acceder a los proyectos del IaC. En donde el directorio `src` corresponde a un enlace simbólico que apunta al repositorio del proyecto.

## Arrancar el contenedor

Para iniciar el contenedor bastará con ejecutar `task up sh` lo que arrancará el contenedor y nos mostrará el prompt de éste.

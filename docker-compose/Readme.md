Here is the English translation of the Markdown file:

# Using the image with docker compose

After generating the image it can be used from the environment through docker compose, by means of the configuration in several files that will then allow it to be started up with specific parameters for each project.

# Configurations

## Taskfile

In the `docker-compose/Taskfile.yml` file, the `PROJECT` variable must be set with the name of the project. It should be short since it will be used in the prompt inside the container.

## Environment variables

In the `docker-compose/my_env_vars.env` file, the necessary environment variables must be set in order to be able to access the AWS clouds.

```shell
## Environment variables file for Docker Ansible projects.
# Defines environment variables for platform context.
APP_ENV=<project name>
AWS_ACCESS_KEY_ID=<access key>
AWS_SECRET_ACCESS_KEY=<secret access key>
AWS_DEFAULT_REGION=<aws region>
TZ=<timezone in database tz format>
```

> NOTE: These environment variables are necessary for some tools like ansible that obtains these values using this mechanism.

## Docker

In the `docker-compose/compose.yml` file, the necessary volumes must be set in order to be able to access the IaC projects. Where the `src` directory corresponds to a symbolic link that points to the project repository.

## Starting the container

To start the container just run `task up sh` which will start the container and show its prompt.

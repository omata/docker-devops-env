# Using the image with Docker Compose

> Spanish version: [Léeme.md](Léeme.md)

Once the image is built, it can be run via Docker Compose using the configuration files in this
directory. Each file controls a different aspect of the container's behaviour.

---

## Setup

### 1. Set the project name

Edit `Taskfile.yml` and set the `PROJECT` variable to a short identifier for your project. This
name is used as the Docker Compose project name (visible in `docker ps` output and in the shell
prompt inside the container).

```yaml
vars:
  PROJECT: myproject
```

### 2. Configure environment variables

Copy or fill in `my_env_vars.env` with the values for your environment:

```shell
# Platform context
APP_ENV=<project-name>

# AWS credentials
AWS_ACCESS_KEY_ID=<access-key-id>
AWS_SECRET_ACCESS_KEY=<secret-access-key>
AWS_DEFAULT_REGION=<region>          # e.g. eu-west-1

# Timezone (IANA tz database format)
TZ=<timezone>                        # e.g. Europe/Madrid
```

> `my_env_vars.env` is not committed to the repository. Keep it out of version control.

### 3. Create the `src` symlink

The `src` directory must exist as a symlink pointing to your IaC project repository:

```shell
ln -s /path/to/your/iac-project docker-compose/src
```

This directory is mounted as `/home/devops/src` inside the container.

### 4. Create `config.cnf`

`config.cnf` is mounted as the SSH client configuration file (`~/.ssh/config`) inside the
container. Create it (it can be empty) or populate it with your SSH host aliases:

```shell
touch docker-compose/config.cnf
```

---

## Volume layout

| Host path | Container path | Notes |
|---|---|---|
| `config.cnf` | `/home/devops/.ssh/config` | SSH client config |
| `~/.ssh/hiberus/hda/` | `/home/devops/.ssh/hiberus/hda` | Read-only SSH keys |
| `~/.ssh/apps` | `/home/devops/.ssh/apps` | Read-only SSH keys |
| `src` | `/home/devops/src` | Symlink to the IaC project repo |
| `tmp` | `/home/devops/tmp` | Scratch space |

---

## Available tasks

Run these commands from the `docker-compose/` directory (or pass `-d docker-compose/` to Task).

| Command | Description |
|---|---|
| `task up` | Start the container in the background |
| `task sh` | Open a shell in the running container |
| `task up sh` | Typical workflow: start the container and open a shell |
| `task down` | Stop and remove the container |
| `task prune` | Stop, remove the container, and delete associated volumes |
| `task restart` | Restart all containers in the project |
| `task restart:cont` | Restart a specific container (default: `devops`; override with `CONTAINER=<name>`) |

To open a shell manually without Task:

```shell
docker compose -p <PROJECT> exec -u devops devops bash -l
```

---

## User remapping (PUID / PGID)

`compose.yml` passes the host user's `$UID` and `$GID` to the container as `PUID` and `PGID`.
The entrypoint remaps the internal `devops` user to these values so that files created inside
the container are owned by your host user. No image rebuild is needed when switching users.

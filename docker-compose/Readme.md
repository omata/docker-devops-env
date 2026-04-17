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

# Timezone (IANA tz database format)
TZ=Europe/Madrid                     # default; change as needed
```

> `my_env_vars.env` is versioned in the repository as a template with example values.
> If you add real secrets or personal data, keep that copy out of version control (e.g. by gitignoring a local override).
>
> AWS credentials are **not** defined here. Use the standard AWS mechanisms instead
> (`~/.aws/credentials`, `AWS_PROFILE`, IAM roles, etc.) and mount them into the container if needed.

### 3. Create the `src` symlink

The `src` directory must exist as a symlink pointing to your IaC project repository:

```shell
ln -s /path/to/your/iac-project docker-compose/src
```

This directory is mounted as `/home/devops/src` inside the container.

### 4. Create `config.cnf`

`config.cnf` is mounted as the SSH client configuration file (`~/.ssh/config`) inside the container. Create it (it can be empty) or populate it with your SSH host aliases:

```shell
touch docker-compose/config.cnf
```

---

## Usage patterns

The image can be used in two ways depending on your workflow:

### A) One container per project (recommended)

Each IaC project gets its own copy of the `docker-compose/` directory (or a symlink to it) with its own `Taskfile.yml`, `my_env_vars.env`, and `src` symlink. This provides full isolation: separate environment variables, SSH configuration, and scratch space per project.

```
~/projects/
  project-alpha/          # IaC repo
  project-beta/           # IaC repo
  devops/                 # this repo (built image)
    docker-compose/       # template

~/compose/
  alpha/                  # copy of docker-compose/
    Taskfile.yml          # PROJECT: alpha
    my_env_vars.env       # APP_ENV=alpha
    src -> ~/projects/project-alpha
    config.cnf
  beta/                   # copy of docker-compose/
    Taskfile.yml          # PROJECT: beta
    my_env_vars.env       # APP_ENV=beta
    src -> ~/projects/project-beta
    config.cnf
```

Each container runs independently:

```shell
cd ~/compose/alpha && task up sh   # enter alpha container
cd ~/compose/beta  && task up sh   # enter beta container
```

### B) Single container for all projects

A single `docker-compose/` instance serves all projects. The `src` symlink is pointed at a parent directory containing all IaC repos, or individual repos are mounted as additional volumes in `compose.yml`.

```
~/projects/
  project-alpha/
  project-beta/

docker-compose/
  Taskfile.yml            # PROJECT: devops
  my_env_vars.env         # APP_ENV=shared
  src -> ~/projects       # mount the parent directory
  config.cnf
```

Inside the container, all projects are available under `/home/devops/src/`:

```shell
cd ~/src/project-alpha
cd ~/src/project-beta
```

Alternatively, add extra bind mounts to `compose.yml`:

```yaml
volumes:
  - ~/projects/project-alpha:/home/devops/alpha
  - ~/projects/project-beta:/home/devops/beta
```

> Choose **one container per project** when projects require different environment variables, > SSH keys, or AWS profiles. Choose **a single container** when projects share the same configuration and you prefer to switch between them without leaving the shell.

---

## Volume layout

| Host path | Container path | Notes |
|---|---|---|
| `~/.aws` | `/home/devops/.aws` | AWS credentials and configuration |
| `config.cnf` | `/home/devops/.ssh/config` | SSH client config |
| `~/.ssh/<path-to-your-keys>` | `/home/devops/.ssh/<path-to-your-keys>` | Read-only SSH keys; adjust to your environment |
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

`compose.yml` passes the host user's `$UID` and `$GID` to the container as `PUID` and `PGID`. The entrypoint remaps the internal `devops` user to these values so that files created inside the container are owned by your host user. No image rebuild is needed when switching users.

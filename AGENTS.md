# AGENTS.md

## What this repo is

Builds a Docker image (`devops:latest`) containing IaC/DevOps tooling (Terraform, Packer, Ansible, AWS CLI, gcloud, Pulumi, etc.) via **Packer + Ansible** on top of `ubuntu:22.04`. This is **not** a Dockerfile-based build.

---

## Developer commands

### Setup (first time or after changing deps)
```shell
uv venv && uv sync
```
Python version is pinned to **3.10** via `.python-version`. Use `uv`, not pip or pipenv.

### Build the image
```shell
task build        # production build
task build:debug  # Ansible failure pauses Packer and prompts [a]bort/[r]etry
task init         # only downloads Packer plugins (called automatically by build)
```

### Use the image (from `docker-compose/`)
```shell
task up           # start container
task sh           # open shell in container
task up sh        # typical workflow: start + enter
task down         # stop and remove
task prune        # down + remove volumes
task restart      # restart all containers
task restart:cont # restart specific container (var CONTAINER, default: devops)
```

---

## Critical quirks

### Packer must run via `uv run`
`ansible-playbook` lives in the uv virtualenv, not globally. Packer's Ansible plugin needs it on PATH. The `task build` command does this automatically via `Taskfile.yaml`. If invoking Packer manually, always prefix with `uv run`.

### Not a Dockerfile
Packer starts a `ubuntu:22.04` container, provisions it with Ansible, then commits it as `devops:latest` + `devops:YYYYMMDD-hhmmss`. Do not add a `Dockerfile` unless the build strategy changes.

### Build is user-agnostic; runtime remapping via PUID/PGID
The image is built with a fixed generic user `devops` (UID/GID `1000`). No host user data is baked into the image. At container startup, `docker-entrypoint.sh` reads `PUID` and `PGID` env vars (set automatically by `compose.yml` from the host's `$UID`/`$GID`) and remaps the `devops` user via `usermod`/`groupmod` before handing off to `gosu devops bash -l`. This means the same image works for any host user without rebuilding.

- `PUID`/`PGID` default to `1000` if not set.
- The entrypoint runs as root; `gosu` drops privileges after remapping.
- Volume paths inside the container are always under `/home/devops/`.

### Tool versions are resolved at build time
Most tools (Terraform, Packer, Pulumi, Taskfile, s5cmd, uv, joe, Starship) are installed at `latest` by querying GitHub API or the HashiCorp index during the Ansible run. `terraform_version` and `packer_version` role defaults can be overridden if a pinned version is needed.

### Duplicate roles path
Ansible roles exist at both `ansible/roles/` and `ansible/playbooks/roles/`. The latter appears to be a symlink. Make edits only in `ansible/roles/`.

### Custom Ansible filter plugins
`sort_versions` filter (using `packaging.version.Version`) lives in:
- `ansible/playbooks/filter_plugins/sort_versions.py`

It is loaded globally for all roles in the play. Do **not** add `filter_plugins/` directories inside individual roles.

### Architecture support
All roles contain `x86_64`/`amd64` and `aarch64`/`arm64` mappings. When adding a new tool, follow the same pattern.

---

## Container entrypoint and user

- Image user: `devops` (UID/GID `1000`, fixed at build time).
- Entrypoint: `/opt/docker-entrypoint.sh` — remaps UID/GID from `PUID`/`PGID`, fixes home ownership, starts `ssh-agent`, then `exec gosu devops bash -l`.
- SSH keys matching `~/.ssh/*ami*` are auto-added to the agent via `.bashrc`.
- Locale: `es_ES.UTF-8`. Prompt: Starship with `APP_ENV` visible.

---

## Required setup before using `docker-compose/`

1. Edit `PROJECT` var in `docker-compose/Taskfile.yml`.
2. Fill in `docker-compose/my_env_vars.env` (AWS keys, `APP_ENV`, `TZ`).
3. Create `docker-compose/src` as a symlink to the IaC project repo.

Volumes mounted into the container (see `docker-compose/compose.yml`):
- `config.cnf` → `/home/devops/.ssh/config`
- `~/.ssh/hiberus/hda/` → `/home/devops/.ssh/hiberus/hda`
- `~/.ssh/apps` → `/home/devops/.ssh/apps`
- `./src` → `/home/devops/src`
- `./tmp` → `/home/devops/tmp`

---

## Linting

`ruff` is the only code quality tool (dev dependency). No config section in `pyproject.toml`; uses defaults.
```shell
uv run ruff check .
uv run ruff format .
```
No CI, no pre-commit hooks configured.

---

## Key files

| Path | Purpose |
|---|---|
| `Taskfile.yaml` | Root task runner (build, build:debug, init) |
| `packer/devops.pkr.hcl` | Packer build definition |
| `ansible/playbooks/devops.yml` | Main Ansible playbook |
| `ansible/roles/` | All provisioning roles |
| `ansible/roles/hashicorp-tool/` | Shared role for Terraform and Packer (and any future HashiCorp tool) |
| `ansible/roles/image-config/files/docker-entrypoint.sh` | Entrypoint: UID/GID remapping + ssh-agent |
| `ansible/roles/user-config/` | Creates `devops` user, locale, sudoers |
| `docker-compose/compose.yml` | Service definition; sets PUID/PGID from host |
| `docker-compose/Taskfile.yml` | Tasks for managing the running container |
| `pyproject.toml` | Python deps (ansible, ruff) managed by uv |
| `.python-version` | Pins Python to 3.10 |
| `.env` | Sets `WORKON_HOME` and `SYSTEM_VERSION_COMPAT=0` for uv |

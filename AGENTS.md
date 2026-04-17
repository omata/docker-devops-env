# AGENTS.md

## Ground rules for agents

- **Never create commits unless the user explicitly asks for it.**
- Commit messages must be written in English, one commit per fix or feature.
- The user communicates in Spanish; always respond in Spanish.

### Git Flow

This repository uses **git flow** for branch management. All branching, merging, and release operations must be performed through `git flow` commands — never manually merge or create release/hotfix branches by hand.

- **Main branches**: `main` (production) and `develop` (integration).
- **Feature branches**: created from `develop` with `git flow feature start <name>`, finished with `git flow feature finish <name>`.
- **Release branches**: created from `develop` with `git flow release start <version>`, finished with `git flow release finish <version>` (merges into both `main` and `develop`, creates a tag).
- **Hotfix branches**: created from `main` with `git flow hotfix start <version>`, finished with `git flow hotfix finish <version>`.
- **Never push directly to `main` or `develop`**; always go through the appropriate git flow workflow.
- When finishing a release or hotfix, git flow will open an editor for the merge commit and the tag message. Accept the defaults unless the user says otherwise.

---

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

### Ansible version pinned to 7
`pyproject.toml` pins `ansible~=7.6`. Later versions produce warnings with the Python libraries
available on Ubuntu 22.04. Do not upgrade beyond the `7.x` series without verifying compatibility.

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
4. Create `docker-compose/config.cnf` (SSH client config; may be empty).

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

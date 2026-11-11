# AGENTS.md

## Ground rules for agents

- **Never create commits unless the user explicitly asks for it.**
- Commit messages must be written in English, one commit per fix or feature.
- The user communicates in Spanish; always respond in Spanish.

### Git Flow

This repository uses the **git flow** branching model (branch names and prefixes: `feature/`, `bugfix/`, `release/`, `hotfix/`) combined with **git worktrees managed by [worktrunk](https://github.com/max-sixty/worktrunk) (`wt`)**. Never create or merge branches by hand with plain `git branch`/`git checkout -b`/`git merge`/`git worktree add`.

- **Main branches**: `main` (production) and `develop` (integration). They live in the main checkout (the repository root); do not do day-to-day work there.
- **Worktree location**: `wt` is configured (user config, `~/.config/worktrunk/config.toml`) with `worktree-path = ".worktrees/{{ branch | sanitize }}"`, so every worktree is created under `.worktrees/` inside the project (e.g. `feature/foo` → `.worktrees/feature-foo`). Project hooks live in `.config/wt.toml`.
- **Branch creation**: every branch is created with `wt`, which creates the branch and its worktree together. Never use `git flow <type> start`, `git checkout -b` or `git worktree add`.
  - Feature / bugfix (based on `develop`): `wt switch --create feature/<name> --base develop` (or `bugfix/<name>`).
  - Release (based on `develop`): `wt switch --create release/<version> --base develop`.
  - Hotfix (based on `main`): `wt switch --create hotfix/<version> --base main`.
- **Merging**: branches are merged through **Pull Requests on GitHub**, never locally (no `wt merge`, no `git flow <type> finish`, no manual `git merge`). Push the branch and open the PR against `develop` (feature, bugfix, release) or `main` (release, hotfix).
- **After the PR is merged**: remove the worktree with `wt remove` (the branch is deleted only if already merged).
- **Other worktree commands**: `wt list` (status of all worktrees), `wt switch <branch>` (move to an existing one).
- **Each worktree has its own `.venv`**: run `uv sync` in a new worktree before using Packer/Ansible/ruff (the `deps` hook in `.config/wt.toml` is currently commented out).
- **Never run `git worktree prune` inside the container**: the `pre-start` hook rewrites each worktree's `.git` file to a relative path, but the registration in `.git/worktrees/` stays absolute.
- **Never push directly to `main` or `develop`**; they only change through merged Pull Requests.

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
Packer starts a `ubuntu:22.04` container, provisions it with Ansible, then commits it as `devops:latest`. When the current commit carries a git tag, the image is also tagged with that version (e.g. `devops:2.0.0`). Do not add a `Dockerfile` unless the build strategy changes.

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

- Image user: `root` (required by the entrypoint for UID/GID remapping; drops to `devops` via `gosu`). The `devops` user is created at build time with UID/GID `1000`.
- Entrypoint: `/opt/docker-entrypoint.sh` — remaps UID/GID from `PUID`/`PGID`, fixes home ownership, starts `ssh-agent`, then `exec gosu devops /bin/bash -l`.
- SSH keys matching `~/.ssh/*ami*` are auto-added to the agent via `.bashrc`.
- Locale: `es_ES.UTF-8`. Prompt: Starship with `APP_ENV` visible.

---

## Required setup before using `docker-compose/`

1. Edit `PROJECT` var in `docker-compose/Taskfile.yml`.
2. Fill in `docker-compose/my_env_vars.env` (`APP_ENV`, `TZ`).
3. Create `docker-compose/src` as a symlink to the IaC project repo.
4. Create `docker-compose/config.cnf` (SSH client config; may be empty).

Volumes mounted into the container (see `docker-compose/compose.yml`):
- `~/.aws` → `/home/devops/.aws`
- `config.cnf` → `/home/devops/.ssh/config`
- `~/.ssh/<path-to-your-keys>` → `/home/devops/.ssh/<path-to-your-keys>` (read-only)
- `~/.ssh/apps` → `/home/devops/.ssh/apps` (read-only)
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
| `pyproject.toml` | Python deps (ansible, certifi, ruff) managed by uv |
| `.python-version` | Pins Python to 3.10 |
| `.env` | Sets `WORKON_HOME` and `SYSTEM_VERSION_COMPAT=0` for uv |

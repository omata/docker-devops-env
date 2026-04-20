# DevOps tooling image

Docker image providing a curated set of IaC/DevOps tools (Terraform, Packer, Ansible, AWS CLI,
Google Cloud SDK, Pulumi, and more), built with **Packer + Ansible** on top of `ubuntu:22.04`.

> Spanish version: [Léeme.md](Léeme.md)

---

## How it works

Packer starts a fresh `ubuntu:22.04` container, provisions it with Ansible, and commits the
result as `devops:latest`. When the current commit carries a git tag (e.g. `2.0.0`), the image
is also tagged as `devops:2.0.0`. There is no Dockerfile; the entire image definition lives in
`packer/devops.pkr.hcl` and the Ansible roles under `ansible/roles/`.

At runtime the container entrypoint (`/opt/docker-entrypoint.sh`) remaps the internal `devops`
user (UID/GID `1000`) to whatever `PUID`/`PGID` the host passes in, then hands off execution
to `gosu devops bash -l`. This means the same image works for any host user without rebuilding.

---

## Requirements

The following tools must be available on your workstation before building the image.

| Tool | Notes |
|---|---|
| **Python 3.10** | Pinned via `.python-version`; managed by `uv` |
| **uv** | Manages the Python virtualenv and runs Ansible + Packer |
| **Packer** | Builds the Docker image; must be invoked via `uv run packer` (see note below) |
| **Task** | Task runner; see [taskfile.dev](https://taskfile.dev/installation/) |
| **Docker** | Engine must be running |

> **Packer must be invoked via `uv run`.** Packer must be installed on the system, but it
> needs access to the `ansible-playbook` binary managed by the project's `uv` virtualenv. Running
> `uv run packer` ensures the virtualenv is activated and Packer can find `ansible-playbook` on
> its PATH.

---

## Installation

### Python 3.10

Install Python 3.10 for your platform and ensure it is the active version, or let `uv` handle it
automatically when you run `uv venv`.

### uv

**macOS — MacPorts**
```shell
sudo port selfupdate && sudo port install uv
```

**macOS — Homebrew**
```shell
brew install uv
```

**Any platform (installer script)**
```shell
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Task

Follow the installation instructions for your platform on the
[Taskfile installation page](https://taskfile.dev/installation/).

### Packer

Install Packer for your platform from the
[HashiCorp Packer installation page](https://developer.hashicorp.com/packer/install).

### Docker

Install Docker Desktop (macOS/Windows) or Docker Engine (Linux) from
[docs.docker.com/get-docker](https://docs.docker.com/get-docker/).

---

## Building the image

```shell
# 1. Clone the repository
git clone <repo-url>
cd devops

# 2. Create the virtualenv and install dependencies (Ansible 7, ruff, certifi)
uv venv && uv sync

# 3. Build the image
task build
```

`task build` calls `task init` first (downloads Packer plugins) and then runs
`uv run packer build packer/devops.pkr.hcl`.

---

## Development and maintenance

Use `task build:debug` when iterating on Ansible roles. In debug mode, if Ansible fails Packer
pauses and prompts `[c] Clean up and exit, [a] abort without cleanup, or [r] retry step`.
Fix the failing role and press `r` to retry without restarting the whole build from scratch.

```shell
task build:debug
```

### Project layout

```
.
├── Taskfile.yaml                        # Root task runner (build, build:debug, init)
├── pyproject.toml                       # Python deps: ansible~=7.6, ruff, certifi
├── packer/
│   └── devops.pkr.hcl                   # Packer build definition
├── ansible/
│   ├── playbooks/
│   │   ├── devops.yml                   # Main playbook (role order)
│   │   └── filter_plugins/
│   │       └── sort_versions.py         # Custom filter: sort_versions (packaging.version)
│   └── roles/
│       ├── ansible/                     # Installs Ansible 7 + AWS collection
│       ├── awscli2/                     # AWS CLI v2
│       ├── clean-up/                    # Removes build artefacts
│       ├── google-cloud-sdk/            # gcloud CLI
│       ├── hashicorp-tool/              # Shared role: Terraform + Packer (inside image)
│       ├── image-config/                # Entrypoint, locale, timezone
│       ├── joe/                         # joe text editor
│       ├── packer/                      # Packer CLI (inside image)
│       ├── pulumi/                      # Pulumi CLI + bash completion
│       ├── python-modules/              # Extra Python packages via apt + pip --user
│       ├── required-packages/           # Base system packages (apt)
│       ├── s5cmd/                       # s5cmd S3 CLI
│       ├── starship/                    # Starship prompt
│       ├── taskfile/                    # Task runner (inside image)
│       ├── terraform/                   # Terraform CLI
│       ├── user-config/                 # devops user, sudoers, .bashrc, .bash_profile
│       └── uv/                          # uv inside the image
└── docker-compose/                      # Runtime configuration (see docker-compose/Readme.md)
```

> **Note on roles path:** `ansible/playbooks/roles/` is a symlink to `ansible/roles/`. Always
> edit files under `ansible/roles/`.

---

## Runtime notes

- The image runs as `root` so the entrypoint can remap UID/GID. The `devops` user (UID/GID
  `1000` at build time) is the effective user after the entrypoint drops privileges via `gosu`.
- Pass `PUID` and `PGID` at runtime (done automatically by `docker-compose/compose.yml` from the
  host's `$UID`/`$GID`). Defaults to `1000` if not set.
- To open a shell: `docker compose exec -u devops devops bash -l`
- Locale: `es_ES.UTF-8`. Prompt: Starship with `APP_ENV` visible.
- SSH keys matching `~/.ssh/*ami*` are auto-added to `ssh-agent` on login via `.bashrc`.
  The entrypoint starts `ssh-agent` as `devops` with a fixed socket at `/tmp/ssh-agent.sock`
  before handing off to the login shell; `.bashrc` sets `SSH_AUTH_SOCK` as a fallback.

---

## Linting

```shell
uv run ruff check .
uv run ruff format .
```

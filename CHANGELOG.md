# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- `Readme.md` (root) rewritten in English: updated prerequisites, modern `uv` installation
  instructions, project layout table, PUID/PGID runtime notes, cross-link to Spanish version.
- `Léeme.md` (root) created: Spanish translation of the rewritten `Readme.md`.
- `docker-compose/Readme.md` rewritten in English: full setup guide (PROJECT var,
  `my_env_vars.env`, `src` symlink, `config.cnf`), volume table with `:ro` mounts, task
  reference table, manual shell command, PUID/PGID section.
- `docker-compose/Léeme.md` created: Spanish translation of the rewritten
  `docker-compose/Readme.md`.
- `AGENTS.md`: added step 4 (create `config.cnf`) to the docker-compose setup section; added
  "Ansible version pinned to 7" quirk entry.

---

## [2.0.0] - 2026-04-14

Major architectural overhaul. The image is now user-agnostic (runtime UID/GID remapping), the
build toolchain migrated fully to `uv`, Ansible roles were hardened and deduplicated, and a
comprehensive Ansible quality audit was applied across all roles.

### Breaking changes
- The image no longer bakes a host-specific user. The internal `devops` user (UID/GID `1000`) is
  remapped at container startup via `PUID`/`PGID` environment variables. Existing bind-mount
  setups may need ownership adjustments on host directories.
- `docker compose exec` now requires `-u devops` to enter the container as the correct user.
- The `croc` tool has been removed; `wormhole` is available as a replacement.
- `boto3`/`botocore` are no longer installed via `apt`; they are installed as the latest versions
  via `uv pip`.

### Added
- Runtime PUID/PGID remapping: `docker-entrypoint.sh` reads `PUID`/`PGID` env vars and remaps
  the `devops` user via `usermod`/`groupmod` before executing `gosu devops bash -l`.
- `gosu` added to required packages for privilege-dropping in the entrypoint.
- `AGENTS.md`: repository architecture guide and developer guidelines for AI agents.
- `ansible/roles/hashicorp-tool/`: new shared Ansible role that installs any HashiCorp tool
  (Terraform, Packer inside the image) from a single parameterised definition.
- `ansible/playbooks/filter_plugins/sort_versions.py`: centralised `sort_versions` filter
  (replaces deprecated `distutils.version`; uses `packaging.version.Version`).
- `uv` role: installs `uv` inside the image.
- `pulumi` role: pre-generates bash completion into `/etc/bash_completion.d/pulumi` at build
  time so it is available immediately on login.
- `httpx` Python module added to `python-modules` role.
- `ansible_architecture | lower` normalisation applied across all roles that build
  architecture-dependent download URLs (`awscli2`, `starship`, `uv`, `hashicorp-tool`).

### Changed
- **Build toolchain**: migrated from `pipenv` to `uv` (`pyproject.toml` + `.python-version`).
  `ansible-playbook` is no longer installed globally; it lives in the `uv` virtualenv.
- **Packer invocation**: all `packer` calls (including `packer init`) now go through `uv run
  packer` so the virtualenv `ansible-playbook` is on PATH.
- `uv` role execution order moved before `python-modules` in the playbook.
- `ansible` role: simplified GPG key handling; fixed galaxy cache configuration; updated
  Ansible PPA reference; pinned installed version to `7.x` series to maintain compatibility
  with Ubuntu 22.04 Python libraries.
- `awscli2` role: added FQCN, `block/always` cleanup guard, fixed boolean values.
- `starship` role: added staging temp dir, FQCN, correct boolean values, fixed variable
  collision, corrected `x86_64` arch mapping case.
- `taskfile` role: added FQCN, `block/always`, fixed variable collision and boolean values.
- `pulumi` role: fixed variable collision, changed to install binaries individually,
  added `block/always` cleanup guard.
- `s5cmd` role: added temp dir, `block/always`, fixed variable collision.
- `joe` role: fixed variable collision, added `block/always`, switched from hard link to
  `copy` module.
- `google-cloud-sdk` role: restored `gpg --dearmor` for ASCII-armoured key; added `creates`
  for idempotency; quoted `state` values.
- `python-modules` role: use `uv_default_path` variable; added `changed_when: false`;
  quoted `state` value.
- `uv` role: replaced hard links with `copy`, fixed ownership hardcoding, added FQCN, correct
  boolean values, `block/always`, `arch | lower`, octal `mode: "0755"`.
- `image-config` role: replaced relative `mode: a+x` with absolute octal `mode: "0755"`.
- `user-config` role: sudoers file permissions set to `0440`; added `regexp` alias; added
  `changed_when`; style fixes.
- `clean-up` role: preserve `/var/lib/apt/lists` directory; use `shell` module for glob
  removal; added `changed_when: false`; split `mkdir` into a dedicated task.
- `hashicorp-tool` role: use `tempfile` module with `block/always` to guarantee archive
  cleanup even on failure.
- `entrypoint`: scoped `chown` with `find -mount` to avoid crossing bind-mount boundaries.
- `.bashrc`: removed redundant `USER` export; fixed `SSH_AUTH_SOCK` fallback; fixed word
  splitting in SSH key loop.
- `compose.yml`: removed deprecated top-level `version` key; SSH key mounts are now `:ro`.
- `docker-compose/Taskfile.yml`: removed redundant `&& exit 0` from the `sh` task; `exec`
  now passes `-u devops`.

### Fixed
- `Taskfile.yaml` `init` task: `packer init` was calling the system `packer` binary instead of
  the virtualenv one, causing plugin downloads to fail when Packer was not installed globally.
- `starship` role: `X86_64` (uppercase) was not matching the `x86_64` arch map key, causing
  the task to fail on x86 hosts.
- `ansible` role: reserved register name collision prevented the role from running correctly.
- `user-config` role: sudoers file was written with `0644` permissions (world-readable),
  which is rejected by `sudo` on some systems.
- `clean-up` role: deleting `/var/lib/apt/lists` entirely broke subsequent `apt` calls during
  the same Packer build.
- `google-cloud-sdk` role: `gpg --dearmor` task was not idempotent, causing repeated builds
  to fail with "file exists" errors.
- `entrypoint`: `chown -R` on `/home/devops` crossed into bind-mounted volumes, recursively
  changing ownership of host files.
- `.bashrc`: `SSH_AUTH_SOCK` was unset when the socket path was empty, causing the variable to
  remain with an empty string instead of being unset cleanly.

---

## [1.1.0] - 2025-09-23 / 2026-01-21

> **Note:** these changes were committed to `develop` after the `1.0.4` tag but before the
> `feature/refactor` branch was cut. They represent unreleased improvements that are included
> in `2.0.0`.

### Added
- `uv` role: added `uv` package manager as a provisioned tool inside the image.
- `httpx` Python module added to the image.
- Several missing system packages added to the `image-config` required packages list.

### Changed
- Migrated Python package manager from `pipenv` to `uv`; `Taskfile.yaml` updated to invoke
  `packer` via `uv run`.
- Removed `croc` file transfer tool; `wormhole` remains as the preferred alternative.

### Fixed
- Fixed an issue with `$PATH` not including the `uv`-managed binaries directory.
- Fixed a typo in a comment.
- Cleaned duplicate entries in `.gitignore`.

---

## [1.0.4] - 2024-03-21

### Changed
- Refactored playbook to make architecture detection more configurable across roles.
- Updated inline comments in several roles to be more meaningful.

### Fixed
- Fixed an error in the Google Cloud SDK role caused by an invalid YAML block structure.
- Fixed a typo in a role title.

---

## [1.0.3] - 2023-08-25

### Fixed
- Fixed an issue when creating the group for the main user: Ubuntu creates a same-name group
  automatically on user creation, so the group task now conditionally skips creation when the
  GID already matches.
- Cleaned Ansible YAML formatting across several tasks.

---

## [1.0.2] - 2023-08-23

### Fixed
- Fixed the Docker Compose service name, which was incorrect and prevented `docker compose`
  commands from targeting the right container.

---

## [1.0.1] - 2023-08-22

### Added
- Added `.env` file for `uv`/virtualenv configuration (`WORKON_HOME`,
  `SYSTEM_VERSION_COMPAT=0`).

### Changed
- Updated `.gitignore` rule to correctly track the `.env` file.
- Updated the `ansible/playbooks/roles` symbolic link.

---

## [1.0.0] - 2023-08-18

Initial release.

### Added
- Packer build definition (`packer/devops.pkr.hcl`) based on `ubuntu:22.04`.
- Ansible playbook (`ansible/playbooks/devops.yml`) orchestrating all provisioning roles.
- Ansible roles: `ansible`, `awscli2`, `clean-up`, `google-cloud-sdk`, `image-config`,
  `joe`, `packer` (standalone), `pulumi`, `python-modules`, `s5cmd`, `starship`,
  `taskfile`, `terraform`, `user-config`.
- `image-config` role: sets locale (`es_ES.UTF-8`), timezone, and installs the container
  entrypoint script with SSH agent auto-loading via `.bashrc`.
- `user-config` role: creates the `devops` user, configures sudoers, `.bashrc`,
  `.bash_profile`, and Starship prompt.
- `docker-compose/` project: `compose.yml`, `Taskfile.yml`, and `my_env_vars.env` template
  for running the built image.
- `Taskfile.yaml` root task runner with `build`, `build:debug`, and `init` tasks.
- `pyproject.toml` with `ansible` and `ruff` dependencies managed by `uv`.

[Unreleased]: https://github.com/your-org/devops/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/your-org/devops/compare/v1.0.4...v2.0.0
[1.1.0]: https://github.com/your-org/devops/compare/v1.0.4...v1.1.0
[1.0.4]: https://github.com/your-org/devops/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/your-org/devops/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/your-org/devops/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/your-org/devops/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/your-org/devops/releases/tag/v1.0.0

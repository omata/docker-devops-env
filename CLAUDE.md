# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

The imported `AGENTS.md` holds the ground rules (git flow, commit policy, Spanish replies), the build/run commands and the critical quirks (Packer via `uv run`, PUID/PGID remapping, Ansible pinned to 7.x, roles symlink). The notes below only add what it does not cover.

## Architecture in one pass

`task build` → `uv run packer build` (`packer/devops.pkr.hcl`) → starts `ubuntu:22.04`, bootstraps `python3-minimal`/`sudo` with a shell provisioner, runs `ansible/playbooks/devops.yml` against it, deletes leftover `.ansible` dirs, commits and tags it `devops:latest` (plus `devops:<tag>` when HEAD has an exact git tag, resolved in `Taskfile.yaml`).

- **Role order in `devops.yml` matters.** `image-config` → `required-packages` → `user-config` come first (entrypoint, apt deps, `devops` user), `python-modules` runs after `uv`, and `clean-up` is always last. Insert new tool roles between `user-config` and `python-modules`, keeping the list's current grouping.
- `hashicorp-tool` is a shared role consumed by `terraform` and `packer` (they only set defaults such as `terraform_version`/`packer_version`); a new HashiCorp tool should reuse it instead of copying tasks.
- Roles that need a version at build time resolve `latest` via GitHub API / HashiCorp index and map `x86_64`/`aarch64` to each vendor's arch naming — follow an existing role (e.g. `terraform`, `s5cmd`) as a template.
- `docker-cli` installs only the client: the container uses Docker-outside-of-Docker through `/var/run/docker.sock`. The socket's GID varies per host, so `docker-compose/Taskfile.yml` (`task up`) resolves `DOCKER_GID` with `stat` and `compose.yml` passes it via `group_add`. Run compose through `task up`, not `docker compose up` directly, or `DOCKER_GID` will be unset.
- `docker-compose/` is a user-facing template (placeholders like `<project name>`, `<version|latest>`); it is not exercised by the build.

## Worktrees

Feature/bugfix work happens in worktrunk (`wt`) worktrees under `.worktrees/`; the exact workflow is in the Git Flow section of `AGENTS.md`. `.config/wt.toml` is the project hook config (its `pre-start` hook rewrites each worktree's `.git` to a relative path so it resolves inside the container).

## Verification

There are no tests or CI. To validate a role change, the only real check is a full `task build` (use `task build:debug` to retry failed Ansible steps without restarting Packer), then `task up sh` from `docker-compose/`. `uv run ruff check .` only covers the few Python files (e.g. the `sort_versions` filter).

## Docs

`Readme.md` (English) and `Léeme.md` (Spanish) are parallel documents — keep them in sync. `CHANGELOG.md` records releases; commit messages follow Conventional Commits (`feat(ansible): …`, `refactor(ansible): …`).

# AGENTS.md

Guidance for AI agents working in this repo. KubePHP is a **template Docker image** (Nginx + PHP-FPM) for Cloud-Native PHP apps; the repo itself ships no application code (the `app/` dir is a mounted demo).

## Setup

```bash
mise trust && mise run setup
```

`mise.toml` is the single source of truth for **tools** (linters/formatters) and **tasks** (the docker compose wrappers). There is no Makefile and no app runtime. Never install a tool by hand or add an ad-hoc script — add a `[tools]` entry or a `[tasks]` task to `mise.toml` instead.

## Run via mise

- `mise run check` — all linters/formatters/validators (alias `lint`; `--fix` to autofix, `--all` for the whole tree, `--pr` for changed-vs-main). **Run this before declaring work done.** It's the exact command the pre-commit hook and CI run.
- `mise run build` / `mise run up` / `mise run deploy` — build / dev stack / prod stack.
- `mise run demo:symfony:setup` / `mise run demo:laravel:setup` — pull a demo app into `./app` to exercise the image.
- `mise tasks` to discover everything; `mise run <task> --help` for a task's flags.

## Hooks

Commits run an [hk](https://hk.jdx.dev) pre-commit hook (installed by `mise run setup`) that runs the same `check`. If a commit is blocked, fix it with `mise run check --fix` — do **not** disable a step or bypass the hook to get a commit through. Hook config is `hk.pkl`; linter configs are at the repo root (`.hadolint.yaml`, `typos.toml`, `.betterleaks.toml`, `lychee.toml`, `rumdl.toml`, `.yamllint.yml`).

## Extending the setup

- **New tool:** add it under `[tools]` in `mise.toml`, then `mise install`.
- **New task:** add a `[tasks.<name>]` block in `mise.toml` (see existing ones for the pattern).
- **New linter:** add an `hk` builtin step in `hk.pkl`'s `linters` mapping (it's shared by both the `check` and `pre-commit` hooks); run `hk builtins` to list available ones.
- The image itself is built from `Dockerfile` + the `docker/` directory (entrypoints, php/nginx/fpm configs, post-build/pre-run hooks). CI is in `.github/workflows/` (`lint.yml` runs `mise run check`; `build-test-scan.yml` builds/tests/scans the image).

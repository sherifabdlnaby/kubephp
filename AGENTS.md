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

`mise run setup` installs [hk](https://hk.jdx.dev) git hooks. On Git 2.54+ they live in git config (`hook.*`), so an empty `.git/hooks/` does not mean hooks are missing. Commits run the commit gates on staged files, pushes run the push gates, and CI runs both as `mise run check`, so a green commit is not yet a green CI. If a commit is blocked, fix it with `mise run check --fix`. Do **not** disable a step or bypass the hook to get a commit through. For a shorter loop, target steps with `mise run check --step <name>` (or `--skip-step`).

Prerequisites mise can't install (a running Docker engine) are `[doctor.checks]` in `mise.toml`; setup runs them first, and `mise doctor project` re-runs them.

## Extending the setup

- **New tool:** add it under `[tools]` in `mise.toml`, then `mise install`. Commit `mise.lock`; after a `[tools]` change regenerate it with `mise lock`.
- **New task:** add a `[tasks.<name>]` block in `mise.toml` (see existing ones for the pattern).
- **New linter:** add an hk builtin step to a gate tier in `.config/hk.pkl` (`commitGates` for fast per-file checks, `pushGates` for slower ones; `check` runs both). Run `hk builtins` to list available ones. Linter configs sit at the repo root.
- **New prerequisite** mise can't install: add a `[doctor.checks.<name>]` probe with a `hint` in `mise.toml`.
- `.config/mise/` holds the gitignored setup stamp that `setup` writes and the `enter` hook reads. Bump `vars.setup_version` only for a change nothing reconciles on its own (a new manual step or prerequisite).
- The image itself is built from `Dockerfile` + the `docker/` directory (entrypoints, php/nginx/fpm configs, post-build/pre-run hooks). CI is in `.github/workflows/` (`lint.yml` runs `mise run check`; `build-test-scan.yml` builds/tests/scans the image).

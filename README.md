# Caido formatter

Shared treefmt configuration for Caido projects, with tools managed by mise.

## Usage

Clone this private repository alongside your projects. From this checkout:

```sh
mise install

# Format a project using its existing conventions.
mise exec -- bin/format proxy-frontend --root ../proxy-frontend
mise exec -- bin/format proxy-backend --root ../proxy-backend

# Desktop uses an older Prettier version; the mise environment preserves it.
mise --env proxy-desktop exec -- bin/format proxy-desktop --root ../proxy-desktop

# CI: fail if formatting changes a file.
mise exec -- bin/format proxy-backend --root ../proxy-backend --ci

# Format selected files. Paths are relative to the target root.
mise exec -- bin/format proxy-frontend --root ../proxy-frontend packages/ui/src/App.vue
```

`treefmt --ci` **can rewrite files** before returning a failure. Run it in a CI checkout or on a clean working tree. Use the formatter's own check command when a strictly read-only check is required.

When tools are already supplied by a project's mise environment, install treefmt there and invoke `/path/to/formatter/bin/format <profile>` from the project root. The script uses executables on `PATH`; it does not install tools, change their versions, or load environment files itself. Use the version overrides in `mise.<profile>.toml` when running from this checkout.

## Shared defaults

`treefmt.toml` contains entries for every formatter family found in the audit:

| Formatter | Files                                                                      | Default selection                              |
| --------- | -------------------------------------------------------------------------- | ---------------------------------------------- |
| Oxfmt     | TypeScript, JavaScript, Vue, HTML, CSS/SCSS, JSON, GraphQL, Markdown, YAML | Yes                                            |
| rustfmt   | Rust, using nightly-2026-04-06 and edition 2024                            | Yes                                            |
| Ruff      | Python, stubs, notebooks                                                   | Yes                                            |
| OpenTofu  | Terraform/OpenTofu configuration and variable files                        | Yes                                            |
| shfmt     | Shell files with `.sh`, `.bash`, or `.bats` extensions                     | Yes                                            |
| StyLua    | Lua and Luau                                                               | Yes                                            |
| Prettier  | Web code and text formats                                                  | Alternative to Oxfmt                           |
| Deno      | JavaScript, TypeScript, JSON, Markdown                                     | Alternative to Oxfmt                           |
| nixfmt    | Nix                                                                        | Optional; installed in backend Nix shells      |
| SQLFluff  | PostgreSQL SQL                                                             | Optional; configuration found in cloud-backend |
| Black     | Python and stubs                                                           | Legacy; found in archived projects             |

Use `bin/format default` for the shared defaults. This is an opt-in organization baseline, not a claim that every existing project already follows it. The Rust baseline assumes edition 2024. Use the project presets for audited differences.

The alternative entries are disabled in the default selection to prevent two tools from reformatting the same files. Select an optional engine explicitly, for example:

```sh
mise exec -- bin/format default --root ../infrastructure --formatters tofu
bin/format nix --root ../nix-config
bin/format postgres --root ../cloud-backend
```

Deno, nixfmt, SQLFluff, and legacy Black are not installed by the base mise configuration. Supply them through the target project's environment, or explicitly install a chosen version. The audit did not establish a version pin for all of these tools. Never use a PostgreSQL SQL preset on dbt or templated SQL without checking compatibility.

## Project presets

`profiles/` contains complete treefmt files; treefmt does not merge them with the root config.

| Preset                                                                               | Behavior retained                                                             |
| ------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| `proxy-backend`                                                                      | Nightly Rust, edition 2024, macro exclusion; Prettier GraphQL at width 100    |
| `proxy-frontend`                                                                     | Oxfmt at width 80 with grouped/sorted imports and generated-file exclusions   |
| `proxy-e2e`                                                                          | Oxfmt for TS/JS/MJS; excludes plugins, binaries, and Playwright output        |
| `proxy-desktop`                                                                      | Prettier defaults on the four source packages currently covered by lint tasks |
| `proxy-playground`, `proxy-extension`                                                | Prettier formatting; existing ESLint checks remain separate                   |
| `cloud-backend`, `sync-backend`, `student-backend`, `sqlite-rs`, `cogfer`, `convert` | Existing Rust style settings; edition selected per project                    |
| `internal-services`                                                                  | Oxfmt with shared import groups                                               |
| `analytics`                                                                          | Ruff on the four Python app trees, excluding dbt's transform app              |
| `caido-private`                                                                      | Ruff for Python 3.11, limited to scripts and tests                            |
| `infrastructure`                                                                     | OpenTofu files under `tofu/`                                                  |
| `infrastructure-yaml`                                                                | Existing single-quoted YAML convention, separately opt-in                     |
| `mise-toolshed`                                                                      | Oxfmt, shfmt and StyLua; excludes generated mise locks                        |
| `secrets-sync`                                                                       | Deno formatting, using the project's Deno configuration                       |
| `electron-updater`                                                                   | Existing Prettier width 180, no semicolons, ES5 trailing commas               |
| `analytics-ingestion`, `cloud-cron`                                                  | Legacy Black presets for archived projects                                    |
| `nix`, `postgres`                                                                    | Optional infrastructure/database formatting                                   |

The presets centralize formatter style. They do not execute ESLint, Clippy, Ruff lint fixes, typechecking, dbt validation, or infrastructure validation. Keep those checks in the source repositories. Desktop's import ordering is an ESLint rule and is not replaced by running Prettier alone.

Rust files are passed directly to rustfmt with `skip_children=true`, so formatting one file cannot recursively modify excluded modules. Presets pin the nightly from proxy-backend; projects using floating nightly will need to review that stabilization. Cargo workspaces containing multiple editions need separate formatter entries or a Cargo-aware wrapper.

`configs/` stores settings that are clearer as companion files, notably Oxfmt import groups. `bin/format` resolves these relative to this checkout through `CAIDO_FORMATTER_ROOT`, even when the target project or shared checkout path contains spaces. Keep the entire checkout available. For direct treefmt use, export that variable first:

```sh
export CAIDO_FORMATTER_ROOT=/absolute/path/to/formatter
treefmt --config-file "$CAIDO_FORMATTER_ROOT/profiles/proxy-backend.toml"
```

## Mise integration in a consuming project

Pin this repository to a reviewed commit or release, then add tasks that point at the checkout. For example, when the shared checkout is a sibling:

```toml
[tasks.format]
run = 'mise -C ../formatter exec -- bin/format proxy-frontend --root "$MISE_PROJECT_ROOT"'

[tasks."format:check"]
run = 'mise -C ../formatter exec -- bin/format proxy-frontend --root "$MISE_PROJECT_ROOT" --ci'
```

This repository does not change or migrate consuming projects automatically. Review tool versions, nested configs, generated paths, and the initial formatting diff when adopting a preset. In particular, extensionless shell scripts need explicit project globs; the default shell entry only matches known extensions.

## Maintenance

The [audit report](docs/audit.md) records the scope and findings. [The inventory](docs/inventory.json) pins source commits and lists matching config/task paths for all 169 repositories scanned on 2026-10-28. Forks and archived projects are identified separately; their conventions are not silently promoted to shared defaults.

[A GitHub Actions workflow](examples/github-actions.yml) is included as an example. To activate CI, copy it to `.github/workflows/validate.yml` using a GitHub connection with workflow write permission. The connection used to initialize this repository could upload contents but could not activate workflows.

```sh
mise test
mise format
mise format:check
```

Tests exercise treefmt's real routing and shell invocation with stub formatter executables, including path handling, exclusions, competing engines, and CI failure behavior. Optional formatter engines must also be checked against their real pinned CLI before rollout.

Initial validation also ran the real Oxfmt 0.53.0, Prettier 3.7.4, nightly-2026-04-06 rustfmt, and OpenTofu 1.9.1 against scratch projects. All Rust presets accepted their configs; the infrastructure preset successfully formatted multiple files in one batch.

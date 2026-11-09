# Caido formatter

Shared formatting for Caido projects, packaged and configured with [treefmt-nix](https://github.com/numtide/treefmt-nix).

Nix supplies the formatter binaries, generates their JSON/TOML settings, and generates treefmt's configuration. Every command points into the Nix store. A caller's npm packages, mise tool versions, or rustup default cannot change the chosen formatters.

## Run a formatter

Requires Nix or Lix with `nix-command` and `flakes` enabled. From this checkout:

```sh
# Format this repository's Nix, Python, shell, JSON, YAML and Markdown.
nix fmt

# Format another project with its audited preset.
bin/format proxy-backend --root ../proxy-backend
bin/format proxy-frontend --root ../proxy-frontend
bin/format analytics --root ../analytics
bin/format infrastructure --root ../infrastructure

# Check formatting in a disposable CI checkout.
bin/format proxy-backend --root ../proxy-backend --ci

# Format selected files, relative to the target root.
bin/format proxy-frontend --root ../proxy-frontend packages/ui/src/App.vue
```

No separate formatter installation step is needed. Nix downloads or builds the selected profile's dependencies on first use and reuses them afterward. The launcher also works from a consuming project: `/path/to/formatter/bin/format proxy-backend` targets the current directory.

Each preset is a Nix app and package. You can bypass the convenience launcher:

```sh
# Run from proxy-backend's root; treefmt detects that Git worktree.
nix run /path/to/formatter#proxy-backend -- .

# Explicit target root from another directory.
nix run .#proxy-backend -- --tree-root ../proxy-backend --working-dir ../proxy-backend

# Build a standalone treefmt wrapper with all dependencies and settings.
nix build .#proxy-backend
./result/bin/treefmt --tree-root ../proxy-backend --working-dir ../proxy-backend
```

`--ci` can rewrite files before returning a failure. `nix flake check` checks this repository's formatting in a disposable copy and does not modify your checkout.

## Where the configuration lives

| File                       | Responsibility                                                                         |
| -------------------------- | -------------------------------------------------------------------------------------- |
| `flake.nix` / `flake.lock` | Pin Nixpkgs, treefmt-nix and rust-overlay; export apps, packages, dev shell and checks |
| `treefmt.nix`              | Enable native treefmt-nix modules and generate formatter-specific settings             |
| `nix/settings.nix`         | Shared Oxfmt, Prettier, rustfmt and Ruff style settings                                |
| `nix/profiles.nix`         | Project-specific formatter selection, file patterns, style selection and Rust edition  |
| `nix/excludes.nix`         | Common dependency and generated-file exclusions                                        |

For example, the backend enables the native Prettier module, limits it to GraphQL, and supplies the existing width-100 override through `programs.prettier.settings`. Treefmt-nix writes a Prettier config in `/nix/store`, writes treefmt's TOML with absolute executable/config paths, and wraps treefmt with that TOML.

The other tools use the same approach. Oxfmt and Ruff settings are generated with `pkgs.formats.json` and `pkgs.formats.toml`; rustfmt uses a Nix-packaged nightly binary directly. There is no runtime `CAIDO_FORMATTER_ROOT`, config copying, or rustup invocation.

Inspect the generated configuration and locked package versions:

```sh
cat "$(nix build .#config-proxy-backend --no-link --print-out-paths)"
cat "$(nix build .#versions --no-link --print-out-paths)"
nix eval --json .#lib.profileNames
```

## Profiles and versions

All 26 existing profile names remain available, including `proxy-*`, `analytics`, `caido-private`, `infrastructure`, `mise-toolshed`, `secrets-sync`, the other Rust backends/libraries, `electron-updater`, and the optional `nix`, `postgres`, and legacy Black presets. Optional profiles now get their tools from Nix too.

`default` selects Oxfmt, rustfmt, Ruff, OpenTofu, shfmt and StyLua. Prettier/Deno and Ruff/Black remain separate choices so competing engines do not rewrite the same files. Treefmt-nix calls the Ruff entry `ruff-format` and the OpenTofu entry `terraform`.

This migration also consolidates package versions. The audited settings and scopes are retained, but old per-project mise version overrides are replaced by this lockfile:

| Tool     | Nix version        | Previous setup                              |
| -------- | ------------------ | ------------------------------------------- |
| treefmt  | 2.6.0              | 2.6.0                                       |
| Oxfmt    | 0.75.0             | 0.53.0 / 0.73.0                             |
| Prettier | 3.9.10             | Several versions, including 3.2.5 and 3.7.4 |
| rustfmt  | nightly-2026-04-06 | Same pinned nightly                         |
| Ruff     | 0.17.4             | 0.15.16 / 0.16.9                            |
| OpenTofu | 1.13.5             | 1.9.1                                       |
| shfmt    | 3.14.1             | 3.14.1                                      |
| StyLua   | 2.6.0              | 2.6.0                                       |
| Deno     | 2.9.8              | Supplied externally                         |
| nixfmt   | 1.5.0              | Supplied externally                         |
| SQLFluff | 4.5.0              | Supplied externally                         |
| Black    | 26.5.1             | Legacy 25.12.0 / older                      |

Version changes can produce additional formatting differences. Review the initial diff when adopting the migration. Updating `flake.lock` updates package versions; the nightly date is also pinned explicitly in `flake.nix`.

Rust still uses explicit editions and `skip_children=true`; the backend macro exclusion stays in treefmt. Analytics still excludes dbt's transform app, and the frontend retains its generated/type-file exclusions. Extensionless shell scripts need explicit patterns; the self profile includes `bin/format`.

ESLint, Clippy, Ruff lint rules, typechecking, dbt validation and infrastructure validation remain separate project checks. Using a formatter preset does not replace those checks. Cargo workspaces with mixed editions need separate Rust entries or a Cargo-aware wrapper.

## Use from another flake

The simplest integration reuses the already-packaged profile. Add the private repository as an input, and expose its wrapper as your project's formatter:

```nix
{
  inputs.caido-formatter.url = "git+ssh://git@github.com/caido/formatter";

  outputs = { caido-formatter, ... }: {
    formatter = builtins.mapAttrs
      (_system: packages: packages.proxy-frontend)
      caido-formatter.packages;
  };
}
```

The consuming flake's lockfile pins the shared repository and its dependencies. Run `nix fmt` in that project. The standard private Git authentication for your checkout is required when resolving the input.

For project overrides, import the exported module into your own treefmt-nix evaluation:

```nix
treefmtEval = treefmt-nix.lib.evalModule pkgs {
  imports = [ caido-formatter.lib.treefmtModule ];
  caido.profile = "proxy-backend";
  settings.excludes = [ "fixtures/*" ];
};

# In the consuming flake's outputs for each system:
formatter.${system} = treefmtEval.config.build.wrapper;
checks.${system}.formatting = treefmtEval.config.build.check self;
```

When importing the module, non-Rust package versions come from the `pkgs` passed to that evaluation. Reusing the packaged profile uses this repository's exact locked versions. The exported module retains the pinned nightly via rust-overlay in both cases.

## Mise and maintenance

Mise can remain the development-environment/task entry point. This repository uses `.mise/config.toml` and executable task files under `.mise/tasks/`, with no formatter tools to install through mise. The `format`, `format:check` and `test` tasks call Nix.

A consuming project can create executable `.mise/tasks/format/_default`:

```sh
#!/usr/bin/env sh
set -eu
exec ../formatter/bin/format proxy-frontend --root "$MISE_PROJECT_ROOT"
```

The corresponding `.mise/tasks/format/check` adds the CI option:

```sh
#!/usr/bin/env sh
set -eu
exec ../formatter/bin/format proxy-frontend --root "$MISE_PROJECT_ROOT" --ci
```

Validation uses the real Nix-packaged binaries, including six-language routing, excluded files, Rust child modules, paths with spaces, idempotence and independence from the host PATH:

```sh
nix flake check
nix flake check --all-systems --no-build
nix develop
```

Supported systems are Apple Silicon macOS (`aarch64-darwin`) and ARM64/x86_64 Linux. The locked Nixpkgs release no longer supports Intel macOS. [The GitHub Actions example](examples/github-actions.yml) installs Nix and runs `nix flake check`. It remains an example; activating it requires workflow write permission.

The [historical audit](docs/audit.md) and [inventory](docs/inventory.json) record the 169 repositories scanned on 2026-10-28. This migration does not modify consuming repositories.

[ADR 0001](docs/adrs/0001-evaluate-treefmt-nix-in-formatter.md) records this as a proposed repository-scoped experiment under the engineering tooling standard. It does not approve an organization-wide tooling change.

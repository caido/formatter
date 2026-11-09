# Caido formatter

One shared [treefmt-nix](https://github.com/numtide/treefmt-nix) configuration for every repository. Each language always uses the same formatter, version and settings. There are no project presets or local formatter settings to maintain.

## Add to any project

Use this identical `flake.nix` in every repository:

```nix
{
  inputs.caido-formatter.url = "git+ssh://git@github.com/caido/formatter";

  outputs = { self, caido-formatter, ... }:
    caido-formatter.lib.forProject self;
}
```

Then run:

```sh
nix fmt
nix flake check
```

The shared helper checks **your repository's source**. It exports only a `formatting` check and a `formatting-check` package. It checks the consuming repository rather than the library's source. An existing flake can merge these outputs with its other outputs; no formatter-specific settings are required.

`nix flake check` runs all entries under `checks`; it has no check-name filter. If your flake adds other checks, run formatting alone with:

```sh
nix build --no-link .#formatting-check
```

This check formats a disposable source copy and leaves your working tree unchanged. Use `--no-update-lock-file` with these commands in CI to reject missing or stale lockfiles.

## The shared configuration

`treefmt.nix` selects formatter packages, file patterns and generic exclusions. Formatter-specific settings live in their native files:

```text
configs/
  oxfmt.json
  ruff.toml
  rustfmt.toml
  stylua.toml
  sqlfluff.ini
```

Shell flags stay in `treefmt.nix`; nixfmt and OpenTofu use their defaults. Every consuming repository shares these same files.

The language mapping is:

| Files                                                                 | Formatter                    |
| --------------------------------------------------------------------- | ---------------------------- |
| JavaScript, TypeScript, Vue, HTML, CSS, JSON, GraphQL, Markdown, YAML | Oxfmt                        |
| Python                                                                | Ruff                         |
| Rust                                                                  | rustfmt, pinned nightly      |
| Terraform/OpenTofu                                                    | OpenTofu                     |
| Shell                                                                 | shfmt                        |
| Lua/Luau                                                              | StyLua                       |
| Nix                                                                   | nixfmt                       |
| SQL                                                                   | SQLFluff, PostgreSQL dialect |

There is one set of language globs and generic dependency/generated-file exclusions. Existing per-repository formatter config files do not select alternate formatting settings. Prettier, Deno and Black are not alternative engines in this setup.

All Rust files use edition 2024 and the shared 2024 style. Projects must update their `Cargo.toml` edition and migrate any incompatible code before adopting the shared formatter. Python formatting targets Python 3.11 compatibility everywhere.

Nix parses the JSON/TOML settings during evaluation and generates the tool configuration files and treefmt TOML in the Nix store. SQLFluff uses the shared INI file directly from the store. Nixpkgs and rust-overlay are pinned in `flake.lock`, so formatter binaries do not come from a project's PATH. Update the shared input's lockfile pin to roll out a new version of this configuration.

## Develop this library

Configuration validation uses JSON/TOML parsing, treefmt-nix’s module option types and config generation. The SQLFluff INI file is passed through without Nix-side parsing. Formatter-specific settings passed through as data or arguments may still be rejected at runtime; there is no custom formatter test suite.

The [validation workflow](.github/workflows/validate.yml) runs on pull requests and pushes to `main`. It uses the Determinate Nix installer and Magic Nix Cache backed by GitHub Actions. It evaluates all supported systems, builds the generated treefmt configuration on Linux and checks repository formatting with the committed lockfile.

```sh
# Same formatter and formatting-only check used by every consumer.
nix fmt --no-update-lock-file
nix flake check --no-update-lock-file

# Evaluate module options and flake outputs on all supported systems without running checks.
nix flake check --all-systems --no-build --no-update-lock-file

# Inspect the generated shared treefmt configuration.
cat "$(nix build --no-link --print-out-paths .#config)"
```

Requires Nix or Lix with `nix-command` and `flakes` enabled. Supported systems are Apple Silicon macOS and ARM64/x86_64 Linux. Private Git access is needed to fetch the shared input. The same minimal consumer flake is available in `templates/default`.

[ADR 0001](docs/adrs/0001-evaluate-treefmt-nix-in-formatter.md) records the proposed tooling experiment.

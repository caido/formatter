# Caido formatter

This repo contains the formatting rules for every language and data serialization format that we use at [caido](https://caido.io). It exposes contains a nix flake that provides utilities to make sure files are properly formatted in your projects. Every formatter we use is pinned here in the `flake.lock` and installed on the fly when the fmt command is run. It is based on [treefmt-nix](https://github.com/numtide/treefmt-nix).

## Add to any project

Add this `flake.nix` to your repos:

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
nix run .#formatting-check
```

## Configs

`treefmt.nix` selects formatters and files patterns. For formatter that supports it, the config is expressed in their standard config file in `config/`.

```text
configs/
  oxfmt.json
  ruff.toml
  rustfmt.toml
  stylua.toml
  sqlfluff.ini
  ...
```

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
| Toml                                                                  | taplo                        |
| SQL                                                                   | SQLFluff, PostgreSQL dialect |

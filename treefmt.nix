{ pkgs, ... }:
let
  json = pkgs.formats.json { };
  toml = pkgs.formats.toml { };
  rustfmt = pkgs.rust-bin.nightly."2026-04-06".minimal.override {
    extensions = [ "rustfmt" ];
  };
  rustSettings = toml.generate "caido-rustfmt.toml" {
    unstable_features = true;
    style_edition = "2024";
    group_imports = "StdExternalCrate";
    imports_granularity = "Module";
    single_line_if_else_max_width = 80;
    skip_children = true;
  };
  # Cargo's language edition is parser metadata, not a formatting preset.
  # Every crate uses the same rustfmt binary and the same style settings.
  rustCommand = pkgs.writeShellScriptBin "caido-rustfmt" ''
    exec ${pkgs.python3}/bin/python3 ${./support/rustfmt.py} \
      ${rustfmt}/bin/rustfmt ${rustSettings} "$@"
  '';
  sqlSettings = (pkgs.formats.ini { }).generate "caido-sqlfluff.cfg" {
    sqlfluff = {
      dialect = "postgres";
      max_line_length = 80;
    };
  };
in
{
  projectRootFile = null;
  settings.on-unmatched = "debug";
  settings.excludes = [
    ".git/*"
    "node_modules/*"
    "*/node_modules/*"
    "dist/*"
    "*/dist/*"
    "target/*"
    "*/target/*"
    "coverage/*"
    "*/coverage/*"
    ".venv/*"
    "*/.venv/*"
    ".terraform/*"
    "*/.terraform/*"
    "**/__generated__/**"
    "*.min.js"
    "*.min.css"
    "result"
    "result-*"
  ];

  programs = {
    oxfmt.enable = true;
    ruff-format = {
      enable = true;
      includes = [
        "*.py"
        "*.pyi"
        "*.ipynb"
      ];
    };
    terraform.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
      simplify = false;
      includes = [
        "*.sh"
        "*.bash"
        "*.bats"
        "*.envrc"
      ];
    };
    stylua = {
      enable = true;
      includes = [
        "*.lua"
        "*.luau"
      ];
      settings = {
        column_width = 80;
        line_endings = "Unix";
        indent_type = "Spaces";
        indent_width = 2;
        quote_style = "AutoPreferDouble";
        call_parentheses = "Always";
        collapse_simple_statement = "Never";
        sort_requires.enabled = false;
      };
    };
    nixfmt.enable = true;
    sqlfluff = {
      enable = true;
      dialect = "postgres";
    };
  };

  settings.formatter = {
    oxfmt.options = [
      "--write"
      "--config"
      (toString (
        json.generate "caido-oxfmt.json" {
          printWidth = 80;
          tabWidth = 2;
          useTabs = false;
          semi = true;
          singleQuote = false;
          trailingComma = "all";
          endOfLine = "lf";
          sortImports = {
            groups = [
              "builtin"
              "external"
              "internal"
              "parent"
              "sibling"
              "index"
            ];
            newlinesBetween = true;
            ignoreCase = true;
            order = "asc";
          };
        }
      ))
      "--disable-nested-config"
      "--ignore-path"
      (toString (pkgs.writeText "caido-oxfmt-ignore" ""))
    ];
    ruff-format.options = [
      "--config"
      (toString (
        toml.generate "caido-ruff.toml" {
          line-length = 88;
          target-version = "py311";
        }
      ))
    ];
    rustfmt = {
      command = rustCommand;
      includes = [ "*.rs" ];
    };
    sqlfluff.options = [
      "--ignore-local-config"
      "--disregard-sqlfluffignores"
      "--config"
      (toString sqlSettings)
    ];
  };
}

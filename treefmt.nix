{ pkgs, ... }:
let
  json = pkgs.formats.json { };
  toml = pkgs.formats.toml { };
  rustfmt = pkgs.rust-bin.nightly."2026-04-06".minimal.override {
    extensions = [ "rustfmt" ];
  };
  readTOML = path: fromTOML (builtins.readFile path);
  rustSettings = toml.generate "caido-rustfmt.toml" (readTOML ./configs/rustfmt.toml);
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
      settings = readTOML ./configs/stylua.toml;
    };
    nixfmt.enable = true;
    sqlfluff.enable = true;
  };

  settings.formatter = {
    oxfmt.options = [
      "--write"
      "--config"
      (toString (
        json.generate "caido-oxfmt.json" (builtins.fromJSON (builtins.readFile ./configs/oxfmt.json))
      ))
      "--disable-nested-config"
      "--ignore-path"
      (toString (pkgs.writeText "caido-oxfmt-ignore" ""))
    ];
    ruff-format.options = [
      "--config"
      (toString (toml.generate "caido-ruff.toml" (readTOML ./configs/ruff.toml)))
    ];
    rustfmt = {
      command = "${rustfmt}/bin/rustfmt";
      includes = [ "*.rs" ];
      options = [
        "--config-path"
        (toString rustSettings)
      ];
    };
    sqlfluff.options = [
      "--ignore-local-config"
      "--disregard-sqlfluffignores"
      "--config"
      "${./configs/sqlfluff.ini}"
    ];
  };
}

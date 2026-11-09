{
  config,
  lib,
  pkgs,
  ...
}:
let
  profiles = import ./nix/profiles.nix;
  styles = import ./nix/settings.nix;
  profile = profiles.${config.caido.profile};
  routes = profile.formatters;
  route = name: routes.${name} or { };
  style = family: styles.${family}.${(route family).style or "default"};
  json = pkgs.formats.json { };
  toml = pkgs.formats.toml { };

  # The names used by treefmt-nix for the audited Ruff and OpenTofu entries.
  programName =
    name:
    {
      ruff = "ruff-format";
      tofu = "terraform";
    }
    .${name} or name;
  nativeRoutes = lib.filterAttrs (name: _: name != "oxfmt-root") routes;
  # Respect downstream mkForce enable/disable overrides as well as the preset.
  enabled = name: config.programs.${programName name}.enable or false;
in
{
  options.caido.profile = lib.mkOption {
    type = lib.types.enum (builtins.attrNames profiles);
    default = "default";
    description = "Audited Caido formatter profile to use.";
  };

  config = {
    # Keep Git/worktree root detection in treefmt itself. In particular, do not
    # anchor a packaged formatter to the formatter repository's flake.nix.
    projectRootFile = null;
    enableDefaultExcludes = false;
    settings.on-unmatched = "debug";
    settings.excludes =
      import ./nix/excludes.nix
      ++ (profile.excludes or [ ])
      ++ [
        "result"
        "result-*"
      ];

    programs = lib.mkMerge [
      (lib.mapAttrs' (
        name: value:
        lib.nameValuePair (programName name) {
          enable = true;
          includes = value.includes;
          excludes = value.excludes or [ ];
        }
      ) nativeRoutes)
      {
        prettier.settings = style "prettier";
        rustfmt.edition = (route "rustfmt").edition or "2024";
        # Preserve the previous `shfmt -w` behavior; treefmt-nix otherwise adds
        # two-space indentation and simplification by default.
        shfmt.useEditorConfig = true;
        sqlfluff.dialect = "postgres";
      }
    ];

    settings.formatter = lib.mkMerge [
      (lib.mkIf (enabled "oxfmt") {
        oxfmt.options = [
          "--write"
          "--config"
          (toString (json.generate "caido-oxfmt.json" (style "oxfmt")))
        ];
      })
      (lib.mkIf (routes ? oxfmt-root && enabled "oxfmt") {
        # A separate root-only entry prevents *.ts from matching unrelated
        # subdirectories while retaining the frontend's source scopes.
        oxfmt-root = {
          command = lib.getExe config.programs.oxfmt.package;
          options = config.settings.formatter.oxfmt.options;
          inherit (routes.oxfmt-root) includes excludes;
        };
      })
      (lib.mkIf (enabled "prettier") {
        prettier.options = [ "--no-editorconfig" ];
      })
      (lib.mkIf (enabled "rustfmt") {
        rustfmt.options = [
          "--config-path"
          (toString (toml.generate "caido-rustfmt.toml" (style "rustfmt")))
        ];
      })
      (lib.mkIf (enabled "ruff") {
        ruff-format.options = [
          "--force-exclude"
          "--config"
          (toString (toml.generate "caido-ruff.toml" (style "ruff")))
        ];
      })
    ];
  };
}

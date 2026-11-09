{
  description = "One shared formatter configuration for every Caido repository";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      rust-overlay,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
      evaluated = eachSystem (system: treefmt-nix.lib.evalModule (pkgsFor system) ./treefmt.nix);
      wrappers = eachSystem (system: evaluated.${system}.config.build.wrapper);

      # Only the source being checked differs between callers. Formatter
      # selection, settings, versions and file routing are identical everywhere.
      forProject = source: {
        formatter = wrappers;
        checks = eachSystem (system: {
          formatting = evaluated.${system}.config.build.check source;
        });
        apps = eachSystem (system: {
          formatting-check = {
            type = "app";
            program = toString (
              (pkgsFor system).writeShellScript "formatting-check" ''
                exec nix build --no-link --no-update-lock-file "${source}#checks.${system}.formatting" "$@"
              ''
            );
          };
        });
      };
      project = forProject self;
    in
    {
      lib = { inherit forProject; };
      inherit (project) formatter checks apps;
      templates.default = {
        path = ./templates/default;
        description = "Identical shared formatting integration for any Caido repository";
      };
    };
}

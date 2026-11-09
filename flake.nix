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
        packages = eachSystem (system: {
          formatting-check = evaluated.${system}.config.build.check source;
        });
      };
      project = forProject self;
    in
    {
      lib = { inherit forProject; };
      inherit (project) formatter checks;

      packages = eachSystem (
        system:
        project.packages.${system}
        // {
          default = wrappers.${system};
          config = evaluated.${system}.config.build.configFile;
        }
      );

      apps = eachSystem (system: {
        default = {
          type = "app";
          program = "${wrappers.${system}}/bin/treefmt";
        };
      });
      devShells = eachSystem (system: {
        default = evaluated.${system}.config.build.devShell;
      });
      templates.default = {
        path = ./templates/default;
        description = "Identical shared formatting integration for any Caido repository";
      };
    };
}

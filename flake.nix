{
  description = "Shared Caido formatters, configured and packaged with treefmt-nix";

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
      # Current Nixpkgs no longer supports x86_64-darwin.
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      eachSystem = nixpkgs.lib.genAttrs systems;
      profiles = import ./nix/profiles.nix;
      profileNames = builtins.attrNames profiles;

      sharedModule = { pkgs, lib, ... }: {
        imports = [ ./treefmt.nix ];
        # The overlay supplies a rustfmt binary directly. No rustup, host
        # toolchain selection, or ambient PATH is needed at runtime.
        programs.rustfmt.package = lib.mkDefault (
          (pkgs.extend rust-overlay.overlays.default).rust-bin.nightly."2026-04-06".minimal.override {
            extensions = [ "rustfmt" ];
          }
        );
      };

      evaluated = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        nixpkgs.lib.genAttrs profileNames (
          name:
          treefmt-nix.lib.evalModule pkgs {
            imports = [ sharedModule ];
            caido.profile = name;
          }
        )
      );
      testProfiles = [
        "default"
        "self"
        "proxy-backend"
        "proxy-frontend"
        "analytics"
        "caido-private"
        "infrastructure"
        "mise-toolshed"
      ];
    in
    {
      lib = {
        inherit profileNames;
        treefmtModule = sharedModule;
        settings = import ./nix/settings.nix;
      };

      formatter = eachSystem (system: evaluated.${system}.self.config.build.wrapper);

      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          configs = evaluated.${system};
          wrappers = builtins.mapAttrs (_: value: value.config.build.wrapper) configs;
          configFiles = nixpkgs.lib.mapAttrs' (
            name: value: nixpkgs.lib.nameValuePair "config-${name}" value.config.build.configFile
          ) configs;
        in
        wrappers
        // configFiles
        // {
          formatting-check = configs.self.config.build.check self;
          tests = pkgs.linkFarm "caido-formatter-tests" [
            {
              name = "configuration";
              path = self.checks.${system}.configuration;
            }
            {
              name = "routing";
              path = self.checks.${system}.routing;
            }
          ];
          versions = pkgs.writeText "caido-formatter-versions.json" (
            builtins.toJSON (
              builtins.mapAttrs (_: value: value.version) {
                inherit (pkgs)
                  treefmt
                  oxfmt
                  prettier
                  ruff
                  opentofu
                  shfmt
                  stylua
                  deno
                  nixfmt
                  sqlfluff
                  black
                  ;
              }
              // {
                rustfmt = "nightly-2026-04-06";
              }
            )
          );
        }
      );

      apps = eachSystem (
        system:
        builtins.mapAttrs (_: value: {
          type = "app";
          program = "${value.config.build.wrapper}/bin/treefmt";
        }) evaluated.${system}
      );

      devShells = eachSystem (system: {
        default = evaluated.${system}.self.config.build.devShell;
      });

      checks = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          configs = evaluated.${system};
          testConfigs = nixpkgs.lib.genAttrs testProfiles (name: {
            program = "${configs.${name}.config.build.wrapper}/bin/treefmt";
            config = toString configs.${name}.config.build.configFile;
          });
          overridden = treefmt-nix.lib.evalModule pkgs {
            imports = [ sharedModule ];
            caido.profile = "proxy-backend";
            programs.rustfmt.enable = pkgs.lib.mkForce false;
            settings.excludes = [ "fixtures/*" ];
          };
        in
        {
          formatting = configs.self.config.build.check self;
          # Force module evaluation for every profile, including optional tools,
          # without requiring every formatter closure just to validate options.
          configuration =
            assert !(overridden.config.settings.formatter ? rustfmt);
            assert builtins.elem "fixtures/*" overridden.config.settings.excludes;
            builtins.deepSeq (builtins.mapAttrs (
              _: value: builtins.removeAttrs value.config.settings [ "global" ]
            ) configs) (pkgs.runCommand "caido-formatter-configuration" { } "touch $out");
          routing =
            pkgs.runCommand "caido-formatter-routing"
              {
                nativeBuildInputs = [ pkgs.python3 ];
                CAIDO_TEST_CONFIGS = builtins.toJSON testConfigs;
                CAIDO_TEST_SOURCE = self;
                CAIDO_TEST_SHELL = pkgs.runtimeShell;
              }
              ''
                python3 ${./tests/test_config.py}
                touch "$out"
              '';
        }
      );
    };
}

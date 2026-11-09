{
  inputs.caido-formatter.url = "git+ssh://git@github.com/caido/formatter";

  outputs =
    { self, caido-formatter, ... }:
    # Expose nix fmt, nix flake check and nix run .#formatting-check.
    caido-formatter.lib.forProject self;
}

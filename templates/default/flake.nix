{
  inputs.caido-formatter.url = "git+ssh://git@github.com/caido/formatter";

  outputs =
    { self, caido-formatter, ... }:
    caido-formatter.lib.forProject self;
}

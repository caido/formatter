# Evaluate treefmt-nix in formatter

Status: Proposed experiment

Date: 2026-11-09

## Context

This repository was created to explore shared treefmt configuration for Caido. The requested PR evaluates using treefmt-nix to supply the formatter binaries, their settings and the treefmt configuration together.

[STD-018](https://github.com/caido/engineering/blob/main/standards/STD-018-tooling.md) requires mise for tool setup and explicitly describes treefmt as an experiment outside the approved tool list. This proposal requests a scoped exception for this experimental repository. It does not claim that an organization-wide exception has already been approved.

## Proposed decision

Use a locked Nix flake and treefmt-nix in `caido/formatter` to evaluate reproducible formatter packages and generated configuration. Retain mise as an optional task entry point using the layout in [STD-019](https://github.com/caido/engineering/blob/main/standards/STD-019-mise.md).

Keep this experiment confined to the shared formatter repository. Do not change the approved tooling standard or migrate consuming repositories as part of this PR. Maintainer acceptance of this proposal and its scoped exception is required before adopting it beyond the experiment.

## Consequences

- Formatter commands and settings resolve to immutable Nix store paths.
- Nix or Lix is required to run a formatter profile, and the first invocation may download or build its dependencies.
- Formatter versions come from the locked Nixpkgs revision; existing per-project mise version differences are consolidated and documented in the README.
- The experiment supports Apple Silicon macOS and ARM64/x86_64 Linux. The locked Nixpkgs revision does not support Intel macOS.
- The historical audit remains available. Existing projects keep their current tooling until a separate migration is reviewed.

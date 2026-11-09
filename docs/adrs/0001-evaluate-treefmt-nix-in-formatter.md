# Evaluate treefmt-nix in formatter

Status: Proposed experiment

Date: 2026-11-09

## Context

This repository was created to explore shared treefmt configuration for Caido. The requested PR evaluates using treefmt-nix to supply the formatter binaries, their settings and the treefmt configuration together.

[STD-018](https://github.com/caido/engineering/blob/main/standards/STD-018-tooling.md) describes treefmt as an experiment outside the approved tool list. This proposal requests a scoped exception for this Nix-only experimental repository. It does not claim that an organization-wide exception has already been approved.

## Proposed decision

Use a locked Nix flake and one shared treefmt-nix configuration in `caido/formatter`. Every repository uses the same formatter per language, the same settings and the same package versions. Remove the project presets, local style variants and profile launcher.

Repositories use the identical `lib.forProject self` flake wiring to expose `nix fmt` and a formatting-only `nix flake check`. Library integration tests are an explicitly built package, not flake checks exported to consumers. The requested interface is Nix only, with no separate task layer.

Keep this experiment confined to the shared formatter repository. Do not change the approved tooling standard or migrate consuming repositories as part of this PR. Maintainer acceptance of this proposal and its scoped exception is required before adopting it beyond the experiment.

## Consequences

- Formatter commands and settings resolve to immutable Nix store paths.
- Nix or Lix is required to run the shared formatter, and the first invocation may download or build its dependencies.
- Formatter versions come from the shared lockfile. Changes to the central configuration are rolled out by updating each consumer's shared input pin.
- The experiment supports Apple Silicon macOS and ARM64/x86_64 Linux. The locked Nixpkgs revision does not support Intel macOS.
- Existing projects keep their current tooling until the shared input is adopted in a separate migration.

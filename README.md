# Bendoom

Doom, written in [Bend 2](https://bend-lang.com).

The game reads a Doom WAD at runtime, so it plays
[Freedoom](https://freedoom.github.io) (BSD licensed, from nixpkgs) or
id's shareware `DOOM1.WAD` (free to pass on, not to sell). The sim is
integer fixed point, as the original was, and the rules that must hold
about it are stated in `LAWS.bend` and proven in `PROOF.bend`; `nix flake
check` refuses a build with an open or broken law.

    nix run github:eliesgalvira/bendoom
    nix run github:eliesgalvira/bendoom#bendoom-shareware

Bend itself is built from its source in the flake, pinned to one commit,
with no self-updating launcher and no telemetry.

Tests are `.bend` files under `tests/` whose trailing `#|` lines are the
expected output. Specs live under `.scratch/`.

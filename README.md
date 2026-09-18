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
expected output, run natively and on the JS lane. Specs live under
`.scratch/`; the Bend constraints the code lives by are in `docs/bend.md`.

## Milestones

Each is a spec under `.scratch/`, cut into tickets, then implemented.
The reference for how anything looks or behaves is vanilla Doom: the
1997 linuxdoom-1.10 source and Chocolate Doom, which reproduces it bug
for bug.

1. WAD loads, directory parses, a window opens. Done.
2. Playsim: fixed point, E1M1 loaded, movement and collision, the wall law. Done.
3. Walls, then floors, ceilings and sky.
4. Doors, the lift, switches, the exit: E1M1 completable, no enemies.
5. Things: decorations, items, pickups, sprites.
6. Monsters, weapons, damage, the status bar.
7. Sound effects.
8. Music, rendered to PCM at build time.
9. Hellbent: the game as one λ-expression.

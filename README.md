# Bendoom

> [!WARNING]
> SLOP WARNING: There has been no adult supervision of the code.

Doom, written in [Bend 2](https://bend-lang.com).

The game reads a Doom WAD at runtime, so it plays id's shareware
`DOOM1.WAD` (free to pass on, not to sell), which the flake fetches from
the idgames archive, or [Freedoom](https://freedoom.github.io) (BSD
licensed, from nixpkgs). The sim is
integer fixed point, as the original was, and the rules that must hold
about it are stated in `LAWS.bend` and proven in `PROOF.bend`; `nix flake
check` refuses a build with an open or broken law.

    nix run github:eliesgalvira/bendoom
    nix run github:eliesgalvira/bendoom#bendoom-freedoom

If flakes aren't enabled on your system, put this after `nix`:

    --extra-experimental-features 'nix-command flakes'

Builds are available for x86_64 Linux, aarch64 Linux and Apple Silicon
macOS. CI checks all three; gameplay and audio on macOS still need a
hardware test.

Without Nix, download and run the portable release:

    curl -fsSL https://github.com/eliesgalvira/bendoom/releases/latest/download/play.sh | sh

For Freedoom, end the command with `sh -s -- --freedoom`. The launcher
checks the archive's SHA-256 and keeps it in `~/.cache/bendoom`, or under
`XDG_CACHE_HOME`. Linux needs an X11 display or Xwayland; the archive
includes its loader and libraries. The macOS build is for Apple Silicon.
You can also extract a release tarball and run `./bendoom` directly.

Nix can download our builds from `bendoom.cachix.org`. Accept the flake's
cache settings when prompted, or configure it once with `cachix use bendoom`.

The up and down arrows or W and S walk, the left and right arrows turn,
A and D strafe, Shift runs, Space opens doors and presses switches, Ctrl
fires, Esc quits. After dying, Space starts the level again.

To record a game and make a video of it, first play with `RECORD` naming
the demo to write, and quit with Esc or by closing the window; the demo
also ends with the level. Ctrl+C in the terminal leaves it without its
end marker. Then `film` encodes the demo as a 1600 by 1200 MP4 at Doom's
35 tics a second, and leaves an existing video alone. Its audio is the
same eight-channel mix of the WAD's song and sound effects that the game
plays, with every sound beginning on its tic. When the demo completes the
level, the video includes the intermission count-up and holds the final
scores for three seconds. The demo is vanilla's .lmp,
which Chocolate Doom plays too. A demo recorded with `bendoom-freedoom`
is filmed with `film-freedoom`, which carries Freedoom's song and sounds.

    RECORD=run.lmp nix run github:eliesgalvira/bendoom
    nix run github:eliesgalvira/bendoom#film -- run.lmp run.mp4

Bend is built from a pinned, unmodified [source snapshot](https://github.com/eliesgalvira/bendoom/releases/tag/bend-2.0.22-source)
hosted in our release assets, with no self-updating launcher or telemetry.

Tests are `.bend` files under `tests/` whose trailing `#|` lines are the
expected output, run natively and on the JS lane. `tools/oracle.nu`
plays a command script as a vanilla demo in Chocolate Doom and diffs its
frame against ours after the same commands. Specs live under
`.scratch/`; the Bend constraints the code lives by are in `docs/bend.md`.

## Milestones

Each is a spec under `.scratch/`, cut into tickets, then implemented.
The reference for how anything looks or behaves is vanilla Doom: the
1997 linuxdoom-1.10 source and Chocolate Doom, which reproduces it bug
for bug.

1. WAD loads, directory parses, a window opens. Done.
2. Playsim: fixed point, E1M1 loaded, movement and collision, the wall law. Done.
3. Walls, floors, ceilings and the sky: vanilla's renderer, its frames Chocolate Doom's pixel for pixel. Done.
4. Doors, the lift, switches, the exit, blinking and glowing lights, animated flats and textures, scrolling walls: E1M1 completable through its world geometry, its frames Chocolate Doom's tic for tic. Done.
5. Decorations, items, pickups and sprites: the two E1M1s' noncombat things spawned on Hurt Me Plenty and drawn as vanilla's sprites behind walls, ledges and grates, animated on its tics; health, armour, ammo, weapons and the blue key taken as vanilla takes them; solid things in the way. Its frames Chocolate Doom's tic for tic. Done.
6. Monsters, weapons, damage, the status bar and intermission on both E1M1s. Recorded fights and complete routes agree with Chocolate Doom; the maintainer played both maps to the intermission. Combat, render, route, proof and performance checks are recorded under `.scratch/milestone-6-combat/`. Done.
7. Sound effects. Doors, the lift, switches, pickups, weapons, monsters, the player and the intermission sound from the WAD's own lumps, expanded and mixed over the music on vanilla's eight moving channels. The film carries the same mix. Done.
8. E1M1's music: the song and the instruments of the package's WAD played in Bend as Chocolate Doom's OPL music plays them, sample for sample, rendered while the flake builds and streamed by the game on repeat, so each package plays the song of the WAD it was built with. Done.
9. Hellbent: the game as one λ-expression.

## License

GPL-2.0-or-later, in `LICENSE`. `src/tables.bend` and
`src/opl_tables.bend` are generated from Chocolate Doom's source, which
is GPL-2.0-or-later too. `src/sfx_taps.bend` is the filter of SDL's
resampler, computed by `tools/gen_sfx_taps.nu` as SDL's source computes
it; SDL is under the zlib license.

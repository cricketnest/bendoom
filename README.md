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

To record a game and make a video of it, first play with `RECORD` naming
the demo to write, and quit with Esc or by closing the window; the demo
also ends with the level. Ctrl+C in the terminal leaves it without its
end marker. Then `film` encodes the demo as a 1600 by 1200 MP4 at Doom's
35 tics a second, and leaves an existing video alone. Under it runs
E1M1's song as the package's WAD holds it, from the first frame and
repeating for as long as the video lasts. The demo is vanilla's .lmp,
which Chocolate Doom plays too. A demo recorded with `bendoom-shareware`
is filmed with `film-shareware`, which carries the shareware song.

    RECORD=run.lmp nix run github:eliesgalvira/bendoom
    nix run github:eliesgalvira/bendoom#film -- run.lmp run.mp4

Bend itself is built from its source in the flake, pinned to one commit,
with no self-updating launcher and no telemetry.

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
4. Doors, the lift, switches, the exit, blinking and glowing lights, animated flats and textures, scrolling walls: E1M1 completable, no enemies, its frames Chocolate Doom's tic for tic. Done.
5. Decorations, items, pickups and sprites: every thing of both E1M1s but the monsters, spawned as on Hurt Me Plenty and drawn as vanilla's sprites behind walls, ledges and grates, animated on its tics; health, armour, ammo, weapons and the blue key taken as vanilla takes them; solid things in the way. Its frames Chocolate Doom's tic for tic. Done.
6. Monsters, weapons, damage, the status bar.
7. Sound effects.
8. E1M1's music: the song and the instruments of the package's WAD played in Bend as Chocolate Doom's OPL music plays them, sample for sample, rendered while the flake builds and streamed by the game on repeat, so each package plays the song of the WAD it was built with. Done.
9. Hellbent: the game as one λ-expression.

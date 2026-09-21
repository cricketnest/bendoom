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

It runs on x86_64 Linux. aarch64 Linux and macOS are untested, and on
macOS the game plays without music or sounds.

The up and down arrows or W and S walk, the left and right arrows turn,
A and D strafe, Shift runs, Space opens doors and presses switches, Ctrl
fires, Esc quits. After dying, Space starts the level again.

To record a game and make a video of it, first play with `RECORD` naming
the demo to write, and quit with Esc or by closing the window; the demo
also ends with the level. Ctrl+C in the terminal leaves it without its
end marker. Then `film` encodes the demo as a 1600 by 1200 MP4 at Doom's
35 tics a second, and leaves an existing video alone. Under it runs
E1M1's song as the package's WAD holds it, from the first frame and
repeating for as long as the video lasts. The demo is vanilla's .lmp,
which Chocolate Doom plays too. A demo recorded with `bendoom-freedoom`
is filmed with `film-freedoom`, which carries Freedoom's song.

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
6. Monsters, weapons, damage, the status bar. In part: the monsters of both E1M1s stand where the map puts them, wake when they see the player and chase; zombiemen and shotgun guys shoot; the pistol fires with vanilla's autoaim, bullets hurt and kill, barrels explode, the nukage burns and the player dies; the status bar with its face, pickup messages and the red and gold flashes are drawn. Not yet: the imps' and demons' attacks (they chase and do not strike), every weapon but the pistol, monsters woken by gunfire, infighting, drops, the intermission. A shot that hits a thing lands a few pixels from vanilla's. Much of what is there is checked against Chocolate Doom only in part; each ticket under `.scratch/milestone-6-combat/` lists what it still owes.
7. Sound effects. In part: doors, the lift, switches, pickups, the pistol, the monsters and the player sound from the WAD's own lumps, expanded as Chocolate Doom expands them, sample for sample, and mixed over the music on vanilla's eight channels. Not yet: a moving source does not pan as it moves, the mix is not yet compared with a recording of Chocolate Doom's, and the film carries the music alone.
8. E1M1's music: the song and the instruments of the package's WAD played in Bend as Chocolate Doom's OPL music plays them, sample for sample, rendered while the flake builds and streamed by the game on repeat, so each package plays the song of the WAD it was built with. Done.
9. Hellbent: the game as one λ-expression.

## License

GPL-2.0-or-later, in `LICENSE`. `src/tables.bend` and
`src/opl_tables.bend` are generated from Chocolate Doom's source, which
is GPL-2.0-or-later too. `src/sfx_taps.bend` is the filter of SDL's
resampler, computed by `tools/gen_sfx_taps.nu` as SDL's source computes
it; SDL is under the zlib license.

# 01: The sim takes commands

**What to build:** A prefactor, so that a script is the same thing as a vanilla demo. The tic takes a command of forward, side, turn and a use button, where it took the held keys. The keys module still builds the command from the held keys with vanilla's walk and run tables, and the six-tic slow turn's held count leaves the player for the game's input state, where vanilla's G_BuildTiccmd keeps it. Replay folds a list of commands. The frame loop builds each owed tic's command from the held keys and the count. The use button is carried and ignored until ticket 04. Nothing the player can see changes.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The tic, the run of n tics and replay take commands; no sim function takes the held keys
- [x] The player record has no held count; the game's input state has it beside the keys, and the slow turn still takes its six tics in the window
- [x] Every line of the sim test and every hash of the render test is unchanged, on both lanes
- [x] The key laws still prove; the rest law, the freedom law, the wall law and the replay law are restated over commands and proven
- [x] No leftover: nothing builds a command inside the sim, and no comment still says the sim reads keys
- [x] The flake check stays green

## Comments

Done. `K.Cmd` carries the use button, ignored until ticket 04, and Space (32) is its key. The held count lives in `K.Input`, the keys beside it, which is what the game holds: `Game.advance` replays `K.Input.script(tics, input)` and keeps `K.Input.after(tics, input)`. The sim's run of n tics of held keys had one reader left once the game replays a script, so it is deleted: the tests build their runs with `K.Input.script` from a fresh input, which is what their runs were (every turn run follows a run with no turn key, so the count was 0 at each). The closed laws name commands (`K.Cmd.idle()`, forward 25 and 50); `cmd_tables` gains Space, and `turn_script` pins the six-tic slow turn where the count now lives. The tic law opens no record any more: its proof is the five lemmas in a row.

Every line of the sim test and every hash of the render test is unchanged on both lanes; `bend PROOF.bend` checks; the game, the benches and the frame dump build.

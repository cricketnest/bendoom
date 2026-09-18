# 08: The player moves: thrust and friction, replay composes

**What to build:** The pure sim step, so that laws can be stated about it. The player state is position, angle, momentum and the held-key word. One tic follows Doom's order: build the command, turn, thrust along the angle by the forward and side moves through the sine table, apply momentum to position, apply friction. The step takes the number of tics to run. No collision yet: the player walks through walls. A test loads E1M1, runs a scripted command list through the same step the game uses, and prints position and angle in map units.

**Blocked by:** 02 (Fixed point), 03 (Angle tables), 05 (Tic command), 06 (Level loaded)

**Status:** resolved

- [x] The step is a pure integer function of a command list, the level and the player, with the tic count as an argument
- [x] Thrust matches Doom: walking forward one tic from rest adds 25 units of momentum along the facing, and friction is 0.90625 per tic
- [x] The sim test's expected lines are pinned to Freedoom's start; a hand check against the shareware constants is recorded in the comments
- [x] Law: replaying two command sequences in turn equals replaying their concatenation, for all sequences, levels and players; proven in PROOF.bend
- [x] Sanity law: one tic of no keys from rest leaves the player where it was
- [x] The test passes on both lanes and the flake check stays green

## Comments

Done. `Sim.tic(level, keys, player)` is the step, `Sim.run(n, ...)` runs n tics, `Sim.replay(script, ...)` folds a list of held-key states. The player carries the turn keys' held count, so the command is built inside the step from the keys and that count. The `replay_append` law is proven by induction on the first script, `tic_rest` by computation for any level and position (the angle is 0 because U32 addition on a symbolic word does not compute in the checker). Expected lines are pinned to Freedoom; the shareware hand check is at the top of `tests/sim.bend`: one tic forward from rest lands at 1055.999694, -3615.218765, that is 25 * 2048 / 65536 = 0.78125 units of momentum along the facing, and forty idle tics of friction 0.90625 a tic settle 76 units on.

The test's every line was cross-checked against a Python model of the same Doom code written independently first, which agreed on all fifteen lines on both WADs; milestone 3 deleted it, and the one number it established beyond the pinned lines, the first tic's thrust and friction from rest, is the `tic_from_rest` law.

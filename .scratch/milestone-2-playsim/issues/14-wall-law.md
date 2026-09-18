# 14: The wall law: replay from the start is free of solid walls

**What to build:** The promise that the player can never pass through a solid wall, proven rather than tested. The law states that replaying any command sequence from the level's start leaves the player at a position that is free, in the sense of ticket 10. It is proven by an invariant: one step from a free position on a level answers a free position, which is then folded over the sequence. It is proven once over the finished step, after collision, openings and sliding are all in.

**Blocked by:** 10 ("Free" is pinned to the map's geometry), 12 (Steps up and low ceilings), 13 (Sliding along walls)

**Status:** resolved

- [x] Law: for all command lists, levels and free players, one step preserves free; in LAWS.bend, proven in PROOF.bend
- [x] Law: for all command lists, replay from the start is free, derived from the invariant and the start being free
- [x] No step function is duplicated or specialised for the proof: the game and the law call the same step
- [x] The flake check stays green with every milestone 2 law filled

## Comments

Done. `tic_keeps_free` and `replay_keeps_free` in LAWS.bend; `PROOF.bend` proves them by one lemma per sim function from `Sim.try_move.fin` up to `Sim.tic`, each a match on the flag the function decides by and the record it opens, with the free hypothesis passed along; the two loops (`slide.go`, `xy.go`) are inductions on their fuel. The game and the law call the same functions. The proof rests on `Sim.free` being the verdict of the same `Sim.fit` every move passes, so it holds for every level value, sound blockmap or not; see 10 for what that leaves open.

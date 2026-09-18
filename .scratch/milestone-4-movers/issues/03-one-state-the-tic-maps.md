# 03: One state the tic maps

**What to build:** A prefactor, so that the first mover has somewhere to live. Everything that changes per tic becomes one value the tic maps to the next: the player, the level, the side texture numbers, the active thinkers (none yet), the random index, the clock, and whether the level has ended. The clock leaves the player, where it has been the bob's clock, for the state. The loader keeps two more things the movers will read: each line's special and tag, in a tree of their own apart from the vertices, flags and sides the wall law reads, and each sector's block box as P_GroupLines computes it, from the sector's lines widened by 32 units. The map as loaded is kept beside the state, so a fresh state can be built from it without the WAD. The renderer takes the state and reads heights, light, textures and the clock from it. Nothing the player can see changes.

**Blocked by:** 01 (The sim takes commands)

**Status:** resolved

- [x] The tic, the run and replay map the state; the game, the tests and the frame dump hold one state where they held a level and a player
- [x] Line specials and tags load for both WADs; the load test prints the counts per special for Freedoom, and they match the counts read out of the WAD in nushell first (20 of special 1, 6 of 2, 1 of 11, 1 of 23, 4 of 26, 4 of 62, 5 of 88, 1 of 117)
- [x] A sector's block box is pinned for one sector against a value computed by hand from its lines in the WAD
- [x] A universal law states that a tic leaves the geometry trees as they were, and it is proven; the wall law, the freedom law, the rest law and the replay law are restated over the state and proven
- [x] Every line of the sim test and every hash of the render test is unchanged, on both lanes
- [x] The comment on the level type no longer says geometry is never part of the state; it says which words change and where they live
- [x] The flake check stays green

## Comments

Done. `S.State` is the player, the level, the side texture numbers, the random index, the clock and the ended flag; `Sim.tic` and `Sim.replay` map it, and an ended state's tic is the identity already (`tic_counts` states that and the clock's step). The thinkers' list is not in it yet: it comes in ticket 04 with the first thinker's type, since a list of nothing needs a placeholder type to be written down. The clock left the player, and the eye takes it as a parameter; the bob's swing is worked out in `Sim.eye` where the clock is, so the ground and air halves lost their level parameter.

The level is `Level{geo, sectors, specials}`. `Level.Geo` is everything no tic writes (lines, sides, vertices, segs, subsectors, nodes, blockmap, names, tables and the sectors' boxes); the sectors' tree and the specials' tree (special and tag a line, from LINEDEFS 6 and 8) are the changing words. Every accessor kept its name and its callers; its pattern opens the nested record. `Vec.set` is the path-copying write, first used to build the boxes: one pass over the lines widens the box of the sector on each side, from a box turned inside out, as `P_GroupLines` does. `Level.blockbox` answers vanilla's block box from it on read (the 32-unit widening, the shift by 23, the clamps to the map). Loading moved below the lookups in `level.bend`, since grouping reads lines through `Level.line`.

The map as loaded stays in `Game.level` beside the state, and the side textures as loaded stay in the graphics: `State.start(level, Gfx.sidetex(gfx))` builds a fresh state with no WAD. The renderer takes the state and puts its side textures where the segs already look (`Gfx.sided`), so no reader changed.

Outside values, read from Freedoom in nushell before the loader answered: 1175 lines; specials 1:20, 2:6, 11:1, 23:1, 26:4, 62:4, 88:5, 117:1 (and no 48 or 36, which only the shareware map has); line 528 is special 2 tag 5; the blockmap's origin is -712, -1072, 32 by 27. Sector 10, the first door, has lines from y 512 to 544 and x 768 to 896, so its block box is top (544 + 1072 + 32) / 128 = 12, bottom (512 + 1072 - 32) / 128 = 12, left (768 + 712 - 32) / 128 = 11, right (896 + 712 + 32) / 128 = 12. Sector 98, the lift, 64 to 192 by 192 to 320: top 11, bottom 9, left 5, right 7. The load test printed all of them right the first time.

Laws: `tic_keeps_geometry` (`Level.geo` of the state's level is the same after any tic) is proven by opening the state, and `tic_counts` is new. The wall law, the tic's freedom law, the rest law and the replay law are restated over the state (`Free(s)` is a def in `LAWS.bend`), and the wall law's lemmas are untouched but for the eye's. The closed laws compare the player after a script in `Level.room`, not whole states, so the checker does not normalise the sine table twice a law.

Every line of the sim test and every hash of the render test is unchanged on both lanes; the oracle still reports 0 for the stride.

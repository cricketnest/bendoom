# 03: One state the tic maps

**What to build:** A prefactor, so that the first mover has somewhere to live. Everything that changes per tic becomes one value the tic maps to the next: the player, the level, the side texture numbers, the active thinkers (none yet), the random index, the clock, and whether the level has ended. The clock leaves the player, where it has been the bob's clock, for the state. The loader keeps two more things the movers will read: each line's special and tag, in a tree of their own apart from the vertices, flags and sides the wall law reads, and each sector's block box as P_GroupLines computes it, from the sector's lines widened by 32 units. The map as loaded is kept beside the state, so a fresh state can be built from it without the WAD. The renderer takes the state and reads heights, light, textures and the clock from it. Nothing the player can see changes.

**Blocked by:** 01 (The sim takes commands)

**Status:** ready-for-agent

- [ ] The tic, the run and replay map the state; the game, the tests and the frame dump hold one state where they held a level and a player
- [ ] Line specials and tags load for both WADs; the load test prints the counts per special for Freedoom, and they match the counts read out of the WAD in nushell first (20 of special 1, 6 of 2, 1 of 11, 1 of 23, 4 of 26, 4 of 62, 5 of 88, 1 of 117)
- [ ] A sector's block box is pinned for one sector against a value computed by hand from its lines in the WAD
- [ ] A universal law states that a tic leaves the geometry trees as they were, and it is proven; the wall law, the freedom law, the rest law and the replay law are restated over the state and proven
- [ ] Every line of the sim test and every hash of the render test is unchanged, on both lanes
- [ ] The comment on the level type no longer says geometry is never part of the state; it says which words change and where they live
- [ ] The flake check stays green

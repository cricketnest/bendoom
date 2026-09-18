# 06: Switches

**What to build:** A switch shows that it took. P_ChangeSwitchTexture with the shareware switch list: of the front side's top, middle and bottom textures, the one that is a switch swaps to its partner, written into the side texture numbers in the state. A once-only switch clears its line's special. A repeatable one starts a 35-tic timer, counted down after the movers each tic, that swaps the texture back. The loader composes the partner of every switch texture the map's sides name, so a swap never names a missing graphic. The first switched mover comes with it: special 23 starts T_MoveFloor on every tagged sector with no thinker, down at 1 a tic to the lowest neighbouring floor, through ticket 04's T_MovePlane.

**Blocked by:** 04 (Space opens a door)

**Status:** resolved

- [x] The switch list is vanilla's episode 1 pairs, taken from linuxdoom's source
- [x] The sim test uses Freedoom's special 23 switch and prints the three tagged floors reaching their destination, the height and the tic computed by hand from the WAD first
- [x] A second use of that switch does nothing; a universal law states that a fired once-only line has no special afterwards, and it is proven
- [x] A closed law pins the repeatable switch's timer: pressed at one tic, back 35 tics later
- [x] The load test shows the partner textures composed; the count of extra textures is recorded in the comments
- [x] The render test gains a frame of the pressed switch; the oracle compares it before and after the press, counts recorded, target zero
- [x] Both lanes pass; the flake check stays green

## Comments

Read out of the WADs in nushell and computed by hand before the Bend code answered. Freedoom's E1M1 names two switch textures, SW1GRAY on the exit (line 407, its middle) and SW1BRN1 on the special 23 switch (line 753, side 1166, its middle); the shareware map names SW1STRTN on its exit. All three are in vanilla's episode 1 list, and no side of either map names two. Freedoom's four special 62 lines carry PLAT1 or nothing, which is no switch, so vanilla swaps nothing on them and starts no timer.

Line 753 is tag 3, which sectors 76, 126 and 129 carry, each a block with its floor at its ceiling. `EV_DoFloor` lowers each at 1 a tic to the lowest floor around it, starting from its own: sector 76 from 272 to 136 (its neighbour 121), there after the 136th tic, its thinker gone on the 137th; sector 126 from 264 to 144 (neighbour 75), the 120th and the 121st; sector 129 from 264 to 136 (neighbours 128 and 102), the 128th and the 129th.

Done, with one part moved. The sim printed the hand computation: the use on tic 1 puts the three floors at 271, 263 and 263; sector 126 is at 144 after the 120th tic and its thinker gone on the 121st; sector 129 at 136 after the 128th, gone on the 129th; sector 76 at 136 after the 136th, gone on the 137th; a second use starts nothing, the line's special being 0.

The 35-tic timer and its closed law moved to ticket 08, where the first repeatable switch is: a timer written here would have had no special that starts it and no test that runs it. `Sim.switch` swaps; ticket 08 adds the timer to it for special 62.

What was built:

- The switch list is `Gfx.switch.pairs`, vanilla's 19 episode 1 pairs from `p_switch.c`'s `alphSwitchList`. Chocolate Doom gives Freedoom the registered list too (episode 2's ten pairs); neither E1M1 names any of those, so they are left out with the specials no map carries.
- The loader numbers each used switch's partner after the map's own names (`Gfx.switch.wanted`), so it is composed like any texture, and builds `switches`, a texture's partner by number or 0. Two extra textures for Freedoom: SW2BRN1 (64 by 128, 5 patches) and SW2GRAY (64 by 128, 3 patches), sizes read from TEXTURE1 in nushell; the load test prints both and that the partner's partner is the switch.
- The sides' texture numbers as loaded and the switch table live in the level's geometry, filled in by the graphics loader (`Level.textured`), so `State.start(level)` needs nothing else and the sim reads a partner through `Level.switch`. A level loaded without graphics, as the sim test's is, has no switches, and its movers work all the same. `Level.Geo` also gained the sectors' special and tag words (`sectags`).
- `Sim.switch` swaps the front side's top texture if it is a switch, else the middle, else the bottom. Vanilla walks its switch list and tries the three against each entry, so a side naming two different switches would swap the one earlier in the list; no side of either map names two (checked in nushell), so the simpler order has no map that tells them apart.
- Tagged movers are one path for tickets 07 and 08 to reuse: `Sim.tagged` answers a tag's sectors that have no mover, in sector order, and `Sim.start` takes the mover's maker as a template (`Sim.floor.low` here). `Sim.use.once` does nothing when no sector starts, as vanilla leaves the switch alone then; otherwise it starts them, swaps the switch, and clears the special last, through `Sim.once`, which is what `once_clears` is about: for any state and line, the line's special after `Sim.once` is 0. Its proof is `vec_get_set`, a tree read where it was just written, by induction on the tree; `Level.at` is the one place a record's index is worked out, so the write and the read name the same index.
- `free_geo` no longer spells the geometry's record out (a second small lemma, `lines_same`, opens it once), so adding a field to it touches two patterns in the proof file.

Oracle, one shot each, from before the switch (`2064 -260 90`): before the press (`20,0,0,0,0 10,25,0,0,0 28,0,0,0,0`): 0 differing. 28 tics after the press (`20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0`): 0. The render test pins the second.

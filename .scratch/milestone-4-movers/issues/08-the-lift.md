# 08: The lift

**What to build:** The lift the player rides. Specials 62 (switch) and 88 (walk-over), both repeatable, start T_PlatRaise's down-wait-up-stay on every tagged sector with no thinker: down at 4 a tic to the lowest neighbouring floor no higher than its own, 105 tics of wait, up to the height it started at, then the thinker ends. The player on it rides through ticket 05's re-clip, the eye moving with the floor and no dip. A lift that rises into a player who does not fit goes back down and waits again. Special 62 swaps its switch and starts ticket 06's timer.

**Blocked by:** 05 (A moving plane re-clips the player), 06 (Switches), 07 (Walk-over triggers)

**Status:** resolved

- [x] The sim test calls Freedoom's lift by its walk-over line, rides it down and up, and prints the floor, the player's height and the eye at chosen tics, all computed by hand from the WAD first
- [x] The sim test calls it by its switch from below and prints the switch popping back 35 tics later
- [x] A trigger on a running lift starts nothing; the lift answers again once its thinker has ended
- [x] Closed laws on a literal level pin the lift's timeline (first tic, bottom, the tic it starts up, the top) and the crushed case going back down
- [x] The oracle compares a frame from on the lift mid-travel and one at the bottom, counts recorded, target zero
- [x] Both lanes pass; the flake check stays green

## Comments

Read out of the WAD in nushell and computed by hand before the Bend code answered, from `p_plats.c` (`downWaitUpStay`: 4 a tic, down to the lowest floor around no higher than its own, 105 tics of wait, up to the height it started at, where the thinker ends) and `p_switch.c` (`BUTTONTIME` 35; the button's count goes down once on the tic of the press).

- Freedoom's first lift is sector 98 (tag 1; lines 593, 595 and 596 are special 88, line 594 special 62), floor 12, the floors around it 0, -124 and 0, so it travels from 12 to -124: with the trigger on tic 1 the floor is 8 after that tic and -124 after the 34th; the 35th would pass and lands, and the wait starts; the count reaches zero on tic 140, which only turns it; -120 after the 141st, 12 after the 174th, and the 175th lands and ends the thinker.
- The second is sector 103 (tag 2), floor 136, the floors around it 136 and 8: 8 after the 32nd tic, the wait ends on the 138th, 136 after the 170th, gone on the 171st.
- A player riding keeps its height on the floor each tic (`P_ThingHeightClip`), and its eye, worked out at the tic's start, follows a tic late: on the way down the eye is 45 over the floor (41 and the step of 4), on the way up 37, with no change of the view height.
- The laws' literal level, the door sector's floor put at -32 so the west room has somewhere to go, line 0 made special 62 with a switch texture (1, partner 2) on its front's middle, the blockmap's origin moved east so that the player at (32, 64) is in no sector's block box and costs the checker no position check: the use on tic 1 starts a lift in each sector (tag 0); sector 0 goes 0 to -32: -4 after tic 1, -32 after tic 8, tic 9 lands, the wait ends on tic 114, -28 after 115, 0 after 122, gone on 123. The switch's middle is 2 from tic 1 and its button 34 after that tic; still 2 after tic 34; 1 again after tic 35, the button gone.
- The crushed lift: the west room's floor at -32 under a ceiling at 40, rising 4 a tic under a player 56 tall standing in it: -16 after 4 tics (56 of room, which fits); the 5th would leave 52, so it is undone and the lift is back on its plan; -20 after the 6th.

Done. The sim printed the hand computation for sector 98: 8 on the tic the run crosses its west line, -124 on the 34th, held through the 140th, -120 on the 141st, 12 on the 174th, the thinker gone on the 175th; the rider's height is the floor's every tic and the eye is 45 over the floor going down and 37 going up, a tic behind it, the view height never touched. From the pit the switch (line 594) calls it; a use while it runs starts nothing and leaves one thinker; a use once it is back calls it again.

One of the ticket's boxes cannot be shown on Freedoom: its four special 62 lines carry PLAT1 or no texture, which is no switch, so vanilla swaps nothing there and starts no button, and neither do we. The button is pinned where a switch texture exists, in the law's literal level.

What was built:

- The lift is a plan, `Sim.lift`: down to the lowest floor around (its own included, which is `p_plats.c`'s "no higher than its own"), hold 105, up to where it was. Nothing else was needed: ticket 04's mover runs it, ticket 05's crushed mover restarts the plan, which is a lift going back down, waiting, and rising again, and a running mover is what `Sim.tagged` leaves out. Special 88 starts it from `Sim.cross.special` with no `Sim.once`; special 62 starts it from `Sim.use.again`.
- `Button{side, slot, texture, tics}` is the second thinker: `Sim.switch` takes whether the switch works again, and then starts a button of 35 tics for the texture the side showed, unless that side has one running, as `P_StartButton` passes over a line already pressed. It runs with the thinkers, not after them as vanilla's `P_UpdateSpecials` does; a button touches only a side's texture, which no thinker reads, so the order cannot be seen. Its count goes down on the tic of the press, so the texture is back on the 35th tic counting the press as the first. This is the timer ticket 06 left for here.
- `State.thinking` is the one place a thinker is appended; the mover's keep, the door and the button use it. `Sim.door.turn` lost its helper and turns a door in one def.

Laws: `lift_timeline` is the whole path on the literal level, from the use: the three lifts the tag starts with their plans and the button at 34, the west room's floor at -32 on tic 8, still there on tic 114, -28 on tic 115, 0 on tic 122 and no thinker on tic 123, the switch showing 2 through tic 34 and 1 from tic 35. My expected list first left out the door sector's own lift (tag 0 is every sector; its floor is already the lowest, so its first tic lands and it sits in its wait), and the checker printed it. `lift_crushed`: -16 after 4 tics, -16 again after the 5th with the lift back on its plan, -20 after the 6th. The lift law's level moves the blockmap's origin east (`Closed.level(ox)`), so the player is in no block box and 123 tics of replay cost no position check; the proof check is 45 seconds.

Oracle, one shot each, from the player 1 start running east (`-416 256 0`):

| script | what | differing |
| --- | --- | --- |
| `4,0,0,0,0 56,50,0,0,0` | riding the lift down, 21 tics after the crossing | 0 (44623 in ticket 02, before the lift) |
| `90,0,0,0,0 66,50,0,0,0` | off its east edge, falling to the pit | 0 (40708 in ticket 02) |
| `5,0,0,0,0 38,50,0,0,0 110,0,0,0,0` | stopped on the lift, at the bottom, in its wait | 0 |

The tool now draws its X display number at random: with other agents running oracles at the same moment, "the first free lock file" gave two of them one display, and the window search failed. It also waits up to 30 seconds for the window under that load.

The sim test's two walks and the render test's `air` and `landed` frames were pins of a level without its lift, as ticket 02 said; they are re-pinned with the lift running (the first walk now turns on the lowering lift and ends in the pit).

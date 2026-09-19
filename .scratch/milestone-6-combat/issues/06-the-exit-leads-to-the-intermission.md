# 06: The exit leads to the intermission

**What to build:** The exit switch leads to vanilla's intermission. The level counts the player's kills, items and secrets against totals taken at spawn, and a secret sector counts once when entered. The intermission is a second game mode: the background, the finished level's name, the three percentages counted up at vanilla's pace, time and par, then the screen naming the next level. A press finishes the counting and the next goes on. Afterwards a fresh E1M1 starts, where vanilla would load E1M2.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Totals count the things flagged as kills and as items at spawn, and the sectors with special 9; special 9 counts on entry and clears itself
- [ ] The kill count exists here and stays 0 until milestone 6's ticket 19 raises it
- [ ] The tally follows `WI_updateStats` and `WI_drawStats` for one player, with all graphics from the WAD
- [ ] Space or Enter accelerates as vanilla's attack and use do, and the last press builds a fresh state from the map as loaded
- [ ] The printed level time and the held last frame are deleted
- [ ] The oracle compares the settled tally, with the animated background patches masked, since they advance during its pause; target zero
- [ ] A test prints the counts and the intermission's state per tic for a scripted exit, with expected tics read from `wi_stuff.c`
- [ ] The route tests still reach the exit

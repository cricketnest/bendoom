# 16: A woken monster chases

**What to build:** A woken monster walks at the player with vanilla's movement: eight directions, turning toward its move direction, backing off and trying again when blocked, stopped by ledges too high, drops too deep and lines that block monsters, and opening the manual doors vanilla lets it open.

**Blocked by:** 03 (Things move, relink and spawn in play), 15 (A monster sees the player)

**Status:** ready-for-agent

- [ ] `A_Chase`'s movement half, `P_NewChaseDir`, `P_TryWalk`, `P_Move` and `A_FaceTarget`, with every random draw in place, the active sound's among them
- [ ] `P_TryMove`'s dropoff test: ticket 03's `Sim.check` does not gather `tmdropoffz`, so this ticket adds it to what the check answers
- [ ] A blocked move uses the special lines it hit, which opens manual doors
- [ ] Each monster moves at its speed on its move tics and relinks as it goes
- [ ] The freedom law grows from the player to every thing that moved
- [ ] Sim cases: a chase across a room, around a corner, through a door, and one stopped at a ledge, with places per tic and the random index from a replay of the source
- [ ] A render case shows walking frames mid-chase at zero differing pixels, from a script that ends before any attack would start

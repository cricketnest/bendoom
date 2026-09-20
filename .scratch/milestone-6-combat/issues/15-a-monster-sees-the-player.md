# 15: A monster sees the player

**What to build:** A monster notices the player by sight. `A_Look` tests the player within the monster's field of view and its line of sight, which reads the REJECT lump first and then walks the BSP with vanilla's slopes. A monster that sees the player makes its sight sound, chosen by a random draw among its variants, and enters its chase state on vanilla's tic. It does not move yet.

**Blocked by:** 08 (Monsters stand where the map puts them); milestone 7's 01 (The sim reports its sounds)

**Status:** ready-for-agent

- [ ] The loader keeps REJECT; `P_CheckSight` follows `P_CrossBSPNode` and `P_CrossSubsector`
- [ ] `A_Look` and `P_LookForPlayers` for one player: the field of view, the close-range exception, and the ambush flag's effect on sight
- [ ] The sight sound's draw is a `P_Random` draw made whether or not anything plays it
- [ ] Sim cases: a monster woken from the front, one approached from behind, one behind a wall, one behind a window, with the wake tic and the random index from a replay of the source
- [ ] Ticket 08 turned the idle rows 61 to 68 into rows whose action is `Null{}`; they become `Look{}` here, with the mobj action dispatch, and `H.Thing.ambush(level, id)` gives the ambush flag
- [ ] Ticket 08 left ten oracle frames as regression pins because vanilla's monsters wake there and Bendoom's could not (air, landed, blink dark, key 22 and 23, key before and after, green armour before and after, chainsaw after); each one whose script ends before a woken monster moves returns to zero here, and the ticket lists which still wait for the chase
- [ ] A sight test over sector pairs prints results that agree with REJECT read in nushell where REJECT decides

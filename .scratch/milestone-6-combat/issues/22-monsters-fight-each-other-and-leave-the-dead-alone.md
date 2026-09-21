# 22: Monsters fight each other and leave the dead alone

**What to build:** The last of monster behaviour. A monster hurt by another monster turns on it by vanilla's rules, keeps its target through the threshold, and goes back to the player afterwards. A barrel's blast turns monsters on whoever shot the barrel. When the player dies, monsters lose their target and return to idling.

**Blocked by:** 17 (Zombiemen and shotgun guys shoot), 18 (Imps claw and throw, demons bite), 19 (Monsters are hurt and die)

**Status:** ready-for-agent

- [x] `P_DamageMobj`'s target switch and threshold, and the rule that an imp's fireball does not hurt an imp
- [x] `A_Chase`'s return to looking when its target is dead
- [x] Sim cases on Freedoom: a shotgun guy hitting an imp and the fight that follows, a barrel shot by the player killing one monster and angering another, the player dead and the monsters idle, from a replay of the source
- [ ] Every oracle case of tickets 15 to 21 that was limited by a missing behaviour is now run at full length

## Comments

- `tests/sim.bend` runs Freedoom records 240 and 81 through a real shotgun attack and 60 subsequent tics. Chocolate Doom independently reaches random index 132 with the imp at fixed position (58408867, 69207132), 15 health, state 447/3, threshold 87 targeting the shotgun guy; the shotgun guy is at (64396762, 69204213), 12 health, state 219/7, threshold 99 targeting the imp. Bendoom matches after its compact state-row mapping.
- The same test keeps a monster's existing target while threshold 100, attributes barrel damage to the player, and shows both nearby imps back in idle rows with threshold zero after the player dies.
- A relinked barrel beside records 81, 82 and 240 runs its explosion as a normal thinker action. Chocolate Doom and Bendoom both end the tic at random index 67: the first imp is dead at -68 health, the second has 24 health and threshold 100, and the shotgun guy has 10 health and threshold 99; both survivors target the player. This caught and fixed the missing immediate `A_Chase` action when damage wakes a monster from its spawn state.
- The remaining formerly limited ticket 15–21 visual routes still need their final integrated oracle records before this ticket is resolved.

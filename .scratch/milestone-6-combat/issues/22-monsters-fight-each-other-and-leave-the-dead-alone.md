# 22: Monsters fight each other and leave the dead alone

**What to build:** The last of monster behaviour. A monster hurt by another monster turns on it by vanilla's rules, keeps its target through the threshold, and goes back to the player afterwards. A barrel's blast turns monsters on whoever shot the barrel. When the player dies, monsters lose their target and return to idling.

**Blocked by:** 17 (Zombiemen and shotgun guys shoot), 18 (Imps claw and throw, demons bite), 19 (Monsters are hurt and die)

**Status:** ready-for-agent

- [ ] `P_DamageMobj`'s target switch and threshold, and the rule that an imp's fireball does not hurt an imp
- [ ] `A_Chase`'s return to looking when its target is dead
- [ ] Sim cases on Freedoom: a shotgun guy hitting an imp and the fight that follows, a barrel shot by the player killing one monster and angering another, the player dead and the monsters idle, from a replay of the source
- [ ] Every oracle case of tickets 15 to 21 that was limited by a missing behaviour is now run at full length

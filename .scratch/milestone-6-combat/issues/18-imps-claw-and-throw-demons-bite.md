# 18: Imps claw and throw, demons bite

**What to build:** The other two monsters attack. An imp claws at melee range and throws a fireball from afar. The fireball flies, hits what is in its way, bursts with its sprite, and vanishes against a sky ceiling. A demon charges and bites.

**Blocked by:** 09 (The nukage hurts and the player dies), 16 (A woken monster chases)

**Status:** ready-for-agent

- [ ] `P_CheckMeleeRange`, `A_TroopAttack` and `A_SargAttack`
- [ ] `P_SpawnMissile` and the missile branches of the XY and Z movement and of the position check, `P_ExplodeMissile`, the sky hack, and damage of one to eight times the missile's
- [ ] A missile never hits its thrower
- [ ] The fireball's throw and burst sounds start where vanilla's do, and the flight sound stops with the thing
- [ ] Sim cases: a claw, a fireball that hits the player, one that hits a wall, one into the sky, a demon's bite on Freedoom, from a replay of the source
- [ ] Render cases: a fireball in flight and bursting, full bright, at zero differing pixels

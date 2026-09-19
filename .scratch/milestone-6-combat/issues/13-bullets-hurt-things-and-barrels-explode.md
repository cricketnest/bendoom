# 13: Bullets hurt things and barrels explode

**What to build:** Damage reaches things. A bullet that hits a shootable thing damages it, thrusts it, and leaves blood or a puff as vanilla decides. A barrel takes damage, explodes, hurts everything within its radius that it can see, the player included, and sets off other barrels. A shot barrel slides from the blow.

**Blocked by:** 09 (The nukage hurts and the player dies), 11 (Ctrl fires the pistol)

**Status:** ready-for-agent

- [ ] `P_DamageMobj` and `P_KillMobj` for any shootable thing, with the thrust and the random death tics; a thing pushed by damage moves through the general movement
- [ ] Blood and puffs spawn as `P_SpawnBlood` and `P_SpawnPuff` do
- [ ] The barrel's death rows, `A_Explode`, and `P_RadiusAttack` with vanilla's blockmap box, distance measure and sight test
- [ ] The explosion's credit passes to whoever shot the barrel
- [ ] Sim cases: a barrel shot to death, a chain of two, the player hurt by one through armour, with health, places and the random index from a replay of the source
- [ ] Render cases: a barrel mid-explosion and blood on a hit, at zero differing pixels

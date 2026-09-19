# 14: The fist, the berserk pack and the chainsaw

**What to build:** The melee weapons. The fist punches at melee range and hits ten times harder after a berserk pack, which also brings the fist up. The chainsaw idles, revs, cuts without ammo, and pulls the player toward what it cuts. Key 1 chooses the chainsaw over the fist unless the player is berserk. Milestone 5's second declared gap closes.

**Blocked by:** 12 (Weapons switch and the shotgun fires), 13 (Bullets hurt things and barrels explode)

**Status:** ready-for-agent

- [ ] `A_Punch` and `A_Saw` with their ranges, damage draws, the turn toward the target and the saw's pull
- [ ] The berserk pickup sets the pending fist, as `P_TouchSpecialThing` does
- [ ] The chainsaw's idle, full and hit sounds start where vanilla's do
- [ ] Sim cases on Freedoom: a punch at a barrel with and without berserk, the saw on a barrel, key 1 under each ownership
- [ ] Render cases: the fist and the saw at rest and attacking, at zero differing pixels

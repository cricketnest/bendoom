# 17: Zombiemen and shotgun guys shoot

**What to build:** The former humans attack. A chasing zombieman or shotgun guy decides to fire by vanilla's missile range check, faces the player, and shoots hitscan with vanilla's spread and damage, one bullet or three.

**Blocked by:** 02 (One traversal finds what a ray meets), 09 (The nukage hurts and the player dies), 16 (A woken monster chases)

**Status:** ready-for-agent

- [ ] `A_Chase`'s attack half, `P_CheckMissileRange`, `A_PosAttack` and `A_SPosAttack`, with reaction time and the just-attacked flag
- [ ] The player takes the damage through armour, and the attacker is recorded
- [ ] Their attack sounds start where vanilla's do
- [ ] Sim cases on Freedoom: each type's first shot at the player, hit and miss, with tics, health and the random index from a replay of the source
- [ ] Render cases: each type mid-attack at zero differing pixels

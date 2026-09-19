# 11: Ctrl fires the pistol

**What to build:** Ctrl fires. The pistol spends a bullet, plays its fire states and its flash, lights the room for the flash's tics, and hits by vanilla's hitscan: autoaim up and down at what stands ahead, the first shot accurate and held fire spread, a puff where a bullet meets a wall. It refuses to fire without ammo.

**Blocked by:** 01 (The tic command carries fire and weapon change), 02 (One traversal finds what a ray meets), 03 (Things move, relink and spawn in play), 07 (The pistol rises, bobs and shows); milestone 7's 01 (The sim reports its sounds)

**Status:** ready-for-agent

- [ ] `A_WeaponReady`'s fire check, `P_FireWeapon`, `A_FirePistol`, `A_ReFire`, `A_GunFlash` and the light actions, with the refire count and the attack-down flag
- [ ] `P_AimLineAttack` and `P_LineAttack` as visitors of the traversal, with vanilla's slopes and its retries to either side; no line in either map fires on a gunshot, so `P_ShootSpecialLine` is left out
- [ ] The puff spawns with its random z and tics; every `P_Random` draw is made where vanilla makes it
- [ ] The extra light reaches the renderer, and flash frames draw full bright
- [ ] The pistol's sound starts where vanilla's does
- [ ] Sim cases: one shot, held fire, the last bullet, a shot at a wall and at a ledge above, with the random index after each
- [ ] Render cases: the firing frames with the room lit and a puff on a wall, at zero differing pixels
- [ ] A closed law pins one bullet a shot and no shot at zero

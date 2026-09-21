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

## Comments

- The implementation follows Chocolate Doom 3.1.1's `P_CheckMeleeRange`, `A_TroopAttack`, `A_SargAttack`, `P_SpawnMissile`, `P_CheckMissileSpawn`, `P_XYMovement`, `P_ZMovement`, `PIT_CheckThing` and `P_ExplodeMissile`. The fireball uses the ordinary thing population and thinker order. Its thrower is filtered from the existing collision fold rather than handled by a second copy of that fold.
- A nushell replay of Chocolate Doom's random table gives 252 at index 60. It makes the claw deal `(252 % 8 + 1) * 3 = 15` and the bite deal `(252 % 10 + 1) * 4 = 12`. The following player pain check consumes index 61 in both direct cases.
- `tools/wad.nu` read Freedoom's `BAL1A0` header as width 15, left offset 8, top offset 11, and `BAL1C0` as width 34, left offset 17, top offset 21. `tests/load.bend` checks both headers and checks that state rows 196 and 198 are full bright.
- The unarmoured barrel replay was compared with Chocolate Doom under GDB at every tic from 64 through 74 and again at 94. The player, random index, projectile position, state and tics agree: tic 64 is random 186 and row 196/2 at `(927.402160, 1031.680648)`; tic 74 is random 192 and row 199/2 at `(933.918884, 1002.397048)`; tic 94 is random 195 with the projectile gone.
- That replay exposed a same-species collision error at tic 68. Vanilla advances from random 187 to 188 and bursts against another imp without damage. The old code damaged the imp, ran its pain roll and advanced to 190. The collision rule now bursts without damage against a non-player of the thrower's type.
- Freedoom pixel oracle, player `(992, 704, 270)`, script `20,0,0,0,0 34,0,0,0,1 10,0,0,0,0`: flight `differing 0`, `face 66`, `palette 0`, `shot_plain true`.
- Freedoom pixel oracle at the same place, script `20,0,0,0,0 34,0,0,0,1 20,0,0,0,0`: full-bright burst `differing 0`, `face 0`, `palette 2`, `shot_plain true`.
- Shareware pixel oracle, player `(1056, -3616, 90)`, record rewrite `8,3001,1056,-3360`, script `60,0,0,0,0`: visible fireball `differing 0`, `face 0`, `palette 0`, `shot_plain true`.
- The new simulation cases cover the direct claw and bite, launch, wall burst, horizontal sky removal, and the unarmoured live replay. The vertical sky branch uses the same removal path. Obsolete comments that described the imp and demon attack rows as absent were deleted.

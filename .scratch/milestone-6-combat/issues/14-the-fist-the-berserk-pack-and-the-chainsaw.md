# 14: The fist, the berserk pack and the chainsaw

**What to build:** The melee weapons. The fist punches at melee range and hits ten times harder after a berserk pack, which also brings the fist up. The chainsaw idles, revs, cuts without ammo, and pulls the player toward what it cuts. Key 1 chooses the chainsaw over the fist unless the player is berserk. Milestone 5's second declared gap closes.

**Blocked by:** 12 (Weapons switch and the shotgun fires), 13 (Bullets hurt things and barrels explode)

**Status:** resolved

- [x] `A_Punch` and `A_Saw` with their ranges, damage draws, the turn toward the target and the saw's pull
- [x] The berserk pickup sets the pending fist, as `P_TouchSpecialThing` does
- [x] The chainsaw's idle, full and hit sounds start where vanilla's do
- [x] Sim cases on Freedoom: a punch at a barrel with and without berserk, the saw on a barrel, key 1 under each ownership
- [x] Render cases: the fist and the saw at rest and attacking, at zero differing pixels

## Comments

The weapon rows are 215 through 229 and are reached through `Thing.fist()` and `Thing.saw()`. Ticket 18 retains rows 190 through 200. `Sim.melee.hit` implements `A_Punch` and `A_Saw`; the next `Sim.move` consumes the saw pull flag and substitutes Doom's forward command of 100.

The damage, three random draws, 64-unit punch range, 65-unit saw range, direct punch turn, gradual saw turn, sound choice and pull are from `p_pspr.c`'s `A_Punch` and `A_Saw`. The sim cases exercise a normal 4-point punch, a 40-point berserk punch, a 14-point saw hit, the next-tic pull, and a saw miss. The expected random indices follow Chocolate Doom's `m_random.c` table from the loaded map's starting index. The pickup and key-selection expectations follow `p_inter.c` and `p_user.c`. The empty-shotgun law now preserves vanilla's supported preference order: shotgun, loaded pistol, chainsaw, fist.

Freedoom and shareware were each compared at fist rest, fist attack, chainsaw rest and chainsaw attack. All eight reports had `differing 0`, palette 0 and the plain PLAYPAL. Freedoom used `-416 256 90`; shareware used `1056 -3616 90`. The chainsaw cases rewrote THINGS record 6 to type 2005 forty units ahead. The initial 944-pixel chainsaw report was the pickup message against Chocolate Doom's messages-off oracle configuration; after the shared frame tool made message visibility explicit, the weapon and world matched without a new mask.

The proof now splits ordinary command movement from the saw's one-tic override and proves both preserve a valid player position. Berserk pickup laws explicitly expect pending fist. No compatibility rows or duplicate melee path remain.

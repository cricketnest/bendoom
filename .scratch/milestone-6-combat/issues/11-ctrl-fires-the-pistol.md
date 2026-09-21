# 11: Ctrl fires the pistol

**What to build:** Ctrl fires. The pistol spends a bullet, plays its fire states and its flash, lights the room for the flash's tics, and hits by vanilla's hitscan: autoaim up and down at what stands ahead, the first shot accurate and held fire spread, a puff where a bullet meets a wall. It refuses to fire without ammo.

**Blocked by:** 01 (The tic command carries fire and weapon change), 02 (One traversal finds what a ray meets), 03 (Things move, relink and spawn in play), 07 (The pistol rises, bobs and shows); milestone 7's 01 (The sim reports its sounds)

**Status:** ready-for-human

- [x] `A_WeaponReady`'s fire check, `P_FireWeapon`, `A_FirePistol`, `A_ReFire` and the light actions, with the refire count; `A_GunFlash` and the attack-down flag are not here, see the Comments
- [x] `P_AimLineAttack` and `P_LineAttack` as visitors of the traversal, with vanilla's slopes and its retries to either side; no line in either map fires on a gunshot, so `P_ShootSpecialLine` is left out
- [x] The puff spawns with its random z and tics; every `P_Random` draw is made where vanilla makes it
- [x] The extra light reaches the renderer, and flash frames draw full bright
- [x] The pistol's sound starts where vanilla's does
- [x] Sim cases: one shot, held fire, the last bullet, a shot at a wall and at a ledge above, with the random index after each
- [ ] Render cases: the firing frames with the room lit and a puff on a wall, at zero differing pixels (one of the three is at zero after the merge; see Deferred)
- [x] A closed law pins one bullet a shot and no shot at zero

## Comments

### What was built

- `src/keys.bend`: `K.Cmd.attack`, `buttons .&. 1`, beside `K.Cmd.use`.
- `src/sound.bend`: sfx_pistol, number 1, lump DSPISTOL, priority 64 from `sounds.c`.
- `src/inventory.bend`: `Inventory.rounds` and `Inventory.spend`, which is `DecreaseAmmo` for a weapon whose ammo type is one of the four.
- `src/things.bend`: rows 61 to 66 are S_PISTOL1 to S_PISTOLFLASH and S_LIGHTDONE, rows 67 to 70 the puff's; `Thing.Weapon` gained `atk` and `flash`; `Thing.Def` gained the puff, whose DoomEd type is -1 so no record can name it; `Thing.null()` is S_NULL, which a thing entering removes itself on and a player sprite entering stops showing on. `Thing.Row` gained a `light` column and `Thing.tic` the vertical half of `P_MobjThinker` (`Thing.z`), since the puff rises a unit a tic on `P_SpawnPuff`'s momentum and is drawn where it stands. `MF_NOBLOCKMAP` is honoured in `Things.placed`, so the puff is in its sector's list and no blockmap cell, as `P_SetThingPosition` leaves it.
- `src/sim.bend`, "Firing": `Sim.Aim` and `Sim.aim.visit` are `PTR_AimTraverse`, `Sim.Shot` and `Sim.shot.visit` are `PTR_ShootTraverse`, both carrying in their own record what vanilla keeps in globals, plus the population and the player to read a mobj the ray met. `Sim.aim` is `P_AimLineAttack`, `Sim.bulletslope` `P_BulletSlope` with its two retries, `Sim.attack` `P_LineAttack`, `Sim.gunshot` `P_GunShot`, `Sim.puff` `P_SpawnPuff`. `Sim.Trace` is the divline the traversal walks, made once in `Sim.trace.of` and read by the shot to place what it leaves.
- `src/sim.bend`, "The player sprites": `Sim.psprite.set` is `P_SetPsprite` with the zero-tic loop, `Sim.psprite.tic` `P_MovePsprites` for one sprite, and `Sim.psprites` the pair, the weapon first so that a flash its action set is counted down in the same tic, as vanilla's loop does. The actions take the whole state; `Sim.psprites` and `Sim.psprites.start` take and return it. The think now runs the sprites after use, which is `P_PlayerThink`'s order.
- `src/project.bend`: `Project.lightnum` is the one place a sector's light becomes a light number, with the view's extra light added and the result held to 0 and 15. `P.View` carries that extra light, and `Segs.lightnum`, the planes, the sprites and `Render.light` all read it, so there is one addition and not four. `Planes.lightnum` is gone.

### Where the values came from

- `sfx_pistol` 1 and priority 64: `sounds.h`'s enum from `sfx_None` and `S_sfx` in `sounds.c`. MT_PUFF's rows, radius 20, height 16 and flags `MF_NOBLOCKMAP|MF_NOGRAVITY` (528): `info.c`. S_PISTOL1 to S_PISTOLFLASH and S_LIGHTDONE with their tics and actions, and the pistol's `weaponinfo` row: `info.c` and `d_items.c`. MISSILERANGE 2048 and the aim slopes ±40960: `p_local.h` and `P_AimLineAttack`.
- The tics of a shot are `p_pspr.c` by hand: A_WeaponReady fires on the tic the attack is seen, S_PISTOL1's 4 tics run out four tics later and A_FirePistol runs as S_PISTOL2 is entered; A_ReFire on S_PISTOL4 fires again 14 tics after that. The sim case's shots are on tics 25 and 39 of a press on tic 21.
- The draws are `P_GunShot`'s damage, its two spread draws when the shot is not the first of a press, `P_SpawnPuff`'s two for the z, `P_SpawnMobj`'s one and one for the tics: 5 for the first shot, 7 for a held one, 1 where the bullet meets the sky. From index 5, `m_random.c`'s table gives 149 for the damage (15), 107 and 75 for the z (half a unit over the eye at 36), 248 for the spawn and 254 for the tics (4 less 2, one of which the puff's own turn spends). The printed puff is at 37.5 in state 67 with 1 tic left, which is those numbers.
- The places are the WAD read in nushell: the start faces a one-sided wall at x 1328 and the puff stands 4 units back along the ray; from the pit at (704, 256), floor -128, line 585 steps up to a floor at 32, which the level shot meets at x 768; from the yard at (-640, 256), line 1049 has sector 40 behind it, whose ceiling is F_SKY1, so the sky hack leaves nothing and the shot draws once.
- Regression pins: P_Random's index at the start of each firing case (5 at tic 20), which is the light thinkers' draws, as the walks' indexes already are. The three new render hashes are pinned after the oracle read zero for each.

### The oracle

`nu tools/oracle.nu x y degrees script --frame`, the dump built from this tree, Freedoom.

Before combat integration, `masked` 665 in each, which was the pause graphic alone:

| case | place | script | differing |
| --- | --- | --- | --- |
| firing, the room lit by the flash | -416 256 0 | `20,0,0,0,0 1,0,0,0,2 4,0,0,0,0` | 0 |
| the flash over, the light out | -416 256 0 | `20,0,0,0,0 1,0,0,0,2 11,0,0,0,0` | 0 |
| the puff on the ledge out of the pit | 704 256 0 | `20,0,0,0,0 1,0,0,0,2 4,0,0,0,0` | 0 |
| rest, unchanged | -416 256 0 | `20,0,0,0,0` | 0 |

After the merge, with monsters in the map and all 200 rows compared, `masked` 1595:

| case | place | script | differing |
| --- | --- | --- | --- |
| firing, the room lit by the flash | -416 256 0 | `20,0,0,0,0 1,0,0,0,2 4,0,0,0,0` | 0 |

That case is a fidelity case with monsters on: the start room holds none on Hurt Me Plenty, and the five tics between the press and the frame are fewer than a monster woken by vanilla's `P_NoiseAlert` needs to reach the view. The other two were checkpoint measurements before combat integration; the final milestone oracle sweep supersedes them.

### What surprised me

- The native compiler refuses a program whose `Sim.turn` holds too much: "an arity over 255", where the JS lane builds the same program. A turn holds the state it began with, the one its thinker made and the one it hands back, and each word on the player costs three of a budget that was nearly spent. Three flat fields (refire, attackdown, extralight) broke the build; one did not. That is why the extra light is the flash sprite's row and not a field, why `attackdown` is gone, and why `State.held` takes the place as two numbers rather than the whole state it came from. `docs/bend.md` has the finding and the way to locate the offending segment.
- P_MovePsprites reaches the flash after the weapon's action has set it, so the flash shows 6 of S_PISTOLFLASH's 7 tics on the tic it is set.
- A thing under its own floor is lifted onto it by `P_ZMovement` before anything reaches it, which moved two closed laws' literal things onto floors of their own.

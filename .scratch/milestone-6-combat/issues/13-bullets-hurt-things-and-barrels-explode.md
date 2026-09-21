# 13: Bullets hurt things and barrels explode

**What to build:** Damage reaches things. A bullet that hits a shootable thing damages it, thrusts it, and leaves blood or a puff as vanilla decides. A barrel takes damage, explodes, hurts everything within its radius that it can see, the player included, and sets off other barrels. A shot barrel slides from the blow.

**Blocked by:** 09 (The nukage hurts and the player dies), 11 (Ctrl fires the pistol)

**Status:** resolved

- [x] `P_DamageMobj` and `P_KillMobj` for any shootable thing, with the thrust and the random death tics; a thing pushed by damage moves through the general movement
- [x] Blood and puffs spawn as `P_SpawnBlood` and `P_SpawnPuff` do
- [x] The barrel's death rows, `A_Explode`, and `P_RadiusAttack` with vanilla's blockmap box, distance measure and sight test
- [x] The explosion's credit passes to whoever shot the barrel
- [x] Sim cases: a barrel shot to death, a chain of two, the player hurt by one through armour, with health, places and the random index from a replay of the source
- [x] Render cases: a barrel mid-explosion and blood on a hit, at zero differing pixels

## Comments

### What was built

- `src/things.bend`: a thing's thirteenth field is one `V.Vec`, its mobj_t past the definition: health, target, reaction time, threshold, the horizontal momentum a blow gave it, the flags `P_KillMobj` and `A_Fall` clear bits of, the height a death quarters, and ticket 15's lastlook, which moved in from a field of its own at the merge. `Thing.fight(kind)` is the rest of `mobjinfo` for the types a blow reaches, read by kind and not kept in the definition, as ticket 15 reads the see state and the sight sound: spawn health, pain chance, the pain, death and gib rows, mass, and the pain and death sounds. Rows 121 to 183 are the four monsters' pain, death and gib rows, the barrel's `S_BEXP` chain and the blood's. `Thing.Action` gained `XScream`, `Fall` and `Explode`. `Thing.zmove` (vanilla's `P_ZMovement`, renamed so that `Thing.z` can be the accessor) gained gravity, which the blood needs, and reads the height and flags from the thing.
- `src/sim.bend`, "Damage": `Sim.damage(target, damage, inflictor, source, s)` is `P_DamageMobj` with vanilla's two branches, the player's and every other shootable thing's. The thing's branch is `Sim.damage.thing`: the shootable and health tests, `Sim.blow.thing` for the thrust with its fall-forwards draw, the health, then either `Sim.kill.thing` or `Sim.pain.thing` and `Sim.awake`. `Sim.kill.thing` is `P_KillMobj`: the flags a death clears and sets, the quartered height, the gib death where the blow went past the spawn health, and the death state's tics less `P_Random()&3`. `Sim.thrust.of(damage, mass)` is the one thrust both branches use, so the player's hard-coded `damage * 8192` is gone.
- `src/sim.bend`, "The radius attack": `Sim.blast(spot, source, damage, s)` is `P_RadiusAttack`, `Sim.blast.one` `PIT_RadiusAttack` with its longer-axis distance and ticket 15's `Sim.sight`, and `Sim.explode(th, s)` is `A_Explode`, credited to the thing's target. `Sim.rows` and `Sim.blast.box` walk the blockmap box row by row, the order `P_RadiusAttack`'s two loops take, where `P_CheckPosition` walks it column by column.
- `src/sim.bend`, "Firing": `Sim.blood` is `P_SpawnBlood`, and `Sim.shot.bled` now spawns it or the puff and then deals the damage, which is `PTR_ShootTraverse`'s order.
- `src/sim.bend`, the thinker: `Sim.thing.xy` is `P_XYMovement` for a thing, with `P_TryMove` against `Sim.check`, the blocked move that stops it dead, and the friction with its corpse clause; it runs before the vertical move, as `P_MobjThinker` does. `Sim.thing.acted` runs `A_Pain`, `A_Scream` with its sound groups, `A_XScream`, `A_Fall` and `A_Explode` as a state is entered.
- `src/sound.bend`: `dmpain` 26, `popain` 27, `slop` 31, `podth1` to `podth3` 59 to 61, `bgdth1` and `bgdth2` 62 and 63, `sgtdth` 64, `barexp` 82, with their lumps and priorities from `sounds.c`. `nix build .#sounds-freedoom` passes, so every lump exists in Freedoom at a rate the mixer takes.
- `src/gfx.bend`: the rows a type dies through are marked for the sprite load, so a corpse and the barrel's `BEXP` have lumps, and the blood's rows are loaded as the puff's are.

### Where the expected values came from

- `p_inter.c`'s `P_DamageMobj` and `P_KillMobj`, `p_map.c`'s `PIT_RadiusAttack` and `P_RadiusAttack`, `p_mobj.c`'s `P_SpawnBlood` and `P_XYMovement`, `p_enemy.c`'s `A_Pain`, `A_Scream`, `A_XScream`, `A_Fall` and `A_Explode`, and `info.c`'s rows for `MT_POSSESSED`, `MT_SHOTGUY`, `MT_TROOP`, `MT_SERGEANT`, `MT_BARREL` and `MT_BLOOD`, all read and worked by hand before the Bend code answered.
- The thrust is `damage*(FRACUNIT>>3)*100/mass`, which for a mass of 100 is `damage * 8192` and for the demon's 400 a quarter of it. `P_RadiusAttack`'s reach is `(damage+MAXRADIUS)<<FRACBITS`, and `MAXRADIUS` is already `32*FRACUNIT`, so on a 32-bit word the product wraps down to the damage in whole units; the same expression on a word that wraps gives the same reach, and the code keeps it rather than the number it comes to.
- The places are Freedoom's E1M1 read in nushell with `tools/wad.nu`: record 265 is the zombieman at (944, -224) in sector 57, records 24, 25 and 26 the barrels at (992, 608), (992, 640) and (960, 608) in sector 13.
- The blast the player takes is `PIT_RadiusAttack` by hand: 74.53 units from barrel 25 less the player's own radius of 16 is 58 whole units, so the blow is 128 less 58, and green armour saves a third of 70, which is 23; the sim case prints 77 armour and 53 health.
- Regression pins, and the ticket says so: the damage each shot deals, the tics each death state loses, and `P_Random`'s index at the start of each case. All are draws; the number of draws and the order they are made in are worked from the source and are not pins.

### Evidence

The integrated combat build was compared with Chocolate Doom 3.1.1 on 2026-09-21. Each report masks only the pause graphic and face (1595 pixels).

| case | place | script | differing |
| --- | --- | --- | --- |
| blood on a hit | 1024 -224 180 | `20,0,0,0,0 6,0,0,0,2` | 0 |
| one shot into a barrel | 992 704 270 | `20,0,0,0,0 6,0,0,0,2` | 0 |
| barrel mid-explosion | 992 704 270 | `20,0,0,0,0 21,0,0,0,2` | 0 |

All 20 rest poses and 33 firing, blood, barrel, movement and pickup frames return zero. Reports: `/tmp/m6-routes/rest-oracles.json` and `/tmp/m6-routes/combat-qa.json`.

### What surprised me

- `A_Explode` deals damage and damage enters a state, which would form a definition cycle Bend refuses. The runtime now passes the common state-entry function through hitscan, melee, missiles and radius damage, so every path runs the entry action immediately.
- The damage section had to move above the firing that calls it, which cost `P_DropWeapon` the general `P_SetPsprite` loop. Writing that one step out is exact, since the down state lasts a tic.
- A barrel's target is set only when it survives the hit, so a barrel killed outright by another barrel's blast credits its own kills to nobody, as vanilla's does.

### Pain and gib sprites restored, 2026-09-21

`Gfx.sprite.hurt` now follows the pain and gib entry chains as well as death. The earlier claim that extra lumps corrupt unrelated frames does not reproduce on the current tree: every existing render hash is unchanged, and all 20 rest/rotation oracle poses plus five movement, key and armour cases report `differing: 0`. No hash was regenerated.

The loader test reads all four monsters' pain entry headers and the three available gib entry headers. Expected widths and offsets came from Freedoom's POSSG1, POSSM0, SPOSG1, SPOSM0, TROOH1, TROON0 and SARGH1 headers read in nushell; the state-to-frame mapping is `info.c`.

The later combat integration also resolves the remaining blood/impact mismatch; the zero-frame results above supersede the loader-only checkpoint. The loader test retains seven independently read sprite headers.

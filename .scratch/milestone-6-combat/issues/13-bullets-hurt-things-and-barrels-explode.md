# 13: Bullets hurt things and barrels explode

**What to build:** Damage reaches things. A bullet that hits a shootable thing damages it, thrusts it, and leaves blood or a puff as vanilla decides. A barrel takes damage, explodes, hurts everything within its radius that it can see, the player included, and sets off other barrels. A shot barrel slides from the blow.

**Blocked by:** 09 (The nukage hurts and the player dies), 11 (Ctrl fires the pistol)

**Status:** ready-for-human

- [x] `P_DamageMobj` and `P_KillMobj` for any shootable thing, with the thrust and the random death tics; a thing pushed by damage moves through the general movement
- [x] Blood and puffs spawn as `P_SpawnBlood` and `P_SpawnPuff` do
- [x] The barrel's death rows, `A_Explode`, and `P_RadiusAttack` with vanilla's blockmap box, distance measure and sight test
- [x] The explosion's credit passes to whoever shot the barrel
- [x] Sim cases: a barrel shot to death, a chain of two, the player hurt by one through armour, with health, places and the random index from a replay of the source
- [ ] Render cases: a barrel mid-explosion and blood on a hit, at zero differing pixels

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

- `bend PROOF.bend`: `All terms check.`
- Every `tests/*.bend` passes native and on bun, before and after the merge of `milestone-6-7`.
- The oracle, `nu tools/oracle.nu x y degrees script --frame`, Freedoom, `masked` 1595 in every report, the frame dump built from this tree after the last merge of `milestone-6-7`, which carries the sight ticket, the sound pass, the width refactor, the face and the heads-up line:

| case | place | script | differing |
| --- | --- | --- | --- |
| the barrel room at rest | 992 704 270 | `20,0,0,0,0` | 0 |
| a stalagmite over a tree | 2752 960 0 | `20,0,0,0,0` | 0 |
| the bars, sprites behind masked textures | 1024 200 0 | `20,0,0,0,0` | 0 |
| ticket 11's firing frame, the room lit by the flash | -416 256 0 | `20,0,0,0,0 1,0,0,0,2 4,0,0,0,0` | 0 |
| one shot into a barrel | 992 704 270 | `20,0,0,0,0 6,0,0,0,2` | 573 |
| the barrel mid-explosion | 992 704 270 | `20,0,0,0,0 21,0,0,0,2` | 37596 |

### What is open

- **A shot that meets a thing is not at zero.** A shot into a wall is (ticket 11's frame, still 0), and the same place with the barrel replaced by a lamp, which a bullet flies past, is 0 too; put the barrel back and the tic of the shot differs by 104 pixels in one blob about the hit point, growing as the puff lives. The damage itself is not the cause: the random index after the shot is vanilla's count, and the barrel's slide is `P_XYMovement` to the unit. What ticket 11 never compared is the geometry of `PTR_AimTraverse` and `PTR_ShootTraverse` **at a mobj**, and that is where this sits. One real mismatch was found and fixed on the way: `P_BulletSlope` looks 1024 units for something to aim at (`16*64*FRACUNIT`), where this tree looked the bullet's whole 2048.
- **A frame past about twenty tics of a fight cannot be compared at all.** Vanilla's `P_NoiseAlert` wakes monsters when the pistol fires and `A_Chase` then draws, which this tree does not do yet (tickets 16 and 21), so the random streams part. The barrel mid-explosion frame is 37596 differing for that reason, and the whole status bar is among it, since a woken monster shoots the player. The frame is kept as a pin.
- **The pain frame and the gib frames are not loaded.** Marking them for the sprite load moves the pixels of six frames of the render test that read zero against vanilla today (`air`, `landed`, `key`, `green armour`, `chainsaw`, `dead`), and `2380 600 180` goes from its own state to 42 differing. Marking the death rows alone leaves every hash and every oracle frame where it was, so that is what ships: a corpse and the barrel's explosion draw, and a monster in its three to six pain tics and a gibbed one draw nothing. Something in `src/gfx.bend`'s loader is tipped over by the extra sprite lumps; finding it is its own ticket.
- `2380 600 180` at rest reads 25 differing on this branch and the same frame hash as `milestone-6-7`, so that divergence is the integration branch's, not this ticket's: ticket 15's monsters see the player there and vanilla's then chase.

### Deferred to the later pass

- The render cases: a barrel mid-explosion and blood on a hit at zero differing pixels. Both wait on the shot-at-a-thing geometry above and on the monsters' chase, without which no frame of a fight can be compared.
- The nushell replay of `m_random.c` that would turn the pinned damages and death tics into computed values.
- A closed law over the blast's distance measure or the thrust.
- `nix flake check`: the orchestrator runs it on the integration branch.

### What ticket 20 adds, and where

`Sim.kill.thing.at` is `P_KillMobj` for a thing; the drop goes at its end, after the death state is entered, and `H.Thing.spawn.mobj`'s `MF_DROPPED` flag goes into the spawned item's `Thing.Hurt.start`. The kill count goes in the same function and is the intermission's.

### What tickets 17 and 18 call

`Sim.damage(target, damage, inflictor, source, s) -> State`, where `target` is the mobj hurt, `H.Things.you(things)` for the player and a thing's id otherwise, and `inflictor` and `source` are ids with `H.Thing.you()` for nobody. A monster's bullet passes no inflictor and the monster as the source, as `P_LineAttack` does; a fireball passes itself and its shooter. A thing's target is `H.Thing.target(th)` and the thing it is after is written by `Sim.awake`, which ticket 16's `A_Chase` reads.

### What surprised me

- `P_SetMobjState` cannot be one function here. `A_Explode` deals damage and damage enters a state, so the two would be a circle Bend refuses. It is not one in practice either: no pain or death row of any type either map spawns carries an action on entry, so a blow's own setter runs none, and the thinker's general one runs them all.
- The damage section had to move above the firing that calls it, which cost `P_DropWeapon` the general `P_SetPsprite` loop. Writing that one step out is exact, since the down state lasts a tic.
- A barrel's target is set only when it survives the hit, so a barrel killed outright by another barrel's blast credits its own kills to nobody, as vanilla's does.

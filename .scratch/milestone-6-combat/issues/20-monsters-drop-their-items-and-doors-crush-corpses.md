# 20: Monsters drop their items and doors crush corpses

**What to build:** What a death leaves behind. A zombieman drops a clip and a shotgun guy a shotgun, each worth half a placed one's ammo. A door closing on a corpse crushes it into gibs, a living monster in a closing door sends it back up, and a dropped item under a mover is removed.

**Blocked by:** 19 (Monsters are hurt and die)

**Status:** ready-for-agent

- [x] The drop spawns with the dropped flag, and `P_GiveAmmo` and `P_GiveWeapon` halve for it
- [x] `PIT_ChangeSector`'s corpse, dropped-item and shootable branches; neither map has a crusher, so crushing damage has no caller and stays out
- [ ] Sim cases: a drop taken, a corpse gibbed by a door, a monster reopening a door, a dropped clip removed by the lift
- [x] A closed law pins the halved amounts
- [x] A render case shows the gibs pool at zero differing pixels

## Verification

`tests/drops.bend` checks death draws, both pickups, corpse dimensions,
dropped-item removal, placed-item preservation and a living obstruction.
`dropped_ammo` pins 5 bullets and 4 shells, compared with 10 and 8 for
placed items. `P_GiveWeapon` gives a dropped shotgun one full shell clip;
it does not use `P_GiveAmmo`'s zero-clip convention for a half clip.

The shared `tests/fixtures/combat.bend` scene keeps Freedoom record 265 as a
zombieman at 448,2088 and removes the other monsters. From 448,2048 facing
90, its script is `20,0,0,0,0 1,0,0,0,1 60,0,0,0,2 1,0,0,32,2 28,0,0,0,2 250,0,0,0,0`.
At tic 360 Chocolate Doom has S_GIBS, zero height and radius, no dropped
clip, and random index 136. The full frame differs by zero pixels.
`tests/render.bend` keeps that frame. The ordinary 311-tic door fight also
matches every recorded player/monster position, health, random index and
door height, and its final frame differs by zero pixels.

Full integration checks and the explicit living-monster door-reopening
case remain before closure.

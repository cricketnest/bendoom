# 20: Monsters drop their items and doors crush corpses

**What to build:** What a death leaves behind. A zombieman drops a clip and a shotgun guy a shotgun, each worth half a placed one's ammo. A door closing on a corpse crushes it into gibs, a living monster in a closing door sends it back up, and a dropped item under a mover is removed.

**Blocked by:** 19 (Monsters are hurt and die)

**Status:** ready-for-agent

- [ ] The drop spawns with the dropped flag, and `P_GiveAmmo` and `P_GiveWeapon` halve for it
- [ ] `PIT_ChangeSector`'s corpse, dropped-item and shootable branches; neither map has a crusher, so crushing damage has no caller and stays out
- [ ] Sim cases: a drop taken, a corpse gibbed by a door, a monster reopening a door, a dropped clip removed by the lift
- [ ] A closed law pins the halved amounts
- [ ] A render case shows the gibs pool at zero differing pixels

# 09: Solid things join collision and movers

**What to build:** Solid map things become real obstacles. The player cannot overlap barrels or solid scenery, but can cross corpses, gore and non-solid decorations. Moving floors carry things standing on them and moving ceilings re-clip the active population through the same height rules as the player. Damage and explosions remain absent.

**Blocked by:** 06 (The blue key opens its door)

**Status:** ready-for-agent

- [ ] Position checking examines nearby things through the blockmap before it examines lines
- [ ] Two radii and intersecting vertical ranges decide a solid collision as vanilla does
- [ ] Solid decorations and barrels stop the move; non-solid scenery and pickups do not
- [ ] A thing standing on a moving floor follows it and retains its stable identity and state
- [ ] A moving ceiling updates thing floor and ceiling bounds and reports a blocked move when an undamageable solid thing no longer fits
- [ ] Crushing damage and barrel explosions are not introduced
- [ ] The player's completed tic is free of every active solid thing, stated and filled as a law
- [ ] Sim tests cover a blocked decoration, a passable corpse, a carried thing and a blocked mover on both lanes
- [ ] Existing line collision, re-clip and mover timelines stay green


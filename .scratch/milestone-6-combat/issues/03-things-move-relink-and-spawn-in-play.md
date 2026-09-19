# 03: Things move, relink and spawn in play

**What to build:** A prefactor for everything that moves. The position check serves any mover: it takes the mover's radius, height and flags, and tests heights against things where vanilla does for a missile. A thing that moves unlinks from its blockmap cell and sector list and links into the new ones, newest first. Things spawned during play get identities past the map's records and never reuse one. All thinkers run in one list in vanilla's order: map things in lump order, then the specials' thinkers, then whatever play spawns.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The player's moves and pickups run on the general check with unchanged outputs
- [ ] Moving a thing updates its blockmap link and its sector's list as `P_UnsetThingPosition` and `P_SetThingPosition` do; milestone 5's assumption that links are written once at spawn is removed with the code that relied on it
- [ ] The renderer's sprite order for a sector follows the sector list's real order
- [ ] A spawned thing takes the next identity past the records; a removed identity is never reused; scripted output names the same thing before and after
- [ ] The thinker order is one list, and a thing spawned in a tic first thinks where vanilla's would
- [ ] Literal-state cases move a thing across a cell border and a sector border and spawn one mid-tic, with expected links worked from the source
- [ ] The freedom law and replay composition still check; the geometry law is restated if links leave the geometry

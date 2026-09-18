# 06: The blue key opens its door

**What to build:** The first complete pickup path. The player starts with vanilla's initial inventory, walks into the blue key, receives the card on that tic, and removes the key from the active population. The existing locked door refuses before collection and opens afterward. Position checking returns the changed state explicitly, including vanilla's rule that a pickup touched before a later line rejection stays collected.

**Blocked by:** 02 (The non-monster population spawns)

**Status:** ready-for-agent

- [ ] Player state gains health, armour, cards, ammo and caps, backpack, weapon ownership, powers, item count and pickup-flash count with vanilla start values
- [ ] XY and vertical reach tests decide whether the player touches the key
- [ ] A successful touch grants the blue card and removes only that stable thing identity on the same tic
- [ ] A repeated touch cannot grant or remove anything again
- [ ] The blue locked door refuses before the pickup and moves after it; either blue card or blue skull satisfies it
- [ ] Position checking carries pickup changes through a move later rejected by a line when vanilla does
- [ ] Replay composition holds over inventory and the active population
- [ ] A Freedoom script prints the key's removal, card state and door heights before and after collection on both lanes
- [ ] Render and oracle frames immediately before and after contact show the key present and absent
- [ ] Existing mover, route and wall laws stay green


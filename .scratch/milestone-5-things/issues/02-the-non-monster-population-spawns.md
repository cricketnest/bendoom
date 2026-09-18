# 02: The non-monster population spawns

**What to build:** Both E1M1 THINGS lumps become their complete milestone 5 populations. Hurt Me Plenty options decide what spawns. Decorations, corpses, barrels and every world item in scope get vanilla definitions and stable map identities. Monsters, other player starts, deathmatch starts, teleport destinations and multiplayer-only records stay out. Restart rebuilds the same population from the loaded map.

**Blocked by:** 01 (One decoration reaches the frame)

**Status:** ready-for-agent

- [ ] A nushell inventory of both maps records every DoomEd type and option combination before the Bend tables are written
- [ ] Every non-monster type used by either E1M1 has the spawn state, radius, height and flags needed by this milestone
- [ ] Hurt Me Plenty and multiplayer filtering matches vanilla's map-thing rules
- [ ] Floor and ceiling spawns use the sector heights under the thing
- [ ] Active things keep stable THINGS-record identities when another thing is later removed
- [ ] Restart reconstructs the original population and resets every thing's state
- [ ] Monsters and mode-only starts do not appear as inert sprites
- [ ] A boundary test prints counts by kind and selected records for Freedoom; the shareware counts are recorded outside the flake
- [ ] Both lanes pass; existing movement and render cases remain green


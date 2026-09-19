# 08: Monsters stand where the map puts them

**What to build:** The zombiemen, shotgun guys, imps and demons of the two E1M1s spawn on Hurt Me Plenty and stand in their idle frames, solid and shootable, facing as their records say, drawn with their rotated and mirrored sprites. They do nothing else yet. The oracle turns monsters on for good.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The thing tables gain the four types' definitions and idle rows; the counts per type match a nushell census of both WADs (Freedoom: 4 zombiemen, 10 shotgun guys, 10 imps, 5 demons; shareware: 4 zombiemen, 2 imps)
- [ ] Spawning draws from the random table where `P_SpawnMapThing` does, so the index after spawn matches a nushell replay with monsters on
- [ ] The ambush flag is kept from the record's options
- [ ] Monsters stop the player and movers as solid shootable things do
- [ ] Render cases show a monster from the front, the side and behind and a mirrored rotation, at zero differing pixels, from places where no monster can see the player
- [ ] The oracle's demo header turns monsters on; every rest position stays at zero or moves to a place the ticket justifies
- [ ] Oracle cases in later tickets hold only while no unported behaviour happens in them, and each ticket says which of its cases those are

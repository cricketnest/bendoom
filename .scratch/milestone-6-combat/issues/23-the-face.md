# 23: The face

**What to build:** The marine's face on the status bar, as `ST_updateFaceWidget` decides it: the health level, the idle glance, the wince toward the side damage came from, the ouch face, the grin at a new weapon, the grimace while fire is held, and dead. The glance is chosen by vanilla's second random index, which advances once a tic here and once for each audible sound start.

**Blocked by:** 04 (The status bar shows the inventory), 09 (The nukage hurts and the player dies), 12 (Weapons switch and the shotgun fires), 17 (Zombiemen and shotgun guys shoot); milestone 7's 01 (The sim reports its sounds)

**Status:** ready-for-agent

- [ ] Every priority of `ST_updateFaceWidget` that the two maps can reach, with its count, including vanilla's ouch-face bug as it stands
- [ ] The second random index starts at 64 and counts as milestone 7's ticket 01 left it; that ticket found that under `-playdemo` one or two tics run before the melt's draws, so check from the source which table entries `ST_Ticker`'s first draws read
- [ ] The face's state is in the sim's state and advances once a tic, so that replay composition holds
- [ ] The sim test prints the face index per tic on cases of damage from each side, a weapon pickup, held fire, and idling, against a nushell replay of `st_stuff.c` over the second random index
- [ ] Chocolate Doom's face keeps changing under the oracle's pause, so the oracle keeps its mask over the face's box except for the dead face, which holds and compares at zero
- [ ] Render cases compare the face's pixels with its patches read from the WAD in nushell
- [ ] A closed law pins the pain offset at each health level's edge

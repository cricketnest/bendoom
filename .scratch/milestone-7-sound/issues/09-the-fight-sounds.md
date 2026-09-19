# 09: The fight sounds

**What to build:** Milestone 6's combat is heard and checked end to end. Its tickets start their sounds inline; this ticket checks the whole: the fight cases print their sounds against vanilla's source, and a recorded fight compares with Chocolate Doom's.

**Blocked by:** 07 (The game sounds); milestone 6's 14 (The fist, the berserk pack and the chainsaw), 20 (Monsters drop their items and doors crush corpses), 21 (Gunfire wakes monsters), 22 (Monsters fight each other and leave the dead alone)

**Status:** ready-for-agent

- [ ] Every sound vanilla starts in the scripted fights is in the sound table with its priority, and none it cannot start
- [ ] The fight cases' sound lines agree with a nushell replay of vanilla's source: weapon, sight, active, attack, pain, death, gib, fireball, barrel, player pain and death
- [ ] The chainsaw's idle and the fireball's flight stop and restart as vanilla's do
- [ ] Ticket 01 left one gap: a line crossed in the first half of a split move is heard from where the whole move ended, so its volume can be off by one; with moves split for fast monsters and missiles, check it against vanilla here and fix it at its cause if a case shows it
- [ ] A recorded fight on Freedoom compares at the target of zero with the sounds placed at their recorded starts
- [ ] The second random index at each fight case's end agrees with the replay, so milestone 6's face glances as vanilla's

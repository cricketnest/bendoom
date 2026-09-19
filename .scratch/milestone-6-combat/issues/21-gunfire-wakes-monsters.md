# 21: Gunfire wakes monsters

**What to build:** A gunshot's noise wakes the monsters it reaches. The noise floods sectors through open two-sided lines, passes one sound-blocking line and stops at the second, and marks each sector with the player as its sound target. A sleeping monster hears it on its next look. An ambush monster hears and still waits until it sees.

**Blocked by:** 11 (Ctrl fires the pistol), 16 (A woken monster chases)

**Status:** ready-for-agent

- [ ] `P_NoiseAlert` and `P_RecursiveSound` with the line openings as they stand on that tic, closed doors included
- [ ] `A_Look`'s sound-target branch and the ambush rule
- [ ] Every weapon's fire alerts as vanilla's does; the fist and the saw as vanilla decides
- [ ] Sim cases: a shot that wakes the next room, one stopped by a closed door, one past sound-blocking lines, an ambush monster that stays asleep, from a replay of the source over the WAD's lines

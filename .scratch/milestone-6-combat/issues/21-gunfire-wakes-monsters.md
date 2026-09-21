# 21: Gunfire wakes monsters

**What to build:** A gunshot's noise wakes the monsters it reaches. The noise floods sectors through open two-sided lines, passes one sound-blocking line and stops at the second, and marks each sector with the player as its sound target. A sleeping monster hears it on its next look. An ambush monster hears and still waits until it sees.

**Blocked by:** 11 (Ctrl fires the pistol), 16 (A woken monster chases)

**Status:** ready-for-agent

- [x] `P_NoiseAlert` and `P_RecursiveSound` with the line openings as they stand on that tic, closed doors included
- [x] `A_Look`'s sound-target branch and the ambush rule
- [x] Every weapon's fire alerts as vanilla's does; the fist and the saw as vanilla decides
- [x] Sim cases: a shot that wakes the next room, one stopped by a closed door, one past sound-blocking lines, an ambush monster that stays asleep, from a replay of the source over the WAD's lines

## Verification

An independent Nushell flood over Freedoom's WAD lines reaches 38 sectors
from start sector 140. Opening sector 100 to height 128 reaches 82.
Sound targets persist when that door closes. Records 176 and 177 hear
player 157 but remain in ambush; record 265 acquires that target only
with the door open. A three-room corridor passes one sound-blocking line
and stops at the second. `tests/noise.bend` checks all nine results.

The alert runs after the weapon attack state's actions, matching
`P_FireWeapon`'s call after `P_SetPsprite`. The zombie fight at 1024,-224
facing 180 matches Chocolate Doom at tics 26,40,54,68,98, including health,
positions and random draws. All five frames and the dropped-clip pickup
frame differ by zero pixels. Shotgun, fist and saw use the same post-action alert in `Sim.psprite.alert`; their implemented attack and oracle cases are recorded in tickets 12 and 14.

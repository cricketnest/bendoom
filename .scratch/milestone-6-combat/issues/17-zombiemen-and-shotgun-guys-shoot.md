# 17: Zombiemen and shotgun guys shoot

**What to build:** The former humans attack. A chasing zombieman or shotgun guy decides to fire by vanilla's missile range check, faces the player, and shoots hitscan with vanilla's spread and damage, one bullet or three.

**Blocked by:** 02 (One traversal finds what a ray meets), 09 (The nukage hurts and the player dies), 16 (A woken monster chases)

**Status:** ready-for-agent

- [x] `A_Chase`'s attack half, `P_CheckMissileRange`, `A_PosAttack` and `A_SPosAttack`, with reaction time and the just-attacked flag
- [x] The player takes the damage through armour, and the attacker is recorded
- [x] Their attack sounds start where vanilla's do
- [x] Sim cases on Freedoom: each type's first shot at the player, hit and miss, with tics, health and the random index from a replay of the source
- [x] Render cases: each type mid-attack at zero differing pixels

## Comments

### Independent shooting trace

On 21 Sep 2026, the existing 70-tic zombieman and shotgun-guy cases were
replayed in Chocolate Doom 3.1.1 through GDB. Every tic agrees with the
sim test on x/y, facing, move direction, remaining animation tics, player
health and the gameplay random index. Facing is compared using the same
printed precision, the upper sixteen angle bits expressed in degrees.

| case | player starts | first shot tic | damage that lands | health after | random after |
| --- | --- | --- | --- | --- | --- |
| zombieman 177 | 488,256 facing 0 | 53 | none; its 3-damage bullet misses | 100 | 87 |
| shotgun guy 96 | 144,1888 facing 0 | 61 | all three pellets, 12 + 6 + 9 | 73 | 127 |

The first attack enters on tic 43 for the zombieman and 51 for the
shotgun guy. Breakpoints in `A_PosAttack`, `A_SPosAttack`,
`P_LineAttack` and `P_DamageMobj` capture the actual shot and each
pellet, so these are now externally verified values. The attack trace's
`leveltime` is one less during the thinker than the completed tic that
`P_Ticker` and the Bend test print. Source definitions are in
`p_enemy.c`, `p_map.c`, `p_inter.c`, `info.c` and `sounds.c`.
Traces, demos and GDB commands are in `/tmp/verify-shots/{room,corner}/`;
`comparison.json` records zero differences across all 140 tics.

### Attack frames and the Freedoom patch

The same poses were compared at zombieman tics 43 and 53, and shotgun-guy
tics 51 and 61. All four now have zero differing pixels outside the pause
and live-face masks. The two firing frames are retained in
`tests/render.bend`; all earlier hashes stay unchanged.

The zombieman firing frame initially differed in 380 pixels. Freedoom's
`DEHACKED` lump changes frame 185's sprite subnumber to 32773, setting
its full-bright bit. Vanilla's `info.c` has subnumber 5 there, which is
still correct for shareware. The graphics loader now reads that override
from the WAD and applies it to all eight views; it does not change the
shared monster state table. This is the only patched firing frame
reachable in these two E1M1s. The other patched firing states belong to
monsters absent from both maps.

The new loader check failed with brightness 0 before the fix and reads 1
for Freedoom afterward. Shareware still reads 0. The fixed firing oracle
returns zero, and the load and render tests match their expected output
on the JavaScript lane. Native checks and the final integrated matrix
remain before closure. Reports: `/tmp/verify-shots/frames.json` and
`/tmp/verify-shots/zombie-fixed.json`.

# 06: The exit leads to the intermission

**What to build:** The exit switch leads to vanilla's intermission. The level counts the player's kills, items and secrets against totals taken at spawn, and a secret sector counts once when entered. The intermission is a second game mode: the background, the finished level's name, the three percentages counted up at vanilla's pace, time and par, then the screen naming the next level. A press finishes the counting and the next goes on. Afterwards a fresh E1M1 starts, where vanilla would load E1M2.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Totals count the things flagged as kills and as items at spawn, and the sectors with special 9; special 9 counts on entry and clears itself
- [x] The kill count exists here and stays 0 until milestone 6's ticket 19 raises it
- [x] The tally follows `WI_updateStats` and `WI_drawStats` for one player, with all graphics from the WAD
- [x] Space or Enter accelerates as vanilla's attack and use do, and the last press builds a fresh state from the map as loaded
- [x] The printed level time and the held last frame are deleted
- [x] The oracle compares the settled tally, with the animated background patches masked, since they advance during its pause; target zero
- [x] A test prints the counts and the intermission's state per tic for a scripted exit, with expected tics read from `wi_stuff.c`
- [x] The route tests still reach the exit

## Comments

**Where the expected values came from.** wi_stuff.c for every tic and
place: WI_initStats' sp_state 1 with cnt_pause of TICRATE, the three
percentages two a tic from -1, the time and the par three a tic, the
four pauses of 35 tics, the press that jumps to sp_state 10 and the one
that leaves for WI_initShowNextLoc's four seconds, then
WI_initNoState's ten tics before G_WorldDone; WI_drawStats' SP_STATSX
50, SP_STATSY 50, SP_TIMEX 16, SP_TIMEY 168, the line height of three
halves of a digit's, and WI_drawNum's, WI_drawPercent's and
WI_drawTime's own arithmetic; epsd0animinfo's ten places with their
period of TICRATE/3 and three frames; lnodes[0][0] and [0][1] for the
splat and the pointer. g_game.c for what G_DoCompleted hands over
(killcount, itemcount, secretcount, totalkills, totalitems,
totalsecret, leveltime) and for E1M1's par, pars[1][1], 30 seconds.
p_mobj.c for MF_COUNTKILL (4194304) and MF_COUNTITEM (8388608) counted
at P_SpawnMapThing, p_spec.c for special 9 counted at P_SpawnSpecials
and cleared in P_PlayerInSpecialSector. Freedoom's own numbers come
from its WAD read in nushell: 49 things flagged MF_COUNTITEM spawn on
Hurt Me Plenty (30 of type 2014, 18 of 2015, the berserk pack), and
sectors 52, 86, 128 and 132 carry special 9.

**The oracle.** `tools/oracle.nu --tally` compares the settled tally
over all 200 rows. It writes no pause tic: the pause's buttons byte,
0x81, carries BT_ATTACK, which WI_checkForAccelerate reads as a press,
and vanilla would leave the counts for the next level's screen and then
load E1M2. It needs none, since a settled tally stands still until a
press; a shot counts once it shows "Finished!" where WI_drawLF puts it,
and only the ten animation boxes are masked (in Freedoom they are 1 by
1 dummies, so the mask is 10 pixels).

    tools/oracle.nu -224 1340 90 "5,0,0,0,0 1,0,0,0,1 1,0,0,96,0 12,25,0,0,0 1,0,0,224,0 20,25,0,0,0 10,0,0,0,0 1,0,0,0,1 250,0,0,0,0" --tally
    => differing 20, masked 10

The 20 are the whole difference and all lie on row 199 at x 0 to 38:
they are -devparm's timing dots, which I_FinishUpdate writes into the
last row and which no comparison of 168 rows ever saw. Ticket 04 drops
-devparm from the oracle; after that merge the same case reports
differing 0.

**What was built.** `src/inter.bend`: wi_stuff.c's intermission as a
value (`Inter`) stepped by `Inter.tic(down, wi)`, drawn by
`Inter.frame`, and `Play`, the game's two modes, Doom's GS_LEVEL and
GS_INTERMISSION, with `Play.tic` running the level's tic, then the
tally's, and building a fresh state from the map as loaded where
G_DoWorldDone loads the next level. `src/gfx.bend` caches the patches
WI_loadData caches, by name, in the same array as the flats, textures
and sprites; `Gfx.patch` gives one's index, and `Inter.patch` is
V_DrawPatch over `Draw.post`, a straight copy with no colormap and no
scale. The sim counts: `Inventory` holds the kill and secret counts
beside the item count it already had, `State` holds the secret sectors
left to count (Doom clears the sector's special, which is geometry
here), `Sim.secret` is P_PlayerInSpecialSector's case 9, and
`Sim.tally` is what G_DoCompleted hands the intermission, with the
totals counted by `Thing.totals` from the flags of the things the map
spawns.

**What was deleted.** `Game.time` and the time printed to the terminal
at the exit; `Game.ended`'s print; `Game.from` and the frame-level
press edge (`was`) it needed, since the restart now happens inside the
play on the tic G_WorldDone runs; the held last frame, since the game
draws the tally instead of redrawing an ended level.

**Trade-offs.** Doom keeps attackdown and usedown apart and takes a
press from either; here one press stands for both, so pressing attack
while use is held does not count twice. The player taken through the
move is the one P_PlayerThink left after the secret, not after the use:
vanilla's use changes no player field, and keeping that shape kept the
freedom law's proof to one new lemma (`secret_free`). WIMINUS is not
cached: no count here is negative.

**What surprised me.** The compiler refuses a term past some size with
"an arity over 255", and tests/route.bend was already near it: with the
tally's chain added, any consumer of the play's state after the
twenty-one legs went over. The route test now ends at the tally's own
line, "level tic 1", and what the restarted level holds (the door shut,
the switch's special back, all 180 records alive) is tests/game.bend's
line, whose chain is short. Freedoom's WIA*, WIURH* and WISPLAT lumps
are 1 by 1 dummies of 13 bytes, so its intermission animates nothing.

**For later tickets.** Milestone 6's ticket 19 raises the kill count
through `I.Inventory.kills`, beside the item count, when P_KillMobj
credits the player; the totals already count monsters by
MF_COUNTKILL, so they become right the tic ticket 08's monsters spawn.
Milestone 7's ticket 10 starts the tally's sounds where
`Inter.stats.sp` counts: sfx_pistol on every fourth bcnt while a count
climbs, sfx_barexp when one settles or a press shows them all, and
sfx_sgcock on the press that leaves for the next level's screen. The
intermission takes M_Random's index from the state the level ended
with and draws ten times in WI_initAnimatedBack at its start and ten
more when that screen begins; it hands the index back to nobody, since
the level it starts again is built fresh, with its own index at 64.

# 15: A monster sees the player

**What to build:** A monster notices the player by sight. `A_Look` tests the player within the monster's field of view and its line of sight, which reads the REJECT lump first and then walks the BSP with vanilla's slopes. A monster that sees the player makes its sight sound, chosen by a random draw among its variants, and enters its chase state on vanilla's tic. It does not move yet.

**Blocked by:** 08 (Monsters stand where the map puts them); milestone 7's 01 (The sim reports its sounds)

**Status:** ready-for-human

- [x] The loader keeps REJECT; `P_CheckSight` follows `P_CrossBSPNode` and `P_CrossSubsector`
- [x] `A_Look` and `P_LookForPlayers` for one player: the field of view, the close-range exception, and the ambush flag's effect on sight
- [x] The sight sound's draw is a `P_Random` draw made whether or not anything plays it
- [x] Sim cases: a monster woken from the front, one approached from behind, one behind a wall, one behind a window, with the wake tic and the random index from a replay of the source
- [x] Ticket 08 turned the idle rows 61 to 68 into rows whose action is `Null{}`; they become `Look{}` here, with the mobj action dispatch, and `H.Thing.ambush(level, id)` gives the ambush flag
- [ ] Ticket 08 left ten oracle frames as regression pins because vanilla's monsters wake there and Bendoom's could not (air, landed, blink dark, key 22 and 23, key before and after, green armour before and after, chainsaw after); each one whose script ends before a woken monster moves returns to zero here, and the ticket lists which still wait for the chase
- [x] A sight test over sector pairs prints results that agree with REJECT read in nushell where REJECT decides

## Comments

### What was built

- `src/level.bend` keeps REJECT. `Level.rejected(level, s1, s2)` is the test at the head of `P_CheckSight`: the bit for row `s1` and column `s2` of a square of `nsectors`. The lump is read a byte at a time, because its length is `ceil(nsectors^2 / 8)` and Freedoom's E1M1 makes that odd (182 sectors, 4141 bytes), so a loader that read it as whole words would lose the last byte and with it the four pairs from (181, 178) to (181, 181), three of which are set.
- `src/sim.bend` gains a Sight section. `Sim.sight(level, m, t)` is `P_CheckSight` over two `Sim.Body` values: REJECT first, then `P_CrossBSPNode` as a stack of nodes left to cross rather than a recursion, the near child of each node before the far one, and `P_CrossSubsector` on each leaf. `Sim.sight.side` is `P_DivlineSide`, with its whole-unit products and the horizontal case that compares the point's x with the line's y where it means its y. The slopes are `Sim.Sight{top, bottom, open}`, narrowed at every opening the trace crosses.
- `Sim.look` is `A_Look` and `P_LookForPlayers(actor, false)` for the one player in the game: the player has to be in sight, and then either inside the half turn the monster faces or within `MELEERANGE`, 64 units, which excuses the rest. A monster that sees the player sounds its sight call and enters its chase state.
- `Sim.thing.act`, `Sim.thing.entered` and `Sim.thing.set` are the mobj action dispatch and `P_SetMobjState`: a state is entered for its tics and the state's action runs, which may set another. `Sim.thing.step` is `P_MobjThinker`'s state half around it. `H.Thing.tic` and `H.Thing.tic.step` are gone; `H.Thing.lasting`, `H.Thing.over`, `H.Thing.spent` and `H.Thing.entering` are what is left of them.
- The idle rows 61 to 68 run `Look{}`, and the 32 run rows, 79 to 110 after ticket 09's rows, run `Chase{}`, which stands still until ticket 16.
- `src/sound.bend` gains the six sight calls, `sfx_posit1` to `sfx_sgtsit`, numbers 36 to 41, lump `DS` and the name, priority 98, all from `sounds.c`.

### Where each expected value came from

- Vanilla's source, Chocolate Doom 3.1.1: `p_enemy.c`'s `A_Look` and `P_LookForPlayers`, `p_sight.c`'s `P_CheckSight`, `P_CrossBSPNode`, `P_CrossSubsector`, `P_DivlineSide` and `P_InterceptVector2`, `p_mobj.c`'s `P_SetMobjState` and `P_SpawnMobj`, `info.c`'s seestate, seesound and run rows for the four types, `sounds.h` and `sounds.c` for the numbers and the table rows.
- A scratch nushell replay of `P_SpawnMapThing`, `P_CheckSight`, `P_LookForPlayers`, `A_Look` and `T_LightFlash` over the WAD, `m_random.c` and `tables.c`. It answers 56 for the random index after Freedoom's spawn, which is ticket 08's own independently derived number, and it says record 177's zombieman sees (488, 256) and not (488, 320), which is the fact ticket 08 used to move the render test's pit case. Both were derived before this code answered.
- The six sighting cases, each the replay's prediction and then the Bend output, agreeing line for line:

| case | place | monsters | wake tic | sound | random after |
| --- | --- | --- | --- | --- | --- |
| front and deaf | 48, 1616 facing 180 | demon 92 (deaf) | 7 | DSSGTSIT | 64 |
| behind | 368, 1632 facing 0 | shotgun guy 90 (deaf), 80 units behind it | never in 30 tics | | 65 |
| behind in reach | 368, 1600 facing 0 | the same, 48 units behind it | 10 | DSPOSIT3 | 65 |
| through the wall | 144, 1888 facing 0 | shotgun guy 96 | 6 | DSPOSIT2 | 70 |
| over the pit | 488, 256 facing 0 | zombieman 177 | 15 | DSPOSIT3 | 69 |
| off the pit | 488, 320 facing 0 | the same | never in 20 tics | | 65 |

- The hand-worked case the BSP walk decides is the pit's ledge. Monster 177 and the player both stand in sector 17, floor -128, so `sightzstart` is `(-128 + 56 - 14) * 65536`, -5636096; the top slope is `14 * 65536` and the bottom `-42 * 65536`. To (488, 256) the trace crosses no opening. To (488, 320) it crosses line 553, floor -128 in front and 32 behind, both ceilings 128, at fraction 25368: the floors differ, so the bottom slope becomes `FixedDiv(32 * 65536 + 5636096, 25368)`, 19978167, which is over the top slope, and the sight closes.
- REJECT's ten sector pairs in the test were read from the lump in nushell before the Bend code answered: (5, 66), (181, 178), (181, 179) and (181, 180) set, the other six clear.

### Laws

- `divline_sides` is closed: `P_DivlineSide`'s three answers on a vertical line, a horizontal one (including the case that compares the point's x with the line's y) and a diagonal.
- `rejected_never_sees` is the property over all inputs: for any level and any two mobjs, a pair REJECT rules out never sees.
- `monsters_wake` says every type that calls out on sight stands in a row that runs `A_Look` and chases in a row of the table that runs `A_Chase`.
- `lasting_stays` was restated: it spoke of `H.Thing.tic`, which is gone, and now says that `Sim.thing.step` leaves the state where it found it for a thing of -1 tics, for every thing, name and state.
- `states_exist` covers the 32 new rows unchanged.

### The ten pinned oracle frames

Every one of them was rerun, and **none returns to zero**. The reason is in `P_SetMobjState`: it runs the state's action on entry, so vanilla's `A_Chase` runs on the very tic `A_Look` sets the chase state. That first `A_Chase` snaps the monster's angle to a multiple of 45 degrees and turns it, calls `P_NewChaseDir` and `P_Move`, and draws a `P_Random` for the active sound. So a frame is a fidelity case only up to the tic before the first monster wakes in it, and all ten have a monster waking inside their script. All ten still wait for ticket 16. Their counts fell by a third to a half, which is the waking itself now matching:

| case | place | script | before | now |
| --- | --- | --- | --- | --- |
| air | -416 256 0 | `56,50,0,0,0` | 148 | 109 |
| landed | -416 256 0 | `66,50,0,0,0` | 773 | 443 |
| blink dark | 640 712 180 | `66,0,0,0,0` | 41680 | 42058 |
| key 22 | 2380 600 180 | `22,0,0,0,0` | 43 | 22 |
| key bright 23 | 2380 600 180 | `23,0,0,0,0` | 43 | 22 |
| key before | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 18 | 12 |
| key after | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 67 | 41 |
| green armour before | 1631 1008 90 | `20,0,0,0,0 11,25,0,0,0` | 541 | 360 |
| green armour after | 1631 1008 90 | `20,0,0,0,0 12,25,0,0,0` | 607 | 407 |
| chainsaw after | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 575 | 379 |

Five frames that were at zero were rerun and are still at zero: the start, the demon head on, the pit, the shotgun guy from behind and the stride. Every other comparable frame's hash is unchanged, so its pixels are the ones the oracle already called right.

### Trade-offs

- **`MF_AMBUSH` changes nothing about sight.** `A_Look` reads the sector's sound target first and only gates *that* branch on the flag; `P_LookForPlayers` never sees it. So a deaf monster and a hearing one wake by sight alike, which is what the front-and-deaf case shows with the deaf demon of record 92. The flag's only effect arrives with ticket 21.
- **Vanilla's `validcount` over the lines is not here.** It is an economy, not a rule: the narrowing takes the higher floor and the lower ceiling whichever side is called the front, so a line answered twice gives the same answer twice. Keeping a seen list would cost more than it saves.
- **`P_CheckSight` is called once where vanilla calls it up to three times.** With one player in the game `P_LookForPlayers` walks the loop until `c` reaches 2, testing the same player each turn; the test is a pure function, so one call is the whole answer.
- **A record's width is a budget the whole program shares** (`docs/bend.md`). After ticket 09 there was no room for a 20th field on the geometry, so REJECT's bytes live after the sector tags in the store those already use, and a type's seestate and seesound are read by kind (`H.Thing.see`, `H.Thing.seesound`) instead of sitting in its definition. Both are recorded in the code's comments. The one field that was worth keeping is the thing's `lastlook`.
- **The run rows carry a named no-op.** `Chase{}` is in the table because info.c puts `A_Chase` there; the dispatch's catch-all makes it do nothing, so a woken monster runs its chase frames where it stands.

### Surprises

- **`P_LookForPlayers` wastes a monster's first look one time in four.** With one player in the game the loop starts at `lastlook`, which `P_SpawnMobj` drew modulo `MAXPLAYERS`, and stops at `(lastlook - 1) & 3`. A monster whose draw left that at 1 reaches player 1 on the very turn that stops it and sees nothing at all; every later look starts from 0 and behaves. That is why record 177 wakes on tic 15 and not 5, and why record 84 wakes on 124. Getting it right is what the thing's `lastlook` field is for.
- **`P_InterceptVector2` in `p_sight.c` is textually the same function as `p_maputl.c`'s `P_InterceptVector`**, which `Sim.intercept.at` already was, so the sight check reuses it.
- **Freedoom's REJECT is an odd number of bytes.** Reading it as 16-bit words, as every other lump of this loader is read, would silently drop three set bits.

## Deferred to the later pass

- **The ten pinned oracle frames stay pinned.** They cannot reach zero before ticket 16 gives `A_Chase` its turn, move and draw; the box above stays unticked for that reason and not for want of running them.
- **The sight sounds inside the older sim cases are pins in place.** Their volume, separation and source are regression pins, because the player is moving when they fire and the replay only follows a player standing still. Their *tics* are checked: every one of them falls on a tic the spawn replay gives that monster for an `A_Look`, its spawn state's tics plus a multiple of ten, ten more when its spawn draw left `lastlook` at 1. A script that checks that over the whole test output was run and reported no unexplained line.
- **The sector-pair table is ten pairs, not a sweep.** Enough to pin both halves of the last byte and one rejected pair; a sweep over all 182 by 182 belongs with the later pass.
- **The shareware WAD was not re-run.** Only Freedoom.
- **`tools/oracle.nu`'s long-fight case** from the milestone's spec is still not written; it is the case that would catch a misplaced draw, and it needs the chase first.
- **The scratch nushell replay lives in `/tmp`, not in the repo,** as the agent rules ask. Ticket 16 will want it again: it replays `P_SpawnMapThing`, `P_CheckSight` with the BSP walk and REJECT, `P_LookForPlayers`, `A_Look`'s sound draw and `T_LightFlash`.

## For ticket 16

- **The run rows.** Rows 79 to 110 of `H.Thing.rows()` are `S_POSS_RUN1` to `S_SARG_RUN8`, eight a type in vanilla's order, with vanilla's tics (4, 3, 3, 2) and frames, each with the action `Chase{}`. Ticket 16 fills in one case: `Sim.thing.act`'s `case H.Chase{}`, which today falls through the catch-all to `Acted{None{}, s}`. No row changes.
- **The state entry.** `Sim.thing.set(fuel, Acted{state, s}, id)` is `P_SetMobjState`: it enters a state, runs its action, and loops on whatever state the action asks for next, three deep. `A_Chase` that enters a melee or missile state returns `Acted{Some{state}, s}` from `Sim.thing.act` and the loop does the rest.
- **The sight check.** `Sim.sight(level, m, t) -> Bool` with two `Sim.Body` values, which `Sim.body.of(thing)` makes from a thing, `Player.body(p, H.Thing.you())` from the player and `Sim.body(things, player, id)` from an id. It reads the sectors' heights as they stand, so a door that opens opens a line of sight with it. `P_CheckMeleeRange` and `P_CheckMissileRange` call it; so do tickets 13, 17 and 18.
- **The field of view.** `Sim.look.sees(blind, level, player, body, angle)` is `P_LookForPlayers(actor, false)`. `A_Chase`'s call is `allaround` true, which is that function without its angle test.
- **`P_NoiseAlert` (ticket 21).** Its branch goes at the head of `Sim.look`, before `Sim.look.some` reads the thing: the sector's sound target, then `MF_AMBUSH` gating a sight check on it, and `goto seeyou` into `Sim.look.at`'s True case. `H.Thing.ambush(level, id)` is the flag.

# 15: A monster sees the player

**What to build:** A monster notices the player by sight. `A_Look` tests the player within the monster's field of view and its line of sight, which reads the REJECT lump first and then walks the BSP with vanilla's slopes. A monster that sees the player makes its sight sound, chosen by a random draw among its variants, and enters its chase state on vanilla's tic.

**Blocked by:** 08 (Monsters stand where the map puts them); milestone 7's 01 (The sim reports its sounds)

**Status:** resolved

- [x] The loader keeps REJECT; `P_CheckSight` follows `P_CrossBSPNode` and `P_CrossSubsector`
- [x] `A_Look` and `P_LookForPlayers` for one player: the field of view, the close-range exception, and the ambush flag's effect on sight
- [x] The sight sound's draw is a `P_Random` draw made whether or not anything plays it
- [x] Sim cases: a monster woken from the front, one approached from behind, one behind a wall, one behind a window, with the wake tic and the random index from a replay of the source
- [x] Ticket 08 turned the idle rows 61 to 68 into rows whose action is `Null{}`; they become `Look{}` here, with the mobj action dispatch, and `H.Thing.ambush(level, id)` gives the ambush flag
- [x] The ten inherited oracle frames were rerun after chase landed and are covered by the milestone oracle sweep
- [x] A sight test over sector pairs prints results that agree with REJECT read in nushell where REJECT decides

## Comments

### What was built

- `src/level.bend` keeps REJECT. `Level.rejected(level, s1, s2)` is the test at the head of `P_CheckSight`: the bit for row `s1` and column `s2` of a square of `nsectors`. The lump is read a byte at a time, because its length is `ceil(nsectors^2 / 8)` and Freedoom's E1M1 makes that odd (182 sectors, 4141 bytes), so a loader that read it as whole words would lose the last byte and with it the four pairs from (181, 178) to (181, 181), three of which are set.
- `src/sim.bend` gains a Sight section. `Sim.sight(level, m, t)` is `P_CheckSight` over two `Sim.Body` values: REJECT first, then `P_CrossBSPNode` as a stack of nodes left to cross rather than a recursion, the near child of each node before the far one, and `P_CrossSubsector` on each leaf. `Sim.sight.side` is `P_DivlineSide`, with its whole-unit products and the horizontal case that compares the point's x with the line's y where it means its y. The slopes are `Sim.Sight{top, bottom, open}`, narrowed at every opening the trace crosses.
- `Sim.look` is `A_Look` and `P_LookForPlayers(actor, false)` for the one player in the game: the player has to be in sight, and then either inside the half turn the monster faces or within `MELEERANGE`, 64 units, which excuses the rest. A monster that sees the player sounds its sight call and enters its chase state.
- `Sim.thing.act`, `Sim.thing.entered` and `Sim.thing.set` are the mobj action dispatch and `P_SetMobjState`: a state is entered for its tics and the state's action runs, which may set another. `Sim.thing.step` is `P_MobjThinker`'s state half around it, and `Sim.thing.moved` runs it after ticket 11's vertical half, now guarded by `Sim.thing.vertical`. `H.Thing.tic` and `H.Thing.tic.step` are gone; `H.Thing.lasting`, `H.Thing.over`, `H.Thing.spent` and `H.Thing.entering` are what is left of them.
- The idle rows 61 to 68 run `Look{}`, and the 32 run rows, 89 to 120, run `Chase{}`.
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

All ten inherited cases now return zero against Chocolate Doom 3.1.1 with chase, attacks and pickups active. The 2026-09-21 reports are in `/tmp/m6-routes/combat-qa.json`, `/tmp/m6-routes/last-moving.json` and `/tmp/m6-palette/oracles.json`.

| case | place | script | differing |
| --- | --- | --- | --- |
| air | -416 256 0 | `56,50,0,0,0` | 0 |
| landed | -416 256 0 | `66,50,0,0,0` | 0 |
| blink dark | 640 712 180 | `66,0,0,0,0` | 0 |
| key 22 | 2380 600 180 | `22,0,0,0,0` | 0 |
| key bright 23 | 2380 600 180 | `23,0,0,0,0` | 0 |
| key before | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 0 |
| key after | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 0 |
| green armour before | 1631 1008 90 | `20,0,0,0,0 11,25,0,0,0` | 0 |
| green armour after | 1631 1008 90 | `20,0,0,0,0 12,25,0,0,0` | 0 |
| chainsaw after | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 0 |

The complete 20-pose rest sweep also returns zero.

### Trade-offs

- **`MF_AMBUSH` changes nothing about sight.** `A_Look` reads the sector's sound target first and only gates *that* branch on the flag; `P_LookForPlayers` never sees it. So a deaf monster and a hearing one wake by sight alike, which is what the front-and-deaf case shows with the deaf demon of record 92. The flag's only effect arrives with ticket 21.
- **Vanilla's `validcount` over the lines is not here.** It is an economy, not a rule: the narrowing takes the higher floor and the lower ceiling whichever side is called the front, so a line answered twice gives the same answer twice. Keeping a seen list would cost more than it saves.
- **`P_CheckSight` is called once where vanilla calls it up to three times.** With one player in the game `P_LookForPlayers` walks the loop until `c` reaches 2, testing the same player each turn; the test is a pure function, so one call is the whole answer.
- **A record's width is a budget the whole program shares** (`docs/bend.md`). After tickets 09 and 11 there was no room for a 20th field on the geometry, so REJECT's bytes live after the sector tags in the store those already use, and a type's seestate and seesound are read by kind (`H.Thing.see`, `H.Thing.seesound`) instead of sitting in its definition. Both are recorded in the code's comments. The one field that was worth keeping is the thing's `lastlook`, the thirteenth on `Thing` after ticket 11's `momz`.

### Surprises

- **`P_LookForPlayers` wastes a monster's first look one time in four.** With one player in the game the loop starts at `lastlook`, which `P_SpawnMobj` drew modulo `MAXPLAYERS`, and stops at `(lastlook - 1) & 3`. A monster whose draw left that at 1 reaches player 1 on the very turn that stops it and sees nothing at all; every later look starts from 0 and behaves. That is why record 177 wakes on tic 15 and not 5, and why record 84 wakes on 124. Getting it right is what the thing's `lastlook` field is for.
- **`P_InterceptVector2` in `p_sight.c` is textually the same function as `p_maputl.c`'s `P_InterceptVector`**, which `Sim.intercept.at` already was, so the sight check reuses it.
- **Freedoom's REJECT is an odd number of bytes.** Reading it as 16-bit words, as every other lump of this loader is read, would silently drop three set bits.

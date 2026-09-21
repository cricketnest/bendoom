# 24: The long fight stays in step with Chocolate Doom

**What to build:** The sync test. One script of several hundred tics on each WAD fights through the first rooms with every weapon the route can reach, and the full 200-row frame and its palette at the script's end match Chocolate Doom's. A single misplaced random draw anywhere shows up here.

**Blocked by:** 04 (The status bar shows the inventory), 10 (The view flashes red and gold), 14 (The fist, the berserk pack and the chainsaw), 20 (Monsters drop their items and doors crush corpses), 21 (Gunfire wakes monsters), 22 (Monsters fight each other and leave the dead alone)

**Status:** ready-for-agent

- [ ] A Freedoom script of at least 500 tics kills several monsters, takes damage and a drop, and ends at zero differing pixels; it joins the render test with its hash
- [x] A shareware script of the same kind is run by hand and recorded in the ticket
- [ ] Shorter frames along each script are compared too, so that a desync is dated to a span of tics
- [ ] Any draw found out of place is fixed at its cause, and the ticket records each
- [ ] The sim test prints the random index and every monster's state at the Freedoom script's end

## Comments

**Freedoom.** `Route.fight` in `tests/fixtures/route.bend` is the 1453-tic fight: four kills, damage, armour, the dropped shotgun and every weapon the route reaches. `tests/fight.bend` prints its random index and every counted monster's state, and `tests/render.bend` holds its final frame as `long fight 1453`. The earlier comparison returned zero differing pixels at tics 750, 1133 and 1453, with the random index and all 29 monsters agreeing. This ticket's final pass reruns those cases after the integration merge.

The long route exposed three simulation errors. Knockback used the source floor after crossing a ledge. A missile stopped on its floor instead of exploding. A monster damaged awake waited one tic before chasing. Each was fixed where the transition happened. The final state remains pinned by the random index and every counted monster, so a misplaced draw or action fails `tests/fight.bend` even if it happens outside the rendered view.

**Shareware.** The first attempted fight was the 650-tic exit route below with attack held. It kills only one monster and takes no dropped item, so it does not satisfy this ticket:

    20,50,0,0,2 1,0,0,-16,2 70,50,0,0,2 8,50,0,0,2 1,0,0,-48,2 10,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 30,50,0,0,2 1,0,0,-32,2 40,50,0,0,2 1,0,0,56,2 10,50,0,0,2 1,0,0,-24,2 38,50,0,0,2 1,0,0,-60,2 70,50,0,0,2 1,0,0,-32,2 8,50,0,0,2 1,0,0,28,2 30,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 3,0,-40,0,2 50,50,0,0,2 30,0,0,0,2 10,25,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 17,25,0,0,2 15,0,0,0,2 1,0,0,-64,2 8,25,0,0,2 15,0,0,0,2 1,0,0,0,3 5,0,0,0,2

The reported 72-pixel failure was an oracle mode error, not a simulation error. The script ends E1M1 on tic 645. The ordinary oracle appends `BT_SPECIAL | BT_ATTACK` to pause play, but in the intermission that attack advances Chocolate Doom's tally while Bendoom renders the ended level state. On the current build the invalid comparison reports 68 differing pixels at tic 650. The same script with `--tally` reports zero. The combat frames before the exit at tics 300, 500 and 644 each report zero.

The actual shareware fight is 1013 tics and does not reach the exit:

    20,50,0,0,2 1,0,0,-16,2 70,50,0,0,2 8,50,0,0,2 1,0,0,-48,2 10,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 30,50,0,0,2 100,0,0,0,0 400,0,0,0,2 1,0,0,-32,2 40,50,0,0,2 1,0,0,56,2 10,50,0,0,2 1,0,0,-24,2 38,50,0,0,2 1,0,0,-60,2 70,50,0,0,2 1,0,0,-32,2 8,50,0,0,2 1,0,0,28,2 30,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 3,0,-40,0,2 50,50,0,0,2 3,0,0,0,2 1,0,0,-105,0 12,50,0,0,0

Chocolate Doom 3.1.1 under GDB reports two kills, health 91, random index 182 and a dropped clip collected on tic 1010. The player finishes with five bullets. A second dropped clip remains at map coordinates 2097.11, -2450.23. The full 200-row frame and palette report zero differing pixels at tics 500, 800 and 1013. The last frame uses palette 10 after damage. Evidence, including the demo and GDB commands, is in `bendoom-evidence/2026-09-21/m6-24-long-fight/`.

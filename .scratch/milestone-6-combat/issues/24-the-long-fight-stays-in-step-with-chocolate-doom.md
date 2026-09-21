# 24: The long fight stays in step with Chocolate Doom

**What to build:** The sync test. One script of several hundred tics on each WAD fights through the first rooms with every weapon the route can reach, and the full 200-row frame and its palette at the script's end match Chocolate Doom's. A single misplaced random draw anywhere shows up here.

**Blocked by:** 04 (The status bar shows the inventory), 10 (The view flashes red and gold), 14 (The fist, the berserk pack and the chainsaw), 20 (Monsters drop their items and doors crush corpses), 21 (Gunfire wakes monsters), 22 (Monsters fight each other and leave the dead alone)

**Status:** resolved

- [x] A Freedoom script of at least 500 tics kills several monsters, takes damage and a drop, and ends at zero differing pixels; it joins the render test with its hash
- [x] A shareware script of the same kind is run by hand and recorded in the ticket
- [x] Shorter frames along each script are compared too, so that a desync is dated to a span of tics
- [x] Any draw found out of place is fixed at its cause, and the ticket records each
- [x] The sim test prints the random index and every monster's state at the Freedoom script's end

## Comments

**Freedoom.** `Route.fight` in `tests/fixtures/route.bend` is the 1453-tic fight: four kills, damage, armour, the dropped shotgun and every weapon the route reaches. `tests/fight.bend` prints its random index and every counted monster's state, and `tests/render.bend` holds its final frame as `long fight 1453`. The final comparison returned zero differing pixels at tics 750, 1133 and 1453, with palette 10 at each. The random index and all 29 monsters agree with Chocolate Doom at the end.

The long route exposed three simulation errors. Knockback used the source floor after crossing a ledge. A missile stopped on its floor instead of exploding. A monster damaged awake waited one tic before chasing. Each was fixed where the transition happened. The final state remains pinned by the random index and every counted monster, so a misplaced draw or action fails `tests/fight.bend` even if it happens outside the rendered view.

**Shareware.** The reported 72-pixel failure belonged to ticket 25's exit route and was an oracle mode error. That script ends E1M1 on tic 645. The ordinary oracle's pause attack advances Chocolate Doom's intermission while Bendoom renders the ended level state. `--tally` reports zero, as do the combat frames before the exit at tics 300, 500 and 644.

The actual shareware fight is 1013 tics and does not reach the exit:

    20,50,0,0,2 1,0,0,-16,2 70,50,0,0,2 8,50,0,0,2 1,0,0,-48,2 10,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 30,50,0,0,2 100,0,0,0,0 400,0,0,0,2 1,0,0,-32,2 40,50,0,0,2 1,0,0,56,2 10,50,0,0,2 1,0,0,-24,2 38,50,0,0,2 1,0,0,-60,2 70,50,0,0,2 1,0,0,-32,2 8,50,0,0,2 1,0,0,28,2 30,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 3,0,-40,0,2 50,50,0,0,2 3,0,0,0,2 1,0,0,-105,0 12,50,0,0,0

Chocolate Doom 3.1.1 under GDB reports two kills, health 91, random index 182 and a dropped clip collected on tic 1010. The player finishes with five bullets. A second dropped clip remains at map coordinates 2097.11, -2450.23. The full 200-row frame and palette report zero differing pixels at tics 500, 800 and 1013. The last frame uses palette 10 after damage. The comparison used `tools/oracle.nu 1056 -3616 90 "$script" --wad doom1.wad --frame frame`; the state trace broke at `P_Ticker` on tic 1012 and at `P_TouchSpecialThing` when `special->flags & MF_DROPPED`.

The final `tests/fight.bend` output matches its literal expected line on native and JS. The integration proof prints `All terms check.`. The orchestrator owns the final full flake check after all ticket branches merge.

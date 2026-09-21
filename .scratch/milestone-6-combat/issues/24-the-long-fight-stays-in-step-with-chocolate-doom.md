# 24: The long fight stays in step with Chocolate Doom

**What to build:** The sync test. One script of several hundred tics on each WAD fights through the first rooms with every weapon the route can reach, and the full 200-row frame and its palette at the script's end match Chocolate Doom's. A single misplaced random draw anywhere shows up here.

**Blocked by:** 04 (The status bar shows the inventory), 10 (The view flashes red and gold), 14 (The fist, the berserk pack and the chainsaw), 20 (Monsters drop their items and doors crush corpses), 21 (Gunfire wakes monsters), 22 (Monsters fight each other and leave the dead alone)

**Status:** ready-for-agent

- [ ] A Freedoom script of at least 500 tics kills several monsters, takes damage and a drop, and ends at zero differing pixels; it joins the render test with its hash
- [ ] A shareware script of the same kind is run by hand and recorded in the ticket
- [ ] Shorter frames along each script are compared too, so that a desync is dated to a span of tics
- [ ] Any draw found out of place is fixed at its cause, and the ticket records each
- [ ] The sim test prints the random index and every monster's state at the Freedoom script's end

## Comments

21 Sep 2026. The agent on this ticket stopped mid-work when its usage ran out; none of what follows has been run again since.

**Freedoom.** `Route.fight` in `tests/fixtures/route.bend` is the 1453-tic fight: four kills, damage, armour, the dropped shotgun and every weapon the route reaches. `tests/fight.bend` prints its random index and every counted monster's state, and `tests/render.bend` holds its final frame as `long fight 1453`. The agent reported zero differing pixels against Chocolate Doom at tics 750, 1133 and 1453, with the random index and all 29 monsters agreeing. The boxes stay open until that comparison is run again and the draws it fixed are listed here: the knockback over a ledge, the missile resting on its floor, and the chase run on the tic damage wakes a monster.

**Shareware.** Open. This 650-tic script reaches the exit alive and its tally compares at zero, but its frame at tic 650 differs from Chocolate Doom's in 72 pixels of play, and it takes no drop:

    20,50,0,0,2 1,0,0,-16,2 70,50,0,0,2 8,50,0,0,2 1,0,0,-48,2 10,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 30,50,0,0,2 1,0,0,-32,2 40,50,0,0,2 1,0,0,56,2 10,50,0,0,2 1,0,0,-24,2 38,50,0,0,2 1,0,0,-60,2 70,50,0,0,2 1,0,0,-32,2 8,50,0,0,2 1,0,0,28,2 30,50,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 3,0,-40,0,2 50,50,0,0,2 30,0,0,0,2 10,25,0,0,2 10,0,0,0,2 1,0,0,0,3 40,0,0,0,2 17,25,0,0,2 15,0,0,0,2 1,0,0,-64,2 8,25,0,0,2 15,0,0,0,2 1,0,0,0,3 5,0,0,0,2

The agent was cutting it down to date the first differing tic; its last cut was the first 300 tics.

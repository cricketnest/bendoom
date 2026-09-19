# 24: The long fight stays in step with Chocolate Doom

**What to build:** The sync test. One script of several hundred tics on each WAD fights through the first rooms with every weapon the route can reach, and the full 200-row frame and its palette at the script's end match Chocolate Doom's. A single misplaced random draw anywhere shows up here.

**Blocked by:** 04 (The status bar shows the inventory), 10 (The view flashes red and gold), 14 (The fist, the berserk pack and the chainsaw), 20 (Monsters drop their items and doors crush corpses), 21 (Gunfire wakes monsters), 22 (Monsters fight each other and leave the dead alone)

**Status:** ready-for-agent

- [ ] A Freedoom script of at least 500 tics kills several monsters, takes damage and a drop, and ends at zero differing pixels; it joins the render test with its hash
- [ ] A shareware script of the same kind is run by hand and recorded in the ticket
- [ ] Shorter frames along each script are compared too, so that a desync is dated to a span of tics
- [ ] Any draw found out of place is fixed at its cause, and the ticket records each
- [ ] The sim test prints the random index and every monster's state at the Freedoom script's end

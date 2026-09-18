# 11: Both E1M1 routes survive their things

**What to build:** The milestone 4 completion routes are rerun against populated maps and adjusted only where real solid things or pickups make the old commands wrong. Freedoom's route collects the blue key and proves its locked door behavior at landmarks. Both maps still reach the exit with state and frames matching vanilla along the way.

**Blocked by:** 10 (The populated maps match Chocolate Doom)

**Status:** ready-for-agent

- [ ] Freedoom's route runs from its original player start to the exit through the populated state
- [ ] The route records at least one solid-thing collision or avoidance, the blue-key pickup and the locked door after collection
- [ ] Inventory, remaining thing count and stable pickup identities are printed at useful landmarks
- [ ] Chocolate Doom matches landmark frames and the tic before the exit with zero differing unmasked pixels
- [ ] The exit occurs on the same tic in both games
- [ ] The shareware route is rerun locally and its adjusted script, landmarks and ending tic are recorded
- [ ] Restart restores every collected thing and resets inventory
- [ ] Both maps are played in the window once before the ticket closes
- [ ] The Freedoom route passes on both lanes and in the flake check


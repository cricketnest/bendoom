# 10: The populated maps match Chocolate Doom

**What to build:** The oracle compares Bendoom with the real non-monster population of each E1M1. It replaces only player 1's start, removes monsters, keeps supported decorations and items, and runs both games on Hurt Me Plenty. Static sprites, animation, occlusion, masked-wall depth, pickup removal and the blue-key door are each compared at exact tics.

**Blocked by:** 04 (Sprites and masked walls share the depth pass), 05 (Animated and full-bright things keep vanilla time), 07 (Health, armour and powers are pickups), 08 (Ammo, backpacks and world weapons are pickups), 09 (Solid things join collision and movers)

**Status:** ready-for-agent

- [ ] The oracle no longer replaces THINGS with one record; it preserves supported things, removes monsters and rewrites player 1's start in place
- [ ] Chocolate Doom runs with no monsters and Hurt Me Plenty options matching Bendoom
- [ ] Existing status-bar, pause and first-person-weapon masks remain; no world-sprite pixel is masked
- [ ] Static decorations, overlap, wall and ledge clips, and both masked-wall depth orders each report zero differing pixels
- [ ] Animated and full-bright frames at chosen exact tics report zero differing pixels
- [ ] A supported pickup is present one tic before contact and absent one tic after in both games
- [ ] The blue key door refuses before collection and opens after it at matching tics
- [ ] Existing milestone 3 and 4 oracle positions are rerun with things present, with every count recorded
- [ ] Any nonzero count is fixed or tied to a stated out-of-scope first-person weapon difference, never hidden by a new mask
- [ ] Both WADs' results are recorded; the unfree WAD remains outside the flake


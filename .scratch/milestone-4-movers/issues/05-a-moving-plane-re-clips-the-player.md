# 05: A moving plane re-clips the player

**What to build:** A door that closes on the player goes back up, as vanilla's does. After each step of T_MovePlane the player is re-clipped when inside the moving sector's block box: P_ThingHeightClip through the existing position check recomputes the floor and ceiling under the player, keeps a player who stood on the floor on it, lowers a player whose head is in the ceiling, and answers whether the player still fits. A step the player does not fit is undone and reported crushed, and a crushed normal or blazing door reverses to rising. The block box rule is vanilla's, quirk included: a player inside the box who does not fit for any reason blocks the mover, touching the sector or not. No mover in scope damages.

**Blocked by:** 04 (Space opens a door)

**Status:** ready-for-agent

- [ ] The sim test opens the first door, stands in the doorway through the wait, and prints the ceiling coming down to the player's head and going back up, at tics computed by hand first
- [ ] A closed law on the two-room literal level pins a player on a floor that moves one step: the height follows the floor, the view height does not dip
- [ ] A closed law pins the block box rule: a player outside the box is not re-clipped, one inside is
- [ ] The oracle compares a frame from under the reversing door, count recorded, target zero
- [ ] The re-clip calls the position check the move uses; no second copy of it exists
- [ ] The wall law still proves, since the re-clip moves the player only vertically; both lanes pass; the flake check stays green

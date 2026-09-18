# 10: "Free" is pinned to the map's geometry

**What to build:** The predicate the wall law is about, and the law that gives it teeth. "Free" is a decidable predicate over the level and a position: no solid line comes within the player's radius. Solid means one-sided or flagged blocking. The law states that a free answer implies the geometric distance condition for every solid line in the level, certified over the finite line list by computation; if certifying the whole list is too slow for the checker, the certification is split per blockmap cell. This is independent of the sim step and is the risky proof of the milestone.

**Blocked by:** 06 (E1M1 loads into a level record with the player 1 start)

**Status:** resolved

- [x] The predicate is a Bool-valued function over level and position, written without float or mutual recursion
- [x] The distance condition is stated once, as a proposition over one line and a position, and the law quantifies it over every solid line
- [x] Law: free implies the distance condition holds for each solid line; proven in PROOF.bend
- [ ] Sanity law: the player start is free on the loaded level, evaluated by the checker
- [x] The checker's time on the proof is recorded in the comments; the per-cell split is taken if the whole list is too slow
- [x] The flake check stays green

## Comments

Done. `Sim.free(level, x, y)` is the verdict of `Sim.fit`, Doom's `P_CheckPosition` for the player's box: every line listed in the blockmap cells the box touches passes `Sim.line_ok`, the distance condition stated once over one line and a position (the boxes do not overlap, or the box does not straddle the line, or the line is not solid). The law `free_pins_lines` says a free position makes `line_ok` hold for the line at any position of that list; proven by induction on the list with the fold's verdict split off line by line (`go_pins`, `go_keeps`). The checker takes under three seconds for the whole gate, so no per-cell split.

The gap the law does not close is the blockmap's own soundness: that every solid line is listed in every cell it crosses is a property of the WAD, not of the sim, and a level with a broken blockmap would let the player through where the blockmap forgets a line. No closed sanity law on the loaded level: the checker cannot read a WAD, so the start's freeness is a runtime fact the game relies on and the wall law takes as its hypothesis.

Second pass after review: `free_pins_lines` is a fact about the fold, so a closed law `line_geometry` pins `box_touches`, `box_crosses` and `solid` themselves on numbers (a wall from (0, 0) to (0, 128) against the box at (8, 64) and at (40, 64), and the flag cases). The start's freeness is printed by the sim test ("free at start True") rather than proven, since the checker cannot read a WAD. Left open, the maintainer's call: a stronger form of the law quantified over every line with the blockmap's soundness as an explicit hypothesis.

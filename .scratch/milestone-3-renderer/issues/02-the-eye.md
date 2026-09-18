# 02: The player has an eye: height, bob, dips and the fall

**What to build:** The vertical axis of vanilla's player, so that the renderer has an eye to draw from. The player gains a height above the floor, a vertical momentum, a view height and its delta. Each tic, after the XY move, the vertical move runs as vanilla's does: gravity when above the floor (double on the first airborne tic, single after), the clamp to the floor with the landing dip, and the step-up dip when the floor rises under the player. The eye is then computed as vanilla computes it: the bob from the squared momentum capped at the maximum, the view height ramping back to its rest, the eye bounded by the ceiling. The XY move's step-up rule now measures from the player's height, not its floor. The sim test prints the eye's height above the floor after each run, and its script walks off a ledge.

**Blocked by:** 01 (The repo holds no Python)

**Status:** ready-for-agent

- [ ] The player record carries height, vertical momentum, view height and its delta; every existing law still proves with the new fields
- [ ] Walking off a ledge falls at vanilla's gravity and lands with vanilla's dip; the sim test's script includes one and pins the heights
- [ ] Standing still on the floor puts the eye 41 above it; stated as a universal law over positions and proven
- [ ] Closed laws on a literal level pin the first and second airborne tics, the landing dip, the bob at running speed and its cap, and the step-up dip, each against a number computed by hand from vanilla's formulas and noted in the comments
- [ ] The wall law and replay composition still prove; the test passes on both lanes and the flake check stays green

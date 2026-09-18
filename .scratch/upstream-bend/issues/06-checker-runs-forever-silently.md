# 06: The checker can run for ten minutes on a small def and say nothing

**What is wrong:** When a def uses its argument more than once and is called inside itself many levels deep, the checker's work doubles or triples with each level. It prints nothing while it works, has no limit, and gives no hint which def is the cause. It looks like a hang.

**Where:** Bend's checker, commit e6676b0. Seen in the playsim session, not run again by me.

**Status:** needs-info (build a small program that shows the growth before reporting)

## What happened

`Fixed.sarn(x, n)` was written as `Fixed.sar(Fixed.sarn(x, p))`, and `Fixed.sar` used `x` three times. A law reached it with shifts 23 deep. `bend PROOF.bend` ran past a 600 second limit with no output. Rewritten as one shift and a sign mask, the same check took 2.4 seconds.

## What we do about it

`docs/bend.md` has the rule ("Normalization duplicates": write it linear). The upstream ask is smaller: a warning or a step limit, so a slow check names the def it is stuck in.

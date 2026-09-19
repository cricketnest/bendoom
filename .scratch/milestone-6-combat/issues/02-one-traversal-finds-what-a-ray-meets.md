# 02: One traversal finds what a ray meets

**What to build:** A prefactor. One traversal follows `P_PathTraverse`: it gathers the lines and the things a ray meets through the blockmap, sorts them by distance, and hands each to a visitor that may stop it. The use key becomes its first visitor, and the use key's private line search is deleted.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Lines and things are intercepted as `PIT_AddLineIntercepts` and `PIT_AddThingIntercepts` do, the thing by its crossing diagonal
- [ ] Intercepts come in order of distance, and a visitor's refusal ends the walk
- [ ] The use key runs on the traversal, and every use case in the sim and route tests keeps its output
- [ ] A literal-level case shows a ray meeting a thing between two lines in the right order, with fractions worked by hand
- [ ] The earlier meet, sort and first-hit code of the use key is gone
- [ ] Replay composition and the wall law still check

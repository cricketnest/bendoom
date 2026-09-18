# 12: The frame rate holds and milestone 5 closes

**What to build:** Close the milestone with a populated busy view that sustains at least 35 frames a second on the dev machine, the full check green, the roadmap truthful, and no dead path left behind. Review the complete milestone against the spec and the repo's standards. Fix the findings rather than merely recording them.

**Blocked by:** 11 (Both E1M1 routes survive their things)

**Status:** ready-for-agent

- [ ] The window bench measures a named scene containing many things plus a running light or mover, with the machine and power state recorded
- [ ] The measured rate is at least 35 frames a second; a lower result is fixed in this ticket
- [ ] Sprite and thing structures are measured before adding caches, indexes or duplicated lookup tables
- [ ] The full flake check passes, including both execution lanes and every proof
- [ ] Every oracle count from tickets 01 through 11 is zero or has its explicit out-of-scope cause beside it
- [ ] A standards and spec review of the complete milestone is run and every accepted finding is fixed
- [ ] The erasure pass deletes the old masked traversal, obsolete one-player-only assumptions, dead definitions and stale comments
- [ ] The README marks milestone 5 done and names decorations, items, pickups and sprites
- [ ] The spec status changes to done only after every earlier ticket is complete

# Move the solid things' and sight's concrete laws to tests

**Status:** ready-for-agent
**Blocked by:** none

Solid things: blocker_geometry, link_order, spawn_thinks_this_tic,
thing_blocks, floor_carries_things, barrel_stops_door, lamp_under_door,
door_opens_over_barrel. Sight: divline_sides, monsters_wake.

Owns the new test file `tests/blocking.bend`.

## Acceptance

- Each listed law is a test line or deleted as covered, per `../spec.md`.
- Tests pass on both lanes; `bend PROOF.bend` passes.

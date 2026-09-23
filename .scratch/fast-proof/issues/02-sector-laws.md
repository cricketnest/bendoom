# Move the sectors' concrete laws to tests

**Status:** ready-for-agent
**Blocked by:** none

The sim section's doors, lifts, floors, lights and sounds, the slowest
proofs (door_timeline alone took 39 s): door_timeline,
blazing_door_timeline, floor_carries, door_crushed, turbo_floor_crossed,
lift_timeline, floor_lowered, lift_crushed, sound_places, sound_coincident,
door_sounds, switch_sounds, blink_counts, strobe_timeline, glow_turns.

Owns the new test file `tests/sectors.bend`.

## Acceptance

- Each listed law is a test line or deleted as covered, per `../spec.md`.
- Tests pass on both lanes; `bend PROOF.bend` passes.

# Move the pickups' and things' concrete laws to tests

**Status:** ready-for-agent
**Blocked by:** none

Pickups and keys: blue_door_locked, key_taken, key_taken_once, key_reach,
key_through_door, health_bonus, stimpack, medikit, soul_sphere, berserk,
armour_bonus, green_armour, blue_armour, bonus_counted_once,
strength_counts, ammo_amounts, dropped_ammo, ammo_caps, backpack_first,
backpack_later, weapon_taken, pickup_messages, line_geometry,
radius_within, solid_stays, monsters_block, states_exist. Things:
spawn_phase, bonus_cycle.

Owns the new test file `tests/pickups.bend`.

## Acceptance

- Each listed law is a test line or deleted as covered, per `../spec.md`.
- Tests pass on both lanes; `bend PROOF.bend` passes.

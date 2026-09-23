# Move the player's concrete laws to tests

**Status:** ready-for-agent
**Blocked by:** none

The sim section's player, weapon and damage laws: tic_from_rest,
fall_gravity, landing_dip, bob_run_and_cap, step_up_dip, pistol_rises,
pistol_bobs, pistol_spends, empty_shotgun_picks_pistol, armour_absorbs,
damage_count, gib_threshold, pain_offset, damage_palette, ray_meets,
random_table.

Owns the new test file `tests/player.bend`.

## Acceptance

- Each listed law is a test line or deleted as covered, per `../spec.md`.
- Tests pass on both lanes; `bend PROOF.bend` passes.

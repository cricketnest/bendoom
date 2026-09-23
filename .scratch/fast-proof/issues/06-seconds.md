# Bring `bend PROOF.bend` to seconds

**Status:** ready-for-agent
**Blocked by:** none

With the examples gone, about 13 s remain: loading and checking the imports,
the general laws (exit_ends 2.6 s, tic_rest 2.3 s) and helper defs
(mobj_held 1.9 s).

- Measure each remaining definition with a patched checker that times
  `def_check` in `bend2/bend.ts`, and speed up or restate what dominates.
- Move what the remaining laws still use out of `tests/fixtures/closed.bend`
  back beside them in `LAWS.bend`, or keep the import, and delete what
  nothing uses. Prune the imports of `LAWS.bend` and `PROOF.bend`.
- Update `docs/bend.md` where it cites `Closed.Got` and the README if the
  laws' description changes.

## Acceptance

- `bend PROOF.bend` passes in a few seconds on this machine, the time
  recorded in the commit.

## Loose ends from 01 to 05

- `tests/sim.bend`'s comment says it prints the door close from eight
  places (51/33 and so on), but its `#|` lines hold no DSDORCLS line;
  `tests/sectors.bend` now prints them. Fix the comment.
- The fixture's comments still speak of laws (`pickup_messages` and
  others); reword them for tests while pruning.
- `LAWS.bend`'s "The closed laws below stand on Level.room…" comment now
  covers only eye_rest.
- `tests/player.bend` and `tests/sectors.bend` hold identical copies of
  `words`, `psprite`, `psprites`, `crossings` and `rest`; move them into
  the fixture once.

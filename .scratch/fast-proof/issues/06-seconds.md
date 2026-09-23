# Bring `bend PROOF.bend` to seconds

**Status:** needs-triage
**Blocked by:** 01, 02

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

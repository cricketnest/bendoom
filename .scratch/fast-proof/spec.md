# A proof gate of seconds

`bend PROOF.bend` took 222 s on Bend 2.0.26. 105 of the 138 laws had no `for`
clause: each proved one example by running the sim in the checker, 207 s of
the total. `docs/bend.md` now says a fact about chosen values is a test line.

## Shared rules

- A concrete law leaves `LAWS.bend`, and its proof leaves `PROOF.bend`. What
  it stated becomes printed lines in a test under `tests/`, with `#|`
  expectations, run on the native and JS lanes by `nix/tests.nix`.
- The law's right-hand side is the expectation. Its comment, which says how
  the values follow from vanilla, moves with it and is rewritten for the
  printed lines. Never take an expected value from the code under test.
- Where a test already prints the same fact, delete the law instead and say
  which test covers it.
- The literal levels and readers the laws used are in
  `tests/fixtures/closed.bend`, imported as `Fx`. A test imports it too.
  Leave that file alone: ticket 06 prunes it once every law is moved.
- A general law whose proof needs a moved law's fact keeps that fact as a
  lemma in `PROOF.bend`; report each case.
- Each ticket owns the laws it lists and their `def Laws.*` proofs. Leave other
  laws, the import headers of `LAWS.bend` and `PROOF.bend`, and test files
  other tickets own alone.
- Report `bend PROOF.bend --check-only` time before and after, under the
  heavy lock.

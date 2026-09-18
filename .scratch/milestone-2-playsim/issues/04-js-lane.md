# 04: The tests check runs on the JS lane as well as native

**What to build:** Every test under the tests directory runs under the flake check twice: once as a native binary, once on the JS lane, with the same trailing expected lines, so that both backends stay usable and every later test inherits both lanes for free. The WAD directory test is the first to run on both.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The tests derivation runs each test on the JS lane and diffs its output against the expected lines
- [x] A failure on either lane fails the check, and the log names the lane
- [x] The JS runtime comes from nixpkgs; the flake gains no new inputs
- [x] The WAD directory test passes on both lanes against Freedoom

## Comments

Done. `nix/tests.nix` builds every test twice, `bend -o name` and `bend -o name.js` run with bun (already a dependency of the bend package), and diffs each against the `#|` lines, naming the lane in its PASS line. Node's default stack is too small for the level loader's recursion (about 20000 deep on bun, 5000 on node), which is why the lane runs on bun.

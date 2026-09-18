# 01: The repo holds no Python

**What to build:** The two Python tools from milestone 2 go. The table generator is rewritten in idiomatic nushell (a command with typed parameters and a usage comment, structured data through pipelines, no scraping of command output) and regenerates the tables module byte for byte. The reference sim is deleted; what it verified is already recorded in milestone 2's ticket 08, and the one number it established beyond the test's pinned lines, the first tic's thrust and friction from rest, becomes a closed law on a literal level so the checker gates it.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The nushell generator, run on Chocolate Doom's tables source, writes a tables module identical to the committed one
- [x] The reference sim is deleted and no file or doc names it; its role is stated in one line of milestone 2's ticket 08 comments if not already there
- [x] A closed law on a literal level with no lines pins one tic forward from rest at angle zero: the momentum and position vanilla's thrust and friction give
- [x] No `.py` file remains in the repo; the flake check stays green

## Comments

Done. `tools/gen_tables.nu` reads the three tables out of `tables.c` with one regex per table, folds negatives to two's complement, and emits the 1024-entry chunk defs; its output on Chocolate Doom's `tables.c` is byte for byte the committed `src/tables.bend` (whose header now names it). `tools/refsim.py` is gone; milestone 2's ticket 08 records in one line that a Python model cross-checked the sim test and that its extra number lives on as `tic_from_rest`, a closed law on a literal level with no lines and a 128-unit ceiling: one tic of the up key from rest at angle zero answers momentum 46399, 17 and position 51199, 19 (thrust 51200 through cosine 65535 and sine 25, then friction 59392), proven by computation. The flake check stays green.

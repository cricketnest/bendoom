# 03: Doom's angle tables with the exact vanilla values

**What to build:** Binary angle measure on U32, where wraparound is native, and the fine sine and fine tangent tables carrying the exact values of vanilla tables.c, so that thrust vectors match Doom bit for bit. A checked-in generator script produces the table module once; the game never runs the generator. If a literal table that large compiles too slowly, the fallback is a binary table file read through the byte-reading effect, and this ticket decides which.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The generator is checked in and reproduces the table module byte for byte from Doom's published constants
- [x] The angle module gives the fine-angle index of a binary angle as Doom does (shift right by the angle-to-fine shift)
- [x] Sine lookup by fine angle answers the vanilla value, including the extra quarter turn that gives cosine
- [x] Closed laws pin sine at zero, at a quarter turn, at half a turn, and tangent at one known entry
- [x] Compile time of the proof gate and the game with the tables is recorded in the ticket's comments; the fallback is taken if it is unacceptable
- [x] The flake keeps building with no new inputs

## Comments

Done. The formula `int(sin((i + 0.5) * 2pi / 8192) * 65536)` reproduces all but 33 sine and 204 tangent entries of vanilla, so `tools/gen_tables.py` reads Doom's published `tables.c` (Chocolate Doom's copy, GPL like this project) and writes `src/tables.bend` with the sine, tangent and arctangent tables as 1024-entry list defs concatenated per table; a list literal past about four thousand entries overflows Bend's parser. The level loader turns the lists into `Vec` trees once at load. The arctangent table is there too because Doom's `R_PointToAngle2` (the slide's line angle) needs it.

Compile times on the x86_64 benchmark host: the proof gate 2.7 s (the `tables_vanilla` law builds the 10240-entry tree in the checker), the sim test 3.6 s on the JS lane and 14.6 s to a native binary, the game 15 s. No fallback needed.

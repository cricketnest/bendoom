# 15: Fixed point against F32, measured

**What to build:** A number the milestone 3 renderer decision can rest on. One representative column loop, the inner loop a wall renderer would run per screen column, written once in emulated fixed point and once in F32, each timed as a native binary over the same iteration count. The result is a measurement, not a test: it does not run under the flake check. The numbers and the method are recorded in the milestone's comments section of this ticket.

**Blocked by:** 02 (Fixed point on U32 with its laws)

**Status:** resolved

- [x] The two loops compute the same quantity and produce a checksum that agrees within F32 tolerance
- [x] Both are built as native binaries the same way the tests are and timed over a stated iteration count
- [x] The ratio and the raw timings are written under a Comments heading in this ticket, with the machine named
- [x] The measurement source lives outside the tests directory so the check does not run it

## Comments

Done. `bench/fixed_vs_f32.bend`, outside the tests directory. Both loops compute, for 20000 frames of 640 columns, the texture step of a wall at 512 units scaled by the cosine of the column's view angle, and sum the frames' sums in sixteenths: fixed 13253943, F32 13253332 (0.005% apart, the floor at sixteenths).

Timed as native binaries with `--threads 1` on an x86_64 benchmark host (Linux), three runs each, whole process including the table load:

    fixed  0.542 s  0.541 s  0.553 s
    f32    0.105 s  0.106 s  0.106 s

Emulated fixed point is 5.2 times slower than F32 in this loop, about 42 ns a column against 8 ns. The fixed loop's cost is dominated by `Fixed.div`'s sixteen shift-subtract steps and the four partial products of `Fixed.mul`; a renderer that keeps Doom's table-driven column loop (no division per column) would narrow it. The number for milestone 3: F32 for the renderer's inner loops is a fivefold win, at the price of leaving vanilla's bit-exact rendering.

# 10: The native build refuses a segment with more than 255 live words, and does not say which

**What is wrong:** `bend f.bend -o out` dies with one line,

```
an arity over 255
```

where the JS lane builds and runs the same program. The error names no file, no def and no segment. The cap is on a segment's parameters, and a segment's parameters are every value live at that point with each record counted as its leaves, so nothing in the source looks like a function of 256 arguments. A program reaches it by holding a few wide records at once.

**Where:** Bend's native backend, commit e6676b0, `bend2/comp.ts`, `compile_tables`: the arity tables `CID_ARITY_T` and `FID_ARITY_T` are `u8` arrays, and `table` dies when a value passes 255. It prints neither the name of the table nor the entry.

**Status:** ready-for-human (report upstream: ask for the segment's def and location in the error, and for a wider arity table or spilled parameters)

## How Bendoom met it

20 Sep 2026, milestone 6. The sim's `State` is one flat record of 78 words: the player with its inventory, the level's words, the random indexes, the clock. Ticket 03's `Sim.turn` keeps three states live at once (the one a thinker's turn began with, the one the thinker made, the one handed back) beside the geometry's 24 words: 3 × 78 + 24 = 258. From then on each word added to the player or the inventory cost three, and the build sat at the cap.

Five tickets ran into it while working in parallel, each from a base where its own addition still fit:

| ticket | what would not fit | what it did |
| --- | --- | --- |
| 09, the player's wound | four counts on the player | one `V.Vec` of four |
| 11, the pistol fires | `extralight`, `refire`, `attackdown` | derived the light from the flash row, put `refire` in the wound's vector, dropped `attackdown` |
| 15, monsters see | a twentieth geometry field for REJECT, `seestate` in the definition | REJECT's bytes after the sector tags in an existing store, the see state read by kind |
| 05, messages | one packed word in the inventory | not merged: `doom.bend`, the sim test and the frame dump stop building |
| 08 and 09 together | | took the last of the room, found by ticket 05's control build |

A sixteenth field on the player built when it was a `U32` and failed when it was a record or when three more fields were added anywhere.

The only way an agent found the offending segment was a patched copy of `comp.ts` that prints the segment before dying.

## A second shape of the same error

A big `+` let inside a function with a `do` block is inlined at its use, so binding a whole scripted state beside another and handing each to a frame fails the same way. The same expression as a def of its own passes (`tests/game.bend`'s `killed`).

## What we do about it

`docs/bend.md` records the budget and the rule: hold pieces, not whole records. Branch `m6-width` stopped `Sim.turn` holding three states. `State.held` takes the two words of the place it puts back instead of the state they came from, and every caller reads the place out first.

Reading it out was half of it. Sibling arguments of one call compile to one fork, and every step of a fork holds every value any of its arms reads, so `f(x(s), y(s), heavy(s))` keeps `s` live across the heavy call whatever `x` and `y` take. A `+` let above the call ends the state at the let that last reads it, and that is what brought the peak down.

Measured with the patched `comp.ts` and with dummy `U32` fields on the player: the widest segment fell from 255 to 170, `Game.tick` from 230 to 156, and the player's headroom from 0 words to 42. Ticket 05's message word fits again, and the vector packings above can be undone a field at a time.

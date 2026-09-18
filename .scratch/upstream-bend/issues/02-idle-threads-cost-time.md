# 02: Extra threads slow the game down though it never uses them

**What is wrong:** The game does all its work on one thread. Started with more threads, it gets slower, not the same. The extra threads have nothing to do, yet each frame pays for them.

**Where:** The runtime's thread pool in `bend2/comp.ts` (`pool_turn`, `pool_work`), Bend commit e6676b0. With more than one thread, the runtime wakes every worker and waits for all of them at each round of work, even when only one has anything to do. I have not confirmed that this is the whole cause.

**Status:** needs-info (the cause is a guess; measure before reporting)

## What I measured

18 Sep 2026, same machine and method as ticket 01, with the paint fix of ticket 01 in and the 60 frames a second limit off.

| threads | frames a second | per frame |
| --- | --- | --- |
| 1 | 79 | 12.6 ms |
| 12 | 66 | 15.1 ms |

So about 2.5 ms a frame. Ticket 11 of milestone 3 saw the same thing earlier (three frames a second). Without the window, in `bench/frames.bend`, the cost is small (8.4 against 9.1 ms), so most of it comes with the window's loop, which hands control back to the runtime every frame.

## What we do about it

`nix/bendoom.nix` starts the game with `--threads 1`. That is enough for now. This ticket matters the day the game wants real parallel work: that work must first win back these 2.5 ms.

## What to do

Find where the time goes before reporting: build the window bench, run it with 1, 2 and 12 threads, and profile the 12-thread run.

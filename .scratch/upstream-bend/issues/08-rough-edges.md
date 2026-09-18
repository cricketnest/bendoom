# 08: Rough edges in Bend that are not bugs

Things that cost the agents time. None gives a wrong result. Kept here so they can go upstream as requests, or into `docs/bend.md` if they bite again. Bend commit e6676b0.

**Status:** needs-triage

- **`App.run` makes the program compile for the GPU when it starts.** Base drops each frame with `Image.drop!`, and one `!` anywhere makes the binary build its GPU program at launch. Upstream knows: its own netcode demo says so. `src/game.bend` has its own loop for this reason.
- **Freeing things is half the level walk's time.** A profile of the renderer showed 50% in the runtime's `term_drop` and 20% in `span_fade`, which count references when a shared record is opened. Removing boxed fields from the hot record changed nothing, so the cause is not confirmed. Ticket 11 of milestone 3 has the numbers.
- **Type errors print the fully worked-out term.** A wrong field count on `Player{..}` printed kilobytes of nested `U32.sub(U32.add(..` instead of the line as written. The agents cut bend's output with `cut -c1-1500`.
- **`List.map` only takes a list that is used once.** `List.length`, `List.append` and `List.concat` take any list; `List.map` wants `List<&1, A>`, so a copyable list has no map. We write the loop by hand.
- **`is` and `where` cannot be names,** and the guide has no list of reserved words. The error is clear.
- **A proof of an equation can be used once and cannot be erased.** `+h` on one gives `expected : Data / observed : Type`; `-h` gives `expected : -e / observed : e`. The guide's "erased variables can only appear in types and proofs" reads as if `-h` should work.
- **The guide says almost nothing about writing an effect in C.** It gives the naming rule and no more. To return an array from C the agent read `comp.ts` for `IoWork`, `io_work`, `io_done`, `blk_new` and the rest. No effect shipped with Bend returns an array.
- **`bend -o` cannot link an extra library.** It adds `-lX11` and `-lasound` when it sees their headers and reads only `CC` and `CUDA_HOME`. An effect that needs another library has to be built by hand from `bend -o file.c`.
- **A program cannot read its command line.** The binary accepts only `--threads`, `--gpu`, `--gpu-build` and `--help`. We pass the WAD's path in `BENDOOM_IWAD`.
- **The X11 window has no class name, no position and no fullscreen,** and its smallest size equals its largest, so a tiling desktop floats it. niri shows `App ID: (unset)`, and a window rule has to match on the title.

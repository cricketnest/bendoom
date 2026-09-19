# 07: Which C headers our own effect gets depends on the GPU build

**What is wrong:** Bend pastes a program's C effects into the same C file as its runtime. The runtime includes `<sys/stat.h>` only when it is built for CUDA. So an effect that calls `fstat` compiles on a CUDA machine and fails everywhere else:

```
error: call to undeclared function 'fstat'; ISO C99 and later do not support implicit function declarations
Error: clang failed to build /tmp/wad_dir
```

**Where:** `bend2/comp.ts` lines 3183 to 3188, commit e6676b0: `<fcntl.h>` and `<sys/stat.h>` sit under `#elif BEND_CUDA`. `<fcntl.h>` is included again for everyone at line 5154; `<sys/stat.h>` is not. I checked the source on 18 Sep 2026.

**Status:** ready-for-human (small upstream report)

## What we do about it

Bendoom's own C effect, `bytes_read.c`, included both headers itself until the repo's C went on 19 Sep 2026 (ticket 09). That is the right habit anyway; the bug is that the guide never says which headers an effect may count on, and the answer changes with the machine.

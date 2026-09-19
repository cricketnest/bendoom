# 01: The runtime paints the window the slow way

**What is wrong:** Bend shows a frame as a tree of squares (`Image`). To paint the window, the runtime asks the tree for the colour of each window pixel, one at a time, starting from the top of the tree every time. Our window has 1.23 million pixels and the tree is nine levels deep under each, so that is about eleven million steps a frame. It takes more than half of our frame.

**Where:** `window_fill` in `bend2/effs/window_frame.c`, Bend commit e6676b0. It only happens on Linux without a GPU build; on a Mac or with CUDA the GPU paints the window.

**Status:** ready-for-human (report upstream; patched locally in `nix/bend.nix` since milestone 5)

## What I measured

18 Sep 2026, x86_64 benchmark host on battery, one thread, the window on Xvfb, the view from the start.

| | per frame |
| --- | --- |
| our renderer | 5.9 ms |
| our fold into the tree, and freeing the old tree | 2.4 ms |
| the runtime's paint (`window_fill`) | 14.2 ms |
| sending the picture to X | 1.4 ms |
| the whole frame | 25.4 ms, 39 frames a second |

## The fix

Walk the tree once. When you reach a square of one colour, paint the whole square. In a throwaway copy of the runtime this took the paint from 14.2 ms to about 1.2 ms. I compared every pixel with the old paint over 600 walking frames: none differed. The game then ran at the runtime's own limit of 60 frames a second, and at 80 with that limit off.

```c
static void window_rect(Corpus H, Term t, u32 i, u32 x0, u32 y0, u32* pix, u32 w, u32 h) {
  if (x0 >= w || y0 >= h) {
    return;
  }
  while (i == 0 && term_tag(t) == TAG_CTR) {
    t = H[term_rfc(t) ? H[term_loc(t)] >> 24 : term_loc(t)];
  }
  if (term_tag(t) == TAG_CTR) {
    Loc l = term_rfc(t) ? H[term_loc(t)] >> 24 : term_loc(t);
    i -= 1;
    window_rect(H, H[l + 0], i, x0, y0, pix, w, h);
    window_rect(H, H[l + 1], i, x0 + (1u << i), y0, pix, w, h);
    window_rect(H, H[l + 2], i, x0, y0 + (1u << i), pix, w, h);
    window_rect(H, H[l + 3], i, x0 + (1u << i), y0 + (1u << i), pix, w, h);
    return;
  }
  u32 c  = (u32)term_loc(t) & 0xFFFFFF;
  u32 x1 = x0 + (1u << i) < w ? x0 + (1u << i) : w;
  u32 y1 = y0 + (1u << i) < h ? y0 + (1u << i) : h;
  for (u32 y = y0; y < y1; y += 1) {
    for (u32 x = x0; x < x1; x += 1) {
      pix[y * w + x] = c;
    }
  }
}
```

In `window_fill`, the two loops that call `window_pix` for every pixel become one call: `window_rect(e.mem, image, k, 0, 0, pix, w, h)`. `window_pix` is then the device kernel's alone, so it moves under `#ifdef __CUDACC_RTC__` in `comp.ts`.

## What to do

Report this upstream with the numbers and the fix. Milestone 5's busiest view, the blue key's room full of things, held 31 frames a second with the slow paint, under the 35 the game must hold, so `nix/window-fill.patch` is this fix, applied by `nix/bend.nix` (milestone 5, ticket 12). It can break when the Bend pin moves; drop it once upstream paints this way.

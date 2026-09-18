# 09: Two-sided middle textures through the masked pass

**What to build:** Grates and bars. Each stored range records the silhouette and sprite clips vanilla's drawseg records, and a two-sided seg with a middle texture keeps its per-column texture columns. After the planes, the masked pass walks the ranges back to front and draws each masked column through its posts, with the texture mid from the pegging flag (bottom-pegged from the higher floor, else from the lower ceiling) and the light from the seg, clipped by the range's sprite clips. Milestone 5's sprites will join this pass. The render test gains a frame facing a masked middle texture.

**Blocked by:** 08 (Floors, ceilings and the sky)

**Status:** resolved

- [x] Two-sided middle textures draw with their transparent parts see-through, behind nearer walls and in front of farther ones
- [x] Ranges record silhouette and sprite clips as vanilla's drawsegs do, with no static limit
- [x] The render test's frame at the masked position is pinned to Freedoom, passes on both lanes, and the flake check stays green

## Comments

Done. The seg loop was re-derived around a per-column plan first (`Segs.Plan`: the wall's rows, the upper wall's bottom and the lower's top, the clips after, the scale), worked out once and read by the drawing, the marking and the recording, where before the drawing and the marking each worked the rows out for themselves; every pinned frame came through the change identical. A stored range now carries what vanilla's drawseg does: its silhouette with the heights it clips sprites below and above (`Segs.sil`, vanilla's rules, a masked texture and a shut door clipping both ways at any height), and, a column each in column order, the texture columns of a two-sided middle texture (none without one) and the ceiling and floor clips the range left, which are 168 and -1 whatever the rows where vanilla points at its constant arrays (a one-sided wall, a door shut above or below). They are lists on the range, so vanilla's openings array and its limit do not exist. Every range records its clips, where vanilla records them only for a silhouette or a masked texture: the lists cost a few thousand cells a frame and the loop has one branch fewer.

`src/masked.bend` is the walls' half of `R_DrawMasked`: after the planes, the ranges newest first, so farthest first drawn; for each with texture columns, `R_RenderMaskedSegRange` (the texture standing on the higher floor when pegged to the bottom, else hanging from the lower ceiling, moved by the side's row offset; the light from the seg with fake contrast; the scale stepped from the range's first) and `R_DrawMaskedColumn` a post at a time, the posts read from three before the texture column's texels in the copied patch, each held inside the range's clips and drawn from its own first row. Milestone 5's sprites join this pass. Vanilla's medusa effect on a multi-patch masked texture is not reproduced: such a column's posts would be read from composed texels; the walk stops at 256 posts, and Freedoom's E1M1 has none.

In the frames the grates are where Chocolate Doom's start screen has them: the grid fences either side of the gate, in front of the hall and behind the gate's posts, and the bars across the window west of the start, which is the render test's masked position (`grate -416 256 180`). Four of the six pinned frames changed and were looked at before re-pinning; all stay fully covered. Both lanes pass. `bench/frames.bend`: 1.28 s for a hundred frames with the load, about 12 ms a frame.

# 04: Sprites and masked walls share the depth pass

**What to build:** Sprites and two-sided middle textures are drawn by one vanilla-order masked pass. A masked wall behind a sprite draws its overlapping columns first. A masked wall in front clips or covers the sprite. Columns already drawn are not drawn again when the pass finishes. The old masked-walls-only pass leaves the codebase rather than surviving beside the replacement.

**Blocked by:** 03 (Sprites obey walls, ledges and each other)

**Status:** ready-for-agent

- [ ] The masked pass walks visible sprites back to front and stored wall ranges newest to oldest as vanilla does
- [ ] A masked range behind a sprite draws only the overlapping columns still pending
- [ ] A masked range in front contributes its silhouette clips without drawing behind the sprite
- [ ] Remaining masked columns draw once after the last sprite
- [ ] The former walls-only traversal is deleted
- [ ] Render tests cover both depth orders through a grate or bars
- [ ] Chocolate Doom reports zero differing sprite and masked-texture pixels for both orders
- [ ] The existing masked-middle-texture frames remain unchanged
- [ ] Both lanes pass and the renderer's existing bounds laws stay green


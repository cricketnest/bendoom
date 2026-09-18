# 09: Two-sided middle textures through the masked pass

**What to build:** Grates and bars. Each stored range records the silhouette and sprite clips vanilla's drawseg records, and a two-sided seg with a middle texture keeps its per-column texture columns. After the planes, the masked pass walks the ranges back to front and draws each masked column through its posts, with the texture mid from the pegging flag (bottom-pegged from the higher floor, else from the lower ceiling) and the light from the seg, clipped by the range's sprite clips. Milestone 5's sprites will join this pass. The render test gains a frame facing a masked middle texture.

**Blocked by:** 08 (Floors, ceilings and the sky)

**Status:** ready-for-agent

- [ ] Two-sided middle textures draw with their transparent parts see-through, behind nearer walls and in front of farther ones
- [ ] Ranges record silhouette and sprite clips as vanilla's drawsegs do, with no static limit
- [ ] The render test's frame at the masked position is pinned to Freedoom, passes on both lanes, and the flake check stays green

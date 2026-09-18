# 07: Walls textured and lit as vanilla draws them

**What to build:** The wall columns become vanilla's. Each stored range selects its textures by side and pegging (upper, lower and one-sided middle; two-sided middle textures wait for ticket 09), its offset from the seg's offset plus the sidedef's, its texture mid from the pegging flags and the sidedef's row offset, and its light from the sector level with fake contrast for walls along an axis. Per column the texture column is the offset minus the tangent times the distance, the reciprocal scale is the 32-bit division, the light index is the scale shifted and capped, and the texel loop reads the fraction's top bits masked to 127 through the light's colormap. The render test's hash and samples update, and it gains frames at hand-chosen positions: a lit and a dark sector, a step and a lowered ceiling.

**Blocked by:** 04 (Textures compose from patches), 06 (Walls drawn in perspective)

**Status:** ready-for-agent

- [ ] One-sided walls, upper and lower textures draw with vanilla's pegging and offsets, seen in the window against Chocolate Doom by eye
- [ ] Walls dim with distance through the scaled-light table, sectors' light levels apply, and axis-aligned walls carry fake contrast
- [ ] Closed laws pin the texture column, the reciprocal scale and the light index cap at known inputs
- [ ] The render test's frames at the start and the chosen positions are pinned to Freedoom, pass on both lanes, and the flake check stays green

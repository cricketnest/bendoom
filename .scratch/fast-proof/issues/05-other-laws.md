# Move the remaining concrete laws to tests

**Status:** ready-for-agent
**Blocked by:** none

Bytes and the WAD: le32_bytes, wad_kinds, vec_of_list. Fixed point:
fixed_of_map, fixed_order, fixed_mul_signs, fixed_mul_overflow,
fixed_mul_one, fixed_div. Angles: fine_quarter, tables_vanilla,
angle_of_axes, sprite_rotation. Keys: cmd_tables, turn_script. The
renderer: solid_clips, view_edges, view_sweep, view_rows, wall_scale,
light_tables, wall_column, silhouettes, sprite_columns, sprite_order,
plane_span. Animations: animation_frames. Music: mus_events,
smpte_division, song_faults, buffer_spills, heap_ties. Sound lumps:
sfx_refusals. The status bar: key_boxes, arms_numbers.

Owns the existing tests their domains match (`tests/bytes.bend`,
`tests/music.bend`, `tests/sfx.bend`, `tests/render.bend`) and new files for
the rest; tickets 01 to 04 only create files.

## Acceptance

- Each listed law is a test line or deleted as covered, per `../spec.md`.
- Tests pass on both lanes; `bend PROOF.bend` passes, and the render rest
  positions stay at zero differing pixels.

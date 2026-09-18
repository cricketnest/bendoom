# The laws. The human states them; PROOF.bend must prove them.
import Base
import ./src/bytes.bend as B
import ./src/wad.bend as W
import ./src/vec.bend as V
import ./src/fixed.bend as F
import ./src/angle.bend as A
import ./src/tables.bend as T
import ./src/level.bend as L
import ./src/keys.bend as K
import ./src/sim.bend as S

# Bytes and the WAD
# -----------------

# LAW: a NUL ends a padded name: whatever follows it is dropped.
law text_nul_ends:
  for rest: List<&2, Char>
  {B.Bytes.text.cons(0, rest) == [] : List<&2, Char>}

# LAW: any other byte is kept, as its char, before what follows.
law text_byte_kept:
  for rest: List<&2, Char>
  {B.Bytes.text.cons(65, rest) == Char.from_u32(65) <> rest : List<&2, Char>}

# LAW: four bytes assemble little-endian: 78 56 34 12 reads as
# 0x12345678 (sanity).
law le32_bytes:
  {B.Bytes.le32(120, 86, 52, 18) == 305419896 : U32}

# LAW: "IWAD" is kind 1, "PWAD" kind 2, anything else 0 (sanity).
law wad_kinds:
  {(W.Wad.kind(1145132873), W.Wad.kind(1145132880), W.Wad.kind(0))
    == (1, 2, 0) : U32 & U32 & U32}

# LAW: the first lump called name is at 0 when it heads the list.
law index_head:
  for +name: String
  for pos: U32
  for size: U32
  for rest: List<&2, W.Wad.Lump>
  {W.Wad.index(name, W.Lump{pos, size, name} <> rest) == Some{0n} : Maybe<Nat>}

# LAW: a tree built from a list reads back its elements by position
# (sanity).
law vec_of_list:
  {(V.Vec.get(V.Vec.of_list([5, 6, 7], 3), 0), V.Vec.get(V.Vec.of_list([5, 6, 7], 3), 1),
    V.Vec.get(V.Vec.of_list([5, 6, 7], 3), 2)) == (5, 6, 7) : U32 & U32 & U32}

# Fixed point
# -----------

# LAW: a map coordinate converts by sign extension then shift: 0xFFFF
# is -1.0 and 0x7FFF is 32767.0 (sanity).
law fixed_of_map:
  {(F.Fixed.of_map(65535), F.Fixed.of_map(32767)) == (4294901760, 2147418112) : U32 & U32}

# LAW: the signed order puts -1 below 0 and 0 below 1 (sanity).
law fixed_order:
  {(F.Fixed.lt(4294967295, 0), F.Fixed.lt(0, 1), F.Fixed.lt(0, 4294967295))
    == (True{}, True{}, False{}) : Bool & Bool & Bool}

# LAW: multiply answers Doom's FixedMul for positive, negative and mixed
# signs: 3 * 0.5, -0.5 * -0.5, 3 * -0.5 (sanity).
law fixed_mul_signs:
  {(F.Fixed.mul(196608, 32768), F.Fixed.mul(4294934528, 4294934528),
    F.Fixed.mul(196608, 4294934528)) == (98304, 16384, 4294868992) : U32 & U32 & U32}

# LAW: the split-word multiply keeps the low word of the exact product
# shifted right by sixteen where the product overflows: 0x7FFFFFFF
# squared is 0x3FFFFFFF00000001, whose bits 16 to 47 are 0xFFFF0000
# (sanity).
law fixed_mul_overflow:
  {F.Fixed.mul(2147483647, 2147483647) == 4294901760 : U32}

# LAW: multiply by one is the identity and commutes, on samples (sanity;
# the universal statement is in the ticket's comments).
law fixed_mul_one:
  {(F.Fixed.mul(4294901760, 65536), F.Fixed.mul(65536, 4294901760),
    F.Fixed.mul(51200, 59392), F.Fixed.mul(59392, 51200))
    == (4294901760, 4294901760, 46400, 46400) : U32 & U32 & U32 & U32}

# LAW: divide answers Doom's FixedDiv: 1 / 3, -1 / 3, and saturates to
# MAXINT and MININT by sign where the quotient would not fit (sanity).
law fixed_div:
  {(F.Fixed.div(65536, 196608), F.Fixed.div(4294901760, 196608), F.Fixed.div(196608, 0),
    F.Fixed.div(4294770688, 0)) == (21845, 4294945451, 2147483647, 2147483648)
    : U32 & U32 & U32 & U32}

# Angles
# ------

# LAW: the fine angle of a binary angle is its top thirteen bits: a
# quarter turn is 2048 (sanity).
law fine_quarter:
  {A.Angle.fine(1073741824) == 2048 : U32}

# LAW: the vanilla sine table at zero, a quarter turn, a half turn, and
# the cosine at zero; the tangent at the table's middle (sanity).
law tables_vanilla:
  {(A.Angle.sin(V.Vec.of_list(T.Tables.finesine(), 10240), 0),
    A.Angle.sin(V.Vec.of_list(T.Tables.finesine(), 10240), 2048),
    A.Angle.sin(V.Vec.of_list(T.Tables.finesine(), 10240), 4096),
    A.Angle.cos(V.Vec.of_list(T.Tables.finesine(), 10240), 0),
    List.get(&2, U32, T.Tables.finetangent(), 2048n))
    == (25, 65535, 4294967271, 65535, Some{25}) : U32 & U32 & U32 & U32 & Maybe<&2, U32>}

# LAW: the angle of a vector: due east is 0, due north a quarter turn
# (sanity).
law angle_of_axes:
  {(A.Angle.of(V.Vec.of_list(T.Tables.tantoangle(), 2049), 65536, 0),
    A.Angle.of(V.Vec.of_list(T.Tables.tantoangle(), 2049), 0, 65536))
    == (0, 1073741823) : U32 & U32}

# Keys
# ----

# LAW: the last press of a key wins: pressing or releasing a key twice
# leaves the keys as the second press alone would, whatever the key.
law last_press:
  for +code: U32
  for d1: Bool
  for +d2: Bool
  for +keys: K.Keys
  {K.Keys.press(code, d2, K.Keys.press(code, d1, keys))
    == K.Keys.press(code, d2, keys) : K.Keys}

# LAW: the arrows and WASD fold to the same keys: up and W, down and S.
law arrows_wasd:
  for +down: Bool
  for +keys: K.Keys
  {(K.Keys.press(63232, down, keys), K.Keys.press(63233, down, keys))
    == (K.Keys.press(119, down, keys), K.Keys.press(115, down, keys)) : K.Keys & K.Keys}

# LAW: walking forward is 25 a tic, running 50; strafing 24 and 40; a
# turn is 320 for its first five tics, then 640, or 1280 running
# (sanity).
law cmd_tables:
  {(K.Keys.cmd(K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}}, 5),
    K.Keys.cmd(K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}}, 6),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, True{}}, 6))
    == (K.Cmd{25, 0, 0}, K.Cmd{50, 0, 0}, K.Cmd{0, 24, 0}, K.Cmd{0, 4294967256, 0},
      K.Cmd{0, 0, 320}, K.Cmd{0, 0, 640}, K.Cmd{0, 0, 4294966016})
    : K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd}

# The sim
# -------

# LAW: one tic of no keys from rest leaves the player where it was, on
# any level, at any position.
law tic_rest:
  for +level: L.Level
  for +x: U32
  for +y: U32
  {(S.Player.x(S.Sim.tic(level, K.Keys.none(),
      S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, 0, 0})),
    S.Player.y(S.Sim.tic(level, K.Keys.none(),
      S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, 0, 0})))
    == (x, y) : U32 & U32}

# The closed laws below stand on Level.room: one sector, no lines, the
# floor at 0 and the ceiling at 128 map units. Every number is computed by hand
# from vanilla's formulas.

# LAW: one tic forward from rest at angle zero thrusts 25 * 2048 along
# the facing (51199 along x through the cosine 65535, 19 along y through
# the sine 25) and then decays it by 0.90625: momentum 46399, 17,
# position 0.78125, 0.000290 (the numbers of milestone 2's ticket 08
# hand check). The eye is the rest height plus the bob: the squared
# momentum over four is 9999, and half of it times the clock's sine 25
# is 1 (sanity).
law tic_from_rest:
  {S.Sim.tic(L.Level.room(0, 128),
    K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}},
    S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, 0, 0})
    == S.Player{51199, 19, 0, 0, 46399, 17, 0, 0, 8388608, 2686976, 0, 2686977, 0, 1} : S.Player}

# LAW: standing still on the floor puts the eye 41 above it, at any
# position, whatever the eye was.
law eye_rest:
  for x: U32
  for y: U32
  {S.Player.viewz(S.Sim.tic(L.Level.room(0, 128), K.Keys.none(),
    S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, 0, 0})) == 2686976 : U32}

# LAW: 64 above the floor, the first airborne tic sets the fall to twice
# gravity without moving, the second moves by it and adds gravity once;
# the eye sits 41 above the height the tic began at (sanity).
law fall_gravity:
  {(S.Sim.run(1n, L.Level.room(0, 128), K.Keys.none(),
      S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, 0, 0}),
    S.Sim.run(2n, L.Level.room(0, 128), K.Keys.none(),
      S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, 0, 0}))
    == (S.Player{0, 0, 4194304, 0, 0, 0, 4294836224, 0, 8388608, 2686976, 0, 6881280, 0, 1},
      S.Player{0, 0, 4063232, 0, 0, 0, 4294770688, 0, 8388608, 2686976, 0, 6881280, 0, 2})
    : S.Player & S.Player}

# LAW: landing at 9 a tic dips the view by an eighth of it, -1.125;
# landing at 8 a tic does not (sanity).
law landing_dip:
  {(S.Sim.tic(L.Level.room(0, 128), K.Keys.none(),
      S.Player{0, 0, 65536, 0, 0, 0, 4294377472, 0, 8388608, 2686976, 0, 0, 0, 0}),
    S.Sim.tic(L.Level.room(0, 128), K.Keys.none(),
      S.Player{0, 0, 65536, 0, 0, 0, 4294443008, 0, 8388608, 2686976, 0, 0, 0, 0}))
    == (S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 4294893568, 2752512, 0, 1},
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2752512, 0, 1})
    : S.Player & S.Player}

# LAW: the bob at the clock's peak (tic 5, sine 65535). The first tic of
# a run from rest has momentum 102398, 39, whose square over four is
# 39998, and half of it bobs the eye by 19998. At 30 a tic the square
# over four is 14745600, capped at 16 units, and half of it bobs the eye
# by 524280, a hair under 8 units (sanity).
law bob_run_and_cap:
  {(S.Player.viewz(S.Sim.tic(L.Level.room(0, 128),
      K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}},
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, 0, 5})),
    S.Player.viewz(S.Sim.tic(L.Level.room(0, 128), K.Keys.none(),
      S.Player{0, 0, 0, 0, 1966080, 0, 0, 0, 8388608, 2686976, 0, 0, 0, 5})))
    == (2706974, 3211256) : U32 & U32}

# LAW: a floor 16 above the player's feet lifts the player onto it, cuts
# the view height by the 16 to 25, and sets it recovering by an eighth
# of the gap, 2 a tic (sanity).
law step_up_dip:
  {S.Sim.tic(L.Level.room(0, 128), K.Keys.none(),
    S.Player{0, 0, 0, 0, 0, 0, 0, 1048576, 8388608, 2686976, 0, 0, 0, 0})
    == S.Player{0, 0, 1048576, 0, 0, 0, 0, 1048576, 8388608, 1638400, 131072, 2686976, 0, 1}
    : S.Player}

# LAW: replaying two scripts in turn is replaying their concatenation,
# for all scripts, levels and players.
law replay_append:
  for a: List<&2, K.Keys>
  for b: List<&2, K.Keys>
  for +level: L.Level
  for p: S.Player
  {S.Sim.replay(List.append(&2, K.Keys, a, b), level, p)
    == S.Sim.replay(b, level, S.Sim.replay(a, level, p)) : S.Player}

# LAW: free is pinned to the geometry: when a position is free, every
# line listed in the blockmap cells its box touches satisfies the
# distance condition, whichever position in the list it holds.
law free_pins_lines:
  for +level: L.Level
  for +x: U32
  for +y: U32
  for k: Nat
  for i: U32
  for listed: {Some{i} == List.get(&2, U32, S.Sim.lines(level, (x - S.Sim.radius() : U32),
    (y - S.Sim.radius() : U32), (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), k)
    : Maybe<&2, U32>}
  for free: {True{} == S.Sim.free(level, x, y) : Bool}
  {True{} == S.Sim.line_ok(level, x, y, i) : Bool}

# LAW: the distance condition on numbers: a one-sided wall from (0, 0)
# to (0, 128) is touched and crossed by the player's box at (8, 64), and
# neither at (40, 64); a two-sided line without the blocking flag is not
# solid, one with it is (sanity).
law line_geometry:
  {(S.Sim.box_touches(524288, 4194304, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_crosses(524288, 4194304, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_touches(2621440, 4194304, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_crosses(2621440, 4194304, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.solid(L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.solid(L.Line{0, 0, 0, 8388608, 4, 0, 1}),
    S.Sim.solid(L.Line{0, 0, 0, 8388608, 5, 0, 1}))
    == (True{}, True{}, False{}, False{}, True{}, False{}, True{})
    : Bool & Bool & Bool & Bool & Bool & Bool & Bool}

# LAW: one tic from a free position answers a free position, for all
# levels, held keys and players.
law tic_keeps_free:
  for +level: L.Level
  for +keys: K.Keys
  for p: S.Player
  for free: {True{} == S.Sim.free(level, S.Player.x(p), S.Player.y(p)) : Bool}
  {True{} == S.Sim.free(level, S.Player.x(S.Sim.tic(level, keys, p)),
    S.Player.y(S.Sim.tic(level, keys, p))) : Bool}

# LAW: the wall law: replaying any script from a free position, the
# start included, leaves the player free of solid walls.
law replay_keeps_free:
  for script: List<&2, K.Keys>
  for +level: L.Level
  for +p: S.Player
  for free: {True{} == S.Sim.free(level, S.Player.x(p), S.Player.y(p)) : Bool}
  {True{} == S.Sim.free(level, S.Player.x(S.Sim.replay(script, level, p)),
    S.Player.y(S.Sim.replay(script, level, p))) : Bool}

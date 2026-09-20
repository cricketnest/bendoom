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
import ./src/random.bend as M
import ./src/things.bend as H
import ./src/inventory.bend as I
import ./src/sound.bend as Sn
import ./src/clip.bend as C
import ./src/project.bend as P
import ./src/draw.bend as D
import ./src/segs.bend as R
import ./src/planes.bend as N
import ./src/gfx.bend as G
import ./src/sprites.bend as Z
import ./src/masked.bend as Q
import ./src/opl.bend as O
import ./src/midi.bend as Mi
import ./src/player.bend as Pl
import ./src/song.bend as Sg
import ./src/sfx.bend as X
import ./src/bar.bend as Y

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

# LAW: the rotation a thing shows, by R_ProjectSprite's rule from the
# angle of the thing from the eye and the thing's facing, 0 for its
# front. Facing east, it shows its front to an eye east of it (the angle
# 180), its back to one west (0), 2 to one north (270) and 6 to one
# south (90); facing north, its front to one north. A rotation spans
# the eighth of a turn centred on its angle, so the front runs from
# 157.5 degrees (0x70000000) and one less is 7 (sanity).
law sprite_rotation:
  {(Z.Sprites.rotation(A.Angle.ang180(), 0), Z.Sprites.rotation(0, 0), Z.Sprites.rotation(A.Angle.ang270(), 0),
    Z.Sprites.rotation(A.Angle.ang90(), 0), Z.Sprites.rotation(A.Angle.ang270(), A.Angle.ang90()),
    Z.Sprites.rotation(1879048192, 0), Z.Sprites.rotation(1879048191, 0))
    == (0, 4, 2, 6, 0, 0, 7) : U32 & U32 & U32 & U32 & U32 & U32 & U32}

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
# turn is 320 for its first five tics, then 640, or 1280 running; Space
# is the use button (sanity).
law cmd_tables:
  {(K.Keys.cmd(K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, 5),
    K.Keys.cmd(K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, 6),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, 6),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}, False{}, False{}}, 0))
    == (K.Cmd{25, 0, 0, 0}, K.Cmd{50, 0, 0, 0}, K.Cmd{0, 24, 0, 0}, K.Cmd{0, 4294967256, 0, 0},
      K.Cmd{0, 0, 320, 0}, K.Cmd{0, 0, 640, 0}, K.Cmd{0, 0, 4294966016, 0},
      K.Cmd{0, 0, 0, 2})
    : K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd}

# LAW: the lowest held number key wins, whatever the higher ones do, as
# G_BuildTiccmd's loop breaks at the first: BT_CHANGE, 4, with the key's
# number less one at BT_WEAPONSHIFT, 3.
law lowest_number_wins:
  for two: Bool
  for three: Bool
  {(K.Keys.change(True{}, two, three), K.Keys.change(False{}, True{}, three),
    K.Keys.change(False{}, False{}, True{}), K.Keys.change(False{}, False{}, False{}))
    == (4, 12, 20, 0) : U32 & U32 & U32 & U32}

# LAW: the held count lives in the input: seven tics of the left key
# from a fresh input turn 320 five times, then 640 (sanity).
law turn_script:
  {K.Input.script(7n, K.Input{K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, 0})
    == [K.Cmd{0, 0, 320, 0}, K.Cmd{0, 0, 320, 0}, K.Cmd{0, 0, 320, 0},
      K.Cmd{0, 0, 320, 0}, K.Cmd{0, 0, 320, 0}, K.Cmd{0, 0, 640, 0},
      K.Cmd{0, 0, 640, 0}] : List<&2, K.Cmd>}

# The sim
# -------

# No things.
def Closed.none() -> H.Things:
  H.Things.of([], 0, H.Thing.you())

# No player sprite showing, which a tic leaves as it is: what the players
# of the laws on movement carry.
def Closed.unarmed() -> S.Psprites:
  S.Psprites{S.Psprite{None{}, 0, 0, 0}, S.Psprite{None{}, 0, 0, 0}}

# A level's first state with the player as given, at a clock.
def Closed.state(p: S.Player, level: L.Level, clock: U32) -> S.State:
  S.State{p, level, Closed.none(), V.Leaf{0}, [], 0, clock, False{}, False{}, [], 0}

# LAW: one tic of the idle command from rest leaves the player where it
# was, on any level, at any position.
law tic_rest:
  for +level: L.Level
  for +x: U32
  for +y: U32
  {(S.Player.x(S.State.player(S.Sim.tic(K.Cmd.idle(),
      Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()}, level, 0)))),
    S.Player.y(S.State.player(S.Sim.tic(K.Cmd.idle(),
      Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()}, level, 0)))))
    == (x, y) : U32 & U32}

# LAW: a tic counts on the clock, and an ended level's tic changes
# nothing, whatever the command.
law tic_counts:
  for +cmd: K.Cmd
  for +p: S.Player
  for +level: L.Level
  for +clock: U32
  {(S.State.clock(S.Sim.tic(cmd, Closed.state(p, level, clock))),
    S.Sim.tic(cmd, S.State{p, level, Closed.none(), V.Leaf{0}, [], 0, clock, True{}, False{}, [], 0}))
    == ((clock + 1 : U32), S.State{p, level, Closed.none(), V.Leaf{0}, [], 0, clock, True{}, False{}, [], 0}) : U32 & S.State}

# The closed laws below stand on Level.room: one sector, no lines, the
# floor at 0 and the ceiling at 128 map units. Every number is computed
# by hand from vanilla's formulas.

# The player after a script in the room, from a player and a clock.
def Closed.room(script: List<&2, K.Cmd>, p: S.Player, clock: U32) -> S.Player:
  S.State.player(S.Sim.replay(script, Closed.state(p, L.Level.room(0, 128), clock)))

# LAW: one tic forward from rest at angle zero thrusts 25 * 2048 along
# the facing (51199 along x through the cosine 65535, 19 along y through
# the sine 25) and then decays it by 0.90625: momentum 46399, 17,
# position 0.78125, 0.000290 (the numbers of milestone 2's ticket 08
# hand check). The eye is the rest height plus the bob: the squared
# momentum over four is 9999, and half of it times the clock's sine 25
# is 1 (sanity).
law tic_from_rest:
  {Closed.room([K.Cmd{25, 0, 0, 0}], S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()}, 0)
    == S.Player{51199, 19, 0, 0, 46399, 17, 0, 0, 8388608, 2686976, 0, 2686977, [], I.Inventory.start(), Closed.unarmed()} : S.Player}

# LAW: standing still on the floor puts the eye 41 above it, at any
# position, whatever the eye was.
law eye_rest:
  for x: U32
  for y: U32
  {S.Player.viewz(Closed.room([K.Cmd.idle()], S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 0))
    == 2686976 : U32}

# LAW: 64 above the floor, the first airborne tic sets the fall to twice
# gravity without moving, the second moves by it and adds gravity once;
# the eye sits 41 above the height the tic began at (sanity).
law fall_gravity:
  {(Closed.room([K.Cmd.idle()], S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 0),
    Closed.room([K.Cmd.idle(), K.Cmd.idle()], S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 0))
    == (S.Player{0, 0, 4194304, 0, 0, 0, 4294836224, 0, 8388608, 2686976, 0, 6881280, [], I.Inventory.start(), Closed.unarmed()},
      S.Player{0, 0, 4063232, 0, 0, 0, 4294770688, 0, 8388608, 2686976, 0, 6881280, [], I.Inventory.start(), Closed.unarmed()})
    : S.Player & S.Player}

# LAW: landing at 9 a tic dips the view by an eighth of it, -1.125;
# landing at 8 a tic does not (sanity).
law landing_dip:
  {(Closed.room([K.Cmd.idle()], S.Player{0, 0, 65536, 0, 0, 0, 4294377472, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 0),
    Closed.room([K.Cmd.idle()], S.Player{0, 0, 65536, 0, 0, 0, 4294443008, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 0))
    == (S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 4294893568, 2752512, [], I.Inventory.start(), Closed.unarmed()},
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2752512, [], I.Inventory.start(), Closed.unarmed()})
    : S.Player & S.Player}

# LAW: the bob at the clock's peak (tic 5, sine 65535). The first tic of
# a run from rest has momentum 102398, 39, whose square over four is
# 39998, and half of it bobs the eye by 19998. At 30 a tic the square
# over four is 14745600, capped at 16 units, and half of it bobs the eye
# by 524280, a hair under 8 units (sanity).
law bob_run_and_cap:
  {(S.Player.viewz(Closed.room([K.Cmd{50, 0, 0, 0}],
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 5)),
    S.Player.viewz(Closed.room([K.Cmd.idle()],
      S.Player{0, 0, 0, 0, 1966080, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 5)))
    == (2706974, 3211256) : U32 & U32}

# LAW: a floor 16 above the player's feet lifts the player onto it, cuts
# the view height by the 16 to 25, and sets it recovering by an eighth
# of the gap, 2 a tic (sanity).
law step_up_dip:
  {Closed.room([K.Cmd.idle()], S.Player{0, 0, 0, 0, 0, 0, 0, 1048576, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Closed.unarmed()}, 0)
    == S.Player{0, 0, 1048576, 0, 0, 0, 0, 1048576, 8388608, 1638400, 131072, 2686976, [], I.Inventory.start(), Closed.unarmed()} : S.Player}

# The pistol's closed laws are p_pspr.c by hand: P_BringUpWeapon starts
# the sprite at WEAPONBOTTOM, 128, and P_SetPsprite runs A_Raise as it
# enters the raise state, row 60, so it starts at 122; each tic's
# A_Raise takes 6 more.

# A player at rest in the room with the pistol coming up.
def Closed.armed() -> S.Player:
  S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(),
    S.Psprites.start(L.Level.sine(L.Level.room(0, 128)), H.Thing.pistol())}

# LAW: the pistol is 38 after 14 tics, and the 15th puts it at the top,
# 32, in the ready state, row 59, where A_WeaponReady with no bob sets
# column 1; the flash shows nothing and is where the weapon is after a
# tic (sanity).
law pistol_rises:
  {(S.Player.psprites(Closed.armed()),
    S.Player.psprites(Closed.room(List.replicate(K.Cmd, 14n, K.Cmd.idle()), Closed.armed(), 0)),
    S.Player.psprites(Closed.room(List.replicate(K.Cmd, 15n, K.Cmd.idle()), Closed.armed(), 0)))
    == (S.Psprites{S.Psprite{Some{60}, 1, 0, 7995392}, S.Psprite{None{}, 0, 0, 0}},
      S.Psprites{S.Psprite{Some{60}, 1, 0, 2490368}, S.Psprite{None{}, 0, 0, 2490368}},
      S.Psprites{S.Psprite{Some{59}, 1, 65536, 2097152}, S.Psprite{None{}, 0, 65536, 2097152}})
    : S.Psprites & S.Psprites & S.Psprites}

# LAW: the ready pistol at the bob's lowest, tic 16, a quarter of its
# turn of 64: at 30 a tic the bob is capped at 16 units, 1048576; the
# cosine -25 moves the column by -400 from 65536, and the sine 65535
# lowers the row by 1048560 from 2097152 (sanity).
law pistol_bobs:
  {S.Player.psprites(Closed.room([K.Cmd.idle()], S.Player{0, 0, 0, 0, 1966080, 0, 0, 0, 8388608, 2686976, 0, 0, [],
      I.Inventory.start(), S.Psprites{S.Psprite{Some{59}, 1, 65536, 2097152}, S.Psprite{None{}, 0, 65536, 2097152}}},
      16))
    == S.Psprites{S.Psprite{Some{59}, 1, 65136, 3145712}, S.Psprite{None{}, 0, 65136, 3145712}} : S.Psprites}

# The movers' closed laws stand on a literal level: a west room (sector
# 0, ceiling 128), a door (sector 1, shut at 0) and an east room (sector
# 2, ceiling 72), all floors at 0, 16 units of door from x 64 to x 80.
# Line 0 is the door's west face, its front to the west, special 1; line
# 1 its east face, its front to the east, special 117. One blockmap
# cell lists both, and one subsector stands for every point. Every
# number below is computed by hand from vanilla's constants. The
# blockmap's origin is a parameter: at 0 a player in the west room is in
# the one cell, so a mover re-clips it; moved east, the player is in no
# sector's block box, and a long replay costs the checker no position
# check. Its THINGS records, so many, are a parameter too.
def Closed.level(ox: U32, records: V.Vec, count: U32) -> L.Level:
  L.Level.grouped(L.Level{L.Geo{V.Vec.of_list([0, 1, 4, 0, 1, 2, 3, 4, 2, 3], 10),
    V.Vec.of_list([0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 1], 12), V.Vec.of_list([64, 128, 64, 0, 80, 0, 80, 128], 8),
    V.Vec.of_list([0, 1, 0, 0, 0, 0], 6), V.Vec.of_list([1, 0], 2), V.Leaf{0}, 32768,
    L.Blockmap{V.Vec.of_list([0, 0, 1, 1, 5, 0, 0, 1, 65535], 9), ox, 0, 1, 1},
    L.Things{records, count, V.Leaf{0}, V.Leaf{0}}, [], [],
    V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049), V.Leaf{0}, 2, 3,
    V.Leaf{0}, V.Leaf{0}, V.Leaf{0}},
    V.Vec.of_list([0, 8388608, 160, 0, 0, 160, 0, 4718592, 160], 9), V.Vec.of_list([1, 0, 117, 0], 4)})

def Closed.doors() -> L.Level:
  Closed.level(0, V.Leaf{0}, 0)

# A player at rest on the floor at 0, under a ceiling.
def Closed.player(x: U32, y: U32, angle: U32, ceilz: U32) -> S.Player:
  S.Player{x, y, 0, angle, 0, 0, 0, 0, ceilz, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()}

# The west room's player, 32 units from the door and facing it, and the
# east room's.
def Closed.west() -> S.State:
  Closed.state(Closed.player(2097152, 4194304, 0, 8388608), Closed.doors(), 0)

def Closed.east() -> S.State:
  Closed.state(Closed.player(7340032, 4194304, 2147483648, 4718592), Closed.doors(), 0)

# The door level with a barrel, radius 10, standing between its two
# faces at x 72, y 64, linked into the one cell as P_SetThingPosition
# links it.
def Closed.barrel() -> L.Level:
  L.Level.link(L.Level.unlinked(Closed.doors(), 1), 0, 4718592, 4194304, 2035)

# What a ray of the use key's 64 units, east from (32, 64), meets, and
# what the use key's visitor makes of the same ray.
def Closed.met(level: L.Level) -> List<&2, S.Sim.Meet>:
  S.Sim.meets(level, True{}, True{}, 2097152, 4194304, 6291456, 4194304)

def Closed.reach(level: L.Level) -> S.Sim.Reach:
  S.Sim.path(~S.Sim.Reach, ~S.Sim.use.visit, level, True{}, False{}, 2097152, 4194304, 6291456, 4194304,
    S.Nothing{})

# LAW: one traversal gathers the lines of the cell it crosses and the
# things linked in it, and hands them over in order of distance: the ray
# meets the door's west face at half its length, the barrel at 0.625 and
# the east face at 0.75, so the thing comes between the two lines. The
# fractions are P_InterceptVector by hand. For the west face, from
# (64, 128) to (64, 0): num is (64 - 32) >> 8 times its dy, -1048576,
# den is its dy >> 8 times the ray's dx, -2097152, and the quotient is
# 32768. For the east face, from (80, 0) to (80, 128): num 1572864, den
# 2097152, quotient 49152. For the barrel, PIT_AddThingIntercepts takes
# the diagonal of its box that a rising ray can cross, from (62, 74) to
# (82, 54): num is (62 - 32) >> 8 times -20 plus (64 - 74) >> 8 times
# 20, -204800, den is -20 >> 8 times the ray's dx, -327680, and the
# quotient is 40960. The use key asks for lines alone, so the barrel is
# not gathered for it, and its refusal at the first line with a special
# ends the walk before the east face (sanity).
law ray_meets:
  {(Closed.met(Closed.barrel()), Closed.reach(Closed.barrel()))
    == ([S.Meet{32768, True{}, 0}, S.Meet{40960, False{}, 0}, S.Meet{49152, True{}, 1}], S.Special{0})
    : List<&2, S.Sim.Meet> & S.Sim.Reach}

# The state after a tic of use and then idle tics.
def Closed.used(idle: Nat, s: S.State) -> S.State:
  S.Sim.replay(K.Cmd{0, 0, 0, 2} <> List.replicate(K.Cmd, idle, K.Cmd.idle()), s)

def Closed.ceil(s: S.State, sector: U32) -> U32:
  L.Level.ceil(S.State.level(s), sector)

# LAW: a manual door, vanilla's T_VerticalDoor. The top is 4 under the
# lower ceiling beside it, 68. Used on tic 1 it is 2 up after that tic
# and at 68 after tic 34; tic 35 would pass, so it lands and the wait
# starts; the count reaches zero on tic 185, which only turns the door;
# tic 186 is the first step down, tic 219 shuts it, and tic 220 passes
# the floor and ends the thinker (sanity).
law door_timeline:
  {(Closed.ceil(Closed.used(0n, Closed.west()), 1), Closed.ceil(Closed.used(32n, Closed.west()), 1),
    Closed.ceil(Closed.used(33n, Closed.west()), 1), Closed.ceil(Closed.used(184n, Closed.west()), 1),
    Closed.ceil(Closed.used(185n, Closed.west()), 1), Closed.ceil(Closed.used(217n, Closed.west()), 1),
    Closed.ceil(Closed.used(218n, Closed.west()), 1), S.State.thinkers(Closed.used(218n, Closed.west())),
    S.State.thinkers(Closed.used(219n, Closed.west())))
    == (131072, 4325376, 4456448, 4456448, 4325376, 131072, 0,
      [S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()}], [])
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & List<&2, S.Thinker> & List<&2, S.Thinker>}

# LAW: the blazing door moves 8 a tic: 64 after tic 8, tic 9 would pass
# and lands on 68; the wait ends on tic 159, tic 160 is 60, tic 167 is
# 4, and tic 168 lands on the floor and ends the thinker (sanity).
law blazing_door_timeline:
  {(Closed.ceil(Closed.used(0n, Closed.east()), 1), Closed.ceil(Closed.used(7n, Closed.east()), 1),
    Closed.ceil(Closed.used(8n, Closed.east()), 1), Closed.ceil(Closed.used(158n, Closed.east()), 1),
    Closed.ceil(Closed.used(159n, Closed.east()), 1), Closed.ceil(Closed.used(166n, Closed.east()), 1),
    Closed.ceil(Closed.used(167n, Closed.east()), 1), S.State.thinkers(Closed.used(167n, Closed.east())))
    == (524288, 4194304, 4456448, 4456448, 3932160, 262144, 0, [])
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & List<&2, S.Thinker>}

# A state of the literal level with one mover running and a player at
# rest at a place under a ceiling.
def Closed.moving(level: L.Level, t: S.Thinker, x: U32, y: U32, ceilz: U32) -> S.State:
  S.State{Closed.player(x, y, 0, ceilz), level, Closed.none(), V.Leaf{0}, [t], 0, 0, False{}, False{}, [], 0}

def Closed.idled(n: Nat, s: S.State) -> S.State:
  S.Sim.replay(List.replicate(K.Cmd, n, K.Cmd.idle()), s)

# LAW: a moving floor carries the player standing on it, vanilla's
# P_ThingHeightClip. The west room's floor goes down 4 a tic. A player at
# (32, 64) is in the one cell of the sector's block box: after a tic the
# floor, the player's height and the player's floor are -4, the view
# height is still 41 with no delta, so no dip, and the eye, worked out
# when the tic began, follows a tic later. A player at (200, 64) is a
# cell outside the box, and is left where it was (sanity).
law floor_carries:
  {(S.State.player(Closed.idled(1n, Closed.moving(Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()},
      2097152, 4194304, 8388608))),
    S.State.player(Closed.idled(2n, Closed.moving(Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()},
      2097152, 4194304, 8388608))),
    S.State.player(Closed.idled(1n, Closed.moving(Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()},
      13107200, 4194304, 8388608))))
    == (S.Player{2097152, 4194304, 4294705152, 0, 0, 0, 0, 4294705152, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()},
      S.Player{2097152, 4194304, 4294443008, 0, 0, 0, 0, 4294443008, 8388608, 2686976, 0, 2424832, [], I.Inventory.start(), Closed.unarmed()},
      S.Player{13107200, 4194304, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()})
    : S.Player & S.Player & S.Player}

# LAW: a door that closes on the player goes back up. From 68, 2 a tic,
# over a player 56 tall standing across both its faces at (72, 64): 56
# after 6 tics; the 7th would be 54, which the player does not fit, so
# the step is undone and the door is back on its plan; 58 after the 8th
# (sanity).
law door_crushed:
  {(Closed.ceil(Closed.idled(6n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448)), 1),
    Closed.ceil(Closed.idled(7n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448)), 1),
    S.State.thinkers(Closed.idled(7n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448))),
    Closed.ceil(Closed.idled(8n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448)), 1))
    == (3670016, 3670016,
      [S.Mover{1, True{}, 131072, [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()}], 3801088)
    : U32 & U32 & List<&2, S.Thinker> & U32}

# The literal level with line 0 a walk-over turbo floor (special 36; its
# tag 0 is every sector), the door sector's floor at 16, its ceiling and
# the east room's at 128, and a player at x moving east at a speed.
def Closed.turbo(x: U32, momx: U32) -> S.State:
  S.State{S.Player{x, 4194304, 0, 0, momx, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Closed.unarmed()},
    L.Level.special.put(L.Level.plane.put(L.Level.plane.put(L.Level.plane.put(Closed.doors(), 1, False{},
      1048576), 1, True{}, 8388608), 2, True{}, 8388608), 0, 36), Closed.none(), V.Leaf{0}, [], 0, 0, False{}, False{}, [], 0}

def Closed.floors(+s: S.State) -> U32 & U32 & U32:
  (L.Level.floor(S.State.level(s), 0), L.Level.floor(S.State.level(s), 1), L.Level.floor(S.State.level(s), 2))

# LAW: a walk-over line fires from the move that crosses it, once, and
# special 36 is vanilla's turboLower: 4 a tic down to the highest floor
# around, plus 8 when that is not the floor's own. A player at (60, 64)
# moving 8 a tic east crosses line 0 on the first tic. Sector 1, floor
# 16 between floors at 0, goes to 8: 12 after that tic, 8 after the
# second, its thinker gone on the third. Sectors 0 and 2, floors at 0
# beside one at 16, go to 24, which is above them, and a travel down to
# a height above lands at once. The line's special is 0 from the first
# tic. A player at (44, 64) moving 6 a tic ends with its box across the
# line and its centre short of it: nothing starts, the special stays
# (sanity).
law turbo_floor_crossed:
  {(Closed.floors(Closed.idled(1n, Closed.turbo(3932160, 524288))),
    Closed.floors(Closed.idled(2n, Closed.turbo(3932160, 524288))),
    S.State.thinkers(Closed.idled(3n, Closed.turbo(3932160, 524288))),
    L.Level.special(S.State.level(Closed.idled(1n, Closed.turbo(3932160, 524288))), 0),
    S.State.thinkers(Closed.idled(1n, Closed.turbo(2883584, 393216))),
    L.Level.special(S.State.level(Closed.idled(1n, Closed.turbo(2883584, 393216))), 0))
    == ((1572864, 786432, 1572864), (1572864, 524288, 1572864), [], 0, [], 36)
    : (U32 & U32 & U32) & (U32 & U32 & U32) & List<&2, S.Thinker> & U32 & List<&2, S.Thinker> & U32}

# The literal level for the switched movers: the door sector's floor at
# -32 and its ceiling at 128, line 0 a switch of the given special (its
# tag 0 is every sector), its front's middle texture 1, a switch whose
# partner is 2, and the blockmap's origin 48 east, so the west room's
# player at (32, 64) is in no block box.
def Closed.switched(special: U32) -> S.State:
  S.State{Closed.player(2097152, 4194304, 0, 8388608),
    L.Level.textured(L.Level.special.put(L.Level.plane.put(L.Level.plane.put(Closed.level(3145728, V.Leaf{0}, 0), 1,
      False{}, 4292870144), 1, True{}, 8388608), 0, special), V.Vec.of_list([0, 0, 1], 12), V.Vec.of_list([0, 2, 1], 3)),
    Closed.none(), V.Vec.of_list([0, 0, 1], 12), [], 0, 0, False{}, False{}, [], 0}

def Closed.lifts() -> S.State:
  Closed.switched(62)

def Closed.seen(+s: S.State) -> U32 & U32:
  (L.Level.floor(S.State.level(s), 0), V.Vec.get(S.State.sidetex(s), 2))

# LAW: the lift, vanilla's downWaitUpStay, and the switch that calls it.
# The use on tic 1 gives each sector a lift (the west room's: 4 a tic
# down to -32, the lowest floor around, 105 tics there, back up to 0;
# the door sector's is at its lowest already, so its first tic lands)
# and swaps the switch to 2 with a button of 35 tics, 34 after that tic.
# The west room's floor is -4 after tic 1 and -32 after tic 8; tic 9
# lands and the wait starts; the count reaches zero on tic 114; -28
# after tic 115, 0 after tic 122, and its thinker gone on tic 123. The
# switch shows 2 through tic 34 and 1 again from tic 35 (sanity).
law lift_timeline:
  {(S.State.thinkers(Closed.used(0n, Closed.lifts())), Closed.seen(Closed.used(7n, Closed.lifts())),
    Closed.seen(Closed.used(33n, Closed.lifts())), Closed.seen(Closed.used(34n, Closed.lifts())),
    Closed.seen(Closed.used(113n, Closed.lifts())), Closed.seen(Closed.used(114n, Closed.lifts())),
    Closed.seen(Closed.used(121n, Closed.lifts())), S.State.thinkers(Closed.used(122n, Closed.lifts())))
    == ([S.Mover{0, False{}, 262144, [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}],
        [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      S.Mover{1, False{}, 262144, [S.Hold{105}, S.Travel{False{}, 4292870144}],
        [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 4292870144}], S.Sim.noise.lift()},
      S.Mover{2, False{}, 262144, [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}],
        [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      S.Button{0, 2, 1, 34}],
      (4292870144, 2), (4292870144, 2), (4292870144, 1), (4292870144, 1), (4293132288, 1), (0, 1), [])
    : List<&2, S.Thinker> & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32)
      & List<&2, S.Thinker>}

# LAW: the switched floor, vanilla's lowerFloorToLowest: 1 a tic down to
# the lowest floor around, its own included. The use on tic 1 starts
# the west room and the east room toward the door sector's -32; the door
# sector is at its lowest already, so its first tic lands and ends it.
# The west room is -1 after tic 1 and -32 after tic 32; tic 33 would
# pass it, so it lands and both thinkers end. The switch works once: its
# line has no special from the first tic (sanity).
law floor_lowered:
  {(L.Level.floor(S.State.level(Closed.used(0n, Closed.switched(23))), 0),
    S.State.thinkers(Closed.used(0n, Closed.switched(23))),
    L.Level.special(S.State.level(Closed.used(0n, Closed.switched(23))), 0),
    L.Level.floor(S.State.level(Closed.used(31n, Closed.switched(23))), 0),
    S.State.thinkers(Closed.used(32n, Closed.switched(23))))
    == (4294901760, [S.Mover{0, False{}, 65536, [S.Travel{True{}, 4292870144}], [S.Travel{True{}, 4292870144}], S.Sim.noise.floor()},
      S.Mover{2, False{}, 65536, [S.Travel{True{}, 4292870144}], [S.Travel{True{}, 4292870144}], S.Sim.noise.floor()}], 0,
      4292870144, [])
    : U32 & List<&2, S.Thinker> & U32 & U32 & List<&2, S.Thinker>}

# LAW: a lift that rises into a player who does not fit goes back down.
# The west room's floor at -32 under a ceiling at 40, rising 4 a tic
# under a player 56 tall: -16 after 4 tics, which leaves 56; the 5th
# would leave 52, so it is undone and the lift is back on its plan; -20
# after the 6th (sanity).
law lift_crushed:
  {(L.Level.floor(S.State.level(Closed.idled(4n, Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      2097152, 4194304, 2621440))), 0),
    L.Level.floor(S.State.level(Closed.idled(5n, Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      2097152, 4194304, 2621440))), 0),
    L.Level.floor(S.State.level(Closed.idled(6n, Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      2097152, 4194304, 2621440))), 0))
    == (4293918720, 4293918720, 4293656576) : U32 & U32 & U32}

# LAW: use held across two tics fires on the first alone: after a live
# tic whose command holds use, no command is a press, whatever the
# state was.
law use_fires_once:
  for forward: U32
  for side: U32
  for turn: U32
  for buttons: U32
  for +next: K.Cmd
  for player: S.Player
  for level: L.Level
  for things: H.Things
  for sidetex: V.Vec
  for thinkers: List<&2, S.Thinker>
  for rnd: U32
  for clock: U32
  for usedown: Bool
  for sounds: List<&2, Sn.Sound.Event>
  for mrnd: U32
  for held: {True{} == K.Cmd.use(K.Cmd{forward, side, turn, buttons}) : Bool}
  {S.Sim.pressed(next, S.State.usedown(S.Sim.tic(K.Cmd{forward, side, turn, buttons},
    S.State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, sounds, mrnd}))) == False{} : Bool}

# LAW: once means once: a line fired for good has no special afterwards,
# whatever the state and the line.
law once_clears:
  for +line: U32
  for s: S.State
  {L.Level.special(S.State.level(S.Sim.once(line, s)), line) == 0 : U32}

# The literal level with an exit switch: line 0's special is 11, the
# middle texture of its front side is numbered 1, and textures 1 and 2
# are each other's partner.
def Closed.exit() -> L.Level:
  L.Level.textured(L.Level.special.put(Closed.doors(), 0, 11), V.Vec.of_list([0, 0, 1], 3),
    V.Vec.of_list([0, 2, 1], 3))

# The west room's player after two idle tics and then a tic of use.
def Closed.exited() -> S.State:
  S.Sim.replay([K.Cmd.idle(), K.Cmd.idle(), K.Cmd{0, 0, 0, 2}], S.State{Closed.player(2097152, 4194304, 0, 8388608),
    Closed.exit(), Closed.none(), L.Level.sidetex(Closed.exit()), [], 0, 0, False{}, False{}, [], 0})

# LAW: the exit switch, vanilla's special 11: P_ChangeSwitchTexture, then
# G_ExitLevel, and the tic runs on. Used on tic 3, the level has ended
# with the clock at 3, the line's special is gone and its side shows the
# switch's partner; a tic of any command after that changes nothing.
law exit_ends:
  for +cmd: K.Cmd
  {(S.State.ended(Closed.exited()), S.State.clock(Closed.exited()),
    L.Level.special(S.State.level(Closed.exited()), 0), V.Vec.get(S.State.sidetex(Closed.exited()), 2),
    S.Sim.tic(cmd, Closed.exited()))
    == (True{}, 3, 0, 2, Closed.exited()) : Bool & U32 & U32 & U32 & S.State}

# What a listener d units south of a source hears, facing an angle.
def Closed.heard(d: U32, facing: U32) -> U32 & U32:
  Sn.Sound.adjust(L.Level.sine(L.Level.room(0, 128)), L.Level.tanto(L.Level.room(0, 128)), 0,
    F.Fixed.neg(F.Fixed.of_map(d)), facing, 0, 0)

# LAW: S_AdjustSoundParams, by hand from s_sound.c and tables.c. The
# source is due north, at angle ANG90 - 1. Facing east the angle between
# is fine index 2047, whose sine 65535 swings 95 left of 128; facing west
# it is 6143, sine -65535, and the floor of -95.99 swings 96 right;
# facing south 4095, sine 25, centred; facing north 8191, sine -25, whose
# product floors to -1: dead ahead is 129. At 400 units 800 of the 1000
# are left, 64 * 800 / 1000 = 51; 200 is still 64 and 201 is 63; 1184
# leaves 16, volume 1, and 1185 leaves 15, which rounds to 0 and is not
# heard, 15 units inside the clipping distance; 1201 is clipped (sanity).
law sound_places:
  {(Closed.heard(400, 0), Closed.heard(400, 2147483648), Closed.heard(400, 3221225472),
    Closed.heard(200, 1073741824), Closed.heard(201, 1073741824), Closed.heard(1184, 1073741824),
    Closed.heard(1185, 1073741824), Closed.heard(1201, 1073741824))
    == ((51, 33), (51, 224), (51, 128), (64, 129), (63, 129), (1, 129), (0, 129), (0, 129))
    : (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32)}

# LAW: the manual door's sounds, where T_VerticalDoor and EV_VerticalDoor
# start them: sfx_doropn, 20, on the tic of the use, nothing on the next,
# sfx_dorcls, 21, on tic 185 as the wait ends, and nothing as it shuts.
# The door's lines span x 64 to 80 and y 0 to 128, so it sounds from
# (72, 64), 40 east of the west room's player, who faces it: full volume,
# and dead ahead is 129. Two starts, two draws from M_Random (sanity).
law door_sounds:
  {(S.State.sounds(Closed.used(0n, Closed.west())), S.State.sounds(Closed.used(1n, Closed.west())),
    S.State.sounds(Closed.used(184n, Closed.west())), S.State.sounds(Closed.used(218n, Closed.west())),
    S.State.mrnd(Closed.used(218n, Closed.west())))
    == ([Sn.Start{20, Sn.Sector{1}, 64, 129}], [], [Sn.Start{21, Sn.Sector{1}, 64, 129}], [], 2)
    : List<&2, Sn.Sound.Event> & List<&2, Sn.Sound.Event> & List<&2, Sn.Sound.Event> & List<&2, Sn.Sound.Event> & U32}

# LAW: the lift's switch. EV_DoPlat starts sfx_pstart, 18, in each sector
# of the tag, P_ChangeSwitchTexture clicks sfx_swtchn, 23, from nobody
# since no button runs yet, and the door sector's lift, at its lowest
# already, lands on its first tic with sfx_pstop, 19. The three sectors'
# boxes are centred at (64, 64), (72, 64) and (80, 64), all dead ahead of
# the player at (32, 64) and nearer than 200. The button pops back on
# tic 35 with a click from the map's origin, where vanilla's mistaken
# origin reads its place: 32 + 64 - 16 = 80 away, at angle ANG270 - 1 -
# tantoangle[1024], fine index 5539, sine -58617, whose -85.86 floors to
# 86 right of 128 (sanity).
law switch_sounds:
  {(S.State.sounds(Closed.used(0n, Closed.lifts())), S.State.sounds(Closed.used(34n, Closed.lifts())))
    == ([Sn.Start{18, Sn.Sector{0}, 64, 129}, Sn.Start{18, Sn.Sector{1}, 64, 129}, Sn.Start{18, Sn.Sector{2}, 64, 129},
      Sn.Start{23, Sn.Nobody{}, 64, 128}, Sn.Start{19, Sn.Sector{1}, 64, 129}],
      [Sn.Start{23, Sn.Spot{0, 0}, 64, 214}])
    : List<&2, Sn.Sound.Event> & List<&2, Sn.Sound.Event>}

# LAW: vanilla's random table, its first entries and its last, and the
# index wrapping at 256 (sanity).
law random_table:
  {(M.Random.at(0), M.Random.at(1), M.Random.at(2), M.Random.at(3), M.Random.at(255),
    M.Random.next(0), M.Random.next(255))
    == (0, 8, 109, 220, 249, 1, 0) : U32 & U32 & U32 & U32 & U32 & U32 & U32}

# The lights' closed laws stand on the literal level with the west room
# at a light and the door sector, light 160, given the light Doom spawns
# for a sector special, the random index at 1 as it is once Doom has
# spawned the player.
def Closed.lit(special: U32, west: U32) -> S.State:
  S.Sim.light.spawn(special, 1, S.State{Closed.player(2097152, 4194304, 0, 8388608),
    L.Level.light.put(Closed.doors(), 0, west), Closed.none(), V.Leaf{0}, [], 1, 0, False{}, False{}, [], 0})

def Closed.light(s: S.State) -> U32:
  L.Level.sector.light(S.State.level(s), 1)

# LAW: the random blink, vanilla's T_LightFlash, between 160 and the 96
# beside it. Its first count is the table's entry 2, 109, masked with 64,
# plus 1: 65. On tic 65 it goes dark for entry 3, 220, masked with 7,
# plus 1: 5 tics. On tic 70 it is bright again for entry 4, 222, masked
# with 64, plus 1 (sanity).
law blink_counts:
  {(S.State.thinkers(Closed.lit(1, 96)), Closed.light(Closed.idled(64n, Closed.lit(1, 96))),
    Closed.light(Closed.idled(65n, Closed.lit(1, 96))), S.State.thinkers(Closed.idled(65n, Closed.lit(1, 96))),
    Closed.light(Closed.idled(69n, Closed.lit(1, 96))), Closed.light(Closed.idled(70n, Closed.lit(1, 96))),
    S.State.thinkers(Closed.idled(70n, Closed.lit(1, 96))), S.State.rnd(Closed.idled(70n, Closed.lit(1, 96))))
    == ([S.Blink{1, 65, 96, 160, 7, 64, True{}}], 160, 96, [S.Blink{1, 5, 96, 160, 7, 64, True{}}], 96, 160,
      [S.Blink{1, 65, 96, 160, 7, 64, True{}}], 4)
    : List<&2, S.Thinker> & U32 & U32 & List<&2, S.Thinker> & U32 & U32 & List<&2, S.Thinker> & U32}

# LAW: the slow strobe in step, vanilla's T_StrobeFlash: dark from the
# first tic for 35, bright for 5. Beside a room at 96 its dark level is
# 96; beside rooms no darker than its own 160 it is 0 (sanity).
law strobe_timeline:
  {(Closed.light(Closed.lit(12, 96)), Closed.light(Closed.idled(1n, Closed.lit(12, 96))),
    Closed.light(Closed.idled(35n, Closed.lit(12, 96))), Closed.light(Closed.idled(36n, Closed.lit(12, 96))),
    Closed.light(Closed.idled(40n, Closed.lit(12, 96))), Closed.light(Closed.idled(41n, Closed.lit(12, 96))),
    Closed.light(Closed.idled(1n, Closed.lit(12, 160))), Closed.light(Closed.idled(36n, Closed.lit(12, 160))),
    Closed.light(Closed.idled(41n, Closed.lit(12, 160))))
    == (160, 96, 96, 160, 160, 96, 0, 160, 0) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# LAW: the glow, vanilla's T_Glow, 8 a tic between 160 and the 96 beside
# it: 104 after tic 7; tic 8 would reach 96, so it is undone and the glow
# turns; 112 after tic 9, 152 after tic 14; tic 15 would reach 160, is
# undone and turns it; 144 after tic 16 (sanity).
law glow_turns:
  {(Closed.light(Closed.idled(1n, Closed.lit(8, 96))), Closed.light(Closed.idled(7n, Closed.lit(8, 96))),
    Closed.light(Closed.idled(8n, Closed.lit(8, 96))), Closed.light(Closed.idled(9n, Closed.lit(8, 96))),
    Closed.light(Closed.idled(14n, Closed.lit(8, 96))), Closed.light(Closed.idled(15n, Closed.lit(8, 96))),
    Closed.light(Closed.idled(16n, Closed.lit(8, 96))))
    == (152, 104, 104, 112, 152, 152, 144) : U32 & U32 & U32 & U32 & U32 & U32 & U32}

# Pickups and keys
# ----------------

# The west room's player holding an inventory, beside the door with
# line 0 made vanilla's blue locked door, special 26.
def Closed.locked(inv: I.Inventory) -> S.State:
  Closed.state(S.Player.holding(Closed.player(2097152, 4194304, 0, 8388608), inv),
    L.Level.special.put(Closed.doors(), 0, 26), 0)

# LAW: the blue locked door, vanilla's EV_VerticalDoor for special 26.
# Used on tic 1 with no card, or with the yellow card alone, it stays
# shut; with the blue card or the blue skull it is the manual door, 2
# up after that tic (sanity).
law blue_door_locked:
  {(Closed.ceil(Closed.used(0n, Closed.locked(I.Inventory.start())), 1),
    Closed.ceil(Closed.used(0n, Closed.locked(I.Inventory.card(2, I.Inventory.start()))), 1),
    Closed.ceil(Closed.used(0n, Closed.locked(I.Inventory.card(1, I.Inventory.start()))), 1),
    Closed.ceil(Closed.used(0n, Closed.locked(I.Inventory.card(8, I.Inventory.start()))), 1))
    == (0, 0, 131072, 131072) : U32 & U32 & U32 & U32}

# The west room's player holding an inventory at (x, 64), on the floor
# under a ceiling at 128, moving by a momentum a tic, among things named
# under 128, on the literal level.
def Closed.among(inv: I.Inventory, x: U32, momx: U32, momy: U32, things: List<&2, H.Thing>) -> S.State:
  S.State.populated(things, 128, S.State{S.Player{x, 4194304, 0, 0, momx, momy, 0, 0, 8388608, 2686976, 0, 2686976, [],
    inv, Closed.unarmed()}, Closed.doors(), Closed.none(), V.Leaf{0}, [], 0, 0, False{}, False{}, [], 0})

# A thing named id of a type at (x, y) and z in the west room, its state
# lasting: the laws below are about its touch and its heights, not its
# tics.
def Closed.thing(id: U32, kind: U32, x: U32, y: U32, z: U32) -> H.Thing:
  H.Thing{id, kind, x, y, z, 0, 8388608, 0, 0, 0, 4294967295}

# The pickup laws' expected values are p_inter.c's P_TouchSpecialThing,
# P_GiveCard, P_GiveBody, P_GiveArmor, P_GivePower, P_GiveAmmo and
# P_GiveWeapon, d_items.c's clips and p_user.c's P_PlayerThink in
# Chocolate Doom 3.1.1, by hand.

# A change to an inventory: its health, its armour points and type, its
# cards as bits in card_t order, its ammo in ammotype_t order (bullets,
# shells, cells, rockets), the backpack with the caps it doubles, 400
# 100 600 100, the weapons owned, the strength counter, the tally or the
# flash.
type Closed.Edit is Data:
  Health{n: U32}
  Armour{points: U32, kind: U32}
  Cards{bits: U32}
  Ammo{rounds: List<&2, U32>}
  Backpack{}
  Weapons{bits: U32}
  Strength{n: U32}
  Items{n: U32}
  Flash{n: U32}

def Closed.edit(inv: I.Inventory, e: Closed.Edit) -> I.Inventory:
  match inv e:
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Health{n}:
      I.Inventory{n, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Armour{points, kind}:
      I.Inventory{health, points, kind, cards, ammo, caps, backpack, weapons, powers, items, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Cards{bits}:
      I.Inventory{health, armour, armourtype, bits, ammo, caps, backpack, weapons, powers, items, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Ammo{rounds}:
      I.Inventory{health, armour, armourtype, cards, V.Vec.of_list(rounds, 4), caps, backpack, weapons, powers, items,
        bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Backpack{}:
      I.Inventory{health, armour, armourtype, cards, ammo, V.Vec.of_list([400, 100, 600, 100], 4), True{}, weapons,
        powers, items, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Weapons{bits}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, bits, powers, items, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Strength{n}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
        V.Vec.set(powers, I.Inventory.pw_strength(), n), items, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Items{n}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, n, bonus}
    case I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
      bonus} Flash{n}:
      I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, n}

# G_PlayerReborn's inventory with changes.
def Closed.inv(es: List<&2, Closed.Edit>) -> I.Inventory:
  List.foldl(~&2, ~Closed.Edit, ~I.Inventory, ~Closed.edit, es, I.Inventory.start())

# What a pickup leaves: the names of the things alive, and the
# inventory.
type Closed.Got is Data:
  Got{ids: List<&2, U32>, inv: I.Inventory}

def Closed.ids(things: List<&2, H.Thing>) -> List<&2, U32>:
  match things:
    case []:
      []
    case H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, tics} <> rest:
      id <> Closed.ids(rest)

def Closed.kept(+s: S.State) -> Closed.Got:
  Got{Closed.ids(H.Things.list(S.State.things(s))), S.Player.inv(S.State.player(s))}

# What is left after n tics of the west room's player, holding an
# inventory, walking north by a momentum a tic toward a thing of a type
# at (32, 80), record 1.
def Closed.walk(n: Nat, momy: U32, inv: I.Inventory, kind: U32) -> Closed.Got:
  Closed.kept(Closed.idled(n, Closed.among(inv, 2097152, 0, momy, [Closed.thing(1, kind, 2097152, 5242880, 0)])))

# What is left after the tic that brings the player 8 from the thing, in
# its reach.
def Closed.offer(inv: I.Inventory, kind: U32) -> Closed.Got:
  Closed.walk(1n, 524288, inv, kind)

# Moving north at 8 a tic from (32, 64) past a bloody mess (record 3)
# and a blue card (record 87), both at (32, 112), toward another blue
# card (record 90) at (32, 400).
def Closed.passing() -> S.State:
  Closed.among(I.Inventory.start(), 2097152, 0, 524288, [Closed.thing(3, 10, 2097152, 7340032, 0),
    Closed.thing(87, 5, 2097152, 7340032, 0), Closed.thing(90, 5, 2097152, 26214400, 0)])

# LAW: P_TouchSpecialThing for the blue card. Tic 1 moves the player to
# 72, 40 short of the card, and the reach is its radius 20 and the
# player's 16. Friction leaves 7.25 a tic, so tic 2 moves it to 79.25,
# 32.75 short: record 87 is gone and no other, the blue card is held,
# and P_GiveCard's 6 and the pickup's 6 set the flash to 12. On tic 3,
# still in reach of where it was, nothing is touched again and the
# flash fades to 11 (sanity).
law key_taken:
  {[Closed.kept(Closed.idled(1n, Closed.passing())), Closed.kept(Closed.idled(2n, Closed.passing())),
    Closed.kept(Closed.idled(3n, Closed.passing()))]
    == [Got{[3, 87, 90], I.Inventory.start()}, Got{[3, 90], Closed.inv([Cards{1}, Flash{12}])},
      Got{[3, 90], Closed.inv([Cards{1}, Flash{11}])}] : List<&2, Closed.Got>}

# LAW: a move of 20 a tic is tried in halves, to 74 and then 84, and a
# blue card at (32, 100) is in reach of both: the first takes it, the
# second finds it gone, so the flash is 12 and not 18 (sanity).
law key_taken_once:
  {Closed.kept(Closed.idled(1n, Closed.among(I.Inventory.start(), 2097152, 0, 1310720,
    [Closed.thing(87, 5, 2097152, 6553600, 0)])))
    == Got{[], Closed.inv([Cards{1}, Flash{12}])} : Closed.Got}

def Closed.key_at(z: U32) -> Closed.Got:
  Closed.kept(Closed.idled(1n, Closed.among(I.Inventory.start(), 2097152, 0, 524288,
    [Closed.thing(87, 5, 2097152, 5242880, z)])))

# LAW: vertical reach. A tic moves the player to 72, 8 from a blue card
# at (32, 80); the card is taken with its bottom 56 over the player's
# feet and not 57, and 8 under them and not 9 (sanity).
law key_reach:
  {[Closed.key_at(3670016), Closed.key_at(3735552), Closed.key_at(4294443008), Closed.key_at(4294377472)]
    == [Got{[], Closed.inv([Cards{1}, Flash{12}])}, Got{[87], I.Inventory.start()},
      Got{[], Closed.inv([Cards{1}, Flash{12}])}, Got{[87], I.Inventory.start()}] : List<&2, Closed.Got>}

# The player at (40, 64) moving east at 12 a tic into the shut door,
# with a blue card at (86, 64) past it.
def Closed.shut_out() -> S.State:
  Closed.idled(1n, Closed.among(I.Inventory.start(), 2621440, 786432, 0, [Closed.thing(87, 5, 5636096, 4194304, 0)]))

# LAW: P_CheckPosition touches things before it checks lines. The move
# to 52 puts the box across the shut door, whose opening refuses it,
# but its position check has already taken the card, 34 away; the
# slide that follows stops the player short of the door, at most 48,
# from where the card is out of reach (sanity).
law key_through_door:
  {(Closed.kept(Closed.shut_out()), F.Fixed.le(S.Player.x(S.State.player(Closed.shut_out())), 3145728))
    == (Got{[], Closed.inv([Cards{1}, Flash{12}])}, True{}) : Closed.Got & Bool}

# LAW: the health bonus is always taken and counted. From 100 it makes
# 101, from 199 200, and at 200 it adds nothing and still goes; the
# flash is 6 (sanity).
law health_bonus:
  {[Closed.offer(I.Inventory.start(), 2014), Closed.offer(Closed.inv([Health{199}]), 2014),
    Closed.offer(Closed.inv([Health{200}]), 2014)]
    == [Got{[], Closed.inv([Health{101}, Items{1}, Flash{6}])}, Got{[], Closed.inv([Health{200}, Items{1}, Flash{6}])},
      Got{[], Closed.inv([Health{200}, Items{1}, Flash{6}])}] : List<&2, Closed.Got>}

# LAW: the stimpack heals 10 up to 100 and is not counted: 89 makes 99,
# 99 makes 100, and at 100 it stays, the inventory untouched (sanity).
law stimpack:
  {[Closed.offer(Closed.inv([Health{89}]), 2011), Closed.offer(Closed.inv([Health{99}]), 2011),
    Closed.offer(I.Inventory.start(), 2011)]
    == [Got{[], Closed.inv([Health{99}, Flash{6}])}, Got{[], Closed.inv([Health{100}, Flash{6}])},
      Got{[1], I.Inventory.start()}] : List<&2, Closed.Got>}

# LAW: the medikit heals 25 up to 100 and is not counted: 74 makes 99,
# 75 and 99 make 100, and at 100, or at 150 from bonuses, it stays
# (sanity).
law medikit:
  {[Closed.offer(Closed.inv([Health{74}]), 2012), Closed.offer(Closed.inv([Health{75}]), 2012),
    Closed.offer(Closed.inv([Health{99}]), 2012), Closed.offer(I.Inventory.start(), 2012),
    Closed.offer(Closed.inv([Health{150}]), 2012)]
    == [Got{[], Closed.inv([Health{99}, Flash{6}])}, Got{[], Closed.inv([Health{100}, Flash{6}])},
      Got{[], Closed.inv([Health{100}, Flash{6}])}, Got{[1], I.Inventory.start()},
      Got{[1], Closed.inv([Health{150}])}] : List<&2, Closed.Got>}

# LAW: the soul sphere adds 100 up to 200 and is always taken and
# counted: 99 makes 199, 100 and 101 make 200, and 200 stays 200
# (sanity).
law soul_sphere:
  {[Closed.offer(Closed.inv([Health{99}]), 2013), Closed.offer(I.Inventory.start(), 2013),
    Closed.offer(Closed.inv([Health{101}]), 2013), Closed.offer(Closed.inv([Health{200}]), 2013)]
    == [Got{[], Closed.inv([Health{199}, Items{1}, Flash{6}])}, Got{[], Closed.inv([Health{200}, Items{1}, Flash{6}])},
      Got{[], Closed.inv([Health{200}, Items{1}, Flash{6}])}, Got{[], Closed.inv([Health{200}, Items{1}, Flash{6}])}]
    : List<&2, Closed.Got>}

# LAW: the berserk pack is always taken and counted, and sets the
# strength counter to 1, even over one already running at 40. It heals
# 1 to 100, leaves 100 at 100, and does not lower 150 (sanity).
law berserk:
  {[Closed.offer(Closed.inv([Health{1}]), 2023), Closed.offer(I.Inventory.start(), 2023),
    Closed.offer(Closed.inv([Health{150}]), 2023), Closed.offer(Closed.inv([Strength{40}]), 2023)]
    == [Got{[], Closed.inv([Strength{1}, Items{1}, Flash{6}])}, Got{[], Closed.inv([Strength{1}, Items{1}, Flash{6}])},
      Got{[], Closed.inv([Health{150}, Strength{1}, Items{1}, Flash{6}])},
      Got{[], Closed.inv([Strength{1}, Items{1}, Flash{6}])}] : List<&2, Closed.Got>}

# LAW: the armour bonus is always taken and counted: no armour makes 1
# point of green armour's type, 199 points of blue make 200 and stay
# blue, and 200 points of green take nothing more (sanity).
law armour_bonus:
  {[Closed.offer(I.Inventory.start(), 2015), Closed.offer(Closed.inv([Armour{199, 2}]), 2015),
    Closed.offer(Closed.inv([Armour{200, 1}]), 2015)]
    == [Got{[], Closed.inv([Armour{1, 1}, Items{1}, Flash{6}])},
      Got{[], Closed.inv([Armour{200, 2}, Items{1}, Flash{6}])},
      Got{[], Closed.inv([Armour{200, 1}, Items{1}, Flash{6}])}] : List<&2, Closed.Got>}

# LAW: green armour gives 100 points of type 1 over fewer points of any
# type, blue's 99 among them, and is not counted; with 100 points of
# green, or 150 of blue, it stays (sanity).
law green_armour:
  {[Closed.offer(I.Inventory.start(), 2018), Closed.offer(Closed.inv([Armour{99, 2}]), 2018),
    Closed.offer(Closed.inv([Armour{100, 1}]), 2018), Closed.offer(Closed.inv([Armour{150, 2}]), 2018)]
    == [Got{[], Closed.inv([Armour{100, 1}, Flash{6}])}, Got{[], Closed.inv([Armour{100, 1}, Flash{6}])},
      Got{[1], Closed.inv([Armour{100, 1}])}, Got{[1], Closed.inv([Armour{150, 2}])}]
    : List<&2, Closed.Got>}

# LAW: blue armour gives 200 points of type 2 over fewer, 199 among
# them, and is not counted; with 200 points of either type it stays
# (sanity).
law blue_armour:
  {[Closed.offer(I.Inventory.start(), 2019), Closed.offer(Closed.inv([Armour{199, 1}]), 2019),
    Closed.offer(Closed.inv([Armour{200, 1}]), 2019), Closed.offer(Closed.inv([Armour{200, 2}]), 2019)]
    == [Got{[], Closed.inv([Armour{200, 2}, Flash{6}])}, Got{[], Closed.inv([Armour{200, 2}, Flash{6}])},
      Got{[1], Closed.inv([Armour{200, 1}])}, Got{[1], Closed.inv([Armour{200, 2}])}]
    : List<&2, Closed.Got>}

# LAW: a move of 20 a tic is tried in halves, to 74 and then 84, and a
# health bonus at (32, 80) is in reach of both: the first takes it and
# the second finds it gone, so health is 101, the tally 1 and the flash
# 6, not 102, 2 and 12 (sanity).
law bonus_counted_once:
  {Closed.walk(1n, 1310720, I.Inventory.start(), 2014)
    == Got{[], Closed.inv([Health{101}, Items{1}, Flash{6}])} : Closed.Got}

# LAW: P_PlayerThink counts strength up a tic before it counts the flash
# down, and both before the mobj moves: a berserk pack taken on the
# first tic leaves the counter at 1 and the flash at 6; the next two
# tics make 2 and 5, then 3 and 4 (sanity).
law strength_counts:
  {[Closed.walk(1n, 524288, I.Inventory.start(), 2023), Closed.walk(2n, 524288, I.Inventory.start(), 2023),
    Closed.walk(3n, 524288, I.Inventory.start(), 2023)]
    == [Got{[], Closed.inv([Strength{1}, Items{1}, Flash{6}])}, Got{[], Closed.inv([Strength{2}, Items{1}, Flash{5}])},
      Got{[], Closed.inv([Strength{3}, Items{1}, Flash{4}])}] : List<&2, Closed.Got>}

# LAW: P_GiveAmmo's clipammo on Hurt Me Plenty, which doubles nothing,
# from G_PlayerReborn's inventory: a clip gives 10 bullets, shells 4, a
# cell 20, a rocket 1; the boxes give five clips, 50 bullets, 20 shells,
# 100 cells and 5 rockets. Each is taken, and flashes 6 (sanity).
law ammo_amounts:
  {[Closed.offer(I.Inventory.start(), 2007), Closed.offer(I.Inventory.start(), 2008),
    Closed.offer(I.Inventory.start(), 2047), Closed.offer(I.Inventory.start(), 2010),
    Closed.offer(I.Inventory.start(), 2048), Closed.offer(I.Inventory.start(), 2049),
    Closed.offer(I.Inventory.start(), 17), Closed.offer(I.Inventory.start(), 2046)]
    == [Got{[], Closed.inv([Ammo{[60, 0, 0, 0]}, Flash{6}])}, Got{[], Closed.inv([Ammo{[50, 4, 0, 0]}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[50, 0, 20, 0]}, Flash{6}])}, Got{[], Closed.inv([Ammo{[50, 0, 0, 1]}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[100, 0, 0, 0]}, Flash{6}])}, Got{[], Closed.inv([Ammo{[50, 20, 0, 0]}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[50, 0, 100, 0]}, Flash{6}])}, Got{[], Closed.inv([Ammo{[50, 0, 0, 5]}, Flash{6}])}]
    : List<&2, Closed.Got>}

# LAW: maxammo's caps, 200 bullets, 50 shells, 300 cells and 50 rockets.
# At each, the loose round and the box are refused, stay, and change
# nothing; one short of each, the box is taken and fills it to the cap
# (sanity).
law ammo_caps:
  {[Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2007),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2048),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2008),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2049),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2047),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 17),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2010),
    Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 2046),
    Closed.offer(Closed.inv([Ammo{[199, 49, 299, 49]}]), 2048),
    Closed.offer(Closed.inv([Ammo{[199, 49, 299, 49]}]), 2049),
    Closed.offer(Closed.inv([Ammo{[199, 49, 299, 49]}]), 17),
    Closed.offer(Closed.inv([Ammo{[199, 49, 299, 49]}]), 2046)]
    == [Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[1], Closed.inv([Ammo{[200, 50, 300, 50]}])},
      Got{[], Closed.inv([Ammo{[200, 49, 299, 49]}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[199, 50, 299, 49]}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[199, 49, 300, 49]}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[199, 49, 299, 50]}, Flash{6}])}]
    : List<&2, Closed.Got>}

# LAW: the first backpack doubles every cap, to 400 100 600 100, before
# it gives a clip of each ammo type: from the start 60 4 20 1, and from
# ammo at the old caps 210 54 320 51. Either way it is taken (sanity).
law backpack_first:
  {[Closed.offer(I.Inventory.start(), 8), Closed.offer(Closed.inv([Ammo{[200, 50, 300, 50]}]), 8)]
    == [Got{[], Closed.inv([Ammo{[60, 4, 20, 1]}, Backpack{}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[210, 54, 320, 51]}, Backpack{}, Flash{6}])}]
    : List<&2, Closed.Got>}

# LAW: a later backpack leaves the doubled caps as they are and gives the
# clips again, 60 4 20 1 to 70 8 40 2; at the doubled caps it gives
# nothing, and it is still taken (sanity).
law backpack_later:
  {[Closed.offer(Closed.inv([Ammo{[60, 4, 20, 1]}, Backpack{}]), 8),
    Closed.offer(Closed.inv([Ammo{[400, 100, 600, 100]}, Backpack{}]), 8)]
    == [Got{[], Closed.inv([Ammo{[70, 8, 40, 2]}, Backpack{}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[400, 100, 600, 100]}, Backpack{}, Flash{6}])}]
    : List<&2, Closed.Got>}

# LAW: P_GiveWeapon for a weapon found, which brings two clips. The
# shotgun, not owned, is owned (weapons 3 to 7) with 8 shells; owned, its
# 8 shells alone take it; owned at 50 shells it stays; not owned at 50
# shells the weapon alone takes it. The chaingun brings 20 bullets and
# stays when owned at 200, the rocket launcher 2 rockets, the plasma
# rifle 40 cells. The chainsaw has no ammo: taken when not owned, left
# when owned (sanity).
law weapon_taken:
  {[Closed.offer(I.Inventory.start(), 2001),
    Closed.offer(Closed.inv([Ammo{[50, 8, 0, 0]}, Weapons{7}]), 2001),
    Closed.offer(Closed.inv([Ammo{[50, 50, 0, 0]}, Weapons{7}]), 2001),
    Closed.offer(Closed.inv([Ammo{[50, 50, 0, 0]}]), 2001),
    Closed.offer(I.Inventory.start(), 2002),
    Closed.offer(Closed.inv([Ammo{[200, 0, 0, 0]}, Weapons{11}]), 2002),
    Closed.offer(I.Inventory.start(), 2003), Closed.offer(I.Inventory.start(), 2004),
    Closed.offer(I.Inventory.start(), 2005),
    Closed.offer(Closed.inv([Weapons{131}]), 2005)]
    == [Got{[], Closed.inv([Ammo{[50, 8, 0, 0]}, Weapons{7}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[50, 16, 0, 0]}, Weapons{7}, Flash{6}])},
      Got{[1], Closed.inv([Ammo{[50, 50, 0, 0]}, Weapons{7}])},
      Got{[], Closed.inv([Ammo{[50, 50, 0, 0]}, Weapons{7}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[70, 0, 0, 0]}, Weapons{11}, Flash{6}])},
      Got{[1], Closed.inv([Ammo{[200, 0, 0, 0]}, Weapons{11}])},
      Got{[], Closed.inv([Ammo{[50, 0, 0, 2]}, Weapons{19}, Flash{6}])},
      Got{[], Closed.inv([Ammo{[50, 0, 40, 0]}, Weapons{35}, Flash{6}])},
      Got{[], Closed.inv([Weapons{131}, Flash{6}])},
      Got{[1], Closed.inv([Weapons{131}])}]
    : List<&2, Closed.Got>}

# LAW: replaying two scripts in turn is replaying their concatenation,
# for all scripts and states.
law replay_append:
  for a: List<&2, K.Cmd>
  for b: List<&2, K.Cmd>
  for s: S.State
  {S.Sim.replay(List.append(&2, K.Cmd, a, b), s) == S.Sim.replay(b, S.Sim.replay(a, s)) : S.State}

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
  {True{} == S.Sim.line_ok(level, x, y, S.Sim.radius(), 1, i) : Bool}

# LAW: the distance condition on numbers: a one-sided wall from (0, 0)
# to (0, 128) is touched and crossed by the player's box at (8, 64), and
# neither at (40, 64); at (24, 64) a barrel's box of radius 10 is clear
# of it and the big tree's of 32 crosses it. A two-sided line without the
# blocking flag is not solid, one with it is; one blocking monsters
# stops a thing's box and not the player's (sanity).
law line_geometry:
  {(S.Sim.box_touches(524288, 4194304, 1048576, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_crosses(524288, 4194304, 1048576, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_touches(2621440, 4194304, 1048576, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_crosses(2621440, 4194304, 1048576, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_crosses(1572864, 4194304, 655360, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.box_crosses(1572864, 4194304, 2097152, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.solid(1, L.Line{0, 0, 0, 8388608, 0, 0, 65535}),
    S.Sim.solid(1, L.Line{0, 0, 0, 8388608, 4, 0, 1}),
    S.Sim.solid(1, L.Line{0, 0, 0, 8388608, 5, 0, 1}),
    S.Sim.solid(1, L.Line{0, 0, 0, 8388608, 6, 0, 1}),
    S.Sim.solid(3, L.Line{0, 0, 0, 8388608, 6, 0, 1}))
    == (True{}, True{}, False{}, False{}, False{}, True{}, True{}, False{}, True{}, False{}, True{})
    : Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool}

# A state whose player passes its level's position check: free of solid
# lines and of solid things.
def Free(+s: S.State) -> Type:
  {True{} == S.Sim.free(S.State.level(s), S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))
    : Bool}

# A state whose player's box is clear of the solid things near it.
def Clear(+s: S.State) -> Type:
  {True{} == S.Sim.clear(S.State.level(s), S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)),
    S.Sim.radius(), H.Thing.you()) : Bool}

# LAW: a tic leaves the geometry as it was: the lines, sides, vertices,
# nodes and blockmap that free reads are the same trees after it, for
# all commands and states.
law tic_keeps_geometry:
  for +cmd: K.Cmd
  for +s: S.State
  {L.Level.geo(S.State.level(S.Sim.tic(cmd, s))) == L.Level.geo(S.State.level(s)) : L.Level.Geo}

# LAW: one tic from a free state answers a free state, for all commands
# and states.
law tic_keeps_free:
  for +cmd: K.Cmd
  for +s: S.State
  for free: Free(s)
  Free(S.Sim.tic(cmd, s))

# LAW: the wall law: replaying any script from a free state, the start
# included, leaves the player free.
law replay_keeps_free:
  for script: List<&2, K.Cmd>
  for +s: S.State
  for free: Free(s)
  Free(S.Sim.replay(script, s))

# LAW: the freedom law: replaying any script from a free state, the start
# included, leaves the player's box clear of every solid thing linked in
# the cells around it (clear_pins_things reads that on each of them).
law replay_keeps_clear:
  for +script: List<&2, K.Cmd>
  for +s: S.State
  for free: Free(s)
  Clear(S.Sim.replay(script, s))

# LAW: clear is pinned to the things: when the player's box is clear,
# every thing the blockmap links in the cells around it, whichever
# position in the list it holds, is not solid or has its box apart from
# the player's (blocker_geometry shows the numbers). That the links hold
# the living solid things rests on tests/sim.bend's links check at the
# start of both E1M1s, which tic_keeps_geometry and solid_stays carry
# through every tic; that none linked in a further cell can reach the
# box rests on ticket 09's argument, since the checker cannot compute
# the cell arithmetic.
law clear_pins_things:
  for +level: L.Level
  for +x: U32
  for +y: U32
  for k: Nat
  for id: U32
  for listed: {Some{id} == List.get(&2, U32, S.Sim.near(level, x, y, S.Sim.radius()), k) : Maybe<&2, U32>}
  for clear: {True{} == S.Sim.clear(level, x, y, S.Sim.radius(), H.Thing.you()) : Bool}
  {False{} == S.Sim.blocker(L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you(), id) : Bool}

def Closed.within(d: H.Thing.Def) -> Bool:
  H.Def{kind, state, radius, height, flags} = d
  U32.is_le(F.Fixed.of_map(radius), S.Sim.maxradius())

# LAW: no type Bendoom spawns is wider than Doom's MAXRADIUS, 32, which
# the thing check widens its box by (sanity).
law radius_within:
  {List.all(~&2, ~H.Thing.Def, ~Closed.within, H.Thing.defs()) == True{} : Bool}

def Closed.lasting(d: H.Thing.Def) -> Bool:
  H.Def{kind, state, radius, height, flags} = d
  Bool.not(U32.is_eq((flags .&. 3 : U32), 3))

# LAW: no type Bendoom spawns is both solid and special, info.c's flags
# 2 and 1, so no pickup takes a solid thing away: only a grant removes a
# thing, and only a special thing is offered one (sanity).
law solid_stays:
  {List.all(~&2, ~H.Thing.Def, ~Closed.lasting, H.Thing.defs()) == True{} : Bool}

# Solid things
# ------------

# The literal level with a floor lamp (type 2028: radius 16, solid) at
# (32, 112), a dead player (type 15: no flags) at (32, 32) and a barrel
# (type 2035: radius 10, height 42, solid and shootable) at (96, 112),
# linked in that order into its one cell.
def Closed.linked() -> L.Level:
  H.Thing.linked(Closed.doors(), [Closed.thing(8, 2028, 2097152, 7340032, 0),
    Closed.thing(15, 15, 2097152, 2097152, 0), Closed.thing(24, 2035, 6291456, 7340032, 0)], 128)

# LAW: vanilla's PIT_CheckThing on numbers. The lamp stops the player's
# box when their centres are under 32 apart, 16 and 16: at 32 it does
# not, 1/65536 closer it does, and it never stops its own. The corpse is
# not solid, so it stops nothing even where it stands. The barrel's
# reach is 26. The cell lists the three things the last linked first
# (sanity).
law blocker_geometry:
  {(S.Sim.blocker(L.Level.things_of(Closed.linked()), 2097152, 5242880, 1048576, H.Thing.you(), 8),
    S.Sim.blocker(L.Level.things_of(Closed.linked()), 2097152, 5242881, 1048576, H.Thing.you(), 8),
    S.Sim.blocker(L.Level.things_of(Closed.linked()), 2097152, 5242881, 1048576, 8, 8),
    S.Sim.blocker(L.Level.things_of(Closed.linked()), 2097152, 2097152, 1048576, H.Thing.you(), 15),
    S.Sim.blocker(L.Level.things_of(Closed.linked()), 4587520, 7340032, 1048576, H.Thing.you(), 24),
    S.Sim.blocker(L.Level.things_of(Closed.linked()), 4587521, 7340032, 1048576, H.Thing.you(), 24),
    S.Sim.near(Closed.linked(), 2097152, 4194304, 1048576))
    == (False{}, True{}, False{}, False{}, False{}, True{}, [24, 15, 8])
    : Bool & Bool & Bool & Bool & Bool & Bool & List<&2, U32>}

# LAW: the player's link among its cell's things for P_ChangeSector: at
# its start record's rank 6 it goes after the things spawned later, 9,
# and before those spawned earlier; once it has moved it goes first; at
# rank 1 last; outside its cell nowhere (sanity).
law link_order:
  {(S.Sim.you.in(True{}, [9, 5, 2], 6), S.Sim.you.in(True{}, [9, 5, 2], 4294967295), S.Sim.you.in(True{}, [9, 5, 2], 1),
    S.Sim.you.in(False{}, [9, 5, 2], 6))
    == ([9, 4294967295, 5, 2], [4294967295, 9, 5, 2], [9, 5, 2, 4294967295], [9, 5, 2])
    : List<&2, U32> & List<&2, U32> & List<&2, U32> & List<&2, U32>}

def Closed.north(things: List<&2, H.Thing>, n: Nat) -> U32:
  S.Player.y(S.State.player(Closed.idled(n, Closed.among(I.Inventory.start(), 2097152, 0, 524288, things))))

# LAW: a solid thing stops the player and a corpse does not. Moving north
# at 8 a tic from (32, 64), friction leaves 7.25 and then 6.57: tic 2
# ends at 79.25, 32.75 short of a lamp at (32, 112), and tic 3's move to
# 85.82 would overlap it. The slide finds no line and stairsteps; its
# move north overlaps too, its move by the momentum east is no move, so
# the player stays at 79.25. Doom's things are as tall as the map: the
# lamp raised 100 units stops it all the same. Over a dead player at the
# same place tic 3 reaches 85.82 (sanity).
law thing_blocks:
  {(Closed.north([Closed.thing(8, 2028, 2097152, 7340032, 0)], 2n),
    Closed.north([Closed.thing(8, 2028, 2097152, 7340032, 0)], 3n),
    Closed.north([Closed.thing(8, 2028, 2097152, 7340032, 6553600)], 3n),
    Closed.north([Closed.thing(15, 15, 2097152, 7340032, 0)], 3n))
    == (5193728, 5193728, 5193728, 5624320) : U32 & U32 & U32 & U32}

# A state of the literal level with one mover and a player at rest at
# (x, 64) under the west room's ceiling, among things.
def Closed.moving.among(level: L.Level, t: S.Thinker, x: U32, things: List<&2, H.Thing>) -> S.State:
  S.State.populated(things, 128, Closed.moving(level, t, x, 4194304, 8388608))

def Closed.things(s: S.State) -> List<&2, H.Thing>:
  H.Things.list(S.State.things(s))

def Closed.lowering(n: Nat) -> List<&2, H.Thing>:
  Closed.things(Closed.idled(n, Closed.moving.among(Closed.doors(),
    S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()}, 13107200,
    [Closed.thing(29, 60, 2097152, 6553600, 3932160), Closed.thing(24, 2035, 2097152, 1048576, 0)])))

# LAW: a moving floor carries the things on it, vanilla's
# P_ThingHeightClip through P_ChangeSector. The west room's floor goes
# down 4 a tic; the player at (200, 64) is out of its block box. The
# barrel standing at (32, 16) follows the floor, -4 after a tic and -8
# after two, its name, type, state and tics as they were. A leg hung 68
# under the ceiling at 128 stays at 60, over its floor at -4 (sanity).
law floor_carries_things:
  {(Closed.lowering(1n), Closed.lowering(2n))
    == ([H.Thing{24, 2035, 2097152, 1048576, 4294705152, 4294705152, 8388608, 0, 0, 0, 4294967295},
        H.Thing{29, 60, 2097152, 6553600, 3932160, 4294705152, 8388608, 0, 0, 0, 4294967295}],
      [H.Thing{24, 2035, 2097152, 1048576, 4294443008, 4294443008, 8388608, 0, 0, 0, 4294967295},
        H.Thing{29, 60, 2097152, 6553600, 3932160, 4294443008, 8388608, 0, 0, 0, 4294967295}])
    : List<&2, H.Thing> & List<&2, H.Thing>}

# The door open at 68 and closing, 2 a tic, over a thing, the west room's
# player at (32, 64) in the one cell.
def Closed.closing(th: H.Thing) -> S.State:
  Closed.moving.among(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
    S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
    2097152, [th])

# LAW: a door closing on a barrel goes back up, vanilla's
# PIT_ChangeSector for a shootable thing that no longer fits, and no
# damage is done. The barrel at (72, 16) stands across both of the
# door's faces, so its ceiling is the door's: 42 after 13 tics, which
# fits its height of 42; the 14th would leave 40, so the step is undone,
# the barrel clipped again under 42, and the door back on its plan; 44
# after the 15th (sanity).
law barrel_stops_door:
  {(Closed.ceil(Closed.idled(13n, Closed.closing(Closed.thing(24, 2035, 4718592, 1048576, 0))), 1),
    Closed.ceil(Closed.idled(14n, Closed.closing(Closed.thing(24, 2035, 4718592, 1048576, 0))), 1),
    S.State.thinkers(Closed.idled(14n, Closed.closing(Closed.thing(24, 2035, 4718592, 1048576, 0)))),
    Closed.things(Closed.idled(14n, Closed.closing(Closed.thing(24, 2035, 4718592, 1048576, 0)))),
    Closed.ceil(Closed.idled(15n, Closed.closing(Closed.thing(24, 2035, 4718592, 1048576, 0))), 1))
    == (2752512, 2752512,
      [S.Mover{1, True{}, 131072, [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()}],
      [H.Thing{24, 2035, 4718592, 1048576, 0, 0, 2752512, 0, 0, 0, 4294967295}], 2883584)
    : U32 & U32 & List<&2, S.Thinker> & List<&2, H.Thing> & U32}

# LAW: a lamp is solid but not shootable, and vanilla's PIT_ChangeSector
# passes over it: the door closes on the lamp at (72, 16) as on nothing,
# shut after 34 tics, its thinker ended on the 35th, the lamp still on
# its floor under a ceiling at 0 (sanity).
law lamp_under_door:
  {(Closed.ceil(Closed.idled(34n, Closed.closing(Closed.thing(8, 2028, 4718592, 1048576, 0))), 1),
    S.State.thinkers(Closed.idled(35n, Closed.closing(Closed.thing(8, 2028, 4718592, 1048576, 0)))),
    Closed.things(Closed.idled(35n, Closed.closing(Closed.thing(8, 2028, 4718592, 1048576, 0)))))
    == (0, [], [H.Thing{8, 2028, 4718592, 1048576, 0, 0, 0, 0, 0, 0, 4294967295}])
    : U32 & List<&2, S.Thinker> & List<&2, H.Thing>}

def Closed.over_barrel() -> S.State:
  S.State.populated([Closed.thing(24, 2035, 4718592, 6553600, 0)], 128, Closed.west())

# LAW: vanilla's T_MovePlane lets a ceiling rise short of its
# destination whatever it leaves unfit. A barrel at (72, 100) across the
# shut door does not fit under it, yet the door used on tic 1 is 2 up
# after it and 4 after the second, the barrel's ceiling rising with it
# (sanity).
law door_opens_over_barrel:
  {(Closed.ceil(Closed.used(0n, Closed.over_barrel()), 1), Closed.things(Closed.used(1n, Closed.over_barrel())))
    == (131072, [H.Thing{24, 2035, 4718592, 6553600, 0, 0, 262144, 0, 0, 0, 4294967295}]) : U32 & List<&2, H.Thing>}

# Things
# ------

# The things' closed laws stand on the literal level with three THINGS
# records on every skill: player 1's start at (32, 64) in the west room,
# a health bonus at (16, 32) and green armour at (16, 96). The one
# subsector's seg is line 0's front, so each stands in the west room, on
# its floor at 0. Their rows are Bendoom's numbers for info.c's states:
# S_BON1 12, then S_BON1A to S_BON1E 13 to 17, 6 tics each, then S_BON1
# again; S_ARM1 6, 6 tics, and S_ARM1A 7, 7 tics, in turn.
def Closed.stocked() -> S.State:
  S.State.at(Closed.level(0, V.Vec.of_list([32, 64, 0, 1, 7, 16, 32, 0, 2014, 7, 16, 96, 0, 2018, 7], 15), 3),
    L.Start{2097152, 4194304, 0})

# The bonus and the armour as they spawned, in a state for some tics.
def Closed.bonus(state: U32, tics: U32) -> H.Thing:
  H.Thing{1, 2014, 1048576, 2097152, 0, 0, 8388608, 0, 0, state, tics}

def Closed.armour(state: U32, tics: U32) -> H.Thing:
  H.Thing{2, 2018, 1048576, 6291456, 0, 0, 8388608, 0, 0, state, tics}

# LAW: the spawn's phase, vanilla's P_SpawnMapThing. The player draws
# the random table's entry 1. The bonus draws entry 2 for P_SpawnMobj,
# then entry 3, 220, for its first state's tics: 1 + 220 mod 6 = 5. The
# armour draws entry 4, then entry 5, 241: 1 + 241 mod 6 = 2. The index
# is 5 (sanity).
law spawn_phase:
  {(Closed.things(Closed.stocked()), S.State.rnd(Closed.stocked()))
    == ([Closed.bonus(12, 5), Closed.armour(6, 2)], 5)
    : List<&2, H.Thing> & U32}

# LAW: one complete cycle of the bonus, vanilla's P_MobjThinker. Its 5
# tics are down to 1 after tic 4; tic 5 enters S_BON1A for 6; tics 11,
# 17, 23 and 29 enter the next four states, and tic 35 is back in S_BON1
# for 6. The armour enters S_ARM1A for 7 on tic 2, S_ARM1 for 6 on tic
# 9, and so on each 13 tics. No thing draws a random number, and the
# clock counts 35 (sanity).
law bonus_cycle:
  {(Closed.things(Closed.idled(4n, Closed.stocked())), Closed.things(Closed.idled(5n, Closed.stocked())),
    Closed.things(Closed.idled(11n, Closed.stocked())), Closed.things(Closed.idled(17n, Closed.stocked())),
    Closed.things(Closed.idled(23n, Closed.stocked())), Closed.things(Closed.idled(29n, Closed.stocked())),
    Closed.things(Closed.idled(35n, Closed.stocked())), S.State.rnd(Closed.idled(35n, Closed.stocked())),
    S.State.clock(Closed.idled(35n, Closed.stocked())))
    == ([Closed.bonus(12, 1), Closed.armour(7, 5)],
      [Closed.bonus(13, 6), Closed.armour(7, 4)],
      [Closed.bonus(14, 6), Closed.armour(6, 4)],
      [Closed.bonus(15, 6), Closed.armour(7, 5)],
      [Closed.bonus(16, 6), Closed.armour(6, 5)],
      [Closed.bonus(17, 6), Closed.armour(7, 6)],
      [Closed.bonus(12, 6), Closed.armour(6, 6)], 5, 35)
    : List<&2, H.Thing> & List<&2, H.Thing> & List<&2, H.Thing> & List<&2, H.Thing> & List<&2, H.Thing>
      & List<&2, H.Thing> & List<&2, H.Thing> & U32 & U32}

# LAW: a thing in a lasting state, of -1 tics, is the same thing after
# its tic, for every thing.
law lasting_stays:
  for id: U32
  for kind: U32
  for x: U32
  for y: U32
  for z: U32
  for floorz: U32
  for ceilz: U32
  for angle: U32
  for sector: U32
  for state: U32
  {H.Thing.tic(H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, 4294967295})
    == H.Thing{id, kind, x, y, z, floorz, ceilz, angle, sector, state, 4294967295} : H.Thing}

# The renderer
# ------------

# LAW: the solid columns stay sorted: clipping any wall range into a
# sorted list of solid ranges, each from a first column to a last no
# less with at least one open column before the next, leaves such a
# list, for all lists and ranges.
law solid_sorted:
  for +first: Nat
  for +last: Nat
  for +rs: List<&2, C.Clip.Range>
  for ordered: {True{} == Nat.is_le(first, last) : Bool}
  for sorted: {True{} == C.Clip.sorted(rs) : Bool}
  {True{} == C.Clip.sorted(C.Clip.add(first, last, rs)) : Bool}

# LAW: a range touching its neighbours joins them, and the fragments a
# wall leaves between solid ranges come out left to right (sanity).
law solid_clips:
  {(C.Clip.add(21n, 29n, [C.Range{10n, 20n}, C.Range{30n, 40n}, C.Range{50n, 60n}]),
    C.Clip.gaps(5n, 45n, [C.Range{10n, 20n}, C.Range{30n, 40n}, C.Range{50n, 60n}]),
    C.Clip.covers(12n, 18n, [C.Range{10n, 20n}]), C.Clip.covers(12n, 25n, [C.Range{10n, 20n}]))
    == ([C.Range{10n, 40n}, C.Range{50n, 60n}],
      [C.Range{5n, 9n}, C.Range{21n, 29n}, C.Range{41n, 45n}], True{}, False{})
    : List<&2, C.Clip.Range> & List<&2, C.Clip.Range> & Bool & Bool}

# LAW: the view's edges are vanilla's at width 320. The focal length is
# 160 over the tangent 65586 of fine angle 3072, 10477766; through it
# the tangent at 3072 lands on column 1 and the next on column 0, so
# column 0's angle is fine angle 3073, Doom's clipangle 0x20080000; on
# the other side 1023 lands on 320 and 1022 past it; the tangent 25 at
# the view's centre lands on column 160 (sanity).
law view_edges:
  {(P.Project.focal(V.Vec.of_list(T.Tables.finetangent(), 4096)),
    P.Project.tox(65586, 10477766), P.Project.tox(65686, 10477766),
    P.Project.tox(4294901710, 10477766), P.Project.tox(4294901610, 10477766),
    P.Project.tox(25, 10477766))
    == (10477766, 1, 0, 320, 321, 160) : U32 & U32 & U32 & U32 & U32 & U32}

# LAW: the sweep gives each column the least fine angle whose column is
# not past it: over the columns 321, 320, 2, 0, -1 of fine angles 0 to
# 4, columns 320 down to 2 take angles 1 and 2, columns 1 and 0 take 3;
# as binary angles less a quarter turn (sanity).
law view_sweep:
  {(List.get(&2, U32, P.Project.xtoangle([321, 320, 2, 0, 4294967295]), 0n),
    List.get(&2, U32, P.Project.xtoangle([321, 320, 2, 0, 4294967295]), 1n),
    List.get(&2, U32, P.Project.xtoangle([321, 320, 2, 0, 4294967295]), 2n),
    List.get(&2, U32, P.Project.xtoangle([321, 320, 2, 0, 4294967295]), 319n),
    List.get(&2, U32, P.Project.xtoangle([321, 320, 2, 0, 4294967295]), 320n))
    == (Some{3222798336}, Some{3222798336}, Some{3222274048}, Some{3222274048}, Some{3221749760})
    : Maybe<&2, U32> & Maybe<&2, U32> & Maybe<&2, U32> & Maybe<&2, U32> & Maybe<&2, U32>}

# LAW: a row's slope is 160 over its distance from the centre row's top
# edge plus a half: 320 at rows 83 and 84, 160 / 83.5 at rows 0 and 167
# (sanity).
law view_rows:
  {(P.Project.yslope(0), P.Project.yslope(83), P.Project.yslope(84), P.Project.yslope(167))
    == (125577, 20971520, 20971520, 125577) : U32 & U32 & U32 & U32}

# LAW: the wall scale from the global angle, looking east at a wall
# whose normal faces the eye. At distance 160 it is 1, at the centre and
# at column 0's angle alike; at 100/65536 the division would overflow,
# so it is 64; at distance 2 it is 80, capped at 64; seen edge on, the
# sine 25 makes it 25/65536, raised to 256 (sanity).
law wall_scale:
  {(P.View.scale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 0, 0, 10485760),
    P.View.scale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 537395200, 0,
      10485760),
    P.View.scale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 0, 0, 100),
    P.View.scale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 0, 0, 131072),
    P.View.scale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 0, 1073741824,
      10485760))
    == (65536, 65536, 4194304, 4194304, 256) : U32 & U32 & U32 & U32 & U32}

# LAW: the light tables' ends. A wall's colormap is 60 less four a light
# number less half the scale index, held to 0 and 31: the darkest light
# is 31 at both ends of the scale, the brightest 0, light 8 runs from 28
# to 5. A span's is the same start less half of 160 over the distance
# index plus one: light 8 is 0 at index 0, 18 at 7, 28 at 127 (sanity).
law light_tables:
  {(P.Project.scalelight(0, 0), P.Project.scalelight(0, 47), P.Project.scalelight(15, 0),
    P.Project.scalelight(15, 47), P.Project.scalelight(8, 0), P.Project.scalelight(8, 47),
    P.Project.zlight(8, 0), P.Project.zlight(8, 7), P.Project.zlight(8, 127))
    == (31, 31, 0, 0, 28, 5, 0, 18, 28)
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# LAW: a wall column's arithmetic, facing a wall 160 away head on with
# texture offset 64. At the centre column the tangent 25 of the wall's
# normal takes 4000/65536 off the offset, texture column 63; at column
# 0's angle the tangent 65686 takes 160.37, texture column -97, the
# shift flooring the negative. The reciprocal of scale 1 is 65535, of
# the cap 64 it is 1023, of the floor 1/256 it is 16777215. At light 8
# scale 1 is light index 16, colormap 20; scale 64 is index 1024, capped
# at 47, colormap 5 (sanity).
law wall_column:
  {(R.Segs.texcol(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Leaf{0}, V.Vec.of_list(T.Tables.finetangent(), 4096),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}},
      10485760, 4194304, 1073741824, 0),
    R.Segs.texcol(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Leaf{0}, V.Vec.of_list(T.Tables.finetangent(), 4096),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{537395200}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}},
      10485760, 4194304, 1073741824, 0),
    R.Segs.iscale(65536), R.Segs.iscale(4194304), R.Segs.iscale(256),
    R.Segs.colormap(8, 65536), R.Segs.colormap(8, 4194304))
    == (63, 4294967199, 65535, 1023, 16777215, 70912, 67072)
    : U32 & U32 & U32 & U32 & U32 & U32 & U32}

# LAW: a range's silhouette, with the eye 41 over a floor at 8 under a
# ceiling at 128. A one-sided wall clips both ways at any height. A
# masked texture over a floor stepping down to 0 keeps the front's floor
# as the height it clips under, and fills in the top at any height. A
# window between two like sectors clips nothing. A door shut at the
# floor clips below at any height, and above since its ceiling is under
# the eye (sanity).
law silhouettes:
  {(R.Segs.sil.of(True{}, False{}, L.Sector{524288, 8388608, 160}, L.Sector{0, 0, 0}, 3211264),
    R.Segs.sil.of(False{}, True{}, L.Sector{524288, 8388608, 160}, L.Sector{0, 8388608, 160}, 3211264),
    R.Segs.sil.of(False{}, False{}, L.Sector{524288, 8388608, 160}, L.Sector{524288, 8388608, 160}, 3211264),
    R.Segs.sil.of(False{}, False{}, L.Sector{524288, 8388608, 160}, L.Sector{524288, 524288, 160}, 3211264))
    == ((3, 2147483647, 2147483648), (3, 524288, 2147483648), (0, 0, 0), (3, 2147483647, 2147483648))
    : (U32 & U32 & U32) & (U32 & U32 & U32) & (U32 & U32 & U32) & (U32 & U32 & U32)}

# A sprite's view from the origin facing east along the x axis, the
# eye 41 up, with the sine and cosine of the angle exactly 0 and 1; the
# graphics hold two state rows' sprites, 64 wide with its origin 32 in
# and 56 down, full-bright: row 0's patch at 1000, row 1's at 2000 and
# mirrored, the same seen from every side.
def Sprite.view() -> P.View:
  P.View{0, 0, 2686976, 0, 0, 65536, P.Tables{V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0},
    V.Leaf{0}, V.Leaf{0}, 0}}

def Sprite.slots(n: Nat, +patch: U32, +flip: U32) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      patch <> 4194304 <> 2097152 <> 3670016 <> flip <> 1 <> Sprite.slots(m, patch, flip)

def Sprite.gfx() -> G.Gfx:
  G.Gfx{V.Leaf{0}, V.Leaf{0}, 0, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0,
    V.Vec.of_list(List.append(&2, U32, Sprite.slots(8n, 1000, 0), Sprite.slots(8n, 2000, 1)), 96),
    G.Anims{G.Anim{[], 0, V.Leaf{0}}, G.Anim{[], 0, V.Leaf{0}}, 0}, V.Leaf{0}}

# Thing id in a state row, x ahead of the eye and y to its left.
def Sprite.at(id: U32, x: U32, y: U32, state: U32) -> List<&2, Z.Sprites.Vis>:
  Z.Sprites.project(Sprite.view(), Closed.doors(), Sprite.gfx(), 1,
    H.Thing{id, 2014, x, y, 0, 0, 0, 0, 0, state, 4294967295}, [])

# LAW: R_ProjectSprite holds a sprite's columns to the screen, and
# R_DrawVisSprite steps down a column by the scale's reciprocal. Facing
# east, a thing x ahead and y to the left has tz = x and tx = -y; its
# scale is 160 / tz, and with the patch 64 wide and its origin 32 in,
# x1 = 160 + (tx - 32) scale and x2 = 160 + (tx + 32) scale - 1, the
# first held to 0 and the last to 319. The patch's column starts at 0,
# or at 64 less 1/65536 for a mirrored patch (startfrac = width - 1),
# and steps xiscale = 1 / scale a column, its negation when mirrored;
# a sprite cut on the left starts xiscale (x1 - x1 unclipped) further.
# - 160 ahead the scale and its reciprocal are 1: straight ahead, x1 =
#   128 and x2 = 191; 150 left, x1 = -22, drawn from 0 at column 22 of
#   the patch; mirrored and 150 right, x1 = 278 and x2 = 341, drawn to
#   319 from 64 less 1/65536 stepping -1; 400 left, x2 = -209, culled.
# - 320 ahead the scale is 1/2 and xiscale 2: straight ahead, x1 = 160
#   - 16 = 144 and x2 = 176 - 1 = 175. Mirrored and 308 left, x1 = 160
#   - 170 = -10 and x2 = 160 - 138 - 1 = 21: drawn from 0, its patch's
#   column 64 less 1/65536 plus -2 times 10, 44 less 1/65536, stepping
#   -2. That column is drawn with dc_iscale 2, the step's absolute
#   value, and its top at 84 less half the 15 its top stands over the
#   eye, 76.5; the clips no range set are the screen's edges (sanity).
law sprite_columns:
  {(Sprite.at(1, 10485760, 0, 0), Sprite.at(2, 10485760, 9830400, 0), Sprite.at(3, 10485760, 4285136896, 1),
    Sprite.at(4, 10485760, 26214400, 0), Sprite.at(5, 20971520, 0, 0), Sprite.at(6, 20971520, 20185088, 1),
    Z.Sprites.col.of(0, Z.Vis{0, 21, 32768, 20971520, 20185088, 0, 3670016, 983040, 2883583, 4294836224, 2000,
      65792, 1, 6}, Z.Sprites.unclipped(), Z.Sprites.unclipped()))
    == ([Z.Vis{128, 191, 65536, 10485760, 0, 0, 3670016, 983040, 0, 65536, 1000, 65792, 1, 1}],
      [Z.Vis{0, 41, 65536, 10485760, 9830400, 0, 3670016, 983040, 1441792, 65536, 1000, 65792, 1, 2}],
      [Z.Vis{278, 319, 65536, 10485760, 4285136896, 0, 3670016, 983040, 4194303, 4294901760, 2000, 65792, 1, 3}],
      [], [Z.Vis{144, 175, 32768, 20971520, 0, 0, 3670016, 983040, 0, 131072, 1000, 65792, 1, 5}],
      [Z.Vis{0, 21, 32768, 20971520, 20185088, 0, 3670016, 983040, 2883583, 4294836224, 2000, 65792, 1, 6}],
      Q.Col{0, 5013504, 32768, 983040, 131072, 65792, 4294967295, 168})
    : List<&2, Z.Sprites.Vis> & List<&2, Z.Sprites.Vis> & List<&2, Z.Sprites.Vis> & List<&2, Z.Sprites.Vis>
      & List<&2, Z.Sprites.Vis> & List<&2, Z.Sprites.Vis> & Q.Masked.Col}

# A sprite of a scale, its sector's rank in the walk and its thing's id.
def Sprite.vis(scale: U32, rank: U32, id: U32) -> Z.Sprites.Vis:
  Z.Vis{0, 0, scale, 0, 0, 0, 0, 0, 0, 0, 0, 0, rank, id}

# LAW: R_SortVisSprites draws the smallest scale first, and of equal
# scales the vissprite made first: sectors in the order the walk reached
# them, and in a sector its thing list's order, newest first (sanity).
law sprite_order:
  {List.sort(~Z.Sprites.Vis, ~Z.Sprites.before, [Sprite.vis(131072, 1, 5), Sprite.vis(65536, 2, 3),
    Sprite.vis(65536, 1, 4), Sprite.vis(65536, 1, 9)])
    == [Sprite.vis(65536, 1, 9), Sprite.vis(65536, 1, 4), Sprite.vis(65536, 2, 3), Sprite.vis(131072, 1, 5)]
    : List<&2, Z.Sprites.Vis>}

# LAW: a plane's arithmetic, looking east from the origin. The sky turns
# a column every 2^22 of angle: column 0's view angle is column 128 of
# the sky, and a quarter turn on it is 256 more. At light 8 a span 200
# away has light index 12, colormap 22; one 13120 away has index 820,
# capped at 127, colormap 28. The centre row's slope 320 puts a plane 41
# under the eye 13120 away; the frame's scales are 0 along x and 409
# along y, so a span there steps 0 and 13120 * 409 a column, and with a
# distance scale of 65537 it starts 13120.2 further along x through the
# cosine 65535, and the sine 25 of that to the south. Packed as the DOS
# span loop packs it, x 1.5 and y 2.25 are 0x06000900, texel 1 of row 2
# (sanity).
law plane_span:
  {(N.Planes.skycol(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0},
      V.Leaf{537395200}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 0),
    N.Planes.skycol(P.View{0, 0, 0, 1073741824, 0, 0, P.Tables{V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0},
      V.Leaf{537395200}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}, 0),
    N.Planes.colormap(8, 13107200), N.Planes.colormap(8, 859832320),
    N.Planes.xscale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240), V.Leaf{0},
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}),
    N.Planes.yscale(P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240), V.Leaf{0},
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, 0}}),
    N.Planes.step(N.Flat{P.View{0, 0, 0, 0, 0, 0, P.Tables{V.Vec.of_list(T.Tables.finesine(), 10240),
      V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{0}, V.Leaf{20971520}, V.Leaf{65537}, V.Leaf{0}, 0}},
      0, 409, 2686976, 8, 0}, 84, 0),
    D.Draw.span.pack(98304, 147456), D.Draw.span.spot(100665600))
    == (128, 384, 71424, 72960, 0, 409, N.Step{859832319, 4294639291, 0, 5366080, 72960}, 100665600, 129)
    : U32 & U32 & U32 & U32 & U32 & U32 & N.Planes.Step & U32 & U32}

# A checker to ride the draw's loop: whether every index so far was the
# one expected, and the one expected next.
type Seq is Data:
  Seq{ok: Bool, next: Nat}

def Seq.see(i: Nat, st: Seq) -> Seq:
  Seq{ok, +next} = st
  Seq{Bool.and(ok, Nat.is_eq(i, next)), 1n+next}

# LAW: the loop under every column and span reaches the indices from its
# first, in order, as many as it is asked and no other: the checker
# riding it from i sees each index be the one expected and ends
# expecting n + i, for all n and i. So a column draw, which writes only
# the row its index names, changes no pixel outside its top and bottom
# rows.
law each_in_order:
  for n: Nat
  for +i: Nat
  {D.Draw.each(~Seq, ~Seq.see, n, i, Seq{True{}, i}) == Seq{True{}, Nat.add(n, i)} : Seq}

# Animations
# ----------

# LAW: P_UpdateSpecials' translation, on Freedoom's numbers. FWATER1 is
# the WAD's flat 141, the first of 4, numbered 3 here: before the first
# tic it shows itself; the first tic runs with the level's time 0 and
# sets 3 + (0 + 141) mod 4 = 4, which holds through the 8th; the 9th
# runs with time 8 and sets 3 + (1 + 141) mod 4 = 5; and 32 tics on,
# one full cycle, it is 5 again. NUKAGE3 is flat 124, the last of 3,
# numbered 2 with NUKAGE1 at 0: 0 + (0 + 124) mod 3 = 1 after tics 1 to
# 8, then 2 after the 9th and, 24 tics on, after the 33rd (sanity).
law animation_frames:
  {(G.Gfx.anim.shown(0, 3, 4, 141, 0), G.Gfx.anim.shown(1, 3, 4, 141, 0), G.Gfx.anim.shown(8, 3, 4, 141, 0),
    G.Gfx.anim.shown(9, 3, 4, 141, 0), G.Gfx.anim.shown(41, 3, 4, 141, 0),
    G.Gfx.anim.shown(0, 2, 3, 124, 2), G.Gfx.anim.shown(1, 2, 3, 124, 2), G.Gfx.anim.shown(8, 2, 3, 124, 2),
    G.Gfx.anim.shown(9, 2, 3, 124, 2), G.Gfx.anim.shown(33, 2, 3, 124, 2))
    == (3, 4, 4, 5, 5, 2, 1, 1, 2, 2)
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# Music
# -----

# LAW: a sysex event is its length and as many bytes, which midifile.c
# reads past, whatever follows: the next event starts after them, under
# the sysex's running status.
law sysex_skipped:
  for rest: List<&2, U32>
  {Mi.Midi.next(Mi.Track{0 <> 240 <> 2 <> 7 <> 7 <> rest, 0})
    == Mi.Got{Mi.Other{}, Mi.Track{rest, 240}} : Mi.Midi.Got}

# LAW: a track ends at its end-of-track event, and the next track's
# header follows it, whatever that is: ReadTrack stops there, not at the
# chunk's length.
law end_of_track_ends:
  for rest: List<&2, U32>
  {Mi.Midi.end(1n, Mi.Midi.next(Mi.Track{0 <> 255 <> 47 <> 0 <> rest, 0})) == Mi.Track{rest, 255} : Mi.Midi.Track}

# An event after its delta.
type Closed.At is Data:
  At{delta: U32, event: Mi.Midi.Event}

# A track's events to its end, each after its delta, at most n.
def Closed.events(n: Nat, g: Mi.Midi.Got, +d: U32) -> List<&2, Closed.At>:
  match n g:
    case _ Mi.Got{Mi.End{}, t}:
      [At{d, Mi.End{}}]
    case 0n Mi.Got{e, t}:
      []
    case 1n+m Mi.Got{e, +t}:
      At{d, e} <> Closed.events(m, Mi.Midi.next(t), Mi.Midi.delta(t))

def Closed.track(+t: Mi.Midi.Track) -> List<&2, Closed.At>:
  Closed.events(40n, Mi.Midi.next(t), Mi.Midi.delta(t))

# A song's division, and its first track's events.
def Closed.song(f: Mi.Midi.File) -> U32 & List<&2, Closed.At>:
  Mi.File{division, tracks} = f
  (division, Closed.track(Maybe.default(&2, Mi.Midi.Track, List.head(&2, Mi.Midi.Track, tracks), Mi.Bad{""})))

# A MUS lump of a score: its header, the score at byte 16.
def Closed.mus(score: List<&2, U32>) -> List<&2, U32>:
  List.append(&2, U32, [77, 85, 83, 26, 0, 0, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0], score)

# A MIDI lump of one track, at a division of 96 unless the header says.
def Closed.midi(header: List<&2, U32>, track: List<&2, U32>) -> List<&2, U32>:
  List.concat(&2, U32, [[77, 84, 104, 100, 0, 0, 0, 6], header, [77, 84, 114, 107, 0, 0, 0, 0], track])

def Closed.fails(+lump: List<&2, U32>) -> Bool:
  Maybe.is_some(&2, String, Mi.Midi.fault(lump))

# LAW: a MUS score as mus2mid.c converts it. Channel 3, used first, is
# MIDI channel 0 and gets an all-notes-off with the delta before its
# first event; percussion channel 15 is 9 and gets none. A key with its
# top bit set carries a velocity, masked to 7 bits, which later presses
# on the channel reuse, whatever other channels do. The pitch wheel's
# byte b is bend 64 * (b & 1), b >> 1; system event 14 is controller
# 121; controller 0 is a program change and 3 is volume, 144 cut to 127.
# The nine channels used next take MIDI 1 to 8 and then 10. A set top
# bit on a descriptor ends its group, and the delay that follows, 5, 128
# and 257 in two bytes each, and 3, falls on the next event, the end
# included.
law mus_events:
  {Closed.song(Mi.Midi.file(Closed.mus([147, 188, 100, 5, 19, 62, 31, 164, 133, 35, 129, 51, 14, 67, 0, 133,
    195, 3, 144, 129, 0, 0, 60, 1, 60, 2, 60, 4, 60, 5, 60, 6, 60, 7, 60, 8, 60, 137, 188, 130, 1, 147, 64, 3, 96])))
    == (70, [At{0, Mi.Chan{176, 0, 123, 0}}, At{0, Mi.Chan{144, 0, 60, 100}}, At{5, Mi.Chan{144, 0, 62, 100}},
      At{0, Mi.Chan{144, 9, 36, 5}}, At{0, Mi.Chan{224, 0, 64, 64}}, At{0, Mi.Chan{176, 0, 121, 0}},
      At{0, Mi.Chan{192, 0, 5, 0}}, At{0, Mi.Chan{176, 0, 7, 127}}, At{128, Mi.Chan{176, 1, 123, 0}},
      At{0, Mi.Chan{128, 1, 60, 0}}, At{0, Mi.Chan{176, 2, 123, 0}}, At{0, Mi.Chan{128, 2, 60, 0}},
      At{0, Mi.Chan{176, 3, 123, 0}}, At{0, Mi.Chan{128, 3, 60, 0}}, At{0, Mi.Chan{176, 4, 123, 0}},
      At{0, Mi.Chan{128, 4, 60, 0}}, At{0, Mi.Chan{176, 5, 123, 0}}, At{0, Mi.Chan{128, 5, 60, 0}},
      At{0, Mi.Chan{176, 6, 123, 0}}, At{0, Mi.Chan{128, 6, 60, 0}}, At{0, Mi.Chan{176, 7, 123, 0}},
      At{0, Mi.Chan{128, 7, 60, 0}}, At{0, Mi.Chan{176, 8, 123, 0}}, At{0, Mi.Chan{128, 8, 60, 0}},
      At{0, Mi.Chan{176, 10, 123, 0}}, At{0, Mi.Chan{128, 10, 60, 0}}, At{257, Mi.Chan{144, 0, 64, 100}},
      At{3, Mi.End{}}]) : U32 & List<&2, Closed.At>}

# LAW: a SMPTE division, 0xE728, means 25 frames a second of 40 ticks,
# but MIDI_GetFileTimeDivision divides the whole short, -6360, by 256
# toward zero: 24 * 40 ticks a beat (sanity).
law smpte_division:
  {Closed.song(Mi.Midi.file(Closed.midi([0, 0, 0, 1, 231, 40], [0, 255, 47, 0])))
    == (960, [At{0, Mi.End{}}]) : U32 & List<&2, Closed.At>}

# LAW: the lumps the render refuses, in order, and near misses it takes:
# neither MUS nor MIDI. MIDI, after the smallest track it takes: a status
# byte of 0xF3; a data byte before any status; a delta of five bytes, but
# not of four; a track cut short; format 2; a track header other than
# MTrk. MUS, after the smallest score it takes: controller 10 in a
# controller change; event type 5; system event 9; a delay of 2^28 ticks;
# a delay of 2^28 - 1, which mus2mid.c writes but whose microseconds
# pass the 2^31 the render counts, though a delay of 300000 ticks, 35.7
# minutes at 140 a second, is taken; a score cut short; and a score of
# 49144 releases in a lump of 96 KiB, which i_oplmusic.c does not
# convert.
law song_faults:
  {[Closed.fails([1, 2, 3, 4, 5, 6, 7, 8]),
    Closed.fails(Closed.midi([0, 0, 0, 1, 0, 96], [0, 255, 47, 0])),
    Closed.fails(Closed.midi([0, 0, 0, 1, 0, 96], [0, 243, 0, 255, 47, 0])),
    Closed.fails(Closed.midi([0, 0, 0, 1, 0, 96], [0, 60, 100, 0, 255, 47, 0])),
    Closed.fails(Closed.midi([0, 0, 0, 1, 0, 96], [129, 128, 128, 128, 0, 255, 47, 0])),
    Closed.fails(Closed.midi([0, 0, 0, 1, 0, 96], [128, 128, 128, 0, 255, 47, 0])),
    Closed.fails(Closed.midi([0, 0, 0, 1, 0, 96], [0, 144, 60])),
    Closed.fails(Closed.midi([0, 2, 0, 1, 0, 96], [0, 255, 47, 0])),
    Closed.fails([77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96, 77, 84, 114, 120, 0, 0, 0, 0, 0, 255, 47, 0]),
    Closed.fails(Closed.mus([96])),
    Closed.fails(Closed.mus([64, 10, 0, 96])),
    Closed.fails(Closed.mus([80, 96])),
    Closed.fails(Closed.mus([48, 9, 96])),
    Closed.fails(Closed.mus([128, 60, 129, 128, 128, 128, 0, 96])),
    Closed.fails(Closed.mus([128, 60, 255, 255, 255, 127, 96])),
    Closed.fails(Closed.mus([128, 60, 146, 167, 96, 96])),
    Closed.fails(Closed.mus([16])),
    Closed.fails(Closed.mus(List.append(&2, U32, List.replicate(U32, U32.to_nat(98288), 0), [96])))]
    == [True{}, False{}, True{}, True{}, True{}, False{}, True{}, True{}, True{}, False{}, True{}, True{}, True{},
      True{}, True{}, False{}, True{}, True{}] : List<&2, Bool>}

def Closed.buffer(o: O.Opl) -> U32 & U32 & Nat:
  O.Opl{core, count, last, pending, rcnt, oldl, oldr, curl, curr} = o
  (count, last, List.length(&2, O.Opl.Pending, pending))

# LAW: the 1025th write queued on a reset chip finds OPL3_WriteRegBuffered's
# buffer full: the first, due at sample 2, is applied at once and the
# sample count moves to 2, while the new write is due at 2050, two after
# the 1024th (sanity).
law buffer_spills:
  {Closed.buffer(O.Opl.queue(List.replicate(O.Opl.Write, U32.to_nat(1025), O.Write{1, 0}), O.Opl.reset()))
    == (2, 2050, U32.to_nat(1024)) : U32 & U32 & Nat}

# LAW: any callback pushed on the empty heap is its first, and popping
# it empties the heap.
law heap_one:
  for +e: Sg.Song.Entry
  {(Sg.Song.push([], e), Sg.Song.pop(Sg.Song.push([], e))) == ([e], [])
    : List<&2, Sg.Song.Entry> & List<&2, Sg.Song.Entry>}

# LAW: callbacks due at the same time do not pop in the order they were
# pushed: after the first, OPL_Queue_Pop moves the last entry to the top,
# so the third pushed runs before the second (sanity).
law heap_ties:
  {Sg.Song.pop(Sg.Song.push(Sg.Song.push(Sg.Song.push([], Sg.Entry{5, Some{0}}), Sg.Entry{5, Some{1}}),
    Sg.Entry{5, Some{2}}))
    == [Sg.Entry{5, Some{2}}, Sg.Entry{5, Some{1}}] : List<&2, Sg.Song.Entry>}

# LAW: before any note, a note off or an all-notes-off on any channel
# releases nothing and writes nothing.
law quiet_offs:
  for +t: Pl.Player.Tabs
  for +raw: U32
  for +key: U32
  for +vel: U32
  {(Pl.Player.event(t, 128, raw, key, vel, Pl.Player.start()),
    Pl.Player.event(t, 176, raw, 123, vel, Pl.Player.start()))
    == (Pl.Player.start(), Pl.Player.start()) : Pl.Player & Pl.Player}

# Sound lumps
# -----------

# LAW: CacheSFX's refusals, on a 57-byte lump unless said: a lump under
# its 8-byte header, a format other than 3, a length of 48, and a length
# one past what follows the header are refused; a length of 49 that fits
# is played (sanity).
law sfx_refusals:
  {[X.Sfx.played(7, 3, 0), X.Sfx.played(57, 2, 49), X.Sfx.played(57, 3, 48), X.Sfx.played(57, 3, 50),
    X.Sfx.played(57, 3, 49)]
    == [False{}, False{}, False{}, False{}, True{}] : List<&2, Bool>}

# LAW: a sound at 16000 or 17990 Hz, the rates of Freedoom's two sounds
# that SDL's converter is not given, has no run, whatever it holds.
law sfx_rates_unserved:
  for count: U32
  for bytes: List<&2, U32>
  {(X.Sfx.run(X.Sound{16000, count, bytes}), X.Sfx.run(X.Sound{17990, count, bytes}))
    == (None{}, None{}) : Maybe<&2, X.Sfx.Run> & Maybe<&2, X.Sfx.Run>}

# The status bar
# --------------

# LAW: ST_updateWidgets' keyboxes over the three colours, the icons
# numbered as ST_loadGraphics loads STKEYS0 to STKEYS5 from slot 21: a
# colour with neither key shows nothing, the blue card shows the first
# icon, the blue skull over it shows the fourth, and the red skull alone
# shows the sixth in the bottom slot.
law key_boxes:
  {[Y.Bar.keybox(0, 0), Y.Bar.keybox(0, 2), Y.Bar.keybox(1, 0), Y.Bar.keybox(1, 1), Y.Bar.keybox(9, 0),
    Y.Bar.keybox(32, 2), Y.Bar.keybox(32, 0)]
    == [4294967295, 4294967295, 21, 4294967295, 24, 26, 4294967295] : List<&2, U32>}

# LAW: ST_createWidgets' w_arms reads weaponowned[i + 1], so the arms
# panel counts the pistol first and the BFG last and never the fist or
# the chainsaw: the starting pair shows the pistol's yellow number, slot
# 12, and a grey number for every other, and owning the chainsaw leaves
# slot 6 grey while owning the BFG turns it yellow.
law arms_numbers:
  {[Y.Bar.arm(3, 0), Y.Bar.arm(3, 1), Y.Bar.arm(7, 1), Y.Bar.arm(3, 5), Y.Bar.arm(131, 5), Y.Bar.arm(64, 5)]
    == [12, 28, 13, 32, 32, 17] : List<&2, U32>}

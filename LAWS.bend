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
import ./src/clip.bend as C
import ./src/project.bend as P
import ./src/draw.bend as D
import ./src/segs.bend as R
import ./src/planes.bend as N
import ./src/gfx.bend as G
import ./src/opl.bend as O
import ./src/midi.bend as Mi
import ./src/player.bend as Pl
import ./src/song.bend as Sg

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
# turn is 320 for its first five tics, then 640, or 1280 running; Space
# is the use button (sanity).
law cmd_tables:
  {(K.Keys.cmd(K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{True{}, False{}, False{}, False{}, False{}, False{}, True{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, False{}, True{}, False{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, True{}, False{}, True{}, False{}}, 0),
    K.Keys.cmd(K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, 5),
    K.Keys.cmd(K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, 6),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, True{}, False{}, False{}, True{}, False{}}, 6),
    K.Keys.cmd(K.Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, True{}}, 0))
    == (K.Cmd{25, 0, 0, False{}}, K.Cmd{50, 0, 0, False{}}, K.Cmd{0, 24, 0, False{}}, K.Cmd{0, 4294967256, 0, False{}},
      K.Cmd{0, 0, 320, False{}}, K.Cmd{0, 0, 640, False{}}, K.Cmd{0, 0, 4294966016, False{}},
      K.Cmd{0, 0, 0, True{}})
    : K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd & K.Cmd}

# LAW: the held count lives in the input: seven tics of the left key
# from a fresh input turn 320 five times, then 640 (sanity).
law turn_script:
  {K.Input.script(7n, K.Input{K.Keys{False{}, False{}, True{}, False{}, False{}, False{}, False{}, False{}}, 0})
    == [K.Cmd{0, 0, 320, False{}}, K.Cmd{0, 0, 320, False{}}, K.Cmd{0, 0, 320, False{}},
      K.Cmd{0, 0, 320, False{}}, K.Cmd{0, 0, 320, False{}}, K.Cmd{0, 0, 640, False{}},
      K.Cmd{0, 0, 640, False{}}] : List<&2, K.Cmd>}

# The sim
# -------

# A level's first state with the player as given, at a clock.
def Closed.state(p: S.Player, level: L.Level, clock: U32) -> S.State:
  S.State{p, level, V.Leaf{0}, [], 0, clock, False{}, False{}}

# LAW: one tic of the idle command from rest leaves the player where it
# was, on any level, at any position.
law tic_rest:
  for +level: L.Level
  for +x: U32
  for +y: U32
  {(S.Player.x(S.State.player(S.Sim.tic(K.Cmd.idle(),
      Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, []}, level, 0)))),
    S.Player.y(S.State.player(S.Sim.tic(K.Cmd.idle(),
      Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, []}, level, 0)))))
    == (x, y) : U32 & U32}

# LAW: a tic counts on the clock, and an ended level's tic changes
# nothing, whatever the command.
law tic_counts:
  for +cmd: K.Cmd
  for +p: S.Player
  for +level: L.Level
  for +clock: U32
  {(S.State.clock(S.Sim.tic(cmd, Closed.state(p, level, clock))),
    S.Sim.tic(cmd, S.State{p, level, V.Leaf{0}, [], 0, clock, True{}, False{}}))
    == ((clock + 1 : U32), S.State{p, level, V.Leaf{0}, [], 0, clock, True{}, False{}}) : U32 & S.State}

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
  {Closed.room([K.Cmd{25, 0, 0, False{}}], S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, []}, 0)
    == S.Player{51199, 19, 0, 0, 46399, 17, 0, 0, 8388608, 2686976, 0, 2686977, []} : S.Player}

# LAW: standing still on the floor puts the eye 41 above it, at any
# position, whatever the eye was.
law eye_rest:
  for x: U32
  for y: U32
  {S.Player.viewz(Closed.room([K.Cmd.idle()], S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, []}, 0))
    == 2686976 : U32}

# LAW: 64 above the floor, the first airborne tic sets the fall to twice
# gravity without moving, the second moves by it and adds gravity once;
# the eye sits 41 above the height the tic began at (sanity).
law fall_gravity:
  {(Closed.room([K.Cmd.idle()], S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, []}, 0),
    Closed.room([K.Cmd.idle(), K.Cmd.idle()], S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, []}, 0))
    == (S.Player{0, 0, 4194304, 0, 0, 0, 4294836224, 0, 8388608, 2686976, 0, 6881280, []},
      S.Player{0, 0, 4063232, 0, 0, 0, 4294770688, 0, 8388608, 2686976, 0, 6881280, []})
    : S.Player & S.Player}

# LAW: landing at 9 a tic dips the view by an eighth of it, -1.125;
# landing at 8 a tic does not (sanity).
law landing_dip:
  {(Closed.room([K.Cmd.idle()], S.Player{0, 0, 65536, 0, 0, 0, 4294377472, 0, 8388608, 2686976, 0, 0, []}, 0),
    Closed.room([K.Cmd.idle()], S.Player{0, 0, 65536, 0, 0, 0, 4294443008, 0, 8388608, 2686976, 0, 0, []}, 0))
    == (S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 4294893568, 2752512, []},
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2752512, []})
    : S.Player & S.Player}

# LAW: the bob at the clock's peak (tic 5, sine 65535). The first tic of
# a run from rest has momentum 102398, 39, whose square over four is
# 39998, and half of it bobs the eye by 19998. At 30 a tic the square
# over four is 14745600, capped at 16 units, and half of it bobs the eye
# by 524280, a hair under 8 units (sanity).
law bob_run_and_cap:
  {(S.Player.viewz(Closed.room([K.Cmd{50, 0, 0, False{}}],
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, []}, 5)),
    S.Player.viewz(Closed.room([K.Cmd.idle()],
      S.Player{0, 0, 0, 0, 1966080, 0, 0, 0, 8388608, 2686976, 0, 0, []}, 5)))
    == (2706974, 3211256) : U32 & U32}

# LAW: a floor 16 above the player's feet lifts the player onto it, cuts
# the view height by the 16 to 25, and sets it recovering by an eighth
# of the gap, 2 a tic (sanity).
law step_up_dip:
  {Closed.room([K.Cmd.idle()], S.Player{0, 0, 0, 0, 0, 0, 0, 1048576, 8388608, 2686976, 0, 0, []}, 0)
    == S.Player{0, 0, 1048576, 0, 0, 0, 0, 1048576, 8388608, 1638400, 131072, 2686976, []} : S.Player}

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
# check.
def Closed.level(ox: U32) -> L.Level:
  L.Level.grouped(L.Level{L.Geo{V.Vec.of_list([0, 1, 4, 0, 1, 2, 3, 4, 2, 3], 10),
    V.Vec.of_list([0, 0, 0, 0, 0, 1, 0, 0, 2, 0, 0, 1], 12), V.Vec.of_list([64, 128, 64, 0, 80, 0, 80, 128], 8),
    V.Vec.of_list([0, 1, 0, 0, 0, 0], 6), V.Vec.of_list([1, 0], 2), V.Leaf{0}, 32768,
    L.Blockmap{V.Vec.of_list([0, 0, 1, 1, 5, 0, 0, 1, 65535], 9), ox, 0, 1, 1}, L.Start{0, 0, 0}, [], [],
    V.Vec.of_list(T.Tables.finesine(), 10240), V.Vec.of_list(T.Tables.tantoangle(), 2049), V.Leaf{0}, 2, 3,
    V.Leaf{0}, V.Leaf{0}, V.Leaf{0}},
    V.Vec.of_list([0, 8388608, 160, 0, 0, 160, 0, 4718592, 160], 9), V.Vec.of_list([1, 0, 117, 0], 4)})

def Closed.doors() -> L.Level:
  Closed.level(0)

# A player at rest on the floor at 0, under a ceiling.
def Closed.player(x: U32, y: U32, angle: U32, ceilz: U32) -> S.Player:
  S.Player{x, y, 0, angle, 0, 0, 0, 0, ceilz, 2686976, 0, 2686976, []}

# The west room's player, 32 units from the door and facing it, and the
# east room's.
def Closed.west() -> S.State:
  Closed.state(Closed.player(2097152, 4194304, 0, 8388608), Closed.doors(), 0)

def Closed.east() -> S.State:
  Closed.state(Closed.player(7340032, 4194304, 2147483648, 4718592), Closed.doors(), 0)

# The state after a tic of use and then idle tics.
def Closed.used(idle: Nat, s: S.State) -> S.State:
  S.Sim.replay(K.Cmd{0, 0, 0, True{}} <> List.replicate(K.Cmd, idle, K.Cmd.idle()), s)

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
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}]}], [])
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
  S.State{Closed.player(x, y, 0, ceilz), level, V.Leaf{0}, [t], 0, 0, False{}, False{}}

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
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}]},
      2097152, 4194304, 8388608))),
    S.State.player(Closed.idled(2n, Closed.moving(Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}]},
      2097152, 4194304, 8388608))),
    S.State.player(Closed.idled(1n, Closed.moving(Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}]},
      13107200, 4194304, 8388608))))
    == (S.Player{2097152, 4194304, 4294705152, 0, 0, 0, 0, 4294705152, 8388608, 2686976, 0, 2686976, []},
      S.Player{2097152, 4194304, 4294443008, 0, 0, 0, 0, 4294443008, 8388608, 2686976, 0, 2424832, []},
      S.Player{13107200, 4194304, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, []})
    : S.Player & S.Player & S.Player}

# LAW: a door that closes on the player goes back up. From 68, 2 a tic,
# over a player 56 tall standing across both its faces at (72, 64): 56
# after 6 tics; the 7th would be 54, which the player does not fit, so
# the step is undone and the door is back on its plan; 58 after the 8th
# (sanity).
law door_crushed:
  {(Closed.ceil(Closed.idled(6n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}]},
      4718592, 4194304, 4456448)), 1),
    Closed.ceil(Closed.idled(7n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}]},
      4718592, 4194304, 4456448)), 1),
    S.State.thinkers(Closed.idled(7n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}]},
      4718592, 4194304, 4456448))),
    Closed.ceil(Closed.idled(8n, Closed.moving(L.Level.plane.put(Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}]},
      4718592, 4194304, 4456448)), 1))
    == (3670016, 3670016,
      [S.Mover{1, True{}, 131072, [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}]}], 3801088)
    : U32 & U32 & List<&2, S.Thinker> & U32}

# The literal level with line 0 a walk-over turbo floor (special 36; its
# tag 0 is every sector), the door sector's floor at 16, its ceiling and
# the east room's at 128, and a player at x moving east at a speed.
def Closed.turbo(x: U32, momx: U32) -> S.State:
  S.State{S.Player{x, 4194304, 0, 0, momx, 0, 0, 0, 8388608, 2686976, 0, 2686976, []},
    L.Level.special.put(L.Level.plane.put(L.Level.plane.put(L.Level.plane.put(Closed.doors(), 1, False{},
      1048576), 1, True{}, 8388608), 2, True{}, 8388608), 0, 36), V.Leaf{0}, [], 0, 0, False{}, False{}}

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
    L.Level.textured(L.Level.special.put(L.Level.plane.put(L.Level.plane.put(Closed.level(3145728), 1, False{},
      4292870144), 1, True{}, 8388608), 0, special), V.Vec.of_list([0, 0, 1], 12), V.Vec.of_list([0, 2, 1], 3)),
    V.Vec.of_list([0, 0, 1], 12), [], 0, 0, False{}, False{}}

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
        [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}]},
      S.Mover{1, False{}, 262144, [S.Hold{105}, S.Travel{False{}, 4292870144}],
        [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 4292870144}]},
      S.Mover{2, False{}, 262144, [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}],
        [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}]},
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
    == (4294901760, [S.Mover{0, False{}, 65536, [S.Travel{True{}, 4292870144}], [S.Travel{True{}, 4292870144}]},
      S.Mover{2, False{}, 65536, [S.Travel{True{}, 4292870144}], [S.Travel{True{}, 4292870144}]}], 0,
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
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}]},
      2097152, 4194304, 2621440))), 0),
    L.Level.floor(S.State.level(Closed.idled(5n, Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}]},
      2097152, 4194304, 2621440))), 0),
    L.Level.floor(S.State.level(Closed.idled(6n, Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}]},
      2097152, 4194304, 2621440))), 0))
    == (4293918720, 4293918720, 4293656576) : U32 & U32 & U32}

# LAW: use held across two tics fires on the first alone: after a live
# tic whose command holds use, no command is a press, whatever the
# state was.
law use_fires_once:
  for forward: U32
  for side: U32
  for turn: U32
  for +next: K.Cmd
  for player: S.Player
  for level: L.Level
  for sidetex: V.Vec
  for thinkers: List<&2, S.Thinker>
  for rnd: U32
  for clock: U32
  for usedown: Bool
  {S.Sim.pressed(next, S.State.usedown(S.Sim.tic(K.Cmd{forward, side, turn, True{}},
    S.State{player, level, sidetex, thinkers, rnd, clock, False{}, usedown}))) == False{} : Bool}

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
  S.Sim.replay([K.Cmd.idle(), K.Cmd.idle(), K.Cmd{0, 0, 0, True{}}], S.State{Closed.player(2097152, 4194304, 0, 8388608),
    Closed.exit(), L.Level.sidetex(Closed.exit()), [], 0, 0, False{}, False{}})

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

# LAW: vanilla's random table, its first entries and its last, and the
# index wrapping at 256 (sanity).
law random_table:
  {(S.Sim.random(0), S.Sim.random(1), S.Sim.random(2), S.Sim.random(3), S.Sim.random(255),
    S.Sim.random.next(0), S.Sim.random.next(255))
    == (0, 8, 109, 220, 249, 1, 0) : U32 & U32 & U32 & U32 & U32 & U32 & U32}

# The lights' closed laws stand on the literal level with the west room
# at a light and the door sector, light 160, given the light Doom spawns
# for a sector special, the random index at 1 as it is once Doom has
# spawned the player.
def Closed.lit(special: U32, west: U32) -> S.State:
  S.Sim.light.spawn(special, 1, S.State{Closed.player(2097152, 4194304, 0, 8388608),
    L.Level.light.put(Closed.doors(), 0, west), V.Leaf{0}, [], 1, 0, False{}, False{}})

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

# A state whose player is free in its level.
def Free(+s: S.State) -> Type:
  {True{} == S.Sim.free(S.State.level(s), S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))
    : Bool}

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
# included, leaves the player free of solid walls.
law replay_keeps_free:
  for script: List<&2, K.Cmd>
  for +s: S.State
  for free: Free(s)
  Free(S.Sim.replay(script, s))

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

# A song's division, and its first track's events.
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
# controller change; event type 5; system event 9; a delay of 2^28 ticks,
# but not of 2^28 - 1; a score cut short.
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
    Closed.fails(Closed.mus([16]))]
    == [True{}, False{}, True{}, True{}, True{}, False{}, True{}, True{}, True{}, False{}, True{}, True{}, True{},
      True{}, False{}, True{}] : List<&2, Bool>}

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
  {Sg.Song.pop(Sg.Song.push(Sg.Song.push(Sg.Song.push([], Sg.Next{5, 0}), Sg.Next{5, 1}), Sg.Next{5, 2}))
    == [Sg.Next{5, 2}, Sg.Next{5, 1}] : List<&2, Sg.Song.Entry>}

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

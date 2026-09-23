# The laws. The human states them; PROOF.bend must prove them.
import Base
import ./tests/fixtures/closed.bend as Fx
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
import ./src/message.bend as Msg
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
import ./src/channel.bend as Ch

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

# LAW: the first lump called name is at 0 when it heads the list.
law index_head:
  for +name: String
  for pos: U32
  for size: U32
  for rest: List<&2, W.Wad.Lump>
  {W.Wad.index(name, W.Lump{pos, size, name} <> rest) == Some{0n} : Maybe<Nat>}

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

# LAW: the lowest held number key wins, whatever the higher ones do, as
# G_BuildTiccmd's loop breaks at the first: BT_CHANGE, 4, with the key's
# number less one at BT_WEAPONSHIFT, 3.
law lowest_number_wins:
  for two: Bool
  for three: Bool
  {(K.Keys.change(True{}, two, three), K.Keys.change(False{}, True{}, three),
    K.Keys.change(False{}, False{}, True{}), K.Keys.change(False{}, False{}, False{}))
    == (4, 12, 20, 0) : U32 & U32 & U32 & U32}

# The sim
# -------

# LAW: one tic of the idle command from rest leaves the player where it
# was, on any level, at any position.
law tic_rest:
  for +level: L.Level
  for +x: U32
  for +y: U32
  {(S.Player.x(S.State.player(S.Sim.tic(K.Cmd.idle(),
      Fx.Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, level, 0)))),
    S.Player.y(S.State.player(S.Sim.tic(K.Cmd.idle(),
      Fx.Closed.state(S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, level, 0)))))
    == (x, y) : U32 & U32}

# LAW: a tic counts on the clock, and an ended level's tic changes
# nothing, whatever the command.
law tic_counts:
  for +cmd: K.Cmd
  for +p: S.Player
  for +level: L.Level
  for +clock: U32
  {(S.State.clock(S.Sim.tic(cmd, Fx.Closed.state(p, level, clock))),
    S.Sim.tic(cmd, S.State{p, level, Fx.Closed.none(), V.Leaf{0}, S.Thinkers{[], []}, 0, clock, True{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}}))
    == ((clock + 1 : U32),
      S.State{p, level, Fx.Closed.none(), V.Leaf{0}, S.Thinkers{[], []}, 0, clock, True{}, False{}, [], S.Sim.Face.start(0), False{}, V.Leaf{0}})
    : U32 & S.State}

# The closed laws below stand on Level.room: one sector, no lines, the
# floor at 0 and the ceiling at 128 map units. Every number is computed
# by hand from vanilla's formulas.

# LAW: standing still on the floor puts the eye 41 above it, at any
# position, whatever the eye was.
law eye_rest:
  for x: U32
  for y: U32
  {S.Player.viewz(Fx.Closed.room([K.Cmd.idle()], S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0))
    == 2686976 : U32}

# LAW: a manual door, vanilla's T_VerticalDoor. The top is 4 under the
# lower ceiling beside it, 68. Used on tic 1 it is 2 up after that tic
# and at 68 after tic 34; tic 35 would pass, so it lands and the wait
# starts; the count reaches zero on tic 185, which only turns the door;
# tic 186 is the first step down, tic 219 shuts it, and tic 220 passes
# the floor and ends the thinker (sanity).
law door_timeline:
  {(Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.west()), 1), Fx.Closed.ceil(Fx.Closed.used(32n, Fx.Closed.west()), 1),
    Fx.Closed.ceil(Fx.Closed.used(33n, Fx.Closed.west()), 1), Fx.Closed.ceil(Fx.Closed.used(184n, Fx.Closed.west()), 1),
    Fx.Closed.ceil(Fx.Closed.used(185n, Fx.Closed.west()), 1), Fx.Closed.ceil(Fx.Closed.used(217n, Fx.Closed.west()), 1),
    Fx.Closed.ceil(Fx.Closed.used(218n, Fx.Closed.west()), 1), Fx.Closed.running(Fx.Closed.used(218n, Fx.Closed.west())),
    Fx.Closed.running(Fx.Closed.used(219n, Fx.Closed.west())))
    == (131072, 4325376, 4456448, 4456448, 4325376, 131072, 0,
      [S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()}], [])
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & List<&2, S.Thinker> & List<&2, S.Thinker>}

# LAW: the blazing door moves 8 a tic: 64 after tic 8, tic 9 would pass
# and lands on 68; the wait ends on tic 159, tic 160 is 60, tic 167 is
# 4, and tic 168 lands on the floor and ends the thinker (sanity).
law blazing_door_timeline:
  {(Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.east()), 1), Fx.Closed.ceil(Fx.Closed.used(7n, Fx.Closed.east()), 1),
    Fx.Closed.ceil(Fx.Closed.used(8n, Fx.Closed.east()), 1), Fx.Closed.ceil(Fx.Closed.used(158n, Fx.Closed.east()), 1),
    Fx.Closed.ceil(Fx.Closed.used(159n, Fx.Closed.east()), 1), Fx.Closed.ceil(Fx.Closed.used(166n, Fx.Closed.east()), 1),
    Fx.Closed.ceil(Fx.Closed.used(167n, Fx.Closed.east()), 1), Fx.Closed.running(Fx.Closed.used(167n, Fx.Closed.east())))
    == (524288, 4194304, 4456448, 4456448, 3932160, 262144, 0, [])
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & List<&2, S.Thinker>}

# LAW: a moving floor carries the player standing on it, vanilla's
# P_ThingHeightClip. The west room's floor goes down 4 a tic. A player at
# (32, 64) is in the one cell of the sector's block box: after a tic the
# floor, the player's height and the player's floor are -4, the view
# height is still 41 with no delta, so no dip, and the eye, worked out
# when the tic began, follows a tic later. A player at (200, 64) is a
# cell outside the box, and is left where it was (sanity).
law floor_carries:
  {(S.State.player(Fx.Closed.idled(1n, Fx.Closed.moving(Fx.Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()},
      2097152, 4194304, 8388608))),
    S.State.player(Fx.Closed.idled(2n, Fx.Closed.moving(Fx.Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()},
      2097152, 4194304, 8388608))),
    S.State.player(Fx.Closed.idled(1n, Fx.Closed.moving(Fx.Closed.doors(),
      S.Mover{0, False{}, 262144, [S.Travel{True{}, 4293918720}], [S.Travel{True{}, 4293918720}], S.Sim.noise.floor()},
      13107200, 4194304, 8388608))))
    == (S.Player{2097152, 4194304, 4294705152, 0, 0, 0, 0, 4294705152, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()},
      S.Player{2097152, 4194304, 4294443008, 0, 0, 0, 0, 4294443008, 8388608, 2686976, 0, 2424832, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()},
      S.Player{13107200, 4194304, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()})
    : S.Player & S.Player & S.Player}

# LAW: a door that closes on the player goes back up. From 68, 2 a tic,
# over a player 56 tall standing across both its faces at (72, 64): 56
# after 6 tics; the 7th would be 54, which the player does not fit, so
# the step is undone and the door is back on its plan; 58 after the 8th
# (sanity).
law door_crushed:
  {(Fx.Closed.ceil(Fx.Closed.idled(6n, Fx.Closed.moving(L.Level.plane.put(Fx.Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448)), 1),
    Fx.Closed.ceil(Fx.Closed.idled(7n, Fx.Closed.moving(L.Level.plane.put(Fx.Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448)), 1),
    Fx.Closed.running(Fx.Closed.idled(7n, Fx.Closed.moving(L.Level.plane.put(Fx.Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448))),
    Fx.Closed.ceil(Fx.Closed.idled(8n, Fx.Closed.moving(L.Level.plane.put(Fx.Closed.doors(), 1, True{}, 4456448),
      S.Mover{1, True{}, 131072, [S.Travel{True{}, 0}], [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()},
      4718592, 4194304, 4456448)), 1))
    == (3670016, 3670016,
      [S.Mover{1, True{}, 131072, [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()}], 3801088)
    : U32 & U32 & List<&2, S.Thinker> & U32}

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
  {(Fx.Closed.floors(Fx.Closed.idled(1n, Fx.Closed.turbo(3932160, 524288))),
    Fx.Closed.floors(Fx.Closed.idled(2n, Fx.Closed.turbo(3932160, 524288))),
    Fx.Closed.running(Fx.Closed.idled(3n, Fx.Closed.turbo(3932160, 524288))),
    L.Level.special(S.State.level(Fx.Closed.idled(1n, Fx.Closed.turbo(3932160, 524288))), 0),
    Fx.Closed.running(Fx.Closed.idled(1n, Fx.Closed.turbo(2883584, 393216))),
    L.Level.special(S.State.level(Fx.Closed.idled(1n, Fx.Closed.turbo(2883584, 393216))), 0))
    == ((1572864, 786432, 1572864), (1572864, 524288, 1572864), [], 0, [], 36)
    : (U32 & U32 & U32) & (U32 & U32 & U32) & List<&2, S.Thinker> & U32 & List<&2, S.Thinker> & U32}

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
  {(Fx.Closed.running(Fx.Closed.used(0n, Fx.Closed.lifts())), Fx.Closed.seen(Fx.Closed.used(7n, Fx.Closed.lifts())),
    Fx.Closed.seen(Fx.Closed.used(33n, Fx.Closed.lifts())), Fx.Closed.seen(Fx.Closed.used(34n, Fx.Closed.lifts())),
    Fx.Closed.seen(Fx.Closed.used(113n, Fx.Closed.lifts())), Fx.Closed.seen(Fx.Closed.used(114n, Fx.Closed.lifts())),
    Fx.Closed.seen(Fx.Closed.used(121n, Fx.Closed.lifts())), Fx.Closed.running(Fx.Closed.used(122n, Fx.Closed.lifts())))
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
  {(L.Level.floor(S.State.level(Fx.Closed.used(0n, Fx.Closed.switched(23))), 0),
    Fx.Closed.running(Fx.Closed.used(0n, Fx.Closed.switched(23))),
    L.Level.special(S.State.level(Fx.Closed.used(0n, Fx.Closed.switched(23))), 0),
    L.Level.floor(S.State.level(Fx.Closed.used(31n, Fx.Closed.switched(23))), 0),
    Fx.Closed.running(Fx.Closed.used(32n, Fx.Closed.switched(23))))
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
  {(L.Level.floor(S.State.level(Fx.Closed.idled(4n, Fx.Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Fx.Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      2097152, 4194304, 2621440))), 0),
    L.Level.floor(S.State.level(Fx.Closed.idled(5n, Fx.Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Fx.Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
      S.Mover{0, False{}, 262144, [S.Travel{False{}, 0}], [S.Travel{True{}, 4292870144}, S.Hold{105}, S.Travel{False{}, 0}], S.Sim.noise.lift()},
      2097152, 4194304, 2621440))), 0),
    L.Level.floor(S.State.level(Fx.Closed.idled(6n, Fx.Closed.moving(L.Level.plane.put(L.Level.plane.put(
      Fx.Closed.doors(), 0, False{}, 4292870144), 0, True{}, 2621440),
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
  for thinkers: S.Thinkers
  for rnd: U32
  for clock: U32
  for usedown: Bool
  for sounds: List<&2, Sn.Sound.Event>
  for mrnd: V.Vec
  for reborn: Bool
  for secrets: V.Vec
  for held: {True{} == K.Cmd.use(K.Cmd{forward, side, turn, buttons}) : Bool}
  {S.Sim.pressed(next, S.State.usedown(S.Sim.tic(K.Cmd{forward, side, turn, buttons},
    S.State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, sounds, mrnd, reborn, secrets}))) == False{} : Bool}

# LAW: once means once: a line fired for good has no special afterwards,
# whatever the state and the line.
law once_clears:
  for +line: U32
  for s: S.State
  {L.Level.special(S.State.level(S.Sim.once(line, s)), line) == 0 : U32}

# LAW: the exit switch, vanilla's special 11: P_ChangeSwitchTexture, then
# G_ExitLevel, and the tic runs on. Used on tic 3, the level has ended
# with the clock at 3, the line's special is gone and its side shows the
# switch's partner; a tic of any command after that changes nothing.
law exit_ends:
  for +cmd: K.Cmd
  {(S.State.ended(Fx.Closed.exited()), S.State.clock(Fx.Closed.exited()),
    L.Level.special(S.State.level(Fx.Closed.exited()), 0), V.Vec.get(S.State.sidetex(Fx.Closed.exited()), 2),
    S.Sim.tic(cmd, Fx.Closed.exited()))
    == (True{}, 3, 0, 2, Fx.Closed.exited()) : Bool & U32 & U32 & U32 & S.State}

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
  {(Fx.Closed.heard(400, 0), Fx.Closed.heard(400, 2147483648), Fx.Closed.heard(400, 3221225472),
    Fx.Closed.heard(200, 1073741824), Fx.Closed.heard(201, 1073741824), Fx.Closed.heard(1184, 1073741824),
    Fx.Closed.heard(1185, 1073741824), Fx.Closed.heard(1201, 1073741824))
    == ((51, 33), (51, 224), (51, 128), (64, 129), (63, 129), (1, 129), (0, 129), (0, 129))
    : (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32) & (U32 & U32)}

law sound_coincident:
  {(Fx.Closed.coincident(True{}), Fx.Closed.coincident(False{})) == ((64, 128), (64, 224))
    : (U32 & U32) & (U32 & U32)}

# LAW: the manual door's sounds, where T_VerticalDoor and EV_VerticalDoor
# start them: sfx_doropn, 20, on the tic of the use, nothing on the next,
# sfx_dorcls, 21, on tic 185 as the wait ends, and nothing as it shuts.
# The door's lines span x 64 to 80 and y 0 to 128, so it sounds from
# (72, 64), 40 east of the west room's player, who faces it: full volume,
# and dead ahead is 129. Two starts draw twice from M_Random and each of
# the 219 tics draws once for ST_Ticker's face, so the index stands at
# 221 (sanity).
law door_sounds:
  {(S.State.sounds(Fx.Closed.used(0n, Fx.Closed.west())), S.State.sounds(Fx.Closed.used(1n, Fx.Closed.west())),
    S.State.sounds(Fx.Closed.used(184n, Fx.Closed.west())), S.State.sounds(Fx.Closed.used(218n, Fx.Closed.west())),
    S.State.mrnd(Fx.Closed.used(218n, Fx.Closed.west())))
    == ([Sn.Start{20, Sn.Sector{1}, 64, 129}], [], [Sn.Start{21, Sn.Sector{1}, 64, 129}], [], 221)
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
  {(S.State.sounds(Fx.Closed.used(0n, Fx.Closed.lifts())), S.State.sounds(Fx.Closed.used(34n, Fx.Closed.lifts())))
    == ([Sn.Start{18, Sn.Sector{0}, 64, 129}, Sn.Start{18, Sn.Sector{1}, 64, 129}, Sn.Start{18, Sn.Sector{2}, 64, 129},
      Sn.Start{23, Sn.Nobody{}, 64, 128}, Sn.Start{19, Sn.Sector{1}, 64, 129}],
      [Sn.Start{23, Sn.Spot{0, 0}, 64, 214}])
    : List<&2, Sn.Sound.Event> & List<&2, Sn.Sound.Event>}

# LAW: the random blink, vanilla's T_LightFlash, between 160 and the 96
# beside it. Its first count is the table's entry 2, 109, masked with 64,
# plus 1: 65. On tic 65 it goes dark for entry 3, 220, masked with 7,
# plus 1: 5 tics. On tic 70 it is bright again for entry 4, 222, masked
# with 64, plus 1 (sanity).
law blink_counts:
  {(Fx.Closed.running(Fx.Closed.lit(1, 96)), Fx.Closed.light(Fx.Closed.idled(64n, Fx.Closed.lit(1, 96))),
    Fx.Closed.light(Fx.Closed.idled(65n, Fx.Closed.lit(1, 96))), Fx.Closed.running(Fx.Closed.idled(65n, Fx.Closed.lit(1, 96))),
    Fx.Closed.light(Fx.Closed.idled(69n, Fx.Closed.lit(1, 96))), Fx.Closed.light(Fx.Closed.idled(70n, Fx.Closed.lit(1, 96))),
    Fx.Closed.running(Fx.Closed.idled(70n, Fx.Closed.lit(1, 96))), S.State.rnd(Fx.Closed.idled(70n, Fx.Closed.lit(1, 96))))
    == ([S.Blink{1, 65, 96, 160, 7, 64, True{}}], 160, 96, [S.Blink{1, 5, 96, 160, 7, 64, True{}}], 96, 160,
      [S.Blink{1, 65, 96, 160, 7, 64, True{}}], 4)
    : List<&2, S.Thinker> & U32 & U32 & List<&2, S.Thinker> & U32 & U32 & List<&2, S.Thinker> & U32}

# LAW: the slow strobe in step, vanilla's T_StrobeFlash: dark from the
# first tic for 35, bright for 5. Beside a room at 96 its dark level is
# 96; beside rooms no darker than its own 160 it is 0 (sanity).
law strobe_timeline:
  {(Fx.Closed.light(Fx.Closed.lit(12, 96)), Fx.Closed.light(Fx.Closed.idled(1n, Fx.Closed.lit(12, 96))),
    Fx.Closed.light(Fx.Closed.idled(35n, Fx.Closed.lit(12, 96))), Fx.Closed.light(Fx.Closed.idled(36n, Fx.Closed.lit(12, 96))),
    Fx.Closed.light(Fx.Closed.idled(40n, Fx.Closed.lit(12, 96))), Fx.Closed.light(Fx.Closed.idled(41n, Fx.Closed.lit(12, 96))),
    Fx.Closed.light(Fx.Closed.idled(1n, Fx.Closed.lit(12, 160))), Fx.Closed.light(Fx.Closed.idled(36n, Fx.Closed.lit(12, 160))),
    Fx.Closed.light(Fx.Closed.idled(41n, Fx.Closed.lit(12, 160))))
    == (160, 96, 96, 160, 160, 96, 0, 160, 0) : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# LAW: the glow, vanilla's T_Glow, 8 a tic between 160 and the 96 beside
# it: 104 after tic 7; tic 8 would reach 96, so it is undone and the glow
# turns; 112 after tic 9, 152 after tic 14; tic 15 would reach 160, is
# undone and turns it; 144 after tic 16 (sanity).
law glow_turns:
  {(Fx.Closed.light(Fx.Closed.idled(1n, Fx.Closed.lit(8, 96))), Fx.Closed.light(Fx.Closed.idled(7n, Fx.Closed.lit(8, 96))),
    Fx.Closed.light(Fx.Closed.idled(8n, Fx.Closed.lit(8, 96))), Fx.Closed.light(Fx.Closed.idled(9n, Fx.Closed.lit(8, 96))),
    Fx.Closed.light(Fx.Closed.idled(14n, Fx.Closed.lit(8, 96))), Fx.Closed.light(Fx.Closed.idled(15n, Fx.Closed.lit(8, 96))),
    Fx.Closed.light(Fx.Closed.idled(16n, Fx.Closed.lit(8, 96))))
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
  {True{} == S.Sim.line_ok(level, x, y, S.Sim.radius(), 1, i) : Bool}

# LAW: a tic leaves the geometry as it was: the lines, sides, vertices,
# nodes and blockmap that free reads are the same trees after it, for
# all commands and states. The things' links are no part of it: they are
# the population's, and a tic that moves, spawns or removes a mobj
# changes them.
law tic_keeps_geometry:
  for +cmd: K.Cmd
  for +s: S.State
  {L.Level.geo(S.State.level(S.Sim.tic(cmd, s))) == L.Level.geo(S.State.level(s)) : L.Level.Geo}

# LAW: one tic from a free state answers a free state, for all commands
# and states.
law tic_keeps_free:
  for +cmd: K.Cmd
  for +s: S.State
  for free: Fx.Free(s)
  Fx.Free(S.Sim.tic(cmd, s))

# LAW: the wall law: replaying any script from a free state, the start
# included, leaves the player free.
law replay_keeps_free:
  for script: List<&2, K.Cmd>
  for +s: S.State
  for free: Fx.Free(s)
  Fx.Free(S.Sim.replay(script, s))

# LAW: the freedom law, for every mobj: a place passes P_CheckPosition
# only when no mobj near stops the box, whatever is moved, among any
# things, with any player, against any lines (clear_pins_things reads
# that on each mobj near). Every move is tried through this check, as
# the things stand when it is tried: links change as mobjs move, spawn
# and leave, so no law can speak of them a tic later.
law check_is_clear:
  for +level: L.Level
  for +things: H.Things
  for +p: S.Player
  for +m: S.Sim.Body
  for +mask: U32
  for passed: {True{} == S.Sim.Fit.ok(S.Sim.check(level, things, p, m, mask)) : Bool}
  {None{} == S.Sim.blocked(level, things, p, m) : Maybe<&2, U32>}

# LAW: the player's move is taken only where its mobj's box passes the
# check, for all levels, things, players and places.
law move_is_checked:
  for +level: L.Level
  for +things: H.Things
  for +p: S.Player
  for +x: U32
  for +y: U32
  for taken: {True{} == S.Sim.Try.ok(S.Sim.try_move(level, things, p, x, y)) : Bool}
  {True{} == S.Sim.Fit.ok(S.Sim.check(level, things, p,
    S.Sim.Body.at(S.Player.body(p, H.Things.you(things)), x, y), 1)) : Bool}

# LAW: a thing's move is taken only where its box passes the check,
# for all bodies, things, levels and places. The twin of
# move_is_checked for everything that is not the player: the mask is 3,
# since the lines that block monsters stop a thing as well.
law thing_move_is_checked:
  for +m: S.Sim.Body
  for th: H.Thing
  for +id: U32
  for +level: L.Level
  for +x: U32
  for +y: U32
  for +ts: H.Things
  for +p: S.Player
  for s: S.State
  for taken: {True{} == S.Sim.Walk.ok(S.Sim.chase.step.met(m, th, id, level, x, y,
    S.Sim.met(level, ts, p, S.Sim.Body.at(m, x, y)), s)) : Bool}
  {True{} == S.Sim.Fit.ok(S.Sim.check(level, ts, p, S.Sim.Body.at(m, x, y), 3)) : Bool}

# LAW: clear is pinned to the mobjs: when nothing stops a box, every
# mobj linked in the cells around it, whichever position in the list it
# holds, does not stop it (tests/blocking.bend shows the numbers). That the
# links hold every living thing once, in the cell of its centre, rests
# on tests/sim.bend's links checks; that none linked in a further cell
# can reach the box rests on milestone 5's ticket 09's argument, since
# the checker cannot compute the cell arithmetic.
law clear_pins_things:
  for +level: L.Level
  for +things: H.Things
  for +p: S.Player
  for +m: S.Sim.Body
  for k: Nat
  for id: U32
  for listed: {Some{id} == List.get(&2, U32, S.Sim.nearby(level, things, m), k) : Maybe<&2, U32>}
  for clear: {None{} == S.Sim.blocked(level, things, p, m) : Maybe<&2, U32>}
  {False{} == S.Sim.stops.at(things, p, m, id) : Bool}

# Things
# ------

# LAW: a thing in a lasting state, of -1 tics, leaves the state where
# its tic found it, for every thing, every name and every state: Doom's
# P_MobjThinker counts no state of -1 tics down and enters no other.
law lasting_stays:
  for +id: U32
  for +kind: U32
  for +x: U32
  for +y: U32
  for +z: U32
  for s: S.State
  {S.Sim.thing.step(H.Thing.lasting(Fx.Closed.thing(id, kind, x, y, z)),
    H.Thing.over(Fx.Closed.thing(id, kind, x, y, z)), Fx.Closed.thing(id, kind, x, y, z), id, s) == s : S.State}

# Sight
# -----

# LAW: a pair of sectors REJECT rules out never sees, for any two mobjs
# in any level: P_CheckSight answers the lump before it walks the BSP,
# and nothing the walk could find brings the sight back.
law rejected_never_sees:
  for level: L.Level
  for m: S.Sim.Body
  for t: S.Sim.Body
  {S.Sim.sight.between(True{}, level, m, t) == False{} : Bool}

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

# LAW: the loop under every column and span reaches the indices from its
# first, in order, as many as it is asked and no other: the checker
# riding it from i sees each index be the one expected and ends
# expecting n + i, for all n and i. So a column draw, which writes only
# the row its index names, changes no pixel outside its top and bottom
# rows.
law each_in_order:
  for n: Nat
  for +i: Nat
  {D.Draw.each(~Fx.Seq, ~Fx.Seq.see, n, i, Fx.Seq{True{}, i}) == Fx.Seq{True{}, Nat.add(n, i)} : Fx.Seq}

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

# LAW: any callback pushed on the empty heap is its first, and popping
# it empties the heap.
law heap_one:
  for +e: Sg.Song.Entry
  {(Sg.Song.push([], e), Sg.Song.pop(Sg.Song.push([], e))) == ([e], [])
    : List<&2, Sg.Song.Entry> & List<&2, Sg.Song.Entry>}

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

# LAW: the default table has exactly eight slots, and starting a sound
# preserves the size of every table.
law channels_capacity:
  for priority: Nat
  for slots: List<&2, Maybe<&2, Ch.Channel.Voice>>
  {(Ch.Channel.model.size(Ch.Channel.model.start(priority, slots)),
    Ch.Channel.model.size(Ch.Channel.model.none()))
    == (Ch.Channel.model.size(slots), 8n) : Nat & Nat}

# LAW: after any start, its source occurs in at most one slot.
law channels_unique_source:
  for priority: Nat
  for slots: List<&2, Maybe<&2, Ch.Channel.Voice>>
  {True{} == Ch.Channel.model.one(Ch.Channel.model.start(priority, slots), False{}) : Bool}

# LAW: a full table whose sounds are all more important refuses the new
# sound: the shared allocator returns the table size, its drop sentinel.
law channels_priority:
  for priority: Nat
  for slots: List<&2, Maybe<&2, Nat>>
  for protected: {True{} == Ch.Channel.model.protected(priority, slots) : Bool}
  {Ch.Channel.model.size.keys(slots) == Ch.Channel.choice(priority, slots) : Nat}

# LAW: a sound at 16000 or 17990 Hz, the rates of Freedoom's two sounds
# that SDL's converter is not given, has no run, whatever it holds.
law sfx_rates_unserved:
  for count: U32
  for bytes: List<&2, U32>
  {(X.Sfx.run(X.Sound{16000, count, bytes}), X.Sfx.run(X.Sound{17990, count, bytes}))
    == (None{}, None{}) : Maybe<&2, X.Sfx.Run> & Maybe<&2, X.Sfx.Run>}

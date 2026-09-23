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

# LAW: one tic forward from rest at angle zero thrusts 25 * 2048 along
# the facing (51199 along x through the cosine 65535, 19 along y through
# the sine 25) and then decays it by 0.90625: momentum 46399, 17,
# position 0.78125, 0.000290 (the numbers of milestone 2's ticket 08
# hand check). The eye is the rest height plus the bob: the squared
# momentum over four is 9999, and half of it times the clock's sine 25
# is 1 (sanity).
law tic_from_rest:
  {Fx.Closed.room([K.Cmd{25, 0, 0, 0}], S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0)
    == S.Player{51199, 19, 0, 0, 46399, 17, 0, 0, 8388608, 2686976, 0, 2686977, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()} : S.Player}

# LAW: standing still on the floor puts the eye 41 above it, at any
# position, whatever the eye was.
law eye_rest:
  for x: U32
  for y: U32
  {S.Player.viewz(Fx.Closed.room([K.Cmd.idle()], S.Player{x, y, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0))
    == 2686976 : U32}

# LAW: 64 above the floor, the first airborne tic sets the fall to twice
# gravity without moving, the second moves by it and adds gravity once;
# the eye sits 41 above the height the tic began at (sanity).
law fall_gravity:
  {(Fx.Closed.room([K.Cmd.idle()], S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0),
    Fx.Closed.room([K.Cmd.idle(), K.Cmd.idle()], S.Player{0, 0, 4194304, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0))
    == (S.Player{0, 0, 4194304, 0, 0, 0, 4294836224, 0, 8388608, 2686976, 0, 6881280, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()},
      S.Player{0, 0, 4063232, 0, 0, 0, 4294770688, 0, 8388608, 2686976, 0, 6881280, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()})
    : S.Player & S.Player}

# LAW: landing at 9 a tic dips the view by an eighth of it, -1.125;
# landing at 8 a tic does not (sanity).
law landing_dip:
  {(Fx.Closed.room([K.Cmd.idle()], S.Player{0, 0, 65536, 0, 0, 0, 4294377472, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0),
    Fx.Closed.room([K.Cmd.idle()], S.Player{0, 0, 65536, 0, 0, 0, 4294443008, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0))
    == (S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 4294893568, 2752512, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()},
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 2752512, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()})
    : S.Player & S.Player}

# LAW: the bob at the clock's peak (tic 5, sine 65535). The first tic of
# a run from rest has momentum 102398, 39, whose square over four is
# 39998, and half of it bobs the eye by 19998. At 30 a tic the square
# over four is 14745600, capped at 16 units, and half of it bobs the eye
# by 524280, a hair under 8 units (sanity).
law bob_run_and_cap:
  {(S.Player.viewz(Fx.Closed.room([K.Cmd{50, 0, 0, 0}],
      S.Player{0, 0, 0, 0, 0, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 5)),
    S.Player.viewz(Fx.Closed.room([K.Cmd.idle()],
      S.Player{0, 0, 0, 0, 1966080, 0, 0, 0, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 5)))
    == (2706974, 3211256) : U32 & U32}

# LAW: a floor 16 above the player's feet lifts the player onto it, cuts
# the view height by the 16 to 25, and sets it recovering by an eighth
# of the gap, 2 a tic (sanity).
law step_up_dip:
  {Fx.Closed.room([K.Cmd.idle()], S.Player{0, 0, 0, 0, 0, 0, 0, 1048576, 8388608, 2686976, 0, 0, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()}, 0)
    == S.Player{0, 0, 1048576, 0, 0, 0, 0, 1048576, 8388608, 1638400, 131072, 2686976, [], I.Inventory.start(), Fx.Closed.unarmed(), S.Sim.Hurt.start()} : S.Player}

# The pistol's closed laws are p_pspr.c by hand: P_BringUpWeapon starts
# the sprite at WEAPONBOTTOM, 128, and P_SetPsprite runs A_Raise as it
# enters the raise state, row 60, so it starts at 122; each tic's
# A_Raise takes 6 more.

# LAW: the pistol is 38 after 14 tics, and the 15th puts it at the top,
# 32, in the ready state, row 59, where A_WeaponReady with no bob sets
# column 1; the flash shows nothing and is where the weapon is after a
# tic (sanity).
law pistol_rises:
  {(S.Player.psprites(Fx.Closed.armed()),
    S.Player.psprites(Fx.Closed.room(List.replicate(K.Cmd, 14n, K.Cmd.idle()), Fx.Closed.armed(), 0)),
    S.Player.psprites(Fx.Closed.room(List.replicate(K.Cmd, 15n, K.Cmd.idle()), Fx.Closed.armed(), 0)))
    == (S.Psprites{S.Psprite{Some{60}, 1, 0, 7995392}, S.Psprite{None{}, 0, 0, 0}},
      S.Psprites{S.Psprite{Some{60}, 1, 0, 2490368}, S.Psprite{None{}, 0, 0, 2490368}},
      S.Psprites{S.Psprite{Some{59}, 1, 65536, 2097152}, S.Psprite{None{}, 0, 65536, 2097152}})
    : S.Psprites & S.Psprites & S.Psprites}

# LAW: the ready pistol at the bob's lowest, tic 16, a quarter of its
# turn of 64: at 30 a tic the bob is capped at 16 units, 1048576; the
# cosine -25 moves the column by -400 from 65536, and the sine 65535
# lowers the row by 1048560 from 2097152 (sanity).
law pistol_bobs:
  {S.Player.psprites(Fx.Closed.room([K.Cmd.idle()], S.Player{0, 0, 0, 0, 1966080, 0, 0, 0, 8388608, 2686976, 0, 0, [],
      I.Inventory.start(), S.Psprites{S.Psprite{Some{59}, 1, 65536, 2097152}, S.Psprite{None{}, 0, 65536, 2097152}}, S.Sim.Hurt.start()},
      16))
    == S.Psprites{S.Psprite{Some{59}, 1, 65136, 3145712}, S.Psprite{None{}, 0, 65136, 3145712}} : S.Psprites}

# LAW: a shot spends one bullet, and none is spent without one. Held
# from the ready state, A_WeaponReady enters S_PISTOL1 on the first tic,
# its 4 tics run out on tic 5 and A_FirePistol spends a bullet as
# S_PISTOL2 is entered; A_ReFire fires again 14 tics later, on tic 19.
# With an empty clip P_CheckAmmo spends nothing and lowers the weapon.
law pistol_spends:
  {(Fx.Closed.bullets(Fx.Closed.firing(4n, 50)), Fx.Closed.bullets(Fx.Closed.firing(5n, 50)),
    Fx.Closed.bullets(Fx.Closed.firing(19n, 50)), Fx.Closed.bullets(Fx.Closed.firing(19n, 0)),
    Fx.Closed.weapon(Fx.Closed.firing(5n, 0)))
    == (50, 49, 48, 0, Some{69}) : U32 & U32 & U32 & U32 & Maybe<&2, U32>}

# LAW: P_CheckAmmo's preference chooses the pistol when the ready
# shotgun has spent its last shell and bullets remain.
law empty_shotgun_picks_pistol:
  {S.Sim.ammo.pick(Fx.Closed.shotgun.empty()) == 1 : U32}

# The damage laws are p_inter.c's P_DamageMobj by hand.

# LAW: armour absorbs a third of a blow when green and a half when blue,
# rounded down, and the health takes the rest: a blow of 20 costs 14
# health and 6 points of green armour, or 10 and 10 of blue. Armour with
# fewer points than the blow's share gives all it has and loses its
# type, leaving the rest of the blow to the health; no armour absorbs
# nothing.
law armour_absorbs:
  {(Fx.Closed.absorbed(1, 100, 20), Fx.Closed.absorbed(2, 100, 20), Fx.Closed.absorbed(1, 5, 20),
    Fx.Closed.absorbed(2, 0, 20), Fx.Closed.absorbed(0, 0, 20))
    == ((86, 94, 1, 14), (90, 90, 2, 10), (85, 0, 0, 15), (80, 0, 0, 20), (80, 0, 0, 20))
    : (U32 & U32 & U32 & U32) & (U32 & U32 & U32 & U32) & (U32 & U32 & U32 & U32) & (U32 & U32 & U32 & U32)
      & (U32 & U32 & U32 & U32)}

# LAW: the damage count takes what reached the player and stops at 100,
# where a blow past the health leaves none.
law damage_count:
  {(Fx.Closed.blow(20), Fx.Closed.blow(120)) == ((80, 20), (0, 100)) : (U32 & U32) & (U32 & U32)}

# LAW: P_KillMobj picks an extreme death only below the negation of the
# type's spawn health, and only for a type with an extreme-death state.
law gib_threshold:
  {(S.Sim.kill.thing.gibs(4294967236, 3001), S.Sim.kill.thing.gibs(4294967235, 3001),
    S.Sim.kill.thing.gibs(4294966295, 2035)) == (False{}, True{}, False{}) : Bool & Bool & Bool}

# LAW: ST_calcPainOffset steps the face's row by eight at each edge of
# the five pain levels, which C's truncating (100 - health) * 5 / 101
# puts at 80, 60, 40 and 20 health, and health over 100 reads as 100.
law pain_offset:
  {(S.Sim.face.pain(200), S.Sim.face.pain(100), S.Sim.face.pain(80), S.Sim.face.pain(79),
    S.Sim.face.pain(60), S.Sim.face.pain(59), S.Sim.face.pain(40), S.Sim.face.pain(39),
    S.Sim.face.pain(20), S.Sim.face.pain(19), S.Sim.face.pain(0))
    == (0, 0, 0, 8, 8, 16, 16, 24, 24, 32, 32)
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

# LAW: ST_doPaletteStuff's palette at each step's edge, st_stuff.c by
# hand. A count steps the red palette every eight from STARTREDPALS 1,
# by (cnt+7)>>3, and holds at the eighth, so counts 1 to 8 pick 2, 9
# picks 3, and 64 and the capped 100 both pick the last red 8. The
# berserk fade 12 - (strength>>6) stands in for the count while it is
# larger: the tic the pack is taken picks 3, the counter at 256 picks 2,
# at 768 the fade is gone and at 4096 vanilla's int is negative, both
# leaving the count to speak. A pickup flash steps the gold palette the
# same way from STARTBONUSPALS 9, so 1 to 8 pick 10, 9 picks 11, and 25
# holds at the last gold 12; a flash under a count picks no gold.
law damage_palette:
  {(Fx.Closed.palette(0, 0, 0), Fx.Closed.palette(1, 0, 0), Fx.Closed.palette(8, 0, 0), Fx.Closed.palette(9, 0, 0),
    Fx.Closed.palette(64, 0, 0), Fx.Closed.palette(100, 0, 0), Fx.Closed.palette(0, 0, 1), Fx.Closed.palette(0, 0, 6),
    Fx.Closed.palette(0, 0, 8), Fx.Closed.palette(0, 0, 9), Fx.Closed.palette(0, 0, 25), Fx.Closed.palette(0, 1, 0),
    Fx.Closed.palette(0, 256, 0), Fx.Closed.palette(0, 768, 0), Fx.Closed.palette(0, 4096, 0),
    Fx.Closed.palette(100, 1, 0), Fx.Closed.palette(0, 768, 6))
    == (0, 2, 2, 3, 8, 8, 10, 10, 10, 11, 12, 3, 2, 0, 0, 8, 10)
    : U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32 & U32}

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
  {(Fx.Closed.met(Fx.Closed.barrel()), Fx.Closed.reach(Fx.Closed.barrel()))
    == ([S.Meet{32768, True{}, 0}, S.Meet{40960, False{}, 0}, S.Meet{49152, True{}, 1}], S.Special{0})
    : List<&2, S.Sim.Meet> & S.Sim.Reach}

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

# LAW: vanilla's random table, its first entries and its last, and the
# index wrapping at 256 (sanity).
law random_table:
  {(M.Random.at(0), M.Random.at(1), M.Random.at(2), M.Random.at(3), M.Random.at(255),
    M.Random.next(0), M.Random.next(255))
    == (0, 8, 109, 220, 249, 1, 0) : U32 & U32 & U32 & U32 & U32 & U32 & U32}

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

# Pickups and keys
# ----------------

# LAW: the blue locked door, vanilla's EV_VerticalDoor for special 26.
# Used on tic 1 with no card, or with the yellow card alone, it stays
# shut; with the blue card or the blue skull it is the manual door, 2
# up after that tic (sanity).
law blue_door_locked:
  {(Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.start())), 1),
    Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.card(2, Msg.Message.none(), I.Inventory.start()))), 1),
    Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.card(1, Msg.Message.none(), I.Inventory.start()))), 1),
    Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.card(8, Msg.Message.none(), I.Inventory.start()))), 1))
    == (0, 0, 131072, 131072) : U32 & U32 & U32 & U32}

# The pickup laws' expected values are p_inter.c's P_TouchSpecialThing,
# P_GiveCard, P_GiveBody, P_GiveArmor, P_GivePower, P_GiveAmmo and
# P_GiveWeapon, d_items.c's clips and p_user.c's P_PlayerThink in
# Chocolate Doom 3.1.1, by hand.

# LAW: P_TouchSpecialThing for the blue card. Tic 1 moves the player to
# 72, 40 short of the card, and the reach is its radius 20 and the
# player's 16. Friction leaves 7.25 a tic, so tic 2 moves it to 79.25,
# 32.75 short: record 87 is gone and no other, the blue card is held,
# and P_GiveCard's 6 and the pickup's 6 set the flash to 12. On tic 3,
# still in reach of where it was, nothing is touched again and the
# flash fades to 11 (sanity).
law key_taken:
  {[Fx.Closed.kept(Fx.Closed.idled(1n, Fx.Closed.passing())), Fx.Closed.kept(Fx.Closed.idled(2n, Fx.Closed.passing())),
    Fx.Closed.kept(Fx.Closed.idled(3n, Fx.Closed.passing()))]
    == [Fx.Got{[3, 87, 90], I.Inventory.start()}, Fx.Got{[3, 90], Fx.Closed.inv([Fx.Cards{1}, Fx.Flash{12}])},
      Fx.Got{[3, 90], Fx.Closed.inv([Fx.Cards{1}, Fx.Flash{11}])}] : List<&2, Fx.Closed.Got>}

# LAW: a move of 20 a tic is tried in halves, to 74 and then 84, and a
# blue card at (32, 100) is in reach of both: the first takes it, the
# second finds it gone, so the flash is 12 and not 18 (sanity).
law key_taken_once:
  {Fx.Closed.kept(Fx.Closed.idled(1n, Fx.Closed.among(I.Inventory.start(), 2097152, 0, 1310720,
    [Fx.Closed.thing(87, 5, 2097152, 6553600, 0)])))
    == Fx.Got{[], Fx.Closed.inv([Fx.Cards{1}, Fx.Flash{12}])} : Fx.Closed.Got}

# LAW: vertical reach. A tic moves the player to 72, 8 from a blue card
# at (32, 80); the card is taken with its bottom 56 over the player's
# feet and not 57, and 8 under them and not 9 (sanity).
law key_reach:
  {[Fx.Closed.key_at(3670016), Fx.Closed.key_at(3735552), Fx.Closed.key_at(4294443008), Fx.Closed.key_at(4294377472)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Cards{1}, Fx.Flash{12}])}, Fx.Got{[87], I.Inventory.start()},
      Fx.Got{[], Fx.Closed.inv([Fx.Cards{1}, Fx.Flash{12}])}, Fx.Got{[87], I.Inventory.start()}] : List<&2, Fx.Closed.Got>}

# LAW: P_CheckPosition touches things before it checks lines. The move
# to 52 puts the box across the shut door, whose opening refuses it,
# but its position check has already taken the card, 34 away; the
# slide that follows stops the player short of the door, at most 48,
# from where the card is out of reach (sanity).
law key_through_door:
  {(Fx.Closed.kept(Fx.Closed.shut_out()), F.Fixed.le(S.Player.x(S.State.player(Fx.Closed.shut_out())), 3145728))
    == (Fx.Got{[], Fx.Closed.inv([Fx.Cards{1}, Fx.Flash{12}])}, True{}) : Fx.Closed.Got & Bool}

# LAW: the health bonus is always taken and counted. From 100 it makes
# 101, from 199 200, and at 200 it adds nothing and still goes; the
# flash is 6 (sanity).
law health_bonus:
  {[Fx.Closed.offer(I.Inventory.start(), 2014), Fx.Closed.offer(Fx.Closed.inv([Fx.Health{199}]), 2014),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Health{200}]), 2014)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Health{101}, Fx.Items{1}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Health{200}, Fx.Items{1}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Health{200}, Fx.Items{1}, Fx.Flash{6}])}] : List<&2, Fx.Closed.Got>}

# LAW: the stimpack heals 10 up to 100 and is not counted: 89 makes 99,
# 99 makes 100, and at 100 it stays, the inventory untouched (sanity).
law stimpack:
  {[Fx.Closed.offer(Fx.Closed.inv([Fx.Health{89}]), 2011), Fx.Closed.offer(Fx.Closed.inv([Fx.Health{99}]), 2011),
    Fx.Closed.offer(I.Inventory.start(), 2011)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Health{99}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Health{100}, Fx.Flash{6}])},
      Fx.Got{[1], I.Inventory.start()}] : List<&2, Fx.Closed.Got>}

# LAW: the medikit heals 25 up to 100 and is not counted: 74 makes 99,
# 75 and 99 make 100, and at 100, or at 150 from bonuses, it stays
# (sanity).
law medikit:
  {[Fx.Closed.offer(Fx.Closed.inv([Fx.Health{74}]), 2012), Fx.Closed.offer(Fx.Closed.inv([Fx.Health{75}]), 2012),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Health{99}]), 2012), Fx.Closed.offer(I.Inventory.start(), 2012),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Health{150}]), 2012)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Health{99}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Health{100}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Health{100}, Fx.Flash{6}])}, Fx.Got{[1], I.Inventory.start()},
      Fx.Got{[1], Fx.Closed.inv([Fx.Health{150}])}] : List<&2, Fx.Closed.Got>}

# LAW: the soul sphere adds 100 up to 200 and is always taken and
# counted: 99 makes 199, 100 and 101 make 200, and 200 stays 200
# (sanity).
law soul_sphere:
  {[Fx.Closed.offer(Fx.Closed.inv([Fx.Health{99}]), 2013), Fx.Closed.offer(I.Inventory.start(), 2013),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Health{101}]), 2013), Fx.Closed.offer(Fx.Closed.inv([Fx.Health{200}]), 2013)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Health{199}, Fx.Items{1}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Health{200}, Fx.Items{1}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Health{200}, Fx.Items{1}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Health{200}, Fx.Items{1}, Fx.Flash{6}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: the berserk pack is always taken and counted, and sets the
# strength counter to 1, even over one already running at 40. It heals
# 1 to 100, leaves 100 at 100, and does not lower 150 (sanity).
law berserk:
  {[Fx.Closed.offer(Fx.Closed.inv([Fx.Health{1}]), 2023), Fx.Closed.offer(I.Inventory.start(), 2023),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Health{150}]), 2023), Fx.Closed.offer(Fx.Closed.inv([Fx.Strength{40}]), 2023)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Strength{1}, Fx.Items{1}, Fx.Flash{6}, Fx.Selection{1, 0}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Strength{1}, Fx.Items{1}, Fx.Flash{6}, Fx.Selection{1, 0}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Health{150}, Fx.Strength{1}, Fx.Items{1}, Fx.Flash{6}, Fx.Selection{1, 0}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Strength{1}, Fx.Items{1}, Fx.Flash{6}, Fx.Selection{1, 0}])}] : List<&2, Fx.Closed.Got>}

# LAW: the armour bonus is always taken and counted: no armour makes 1
# point of green armour's type, 199 points of blue make 200 and stay
# blue, and 200 points of green take nothing more (sanity).
law armour_bonus:
  {[Fx.Closed.offer(I.Inventory.start(), 2015), Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{199, 2}]), 2015),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{200, 1}]), 2015)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Armour{1, 1}, Fx.Items{1}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Armour{200, 2}, Fx.Items{1}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Armour{200, 1}, Fx.Items{1}, Fx.Flash{6}])}] : List<&2, Fx.Closed.Got>}

# LAW: green armour gives 100 points of type 1 over fewer points of any
# type, blue's 99 among them, and is not counted; with 100 points of
# green, or 150 of blue, it stays (sanity).
law green_armour:
  {[Fx.Closed.offer(I.Inventory.start(), 2018), Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{99, 2}]), 2018),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{100, 1}]), 2018), Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{150, 2}]), 2018)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Armour{100, 1}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Armour{100, 1}, Fx.Flash{6}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Armour{100, 1}])}, Fx.Got{[1], Fx.Closed.inv([Fx.Armour{150, 2}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: blue armour gives 200 points of type 2 over fewer, 199 among
# them, and is not counted; with 200 points of either type it stays
# (sanity).
law blue_armour:
  {[Fx.Closed.offer(I.Inventory.start(), 2019), Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{199, 1}]), 2019),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{200, 1}]), 2019), Fx.Closed.offer(Fx.Closed.inv([Fx.Armour{200, 2}]), 2019)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Armour{200, 2}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Armour{200, 2}, Fx.Flash{6}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Armour{200, 1}])}, Fx.Got{[1], Fx.Closed.inv([Fx.Armour{200, 2}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: a move of 20 a tic is tried in halves, to 74 and then 84, and a
# health bonus at (32, 80) is in reach of both: the first takes it and
# the second finds it gone, so health is 101, the tally 1 and the flash
# 6, not 102, 2 and 12 (sanity).
law bonus_counted_once:
  {Fx.Closed.walk(1n, 1310720, I.Inventory.start(), 2014)
    == Fx.Got{[], Fx.Closed.inv([Fx.Health{101}, Fx.Items{1}, Fx.Flash{6}])} : Fx.Closed.Got}

# LAW: P_PlayerThink counts strength up a tic before it counts the flash
# down, and both before the mobj moves: a berserk pack taken on the
# first tic leaves the counter at 1 and the flash at 6; the next two
# tics make 2 and 5, then 3 and 4 (sanity).
law strength_counts:
  {[Fx.Closed.walk(1n, 524288, I.Inventory.start(), 2023), Fx.Closed.walk(2n, 524288, I.Inventory.start(), 2023),
    Fx.Closed.walk(3n, 524288, I.Inventory.start(), 2023)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Strength{1}, Fx.Items{1}, Fx.Flash{6}, Fx.Selection{1, 0}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Strength{2}, Fx.Items{1}, Fx.Flash{5}, Fx.Selection{1, 0}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Strength{3}, Fx.Items{1}, Fx.Flash{4}, Fx.Selection{1, 0}])}] : List<&2, Fx.Closed.Got>}

# LAW: P_GiveAmmo's clipammo on Hurt Me Plenty, which doubles nothing,
# from G_PlayerReborn's inventory: a clip gives 10 bullets, shells 4, a
# cell 20, a rocket 1; the boxes give five clips, 50 bullets, 20 shells,
# 100 cells and 5 rockets. Each is taken, and flashes 6 (sanity).
law ammo_amounts:
  {[Fx.Closed.offer(I.Inventory.start(), 2007), Fx.Closed.offer(I.Inventory.start(), 2008),
    Fx.Closed.offer(I.Inventory.start(), 2047), Fx.Closed.offer(I.Inventory.start(), 2010),
    Fx.Closed.offer(I.Inventory.start(), 2048), Fx.Closed.offer(I.Inventory.start(), 2049),
    Fx.Closed.offer(I.Inventory.start(), 17), Fx.Closed.offer(I.Inventory.start(), 2046)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[60, 0, 0, 0]}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 4, 0, 0]}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 0, 20, 0]}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 0, 0, 1]}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[100, 0, 0, 0]}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 20, 0, 0]}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 0, 100, 0]}, Fx.Flash{6}])}, Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 0, 0, 5]}, Fx.Flash{6}])}]
    : List<&2, Fx.Closed.Got>}

# P_TouchSpecialThing gives a dropped clip half a load (5 bullets).
# P_GiveWeapon gives a dropped shotgun one load (4 shells), versus two
# for a placed shotgun. G_PlayerReborn starts with 50 bullets.
law dropped_ammo:
  {[I.Inventory.rounds(I.Inventory.am_clip(), Fx.Closed.granted(2007, True{})),
    I.Inventory.rounds(I.Inventory.am_shell(), Fx.Closed.granted(2001, True{})),
    I.Inventory.rounds(I.Inventory.am_clip(), Fx.Closed.granted(2007, False{})),
    I.Inventory.rounds(I.Inventory.am_shell(), Fx.Closed.granted(2001, False{}))]
    == [55, 4, 60, 8] : List<&2, U32>}

# LAW: maxammo's caps, 200 bullets, 50 shells, 300 cells and 50 rockets.
# At each, the loose round and the box are refused, stay, and change
# nothing; one short of each, the box is taken and fills it to the cap
# (sanity).
law ammo_caps:
  {[Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2007),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2048),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2008),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2049),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2047),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 17),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2010),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 2046),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[199, 49, 299, 49]}]), 2048),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[199, 49, 299, 49]}]), 2049),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[199, 49, 299, 49]}]), 17),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[199, 49, 299, 49]}]), 2046)]
    == [Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[200, 49, 299, 49]}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[199, 50, 299, 49]}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[199, 49, 300, 49]}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[199, 49, 299, 50]}, Fx.Flash{6}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: the first backpack doubles every cap, to 400 100 600 100, before
# it gives a clip of each ammo type: from the start 60 4 20 1, and from
# ammo at the old caps 210 54 320 51. Either way it is taken (sanity).
law backpack_first:
  {[Fx.Closed.offer(I.Inventory.start(), 8), Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 50, 300, 50]}]), 8)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[60, 4, 20, 1]}, Fx.Backpack{}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[210, 54, 320, 51]}, Fx.Backpack{}, Fx.Flash{6}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: a later backpack leaves the doubled caps as they are and gives the
# clips again, 60 4 20 1 to 70 8 40 2; at the doubled caps it gives
# nothing, and it is still taken (sanity).
law backpack_later:
  {[Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[60, 4, 20, 1]}, Fx.Backpack{}]), 8),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[400, 100, 600, 100]}, Fx.Backpack{}]), 8)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[70, 8, 40, 2]}, Fx.Backpack{}, Fx.Flash{6}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[400, 100, 600, 100]}, Fx.Backpack{}, Fx.Flash{6}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: P_GiveWeapon for a weapon found, which brings two clips. The
# shotgun, not owned, is owned (weapons 3 to 7) with 8 shells; owned, its
# 8 shells alone take it; owned at 50 shells it stays; not owned at 50
# shells the weapon alone takes it. The chaingun brings 20 bullets and
# stays when owned at 200, the rocket launcher 2 rockets, the plasma
# rifle 40 cells. The chainsaw has no ammo: taken when not owned, left
# when owned (sanity). Newly owned weapons become pending; ready stays pistol.
law weapon_taken:
  {[Fx.Closed.offer(I.Inventory.start(), 2001),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[50, 8, 0, 0]}, Fx.Weapons{7}]), 2001),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[50, 50, 0, 0]}, Fx.Weapons{7}]), 2001),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[50, 50, 0, 0]}]), 2001),
    Fx.Closed.offer(I.Inventory.start(), 2002),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Ammo{[200, 0, 0, 0]}, Fx.Weapons{11}]), 2002),
    Fx.Closed.offer(I.Inventory.start(), 2003), Fx.Closed.offer(I.Inventory.start(), 2004),
    Fx.Closed.offer(I.Inventory.start(), 2005),
    Fx.Closed.offer(Fx.Closed.inv([Fx.Weapons{131}]), 2005)]
    == [Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 8, 0, 0]}, Fx.Weapons{7}, Fx.Flash{6}, Fx.Selection{1, 2}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 16, 0, 0]}, Fx.Weapons{7}, Fx.Flash{6}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[50, 50, 0, 0]}, Fx.Weapons{7}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 50, 0, 0]}, Fx.Weapons{7}, Fx.Flash{6}, Fx.Selection{1, 2}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[70, 0, 0, 0]}, Fx.Weapons{11}, Fx.Flash{6}, Fx.Selection{1, 3}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Ammo{[200, 0, 0, 0]}, Fx.Weapons{11}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 0, 0, 2]}, Fx.Weapons{19}, Fx.Flash{6}, Fx.Selection{1, 4}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Ammo{[50, 0, 40, 0]}, Fx.Weapons{35}, Fx.Flash{6}, Fx.Selection{1, 5}])},
      Fx.Got{[], Fx.Closed.inv([Fx.Weapons{131}, Fx.Flash{6}, Fx.Selection{1, 7}])},
      Fx.Got{[1], Fx.Closed.inv([Fx.Weapons{131}])}]
    : List<&2, Fx.Closed.Got>}

# LAW: the heads-up line. d_englsh.h's string for each pickup type the
# two E1M1s hold, PD_BLUEK for the blue door that refuses, and
# hu_stuff.c's four seconds. A pickup takes the line on its own tic with
# HU_MSGTIMEOUT tics left; a pickup the grant refuses says nothing and
# leaves the line as it was; the counter falls by one a tic and the line
# goes out at zero.
law pickup_messages:
  {[Fx.Closed.said(I.Inventory.start(), 2014), Fx.Closed.said(Fx.Closed.inv([Fx.Health{99}]), 2011),
    Fx.Closed.said(Fx.Closed.inv([Fx.Health{99}]), 2012), Fx.Closed.said(I.Inventory.start(), 2018),
    Fx.Closed.said(I.Inventory.start(), 2019), Fx.Closed.said(I.Inventory.start(), 5),
    Fx.Closed.said(I.Inventory.start(), 2005), Fx.Closed.said(I.Inventory.start(), 2023),
    Fx.Closed.said(I.Inventory.start(), 2011), Fx.Closed.said(Fx.Closed.inv([Fx.Armour{150, 2}]), 2018),
    Fx.Closed.said(Fx.Closed.inv([Fx.Said{3, 90}]), 2011),
    Fx.Closed.ticked(1n, Fx.Closed.inv([Fx.Said{3, 2}])), Fx.Closed.ticked(2n, Fx.Closed.inv([Fx.Said{3, 2}])),
    Fx.Closed.ticked(3n, Fx.Closed.inv([Fx.Said{3, 2}])),
    Fx.Closed.line(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.start()))),
    Fx.Closed.line(Fx.Closed.used(0n, Fx.Closed.locked(I.Inventory.card(1, Msg.Message.none(), I.Inventory.start()))))]
    == [Fx.Shown{3, 140}, Fx.Shown{5, 140}, Fx.Shown{6, 140}, Fx.Shown{1, 140}, Fx.Shown{2, 140}, Fx.Shown{7, 140}, Fx.Shown{15, 140},
      Fx.Shown{8, 140}, Fx.Shown{0, 0}, Fx.Shown{0, 0}, Fx.Shown{3, 89}, Fx.Shown{3, 1}, Fx.Shown{3, 0}, Fx.Shown{3, 0}, Fx.Shown{17, 140},
      Fx.Shown{0, 0}]
    : List<&2, Fx.Closed.Line>}

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
# holds, does not stop it (blocker_geometry shows the numbers). That the
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

# LAW: no type Bendoom spawns is wider than Doom's MAXRADIUS, 32, which
# the thing check widens its box by (sanity).
law radius_within:
  {List.all(~&2, ~H.Thing.Def, ~Fx.Closed.within, H.Thing.defs()) == True{} : Bool}

# LAW: no type Bendoom spawns is both solid and special, info.c's flags
# 2 and 1, so no pickup takes a solid thing away: only a grant removes a
# thing, and only a special thing is offered one (sanity).
law solid_stays:
  {List.all(~&2, ~H.Thing.Def, ~Fx.Closed.lasting, H.Thing.defs()) == True{} : Bool}

# LAW: every type the tally counts as a kill, info.c's flag 4194304, is
# solid and shootable, so a monster stops the player as the solid things
# of clear_pins_things do and a mover as the barrel of barrel_stops_door
# does (sanity).
law monsters_block:
  {List.all(~&2, ~H.Thing.Def, ~Fx.Closed.blocks, H.Thing.defs()) == True{} : Bool}

# LAW: every type's spawn state is a row of the table, and every row's
# next state is a row of it or S_NULL, which removes the thing or stops
# the sprite showing, so nothing enters the empty row Thing.row gives
# past its end (sanity).
law states_exist:
  {Bool.and(List.all(~&2, ~H.Thing.Row, ~Fx.Closed.leads, H.Thing.rows()),
    List.all(~&2, ~H.Thing.Def, ~Fx.Closed.spawns, H.Thing.defs())) == True{} : Bool}

# Solid things
# ------------

# LAW: vanilla's PIT_CheckThing on numbers. The lamp stops the player's
# box when their centres are under 32 apart, 16 and 16: at 32 it does
# not, 1/65536 closer it does, and it never stops its own. The corpse is
# not solid, so it stops nothing even where it stands. The barrel's
# reach is 26. The player's mobj stops a barrel's box under 26 away and
# not at 26. A missile, flag 65536, of radius 6 and height 8 is tested
# against heights: on the barrel's top at 42 it has hit the barrel,
# 1/65536 higher it passes over; under the raised barrel its top at 99
# passes and at 100 has hit; the lamp, not shootable, stops it as a
# solid thing does, and the corpse does not. The cell lists the mobjs
# the last linked first, less the raised barrel, which at x 160 is off
# the one cell's blockmap and so in no cell (sanity).
law blocker_geometry:
  {(Fx.Closed.stops(8, 2097152, 5242880, 0, 1048576, 3670016, 33557510, 4294967295),
    Fx.Closed.stops(8, 2097152, 5242881, 0, 1048576, 3670016, 33557510, 4294967295),
    Fx.Closed.stops(8, 2097152, 5242881, 0, 1048576, 1048576, 2, 8),
    Fx.Closed.stops(15, 2097152, 2097152, 0, 1048576, 3670016, 33557510, 4294967295),
    Fx.Closed.stops(24, 4587520, 7340032, 0, 1048576, 3670016, 33557510, 4294967295),
    Fx.Closed.stops(24, 4587521, 7340032, 0, 1048576, 3670016, 33557510, 4294967295),
    Fx.Closed.stops(4294967295, 3801087, 4194304, 0, 655360, 2752512, 524294, 24),
    Fx.Closed.stops(4294967295, 3801088, 4194304, 0, 655360, 2752512, 524294, 24),
    Fx.Closed.stops(24, 6291456, 7340032, 2752512, 393216, 524288, 65536, 200),
    Fx.Closed.stops(24, 6291456, 7340032, 2752513, 393216, 524288, 65536, 200),
    Fx.Closed.stops(30, 10485760, 7340032, 5963776, 393216, 524288, 65536, 200),
    Fx.Closed.stops(30, 10485760, 7340032, 6029312, 393216, 524288, 65536, 200),
    Fx.Closed.stops(8, 2097152, 7340032, 0, 393216, 524288, 65536, 200),
    Fx.Closed.stops(15, 2097152, 2097152, 0, 393216, 524288, 65536, 200),
    S.Sim.near(Fx.Closed.doors(), S.State.things(Fx.Closed.linked()), 2097152, 4194304, 1048576))
    == (False{}, True{}, False{}, False{}, False{}, True{}, True{}, False{}, True{}, False{}, False{}, True{}, True{},
      False{}, [4294967295, 24, 15, 8])
    : Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & Bool & List<&2, U32>}

# LAW: the links' order, vanilla's P_SetThingPosition: a mobj goes first
# in its cell's list when it spawns and when it moves. The player's mobj
# spawns at its record's turn, so as record 6 it is listed after record
# 9 and before 5 and 2, and as record 1 last; once it has moved it is
# first; at (200, 64), off the blockmap, no cell lists it. The thinkers
# are started in the same order (sanity).
law link_order:
  {(Fx.Closed.cell(Fx.Closed.ranked(6, 2097152, 0)), Fx.Closed.cell(Fx.Closed.idled(1n, Fx.Closed.ranked(6, 2097152, 65536))),
    Fx.Closed.cell(Fx.Closed.ranked(1, 2097152, 0)), Fx.Closed.cell(Fx.Closed.ranked(6, 13107200, 0)),
    S.State.thinkers(Fx.Closed.ranked(6, 2097152, 0)))
    == ([9, 6, 5, 2], [6, 9, 5, 2], [9, 5, 2, 1], [9, 5, 2], [S.Mobj{2}, S.Mobj{5}, S.Mobj{6}, S.Mobj{9}])
    : List<&2, U32> & List<&2, U32> & List<&2, U32> & List<&2, U32> & List<&2, S.Thinker>}

# LAW: a mobj spawned while the thinkers run joins the tail of the list
# and thinks in that same run, as one P_AddThinker appends to the tail of
# Doom's list does. The bonus takes the id past the 128 records, draws
# one random number (the index goes 0 to 1) and stands in S_BON1 for its
# 6 tics; the rest of the run reaches it and leaves 5. The thinkers are
# the player's mobj's and then the bonus's (sanity).
law spawn_thinks_this_tic:
  {(Fx.Closed.tics(H.Things.get(S.State.things(Fx.Closed.spawned()), 128)), S.State.rnd(Fx.Closed.spawned()),
    Fx.Closed.tics(H.Things.get(S.State.things(Fx.Closed.spawned.ran()), 128)), S.State.thinkers(Fx.Closed.spawned.ran()))
    == (Some{6}, 1, Some{5}, [S.Mobj{H.Thing.you()}, S.Mobj{128}])
    : Maybe<&2, U32> & U32 & Maybe<&2, U32> & List<&2, S.Thinker>}

# LAW: a solid thing stops the player and a corpse does not. Moving north
# at 8 a tic from (32, 64), friction leaves 7.25 and then 6.57: tic 2
# ends at 79.25, 32.75 short of a lamp at (32, 112), and tic 3's move to
# 85.82 would overlap it. The slide finds no line and stairsteps; its
# move north overlaps too, its move by the momentum east is no move, so
# the player stays at 79.25. Doom's things are as tall as the map: the
# lamp raised 100 units stops it all the same. Over a dead player at the
# same place tic 3 reaches 85.82 (sanity).
law thing_blocks:
  {(Fx.Closed.north([Fx.Closed.thing(8, 2028, 2097152, 7340032, 0)], 2n),
    Fx.Closed.north([Fx.Closed.thing(8, 2028, 2097152, 7340032, 0)], 3n),
    Fx.Closed.north([Fx.Closed.thing(8, 2028, 2097152, 7340032, 6553600)], 3n),
    Fx.Closed.north([Fx.Closed.thing(15, 15, 2097152, 7340032, 0)], 3n))
    == (5193728, 5193728, 5193728, 5624320) : U32 & U32 & U32 & U32}

# LAW: a moving floor carries the things on it, vanilla's
# P_ThingHeightClip through P_ChangeSector. The west room's floor goes
# down 4 a tic; the player at (200, 64) is out of its block box. The
# barrel standing at (32, 16) follows the floor, -4 after a tic and -8
# after two, its name, type, state and tics as they were. A leg hung 68
# under the ceiling at 128 stays at 60, over its floor at -4 (sanity).
law floor_carries_things:
  {(Fx.Closed.lowering(1n), Fx.Closed.lowering(2n))
    == ([H.Thing{24, 2035, 2097152, 1048576, 4294705152, 4294705152, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(2035)},
        H.Thing{29, 60, 2097152, 6553600, 3932160, 4294705152, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(60)}],
      [H.Thing{24, 2035, 2097152, 1048576, 4294443008, 4294443008, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(2035)},
        H.Thing{29, 60, 2097152, 6553600, 3932160, 4294443008, 8388608, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(60)}])
    : List<&2, H.Thing> & List<&2, H.Thing>}

# LAW: a door closing on a barrel goes back up, vanilla's
# PIT_ChangeSector for a shootable thing that no longer fits, and no
# damage is done. The barrel at (72, 16) stands across both of the
# door's faces, so its ceiling is the door's: 42 after 13 tics, which
# fits its height of 42; the 14th would leave 40, so the step is undone,
# the barrel clipped again under 42, and the door back on its plan; 44
# after the 15th (sanity).
law barrel_stops_door:
  {(Fx.Closed.ceil(Fx.Closed.idled(13n, Fx.Closed.closing(Fx.Closed.thing(24, 2035, 4718592, 1048576, 0))), 1),
    Fx.Closed.ceil(Fx.Closed.idled(14n, Fx.Closed.closing(Fx.Closed.thing(24, 2035, 4718592, 1048576, 0))), 1),
    Fx.Closed.running(Fx.Closed.idled(14n, Fx.Closed.closing(Fx.Closed.thing(24, 2035, 4718592, 1048576, 0)))),
    Fx.Closed.things(Fx.Closed.idled(14n, Fx.Closed.closing(Fx.Closed.thing(24, 2035, 4718592, 1048576, 0)))),
    Fx.Closed.ceil(Fx.Closed.idled(15n, Fx.Closed.closing(Fx.Closed.thing(24, 2035, 4718592, 1048576, 0))), 1))
    == (2752512, 2752512,
      [S.Mover{1, True{}, 131072, [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}],
        [S.Travel{False{}, 4456448}, S.Hold{150}, S.Travel{True{}, 0}], S.Sim.noise.door()}],
      [H.Thing{24, 2035, 4718592, 1048576, 0, 0, 2752512, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(2035)}], 2883584)
    : U32 & U32 & List<&2, S.Thinker> & List<&2, H.Thing> & U32}

# LAW: a lamp is solid but not shootable, and vanilla's PIT_ChangeSector
# passes over it: the door closes on the lamp at (72, 16) as on nothing,
# shut after 34 tics, its thinker ended on the 35th, the lamp still on
# its floor under a ceiling at 0 (sanity).
law lamp_under_door:
  {(Fx.Closed.ceil(Fx.Closed.idled(34n, Fx.Closed.closing(Fx.Closed.thing(8, 2028, 4718592, 1048576, 0))), 1),
    Fx.Closed.running(Fx.Closed.idled(35n, Fx.Closed.closing(Fx.Closed.thing(8, 2028, 4718592, 1048576, 0)))),
    Fx.Closed.things(Fx.Closed.idled(35n, Fx.Closed.closing(Fx.Closed.thing(8, 2028, 4718592, 1048576, 0)))))
    == (0, [], [H.Thing{8, 2028, 4718592, 1048576, 0, 0, 0, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(2028)}])
    : U32 & List<&2, S.Thinker> & List<&2, H.Thing>}

# LAW: vanilla's T_MovePlane lets a ceiling rise short of its
# destination whatever it leaves unfit. A barrel at (72, 100) across the
# shut door does not fit under it, yet the door used on tic 1 is 2 up
# after it and 4 after the second, the barrel's ceiling rising with it
# (sanity).
law door_opens_over_barrel:
  {(Fx.Closed.ceil(Fx.Closed.used(0n, Fx.Closed.over_barrel()), 1), Fx.Closed.things(Fx.Closed.used(1n, Fx.Closed.over_barrel())))
    == (131072, [H.Thing{24, 2035, 4718592, 6553600, 0, 0, 262144, 0, 0, 0, 4294967295, 0, H.Thing.Hurt.of(2035)}]) : U32 & List<&2, H.Thing>}

# Things
# ------

# LAW: the spawn's phase, vanilla's P_SpawnMapThing. The player draws
# the random table's entry 1. The bonus draws entry 2 for P_SpawnMobj,
# then entry 3, 220, for its first state's tics: 1 + 220 mod 6 = 5. The
# armour draws entry 4, then entry 5, 241: 1 + 241 mod 6 = 2. The index
# is 5. P_SpawnMobj's own draw is each one's lastlook, the entry modulo
# MAXPLAYERS: 109 mod 4 = 1 for the bonus and 222 mod 4 = 2 for the
# armour (sanity).
law spawn_phase:
  {(Fx.Closed.things(Fx.Closed.stocked()), S.State.rnd(Fx.Closed.stocked()))
    == ([Fx.Closed.bonus(12, 5), Fx.Closed.armour(6, 2)], 5)
    : List<&2, H.Thing> & U32}

# LAW: one complete cycle of the bonus, vanilla's P_MobjThinker. Its 5
# tics are down to 1 after tic 4; tic 5 enters S_BON1A for 6; tics 11,
# 17, 23 and 29 enter the next four states, and tic 35 is back in S_BON1
# for 6. The armour enters S_ARM1A for 7 on tic 2, S_ARM1 for 6 on tic
# 9, and so on each 13 tics. No thing draws a random number, and the
# clock counts 35 (sanity).
law bonus_cycle:
  {(Fx.Closed.things(Fx.Closed.idled(4n, Fx.Closed.stocked())), Fx.Closed.things(Fx.Closed.idled(5n, Fx.Closed.stocked())),
    Fx.Closed.things(Fx.Closed.idled(11n, Fx.Closed.stocked())), Fx.Closed.things(Fx.Closed.idled(17n, Fx.Closed.stocked())),
    Fx.Closed.things(Fx.Closed.idled(23n, Fx.Closed.stocked())), Fx.Closed.things(Fx.Closed.idled(29n, Fx.Closed.stocked())),
    Fx.Closed.things(Fx.Closed.idled(35n, Fx.Closed.stocked())), S.State.rnd(Fx.Closed.idled(35n, Fx.Closed.stocked())),
    S.State.clock(Fx.Closed.idled(35n, Fx.Closed.stocked())))
    == ([Fx.Closed.bonus(12, 1), Fx.Closed.armour(7, 5)],
      [Fx.Closed.bonus(13, 6), Fx.Closed.armour(7, 4)],
      [Fx.Closed.bonus(14, 6), Fx.Closed.armour(6, 4)],
      [Fx.Closed.bonus(15, 6), Fx.Closed.armour(7, 5)],
      [Fx.Closed.bonus(16, 6), Fx.Closed.armour(6, 5)],
      [Fx.Closed.bonus(17, 6), Fx.Closed.armour(7, 6)],
      [Fx.Closed.bonus(12, 6), Fx.Closed.armour(6, 6)], 5, 35)
    : List<&2, H.Thing> & List<&2, H.Thing> & List<&2, H.Thing> & List<&2, H.Thing> & List<&2, H.Thing>
      & List<&2, H.Thing> & List<&2, H.Thing> & U32 & U32}

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

# LAW: P_DivlineSide's three answers. A line up the y axis through
# x 64 has a point at x 64 on it, one west of it behind it and one east
# of it in front. A line east along y 64 from x 0 answers on for the
# point (64, 32), because vanilla compares the point's x with the line's
# y where it means its y; (0, 32) is south of it and in front, and
# (0, 96) north of it and behind. A line out along (1, 1) from the
# origin has (1, 0) in front, (0, 1) behind and (1, 1) on it, from the
# whole-unit products 1 against 0, 0 against 1 and 1 against 1.
law divline_sides:
  {[S.Sim.sight.side(4194304, 2097152, 4194304, 0, 0, 65536),
    S.Sim.sight.side(2097152, 2097152, 4194304, 0, 0, 65536),
    S.Sim.sight.side(6291456, 2097152, 4194304, 0, 0, 65536),
    S.Sim.sight.side(4194304, 2097152, 0, 4194304, 65536, 0),
    S.Sim.sight.side(0, 2097152, 0, 4194304, 65536, 0),
    S.Sim.sight.side(0, 6291456, 0, 4194304, 65536, 0),
    S.Sim.sight.side(65536, 0, 0, 0, 65536, 65536),
    S.Sim.sight.side(0, 65536, 0, 0, 65536, 65536),
    S.Sim.sight.side(65536, 65536, 0, 0, 65536, 65536)]
    == [2, 1, 0, 2, 0, 1, 0, 1, 2] : List<&2, U32>}

# LAW: a pair of sectors REJECT rules out never sees, for any two mobjs
# in any level: P_CheckSight answers the lump before it walks the BSP,
# and nothing the walk could find brings the sight back.
law rejected_never_sees:
  for level: L.Level
  for m: S.Sim.Body
  for t: S.Sim.Body
  {S.Sim.sight.between(True{}, level, m, t) == False{} : Bool}

# LAW: every type that calls out on sight stands in a row that runs
# A_Look and chases in a row of the table that runs A_Chase, so no
# monster can wake without a state to wake into and none can watch for
# the player without A_Look to do it (sanity).
law monsters_wake:
  {List.all(~&2, ~H.Thing.Def, ~Fx.Closed.wakes, H.Thing.defs()) == True{} : Bool}

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

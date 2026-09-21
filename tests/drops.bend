# P_KillMobj spawns the human's item after its death-state draw.
# P_GiveAmmo gives 5 bullets for a dropped clip; P_GiveWeapon gives
# 4 shells for a dropped shotgun. PIT_ChangeSector removes only dropped
# items, makes an obstructing corpse S_GIBS with zero dimensions, and
# reports a living shootable obstruction to the mover.
import Base
import ../src/level.bend as L
import ../src/sim.bend as S
import ../src/things.bend as H
import ../src/inventory.bend as I
import ../src/vec.bend as V

def spawned(kind: U32) -> S.State:
  S.Sim.spawn(H.Thing.info(kind), 4194304, 0, H.Thing.onfloor(), S.State.start(L.Level.room(0, 128)))

def killed(kind: U32) -> S.State:
  S.Sim.damage(0, 100, H.Thing.you(), H.Thing.you(), spawned(kind))

def drop(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "missing"
    case Some{+th}:
      U32.show(H.Thing.kind(th)) ++ " dropped " ++ Bool.show(H.Thing.flagged(th, 131072))

def clipped(+id: U32, +s: S.State) -> S.Sim.Try:
  S.Sim.change.thing(S.State.thing(id, s), id, L.Level.room(0, 8), True{}, S.State.player(s), S.State.things(s))

def things(t: S.Sim.Try) -> H.Things:
  S.Try{ok, p, things} = t
  things

def body(m: Maybe<&2, H.Thing>) -> String:
  match m:
    case None{}:
      "missing"
    case Some{+th}:
      "state " ++ U32.show(H.Thing.state(th)) ++ " height " ++ U32.show(H.Thing.height(th))
        ++ " radius " ++ U32.show(V.Vec.get(H.Thing.hurt(th), H.Thing.hurt.radius()))
        ++ " solid " ++ Bool.show(H.Thing.flagged(th, 2))

def items(inv: I.Inventory) -> U32:
  I.Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, line} = inv
  items

def pickup(got: I.Inventory & H.Things, ammo: U32) -> String:
  (+inv, things) = got
  "rounds " ++ U32.show(I.Inventory.rounds(ammo, inv)) ++ " gone "
    ++ Bool.show(Maybe.is_none(&2, H.Thing, H.Things.get(things, 1)))
    ++ " items " ++ U32.show(items(inv))

def taken(+s: S.State, ammo: U32) -> String:
  pickup(S.Sim.touch.thing(S.State.thing(1, s), 4194304, 0, 0, I.Inventory.start(),
    L.Level.blockmap_of(S.State.level(s)), S.State.things(s)), ammo)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("zombieman " ++ drop(S.State.thing(1, killed(3004))) ++ " draws " ++ U32.show(S.State.rnd(killed(3004))))
    IO.print("shotgun guy " ++ drop(S.State.thing(1, killed(9))) ++ " draws " ++ U32.show(S.State.rnd(killed(9))))
    IO.print("clip " ++ taken(killed(3004), I.Inventory.am_clip()))
    IO.print("shotgun " ++ taken(killed(9), I.Inventory.am_shell()))
    IO.print("corpse " ++ body(H.Things.get(things(clipped(0, killed(3004))), 0)))
    IO.print("dropped removed " ++ Bool.show(Maybe.is_none(&2, H.Thing, H.Things.get(things(clipped(1, killed(3004))), 1))))
    IO.print("placed kept " ++ Bool.show(Bool.not(Maybe.is_none(&2, H.Thing, H.Things.get(things(clipped(0, spawned(2007))), 0)))))
    IO.print("living fits " ++ Bool.show(S.Sim.Try.ok(clipped(0, spawned(3004)))))

#|zombieman 2007 dropped True draws 3
#|shotgun guy 2001 dropped True draws 3
#|clip rounds 55 gone True items 0
#|shotgun rounds 4 gone True items 0
#|corpse state 50 height 0 radius 0 solid False
#|dropped removed True
#|placed kept True
#|living fits False

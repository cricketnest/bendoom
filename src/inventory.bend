# Doom's player_t inventory, as G_PlayerReborn starts it, and
# P_TouchSpecialThing's grants for the types Bendoom takes.
import Base
import ./vec.bend as V

# Health; armour points and type (0 none, 1 green, 2 blue); the cards,
# a bit each in card_t order (blue, yellow and red card, then blue,
# yellow and red skull); the ammo and its caps in ammotype_t order
# (bullets, shells, cells, rockets); the backpack; the weapons owned, a
# bit each in weapontype_t order (fist, pistol, shotgun, chaingun,
# rocket launcher, plasma rifle, BFG, chainsaw, super shotgun); the six
# powers' counters in powertype_t order; the items the tally counts;
# and the pickup flash's count, Doom's bonuscount.
type Inventory is Data:
  Inventory{health: U32, armour: U32, armourtype: U32, cards: U32, ammo: V.Vec, caps: V.Vec, backpack: Bool,
    weapons: U32, powers: V.Vec, items: U32, bonus: U32}

# 100 health, the fist and the pistol, fifty bullets, maxammo's caps.
def Inventory.start() -> Inventory:
  Inventory{100, 0, 0, 0, V.Vec.of_list([50, 0, 0, 0], 4), V.Vec.of_list([200, 50, 300, 50], 4), False{}, 3,
    V.Vec.of_list([0, 0, 0, 0, 0, 0], 6), 0, 0}

def Inventory.cards(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  cards

def Inventory.bonus(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  bonus

# Whether any of the cards a mask names is owned.
def Inventory.has(inv: Inventory, +mask: U32) -> Bool:
  Bool.not(U32.is_zero((Inventory.cards(inv) .&. mask : U32)))

# Doom's P_GiveCard: a card not owned yet sets the flash to 6.
def Inventory.card(+bit: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, +cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, (cards .|. bit : U32), ammo, caps, backpack, weapons, powers, items,
    Bool.pick(U32, U32.is_zero((cards .&. bit : U32)), 6, bonus)}

# Doom's clipammo: the rounds in a clip of each ammo type.
def Inventory.clip(+t: U32) -> U32:
  V.Vec.get(V.Vec.of_list([10, 4, 20, 1], 4), t)

# Whether an ammo type is short of its cap: P_GiveAmmo gives nothing
# otherwise.
def Inventory.room(+t: U32, inv: Inventory) -> Bool:
  Inventory{health, armour, armourtype, cards, +ammo, +caps, backpack, weapons, powers, items, bonus} = inv
  Bool.not(U32.is_eq(V.Vec.get(ammo, t), V.Vec.get(caps, t)))

# P_GiveAmmo's rounds: clips of an ammo type, up to its cap. Only the
# easiest and hardest skills double them, never Hurt Me Plenty.
def Inventory.give(+t: U32, clips: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, +ammo, +caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards,
    V.Vec.set(ammo, t, U32.min((V.Vec.get(ammo, t) + clips * Inventory.clip(t) : U32), V.Vec.get(caps, t))), caps,
    backpack, weapons, powers, items, bonus}

# A grant's answer: the inventory after it when the thing is taken, none
# when it stays.
def Inventory.taken(taken: Bool, inv: Inventory) -> Maybe<&2, Inventory>:
  match taken:
    case True{}:
      Some{inv}
    case False{}:
      None{}

# An ammo pickup: P_GiveAmmo, refused at the cap.
def Inventory.ammo(+t: U32, clips: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.taken(Inventory.room(t, inv), Inventory.give(t, clips, inv))

# P_GiveWeapon for a weapon found on the map, from the inventory its two
# clips of ammo left: the weapon is owned after, and it is taken when the
# ammo was given or the weapon was not owned before. Doom also makes it
# the pending weapon, which Bendoom has none of yet.
def Inventory.weapon(+bit: U32, gave: Bool, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, +weapons, powers, items, bonus} = inv
  Inventory.taken(Bool.or(gave, U32.is_zero((weapons .&. bit : U32))),
    Inventory{health, armour, armourtype, cards, ammo, caps, backpack, (weapons .|. bit : U32), powers, items, bonus})

def Inventory.doubled(v: V.Vec) -> V.Vec:
  match v:
    case V.Leaf{x}:
      V.Leaf{(x * 2 : U32)}
    case V.Node{l, r}:
      V.Node{Inventory.doubled(l), Inventory.doubled(r)}

# The caps once a backpack is taken: the first doubles each.
def Inventory.bag(had: Bool, caps: V.Vec) -> V.Vec:
  match had:
    case True{}:
      caps
    case False{}:
      Inventory.doubled(caps)

# P_TouchSpecialThing's backpack, always taken: the caps as the bag
# leaves them, then a clip of each ammo type in turn.
def Inventory.backpack(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory.give(3, 1, Inventory.give(2, 1, Inventory.give(1, 1, Inventory.give(0, 1,
    Inventory{health, armour, armourtype, cards, ammo, Inventory.bag(backpack, caps), True{}, weapons, powers, items,
      bonus}))))

# P_TouchSpecialThing's switch for the types Bendoom spawns: the
# inventory after the grant, none when the thing stays. The blue card
# and the backpack are always taken; a weapon brings two clips of its
# ammo, and the chainsaw has none.
def Inventory.grant(kind: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  match kind:
    case 5:
      Some{Inventory.card(1, inv)}
    case 8:
      Some{Inventory.backpack(inv)}
    case 17:
      Inventory.ammo(2, 5, inv)
    case 2001:
      Inventory.weapon(4, Inventory.room(1, inv), Inventory.give(1, 2, inv))
    case 2002:
      Inventory.weapon(8, Inventory.room(0, inv), Inventory.give(0, 2, inv))
    case 2003:
      Inventory.weapon(16, Inventory.room(3, inv), Inventory.give(3, 2, inv))
    case 2004:
      Inventory.weapon(32, Inventory.room(2, inv), Inventory.give(2, 2, inv))
    case 2005:
      Inventory.weapon(128, False{}, inv)
    case 2007:
      Inventory.ammo(0, 1, inv)
    case 2008:
      Inventory.ammo(1, 1, inv)
    case 2010:
      Inventory.ammo(3, 1, inv)
    case 2046:
      Inventory.ammo(3, 5, inv)
    case 2047:
      Inventory.ammo(2, 1, inv)
    case 2048:
      Inventory.ammo(0, 5, inv)
    case 2049:
      Inventory.ammo(1, 5, inv)
    case _:
      None{}

# The end of P_TouchSpecialThing for a thing taken: the tally counts an
# item flagged for it, and the flash grows by 6.
def Inventory.took(counted: Bool, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    (items + Bool.to_u32(counted) : U32), (bonus + 6 : U32)}

# P_PlayerThink's counters: the flash fades by one a tic.
def Inventory.tic(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, +bonus} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items,
    (bonus - Bool.to_u32(Bool.not(U32.is_zero(bonus))) : U32)}

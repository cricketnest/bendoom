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

def Inventory.health(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  health

def Inventory.cards(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  cards

def Inventory.bonus(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  bonus

# powertype_t's pw_strength, the berserk pack's power.
def Inventory.pw_strength() -> U32:
  1

# Whether the blue card or the blue skull is owned.
def Inventory.blue(inv: Inventory) -> Bool:
  Bool.not(U32.is_zero((Inventory.cards(inv) .&. 9 : U32)))

# Doom's P_GiveCard: a card not owned yet sets the flash to 6.
def Inventory.card(+bit: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, +cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, (cards .|. bit : U32), ammo, caps, backpack, weapons, powers, items,
    Bool.pick(U32, U32.is_zero((cards .&. bit : U32)), 6, bonus)}

# A count raised by an amount up to a cap, and never lowered by it: a
# count already at or past the cap stays.
def Inventory.upto(+v: U32, +amount: U32, +cap: U32) -> U32:
  U32.max(v, U32.min((v + amount : U32), cap))

# Health healed by an amount up to a cap.
def Inventory.heal(+amount: U32, +cap: U32, inv: Inventory) -> Inventory:
  Inventory{+health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{Inventory.upto(health, amount, cap), armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    items, bonus}

# Doom's P_GiveBody: under 100 health, heal by an amount up to 100; at
# 100 or more the thing stays.
def Inventory.body(+amount: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Bool.pick(Maybe<&2, Inventory>, U32.is_lt(Inventory.health(inv), 100), Some{Inventory.heal(amount, 100, inv)},
    None{})

# The strength power on, its counter at 1.
def Inventory.strong(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
    V.Vec.set(powers, Inventory.pw_strength(), 1), items, bonus}

# The armour bonus: a point more up to 200, and green armour's type if
# none is worn.
def Inventory.helmet(inv: Inventory) -> Inventory:
  Inventory{health, +armour, +armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, Inventory.upto(armour, 1, 200), U32.max(armourtype, 1), cards, ammo, caps, backpack, weapons,
    powers, items, bonus}

# Doom's P_GiveArmor: a type's 100 points each, and the type, over fewer
# points of any type; with as many or more the thing stays.
def Inventory.suit(+kind: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, +armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Bool.pick(Maybe<&2, Inventory>, U32.is_lt(armour, (kind * 100 : U32)),
    Some{Inventory{health, (kind * 100 : U32), kind, cards, ammo, caps, backpack, weapons, powers, items, bonus}},
    None{})

# P_TouchSpecialThing's grant for a type: the inventory after it, none
# when the thing stays. The blue card, the two bonuses and the soul
# sphere are always taken, and so is the berserk pack, P_GivePower's
# strength with P_GiveBody's 100 whether it heals or not; the stimpack
# heals 10, the medikit 25; green armour is type 1, blue type 2.
def Inventory.grant(kind: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  match kind:
    case 5:
      Some{Inventory.card(1, inv)}
    case 2011:
      Inventory.body(10, inv)
    case 2012:
      Inventory.body(25, inv)
    case 2013:
      Some{Inventory.heal(100, 200, inv)}
    case 2014:
      Some{Inventory.heal(1, 200, inv)}
    case 2015:
      Some{Inventory.helmet(inv)}
    case 2018:
      Inventory.suit(1, inv)
    case 2019:
      Inventory.suit(2, inv)
    case 2023:
      Some{Inventory.strong(Inventory.heal(100, 100, inv))}
    case _:
      None{}

# The end of P_TouchSpecialThing for a thing taken: the tally counts an
# item flagged for it, and the flash grows by 6.
def Inventory.took(counted: Bool, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    (items + Bool.to_u32(counted) : U32), (bonus + 6 : U32)}

# 1 for a counter that runs, 0 for one at rest.
def Inventory.on(+n: U32) -> U32:
  Bool.to_u32(Bool.not(U32.is_zero(n)))

# P_PlayerThink's counters: strength counts up once on, and the flash
# fades by one a tic.
def Inventory.tic(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, +powers, items, +bonus} = inv
  +strength = V.Vec.get(powers, Inventory.pw_strength())
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
    V.Vec.set(powers, Inventory.pw_strength(), (strength + Inventory.on(strength) : U32)), items,
    (bonus - Inventory.on(bonus) : U32)}

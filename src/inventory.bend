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

# P_TouchSpecialThing's grant for a type: the inventory after it, none
# when the thing stays. The blue card is always taken.
def Inventory.grant(kind: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  match kind:
    case 5:
      Some{Inventory.card(1, inv)}
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

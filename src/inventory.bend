# Doom's player_t inventory, as G_PlayerReborn starts it, and
# P_TouchSpecialThing's grants for the types Bendoom takes.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./sound.bend as Sn

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

# Every count as text, for the tests and the tools.
def Inventory.show(inv: Inventory) -> String:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  "inventory health " ++ U32.show(health) ++ " armour " ++ U32.show(armour) ++ " type " ++ U32.show(armourtype)
    ++ " cards " ++ U32.show(cards) ++ " ammo" ++ V.Vec.show(ammo, 4n, 0) ++ " caps" ++ V.Vec.show(caps, 4n, 0)
    ++ " backpack " ++ Bool.show(backpack) ++ " weapons " ++ U32.show(weapons) ++ " powers"
    ++ V.Vec.show(powers, 6n, 0) ++ " items " ++ U32.show(items) ++ " flash " ++ U32.show(bonus)

def Inventory.health(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  health

# Doom's PST_DEAD: the health P_DamageMobj holds at 0 has run out.
# Health is compared as a signed quantity, as vanilla's is.
def Inventory.dead(+inv: Inventory) -> Bool:
  F.Fixed.le(Inventory.health(inv), 0)

def Inventory.armour(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  armour

def Inventory.armourtype(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  armourtype

def Inventory.cards(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  cards

def Inventory.bonus(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  bonus

def Inventory.weapons(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  weapons

# The rounds of an ammo type and the cap on them, Doom's ammo[t] and
# maxammo[t].
def Inventory.rounds(+t: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  V.Vec.get(ammo, t)

def Inventory.cap(+t: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  V.Vec.get(caps, t)

# The armour types.
def Inventory.green_armour() -> U32:
  1

def Inventory.blue_armour() -> U32:
  2

# The blue card's and the blue skull's bits among the cards.
def Inventory.bluecard() -> U32:
  1

def Inventory.blueskull() -> U32:
  8

# ammotype_t's indexes.
def Inventory.am_clip() -> U32:
  0

def Inventory.am_shell() -> U32:
  1

def Inventory.am_cell() -> U32:
  2

def Inventory.am_misl() -> U32:
  3

# The world weapons' bits among the weapons owned.
def Inventory.shotgun() -> U32:
  4

def Inventory.chaingun() -> U32:
  8

def Inventory.launcher() -> U32:
  16

def Inventory.plasma() -> U32:
  32

def Inventory.chainsaw() -> U32:
  128

# powertype_t's pw_strength, the berserk pack's power.
def Inventory.pw_strength() -> U32:
  1

# The berserk power's counter, which counts up from 1 while it is on.
def Inventory.strength(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  V.Vec.get(powers, Inventory.pw_strength())

# Whether the blue card or the blue skull is owned.
def Inventory.blue(inv: Inventory) -> Bool:
  Bool.not(U32.is_zero((Inventory.cards(inv) .&. (Inventory.bluecard() .|. Inventory.blueskull() : U32) : U32)))

# Doom's P_GiveCard: a card not owned yet sets the flash to 6.
def Inventory.card(+bit: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, +cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, (cards .|. bit : U32), ammo, caps, backpack, weapons, powers, items,
    Bool.pick(U32, U32.is_zero((cards .&. bit : U32)), 6, bonus)}

# A grant's answer: the inventory after it when the thing is taken, none
# when it stays.
def Inventory.taken(taken: Bool, inv: Inventory) -> Maybe<&2, Inventory>:
  match taken:
    case True{}:
      Some{inv}
    case False{}:
      None{}

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
  Inventory.taken(U32.is_lt(Inventory.health(inv), 100), Inventory.heal(amount, 100, inv))

# The strength power on, its counter at 1.
def Inventory.strong(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
    V.Vec.set(powers, Inventory.pw_strength(), 1), items, bonus}

# The armour bonus: a point more up to 200, and green armour's type if
# none is worn.
def Inventory.helmet(inv: Inventory) -> Inventory:
  Inventory{health, +armour, +armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, Inventory.upto(armour, 1, 200), U32.max(armourtype, Inventory.green_armour()), cards, ammo,
    caps, backpack, weapons, powers, items, bonus}

# Doom's P_GiveArmor: a type's 100 points each, and the type, over fewer
# points of any type; with as many or more the thing stays.
def Inventory.suit(+kind: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, +armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory.taken(U32.is_lt(armour, (kind * 100 : U32)),
    Inventory{health, (kind * 100 : U32), kind, cards, ammo, caps, backpack, weapons, powers, items, bonus})

# Doom's clipammo: the rounds in a clip of each ammo type.
def Inventory.clip(+t: U32) -> U32:
  V.Vec.get(V.Vec.of_list([10, 4, 20, 1], 4), t)

# Doom's DecreaseAmmo: a shot spends rounds of its weapon's type. No
# weapon Bendoom carries has an ammo type past the four, so vanilla's
# overflow into the caps has no caller.
def Inventory.spend(+t: U32, +amount: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, +ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards, V.Vec.set(ammo, t, (V.Vec.get(ammo, t) - amount : U32)), caps,
    backpack, weapons, powers, items, bonus}

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
    V.Vec.set(ammo, t, Inventory.upto(V.Vec.get(ammo, t), (clips * Inventory.clip(t) : U32), V.Vec.get(caps, t))),
    caps, backpack, weapons, powers, items, bonus}

# An ammo pickup: P_GiveAmmo, refused at the cap.
def Inventory.ammo(+t: U32, clips: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.taken(Inventory.room(t, inv), Inventory.give(t, clips, inv))

# P_GiveWeapon for a weapon found on the map, from the inventory its
# ammo left: the weapon is owned after, and it is taken when the ammo
# was given or the weapon was not owned before. Doom also makes it the
# pending weapon, which Bendoom has none of yet.
def Inventory.weapon(+bit: U32, gave: Bool, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, +weapons, powers, items, bonus} = inv
  Inventory.taken(Bool.or(gave, U32.is_zero((weapons .&. bit : U32))),
    Inventory{health, armour, armourtype, cards, ammo, caps, backpack, (weapons .|. bit : U32), powers, items, bonus})

# A weapon found with ammo of a type: two clips of it.
def Inventory.armed(bit: U32, +t: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.weapon(bit, Inventory.room(t, inv), Inventory.give(t, 2, inv))

# The caps once a backpack is taken: the first doubles each.
def Inventory.bag(had: Bool, caps: V.Vec) -> V.Vec:
  match had:
    case True{}:
      caps
    case False{}:
      V.Vec.doubled(caps)

# P_TouchSpecialThing's backpack, always taken: the caps as the bag
# leaves them, then a clip of each ammo type in turn.
def Inventory.backpack(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory.give(Inventory.am_misl(), 1, Inventory.give(Inventory.am_cell(), 1, Inventory.give(Inventory.am_shell(),
    1, Inventory.give(Inventory.am_clip(), 1, Inventory{health, armour, armourtype, cards, ammo,
      Inventory.bag(backpack, caps), True{}, weapons, powers, items, bonus}))))

# P_TouchSpecialThing's switch for the types Bendoom spawns: the
# inventory after the grant, none when the thing stays. The blue card,
# the two bonuses, the soul sphere and the backpack are always taken, and
# so is the berserk pack, P_GivePower's strength with P_GiveBody's 100
# whether it heals or not; the stimpack heals 10, the medikit 25; a box
# holds five clips; a weapon brings two clips of its ammo, and the
# chainsaw has none.
def Inventory.grant(kind: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  match kind:
    case 5:
      Some{Inventory.card(Inventory.bluecard(), inv)}
    case 8:
      Some{Inventory.backpack(inv)}
    case 17:
      Inventory.ammo(Inventory.am_cell(), 5, inv)
    case 2001:
      Inventory.armed(Inventory.shotgun(), Inventory.am_shell(), inv)
    case 2002:
      Inventory.armed(Inventory.chaingun(), Inventory.am_clip(), inv)
    case 2003:
      Inventory.armed(Inventory.launcher(), Inventory.am_misl(), inv)
    case 2004:
      Inventory.armed(Inventory.plasma(), Inventory.am_cell(), inv)
    case 2005:
      Inventory.weapon(Inventory.chainsaw(), False{}, inv)
    case 2007:
      Inventory.ammo(Inventory.am_clip(), 1, inv)
    case 2008:
      Inventory.ammo(Inventory.am_shell(), 1, inv)
    case 2010:
      Inventory.ammo(Inventory.am_misl(), 1, inv)
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
      Inventory.suit(Inventory.green_armour(), inv)
    case 2019:
      Inventory.suit(Inventory.blue_armour(), inv)
    case 2023:
      Some{Inventory.strong(Inventory.heal(100, 100, inv))}
    case 2046:
      Inventory.ammo(Inventory.am_misl(), 5, inv)
    case 2047:
      Inventory.ammo(Inventory.am_cell(), 1, inv)
    case 2048:
      Inventory.ammo(Inventory.am_clip(), 5, inv)
    case 2049:
      Inventory.ammo(Inventory.am_shell(), 5, inv)
    case _:
      None{}

# P_TouchSpecialThing's sound for a type taken: the weapons' (2001 to
# 2005), the power's for the soul sphere and the berserk pack, and the
# item's for the rest.
def Inventory.sound(+kind: U32) -> U32:
  Bool.pick(U32, Bool.and(U32.is_ge(kind, 2001), U32.is_le(kind, 2005)), Sn.Sound.wpnup(),
    Bool.pick(U32, Bool.or(U32.is_eq(kind, 2013), U32.is_eq(kind, 2023)), Sn.Sound.getpow(), Sn.Sound.itemup()))

# The end of P_TouchSpecialThing for a thing taken: the tally counts an
# item flagged for it, and the flash grows by 6.
def Inventory.took(counted: Bool, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    (items + Bool.to_u32(counted) : U32), (bonus + 6 : U32)}

# P_DamageMobj's saved: green armour absorbs a third of a blow and blue
# a half, and neither more than the points worn. No armour absorbs
# nothing.
def Inventory.saved(worn: Bool, +armourtype: U32, +armour: U32, +damage: U32) -> U32:
  match worn:
    case False{}:
      0
    case True{}:
      U32.min(armour, Bool.pick(U32, U32.is_eq(armourtype, Inventory.green_armour()), (damage / 3 : U32),
        (damage / 2 : U32)))

def Inventory.hurt.fin(+saved: U32, inv: Inventory, +damage: U32) -> Inventory & U32:
  Inventory{+health, +armour, +armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus} = inv
  +left = (damage - saved : U32)
  (Inventory{F.Fixed.max((health - left : U32), 0), (armour - saved : U32),
    Bool.pick(U32, U32.is_eq(armour, saved), 0, armourtype), cards, ammo, caps, backpack, weapons, powers, items,
    bonus}, left)

# P_DamageMobj's blow on the inventory: the armour absorbs its share and
# loses its type where the share used it up, and the health takes the
# rest and stops at 0, as player->health does. The inventory after, and
# the damage that reached the player, which the damage count takes.
def Inventory.hurt(+inv: Inventory, +damage: U32) -> Inventory & U32:
  Inventory.hurt.fin(Inventory.saved(Bool.not(U32.is_zero(Inventory.armourtype(inv))), Inventory.armourtype(inv),
    Inventory.armour(inv), damage), inv, damage)

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

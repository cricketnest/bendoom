# Doom's player_t inventory, as G_PlayerReborn starts it, and
# P_TouchSpecialThing's grants for the types Bendoom takes.
import Base
import ./vec.bend as V
import ./sound.bend as Sn
import ./message.bend as Msg

# Health; armour points and type (0 none, 1 green, 2 blue); the cards,
# a bit each in card_t order (blue, yellow and red card, then blue,
# yellow and red skull); the ammo and its caps in ammotype_t order
# (bullets, shells, cells, rockets); the backpack; the weapons owned, a
# bit each in weapontype_t order (fist, pistol, shotgun, chaingun,
# rocket launcher, plasma rifle, BFG, chainsaw, super shotgun); the six
# powers' counters in powertype_t order; the items the tally counts;
# the pickup flash's count, Doom's bonuscount; and the heads-up line,
# the number of the message it shows and the tics it has left there.
# The player carries the line because vanilla's own message is a
# player_t field and Bendoom keeps no state beside the player's for
# hu_stuff.c's two statics.
type Inventory is Data:
  Inventory{health: U32, armour: U32, armourtype: U32, cards: U32, ammo: V.Vec, caps: V.Vec, backpack: Bool,
    weapons: U32, powers: V.Vec, items: U32, bonus: U32, message: U32, msgtics: U32}

# 100 health, the fist and the pistol, fifty bullets, maxammo's caps.
def Inventory.start() -> Inventory:
  Inventory{100, 0, 0, 0, V.Vec.of_list([50, 0, 0, 0], 4), V.Vec.of_list([200, 50, 300, 50], 4), False{}, 3,
    V.Vec.of_list([0, 0, 0, 0, 0, 0], 6), 0, 0, Msg.Message.none(), 0}

# Every count as text, for the tests and the tools. The message line is
# printed where a test is about it.
def Inventory.show(inv: Inventory) -> String:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  "inventory health " ++ U32.show(health) ++ " armour " ++ U32.show(armour) ++ " type " ++ U32.show(armourtype)
    ++ " cards " ++ U32.show(cards) ++ " ammo" ++ V.Vec.show(ammo, 4n, 0) ++ " caps" ++ V.Vec.show(caps, 4n, 0)
    ++ " backpack " ++ Bool.show(backpack) ++ " weapons " ++ U32.show(weapons) ++ " powers"
    ++ V.Vec.show(powers, 6n, 0) ++ " items " ++ U32.show(items) ++ " flash " ++ U32.show(bonus)

def Inventory.health(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  health

def Inventory.cards(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  cards

def Inventory.bonus(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  bonus

def Inventory.armour(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  armour

def Inventory.weapons(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  weapons

# The rounds of an ammo type and the cap on them, Doom's ammo[t] and
# maxammo[t].
def Inventory.rounds(+t: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  V.Vec.get(ammo, t)

def Inventory.cap(+t: U32, inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
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

# Whether the blue card or the blue skull is owned.
def Inventory.blue(inv: Inventory) -> Bool:
  Bool.not(U32.is_zero((Inventory.cards(inv) .&. (Inventory.bluecard() .|. Inventory.blueskull() : U32) : U32)))

# 1 for a counter that runs, 0 for one at rest.
def Inventory.on(+n: U32) -> U32:
  Bool.to_u32(Bool.not(U32.is_zero(n)))

# The message the heads-up line shows, and the tics it has left there.
def Inventory.message(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message,
    msgtics} = inv
  message

def Inventory.msgtics(inv: Inventory) -> U32:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message,
    msgtics} = inv
  msgtics

# Doom's player->message = s, where p_inter.c and p_doors.c set it, with
# HU_Ticker's own work folded in: the message takes the line at once,
# and for a tic more than HU_MSGTIMEOUT, since the tic that gives it
# counts it down before it is ever drawn. A newer message replaces an
# older, as vanilla's later write does. No message leaves the line as it
# was, since vanilla's code sets one or returns.
def Inventory.saying(+msg: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message,
    msgtics} = inv
  +quiet = U32.is_zero(msg)
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus,
    Bool.pick(U32, quiet, message, msg), Bool.pick(U32, quiet, msgtics, Msg.Message.given())}

# Doom's HU_Ticker: the line's counter falls by one, and the tic it
# reaches zero the line goes out.
def Inventory.hud(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message,
    +msgtics} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message,
    (msgtics - Inventory.on(msgtics) : U32)}

# Doom's P_GiveCard, with the message p_inter.c sets on the same test
# just before it: a card not owned yet sets the flash to 6 and names
# itself, and one already owned leaves the line as it was.
def Inventory.card(+bit: U32, +msg: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, +cards, ammo, caps, backpack, weapons, powers, items, bonus, message,
    msgtics} = inv
  +fresh = U32.is_zero((cards .&. bit : U32))
  Inventory.saying(Bool.pick(U32, fresh, msg, Msg.Message.none()),
    Inventory{health, armour, armourtype, (cards .|. bit : U32), ammo, caps, backpack, weapons, powers, items,
      Bool.pick(U32, fresh, 6, bonus), message, msgtics})

# A grant's answer: the inventory saying its message when the thing is
# taken, none when it stays, as each of p_inter.c's cases returns before
# it sets one.
def Inventory.taken(taken: Bool, msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  match taken:
    case True{}:
      Some{Inventory.saying(msg, inv)}
    case False{}:
      None{}

# A count raised by an amount up to a cap, and never lowered by it: a
# count already at or past the cap stays.
def Inventory.upto(+v: U32, +amount: U32, +cap: U32) -> U32:
  U32.max(v, U32.min((v + amount : U32), cap))

# Health healed by an amount up to a cap.
def Inventory.heal(+amount: U32, +cap: U32, inv: Inventory) -> Inventory:
  Inventory{+health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory{Inventory.upto(health, amount, cap), armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    items, bonus, message, msgtics}

# Doom's P_GiveBody: under 100 health, heal by an amount up to 100; at
# 100 or more the thing stays.
def Inventory.body(+amount: U32, msg: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.taken(U32.is_lt(Inventory.health(inv), 100), msg, Inventory.heal(amount, 100, inv))

# The strength power on, its counter at 1.
def Inventory.strong(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
    V.Vec.set(powers, Inventory.pw_strength(), 1), items, bonus, message, msgtics}

# The armour bonus: a point more up to 200, and green armour's type if
# none is worn.
def Inventory.helmet(inv: Inventory) -> Inventory:
  Inventory{health, +armour, +armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory{health, Inventory.upto(armour, 1, 200), U32.max(armourtype, Inventory.green_armour()), cards, ammo,
    caps, backpack, weapons, powers, items, bonus, message, msgtics}

# Doom's P_GiveArmor: a type's 100 points each, and the type, over fewer
# points of any type; with as many or more the thing stays.
def Inventory.suit(+kind: U32, msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, +armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory.taken(U32.is_lt(armour, (kind * 100 : U32)), msg,
    Inventory{health, (kind * 100 : U32), kind, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics})

# Doom's clipammo: the rounds in a clip of each ammo type.
def Inventory.clip(+t: U32) -> U32:
  V.Vec.get(V.Vec.of_list([10, 4, 20, 1], 4), t)

# Whether an ammo type is short of its cap: P_GiveAmmo gives nothing
# otherwise.
def Inventory.room(+t: U32, inv: Inventory) -> Bool:
  Inventory{health, armour, armourtype, cards, +ammo, +caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Bool.not(U32.is_eq(V.Vec.get(ammo, t), V.Vec.get(caps, t)))

# P_GiveAmmo's rounds: clips of an ammo type, up to its cap. Only the
# easiest and hardest skills double them, never Hurt Me Plenty.
def Inventory.give(+t: U32, clips: U32, inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, +ammo, +caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory{health, armour, armourtype, cards,
    V.Vec.set(ammo, t, Inventory.upto(V.Vec.get(ammo, t), (clips * Inventory.clip(t) : U32), V.Vec.get(caps, t))),
    caps, backpack, weapons, powers, items, bonus, message, msgtics}

# An ammo pickup: P_GiveAmmo, refused at the cap.
def Inventory.ammo(+t: U32, clips: U32, msg: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.taken(Inventory.room(t, inv), msg, Inventory.give(t, clips, inv))

# P_GiveWeapon for a weapon found on the map, from the inventory its
# ammo left: the weapon is owned after, and it is taken when the ammo
# was given or the weapon was not owned before. Doom also makes it the
# pending weapon, which Bendoom has none of yet.
def Inventory.weapon(+bit: U32, gave: Bool, msg: U32, inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, +weapons, powers, items, bonus, message, msgtics} = inv
  Inventory.taken(Bool.or(gave, U32.is_zero((weapons .&. bit : U32))), msg,
    Inventory{health, armour, armourtype, cards, ammo, caps, backpack, (weapons .|. bit : U32), powers, items, bonus, message, msgtics})

# A weapon found with ammo of a type: two clips of it.
def Inventory.armed(bit: U32, +t: U32, msg: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  Inventory.weapon(bit, Inventory.room(t, inv), msg, Inventory.give(t, 2, inv))

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
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory.give(Inventory.am_misl(), 1, Inventory.give(Inventory.am_cell(), 1, Inventory.give(Inventory.am_shell(),
    1, Inventory.give(Inventory.am_clip(), 1, Inventory{health, armour, armourtype, cards, ammo,
      Inventory.bag(backpack, caps), True{}, weapons, powers, items, bonus, message, msgtics}))))

# P_TouchSpecialThing's switch for the types Bendoom spawns: the
# inventory after the grant, saying the message that case sets, and none
# when the thing stays. The blue card, the two bonuses, the soul sphere
# and the backpack are always taken, and so is the berserk pack,
# P_GivePower's strength with P_GiveBody's 100 whether it heals or not;
# the stimpack heals 10, the medikit 25; a box holds five clips; a weapon
# brings two clips of its ammo, and the chainsaw has none. The types
# neither E1M1 places keep their grant and say nothing, since no play
# could show their strings.
def Inventory.grant(kind: U32, +inv: Inventory) -> Maybe<&2, Inventory>:
  match kind:
    case 5:
      Some{Inventory.card(Inventory.bluecard(), Msg.Message.gotbluecard(), inv)}
    case 8:
      Some{Inventory.backpack(inv)}
    case 17:
      Inventory.ammo(Inventory.am_cell(), 5, Msg.Message.none(), inv)
    case 2001:
      Inventory.armed(Inventory.shotgun(), Inventory.am_shell(), Msg.Message.gotshotgun(), inv)
    case 2002:
      Inventory.armed(Inventory.chaingun(), Inventory.am_clip(), Msg.Message.none(), inv)
    case 2003:
      Inventory.armed(Inventory.launcher(), Inventory.am_misl(), Msg.Message.none(), inv)
    case 2004:
      Inventory.armed(Inventory.plasma(), Inventory.am_cell(), Msg.Message.none(), inv)
    case 2005:
      Inventory.weapon(Inventory.chainsaw(), False{}, Msg.Message.gotchainsaw(), inv)
    case 2007:
      Inventory.ammo(Inventory.am_clip(), 1, Msg.Message.gotclip(), inv)
    case 2008:
      Inventory.ammo(Inventory.am_shell(), 1, Msg.Message.gotshells(), inv)
    case 2010:
      Inventory.ammo(Inventory.am_misl(), 1, Msg.Message.gotrocket(), inv)
    case 2011:
      Inventory.body(10, Msg.Message.gotstim(), inv)
    case 2012:
      Inventory.body(25, Msg.Message.gotmedikit(), inv)
    case 2013:
      Some{Inventory.heal(100, 200, inv)}
    case 2014:
      Some{Inventory.saying(Msg.Message.goththbonus(), Inventory.heal(1, 200, inv))}
    case 2015:
      Some{Inventory.saying(Msg.Message.gotarmbonus(), Inventory.helmet(inv))}
    case 2018:
      Inventory.suit(Inventory.green_armour(), Msg.Message.gotarmor(), inv)
    case 2019:
      Inventory.suit(Inventory.blue_armour(), Msg.Message.gotmega(), inv)
    case 2023:
      Some{Inventory.saying(Msg.Message.gotberserk(), Inventory.strong(Inventory.heal(100, 100, inv)))}
    case 2046:
      Inventory.ammo(Inventory.am_misl(), 5, Msg.Message.none(), inv)
    case 2047:
      Inventory.ammo(Inventory.am_cell(), 1, Msg.Message.gotcell(), inv)
    case 2048:
      Inventory.ammo(Inventory.am_clip(), 5, Msg.Message.gotclipbox(), inv)
    case 2049:
      Inventory.ammo(Inventory.am_shell(), 5, Msg.Message.gotshellbox(), inv)
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
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers, items, bonus, message, msgtics} = inv
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, powers,
    (items + Bool.to_u32(counted) : U32), (bonus + 6 : U32), message, msgtics}

# P_PlayerThink's counters: strength counts up once on, and the flash
# fades by one a tic.
def Inventory.tic(inv: Inventory) -> Inventory:
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons, +powers, items, +bonus, message, msgtics} = inv
  +strength = V.Vec.get(powers, Inventory.pw_strength())
  Inventory{health, armour, armourtype, cards, ammo, caps, backpack, weapons,
    V.Vec.set(powers, Inventory.pw_strength(), (strength + Inventory.on(strength) : U32)), items,
    (bonus - Inventory.on(bonus) : U32), message, msgtics}

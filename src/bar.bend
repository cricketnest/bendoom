# Doom's status bar: ST_refreshBackground and ST_drawWidgets drawn into
# rows 168 to 199 of the frame from the inventory, each patch placed
# where ST_createWidgets puts its widget and written as V_DrawPatch
# writes one, over the background and under nothing. Single player, so
# the frags widget and the net game's face background are never drawn
# and the arms panel always is. The face is ticket 23's; until then the
# background shows in its box.
import Base
import ./bytes.bend as B
import ./vec.bend as V
import ./gfx.bend as G
import ./things.bend as H
import ./inventory.bend as I

# The slots of Gfx.bar.names(): the ten tall digits from 0, the ten
# short ones from 10, the percent sign, the six key icons from 21, the
# six grey weapon numbers from 27, the arms panel, the background.
def Bar.tall() -> U32:
  0

def Bar.short() -> U32:
  10

def Bar.prcnt() -> U32:
  20

def Bar.keys() -> U32:
  21

def Bar.grey() -> U32:
  27

def Bar.arms() -> U32:
  33

def Bar.back() -> U32:
  34

# Patches
# -------

# A post's texels written down a column of the frame, a row apart.
def Bar.down(n: Nat, +from: U32, +to: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Bar.down(m, (from + 1 : U32), (to + 320 : U32), G.Gfx.move.put(to, B.Bytes.at(mem, from)))

# One post of a patch's column, at its rows of the frame from the
# column's first, which the context carries.
def Bar.post(mem: Array<U32>, +src: U32, +delta: U32, +len: U32, +at: U32) -> Array<U32>:
  Bar.down(U32.to_nat(len), (src + 3 : U32), (at + delta * 320 : U32), mem)

def Bar.column(+patch: U32, +at: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, off) = p
  G.Gfx.posts(~U32, ~Bar.post, 64n, G.Post{False{}, mem, (patch + off : U32)}, at)

# The patch's columns in turn, each from its own column offset.
def Bar.cols(n: Nat, +patch: U32, +col: U32, +at: U32, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Bar.cols(m, patch, (col + 1 : U32), (at + 1 : U32),
        Bar.column(patch, at, B.Bytes.u32(mem, (patch + 8 + col * 4 : U32))))

def Bar.patch.wide(+patch: U32, +at: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, width) = p
  Bar.cols(U32.to_nat(width), patch, 0, at, mem)

def Bar.patch.left(+patch: U32, +x: U32, +row: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, left) = p
  Bar.patch.wide(patch, (G.Gfx.frame() + row * 320 + x - G.Gfx.s16(left) : U32), B.Bytes.u16(mem, patch))

def Bar.patch.top(+patch: U32, +x: U32, +y: U32, p: Array<U32> & U32) -> Array<U32>:
  (mem, top) = p
  Bar.patch.left(patch, x, (y - G.Gfx.s16(top) : U32), B.Bytes.u16(mem, (patch + 4 : U32)))

# Doom's V_DrawPatch: the patch's posts written into the frame at x, y
# less its offsets, with what lies between them left as it was.
def Bar.patch(+patch: U32, +x: U32, +y: U32, mem: Array<U32>) -> Array<U32>:
  Bar.patch.top(patch, x, y, B.Bytes.u16(mem, (patch + 6 : U32)))

# Widgets
# -------

def Bar.digit(+gfx: G.Gfx, +font: U32, +d: U32) -> U32:
  G.Gfx.bar(gfx, (font + d : U32))

# STlib_drawNum's loop: the last digit a zero's width left of x, each
# digit before it a width further left, while digits are left and the
# number has more. A zero draws one digit, since its loop stops on the
# number and not on the width.
def Bar.num.go(n: Nat, more: Bool, +num: U32, +x: U32, +y: U32, +w: U32, +font: U32, +gfx: G.Gfx,
  mem: Array<U32>) -> Array<U32>:
  match n more:
    case 1n+m True{}:
      +left = (x - w : U32)
      +rest = (num / 10 : U32)
      Bar.num.go(m, Bool.not(U32.is_zero(rest)), rest, left, y, w, font, gfx,
        Bar.patch(Bar.digit(gfx, font, (num % 10 : U32)), left, y, mem))
    case _ _:
      mem

def Bar.num.wide(width: Nat, +num: U32, +x: U32, +y: U32, +font: U32, +gfx: G.Gfx, p: Array<U32> & U32) ->
  Array<U32>:
  (mem, w) = p
  Bar.num.go(width, True{}, num, x, y, w, font, gfx, mem)

# Doom's STlib_drawNum: up to width digits of a number, right-aligned at
# x, stepped by the width of the font's zero however wide each digit is.
# No count this bar shows is negative or the 1994 that stands for no
# ammo, so the minus sign and the blank have no caller.
def Bar.num(width: Nat, +num: U32, +x: U32, +y: U32, +font: U32, +gfx: G.Gfx, mem: Array<U32>) ->
  Array<U32>:
  Bar.num.wide(width, num, x, y, font, gfx, B.Bytes.u16(mem, G.Gfx.bar(gfx, font)))

# Doom's STlib_updatePercent: the percent sign at the widget's place,
# then its number of three tall digits.
def Bar.percent(+num: U32, +x: U32, +y: U32, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Bar.num(3n, num, x, y, Bar.tall(), gfx, Bar.patch(G.Gfx.bar(gfx, Bar.prcnt()), x, y, mem))

# ST_AMMO0Y on: the rows of the four ammo counts and their caps, the
# rockets' under the cells'.
def Bar.ammo.rows() -> V.Vec:
  V.Vec.of_list([173, 179, 191, 185], 4)

# The count of each ammo type at ST_AMMO0X and its cap at ST_MAXAMMO0X,
# three short digits each.
def Bar.ammo.go(n: Nat, +i: U32, +rows: V.Vec, +inv: I.Inventory, +gfx: G.Gfx, mem: Array<U32>) ->
  Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      +y = V.Vec.get(rows, i)
      Bar.ammo.go(m, (i + 1 : U32), rows, inv, gfx,
        Bar.num(3n, I.Inventory.cap(i, inv), 314, y, Bar.short(), gfx,
          Bar.num(3n, I.Inventory.rounds(i, inv), 288, y, Bar.short(), gfx, mem)))

# ST_updateWidgets' w_arms: weapon i + 1 shows its yellow short number
# when it is owned and its grey one when it is not.
def Bar.arm(+weapons: U32, +i: U32) -> U32:
  Bool.pick(U32, U32.is_zero((weapons .&. U32.shln(2, U32.to_nat(i)) : U32)), (Bar.grey() + i : U32),
    (Bar.short() + i + 2 : U32))

# The six numbers of the arms panel, three to a row from ST_ARMSX,
# ST_ARMSY.
def Bar.arms.go(n: Nat, +i: U32, +weapons: U32, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      Bar.arms.go(m, (i + 1 : U32), weapons, gfx,
        Bar.patch(G.Gfx.bar(gfx, Bar.arm(weapons, i)), (111 + (i % 3) * 12 : U32),
          (172 + (i / 3) * 10 : U32), mem))

# ST_updateWidgets' keyboxes: a colour shows its skull when that is
# held, else its card, and nothing when neither is.
def Bar.keybox(+cards: U32, +i: U32) -> U32:
  +skull = Bool.not(U32.is_zero((cards .&. U32.shln(8, U32.to_nat(i)) : U32)))
  Bool.pick(U32, Bool.or(skull, Bool.not(U32.is_zero((cards .&. U32.shln(1, U32.to_nat(i)) : U32)))),
    (Bar.keys() + i + 3 * Bool.to_u32(skull) : U32), G.Gfx.none())

# Doom's STlib_updateMultIcon: a widget whose icon is none draws
# nothing.
def Bar.icon(shown: Bool, +slot: U32, +x: U32, +y: U32, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  match shown:
    case False{}:
      mem
    case True{}:
      Bar.patch(G.Gfx.bar(gfx, slot), x, y, mem)

# The three key slots down the bar's right, ST_KEY0Y on.
def Bar.keys.go(n: Nat, +i: U32, +cards: U32, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      mem
    case 1n+m:
      +box = Bar.keybox(cards, i)
      Bar.keys.go(m, (i + 1 : U32), cards, gfx,
        Bar.icon(Bool.not(U32.is_eq(box, G.Gfx.none())), box, 239, (171 + i * 10 : U32), gfx, mem))

# The bar
# -------

# ST_drawWidgets' numbers: the ready weapon's ammo, the four counts with
# their caps, then health and armour behind their percent signs.
def Bar.numbers(+inv: I.Inventory, +ammo: U32, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Bar.percent(I.Inventory.armour(inv), 221, 171, gfx,
    Bar.percent(I.Inventory.health(inv), 90, 171, gfx,
      Bar.ammo.go(4n, 0, Bar.ammo.rows(), inv, gfx,
        Bar.num(3n, I.Inventory.rounds(ammo, inv), 44, 171, Bar.tall(), gfx, mem))))

# ST_drawWidgets' icons: the arms panel with its six weapon numbers, and
# the key slot of each colour.
def Bar.icons(+inv: I.Inventory, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Bar.keys.go(3n, 0, I.Inventory.cards(inv), gfx,
    Bar.arms.go(6n, 0, I.Inventory.weapons(inv), gfx,
      Bar.patch(G.Gfx.bar(gfx, Bar.arms()), 104, 168, mem)))

# Doom's ST_Drawer with the bar on: the background, then the widgets in
# ST_drawWidgets' order.
def Bar.draw(+inv: I.Inventory, ready: H.Thing.Weapon, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Bar.icons(inv, gfx,
    Bar.numbers(inv, H.Thing.Weapon.ammo(ready), gfx, Bar.patch(G.Gfx.bar(gfx, Bar.back()), 0, 168, mem)))

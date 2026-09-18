# A top-down view of the level around the player: the lines drawn into
# a 320 by 200 framebuffer, one-sided walls in white, two-sided lines in
# grey, the player as a yellow dot with a tick for its facing; then the
# framebuffer folded into the frame's quadtree, four pixels a cell, so
# the 1280 by 800 window shows Doom's resolution at a playable size.
# Throwaway: milestone 3's wall renderer replaces this module.
import Base
import ./vec.bend as V
import ./fixed.bend as F
import ./angle.bend as A
import ./level.bend as L
import ./sim.bend as S

def View.w() -> U32:
  320

def View.h() -> U32:
  200

# A pixel is four map units; the player is at the centre.
def View.sx(+px: U32, +x: U32) -> U32:
  (160 + F.Fixed.sarn((x - px : U32), 18n) : U32)

def View.sy(+py: U32, +y: U32) -> U32:
  (100 - F.Fixed.sarn((y - py : U32), 18n) : U32)

def View.plot.at(on: Bool, fb: Array<U32>, i: U32, c: U32) -> Array<U32>:
  match on:
    case False{}:
      fb
    case True{}:
      fb[i] <- c

# Plots a pixel when it is on the frame: a negative coordinate reads as
# a huge unsigned one, so one bound serves both ends.
def View.plot(fb: Array<U32>, +x: U32, +y: U32, c: U32) -> Array<U32>:
  View.plot.at(Bool.and(U32.is_lt(x, View.w()), U32.is_lt(y, View.h())), fb,
    (y * View.w() + x : U32), c)

def View.add_if(on: Bool, +v: U32, +d: U32) -> U32:
  Bool.pick(U32, on, (v + d : U32), v)

# Bresenham's line, n steps: dx and dy are the signed spans, sx and sy
# the signed steps.
def View.line.go(n: Nat, fb: Array<U32>, +x: U32, +y: U32, +dx: U32, +dy: U32,
  +sx: U32, +sy: U32, +err: U32, +c: U32) -> Array<U32>:
  match n:
    case 0n:
      View.plot(fb, x, y, c)
    case 1n+m:
      +e2 = (err << 1n : U32)
      +mx = F.Fixed.ge(e2, dy)
      +my = F.Fixed.le(e2, dx)
      View.line.go(m, View.plot(fb, x, y, c), View.add_if(mx, x, sx), View.add_if(my, y, sy),
        dx, dy, sx, sy, View.add_if(my, View.add_if(mx, err, dy), dx), c)

def View.span(+a: U32, +b: U32) -> U32:
  F.Fixed.abs((b - a : U32))

def View.dir(+a: U32, +b: U32) -> U32:
  Bool.pick(U32, F.Fixed.lt(a, b), 1, 4294967295)

def View.line(fb: Array<U32>, +x0: U32, +y0: U32, +x1: U32, +y1: U32, c: U32) ->
  Array<U32>:
  +dx = View.span(x0, x1)
  +dy = F.Fixed.neg(View.span(y0, y1))
  View.line.go(U32.to_nat(U32.max(dx, F.Fixed.neg(dy))), fb, x0, y0, dx, dy,
    View.dir(x0, x1), View.dir(y0, y1), (dx + dy : U32), c)

def View.color(back: U32) -> U32:
  Bool.pick(U32, U32.is_eq(back, L.Level.none()), 16777215, 8421504)

def View.draw(fb: Array<U32>, +px: U32, +py: U32, line: L.Level.Line) -> Array<U32>:
  L.Line{+x1, +y1, +x2, +y2, flags, front, back} = line
  View.line(fb, View.sx(px, x1), View.sy(py, y1), View.sx(px, x2), View.sy(py, y2),
    View.color(back))

# Every line of the level, drawn relative to the player.
def View.lines(n: Nat, fb: Array<U32>, +level: L.Level, +px: U32, +py: U32, +i: U32) ->
  Array<U32>:
  match n:
    case 0n:
      fb
    case 1n+m:
      View.lines(m, View.draw(fb, px, py, L.Level.line(level, i)), level, px, py,
        (i + 1 : U32))

# The player: a dot at the centre and a tick along its facing as long
# as its radius, so it never reaches past a wall the box stops at.
def View.player(fb: Array<U32>, +level: L.Level, +angle: U32) -> Array<U32>:
  +sine = L.Level.sine(level)
  +f = A.Angle.fine(angle)
  View.plot(View.line(fb, 160, 100,
    (160 + F.Fixed.sarn(F.Fixed.mul(262144, A.Angle.cos(sine, f)), 16n) : U32),
    (100 - F.Fixed.sarn(F.Fixed.mul(262144, A.Angle.sin(sine, f)), 16n) : U32),
    16776960), 160, 100, 16776960)

# The fold's work: a quadrant to visit (skipped when off the frame),
# or the join of the last four images into one.
type View.Task is Data:
  Visit{off: Bool, d: Nat, x: U32, y: U32}
  Join{}

type View.State is Type:
  State{fb: Array<U32>, tasks: List<&2, View.Task>, images: List<&2, Image>}

def View.off(+x: U32, +y: U32) -> Bool:
  Bool.or(U32.is_ge(x, 1280), U32.is_ge(y, 800))

def View.visit(+e: Nat, +x: U32, +y: U32) -> View.Task:
  Visit{View.off(x, y), e, x, y}

def View.leaf.fin(tasks: List<&2, View.Task>, images: List<&2, Image>, p: Array<U32> & U32) ->
  View.State:
  (fb, c) = p
  State{fb, tasks, Pix{c} <> images}

def View.leaf(fb: Array<U32>, +x: U32, +y: U32, tasks: List<&2, View.Task>,
  images: List<&2, Image>) -> View.State:
  View.leaf.fin(tasks, images, fb[(y >> 2n) * View.w() + (x >> 2n)])

def View.join(fb: Array<U32>, tasks: List<&2, View.Task>, images: List<&2, Image>) ->
  View.State:
  match images:
    case br <> bl <> tr <> tl <> rest:
      State{fb, tasks, Qua{tl, tr, bl, br} <> rest}
    case _:
      State{fb, tasks, images}

def View.done(images: List<&2, Image>) -> Image:
  match images:
    case []:
      Pix{0}
    case img <> rest:
      img

# The frame's quadtree from the framebuffer, with an explicit stack
# since the array has one owner: a quadrant of depth d covers 2^d
# pixels a side, a cell of depth 2 is one framebuffer pixel, and a
# quadrant off the framebuffer is one black pixel.
def View.fold(fuel: Nat, st: View.State) -> Array<U32> & Image:
  match fuel:
    case 0n:
      State{fb, tasks, images} = st
      (fb, View.done(images))
    case 1n+f:
      match st:
        case State{fb, [], images}:
          (fb, View.done(images))
        case State{fb, Join{} <> rest, images}:
          View.fold(f, View.join(fb, rest, images))
        case State{fb, Visit{True{}, d, x, y} <> rest, images}:
          View.fold(f, State{fb, rest, Pix{0} <> images})
        case State{fb, Visit{False{}, 0n, x, y} <> rest, images}:
          View.fold(f, State{fb, rest, Pix{0} <> images})
        case State{fb, Visit{False{}, 1n, x, y} <> rest, images}:
          View.fold(f, State{fb, rest, Pix{0} <> images})
        case State{fb, Visit{False{}, 2n, x, y} <> rest, images}:
          View.fold(f, View.leaf(fb, x, y, rest, images))
        case State{fb, Visit{False{}, 3n++e, +x, +y} <> rest, images}:
          +h = U32.shln(1, 2n+e)
          View.fold(f, State{fb, View.visit(2n+e, x, y) <> View.visit(2n+e, (x + h : U32), y)
            <> View.visit(2n+e, x, (y + h : U32)) <> View.visit(2n+e, (x + h : U32), (y + h : U32))
            <> Join{} <> rest, images})

# The frame: the level's lines and the player around the player.
def View.frame(+level: L.Level, +p: S.Player) -> Image:
  fb = [0 : U32^16n]
  fb2 = View.player(View.lines(U32.to_nat(L.Level.line_count(level)), fb, level,
    S.Player.x(p), S.Player.y(p), 0), level, S.Player.angle(p))
  Pair.snd(Array<U32>, Image, View.fold(U32.to_nat(200000),
    State{fb2, [View.visit(11n, 0, 0)], []}))

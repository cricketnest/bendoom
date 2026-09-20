# Doom's R_RenderPlayerView with the heads-up line HU_Drawer puts over
# it: a frame of the level from the player's eye, drawn into the array's
# frame as palette indices. A pure function of the tables, the graphics,
# the state and the array it redraws, so a frame renders in a test
# without a window; and the latest tic's state with no interpolation, as
# vanilla shows it.
import Base
import ./bytes.bend as B2
import ./level.bend as L
import ./gfx.bend as G
import ./sim.bend as S
import ./things.bend as H
import ./project.bend as P
import ./draw.bend as D
import ./bsp.bend as B
import ./planes.bend as N
import ./sprites.bend as T
import ./message.bend as Msg

def Render.eye(+tables: P.Project.Tables, +p: S.Player) -> P.View:
  P.View.make(tables, S.Player.x(p), S.Player.y(p), S.Player.viewz(p), S.Player.angle(p))

# After the walk, the planes, then the sprites of the things in the
# sectors it saw and the masked middle textures, in depth order.
def Render.rest(+view: P.View, +level: L.Level, +gfx: G.Gfx, things: List<&2, H.Thing>, st: D.Draw) ->
  Array<U32>:
  D.Draw{mem, solid, walls, tasks, planes, seen} = st
  T.Sprites.masked(things, seen, view, level, gfx, walls, N.Planes.draw(view, gfx, mem, planes))

# Doom's R_DrawPlayerSprites' light number: the player's sector's light.
def Render.light(+level: L.Level, +p: S.Player) -> U32:
  (L.Level.sector.light(level, L.Level.sector_at(level, S.Player.x(p), S.Player.y(p))) >> 4n : U32)

def Render.psprite(psp: S.Psprite, gfx: G.Gfx, lightnum: U32, mem: Array<U32>) -> Array<U32>:
  match psp:
    case S.Psprite{None{}, tics, sx, sy}:
      mem
    case S.Psprite{Some{state}, tics, sx, sy}:
      T.Sprites.psprite(gfx, state, sx, sy, lightnum, mem)

# Doom's R_DrawPlayerSprites: the weapon, then its flash, those that
# show, over the view.
def Render.psprites(ps: S.Psprites, +gfx: G.Gfx, +lightnum: U32, mem: Array<U32>) -> Array<U32>:
  S.Psprites{weapon, flash} = ps
  Render.psprite(flash, gfx, lightnum, Render.psprite(weapon, gfx, lightnum, mem))

def Render.view(+view: P.View, +level: L.Level, +gfx: G.Gfx, things: List<&2, H.Thing>, +p: S.Player,
  mem: Array<U32>) -> Array<U32>:
  Render.psprites(S.Player.psprites(p), gfx, Render.light(level, p),
    Render.rest(view, level, gfx, things, B.Bsp.walk(view, level, gfx, D.Draw.clear(mem))))

# The heads-up line
# -----------------

# The line so far: the array, the column the next character is drawn at,
# and whether the edge of the screen has stopped it.
type Render.Line is Type:
  Line{mem: Array<U32>, x: U32, done: Bool}

# HUlib_drawTextLine's test for a glyph that would run off the screen:
# it stops the line where it stands, undrawn.
def Render.line.fit(fits: Bool, +x: U32, w: U32, patch: U32, mem: Array<U32>) -> Render.Line:
  match fits:
    case False{}:
      Line{mem, x, True{}}
    case True{}:
      Line{D.Draw.patch(mem, patch, x, Msg.Message.y()), (x + w : U32), False{}}

def Render.line.wide(+x: U32, patch: U32, p: Array<U32> & U32) -> Render.Line:
  (mem, +w) = p
  Render.line.fit(U32.is_le((x + w : U32), 320), x, w, patch, mem)

# One character of HUlib_drawTextLine: a glyph is drawn and moves the
# line on by its patch's width, and a character without one moves it on
# by 4 and stops the line at the screen's edge.
def Render.line.char(g: Maybe<&2, U32>, +gfx: G.Gfx, +x: U32, mem: Array<U32>) -> Render.Line:
  match g:
    case None{}:
      Line{mem, (x + 4 : U32), U32.is_ge((x + 4 : U32), 320)}
    case Some{i}:
      +patch = G.Gfx.font(gfx, i)
      Render.line.wide(x, patch, B2.Bytes.u16(mem, patch))

def Render.line(text: String, +gfx: G.Gfx, st: Render.Line) -> Array<U32>:
  match text st:
    case SNil{} Line{mem, x, done}:
      mem
    case SCon{c, rest} Line{mem, x, True{}}:
      mem
    case SCon{c, rest} Line{mem, +x, False{}}:
      Render.line(rest, gfx, Render.line.char(Msg.Message.glyph(c), gfx, x, mem))

# Doom's HU_Drawer: the message line in the WAD's font at HU_MSGX,
# HU_MSGY, over the view, while the line is on. A frame drawn with
# messages off shows none, as vanilla's show_messages 0 does.
def Render.messages(on: Bool, +gfx: G.Gfx, n: U32, mem: Array<U32>) -> Array<U32>:
  match on:
    case False{}:
      mem
    case True{}:
      Render.line(Msg.Message.text(n), gfx, Line{mem, Msg.Message.x(), False{}})

# The sectors' heights and light come from the state's level, the
# sides' textures from the state, and the animations' frames and the
# walls' scroll from its clock. The heads-up line is drawn last, as
# D_Display draws it over the view, when messages are asked for and one
# is up.
def Render.frame(tables: P.Project.Tables, +gfx: G.Gfx, +s: S.State, messages: Bool, mem: Array<U32>) ->
  Array<U32>:
  Render.messages(Bool.and(messages, Bool.not(U32.is_zero(S.State.msgtics(s)))), gfx, S.State.message(s),
    Render.view(Render.eye(tables, S.State.player(s)), S.State.level(s),
      G.Gfx.of_state(gfx, S.State.sidetex(s), S.State.clock(s)), H.Things.list(S.State.things(s)),
      S.State.player(s), mem))

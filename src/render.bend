# Doom's R_RenderPlayerView: a frame of the level from the player's eye,
# drawn into the array's frame as palette indices. A pure function of
# the tables, the graphics, the state and the array it redraws, so a
# frame renders in a test without a window; and the latest tic's state
# with no interpolation, as vanilla shows it.
import Base
import ./level.bend as L
import ./gfx.bend as G
import ./sim.bend as S
import ./things.bend as H
import ./project.bend as P
import ./draw.bend as D
import ./bsp.bend as B
import ./planes.bend as N
import ./sprites.bend as T

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

# The sectors' heights and light come from the state's level, the
# sides' textures from the state, and the animations' frames and the
# walls' scroll from its clock.
def Render.frame(tables: P.Project.Tables, gfx: G.Gfx, +s: S.State, mem: Array<U32>) -> Array<U32>:
  Render.view(Render.eye(tables, S.State.player(s)), S.State.level(s),
    G.Gfx.of_state(gfx, S.State.sidetex(s), S.State.clock(s)), H.Things.shown(S.State.things(s)),
    S.State.player(s), mem)

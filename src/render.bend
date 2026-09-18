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
import ./masked.bend as M
import ./sprites.bend as T

def Render.eye(+tables: P.Project.Tables, +p: S.Player) -> P.View:
  P.View.make(tables, S.Player.x(p), S.Player.y(p), S.Player.viewz(p), S.Player.angle(p))

# After the walk, the planes, then the sprites of the things in the
# sectors it saw, then the masked middle textures over them all.
def Render.rest(+view: P.View, +level: L.Level, +gfx: G.Gfx, things: List<&2, H.Thing>, st: D.Draw) ->
  Array<U32>:
  D.Draw{mem, solid, +walls, tasks, planes, seen} = st
  M.Masked.draw(walls, view, level, gfx, T.Sprites.draw(T.Sprites.gather(things, seen, view, level, gfx), walls,
    level, N.Planes.draw(view, gfx, mem, planes)))

def Render.view(+view: P.View, +level: L.Level, +gfx: G.Gfx, things: List<&2, H.Thing>, mem: Array<U32>) ->
  Array<U32>:
  Render.rest(view, level, gfx, things, B.Bsp.walk(view, level, gfx, D.Draw.clear(mem)))

# The sectors' heights and light come from the state's level, the
# sides' textures from the state, and the animations' frames and the
# walls' scroll from its clock.
def Render.frame(tables: P.Project.Tables, gfx: G.Gfx, +s: S.State, mem: Array<U32>) -> Array<U32>:
  Render.view(Render.eye(tables, S.State.player(s)), S.State.level(s),
    G.Gfx.of_state(gfx, S.State.sidetex(s), S.State.clock(s)), S.State.things(s), mem)

# Doom's R_RenderPlayerView: a frame of the level from the player's eye,
# drawn into the array's frame as palette indices. A pure function of
# the tables, the level, the graphics, the player and the array it
# redraws, so a frame renders in a test without a window; and the
# latest tic's state with no interpolation, as vanilla shows it.
import Base
import ./level.bend as L
import ./gfx.bend as G
import ./sim.bend as S
import ./project.bend as P
import ./draw.bend as D
import ./bsp.bend as B
import ./planes.bend as N

def Render.eye(+tables: P.Project.Tables, +p: S.Player) -> P.View:
  P.View.make(tables, S.Player.x(p), S.Player.y(p), S.Player.viewz(p), S.Player.angle(p))

# The planes after the walk, as Doom draws them.
def Render.planes(+view: P.View, +gfx: G.Gfx, st: D.Draw) -> Array<U32>:
  D.Draw{mem, solid, walls, tasks, planes} = st
  N.Planes.draw(view, gfx, mem, planes)

def Render.view(+view: P.View, +level: L.Level, +gfx: G.Gfx, mem: Array<U32>) -> Array<U32>:
  Render.planes(view, gfx, B.Bsp.walk(view, level, gfx, D.Draw.clear(mem)))

def Render.frame(tables: P.Project.Tables, level: L.Level, gfx: G.Gfx, p: S.Player, mem: Array<U32>) ->
  Array<U32>:
  Render.view(Render.eye(tables, p), level, gfx, mem)

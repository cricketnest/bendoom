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

def Render.eye(+tables: P.Project.Tables, +p: S.Player) -> P.View:
  P.View.make(tables, S.Player.x(p), S.Player.y(p), S.Player.viewz(p), S.Player.angle(p))

def Render.mem(st: D.Draw) -> Array<U32>:
  D.Draw{mem, solid, walls, tasks} = st
  mem

# The view's 168 rows are blanked first, until the planes draw.
def Render.frame(tables: P.Project.Tables, +level: L.Level, +gfx: G.Gfx, p: S.Player,
  mem: Array<U32>) -> Array<U32>:
  Render.mem(B.Bsp.walk(Render.eye(tables, p), level, gfx,
    D.Draw.clear(D.Draw.set(U32.to_nat(53760), mem, G.Gfx.frame(), 0))))

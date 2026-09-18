# The draw's state: the one linear array and the lists Doom keeps in
# static arrays, here with no limit. One value threaded through the BSP
# walk, since every step reads what the last wrote.
import Base
import ./clip.bend as C

# The walk's work, a stack: a node or subsector to visit, a node's far
# child to visit if its box might show, a seg to add.
type Draw.Task is Data:
  Visit{node: U32}
  Check{node: U32, side: U32}
  Line{seg: U32}

# A stored wall range, Doom's drawseg: the seg, its first and last
# column, and its scale at each with the step between.
type Draw.Wall is Data:
  Wall{seg: U32, x1: U32, x2: U32, scale1: U32, scale2: U32, step: U32}

# mem: the frame, the clip arrays and the graphics. solid: the solid
# columns. walls: the stored ranges, newest first. tasks: the walk's
# stack.
type Draw is Type:
  Draw{mem: Array<U32>, solid: List<&2, C.Clip.Range>, walls: List<&2, Draw.Wall>,
    tasks: List<&2, Draw.Task>}

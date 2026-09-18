# Doom's P_Random: the playsim's random numbers, one table and an index.
import Base
import ./vec.bend as V
import ./tables.bend as T

# P_Random steps its index, then answers the table's entry there.
def Random.next(rnd: U32) -> U32:
  ((rnd + 1 : U32) .&. 255 : U32)

def Random.at(i: U32) -> U32:
  V.Vec.get(V.Vec.of_list(T.Tables.rndtable(), 256), i)

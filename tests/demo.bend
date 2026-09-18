# A demo's bytes, the turn carried after them, and the commands read
# back from them. Each expected value was worked out by hand from
# Chocolate Doom's G_BuildTiccmd, which when recording rounds the turn
# plus the carry to (t + 128) & 0xff00 and carries the rest, and
# linuxdoom-1.10's G_WriteDemoTiccmd and G_ReadDemoTiccmd, which write
# forward, side, the turn's high byte and the buttons, and read the turn
# back as that byte << 8. So from no carry the walk's 640 turns 768, 512,
# 768 left, carrying -128, and -512, -768, -512 right, carrying -128;
# the slow 320 turns 256, 512, 256, 256, carrying none; the run's 1280
# stays. Side -40 is the byte 216. The end marker, 0x80 where a tic's
# forward byte would be, ends the read, and so does a tic cut short.
import Base
import ../src/keys.bend as K
import ../src/demo.bend as D

def int(+x: U32) -> String:
  Bool.pick(String, U32.is_lt(x, 2147483648), U32.show(x), "-" ++ U32.show((0 - x : U32)))

def bytes(xs: List<&2, U32>) -> String:
  match xs:
    case []:
      ""
    case x <> rest:
      " " ++ U32.show(x) ++ bytes(rest)

def cmds(xs: List<&2, K.Cmd>) -> String:
  match xs:
    case []:
      ""
    case K.Cmd{+forward, +side, +turn, use} <> rest:
      " " ++ int(forward) ++ "," ++ int(side) ++ "," ++ int(turn) ++ "," ++ Bool.show(use) ++ cmds(rest)

def recorded(tag: String, p: List<&2, U32> & U32) -> String:
  (+tics, carry) = p
  tag ++ bytes(tics) ++ " | carry " ++ int(carry) ++ " | read" ++ cmds(D.Demo.cmds(tics))

def turns(n: Nat, turn: U32) -> List<&2, K.Cmd>:
  List.replicate(K.Cmd, n, K.Cmd{0, 0, turn, False{}})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print("header" ++ bytes(D.Demo.header()))
    IO.print(recorded("left", D.Demo.tics(K.Cmd{50, (0 - 40 : U32), 640, True{}} <> turns(2n, 640), 0)))
    IO.print(recorded("right", D.Demo.tics(K.Cmd{(0 - 25 : U32), 24, (0 - 640 : U32), False{}}
      <> turns(2n, (0 - 640 : U32)), 0)))
    IO.print(recorded("slow", D.Demo.tics(turns(4n, 320), 0)))
    IO.print(recorded("run", D.Demo.tics(turns(2n, (0 - 1280 : U32)), 0)))
    IO.print("marker" ++ cmds(D.Demo.cmds([50, 0, 0, 0, 128, 0, 0, 0, 25, 0, 0, 0])))
    IO.print("cut" ++ cmds(D.Demo.cmds([50, 0, 0, 0, 25, 0, 0])))

#|header 109 2 1 1 0 0 0 1 0 1 0 0 0
#|left 50 216 3 2 0 0 2 0 0 0 3 0 | carry -128 | read 50,-40,768,True 0,0,512,False 0,0,768,False
#|right 231 24 254 0 0 0 253 0 0 0 254 0 | carry -128 | read -25,24,-512,False 0,0,-768,False 0,0,-512,False
#|slow 0 0 1 0 0 0 2 0 0 0 1 0 0 0 1 0 | carry 0 | read 0,0,256,False 0,0,512,False 0,0,256,False 0,0,256,False
#|run 0 0 251 0 0 0 251 0 | carry 0 | read 0,0,-1280,False 0,0,-1280,False
#|marker 50,0,0,False
#|cut 50,0,0,False

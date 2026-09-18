# Where a script leaves the sim: E1M1 from the WAD named by BENDOOM_IWAD,
# the player put at the place FRAME names, and after each run of SCRIPT
# (tools/script.bend has both forms) a line of the tics run so far, the
# player's position, facing, height, floor and eye, and the floor and
# ceiling of each sector SECTORS lists. How routes and movers' tics are
# found for the tests and the oracle.
#
#   bend tools/walk.bend -o walk
#   FRAME="-416 256 0" SCRIPT="34,50,0,0,0 1,0,0,0,1" SECTORS="10 98" ./walk
import Base
import ../src/bytes.bend as B
import ../src/wad.bend as W
import ../src/vec.bend as V
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/keys.bend as K
import ../src/sim.bend as S
import ./script.bend as T

def Walk.named(name: String) -> Bool:
  Bool.not(String.is_empty(name))

def Walk.sectors(which: List<&2, String>, +level: L.Level) -> String:
  match which:
    case []:
      ""
    case name <> rest:
      +s = T.Script.int(name)
      " | " ++ U32.show(s) ++ " " ++ F.Fixed.show(L.Level.floor(level, s)) ++ " "
        ++ F.Fixed.show(L.Level.ceil(level, s)) ++ Walk.sectors(rest, level)

def Walk.line(+which: List<&2, String>, +s: S.State) -> String:
  +p = S.State.player(s)
  "tic " ++ U32.show(S.State.clock(s)) ++ " at " ++ F.Fixed.show(S.Player.x(p)) ++ " "
    ++ F.Fixed.show(S.Player.y(p)) ++ " " ++ A.Angle.show(S.Player.angle(p)) ++ " z "
    ++ F.Fixed.show(S.Player.z(p)) ++ " floor " ++ F.Fixed.show(S.Player.floorz(p)) ++ " eye "
    ++ F.Fixed.show((S.Player.viewz(p) - S.Player.floorz(p) : U32)) ++ " ended "
    ++ Bool.show(S.State.ended(s)) ++ Walk.sectors(which, S.State.level(s))

def Walk.go(runs: List<&2, List<&2, K.Cmd>>, +which: List<&2, String>, +s: S.State) -> IO(Unit):
  match runs:
    case []:
      IO.print(Walk.line(which, s))
    case run <> rest:
      do IO<Unit>:
        IO.print(Walk.line(which, s))
        Walk.go(rest, which, S.Sim.replay(run, s))

def Walk.start(place: L.Level.Start, runs: List<&2, List<&2, K.Cmd>>, which: List<&2, String>,
  p: Array<U32> & L.Level) -> IO(Unit):
  (a, +level) = p
  Walk.go(runs, which, S.State.at(level, place))

def main() -> IO(Unit):
  do IO<Unit>:
    path : String <- IO.try(String, IO.get_env("BENDOOM_IWAD"))
    spot : String <- IO.try(String, IO.get_env("FRAME"))
    script : String <- IO.try(String, IO.get_env("SCRIPT"))
    sectors : Result<&1, &1, U32 & String, String> <- IO.get_env("SECTORS")
    bytes : Array<U32> <- IO.try(Array<U32>, B.Bytes.read(path))
    Walk.start(T.Script.place(String.split(spot, ' ')), T.Script.runs(String.split(script, ' ')),
      List.filter(~String, ~Walk.named, String.split(Result.default(&1, &1, U32 & String, String, sectors, ""), ' ')),
      L.Level.load(W.Wad.dir(bytes)))

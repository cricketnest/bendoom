# The held keys and the tic command built from them, as Doom's
# G_BuildTiccmd: the forward and side moves and the turn, from the walk
# and run tables, with the six-tic slow turn, and the use button.
import Base

type Keys is Data:
  Keys{up: Bool, down: Bool, left: Bool, right: Bool, sleft: Bool,
    sright: Bool, run: Bool, use: Bool}

# forward and side in Doom's units (times 2048 is the thrust), turn in
# Doom's angleturn units (times 65536 is the angle), and the use button.
type Cmd is Data:
  Cmd{forward: U32, side: U32, turn: U32, use: Bool}

def Keys.none() -> Keys:
  Keys{False{}, False{}, False{}, False{}, False{}, False{}, False{}, False{}}

def Cmd.idle() -> Cmd:
  Cmd{0, 0, 0, False{}}

def Cmd.use(cmd: Cmd) -> Bool:
  Cmd{forward, side, turn, use} = cmd
  use

# A command in a demo file's units: the moves as they are, the turn in
# steps of 256, the byte a demo keeps of it.
def Cmd.demo(forward: U32, side: U32, turn: U32, use: Bool) -> Cmd:
  Cmd{forward, side, (turn << 8n : U32), use}

def Keys.set(on: Bool, down: Bool, old: Bool) -> Bool:
  match on:
    case True{}:
      down
    case False{}:
      old

# The runtime's key codes: arrows 63232 up, 63233 down, 63234 left,
# 63235 right; letters lower case; Shift 65592 and 65596; Space 32.
def Keys.press(+code: U32, +down: Bool, keys: Keys) -> Keys:
  Keys{up, dn, left, right, sleft, sright, run, use} = keys
  Keys{Keys.set(U32.is_eq(code, 63232) || U32.is_eq(code, 119), down, up),
    Keys.set(U32.is_eq(code, 63233) || U32.is_eq(code, 115), down, dn),
    Keys.set(U32.is_eq(code, 63234), down, left),
    Keys.set(U32.is_eq(code, 63235), down, right),
    Keys.set(U32.is_eq(code, 97), down, sleft),
    Keys.set(U32.is_eq(code, 100), down, sright),
    Keys.set(U32.is_eq(code, 65592) || U32.is_eq(code, 65596), down, run),
    Keys.set(U32.is_eq(code, 32), down, use)}

def Keys.if(c: Bool, v: U32) -> U32:
  match c:
    case True{}:
      v
    case False{}:
      0

# Doom's forwardmove {25, 50}, sidemove {24, 40} and angleturn
# {640, 1280, 320}: index 1 when running, 2 the slow turn.
def Keys.forward(run: Bool) -> U32:
  Bool.pick(U32, run, 50, 25)

def Keys.side(run: Bool) -> U32:
  Bool.pick(U32, run, 40, 24)

def Keys.turn(run: Bool, slow: Bool) -> U32:
  Bool.pick(U32, slow, 320, Bool.pick(U32, run, 1280, 640))

# The command for held keys, with the tics the turn keys have been
# held, this one included: the first five turn slowly. Opposite keys
# cancel out, in U32's wrapping arithmetic.
def Keys.cmd(keys: Keys, +turnheld: U32) -> Cmd:
  Keys{up, down, left, right, sleft, sright, +run, use} = keys
  +slow = U32.is_lt(turnheld, 6)
  Cmd{(Keys.if(up, Keys.forward(run)) - Keys.if(down, Keys.forward(run)) : U32),
    (Keys.if(sright, Keys.side(run)) - Keys.if(sleft, Keys.side(run)) : U32),
    (Keys.if(left, Keys.turn(run, slow)) - Keys.if(right, Keys.turn(run, slow)) : U32), use}

# The turn keys' held count after a tic: one more while either is held.
def Keys.held(keys: Keys, turnheld: U32) -> U32:
  Keys{up, down, left, right, sleft, sright, run, use} = keys
  Bool.pick(U32, Bool.or(left, right), (turnheld + 1 : U32), 0)

# What G_BuildTiccmd reads: the held keys and the turn keys' held count.
type Input is Data:
  Input{keys: Keys, turnheld: U32}

def Input.press(code: U32, down: Bool, input: Input) -> Input:
  Input{keys, turnheld} = input
  Input{Keys.press(code, down, keys), turnheld}

# The input a tic later, the keys still held.
def Input.tic(input: Input) -> Input:
  Input{+keys, turnheld} = input
  Input{keys, Keys.held(keys, turnheld)}

def Input.cmd(input: Input) -> Cmd:
  Input{keys, turnheld} = input
  Keys.cmd(keys, turnheld)

def Input.after(n: Nat, input: Input) -> Input:
  match n:
    case 0n:
      input
    case 1n+m:
      Input.after(m, Input.tic(input))

# The commands of n tics of the same held keys.
def Input.script(n: Nat, input: Input) -> List<&2, Cmd>:
  match n:
    case 0n:
      []
    case 1n+m:
      +next = Input.tic(input)
      Input.cmd(next) <> Input.script(m, next)

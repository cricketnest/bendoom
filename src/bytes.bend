# A file as one flat Array<U32>, one byte per slot (Base's File.read_bytes
# answers a List, one cell per byte), and little-endian readers over it.
# A read hands the array back beside the byte, and a pair from a call can
# only be taken apart by a helper, so each reader is a chain of them.
import Base

# The bytes, sized up to a power of two, zero past the end.
def Bytes.read(path: String) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  import "./effs/bytes_read.c"
  import "./effs/bytes_read.js"

# The low byte of each cell to an open file: Base writes only text, as
# UTF-8.
def Bytes.write(file: File, bytes: List<&2, U32>) -> IO(File & Result<&1, &1, U32 & String, Unit>):
  import "./effs/bytes_write.c"
  import "./effs/bytes_write.js"

def Bytes.put.done(p: File & Result<&1, &1, U32 & String, Unit>) -> IO(File):
  (file, done) = p
  IO.bind(Unit, File, IO.pass(Unit, done), u => IO.pure(File, file))

# The bytes written, or the program dies with the error.
def Bytes.put(file: File, bytes: List<&2, U32>) -> IO(File):
  IO.bind(File & Result<&1, &1, U32 & String, Unit>, File, Bytes.write(file, bytes), Bytes.put.done)

def Bytes.at(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  a[i]

def Bytes.le32(+b0: U32, +b1: U32, +b2: U32, +b3: U32) -> U32:
  (b0 .|. (b1 << 8n) .|. (b2 << 16n) .|. (b3 << 24n) : U32)

def Bytes.le16(+b0: U32, +b1: U32) -> U32:
  (b0 .|. (b1 << 8n) : U32)

def Bytes.u32.fin(b0: U32, b1: U32, b2: U32, p: Array<U32> & U32) ->
  Array<U32> & U32:
  (a, b3) = p
  (a, Bytes.le32(b0, b1, b2, b3))

def Bytes.u32.b3(+i: U32, b0: U32, b1: U32, p: Array<U32> & U32) ->
  Array<U32> & U32:
  (a, b2) = p
  Bytes.u32.fin(b0, b1, b2, Bytes.at(a, (i + 3 : U32)))

def Bytes.u32.b2(+i: U32, b0: U32, p: Array<U32> & U32) ->
  Array<U32> & U32:
  (a, b1) = p
  Bytes.u32.b3(i, b0, b1, Bytes.at(a, (i + 2 : U32)))

def Bytes.u32.b1(+i: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, b0) = p
  Bytes.u32.b2(i, b0, Bytes.at(a, (i + 1 : U32)))

def Bytes.u32(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.u32.b1(i, Bytes.at(a, i))

def Bytes.u16.fin(b0: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, b1) = p
  (a, Bytes.le16(b0, b1))

def Bytes.u16.b1(+i: U32, p: Array<U32> & U32) -> Array<U32> & U32:
  (a, b0) = p
  Bytes.u16.fin(b0, Bytes.at(a, (i + 1 : U32)))

def Bytes.u16(a: Array<U32>, +i: U32) -> Array<U32> & U32:
  Bytes.u16.b1(i, Bytes.at(a, i))

def Bytes.text.cut(z: Bool, c: U32, rest: List<&2, Char>) -> List<&2, Char>:
  match z:
    case True{}:
      []
    case False{}:
      Char.from_u32(c) <> rest

def Bytes.text.cons(+c: U32, rest: List<&2, Char>) -> List<&2, Char>:
  Bytes.text.cut(U32.is_zero(c), c, rest)

def Bytes.text.join(rest: List<&2, Char>, q: Array<U32> & U32) ->
  Array<U32> & List<&2, Char>:
  (a, c) = q
  (a, Bytes.text.cons(c, rest))

def Bytes.text.read(+i: U32, p: Array<U32> & List<&2, Char>) ->
  Array<U32> & List<&2, Char>:
  (a, rest) = p
  Bytes.text.join(rest, Bytes.at(a, i))

# The bytes after i are gathered first, then the byte at i is consed on:
# a loop over a linear array recurses before it reads, and the shrinking
# count goes first, or the termination checker refuses it.
def Bytes.text.go(n: Nat, a: Array<U32>, +i: U32) ->
  Array<U32> & List<&2, Char>:
  match n:
    case 0n:
      (a, [])
    case 1n+m:
      Bytes.text.read(i, Bytes.text.go(m, a, (i + 1 : U32)))

def Bytes.text.pack(p: Array<U32> & List<&2, Char>) -> Array<U32> & String:
  (a, cs) = p
  (a, String.from_list(cs))

# The n bytes at i as a string, cut at the first NUL.
def Bytes.text(a: Array<U32>, +i: U32, n: Nat) -> Array<U32> & String:
  Bytes.text.pack(Bytes.text.go(n, a, i))

def Bytes.name.up(p: Array<U32> & String) -> Array<U32> & String:
  (a, s) = p
  (a, String.to_upper(s))

# A lump, texture or flat name: eight bytes, matched without case as
# Doom matches them, so read in upper case.
def Bytes.name(a: Array<U32>, +i: U32) -> Array<U32> & String:
  Bytes.name.up(Bytes.text(a, i, 8n))

def Bytes.each.join(~T: Data, rest: List<&2, T>, q: Array<U32> & T) ->
  Array<U32> & List<&2, T>:
  (a, x) = q
  (a, x <> rest)

def Bytes.each.cons(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T, i: U32,
  p: Array<U32> & List<&2, T>) -> Array<U32> & List<&2, T>:
  (a, rest) = p
  Bytes.each.join(~T, rest, read(a, i))

# One read at each offset, the later offsets first so the list comes
# out in order: every lump is read by planning its offsets, then this.
def Bytes.each(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T, offs: List<&2, U32>,
  a: Array<U32>) -> Array<U32> & List<&2, T>:
  match offs:
    case []:
      (a, [])
    case i <> rest:
      Bytes.each.cons(~T, ~read, i, Bytes.each(~T, ~read, rest, a))

def Bytes.fields.one(fields: List<&2, U32>, +i: U32, tail: List<&2, U32>) -> List<&2, U32>:
  match fields:
    case []:
      tail
    case f <> rest:
      (i + f : U32) <> Bytes.fields.one(rest, i, tail)

# The offsets of the given fields in each of n records of stride bytes
# from i, record by record.
def Bytes.fields(n: Nat, +i: U32, +stride: U32, +fields: List<&2, U32>) -> List<&2, U32>:
  match n:
    case 0n:
      []
    case 1n+m:
      Bytes.fields.one(fields, i, Bytes.fields(m, (i + stride : U32), stride, fields))

def Bytes.lists.join(~T: Data, rest: List<&2, List<&2, T>>, q: Array<U32> & List<&2, T>) ->
  Array<U32> & List<&2, List<&2, T>>:
  (a, xs) = q
  (a, xs <> rest)

def Bytes.lists.cons(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T, offs: List<&2, U32>,
  p: Array<U32> & List<&2, List<&2, T>>) -> Array<U32> & List<&2, List<&2, T>>:
  (a, rest) = p
  Bytes.lists.join(~T, rest, Bytes.each(~T, ~read, offs, a))

# Bytes.each over each plan of a list, a list of reads a plan.
def Bytes.lists(~T: Data, ~read: Array<U32> -> @+i: U32 -> Array<U32> & T,
  plans: List<&2, List<&2, U32>>, a: Array<U32>) -> Array<U32> & List<&2, List<&2, T>>:
  match plans:
    case []:
      (a, [])
    case offs <> rest:
      Bytes.lists.cons(~T, ~read, offs, Bytes.lists(~T, ~read, rest, a))

# A long run of bytes as a list, read from its last byte back to its
# first by a loop whose body is not recursive, so the run's length is no
# recursion depth on the JS lane.
type Bytes.Run is Type:
  Run{a: Array<U32>, i: U32, acc: List<&2, U32>}

def Bytes.run.put(+i: U32, acc: List<&2, U32>, p: Array<U32> & U32) -> Bytes.Run:
  (a, b) = p
  Run{a, (i - 1 : U32), b <> acc}

def Bytes.run.step(r: Bytes.Run) -> Bytes.Run:
  Run{a, +i, acc} = r
  Bytes.run.put(i, acc, Bytes.at(a, i))

def Bytes.run.go(n: Nat, r: Bytes.Run) -> Bytes.Run:
  match n:
    case 0n:
      r
    case 1n+m:
      Bytes.run.go(m, Bytes.run.step(r))

def Bytes.run.fin(r: Bytes.Run) -> Array<U32> & List<&2, U32>:
  Run{a, i, acc} = r
  (a, acc)

# The n bytes at i.
def Bytes.list(a: Array<U32>, +i: U32, +n: U32) -> Array<U32> & List<&2, U32>:
  Bytes.run.fin(Bytes.run.go(U32.to_nat(n), Run{a, (i + n - 1 : U32), []}))

# A file as one flat Array<U32>, one byte per slot (Base's File.read_bytes
# answers a List, one cell per byte), and little-endian readers over it.
# A read hands the array back beside the byte, and a pair from a call can
# only be taken apart by a helper, so each reader is a chain of them.
import Base

# The bytes, sized up to a power of two, zero past the end.
def Bytes.read(path: String) -> IO(Result<&1, &1, U32 & String, Array<U32>>):
  import "./effs/bytes_read.c"
  import "./effs/bytes_read.js"

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

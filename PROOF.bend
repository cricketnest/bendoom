# The proofs: every law in LAWS.bend, filled. `bend PROOF.bend` is the
# gate; it fails while any law is open or false.
import Base
import ./src/bytes.bend as B
import ./src/wad.bend as W
import ./LAWS.bend as Laws

def Laws.text_nul_ends(rest):
  {==}

def Laws.text_byte_kept(rest):
  {==}

def Laws.le32_bytes():
  {==}

def Laws.wad_kinds():
  {==}

# A comparison of a value with itself answers EQ, from a bit up to a
# string; stated value first so a rewrite replaces the comparison in a
# goal by its answer.

def bool_cmp_refl(b: Bool) -> {EQ{} == Bool.cmp(b, b) : Cmp}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def word_cmp_refl(n: Nat, w: Word(n)) -> {EQ{} == Word.cmp(n, w, w) : Cmp}:
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{hb, ht}:
          %word_cmp_refl(p, ht) : {EQ{} == Word.cmp.fin(hb, hb, _) : Cmp}
          %bool_cmp_refl(hb) : {EQ{} == _ : Cmp}
          {==}

def u32_cmp_refl(x: U32) -> {EQ{} == U32.cmp(x, x) : Cmp}:
  match x:
    case U32{w}:
      word_cmp_refl(32n, w)

def char_cmp_refl(c: Char) ->
  {((c, c), EQ{}) == Char.cmp(c, c) : (Char & Char) & Cmp}:
  match c:
    case Chr{x}:
      %u32_cmp_refl(x)
        : {((Chr{x}, Chr{x}), EQ{}) == ((Chr{x}, Chr{x}), _) : (Char & Char) & Cmp}
      {==}

def string_cmp_refl(s: String) ->
  {((s, s), EQ{}) == String.cmp(s, s) : (String & String) & Cmp}:
  match s:
    case SNil{}:
      {==}
    case SCon{h, t}:
      %char_cmp_refl(h)
        : {((SCon{h, t}, SCon{h, t}), EQ{}) == String.cmp.fin(t, t, _) : (String & String) & Cmp}
      %string_cmp_refl(t)
        : {((SCon{h, t}, SCon{h, t}), EQ{}) == String.cmp.rec(h, h, _) : (String & String) & Cmp}
      {==}

def string_eq_refl(s: String) -> {True{} == String.eq(s, s) : Bool}:
  %string_cmp_refl(s) : {True{} == String.eq.fin(_) : Bool}
  {==}

def Laws.index_head(name, pos, size, rest):
  %string_eq_refl(name)
    : {W.Wad.index.pick(_, W.Wad.index(name, rest)) == Some{0n} : Maybe<Nat>}
  {==}

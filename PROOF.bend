# The proofs: every law in LAWS.bend, filled. `bend PROOF.bend` is the
# gate; it fails while any law is open or false.
import Base
import ./src/bytes.bend as B
import ./src/wad.bend as W
import ./src/vec.bend as V
import ./src/fixed.bend as F
import ./src/angle.bend as A
import ./src/tables.bend as T
import ./src/level.bend as L
import ./src/keys.bend as K
import ./src/random.bend as M
import ./src/sound.bend as Sn
import ./src/sim.bend as S
import ./src/things.bend as H
import ./src/inventory.bend as I
import ./src/clip.bend as C
import ./src/project.bend as P
import ./src/draw.bend as D
import ./src/segs.bend as R
import ./src/planes.bend as N
import ./src/midi.bend as Mi
import ./src/player.bend as Pl
import ./src/song.bend as Sg
import ./LAWS.bend as Laws

# Closed laws compute.

def Laws.text_nul_ends(rest):
  {==}

def Laws.text_byte_kept(rest):
  {==}

def Laws.le32_bytes():
  {==}

def Laws.wad_kinds():
  {==}

def Laws.vec_of_list():
  {==}

def Laws.fixed_of_map():
  {==}

def Laws.fixed_order():
  {==}

def Laws.fixed_mul_signs():
  {==}

def Laws.fixed_mul_overflow():
  {==}

def Laws.fixed_mul_one():
  {==}

def Laws.fixed_div():
  {==}

def Laws.fine_quarter():
  {==}

def Laws.tables_vanilla():
  {==}

def Laws.angle_of_axes():
  {==}

def Laws.sprite_rotation():
  {==}

def Laws.cmd_tables():
  {==}

def Laws.turn_script():
  {==}

def Laws.line_geometry():
  {==}

def Laws.solid_clips():
  {==}

def Laws.view_edges():
  {==}

def Laws.view_sweep():
  {==}

def Laws.view_rows():
  {==}

def Laws.wall_scale():
  {==}

def Laws.light_tables():
  {==}

def Laws.wall_column():
  {==}

def Laws.silhouettes():
  {==}

def Laws.sprite_columns():
  {==}

def Laws.sprite_order():
  {==}

def Laws.plane_span():
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

# Keys: a key's flag set twice keeps the second setting; the twelve
# flags are rewritten one by one, abstracted from the key code.

def set_twice(b: Bool, +d1: Bool, +d2: Bool, +old: Bool) ->
  {K.Keys.set(b, d2, old) == K.Keys.set(b, d2, K.Keys.set(b, d1, old)) : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def press12(b1: Bool, b2: Bool, b3: Bool, b4: Bool, b5: Bool, b6: Bool, b7: Bool, b8: Bool, b9: Bool,
  b10: Bool, b11: Bool, b12: Bool, +d1: Bool, +d2: Bool, +up: Bool, +dn: Bool, +left: Bool, +right: Bool,
  +sleft: Bool, +sright: Bool, +run: Bool, +use: Bool, +fire: Bool, +one: Bool, +two: Bool, +three: Bool) ->
  {K.Keys{K.Keys.set(b1, d2, K.Keys.set(b1, d1, up)), K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)),
    K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
    K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
    K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
    K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)),
    K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)), K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
    == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
      K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}:
  %set_twice(b1, d1, d2, up)
    : {K.Keys{_, K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)), K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)),
      K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)), K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)),
      K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)),
      K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)), K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)),
      K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)), K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)),
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b2, d1, d2, dn)
    : {K.Keys{K.Keys.set(b1, d2, up), _, K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)),
      K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)), K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)),
      K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)),
      K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)), K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)),
      K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)), K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)),
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b3, d1, d2, left)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), _,
      K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)), K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)),
      K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)),
      K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)), K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)),
      K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)), K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)),
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b4, d1, d2, right)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), _,
      K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)),
      K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)), K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b5, d1, d2, sleft)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), _, K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
      K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)),
      K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)), K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)),
      K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)), K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b6, d1, d2, sright)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), _, K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)),
      K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)), K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)),
      K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)), K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)),
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b7, d1, d2, run)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), _,
      K.Keys.set(b8, d2, K.Keys.set(b8, d1, use)), K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)),
      K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)), K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)),
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b8, d1, d2, use)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), _, K.Keys.set(b9, d2, K.Keys.set(b9, d1, fire)),
      K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)), K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)),
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b9, d1, d2, fire)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), _, K.Keys.set(b10, d2, K.Keys.set(b10, d1, one)),
      K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)), K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b10, d1, d2, one)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), _,
      K.Keys.set(b11, d2, K.Keys.set(b11, d1, two)), K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b11, d1, d2, two)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one), _,
      K.Keys.set(b12, d2, K.Keys.set(b12, d1, three))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  %set_twice(b12, d1, d2, three)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
      K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
      K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
      K.Keys.set(b11, d2, two), _}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left),
        K.Keys.set(b4, d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright),
        K.Keys.set(b7, d2, run), K.Keys.set(b8, d2, use), K.Keys.set(b9, d2, fire), K.Keys.set(b10, d2, one),
        K.Keys.set(b11, d2, two), K.Keys.set(b12, d2, three)} : K.Keys}
  {==}

def Laws.last_press(code, d1, d2, keys):
  match keys:
    case K.Keys{up, dn, left, right, sleft, sright, run, use, fire, one, two, three}:
      press12(U32.is_eq(code, 63232) || U32.is_eq(code, 119),
        U32.is_eq(code, 63233) || U32.is_eq(code, 115), U32.is_eq(code, 63234),
        U32.is_eq(code, 63235), U32.is_eq(code, 97), U32.is_eq(code, 100),
        U32.is_eq(code, 65592) || U32.is_eq(code, 65596), U32.is_eq(code, 32),
        U32.is_eq(code, 65595) || U32.is_eq(code, 65598), U32.is_eq(code, 49), U32.is_eq(code, 50),
        U32.is_eq(code, 51), d1, d2, up, dn, left, right, sleft, sright, run, use, fire, one, two, three)

def Laws.arrows_wasd(down, keys):
  match keys:
    case K.Keys{up, dn, left, right, sleft, sright, run, use, fire, one, two, three}:
      {==}

def Laws.lowest_number_wins(two, three):
  {==}

def Laws.tic_rest(level, x, y):
  match level:
    case L.Level{geo, sectors, specials}:
      {==}

def Laws.tic_counts(cmd, p, level, clock):
  match level:
    case L.Level{geo, sectors, specials}:
      {==}

def Laws.tic_from_rest():
  {==}

def Laws.eye_rest(x, y):
  {==}

def Laws.fall_gravity():
  {==}

def Laws.landing_dip():
  {==}

def Laws.bob_run_and_cap():
  {==}

def Laws.step_up_dip():
  {==}

def Laws.pistol_rises():
  {==}

def Laws.pistol_bobs():
  {==}

def Laws.armour_absorbs():
  {==}

def Laws.damage_count():
  {==}

def Laws.door_timeline():
  {==}

def Laws.blazing_door_timeline():
  {==}

def Laws.floor_carries():
  {==}

def Laws.door_crushed():
  {==}

def Laws.turbo_floor_crossed():
  {==}

def Laws.lift_timeline():
  {==}

def Laws.floor_lowered():
  {==}

def Laws.lift_crushed():
  {==}

def Laws.use_fires_once(forward, side, turn, buttons, next, player, level, things, sidetex, thinkers, rnd, clock, usedown,
  sounds, mrnd, reborn, held):
  match level:
    case L.Level{geo, sectors, specials}:
      %held : {S.Sim.pressed(next, _) == False{} : Bool}
      {==}

# A tree read where it was just written answers what was written: both
# walk the same path, by the same bits of the index.
def vec_get_set(v: V.Vec, odd: Bool, +i: U32, +x: U32) ->
  {x == V.Vec.get.go(V.Vec.set.go(v, odd, i, x), odd, i) : U32}:
  match v odd:
    case V.Leaf{y} True{}:
      {==}
    case V.Leaf{y} False{}:
      {==}
    case V.Node{l, r} False{}:
      vec_get_set(l, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32), x)
    case V.Node{l, r} True{}:
      vec_get_set(r, V.Vec.odd((i >> 1n : U32)), (i >> 1n : U32), x)

def Laws.once_clears(line, s):
  match s:
    case S.State{player, L.Level{geo, sectors, specials}, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      Equal.sym(U32, 0, V.Vec.get.go(V.Vec.set.go(specials, V.Vec.odd(L.Level.at(line, 2, 0)),
        L.Level.at(line, 2, 0), 0), V.Vec.odd(L.Level.at(line, 2, 0)), L.Level.at(line, 2, 0)),
        vec_get_set(specials, V.Vec.odd(L.Level.at(line, 2, 0)), L.Level.at(line, 2, 0), 0))

def Laws.exit_ends(cmd):
  {==}

def Laws.sound_places():
  {==}

def Laws.door_sounds():
  {==}

def Laws.switch_sounds():
  {==}

def Laws.random_table():
  {==}

def Laws.blink_counts():
  {==}

def Laws.strobe_timeline():
  {==}

def Laws.glow_turns():
  {==}

def Laws.replay_append(a, b, s):
  match a:
    case []:
      {==}
    case cmd <> rest:
      Laws.replay_append(rest, b, S.Sim.tic(cmd, s))

# Free pins the lines
# -------------------

# A type picked by a Bool or a Maybe: a rewrite through it refutes
# True == False and Some == None.
def BD(b: Bool, t: Type, f: Type) -> Type:
  match b:
    case True{}:
      t
    case False{}:
      f

def MD(m: Maybe<&2, U32>, s: Type, n: Type) -> Type:
  match m:
    case None{}:
      n
    case Some{x}:
      s

def and_true_left(a: Bool, -b: Bool, e: {True{} == Bool.and(a, b) : Bool}) ->
  {True{} == a : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      e

def and_true_right(a: Bool, -b: Bool, e: {True{} == Bool.and(a, b) : Bool}) ->
  {True{} == b : Bool}:
  match a:
    case True{}:
      e
    case False{}:
      %e : BD(_, Unit, {True{} == b : Bool})
      Unit{}

# The thing check's verdict is carried by a line's pass only while it
# holds, and a line that stops the box ends it: a True verdict after a
# line means the verdict before and the line's condition both held.
def cross_true(ok: Bool, +level: L.Level, +x: U32, +y: U32, +r: U32, +line: L.Level.Line, fl: U32, cl: U32,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.cross(ok, level, x, y, r, line, fl, cl)) : Bool}) -> {True{} == ok : Bool}:
  match ok:
    case False{}:
      e
    case True{}:
      {==}

def line_ok_of(+level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +i: U32, f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.line(level, x, y, r, mask, i, f)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool}:
  match f:
    case S.Fit{False{}, fl, cl}:
      %e : BD(_, Unit, {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool})
      Unit{}
    case S.Fit{True{}, fl, cl}:
      cross_true(S.Sim.line_ok(level, x, y, r, mask, i), level, x, y, r, L.Level.line(level, i), fl, cl, e)

def fit_of(+level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +i: U32, f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.line(level, x, y, r, mask, i, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match f:
    case S.Fit{False{}, fl, cl}:
      e
    case S.Fit{True{}, fl, cl}:
      {==}

# The fold only ands: a True verdict at the end means one at the start.
def go_keeps(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.go(lines, level, x, y, r, mask, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match lines:
    case []:
      e
    case +i <> rest:
      fit_of(level, x, y, r, mask, i, f,
        go_keeps(rest, level, x, y, r, mask, S.Sim.fit.line(level, x, y, r, mask, i, f), e))

def some_eq(+i: U32, +h: U32, e: {Some{i} == Some{h} : Maybe<&2, U32>}) -> {h == i : U32}:
  Equal.cong(Maybe<&2, U32>, U32, m => Maybe.default(&2, U32, m, 0), Some{h}, Some{i},
    Equal.sym(Maybe<&2, U32>, Some{i}, Some{h}, e))

# A True verdict over a list means the condition holds for each line in
# it, by its position.
def go_pins(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +r: U32, +mask: U32, +f: S.Sim.Fit,
  k: Nat, +i: U32, listed: {Some{i} == List.get(&2, U32, lines, k) : Maybe<&2, U32>},
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.go(lines, level, x, y, r, mask, f)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool}:
  match lines k:
    case [] _:
      %listed : MD(_, Unit, {True{} == S.Sim.line_ok(level, x, y, r, mask, i) : Bool})
      Unit{}
    case +h <> rest 0n:
      %some_eq(i, h, listed) : {True{} == S.Sim.line_ok(level, x, y, r, mask, _) : Bool}
      line_ok_of(level, x, y, r, mask, h, f, go_keeps(rest, level, x, y, r, mask,
        S.Sim.fit.line(level, x, y, r, mask, h, f), e))
    case +h <> rest 1n+j:
      go_pins(rest, level, x, y, r, mask, S.Sim.fit.line(level, x, y, r, mask, h, f), j, i, listed, e)

# A free position passed the thing check, and then every line.
def at_pins(c: Bool, +level: L.Level, +x: U32, +y: U32, k: Nat, +i: U32,
  listed: {Some{i} == List.get(&2, U32, S.Sim.lines(level, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32),
    (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), k) : Maybe<&2, U32>},
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, S.Sim.radius(), 1, i) : Bool}:
  match c:
    case False{}:
      %e : BD(_, Unit, {True{} == S.Sim.line_ok(level, x, y, S.Sim.radius(), 1, i) : Bool})
      Unit{}
    case True{}:
      go_pins(S.Sim.lines(level, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32), (x + S.Sim.radius() : U32),
        (y + S.Sim.radius() : U32)), level, x, y, S.Sim.radius(), 1, S.Sim.fit.start(True{}, level, x, y), k, i, listed,
        e)

def Laws.free_pins_lines(level, x, y, k, i, listed, free):
  at_pins(S.Sim.clear(level, x, y, S.Sim.radius(), H.Thing.you()), level, x, y, k, i, listed, free)

# Clear pins the things
# ---------------------

def not_blocker(b: Bool, -c: Bool, e: {True{} == Bool.and(Bool.not(b), c) : Bool}) -> {False{} == b : Bool}:
  match b:
    case True{}:
      %e : BD(_, Unit, {False{} == True{} : Bool})
      Unit{}
    case False{}:
      {==}

# A True verdict over the things near means no one of them stops the
# box, by its position.
def clear_pins(ids: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, k: Nat, +id: U32,
  listed: {Some{id} == List.get(&2, U32, ids, k) : Maybe<&2, U32>},
  e: {True{} == S.Sim.clear.go(ids, L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you()) : Bool}) ->
  {False{} == S.Sim.blocker(L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you(), id) : Bool}:
  match ids k:
    case [] _:
      %listed : MD(_, Unit,
        {False{} == S.Sim.blocker(L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you(), id) : Bool})
      Unit{}
    case +h <> rest 0n:
      %some_eq(id, h, listed)
        : {False{} == S.Sim.blocker(L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you(), _) : Bool}
      not_blocker(S.Sim.blocker(L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you(), h),
        S.Sim.clear.go(rest, L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you()), e)
    case +h <> rest 1n+j:
      clear_pins(rest, level, x, y, j, id, listed,
        and_true_right(Bool.not(S.Sim.blocker(L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you(), h)),
          S.Sim.clear.go(rest, L.Level.things_of(level), x, y, S.Sim.radius(), H.Thing.you()), e))

def Laws.clear_pins_things(level, x, y, k, id, listed, clear):
  clear_pins(S.Sim.near(level, x, y, S.Sim.radius()), level, x, y, k, id, listed, clear)

# The wall law
# ------------

# Free: the player's position passes Sim.fit. Every move the sim takes
# has passed it, so each function from the tic down keeps it: a lemma a
# function, on the flag it decides by and the record it opens.
def Free(level: L.Level, +p: S.Player) -> Type:
  {True{} == S.Sim.free(level, S.Player.x(p), S.Player.y(p)) : Bool}

def Xy.player(s: S.Sim.Xy) -> S.Player:
  S.Xy{done, t, xm, ym} = s
  S.Sim.Try.player(t)

# Holding another inventory keeps the place.
def holding_free(+level: L.Level, p: S.Player, held: I.Inventory, hp: Free(level, p)) ->
  Free(level, S.Player.holding(p, held)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def fin_free(+level: L.Level, go: Bool, p: S.Player, things: H.Things, +x: U32, +y: U32, floor: U32,
  ceil: U32, over: List<&2, U32>, +ok: Bool, fl: U32, cl: U32, +h: Bool, e: {go == Bool.and(ok, h) : Bool},
  hf: {S.Fit{ok, fl, cl} == S.Sim.fit(level, x, y) : S.Sim.Fit}, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move.fin(go, p, things, x, y, floor, ceil, over))):
  match go p:
    case False{} S.Player{+px, +py, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} S.Player{+px, +py, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      %hf : {True{} == S.Sim.Fit.ok(_) : Bool}
      and_true_left(ok, h, e)

def fit_free(+level: L.Level, +p: S.Player, +x: U32, +y: U32, touched: I.Inventory & H.Things,
  f: S.Sim.Fit, over: List<&2, U32>, hf: {f == S.Sim.fit(level, x, y) : S.Sim.Fit}, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move.fit(p, x, y, touched, f, over))):
  match touched f:
    case (+inv, +things) S.Fit{+ok, +floor, +ceil}:
      fin_free(level, Bool.and(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), S.Sim.height()),
        Bool.and(F.Fixed.ge((ceil - S.Player.z(p) : U32), S.Sim.height()),
          F.Fixed.le((floor - S.Player.z(p) : U32), S.Sim.step_up())))), S.Player.holding(p, inv), things, x, y,
        floor, ceil, over, ok, floor, ceil, Bool.and(F.Fixed.ge((ceil - floor : U32), S.Sim.height()),
          Bool.and(F.Fixed.ge((ceil - S.Player.z(p) : U32), S.Sim.height()),
            F.Fixed.le((floor - S.Player.z(p) : U32), S.Sim.step_up()))), {==}, hf, holding_free(level, p, inv, hp))

def try_free(+level: L.Level, things: H.Things, +p: S.Player, +x: U32, +y: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move(level, things, p, x, y))):
  fit_free(level, p, x, y, S.Sim.touch(level, x, y, S.Player.z(p), (S.Player.inv(p), things)), S.Sim.fit(level, x, y),
    S.Sim.crossings(level, S.Player.x(p), S.Player.y(p), x, y), {==}, hp)

def done_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.Try.done(t))):
  match t:
    case S.Try{ok, p, things}:
      ht

def stairstep_fin_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.stairstep.fin(level, t))):
  match t:
    case S.Try{True{}, p, things}:
      ht
    case S.Try{False{}, +p, +things}:
      done_free(level, S.Sim.try_move(level, things, p, (S.Player.x(p) + S.Player.momx(p) : U32), S.Player.y(p)),
        try_free(level, things, p, (S.Player.x(p) + S.Player.momx(p) : U32), S.Player.y(p), ht))

def stairstep_free(+level: L.Level, +things: H.Things, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.stairstep(level, things, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      stairstep_fin_free(level, S.Sim.try_move(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, x, (y + momy : U32)),
        try_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, x, (y + momy : U32), hp))

def wall_go_free(+level: L.Level, things: H.Things, p: S.Player, m: U32 & U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.wall.go(level, things, p, m))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      (+mx, +my) = m
      try_free(level, things, S.Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz,
        crossed, inv, psprites, hurt}, (x + mx : U32), (y + my : U32), hp)

def wall_free(left: Bool, +level: L.Level, things: H.Things, p: S.Player, +frac: U32, i: U32,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.slide.wall(left, level, things, p, frac, i))):
  match left p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      wall_go_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, S.Sim.along(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, i, F.Fixed.mul(momx, frac), F.Fixed.mul(momy, frac)), hp)

def rest_free(+level: L.Level, things: H.Things, p: S.Player, +frac: U32, i: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.rest(level, things, p, frac, i))):
  wall_free(F.Fixed.gt(F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32)), 0),
    level, things, p, F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32)), i, hp)

def upto_fin_free(+level: L.Level, +frac: U32, i: U32, t: S.Sim.Try,
  ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.upto.fin(level, frac, i, t))):
  match t:
    case S.Try{True{}, p, things}:
      rest_free(level, things, p, frac, i, ht)
    case S.Try{False{}, p, things}:
      stairstep_free(level, things, p, ht)

def upto_free(some: Bool, +level: L.Level, +things: H.Things, p: S.Player, +frac: U32, i: U32,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.slide.upto(some, level, things, p, frac, i))):
  match some p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      rest_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, frac, i, hp)
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      upto_fin_free(level, frac, i, S.Sim.try_move(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32)),
        try_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32), hp))

def found_free(hit: Bool, +level: L.Level, +things: H.Things, p: S.Player, +frac: U32, i: U32,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.slide.found(hit, level, things, p, frac, i))):
  match hit:
    case False{}:
      stairstep_free(level, things, p, hp)
    case True{}:
      upto_free(F.Fixed.gt(frac, 0), level, things, p, frac, i, hp)

def hit_free(+level: L.Level, +things: H.Things, p: S.Player, best: U32 & U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.hit(level, things, p, best))):
  (+frac, i) = best
  found_free(U32.is_le(frac, F.Fixed.unit()), level, things, p, (frac - 2048 : U32), i, hp)

def once_free(+level: L.Level, +things: H.Things, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.once(level, things, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hit_free(level, things, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        S.Sim.trace(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
          S.Sim.lead(x, momx), S.Sim.trail(y, momy), (S.Sim.lead(x, momx) + momx : U32),
          (S.Sim.trail(y, momy) + momy : U32),
          S.Sim.trace(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
            S.Sim.trail(x, momx), S.Sim.lead(y, momy), (S.Sim.trail(x, momx) + momx : U32),
            (S.Sim.lead(y, momy) + momy : U32),
            S.Sim.trace(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
              S.Sim.lead(x, momx), S.Sim.lead(y, momy), (S.Sim.lead(x, momx) + momx : U32),
              (S.Sim.lead(y, momy) + momy : U32), ((F.Fixed.unit() + 1 : U32), 0)))), hp)

def slide_go_free(fuel: Nat, +level: L.Level, st: S.Sim.Try, hs: Free(level, S.Sim.Try.player(st))) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.go(fuel, level, st))):
  match fuel st:
    case 0n S.Try{True{}, p, things}:
      hs
    case 1n+f S.Try{True{}, p, things}:
      hs
    case 0n S.Try{False{}, p, things}:
      stairstep_free(level, things, p, hs)
    case 1n+f S.Try{False{}, +p, +things}:
      slide_go_free(f, level, S.Sim.slide.once(level, things, p), once_free(level, things, p, hs))

def slide_free(+level: L.Level, things: H.Things, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide(level, things, p))):
  slide_go_free(2n, level, S.Try{False{}, p, things}, hp)

def tried_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.xy.tried(level, t))):
  match t:
    case S.Try{True{}, p, things}:
      ht
    case S.Try{False{}, p, things}:
      slide_free(level, things, p, ht)

def xy_fin_free(+level: L.Level, +things: H.Things, +p: S.Player, +tx: U32, +ty: U32, xm: U32, ym: U32,
  hp: Free(level, p)) -> Free(level, Xy.player(S.Sim.xy.fin(level, things, p, tx, ty, xm, ym))):
  tried_free(level, S.Sim.try_move(level, things, p, tx, ty), try_free(level, things, p, tx, ty, hp))

def step_free(big: Bool, +level: L.Level, t: S.Sim.Try, +xm: U32, +ym: U32, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, Xy.player(S.Sim.xy.step(big, level, t, xm, ym))):
  match big t:
    case True{} S.Try{ok, +p, +things}:
      xy_fin_free(level, things, p, (S.Player.x(p) + F.Fixed.half(xm) : U32),
        (S.Player.y(p) + F.Fixed.half(ym) : U32), F.Fixed.sar(xm), F.Fixed.sar(ym), ht)
    case False{} S.Try{ok, +p, +things}:
      xy_fin_free(level, things, p, (S.Player.x(p) + xm : U32), (S.Player.y(p) + ym : U32), 0, 0, ht)

def xy_go_free(fuel: Nat, +level: L.Level, st: S.Sim.Xy, hs: Free(level, Xy.player(st))) ->
  Free(level, S.Sim.Try.player(S.Sim.xy.go(fuel, level, st))):
  match fuel st:
    case 0n S.Xy{True{}, t, xm, ym}:
      hs
    case 1n+f S.Xy{True{}, t, xm, ym}:
      hs
    case 0n S.Xy{False{}, t, xm, ym}:
      hs
    case 1n+f S.Xy{False{}, +t, +xm, +ym}:
      xy_go_free(f, level, S.Sim.xy.step(S.Sim.big(xm, ym), level, t, xm, ym),
        step_free(S.Sim.big(xm, ym), level, t, xm, ym, hs))

def slow_free(stop: Bool, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.slow(stop, p)):
  match stop p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def ground_free(+level: L.Level, cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.friction.ground(cmd, p)):
  match cmd p:
    case K.Cmd{+forward, +side, +turn, +buttons} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      slow_free(Bool.and(S.Sim.crawling(momx), Bool.and(S.Sim.crawling(momy),
        Bool.and(U32.is_zero(forward), U32.is_zero(side)))), level,
        S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, hp)

def friction_if_free(ground: Bool, +level: L.Level, +cmd: K.Cmd, +p: S.Player, hp: Free(level, p)) ->
  Free(level, Bool.pick(S.Player, ground, S.Sim.friction.ground(cmd, p), p)):
  match ground:
    case True{}:
      ground_free(level, cmd, p, hp)
    case False{}:
      hp

def friction_free(+level: L.Level, +cmd: K.Cmd, +p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.friction(cmd, p)):
  friction_if_free(S.Player.onground(p), level, cmd, p, hp)

def slowed_free(+level: L.Level, +cmd: K.Cmd, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.xy.slowed(cmd, t))):
  match t:
    case S.Try{ok, +p, things}:
      friction_free(level, cmd, p, ht)

def moving_free(moving: Bool, +level: L.Level, +things: H.Things, +cmd: K.Cmd, p: S.Player,
  hp: Free(level, p)) -> Free(level, S.Sim.Try.player(S.Sim.xy.moving(moving, level, things, cmd, p))):
  match moving p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      slowed_free(level, cmd, S.Sim.xy.go(2n, level, S.Xy{False{}, S.Try{False{},
        S.Player{x, y, z, angle, S.Sim.clamp(momx), S.Sim.clamp(momy), momz, floorz, ceilz, viewheight,
          deltaview, viewz, crossed, inv, psprites, hurt}, things}, S.Sim.clamp(momx), S.Sim.clamp(momy)}),
        xy_go_free(2n, level, S.Xy{False{}, S.Try{False{},
          S.Player{x, y, z, angle, S.Sim.clamp(momx), S.Sim.clamp(momy), momz, floorz, ceilz,
            viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, things}, S.Sim.clamp(momx), S.Sim.clamp(momy)}, hp))

def xy_free(+level: L.Level, +things: H.Things, +cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.xy(level, things, cmd, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      moving_free(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, things, cmd, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, hp)

# Thrust, turning, the eye and the vertical move keep the position.
def thrust_free(+level: L.Level, p: S.Player, +angle: U32, +move: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.thrust(level, p, angle, move)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def push_if_free(skip: Bool, +level: L.Level, +p: S.Player, +angle: U32, +move: U32,
  hp: Free(level, p)) ->
  Free(level, Bool.pick(S.Player, skip, p, S.Sim.thrust(level, p, angle, (move * 2048 : U32)))):
  match skip:
    case True{}:
      hp
    case False{}:
      thrust_free(level, p, angle, (move * 2048 : U32), hp)

def push_free(+level: L.Level, +p: S.Player, +angle: U32, +move: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.push(level, p, angle, move)):
  push_if_free(Bool.or(U32.is_zero(move), Bool.not(S.Player.onground(p))), level, p, angle, move, hp)

def move_free(+level: L.Level, cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.move(level, cmd, p)):
  match cmd p:
    case K.Cmd{+forward, +side, +turn, +buttons} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      push_free(level, S.Sim.push(level, S.Player{x, y, z, (angle + (turn << 16n) : U32), momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        (angle + (turn << 16n) : U32), forward),
        ((angle + (turn << 16n) : U32) - A.Angle.ang90() : U32), side,
        push_free(level, S.Player{x, y, z, (angle + (turn << 16n) : U32), momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
          (angle + (turn << 16n) : U32), forward, hp))

def eye_if_free(ground: Bool, live: Bool, +level: L.Level, p: S.Player, swing: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.eye.if(ground, live, p, swing)):
  match ground live p:
    case True{} True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case True{} False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def eye_free(+level: L.Level, clock: U32, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.eye(level, clock, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      eye_if_free(S.Player.onground(S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}),
        Bool.not(S.Player.dead(S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt})),
        level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt},
        F.Fixed.mul((S.Sim.bob(momx, momy) >> 1n : U32),
          A.Angle.sin(L.Level.sine(level), ((409 * clock : U32) .&. 8191 : U32))), hp)

def z_if_free(still: Bool, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.z.if(still, p)):
  match still p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def z_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.z(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      z_if_free(Bool.and(U32.is_eq(z, floorz), U32.is_zero(momz)), level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}, hp)

# The player sprites, the counters, the vertical move and the state the
# mobj leaves keep the place too.
def psprites_free(+level: L.Level, clock: U32, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.psprites(level, clock, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, S.Psprites{+weapon, +flash}, +hurt}:
      hp

def counters_free(+level: L.Level, p: S.Player, hp: Free(level, p)) -> Free(level, S.Sim.counters(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def mobj_z_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.mobj.z(t))):
  match t:
    case S.Try{ok, +p, things}:
      z_free(level, p, ht)

def moved_free(+level: L.Level, t: S.Sim.Try, at: L.Level, s: S.State, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.State.player(S.State.moved(t, at, s))):
  match t s:
    case S.Try{ok, p, got} S.State{player, old, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      ht

# Free reads the geometry alone
# -----------------------------

# A line's pass narrows the floor and ceiling and changes nothing else of
# the verdict, stated value first.
def narrow_ok(hit: Bool, +level: L.Level, +line: L.Level.Line, f: S.Sim.Fit) ->
  {S.Sim.Fit.ok(f) == S.Sim.Fit.ok(S.Sim.fit.narrow(hit, level, line, f)) : Bool}:
  match hit f:
    case True{} S.Fit{ok, floor, ceil}:
      {==}
    case False{} S.Fit{ok, floor, ceil}:
      {==}

def heights_ok(+level: L.Level, +x: U32, +y: U32, +r: U32, line: L.Level.Line, f: S.Sim.Fit) ->
  {S.Sim.Fit.ok(f) == S.Sim.Fit.ok(S.Sim.fit.heights(level, x, y, r, line, f)) : Bool}:
  match line:
    case L.Line{+x1, +y1, +x2, +y2, +flags, +front, +back}:
      narrow_ok(Bool.and(Bool.not(U32.is_eq(back, L.Level.none())),
        Bool.and(S.Sim.box_touches(x, y, r, L.Line{x1, y1, x2, y2, flags, front, back}),
          S.Sim.box_crosses(x, y, r, L.Line{x1, y1, x2, y2, flags, front, back}))),
        level, L.Line{x1, y1, x2, y2, flags, front, back}, f)

# A line's condition reads its ends, flags and sides, which two levels
# of one geometry share whatever their sectors and specials hold.
def cond_same(geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec, +x: U32, +y: U32, +r: U32, +mask: U32,
  +i: U32) ->
  {S.Sim.line_ok(L.Level{geo, sa, pa}, x, y, r, mask, i) == S.Sim.line_ok(L.Level{geo, sb, pb}, x, y, r, mask, i)
    : Bool}:
  match geo:
    case L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches}:
      {==}

# Past a line the box does not stop, the verdict is True in any level.
def cross_same(ok: Bool, +la: L.Level, +lb: L.Level, +x: U32, +y: U32, +r: U32, +linea: L.Level.Line,
  +lineb: L.Level.Line, +fl: U32, +cl: U32, +gl: U32, +hl: U32) ->
  {S.Sim.Fit.ok(S.Sim.fit.cross(ok, la, x, y, r, linea, fl, cl))
    == S.Sim.Fit.ok(S.Sim.fit.cross(ok, lb, x, y, r, lineb, gl, hl)) : Bool}:
  match ok:
    case False{}:
      {==}
    case True{}:
      %heights_ok(la, x, y, r, linea, S.Fit{True{}, fl, cl})
        : {_ == S.Sim.Fit.ok(S.Sim.fit.heights(lb, x, y, r, lineb, S.Fit{True{}, gl, hl})) : Bool}
      heights_ok(lb, x, y, r, lineb, S.Fit{True{}, gl, hl})

def line_same(+geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec, +x: U32, +y: U32, +r: U32,
  +mask: U32, +i: U32, fa: S.Sim.Fit, fb: S.Sim.Fit, e: {S.Sim.Fit.ok(fa) == S.Sim.Fit.ok(fb) : Bool}) ->
  {S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sa, pa}, x, y, r, mask, i, fa))
    == S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sb, pb}, x, y, r, mask, i, fb)) : Bool}:
  match fa fb:
    case S.Fit{False{}, fl, cl} S.Fit{False{}, gl, hl}:
      {==}
    case S.Fit{True{}, +fl, +cl} S.Fit{True{}, +gl, +hl}:
      %cond_same(geo, sa, pa, sb, pb, x, y, r, mask, i)
        : {S.Sim.Fit.ok(S.Sim.fit.cross(S.Sim.line_ok(L.Level{geo, sa, pa}, x, y, r, mask, i), L.Level{geo, sa, pa},
          x, y, r, L.Level.line(L.Level{geo, sa, pa}, i), fl, cl))
          == S.Sim.Fit.ok(S.Sim.fit.cross(_, L.Level{geo, sb, pb}, x, y, r, L.Level.line(L.Level{geo, sb, pb}, i), gl,
            hl)) : Bool}
      cross_same(S.Sim.line_ok(L.Level{geo, sa, pa}, x, y, r, mask, i), L.Level{geo, sa, pa}, L.Level{geo, sb, pb}, x,
        y, r, L.Level.line(L.Level{geo, sa, pa}, i), L.Level.line(L.Level{geo, sb, pb}, i), fl, cl, gl, hl)
    case S.Fit{True{}, fl, cl} S.Fit{False{}, gl, hl}:
      %e : BD(_, Unit, {S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sa, pa}, x, y, r, mask, i, S.Fit{True{}, fl, cl}))
        == S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sb, pb}, x, y, r, mask, i, S.Fit{False{}, gl, hl})) : Bool})
      Unit{}
    case S.Fit{False{}, fl, cl} S.Fit{True{}, gl, hl}:
      %e : BD(_, {S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sa, pa}, x, y, r, mask, i, S.Fit{False{}, fl, cl}))
        == S.Sim.Fit.ok(S.Sim.fit.line(L.Level{geo, sb, pb}, x, y, r, mask, i, S.Fit{True{}, gl, hl})) : Bool}, Unit)
      Unit{}

def go_same(lines: List<&2, U32>, +geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec,
  +x: U32, +y: U32, +r: U32, +mask: U32, +fa: S.Sim.Fit, +fb: S.Sim.Fit,
  e: {S.Sim.Fit.ok(fa) == S.Sim.Fit.ok(fb) : Bool}) ->
  {S.Sim.Fit.ok(S.Sim.fit.go(lines, L.Level{geo, sa, pa}, x, y, r, mask, fa))
    == S.Sim.Fit.ok(S.Sim.fit.go(lines, L.Level{geo, sb, pb}, x, y, r, mask, fb)) : Bool}:
  match lines:
    case []:
      e
    case +i <> rest:
      go_same(rest, geo, sa, pa, sb, pb, x, y, r, mask, S.Sim.fit.line(L.Level{geo, sa, pa}, x, y, r, mask, i, fa),
        S.Sim.fit.line(L.Level{geo, sb, pb}, x, y, r, mask, i, fb),
        line_same(geo, sa, pa, sb, pb, x, y, r, mask, i, fa, fb, e))

# The lines gathered for a box are the blockmap's, and the things near it
# its links, which two levels of one geometry share.
def lines_same(geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec, +x0: U32, +y0: U32, +x1: U32,
  +y1: U32) ->
  {S.Sim.lines(L.Level{geo, sa, pa}, x0, y0, x1, y1) == S.Sim.lines(L.Level{geo, sb, pb}, x0, y0, x1, y1)
    : List<&2, U32>}:
  match geo:
    case L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches}:
      {==}

def clear_same(geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec, +x: U32, +y: U32) ->
  {S.Sim.clear(L.Level{geo, sa, pa}, x, y, S.Sim.radius(), H.Thing.you())
    == S.Sim.clear(L.Level{geo, sb, pb}, x, y, S.Sim.radius(), H.Thing.you()) : Bool}:
  match geo:
    case L.Geo{lines, sides, verts, segs, subs, nodes, root, blockmap, things, texnames, flatnames, sine, tanto, boxes, nlines, nsectors, sectags, sidetex, switches}:
      {==}

def at_same(c: Bool, +geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec, +x: U32, +y: U32) ->
  {S.Sim.Fit.ok(S.Sim.fit.at(c, L.Level{geo, sa, pa}, x, y, S.Sim.radius(), 1))
    == S.Sim.Fit.ok(S.Sim.fit.at(c, L.Level{geo, sb, pb}, x, y, S.Sim.radius(), 1)) : Bool}:
  match c:
    case False{}:
      {==}
    case True{}:
      %lines_same(geo, sa, pa, sb, pb, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32),
        (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32))
        : {S.Sim.Fit.ok(S.Sim.fit.go(S.Sim.lines(L.Level{geo, sa, pa}, (x - S.Sim.radius() : U32),
          (y - S.Sim.radius() : U32), (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), L.Level{geo, sa, pa},
          x, y,
          S.Sim.radius(), 1, S.Sim.fit.start(True{}, L.Level{geo, sa, pa}, x, y)))
          == S.Sim.Fit.ok(S.Sim.fit.go(_, L.Level{geo, sb, pb}, x, y, S.Sim.radius(), 1,
            S.Sim.fit.start(True{}, L.Level{geo, sb, pb}, x, y))) : Bool}
      go_same(S.Sim.lines(L.Level{geo, sa, pa}, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32),
        (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), geo, sa, pa, sb, pb, x, y, S.Sim.radius(), 1,
        S.Sim.fit.start(True{}, L.Level{geo, sa, pa}, x, y), S.Sim.fit.start(True{}, L.Level{geo, sb, pb}, x, y), {==})

# Free is the same in two levels of one geometry: the things near are
# its links, the lines gathered its blockmap's, and each one's condition
# is the geometry's.
def free_geo(+geo: L.Level.Geo, +sa: V.Vec, +pa: V.Vec, +sb: V.Vec, +pb: V.Vec, +x: U32, +y: U32) ->
  {S.Sim.free(L.Level{geo, sa, pa}, x, y) == S.Sim.free(L.Level{geo, sb, pb}, x, y) : Bool}:
  %clear_same(geo, sa, pa, sb, pb, x, y)
    : {S.Sim.Fit.ok(S.Sim.fit.at(S.Sim.clear(L.Level{geo, sa, pa}, x, y, S.Sim.radius(), H.Thing.you()),
      L.Level{geo, sa, pa}, x, y, S.Sim.radius(), 1))
      == S.Sim.Fit.ok(S.Sim.fit.at(_, L.Level{geo, sb, pb}, x, y, S.Sim.radius(), 1)) : Bool}
  at_same(S.Sim.clear(L.Level{geo, sa, pa}, x, y, S.Sim.radius(), H.Thing.you()), geo, sa, pa, sb, pb, x, y)

# A mover's re-clip moves the player up and down alone.
def stood_x(moved: S.Player, +q: S.Player) -> {S.Player.x(moved) == S.Player.x(S.Player.stood(moved, q)) : U32}:
  match moved:
    case S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}:
      {==}

def stood_y(moved: S.Player, +q: S.Player) -> {S.Player.y(moved) == S.Player.y(S.Player.stood(moved, q)) : U32}:
  match moved:
    case S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, crossed, inv, psprites, hurt}:
      {==}

# The player's think through the state
# ------------------------------------

# From the sector's special down, the think hands the player on inside
# the state, so each lemma is about the player the state holds. None of
# these moves it: a blow writes the health, the wound and the momentum,
# the sounds write the state's own fields, and dying writes the view.

# The state with another player is free where that player is.
def put_free(+level: L.Level, s: S.State, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.State.player(S.State.player.put(s, p))):
  match s:
    case S.State{was, l, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      hp

# The sounds a tic reports leave the player where it was.
def heard_free(+level: L.Level, e: Sn.Sound.Event, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.State.heard(e, s))):
  match s:
    case S.State{player, l, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      h

def told_go_free(events: List<&2, Sn.Sound.Event>, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.State.told.go(events, s))):
  match events:
    case []:
      h
    case e <> rest:
      told_go_free(rest, level, S.State.heard(e, s), heard_free(level, e, s, h))

def told_free(+level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.State.told(s))):
  match s:
    case S.State{player, l, H.Things{tree, count, you, heard}, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      told_go_free(heard, level, S.State{player, l, H.Things{tree, count, you, []}, sidetex, thinkers, rnd, clock,
        ended, usedown, sounds, mrnd, reborn}, h)

def sound_if_free(audible: Bool, +level: L.Level, e: Sn.Sound.Event, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.sound.if(audible, e, s))):
  match audible:
    case False{}:
      h
    case True{}:
      heard_free(level, e, s, h)

def sound_start_free(+sfx: U32, source: Sn.Sound.Source, params: U32 & U32, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.sound.start(sfx, source, params, s))):
  (+vol, sep) = params
  sound_if_free(Bool.not(Bool.or(U32.is_zero(sfx), U32.is_zero(vol))), level, Sn.Start{sfx, source, vol, sep}, s, h)

def sound_told_free(sfx: U32, source: Sn.Sound.Source, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.sound.told(sfx, source, s))):
  sound_start_free(sfx, source,
    S.Sim.sound.params(S.Sim.sound.place(source, s), S.State.level(s), S.State.player(s)), level, s, h)

def sound_free(sfx: U32, source: Sn.Sound.Source, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.sound(sfx, source, s))):
  sound_told_free(sfx, source, level, S.State.told(s), told_free(level, s, h))

# The mobj's own states: entering one, counting its tics down, and the
# actions the rows run, which are sounds.
def act_free(action: H.Thing.Action, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.mobj.act(action, s))):
  match action:
    case H.Pain{}:
      sound_free(Sn.Sound.plpain(), Sn.Thing{H.Thing.you()}, level, s, h)
    case H.Scream{}:
      sound_free(Sn.Sound.pldeth(), Sn.Thing{H.Thing.you()}, level, s, h)
    case H.Null{}:
      h
    case H.Raise{}:
      h
    case H.WeaponReady{}:
      h
    case H.Lower{}:
      h

def entering_free(+state: U32, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Player.entering(state, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, S.Hurt{+was, +tics, +damage, +attacker}}:
      hp

def counted_free(+n: U32, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Player.counted(n, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, S.Hurt{+st, +tics, +damage, +attacker}}:
      hp

def enter_free(+state: U32, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.mobj.enter(state, s))):
  act_free(H.Thing.Row.action(H.Thing.row(state)), level,
    S.State.player.put(s, S.Player.entering(state, S.State.player(s))),
    put_free(level, s, S.Player.entering(state, S.State.player(s)),
      entering_free(state, level, S.State.player(s), h)))

def mobj_step_free(lasting: Bool, out: Bool, +next: U32, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.mobj.step(lasting, out, next, s))):
  match lasting out:
    case True{} True{}:
      h
    case True{} False{}:
      h
    case False{} True{}:
      enter_free(next, level, s, h)
    case False{} False{}:
      put_free(level, s, S.Player.counted(1, S.State.player(s)),
        counted_free(1, level, S.State.player(s), h))

def mobj_state_free(row: S.Sim.Hurt, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.mobj.state(row, s))):
  match row:
    case S.Hurt{+st, +tics, damage, attacker}:
      mobj_step_free(U32.is_eq(tics, 4294967295), U32.is_eq(tics, 1),
        H.Thing.Row.next(H.Thing.row(st)), level, s, h)

def mobj_tics_free(+level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.mobj.tics(s))):
  mobj_state_free(S.Player.hurt(S.State.player(s)), level, s, h)

# The blow: the thrust, the armour and the health, the wound, and the
# death it may end in.
def dropped_free(+sine: V.Vec, +clock: U32, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Player.dropped(sine, clock, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, S.Psprites{+weapon, +flash}, +hurt}:
      hp

def drop_free(+level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.drop(s))):
  put_free(level, s, S.Player.dropped(L.Level.sine(S.State.level(s)), S.State.clock(s), S.State.player(s)),
    dropped_free(L.Level.sine(S.State.level(s)), S.State.clock(s), level, S.State.player(s), h))

def drawn_free(+level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(Pair.fst(S.State, U32, S.Sim.drawn(s)))):
  match s:
    case S.State{player, l, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      h

def kill_tics_free(got: S.State & U32, +level: L.Level, h: Free(level, S.State.player(Pair.fst(S.State, U32, got)))) ->
  Free(level, S.State.player(S.Sim.kill.tics(got))):
  (+s, drawn) = got
  put_free(level, s, S.Player.counted((drawn .&. 3 : U32), S.State.player(s)),
    counted_free((drawn .&. 3 : U32), level, S.State.player(s), h))

def kill_free(+level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.kill(s))):
  kill_tics_free(S.Sim.drawn(S.Sim.mobj.enter(H.Thing.play.death(), S.Sim.drop(s))), level,
    drawn_free(level, S.Sim.mobj.enter(H.Thing.play.death(), S.Sim.drop(s)),
      enter_free(H.Thing.play.death(), level, S.Sim.drop(s), drop_free(level, s, h))))

def flinch_free(flinches: Bool, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.damage.flinch(flinches, s))):
  match flinches:
    case False{}:
      h
    case True{}:
      enter_free(H.Thing.play.pain(), level, s, h)

def pain_free(got: S.State & U32, +level: L.Level, h: Free(level, S.State.player(Pair.fst(S.State, U32, got)))) ->
  Free(level, S.State.player(S.Sim.damage.pain(got))):
  (s, +drawn) = got
  flinch_free(U32.is_lt(drawn, 255), level, s, h)

def done_damage_free(dead: Bool, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.damage.done(dead, s))):
  match dead:
    case True{}:
      kill_free(level, s, h)
    case False{}:
      pain_free(S.Sim.drawn(s), level, drawn_free(level, s, h))

def took_free(+level: L.Level, p: S.Player, inv: I.Inventory, +left: U32, source: Maybe<&2, U32>,
  hp: Free(level, p)) -> Free(level, S.Player.took(p, inv, left, source)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +was, +psprites, S.Hurt{+st, +tics, +damage, +old}}:
      hp

def taken_free(hurt: I.Inventory & U32, source: Maybe<&2, U32>, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.damage.taken(hurt, source, s))):
  (+inv, +left) = hurt
  done_damage_free(I.Inventory.dead(inv), level,
    S.State.player.put(s, S.Player.took(S.State.player(s), inv, left, source)),
    put_free(level, s, S.Player.took(S.State.player(s), inv, left, source),
      took_free(level, S.State.player(s), inv, left, source, h)))

def damage_player_free(+damage: U32, source: Maybe<&2, U32>, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.damage.player(damage, source, s))):
  taken_free(I.Inventory.hurt(S.Player.inv(S.State.player(s)), damage), source, level, s, h)

# The thrust reads a level for its sines and writes the momentum alone,
# so the place it leaves is free of the level the law is about.
def thrust_at_free(+at: L.Level, +level: L.Level, p: S.Player, +angle: U32, +move: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.thrust(at, p, angle, move)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def thrown_free(+at: L.Level, +level: L.Level, p: S.Player, +angle: U32, +thrust: U32, back: Bool,
  hp: Free(level, p)) -> Free(level, S.Sim.blow.thrown(at, p, angle, thrust, back)):
  match back:
    case False{}:
      thrust_at_free(at, level, p, angle, thrust, hp)
    case True{}:
      thrust_at_free(at, level, p, (angle + A.Angle.ang180() : U32), (thrust * 4 : U32), hp)

def blow_free(+ix: U32, +iy: U32, +iz: U32, +damage: U32, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.blow(ix, iy, iz, damage, s))):
  match s:
    case S.State{+player, +at, things, sidetex, thinkers, +rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      thrown_free(at, level, player, A.Angle.of(L.Level.tanto(at), (S.Player.x(player) - ix : U32),
          (S.Player.y(player) - iy : U32)), (damage * 8192 : U32),
        Bool.and(Bool.and(U32.is_lt(damage, 40),
            Bool.and(F.Fixed.gt(damage, I.Inventory.health(S.Player.inv(player))),
              F.Fixed.gt((S.Player.z(player) - iz : U32), 4194304))),
          Bool.not(U32.is_zero((M.Random.at(Bool.pick(U32, Bool.and(U32.is_lt(damage, 40),
            Bool.and(F.Fixed.gt(damage, I.Inventory.health(S.Player.inv(player))),
              F.Fixed.gt((S.Player.z(player) - iz : U32), 4194304))), M.Random.next(rnd), rnd)) .&. 1 : U32)))),
        h)

def damage_hit_free(m: Maybe<&2, H.Thing>, +damage: U32, source: Maybe<&2, U32>, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.damage.hit(m, damage, source, s))):
  match m:
    case None{}:
      damage_player_free(damage, source, level, s, h)
    case Some{H.Thing{id, kind, +x, +y, +z, floorz, ceilz, angle, sector, st, tics}}:
      damage_player_free(damage, source, level, S.Sim.blow(x, y, z, damage, s), blow_free(x, y, z, damage, level, s, h))

def damage_if_free(dead: Bool, +damage: U32, inflictor: Maybe<&2, U32>, source: Maybe<&2, U32>, +level: L.Level,
  s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.damage.if(dead, damage, inflictor, source, s))):
  match dead:
    case True{}:
      h
    case False{}:
      damage_hit_free(S.Sim.named(inflictor, S.State.things(s)), damage, source, level, s, h)

def damage_free(damage: U32, inflictor: Maybe<&2, U32>, source: Maybe<&2, U32>, +level: L.Level, s: S.State,
  h: Free(level, S.State.player(s))) -> Free(level, S.State.player(S.Sim.damage(damage, inflictor, source, s))):
  damage_if_free(S.Player.dead(S.State.player(s)), damage, inflictor, source, level, s, h)

# The sector's special, the one blow the map can deal.
def sector_hurt_free(due: Bool, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.sector.hurt(due, s))):
  match due:
    case False{}:
      h
    case True{}:
      damage_free(5, None{}, None{}, level, s, h)

def sector_free(+level: L.Level, +clock: U32, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.sector(level, clock, s))):
  sector_hurt_free(Bool.and(U32.is_eq(L.Level.sector.special(S.State.level(s),
      L.Level.sector_at(level, S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s)))), 7),
    Bool.and(U32.is_zero((clock .&. 31 : U32)),
      U32.is_eq(S.Player.z(S.State.player(s)), L.Level.floor(level,
        L.Level.sector_at(level, S.Player.x(S.State.player(s)), S.Player.y(S.State.player(s))))))), level, s, h)

# Dying: the view sinks and turns, which the place does not feel, and
# the reborn is a flag on the state.
def sinking_free(+level: L.Level, p: S.Player, hp: Free(level, p)) -> Free(level, S.Player.sinking(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def turned_free(near: Bool, +to: U32, +delta: U32, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Player.turned(near, to, delta, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +crossed, +inv, +psprites, +hurt}:
      hp

def faced_free(m: Maybe<&2, H.Thing>, +at: L.Level, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.death.faced(m, at, p)):
  match m:
    case None{}:
      turned_free(True{}, S.Player.angle(p), 0, level, p, hp)
    case Some{H.Thing{id, kind, +x, +y, z, floorz, ceilz, angle, sector, st, tics}}:
      turned_free(Bool.or(U32.is_lt((A.Angle.of(L.Level.tanto(at), (x - S.Player.x(p) : U32),
            (y - S.Player.y(p) : U32)) - S.Player.angle(p) : U32), S.Sim.ang5()),
          U32.is_gt((A.Angle.of(L.Level.tanto(at), (x - S.Player.x(p) : U32), (y - S.Player.y(p) : U32))
            - S.Player.angle(p) : U32), F.Fixed.neg(S.Sim.ang5()))),
        A.Angle.of(L.Level.tanto(at), (x - S.Player.x(p) : U32), (y - S.Player.y(p) : U32)),
        (A.Angle.of(L.Level.tanto(at), (x - S.Player.x(p) : U32), (y - S.Player.y(p) : U32))
          - S.Player.angle(p) : U32), level, p, hp)

def asked_free(use: Bool, +level: L.Level, s: S.State, h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.death.asked(use, s))):
  match s:
    case S.State{player, l, things, sidetex, thinkers, rnd, clock, ended, usedown, sounds, mrnd, reborn}:
      h

def death_free(+level: L.Level, clock: U32, m: Maybe<&2, H.Thing>, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.death(level, clock, m, p)):
  faced_free(m, level, level, S.Sim.eye(level, clock, S.Player.sinking(S.Sim.psprites(level, clock, p))),
    eye_free(level, clock, S.Player.sinking(S.Sim.psprites(level, clock, p)),
      sinking_free(level, S.Sim.psprites(level, clock, p), psprites_free(level, clock, p, hp))))

# The think's two halves: what it leaves in the state, and the player it
# hands the move.
def player_free(dead: Bool, +cmd: K.Cmd, +level: L.Level, +clock: U32, s: S.State,
  h: Free(level, S.State.player(s))) ->
  Free(level, S.State.player(S.Sim.player(dead, cmd, level, clock, s))):
  match dead:
    case False{}:
      sector_free(level, clock,
        S.State.player.put(s, S.Sim.eye(level, clock, S.Sim.move(level, cmd, S.State.player(s)))),
        put_free(level, s, S.Sim.eye(level, clock, S.Sim.move(level, cmd, S.State.player(s))),
          eye_free(level, clock, S.Sim.move(level, cmd, S.State.player(s)),
            move_free(level, cmd, S.State.player(s), h))))
    case True{}:
      asked_free(K.Cmd.use(cmd), level, s, h)

def thought_free(dead: Bool, +level: L.Level, +clock: U32, m: Maybe<&2, H.Thing>, p: S.Player,
  hp: Free(level, p)) -> Free(level, S.Sim.thought(dead, level, clock, m, p)):
  match dead:
    case False{}:
      counters_free(level, S.Sim.psprites(level, clock, p), psprites_free(level, clock, p, hp))
    case True{}:
      death_free(level, clock, m, p, hp)

# What the tic keeps is free where the player it moved was: the level
# it packs has the geometry the move was checked against, and the
# player it packs the place.
def kept_free(+geo: L.Level.Geo, +sectors: V.Vec, +specials: V.Vec, +moved: S.Player, clock: U32, use: Bool,
  +after: S.State, h: Free(L.Level{geo, sectors, specials}, moved)) ->
  Laws.Free(S.Sim.tic.kept(geo, moved, clock, use, after)):
  %stood_x(moved, S.State.player(after))
    : {True{} == S.Sim.free(L.Level{geo, L.Level.sectors(S.State.level(after)),
      L.Level.specials(S.State.level(after))}, _,
      S.Player.y(S.Player.stood(moved, S.State.player(after)))) : Bool}
  %stood_y(moved, S.State.player(after))
    : {True{} == S.Sim.free(L.Level{geo, L.Level.sectors(S.State.level(after)),
      L.Level.specials(S.State.level(after))}, S.Player.x(moved), _) : Bool}
  %free_geo(geo, sectors, specials, L.Level.sectors(S.State.level(after)),
    L.Level.specials(S.State.level(after)), S.Player.x(moved), S.Player.y(moved))
    : {True{} == _ : Bool}
  h

def Laws.tic_keeps_geometry(cmd, s):
  match s:
    case S.State{player, L.Level{geo, sectors, specials}, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}:
      {==}
    case S.State{player, L.Level{geo, sectors, specials}, things, sidetex, thinkers, rnd, clock, False{}, usedown, sounds, mrnd, reborn}:
      {==}

# The rest of a live tic, from the state the think left: the player it
# hands the move is free where the think's was, the use does not move
# it, and the mobj's own move is the checked one.
def tic_live_free(+cmd: K.Cmd, +geo: L.Level.Geo, +sectors: V.Vec, +specials: V.Vec, +clock: U32,
  +usedown: Bool, +dead: Bool, +hurt: S.State,
  h: Free(L.Level{geo, sectors, specials}, S.State.player(hurt))) ->
  Laws.Free(S.Sim.tic.live(cmd, L.Level{geo, sectors, specials}, geo, clock, usedown, dead, hurt)):
  +level = {L.Level{geo, sectors, specials} : L.Level}
  +m = S.Sim.named(S.Sim.Hurt.attacker(S.Player.hurt(S.State.player(hurt))), S.State.things(hurt))
  +thought = S.Sim.thought(dead, level, clock, m, S.State.player(hurt))
  +used = S.Sim.use(Bool.and(Bool.not(dead), S.Sim.pressed(cmd, usedown)), S.State.player.put(hurt, thought))
  +went = S.Sim.mobj(cmd, level, thought, used)
  kept_free(geo, sectors, specials, S.State.player(went), clock, K.Cmd.use(cmd),
    S.State.told(S.Sim.thinkers(S.Sim.mobj.tics(S.Sim.cross(S.Player.crossed(S.State.player(went)), went)))),
    moved_free(level, S.Sim.mobj.z(S.Sim.xy(level, S.State.things(used), cmd, thought)), S.State.level(used), used,
      mobj_z_free(level, S.Sim.xy(level, S.State.things(used), cmd, thought), xy_free(level,
        S.State.things(used), cmd, thought,
        thought_free(dead, level, clock, m, S.State.player(hurt), h)))))

def Laws.tic_keeps_free(cmd, s, free):
  match s:
    case S.State{player, L.Level{geo, sectors, specials}, things, sidetex, thinkers, rnd, clock, True{}, usedown, sounds, mrnd, reborn}:
      free
    case S.State{+player, L.Level{+geo, +sectors, +specials}, +things, +sidetex, +thinkers, +rnd, +clock, False{}, +usedown, sounds, +mrnd, +reborn}:
      +level = {L.Level{geo, sectors, specials} : L.Level}
      +dead = S.Player.dead(player)
      tic_live_free(cmd, geo, sectors, specials, clock, usedown, dead,
        S.Sim.player(dead, cmd, level, clock,
          {S.State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, [], mrnd, reborn} : S.State}),
        player_free(dead, cmd, level, clock,
          {S.State{player, level, things, sidetex, thinkers, rnd, clock, False{}, usedown, [], mrnd, reborn} : S.State},
          free))

def Laws.replay_keeps_free(script, s, free):
  match script:
    case []:
      free
    case +cmd <> rest:
      Laws.replay_keeps_free(rest, S.Sim.tic(cmd, s), Laws.tic_keeps_free(cmd, s, free))

# A free position is clear: the thing check's verdict starts the fit.
def free_clear(c: Bool, +level: L.Level, +x: U32, +y: U32,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.at(c, level, x, y, S.Sim.radius(), 1)) : Bool}) -> {True{} == c : Bool}:
  match c:
    case False{}:
      e
    case True{}:
      {==}

def Laws.replay_keeps_clear(script, s, free):
  +after = S.Sim.replay(script, s)
  free_clear(S.Sim.clear(S.State.level(after), S.Player.x(S.State.player(after)), S.Player.y(S.State.player(after)),
    S.Sim.radius(), H.Thing.you()), S.State.level(after), S.Player.x(S.State.player(after)),
    S.Player.y(S.State.player(after)), Laws.replay_keeps_free(script, s, free))

# Things compute.

def Laws.spawn_phase():
  {==}

def Laws.bonus_cycle():
  {==}

def Laws.lasting_stays(id, kind, x, y, z, floorz, ceilz, angle, sector, state):
  {==}

# The solid columns stay sorted
# -----------------------------

# The order on Nat, through Base's comparison: each fact by induction on
# the numbers, the impossible cases refuted through BD.
def LE(a: Nat, b: Nat) -> Type:
  {True{} == Nat.is_le(a, b) : Bool}

def LT(a: Nat, b: Nat) -> Type:
  {True{} == Nat.is_lt(a, b) : Bool}

def le_trans(a: Nat, b: Nat, c: Nat, h1: LE(a, b), h2: LE(b, c)) -> LE(a, c):
  match a b c:
    case 0n _ 0n:
      {==}
    case 0n _ 1n+r:
      {==}
    case 1n+p 0n _:
      %h1 : BD(_, Unit, LE(1n+p, c))
      Unit{}
    case 1n+p 1n+q 0n:
      %h2 : BD(_, Unit, LE(1n+p, 0n))
      Unit{}
    case 1n+p 1n+q 1n+r:
      le_trans(p, q, r, h1, h2)

def le_lt_le(a: Nat, b: Nat, c: Nat, h1: LE(a, b), h2: LT(b, c)) -> LE(a, c):
  match a b c:
    case 0n _ 0n:
      {==}
    case 0n _ 1n+r:
      {==}
    case 1n+p 0n _:
      %h1 : BD(_, Unit, LE(1n+p, c))
      Unit{}
    case 1n+p 1n+q 0n:
      %h2 : BD(_, Unit, LE(1n+p, 0n))
      Unit{}
    case 1n+p 1n+q 1n+r:
      le_lt_le(p, q, r, h1, h2)

def not_lt_le(a: Nat, b: Nat, h: {False{} == Nat.is_lt(a, b) : Bool}) -> LE(b, a):
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+q:
      %h : BD(_, LE(1n+q, 0n), Unit)
      Unit{}
    case 1n+p 0n:
      {==}
    case 1n+p 1n+q:
      not_lt_le(p, q, h)

# The larger of hi and another is no less than what hi is no less than;
# the flag is the comparison Nat.max picks by.
def le_max(lo: Nat, hi: Nat, other: Nat, c: Bool, e: {c == Nat.is_lt(hi, other) : Bool},
  h: LE(lo, hi)) -> LE(lo, Bool.pick(Nat, c, other, hi)):
  match c:
    case True{}:
      le_lt_le(lo, hi, other, h, e)
    case False{}:
      h

# The smaller of first and rf is no more than the larger of last and rl
# when first is no more than last.
def min_le_max(+first: Nat, +last: Nat, +rf: Nat, +rl: Nat, c: Bool,
  e: {c == Nat.is_lt(first, rf) : Bool}, h: LE(first, last)) ->
  LE(Bool.pick(Nat, c, first, rf), Nat.max(last, rl)):
  match c:
    case True{}:
      le_max(first, last, rl, Nat.is_lt(last, rl), {==}, h)
    case False{}:
      le_max(rf, last, rl, Nat.is_lt(last, rl), {==},
        le_trans(rf, first, last, not_lt_le(first, rf, e), h))

def lt_pick(x: Nat, b: Nat, c: Nat, flag: Bool, hb: LT(x, b), hc: LT(x, c)) ->
  LT(x, Bool.pick(Nat, flag, b, c)):
  match flag:
    case True{}:
      hb
    case False{}:
      hc

# Three true conjuncts make the sorted conjunction of a head range.
def and3(a: Bool, b: Bool, c: Bool, ha: {True{} == a : Bool}, hb: {True{} == b : Bool},
  hc: {True{} == c : Bool}) -> {True{} == Bool.and(a, Bool.and(b, c)) : Bool}:
  %ha : {True{} == Bool.and(_, Bool.and(b, c)) : Bool}
  %hb : {True{} == Bool.and(_, c) : Bool}
  hc

# absorb's head starts at lo, whatever it swallows, so a column two
# before lo stays apart from it.
def absorb_head(rs: List<&2, C.Clip.Range>, ahead: Bool, +lo: Nat, +hi: Nat, +x: Nat,
  h: LT(1n+x, lo)) -> {True{} == C.Clip.apart(C.Clip.absorb(rs, ahead, lo, hi), x) : Bool}:
  match rs ahead:
    case [] True{}:
      h
    case [] False{}:
      h
    case C.Range{rf, rl} <> rest True{}:
      h
    case C.Range{+rf, +rl} <> +rest False{}:
      absorb_head(rest, C.Clip.ahead(rest, Nat.max(hi, rl)), lo, Nat.max(hi, rl), x, h)

def absorb_sorted(rs: List<&2, C.Clip.Range>, ahead: Bool, +lo: Nat, +hi: Nat,
  e: {ahead == C.Clip.ahead(rs, hi) : Bool}, ho: LE(lo, hi),
  hs: {True{} == C.Clip.sorted(rs) : Bool}) ->
  {True{} == C.Clip.sorted(C.Clip.absorb(rs, ahead, lo, hi)) : Bool}:
  match rs ahead:
    case [] True{}:
      and3(Nat.is_le(lo, hi), True{}, True{}, ho, {==}, {==})
    case [] False{}:
      and3(Nat.is_le(lo, hi), True{}, True{}, ho, {==}, {==})
    case C.Range{+rf, +rl} <> +rest True{}:
      and3(Nat.is_le(lo, hi), Nat.is_lt(1n+hi, rf), C.Clip.sorted(C.Range{rf, rl} <> rest), ho, e, hs)
    case C.Range{+rf, +rl} <> +rest False{}:
      absorb_sorted(rest, C.Clip.ahead(rest, Nat.max(hi, rl)), lo, Nat.max(hi, rl), {==},
        le_max(lo, hi, rl, Nat.is_lt(hi, rl), {==}, ho),
        and_true_right(C.Clip.apart(rest, rl), C.Clip.sorted(rest),
          and_true_right(Nat.is_le(rf, rl), Bool.and(C.Clip.apart(rest, rl), C.Clip.sorted(rest)), hs)))

# add's head is a range of the list, the new range, or absorb's: a
# column apart from the list's head and two before first stays apart.
def add_head(rs: List<&2, C.Clip.Range>, behind: Bool, ahead: Bool, +first: Nat, +last: Nat, +x: Nat,
  hf: LT(1n+x, first), hr: {True{} == C.Clip.apart(rs, x) : Bool}) ->
  {True{} == C.Clip.apart(C.Clip.add.go(rs, behind, ahead, first, last), x) : Bool}:
  match rs behind ahead:
    case [] True{} True{}:
      hf
    case [] True{} False{}:
      hf
    case [] False{} True{}:
      hf
    case [] False{} False{}:
      hf
    case C.Range{+rf, +rl} <> +rest True{} True{}:
      hr
    case C.Range{+rf, +rl} <> +rest True{} False{}:
      hr
    case C.Range{+rf, +rl} <> +rest False{} True{}:
      hf
    case C.Range{+rf, +rl} <> +rest False{} False{}:
      absorb_head(rest, C.Clip.ahead(rest, Nat.max(last, rl)), Nat.min(first, rf), Nat.max(last, rl), x,
        lt_pick(1n+x, first, rf, Nat.is_lt(first, rf), hf, hr))

# A proof is used once, so the three conjuncts of a sorted list come
# out of its one hypothesis together.
def and3_split(a: Bool, b: Bool, c: Bool, e: {True{} == Bool.and(a, Bool.and(b, c)) : Bool}) ->
  {True{} == a : Bool} & {True{} == b : Bool} & {True{} == c : Bool}:
  match a b c:
    case True{} True{} True{}:
      ({==}, {==}, {==})
    case True{} True{} False{}:
      %e : BD(_, Unit, {True{} == True{} : Bool} & {True{} == True{} : Bool} & {True{} == False{} : Bool})
      Unit{}
    case True{} False{} _:
      %e : BD(_, Unit, {True{} == True{} : Bool} & {True{} == False{} : Bool} & {True{} == c : Bool})
      Unit{}
    case False{} _ _:
      %e : BD(_, Unit, {True{} == False{} : Bool} & {True{} == b : Bool} & {True{} == c : Bool})
      Unit{}

# A range behind the new one stays the head: it is a range, the rest's
# head stays apart from it, and the rest stays sorted, which the caller
# proves by its own induction, handed in as next.
def behind_sorted(+rf: Nat, +rl: Nat, +rest: List<&2, C.Clip.Range>, +first: Nat, +last: Nat,
  parts: {True{} == Nat.is_le(rf, rl) : Bool} & {True{} == C.Clip.apart(rest, rl) : Bool}
    & {True{} == C.Clip.sorted(rest) : Bool},
  eb: LT(1n+rl, first),
  next: {True{} == C.Clip.sorted(rest) : Bool} -> {True{} == C.Clip.sorted(C.Clip.add.go(rest,
    C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last)) : Bool}) ->
  {True{} == C.Clip.sorted(C.Range{rf, rl} <> C.Clip.add.go(rest, C.Clip.behind(rest, first),
    C.Clip.ahead(rest, last), first, last)) : Bool}:
  (p1, p2, p3) = parts
  and3(Nat.is_le(rf, rl),
    C.Clip.apart(C.Clip.add.go(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last), rl),
    C.Clip.sorted(C.Clip.add.go(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last)),
    p1, add_head(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last, rl, eb, p2),
    next(p3))

def add_sorted(rs: List<&2, C.Clip.Range>, behind: Bool, ahead: Bool, +first: Nat, +last: Nat,
  eb: {behind == C.Clip.behind(rs, first) : Bool}, ea: {ahead == C.Clip.ahead(rs, last) : Bool},
  ho: LE(first, last), hs: {True{} == C.Clip.sorted(rs) : Bool}) ->
  {True{} == C.Clip.sorted(C.Clip.add.go(rs, behind, ahead, first, last)) : Bool}:
  match rs behind ahead:
    case [] True{} True{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case [] True{} False{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case [] False{} True{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case [] False{} False{}:
      and3(Nat.is_le(first, last), True{}, True{}, ho, {==}, {==})
    case C.Range{+rf, +rl} <> +rest True{} _:
      behind_sorted(rf, rl, rest, first, last,
        and3_split(Nat.is_le(rf, rl), C.Clip.apart(rest, rl), C.Clip.sorted(rest), hs), eb,
        h => add_sorted(rest, C.Clip.behind(rest, first), C.Clip.ahead(rest, last), first, last, {==}, {==},
          ho, h))
    case C.Range{+rf, +rl} <> +rest False{} True{}:
      and3(Nat.is_le(first, last), Nat.is_lt(1n+last, rf), C.Clip.sorted(C.Range{rf, rl} <> rest), ho, ea, hs)
    case C.Range{+rf, +rl} <> +rest False{} False{}:
      absorb_sorted(rest, C.Clip.ahead(rest, Nat.max(last, rl)), Nat.min(first, rf), Nat.max(last, rl),
        {==}, min_le_max(first, last, rf, rl, Nat.is_lt(first, rf), {==}, ho),
        and_true_right(C.Clip.apart(rest, rl), C.Clip.sorted(rest),
          and_true_right(Nat.is_le(rf, rl), Bool.and(C.Clip.apart(rest, rl), C.Clip.sorted(rest)), hs)))

def Laws.solid_sorted(first, last, rs, ordered, sorted):
  add_sorted(rs, C.Clip.behind(rs, first), C.Clip.ahead(rs, last), first, last, {==}, {==}, ordered, sorted)

# The draw's loop reaches its indices in order
# --------------------------------------------

def nat_eq_refl(i: Nat) -> {True{} == Nat.is_eq(i, i) : Bool}:
  match i:
    case 0n:
      {==}
    case 1n+p:
      nat_eq_refl(p)

def add_succ(m: Nat, +i: Nat) -> {Nat.add(m, 1n+i) == 1n+Nat.add(m, i) : Nat}:
  match m:
    case 0n:
      {==}
    case 1n++p:
      %add_succ(p, i) : {1n+Nat.add(p, 1n+i) == 1n+_ : Nat}
      {==}

def Laws.each_in_order(n, i):
  match n:
    case 0n:
      {==}
    case 1n++m:
      %nat_eq_refl(i)
        : {D.Draw.each(~Laws.Seq, ~Laws.Seq.see, m, 1n+i, Laws.Seq{_, 1n+i}) == Laws.Seq{True{}, 1n+Nat.add(m, i)} : Laws.Seq}
      %add_succ(m, i)
        : {D.Draw.each(~Laws.Seq, ~Laws.Seq.see, m, 1n+i, Laws.Seq{True{}, 1n+i}) == Laws.Seq{True{}, _} : Laws.Seq}
      Laws.each_in_order(m, 1n+i)

def Laws.animation_frames():
  {==}

def Laws.blue_door_locked():
  {==}

def Laws.key_taken():
  {==}

def Laws.key_taken_once():
  {==}

def Laws.key_reach():
  {==}

def Laws.key_through_door():
  {==}

def Laws.health_bonus():
  {==}

def Laws.stimpack():
  {==}

def Laws.medikit():
  {==}

def Laws.soul_sphere():
  {==}

def Laws.berserk():
  {==}

def Laws.armour_bonus():
  {==}

def Laws.green_armour():
  {==}

def Laws.blue_armour():
  {==}

def Laws.bonus_counted_once():
  {==}

def Laws.strength_counts():
  {==}

def Laws.ammo_amounts():
  {==}

def Laws.ammo_caps():
  {==}

def Laws.backpack_first():
  {==}

def Laws.backpack_later():
  {==}

def Laws.weapon_taken():
  {==}

def Laws.radius_within():
  {==}

def Laws.solid_stays():
  {==}

def Laws.blocker_geometry():
  {==}

def Laws.link_order():
  {==}

def Laws.thing_blocks():
  {==}

def Laws.floor_carries_things():
  {==}

def Laws.barrel_stops_door():
  {==}

def Laws.lamp_under_door():
  {==}

def Laws.door_opens_over_barrel():
  {==}

# Music: the reader's laws split on what follows, since Midi.drop
# matches the list even when its count is 0.

def Laws.sysex_skipped(rest):
  match rest:
    case []:
      {==}
    case h <> t:
      {==}

def Laws.end_of_track_ends(rest):
  match rest:
    case []:
      {==}
    case h <> t:
      {==}

def Laws.heap_one(e):
  {==}

def Laws.heap_ties():
  {==}

def Laws.quiet_offs(t, raw, key, vel):
  {==}

def Laws.mus_events():
  {==}

def Laws.smpte_division():
  {==}

def Laws.song_faults():
  {==}

def Laws.buffer_spills():
  {==}

def Laws.sfx_refusals():
  {==}

def Laws.sfx_rates_unserved(count, bytes):
  {==}

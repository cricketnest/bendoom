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
import ./src/sim.bend as S
import ./src/clip.bend as C
import ./src/project.bend as P
import ./src/draw.bend as D
import ./src/segs.bend as R
import ./src/planes.bend as N
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

# Keys: a key's flag set twice keeps the second setting; the eight
# flags are rewritten one by one, abstracted from the key code.

def set_twice(b: Bool, +d1: Bool, +d2: Bool, +old: Bool) ->
  {K.Keys.set(b, d2, old) == K.Keys.set(b, d2, K.Keys.set(b, d1, old)) : Bool}:
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def press8(b1: Bool, b2: Bool, b3: Bool, b4: Bool, b5: Bool, b6: Bool, b7: Bool, b8: Bool, +d1: Bool, +d2:
  Bool, +up: Bool, +dn: Bool, +left: Bool, +right: Bool, +sleft: Bool, +sright: Bool, +run: Bool, +use:
  Bool) ->
  {K.Keys{K.Keys.set(b1, d2, K.Keys.set(b1, d1, up)), K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)),
    K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)),
    K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)),
    K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use))}
    == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4, d2,
      right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
      K.Keys.set(b8, d2, use)} : K.Keys}:
  %set_twice(b1, d1, d2, up)
    : {K.Keys{_, K.Keys.set(b2, d2, K.Keys.set(b2, d1, dn)), K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)),
      K.Keys.set(b4, d2, K.Keys.set(b4, d1, right)), K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)),
      K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)),
      K.Keys.set(b8, d2, K.Keys.set(b8, d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b2, d1, d2, dn)
    : {K.Keys{K.Keys.set(b1, d2, up), _, K.Keys.set(b3, d2, K.Keys.set(b3, d1, left)), K.Keys.set(b4, d2,
      K.Keys.set(b4, d1, right)), K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2,
      K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2,
      K.Keys.set(b8, d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b3, d1, d2, left)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), _, K.Keys.set(b4, d2, K.Keys.set(b4, d1,
      right)), K.Keys.set(b5, d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1,
      sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b4, d1, d2, right)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), _, K.Keys.set(b5,
      d2, K.Keys.set(b5, d1, sleft)), K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2,
      K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b5, d1, d2, sleft)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4, d2,
      right), _, K.Keys.set(b6, d2, K.Keys.set(b6, d1, sright)), K.Keys.set(b7, d2, K.Keys.set(b7, d1,
      run)), K.Keys.set(b8, d2, K.Keys.set(b8, d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b6, d1, d2, sright)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4, d2,
      right), K.Keys.set(b5, d2, sleft), _, K.Keys.set(b7, d2, K.Keys.set(b7, d1, run)), K.Keys.set(b8, d2,
      K.Keys.set(b8, d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b7, d1, d2, run)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4, d2,
      right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), _, K.Keys.set(b8, d2, K.Keys.set(b8,
      d1, use))}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  %set_twice(b8, d1, d2, use)
    : {K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4, d2,
      right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run), _}
      == K.Keys{K.Keys.set(b1, d2, up), K.Keys.set(b2, d2, dn), K.Keys.set(b3, d2, left), K.Keys.set(b4,
        d2, right), K.Keys.set(b5, d2, sleft), K.Keys.set(b6, d2, sright), K.Keys.set(b7, d2, run),
        K.Keys.set(b8, d2, use)} : K.Keys}
  {==}

def Laws.last_press(code, d1, d2, keys):
  match keys:
    case K.Keys{up, dn, left, right, sleft, sright, run, use}:
      press8(U32.is_eq(code, 63232) || U32.is_eq(code, 119),
        U32.is_eq(code, 63233) || U32.is_eq(code, 115), U32.is_eq(code, 63234),
        U32.is_eq(code, 63235), U32.is_eq(code, 97), U32.is_eq(code, 100),
        U32.is_eq(code, 65592) || U32.is_eq(code, 65596), U32.is_eq(code, 32), d1, d2, up, dn, left,
        right, sleft, sright, run, use)

def Laws.arrows_wasd(down, keys):
  match keys:
    case K.Keys{up, dn, left, right, sleft, sright, run, use}:
      {==}

def Laws.tic_rest(level, x, y):
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

def Laws.replay_append(a, b, level, p):
  match a:
    case []:
      {==}
    case cmd <> rest:
      Laws.replay_append(rest, b, level, S.Sim.tic(level, cmd, p))

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

# Narrowing a fit keeps its verdict, so a line's height pass does too,
# and a line's pass ands its condition onto the verdict: a True verdict
# after a line means the condition and the verdict before both held.
def narrow_keeps(hit: Bool, +level: L.Level, +line: L.Level.Line, f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.narrow(hit, level, line, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match hit f:
    case True{} S.Fit{ok, floor, ceil}:
      e
    case False{} S.Fit{ok, floor, ceil}:
      e

def heights_keeps(+level: L.Level, +x: U32, +y: U32, line: L.Level.Line, f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.heights(level, x, y, line, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match line:
    case L.Line{+x1, +y1, +x2, +y2, +flags, +front, +back}:
      narrow_keeps(Bool.and(Bool.not(U32.is_eq(back, L.Level.none())),
        Bool.and(S.Sim.box_touches(x, y, L.Line{x1, y1, x2, y2, flags, front, back}),
          S.Sim.box_crosses(x, y, L.Line{x1, y1, x2, y2, flags, front, back}))),
        level, L.Line{x1, y1, x2, y2, flags, front, back}, f, e)

def and_ok_right(+b: Bool, g: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.and(b, g)) : Bool}) -> {True{} == b : Bool}:
  match g:
    case S.Fit{ok, floor, ceil}:
      and_true_right(ok, b, e)

def and_ok_left(+b: Bool, g: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.and(b, g)) : Bool}) -> {True{} == S.Sim.Fit.ok(g) : Bool}:
  match g:
    case S.Fit{ok, floor, ceil}:
      and_true_left(ok, b, e)

def line_ok_of(+level: L.Level, +x: U32, +y: U32, +i: U32, +f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.line(level, x, y, i, f)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, i) : Bool}:
  and_ok_right(S.Sim.line_ok(level, x, y, i),
    S.Sim.fit.heights(level, x, y, L.Level.line(level, i), f), e)

def fit_of(+level: L.Level, +x: U32, +y: U32, +i: U32, +f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.line(level, x, y, i, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  heights_keeps(level, x, y, L.Level.line(level, i), f,
    and_ok_left(S.Sim.line_ok(level, x, y, i),
      S.Sim.fit.heights(level, x, y, L.Level.line(level, i), f), e))

# The fold only ands: a True verdict at the end means one at the start.
def go_keeps(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +f: S.Sim.Fit,
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.go(lines, level, x, y, f)) : Bool}) ->
  {True{} == S.Sim.Fit.ok(f) : Bool}:
  match lines:
    case []:
      e
    case +i <> rest:
      fit_of(level, x, y, i, f, go_keeps(rest, level, x, y, S.Sim.fit.line(level, x, y, i, f), e))

def some_eq(+i: U32, +h: U32, e: {Some{i} == Some{h} : Maybe<&2, U32>}) -> {h == i : U32}:
  Equal.cong(Maybe<&2, U32>, U32, m => Maybe.default(&2, U32, m, 0), Some{h}, Some{i},
    Equal.sym(Maybe<&2, U32>, Some{i}, Some{h}, e))

# A True verdict over a list means the condition holds for each line in
# it, by its position.
def go_pins(lines: List<&2, U32>, +level: L.Level, +x: U32, +y: U32, +f: S.Sim.Fit,
  k: Nat, +i: U32, listed: {Some{i} == List.get(&2, U32, lines, k) : Maybe<&2, U32>},
  e: {True{} == S.Sim.Fit.ok(S.Sim.fit.go(lines, level, x, y, f)) : Bool}) ->
  {True{} == S.Sim.line_ok(level, x, y, i) : Bool}:
  match lines k:
    case [] _:
      %listed : MD(_, Unit, {True{} == S.Sim.line_ok(level, x, y, i) : Bool})
      Unit{}
    case +h <> rest 0n:
      %some_eq(i, h, listed) : {True{} == S.Sim.line_ok(level, x, y, _) : Bool}
      line_ok_of(level, x, y, h, f, go_keeps(rest, level, x, y, S.Sim.fit.line(level, x, y, h, f), e))
    case +h <> rest 1n+j:
      go_pins(rest, level, x, y, S.Sim.fit.line(level, x, y, h, f), j, i, listed, e)

def Laws.free_pins_lines(level, x, y, k, i, listed, free):
  go_pins(S.Sim.lines(level, (x - S.Sim.radius() : U32), (y - S.Sim.radius() : U32),
    (x + S.Sim.radius() : U32), (y + S.Sim.radius() : U32)), level, x, y,
    S.Fit{True{}, L.Level.floor(level, L.Level.sector_at(level, x, y)),
      L.Level.ceil(level, L.Level.sector_at(level, x, y))}, k, i, listed, free)

# The wall law
# ------------

# Free: the player's position passes Sim.fit. Every move the sim takes
# has passed it, so each function from the tic down keeps it: a lemma a
# function, on the flag it decides by and the record it opens.
def Free(level: L.Level, +p: S.Player) -> Type:
  {True{} == S.Sim.free(level, S.Player.x(p), S.Player.y(p)) : Bool}

def Xy.player(s: S.Sim.Xy) -> S.Player:
  S.Xy{done, p, xm, ym} = s
  p

def fin_free(+level: L.Level, go: Bool, p: S.Player, +x: U32, +y: U32, floor: U32, ceil: U32,
  +ok: Bool, fl: U32, cl: U32, +h: Bool, e: {go == Bool.and(ok, h) : Bool},
  hf: {S.Fit{ok, fl, cl} == S.Sim.fit(level, x, y) : S.Sim.Fit}, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move.fin(go, p, x, y, floor, ceil))):
  match go p:
    case False{} S.Player{+px, +py, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp
    case True{} S.Player{+px, +py, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      %hf : {True{} == S.Sim.Fit.ok(_) : Bool}
      and_true_left(ok, h, e)

def fit_free(+level: L.Level, +p: S.Player, +x: U32, +y: U32, f: S.Sim.Fit,
  hf: {f == S.Sim.fit(level, x, y) : S.Sim.Fit}, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move.fit(p, x, y, f))):
  match f:
    case S.Fit{+ok, +floor, +ceil}:
      fin_free(level, Bool.and(ok, Bool.and(F.Fixed.ge((ceil - floor : U32), S.Sim.height()),
        Bool.and(F.Fixed.ge((ceil - S.Player.z(p) : U32), S.Sim.height()),
          F.Fixed.le((floor - S.Player.z(p) : U32), S.Sim.step_up())))), p, x, y, floor, ceil, ok,
        floor, ceil, Bool.and(F.Fixed.ge((ceil - floor : U32), S.Sim.height()),
          Bool.and(F.Fixed.ge((ceil - S.Player.z(p) : U32), S.Sim.height()),
            F.Fixed.le((floor - S.Player.z(p) : U32), S.Sim.step_up()))), {==}, hf, hp)

def try_free(+level: L.Level, +p: S.Player, +x: U32, +y: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.try_move(level, p, x, y))):
  fit_free(level, p, x, y, S.Sim.fit(level, x, y), {==}, hp)

def stairstep_fin_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.stairstep.fin(level, t)):
  match t:
    case S.Try{True{}, p}:
      ht
    case S.Try{False{}, +p}:
      try_free(level, p, (S.Player.x(p) + S.Player.momx(p) : U32), S.Player.y(p), ht)

def stairstep_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.stairstep(level, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      stairstep_fin_free(level, S.Sim.try_move(level,
        S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, x, (y + momy : U32)),
        try_free(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, x, (y + momy : U32), hp))

def wall_go_free(+level: L.Level, p: S.Player, m: U32 & U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.wall.go(level, p, m))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      (+mx, +my) = m
      try_free(level, S.Player{x, y, z, angle, mx, my, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, (x + mx : U32),
        (y + my : U32), hp)

def wall_free(left: Bool, +level: L.Level, p: S.Player, +frac: U32, i: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.wall(left, level, p, frac, i))):
  match left p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      wall_go_free(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
        S.Sim.along(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, i,
          F.Fixed.mul(momx, frac), F.Fixed.mul(momy, frac)), hp)

def rest_free(+level: L.Level, p: S.Player, +frac: U32, i: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.rest(level, p, frac, i))):
  wall_free(F.Fixed.gt(F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32)), 0),
    level, p, F.Fixed.min(F.Fixed.unit(), (F.Fixed.unit() - frac - 2048 : U32)), i, hp)

def upto_fin_free(+level: L.Level, +frac: U32, i: U32, t: S.Sim.Try,
  ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.upto.fin(level, frac, i, t))):
  match t:
    case S.Try{True{}, p}:
      rest_free(level, p, frac, i, ht)
    case S.Try{False{}, p}:
      stairstep_free(level, p, ht)

def upto_free(some: Bool, +level: L.Level, p: S.Player, +frac: U32, i: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.upto(some, level, p, frac, i))):
  match some p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      rest_free(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, frac, i, hp)
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      upto_fin_free(level, frac, i, S.Sim.try_move(level,
        S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
        (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32)),
        try_free(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
          (x + F.Fixed.mul(momx, frac) : U32), (y + F.Fixed.mul(momy, frac) : U32), hp))

def found_free(hit: Bool, +level: L.Level, p: S.Player, +frac: U32, i: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.found(hit, level, p, frac, i))):
  match hit:
    case False{}:
      stairstep_free(level, p, hp)
    case True{}:
      upto_free(F.Fixed.gt(frac, 0), level, p, frac, i, hp)

def hit_free(+level: L.Level, p: S.Player, best: U32 & U32, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.hit(level, p, best))):
  (+frac, i) = best
  found_free(U32.is_le(frac, F.Fixed.unit()), level, p, (frac - 2048 : U32), i, hp)

def once_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.Try.player(S.Sim.slide.once(level, p))):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hit_free(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
        S.Sim.trace(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
          S.Sim.lead(x, momx), S.Sim.trail(y, momy), (S.Sim.lead(x, momx) + momx : U32),
          (S.Sim.trail(y, momy) + momy : U32),
          S.Sim.trace(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
            S.Sim.trail(x, momx), S.Sim.lead(y, momy), (S.Sim.trail(x, momx) + momx : U32),
            (S.Sim.lead(y, momy) + momy : U32),
            S.Sim.trace(level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
              S.Sim.lead(x, momx), S.Sim.lead(y, momy), (S.Sim.lead(x, momx) + momx : U32),
              (S.Sim.lead(y, momy) + momy : U32), ((F.Fixed.unit() + 1 : U32), 0)))), hp)

def slide_go_free(fuel: Nat, +level: L.Level, st: S.Sim.Try, hs: Free(level, S.Sim.Try.player(st))) ->
  Free(level, S.Sim.slide.go(fuel, level, st)):
  match fuel st:
    case 0n S.Try{True{}, p}:
      hs
    case 1n+f S.Try{True{}, p}:
      hs
    case 0n S.Try{False{}, p}:
      stairstep_free(level, p, hs)
    case 1n+f S.Try{False{}, +p}:
      slide_go_free(f, level, S.Sim.slide.once(level, p), once_free(level, p, hs))

def slide_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.slide(level, p)):
  slide_go_free(2n, level, S.Try{False{}, p}, hp)

def tried_free(+level: L.Level, t: S.Sim.Try, ht: Free(level, S.Sim.Try.player(t))) ->
  Free(level, S.Sim.xy.tried(level, t)):
  match t:
    case S.Try{True{}, p}:
      ht
    case S.Try{False{}, p}:
      slide_free(level, p, ht)

def xy_fin_free(+level: L.Level, +p: S.Player, +tx: U32, +ty: U32, xm: U32, ym: U32,
  hp: Free(level, p)) -> Free(level, Xy.player(S.Sim.xy.fin(level, p, tx, ty, xm, ym))):
  tried_free(level, S.Sim.try_move(level, p, tx, ty), try_free(level, p, tx, ty, hp))

def step_free(big: Bool, +level: L.Level, +p: S.Player, +xm: U32, +ym: U32, hp: Free(level, p)) ->
  Free(level, Xy.player(S.Sim.xy.step(big, level, p, xm, ym))):
  match big:
    case True{}:
      xy_fin_free(level, p, (S.Player.x(p) + F.Fixed.half(xm) : U32),
        (S.Player.y(p) + F.Fixed.half(ym) : U32), F.Fixed.sar(xm), F.Fixed.sar(ym), hp)
    case False{}:
      xy_fin_free(level, p, (S.Player.x(p) + xm : U32), (S.Player.y(p) + ym : U32), 0, 0, hp)

def xy_go_free(fuel: Nat, +level: L.Level, st: S.Sim.Xy, hs: Free(level, Xy.player(st))) ->
  Free(level, S.Sim.xy.go(fuel, level, st)):
  match fuel st:
    case 0n S.Xy{True{}, p, xm, ym}:
      hs
    case 1n+f S.Xy{True{}, p, xm, ym}:
      hs
    case 0n S.Xy{False{}, p, xm, ym}:
      hs
    case 1n+f S.Xy{False{}, +p, +xm, +ym}:
      xy_go_free(f, level, S.Sim.xy.step(S.Sim.big(xm, ym), level, p, xm, ym),
        step_free(S.Sim.big(xm, ym), level, p, xm, ym, hs))

def slow_free(stop: Bool, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.slow(stop, p)):
  match stop p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp

def ground_free(+level: L.Level, cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.friction.ground(cmd, p)):
  match cmd p:
    case K.Cmd{+forward, +side, +turn, +use} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      slow_free(Bool.and(S.Sim.crawling(momx), Bool.and(S.Sim.crawling(momy),
        Bool.and(U32.is_zero(forward), U32.is_zero(side)))), level,
        S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, hp)

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

def moving_free(moving: Bool, +level: L.Level, +cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.xy.moving(moving, level, cmd, p)):
  match moving p:
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      friction_free(level, cmd, S.Sim.xy.go(2n, level, S.Xy{False{},
        S.Player{x, y, z, angle, S.Sim.clamp(momx), S.Sim.clamp(momy), momz, floorz, ceilz, viewheight,
          deltaview, viewz, tic},
        S.Sim.clamp(momx), S.Sim.clamp(momy)}),
        xy_go_free(2n, level, S.Xy{False{},
          S.Player{x, y, z, angle, S.Sim.clamp(momx), S.Sim.clamp(momy), momz, floorz, ceilz,
            viewheight, deltaview, viewz, tic},
          S.Sim.clamp(momx), S.Sim.clamp(momy)}, hp))

def xy_free(+level: L.Level, +cmd: K.Cmd, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.xy(level, cmd, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      moving_free(Bool.not(Bool.and(U32.is_zero(momx), U32.is_zero(momy))), level, cmd,
        S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, hp)

# Thrust, turning, the eye, the vertical move and the clock keep the
# position.
def thrust_free(+level: L.Level, p: S.Player, +angle: U32, +move: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.thrust(level, p, angle, move)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
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
    case K.Cmd{+forward, +side, +turn, +use} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      push_free(level, S.Sim.push(level, S.Player{x, y, z, (angle + (turn << 16n) : U32), momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
        (angle + (turn << 16n) : U32), forward),
        ((angle + (turn << 16n) : U32) - A.Angle.ang90() : U32), side,
        push_free(level, S.Player{x, y, z, (angle + (turn << 16n) : U32), momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
          (angle + (turn << 16n) : U32), forward, hp))

def eye_if_free(ground: Bool, +level: L.Level, p: S.Player, +bob: U32, hp: Free(level, p)) ->
  Free(level, S.Sim.eye.if(ground, level, p, bob)):
  match ground p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp

def eye_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.eye(level, p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      eye_if_free(S.Player.onground(S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}), level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic},
        F.Fixed.min(S.Sim.maxbob(),
          ((F.Fixed.mul(momx, momx) + F.Fixed.mul(momy, momy) : U32) >> 2n : U32)), hp)

def z_if_free(still: Bool, +level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.z.if(still, p)):
  match still p:
    case True{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp
    case False{} S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp

def z_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.z(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      z_if_free(Bool.and(U32.is_eq(z, floorz), U32.is_zero(momz)), level, S.Player{x, y, z, angle, momx, momy, momz, floorz, ceilz, viewheight, deltaview, viewz, tic}, hp)

def clock_free(+level: L.Level, p: S.Player, hp: Free(level, p)) ->
  Free(level, S.Sim.clock(p)):
  match p:
    case S.Player{+x, +y, +z, +angle, +momx, +momy, +momz, +floorz, +ceilz, +viewheight, +deltaview, +viewz, +tic}:
      hp

def Laws.tic_keeps_free(level, cmd, p, free):
  clock_free(level, S.Sim.z(S.Sim.xy(level, cmd, S.Sim.eye(level, S.Sim.move(level, cmd, p)))),
    z_free(level, S.Sim.xy(level, cmd, S.Sim.eye(level, S.Sim.move(level, cmd, p))),
      xy_free(level, cmd, S.Sim.eye(level, S.Sim.move(level, cmd, p)),
        eye_free(level, S.Sim.move(level, cmd, p), move_free(level, cmd, p, free)))))

def Laws.replay_keeps_free(script, level, p, free):
  match script:
    case []:
      free
    case +cmd <> rest:
      Laws.replay_keeps_free(rest, level, S.Sim.tic(level, cmd, p),
        Laws.tic_keeps_free(level, cmd, p, free))

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

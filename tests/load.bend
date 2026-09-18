# E1M1's level record and graphics from the WAD named by BENDOOM_IWAD,
# loaded by the game's loaders: samples of what the renderer reads. Each
# expected value was read from Freedoom's bytes independently, in
# nushell, before the loader answered it; the multi-patch texels were
# composed there by vanilla's rule, patches pasted in order.
import Base
import ../src/bytes.bend as B
import ../src/fixed.bend as F
import ../src/angle.bend as A
import ../src/level.bend as L
import ../src/gfx.bend as G

def seg(+i: U32, s: L.Level.Seg) -> String:
  L.Seg{x1, y1, x2, y2, angle, offset, flags, side, front, back} = s
  "seg " ++ U32.show(i) ++ " from " ++ F.Fixed.show(x1) ++ " " ++ F.Fixed.show(y1) ++ " to "
    ++ F.Fixed.show(x2) ++ " " ++ F.Fixed.show(y2) ++ " angle " ++ A.Angle.show(angle)
    ++ " offset " ++ F.Fixed.show(offset) ++ " flags " ++ U32.show(flags) ++ " side "
    ++ U32.show(side) ++ " front " ++ U32.show(front) ++ " back " ++ U32.show(back)

def sub(s: L.Level.Sub) -> String:
  L.Sub{count, first} = s
  "subsector 681 segs " ++ U32.show(count) ++ " first " ++ U32.show(first)

def box(b: L.Level.Box) -> String:
  L.Box{top, bottom, left, right} = b
  F.Fixed.show(top) ++ " " ++ F.Fixed.show(bottom) ++ " " ++ F.Fixed.show(left) ++ " "
    ++ F.Fixed.show(right)

def names(xs: List<&2, String>) -> String:
  String.join(xs, " ")

def sector(+level: L.Level, +gfx: G.Gfx, +i: U32, s: L.Level.Sector) -> String:
  L.Sector{floor, ceil, light} = s
  "sector " ++ U32.show(i) ++ " floor " ++ F.Fixed.show(floor) ++ " ceil " ++ F.Fixed.show(ceil)
    ++ " light " ++ U32.show(light) ++ " flats " ++ names(L.Level.flat_names(level, i))
    ++ " sky " ++ Bool.show(U32.is_eq(G.Gfx.ceilpic(gfx, i), G.Gfx.sky(gfx)))

def side(+level: L.Level, +i: U32, s: L.Level.Side) -> String:
  L.Side{xoff, yoff, sector} = s
  "side " ++ U32.show(i) ++ " offset " ++ F.Fixed.show(xoff) ++ " " ++ F.Fixed.show(yoff)
    ++ " sector " ++ U32.show(sector) ++ " textures " ++ names(L.Level.side_names(level, i))

def shows(xs: List<&2, U32>) -> List<&2, String>:
  match xs:
    case []:
      []
    case x <> rest:
      U32.show(x) <> shows(rest)

def show(xs: List<&2, U32>) -> String:
  String.join(shows(xs), " ")

# The palette at 4, 176 and 255; four colormap entries; the floor flat
# of sector 9 and the ceiling flat of sector 140 at texels 0 and 2077.
def peeks(+gfx: G.Gfx) -> List<&2, U32>:
  [(G.Gfx.palette() + 4 : U32), (G.Gfx.palette() + 176 : U32), (G.Gfx.palette() + 255 : U32),
    (G.Gfx.colormap() + 4 : U32), (G.Gfx.colormap() + 16 * 256 + 4 : U32),
    (G.Gfx.colormap() + 31 * 256 + 176 : U32), (G.Gfx.colormap() + 32 * 256 + 4 : U32),
    G.Gfx.flat(gfx, G.Gfx.floorpic(gfx, 9)), (G.Gfx.flat(gfx, G.Gfx.floorpic(gfx, 9)) + 2077 : U32),
    G.Gfx.flat(gfx, G.Gfx.ceilpic(gfx, 140)), (G.Gfx.flat(gfx, G.Gfx.ceilpic(gfx, 140)) + 2077 : U32)]

def texture(+gfx: G.Gfx, name: String, +t: U32) -> String:
  "texture " ++ name ++ " " ++ U32.show(G.Gfx.tex.width(gfx, t)) ++ "x"
    ++ F.Fixed.show(G.Gfx.tex.height(gfx, t)) ++ " patches " ++ U32.show(G.Gfx.tex.patches(gfx, t))
    ++ " mask " ++ U32.show(G.Gfx.tex.mask(gfx, t))

def from(+i: U32, offs: List<&2, U32>) -> List<&2, U32>:
  match offs:
    case []:
      []
    case o <> rest:
      (i + o - 3 : U32) <> from(i, rest)

# Offsets are from three before a column's texels, where its first
# post's header sits. Multi-patch COMPUTE1 and LITE3 (sides 1386 and
# 520) at rows 0, 1, 64 and 127 of column 0; single-patch STARGR1 (side
# 645) and the sky at rows 0, 1 and 64; masked CEILVINE (side 419)
# column 17's first two posts and AQMETL21 (side 216) column 0's first,
# each as top, length and first texel.
def texels(+gfx: G.Gfx) -> List<&2, U32>:
  List.concat(&2, U32, [
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 1386), 0), [3, 4, 67, 130]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 520), 0), [3, 4, 67, 130]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 645), 0), [3, 4, 67]),
    from(G.Gfx.column(gfx, G.Gfx.skytex(gfx), 0), [3, 4, 67]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 419), 17), [0, 1, 3, 20, 21, 23]),
    from(G.Gfx.column(gfx, G.Gfx.mid(gfx, 216), 0), [0, 1, 3])])

def report.go(mem: Array<U32>, gl: G.Gfx & L.Level) -> IO(Unit):
  (+gfx, +level) = gl
  do IO<Unit>:
    IO.print(seg(0, L.Level.seg(level, 0)))
    IO.print(seg(75, L.Level.seg(level, 75)))
    IO.print(sub(L.Level.sub(level, 681)))
    IO.print("node 680 right " ++ box(L.Level.box(level, 680, 0)) ++ " left " ++ box(L.Level.box(level, 680, 1)))
    IO.print(sector(level, gfx, 14, L.Level.sector(level, 14)))
    IO.print(sector(level, gfx, 140, L.Level.sector(level, 140)))
    IO.print(side(level, 0, L.Level.side(level, 0)))
    IO.print(side(level, 5, L.Level.side(level, 5)))
    IO.print(texture(gfx, "COMPUTE1", G.Gfx.mid(gfx, 1386)))
    IO.print(texture(gfx, "DOOR1", G.Gfx.top(gfx, 526)))
    IO.print(texture(gfx, "SKY1", G.Gfx.skytex(gfx)))
    IO.print("side 526 textures " ++ U32.show(G.Gfx.top(gfx, 526)) ++ " " ++ U32.show(G.Gfx.bottom(gfx, 526))
      ++ " " ++ U32.show(G.Gfx.mid(gfx, 526)))
    IO.print("palette colormap flats texels " ++ show(Pair.snd(Array<U32>, List<&2, U32>,
      B.Bytes.each(~U32, ~B.Bytes.at, List.append(&2, U32, peeks(gfx), texels(gfx)), mem))))

def report(w: Array<U32> & G.Gfx & L.Level) -> IO(Unit):
  (mem, gl) = w
  report.go(mem, gl)

def main() -> IO(Unit):
  do IO<Unit>:
    world : Array<U32> & G.Gfx & L.Level <- G.Gfx.open()
    report(world)

#|seg 0 from 448.000000 896.000000 to 256.000000 896.000000 angle 180.000 offset 0.000000 flags 4 side 344 front 122 back 8
#|seg 75 from -208.000000 1472.000000 to 0.000000 1472.000000 angle 0.000 offset 112.000000 flags 4 side 337 front 135 back 36
#|subsector 681 segs 4 first 2053
#|node 680 right 2336.000000 64.000000 -704.000000 3248.000000 left 64.000000 -1064.000000 -128.000000 2544.000000
#|sector 14 floor -80.000000 ceil 536.000000 light 224 flats RROCK18 F_SKY1 sky True
#|sector 140 floor 0.000000 ceil 128.000000 light 192 flats AQF054 SLIME14 sky False
#|side 0 offset 53.000000 -24.000000 sector 15 textures - - MC5
#|side 5 offset 94.000000 0.000000 sector 46 textures - MC18 -
#|texture COMPUTE1 128x128.000000 patches 10 mask 127
#|texture DOOR1 64x72.000000 patches 1 mask 63
#|texture SKY1 256x128.000000 patches 1 mask 255
#|side 526 textures 60 61 0
#|palette colormap flats texels 16777215 16711680 10972011 4 97 0 0 149 148 6 15 98 97 98 104 108 108 108 7 110 110 108 87 87 92 0 16 122 20 7 78 86 4 106

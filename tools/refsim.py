#!/usr/bin/env python3
"""The oracle for tests/sim.bend: Doom's player movement (p_user.c,
p_mobj.c, p_map.c, p_maputl.c) for one player and no things, written
independently of the Bend sim with the same two simplifications (z
tracks the floor; the slide's traces gather lines from the cells of the
trace's box). Prints the lines the test must print for a script:

    python3 tools/refsim.py tables.json $BENDOOM_IWAD U:1 "U!:34" L:20

The first argument is Doom's tables as JSON ({"finesine": [...],
"tantoangle": [...]}, from tables.c as tools/gen_tables.py reads it),
the second the WAD.
"""
import json
import struct
import sys

FRACUNIT = 65536
MAXMOVE = 30 * FRACUNIT
STOPSPEED = 0x1000
FRICTION = 0xe800
RADIUS = 16 * FRACUNIT
HEIGHT = 56 * FRACUNIT
MAXRADIUS = 32 * FRACUNIT
ML_BLOCKING = 1
ML_TWOSIDED = 4
ANG90 = 0x40000000
ANG180 = 0x80000000
ANG270 = 0xc0000000
SLOPERANGE = 2048
INT_MIN = -2 ** 31
INT_MAX = 2 ** 31 - 1

T = json.load(open(sys.argv[1]))
sys.argv.pop(1)
FINESINE = T["finesine"]
TANTOANGLE = T["tantoangle"]


def s32(x):
    x &= 0xffffffff
    return x - 2 ** 32 if x >= 2 ** 31 else x


def u32(x):
    return x & 0xffffffff


def fmul(a, b):
    return s32((a * b) >> 16)


def fdiv(a, b):
    if (abs(a) >> 14) >= abs(b):
        return INT_MIN if (a ^ b) < 0 else INT_MAX
    q = (abs(a) << 16) // abs(b)
    return -q if (a < 0) != (b < 0) else q


def sar(x, n):
    return x >> n  # python's >> on ints is arithmetic


def finesine(i):
    return FINESINE[i]


def finecos(i):
    return FINESINE[i + 2048]


def slopediv(num, den):
    num &= 0xffffffff
    den &= 0xffffffff
    if den < 512:
        return SLOPERANGE
    ans = (u32(num << 3)) // (den >> 8)
    return ans if ans <= SLOPERANGE else SLOPERANGE


def point_to_angle(x, y):
    if x == 0 and y == 0:
        return 0
    if x >= 0:
        if y >= 0:
            if x > y:
                return u32(TANTOANGLE[slopediv(y, x)])
            return u32(ANG90 - 1 - TANTOANGLE[slopediv(x, y)])
        y = -y
        if x > y:
            return u32(-TANTOANGLE[slopediv(y, x)])
        return u32(ANG270 + TANTOANGLE[slopediv(x, y)])
    x = -x
    if y >= 0:
        if x > y:
            return u32(ANG180 - 1 - TANTOANGLE[slopediv(y, x)])
        return u32(ANG90 + TANTOANGLE[slopediv(x, y)])
    y = -y
    if x > y:
        return u32(ANG180 + TANTOANGLE[slopediv(y, x)])
    return u32(ANG270 - 1 - TANTOANGLE[slopediv(x, y)])


def approx_distance(dx, dy):
    dx = abs(dx)
    dy = abs(dy)
    if dx < dy:
        return dx + dy - (dx >> 1)
    return dx + dy - (dy >> 1)


class Level:
    def __init__(self, path):
        d = open(path, "rb").read()
        magic, n, off = struct.unpack_from("<4sII", d, 0)
        lumps = []
        for i in range(n):
            pos, size, name = struct.unpack_from("<II8s", d, off + 16 * i)
            lumps.append((name.rstrip(b"\0").decode(), pos, size))
        names = [l[0] for l in lumps]
        m = names.index("E1M1")

        def lump(nm):
            k = names.index(nm, m)
            return d[lumps[k][1]:lumps[k][1] + lumps[k][2]]

        def recs(nm, fmt):
            b = lump(nm)
            sz = struct.calcsize(fmt)
            return [struct.unpack_from(fmt, b, i * sz) for i in range(len(b) // sz)]

        self.things = recs("THINGS", "<hhhhh")
        self.lines = recs("LINEDEFS", "<HHHHHHH")   # v1 v2 flags special tag s0 s1
        self.sides = recs("SIDEDEFS", "<hh8s8s8sH")
        self.verts = recs("VERTEXES", "<hh")
        self.segs = recs("SEGS", "<HHHHHh")           # v1 v2 angle line side offset
        self.ssecs = recs("SSECTORS", "<HH")          # numsegs firstseg
        self.nodes = recs("NODES", "<hhhhhhhhhhhhHH")  # x y dx dy bbox[8] c0 c1
        self.sectors = recs("SECTORS", "<hh8s8shhh")
        bm = lump("BLOCKMAP")
        self.bm = [struct.unpack_from("<H", bm, 2 * i)[0] for i in range(len(bm) // 2)]
        self.bmorgx = s16(self.bm[0]) << 16
        self.bmorgy = s16(self.bm[1]) << 16
        self.bmw = self.bm[2]
        self.bmh = self.bm[3]
        for t in self.things:
            if t[3] == 1:
                self.start = (t[0] << 16, t[1] << 16, u32((t[2] // 45) * 0x20000000))

    # geometry
    def vx(self, i):
        return self.verts[i][0] << 16

    def vy(self, i):
        return self.verts[i][1] << 16

    def line_dx(self, l):
        return self.vx(self.lines[l][1]) - self.vx(self.lines[l][0])

    def line_dy(self, l):
        return self.vy(self.lines[l][1]) - self.vy(self.lines[l][0])

    def line_bbox(self, l):
        x1, x2 = self.vx(self.lines[l][0]), self.vx(self.lines[l][1])
        y1, y2 = self.vy(self.lines[l][0]), self.vy(self.lines[l][1])
        return (max(y1, y2), min(y1, y2), min(x1, x2), max(x1, x2))  # top bottom left right

    def slopetype(self, l):
        dx, dy = self.line_dx(l), self.line_dy(l)
        if dx == 0:
            return "V"
        if dy == 0:
            return "H"
        return "P" if fdiv(dy, dx) > 0 else "N"

    def side_sector(self, s):
        return self.sides[s][5] if s != 0xffff else None

    def floor(self, sec):
        return self.sectors[sec][0] << 16

    def ceil(self, sec):
        return self.sectors[sec][1] << 16

    def front(self, l):
        return self.side_sector(self.lines[l][5])

    def back(self, l):
        return self.side_sector(self.lines[l][6])

    def cell_lines(self, bx, by):
        if bx < 0 or by < 0 or bx >= self.bmw or by >= self.bmh:
            return []
        off = self.bm[4 + by * self.bmw + bx]
        out = []
        i = off + 1  # skip the leading 0
        while self.bm[i] != 0xffff:
            out.append(self.bm[i])
            i += 1
        return out

    def point_on_side(self, x, y, l):
        dx, dy = self.line_dx(l), self.line_dy(l)
        v1x, v1y = self.vx(self.lines[l][0]), self.vy(self.lines[l][0])
        if dx == 0:
            if x <= v1x:
                return 1 if dy > 0 else 0
            return 1 if dy < 0 else 0
        if dy == 0:
            if y <= v1y:
                return 1 if dx < 0 else 0
            return 1 if dx > 0 else 0
        pdx = x - v1x
        pdy = y - v1y
        left = fmul(sar(dy, 16), pdx)
        right = fmul(pdy, sar(dx, 16))
        return 0 if right < left else 1

    def box_on_side(self, box, l):
        top, bottom, left, right = box
        st = self.slopetype(l)
        v1x, v1y = self.vx(self.lines[l][0]), self.vy(self.lines[l][0])
        if st == "H":
            p1 = int(top > v1y)
            p2 = int(bottom > v1y)
            if self.line_dx(l) < 0:
                p1 ^= 1
                p2 ^= 1
        elif st == "V":
            p1 = int(right < v1x)
            p2 = int(left < v1x)
            if self.line_dy(l) < 0:
                p1 ^= 1
                p2 ^= 1
        elif st == "P":
            p1 = self.point_on_side(left, top, l)
            p2 = self.point_on_side(right, bottom, l)
        else:
            p1 = self.point_on_side(right, top, l)
            p2 = self.point_on_side(left, bottom, l)
        return p1 if p1 == p2 else -1

    def node_side(self, x, y, n):
        nx, ny, ndx, ndy = [v << 16 for v in self.nodes[n][:4]]
        if ndx == 0:
            if x <= nx:
                return int(ndy > 0)
            return int(ndy < 0)
        if ndy == 0:
            if y <= ny:
                return int(ndx < 0)
            return int(ndx > 0)
        dx = x - nx
        dy = y - ny
        if u32(ndy ^ ndx ^ dx ^ dy) & 0x80000000:
            return 1 if u32(ndy ^ dx) & 0x80000000 else 0
        left = fmul(sar(ndy, 16), dx)
        right = fmul(dy, sar(ndx, 16))
        return 0 if right < left else 1

    def sector_at(self, x, y):
        n = len(self.nodes) - 1
        while not (n & 0x8000):
            n = self.nodes[n][12 + self.node_side(x, y, n)]
        ss = n & 0x7fff
        seg = self.segs[self.ssecs[ss][1]]
        side = self.lines[seg[3]][5 + seg[4]]
        return self.sides[side][5]

    def opening(self, l):
        f, b = self.front(l), self.back(l)
        top = min(self.ceil(f), self.ceil(b))
        bottom = max(self.floor(f), self.floor(b))
        return top, bottom


def s16(w):
    return w - 65536 if w >= 32768 else w


class Player:
    def __init__(self, lvl):
        self.x, self.y, self.angle = lvl.start
        self.momx = self.momy = 0
        self.floorz = lvl.floor(lvl.sector_at(self.x, self.y))
        self.turnheld = 0


FORWARD = [0x19, 0x32]
SIDE = [0x18, 0x28]
TURN = [640, 1280, 320]


def build_cmd(keys, p):
    # keys: set of 'up','down','left','right','sl','sr','run'
    run = 1 if "run" in keys else 0
    if "left" in keys or "right" in keys:
        p.turnheld += 1
    else:
        p.turnheld = 0
    tspeed = 2 if p.turnheld < 6 else run
    fwd = side = turn = 0
    if "right" in keys:
        turn -= TURN[tspeed]
    if "left" in keys:
        turn += TURN[tspeed]
    if "up" in keys:
        fwd += FORWARD[run]
    if "down" in keys:
        fwd -= FORWARD[run]
    if "sl" in keys:
        side -= SIDE[run]
    if "sr" in keys:
        side += SIDE[run]
    return fwd, side, turn


class Sim:
    def __init__(self, lvl):
        self.lvl = lvl

    def check_position(self, p, x, y):
        lvl = self.lvl
        box = (y + RADIUS, y - RADIUS, x - RADIUS, x + RADIUS)
        sec = lvl.sector_at(x, y)
        self.tmfloorz = lvl.floor(sec)
        self.tmceilingz = lvl.ceil(sec)
        xl = (box[2] - lvl.bmorgx) >> 23
        xh = (box[3] - lvl.bmorgx) >> 23
        yl = (box[1] - lvl.bmorgy) >> 23
        yh = (box[0] - lvl.bmorgy) >> 23
        seen = set()
        for bx in range(xl, xh + 1):
            for by in range(yl, yh + 1):
                for l in lvl.cell_lines(bx, by):
                    if l in seen:
                        continue
                    seen.add(l)
                    if not self.check_line(box, l):
                        return False
        return True

    def check_line(self, box, l):
        lvl = self.lvl
        lb = lvl.line_bbox(l)
        if box[3] <= lb[2] or box[2] >= lb[3] or box[0] <= lb[1] or box[1] >= lb[0]:
            return True
        if lvl.box_on_side(box, l) != -1:
            return True
        if lvl.back(l) is None:
            return False
        if lvl.lines[l][2] & ML_BLOCKING:
            return False
        top, bottom = lvl.opening(l)
        if top < self.tmceilingz:
            self.tmceilingz = top
        if bottom > self.tmfloorz:
            self.tmfloorz = bottom
        return True

    def try_move(self, p, x, y):
        if not self.check_position(p, x, y):
            return False
        if self.tmceilingz - self.tmfloorz < HEIGHT:
            return False
        if self.tmceilingz - p.floorz < HEIGHT:
            return False
        if self.tmfloorz - p.floorz > 24 * FRACUNIT:
            return False
        p.x, p.y = x, y
        p.floorz = self.tmfloorz
        return True

    def slide_traverse(self, p, x1, y1, x2, y2):
        """The blocking line of least frac along the trace, as
        (frac, line), or None."""
        lvl = self.lvl
        if ((x1 - lvl.bmorgx) & (128 * FRACUNIT - 1)) == 0:
            x1 += FRACUNIT
        if ((y1 - lvl.bmorgy) & (128 * FRACUNIT - 1)) == 0:
            y1 += FRACUNIT
        tdx, tdy = x2 - x1, y2 - y1
        xl = (min(x1, x2) - lvl.bmorgx) >> 23
        xh = (max(x1, x2) - lvl.bmorgx) >> 23
        yl = (min(y1, y2) - lvl.bmorgy) >> 23
        yh = (max(y1, y2) - lvl.bmorgy) >> 23
        best = None
        seen = set()
        for bx in range(xl, xh + 1):
            for by in range(yl, yh + 1):
                for l in lvl.cell_lines(bx, by):
                    if l in seen:
                        continue
                    seen.add(l)
                    frac = self.intercept(x1, y1, tdx, tdy, l)
                    if frac is None or frac > FRACUNIT:
                        continue
                    if not self.slide_blocks(p, l):
                        continue
                    if best is None or frac < best[0]:
                        best = (frac, l)
        return best

    def intercept(self, tx, ty, tdx, tdy, l):
        lvl = self.lvl
        v1x, v1y = lvl.vx(lvl.lines[l][0]), lvl.vy(lvl.lines[l][0])
        v2x, v2y = lvl.vx(lvl.lines[l][1]), lvl.vy(lvl.lines[l][1])
        if tdx > 16 * FRACUNIT or tdy > 16 * FRACUNIT or tdx < -16 * FRACUNIT or tdy < -16 * FRACUNIT:
            s1 = self.divline_side(v1x, v1y, tx, ty, tdx, tdy)
            s2 = self.divline_side(v2x, v2y, tx, ty, tdx, tdy)
        else:
            s1 = lvl.point_on_side(tx, ty, l)
            s2 = lvl.point_on_side(tx + tdx, ty + tdy, l)
        if s1 == s2:
            return None
        ldx, ldy = lvl.line_dx(l), lvl.line_dy(l)
        # P_InterceptVector(trace, dl): v2 = trace, v1 = dl
        den = fmul(sar(ldy, 8), tdx) - fmul(sar(ldx, 8), tdy)
        if den == 0:
            return 0
        num = fmul(sar(v1x - tx, 8), ldy) + fmul(sar(ty - v1y, 8), ldx)
        frac = fdiv(num, den)
        if frac < 0:
            return None
        return frac

    def divline_side(self, x, y, lx, ly, ldx, ldy):
        if ldx == 0:
            if x <= lx:
                return int(ldy > 0)
            return int(ldy < 0)
        if ldy == 0:
            if y <= ly:
                return int(ldx < 0)
            return int(ldx > 0)
        dx = x - lx
        dy = y - ly
        if u32(ldy ^ ldx ^ dx ^ dy) & 0x80000000:
            return 1 if u32(ldy ^ dx) & 0x80000000 else 0
        left = fmul(sar(ldy, 8), sar(dx, 8))
        right = fmul(sar(dy, 8), sar(ldx, 8))
        return 0 if right < left else 1

    def slide_blocks(self, p, l):
        lvl = self.lvl
        if not (lvl.lines[l][2] & ML_TWOSIDED):
            if lvl.point_on_side(p.x, p.y, l):
                return False
            return True
        top, bottom = lvl.opening(l)
        if top - bottom < HEIGHT:
            return True
        if top - p.floorz < HEIGHT:
            return True
        if bottom - p.floorz > 24 * FRACUNIT:
            return True
        return False

    def hit_slide_line(self, p, l, mx, my):
        lvl = self.lvl
        st = lvl.slopetype(l)
        if st == "H":
            return mx, 0
        if st == "V":
            return 0, my
        side = lvl.point_on_side(p.x, p.y, l)
        lineangle = point_to_angle(lvl.line_dx(l), lvl.line_dy(l))
        if side == 1:
            lineangle = u32(lineangle + ANG180)
        moveangle = point_to_angle(mx, my)
        delta = u32(moveangle - lineangle)
        if delta > ANG180:
            delta = u32(delta + ANG180)
        lineangle >>= 19
        delta >>= 19
        movelen = approx_distance(mx, my)
        newlen = fmul(movelen, finecos(delta))
        return fmul(newlen, finecos(lineangle)), fmul(newlen, finesine(lineangle))

    def slide_move(self, p):
        hitcount = 0
        while True:
            hitcount += 1
            if hitcount == 3:
                return self.stairstep(p)
            if p.momx > 0:
                leadx, trailx = p.x + RADIUS, p.x - RADIUS
            else:
                leadx, trailx = p.x - RADIUS, p.x + RADIUS
            if p.momy > 0:
                leady, traily = p.y + RADIUS, p.y - RADIUS
            else:
                leady, traily = p.y - RADIUS, p.y + RADIUS
            best = None
            for (sx, sy) in ((leadx, leady), (trailx, leady), (leadx, traily)):
                b = self.slide_traverse(p, sx, sy, sx + p.momx, sy + p.momy)
                if b is not None and (best is None or b[0] < best[0]):
                    best = b
            if best is None:
                return self.stairstep(p)
            frac = best[0] - 0x800
            if frac > 0:
                newx = fmul(p.momx, frac)
                newy = fmul(p.momy, frac)
                if not self.try_move(p, p.x + newx, p.y + newy):
                    return self.stairstep(p)
            frac = FRACUNIT - (frac + 0x800)
            if frac > FRACUNIT:
                frac = FRACUNIT
            if frac <= 0:
                return
            mx = fmul(p.momx, frac)
            my = fmul(p.momy, frac)
            mx, my = self.hit_slide_line(p, best[1], mx, my)
            p.momx, p.momy = mx, my
            if self.try_move(p, p.x + mx, p.y + my):
                return

    def stairstep(self, p):
        if not self.try_move(p, p.x, p.y + p.momy):
            self.try_move(p, p.x + p.momx, p.y)

    def xy_movement(self, p, cmd):
        if p.momx == 0 and p.momy == 0:
            return
        p.momx = max(-MAXMOVE, min(MAXMOVE, p.momx))
        p.momy = max(-MAXMOVE, min(MAXMOVE, p.momy))
        xmove, ymove = p.momx, p.momy
        while True:
            if xmove > MAXMOVE // 2 or ymove > MAXMOVE // 2:
                ptryx = p.x + int(xmove / 2)
                ptryy = p.y + int(ymove / 2)
                xmove = sar(xmove, 1)
                ymove = sar(ymove, 1)
            else:
                ptryx = p.x + xmove
                ptryy = p.y + ymove
                xmove = ymove = 0
            if not self.try_move(p, ptryx, ptryy):
                self.slide_move(p)
            if xmove == 0 and ymove == 0:
                break
        if (-STOPSPEED < p.momx < STOPSPEED and -STOPSPEED < p.momy < STOPSPEED
                and cmd[0] == 0 and cmd[1] == 0):
            p.momx = p.momy = 0
        else:
            p.momx = fmul(p.momx, FRICTION)
            p.momy = fmul(p.momy, FRICTION)

    def thrust(self, p, angle, move):
        fa = angle >> 19
        p.momx = s32(p.momx + fmul(move, finecos(fa)))
        p.momy = s32(p.momy + fmul(move, finesine(fa)))

    def tic(self, p, keys):
        cmd = build_cmd(keys, p)
        fwd, side, turn = cmd
        p.angle = u32(p.angle + (turn << 16))
        if fwd:
            self.thrust(p, p.angle, fwd * 2048)
        if side:
            self.thrust(p, u32(p.angle - ANG90), side * 2048)
        self.xy_movement(p, cmd)


def fshow(x):
    x = s32(x)
    m = abs(x)
    return ("-" if x < 0 else "") + "%d.%06d" % (m >> 16, ((m & 0xffff) * 15625) >> 10)


def ashow(a):
    d = (a >> 16) * 360
    return "%d.%03d" % (d >> 16, ((d & 0xffff) * 1000) >> 16)


def report(tag, p):
    print("%s %s %s %s floor %s" % (tag, fshow(p.x), fshow(p.y), ashow(p.angle), fshow(p.floorz)))


KEYS = {"U": "up", "D": "down", "L": "left", "R": "right", "A": "sl", "S": "sr", "!": "run"}


def run(sim, p, script):
    """script: list of (keystring, tics)."""
    for ks, n in script:
        keys = {KEYS[c] for c in ks}
        for _ in range(n):
            sim.tic(p, keys)


if __name__ == "__main__":
    lvl = Level(sys.argv[1])
    sim = Sim(lvl)
    p = Player(lvl)
    report("start", p)
    script = [(s.split(":")[0], int(s.split(":")[1])) for s in sys.argv[2:]]
    for ks, n in script:
        run(sim, p, [(ks, n)])
        report("%s:%d" % (ks or "-", n), p)

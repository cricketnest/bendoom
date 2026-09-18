# 06: E1M1 loads into a level record with the player 1 start

**What to build:** The level as one record of flat arrays indexed by number, so that lookups are O(1) and level geometry is a parameter of every sim function, never part of the state. Vertices, linedefs, sidedefs, sectors and the blockmap are parsed from their lumps at load; the things lump is read only for the player 1 start, whose position and facing come out in fixed point and binary angle. The game state's lump list is replaced by the level. A test loads E1M1 through the same loader the game uses and prints the start.

**Blocked by:** 01 (Bytes reads signed 16-bit values and lump records into arrays), 02 (Fixed point on U32 with its laws)

**Status:** resolved

- [x] The level record holds the five geometry lumps as arrays and the player 1 start as position and angle
- [x] Map coordinates are stored as fixed point, converted by sign extension then shift
- [x] The blockmap's header (origin, columns, rows) and its offset table are loaded so a cell's line list can be walked
- [x] The map's lumps are found by name relative to the E1M1 marker, so Freedoom's first map loads the same way
- [x] A test prints the start position in map units and the facing, pinned to Freedoom's values; the shareware start (1056, -3616, facing east) is checked by hand and noted in the comments
- [x] The game state no longer carries the lump list; the window still opens and quits
- [x] The test passes on both lanes and the flake check stays green

## Comments

Done. The level is `Level`, a record of `Vec` trees: a copyable array (a complete binary tree of U32 leaves, Data), because Bend's `Array` is linear and a step that threaded it would have to hand the level back beside the player, which is what the spec's "never part of the state" wants to avoid. A lookup is O(log n) (11 steps for E1M1's lines). Map coordinates are shifted to fixed point at load. The NODES, SSECTORS and SEGS lumps are read too, for the sector under a point (Doom's `R_PointInSubsector`), which `P_CheckPosition` starts its floor and ceiling from; without it, walking down a step would leave the player on the higher floor.

Freedoom's start is (-416, 256) facing 0 (east) on floor 0. The shareware start is (1056, -3616) facing 90 (north), not east as the spec said; checked from the WAD's THINGS lump (angle 90) and by the test's first tic, which moves along y. The tests pass on both lanes.

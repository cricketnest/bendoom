# 12: Steps up to 24 units and low ceilings through openings

**What to build:** Two-sided lines behave as in Doom: the player steps up onto floors up to 24 units higher, so E1M1's stairs are walkable, and is blocked where the ceiling drops so low the player does not fit. The opening across a line is the higher floor and lower ceiling of its two sectors, found through the sidedefs; a move is blocked when the opening is too short for the player's height or the floor is more than 24 units above the player's feet. The player's height tracks the floor.

**Blocked by:** 11 (Solid walls stop the player through the blockmap)

**Status:** resolved

- [x] Crossing a line into a sector up to 24 units higher succeeds; higher fails
- [x] Crossing a line into an opening shorter than the player's height fails
- [x] The player's floor height updates on crossing so the next step measures from the new floor
- [x] The sim test's scripted list climbs one of the map's steps and pins the position and floor
- [x] The test passes on both lanes and the flake check stays green

## Comments

Done. The opening is the higher floor and lower ceiling of the two sectors through the sidedefs; the fit's floor and ceiling start from the sector under the point (through the BSP, see 06) and are narrowed by every two-sided line the box crosses; the move is refused when the opening is below the player's height, the ceiling is too low from the feet, or the floor is more than 24 units up. The script's "L:20" segment climbs Freedoom's 12-unit step (floor 12.000000) and "U!:200" walks back down to 0.

Declared simplification, beyond the ticket's wording: because z tracks the floor, there are no airborne tics. Vanilla withholds thrust and friction while z is above the floor for a few tics after a step down; here a step down is instant, so a script that crosses one (the test's "U!:200" does) pins values vanilla would not reach until milestone 4 or later gives the player a z of its own.

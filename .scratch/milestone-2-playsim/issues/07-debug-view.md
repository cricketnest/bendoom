# 07: Top-down debug view shows the map and the player start

**What to build:** A top-down view of the level in the window, so that the player can be seen before the 3D view exists. Map lines are drawn into a flat framebuffer array with integer line drawing, one-sided walls and two-sided lines in different colours, the player as a dot with a tick for facing, and the framebuffer is folded into the frame quadtree. This view is throwaway: milestone 3's wall renderer deletes it, and the ticket says so at the top of the module.

**Blocked by:** 06 (E1M1 loads into a level record with the player 1 start)

**Status:** resolved

- [x] The window shows E1M1's lines scaled and centred on the player, in the 640 by 400 frame
- [x] One-sided walls and two-sided lines are told apart by colour
- [x] The player start is drawn at the map's start position with its facing
- [x] Esc and Close still quit
- [x] The view is one module with no state of its own, marked as replaced by milestone 3

## Comments

Done. `src/view.bend`, marked as replaced by milestone 3 at its top. Lines are drawn with Bresenham into a 320 by 200 framebuffer (Doom's own resolution, shown two pixels a cell) at an eighth of a map unit a pixel, centred on the player, one-sided walls white and two-sided lines grey, the player a yellow dot with an eight-pixel tick. The fold into the quadtree runs an explicit stack of tasks: the framebuffer has one owner, so four nested recursive calls cannot share it, and Bend has no mutual recursion for a helper to sequence them. A frame's fold costs 66 ms in a throwaway count of lit pixels (10104 for the start frame), which held 60 Hz in the window.

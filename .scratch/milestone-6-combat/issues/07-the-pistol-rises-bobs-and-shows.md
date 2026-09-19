# 07: The pistol rises, bobs and shows

**What to build:** The player's weapon appears. The player carries vanilla's two player sprites, weapon and flash, each with a state, tics and a position. The pistol rises at the level's start, rests, and bobs with the player's steps. The renderer draws it after the masked pass at scale one, lit by the player's sector.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `P_SetupPsprites`, `P_MovePsprites`, `A_Raise` and `A_WeaponReady`'s bob run in the player's think, with state rows for the pistol's ready and raise states
- [ ] The sprite is placed and clipped as `R_DrawPSprite` does, with the weapon's patches loaded from the WAD
- [ ] The oracle's pistol mask and its rule that a script lasts at least 18 tics are deleted
- [ ] Render cases: the pistol mid-rise, at rest, and at two phases of the bob, at zero differing pixels
- [ ] Every existing rest and mover frame stays at zero with the pistol compared
- [ ] The sim test prints the weapon sprite's state, tics and position on a walk

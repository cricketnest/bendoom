# 08: Ammo, backpacks and world weapons are pickups

**What to build:** Clips, shells, rockets, cells, their boxes, backpacks and map weapons update the inventory with vanilla amounts and caps. A backpack doubles caps once and grants ammo. A weapon pickup grants ownership and pickup ammo, then disappears when either grant succeeds. The ready weapon stays the pistol until milestone 6.

**Blocked by:** 06 (The blue key opens its door)

**Status:** ready-for-agent

- [ ] Each ammo family and box uses vanilla clip counts, including the game's fixed skill multiplier
- [ ] Ammo at its cap refuses a loose or boxed pickup and leaves it active
- [ ] The first backpack doubles every ammo cap and every accepted backpack grants one clip of each ammo family
- [ ] A later backpack does not double caps again
- [ ] World weapons grant ownership and their vanilla pickup ammo
- [ ] A weapon remains only when neither ownership nor ammo changes
- [ ] Ready weapon, switching, firing and first-person weapon sprites remain unchanged and out of scope
- [ ] Closed laws pin each ammo cap, backpack idempotence and weapon acceptance
- [ ] Scripted Freedoom cases print ammo, caps, backpack and weapon ownership on both lanes
- [ ] Render cases show accepted pickups disappear and refused pickups remain


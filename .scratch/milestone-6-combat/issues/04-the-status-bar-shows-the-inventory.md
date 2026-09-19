# 04: The status bar shows the inventory

**What to build:** The black band under the view becomes Doom's status bar, drawn by the renderer into rows 168 to 199 from the state and the WAD's own graphics: the background, ammo for the ready weapon, health, armour, the arms panel, the keys, and the four ammo counts with their caps. The face's box shows the bar's background until its ticket.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Every patch comes from the opened WAD, so Freedoom's bar is Freedoom's
- [ ] Numbers, percent signs, the minus-free layout and the arms and key slots sit where `ST_createWidgets` puts them
- [ ] The blue key shows on the tic it is taken
- [ ] The oracle compares rows 168 to 199; its status-bar mask is deleted and a mask over the face's box alone replaces it
- [ ] Render cases: the bar at the start, after an ammo pickup, after armour, after the blue key; each at zero differing pixels outside the face's box
- [ ] The frame stays a pure function of tables, graphics and state

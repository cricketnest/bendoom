# Milestone 5: things, sprites and pickups

Status: ready-for-agent

## Problem Statement

Bendoom's E1M1 can be finished, but its rooms are empty. Decorations, corpses, barrels, keys, armour, health, ammo and weapons from the map's THINGS lump do not exist. The blue key cannot be collected, so its door always refuses to open. A player expects the objects placed by the map author to appear with Doom's scale, lighting, animation and occlusion, and expects walking over an item to change the same inventory values and remove the same object as vanilla Doom.

## Solution

Load the non-monster things used by the shareware and Freedoom E1M1s at Hurt Me Plenty skill, spawn them into the pure game state, advance their vanilla state sequences each tic, and render them through Doom's sprite pass. Sprites come straight from the WAD, are projected in 16.16 fixed point, sorted back to front, clipped by walls, floors, ceilings and masked middle textures, and lit by their sector. The player's movement checks solid things and touches pickups. Pickups update health, armour, ammo, keys, powers and weapon ownership, then disappear when vanilla would consume them. Collecting the blue key makes the existing blue door usable. Chocolate Doom remains the visual and gameplay oracle, with monsters disabled and every supported thing left in the map.

## User Stories

1. As a player, I want E1M1's decorations and items to appear where the map puts them, so that its rooms no longer look empty.
2. As a player, I want the shareware and Freedoom maps to use their own sprite art, so that Bendoom does not bake in graphics from either WAD.
3. As a player, I want sprites to have Doom's apparent size and position, so that objects sit on the floor instead of floating or sinking.
4. As a player, I want sprite patch offsets honoured, so that each object's origin matches vanilla.
5. As a player, I want sprites behind me or outside the field of view culled, so that only visible things are drawn.
6. As a player, I want distant sprites drawn before near sprites, so that overlapping objects cover each other correctly.
7. As a player, I want walls to hide sprites behind them, so that objects do not show through solid geometry.
8. As a player, I want floors and ceilings to clip sprites at height changes, so that objects in lower or upper rooms do not bleed through ledges.
9. As a player, I want a masked wall and a sprite to cover each other according to their real depth, so that bars and grates work from either side.
10. As a player, I want transparent pixels in a sprite to leave the scene behind it visible, so that sprites keep their cut-out shape.
11. As a player, I want a thing's sector light and distance to shade it as vanilla does, so that objects belong in the room around them.
12. As a player, I want full-bright item frames to ignore sector darkness, so that bonuses pulse as they do in Doom.
13. As a player, I want animated bonuses and decorations to advance on Doom's tics, so that their frames match vanilla at the same level time.
14. As a player, I want each animated thing to start at the phase selected by vanilla's random sequence, so that the whole frame can match to the tic.
15. As a player, I want things placed for Hurt Me Plenty to spawn and things meant only for another skill to stay absent, so that E1M1 has Doom's default population.
16. As a player, I want multiplayer-only things and extra player starts to stay absent in this single-player game, so that they do not appear as stray objects.
17. As a player, I want monsters omitted until they can act, so that milestone 5 does not fill the map with inert enemies.
18. As a player, I want solid decorations and barrels to stop me, so that I cannot walk through objects vanilla treats as solid.
19. As a player, I want corpses, gore and non-solid decorations to let me pass, so that scenery does not block more than vanilla's does.
20. As a player, I want a moving floor to carry a thing standing on it, so that things stay attached to the level geometry.
21. As a player, I want a moving ceiling to re-clip things in its sector, so that movers account for more than the player.
22. As a player, I want to collect the blue key, so that I can open E1M1's blue door.
23. As a player, I want keycards to remain unavailable before I touch them, so that a locked door still means something.
24. As a player, I want health bonuses to add one health up to 200, so that they behave as vanilla bonuses.
25. As a player, I want stimpacks and medikits to heal by their vanilla amounts up to 100, so that a full-health player leaves them on the floor.
26. As a player, I want soul spheres and berserk packs to set health by vanilla's rules, so that the E1M1 pickups have their real effect even before damage exists.
27. As a player, I want armour bonuses to add one armour up to 200 and establish green armour when needed, so that their effect is not deferred to the status bar.
28. As a player, I want green and blue armour to apply their vanilla armour values and types, so that a weaker armour pickup stays when it cannot improve me.
29. As a player, I want clips, shells, rockets and cells to add vanilla ammo amounts up to their caps, so that full ammo leaves an item uncollected.
30. As a player, I want ammo boxes to grant their larger vanilla amounts, so that a box is not treated as one loose round.
31. As a player, I want a backpack to double ammo caps once and grant ammo every time one can be collected, so that its inventory effect matches vanilla.
32. As a player, I want a weapon pickup to grant ownership and its pickup ammo, so that the world item is consumed for a real reason.
33. As a player, I want weapon pickups to remain when neither ownership nor ammo can improve my inventory, so that Bendoom does not eat an unusable pickup.
34. As a player, I want the first-person weapon to remain the current pistol for this milestone, so that firing, switching and weapon sprites arrive together in milestone 6.
35. As a player, I want pickups that vanilla counts as items to increase the item count, so that a later tally can use the state already earned during the level.
36. As a player, I want a pickup to disappear on the tic I touch it, so that the rendered frame after that tic agrees with the sim.
37. As a player, I want an item I cannot accept to remain visible and collectable later, so that walking over a full-health medikit does not destroy it.
38. As a player, I want pickups above my head or too far below me to stay untouched, so that contact uses Doom's vertical reach as well as XY overlap.
39. As a player, I want the existing doors, lift, switches, lights, animations, scrolling walls and exit route to keep working with things present, so that milestone 5 adds to the living map without breaking it.
40. As a player, I want Esc, Close and restart after the exit to keep working, so that the game loop behaves as before.
41. As a developer, I want the loader to retain every THINGS field needed for spawning, so that position, angle, type and options come from the WAD.
42. As a developer, I want thing definitions and state sequences to carry only the non-monster types used by the two E1M1s, so that milestone 6 owns monster behaviour instead of inheriting dead branches.
43. As a developer, I want sprite definitions built from lumps between the WAD's sprite markers, including mirrored and rotated names, so that Freedoom and Doom can name different patches without code changes.
44. As a developer, I want only the sprite patches reachable from spawned things' states loaded into the draw array, so that unused WAD art does not increase startup time or memory.
45. As a developer, I want every per-tic thing and inventory change inside the state replay already maps, so that a command script still determines the exact state and frame.
46. As a developer, I want things to keep stable map identities after pickups are removed, so that scripted output can name the same object before and after a tic.
47. As a developer, I want thing state sequences advanced in vanilla thinker order before the level clock advances, so that animations and the random index stay on the same tic as Chocolate Doom.
48. As a developer, I want the player position check to return both collision and pickup changes without hidden mutation, so that the pure sim preserves vanilla's order of effects.
49. As a developer, I want the renderer to gather a sector's things once even when the BSP visits several subsectors in it, so that no sprite is drawn twice.
50. As a developer, I want sprite projection and clipping to reuse the stored wall ranges and clip lists, so that the renderer gains no second account of visibility.
51. As a developer, I want masked middle textures drawn during sprite clipping when they are behind a sprite, with the remaining masked ranges drawn afterward, so that the final pass follows vanilla's ordering.
52. As a developer, I want sprite and masked-object lists to have no static vanilla limits, so that Bendoom keeps the renderer's existing policy of not reproducing overflow crashes.
53. As a developer, I want the frame dump and oracle to keep the map's supported things while removing monsters and replacing only the player start, so that sprite comparisons use the real E1M1 population.
54. As a developer, I want scripted pickup runs to print the inventory, active thing count and blue door result, so that pickup behaviour is checked at the program's boundary on both lanes.
55. As a developer, I want rendered frames before and after a pickup and at sprite occlusion cases, so that state, projection and removal are covered through one replay seam.
56. As a developer, I want every compared sprite frame to report zero differing unmasked pixels against Chocolate Doom, so that fidelity remains a number.
57. As a proof author, I want replay composition to keep holding over things and inventory, so that two scripts in turn equal their concatenation.
58. As a proof author, I want a completed tic to leave the player outside every active solid thing, so that object collision has the same standing as the wall law.
59. As a proof author, I want a consumed pickup absent and its inventory grant present together, so that collection cannot lose either half of the change.
60. As a proof author, I want closed laws for health, armour, ammo and key caps, so that the checker gates the numbers that decide whether a pickup remains.
61. As a packager, I want the new sim and render cases in the flake check against Freedoom with no new dependency, so that the five-node build graph stays unchanged.
62. As a reader of the README, I want milestone 5 marked done only after the populated maps, pickups and sprite oracle all pass, so that the roadmap does not overclaim.

## Implementation Decisions

- The game stays single-player on Hurt Me Plenty. A map thing spawns when its normal-skill option bit is set and its multiplayer-only bit is clear. Player starts 2 through 4, deathmatch starts and teleport destinations are data for modes or specials outside this milestone. Monsters and lost souls do not spawn until milestone 6. Every other type carried by either E1M1 is represented, including corpses, hanging bodies, lamps, columns, trees, barrels, keys, health, armour, ammo, backpacks, powers and world weapon pickups.
- The loader reads THINGS as records of signed map coordinates, angle, DoomEd type and options. The loaded map keeps the records unchanged. Building a fresh state filters and spawns them in lump order, assigns stable identities from their record indices, places floor things on the sector floor and ceiling things against the ceiling, and consumes the vanilla random sequence in the same places as P_SpawnMobj and P_SpawnMapThing. Restart rebuilds the population and inventory from the loaded map.
- A thing definition supplies its spawn state, radius, height and vanilla flags. A state row supplies sprite, frame, full-bright bit, duration and next state. The tables contain the non-monster rows reachable by the two E1M1s. There are no inert monster definitions kept for later compatibility. Milestone 6 adds those rows when it adds their actions.
- Active things live in the game state beside the player and level. A thing carries its stable identity, type, position, angle, floor and ceiling, state and tics. Removal drops it from the active population but never renumbers another thing. Static states with duration minus one never enter an animation branch.
- The player gains inventory for health, armour points and type, the six cards and skulls, four ammo counts and caps, backpack ownership, weapon ownership, powers, item count and pickup flash count. It starts with vanilla's 100 health, no armour, fifty bullets, fist and pistol, normal ammo caps, no cards and no powers. The status bar does not draw these values until milestone 6.
- Pickup grants follow P_TouchSpecialThing and P_GiveAmmo for the supported types, including caps and refusal when an item cannot improve the player. Keys open their corresponding locked doors. The existing blue door special checks the blue card or skull instead of refusing unconditionally. Pickup messages and sounds have no representation yet.
- World weapon pickups grant ownership and the vanilla pickup ammo, and then disappear when either grant succeeds. They do not change the ready weapon and Bendoom continues to show no first-person weapon. Selection, firing, weapon state machines and player sprites belong to milestone 6. This is the one deliberate difference from vanilla in pickup state during this milestone; oracle frames after a weapon pickup are not fidelity cases.
- The berserk pack gives its vanilla health and records the strength power, but the fist and its automatic selection wait for milestone 6. Other power timers advance where a supported E1M1 item needs them. Visual effects that require palette changes, invisibility or the automap stay inert until the milestone that owns that renderer or system.
- Position checking examines things before lines, as vanilla does. A solid thing blocks when the two boxes, each its radius about its centre, overlap; vanilla gives a thing no height here, so it blocks at any height. A special thing touched by the player tries its grant and is removed only on success. The pure check returns the changed population and player inventory with its fit result. If vanilla can consume a pickup during a position check whose later line check rejects the move, Bendoom preserves that order.
- Moving sectors re-clip the player and active things in the sector's block box through the same height rules. A thing standing on the old floor follows the new floor. Crushing damage and barrel explosions remain inert, but a shootable thing that no longer fits makes the mover report the same blocked result as an undamageable vanilla thing, and any other that no longer fits is passed over, as vanilla's PIT_ChangeSector passes over it.
- The graphics loader scans the sprite namespace and builds Doom's sprite definitions from four-character sprite names, frame letters and rotation digits. A zero rotation supplies every view. Rotations 1 through 8 may use the second frame and rotation encoded in a mirrored lump name. Missing frames or mixed zero and rotated frames fail the load as vanilla does. Only patches reachable from the spawned non-monster states are copied into the draw array.
- The BSP walk gathers active things from each visible sector once. Projection follows R_ProjectSprite in the renderer's existing fixed point: transform relative to the eye, near and side culls, rotation choice, patch offsets, screen bounds, reciprocal scale and sector sprite light. Full-bright frames use the first colormap. There is no fuzz column in this milestone because no supported spawned thing has the shadow flag.
- Visible sprites sort back to front by scale with vanilla's tie behaviour. For each sprite, the masked pass scans stored wall ranges from newest to oldest. A range behind the sprite draws its still-undrawn masked middle columns before the sprite. A range in front contributes its top and bottom clips when its silhouette heights cross the sprite. The sprite then draws its patch posts through those clips. After all sprites, any masked columns not yet drawn are drawn. The old masked-walls-only pass is fully replaced.
- The state advances things in vanilla thinker order after the player's movement and use, among the existing thinkers, then advances the clock. Pickup animation is a state sequence, not a function of the clock, because spawn phases differ. Existing flat and wall animations remain functions of the clock.
- The frame stays 320 by 200 palette indices with a 320 by 168 view. The black status-bar band and the missing first-person weapon stay as they are. The renderer remains a pure function of tables, graphics and state and still draws the latest completed tic without interpolation.
- The oracle keeps E1M1's non-monster THINGS records, removes monsters, replaces the player 1 start in place, and runs Chocolate Doom with no monsters on Hurt Me Plenty. It no longer replaces the entire lump with one record. The existing status bar, pause graphic and first-person weapon masks remain. Sprite pixels themselves are never masked.
- README's milestone 5 line is marked done only after both WADs render their things, the blue key route works, the oracle cases reach zero and the frame-rate measurement passes.

## Testing Decisions

- A good test drives one seam: load a real E1M1, build its state, replay a command script, then inspect the state or render the frame. It checks which things remain, what inventory the player owns, whether a locked door moves, and which pixels the complete renderer produces. It does not test sprite-name parsers, grant helpers or projection helpers in isolation.
- Expected state values come from outside the Bend code. Thing records and counts are read from the WAD in nushell. Pickup amounts, caps, spawn filtering, random calls, state durations, projection and clipping come from linuxdoom-1.10. Values with no outside oracle are labelled regression pins in their ticket.
- The sim test gains tagged scripts on Freedoom that touch one item from each behaviour present in its E1M1: a capped and an accepted health pickup, an armour bonus or armour, each ammo family the route can reach, a backpack, a world weapon, the berserk pack and the blue key. It prints the stable identities of removed things, remaining count, health, armour, ammo, caps, cards, powers, weapon ownership, item count and the blue door's height after use. Short literal-state cases cover grants impractical to reach by a map route.
- The render test adds frames with several static decorations, an animated full-bright pickup at two tics, overlapping sprites, a sprite cut by a ledge, a sprite behind a solid wall, both depth orders against a masked middle texture, and a frame immediately after a pickup disappears. Each case keeps the existing hash and sampled-pixel output on both lanes.
- Chocolate Doom remains the visual oracle. Every new render frame that does not depend on the deliberately deferred ready-weapon change runs from the same start and script on both games. The ticket records the differing-pixel count, target zero. Existing rest and mover frames must remain zero with the populated map or be updated to positions whose real things explain the new pixels.
- Pickup timing is also checked against Chocolate Doom by pausing on the tic before contact and the tic after it. The relevant sprite must be present before and absent after. The blue key route checks refusal before collection and opening after collection at the same tics in both games.
- Laws keep the existing wall, geometry, replay, mover and renderer laws. The replay law grows the active things and inventory. A new freedom law says the player does not overlap an active solid thing after a tic. Closed laws pin pickup acceptance and refusal at health, armour and ammo caps, key possession, stable identities after removal, state-sequence timing, sprite rotation choice and sprite-column bounds. All laws are filled in so the flake check gates them.
- Prior art is the scripted sim and route tests, hashed render frames, the Chocolate Doom demo oracle, WAD inspection through nushell, closed laws on literal levels, and the existing masked-post drawing code. The sprite pass extends the stored wall ranges rather than adding a second visibility test.
- The window is measured on the dev machine in a view containing many Freedoom things and a running light or mover. It must hold at least 35 frames a second, the same bar as milestones 3 and 4. The ticket records the machine, scene and measured range.
- Both E1M1s are played through the populated route. The shareware run is manual or scripted outside the flake because its WAD is unfree. The Freedoom route stays in the flake check.

## Out of Scope

Monster spawning, sight, movement, attacks, pain, death and drops. The player's first-person weapon, weapon switching, firing, projectiles and hitscan. Damage to the player or things, barrel explosions, damaging floors and crushers that deal damage. The status bar, pickup messages, palette flashes and the automap. Pickup and door sounds. Multiplayer, deathmatch item respawn and skill selection. Teleporters, secrets, the intermission and another map. Save games, menus, demo playback inside Bendoom, sound, music and Hellbent.

## Further Notes

- The single test seam matches milestones 2 through 4: a command script enters the pure replay, and state plus frame come out. Chocolate Doom supplies the outside answer. No new test-only interface is needed.
- Sprite drawing is the risky part. The current masked pass can draw walls only after all planes. Vanilla interleaves masked wall columns with sprites according to depth, then draws the columns that remain. Replacing that pass, rather than layering a second sprite pass over it, is necessary for grates and bars to match from both sides.
- Random order is the quieter risk. Spawning each thing consumes vanilla's random table before the light thinkers start, so milestone 4's pinned blink phase and random index will change once the real population exists. The new expected values must come from vanilla's spawn order, not from today's regression output.
- The map population is deliberately narrower than Doom's full thing table. It covers both E1M1s completely after monsters and mode-only starts are excluded. Milestone 6 adds monsters and combat objects by extending the same state and sprite definitions, not by keeping dormant milestone 6 code here.
- The Bend constraints that shape the implementation remain in the project's Bend guide.

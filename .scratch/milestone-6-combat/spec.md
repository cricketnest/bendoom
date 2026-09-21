# Milestone 6: monsters, weapons, damage, the status bar

Status: ready-for-agent

## Problem Statement

Milestone 5 ended at world interaction and pickups. Combat, player weapons,
damage feedback, the status bar and the intermission were the next coherent
slice because they share the simulation state, renderer and Chocolate Doom
oracle. This milestone implements and checks that slice over both E1M1s.

## Solution

The monsters of both E1M1s spawn on Hurt Me Plenty and behave as vanilla's: they hear and see the player, chase, attack, feel pain, die, drop their items and fight each other. The player carries the weapons the two maps can give (fist, chainsaw, pistol, shotgun), raises, fires, bobs and switches them as vanilla does, and hits by vanilla's hitscan with its autoaim. Damage reaches everything that vanilla damages: monsters, barrels, and the player through armour. The player dies, and a press of Space loads the level again. The status bar, pickup messages and palette flashes show the inventory that milestone 5 already keeps. The exit leads to vanilla's intermission. Chocolate Doom stays the oracle. It now runs with monsters, and its frame is compared over all 200 rows.

## User Stories

1. As a player, I want E1M1's monsters where the map puts them on Hurt Me Plenty, so that the level is Doom's and not a museum.
2. As a player, I want monsters marked deaf to wait in ambush until they see me, so that the map author's traps work.
3. As a player, I want a monster to wake when it sees me within its field of view, so that sneaking up behind one works as in vanilla.
4. As a player, I want a gunshot to wake the monsters its noise reaches through open sectors, and to stop at sound-blocking lines, so that firing has vanilla's cost.
5. As a player, I want monsters to chase me with vanilla's eight-direction movement, turning and back-off, so that they move like Doom's.
6. As a player, I want monsters to open the manual doors vanilla lets them open, so that a door does not make me safe.
7. As a player, I want monsters stopped by ledges too high, drops too deep and lines that block monsters, so that they stay where vanilla keeps them.
8. As a player, I want zombiemen and shotgun guys to shoot with vanilla's spread and damage, so that their threat matches the original.
9. As a player, I want imps to claw at close range and throw fireballs from afar, so that both their attacks exist.
10. As a player, I want a fireball to fly, to hit what is in its way, to explode with its sprite, and to vanish into the sky where vanilla's does.
11. As a player, I want Freedoom's demons to charge and bite, so that Freedoom's E1M1 has its whole population.
12. As a player, I want a hurt monster to flinch by its pain chance, so that weapons interrupt attacks as in vanilla.
13. As a player, I want a monster hit by another monster to turn on it, so that infighting works.
14. As a player, I want a killed monster to play its death frames and leave its corpse, and to gib when the damage is large enough.
15. As a player, I want a zombieman to drop a clip and a shotgun guy a shotgun, each worth half the ammo of a placed one.
16. As a player, I want a door that closes on a corpse to crush it into gibs, as vanilla does.
17. As a player, I want a living monster in a closing door to send the door back up, as I do.
18. As a player, I want Ctrl to fire, so that I can fight.
19. As a player, I want the pistol to rise at the level's start and show at the bottom of the view, so that the screen looks like Doom's.
20. As a player, I want the weapon to bob with my steps, so that walking feels as it does in Doom.
21. As a player, I want the pistol's first shot accurate and its held fire spread, as vanilla's refire rule makes it.
22. As a player, I want the shotgun to fire seven pellets with vanilla's spread and pump time.
23. As a player, I want the fist to punch, and to hit ten times harder after a berserk pack.
24. As a player, I want the chainsaw to idle, rev, pull me toward what it cuts, and need no ammo.
25. As a player, I want shots to aim themselves up and down at what stands in front of me, so that enemies on ledges can be hit without looking up.
26. As a player, I want a bullet that hits a wall to leave a puff and one that hits flesh to leave blood.
27. As a player, I want the muzzle flash to light the room for its tics, so that firing brightens the view as in vanilla.
28. As a player, I want number keys to select a weapon I own, with 1 choosing the chainsaw over the fist unless berserk, so that selection follows vanilla's rules.
29. As a player, I want the weapon to lower and the next to rise at vanilla's speed when I switch.
30. As a player, I want a picked-up weapon I did not own to come up, so that the shotgun arrives in my hands.
31. As a player, I want the berserk pack to bring up the fist.
32. As a player, I want to switch to the best weapon with ammo when the current one runs dry.
33. As a player, I want ammo picked up at zero to bring back a better weapon by vanilla's rule.
34. As a player, I want a weapon to refuse to fire without ammo.
35. As a player, I want barrels to take damage, explode, hurt everything within vanilla's radius, and set each other off.
36. As a player, I want a shot barrel to slide from the blow, since vanilla's things take thrust from damage.
37. As a player, I want armour to absorb a third of damage when green and half when blue, until it runs out.
38. As a player, I want the nukage to hurt me every 32 tics while I stand on it.
39. As a player, I want the view to flash red in proportion to damage, gold on a pickup, and red-tinted while berserk fades.
40. As a player, I want my view to kick toward the attacker's blow, as vanilla thrusts a damaged player.
41. As a player, I want to die at zero health: the view sinks to the floor, turns to my killer, and the weapon drops away.
42. As a player, I want a press of Space after death to start E1M1 again with a fresh inventory.
43. As a player, I want monsters to stop attacking a dead player and go back to idling, as vanilla's do.
44. As a player, I want the status bar under the view, drawn from the WAD's own graphics, so that Freedoom's bar is Freedoom's.
45. As a player, I want the bar to show ammo for the ready weapon, health, armour, the owned weapons, the keys and the four ammo counts with their caps.
46. As a player, I want the blue key to appear on the bar the tic I take it.
47. As a player, I want the marine's face to show my health level, to look around, to wince toward the side damage came from, to grin at a new weapon, to grimace while I hold fire, and to show dead.
48. As a player, I want a message for each pickup at the top of the view for four seconds, in the WAD's font, so that I know what I got.
49. As a player, I want a message when a locked door refuses me, so that I know to look for the key.
50. As a player, I want the exit to show the intermission: the finished level's name, kills, items and secrets counted up as percentages, my time and par.
51. As a player, I want a press during the intermission to finish the counting, and the next press to go on.
52. As a player, I want E1M1 to start again after the intermission, since Bendoom has no second map.
53. As a player, I want a secret sector to count once when I enter it.
54. As a player, I want the doors, lift, switches, lights, pickups and music to keep working with monsters present.
55. As a player, I want the game to hold 35 frames a second with the monsters awake.
56. As a player recording a demo, I want fire and weapon changes written into it, so that Chocolate Doom plays my fight and the film shows it.
57. As a developer, I want the tic command to carry attack and weapon change as the demo's buttons byte does, so that one script drives Bendoom and vanilla.
58. As a developer, I want monster, missile, puff, blood and drop rows added to the thing tables only for types the two E1M1s can produce, so that no dead definitions enter.
59. As a developer, I want things spawned during play to get identities past the map's records, never reusing one, so that a script's output names the same thing throughout.
60. As a developer, I want moving things relinked in the blockmap and their sector's list in vanilla's order, so that collision and sprite order follow vanilla.
61. As a developer, I want every thinker run in vanilla's order, things spawned in play joining at the end, so that the random index stays on vanilla's tic.
62. As a developer, I want every `P_Random` draw made where vanilla makes it, including the ones that only choose a sound, so that a long fight stays in step with the oracle.
63. As a developer, I want line-of-sight to use the REJECT lump and vanilla's BSP sight check, so that monsters see exactly what vanilla's see.
64. As a developer, I want one path traversal that gathers lines and things in order of distance, used by hitscan, autoaim and the existing use-line search, so that there is one account of what a ray meets.
65. As a developer, I want health and damage compared as signed values, so that gibbing and overkill follow vanilla.
66. As a developer, I want the player's sprites drawn after the masked pass at vanilla's scale and light, with full-bright flashes, so that the weapon matches pixel for pixel.
67. As a developer, I want the frame to carry which of the WAD's 14 palettes is in force, so that flashes reach the window and the oracle.
68. As a developer, I want the status bar drawn into the frame's bottom 32 rows by the renderer from the state, so that the frame is still a pure function of tables, graphics and state.
69. As a developer, I want the oracle to run with monsters on and compare all 200 rows and the palette, so that its status-bar and pistol masks are deleted.
70. As a developer, I want the face and message timers, which keep running while Chocolate Doom is paused, checked by a replay of vanilla's source and not by the paused screenshot, so that the oracle never compares a frame it cannot pin.
71. As a developer, I want scripted fights that print each monster's state, health and place, the player's health, armour, ammo and ready weapon, and the random index, so that combat is checked at the program's boundary on both lanes.
72. As a proof author, I want replay composition to keep holding over monsters, missiles and weapons.
73. As a proof author, I want every thing that moved in a tic to stand where the position check passed, so that the freedom law covers monsters as it covers the player.
74. As a proof author, I want closed laws for armour absorption, ammo spent per shot, weapon selection order, drop amounts and the damage palette, so that the checker gates the numbers.
75. As a packager, I want the new cases in the flake check against Freedoom with no new dependency.
76. As a reader of the README, I want milestone 6 marked done only after both maps are played to the intermission with monsters and the oracle cases reach zero.

## Implementation Decisions

- The game stays single-player on Hurt Me Plenty. The monsters are the ones the two E1M1s spawn there: zombieman and imp in both, shotgun guy and demon in Freedoom alone. The shareware map's shotgun guys are for the harder skill, and the spectre appears in Freedoom's map on another skill only, so it gets no row and no fuzz column. The thing tables gain those monsters' states and actions, the imp's fireball, the bullet puff, blood, the dropped clip and shotgun, the gibs pool and the barrel's explosion. Nothing else.
- The weapons are the ones the maps can give: fist, chainsaw, pistol, shotgun. Freedoom's map holds the chainsaw and the berserk pack, the shareware map a shotgun, and Freedoom's shotgun guys drop theirs. The chaingun, launcher, plasma rifle and BFG have no state rows, and their number keys select nothing, since the player can never own them. Rockets and cells stay inventory numbers.
- The tic command gains vanilla's attack bit and its weapon-change bits, laid out as the demo's buttons byte. Ctrl fires. The keys 1 to 3 select as `G_BuildTiccmd` does. The demo recorder writes the byte and the demo reader returns it, so the film and Chocolate Doom both replay a fight.
- The sim reports the sounds it starts and carries vanilla's second random index. Each action starts its sounds where vanilla calls `S_StartSound`. The draws that pick a sound variant are `P_Random` draws and happen whether or not anything plays them.
- The player's weapon is vanilla's two player sprites, weapon and flash, each with a state, tics and a position. `P_MovePsprites` runs in the player's think. The actions are `A_WeaponReady`, `A_ReFire`, `A_CheckReload`, `A_Lower`, `A_Raise`, `A_Punch`, `A_Saw`, `A_FirePistol`, `A_FireShotgun`, `A_GunFlash` and the three light actions. The pending weapon, the refire count, the attack-down flag and the extra light join the player. Milestone 5's two deliberate gaps close: a picked-up weapon becomes pending, and the berserk pack brings up the fist. `P_GiveAmmo`'s switch to a better weapon comes with them.
- One traversal replaces the use key's private line search. It follows `P_PathTraverse`: it gathers the lines and the things a ray meets through the blockmap, sorts them by distance, and hands them to a visitor. The use key, `P_AimLineAttack` and `P_LineAttack` are three visitors. Autoaim keeps vanilla's slopes and its two retries to either side. No line in either map fires on a gunshot, so `P_ShootSpecialLine` is left out.
- Damage is `P_DamageMobj`: thrust from the blow, the chainsaw's exemption, armour absorbing by type, the player's damage count and attacker, pain chance, reaction time, the threshold that keeps a monster on its target, and the switch of target that makes infighting. Death is `P_KillMobj`: flags, the kill count, the gib test against spawn health, the death tics shortened by a random draw, and the drop. Health becomes a signed quantity wherever it is compared.
- Monsters think as vanilla's do. `A_Look` reads the sector's sound target and the ambush flag. `P_NoiseAlert` floods sectors through open two-sided lines and spends one pass through a sound-blocking line. `P_CheckSight` tests REJECT first and then walks the BSP with vanilla's slopes. `A_Chase`, `P_NewChaseDir`, `P_TryWalk` and `P_Move` give movement, including the use of a special line that blocked the move, which opens manual doors. Attacks are `A_PosAttack`, `A_SPosAttack`, `A_TroopAttack` and `A_SargAttack` with `P_CheckMeleeRange` and `P_CheckMissileRange`.
- The position check serves every mover. It takes the mover's radius, height and flags, tests things with heights for missiles, and returns what a missile hit. The player's pickups stay on it. Monsters never take pickups. A moved thing unlinks from its old blockmap cell and sector list and links into the new ones, newest first, as `P_SetThingPosition` does. Milestone 5's assumption that links are written once at spawn is removed with the code that relied on it.
- Missiles move through the same XY and Z movement as everything else, with the missile branches: they explode on a blocking line or thing, vanish against a sky ceiling, and deal `((P_Random % 8) + 1)` times their damage.
- Barrels are shootable things with health. `A_Explode` is `P_RadiusAttack` with vanilla's blockmap box, its distance measure and its sight test. A barrel's killer is credited to whoever shot it, so monsters infight over barrels.
- Movers crush as `PIT_ChangeSector` does: a corpse that no longer fits becomes gibs, a dropped item in the way is removed, and a shootable thing blocks. No crusher exists in either map, so crushing damage has no caller and stays out.
- Sector special 7 takes 5 health every 32 tics while the player stands on the floor. Special 9 counts a secret and clears itself. Neither map spawns a radiation suit on this skill, so the suit's protection and its green palette have no code.
- The player dies at zero health. `P_DeathThink` lowers the view to 6 units, turns it to the attacker, and waits for use. A press then builds a fresh state from the map as loaded, which is vanilla's single-player reborn. It uses the same path as the restart after the exit.
- All thinkers run in one list in creation order, as vanilla's do: map things in lump order, then the specials' thinkers, then whatever play spawns. The random index and its draws are vanilla's throughout.
- The renderer draws the player sprites after the masked pass, at scale one, centred as `R_DrawPSprite` centres them, lit by the player's sector plus the extra light, full bright on flash frames. Monsters bring the first rotated and mirrored frames into real frames. The projection already handles them, and the render cases now cover them.
- The status bar is drawn by the renderer into rows 168 to 199 from the state: the background, the big numbers, the arms panel, the keys, the small ammo numbers and the face. All patches come from the WAD. The face is `ST_updateFaceWidget`: its priorities, its counts, the pain offset, the direction of the last attacker, and the glance chosen by vanilla's second random index. That index advances once a tic for the face and once for each audible sound start, and begins where vanilla's stands after the level's wipe.
- Messages are vanilla's heads-up line: one message at a time in the WAD's font at the top of the view, held for 4 seconds. Pickups and the locked door's refusal set them. The strings are vanilla's English ones.
- The palette number is part of the frame's output. `ST_doPaletteStuff` chooses it from the damage count, the berserk fade and the bonus count. The window's fold reads the chosen palette of the WAD's 14.
- The intermission is a second game mode beside the level. It shows the background, the finished level's name, kills, items and secrets counted up at vanilla's pace, time and par, and then the screen that names the next level. Presses speed it up as vanilla's do. After it the game builds a fresh E1M1, where vanilla would load E1M2. That is this milestone's declared difference. The totals are counted at spawn (things flagged to count as kills or items, sectors with special 9). The printed level time is removed.
- The window, the loop, the music stream, the 320 by 200 frame and the 4:3 stretch stay as they are. The frame is still a pure function of tables, graphics and state.
- README's milestone 6 line is marked done only after both WADs play from start to intermission with monsters, the oracle cases reach zero, the frame-rate measurement passes, and the maintainer has played both maps.

## Testing Decisions

- A good test drives the one seam milestones 2 to 5 use. It loads a real E1M1, builds its state, replays a command script, then prints the state or renders the frame. It checks where monsters stand and what they are doing, what the player has left, and which pixels the renderer produces. It does not test chase-direction helpers, damage helpers or status-bar widgets on their own.
- Expected values come from outside the Bend code. Monster records, counts, REJECT bits and patch pixels are read from the WAD in nushell. Damage, spread, pain, drops, state durations and the face's choices come from linuxdoom-1.10 and Chocolate Doom's source, replayed in nushell over the random table where a draw is involved. Values with no outside answer are regression pins, and the ticket says so.
- The sim test gains scripted fights on Freedoom: a monster woken by sight and one by noise, a deaf one that stays asleep, a zombieman killed by the pistol with its drop taken, a shotgun blast, a punch with and without berserk, the chainsaw, an imp's fireball that hits and one that misses into a wall, a demon's bite, two monsters infighting, a barrel chain, a corpse crushed by a door, nukage damage, armour absorption, a weapon switch by key and one by empty ammo, the player's death and restart, a secret counted. Literal-state cases cover what no short route reaches.
- The oracle changes with this milestone. It runs Chocolate Doom with monsters, fires and switches weapons through the demo's buttons byte, and compares all 200 rows and the palette the screenshot carries. Its status-bar mask and its pistol mask are deleted, along with the rule that a script lasts at least 18 tics. The pause graphic's mask stays, since the pause is the oracle's own doing.
- Chocolate Doom's pause stops the playsim and nothing else. The status bar's ticker and the message ticker run on, so the face keeps changing and a message expires while the screenshot waits. The oracle therefore masks the face's box, except for the dead face, which holds. It runs with messages off, as it does now. The face's sequence is checked in the sim test against a nushell replay of `ST_updateFaceWidget`. Message pixels are checked in the render test against the font's patches read from the WAD, which the oracle's patch reader already does for the pause graphic.
- Every rest position in the render test stays at zero differing pixels with monsters on, or moves to a position whose monsters explain the new pixels. New render cases: a monster from the front, the side and behind, a mirrored rotation, a monster mid-attack, a fireball in flight, a corpse, a puff, blood, the pistol and the shotgun at rest and firing with the room lit by the flash, the weapon mid-switch, the status bar after a pickup and after damage, a red and a gold palette, the dead view.
- A long fight is the sync test. One script of several hundred tics on each WAD fights through the first rooms, and the frame at its end must be at zero. A single misplaced random draw anywhere shows up there.
- The intermission is compared once its counts have settled. Its animated background patches are masked, since they advance on the pause's wall-clock time.
- Laws keep the wall, geometry, replay, mover, thing and renderer laws. Replay composition grows to the new state. The freedom law grows from the player to every thing that moved. Closed laws pin armour absorption at both types, ammo per shot, the weapon chosen when ammo runs out, drop amounts, the gib threshold, the palette chosen for a damage count, and the face's pain offset. Each ticket adds a law where a property over all inputs shows up. All laws are filled in so the flake check gates them.
- Prior art is the scripted sim and route tests, the hashed render frames, the Chocolate Doom demo oracle, WAD inspection in nushell, the nushell replays of `P_SpawnMapThing` and `T_LightFlash` from milestones 4 and 5, and closed laws on literal levels.
- The window is measured on the dev machine in Freedoom's first fight, with the monsters awake and shooting. It must hold 35 frames a second, the bar of milestones 3 to 5 and 8. The ticket records the machine, the scene and the range.
- Both E1M1s are played through with monsters to the intermission. The shareware run is by hand, since its WAD is unfree. The Freedoom route test stays in the flake check and now has to survive or avoid the monsters on its way.

## Out of Scope

Sound effects themselves (milestone 7). The chaingun, launcher, plasma rifle and BFG, and every monster the two E1M1s do not spawn on Hurt Me Plenty, the spectre and its fuzz among them. Other skills, multiplayer, deathmatch, item respawn. Crushers, teleporters, gun-triggered lines and any special neither map uses. The automap, menus, cheats, save games, the pause, the title screen and the screen wipe. E1M2 and the finale. Look up and down, jumping, the mouse. Demo playback inside Bendoom. Hellbent.

## Further Notes

- Milestones 6 and 7 share the sim's sound events and random stream. Actions record sounds where vanilla starts them, and the mixer consumes those events without changing simulation order.
- Combat sync is the main fidelity risk. A fight has thousands of random draws spread over sight checks, chase turns, attack rolls, pain, puffs and death tics, and the thinker order decides who draws first. Long-fight oracle cases expose a misplaced draw.
- The status bar is the quieter risk. It was never checked, because the oracle masked it. The face cannot be pinned by a paused screenshot, which is why its check moves to a replay of vanilla's source.
- The Bend constraints that shape the implementation remain in the project's Bend guide.

# 06: The blue key opens its door

**What to build:** The first complete pickup path. The player starts with vanilla's initial inventory, walks into the blue key, receives the card on that tic, and removes the key from the active population. The existing locked door refuses before collection and opens afterward. Position checking returns the changed state explicitly, including vanilla's rule that a pickup touched before a later line rejection stays collected.

**Blocked by:** 02 (The non-monster population spawns)

**Status:** resolved

- [x] Player state gains health, armour, cards, ammo and caps, backpack, weapon ownership, powers, item count and pickup-flash count with vanilla start values
- [x] XY and vertical reach tests decide whether the player touches the key
- [x] A successful touch grants the blue card and removes only that stable thing identity on the same tic
- [x] A repeated touch cannot grant or remove anything again
- [x] The blue locked door refuses before the pickup and moves after it; either blue card or blue skull satisfies it
- [x] Position checking carries pickup changes through a move later rejected by a line when vanilla does
- [x] Replay composition holds over inventory and the active population
- [x] A Freedoom script prints the key's removal, card state and door heights before and after collection on both lanes
- [x] Render and oracle frames immediately before and after contact show the key present and absent
- [x] Existing mover, route and wall laws stay green


## Comments

Every expected value came from outside the Bend code: linuxdoom-1.10's p_inter.c, p_map.c, p_doors.c and g_game.c, the WAD read in nushell, and Chocolate Doom on the oracle's script.

What was built:

- `src/inventory.bend` is player_t's inventory. It holds health, armour points and type, and the six cards and skulls as bits in card_t order. It holds ammo and caps in ammotype_t order, the backpack, owned weapons as bits in weapontype_t order, the six power counters, the item count and bonuscount. `Inventory.start` is G_PlayerReborn's: 100 health, 50 bullets, caps 200 50 300 50, fist and pistol, nothing else. `Inventory.grant` is P_TouchSpecialThing's switch for the one type granted so far, the blue card, which P_GiveCard always takes in single player. `took` is the switch's tail, the COUNTITEM tally and bonuscount plus 6. `tic` is P_PlayerThink's bonuscount countdown.
- The player carries the inventory. `Sim.touch` is P_CheckPosition's thing half. It offers a special thing to the inventory when the thing's box overlaps the player's (its radius plus 16) and its bottom is between 8 under and 56 over the player's feet. When the grant takes the thing, the check drops it by record id. The check returns the new inventory and population. `Sim.try_move` keeps both whatever the line check says next, so a pickup touched before the lines refuse the move stays taken. `Sim.Try` carries the population through the slide and the XY movement, and `Sim.mobj` is P_MobjThinker for the player. The mover's re-clip, P_ThingHeightClip, also picks up, as vanilla's P_CheckPosition does there.
- Special 26 is the blue locked door. `Sim.door.locked` asks for the blue card or the blue skull and is then the manual door. Use reads the inventory the player had when it thought, before this tic's movement, because P_PlayerThink runs P_UseLines before the mobj moves.
- Restart goes through `State.start`, which rebuilds the key and G_PlayerReborn's inventory. The game test ends a level after the pickup, presses Enter, and gets 180 things and no card back.

The numbers:

- **Pickup tic.** On the oracle's script (from 2246 592 180: 20 idle tics, a turn of -16 to 157.5, then strafing left at 24), tic 33 leaves the player 37.79 east of the key and tic 34 leaves it 35.58 east and 28.51 south. The reach is 36, so tic 34 takes the key. Chocolate Doom's status bar key box is empty on tic 33 and shows the blue card on tic 34 of the same demo.
- **Pickup flash.** P_GiveCard sets 6 and the pickup adds 6, for 12 on the contact tic, then one less a tic: 2 ten tics later. The screenshot's palette is palette 0 either way, so vanilla does not confirm this count.
- **Door 71.** EV_VerticalDoor's top is 4 under the lowest ceiling beside it. Sectors 70 and 72 both have ceilings of 0, so the top is -4. At VDOORSPEED 2 from -128, used on tic 31, the door is at -126 after that tic, -106 at tic 41 and -4 at tic 92. It refuses the start's inventory and opens for the key's inventory or the blue skull alone.
- **Closed laws**, on the literal level, by hand. `blue_door_locked`: no card or the yellow card leaves the door at 0, the card or the skull makes it 2 up after the tic. `key_taken`: 40 short after tic 1, 32.75 on tic 2, only record 87 goes, card held, flash 12, then 11 with nothing touched again. `key_taken_once`: a move of 20 tried in halves takes the key once, flash 12 and not 18. `key_reach`: a bottom 56 over the feet is taken and 57 is not; 8 under is taken and 9 is not. `key_through_door`: the move into the shut door is refused, but its check has already taken a key 34 away, and the slide stops at most 48, out of reach. A mutated expected value fails the check, so the laws compute.
- Replay composition holds over the inventory and the population with no new proof. `replay_append` quantifies over the whole state. The wall-law proofs thread the population and gained lemmas for holding an inventory, a stairstep that ends the slide, the counters and the mobj's state.

The oracle, Freedoom with every thing kept (20 idle tics unless a script is given):

| case | place | script | differing |
| --- | --- | --- | --- |
| start | -416 256 0 | | 13 |
| lit | 736 464 135 | | 1229 |
| dark | -416 256 90 | | 0 |
| step | 137 256 45 | | 7 |
| grate | -416 256 180 | | 39 |
| water | 3 256 0 | | 0 |
| sky | -640 256 90 | | 0 |
| pit | 488 256 0 | | 13 |
| sergeant | 1144 259 315 | | 448 |
| stride | -416 256 0 | `34,50,0,0,0` | 0 |
| air | -416 256 0 | `56,50,0,0,0` | 3 |
| landed | -416 256 0 | `66,50,0,0,0` | 16 |
| door | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 41 |
| switch | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 |
| blink | 640 712 180 | `66,0,0,0,0` | 0 |
| water moving | 3 256 0 | `40,0,0,0,0` | 0 |
| key before, tic 33 | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 0 |
| key after, tic 34 | 2246 592 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 0 |

Every count before the key's equals ticket 02's. Its nonzero counts come from animation, full-bright frames and sprite order (tickets 03 to 05). The pickup changes no frame the sim reached before, and the render test's old hashes are unchanged.

The two key frames compare the key. Against our frame with record 87 left out of the WAD, the tic 33 frame differs in 44 pixels, all key colours. Against a throwaway build that never takes the key, the tic 34 frame differs in 347. So the first frame shows the key and the second shows it gone. A first attempt walked straight into the key from 2192 440 90, contact on tic 21. At contact a floor item sits below the view, or under the pistol's mask, in both games, so neither frame could see it. Strafing past keeps the key about 46 ahead through contact. The script's 20 idle tics put the bob low on those tics.

Trade-offs:

- **Touch order.** Things are offered the last spawned first, which is the order within one blockmap cell. Doom also walks the cells west to east, which only matters when one check touches two things whose grants interact. Only the blue card grants so far. Ticket 09 walks the blockmap for solid things.
- **Cost.** Every position check scans the population, prefiltered by Doom's MAXRADIUS box before the definition lookup. Against ticket 02, the route test runs in 314 ms native (from 193) and 1577 ms on bun (from 1413), about 0.2 ms a tic native. Without the prefilter it was 622 ms.
- **Dead toucher.** P_TouchSpecialThing's check for a dead toucher is left out: nothing lowers health until milestone 6.
- **Door scripts.** The door 71 scripts hand a fresh state at the door the inventory the key run left, built with the player's constructor. Freedoom has no short walk from the key to its door, and ticket 11 owns the full route.
- **Not represented.** Pickup messages, sounds, the status bar's key and the bonus palette have no representation, as the spec says.

Checks:

- Every test on both lanes. `bend PROOF.bend` prints "All terms check." The game, the benches and the tools build. `nix flake check` passes. The oracle table above was rerun on this branch.

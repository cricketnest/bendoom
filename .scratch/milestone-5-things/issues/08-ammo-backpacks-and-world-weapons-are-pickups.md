# 08: Ammo, backpacks and world weapons are pickups

**What to build:** Clips, shells, rockets, cells, their boxes, backpacks and map weapons update the inventory with vanilla amounts and caps. A backpack doubles caps once and grants ammo. A weapon pickup grants ownership and pickup ammo, then disappears when either grant succeeds. The ready weapon stays the pistol until milestone 6.

**Blocked by:** 06 (The blue key opens its door)

**Status:** resolved

- [x] Each ammo family and box uses vanilla clip counts, including the game's fixed skill multiplier
- [x] Ammo at its cap refuses a loose or boxed pickup and leaves it active
- [x] The first backpack doubles every ammo cap and every accepted backpack grants one clip of each ammo family
- [x] A later backpack does not double caps again
- [x] World weapons grant ownership and their vanilla pickup ammo
- [x] A weapon remains only when neither ownership nor ammo changes
- [x] Ready weapon, switching, firing and first-person weapon sprites remain unchanged and out of scope
- [x] Closed laws pin each ammo cap, backpack idempotence and weapon acceptance
- [x] Scripted Freedoom cases print ammo, caps, backpack and weapon ownership on both lanes
- [x] Render cases show accepted pickups disappear and refused pickups remain


## Comments

Every expected amount and cap came from linuxdoom-1.10's p_inter.c (P_TouchSpecialThing, P_GiveAmmo, P_GiveWeapon) and d_items.c. The WAD was read in nushell (tools/wad.nu) for the records. Chocolate Doom checked the frames.

What was built:

- `Inventory.grant` is still P_TouchSpecialThing's switch, and its `Maybe` is still the one answer: the inventory after the grant when the thing is taken, none when it stays. `Sim.touch` removes the thing on `Some` exactly as it did for the key, so ticket 06's same-tic removal, stable identities, touch before lines, and replay composition carry over without change. The switch gains every ammo, backpack and weapon type the two E1M1s place: 2007, 2048, 2008, 2049, 2047, 17, 2010, 2046, 8, 2001 to 2005. The blue card's case needed no special branch to remove.
- `Inventory.give` is P_GiveAmmo's rounds: clips times clipammo (10 4 20 1), up to the cap. Hurt Me Plenty doubles nothing, so no skill multiplier appears in the code. `Inventory.room` is its first test, ammo not equal to the cap. `Inventory.ammo` is a loose or boxed pickup: taken when there was room. A map clip is a whole clip; the dropped half-clip waits for monsters.
- `Inventory.weapon` is P_GiveWeapon for a weapon found, which brings two clips. The weapon is owned after, and the pickup is taken when the ammo had room or the weapon was new. The chainsaw has no ammo, so only ownership can take it. Doom's pendingweapon has no representation: the ready weapon stays the pistol.
- `Inventory.backpack` is always taken, as vanilla's backpack case never returns. The first doubles every cap (`Inventory.bag`), then each gives one clip of each ammo type through `give`, capped as usual.

The numbers, all from vanilla:

| pickup | from | to |
| --- | --- | --- |
| clip, shells, cell, rocket | 50 0 0 0 | 60, +4, +20, +1 |
| box of bullets, shells, cells, rockets | 50 0 0 0 | 100, 20, 100, 5 |
| any, at maxammo 200 50 300 50 | at the cap | refused, stays |
| box one short of its cap | 199 49 299 49 | fills that cap |
| first backpack | 50 0 0 0, caps 200 50 300 50 | 60 4 20 1, caps 400 100 600 100 |
| first backpack at the old caps | 200 50 300 50 | 210 54 320 51 |
| later backpack | 60 4 20 1 | 70 8 40 2, caps unchanged |
| later backpack at the doubled caps | 400 100 600 100 | taken, nothing changes |
| shotgun, not owned | weapons 3, shells 0 | weapons 7, shells 8 |
| shotgun, owned, room | shells 8 | 16, taken |
| shotgun, owned, 50 shells | | stays |
| shotgun, not owned, 50 shells | weapons 3 | 7, taken |
| chaingun, rocket launcher, plasma rifle | start | +20 bullets, +2 rockets, +40 cells |
| chaingun, owned, 200 bullets | | stays |
| chainsaw | weapons 3 | 131; owned, stays |

Each taken pickup adds the flash of 6. None of these types is COUNTITEM, so the item count stays.

Closed laws on the literal level, each a tic that brings the player 8 from the item: `ammo_amounts`, `ammo_caps`, `backpack_first`, `backpack_later` and `weapon_taken` hold the table above. `Closed.among` now takes the inventory, so ticket 06's key laws and these share one builder. Changing one expected value in each of the five laws makes `bend PROOF.bend` fail at that law, so they compute. Merged with ticket 07, its laws and these share one driver, `Closed.offer`, one result, `Closed.Got`, and one builder, `Closed.inv`, a list of edits to G_PlayerReborn's inventory.

Scripted Freedoom cases (tests/sim.bend, both lanes) go through the real load, `State.at`, replay and touch. Freedoom's E1M1 on Hurt Me Plenty in single player, read from THINGS in nushell, carries these records:

- clips 139 and 140
- 14 shells
- shell box 137
- box of bullets 210
- cell 278
- rocket 279
- the chainsaw, record 2

Its other ammo and weapon records are multiplayer-only or for other skills; the shotguns (183, 256) and the backpack (288) are for the easy ones, so no case here reaches them and the laws `backpack_first`, `backpack_later` and `weapon_taken` hold those grants. Each case prints the tic before contact and the contact tic:

- Clip 140 walked into from the east: tic 10, bullets 60.
- The shells in a row, 276, 208 and 207: tics 9, 18 and 26, shells 12. At 50 shells nothing is taken.
- Rocket 279: tic 9. At 50 rockets it stays.
- Shell box 137 behind closet door 48: an idle tic, since G_PlayerReborn starts use held, then the use and the walk. Tic 52 gives 20 shells, 45 becomes 50, and 50 leaves the box.
- The chainsaw on its step, strafed past on the key's script: taken on tic 34, weapons 131. Owned, it stays.

The contact tics are the reach's (radius 20 plus 16), checked against the printed positions. For example, tic 34 leaves the player 35.58 east and 28.51 south of the chainsaw. They are regression pins. Box of bullets 210 and cell 278 stand in closets shut by sectors 129 and 77, whose floors meet their ceilings. The cases do not open those, so the box of bullets, the cell, and the types Freedoom does not place on this skill rest on the laws.

The oracle, Freedoom with every thing kept. The new frames are also in tests/render.bend:

| case | place | script | differing |
| --- | --- | --- | --- |
| rocket before, tic 32 | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 11,0,-24,0,0` | 0 |
| rocket after, tic 33 | 714 -1011 90 | `20,0,0,0,0 1,0,0,16,0 12,0,-24,0,0` | 0 |
| chainsaw before, tic 33 | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 12,0,-24,0,0` | 10, 0 merged |
| chainsaw after, tic 34 | 3158 2176 180 | `20,0,0,0,0 1,0,0,-16,0 13,0,-24,0,0` | 0 |

The rocket, 24 units tall, is taken on tic 33, about 46 ahead and 19 left: screen columns 77 to 111, clear of the pistol mask. A pickup of rockets from none switches no weapon from the pistol, so this is a fidelity case. The chainsaw's contact tic is comparable too: vanilla sets its pending weapon then, but the pistol only starts down on the next tic. Its before frame's 10 pixels, at x 76 and 77 near the horizon and on row 121 from x 233, are not the chainsaw's: merged with tickets 01 to 05 the frame reports 0. The six on row 121 are ticket 03's sprite clipping, the four at x 76 and 77 ticket 05's animation. It is not in the render test. The refused frames hold every weapon and every ammo type at its cap. Vanilla's demo cannot reach that inventory, so they are not compared. Against their taken twins they differ in exactly the sprite: 762 pixels of the rocket (columns 77 to 111, rows 136 to 167) and 5092 of the chainsaw. Rerun on this branch, ticket 06's table is unchanged, key frames 0 and 0, and every older render hash is unchanged.

Trade-offs:

- **Not represented.** The pending weapon, the dropped half-clip, messages and sounds, as the spec says.
- **Touch order.** Since the merge with ticket 09 the grants run inside its blockmap walk, P_CheckPosition's order, until the first solid thing that overlaps the player stops the check, so two ammo pickups touched by one check near a cap resolve as in Chocolate Doom. Every law and script here touches one item per check.
- **P_GiveAmmo's weapon switch** is not represented because milestone 5 cannot reach it. It fires only when the ammo was 0: for bullets and rockets with the fist ready, for shells and cells with the fist or pistol ready and the shotgun or plasma rifle owned. The pistol stays ready, and no ammo count drops to 0: nothing spends ammo, and a weapon pickup gives its ammo before the weapon is owned. Milestone 6, which fires weapons, owns the switch.

Checks:

- Every test on both lanes.
- `bend PROOF.bend` prints "All terms check." (65 s).
- `nix flake check` passes.
- `git diff --check` is clean.
- Merged with tickets 01 to 07: every test on both lanes, `bend PROOF.bend`, `nix flake check` and `git diff --check` pass, and one mutated expected value in each of the five laws fails at that law.

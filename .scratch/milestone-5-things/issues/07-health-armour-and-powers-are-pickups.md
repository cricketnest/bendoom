# 07: Health, armour and powers are pickups

**What to build:** E1M1's health, armour and power items grant their vanilla values and disappear only when the player can accept them. Bonuses use their 200 caps, ordinary healing stops at 100, armour type controls whether armour is an improvement, and the berserk pack records its power and health effect without adding milestone 6's fist behavior.

**Blocked by:** 06 (The blue key opens its door)

**Status:** resolved

- [x] Health bonuses add one up to 200 and always count when accepted
- [x] Stimpacks and medikits add their vanilla amounts up to 100 and remain when health is full
- [x] Soul spheres and the berserk pack apply the vanilla health rules used by the two E1M1s
- [x] Armour bonuses add one up to 200 and establish green armour when needed
- [x] Green and blue armour grant their vanilla points and types and remain when they cannot improve the player
- [x] Supported power state advances without adding palette, automap, invisibility or weapon behavior owned by later milestones
- [x] COUNTITEM pickups increase item count once; other pickups do not
- [x] Literal-state laws pin accepted and refused grants at every cap
- [x] Scripted Freedoom cases print state and remaining stable identities on both lanes
- [x] Before-and-after render frames agree with pickup removal


## Comments

Every expected value came from outside the Bend code: Chocolate Doom 3.1.1's p_inter.c, p_user.c, deh_misc.h and doomdef.h (from nixpkgs' `chocolate-doom.src`), the WADs read in nushell, and Chocolate Doom playing the oracle's scripts.

What was built:

- `Inventory.grant` takes the eight types on the same path as the blue key: `Sim.touch` offers, `Inventory.took` tallies and flashes, and the check drops the thing by record id. The stimpack and medikit are P_GiveBody's 10 and 25: refused at 100 health or more, otherwise healed to at most 100. The soul sphere adds 100 and the health bonus 1, up to 200, and both are always taken. The armour bonus adds 1 up to 200 and sets type 1 when no armour is worn. Green and blue armour are P_GiveArmor: 100 points per type level, with the type, taken over fewer points of any type and refused at as many or more. The berserk pack is P_GivePower's strength: P_GiveBody's 100 whatever it returns, the counter set to 1, always taken. COUNTITEM stays in the definitions (the two bonuses, the soul sphere, the berserk pack).
- `Inventory.tic` counts strength up by one a tic once it is on, as P_PlayerThink does. The fist, the pending weapon and the red palette are not represented.
- The masks and indexes stay in inventory.bend: the blue lock's mask 9 moved out of sim.bend into `Inventory.blue`, and the power index is `Inventory.pw_strength`. sim.bend gains no numbers.
- `Sim.touch` is unchanged, and so is its reverse spawn order. Its comment now says that order is Doom's within one blockmap cell only.

Acceptance and refusal boundaries, the closed laws, by hand. Each offers a thing named 7 in reach and one named 8 out of reach. An accepted grant leaves only 8 and a flash of 6; a refusal leaves both and the inventory untouched.

| type | taken | left |
| --- | --- | --- |
| health bonus 2014, counted | 100→101, 199→200, 200→200 | never |
| stimpack 2011 | 89→99, 99→100 | 100 |
| medikit 2012 | 74→99, 75→100, 99→100 | 100, 150 |
| soul sphere 2013, counted | 99→199, 100→200, 101→200, 200→200 | never |
| berserk 2023, counted | 1→100, 100→100, 150→150, strength 40→1 | never |
| armour bonus 2015, counted | none→1 green, 199 blue→200 blue, 200 green→200 green | never |
| green armour 2018 | none→100 green, 99 blue→100 green | 100 green, 150 blue |
| blue armour 2019 | none→200 blue, 199 green→200 blue | 200 green, 200 blue |

`bonus_counted_once`: a 20-unit move tried in halves, both in reach of a health bonus, takes it once: 101 health, tally 1, flash 6. `strength_counts`: a berserk pack taken on tic 1 leaves the counter and flash at 1 and 6, then 2 and 5, then 3 and 4. Six mutated expected values each fail at their own law.

Scripted Freedoom cases, `tests/sim.bend` on both lanes: each pickup walked at alone from 80 short, printed on the tic before contact (41.61 short) and the tic of it (35.84 short, reach 36). Each line prints the inventory, which of records 268, 215, 259, 291, 204 and 6 remain, and the thing count:

- health bonus 268: 101, tally 1; at 200 it is taken for nothing, tally 1
- stimpack 215 at 100 health: stays, and still stays after 10 more tics walking across it; at 60 health it heals to 70 and only 215 goes
- medikit 259: stays at 100; at 60 it heals to 85
- berserk 291: at 100, health stays 100, strength 1, tally 1, and strength is 11 ten tics later; at 60 it heals to 100
- armour bonus 204: 1 point of type 1, tally 1
- green armour 6: 100 of type 1, tally 0; with 100 of type 1 worn it stays

Freedoom's only soul sphere, record 231, is multiplayer-only. Blue armour is in the shareware map only. Those two rest on the laws and the shareware oracle below.

The oracle (20 idle tics unless a script says otherwise):

| case | place | script | differing |
| --- | --- | --- | --- |
| bonus before, tic 38 | 2590 780 90 | `20,0,0,0,0 18,25,0,0,0` | 0 |
| bonus after, tic 39 | 2590 780 90 | `20,0,0,0,0 19,25,0,0,0` | 0 |
| green armour before | 1631 1008 90 | | 37 |
| green armour after | 1631 1008 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` | 31 |
| stimpack and medikit before | 0 400 90 | | 0 |
| stimpack and medikit refused | 0 400 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` | 0 |
| shareware blue armour before | 1791 -3360 90 | `26,0,0,0,0` | 0 |
| shareware blue armour after | 1791 -3360 90 | `20,0,0,0,0 16,25,0,0,0 24,-25,0,0,0` | 0 |

- **Bonus.** Health bonus 223 stands on a step 24 above the player, which keeps it in view at contact. Tic 38 leaves the player 36.86 south of it, tic 39 29.81 south and 30.04 west. The walk runs up x 2590 rather than 2620 because a burnt tree, solid in vanilla, stands at 2624 832.
- **Coverage.** Throwaway builds show each comparison covers the pickup. One that never takes the bonus or the green armour differs from our frames in 1465 pixels of the bonus-after frame and 2137 of the green-armour-after frame. One that takes the stimpack and medikit at 100 health differs in 2744 of the refused frame.
- **Green armour's counts.** They are four distant health bonuses whose animation is ticket 05's; none falls in the armour's columns. The armour sits 33 to the right of the walk, so most of it is outside the pistol mask.
- **Shareware blue armour.** It runs outside the flake. At 20 idle tics the before frame differs in 884 pixels, all on the armour: vanilla is on its second animation frame (ticket 05). At 26 idle tics it is 0.

The render test's old hashes and the sim test's old lines are unchanged, so ticket 06's oracle table stands.

Trade-offs:

- **Touch order.** One position check still offers the last-spawned thing first. Health bonuses and armour bonuses commute with each other, but a stimpack, medikit or health bonus near 100 health does not commute with another healing item. Two such items in different blockmap cells, touched by one check, can resolve differently from vanilla until ticket 09's blockmap walk. Every law and script here touches one item per check.
- **Berserk.** The fist, the pending weapon and the red palette wait for milestone 6. Vanilla lowers the pistol on the tic after a berserk pickup, so no render case follows one.
- **Health is unsigned.** P_GiveBody compares signed health. Nothing lowers health until milestone 6, and there P_TouchSpecialThing refuses a dead toucher before any grant, so the unsigned compare never differs.

Checks:

- Every test on both lanes. `bend PROOF.bend` prints "All terms check." `nix flake check` passes. The oracle rows above were run on this branch.

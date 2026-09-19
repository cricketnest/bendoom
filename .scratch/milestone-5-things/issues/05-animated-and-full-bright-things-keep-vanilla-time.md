# 05: Animated and full-bright things keep vanilla time

**What to build:** Animated bonuses and decorations run their vanilla state sequences in the replay. Spawning things consumes the random table in the same order as vanilla, including the initial state duration, before the level's light thinkers start. Each tic advances finite states and full-bright frames use the first colormap. Static states avoid the animation path.

**Blocked by:** 02 (The non-monster population spawns)

**Status:** resolved

- [x] Reachable non-monster state rows carry sprite, frame, full-bright, duration and next state from vanilla
- [x] Spawn consumes P_SpawnMobj and P_SpawnMapThing random calls in THINGS order
- [x] The initial state duration and every later transition match vanilla to the tic
- [x] Static minus-one states do not take an animation branch each tic
- [x] Thing thinkers run in vanilla order relative to lights, movers and the clock
- [x] The random index and milestone 4 blink expectations are updated from vanilla's populated spawn order, not copied from current output
- [x] Full-bright frames ignore sector darkness while ordinary frames keep sprite lighting
- [x] Closed laws pin spawn phase and at least one complete animated-item cycle
- [x] Two oracle frames on different animation states report zero differing sprite pixels
- [x] Both lanes and the flake check pass


## Comments

Every expected value came from outside the Bend code. A throwaway nushell script parsed Chocolate Doom 3.1.1's `info.c` and `m_random.c`, replayed P_SpawnMapThing over the THINGS records, then ran the state half of P_MobjThinker tic by tic. The same script printed the Bend row and definition tables, so no row was typed by hand. Its spawn gives ticket 02's numbers again (180 things, index 254 before the flashes; 85 and 131 on the shareware map), so ticket 02's spawn draws, initial tics, `src/random.bend` and blink lines stand unchanged. The sim test still prints them.

From the 40 definitions' spawn states, 59 states are reachable. None has 0 tics or an action, so one tic enters at most one state. The animated ones are S_ARM1/ARM1A (6 and 7 tics, the second full-bright), S_ARM2/ARM2A, S_BAR1/BAR2, the six S_BON1 and six S_BON2 states, S_BKEY/BKEY2 (10 each, the second full-bright), the six full-bright S_SOUL states, and S_LIVESTICK/LIVESTICK2 (6 and 8). S_PSTR, S_COLU and S_CANDELABRA are full-bright and lasting.

What was built:

- `Thing.Row` carries sprite, frame, full-bright bit, tics and next row. The rows are the 59 reachable states in info.c's order, and the definitions point at their spawn rows among them. A lasting row's next, vanilla's S_NULL, names the row itself. No tic reads it; the sprite load's chase does, and meeting the row itself there ends the chase.
- `Thing.tic` is P_MobjThinker for a thing that does not move. A thing whose tics are -1 matches the first case and comes back as it was, with no row read and no decrement. Otherwise its tics count down, and on the tic they reach zero it enters the next row for that row's tics.
- `Sim.thinkers` runs every thing's tic before the lights and movers, because vanilla spawns the things (P_LoadThings) before P_SpawnSpecials adds the lights, and movers come later still. That is after the player's move, eye, use and crossings and before the clock counts, as in P_Ticker. Things draw no random numbers, so the index is untouched.
- The sprite load follows every row reachable from a spawned thing. It chases each thing's state through `next` until it comes back to the start (fuel is the row count), and the name table drops duplicates. POL6B0, reached only by animation, is loaded; the load test reads its offset of 15 against POL6A0's 14.
- The sprite table has a sixth word in each of a row's eight views, 1 for a full-bright frame. Projection then gives such a frame the first colormap and every other frame its sector-light colormap, with no row lookup per frame.
- Three closed laws. `spawn_phase` pins a literal level's player, health bonus and green armour: entries 3 and 5 of the table (220 and 241) give first tics 1 + 220 mod 6 = 5 and 1 + 241 mod 6 = 2, index 5. `bonus_cycle` pins both things over one whole bonus cycle, 35 tics, back to S_BON1 for 6, with the armour on its 13-tic cycle, the index still 5 and the clock at 35. `lasting_stays` says a -1 thing is unchanged by its tic, for every thing. Changing one expected value in each made the checker refuse it.
- The sim test prints the rows and tics of seven things at tics 0 to 5, 13, 23, 35 and 36: a lasting chainsaw, the armour, the blue key, a barrel, an armour bonus, a health bonus and the twitching impaled body. Every line is the nushell replay's. The six spawn records now print their new row numbers.
- The render test's rest frames replay the oracle's 20 idle tics first. Before this ticket a rest frame at tic 0 differed from the oracle's tic 20 only in animated flats. Now thing states differ too, so the hash has to be the frame the oracle compared. That made "water moving" (20 idle tics at the water) the same frame as "water", with the same hash, so it is gone. Two frames are new: the blue key from 2380 600 180 after tic 22, the last of S_BKEY, and tic 23, the first of full-bright S_BKEY2.

The oracle (Freedoom unless named, 20 idle tics unless a script is given):

| case | place | script | differing | ticket 02 |
| --- | --- | --- | --- | --- |
| start | -416 256 0 | | 0 | 13 |
| lit | 736 464 135 | | 0 | 1229 |
| dark | -416 256 90 | | 0 | 0 |
| step | 137 256 45 | | 0 | 7 |
| grate | -416 256 180 | | 39 | 39 |
| water | 3 256 0 | | 0 | 0 |
| sky | -640 256 90 | | 0 | 0 |
| pit | 488 256 0 | | 0 | 13 |
| sergeant | 1144 259 315 | | 0 | 448 |
| stride | -416 256 0 | `34,50,0,0,0` | 0 | 0 |
| air | -416 256 0 | `56,50,0,0,0` | 0 | 3 |
| landed | -416 256 0 | `66,50,0,0,0` | 0 | 16 |
| door | 832 384 90 | `20,0,0,0,0 20,25,0,0,0 1,0,0,0,1 20,0,0,0,0` | 14 | 41 |
| switch | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 | 0 |
| blink | 640 712 180 | `66,0,0,0,0` | 0 | 0 |
| key dim | 2380 600 180 | `22,0,0,0,0` | 0 | |
| key bright | 2380 600 180 | `23,0,0,0,0` | 0 | |
| armour and bonuses | 1600 1000 90 | `20,0,0,0,0` | 0 | |
| armour and bonuses | 1600 1000 90 | `27,0,0,0,0` | 0 | |
| shareware start | 1056 -3616 90 | | 0 | 5 |
| shareware pedestal | -120 -3160 180 | | 0 | 871 |
| shareware nukage | 1800 -3300 0 | | 0 | 0 |

The key cases do discriminate. Our frames at tics 22 and 23 differ in 159 pixels, all on the key. Both match vanilla, so vanilla's differ there too, and a phase one tic off would fail. A throwaway build that ignored the full-bright word reported 163 differing pixels at tic 23 (4 at tic 22, from a lasting full-bright thing in view).

The grate's 39 and the door's 14 are ticket 03's. In both, trees overlap other sprites unsorted: in the door frame a tree covers a small far sprite in vanilla, and ours draws the sprite over it. A throwaway copy that sorted the sprites far to near put both at 0.

Trade-offs:

- **The armour cannot test full-bright.** Freedoom's ARM1A0 and ARM1B0 are byte for byte the same, and its sector 130 has light 240. That light's scale row is colormap 0 at every distance, so bright and dim armour draw the same pixels. The blue key in sector 35, light 180, is the case that shows it, and only from past about 160 units: nearer, its scale also reaches colormap 0. The armour frames stay as a check on the bonuses' art frames.
- **Most key views meet ticket 04.** From 2192 400 90, 2192 480 90 and three other angles, the fence's masked middle texture and the sprites behind it disagree with vanilla by 14 to 62 pixels, the depth pass ticket 04 replaces. The chosen view keeps the key clear of the fence.
- **A transition reads the row list.** `Thing.row` walks the 59-row literal, twice on a transition and never on a lasting or counting tic. Over 3500 idle tics on Freedoom the replay went from 314 to 341 ms, about 8 µs a tic, against a 28 ms tic. `bench/frames.bend` showed no difference beyond its run-to-run noise.
- **The lasting row's next names itself.** Vanilla's S_NULL removes a thing, and ticket 06 removes things by dropping them from the population, so no row needs a removal target yet.

Checks:

- Every test on both lanes, `bend PROOF.bend` ("All terms check."), and `nix flake check`.
- The shareware sim run with `BENDOOM_IWAD` set to `doom1.wad`, outside the flake: 85 things, index 132, and its state lines equal the nushell replay's.

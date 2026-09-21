# 23: The face

**What to build:** The marine's face on the status bar, as `ST_updateFaceWidget` decides it: the health level, the idle glance, the wince toward the side damage came from, the ouch face, the grin at a new weapon, the grimace while fire is held, and dead. The glance is chosen by vanilla's second random index, which advances once a tic here and once for each audible sound start.

**Blocked by:** 04 (The status bar shows the inventory), 09 (The nukage hurts and the player dies), 12 (Weapons switch and the shotgun fires), 17 (Zombiemen and shotgun guys shoot); milestone 7's 01 (The sim reports its sounds)

**Status:** resolved

- [x] Every priority of `ST_updateFaceWidget` that the two maps can reach, with its count, including vanilla's ouch-face bug as it stands
- [x] The second random index starts at 64 and counts as milestone 7's ticket 01 left it; that ticket found that under `-playdemo` one or two tics run before the melt's draws, so check from the source which table entries `ST_Ticker`'s first draws read
- [x] The face's state is in the sim's state and advances once a tic, so that replay composition holds
- [x] The sim test prints the face index per tic on cases of damage from each side, a weapon pickup, held fire, and idling, against a nushell replay of `st_stuff.c` over the second random index
- [x] Chocolate Doom's face keeps changing under the oracle's pause, so the oracle keeps its mask over the face's box except for the dead face, which holds and compares at zero
- [x] Render cases compare the face's pixels with its patches read from the WAD in nushell
- [x] A closed law pins the pain offset at each health level's edge

## Comments

21 Sep 2026. The maintainer played both packages of this branch in the window to the intermission and the face looks right. What is left is the deferred list below, all of it an agent's: tickets 12, 17 and 18 have since given the map weapon switching and attacking monsters, so the grin and the wince can now come from real play.

### What was built

- `src/sim.bend`, "The face": `Sim.face.pain` is `ST_calcPainOffset`, whose static cache answers the same offset for the same health and so keeps no state. `Sim.face.dead`, `.grin`, `.hit`, `.own`, `.rampage` and `.glance` are `ST_updateFaceWidget`'s priorities in its order, each a function of the face vector it is handed; `Sim.face.ticked` is the `st_facecount--` that ends it and `Sim.face.widget` the chain. `Sim.face.wince` and `Sim.face.turn` are the turn, `R_PointToAngle2` to the attacker against the player's facing with vanilla's comment's own confusion kept. `Sim.face.ouch` is vanilla's ouch test with the subtraction the wrong way round, which is the bug as it stands.
- `Sim.st.ticker` is `ST_Ticker`, which `G_Ticker` runs after `P_Ticker`: it draws from M_Random, runs the widget over that number, and then writes the health the next tic looks back at. It is the last step of `Sim.tic.live`, so it sees the damage count already faded by `P_PlayerThink`'s counters and comes after every sound that tic started, which is where vanilla's draw falls.
- `State`'s `mrnd` field is a `V.Vec`: `Sim.Face` lays it out as the face index, the tics that face has left, the priority, the health seen last, the count of tics fire has been held, the weapons owned when the grin last looked, M_Random's index, and `attackdown`. `State.mrnd` reads its slot and `State.face` the whole vector. The reason is the width cap: the state had no word to spare, see Trade-offs.
- `src/gfx.bend`: `Gfx.bar.faces` is `ST_loadUnloadGraphics`' face states in its order, eight a pain level then `STFGOD0` and `STFDEAD0`; `Gfx.bar.names()` gained the 42, which `Gfx.bar` numbers from 35.
- `src/bar.bend`: `Bar.face()` is slot 35, and `Bar.icons` draws `Gfx.bar(gfx, 35 + index)` at `ST_FACESX`, `ST_FACESY`, between the arms numbers and the key slots, which is `ST_drawWidgets`' order. `Bar.draw` takes the index.
- `src/render.bend` passes `Sim.Face.index(State.face(s))`.
- `tools/oracle.nu` reports a second count, `face`, the differing pixels inside the face's box. The box is still masked out of `differing`, since vanilla's ticker runs on under the pause and the face keeps changing; `face` is 0 only where the face holds still, as the dead one does.
- `LAWS.bend`, `PROOF.bend`: `pain_offset`. `use_fires_once`'s quantified `mrnd` is now a `V.Vec`, and `door_sounds`' index reads 221.
- Tests: `tests/sim.bend`'s face cases, `tests/render.bend`'s sixth sampled pixel.

### Where the expected values came from

- The priorities, their counts and the face lump order: `st_stuff.c` read by hand. `ST_FACESTRIDE` is 8, so `ST_TURNOFFSET` 3, `ST_OUCHOFFSET` 5, `ST_EVILGRINOFFSET` 6, `ST_RAMPAGEOFFSET` 7, `ST_GODFACE` 40 and `ST_DEADFACE` 41. `ST_EVILGRINCOUNT` 70, `ST_TURNCOUNT` and `ST_OUCHCOUNT` 35, `ST_RAMPAGEDELAY` 70, `ST_STRAIGHTFACECOUNT` 17, `ST_MUCHPAIN` 20.
- `ST_initData`: `st_faceindex` 0, `st_oldhealth` -1, `oldweaponsowned` the player's. `st_facecount`, `priority` and `lastattackdown` are statics it does not touch, so at a fresh game they are 0, 0 and -1, which is what `Sim.Face.start` holds.
- The pain offsets: `8 * ((100 - health) * 5 / 101)` worked in nushell at every edge, 0 at 100 down to 80, 8 at 79 down to 60, then 16, 24 and 32, which is law `pain_offset` and the sim test's 7, 15, 23, 31 and 39.
- The glances: `rndtable` read from `m_random.c` in nushell. Each face line carries the M_Random index the tic's draw left, so each is `ST_calcPainOffset(health) + rndtable[index] % 3` checked in nushell: 197 at 65 and 92 at 99 give 2, 249 at 82 and 171 at 124 give 0, 145 at 101 and 61 at 137 give 1, and all eight glances the test prints agree. Printing the draw is what turns them from pins into computed values; before the sight ticket merged they were 64 plus the tic plus the sounds, and the sights now count too.
- The sides: `R_PointToAngle2` by hand for a player at the origin facing east. A barrel due south is at `ANG270`, which is above the facing, so the difference is `ANG270` itself, past `ANG180`, and the face turns right, offset 3. Due north is `ANG90 - 1 - tantoangle[0]`, above the facing too, and the difference is under `ANG180`, so the face turns left, offset 4. Due east the difference is 0, inside `ANG45`, so the face is the rampage one, offset 7.
- `ST_RAMPAGEDELAY` on the 71st tic of held fire: the first tic finds `lastattackdown` at -1 and sets it to 70, and each tic after it takes one off before the test, so it reaches 0 on the 71st.
- `M_Random`'s index in every case: 64 at the level's start, one for each tic, which is `ST_Ticker`'s draw, and one for each audible sound start but the item pickup's. The idling case ends at 124 after 60 tics with nothing heard, the blows at 68 after 4 in the closed room, and held fire at 144 after 75 tics and 5 pistol shots. Cases in the yard also count the monsters' sights, which milestone 6's ticket 15 added.
- The face pixel the render test samples, row 180 column 155: `tools/oracle.nu`'s `patch-pixels` over Freedoom says 72 in `STFST00`, 64 in `STFST01`, 59 in `STFST02`, 79 in `STFEVL0` and 8 in `STFDEAD0`.

### The first two tics under -playdemo, settled

Milestone 7's ticket 01 left this open: the sim starts `mrnd` at 64, which is the melt's 320 draws modulo 256, but under `-playdemo` the melt has not run when `ST_Ticker` first draws. `D_DoomMain` calls `TryRunTics` once before `D_DoomLoop`'s loop and `D_RunFrame` calls it again before the first `D_Display`, so at least two tics run before the melt; `G_InitNew` has cleared the index, so those tics read the table at 1 and 2 where this sim reads 65 and 66. After the melt the two agree exactly, since the melt adds 320 and 320 modulo 256 is the 64 this sim began with.

It does not change a face. The only tics whose draw is read are the ones a glance is chosen on, the first and then every 17th, and `rndtable` at 1 and at 65 are 8 and 197, both 2 modulo 3, so the first glance is the same face either way; the second glance falls on tic 18, long after the melt. `rndtable` at 2 and at 66 are 109 and 4, both 1 modulo 3, so a first tic that drew for a sound would agree as well.

### The oracle

`nu tools/oracle.nu x y degrees script --frame /tmp/m6-23/frame`, the dump built from this tree, Freedoom, `masked` 1595 in each. `face` is the differing pixels inside the face's box, which is masked out of `differing`.

| case | place | script | differing | face |
| --- | --- | --- | --- | --- |
| the dead face | 1600 1000 90 | `650,0,0,0,0` | 48983 | 0 |
| start, at rest | -416 256 0 | `20,0,0,0,0` | 0 | 66 |
| switch pressed | 2064 -260 90 | `20,0,0,0,0 10,25,0,0,0 1,0,0,0,1 27,0,0,0,0` | 0 | 28 |

At this ticket's checkpoint the dead view differed by 48983 pixels because chase had not landed; the face box itself was at zero. and it is the one face that holds still under the pause. The other two rows are the living face changing under the pause, which is why the box stays masked, beside 0 differing everywhere else.

The face's pixels were then compared with the patches themselves, `tools/oracle.nu`'s `patch-pixels` over Freedoom against our own frame dump: all 578 pixels of `STFST00` in the rested start's frame and all 591 of `STFDEAD0` in the dead one, none differing. Against the wrong lump, `STFST01`, the start's frame differs in 64 pixels, so the check has teeth.

### Verification pass

- The face now keeps `player->attackdown` in the existing face vector. `G_PlayerReborn` starts it true, `A_WeaponReady` writes the command's attack bit, and `ST_Ticker` reads the kept value. It no longer reads the command directly. A one-tic release during the pistol's firing rows therefore leaves the rampage countdown running.
- Chocolate Doom was traced in GDB at `ST_updateFaceWidget` from the Freedoom start. Continuous fire and 69 tics of fire followed by a release on tic 70 both leave `attackdown` true. Both have `lastattackdown` 2 on tic 69, 1 on tic 70, and show face 7 on tic 71. The sim test now replays both paths through the whole state and gets the same transition and count.
- The shotgun guy at record 96 now supplies a real map attack for the wince case. Its first shot on tic 61 takes the player to 73 health, and the face turns left at pain level 1, index 15, with 34 tics left after `ST_Ticker` decrements it. The chainsaw pickup case already walks over the real map weapon and shows index 6, so the grin no longer depends on a constructed inventory.
- The maintainer played both the Freedoom and shareware packages to the intermission with sound and accepted the face. The face state machine does not read WAD-specific data; each package supplies its own 42 patches through the same table.
- A removed attacker cannot reach the fallback in these maps. Hitscan and melee damage record the attacking monster, whose corpse remains. Missile damage records the missile's source, not the missile. A barrel remains through its explosion states while the hit is handled. The only things removed immediately are pickups and crushed dropped items, and neither can damage the player. The fallback remains defensive behavior outside the maps' reachable cases.
- `ST_GODFACE` remains unreachable. Neither cheat input nor an invulnerability pickup exists in these maps, so the lump stays loaded without a face-selection stage.

### Trade-offs

- The face's counters and `attackdown` share the state's `mrnd` field as a `V.Vec`, rather than taking fields of their own. A field costs three words of `Sim.turn`'s budget and the native build refuses a segment over 255: a thirteenth field on `State` failed with "an arity over 255" where the JS lane built the same program. The accessors hide the vector, so the state record stays within the native compiler's width limit.
- The face is on the state, not the player. Vanilla's are `st_stuff.c` statics and `ST_Ticker` runs outside `P_Ticker`; putting them on the player would also have broken every law that pins a whole player after a tic, since the face steps every tic.
- `Sim.face.pain` is called again in each stage rather than once. Vanilla's static cache does the same work; the call is two multiplications and a divide.

### Surprises

- The ouch face is what the nukage shows on the tic the level begins. `st_oldhealth` is still -1 there, so vanilla's backwards subtraction reads a rise of 96 and puts the ouch face up at a blow that took five health. Every later blow finds the priority its own 35-tic count still holds, so the face only changes again when it runs out.
- Once the nukage has taken enough health, the face never glances again: the pain face's count is 35 tics and a blow lands every 32, so each blow resets it before it can time out.
- The chainsaw's grin shows in the render test without a case of its own. `P_TouchSpecialThing` sets the pickup flash before `ST_Ticker` looks, so the frame named `chainsaw after` draws `STFEVL0`, which the sampled pixel reads as 79.

### After the merge

`milestone-6-7` at 5feab80, the sight ticket and the width refactor, merged in. Five conflicts, all resolved by reading both sides: the oracle's and the two tests' headers, which gained a paragraph from each side; `tests/game.bend`'s and both tests' expected blocks, regenerated; and `Sim.tic.live`, where the refactor's `+x` and `+y` lets now sit above `Sim.st.ticker`'s call with `+attack` beside them, which is the rule that keeps the native headroom. `Sim.face.hit.at` gained the thing record's new `lastlook` field.

The merge moved every face that a monster's sight sound draws before: the nukage's two glances swapped and the render frames' faces changed. That is why each face line now prints the M_Random index its draw left, which is what makes the glance a computed value rather than a pin.

The whole of the evidence above was rerun on the merged tree: the proof, every test on both lanes, the three oracle cases, and the two comparisons against the WAD's patches.

### Checks

`bend PROOF.bend` prints "All terms check."; every test in `tests/` passes native and on bun; `doom.bend`, `tests/sim.bend`, `tests/render.bend` and `tools/frame.bend` all build natively; the three oracle cases above; `git diff --check`. The flake check is the orchestrator's.

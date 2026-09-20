# 01: The sim reports its sounds

**What to build:** The replay answers which sounds each tic started and stopped. Everything that already moves in E1M1 reports its sound where vanilla calls `S_StartSound`: doors, the lift, lowering floors, switches and their pop-back, the exit switch, the grunt of a use on a bare wall, the locked door, each pickup family, and the player's landing. The sim also carries vanilla's second random index, which `S_StartSound` advances for every audible start. This is the shared root of milestones 6 and 7: milestone 6's action tickets start their sounds through what this ticket builds.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The state holds the tic's sound starts and stops, cleared at each tic's start; a start names the sound and its source (a thing by identity, a sector, or nobody), a stop names a source
- [x] A sector's sound origin is the centre of its bounding box, computed at load, as vanilla's `soundorg`
- [x] `S_AdjustSoundParams` runs in the sim against the player for every start with a source: a start beyond the clipping distance is dropped, and an audible one carries vanilla's volume and separation
- [x] The second random index advances once for each audible start except the item pickup sound, as `S_StartSound` draws for a pitch it never uses, and begins where vanilla's stands after the level's wipe; the ticket records how that start value was derived from Chocolate Doom's source
- [x] The sound table holds the lump name and priority of each sound reported here, and nothing else
- [x] Removing a thing stops its sound, as `P_RemoveMobj` does
- [x] The sim test's existing door, lift, switch, exit, locked door, pickup and fall cases print their sounds, with expected sounds and tics read from linuxdoom-1.10's source, and the second random index at each case's end
- [x] New cases place a sounding door hard left, hard right, behind, at the close distance, and just inside and outside the clipping distance; volumes and separations are worked by hand from the source
- [x] Closed laws pin volume and separation at those places; replay composition still holds
- [x] Existing outputs change only by the added sound lines

## Comments

### What was built

- `src/sound.bend`: the sound table (13 rows: number, lump, priority), the source of a sound (`Thing{id}`, `Sector{sector}`, `Spot{x, y}`, `Nobody{}`), the event a tic reports (`Start{sfx, source, vol, sep}`, `Stop{source}`), and `Sound.adjust`, vanilla's `S_AdjustSoundParams` as a function of the tables, the listener and the source's place. A sound is named by its `sfxenum_t` number, and 0 is `sfx_None`, which starts nothing.
- `State` gained two fields at its end: `sounds`, the events of the last live tic in the order vanilla makes them, and `mrnd`, `M_Random`'s index. `Sim.tic` starts each live tic with no sounds. An ended level's tic is still the identity (laws `tic_counts` and `exit_ends` stand as written), so its sounds stay the last live tic's; whoever gathers sounds tic by tic skips a state that had ended, as `tests/sim.bend`'s `play` does.
- `Sim.sound(sfx, source, s)` is `S_StartSound`: it finds the source's place (a thing's x and y, a sector's `Level.soundorg`, a spot; the player and nobody have none), runs `Sound.adjust` against the state's player, drops a start of volume 0 or of sound 0, and otherwise appends the start and steps `mrnd` unless the sound is `sfx_itemup`.
- `H.Things.removed(things, id)` is `P_RemoveMobj`: the thing leaves the population and `Stop{Thing{id}}` is queued. The population carries a queue, `heard`, because a position check has no state in hand: pickups and the landing write there (`H.Things.sounded`), and `State.told` moves the queue into the state's sounds. `Sim.sound` calls `State.told` first and `Sim.tic` calls it last, so the queue is always empty between tics and events stay in order.
- `Level.soundorg` halves the sector's box, which `Level.grouped` already computes at load as `P_GroupLines` does. The box is the part computed at load; the two halvings happen per sound. A new `Geo` field for the centre would have changed some 45 destructuring lines for no saved work worth naming.
- The movers carry their sounds as data: `Sim.Noise{start, wake, up, down, crush, grind}`, with the rows `Sim.noise.door`, `.blazing`, `.lift`, `.floor`. `Sim.mover.begin` replaces `Sim.mover.new` and sounds the start; the wait's end sounds `wake`; a travel's last step sounds `up` or `down`, whether or not everything fit, as `T_MovePlane` answers `pastdest` there; a step undone sounds `crush`; and `grind` sounds when `leveltime & 7` is 0. The tagged movers' makers now take and return the state.
- Use, the locked door, switches, the button's pop-back, pickups and the landing call `Sim.sound` or queue their event where vanilla calls `S_StartSound`.
- `Sim.tic` now runs the use before the player's mobj moves, which is vanilla's order (`P_PlayerThink`, then `P_RunThinkers`) and puts a use's sound before a pickup's in the same tic. The move is still checked against the level the tic began with, so `tic_keeps_free` needed only its terms updated. `Sim.use` lost its player parameter, since the state now holds that player.
- `tools/sound.nu`: `S_AdjustSoundParams`, `R_PointToAngle2`, `SlopeDiv` and `P_GroupLines`' `soundorg` replayed in nushell over a `tables.c` and the WAD.

### Where each expected value came from

- Sound numbers: counted from `sfx_None` in `src/doom/sounds.h`. Lumps and priorities: `S_sfx` in `sounds.c` (the lump is `DS` and the name). `sfx_swtchx` is not in the table, see Surprises.
- `snd_SfxVolume`: `d_main.c` calls `S_Init(sfxVolume * 8, musicVolume * 8)` and `m_menu.c` calls `S_SetSfxVolume(sfxVolume * 8)`, so the menu's 8 is 64 on the 0 to 127 scale.
- The start of `mrnd`, 64: `G_InitNew` calls `M_ClearRandom`, which zeroes `rndindex`. `D_Display` sees `gamestate != wipegamestate` on the level's first frame and starts the melt; `wipe_initMelt` calls `M_Random` once for column 0 and once for each of the other `width - 1` columns, and `D_RunFrame` passes `SCREENWIDTH`, 320. 320 mod 256 is 64. Under `-playdemo`, as `tools/oracle.nu` runs it, `G_DoPlayDemo` reaches `G_InitNew` inside the first `G_Ticker`, so one or two tics run before the melt's draws. The index is a count modulo 256, so the order does not change it. It will matter to milestone 6's face ticket: `ST_Ticker`'s draw in those first tics reads the table near index 1, not 65.
- Which sound on which tic, in `tests/sim.bend`: read from `p_doors.c`, `p_plats.c`, `p_floor.c`, `p_map.c`, `p_inter.c` and `p_mobj.c` against the heights and tics milestone 4's tickets worked by hand. The landing's tic, 61, is worked in the test's header from `P_ZMovement`'s gravity. Pickup tics are the contact tics, which were regression pins already.
- Volume and separation of sector sounds: `tools/sound.nu`'s `heard` with the listener's printed place and `soundorg` of the sector from the WAD. It gave the door (832, 528) 64 and 129 from the pit; door 71 (832, 1488) 64 and 129 on tic 31 and 64 and 123 on tic 97; the three floors (2352, -16), (2352, -16), (1680, -840) 51 and 204, 51 and 204, 26 and 77; the crossed door 145 (2464, -580) 45 and 156; the lift (128, 256) 64 and 129 in the lift cases. Each matched the Bend output before the expected block was written. The sounds inside the two key-driven walks (tics 41, 75, 180, 215 and 39, 73) fall where the player's place is not printed, so their volume and separation are regression pins.
- The eight placements: worked by hand. The listener stands d units due south of (832, 528), so `R_PointToAngle2` answers `ANG90 - 1 - tantoangle[0]`, 0x3fffffff. Facing east that angle is past the facing and stays; shifted by 19 it is fine index 2047, `finesine` 65535, `FixedMul(96 << 16, 65535)` is 6291360, 95 after the shift, separation 33. Facing west it is not past, so vanilla adds `0xffffffff - facing`: index 6143, sine -65535, floor of -95.99 is -96, separation 224. Facing south: index 4095, sine 25, product 2400, 0 after the shift, 128. Facing north: index 8191, sine -25, -2400 floors to -1, 129. Volumes are `64 * (1200 - d) / 1000` in integers: 51 at 400, 64 at 200, 63 at 201, 1 at 1184, 0 at 1185 (not heard, and no draw), and past 1200 the sound is clipped. The `finesine` entries were read from `tables.c` in nushell. `tools/sound.nu` gives the same eight answers.
- `tests/game.bend`'s click: written from `P_ChangeSwitchTexture` before the run (sound 23 from nobody, index 64 + the route's door + the click = 66).
- Laws `door_sounds` and `switch_sounds`: the literal level's boxes come from its two lines, so its sectors sound from (64, 64), (72, 64) and (80, 64), dead ahead of the player at (32, 64): 64 and 129. The pop-back from (0, 0) is 80 away (32 + 64 - 16) at `ANG270 - 1 - tantoangle[1024]` (316933408), fine index 5539, sine -58617, -85.86 floors to -86: 214. My first hand value for the door was wrong because I took the literal level's boxes for empty; the checker's answer sent me back to `Level.grouped`.

### Laws added

`sound_places` (the eight placements through `Sound.adjust`), `door_sounds` (the manual door's two sounds, the silent tics between, and `mrnd` 2 after them) and `switch_sounds` (the lift switch's five events on the use tic, and the pop-back on tic 35). All three are closed and filled by computation. `use_fires_once` gained the two new fields as quantified variables. `replay_append` and the wall laws check unchanged in statement.

### Trade-offs

- The pending queue lives in `H.Things`, not in the inventory or in `Sim.Try`. It costs one field there and keeps `Sim.touch`'s shape, which milestone 6's position check ticket is rewriting.
- A switch's click comes from the first running button's sector, or nobody. Vanilla reads slot 0 of `buttonlist`, which can be free while a later slot runs; the two agree while at most one button runs. Neither E1M1 can run a button at all (see Surprises), so slots were not modelled.
- The pop-back sounds from `Spot{0, 0}`. Chocolate Doom on 64 bits reads x from the next slot's timer, a raw fixed value of at most 35, less than a thousandth of a unit.
- Lines crossed are still fired after the whole move, so a line crossed in the first half of a split move (momentum over 15 units a tic) sounds with the listener where the whole move ended, up to half a step from vanilla's. Volume can differ by one and separation by a few units when the source is near. Fixing it means firing crossings inside `Sim.try_move`, which belongs with the position check ticket.
- `Sim.approx` moved to `F.Fixed.approx` so that `Sound.adjust` can share it. A branch that still calls `Sim.approx` needs that one name changed after merging.
- The button is a thinker here, so its pop-back sounds in thinker order and not after all thinkers, as `P_UpdateSpecials` would.

### Surprises

- Vanilla never plays `sfx_swtchx`. `P_ChangeSwitchTexture` clears a once-only line's special before it compares it with 11, so the exit switch clicks with `sfx_swtchn`. The spec's user story 5 asks for the exit's own sound; vanilla's source says otherwise, and the table leaves the sound out.
- Neither E1M1 has a switch that pops back. The shareware map has no repeatable switch, and Freedoom's four special 62 lines show `PLAT1`, which is no switch texture, so `P_ChangeSwitchTexture` changes nothing, starts no button and makes no sound there. The pop-back is covered by `switch_sounds` on the literal level alone.
- `tests/sim.bend` loads the map without graphics, so no texture has a partner and no switch clicked in it. The switch and exit cases now run on the map with the two switches' middle textures numbered as a switch pair (`switched`), the way the literal level of the laws does it. Both clicks were predicted before the run: `sfx_swtchn` from nobody on tics 31 and 21, one draw each. `tests/game.bend`, which loads the graphics, pins the exit's click as well.
- The last 15 units inside the clipping distance are silent: `S_AdjustSoundParams` returns `vol > 0`, and the integer volume is 0 from 1185 on.
- A source dead ahead sits at 129, not 128, because vanilla subtracts one more from an angle that is not past the facing.

### For later tickets

- Start a sound: `Sim.sound(sfx, source, s)`, which returns the state. From a thing: `Sn.Thing{id}` (the player is `Sn.Thing{H.Thing.you()}` and is heard centred at full volume). From a sector: `Sn.Sector{sector}`. From nobody: `Sn.Nobody{}`. A table-driven caller may pass 0 for a row with no sound.
- Stop a thing's sound: remove it with `H.Things.removed(things, id)`. `S_StopSound` has no other caller in the play code. Code with no state in hand can also queue a start with `H.Things.sounded(things, Sn.Sound.plain(sfx, source))`, which is full volume and centred; a placed start needs `Sim.sound`.
- A new sound adds its number and its row to `src/sound.bend`.
- `State.sounds` is one tic's. `src/game.bend` still replays a frame's tics in one call, so ticket 07 has to gather them tic by tic and skip ended states.

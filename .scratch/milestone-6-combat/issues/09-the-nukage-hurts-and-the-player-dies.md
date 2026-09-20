# 09: The nukage hurts and the player dies

**What to build:** The player can be hurt and can die. Standing in a special 7 sector takes 5 health every 32 tics. Damage passes through armour, a third absorbed by green and a half by blue. At zero health the view sinks to the floor and turns to the killer, and a press of Space loads the level again with a fresh inventory.

**Blocked by:** milestone 7's 01 (The sim reports its sounds)

**Status:** resolved

- [x] `P_DamageMobj`'s player branch: armour absorption, the damage count, the attacker, thrust when there is an inflictor, and health as a signed quantity
- [x] `P_PlayerInSpecialSector` for special 7, only while the player stands on the floor
- [x] `P_DeathThink`: the view falls to 6 units, turns to the attacker, the weapon lowers if one shows, and use restarts through the same path as the restart after the exit
- [x] Pickups refuse a dead toucher
- [x] The pain and death sounds start where vanilla's do
- [x] Sim cases: nukage tics, green and blue armour absorbing, death in the nukage and the restart, with values worked from the source
- [x] Closed laws pin absorption at both armour types; replay composition still holds
- [x] A render case shows the dead view at zero differing pixels

## Comments

**Where the expected values came from.** Every one was written down before the Bend code answered.

- The nukage is p_spec.c by hand: `P_PlayerInSpecialSector` is called from `P_PlayerThink` after `P_CalcHeight`, returns at once unless `player->mo->z` equals the sector's floor height, and special 7 calls `P_DamageMobj (mo, NULL, NULL, 5)` when `leveltime & 0x1f` is zero. `leveltime` is the clock the tic began with, since `P_Ticker` counts it up after the thinkers, so the first blow lands on the tic the level begins and every 32nd after it: health 95 after tic 1, 90 after tic 33, and no health after the twentieth, on the tic the clock reads 608.
- The armour is p_inter.c by hand. `saved` is `damage/3` for type 1 and `damage/2` for type 2, both C's truncating division, and armour with `armorpoints <= saved` gives what it has and clears its type. A blow of 5 costs 1 point of green armour and 4 health, or 2 of blue and 3; green armour of a single point gives it, loses its type and leaves 4. The closed law `armour_absorbs` states the same at a blow of 20 (6 and 14, 10 and 10), with armour of 5 points and of none.
- The pain and the death are info.c by hand. The player's `painchance` is 255, so `P_Random () < painchance` fails on a draw of 255 alone. `S_PLAY_PAIN` lasts 4 tics with no action and leads to `S_PLAY_PAIN2`, whose `A_Pain` starts `sfx_plpain`; `P_SetMobjState` sets the tics and `P_MobjThinker` takes one off on the same tic, so the sound comes three tics after the blow. `S_PLAY_DIE1` lasts 10 tics less `P_Random () & 3` and leads to `S_PLAY_DIE2`, whose `A_PlayerScream` starts `sfx_pldeth`; the death ends in `S_PLAY_DIE7`, which is the row a dead marine record already spawns in. `sfx_pdiehi` is commercial only and has no code.
- `P_DeathThink` is p_user.c by hand: the view height falls a unit a tic from 41 to 6, `deltaviewheight` is cleared, and `P_CalcHeight` skips its ramp for a dead player but still adds the bob, so a corpse that slides still bobs. The turn is `ANG90/18`, 59652323, with the damage count fading only on the tic the view is within that of the attacker.
- `P_DropWeapon` and `A_Lower` are p_pspr.c by hand. `P_SetPsprite` runs `A_Lower` as it enters `S_PISTOLDOWN`, and `P_MovePsprites` runs it again on the same tic, since that state lasts one tic and leads to itself: the pistol is at 44 on the tic of the death and 6 lower a tic until `WEAPONBOTTOM`, 128, fourteen tics later.
- The thrust is p_inter.c by hand over Chocolate Doom's tables.c: `damage*(FRACUNIT>>3)*100/mass` with the player's mass of 100 is `damage * 8192`, along `R_PointToAngle2` from the inflictor to the player. For a thing due south that angle is `ANG90 - 1`, fine index 2047, sine 65535 and cosine 25, so a blow of 20 gives momentum 2.499954 north and 0.000946 east. The fall-forwards branch needs `damage < 40`, `damage > target->health`, an inflictor more than 64 units below, and an odd `P_Random ()`, drawn only where the first three pass; it turns the angle by `ANG180` and quadruples the thrust, which at fine index 6143 is 9.999847 south and 0.003814 west.
- The draws are m_random.c's table read in nushell. The room's blows start the index at 0 and 1: the pain roll draws 8 at index 1, the fall-forwards roll 109 at index 2, which is odd, and `P_KillMobj` 220 at index 3, whose low two bits are 0, so the death state keeps its 10 tics.
- Regression pin: the death state's tics in the nukage case (8 after the tic that kills). The level's random blinks draw between the blows, so the index at the twentieth is the whole tic stream's, not a hand count. Everything else in the sim test's new lines is from the sources above; the corpse's slide distance is the existing friction, itself pinned in milestone 2.

**The oracle.** `nix develop -c nu tools/oracle.nu 1600 1000 90 <script> --frame <dump>`, frame dump built from this tree, Freedoom, `masked` 665 in every report, which is the pause graphic alone. The place is the middle of sector 173, one of Freedoom's three special 7 sectors (23, 38 and 173, all read from the WAD in nushell).

| case | script | rows | differing |
| --- | --- | --- | --- |
| the pistol still sinking, view 35 | `615,0,0,0,0` | 168 | 0 |
| the view still falling, 20 | `630,0,0,0,0` | 168 | 0 |
| the dead view at rest, 6 | `650,0,0,0,0` | 168 | 0 |
| the dead view with the bar | `650,0,0,0,0` | 200 | 0 |

The render test's new case is the last of these. It was run again, with the frame dump built again, after each merge of the integration branch: the buttons byte, the one traversal, and then the one position check with the status bar, where it is 0 over all 200 rows, the bar showing no health, with the pause graphic and the face box masked.

Ticket 08 then turned the oracle's monsters on, and that place cannot be compared any more: vanilla's imps in the yard see a player who stands 650 tics there and wake, and Bendoom's cannot move yet, so the frames part company from about the twentieth tic (117 and 329 differing pixels at two places at 20 tics, 48988 at 650). The case stays as a regression pin, beside the ones ticket 08 pinned for the same reason, until the monsters think. Every other render case is unchanged.

**What was built.**

- `src/sim.bend`: a damage section and a dying section. `Sim.damage` is `P_DamageMobj`'s player branch and the one function everything that hurts the player calls: the damage, an inflictor and a source, both `Maybe` of a thing's name. `Sim.blow` is the thrust with its draw; `I.Inventory.hurt` is the armour and the health; `Player.took` keeps the attacker and raises the damage count to at most 100; `Sim.kill` is `P_KillMobj` for the player, with `Sim.drop` for `P_DropWeapon`. `Sim.sector` is `P_PlayerInSpecialSector`, whose switch is one test, since special 7 is the only special either map carries that hurts: the sector's special, the clock's low five bits and the player's feet on the floor decide the blow together. `Sim.death` is `P_DeathThink`. `Sim.mobj.enter` is `P_SetMobjState` for the player's mobj and `Sim.mobj.tics` its state cycle, which runs where `P_MobjThinker` runs it, after the lines the move crossed have fired. `P_PlayerThink` splits in two: `Sim.player` is the half that writes the state, the sector's special for a living player and the reborn for a dying one, and `Sim.thought` the half that is the player's alone, the sprites and the counters or the dying view. The sector's special runs where vanilla runs it, right after the eye; the use stays after the counters, where this sim already had it, since a dead player makes no press and nothing the sprites do is heard yet.
- The player carries the wound in one field, a vector of four counts as the powers are: the mobj state row that times the pain and death sounds, the tics left in it, the damage count that milestone 6's palette and face read, and who hit last, the player's own name for nobody. A record there would have been a sixteenth field the merged sim cannot afford: the native build fails with "an arity over 255" at a seventeenth, and a record field costs its width. The state carries `reborn`, vanilla's `PST_REBORN`, which the game loop answers.
- `src/things.bend`: `Thing.Action` gains `Lower`, `Pain` and `Scream`; row 61 is `S_PISTOLDOWN` and rows 62 to 70 the player mobj's standing, pain and death states, which end in row 0, `S_PLAY_DIE7`. `Thing.Weapon` gains `down`, so `Gfx.sprite.weapon` loads the down state's sprite.
- `src/inventory.bend`: `Inventory.dead`, the `PST_DEAD` test, which `P_TouchSpecialThing` and `P_PlayerThink` both ask; `Inventory.hurt` and `Inventory.saved`, `P_DamageMobj`'s armour and health; `Inventory.armour` and `Inventory.armourtype`.
- `src/game.bend`: `Game.from` is still the one path to a fresh level; its caller now asks for it on the press after the exit or on the sim's own reborn.
- `src/sound.bend`: `sfx_plpain` (25) and `sfx_pldeth` (57) with their lumps and priorities.
- `LAWS.bend`, `PROOF.bend`: `armour_absorbs` and `damage_count`. Every literal player gained `Sim.Hurt.start()` and every literal state `False{}`; the replay, freedom and mover laws hold unchanged.
- Tests: the sim test's nukage, armour, death, blow and corpse cases; the game test's death restart; the render test's dead view.

**What was deleted.** Nothing was replaced, so nothing was removed outright. The comments that were made false were rewritten: the sim's header, `Player.stood`'s, `Sim.tic`'s, the pickup reach's, and the three test headers.

**Pulled forward.** The player mobj's state rows and their two actions, which the monsters' tickets need for their own states; `Thing.Weapon.down` and `A_Lower`, which ticket 12 needs for switching.

**Left for later tickets, by design.**

- `mo->health` below zero. Vanilla keeps both it and `player->health`, which clamps at 0; the only place they differ is `P_KillMobj`'s gib test against the spawn health, and nothing here can deal 200 points. One clamped health is the whole of this ticket, and ticket 13 adds the signed mobj health when a barrel can overkill.
- The flags `P_KillMobj` clears and the quartered height. A dead player takes no more damage, since `P_DamageMobj` asks its health; no mover in either map crushes; and the player's own sprite is never drawn. Ticket 13's blast and any crusher would need them.
- The chainsaw's exemption from the thrust, which needs a ready weapon to read (ticket 12).
- `P_DamageMobj`'s monster half: pain chance per type, reaction time, threshold and the switch of target (tickets 12 to 18 call the same `Sim.damage` shape for things once things can be hurt).

**How the later tickets use this.**

- The damage count is `Sim.Hurt.damage(Player.hurt(p))`, or the whole record through `Player.hurt`. Ticket 10 reads it for `ST_doPaletteStuff`'s red, ticket 23 for the face's pain and, with `Sim.Hurt.attacker`, for the side it winces to. It is already capped at 100 and fades a tic, in the counters while alive and in `Sim.death` once dead.
- The damage function is `Sim.damage(damage, inflictor, source, s) -> State`, where the inflictor and the source are `Maybe<&2, U32>` thing names, `None{}` for nobody. Tickets 13, 17 and 18 call it with `Some{id}`: a barrel's blast passes the barrel as the inflictor and whoever shot it as the source, a monster's bullet passes no inflictor and the monster as the source (as `P_LineAttack` does), and a fireball passes itself and its shooter. The thrust and the attacker's turn already work from a source, which the sim test's literal-state blows show.

**Trade-offs.**

- One field on the player, a record, not four. Every `Player{..}` pattern in the sim, the laws and the tests gained one name; four would have been four.
- The damage count lives with the mobj state, not beside `bonuscount` in the inventory. It is `player_t`'s and `G_PlayerReborn` clears it, which argues for the inventory; but the inventory prints in sixty expected test lines, and the count is read with the attacker and the mobj state by the same two later tickets. The fade reuses `Inventory.on`.
- The reborn is a flag on the state, read by whoever runs the tics, which is where vanilla reads `PST_REBORN`: `G_Ticker` answers it outside `P_Ticker`. The game loop reads it once a frame, so a reborn asked in the middle of a batch of tics is answered at the next frame, up to eight tics late. At 35 frames a second there is one tic a frame.
- The press after the exit stays in the loop and the reborn comes from the sim, both reaching the one `Game.from`. Folding the exit's press into the sim would make the ended state watch the use button, which would cost the law that an ended tic changes nothing, and would drop Enter, which the game test pins. The intermission ticket owns that path and will delete the exit's branch.
- The player's mobj state rows are appended, 62 to 70, and are marked in no sprite load, since the view never shows the player's own sprite. That keeps PLAY frames G to M out of the graphics.

**What the proof cost.** Three runs found three things, each a shape this codebase's guide now carries. The `State` and `Player` patterns of every lemma above the tic had to grow their new fields. The freedom law then had to walk the blow: a lemma a function from the sector's special down, which is why `P_PlayerThink` is split in two, so the player the move is handed is a term the checker can follow rather than one buried inside `Sim.use`. And `tic_rest`, which quantifies over any level, leaves the nukage's flag stuck, so its filler splits on that flag and both sides compute; the blow it may deal writes the health, the wound and the momentum, never the place.

**Surprises.**

- The pain sound is not on the tic of the blow. `S_PLAY_PAIN` has no action; `A_Pain` is on the state after it, so vanilla screams three tics late, which the oracle's frames cannot see but the sim test prints.
- `P_CalcHeight` still bobs a dead player. Only the view height's ramp is skipped, so a corpse sliding on its momentum bobs as it goes; the corpse slide case shows it.
- A blow's thrust moved the corpse past its own attacker in the first draft of the literal-state case, which turned the view the other way round. The barrel was moved to 512 units away so the turn runs one way.
- A big `+` let bound in the game test's `play` and handed to a frame failed the native build with "an arity over 255" and no location; the same expression as a def of its own passes. It is in `docs/bend.md`.
- The same error, with no location again, is what a sixteenth field on the player costs once the merged sim is this wide: a U32 passes, a record or three more do not. The wound went into a vector, and the budget is in `docs/bend.md` too.
- The hold ticket 03 built is what carries the freedom law over the blow. Nothing in the think moves the player, so putting the whole of `P_PlayerThink` inside `State.held` costs the proof no lemma at all, where threading the blow through it would have cost one a function.

Checks, after the last merge (milestone 6's tickets 02, 03, 04 and 08 and the buttons byte): `bend PROOF.bend` prints "All terms check."; every test in `tests/` passes native and on bun; the oracle cases above; `git diff --check`. The flake check is the integration branch's.

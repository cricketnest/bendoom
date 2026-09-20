# 05: Pickups and the locked door leave a message

**What to build:** Vanilla's heads-up message line. A pickup or a locked door's refusal sets one message, drawn in the WAD's font at the top of the view and held for 4 seconds. The strings are vanilla's English ones.

**Blocked by:** None (can start immediately)

**Status:** ready-for-human

- [x] Each pickup type the two E1M1s hold sets its vanilla string, and the blue door's refusal sets its own
- [x] A new message replaces the old; the line clears after `HU_MSGTIMEOUT`
- [x] Glyphs come from the WAD's font lumps, spaced as `HUlib_drawTextLine` spaces them
- [x] The sim test prints the message and its tics left on pickup cases
- [x] Render cases compare message pixels with the font's patches read from the WAD in nushell, since Chocolate Doom's message ticker runs on under the oracle's pause; the oracle keeps messages off

## Comments

### What was built

- `src/message.bend`: the seventeen strings d_englsh.h gives the pickup types the two E1M1s hold and the blue locked door, numbered 1 to 17; `Message.text` turns a number into its string; `HU_MSGTIMEOUT`, `HU_MSGX`, `HU_MSGY`, and `HUlib_drawTextLine`'s glyph rule (upper-case, `'!'` to `'_'`, anything else none). A message is carried as its number, not its text: the state is what the laws quantify over and the tests print, and a `String` there would have made both awkward.
- The line lives in the `Inventory`, two U32 fields: the message it shows and the tics it has left there. That is where vanilla's own `player->message` is, and the state had no room (see Surprises). `Inventory.saying` is p_inter.c's write with HU_Ticker's own work folded in: the message takes the line at once and for a tic more than `HU_MSGTIMEOUT`, since the tic that gives it counts it down before it is ever drawn. So a message shows for vanilla's four seconds, a newer message replaces an older as vanilla's later write does, and no message leaves the line as it was, since each of vanilla's cases sets one or returns. `Inventory.hud` is HU_Ticker's counter.
- `Inventory.taken` says the message of the grant that took, so `Inventory.grant` names one in each case it already branches on and no second switch on the type exists. `P_GiveCard` says its own on the same test that sets the flash. The types neither map places keep their grant and say nothing.
- `Sim.door.locked` says `PD_BLUEK` with its grunt, where EV_VerticalDoor sets it. `Sim.tic.done` runs `State.hud` after the thinkers, as `G_Ticker` runs `HU_Ticker` after `P_Ticker`.
- `src/draw.bend`: `Draw.patch` is `V_DrawPatch`, a patch's columns from x, y with its offsets taken off, post by post, straight into the frame with no colormap. `src/render.bend`: `Render.line` is `HUlib_drawTextLine` and `Render.hud` is `HU_Drawer`, drawn last of all, as `D_Display` draws it over the view and the bar. `src/gfx.bend` loads STCFN033 to STCFN095 as `HU_Init` does and keeps each patch's index.
- `Render.frame` takes whether messages show. `tools/frame.bend`, which the oracle diffs, passes `False`, as the Chocolate Doom it is compared with runs with `show_messages 0`; the game, the film and the bench pass `True`.
- `tools/wad.nu` gained the oracle's `posts` and `patch-pixels`, which `tools/oracle.nu` now sources from there through `demo.nu`, and `hu-line`, `HUlib_drawTextLine` replayed over the WAD's font.

### Where each expected value came from

- The strings: d_englsh.h, and which one each pickup sets: p_inter.c's `P_TouchSpecialThing`. The locked door's: p_doors.c's `EV_VerticalDoor`, case 26.
- Which strings to carry: a nushell census of both E1M1s' THINGS on Hurt Me Plenty (skill bit 2 set, MTF_NOTSINGLE clear). Freedoom places types 5, 2005, 2007, 2008, 2010, 2011, 2012, 2014, 2015, 2018, 2023, 2047, 2048 and 2049; the shareware map 2001, 2007, 2008, 2011, 2012, 2014, 2015, 2018, 2019, 2048 and 2049. Sixteen pickup strings and PD_BLUEK.
- The four seconds: `HU_MSGTIMEOUT` is `4*TICRATE` in hu_stuff.h, and `HU_Ticker` counts it down once a tic after `P_Ticker`.
- The glyph rule and the advance: hu_lib.c's `HUlib_drawTextLine`, the font lumps and `HU_FONTSTART` from hu_stuff.c's `HU_Init`, `HU_MSGX` and `HU_MSGY` from hu_stuff.h, and the order the line is drawn in from d_main.c's `D_Display`.
- The render test's message pixels: `tools/wad.nu`'s `hu-line` over Freedoom's font. It answers 730 pixels for "Picked up the armor.", 901 for "Picked up a blue keycard." and 1030 for "A chainsaw!  Find some meat!", and the frame's own colours at the first four indices each case prints: `0,47 1,45 2,45 3,45`, `0,47 1,45 2,45 3,45` and `3,47 4,45 5,189 16,47`. Every one matches the test's output, and the counts match exactly, which says both that every pixel the font covers differs from the frame under it and that the line changes nothing else.
- The sim test's tics: the card is taken on tic 56 and its message is gone on tic 196, 140 tics later, with 1 left on tic 195.

### Laws added

`pickup_messages`: the message each of eight pickup types leaves with `HU_MSGTIMEOUT` tics, a pickup the grant refuses saying nothing and leaving the line as it was, the counter's fall to zero, and the blue locked door's `PD_BLUEK` beside the same door opening silently with the card. `Closed.kept` takes the line off the inventory it compares, since the pickup laws are about the grants; `Closed.Edit` gained `Said` so a literal inventory can carry a line. `hud_free` carries the freedom law through HU_Ticker, which writes the inventory and leaves the place.

### Trade-offs

- The line is in the `Inventory`, not in `State`, and its two numbers are one word. `State` is where it belongs by kind, and it was there until the native lane refused it (see Surprises). The `Inventory` is the player's own record, it already carries `bonus`, which is as much a heads-up counter as a possession, and it is what the position check has in hand where a pickup writes.
- HU_Ticker is split where it costs nothing: its install rides on the write, so a message takes the line at once for `HU_MSGTIMEOUT` tics, and its counter rides on `P_PlayerThink`'s counters, which have already run when a pickup or a use happens. The schedule is vanilla's tic for tic, and neither the tic nor the state grew a step.
- The oracle's `patch-pixels` moved to `tools/wad.nu` rather than being copied, as the ticket asks.

### Surprises

- Vanilla never shows `GOTMEDINEED`. `P_GiveBody` heals before p_inter.c tests `player->health < 25`, and the health after a medikit is never under 26, so the "really needed" branch is dead. The string is not carried.
- The native lane refuses an arity over 255 while the JS lane takes the same program, so a tree can pass `bend f.bend` and fail `bend f.bend -o f`. Two more fields on `State`, or one record-typed field on `Inventory`, each broke it, where two more U32 fields on `Inventory` did not. That is what moved the line out of the state, and it is now in `docs/bend.md`.
- Freedoom has 68 STCFN lumps and the shareware WAD 64; both hold the 63 vanilla asks for, STCFN033 to STCFN095.

### Deferred to the later pass

- **This branch does not build on the native lane and must not be merged as it stands.** `bend PROOF.bend` checks, every test passes on the interpreter and on bun, and the game runs there; but `bend doom.bend -o doom`, `bend tests/sim.bend -o sim` and `bend tools/frame.bend -o frame` all end in `an arity over 255`, so `nix flake check` would fail. The integration branch at c98ff58 builds all three, and one more U32 field in `Inventory` is the whole difference: the monsters and the damage work have taken the last of the native lane's room. The line is already packed into a single word for this reason. What would close it: room made elsewhere, after which nothing in this ticket need change; or the line moved into a `V.Vec` slot beside counts already there, which `docs/bend.md` names as what to do with a count that will not fit and which costs no field at all.
- The oracle was not run on this tree; the frame dump does not build here, so it could not be. What stands in for it: every hash in `tests/render.bend` is the integration branch's, regenerated there after its own zero, and they all still hold with the message line built, which is what it means for a frame drawn with messages off to be untouched.

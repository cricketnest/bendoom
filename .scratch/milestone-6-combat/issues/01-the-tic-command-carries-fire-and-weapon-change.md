# 01: The tic command carries fire and weapon change

**What to build:** Ctrl and the keys 1 to 3 reach the tic command as vanilla's attack bit and weapon-change bits, laid out as the demo's buttons byte. The demo recorder writes the byte, the demo reader returns it, and the oracle's script format carries it, so one script drives Bendoom and Chocolate Doom alike. Nothing fires yet.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] The command holds attack and the weapon change as `G_BuildTiccmd` builds them from held keys, including its order of preference among held number keys
- [x] A recorded demo carries the bits, and Chocolate Doom plays it: the ticket records a demo of held Ctrl and a press of 1 replayed there, with the pistol seen firing and lowering
- [x] The oracle's and the frame dump's script runs gain the buttons, and every existing script still parses
- [x] The demo test covers the new bits on both lanes, with bytes worked by hand from `G_WriteDemoTiccmd`
- [x] The use bit's handling is folded into the buttons, not kept as a parallel field

## Comments

### What was built

- `K.Cmd` holds one `buttons` word where it held a `use: Bool`. It is the demo's byte: `BT_ATTACK` 1, `BT_USE` 2, `BT_CHANGE` 4 with the weapon's number at `BT_WEAPONSHIFT`, 3. `K.Cmd.use` reads bit 1 and stays the one reader of the byte; nothing else opens it yet.
- `K.Keys` gained `fire`, `one`, `two` and `three` at its end. `Keys.press` maps Ctrl, the runtime's 65595 and 65598, to fire and the characters 49, 50 and 51 to the number keys. `Keys.cmd` sums `Keys.if(fire, 1)`, `Keys.if(use, 2)` and `Keys.change(one, two, three)`; the three parts are disjoint bits, so the sum is the or.
- `Keys.change` is `G_BuildTiccmd`'s loop over `weapon_keys`, which breaks at the first held key: 1 gives 4, 2 gives 12, 3 gives 20, and the lowest held wins over any higher one. Law `lowest_number_wins` pins that over all values of the higher two keys.
- `Demo.tic` writes the byte whole and `Demo.cmds` reads it back whole, as `G_WriteDemoTiccmd` and `G_ReadDemoTiccmd` do; the recorder no longer builds a byte out of one flag.
- The script's fifth field carries the buttons, with use kept at 1: use 1, attack 2, a change 4 and eight times the weapon's number, so the key 1 is 4, the key 2 is 12 and the key 3 is 20. That is the demo's byte with its two low bits trading places. `Script.buttons` does the swap on the Bend side and `runs` in `tools/demo.nu` on the nushell side, one parser per language as before. `tools/demo.nu` carries the statement of the format and the reason for the swap; `tools/script.bend` restates the format for a Bend reader and points there for the why; `tools/oracle.nu` and `tools/listen.nu` name the field.

### Why the script's fifth field is not the demo byte

Every script written so far says 1 for use: the tests, the tool headers and the examples in milestone 4 and 5 tickets. Laying the demo byte straight into the field would have made all of them mean attack. Adding a sixth field would have split the parser into an old shape and a new one in both languages. Swapping the two low bits costs one line per language and leaves every existing script meaning exactly what it meant; the oracle case below is the check.

### Where each expected value came from

- `BT_ATTACK` 1, `BT_USE` 2, `BT_CHANGE` 4, `BT_WEAPONMASK` 8+16+32 and `BT_WEAPONSHIFT` 3: `src/d_event.h`.
- Which key gives which weapon number: `weapon_keys` in `g_game.c` is `key_weapon1` through `key_weapon8` in order, and the loop sets `i << BT_WEAPONSHIFT` for the first held one, so the key's number less one is the weapon's. `m_controls.c` binds `key_weapon1` to '1' and `key_fire` to `KEY_RCTRL`.
- The runtime's key codes: `window_keys` in bend 2.0.5's `effs/window_frame.c` has `XK_Control_L` 65595 and `XK_Control_R` 65598; a digit has no row there and comes back as its character from `XLookupString`. Both Ctrls are read, as both Shifts already are for run.
- `tests/demo.bend`'s new bytes are worked by hand in its header from `G_BuildTiccmd` and `G_WriteDemoTiccmd`: fire alone 1, the keys 1, 2 and 3 alone 4, 12 and 20, 2 with 3 held 12, 1 with 3 held 4, fire with use 3, and fire with use and 3 together 23. No regression pins were added.

### Chocolate Doom plays the demo

Bendoom itself recorded it. `doom.bend` built to `/tmp/m6-01/doom` and run under `RECORD` on an Xvfb of its own with no music, with xdotool holding right Ctrl for a second, pressing 1, then holding 3 and 2 together and releasing 2 first. The 311-tic demo's buttons byte, tic by tic:

| tic | tics | byte | what |
| --- | --- | --- | --- |
| 0 | 75 | 0 | nothing held |
| 75 | 36 | 1 | right Ctrl, `BT_ATTACK` |
| 111 | 36 | 0 | released |
| 147 | 7 | 4 | the key 1, `BT_CHANGE` with weapon 0 |
| 154 | 71 | 0 | released |
| 225 | 8 | 12 | 3 and 2 held, the lower key wins |
| 233 | 8 | 20 | 2 released, 3 still held |
| 241 | 70 | 0 | released |

That demo, cut at a tic and paused there, replayed in Chocolate Doom against Freedoom through `tools/oracle.nu`'s `vanilla`:

- tic 83: the pistol firing, its muzzle flash lighting the room, and ammo 49 of 50, eight tics into the held Ctrl.
- tic 155: ammo 47, three shots into the 36 held tics, and the pistol most of the way off the bottom of the view; the press of 1 at tic 147 put `A_Lower` to work.
- tic 175: the ammo number gone from the bar, which vanilla leaves blank only for a ready weapon of `am_noammo`, and the fist rising. The change took, and 1 chose the fist because the chainsaw is not owned.

The bytes therefore mean in vanilla what they mean here, including the order of preference among held number keys.

### The oracle

`nix develop -c nu tools/oracle.nu x y degrees script --frame <dump>`, the frame dump built from this tree with the merge of `milestone-6-7` committed. Freedoom, `masked` 665 in both, which is the pause graphic alone.

| case | place | script | differing |
| --- | --- | --- | --- |
| rest | -416 256 0 | `20,0,0,0,0` | 0 |
| the door used, from `tools/oracle.nu`'s own header | 832 384 90 | `40,25,0,0,0 1,0,0,0,1` | 0 |

The second case is the point of the encoding: a script whose fifth field is 1, written before this ticket, still opens the door on both sides.

### The rest of the run

`bend PROOF.bend` prints "All terms check.", every `tests/*.bend` passes on both lanes, and `nix flake check` ends in "all checks passed!", all on the merged tree. The flake check runs the proof and the tests again in the sandbox from the git-added files, so it is the authoritative one.

### What was deleted

- `K.Cmd`'s `use: Bool` field, `Demo.tic`'s `Bool.pick(U32, use, 2, 0)` and `Demo.cmds`' test of bit 1, which now lives once in `K.Cmd.use`.
- `PROOF.bend`'s `press8`, replaced by `press12`.
- "where use is bit 1" from `src/demo.bend`, "the use 0 or 1" from `tools/script.bend`, and the fifth field's name in the four files that document the script format: `tools/demo.nu`, `tools/script.bend`, `tools/oracle.nu` and `tools/listen.nu`.

### What surprised me

- `use_fires_once` could no longer be proved by splitting a `Bool`: the command's fourth field is a word now, and a word is stuck in the checker. The law instead takes a hypothesis that the byte's use bit is set, and `Sim.pressed` tests `usedown` before `K.Cmd.use`, so the goal reduces to `False` from `usedown` alone once the hypothesis has been rewritten in. The same fact, one fewer case, and it holds for every buttons word with the bit set rather than for the single value `True`.
- Vanilla's command would carry `BT_CHANGE` for a press of 4 to 8, and ours carries nothing, because those keys are not read. It cannot be seen: `P_PlayerThink` drops a change to a weapon the player does not own, and E1M1 gives none of them. `Keys.change`'s comment says so, for whoever adds a weapon.

### For tickets 11 and 12

Read the byte out of the command with the masks vanilla uses on `cmd->buttons`: attack is `buttons .&. 1`, a change is `buttons .&. 4`, and the weapon it names is `(buttons .&. 56) >> 3`. Nothing reads them yet, so no reader was written for them; write the one you need beside `K.Cmd.use` in `src/keys.bend`. The `Keys` record has room for the number keys 1 to 3 only.

# 06: Eight channels by priority

**What to build:** The sound module that turns the sim's reported sounds into what the mixer plays. It allots vanilla's eight channels: a source's new sound cuts its old one, a free channel is taken, and otherwise a less important sound is evicted or the new one dropped, by `S_GetChannel`'s rule. It sets left and right volumes from volume and separation with Chocolate Doom's formula, follows moving sources once a tic as `S_UpdateSounds` does, and frees a channel when its file ends.

**Blocked by:** 01 (The sim reports its sounds), 05 (The mixer plays a sound over the song)

**Status:** ready-for-human

- [x] Channel state lives outside the sim's state, since in vanilla it follows the sound device's clock
- [ ] Starts, stops, eviction and the per-tic update follow `S_StartSound`, `S_StopSound`, `S_GetChannel` and `S_UpdateSounds`
- [x] Left and right come from Chocolate Doom's `I_SDL_UpdateSoundParams`
- [ ] Laws over all inputs: the table never holds more than eight, no two channels share a source, eviction never drops a more important sound for a less important one
- [x] A test drives the module with event lists and prints the channel table after each tic, with expected tables worked by hand from the source
- [ ] Recordings of a ninth sound evicting a channel and of a sound cut by its source's next sound compare at the target of zero

## Deferred to the later pass

- `S_UpdateSounds`, the per-tic re-panning of a moving source and the stopping of one gone out of earshot. Tonight a sound keeps the volume and separation it started with, so a monster that walks past while its sound plays does not pan. Everything else of the first unticked box is done.
- The laws over the channel table. Allotment is an `IO` action, since taking a channel opens a file and losing one closes it, and the checker cannot reach inside `IO`. Proving them means splitting the pure decision out of the action, and the decision reads priorities off a table of open files. The size law is true by construction instead: the table is a list of eight slots that `Channel.put` walks without changing its length. The other two would want closed sample laws, since a universal U32 law does not compute.
- The two recordings through `tools/listen.nu`. The scripted sequence in `tests/mixer.bend` covers the same two cases against the source instead.

## Comments

20 Sep 2026.

### What was built

- `src/channel.bend`. A `Channel` is the open file of a playing sound, the sound, the source that made it, and the left and right volumes the device was given. The table is a list of eight `Maybe<Channel>`, so a freed channel leaves a hole where it was and slot order is vanilla's.
- `Channel.hear(dir, events, chans)` takes the events of a frame's tics in order. A start is `S_StartSound`'s tail after the audibility test, which the sim already ran: `Channel.hush` for `S_StopSound`, then `Channel.slots` and `Channel.put` for `S_GetChannel`. A stop is `Channel.hush` alone.
- `Channel.slots` is `S_GetChannel`'s two searches in one walk of the table: the number of the first free channel and the number of the first whose sound's priority is greater than or equal to the new one's, each eight for none. A free channel wins if there is one, which is vanilla's order: it scans the whole table for a hole before it looks for a victim. Eight means nowhere, and `Channel.put` walking off the end of the table is the sound dropped, closing the file it opened.
- `Channel.left` and `Channel.right` are `I_SDL_UpdateSoundParams`: `((254 - sep) * vol) / 127` and `(sep * vol) / 127`, each clamped to a byte. A separation of 255 would make the left share -1 in C, which divides toward zero and clamps to 0; the share stops at 0 here and gives the same answer. The sim never sends more than 224.
- `Sound.priority` and `Sound.Source.same` are new in `src/sound.bend`, at its end, so a sibling adding a row to the table does not meet them.

### Where each expected value came from

`tests/mixer.bend`'s sixteen tables are worked by hand from `S_GetChannel` and `S_StopSound` in `s_sound.c` with the priorities of `S_sfx`, and are written out in the test's header. All sixteen matched on the first run. The cases are: eight sounds filling the table in order; a ninth (DSPLPAIN, 96) kicking out DSSTNMOV (119), the first channel of no greater importance; DSPLDETH from the same thing cutting its own DSPLPAIN and taking the freed channel; DSITEMUP (78) passing over DSPLDETH (32) to take DSDOROPN (100); DSGETPOW (60) taking that one back from DSITEMUP; a second DSPLDETH (32) kicking out the first, since the rule is greater than or equal; DSSTNMOV (119), less important than every channel, dropped with the table unchanged; a removed thing's stop freeing its channel; and DSNOWAY from nobody taking the free channel without cutting the DSSWTCHN from nobody. The sides, 63 and 64 centred, 20 and 81 for the door at volume 51 and separation 204, and 62 and 65 at 64 and 129, are the two formulas by hand.

### The one place this differs from vanilla, and why

`S_StopSound(NULL)` in vanilla stops the first channel whose origin is NULL, so two sounds from nobody do cut each other there. This module leaves them alone, as the milestone's dispatch asked. Which is closer to vanilla depends on what the sim reports: in E1M1 the sounds this affects are pickups, the landing grunt and a switch click with no button running, and vanilla gives the first two `player->mo` and the third `buttonlist->soundorg`, two different origins, neither NULL. So vanilla cuts a pickup with the next pickup and does not cut a pickup with a click, and neither rule here gets both. The fix belongs in the sim: if a pickup and the landing reported `Thing{you}`, which is what vanilla passes, cutting would fall out of the thing rule and nobody would be left with nothing to compare. `src/sim.bend` line 653 and line 2226 are where that would change. Worth a ticket of its own.

### Trade-offs

- The table is a list and not eight fields, so the size holds because nothing changes the list's length, not because the type says so. Eight fields would make the size a type fact and every search eight cases of code.
- `Channel.hush` frees every channel of the source, where vanilla frees the first and breaks. They agree while no two channels share a source, which is the rule the allotment keeps, and it saves the early exit.
- A dropped sound still opens and closes its file. The open is what makes the channel, and the drop is the rare case.

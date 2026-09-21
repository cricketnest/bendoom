# 06: Eight channels by priority

**What to build:** Allot vanilla's eight channels, stop a source's previous sound, choose a free slot or the first eligible victim, and update moving sources once per rendered frame as `S_UpdateSounds` does.

**Blocked by:** 01 (The sim reports its sounds), 05 (The mixer plays a sound over the song)

**Status:** ready-for-agent

- [x] Channels live outside simulation state and end on the device's sample clock
- [x] Starts, stops, eviction and updates follow `S_StartSound`, `S_StopSound`, `S_GetChannel` and `S_UpdateSounds`
- [x] Pan gains use `I_SDL_UpdateSoundParams`
- [ ] Universal channel invariants: eight slots, unique sources, no lower-priority eviction of a more important sound
- [x] Event-list tests print tables derived by hand from vanilla's source
- [x] Recorded ninth-sound eviction and same-source replacement match every sample

## Verification

`tests/mixer.bend` covers filling eight slots, eviction, equal-priority replacement, dropping a less important sound, explicit stops, NULL-source replacement, moving-source gains and stopping a source that leaves earshot. The native and JavaScript transcripts pass.

The 21 Sep Chocolate Doom recording injects eight DSSTNMOV starts from distinct sector origins at the listener's position. Four tics later DSPLPAIN from a ninth origin evicts channel 0; four tics after that DSPLDETH from that same origin cuts the pain sound and takes its slot. GDB pauses SDL audio while inserting each batch, and unregisters the OPL postmix effect so the capture contains effects alone. All effects still pass through vanilla `S_StartSound`, channel allocation and SDL_mixer.

The recording starts the eight sounds at frame 105472, the ninth at 110592 and its replacement at 115712. The actual Bend `Channel.hear`/`Stream.window` output matches **61440 stereo frames with zero differing samples and zero largest difference**, including clipped overlap. Artifacts and the reproducible GDB/Bend drivers are under `/tmp/m7-06/audio/`: `channels-trace/`, `channels.bend`, `channels.json` and `channels-timing.json`.

## Implementation

`Channel.none` creates eight optional slots. `Channel.hush` closes a source's slot; `Channel.slots` finds the first free slot and the first sound whose priority is numerically greater than or equal to the new sound's. A free slot wins. `Channel.put` replaces a slot without changing the list length and drops the new sound if its index is past the end.

`Channel.update` asks the current simulation for each source's volume and separation, updates the gains, and closes inaudible channels. It runs after the current frame's sound starts and before writing audio, matching `TryRunTics` followed by `S_UpdateSounds`. The initial-start centring override applies only to `S_StartSound`: an already playing coincident source is re-panned normally. `sound_coincident` pins the difference at a listener angle of 90 degrees.

`S_StopSound(NULL)` stops the previous NULL-origin sound. Pickups really do pass NULL in `p_inter.c`; changing their origin to the player would be incorrect. Landing grunts already report the player. The former exception for `Nobody` is deleted.

## Remaining proof work

The runtime operations hold linear file handles and perform IO. The existing checker cannot normalize those actions into universal table laws. The structural size invariant and the source/priority cases are exercised above, but this is not a proof over arbitrary event lists. A pure allocation decision shared with the runtime still needs to be exposed before those laws can be claimed.

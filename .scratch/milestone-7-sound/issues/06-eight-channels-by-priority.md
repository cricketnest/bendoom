# 06: Eight channels by priority

**What to build:** The sound module that turns the sim's reported sounds into what the mixer plays. It allots vanilla's eight channels: a source's new sound cuts its old one, a free channel is taken, and otherwise a less important sound is evicted or the new one dropped, by `S_GetChannel`'s rule. It sets left and right volumes from volume and separation with Chocolate Doom's formula, follows moving sources once a tic as `S_UpdateSounds` does, and frees a channel when its file ends.

**Blocked by:** 01 (The sim reports its sounds), 05 (The mixer plays a sound over the song)

**Status:** ready-for-agent

- [ ] Channel state lives outside the sim's state, since in vanilla it follows the sound device's clock
- [ ] Starts, stops, eviction and the per-tic update follow `S_StartSound`, `S_StopSound`, `S_GetChannel` and `S_UpdateSounds`
- [ ] Left and right come from Chocolate Doom's `I_SDL_UpdateSoundParams`
- [ ] Laws over all inputs: the table never holds more than eight, no two channels share a source, eviction never drops a more important sound for a less important one
- [ ] A test drives the module with event lists and prints the channel table after each tic, with expected tables worked by hand from the source
- [ ] Recordings of a ninth sound evicting a channel and of a sound cut by its source's next sound compare at the target of zero

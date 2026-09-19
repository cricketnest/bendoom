# 05: The mixer plays a sound over the song

**What to build:** The music stream becomes the mixer and stays the only writer to `Audio`. Given the song and a list of hand-written events (this sound, from this frame, at these left and right volumes), it streams each playing sound from its file, adds it to the song with SDL_mixer's arithmetic and clipping, and produces the frames the device would get. No channel logic yet.

**Blocked by:** 04 (The sounds node)

**Status:** ready-for-agent

- [ ] Each playing sound is read from its file front to back, and nothing but the frames about to be written is held
- [ ] Volumes scale and sums clip as SDL_mixer's do, at Chocolate Doom's default music and sound volumes
- [ ] With no sound playing the output equals the song alone, and milestone 8's stream test keeps its values
- [ ] A test on both lanes mixes Freedoom's sounds and song in pieces of varying frame counts and prints a hash and sampled values at each sound's start and end and where two overlap, with expected values read from the recordings in nushell
- [ ] `tools/listen.nu` compares three recordings with the mixer's output placed at the recorded starts: one centred sound, two overlapping, one over the music; the ticket records differing samples and the largest difference, target zero
- [ ] The old stream's code that the mixer replaces is deleted, not kept beside it

# Milestone 7: sound effects

Status: ready-for-agent

## Problem Statement

Bendoom plays E1M1's song over a silent level. Doors rise without their motor, the lift has no clank, a switch has no click, a pickup has no chime, and the marine does not grunt at a wall he cannot use. Milestone 6 brings gunfire, monsters and pain, all mute. In vanilla, sound is also information. A sight growl tells the player that a monster has noticed them, a door heard behind them tells them someone came through it, and the stereo position says from where.

## Solution

Every sound vanilla starts in E1M1 plays in Bendoom, from the WAD's own sound lumps, as Chocolate Doom plays it. The sim reports the sounds each tic starts and stops. A sound module outside the sim allots vanilla's eight channels by priority, sets each channel's volume and stereo position from the distance and angle to the listener, follows a moving source every tic, and mixes the playing channels into the stream that already carries the music. The sounds are expanded to 44100 Hz while the flake builds, one file a sound, next to the song. Chocolate Doom is the oracle again. A nushell tool records what it plays for a demo with no window and no sound card, and Bendoom's mix of the same demo is compared with the recording sample by sample.

## User Stories

1. As a player, I want a door to sound as it opens and as it closes, with the fast door's own sounds for a fast door.
2. As a player, I want the lift to sound when it starts and when it stops.
3. As a player, I want a lowering floor to grind while it moves and thud when it stops.
4. As a player, I want a switch to click when I press it and again when it pops back.
5. As a player, I want the exit switch to click as vanilla's does, which is the ordinary switch's click: `P_ChangeSwitchTexture` clears the line's special before it looks for the exit's.
6. As a player, I want a grunt when I press use on a wall that does nothing.
7. As a player, I want a locked door to grunt at me.
8. As a player, I want a pickup to chime, a weapon pickup to make the weapon sound, and a power to make the power sound.
9. As a player, I want to hear my landing after a fall.
10. As a player, I want the pistol, the shotgun with its pump, the punch, and the chainsaw's start, idle, rev and hit.
11. As a player, I want a monster's sight sound when it notices me, picked among its variants as vanilla picks.
12. As a player, I want monsters' idle sounds while they hunt, their attack, pain and death sounds, and the wet sound of a gibbing.
13. As a player, I want the imp's fireball to sound when thrown and when it bursts.
14. As a player, I want a barrel to boom.
15. As a player, I want my own pain and death sounds.
16. As a player, I want a sound to come from the side its source is on, so that I can turn toward a monster I hear.
17. As a player, I want a sound to fade with distance and to be silent beyond 1200 units, as in vanilla.
18. As a player, I want a moving monster's sound to pan and fade as it or I move.
19. As a player, I want my own weapon and pickup sounds centred and at full volume.
20. As a player, I want a thing to make one sound at a time, its new sound cutting its old one, as vanilla does.
21. As a player, I want at most eight sounds at once, and a ninth to replace a less important one or be dropped, as vanilla decides by priority.
22. As a player, I want a sound to stop when the thing that made it is removed, as a fireball's flight sound does when it bursts.
23. As a player, I want the sounds at Chocolate Doom's default volume against the music, so that the balance is the original's.
24. As a player, I want a sound to reach my ears soon after the tic that made it, close to vanilla's delay.
25. As a player, I want the music to play on untouched under the sounds, with no click when a sound starts or ends.
26. As a player, I want the intermission's counting ticks and its final thump.
27. As a player, I want the game to play silently when there is no sound device, as it does now.
28. As a player, I want sounds to cost no frame rate I can see.
29. As a player recording a demo, I want the film to carry the sound effects with the music, each on the tic it happened.
30. As a player, I want the shareware package to play the shareware sounds and the Freedoom package Freedoom's.
31. As a developer, I want the sim to report each tic's sound starts and stops as plain values in the state, so that sound is checked through the replay seam like everything else.
32. As a developer, I want a sound's source named as a thing, a sector or nobody, so that doors sound from their sector's centre as vanilla's do.
33. As a developer, I want the sim to decide audibility with `S_AdjustSoundParams` and to advance vanilla's second random index for each audible start that vanilla draws for, so that milestone 6's face glances as Chocolate Doom's does.
34. As a developer, I want channel allotment, volume, separation and the per-tic update outside the sim's state, since vanilla frees a channel when the device finishes it and not on a tic.
35. As a developer, I want each sound's volume and separation computed with vanilla's integer formulas and Chocolate Doom's left and right scaling.
36. As a developer, I want the sound lumps read as Chocolate Doom reads them, header checked and padding dropped, so that a malformed lump is skipped and not played as noise.
37. As a developer, I want the expansion to 44100 Hz to give Chocolate Doom's samples, so that the comparison can reach zero.
38. As a developer, I want the mixer to add channels and music with SDL_mixer's arithmetic and clipping, so that a loud moment distorts as the original does and not otherwise.
39. As a developer, I want the mixer to stream each playing sound from its file, holding nothing but the frames it is about to write, as the music stream does.
40. As a developer, I want one module to own the device, mixing the song and the channels, so that there is one writer to `Audio`.
41. As a developer, I want a tool that records Chocolate Doom's sound for a demo with no window, desktop or sound card.
42. As a developer, I want the comparison to find each sound's start in the recording and mix ours at those starts, since vanilla starts a sound on a device buffer and not on a tic.
43. As a developer, I want the queue level chosen from a measurement of frame time, so that latency is as low as the frame rate allows and the ring never runs dry.
44. As a proof author, I want laws over the channel table: never more than eight, never two channels for one source, a kept sound never less important than the one dropped for it.
45. As a proof author, I want closed laws for volume and separation at the close distance, the clipping distance, dead ahead, and hard left and right.
46. As a packager, I want the expanded sounds as one node per WAD in the build graph, beside the music node, with no binary download.
47. As a packager, I want the flake check to build Freedoom's sounds alone, so that it never needs the unfree WAD.
48. As a reader of the README, I want milestone 7 marked done only after both packages play their sounds and the comparison with Chocolate Doom is recorded.

## Implementation Decisions

- The reference is Chocolate Doom 3.1.1 at its defaults: 44100 Hz, the digital sound effects device, eight game channels, sound volume 8 of 15, no pitch shifting, no libsamplerate. Its sound path has three parts, and the Bend code follows each: the game's sound logic (`S_StartSound`, `S_StopSound`, `S_UpdateSounds`, `S_AdjustSoundParams`, `S_GetChannel`), the sound device (lump loading, expansion, left and right volumes), and SDL_mixer's mixing. They are read as the specification. No C enters the repo.
- The first ticket is shared with milestone 6 and blocks its action tickets. The sim's state gains the sounds the tic started and stopped, cleared at each tic's start, and vanilla's second random index. A start names the sound and its source: a thing by identity, a sector, or nobody. A stop names a source. The sim runs vanilla's audibility test against the player for every start with a source, drops the inaudible ones, and advances the second random index as `S_StartSound` does: one draw for every audible start, except the item pickup sound. The draw happens although the pitch it chooses is unused. `P_RemoveMobj` stops its thing's sound. That ticket also makes what exists sound: doors, the lift, floors, switches, the exit, the use grunt, the locked door, pickups and landing. Milestone 6's tickets then start their own sounds inline.
- The sound table carries, for each sound either E1M1 can start, its lump name and its priority. Link sounds belong to the chaingun, which no map here gives, so they are left out. Sounds added by milestone 6's tickets add their rows there.
- A sector's sound comes from the centre of its bounding box, computed at load, as vanilla's `soundorg`.
- The sound module lives in the game record beside the music. Each frame it takes the sounds of the tics just run. For each start it stops the source's old channel, finds a free channel or evicts one of lower or equal importance by `S_GetChannel`'s rule, and sets the channel's left and right volumes from volume and separation with Chocolate Doom's formula. Once per tic it re-runs the audibility test for every channel with a moving source and stops the ones gone silent. A channel frees itself when its file is read to the end. This state is outside the sim's state on purpose: in vanilla it depends on the sound device's clock.
- Sounds are expanded while the flake builds, as the music is rendered. A Bend program reads the package's WAD and writes one raw file for each sound in the table: signed 16-bit mono at 44100 Hz, since Chocolate Doom's stereo chunk holds the same sample on both sides and the sides part only at the channel's volumes. A sibling of the music node runs it once per WAD. The launcher finds the directory beside the IWAD, as it finds the music. The cost is the one the music already has: a package plays the sounds of the WAD it was built with, and the music-from-the-wad ticket grows to cover sounds. The gain is that the game holds no expanded sound in memory and pays nothing at load or at a sound's first play. This is the maintainer's call to reverse, and the first audio ticket records the measured cost of expanding at load so the call rests on a number.
- Expansion follows Chocolate Doom. Ticket 02 found that every sound either E1M1 can start is at 11025 or 22050 Hz, which Chocolate Doom hands to SDL's converter. The dev shell's Chocolate Doom links sdl2-compat 2.32.70 over SDL3 3.4.14, so the converter is SDL3's audio stream and its resampler, not SDL2's. Freedoom's two sounds at 16000 and 17990 Hz take Chocolate Doom's nearest-sample loop, but nothing in E1M1 starts them, so that loop is not written. The first audio ticket ports SDL3's path, compares one expanded sound with the recording, and reports the differing samples and the largest difference. If SDL's filter table cannot be reproduced bit for bit from its source, the ticket brings the number to the maintainer before going on. A tool generates the filter table from SDL's source if it is needed, the way the angle and chip tables are generated.
- The music stream becomes the mixer and stays the only writer to `Audio`. Each frame it reads the song's next frames, adds every playing channel's next frames scaled by its left and right volumes, clips to 16 bits as SDL_mixer does, and writes the sum. Music volume and sound volume are Chocolate Doom's defaults, applied with its arithmetic. With no channel playing, the output equals the song alone, so milestone 8's stream test keeps its values.
- A sound starts at the first frame of the next write after its tic. The queue level decides the delay. It is 3072 frames today, about 70 ms, against Chocolate Doom's buffer of 1024 frames, about 23 ms. The mixer ticket measures how low the level can go with no dry frame at 35 frames a second and sets it there. The ticket records the level, the delay and the measurement.
- The film mixes offline. A tic is exactly 1260 frames at 44100 Hz, so each sound starts on its tic's first frame, mixed over the song by the same mixer and muxed under the video.
- The game with no sound device or no sound directory prints one line and plays on, silent or with music alone.
- README's milestone 7 line is marked done only after both packages play their sounds, the comparison is recorded, the frame-rate measurement passes, and the maintainer has listened to a fight on both.

## Testing Decisions

- A good test drives one of two seams. The sim seam is the replay: a script in, and the tic's sounds out, each with its source, volume and separation. The audio seam is the mixer: sound events, a song and a directory of expanded sounds in, samples out. Neither tests the lump parser, the channel search or the resampler alone, and no automated check opens a sound device.
- Expected values come from outside the Bend code. Which sound an action starts, its priority, and the volume and separation formulas come from linuxdoom-1.10 and Chocolate Doom's source, worked by hand or replayed in nushell. Lump rates and lengths are read from the WAD in nushell. Sample values are read from the recording in nushell.
- The sim test gains, on each scripted case that already exists, the sounds its tics start: the first door's open and close, the lift, the switch and its pop-back, the exit, a use on a bare wall, the blue door refusing, each pickup family, a landing. It adds a source heard hard left, hard right, behind, at the close distance, just inside and just outside the clipping distance. It prints the second random index at the end of each. Milestone 6's fight cases print their sounds through the same output once both are merged.
- `tools/listen.nu` gains the sounds. It runs Chocolate Doom on a demo with SDL's disk audio driver, music off for sound cases and on for the mix case, in real time, with no window. It finds each sound's first frame in the recording, renders Bendoom's mix of the same demo with its sounds placed at those frames, and reports the count of differing samples and the largest difference. The target is zero. It never runs in the flake check, since Chocolate Doom runs in real time.
- The capture cases: one centred sound alone (a use grunt), one positioned sound (a door heard from the side), two overlapping sounds, a ninth sound evicting a channel, a sound cut by its source's next sound, and one sound over the music.
- The flake check gets a mixer test on both lanes. It mixes Freedoom's expanded sounds and song from a list of events, in pieces of varying frame counts, and prints a hash and sampled values at each sound's start and end and where two overlap. The expected values are read from the recording where a capture case covers them and from the render files in nushell otherwise. The tests derivation gets the Freedoom sounds node.
- Laws cover the channel table over all inputs: its size never passes eight, no two channels share a source, and eviction never drops a more important sound for a less important one. Closed laws pin volume and separation at the named distances and angles. All laws are filled in so the flake check gates them.
- Prior art is the music milestone throughout: the listen tool and its disk-audio capture, the stream test that reads the render in uneven pieces, the render node per WAD, the generated tables, and the window bench's dry-frame count.
- The window bench plays sounds while it measures: a script that keeps several channels busy over the music. The target is 35 frames a second and no dry frame after the first. The ticket records the machine and the power state.
- Both packages are played with sound on the dev machine. The shareware package and its capture comparison are run by hand, since its WAD is unfree.

## Out of Scope

Pitch shifting, which Chocolate Doom leaves off. The PC speaker sounds. A volume setting or a menu. Sounds that nothing in the two E1M1s can start, the chaingun's link sound and the teleporter's among them. Expanding sounds from the WAD opened at runtime (the music-from-the-wad ticket, which now covers sounds too). The pause. Hellbent.

## Further Notes

- Milestones 6 and 7 run in parallel as one ticket graph. This spec's first ticket blocks milestone 6's action tickets. In the other direction, only the ticket that checks combat sounds end to end waits for milestone 6. The lump reader, the expansion, the channels, the mixer, the capture tool, the film and the sounds of doors, lifts, switches and pickups need nothing from it.
- The sim seam and the audio seam meet at a list of events, which is what lets the two halves of this milestone proceed side by side: the audio tickets can be driven by hand-written events before the sim reports any.
- The expansion is the risky part. SDL3's resampler is float code, and the recording is the only judge of whether the port is exact. The quieter risk is the mix's frame cost: up to eight files read and summed each frame on top of the song, inside a frame budget milestone 6 is also spending.
- Vanilla starts a sound when the device asks for its next buffer, so the same demo recorded twice places a sound a buffer apart. That is why the comparison takes each sound's start from the recording. What it checks is the samples, the volumes and the mix, not the start.
- The Bend constraints that shape the implementation remain in the project's Bend guide.

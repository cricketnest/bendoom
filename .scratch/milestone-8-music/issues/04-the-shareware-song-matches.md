# 04: The shareware song matches

**What to build:** The MUS reader. A MUS lump goes straight to the events and delays the player reads, with `mus2mid.c`'s channel, controller and velocity mapping and its timing, and no MIDI bytes built in between. A lump that is neither MUS nor MIDI fails the render. The shareware song's first pass is compared with its capture.

**Blocked by:** 03 (Freedoom's first pass matches)

**Status:** done

- [x] Expected event counts and the song's length (13440 ticks at 140 a second, 96.0 s) are read from the lump in nushell before the Bend code answers
- [x] The shareware first pass has zero differing samples against its capture, run by hand because the WAD is unfree, and the numbers are recorded
- [x] A lump that is neither format fails the render with a message naming the lump
- [x] A closed law or a test on a small literal MUS lump in the flake check covers the mapping without the unfree WAD

## Comments

19 Sep 2026. Chocolate Doom 3.1.1 from the flake's nixpkgs, DOOM1.WAD 1.9 and Freedoom 0.13.0, on an x86_64 benchmark host on AC power, balanced profile.

The first commit is ticket 03's review. `Player.level.go`, `Player.split` and `Player.without` build their lists with Base's `List.filter.put`; `List.filter` itself cannot serve, because a template argument may not capture the voice to drop. `Player.Voice.rank` matches the channel, and `Player.Voice.on` compares ranks, so `Player.on.chan` and `Player.rank` are gone. `Midi.meta.event` matches. `Opl.hash` is `Fnv.words` in `src/fnv.bend`, and `tests/render.bend` mixes with `Fnv.mix`. The test pins frames 67842 and 67843: rendered without the steal, the first 72000 frames first differ at 67843, so these are the last frame the steal leaves alone and the first it changes. The old 67613 and 67614 came before any difference. Their values come from a new real-time capture, lead 4536, whose hash over the 72000 frames is still 1145462143. The test also prints the two negative rescales (994 and 87) on both lanes. `velocity_zero_is_off` is gone.

What landed. `Midi.Track` has two more shapes: `Mus{bytes, delta, chans, vels}` and `Bad{why}`. `Midi.next` and `Midi.delta` answer for all three, so `Song.play` reads a MUS song without change. What `mus2mid.c` emits, read from its source:

- One track at division 70 (0x46) and no tempo event, so the player's default 500000 µs a beat applies: 140 ticks a second.
- MUS channel 15 is MIDI channel 9. The other channels are not a fixed map: `AllocateMIDIChannel` gives each the next MIDI channel on its first use and skips 9. The 9 and 15 swap belongs to the player (`i_oplmusic.c`), which already does it. The first use of a channel sends that channel controller 123 (all notes off) with the pending delta, and the event follows at delta 0. The reader does this by returning the all-notes-off and reading the same descriptor again.
- A key with its top bit set carries a velocity byte, masked to 7 bits, which the MIDI channel keeps for later presses; every channel starts at 127. `channelvelocities` is static and never reset between songs. With `-warp` E1M1's song is the first one converted, so that does not show.
- Release is note off with velocity 0. Pitch wheel byte b is bend (b & 1) * 64, b >> 1. System events 10 to 14 are controllers 120, 123, 126, 127 and 121, with value 0. Controller 0 is a program change (value & 0x7F), and 1 to 9 map through `controller_map`, with any value past 127 sent as 127.
- A descriptor with its top bit set ends its group. The delay that follows (7 bits a byte, any length, in an unsigned int) falls on the next event, the end of the score included.

The faults. A song the render cannot play as Chocolate Doom would now stops the render: `Song.load` exits 1 with `D_E1M1: ` and the reason on stderr. This is the one change in `src/song.bend`, since only IO can exit (the maintainer chose it over leaving the wiring to ticket 05). Each fault is a `Bad` track, and `Midi.fault` walks every track to its end to find the first. For MIDI, `midifile.c` refuses:

- a header chunk whose size is not 6, a format other than 0 or 1, or no tracks
- a track header other than MTrk
- a lump that ends mid-event or before its end-of-track
- a number of five bytes
- a status outside 0x80 to 0xEF, 0xF0, 0xF7 and 0xFF, including a data byte before any status (the running status starts at 0)

A division of 0 is refused too, since `ScheduleTrack` would divide by it. For MUS, `mus2mid.c` refuses a score cut short, event types 5 and 7, system events outside 10 to 14, and controller changes past 9. A delay of 2^28 ticks or more is also refused: `WriteTime` writes it in five bytes, which `midifile.c` then refuses. `I_OPL_RegisterSong` converts any lump that is not "MThd" under 96 KiB as MUS, without looking at its header. The render takes as MUS only a lump that starts "MUS" 0x1A and has its 16-byte header, and names anything else "neither MUS nor a MIDI lump under 96 KiB". That is the one declared difference.

A SMPTE division is not a refusal: `MIDI_GetFileTimeDivision` turns it into ticks a beat, and the reader does the same. C divides the whole short by 256 toward zero, so 0xE728 (25 frames of 40 ticks) is 24 * 40 = 960, and the law pins 960.

The write buffer. The shareware pass never has more than 319 writes pending, and Freedoom's 360. I measured both with a throwaway copy of `Song.play` that recorded the buffer after every callback. Neither song reaches 1024, but opl3.c:1344 is ported rather than guarded: a write that finds 1024 pending has the oldest applied at once, and the sample count moves to that write's time. The spill moves the count no further than the last write queued, so it moves no write's due time. The law `buffer_spills` pins it.

The numbers. `tools/wad.nu` gains `song-events` (MUS as `mus2mid.c` converts it, MIDI as `midifile.c` reads it, both written from the C) and `song-counts`. The shareware song is 13440 ticks, 96.0 s at 140 a second. It has 5829 events: 2332 note on, 2332 note off, 14 controllers (11 from the score, 3 first-use all-notes-offs for MUS channels 0, 1 and 2; channel 15 gets none), 4 program changes, 1146 bends and 1 end. Freedoom's is 26114 ticks with 12478 events: 5483 on, 5483 off, 439 controllers, 80 programs, 955 bends, 3 tempos, 18 ends and 17 others. `tests/music.bend` prints the same line from the reader. It matches on Freedoom in the flake check, and on the shareware WAD by hand.

The comparison. The capture (`--length 200sec`) is 8,835,072 frames, lead 4536, with left and right differing on 7,100,862. The render's first pass is 4,238,520 frames: 4096 idle frames and 4,234,424 of song. Against the capture, 0 left and 0 right samples differ, largest difference 0.

Failing renders. On a WAD whose D_E1M1 is eight bytes of neither format, the render prints `D_E1M1: neither MUS nor a MIDI lump under 96 KiB` and exits 1 with nothing on stdout. On a MUS score whose controller change names controller 10, it prints `D_E1M1: MUS data mus2mid.c refuses: …` and exits 1. A MUS score of one end event renders.

The speed. The shareware pass renders natively in 6.76 to 6.79 s over three runs with every frame printed as hex: 96.1 s of audio, 14 times real time.

The laws. `mus_events` is a 45-byte score through the reader: first-use all-notes-offs, channel 15 on 9 with none, a velocity masked and then reused by a later press after other channels have played, the pitch wheel, a system event, a program change, a volume cut to 127, ten channels in first-use order with MIDI 9 skipped, and delays of one and two bytes, each landing on the next event, the end included. `smpte_division` pins 960. `song_faults` is 16 lumps: each fault above, a delta of four bytes and a delay of 2^28 - 1 that pass, and the smallest MIDI track and MUS score the reader takes. `buffer_spills` queues 1025 writes on a reset chip: the count is 2, the last write due is 2050, and 1024 writes are pending. `end_of_track_ends` now reads `Midi.end`. A false `mus_events` or `buffer_spills` fails the proof.

On the way: Base's `List.length` recurses once per element, so measuring the 50 KB lump overflowed bun's stack in the JS lane. The size checks drop into the lump instead (`Midi.over`), and `docs/bend.md` records it.

Commands:

    nu -c 'source tools/wad.nu; open --raw <wad> | song-events | song-counts'      (both WADs)
    tools/listen.nu --wad <doom1.wad> --length 200sec --keep
    tools/listen.nu --length 10sec --keep
    bend tools/render.bend -o render
    BENDOOM_IWAD=<doom1.wad> tools/listen.nu render <capture> --binary render
    BENDOOM_IWAD=<doom1.wad> time ./render --threads 1 > /dev/null                (three times)
    bend tests/music.bend -o music; BENDOOM_IWAD=<doom1.wad> ./music
    nix build .#checks.x86_64-linux.tests .#checks.x86_64-linux.proof

For ticket 05:

- `Song.load` exits on a song Chocolate Doom would not play. `music.bend` should load through it, or call `Midi.fault` itself, so that the render node fails on a bad lump. In `src/song.bend`, `Song.song` moved above `Song.load`.
- `tools/render.bend`'s header still says Freedoom's song. It renders the song of whatever WAD `BENDOOM_IWAD` names.
- The shareware first pass ends with the restart due at song frame 4,234,424. Ticket 01 measured 4,234,429 frames between the first notes of the first two passes.

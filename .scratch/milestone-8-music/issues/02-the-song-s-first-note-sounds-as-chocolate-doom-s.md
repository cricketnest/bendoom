# 02: The song's first note sounds as Chocolate Doom's

**What to build:** The narrow path from WAD to samples, in Bend. A nushell tool generates Nuked OPL3's log-sine and exponent tables from Chocolate Doom's `opl/opl3.c`. The chip is written in Bend for what DMX drives, with the buffered register writes and the integer conversion to 44100 Hz. The player sets up the chip as Chocolate Doom does and starts a note with its GENMIDI instrument, volume and frequency. The song reader reads Freedoom's MIDI lump far enough to reach its opening. The result is Freedoom's opening, from the song's start to the first event after its first notes, rendered after the capture's idle lead and compared with ticket 01's capture. The chip's speed is measured before anything is built on it.

**Blocked by:** 01 (Chocolate Doom's music is recorded)

**Status:** ready-for-agent

- [ ] The table tool regenerates the tables module byte for byte from `opl3.c`, and the module names the tool at its top
- [ ] The chip carries two-operator voices, waveform select, note select, tremolo, vibrato, the envelope generator and its global timer, key scaling, feedback and both connections, and nothing Doom's player does not write
- [ ] Register writes go through the delay buffer of `OPL3_WriteRegBuffered`, and output goes through `OPL3_GenerateResampled`
- [ ] The player's chip setup and note start follow `i_oplmusic.c` for the Doom 1.9 driver in OPL2 mode, at music volume 8
- [ ] The opening's samples equal the capture's after the idle lead; the count of differing samples is recorded, target zero
- [ ] The chip's samples a second against real time are measured natively on the dev machine and recorded; below a tenth of real time, the ticket stops and brings the number to the maintainer
- [ ] A test in the flake check renders the opening on both lanes and prints a hash and sampled values taken from the capture in nushell

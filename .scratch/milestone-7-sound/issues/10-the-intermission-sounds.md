# 10: The intermission sounds

**What to build:** The intermission's counting ticks and its thump at the end of each count play as vanilla's do, from the intermission's own ticker and through the same channels and mixer.

**Blocked by:** 07 (The game sounds); milestone 6's 06 (The exit leads to the intermission)

**Status:** resolved

- [x] The ticks, the thumps and the sound of a press that skips the count start on vanilla's intermission tics, read from `wi_stuff.c`
- [x] They play centred at full volume, as sounds with no source do
- [x] A test prints the intermission's sounds per tic for a scripted exit on Freedoom

**Evidence:** `WI_updateStats` in Chocolate Doom 3.1.1's `src/doom/wi_stuff.c`
starts `sfx_pistol` when `!(bcnt & 3)`, `sfx_barexp` when a count
finishes or acceleration skips unfinished counts, and `sfx_sgcock` when
the completed screen advances. `tests/tally.bend` covers a natural
count completion, an early press, and the completed-screen press; the
JavaScript lane matches its checked transcript.

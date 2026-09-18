# 05: Held keys fold into a tic command, with the key laws

**What to build:** The held-key word and the tic command, so that input has no surprises. Key events fold into a word of held bits where the last press or release of a key wins; arrows and WASD map to the same bits; Shift sets run. A tic command is forward move, side move and turn, built from the held word with Doom's speed tables: walk and run values, and turn speed with the two-tic slow-turn ramp. Key codes follow the runtime's table: Esc 27, arrows 63232 to 63235, letters as lowercase ASCII, Shift by its code.

**Blocked by:** None (can start immediately)

**Status:** resolved

- [x] Folding a press then a release of the same key leaves its bit clear; release then press leaves it set
- [x] Up arrow and W fold to the same bit, likewise down and S, left and right arrows to the turn bits, A and D to the strafe bits
- [x] The command for forward walking is 25 per tic, forward running 50, matching Doom's forwardmove table; side and turn tables likewise
- [ ] The slow-turn ramp: the first two tics of a held turn use the slow value, the third the full value
- [x] Laws: the last press wins for all prior words; arrows and WASD fold to equal words; all in LAWS.bend and proven in PROOF.bend
- [x] The flake check stays green

## Comments

Done. Held keys are a record of seven flags (`Keys`), not a bit word: the last-press law is then a case analysis on the flags, as in Bend's pong demo, instead of bit-level word lemmas. Shift is codes 65592 and 65596 (the runtime's left and right Shift). The slow turn is Doom's SLOWTURNTICS: the "two-tic ramp" in this ticket read Doom's "two stage accelerative turning" comment as two tics; vanilla turns slowly while the held count, bumped before the test, is below 6, so the first five tics of a held turn are slow and the sixth is full. `cmd_tables` pins it at held counts 5 and 6.

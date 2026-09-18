# 10: Frames match Chocolate Doom pixel for pixel

**What to build:** The fidelity of the milestone as a number. A nushell tool takes a position and an angle on a multiple of 45 degrees, writes a PWAD whose E1M1 things are one player start there, runs Chocolate Doom from nixpkgs on it with no monsters, waits for the pistol to finish rising, takes its screenshot, decodes the paletted image, masks the status bar rows and the pixels the resting pistol sprite covers, and diffs it against our frame at the same position, dumped as hex rows by a program outside the tests directory that renders through the game's renderer. Every position the render test uses with the eye at rest is compared; each difference found is a renderer bug to fix, and the count of differing pixels per position is recorded in the comments, target zero. The render test also gains frames at positions reached by the sim's scripted walk, so bob and fall are pinned.

**Blocked by:** 09 (Two-sided middle textures through the masked pass)

**Status:** resolved

- [x] The tool is idiomatic nushell: typed parameters, a usage comment, structured data through pipelines, the standard library over shelling out where one exists
- [x] The tool produces vanilla's paletted frame and the diff for a given position in one run
- [x] Every rest position of the render test is compared and its differing-pixel count recorded; positions at zero are the milestone's fidelity claim
- [x] Differences found are fixed in the renderer, not masked, unless recorded as a vanilla behaviour out of scope with the reason
- [x] The render test's scripted-walk frames are pinned to Freedoom, pass on both lanes, and the flake check stays green

## Comments

Done. Every rest position of the render test is bit for bit Chocolate Doom's frame, outside its animated surfaces and the pistol:

| place | differing | animated | pistol |
| --- | --- | --- | --- |
| -416 256 0 (start) | 0 | 737 | 1793 |
| 736 464 135 (lit) | 0 | 0 | 1793 |
| -416 256 90 (dark) | 0 | 0 | 1793 |
| 137 256 45 (step) | 0 | 123 | 1793 |
| -416 256 180 (grate, sky behind) | 0 | 0 | 1793 |
| 3 256 0 (water ceiling) | 0 | 3803 | 1793 |
| -640 256 90 (open sky) | 0 | 0 | 1793 |
| 488 256 0 (pit) | 0 | 1134 | 1793 |

Chocolate Doom 3.1.1 from nixpkgs on Freedoom 0.13.0, of 53760 view pixels each. "animated" counts pixels that vary among Chocolate Doom's own shots: Freedoom's animated flats and textures (the water ceiling, the computer screens), which Bendoom draws in their first frame and does not animate yet; animation is not in this milestone's stories.

`tools/oracle.nu` writes a PWAD of E1M1 (all its lumps, since vanilla loads a map's lumps by their place after the marker) whose things are one player 1 start and whose line and sector specials are zeroed, runs Chocolate Doom on it in a scratch directory with its own config, on a headless X server of its own (Xvfb), takes eight screenshots about 0.2 s apart, decodes the PCX files (Chocolate Doom writes every byte of 0xc0 and over as a marker and the byte, so one regex pass over the hex decodes it), and diffs the first settled shot against `tools/frame.bend`'s dump outside the status bar and the pistol's opaque pixels, which it works out from the sprite's posts and Doom's weapon placement. It returns a record and runs in about 12 s. `chocolate-doom`, `xorg.xorgserver` and `xdotool` joined the dev shell; the flake has no new input.

What the oracle taught, each found as a count and fixed at its cause:

- 42150 differing: Chocolate Doom's default screen size is 9, a bordered 288 by 144 view, not the 320 by 168 the spec calls its default. The oracle's config sets `screenblocks 10`.
- 762, specks on floors and ceilings and one whole ceiling row: a renderer bug by the oracle's standard. Chocolate Doom's `R_DrawSpan` is not linuxdoom's: it keeps the DOS executable's packed position, x in the top sixteen bits and y in the bottom, six whole bits over ten of fraction each, so a span drifts from the 16.16 fractions as it runs and y's overflow carries into x. `Draw.span` now does the same (`Draw.span.pack`, `Draw.span.spot`, pinned in the `plane_span` law). My first diff of the two sources had been cut short before that function.
- A count that changed from run to run: sector lights blink on their own clocks, so two shots could not tell them from differences. Zeroing the specials in the oracle's map removes them at the source; Bendoom reads no specials yet, so its frame is unchanged.
- 110, then 54, inside the animated water: pixels where a few shots agreed by chance while showing a later animation frame than ours. Eight shots 0.2 s apart see all four frames of the longest cycle (the shots' hashes cycle through exactly four), and ours is one of those frames, so an animated pixel that differs from ours differs among the shots too and none leaks. The last 54 were the tool's own: the pistol mask's first row was 114 for 113.
- 702 in the top eight rows: I had stopped looking for animation there because of the "screen shot" message on later shots. `show_messages 0` in the config removes the message instead.
- 44138 once, 0 on the rerun: a first shot taken while the screen wipe still ran. The tool drops shots until the status bar's left hundred columns hold still (the whole bar does not: the face looks about).
- The first version opened Chocolate Doom's window on the desktop, found it through niri, focused it for the key press and handed the focus back, interrupting the desktop session. Chocolate Doom can only take a screenshot while it runs, and from nixpkgs it does not start natively on Wayland here (with `SDL_VIDEODRIVER=wayland` it only puts up an error dialog), so the tool now runs it on Xvfb: nothing shows on the desktop, no focus moves, no workspace matters, niri is not involved, and the first key press is no longer swallowed. The window was never what was compared: the frames are the 320 by 200 PCX files Chocolate Doom writes from its own framebuffer, and Bendoom's side is `tools/frame.bend`'s headless dump.

The render test gained the open sky, the pit, and three frames no player start can express, from the sim's run east off the ledge: mid-stride with the eye bobbing (tic 34), in the air (tic 56) and just landed with the view dipping (tic 66). All eleven frames are pinned to Freedoom, fully covered, and pass on both lanes.

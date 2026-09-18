# 10: Frames match Chocolate Doom pixel for pixel

**What to build:** The fidelity of the milestone as a number. A nushell tool takes a position and an angle on a multiple of 45 degrees, writes a PWAD whose E1M1 things are one player start there, runs Chocolate Doom from nixpkgs on it with no monsters, waits for the pistol to finish rising, takes its screenshot, decodes the paletted image, masks the status bar rows and the pixels the resting pistol sprite covers, and diffs it against our frame at the same position, dumped as hex rows by a program outside the tests directory that renders through the game's renderer. Every position the render test uses with the eye at rest is compared; each difference found is a renderer bug to fix, and the count of differing pixels per position is recorded in the comments, target zero. The render test also gains frames at positions reached by the sim's scripted walk, so bob and fall are pinned.

**Blocked by:** 09 (Two-sided middle textures through the masked pass)

**Status:** ready-for-agent

- [ ] The tool is idiomatic nushell: typed parameters, a usage comment, structured data through pipelines, the standard library over shelling out where one exists
- [ ] The tool produces vanilla's paletted frame and the diff for a given position in one run
- [ ] Every rest position of the render test is compared and its differing-pixel count recorded; positions at zero are the milestone's fidelity claim
- [ ] Differences found are fixed in the renderer, not masked, unless recorded as a vanilla behaviour out of scope with the reason
- [ ] The render test's scripted-walk frames are pinned to Freedoom, pass on both lanes, and the flake check stays green

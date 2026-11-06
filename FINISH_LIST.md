# Airplane Rescue 1.0 list

The finish line, sorted from "625 Tips for Finishing a Game". Tips that don't fit this game (multiplayer, Roblox, phones, levels) are left out. New ideas go under "Later", not into 1.0.

**1.0 is done when:** playable from title to ending, no crashes in 3 full runs, 5 outside testers have played it, and the download page is up.

## Already in
- Goal shown at all times (the NEXT line), in steps, using the same words throughout (Tips 1, 6)
- Title screen, Continue, pause that freezes, settings, controls, credits (Tips 9, 11, 12, 13, 15)
- Save with backup, version migration and torn-save test (Tip 14)
- Win and game-over paths covered by the self-test (Tip 4)
- More faults per job as you rescue more planes (Tip 5)
- Sound per action, music fades, volume sliders, loudness matched (Tip 17)
- Auto-pause when the window loses focus (Tip 12)
- Ending screen with stats, game-over screen that explains why (Tips 2, 10)
- Money changes, "Saved" mark, moments for finished jobs (Tips 1, 8, 14)
- Invert Y and a screen-shake toggle (Tips 8, 13)
- Take-off with stakes: a spot you skipped can strike on the runway or in the climb (Tips 3, 4)

## Must do for 1.0
1. **Five outside testers,** silent watching, one who rarely plays (Tip 23).
2. **Download page** with screenshots, a short clip and controls (Tip 24).

## Automated testing
- `godot --path . -- --monkey --monkey-min=480` mashes random input overnight, on a throwaway save. Log: `user://monkey_log.txt` (inputs, stuck, low FPS, memory).
- The self-test also covers every failed start, every missed-fault outcome and a 500-open menu leak check. Run it with `--max-fps 30` and `--max-fps 144` for frame-rate bugs.

## Later (1.1)
- Controller support, key rebinding, UI scale slider
- Hangar and flight ambience beyond wind and engine
- Difficulty modes
- Replay recording, balance runs, an RL agent (once the game stops changing)
- Text size setting
- Medals or rescue ratings

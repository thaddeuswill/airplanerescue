# Airplane Rescue

First-person game (Godot 4.7) about a traveling A&P mechanic in mid-century rural America. Fly to stranded planes, diagnose them on a walk-around, fix them where they sit, and fly them out yourself.

## Run
Open the folder in Godot 4.7 (Import → select `project.godot`) and press F5.

**Controls:** WASD to move, mouse to look, Space to jump, E to interact (and to close panels), Esc to close a panel or free the mouse.
**Title screen:** the hangar interior behind a text menu (W/S or arrows, Enter): Continue, New career, Graphics (High/Low for weaker PCs), Quit. Message of the day bottom left (Q/E pages, V hides). Flying to a job shows a travel card while the field loads.
**Pockets:** Tab opens your wallet (cash, day, parts, tools, start over), J the clipboard (the work order), L the logbook (every rescue), M the service manual (opens to whatever you're working on; closing it puts you back in the job). The game autosaves and picks up where you left off.
**Ferry flight:** hold W for throttle, and at 40 mph hold S to lift off.

## Install and updates
- **Mac:** download `AirplaneRescue-<version>-mac.zip`, unzip it and drag **Airplane Rescue** into Applications. It runs on Intel and Apple Silicon Macs (macOS 11 or later on Apple Silicon). The app isn't signed with an Apple developer ID, so the first launch is blocked: open it once, then go to System Settings, Privacy & Security, and click **Open Anyway** (on older macOS, right-click the app and choose Open). After that it opens normally. When a newer version is out, the game offers it and opens the download in your browser.
- **Build the installer:** `powershell -ExecutionPolicy Bypass -File tools/build_release.ps1`, which writes `dist\AirplaneRescue-<version>-setup.exe` and the Mac zip `dist\AirplaneRescue-<version>-mac.zip`. It needs the Godot 4.7.2 Windows export templates and Inno Setup 6 (both already installed on the dev PC). The installer is per user (no admin prompt), adds Start menu and optional desktop shortcuts, and comes with an uninstaller. Saves live in AppData and survive updates and uninstalls.
- **Auto-update:** on launch, the installed game asks GitHub for the latest release of `thaddeuswill/airplanerescue`. If the release tag (for example `v0.9.1`) is newer than `application/config/version` in `project.godot` and has a `*-setup.exe` attached, the game offers "Install now". It saves, downloads the setup, installs silently and relaunches. It only runs files from this repo's own release downloads.
- **To ship an update:**
  1. Bump `config/version` in `project.godot`.
  2. Run the build script.
  3. Create a GitHub release tagged `v<version>` and attach the setup .exe and the -mac.zip.

## Loop
1. **Take a call.** The **MAP** on the hangar workbench shows rescue calls, with the owner's symptoms ("runs rough, oil spots under the nose"), the pay, the distance, and how many days the owner will wait. Flying there costs fuel and days.
2. **Walk around the plane.** Some planes just sat a few weeks; others sat out in the weather for years (it's on the radio call, and they pay more). Those are caked in grime, so **wash it down** first or you can't tell damage from dirt, and expect stale fuel to sump, an engine to pre-oil before its first start, maybe a door pin rusted shut.
    There are 8 spots to check: propeller, engine, cabin, both main gears, left wing, battery bay and tail. Press E on each to inspect it. You notice what's visible there (oil dripping, a flat tire, straw in the cowl). Then **sit in and run it up** from the cabin: start it on the chocks, hold 1700 rpm and switch to each mag alone (I) to read the drop off the tach, then pull the carb heat (H) and watch for a small drop. A weak battery, a bad starter, a dead radio, fouled plugs, a bad magneto, a broken P-lead (a mag with no drop at all is live with the key off) or a broken carb heat cable only show up there. Some faults look alike (a big drop on one mag could be the plugs or the magneto; a clicking starter could be the battery or the starter), so the work order lists them as suspects and you pick which to fix. Pick wrong and the part and the time are spent, and the next run-up shows nothing changed. Sometimes taking the cowl off for one job shows you another behind it; the owner pays for the extra work. Your first two jobs have neither look-alikes nor hidden faults, so you can learn the controls first.
3. **Get tools, materials and parts.** You start with a screwdriver and a rag. The ratchet set, torque wrench and safety-wire pliers must be bought: at a town's **PARTS** shed if it stocks them, or mail-ordered from the hangar **TOOLS** box (1 day, +25%). Repairs use up materials (safety wire, cotter pins, penetrant), so keep them stocked. Each town's **PARTS** shed stocks only some parts. The rest come by mail order, which costs 25% more and takes a day.
4. **Do the work.** Stand at the spot (yellow **?** markers float over unchecked spots, orange **!** over work still to do) and press E; "Work on it" opens a flat 2D view of that spot. The J clipboard is read-only: run-ups and take-off happen from the cabin. Pick a tool, hold the mouse on each screw or bolt to loosen it, take it out to the magnetic tray, lift panels onto the bench, pull the old part, fit the new one, clean up, then put everything back and tighten it. Prop bolts and spark plugs get the torque wrench, a fuel line gets a leak check with the fuel back on, and now and then a bolt is seized and needs penetrant first. Every step takes time, and you can step away (Esc) and come back. Art list: `WORK_SCENES.md`.
5. **Fly it out.** Push the plane into the hangar to work on it if you like, but roll it back out and fuel it at the **fuel truck** (no fueling indoors, never on top of stale gas; at least half tanks). Parts and materials you own sit on the **PARTS ON HAND** table by the apron. Once every spot is checked, the run-up is clean and every fault is fixed, climb in and take off. The panel gauges (airspeed, altimeter, tach, oil pressure) work. The owner pays you once you're airborne. The logbook keeps an itemized sheet per rescue: pay, fuel, parts, net, days on site.

Rescue 10 planes to win. Owners scrap their planes if you're too late. One call on the radio is always within 650 miles. Run out of money while grounded (can't afford a flight, or the parts, tools and materials to finish the plane here) and the game's over.

**Look and sound:** the MyAP design doc's palette (dark earth, aged paper, hangar green, worn brass), a framed photo on the hangar wall, wheel chocks, a chime for a new call and a pen scratch on each sign-off. Repairs use recorded tool sounds per action, with guitar music and hangar room tone behind them (sources in CREDITS.md).

**Flying it out** starts in the cockpit: run the checklist (F fuel, M master, P primer, W/S throttle, I mags, hold Space for the starter). Skip a step and it won't start: no fuel, no spark, flooded, or a hung start that dies unless you ease in throttle. Then W/S throttle, A/D rudder against the left swing, Down arrow to rotate at 55 kt.

**Playtest log.** A hand-played session writes how long each step took to `playtest_log.txt` in the game's save folder; press F8 any time to mark "something's off here" in it.

**Before take-off** you write up the aircraft logbook entry (the data you worked to, and who signs for it) and sign it; the plane can't leave until it's signed. Each spot takes about two hours to check, owners wait 4 to 8 days, and hangar rent and insurance cost $40 a day, so skipping a spot is a real gamble. You can sign with spots unchecked, but a fault you never found will strike on the runway or in the climb: land it and you lose a day and a quarter of the pay, crash it and you lose the job and $1500. Run out of money and you can take three days of odd jobs at the field for $900 and keep going. Esc pauses, with settings, controls and credits there and on the title screen.

## Layout
- `scripts/main.gd`: game state, world and plane building, panels
- `scripts/work.gd`: the 2D work scenes (rules, drawing, and every job as data: 57 scenes)
- `scripts/manual.gd`, `scripts/parts_book.gd`: the M-key service manual and parts book, read from `data/c85_manual.json` and `data/c85_parts.json`
- `tools/art_list.gd`: lists every work-scene piece and whether its art exists
- `docs/`: art guides for the job scenes and the parts list
- `CLAUDE.md`: how to run, test and extend the project (for Claude Code and contributors)
- `scripts/gauge.gd`: round cockpit dials drawn into the Cub's panel
- `scripts/updater.gd`: checks GitHub Releases and installs newer versions
- `scripts/chart.gd`: the rescue map's navigation chart overlay
- `scripts/radio.gd`: the shop radio on the workbench (stations, and media keys for the player's own music)
- `scripts/catalog.gd`: the Field Service Catalog parts book
- `scripts/selftest.gd`: the self-test (plays a whole rescue through the real code)
- `installer/airplane_rescue.iss`, `tools/build_release.ps1`: the Windows installer and its build
- `scripts/player.gd`: first-person controller
- `scripts/terrain.gd`: noise terrain per region (flat airfield, hills to mountains, ponds), slope/height ground blending
- `scripts/ferry.gd`: cockpit takeoff
- `scripts/sound.gd`: procedural wind, engine and wrench sounds (no audio files yet)
- `tools/optimize_models.py`: Blender batch that makes Meshy exports game-ready (`models_raw/` → `models/`)
- `tools/ac3d_to_glb.py`: converts FlightGear `.ac` models to `.glb` (used for `models/plane_cub.glb`)

## Credits
- Plane: Piper J-3 Cub for FlightGear by Don Lavelle (model), David Megginson and Jim Wilson, GPLv3 ([source](https://github.com/wlbragg/J3Cub)). Source files and license are in `models_raw/j3cub_fg/`.
- `ART_DIRECTION.md`, `TEXTURES.md`, `MODELS.md`: art direction and asset lists
- `prototype/index.html`: the original 2D browser prototype
- `JOBS_ATA.md`: every job on the airplane by ATA code, with real-world values and what is still missing
- `reference/`: the FAA source documents behind it

Self-test (`scripts/selftest.gd`): `godot --headless --path . -- --self-test [--all-faults] [--faults=a,b] [--city=Omaha] [--seed=N] [--shot=prefix] [--scene-shots=prefix[:scene,scene]]`

Before a release, also run `godot --headless --path . -- --self-test --all-fields`: it flies a forced landing at every field.

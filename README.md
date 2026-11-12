# Airplane Rescue

First-person game (Godot 4.7) about a traveling A&P mechanic in mid-century rural America. Fly to stranded planes, diagnose them on a walk-around, fix them where they sit, and fly them out yourself.

## Run
Open the folder in Godot 4.7 (Import → select `project.godot`) and press F5.

**Controls:** WASD to move, mouse to look, Space to jump, E to interact (and to close panels), Esc to close a panel or free the mouse.
**Title screen:** the hangar interior behind a text menu (W/S or arrows, Enter): Continue, New career, Graphics (High/Low for weaker PCs), Quit. Message of the day bottom left (Q/E pages, V hides). Flying to a job shows a travel card while the field loads.
**Pockets:** Tab opens your wallet (cash, day, parts, tools, start over), J the clipboard (the work order), L the logbook (every rescue). The game autosaves and picks up where you left off.
**Ferry flight:** hold W for throttle, and at 40 mph hold S to lift off.

## Install and updates
- **Build the installer:** `powershell -ExecutionPolicy Bypass -File tools/build_release.ps1`, which writes `dist\AirplaneRescue-<version>-setup.exe`. It needs the Godot 4.7.2 Windows export templates and Inno Setup 6 (both already installed on the dev PC). The installer is per user (no admin prompt), adds Start menu and optional desktop shortcuts, and comes with an uninstaller. Saves live in AppData and survive updates and uninstalls.
- **Auto-update:** on launch, the installed game asks GitHub for the latest release of `thaddeuswill/airplanerescue`. If the release tag (for example `v0.9.1`) is newer than `application/config/version` in `project.godot` and has a `*-setup.exe` attached, the game offers "Install now". It saves, downloads the setup, installs silently and relaunches. It only runs files from this repo's own release downloads.
- **To ship an update:**
  1. Bump `config/version` in `project.godot`.
  2. Run the build script.
  3. Create a GitHub release tagged `v<version>` and attach the setup .exe.

## Loop
1. **Take a call.** The **RADIO** in the hangar shows rescue calls on a map, with the owner's symptoms ("runs rough, oil spots under the nose"), the pay, the distance, and how many days the owner will wait. Flying there costs fuel and days.
2. **Walk around the plane.** Some planes just sat a few weeks; others sat out in the weather for years (it's on the radio call, and they pay more). Those are caked in grime, so **wash it down** first or you can't tell damage from dirt, and expect stale fuel to sump, an engine to pre-oil before its first start, maybe a door pin rusted shut.
    There are 8 spots to check: propeller, engine, cabin, both main gears, left wing, battery bay and tail. Press E on each to inspect it. You notice what's visible there (oil dripping, a flat tire, straw in the cowl). Then **sit in and run it up** from the work order: a dead battery, a clicking starter, a dead radio, a mag drop or rough plugs only show up there, and a dead battery or starter stops the run-up until it's fixed.
3. **Get tools, materials and parts.** You start with a screwdriver and a rag. The ratchet set, torque wrench and safety-wire pliers must be bought: at a town's **PARTS** shed if it stocks them, or mail-ordered from the hangar **TOOLS** box (1 day, +25%). Repairs use up materials (safety wire, cotter pins, penetrant), so keep them stocked. Each town's **PARTS** shed stocks only some parts. The rest come by mail order, which costs 25% more and takes a day.
4. **Do the work.** Stand at the spot (yellow **?** markers float over unchecked spots, orange **!** over work still to do) and press E; "Work on it" opens a flat 2D view of that spot. The J clipboard is read-only: run-ups and take-off happen from the cabin. Pick a tool, hold the mouse on each screw or bolt to loosen it, take it out to the magnetic tray, lift panels onto the bench, pull the old part, fit the new one, clean up, then put everything back and tighten it. Prop bolts get the torque wrench. Every step takes time, and you can step away (Esc) and come back. Art list: `WORK_SCENES.md`.
5. **Fly it out.** Push the plane into the hangar to work on it if you like, but roll it back out and fuel it at the **fuel truck** (no fueling indoors, never on top of stale gas; at least half tanks). Parts and materials you own sit on the **PARTS ON HAND** table by the apron. Once every spot is checked, the run-up is clean and every fault is fixed, climb in and take off. The panel gauges (airspeed, altimeter, tach, oil pressure) work. The owner pays you once you're airborne. The logbook keeps an itemized sheet per rescue: pay, fuel, parts, net, days on site.

Rescue 10 planes to win. Owners scrap their planes if you're too late. One call on the radio is always within 650 miles. Run out of money while grounded (can't afford a flight, or the parts, tools and materials to finish the plane here) and the game's over.

**Look and sound** (from the MyAP design doc): its palette (dark earth, aged paper, hangar green, worn brass) and typewriter type, a shop log and framed photo on the hangar wall, wheel chocks, a chime for a new call, a pen scratch on each sign-off and a tone at rotation speed.

## Layout
- `scripts/main.gd`: game state, world and plane building, panels
- `scripts/work.gd`: the 2D work scenes (rules, drawing, and all 13 jobs as data)
- `scripts/gauge.gd`: round cockpit dials drawn into the Cub's panel
- `scripts/updater.gd`: checks GitHub Releases and installs newer versions
- `scripts/chart.gd`: the radio's navigation chart overlay
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

Self-test (`scripts/selftest.gd`): `godot --headless --path . -- --self-test [--all-faults] [--city=Omaha] [--shot=prefix]`

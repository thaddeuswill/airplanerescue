# Airplane Rescue

First-person game (Godot 4.7) about a traveling A&P mechanic in mid-century rural America. Fly to stranded planes, diagnose them on a walk-around, fix them where they sit, and fly them out yourself.

## Run
Open the folder in Godot 4.7 (Import → select `project.godot`) and press F5.

**Controls:** WASD to move, mouse to look, Space to jump, E to interact (and to close panels), Esc to close a panel or free the mouse.
**Pockets:** Tab opens your wallet (cash, day, parts, tools, start over), J the clipboard (the work order), L the logbook (every rescue). The game autosaves and picks up where you left off.
**Ferry flight:** hold W for throttle, and at 55 knots hold S to lift off.

## Loop
1. **Take a call.** The **RADIO** in the hangar shows rescue calls on a map, with the owner's symptoms ("runs rough, oil spots under the nose"), the pay, the distance, and how many days the owner will wait. Flying there costs fuel and days.
2. **Walk around the plane.** Some planes just sat a few weeks; others sat out in the weather for years (it's on the radio call, and they pay more). Those are caked in grime, so **wash it down** first or you can't tell damage from dirt, and expect stale fuel to sump, an engine to pre-oil before its first start, maybe a door pin rusted shut.
    There are 8 spots to check: propeller, engine, cabin, both main gears, left wing, battery bay and tail. Press E on each to inspect it. You notice what's visible there (oil dripping, a flat tire, straw in the cowl). Then **sit in and run it up** from the work order: a dead battery, a clicking starter, a dead radio, a mag drop or rough plugs only show up there, and a dead battery or starter stops the run-up until it's fixed.
3. **Get tools and parts.** Take tools from the **TOOLS** box in the hangar into your tool roll (screwdriver, ratchet, torque wrench, safety-wire pliers, rag); they travel with you. Each town's **PARTS** shed stocks only some parts. The rest come by mail order, which costs 25% more and takes a day.
4. **Do the work.** "Work on it" opens a flat 2D view of that spot. Pick a tool, hold the mouse on each screw or bolt to loosen it, take it out to the magnetic tray, lift panels onto the bench, pull the old part, fit the new one, clean up, then put everything back and tighten it. Prop bolts get the torque wrench. Every step takes time, and you can step away (Esc) and come back. Art list: `WORK_SCENES.md`.
5. **Fly it out.** Once every spot is checked, the run-up is clean and every fault is fixed, climb in and take off. The panel gauges (airspeed, altimeter, tach, oil pressure) work. The owner pays you once you're airborne. The logbook keeps an itemized sheet per rescue: pay, fuel, parts, net, days on site.

Rescue 10 planes to win. Owners scrap their planes if you're too late. Run out of money while grounded and the game's over.

## Layout
- `scripts/main.gd`: game state, world and plane building, panels
- `scripts/work.gd`: the 2D work scenes (rules, drawing, and all 13 jobs as data)
- `scripts/gauge.gd`: round cockpit dials drawn into the Cub's panel
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

Self-test: `godot --headless --path . -- --self-test [--all-faults] [--city=Omaha] [--shot=prefix]`

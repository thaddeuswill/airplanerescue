# Airplane Rescue

First-person game (Godot 4.7) about a traveling A&P mechanic in mid-century rural America. Fly to stranded planes, diagnose them on a walk-around, fix them where they sit, and fly them out yourself.

## Run
Open the folder in Godot 4.7 (Import → select `project.godot`) and press F5.

**Controls:** WASD to move, mouse to look, Space to jump, E to interact (and to close panels), Esc to close a panel or free the mouse.
**Ferry flight:** hold W for throttle, and at 55 knots hold S to lift off.

## Loop
1. **Take a call.** The **RADIO** in the hangar shows rescue calls on a map, with the owner's symptoms ("runs rough, oil spots under the nose"), the pay, the distance, and how many days the owner will wait. Flying there costs fuel and days.
2. **Walk around the plane.** There are 8 spots to check: propeller, engine, cabin, both main gears, left wing, battery bay and tail. Press E on each to inspect it. Faults only show up on the work order once you've checked the right spot.
3. **Get parts.** Each town's **PARTS** shed stocks only some parts. The rest come by mail order, which costs 25% more and takes a day.
4. **Repair.** Stop the needle in the green. Pricier parts are trickier, and a slip can ruin the part.
5. **Fly it out.** Once every spot is checked and every fault fixed, climb in and take off. The owner pays you once you're airborne.

Rescue 10 planes to win. Owners scrap their planes if you're too late. Run out of money while grounded and the game's over.

## Layout
- `scripts/main.gd`: game state, world and plane building, panels
- `scripts/player.gd`: first-person controller
- `scripts/ferry.gd`: cockpit takeoff
- `scripts/sound.gd`: procedural wind, engine and wrench sounds (no audio files yet)
- `tools/optimize_models.py`: Blender batch that makes Meshy exports game-ready (`models_raw/` → `models/`)
- `ART_DIRECTION.md`, `TEXTURES.md`, `MODELS.md`: art direction and asset lists
- `prototype/index.html`: the original 2D browser prototype

Self-test: `godot --headless --path . -- --self-test [--all-faults] [--city=Omaha] [--shot=prefix]`

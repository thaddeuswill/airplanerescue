# Airplane Rescue

First-person low-poly game (Godot 4.7). Fly around the country to stranded planes, inspect them, buy parts, fix them where they sit, and get them airworthy.

## Run
Open the folder in Godot 4.7 (Import → select `project.godot`) and press F5.

**Controls:** WASD to move, mouse to look, Space to jump, E to interact, Esc to close a panel or free the mouse.

## Loop
1. Use the **RADIO** in the hangar to pick a rescue call and fly there (costs fuel money).
2. Walk up to the plane and press **E** to open the inspection panel, which lists every fault.
3. Buy the parts you need at the **PARTS** shed.
4. Click **Repair** on each fault. That part of the 3D plane changes from broken to fixed.
5. When everything is fixed, click **Test flight & sign off**. The plane takes off and the owner pays you.

Rescue 10 planes to win. Run out of money while grounded and you lose.

## Layout
- `scripts/main.gd`: game state, world and plane building, 2D panels
- `scripts/player.gd`: first-person controller
- `TEXTURES.md`: textures wanted (art goes in `textures/`)
- `prototype/index.html`: the original 2D browser prototype

Self-test: `godot --headless --path . -- --self-test`

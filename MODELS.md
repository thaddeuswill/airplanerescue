# Models needed

Put finished files in `models/` with these exact names, and I'll swap them in for the placeholder shapes.

## Format rules (all models)
- **glTF binary `.glb`**, which Godot imports directly
- **Units in meters, Y up, front facing -Z** (in Blender, export with "+Y Up" ticked; Blender's -Y forward becomes Godot's -Z)
- **Origin on the ground**, at the center of the footprint
- Low-poly, triangulated. Rough budgets: plane under 3k tris, buildings under 2k, trees and rocks under 300
- Use the textures in `textures/` (or embed your own in the .glb)
- No collision meshes needed; I'll add simple box colliders

---

## 1. Plane: `plane_trainer.glb` (most important)
A high-wing single-engine trainer, about **8 m long with a 10 m wingspan**. Main wheels sit under the wings and there's a small tail wheel.

**The body material must be named `body`.** I tint it a random color for every plane, so give it a light gray texture (`plane_body.png`).

**Fault parts must be separate objects with these exact names.** The game shows or hides them as you repair. Parts marked "—" have no fixed version; they just disappear when repaired.

| Fault | Fixed object | Broken object | Broken looks like |
|---|---|---|---|
| Flat tire | `tire_ok` | `tire_broken` | Left main wheel squashed flat |
| Brakes | `brakes_ok` | `brakes_broken` | Right main wheel with a rusty brake disc |
| Battery | `battery_ok` | `battery_broken` | Side access hatch hanging open, corroded battery inside |
| Spark plugs | — | `spark_plugs_broken` | Black soot streaks on the cowling side |
| Oil leak | — | `oil_leak_broken` | Oil puddle on the ground under the nose |
| Bird nest | — | `bird_nest_broken` | Twig nest with eggs on top of the cowling |
| Fuel line | — | `fuel_line_broken` | Dripping line under the left wing plus a puddle |
| Windshield | `windshield_ok` | `windshield_broken` | Cracked and fogged glass |
| Starter | `starter_ok` | `starter_broken` | Rusty starter motor on the left of the engine |
| Magneto | `magneto_ok` | `magneto_broken` | Rusty magneto on the right of the engine |
| Rudder cables | `control_cables_ok` | `control_cables_broken` | Rudder jammed at a crooked angle |
| Antenna/radio | `avionics_ok` | `avionics_broken` | Antenna snapped and lying on the fuselage |
| Propeller | `propeller_ok` | `propeller_broken` | One blade bent backward |

Everything else (fuselage, wings, tail, struts, cowling, tail wheel) can be one mesh or many, with any names.

**Later, same rules:** `plane_taildragger.glb`, `plane_bush.glb` (big tires, high wing), `plane_tourer.glb` (low wing), `plane_hauler.glb` (bigger, boxy). Each matches a plane type in the game.

## 2. Buildings
| File | Size | Notes |
|---|---|---|
| `hangar.glb` | 14 × 6 × 12 m | **Open front facing +Z** (toward the runway), solid back and sides, roof. Leave room inside, near the back-right corner, for the radio desk |
| `parts_shed.glb` | 5 × 3 × 5 m | Open front facing +Z, with a counter and shelves of parts boxes |
| `radio_desk.glb` | ~2 × 1.4 × 0.8 m | Desk with an old radio set on top. Origin at the floor |

## 3. Nature (2 or 3 variants each if you can: `_a`, `_b`, `_c`)
| File | Size | Region |
|---|---|---|
| `tree_broadleaf_a.glb` | 4–7 m tall | Plains |
| `tree_pine_a.glb` | 5–9 m tall | Forest |
| `tree_pine_snow_a.glb` | 5–9 m tall | Snow (snow on the branches) |
| `cactus_a.glb` | 2–4 m tall | Desert |
| `rock_a.glb` | ~1–2 m | Desert, plus anywhere for scatter |
| `mountain_a.glb` | ~60 m wide, 40 m tall | Distant backdrop. Very low poly is fine |

## 4. Nice to have
- `windsock.glb`: pole plus orange sock, about 5 m tall
- `fuel_truck.glb`: small airport fuel truck
- `crate_a.glb`, `barrel_a.glb`, `toolbox.glb`: apron clutter
- `player_plane.glb`: your own little plane, parked when you arrive at a field (no fault parts needed)

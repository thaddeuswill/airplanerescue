# Models needed

Put finished files in `models/` with these exact names, and I'll swap them in for the placeholder shapes.

## Format rules (all models)
- **glTF binary `.glb`**, which Godot imports directly
- **Units in meters, Y up, front facing -Z** (in Blender, export with "+Y Up" ticked; Blender's -Y forward becomes Godot's -Z)
- **Origin on the ground**, at the center of the footprint
- Medium-poly, stylized-realistic (see ART_DIRECTION.md). Rough budgets: plane 8–20k tris, buildings 5–15k, trees and rocks 1–3k
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

---

# World-building models (round 2)

**Workflow:** generate in Meshy as usual and drop the **textured** `.glb` into `models_raw/`. My Blender script (`tools/optimize_models.py`) rebuilds, shrinks and bakes them, so you don't need to remesh. Name each file the way it's listed below.

**Add this to every prompt:** *Stylized-realistic game asset, medium detail, mid-century rural America, weathered and lived-in, warm hand-painted textures, single object, no ground plane, centered.*

## A. Airfield (priority 1)
| Name | Prompt |
|---|---|
| `hangar` | Small rural airfield hangar, corrugated metal walls, curved roof, wide open front, faded paint, rust streaks, 14 m wide |
| `airfield_office` | Tiny 1950s airfield office, white clapboard, a big front window, "FLIGHT OFFICE" sign, a bench out front |
| `fuel_pump_avgas` | Vintage round-top 1950s fuel pump, red and cream paint, hose and nozzle, chipped enamel |
| `fuel_truck` | Small 1950s airport fuel truck, rounded cab, cylindrical tank, hose reel |
| `windsock` | Orange-and-white striped windsock on a thin metal pole |
| `beacon_tower` | Small steel lattice tower with a green-and-white rotating airport beacon on top |
| `runway_light` | Short runway edge light: stake base and a small glass dome |
| `wheel_chocks` | Pair of yellow wooden wheel chocks joined by a rope |
| `tiedown` | Concrete tie-down block with a steel ring and rope |

## B. Hangar interior (priority 1)
| Name | Prompt |
|---|---|
| `toolbox_rolling` | Red rolling mechanic's toolbox, many drawers, stickers, scuffed paint |
| `workbench` | Heavy wooden workbench with a bench vise, a drawer, oil stains, tools on top |
| `pegboard_wall` | Pegboard wall section full of wrenches, hammers and pliers outlines |
| `parts_shelf` | Steel shelf unit with cardboard parts boxes, tires and oil cans |
| `engine_stand` | Small aircraft piston engine on a red engine stand |
| `engine_hoist` | Yellow shop engine hoist with a chain |
| `air_compressor` | Old upright air compressor tank with a hose |
| `oil_drum` | 55-gallon oil drum, faded blue, dented |
| `jerry_can` | Olive-drab metal jerry can |
| `step_ladder` | Paint-splattered wooden step ladder |
| `creeper` | Mechanic's rolling creeper board |

## C. Small town and roadside (priority 2)
| Name | Prompt |
|---|---|
| `gas_station` | 1950s small-town gas station, white with a red stripe, two service bays, a canopy, two pumps |
| `garage_brick` | Old brick auto garage, big wooden doors, faded painted "GARAGE" sign |
| `general_store` | Two-story wood general store with a porch, signs and a soda machine |
| `water_tower` | Small-town water tower on steel legs, a blank tank for the town name |
| `grain_elevator` | Wooden prairie grain elevator, tall and weathered |
| `barn_red` | Big weathered red barn with a gambrel roof and hayloft door |
| `farmhouse` | White two-story farmhouse with a porch |
| `grain_bin` | Corrugated galvanized grain bin |
| `pickup_truck` | 1960s pickup truck, faded paint, dented |
| `tractor` | Old red farm tractor |
| `utility_pole` | Wooden utility pole with crossbar and insulators |
| `street_lamp` | Old sodium street lamp on a wooden pole |
| `mailbox` | Rural mailbox on a wooden post |
| `fence_rail` | 4 m section of split-rail wooden fence |
| `fence_gate` | Metal farm gate |
| `hay_bale_round` | Round hay bale |
| `billboard` | Wooden roadside billboard frame with a blank face |

## D. Nature (2 or 3 variants each: `_a`, `_b`, `_c`)
| Name | Prompt | Region |
|---|---|---|
| `tree_oak` | Broad spreading oak tree, full canopy | Plains |
| `tree_cottonwood` | Tall cottonwood, light green leaves | Plains, river |
| `tree_pine` | Tall ponderosa pine | Forest |
| `tree_pine_snow` | Snow-covered spruce | Snow |
| `tree_birch` | White birch cluster | Forest |
| `tree_dead` | Bare dead tree, gray wood | Any |
| `stump` / `log` | Tree stump / fallen log with moss | Forest |
| `bush` | Round green shrub | Any |
| `sagebrush` | Gray-green sagebrush clump | Desert |
| `cactus_saguaro` | Saguaro cactus with arms | Desert |
| `cactus_prickly` | Prickly pear cactus | Desert |
| `rock` | Weathered boulder | Any |
| `cliff` | Layered rock cliff chunk, 10 m | Desert, mountains |
| `cattails` | Cattail and reed clump | Lakes |
| `mountain` | Distant mountain, simple shape, snow cap | Backdrop |

## E. Lakes and landmarks (priority 3)
| Name | Prompt |
|---|---|
| `dock` | Wooden lake dock with posts |
| `rowboat` | Old wooden rowboat, peeling paint |
| `fire_lookout` | Wooden fire lookout tower with a cabin on top |
| `cabin` | Small log cabin with a stone chimney |

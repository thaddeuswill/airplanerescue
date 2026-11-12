# Airplane Rescue · Job Art Kit

Art for 25 maintenance and troubleshooting jobs on the Cub. Every piece is a loose PNG, so you can place it wherever it works best in the scene. The positions below are where I'd put them, not a requirement.

## What's in here

| Folder | Contents |
|---|---|
| `backgrounds/` | One 1000 x 560 background per job, no transparency. The right-hand strip (x 828 to 988) is left for the game's bench/tool tray. |
| `jobs/<job>/` | The loose pieces for that job, trimmed tight, transparent PNG, soft drop shadow baked in. |
| `reference/` | `_start` and `_end` mockups (half size) showing how I pictured each job before and after. Use them as a guide, not as game assets. |

## How the pieces work

**Scale.** Everything is drawn at 1:1 for a 1000 x 560 scene. If you scale the scene, scale the pieces by the same amount. Scaling one piece on its own works, but stay between about 0.8 and 1.25 so the line weight still matches.

**State pairs swap in place.** Files that differ only by their last word, like `_old`/`_new`, `_dirty`/`_clean`, `_off`/`_on`, `_slack`/`_set` or `_bubbles`/`_clear`, are trimmed to the same box. Put one sprite at the position, then change its texture and nothing jumps.
Example: in fuel_strainer, `fuel_strainer_bowl_old.png` and `fuel_strainer_bowl_new.png` are both 80 x 112 with the same center. A single `Sprite2D` handles the swap with `texture = preload(".../bowl_new.png")`.

**Light comes from the upper left.** Shadows fall down and to the right. If you add your own pieces or shadows, match that.

**Fasteners aren't drawn in.** Covers, plates and cowls show empty screw holes. Put your fastener nodes on those holes.

**Layer order**, back to front:
1. background
2. old or faulty parts
3. hoses and wires
4. covers, cowl and plates
5. tools the player is holding

## Godot setup that keeps it crisp

- Import: Filter **Linear**, Mipmaps **off**, Compress **Lossless**.
- `Sprite2D` with `centered = true`. Set `position` to the suggested center below.
- Click zones: an `Area2D` with a `RectangleShape2D` the size of the piece, slightly inset, works well. For hoses and wires, a `CapsuleShape2D` or a polygon feels better.
- Pieces used in several spots (spark, quart cans, dehydrator plugs) are a single file listed once per spot. Instance it and move each copy.

## Shared art between jobs

- `oil_change` reuses the oil_screen screens. When the player pulls the screen, the oil_screen job can follow right after.
- `aileron_rigging` and `trim_cable` share the turnbuckles, safety wire and plate from the rudder cable job.
- `mag_timing` uses the hot_mag accessory case. `baffles` uses the bird-nest top view.
- `storage` ends by handing off to `pre_oil`.

---

## Spark test (find the dead lead)
`jobs/spark_test/` · mockups: `reference/spark_test_start.png`, `reference/spark_test_end.png`

**Flow**

1. Cowl off.
2. Pull each top plug, leave the lead on, lay the plug on the crankcase.
3. Player turns the prop; show `spark` at each plug that fires. The one with no spark has a bad lead.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/spark_test_bg.png` | 1000 x 560 | fills the scene | Engine left side, cowling off, the four top plug holes empty and the leads hanging down to the crankcase |
| `spark_test_plug0.png` | 138 x 48 | 181, 320 | Plug 1 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `spark_test_plug1.png` | 138 x 48 | 351, 320 | Plug 2 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `spark_test_plug2.png` | 138 x 48 | 521, 320 | Plug 3 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `spark_test_plug3.png` | 138 x 48 | 691, 320 | Plug 4 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `spark_test_spark.png` | 50 x 50 | 247, 320 | Spark at plug 1's electrodes (shown only on the ones that fire) |
| `spark_test_spark.png` | 50 x 50 | 417, 320 | Spark at plug 2's electrodes (shown only on the ones that fire) |
| `spark_test_spark.png` | 50 x 50 | 587, 320 | Spark at plug 3's electrodes (shown only on the ones that fire) |
| `spark_test_spark.png` | 50 x 50 | 757, 320 | Spark at plug 4's electrodes (shown only on the ones that fire) |
| `spark_test_cowl.png` | 756 x 296 | 420, 190 | Cowling (same as the other engine scenes) |

## Cold cylinder check
`jobs/cold_cylinder/` · mockups: `reference/cold_cylinder_start.png`, `reference/cold_cylinder_end.png`

**Flow**

1. Cowl off.
2. Pick up the grease pencil, mark each exhaust stack (`mark`).
3. Short engine run, then swap each mark to `melted` except the cold cylinder.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/cold_cylinder_bg.png` | 1000 x 560 | fills the scene | Engine left side with the four exhaust stacks running down through the lower cowl |
| `cold_cylinder_mark.png` | 53 x 24 | 180, 416 | Grease-pencil mark on stack 1 (before the run) |
| `cold_cylinder_melted.png` | 53 x 24 | 180, 416 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `cold_cylinder_mark.png` | 53 x 24 | 350, 416 | Grease-pencil mark on stack 2 (before the run) |
| `cold_cylinder_melted.png` | 53 x 24 | 350, 416 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `cold_cylinder_mark.png` | 53 x 24 | 520, 416 | Grease-pencil mark on stack 3 (before the run) |
| `cold_cylinder_melted.png` | 53 x 24 | 520, 416 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `cold_cylinder_mark.png` | 53 x 24 | 690, 416 | Grease-pencil mark on stack 4 (before the run) |
| `cold_cylinder_melted.png` | 53 x 24 | 690, 416 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `cold_cylinder_pencil.png` | 125 x 14 | 664, 515 | Grease pencil lying on the lower cowl, picked up to mark the stacks |
| `cold_cylinder_cowl.png` | 756 x 296 | 420, 190 | Cowling |

## Compression test
`jobs/compression/` · mockups: `reference/compression_start.png`, `reference/compression_end.png`

**Flow**

1. Cowl off, hose on cylinder 1.
2. Show the tester gauge, `good` or `low`.
3. On a low cylinder, play the hiss at one spot: exhaust = exhaust valve, air filter = intake valve, oil filler = rings.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/compression_bg.png` | 1000 x 560 | fills the scene | Engine left side with the air filter, exhaust outlet and oil filler showing, top plug of cylinder 1 out |
| `compression_tester_good.png` | 216 x 142 | 692, 449 | Differential compression tester, 80 in / 76 held (healthy cylinder) |
| `compression_tester_low.png` | 216 x 142 | 692, 449 | Differential compression tester, 80 in / 48 held (leaking cylinder) |
| `compression_hose.png` | 404 x 124 | 374, 318 | Tester hose from cylinder 1's plug hole to the tester (comes off between cylinders) |
| `compression_hiss.png` | 50 x 60 | 777, 482 | Air you hear at the exhaust: exhaust valve |
| `compression_hiss.png` | 50 x 60 | 249, 430 | Air you hear at the air filter: intake valve |
| `compression_hiss.png` | 50 x 60 | 485, 96 | Air you hear at the oil filler: rings |
| `compression_cowl.png` | 756 x 296 | 420, 190 | Cowling |

## Reading plugs
`jobs/reading_plugs/` · mockups: `reference/reading_plugs_start.png`, `reference/reading_plugs_end.png`

**Flow**

1. Plugs go in the tray by cylinder and top/bottom.
2. Player compares each to the chart.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/reading_plugs_bg.png` | 1000 x 560 | fills the scene | Workbench with a numbered plug tray (top and bottom row, cylinders 1 to 4) and a plug-reading chart |
| `reading_plugs_tan.png` | 96 x 100 | 162, 210 | Top plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 162, 210 | Top plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 162, 210 | Top plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 162, 210 | Top plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 277, 210 | Top plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 277, 210 | Top plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 277, 210 | Top plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 277, 210 | Top plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 392, 210 | Top plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 392, 210 | Top plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 392, 210 | Top plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 392, 210 | Top plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 507, 210 | Top plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 507, 210 | Top plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 507, 210 | Top plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 507, 210 | Top plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 162, 360 | Bottom plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 162, 360 | Bottom plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 162, 360 | Bottom plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 162, 360 | Bottom plug, cylinder 1: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 277, 360 | Bottom plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 277, 360 | Bottom plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 277, 360 | Bottom plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 277, 360 | Bottom plug, cylinder 2: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 392, 360 | Bottom plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 392, 360 | Bottom plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 392, 360 | Bottom plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 392, 360 | Bottom plug, cylinder 3: firing end, any of the four conditions |
| `reading_plugs_tan.png` | 96 x 100 | 507, 360 | Bottom plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_black.png` | 96 x 100 | 507, 360 | Bottom plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_oily.png` | 96 x 100 | 507, 360 | Bottom plug, cylinder 4: firing end, any of the four conditions |
| `reading_plugs_eroded.png` | 96 x 100 | 507, 360 | Bottom plug, cylinder 4: firing end, any of the four conditions |

## Oil screen inspection
`jobs/oil_screen/` · mockups: `reference/oil_screen_start.png`, `reference/oil_screen_end.png`

**Flow**

1. Screen starts `dirty`; rinsing in the pan swaps it to `clean`.
2. Whatever metal the fault calls for lands on the towel.
3. Magnet test: steel sticks (`magnet_steel`), aluminum and bronze don't.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/oil_screen_bg.png` | 1000 x 560 | fills the scene | Workbench with a solvent pan, a white shop towel and a card on what the metal means |
| `oil_screen_screen_dirty.png` | 234 x 66 | 201, 255 | Oil suction screen as it came out: sludge and flakes |
| `oil_screen_screen_clean.png` | 234 x 66 | 201, 255 | Oil suction screen rinsed clean |
| `oil_screen_metal_steel.png` | 170 x 79 | 522, 358 | Steel particles rinsed out onto the towel |
| `oil_screen_metal_aluminum.png` | 170 x 79 | 522, 358 | Aluminum particles rinsed out onto the towel |
| `oil_screen_metal_bronze.png` | 170 x 79 | 522, 358 | Bronze particles rinsed out onto the towel |
| `oil_screen_magnet_bare.png` | 114 x 64 | 722, 418 | Magnet before |
| `oil_screen_magnet_steel.png` | 114 x 64 | 722, 418 | Magnet with steel stuck to it |

## Hot mag (broken P-lead)
`jobs/hot_mag/` · mockups: `reference/hot_mag_start.png`, `reference/hot_mag_end.png`

**Flow**

1. Hang the DANGER tag on the prop first.
2. Cowl off, find the `plead_old`, replace with `plead_new`.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/hot_mag_bg.png` | 1000 x 560 | fills the scene | Rear accessory case with the left magneto installed; its P-lead terminal (the switch ground) is empty |
| `hot_mag_plead_old.png` | 294 x 47 | 657, 200 | P-lead from the mag to the ignition switch: chafed through and broken off |
| `hot_mag_plead_new.png` | 294 x 47 | 657, 200 | P-lead from the mag to the ignition switch: new, nut on the terminal |
| `hot_mag_tag.png` | 110 x 150 | 145, 195 | Red DANGER tag: hang it on the prop as soon as the mag check shows no drop |
| `hot_mag_cowl.png` | 756 x 296 | 420, 190 | Cowling |

## Plugged fuel vent
`jobs/fuel_vent/` · mockups: `reference/fuel_vent_start.png`, `reference/fuel_vent_end.png`

**Flow**

1. Pull the nest, run a wire through, wipe the crumbs.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/fuel_vent_bg.png` | 1000 x 560 | fills the scene | Close-up of the Cub's fuel cap on the nose deck, its vent tube pointing forward |
| `fuel_vent_nest.png` | 112 x 82 | 554, 164 | Mud dauber nest plugging the vent tube (pull it, then run a wire through) |
| `fuel_vent_crumbs.png` | 286 x 32 | 551, 351 | Dried mud crumbs on the deck to wipe away |

## Water in the fuel
`jobs/water_fuel/` · mockups: `reference/water_fuel_start.png`, `reference/water_fuel_end.png`

**Flow**

1. Sump the drain into the tester cup: `water` or `clean`.
2. Dump the cup (spill shows on the gravel), repeat until clean.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/water_fuel_bg.png` | 1000 x 560 | fills the scene | Under the nose: the gascolator bowl and its drain, gear legs either side |
| `water_fuel_cup_water.png` | 80 x 176 | 430, 358 | Fuel tester under the drain: blue avgas over a clear water layer, beads sinking |
| `water_fuel_cup_clean.png` | 80 x 176 | 430, 358 | Fuel tester under the drain: all blue, no water |
| `water_fuel_spill.png` | 300 x 31 | 430, 500 | Sumped fuel splashed on the gravel |

## Oil change with screen check
`jobs/oil_change/` · mockups: `reference/oil_change_start.png`, `reference/oil_change_end.png`

**Flow**

1. Slide the pan under. Cut the safety wire, pull the drain `plug`, show `stream` while it drains.
2. Pull the suction screen (`screen_old`), send it to the oil_screen job, put back `screen_new`.
3. Plug back in and re-safetied. Pour the four `quart` cans at the filler.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/oil_change_bg.png` | 1000 x 560 | fills the scene | Engine bay with the lower cowl off: sump, drain boss, suction screen housing and the oil filler; concrete floor below |
| `oil_change_plug.png` | 44 x 42 | 427, 414 | Drain plug, safety-wired (cut the wire, then out) |
| `oil_change_stream.png` | 9 x 70 | 420, 460 | Old black oil pouring out (shows while it drains) |
| `oil_change_pan.png` | 280 x 80 | 420, 516 | Drain pan slid under the engine |
| `oil_change_screen_old.png` | 234 x 66 | 681, 340 | Oil suction screen as it comes out (send it to the oil screen check) |
| `oil_change_screen_new.png` | 234 x 66 | 681, 340 | Oil suction screen back in, cleaned |
| `oil_change_quart.png` | 69 x 100 | 76, 410 | Quart 1 of aviation oil, poured in at the filler |
| `oil_change_quart.png` | 69 x 100 | 140, 410 | Quart 2 of aviation oil, poured in at the filler |
| `oil_change_quart.png` | 69 x 100 | 204, 410 | Quart 3 of aviation oil, poured in at the filler |
| `oil_change_quart.png` | 69 x 100 | 268, 410 | Quart 4 of aviation oil, poured in at the filler |

## Fuel strainer (gascolator)
`jobs/fuel_strainer/` · mockups: `reference/fuel_strainer_start.png`, `reference/fuel_strainer_end.png`

**Flow**

1. Cut the `wire`, loosen the `nut`, drop the bail.
2. Bowl and screen come off as `old`; clean them, they go back as `new`.
3. Nut tight, new safety wire.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/fuel_strainer_bg.png` | 1000 x 560 | fills the scene | Firewall with the gascolator head, fuel lines in and out, and its wire bail hanging empty |
| `fuel_strainer_bowl_old.png` | 80 x 112 | 490, 300 | Glass sediment bowl with water and grit in the bottom |
| `fuel_strainer_bowl_new.png` | 80 x 112 | 490, 300 | Glass sediment bowl clean, fresh fuel |
| `fuel_strainer_screen_old.png` | 68 x 38 | 490, 269 | Strainer screen caked with rust and grit |
| `fuel_strainer_screen_new.png` | 68 x 38 | 490, 269 | Strainer screen rinsed |
| `fuel_strainer_nut.png` | 34 x 26 | 490, 377 | Bail thumb nut holding the bowl up |
| `fuel_strainer_wire.png` | 46 x 34 | 535, 364 | Safety wire from the nut to the bail (cut off, then put back) |

## Brake bleed (expander tube brakes)
`jobs/brake_bleed/` · mockups: `reference/brake_bleed_start.png`, `reference/brake_bleed_end.png`

**Flow**

1. Pop the `cap` off the bleeder, fit the `hose` into the jar.
2. Open the bleeder and pump: jar shows `jar_bubbles` until it runs `jar_clear`.
3. Close the bleeder, cap on, top up from the `can`.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/brake_bleed_bg.png` | 1000 x 560 | fills the scene | Inside of the left main wheel: Goodyear-style expander-tube brake with its bleeder valve at the top, line running up the gear leg |
| `brake_bleed_cap.png` | 22 x 24 | 414, 216 | Rubber dust cap on the bleeder |
| `brake_bleed_hose.png` | 143 x 190 | 486, 301 | Clear bleed hose from the bleeder down into the jar, bubbles in the red fluid |
| `brake_bleed_jar_bubbles.png` | 90 x 116 | 555, 448 | Catch jar still full of bubbles |
| `brake_bleed_jar_clear.png` | 90 x 116 | 555, 448 | Catch jar running clear, no air |
| `brake_bleed_can.png` | 87 x 124 | 706, 448 | Can of red hydraulic fluid for topping up the reservoir |

## Bungee cords
`jobs/bungee/` · mockups: `reference/bungee_start.png`, `reference/bungee_end.png`

**Flow**

1. Player reads the color threads on each cord against the card.
2. Old cords come off, new ones go on with the bungee `tool` (both sides).

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/bungee_bg.png` | 1000 x 560 | fills the scene | Left main gear from the side: vee legs, shock strut, the fixed and sliding bungee spools with no cords on them, color-code card |
| `bungee_cord_old.png` | 73 x 136 | 408, 195 | Bungee cord rings around both spools (old: faded red-and-green threads, cracked cover, broken strands) |
| `bungee_cord_new.png` | 73 x 136 | 408, 195 | Bungee cord rings around both spools (new: blue-and-yellow threads, tight) |
| `bungee_tool.png` | 219 x 57 | 190, 502 | Bungee stretching tool lying on the gravel (needed to get new rings over the spools) |

## Tailwheel service
`jobs/tailwheel/` · mockups: `reference/tailwheel_start.png`, `reference/tailwheel_end.png`

**Flow**

1. Inspect `leaf_old` (cracked) and `steer_old` (stretched); replace with `_new`.
2. Wipe the `grime` off the fitting, grease with the `gun`.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/tailwheel_bg.png` | 1000 x 560 | fills the scene | Cub tail from the left: leaf-spring mount under the sternpost, rudder steering horn, tailwheel head, fork and wheel, grease fitting on the head |
| `tailwheel_leaf_old.png` | 128 x 66 | 646, 355 | Tailwheel leaf spring, mount to the tailwheel head (cracked top leaf, rusty) |
| `tailwheel_leaf_new.png` | 128 x 66 | 646, 355 | Tailwheel leaf spring, mount to the tailwheel head (new) |
| `tailwheel_steer_old.png` | 56 x 31 | 686, 358 | Steering spring and chain, rudder horn to tailwheel arm (stretched open, rusty) |
| `tailwheel_steer_new.png` | 56 x 31 | 686, 358 | Steering spring and chain, rudder horn to tailwheel arm (new) |
| `tailwheel_grime.png` | 33 x 21 | 706, 386 | Old dried grease and grit over the grease fitting |
| `tailwheel_gun.png` | 219 x 53 | 460, 500 | Grease gun on the gravel |

## Aileron/elevator cable rigging
`jobs/aileron_rigging/` · mockups: `reference/aileron_rigging_start.png`, `reference/aileron_rigging_end.png`

**Flow**

1. Plate off. Clamp the tensiometer: reads `tensio_slack`.
2. Cut the turnbuckle `wire_a/_b`, turn the `tb_a/_b` until it reads `tensio_set`.
3. New safety wire, plate on. Swap `cable_old` for `cable_new` if it's frayed.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/aileron_rigging_bg.png` | 1000 x 560 | fills the scene | Underside of the left wing root with the inspection plate off: spruce ribs, pulleys, aileron cable run |
| `aileron_rigging_plate.png` | 658 x 318 | 410, 270 | Inspection plate (same as the rudder cable job) |
| `aileron_rigging_cable_old.png` | 620 x 14 | 410, 262 | Aileron cable slack and frayed |
| `aileron_rigging_cable_new.png` | 620 x 14 | 410, 262 | Aileron cable new |
| `aileron_rigging_tb_a.png` | 120 x 34 | 240, 264 | Turnbuckle (turn to set tension) |
| `aileron_rigging_wire_a.png` | 102 x 24 | 246, 261 | Turnbuckle safety wire |
| `aileron_rigging_tb_b.png` | 120 x 34 | 580, 264 | Turnbuckle (turn to set tension) |
| `aileron_rigging_wire_b.png` | 102 x 24 | 586, 261 | Turnbuckle safety wire |
| `aileron_rigging_tensio_slack.png` | 196 x 98 | 432, 255 | Tensiometer clamped on the cable reading 12 lb (too slack) |
| `aileron_rigging_tensio_set.png` | 196 x 98 | 432, 255 | Tensiometer clamped on the cable reading 30 lb (in range) |

## Trim cable tension
`jobs/trim_cable/` · mockups: `reference/trim_cable_start.png`, `reference/trim_cable_end.png`

**Flow**

1. Plate off. The cable is `cable_old` (someone oiled it): clean it to `cable_new`.
2. The `oilcan` is the trap: using it fails the job.
3. Set tension on the turnbuckles, check with the `tensio`.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/trim_cable_bg.png` | 1000 x 560 | fills the scene | Tail cone with the inspection plate off: the stabilizer trim jackscrew drum, pulleys and cable run |
| `trim_cable_plate.png` | 658 x 318 | 410, 270 | Inspection plate |
| `trim_cable_cable_old.png` | 620 x 8 | 410, 262 | Trim cable someone oiled it: gummed with grit, slipping on the drum |
| `trim_cable_cable_new.png` | 620 x 8 | 410, 262 | Trim cable clean and dry |
| `trim_cable_tb_a.png` | 120 x 34 | 240, 264 | Turnbuckle |
| `trim_cable_tb_b.png` | 120 x 34 | 580, 264 | Turnbuckle |
| `trim_cable_oilcan.png` | 105 x 99 | 682, 456 | Oil can with a NO sign: the trap. Trim cables stay dry |
| `trim_cable_tensio.png` | 196 x 98 | 432, 355 | Tensiometer on the trim cable |

## Exhaust and heat shroud check
`jobs/exhaust_check/` · mockups: `reference/exhaust_check_start.png`, `reference/exhaust_check_end.png`

**Flow**

1. Pull the `scat` hose and the `shroud`.
2. Look for `muffler_old` (crack with a gray stain). Replace with `muffler_new`, shroud and hose back on.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/exhaust_check_bg.png` | 1000 x 560 | fills the scene | Engine bay from below: both exhaust risers into the muffler, cabin heat box on the right; shroud off |
| `exhaust_check_muffler_old.png` | 280 x 70 | 420, 420 | Muffler cracked, gray exhaust stain around the crack |
| `exhaust_check_muffler_new.png` | 280 x 70 | 420, 420 | Muffler new |
| `exhaust_check_shroud.png` | 316 x 129 | 422, 424 | Cabin heat shroud wrapped around the muffler (comes off to look) |
| `exhaust_check_scat.png` | 220 x 45 | 630, 378 | SCAT hose from the shroud to the cabin heat box |

## Air filter and carb heat box
`jobs/air_filter/` · mockups: `reference/air_filter_start.png`, `reference/air_filter_end.png`

**Flow**

1. Cover off, `filter_old` out, `filter_new` in.
2. Check the carb heat `flapper`: if it's `_old`, replace it. Cover back on.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/air_filter_bg.png` | 1000 x 560 | fills the scene | Carb heat box below the engine: filter opening on the left, valve chamber on the right, duct to the carb |
| `air_filter_filter_old.png` | 202 x 92 | 375, 400 | Air filter clogged with dirt and bugs |
| `air_filter_filter_new.png` | 202 x 92 | 375, 400 | Air filter new |
| `air_filter_cover.png` | 240 x 140 | 375, 400 | Filter cover grille, four screws |
| `air_filter_flapper_old.png` | 92 x 73 | 559, 402 | Carb heat valve flapper worn and loose, corner gone |
| `air_filter_flapper_new.png` | 92 x 73 | 559, 402 | Carb heat valve flapper new |

## Magneto timing
`jobs/mag_timing/` · mockups: `reference/mag_timing_start.png`, `reference/mag_timing_end.png`

**Flow**

1. Cowl off, clip on the `leads`.
2. Turn the prop toward 28° BTC (C-85) on the `marks`. The `light` goes from `off` to `on` when the points open.
3. If it lights early or late, loosen the mag and rotate it, then check again.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/mag_timing_bg.png` | 1000 x 560 | fills the scene | Rear accessory case with the left magneto, a timing window over the starter ring gear |
| `mag_timing_light_off.png` | 150 x 100 | 195, 160 | Timing light, lamps dark |
| `mag_timing_light_on.png` | 150 x 100 | 195, 160 | Timing light, left lamp lit: points just opened |
| `mag_timing_leads.png` | 320 x 52 | 428, 190 | Timing light clips: one to the magneto P-lead, one to ground |
| `mag_timing_marks.png` | 260 x 40 | 260, 280 | Degree marks; bring the pointer to 28° BTC (C-85) while turning the prop |
| `mag_timing_cowl.png` | 756 x 296 | 420, 190 | Cowling |

## Dressing a prop nick (metal props only)
`jobs/prop_dress/` · mockups: `reference/prop_dress_start.png`, `reference/prop_dress_end.png`

**Flow**

1. File across the `nick` until it becomes the `dressed` scallop.
2. Finish with `emery`. A nick too deep means the prop is scrapped.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/prop_dress_bg.png` | 1000 x 560 | fills the scene | Metal prop blade (other plane types) on the bench, leading edge toward the viewer |
| `prop_dress_nick.png` | 61 x 25 | 460, 208 | Stone nick bitten into the leading edge |
| `prop_dress_dressed.png` | 160 x 10 | 460, 201 | The blended, polished scallop left after dressing |
| `prop_dress_file.png` | 240 x 28 | 490, 154 | Fine flat file |
| `prop_dress_emery.png` | 109 x 63 | 700, 156 | Emery cloth |

## Prop tracking
`jobs/prop_track/` · mockups: `reference/prop_track_start.png`, `reference/prop_track_end.png`

**Flow**

1. Set the `block` under the tip. Blade A down: pencil `mark_a`.
2. Rotate, blade B down: `mark_b`. Apart by more than 1/16 inch means out of track.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/prop_track_bg.png` | 1000 x 560 | fills the scene | Cub nose from the left side, prop hub at the left of the cowl, gravel apron below |
| `prop_track_blade_a.png` | 33 x 319 | 532, 320 | Blade A pointing straight down, at the block |
| `prop_track_blade_b.png` | 33 x 319 | 532, 320 | Blade B pointing straight down, at the block |
| `prop_track_block.png` | 118 x 114 | 533, 533 | Wood block set just under the tip, white tape on top to mark |
| `prop_track_mark_a.png` | 16 x 4 | 513, 482 | Pencil mark where blade A's tip passed (more than 1/16" apart = out of track) |
| `prop_track_mark_b.png` | 16 x 4 | 523, 482 | Pencil mark where blade B's tip passed (more than 1/16" apart = out of track) |

## Wing rigging
`jobs/wing_rig/` · mockups: `reference/wing_rig_start.png`, `reference/wing_rig_end.png`

**Flow**

1. Stretch the `string` tip to tip, read the `ruler` at the root (dihedral).
2. `block` and `level` on the tip rib (wash-out).
3. Out of spec: turn the strut `fork` in or out (`fork_old` has a rusted jam nut, swap it).

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/wing_rig_bg.png` | 1000 x 560 | fills the scene | Cub head-on in the hangar: both wings showing dihedral, struts with their forks at the wing, gear, prop vertical |
| `wing_rig_string.png` | 800 x 18 | 410, 115 | String stretched tip to tip, just above the wing tips |
| `wing_rig_ruler.png` | 18 x 56 | 471, 126 | Ruler at the wing root, reading the string-to-wing gap |
| `wing_rig_level.png` | 152 x 24 | 720, 86 | Level on the tip block (bubble off center = wash-out out of spec) |
| `wing_rig_block.png` | 52 x 22 | 720, 113 | Rigging block on the tip rib |
| `wing_rig_fork_old.png` | 20 x 42 | 167, 143 | Left front strut fork at the wing, threaded in or out to set the angle (jam nut rusted) |
| `wing_rig_fork_old.png` | 20 x 42 | 653, 143 | Right front strut fork at the wing, threaded in or out to set the angle (jam nut rusted) |
| `wing_rig_fork_new.png` | 20 x 42 | 167, 143 | Left front strut fork at the wing, threaded in or out to set the angle (set and jammed) |
| `wing_rig_fork_new.png` | 20 x 42 | 653, 143 | Right front strut fork at the wing, threaded in or out to set the angle (set and jammed) |

## Tail brace wires
`jobs/brace_wires/` · mockups: `reference/brace_wires_start.png`, `reference/brace_wires_end.png`

**Flow**

1. Check `upper` and `lower`. `_old` are bowed and rusty. Replace with `_new` and set tension.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/brace_wires_bg.png` | 1000 x 560 | fills the scene | Cub tail from the left: the fin, stabilizer and fuselage fittings where the brace wires attach |
| `brace_wires_upper_old.png` | 153 x 183 | 630, 176 | Upper brace wire bowed, loose and rusty |
| `brace_wires_lower_old.png` | 233 x 83 | 590, 296 | Lower brace wire bowed, loose and rusty |
| `brace_wires_upper_new.png` | 153 x 183 | 630, 176 | Upper brace wire new, tight |
| `brace_wires_lower_new.png` | 233 x 83 | 590, 296 | Lower brace wire new, tight |

## Cooling baffles and fins
`jobs/baffles/` · mockups: `reference/baffles_start.png`, `reference/baffles_end.png`

**Flow**

1. Clean the `packed` dirt out of the fins (4 spots).
2. Replace torn `seal_old` with `seal_new` (2 spots).

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/baffles_bg.png` | 1000 x 560 | fills the scene | Engine from the top, cowling off (same view as the bird-nest job) |
| `baffles_seal_old.png` | 18 x 270 | 294, 205 | Baffle seal torn: cooling air leaks past the cylinders |
| `baffles_seal_old.png` | 18 x 270 | 554, 205 | Baffle seal torn: cooling air leaks past the cylinders |
| `baffles_seal_new.png` | 18 x 270 | 294, 205 | Baffle seal new |
| `baffles_seal_new.png` | 18 x 270 | 554, 205 | Baffle seal new |
| `baffles_packed.png` | 212 x 102 | 170, 135 | Dirt, straw and bugs packed between the cooling fins |
| `baffles_packed.png` | 212 x 102 | 170, 265 | Dirt, straw and bugs packed between the cooling fins |
| `baffles_packed.png` | 212 x 102 | 670, 135 | Dirt, straw and bugs packed between the cooling fins |
| `baffles_packed.png` | 212 x 102 | 670, 265 | Dirt, straw and bugs packed between the cooling fins |

## Chafed wire splice
`jobs/wire_chafe/` · mockups: `reference/wire_chafe_start.png`, `reference/wire_chafe_end.png`

**Flow**

1. Find `wire_old` (bare copper at the bracket), splice in `wire_new`.
2. Add the cushioned `clamp` so it can't rub again.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/wire_chafe_bg.png` | 1000 x 560 | fills the scene | Behind the panel: a wiring harness passing a bracket; one white wire's middle run is the piece being replaced |
| `wire_chafe_wire_old.png` | 320 x 14 | 400, 257 | White wire chafed through to bare copper where it rubs the bracket |
| `wire_chafe_wire_new.png` | 320 x 14 | 400, 257 | White wire spliced in with two heat-shrink butt splices |
| `wire_chafe_clamp.png` | 59 x 49 | 370, 270 | Cushioned clamp that holds the harness off the bracket (missing before) |

## Engine out of storage
`jobs/storage/` · mockups: `reference/storage_start.png`, `reference/storage_end.png`

**Flow**

1. Read the yellow `tag`. Pull the `bag_intake` and `bag_exhaust` desiccant bags.
2. Cowl off, pull the four `dehy` plugs, wipe the preservative `oil`.
3. Then hand off to the pre_oil job before first start.

**Pieces** (suggested center on the 1000 x 560 scene; a file listed twice is placed twice)

| File | Size | Suggested center (x, y) | What it is |
|---|---|---|---|
| `backgrounds/storage_bg.png` | 1000 x 560 | fills the scene | Engine left side, cowling off, harness leads hanging, intake and exhaust openings at the bottom |
| `storage_dehy.png` | 50 x 72 | 180, 244 | Blue dehydrator plug in cylinder 1 (pull all four) |
| `storage_dehy.png` | 50 x 72 | 350, 244 | Blue dehydrator plug in cylinder 2 (pull all four) |
| `storage_dehy.png` | 50 x 72 | 520, 244 | Blue dehydrator plug in cylinder 3 (pull all four) |
| `storage_dehy.png` | 50 x 72 | 690, 244 | Blue dehydrator plug in cylinder 4 (pull all four) |
| `storage_bag_intake.png` | 160 x 100 | 140, 420 | Desiccant bag taped into the intake, red REMOVE BEFORE FLIGHT streamer |
| `storage_bag_exhaust.png` | 130 x 100 | 721, 470 | Desiccant bag taped into the exhaust, red REMOVE BEFORE FLIGHT streamer |
| `storage_tag.png` | 110 x 144 | 495, 458 | Yellow preservation tag hung on the engine (read it first) |
| `storage_oil.png` | 500 x 33 | 410, 312 | Sticky preservative oil weeping down the crankcase, to wipe off |
| `storage_cowl.png` | 756 x 296 | 420, 190 | Cowling |

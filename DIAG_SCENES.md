# Troubleshooting scene art

Same rules as WORK_SCENES.md: 1000 x 560 canvas, each piece at the size and position below, PNG with transparency except backgrounds.
Files that appear more than once (the plug, spark, grease marks, hiss) are one image placed several times.

## spark_test

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/spark_test_bg.png` | 1000 x 560 | 0, 0 | Engine left side, cowling off, the four top plug holes empty and the leads hanging down to the crankcase |
| `work/spark_test_plug0.png` | 140 x 60 | 110, 290 | Plug 1 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `work/spark_test_plug1.png` | 140 x 60 | 280, 290 | Plug 2 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `work/spark_test_plug2.png` | 140 x 60 | 450, 290 | Plug 3 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `work/spark_test_plug3.png` | 140 x 60 | 620, 290 | Plug 4 out of its hole, lead still on, laid on the crankcase so it's grounded |
| `work/spark_test_spark.png` | 50 x 50 | 222, 295 | Spark at plug 1's electrodes (shown only on the ones that fire) |
| `work/spark_test_spark.png` | 50 x 50 | 392, 295 | Spark at plug 2's electrodes (shown only on the ones that fire) |
| `work/spark_test_spark.png` | 50 x 50 | 562, 295 | Spark at plug 3's electrodes (shown only on the ones that fire) |
| `work/spark_test_spark.png` | 50 x 50 | 732, 295 | Spark at plug 4's electrodes (shown only on the ones that fire) |
| `work/spark_test_cowl.png` | 760 x 300 | 40, 40 | Cowling (same as the other engine scenes) |

## cold_cylinder

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/cold_cylinder_bg.png` | 1000 x 560 | 0, 0 | Engine left side with the four exhaust stacks running down through the lower cowl |
| `work/cold_cylinder_mark.png` | 60 x 40 | 150, 392 | Grease-pencil mark on stack 1 (before the run) |
| `work/cold_cylinder_melted.png` | 60 x 40 | 150, 392 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `work/cold_cylinder_mark.png` | 60 x 40 | 320, 392 | Grease-pencil mark on stack 2 (before the run) |
| `work/cold_cylinder_melted.png` | 60 x 40 | 320, 392 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `work/cold_cylinder_mark.png` | 60 x 40 | 490, 392 | Grease-pencil mark on stack 3 (before the run) |
| `work/cold_cylinder_melted.png` | 60 x 40 | 490, 392 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `work/cold_cylinder_mark.png` | 60 x 40 | 660, 392 | Grease-pencil mark on stack 4 (before the run) |
| `work/cold_cylinder_melted.png` | 60 x 40 | 660, 392 | Same mark melted (after the run; the cold cylinder keeps its _mark) |
| `work/cold_cylinder_pencil.png` | 130 x 30 | 600, 500 | Grease pencil lying on the lower cowl, picked up to mark the stacks |
| `work/cold_cylinder_cowl.png` | 760 x 300 | 40, 40 | Cowling |

## compression

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/compression_bg.png` | 1000 x 560 | 0, 0 | Engine left side with the air filter, exhaust outlet and oil filler showing, top plug of cylinder 1 out |
| `work/compression_tester_good.png` | 220 x 150 | 580, 370 | Differential compression tester, 80 in / 76 held (healthy cylinder) |
| `work/compression_tester_low.png` | 220 x 150 | 580, 370 | Differential compression tester, 80 in / 48 held (leaking cylinder) |
| `work/compression_hose.png` | 420 x 130 | 172, 252 | Tester hose from cylinder 1's plug hole to the tester (comes off between cylinders) |
| `work/compression_hiss.png` | 80 x 60 | 738, 452 | Air you hear at the exhaust: exhaust valve |
| `work/compression_hiss.png` | 80 x 60 | 210, 400 | Air you hear at the air filter: intake valve |
| `work/compression_hiss.png` | 80 x 60 | 446, 66 | Air you hear at the oil filler: rings |
| `work/compression_cowl.png` | 760 x 300 | 40, 40 | Cowling |

## reading_plugs

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/reading_plugs_bg.png` | 1000 x 560 | 0, 0 | Workbench with a numbered plug tray (top and bottom row, cylinders 1 to 4) and a plug-reading chart |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 110, 160 | Top plug, cylinder 1: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 225, 160 | Top plug, cylinder 2: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 340, 160 | Top plug, cylinder 3: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 455, 160 | Top plug, cylinder 4: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 110, 310 | Bottom plug, cylinder 1: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 225, 310 | Bottom plug, cylinder 2: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 340, 310 | Bottom plug, cylinder 3: firing end, any of the four conditions |
| `work/reading_plugs_<tan|black|oily|eroded>.png` | 100 x 100 | 455, 310 | Bottom plug, cylinder 4: firing end, any of the four conditions |

## oil_screen

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/oil_screen_bg.png` | 1000 x 560 | 0, 0 | Workbench with a solvent pan, a white shop towel and a card on what the metal means |
| `work/oil_screen_screen_dirty.png` | 240 x 110 | 80, 200 | Oil suction screen as it came out: sludge and flakes |
| `work/oil_screen_screen_clean.png` | 240 x 110 | 80, 200 | Oil suction screen rinsed clean |
| `work/oil_screen_metal_steel.png` | 200 x 110 | 420, 300 | Steel particles rinsed out onto the towel |
| `work/oil_screen_metal_aluminum.png` | 200 x 110 | 420, 300 | Aluminum particles rinsed out onto the towel |
| `work/oil_screen_metal_bronze.png` | 200 x 110 | 420, 300 | Bronze particles rinsed out onto the towel |
| `work/oil_screen_magnet_bare.png` | 120 x 70 | 660, 380 | Magnet before |
| `work/oil_screen_magnet_steel.png` | 120 x 70 | 660, 380 | Magnet with steel stuck to it |

## hot_mag

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/hot_mag_bg.png` | 1000 x 560 | 0, 0 | Rear accessory case with the left magneto installed; its P-lead terminal (the switch ground) is empty |
| `work/hot_mag_plead_old.png` | 300 x 60 | 510, 170 | P-lead from the mag to the ignition switch: chafed through and broken off |
| `work/hot_mag_plead_new.png` | 300 x 60 | 510, 170 | P-lead from the mag to the ignition switch: new, nut on the terminal |
| `work/hot_mag_tag.png` | 110 x 150 | 90, 120 | Red DANGER tag: hang it on the prop as soon as the mag check shows no drop |
| `work/hot_mag_cowl.png` | 760 x 300 | 40, 40 | Cowling |

## fuel_vent

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/fuel_vent_bg.png` | 1000 x 560 | 0, 0 | Close-up of the Cub's fuel cap on the nose deck, its vent tube pointing forward |
| `work/fuel_vent_nest.png` | 160 x 110 | 470, 100 | Mud dauber nest plugging the vent tube (pull it, then run a wire through) |
| `work/fuel_vent_crumbs.png` | 300 x 40 | 400, 330 | Dried mud crumbs on the deck to wipe away |

## water_fuel

| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/water_fuel_bg.png` | 1000 x 560 | 0, 0 | Under the nose: the gascolator bowl and its drain, gear legs either side |
| `work/water_fuel_cup_water.png` | 140 x 180 | 360, 270 | Fuel tester under the drain: blue avgas over a clear water layer, beads sinking |
| `work/water_fuel_cup_clean.png` | 140 x 180 | 360, 270 | Fuel tester under the drain: all blue, no water |
| `work/water_fuel_spill.png` | 300 x 40 | 280, 480 | Sumped fuel splashed on the gravel |

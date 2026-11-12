# Work scene art (for the art team)

The repairs are now 2D work scenes (`scripts/work.gd`). Each fault gets one fixed, flat painted view of one spot on the plane. In it you take the job apart with real tools, swap the part, clean up, and put it all back. Right now every scene runs on placeholder shapes. **Any file listed here that is dropped into `textures/work/` replaces its placeholder automatically.** No code changes are needed.

## Rules for every image
- **Style:** the same painterly rural Americana as `ART_DIRECTION.md`, in a **straight-on, flat view** with no perspective.
- **Canvas:** every scene is **1000 x 560 px**. Each piece is drawn in its own rectangle, at the size and position in the tables below, so the pieces line up with the background.
- **Files:** PNG with transparency for everything except the backgrounds. sRGB color.
- **Backgrounds** (`<scene>_bg.png`) show the spot with **every removable piece taken off**: the bare engine, the empty wheel axle, and so on. The covers and parts are layered on top.
- **The right edge (x 828 to 988)** is the workbench and magnetic tray, and the game draws it. You can paint a wooden bench strip there in the background.
- **Screws, bolts and nuts are drawn by the game** (silver heads that lift when loose). Leave their holes in the art. Optional sprites: `work/screw.png`, `work/bolt.png`, `work/nut.png`, all 24 x 24.
- **Parts have two versions:** `_old` (worn, rusty, cracked, oily) and `_new` (clean, factory fresh).
- **"Mess" images** are dirt the player clears: oil, straw, old sealant and so on. Each one disappears when its job is done.

## Tool icons
Shown on the tool roll buttons, **96 x 96 px**, transparent:

| File | Tool |
|---|---|
| `work/tool_screwdriver.png` | Flat screwdriver |
| `work/tool_ratchet.png` | Ratchet with a socket on it |
| `work/tool_torque.png` | Click-type torque wrench |
| `work/tool_pliers.png` | Safety-wire pliers |
| `work/tool_rag.png` | Red shop rag |
| `work/tool_hand.png` | Work glove (hands) |

Also wanted: a mouse cursor for each tool, **48 x 48 px**, named `work/cursor_<tool>.png`. Not wired in yet.

## Pocket icons (HUD)
Small icons in the bottom-left corner, **64 x 64 px**, transparent, in `textures/ui/` (not `work/`):

| File | What |
|---|---|
| `ui/wallet.png` | Worn leather wallet |
| `ui/clipboard.png` | Clipboard with a work order |
| `ui/logbook.png` | Pilot/mechanic logbook |

## Scenes

### propeller (Nose, head-on)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/propeller_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/propeller_prop_old.png` | 740 x 70 | 40, 245 | Propeller, worn/broken |
| `work/propeller_prop_new.png` | 740 x 70 | 40, 245 | Propeller, new |
| `work/propeller_wire.png` | 140 x 140 | 340, 210 | Safety wire (comes off) |
| `work/propeller_spinner.png` | 210 x 210 | 305, 175 | Spinner (comes off) |

### spark_plugs (Engine, left side)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/spark_plugs_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/spark_plugs_plug0_old.png` | 60 x 110 | 150, 160 | Plug 1, worn/broken |
| `work/spark_plugs_plug0_new.png` | 60 x 110 | 150, 160 | Plug 1, new |
| `work/spark_plugs_lead0.png` | 80 x 50 | 140, 130 | Lead 1 (comes off) |
| `work/spark_plugs_plug1_old.png` | 60 x 110 | 320, 160 | Plug 2, worn/broken |
| `work/spark_plugs_plug1_new.png` | 60 x 110 | 320, 160 | Plug 2, new |
| `work/spark_plugs_lead1.png` | 80 x 50 | 310, 130 | Lead 2 (comes off) |
| `work/spark_plugs_plug2_old.png` | 60 x 110 | 490, 160 | Plug 3, worn/broken |
| `work/spark_plugs_plug2_new.png` | 60 x 110 | 490, 160 | Plug 3, new |
| `work/spark_plugs_lead2.png` | 80 x 50 | 480, 130 | Lead 3 (comes off) |
| `work/spark_plugs_plug3_old.png` | 60 x 110 | 660, 160 | Plug 4, worn/broken |
| `work/spark_plugs_plug3_new.png` | 60 x 110 | 660, 160 | Plug 4, new |
| `work/spark_plugs_lead3.png` | 80 x 50 | 650, 130 | Lead 4 (comes off) |
| `work/spark_plugs_cowl.png` | 760 x 300 | 40, 40 | Cowling (comes off) |

### oil_leak (Engine, left side)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/oil_leak_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/oil_leak_gasket_old.png` | 400 x 110 | 220, 150 | Rocker cover gasket, worn/broken |
| `work/oil_leak_gasket_new.png` | 400 x 110 | 220, 150 | Rocker cover gasket, new |
| `work/oil_leak_scrape.png` | 400 x 30 | 220, 230 | Mess to clear: Scrape off the old gasket |
| `work/oil_leak_rocker.png` | 440 x 150 | 200, 130 | Rocker cover (comes off) |
| `work/oil_leak_wipe.png` | 600 x 40 | 120, 290 | Mess to clear: Wipe the oil off the engine |
| `work/oil_leak_cowl.png` | 760 x 300 | 40, 40 | Cowling (comes off) |

### bird_nest (Engine, top)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/bird_nest_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/bird_nest_straw.png` | 540 x 60 | 140, 250 | Mess to clear: Sweep out the loose straw |
| `work/bird_nest_nest.png` | 240 x 140 | 300, 110 | Mess to clear: Pull the nest out |
| `work/bird_nest_cowl.png` | 760 x 300 | 40, 40 | Cowling (comes off) |

### starter (Engine, lower left)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/starter_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/starter_starter_old.png` | 260 x 110 | 130, 200 | Starter motor, worn/broken |
| `work/starter_starter_new.png` | 260 x 110 | 130, 200 | Starter motor, new |
| `work/starter_cable.png` | 260 x 40 | 400, 230 | Starter cable (comes off) |
| `work/starter_cowl.png` | 760 x 300 | 40, 40 | Cowling (comes off) |

### magneto (Engine, rear accessory case)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/magneto_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/magneto_timing.png` | 260 x 50 | 130, 260 | Mess to clear: Set the magneto timing |
| `work/magneto_magneto_old.png` | 220 x 170 | 470, 130 | Magneto, worn/broken |
| `work/magneto_magneto_new.png` | 220 x 170 | 470, 130 | Magneto, new |
| `work/magneto_cap.png` | 160 x 70 | 500, 150 | Harness cap (comes off) |
| `work/magneto_cowl.png` | 760 x 300 | 40, 40 | Cowling (comes off) |

### tire (Left main wheel, outside)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/tire_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/tire_pump.png` | 200 x 70 | 600, 380 | Mess to clear: Pump to 35 psi to seat the beads, let down to 15 |
| `work/tire_tire_old.png` | 340 x 340 | 230, 130 | Tire & tube, worn/broken |
| `work/tire_tire_new.png` | 340 x 340 | 230, 130 | Tire & tube, new |
| `work/tire_pin.png` | 44 x 24 | 378, 260 | Cotter pin (comes off) |
| `work/tire_hubcap.png` | 140 x 140 | 330, 230 | Hubcap (comes off) |
| `work/tire_jack.png` | 130 x 140 | 80, 330 | Jack (comes off) |

### brakes (Right main wheel, inside)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/brakes_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/brakes_disc_old.png` | 240 x 240 | 210, 170 | Brake disc, worn/broken |
| `work/brakes_disc_new.png` | 240 x 240 | 210, 170 | Brake disc, new |
| `work/brakes_wheel.png` | 320 x 320 | 170, 130 | Wheel (comes off) |
| `work/brakes_pin.png` | 44 x 24 | 308, 250 | Cotter pin (comes off) |
| `work/brakes_caliper.png` | 120 x 150 | 520, 160 | Brake caliper (comes off) |
| `work/brakes_jack.png` | 130 x 140 | 650, 330 | Jack (comes off) |

### battery (Battery bay, right side)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/battery_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/battery_battery_old.png` | 300 x 200 | 260, 170 | Battery, worn/broken |
| `work/battery_battery_new.png` | 300 x 200 | 260, 170 | Battery, new |
| `work/battery_strap.png` | 340 x 28 | 240, 256 | Hold-down strap (comes off) |
| `work/battery_pos.png` | 70 x 50 | 470, 150 | Positive (+) cable (comes off) |
| `work/battery_neg.png` | 70 x 50 | 280, 150 | Negative (-) cable (comes off) |
| `work/battery_hatch.png` | 460 x 360 | 180, 100 | Access hatch (comes off) |

### fuel_line (Left wing root, underside)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/fuel_line_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/fuel_line_mop.png` | 520 x 40 | 140, 330 | Mess to clear: Wipe up the spilled fuel |
| `work/fuel_line_line_old.png` | 440 x 34 | 180, 240 | Fuel line, worn/broken |
| `work/fuel_line_line_new.png` | 440 x 34 | 180, 240 | Fuel line, new |
| `work/fuel_line_fairing.png` | 560 x 230 | 120, 150 | Wing-root fairing (comes off) |
| `work/fuel_line_valve.png` | 100 x 90 | 700, 420 | Fuel selector (comes off) |

### windshield (Windshield, from the front)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/windshield_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/windshield_screen_old.png` | 540 x 330 | 140, 90 | Windshield, worn/broken |
| `work/windshield_screen_new.png` | 540 x 330 | 140, 90 | Windshield, new |
| `work/windshield_sealant.png` | 540 x 26 | 140, 390 | Mess to clear: Scrape off the old sealant |
| `work/windshield_top.png` | 560 x 30 | 130, 64 | Top retainer strip (comes off) |
| `work/windshield_left.png` | 30 x 330 | 110, 90 | Left retainer strip (comes off) |
| `work/windshield_right.png` | 30 x 330 | 680, 90 | Right retainer strip (comes off) |

### control_cables (Tail, inspection panel)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/control_cables_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/control_cables_cable_old.png` | 620 x 14 | 100, 255 | Rudder cable, worn/broken |
| `work/control_cables_cable_new.png` | 620 x 14 | 100, 255 | Rudder cable, new |
| `work/control_cables_tb_a.png` | 120 x 60 | 180, 230 | Mess to clear: Tension the left turnbuckle |
| `work/control_cables_tb_b.png` | 120 x 60 | 520, 230 | Mess to clear: Tension the right turnbuckle |
| `work/control_cables_wire_a.png` | 140 x 80 | 170, 220 | Left safety wire (comes off) |
| `work/control_cables_wire_b.png` | 140 x 80 | 510, 220 | Right safety wire (comes off) |
| `work/control_cables_plate.png` | 660 x 320 | 80, 110 | Inspection plate (comes off) |

### avionics (Cabin roof and instrument panel)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/avionics_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/avionics_antenna_old.png` | 90 x 240 | 470, 120 | Antenna, worn/broken |
| `work/avionics_antenna_new.png` | 90 x 240 | 470, 120 | Antenna, new |
| `work/avionics_coax.png` | 160 x 30 | 560, 300 | Coax cable (comes off) |
| `work/avionics_radio_old.png` | 260 x 120 | 90, 300 | Radio, worn/broken |
| `work/avionics_radio_new.png` | 260 x 120 | 90, 300 | Radio, new |


## New: jobs for planes that sat for years (batch 2)
Same rules as above. Notes for the painter:
- **stale_fuel**: `fuel_old` is a dark, varnish-brown tank view seen through the open filler; `fuel_new` is clean blue 100LL. The two `sump` images are a clear fuel-tester cup under each drain, showing murky fuel. They disappear once that drain runs clean.
- **door_pin**: the background shows the door frame and hinge with the trim panel off. `pin_old` is a rust-crusted hinge pin, `pin_new` is bright steel. `soak` is a wet penetrant stain around the pin.
- **pre_oil**: the background is the engine side with its top plug holes empty. The 4 `plug` images are installed spark plugs with leads, so it can reuse the spark_plugs art. `turn` is the prop blade and an oil-pressure gauge reading zero. It disappears when the job is done.
- `pre_oil_cowl.png` can be the same image as the other cowlings, and `door_pin_cotter.png` the same as the other cotter pins.

### stale_fuel (Left wing, fuel tank and sumps)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/stale_fuel_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/stale_fuel_fuel_old.png` | 500 x 120 | 160, 170 | Avgas, worn/broken |
| `work/stale_fuel_fuel_new.png` | 500 x 120 | 160, 170 | Avgas, new |
| `work/stale_fuel_sump_l.png` | 220 x 60 | 160, 330 | Mess to clear: Sump the left tank until it runs clean |
| `work/stale_fuel_sump_r.png` | 220 x 60 | 440, 330 | Mess to clear: Sump the gascolator until it runs clean |
| `work/stale_fuel_cap.png` | 80 x 60 | 380, 90 | Fuel cap (comes off) |

### door_pin (Cabin door, hinge side)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/door_pin_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/door_pin_pin_old.png` | 30 x 260 | 395, 150 | Door pin, worn/broken |
| `work/door_pin_pin_new.png` | 30 x 260 | 395, 150 | Door pin, new |
| `work/door_pin_soak.png` | 80 x 60 | 370, 360 | Mess to clear: Soak the pin in penetrant |
| `work/door_pin_cotter.png` | 44 x 24 | 388, 410 | Cotter pin (comes off) |
| `work/door_pin_trim.png` | 300 x 320 | 260, 120 | Door trim panel (comes off) |

### pre_oil (Engine, left side)
| File | Size (px) | Placed at (x, y) | What it is |
|---|---|---|---|
| `work/pre_oil_bg.png` | 1000 x 560 | 0, 0 | Painted background of this spot, everything removable left off |
| `work/pre_oil_turn.png` | 520 x 40 | 150, 290 | Mess to clear: Turn the prop by hand until oil pressure shows |
| `work/pre_oil_plug0.png` | 60 x 110 | 150, 160 | Top plug 1 (comes off) |
| `work/pre_oil_plug1.png` | 60 x 110 | 320, 160 | Top plug 2 (comes off) |
| `work/pre_oil_plug2.png` | 60 x 110 | 490, 160 | Top plug 3 (comes off) |
| `work/pre_oil_plug3.png` | 60 x 110 | 660, 160 | Top plug 4 (comes off) |
| `work/pre_oil_cowl.png` | 760 x 300 | 40, 40 | Cowling (comes off) |


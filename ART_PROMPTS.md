# Art prompts

One prompt per missing texture, written to paste into Claude Design one at a time. Each prompt stands on its own.
Generated from the game's scene data (`tools/art_list.gd`); a file listed here is still drawn as a placeholder. Drop a finished file into `textures/` at the path given and the game uses it with no code change.

## Shared rules (already inside every prompt below)

- Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there.
- Work-scene canvas is 1000 x 560. Backgrounds are opaque and leave the strip x 828 to 988 clear for the game's bench.
- Pieces are transparent PNG, trimmed to the size given, with a soft baked shadow. `_old` and `_new` versions of a piece are the same size and line up exactly.
- Screw, bolt and nut holes are left empty: the game draws the fasteners.

## 1. Scenes with no art yet

Each needs a background plus its pieces. Positions are where the game places them (top-left x, y on the 1000 x 560 canvas).

### Compass way off (`compass`)

**`textures/work/compass_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Compass rose": The Cub's whiskey compass above the panel, a compass rose painted on the apron seen through the windshield. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

### Socket loose under the cowl (`fod`)

**`textures/work/fod_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Engine, under the cowl": Engine left side, cowling off: a socket wedged behind a cylinder baffle. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/fod_fish.png`**, 160 x 60 px, placed at 500, 230

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. A 7/16 in chrome socket wedged behind a cylinder baffle. Transparent PNG, trimmed to 160 x 60 px, soft drop shadow down-right.

### hand_prop (`hand_prop`)

**`textures/work/hand_prop_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "In front of the prop": Standing in front of a Cub's propeller on grass, chocks at the wheels, the cabin door open to the throttle and switch. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

### Chafed ignition lead (`ign_lead`)

**`textures/work/ign_lead_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Engine, left side": Engine left side, cowling off, the ignition harness running from the magneto to each plug. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/ign_lead_lead_old.png`**, 420 x 30 px, placed at 200, 170

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Ignition lead from the magneto harness to one spark plug: old is cracked, chafed through to the wire near the exhaust; new is clean shielded braid with fresh elbows Draw it worn or broken, the way it came off. Transparent PNG, trimmed to 420 x 30 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/ign_lead_lead_new.png`**, 420 x 30 px, placed at 200, 170

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Ignition lead from the magneto harness to one spark plug: old is cracked, chafed through to the wire near the exhaust; new is clean shielded braid with fresh elbows Draw it new, factory fresh. Transparent PNG, trimmed to 420 x 30 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/ign_lead_clamp.png`**, 90 x 50 px, placed at 400, 140

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Small cushioned P-clamp holding the lead to the baffle, two screw holes empty. Transparent PNG, trimmed to 90 x 50 px, soft drop shadow down-right. Leave its screw holes empty.

### Leaking static line (`pitot_static`)

**`textures/work/pitot_static_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Behind the panel": Behind the Cub's instrument panel: the airspeed and altimeter cases with rubber static and pitot hoses, a test set hooked up. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/pitot_static_hose_old.png`**, 300 x 24 px, placed at 360, 200

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Short rubber static line between the altimeter and the static tee: old is cracked and hard; new is supple black rubber Draw it worn or broken, the way it came off. Transparent PNG, trimmed to 300 x 24 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/pitot_static_hose_new.png`**, 300 x 24 px, placed at 360, 200

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Short rubber static line between the altimeter and the static tee: old is cracked and hard; new is supple black rubber Draw it new, factory fresh. Transparent PNG, trimmed to 300 x 24 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/pitot_static_panel.png`**, 380 x 200 px, placed at 340, 100

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Painted steel back cover of the instrument panel, four screw holes. Transparent PNG, trimmed to 380 x 200 px, soft drop shadow down-right. Leave its screw holes empty.

**`textures/work/pitot_static_tester.png`**, 200 x 100 px, placed at 380, 380

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Pitot-static test set: a small gray case with a hand pump, a gauge and two hoses. Transparent PNG, trimmed to 200 x 100 px, soft drop shadow down-right. Leave its screw holes empty.

### Leaking primer (`primer_leak`)

**`textures/work/primer_leak_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Instrument panel, primer": Cub instrument panel close up, the brass primer pump knob on the right of the panel. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/primer_leak_seals_old.png`**, 120 x 110 px, placed at 380, 170

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Primer pump plunger pulled out of the panel: old has a dried, cracked O-ring and fuel stain; new has fresh black O-rings Draw it worn or broken, the way it came off. Transparent PNG, trimmed to 120 x 110 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/primer_leak_seals_new.png`**, 120 x 110 px, placed at 380, 170

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Primer pump plunger pulled out of the panel: old has a dried, cracked O-ring and fuel stain; new has fresh black O-rings Draw it new, factory fresh. Transparent PNG, trimmed to 120 x 110 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/primer_leak_nut.png`**, 70 x 40 px, placed at 405, 130

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Knurled brass packing nut of the primer pump. Transparent PNG, trimmed to 70 x 40 px, soft drop shadow down-right. Leave its screw holes empty.

**`textures/work/primer_leak_valve.png`**, 100 x 90 px, placed at 700, 420

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Fuel shut-off valve handle, red, with OFF and ON stenciled. Transparent PNG, trimmed to 100 x 90 px, soft drop shadow down-right. Leave its screw holes empty.

### Sticking oil relief valve (`relief_valve`)

**`textures/work/relief_valve_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Engine, oil relief valve": Rear of the crankcase: the oil pressure relief valve cap, safety-wired, beside the oil screen housing. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/relief_valve_cap.png`**, 160 x 160 px, placed at 330, 150

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Oil pressure relief valve cap, a hex brass cap screwed into the crankcase, one nut hole. Transparent PNG, trimmed to 160 x 160 px, soft drop shadow down-right. Leave its screw holes empty.

**`textures/work/relief_valve_wire.png`**, 180 x 180 px, placed at 320, 140

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Twisted steel safety wire looped from the relief valve cap to a nearby stud. Transparent PNG, trimmed to 180 x 180 px, soft drop shadow down-right. Leave its screw holes empty.

### Sticking valve (`stuck_valve`)

**`textures/work/stuck_valve_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Engine, rocker cover off": One cylinder head with its rocker cover off: rocker arms, valve springs and stems showing. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/stuck_valve_gasket_old.png`**, 392 x 102 px, placed at 224, 154

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Rocker cover gasket lying in the rocker box: old is torn, oil-soaked cork; new is fresh tan cork Draw it worn or broken, the way it came off. Transparent PNG, trimmed to 392 x 102 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/stuck_valve_gasket_new.png`**, 392 x 102 px, placed at 224, 154

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Rocker cover gasket lying in the rocker box: old is torn, oil-soaked cork; new is fresh tan cork Draw it new, factory fresh. Transparent PNG, trimmed to 392 x 102 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/stuck_valve_soak.png`**, 150 x 50 px, placed at 260, 180

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. A wet penetrant stain pooled around one valve stem and spring. Transparent PNG, trimmed to 150 x 50 px, soft drop shadow down-right.

**`textures/work/stuck_valve_rocker.png`**, 440 x 150 px, placed at 200, 130

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Cast aluminum rocker cover, oily, four empty screw holes at the corners. Transparent PNG, trimmed to 440 x 150 px, soft drop shadow down-right. Leave its screw holes empty.

### Rotten tie-downs (`tie_down`)

**`textures/work/tie_down_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Tied down on the grass": A Cub tied down on grass from the side: rope at the tail lift handle, ropes to both front lift struts, chocks at the wheels. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/tie_down_chocks.png`**, 200 x 46 px, placed at 60, 420

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. A pair of yellow wooden wheel chocks lying on the grass. Transparent PNG, trimmed to 200 x 46 px, soft drop shadow down-right.

**`textures/work/tie_down_tail.png`**, 240 x 46 px, placed at 280, 420

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Rotten coil of tie-down rope at the tail handle, frayed. Transparent PNG, trimmed to 240 x 46 px, soft drop shadow down-right.

**`textures/work/tie_down_left.png`**, 200 x 46 px, placed at 60, 360

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Rotten coil of tie-down rope at the left strut. Transparent PNG, trimmed to 200 x 46 px, soft drop shadow down-right.

**`textures/work/tie_down_right.png`**, 240 x 46 px, placed at 280, 360

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Rotten coil of tie-down rope at the right strut. Transparent PNG, trimmed to 240 x 46 px, soft drop shadow down-right.

**`textures/work/tie_down_lock.png`**, 260 x 46 px, placed at 540, 360

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. The front seat belt hanging loose, ready to wrap round the rear stick. Transparent PNG, trimmed to 260 x 46 px, soft drop shadow down-right.

### Weight and balance out of date (`weight_balance`)

**`textures/work/weight_balance_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "On the scales": A Cub sitting level on three platform scales, one under each main wheel and one under the tailwheel, a spirit level on the cockpit longeron. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/weight_balance_level.png`**, 300 x 46 px, placed at 60, 60

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. A 20-inch spirit level lying on the cockpit longeron. Transparent PNG, trimmed to 300 x 46 px, soft drop shadow down-right.

**`textures/work/weight_balance_l.png`**, 220 x 46 px, placed at 60, 400

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Platform scale dial under the left main wheel. Transparent PNG, trimmed to 220 x 46 px, soft drop shadow down-right.

**`textures/work/weight_balance_r.png`**, 220 x 46 px, placed at 300, 400

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Platform scale dial under the right main wheel. Transparent PNG, trimmed to 220 x 46 px, soft drop shadow down-right.

**`textures/work/weight_balance_t.png`**, 220 x 46 px, placed at 540, 400

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Small platform scale dial under the tailwheel. Transparent PNG, trimmed to 220 x 46 px, soft drop shadow down-right.

### Worn rings, low cylinder (`worn_rings`)

**`textures/work/worn_rings_bg.png`**, 1000 x 560, opaque

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Background for the work scene "Engine, one cylinder": One cylinder of a small flat-four with the intake pipe, exhaust stack and rocker cover still on it. Show the spot with every removable piece taken off (they are separate images layered on top). Leave x 828 to 988 as a plain wooden bench strip. 1000 x 560, opaque PNG.

**`textures/work/worn_rings_cyl_old.png`**, 300 x 240 px, placed at 250, 90

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. A whole air-cooled cylinder with its fins and head: old is dark, oil-streaked, with soot at the base; new is bright gray with clean fins Draw it worn or broken, the way it came off. Transparent PNG, trimmed to 300 x 240 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/worn_rings_cyl_new.png`**, 300 x 240 px, placed at 250, 90

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. A whole air-cooled cylinder with its fins and head: old is dark, oil-streaked, with soot at the base; new is bright gray with clean fins Draw it new, factory fresh. Transparent PNG, trimmed to 300 x 240 px, soft drop shadow down-right; the old and new versions are the same size and line up exactly.

**`textures/work/worn_rings_intake.png`**, 160 x 40 px, placed at 140, 300

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Short aluminum intake pipe with its rubber hose connector. Transparent PNG, trimmed to 160 x 40 px, soft drop shadow down-right. Leave its screw holes empty.

**`textures/work/worn_rings_exhaust.png`**, 160 x 40 px, placed at 520, 300

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Rusty steel exhaust stack stub with its flange. Transparent PNG, trimmed to 160 x 40 px, soft drop shadow down-right. Leave its screw holes empty.

**`textures/work/worn_rings_rocker.png`**, 220 x 70 px, placed at 290, 100

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Cast rocker cover for that one cylinder. Transparent PNG, trimmed to 220 x 70 px, soft drop shadow down-right. Leave its screw holes empty.

## 2. Placeholder pieces in painted scenes

These scenes have their art; one physical piece in each is still a placeholder box.

**`textures/work/bungee_jack.png`** (Tired shock cords), 110 x 110 px, placed at 20, 300

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Small red bottle jack under the gear leg, about 110 x 110. It sits on top of the existing `bungee_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 110 x 110 px, soft drop shadow down-right.

**`textures/work/fuel_strainer_valve.png`** (Clogged fuel strainer), 100 x 80 px, placed at 700, 440

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Fuel shut-off valve handle, red, OFF and ON stenciled, mounted low on the firewall. It sits on top of the existing `fuel_strainer_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 100 x 80 px, soft drop shadow down-right.

**`textures/work/mag_timing_clamp.png`** (Magneto timing drifted), 170 x 140 px, placed at 330, 150

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. The magneto hold-down clamp and its two nuts at the magneto flange (semi-transparent so the magneto shows through is fine). It sits on top of the existing `mag_timing_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 170 x 140 px, soft drop shadow down-right.

**`textures/work/tailwheel_stand.png`** (Sloppy tailwheel), 130 x 140 px, placed at 60, 330

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Red tail stand: a padded steel trestle that holds the tail up off the tailwheel. It sits on top of the existing `tailwheel_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 130 x 140 px, soft drop shadow down-right.

**`textures/work/prop_track_plugs.png`** (Prop out of track), 200 x 46 px, placed at 40, 60

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Four spark plugs lying in a row on a shop rag, pulled one per cylinder. It sits on top of the existing `prop_track_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 200 x 46 px, soft drop shadow down-right.

**`textures/work/pre_oil_rocker0.png`** (Dry engine: pre-oil before start), 140 x 84 px, placed at 110, 118

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Cast aluminum rocker cover for cylinder 1, two screw holes, oily (the background shows the rockers bare). It sits on top of the existing `pre_oil_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 140 x 84 px, soft drop shadow down-right.

**`textures/work/pre_oil_rocker1.png`** (Dry engine: pre-oil before start), 140 x 84 px, placed at 280, 118

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Cast aluminum rocker cover for cylinder 2, two screw holes, oily (the background shows the rockers bare). It sits on top of the existing `pre_oil_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 140 x 84 px, soft drop shadow down-right.

**`textures/work/pre_oil_rocker2.png`** (Dry engine: pre-oil before start), 140 x 84 px, placed at 450, 118

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Cast aluminum rocker cover for cylinder 3, two screw holes, oily (the background shows the rockers bare). It sits on top of the existing `pre_oil_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 140 x 84 px, soft drop shadow down-right.

**`textures/work/pre_oil_rocker3.png`** (Dry engine: pre-oil before start), 140 x 84 px, placed at 620, 118

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Cast aluminum rocker cover for cylinder 4, two screw holes, oily (the background shows the rockers bare). It sits on top of the existing `pre_oil_bg.png` background, so match its lighting and palette. Transparent PNG, trimmed to 140 x 84 px, soft drop shadow down-right.

## 3. Tools

The tool roll shows a 96 x 96 icon per tool, and the mouse becomes that tool (48 x 48 cursor). Two tools are new.

**`textures/work/tool_tester.png`**, 96 x 96

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Tool icon: Differential compression tester: two round gauges (supply and cylinder) on a small black body with a hose and a brass fitting. Centered, transparent PNG, 96 x 96, readable at small size.

**`textures/work/cursor_tester.png`**, 48 x 48

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Mouse cursor of the same tool (Differential compression tester), held at an angle with its working end at the top-left corner (that's the click point). Transparent PNG, 48 x 48.

**`textures/work/tool_timing.png`**, 96 x 96

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Tool icon: Timing light: a small black box with two lamps, L and R, and two alligator-clip leads. Centered, transparent PNG, 96 x 96, readable at small size.

**`textures/work/cursor_timing.png`**, 48 x 48

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Mouse cursor of the same tool (Timing light), held at an angle with its working end at the top-left corner (that's the click point). Transparent PNG, 48 x 48.

## 4. Pocket icons (HUD)

Bottom-left strip, 64 x 64 each, in `textures/ui/`. None exist yet, so the strip shows text only.

**`textures/ui/wallet.png`**, 64 x 64

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. HUD icon: A worn brown leather wallet. Simple silhouette that reads at 40 px, transparent PNG, 64 x 64.

**`textures/ui/clipboard.png`**, 64 x 64

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. HUD icon: A clipboard with a work order on it. Simple silhouette that reads at 40 px, transparent PNG, 64 x 64.

**`textures/ui/logbook.png`**, 64 x 64

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. HUD icon: A pilot and mechanic logbook, dark green cloth cover. Simple silhouette that reads at 40 px, transparent PNG, 64 x 64.

**`textures/ui/manual.png`**, 64 x 64

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. HUD icon: A spiral-bound shop service manual with a red cover reading SERVICE MANUAL. Simple silhouette that reads at 40 px, transparent PNG, 64 x 64.

## 5. Part icons

Shown on the bench tile and the work order (`textures/icon_<job>.png`, 256 x 256). These jobs have a part to buy but no icon yet.

**`textures/icon_stale_fuel.png`** (Stale fuel in the tank), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new fresh avgas for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_door_pin.png`** (Door pin rusted solid), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new door pin & cotter for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_bungee.png`** (Tired shock cords), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new bungee cords for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_ign_lead.png`** (Chafed ignition lead), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new ignition lead for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_primer_leak.png`** (Leaking primer), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new primer seal kit for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_stuck_valve.png`** (Sticking valve), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new rocker cover gasket for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_worn_rings.png`** (Worn rings, low cylinder), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new cylinder assembly for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_hot_mag.png`** (Hot magneto (broken P-lead)), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new p-lead for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_wire_chafe.png`** (Chafed wire behind the panel), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new wire & splices for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_exhaust_check.png`** (Cracked muffler), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new muffler for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_air_filter.png`** (Clogged air filter), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new air filter & flapper for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_baffles.png`** (Packed fins, loose baffle seal), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new baffle seal strip for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_aileron_rigging.png`** (Ailerons out of rig), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new aileron cable for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_wing_rig.png`** (Wings out of rig), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new strut forks for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_elevator_cable.png`** (Frayed elevator cable), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new elevator cable for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_brace_wires.png`** (Kinked tail brace wire), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new brace wire set for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_tailwheel.png`** (Sloppy tailwheel), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new tailwheel springs for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

**`textures/icon_pitot_static.png`** (Leaking static line), 256 x 256

> Style: painterly rural Americana, late-1940s Piper J-3 Cub with a Continental C85 engine, Cub yellow (#E8B820) fabric, worn but honest metal, light from the upper left with soft shadows falling down-right, straight-on flat view with no perspective, matching the existing Airplane Rescue job art kit. No text except stenciled labels that would really be there. Catalog-style icon of a new static hose for a Piper Cub with a Continental C85, shown alone on transparent background, three-quarter view allowed for this one, soft shadow. Transparent PNG, 256 x 256.

## 6. Also worth having

Not wired in yet, but the jobs would read better on the walk-around with them (3D decals on the plane, square, tileable edges not needed):

- `textures/decal_mud_nest.png` (512 x 512): a clay mud dauber nest, for a plugged fuel vent or packed fins.
- `textures/decal_exhaust_streak.png` (512 x 512): gray-white exhaust streaks below a cracked muffler seam.
- `textures/decal_do_not_turn.png` (256 x 512): a yellow DO NOT TURN PROPELLER - ENGINE PRESERVED tag hanging from the prop.
- `textures/decal_danger_tag.png` (256 x 512): the red DANGER: PROP IS LIVE tag for a hot magneto.
- `textures/decal_frayed_rope.png` (512 x 512): rotten, frayed tie-down rope for neglected planes.
- Manual pictures (`textures/manual/ref_<job>.png`) for jobs the manual doesn't cover yet: ign_lead, primer_leak, stuck_valve, worn_rings, relief_valve, tie_down, compass, pitot_static, weight_balance, elevator_cable, fod. Those also need manual pages written.

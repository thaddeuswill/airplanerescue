# Textures needed (round 2)

Drop files into `textures/` with these exact names and I'll wire them in. Style follows [ART_DIRECTION.md](ART_DIRECTION.md).

**Defaults:** PNG, **1024 px**, **seamless/tileable** unless marked *decal* (needs a transparent background) or *image* (a one-off picture). Painterly or stylized-realistic, with wear painted in. Golden-hour warmth, but keep lighting **out** of tileable textures: no baked shadows or highlights.

**Optional extra maps:** for any tileable texture you can also send `_normal.png` (bumps) and `_rough.png` (shine). Not required.

**Already have (round 1):** the 19 textures at 256 px. Re-doing them at 1024 px in the new style is welcome, with the same names. `plane_body`, `ground_grass` and `runway_asphalt` matter most.

---

## Tier 1: biggest visual win

| File | What it looks like |
|---|---|
| `sky_golden.png` | *Image*, 2048×1024 equirectangular panorama. Golden-hour sky: low warm sun, soft clouds, hazy horizon |
| `ground_wheat.png` | Golden wheat or dry prairie seen from above, for plains fields |
| `gravel.png` | Gray gravel road and apron |
| `dirt_red.png` | Red-clay dirt road |
| `grass_card.png` | *Decal*. A clump of grass blades on transparent background (512 px). I scatter thousands of these as 3D grass |
| `wheat_card.png` | *Decal*. A clump of wheat stalks with heads, same idea |
| `plane_body_worn.png` | Light gray painted panels with rivets, chipped edges, faded paint and grime streaks. **Stays light** so I can tint it any color |
| `cockpit_panel.png` | *Image*. Vintage light-aircraft instrument panel: round gauges, switches, yoke cutout. You see this up close in first person |
| `decal_soot.png` | *Decal*. Black exhaust soot streak (spark plug fault) |
| `decal_fuel_stain.png` | *Decal*. Blue-tinged avgas wet stain on concrete (fuel leak fault) |

## Tier 2: hangar and shop interior

| File | What it looks like |
|---|---|
| `pegboard.png` | Brown pegboard with hole grid |
| `workbench_top.png` | Thick worn wood bench top: oil rings, gouges, paint drips |
| `concrete_oil.png` | Hangar floor: concrete with oil stains, cracks and faded yellow lines |
| `toolbox_red.png` | Glossy red painted steel with a slightly scuffed drawer-front look |
| `stickers_sheet.png` | *Decal*. 4×4 grid of made-up vintage tool, oil and tire stickers for toolboxes |
| `hangar_door.png` | Big sliding hangar door: corrugated panels, faded paint, rust at the bottom |
| `seat_vinyl.png` | Cracked brown or tan vinyl seat |

## Tier 3: small-town and farm Americana

| File | What it looks like |
|---|---|
| `barn_red.png` | Weathered red barn boards, paint peeling to gray wood |
| `clapboard_white.png` | Weathered white clapboard siding |
| `brick_faded.png` | Old soft red brick with mortar |
| `wood_dock.png` | Gray sun-bleached dock planks |
| `water.png` | Lake or river surface (a matching `water_normal.png` is ideal) |
| `metal_galvanized.png` | Galvanized steel with zinc spangle (water tower, grain bin) |
| `ghost_sign_1.png` / `_2.png` | *Image*. Faded hand-painted wall ad for a **made-up** brand (oil, feed store, soda) |
| `field_sign.png` | *Image*. Blank-ish wooden airfield sign board; I'll add town names in-game |

## Tier 4: UI (vintage tool-catalog look)

| File | What it looks like |
|---|---|
| `ui_paper.png` | Aged cream catalog paper with faint halftone dots |
| `ui_logbook.png` | Lined maintenance logbook page, coffee stain optional |
| `ui_map.png` | *Image*, 2048 px. Vintage 1950s road-map style US map, with no labels (I place the cities). This becomes the travel screen |
| `ui_stamp_airworthy.png` | *Decal*. Red rubber stamp "AIRWORTHY" |
| `ui_stamp_inspected.png` | *Decal*. Stamp "INSPECTED" |
| `ui_price_tag.png` | *Decal*. Blank orange or yellow price sticker |
| `icon_<part>.png` | *Decal*, 256 px. Catalog-illustration icon for each shop part: `tire`, `brake_disc`, `battery`, `spark_plugs`, `gasket`, `fuel_line`, `windshield`, `starter`, `control_cable`, `magneto`, `radio`, `propeller` |

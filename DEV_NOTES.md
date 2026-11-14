# Airplane Rescue — dev notes (Nov 2026)

What changed, what was downloaded, and what's still open.

## Read first: this was built against an older copy of the scripts

The changes below were made against the scripts Thad uploaded earlier. The repo has moved on since: `work.gd` here is about 2,030 lines, with `view`/`check` elements, `with`/`rest`/`trap`, torque needles (`SPEC`/`RANGE`) and a different tool set. So:

- **Don't copy the zip's `scripts/*.gd` over the repo.** That would wipe newer work. Treat them, and the `.diff` files, as references. Port the pieces you want by hand, then run `--self-test` several times plus `--all-faults`.
- **`data/job_text.json` is keyed to the old scene ids.** Check its ids against today's `scenes()` before wiring `_apply_text` in. Unmatched keys are skipped, so it fails safe.
- **Number conflicts with `CLAUDE.md` / `JOBS_ATA.md` (don't merge until settled):**
  - Prop hub bolts: the old copy used 200-220 in-lb (Continental Table of Limits); the repo uses 175-225 in-lb for AN6 bolts. Per the "don't invent a number" rule, Thad decides.
  - Prop track: `job_text.json` says 1/8 in.; `CLAUDE.md` settles 1/16 in. Fix the four prop lines before using the file.
- **Voice conflict:** `CLAUDE.md` says player text should sound like a mechanic talking, with no jargon. The manual-style rewrite in `job_text.json` is the opposite style, done at Thad's request. Settle with Thad which voice wins before shipping it.
- **The Cub isn't a Meshy model.** `CREDITS.md` says the plane is the FlightGear J3Cub (Don Lavelle, David Megginson, Jim Wilson), **GPLv3**. That's human-made, so the AI section below only applies to the other models. GPLv3 asks you to share the model files (and changes) under GPL with the game, so check that's fine for a paid release.
- **Downloads landed in the project root**, not in `textures/` / `models/` / `sounds/`. They need sorting (section 2). The root also has `belfast_sunset_puresky_2k.hdr` and `concrete_floor_1k.blend.zip`, which weren't part of this round.
- **Credits:** the repo already has `CREDITS.md`. `CREDITS.txt` lists only the new assets from this round; merge it into `CREDITS.md` and delete it.

Two packages from this round:

- `design_pass_fix_all.zip`: script changes (below), with a `.diff` per script
- `CREDITS.txt`: every third-party asset and its license

---

## 1. Code changes (`design_pass_fix_all.zip`)

See "Read first": port these by hand, don't copy the files over. Copy `fonts/DejaVuSerifCondensed.ttf` into `res://fonts/` if you take the manual font change.

**Verified:** all 45 jobs pass `work.gd`'s `solve()` self-test in Godot 4.5, and all six scripts load next to the rest of the project with no parse errors. The work scene, manual and catalog were rendered and checked; renders are in `screens/`.
**Not verified:** the full game wasn't run here (only the scripts). Please check the HUD with the new font, and the title menu with a real gamepad.

### New: `scripts/style.gd` (class_name `Style`)

Design tokens in three tiers: global (raw values) → alias (meaning) → component. One source for colors, type sizes, spacing, motion and fonts. Screens should use alias names (`Style.COLOR_TEXT_PAPER`, `Style.COLOR_ACTION_PRIMARY`…), never raw hex.

- `Style.display(weight)`: Big Shoulders at 600/800/900
- `Style.text_font()`: DejaVu Serif Condensed for long reading (manual)
- `Style.button(b, "primary"|"quiet"|"exit")`: includes a visible focus ring
- `Style.label(text, role, size)`
- Every text/background pair was contrast-checked (all pass WCAG AA). Never put red text on mustard (3.2:1).

The rules behind the tokens are in `design/mood.md`, `design/voice.md` and `design/tokens.md`.

### `work.gd`

| Change | Detail |
|---|---|
| Needs line in the header | Shows the consumables and the part the job still needs vs inventory, e.g. "Needs: Gasket x8 (have 2)". Orange when short. |
| Hold **H** | Outlines every step available right now (`_available()`, `_draw_next_marks()`) |
| Idle hint | After `IDLE_HINT` (20 s) with no progress, the next available step pulses |
| Torque spec | `TORQUE_SPEC` per fault; torque tooltip reads "Torque to 200-220 in-lb" (Continental X30010 Table of Limits) |
| Part number in blocked messages | "You need a new Magneto (No. 50483)", read once per scene from `parts_book.gd` |
| **M** opens the manual | Opens `manual.gd` over the scene at this job's page. M or Esc closes it; uses `main._sub_back` so Esc doesn't close the job. Needs `res://data/c85_manual.json`. |
| Quick hold | `settings.quick_hold` sets every hold to 0.15 s |
| Small fixes | Mouse wheel cycles only this job's tool roll; tool-key hint counts the real roll (up to 9); "Torque every bolt on the <part> first."; tooltip 14 px, hints 13 px |

### Job text rewritten in manual style (`data/job_text.json`)

All on-screen job wording is now data instead of hard-coded strings. Copy `data/job_text.json` to `res://data/`.

- **What's in it:** each job's title with its source reference (e.g. "Accessory case: starter mounting pad · Cont. 10-25, 10-26"), piece names, step labels, and `verb_off` / `verb_on` / `verb_remove` / `verb_install` lines. Keys are job id → piece id → field.
- **How it loads:** `work.gd` applies the file at the end of `scenes()` (`_apply_text`). A missing file or key falls back to the built-in text. Ids and job logic are untouched; all 45 jobs still pass `solve()`.
- **Style:** service-manual imperative with the manuals' terms (spark plug "No. 4 upper", "ignition cable", "magneto ground lead (P-lead)", "Remove… / Install… / Safety-wire with new wire"). It's paraphrased, not copied, so the manuals' wording isn't reproduced.
- **Generic messages** were reworded to match: "Remove the cowling first.", "Reinstall the X first.", "Install the new X first.", "Torque all bolts on the X first.", "Complete the X before reinstalling.". `_n()` lowercases names mid-sentence but keeps "No. 4…" and "P-lead".
- `job_text_before_after.csv` lists all 368 changed lines, with an empty "your words" column for later human rewrites. Edit the JSON (or regenerate it from the CSV) to change any wording.
- This text is still AI-written, so it stays on the Steam AI disclosure until it's rewritten by hand.

### `catalog.gd` / `parts_book.gd`

- Colors and fonts come from `Style`
- Greyed BUY shows "SHORT $N" underneath (`parts_book` now passes a `short` value)
- NEEDED stamp moved onto the picture (it used to cover the part name); the stock line also says NEEDED in words
- Price tag 15% smaller so BUY leads the row
- Long names wrap to two lines at one size, never break at a hyphen
- Blurbs end in "…" with the full text on hover

### `manual.gd`

- Colors and fonts come from `Style`
- Summaries and steps use the serif text face at 16 px
- The figure moves under the left column when there's room (`_layout_figure_and_steps`, waits one frame for layout), so short pages aren't half empty
- More space under section rules

### `main.gd`

- `C_*` colors now point at `Style`; the unused `#8B2020` red was retired
- `UI_FONT_BUNDLED := true` uses bundled Big Shoulders everywhere (Bahnschrift is Windows-only). Set it to `false` to revert.
- New careers start with `STARTER_SUPPLIES` (4 gaskets, 5 safety wire, 5 cotter pins)
- The first job of a career is from `FIRST_JOBS` (`water_fuel`, then `bird_nest`); both are doable with the starter tools
- Settings: new "Quick hold" toggle
- Title menu works on gamepad (`_menu_pad`): d-pad, A to pick, shoulder buttons page the shop wisdom. The stick is left out on purpose because it repeats every frame.

---

## 2. Free human-made assets (downloaded to Thad's machine)

All are CC0: free for commercial use, credit not required (given anyway in `CREDITS.txt`).

### Poly Haven (already renamed)

| File | Source | Use |
|---|---|---|
| `sky_golden.hdr` | Kloppenheim 06 (Pure Sky), 2K | `PanoramaSkyMaterial` on the `WorldEnvironment` |
| `concrete_oil.png` + `_normal` + `_rough` | Concrete Floor Worn 001 | Hangar floor |
| `workbench_top.png` + maps | Weathered Brown Planks | Bench |
| `wood_dock.png` + maps | Wood Planks Grey | Docks |
| `brick_faded.png` + maps | Red Brick | Town |

### ambientCG (1K PNG zips, named `gamename__ambientCG_ID.zip`)

Inside each zip: rename `*_Color.png` to `<gamename>.png`, `*_NormalGL.png` to `<gamename>_normal.png`, and `*_Roughness.png` to `<gamename>_rough.png`.

| Game name | Asset |
|---|---|
| `gravel` | Gravel023 |
| `dirt_red` | Gravel025 |
| `ground_wheat` | Ground109 |
| `plane_body_worn` | PaintedMetal012 (light, so it tints well) |
| `toolbox_red` | PaintedMetal004 |
| `hangar_door` | CorrugatedSteel007A |
| `galvanized_metal` (the zip says `metal_galvanized`; the code uses `galvanized_metal`) | CorrugatedSteel009 |
| `seat_vinyl` | Leather038 |
| `barn_red` | PaintedWood003 |
| `clapboard_white` | PaintedWood009C |

Import notes: turn on repeat for tiling materials. For each `_normal.png`, set the import to **Normal Map** (all files use the OpenGL convention, which matches Godot).

### Kenney (zips)

| Pack | Suggested use |
|---|---|
| Nature Kit | Grass clumps, small rocks, filler trees |
| City Kit (Suburban) | Town buildings |
| Car Kit | Base for `fuel_truck` (repaint) |
| Survival Kit, Furniture Kit | `crate_a`, `barrel_a`, `radio_desk`, apron and hangar clutter |
| Input Prompts | Keyboard/gamepad button art (pairs with the new gamepad menu) |
| Impact Sounds, Interface Sounds | Fallbacks for sound clips not recorded yet (`tray`, `heavy`, `panel`, `deny`, `tool`) |

### Quaternius: Stylized Nature MegaKit (99 MB zip)

Trees, rocks and plants for `tree_broadleaf_*`, `tree_pine_*`, `rock_*`. A large rock scaled up can stand in for `mountain_a`. Use the glTF files.

### How to put them in the game

Everything below sits loose in the project root right now. The game only looks in three places, by exact name:

| The game loads | From | Notes |
|---|---|---|
| Models | `models/<name>.glb` | `model()` / `prop()` in `main.gd` scale each model to a size set in code, so the source scale doesn't matter. Only `.glb` is loaded |
| Textures | `textures/<name>.png` | `tmat()` in `main.gd`: triplanar, so no UVs needed. Only the color map is used today |
| Sounds | `sounds/sfx/<clip>.wav` or `.ogg`, plus `_1`, `_2`, `_3` takes | `sound.gd` picks a take at random. Clip names are in `CLIPS` at the top of `sound.gd` |

**Step 0: get the raw downloads out of the project.** Godot has already imported the Freesound WAVs in the root (there are `.import` files next to them), so they'd ship in the build. The Cessna clip alone is 252 MB. Make a folder `_downloads/`, put an empty file named `.gdignore` in it, and move every zip, `.wav`, `.hdr` and `.blend.zip` from the root into it. Delete the leftover `.import` files. Godot skips any folder with a `.gdignore`.

**Models (Kenney, Quaternius): use `tools/pack_glb.py`.** Kenney's GLBs don't carry their own texture; they point at `Textures/colormap.png` next to them, and every kit has a different file with that same name. Copied straight into `models/`, they lose their colors. `pack_glb.py` packs the model and its textures into one file under the name the game wants:

```bash
python tools/pack_glb.py "_downloads/kenney_survival/Models/GLB format/barrel.glb" models/barrel_a.glb
python tools/pack_glb.py "_downloads/kenney_survival/Models/GLB format/box-large.glb" models/crate_a.glb
```

Unzip each kit into its own folder first and keep its folders as they are. Tested: both files above load in Godot 4.7.2 with their textures. It also takes `.gltf` + `.bin` (check whether the Quaternius zip has a `glTF` folder; if it only has FBX, open it in Blender and export `.glb`).

Names the game asks for today, and what to swap in:

| Name in code | Where | Swap-in candidate | Watch out |
|---|---|---|---|
| `barrel_a`, `crate_a`, `toolbox` | Hangar clutter | Kenney Survival `barrel`, `box-large`; Furniture kit for `toolbox` | `prop()` is passed a material (`tmat("galvanized_metal", ...)`, `tmat("toolbox_red", ...)`), which replaces the model's own colors. Pass `null` to keep Kenney's |
| `tree_broadleaf_a/_b/_c` | Plains | Quaternius trees | `TREE_SPLIT` in `main.gd` holds each tree's trunk share of its height (for the trunk collider). Measure the new tree and update it |
| `tree_pine_snow_a`, `cactus_a/_b/_c` | Snow, desert | Quaternius pines, Kenney Nature cactus | — |
| `fuel_truck` | Airfield | Kenney Car kit (repaint) | — |
| `hangar`, `parts_shed` | Airfield | Keep current; Kenney City kit is too modern | `hangar` uses exact mesh walls, so keep the open front on +Z |

A new name (say `rock_a`) needs a `prop("rock_a", ...)` call somewhere before it shows up.

**Textures (Poly Haven, ambientCG):** put the color map in `textures/` as `<name>.png`. For ambientCG, unzip and rename `*_Color.png` to `<name>.png`; set repeat on in the import tab.

Drop-in now (the code already asks for these names; your file replaces the current one):
- `gravel`, `dirt_red`, `ground_wheat`, `toolbox_red`, `workbench_top`
- `galvanized_metal`: **the code calls it `galvanized_metal`, not `metal_galvanized`** as the zip is named. Rename it.
- `plane_body_worn`: used by the 2D work scenes as the plane skin. Look at a few scenes before keeping it; it's photo-real next to painted art.

Need a line of code first (nothing uses these names yet): `concrete_oil` (hangar floor), `hangar_door`, `seat_vinyl`, `barn_red`, `clapboard_white`, `brick_faded`, `wood_dock`. Example for the hangar floor: find the floor `box(...)` in the hangar builder and give it `tmat("concrete_oil", Color.WHITE, 0.25)`.

The `_normal.png` and `_rough.png` maps are ignored today. To use them, add this to the end of `tmat()`:

```gdscript
	var n := "res://textures/%s_normal.png" % tex
	if ResourceLoader.exists(n):
		m.normal_enabled = true
		m.normal_texture = load(n)
	var r := "res://textures/%s_rough.png" % tex
	if ResourceLoader.exists(r):
		m.roughness_texture = load(r)
		m.roughness = 1.0
```

Set each `_normal.png` import to Normal Map.

**Sky:** `_setup_environment()` in `main.gd` loads `res://textures/sky_golden.png`. Move `sky_golden.hdr` into `textures/` and change that line to `load("res://textures/sky_golden.hdr")`. (`belfast_sunset_puresky_2k.hdr` is a spare; `concrete_floor_1k.blend.zip` isn't needed, since `concrete_oil` covers it.)

**Sounds:**
- **Kenney Impact/Interface sounds:** drop-in. Copy a few `.ogg` files into `sounds/sfx/` named after a clip in `CLIPS`, for example `tray.ogg`, `tray_1.ogg`, `heavy.ogg`, `panel.ogg`, `deny.ogg`, `tool.ogg`. Thad's real recordings replace them later under the same names.
- **Freesound clips (they did arrive):** nothing plays them yet. The engine sound is made in code (`_bake_cruise()` in `sound.gd`) and the only ambience is `sounds/amb/room.wav`. Trim each one to a 20-40 s loop, save it as `.ogg` in `sounds/amb/`, and add a player for it the same way `_room` is set up. Suggested names: `field_idle.ogg` (695971), `field_far_piper.ogg` (695970), `cockpit_cub.ogg` (437758), `flyover.ogg` (251971), `runway.ogg` (251977), `wind_grass.ogg` (176252), `birds.ogg` (345852), `wind_birds.ogg` (288899), `radio_static.ogg` (17804 or 337700). Cut the Cessna recording (322321) into `engine_start`, `engine_idle` and `engine_takeoff`.

Credits for all of these are in `CREDITS.txt`.

### Not downloaded yet

- **Freesound**: all 11 clips arrived (see "How to put them in the game" above). The list:
  - Cessna start/idle/takeoff (13:30, cut it into `engine_start`, `engine_idle` and `engine_takeoff`)
  - Plane idling near, and a Piper idling in the distance (field ambience)
  - Piper Cub interior (in-flight cockpit loop)
  - Propeller flyover, runway ambience
  - Wind in grass, spring birds loop, wind and birds
  - Two radio static clips (owner radio calls)
- **Godot plugins**: install from the AssetLib tab:
  - Now: **Sky3D**, **Terrain3D**, **ProtonScatter**
  - Optional: Phantom Camera, Dialogue Manager 3, Controller Icons, Godot State Charts
  - At release: GodotSteam
  - All MIT. Ship each license file with the game.
- **Tool sounds**: Thad will record the 27 clips (`ratchet`, `torque_turn`, `snip`, …) with real tools. Keep the names `sound.gd` expects.

---

## 3. AI content and Steam disclosure

**Decision:** use free human-made assets wherever they exist and keep AI-made art for the rest. What stays AI-made for now:

- the 317 work-scene images (`textures/work/`)
- manual, catalog and in-game text (Thad may rewrite this in his own words)
- the **Meshy** models: Meshy is an AI 3D generator, so swap in Kenney/Quaternius models wherever there's a match. The Cub and the other planes have no free match yet.

Steam requires disclosing AI content that players see (store art, in-game art, text, sound). Code tools don't count. Please make sure the Steamworks content survey is filled in honestly at submission. A suggested store line:

> Some work-scene art and text were made with AI tools. Sounds, environment art, procedures and all maintenance knowledge come from a working A&P mechanic and real Continental and Piper manuals.

---

## 4. If art gets commissioned later

The spec lives in the plan doc ("Airplane Rescue plan"). Short version:

- **Work-scene backgrounds:** 2000×1120 canvas (2× the 1000×560 scene). Each removable piece on its own full-canvas transparent layer, named with the piece id (`bg`, `cowl`, `plug0_old`…). Leave the right strip, x 1656–1976, plain for the bench.
- **Icons:** 512×512, transparent background, named `icon_<part>` / `tool_<tool>`.
- **Models:** .glb, meters, Y up, front facing -Z, origin on the ground; names from `MODELS.md`.

A small script that crops full-canvas layers to each piece's rect and saves them as `textures/work/<fault>_<id>.png` would make drop-in easy. Worth writing when the first commission arrives.

---

## 5. Icon and scene-art update (Nov 13): how to pull it in

This one was written straight into the project folder, against the current `scripts/work.gd`, so there's nothing to merge by hand. If you work on another machine, pull these files from Thad's copy:

| Files | What changed |
|---|---|
| `textures/catalog/*.png` (all 54) | Parts-book icons redrawn: one drawing per part, mid-tone fills, 4 px outline at 256. Why and how: `docs/ICON_AUDIT.md` |
| `textures/icon_tire.png`, `textures/icon_brakes.png` | Same style as the other job icons |
| `scripts/work.gd` | New `ROCKER_RECT` and `_rocker_screws()`, used by `oil_leak` and `stuck_valve` (one lobed cover per cylinder, six screws on the lobes). `starter` gasket task rect is now `Rect2(125, 195, 100, 120)`. No other logic touched |
| `textures/work/oil_leak_*`, `brace_wires_*`, `starter_bg/gasket`, `magneto_gasket`, `spark_plugs_lead0-3` | Repainted to match the real parts. List and reasons: `docs/quick-specs/scene-parts-match-2026-11-13.md` |
| `tools/draw_catalog_icons.py`, `tools/paint_scene_fixes.py` | The scripts that made the above |

**After pulling:**

1. Open the project in Godot 4.7.2 once so it reimports the PNGs.
2. Run the self-test on the changed jobs, then a few plain runs:
   ```bash
   godot --headless --path . -- --self-test --faults=oil_leak,starter,brace_wires,magneto,spark_plugs,stuck_valve
   godot --headless --path . -- --self-test
   ```
   On a partial copy the scene check passed (`scenes=true edges=true`); the full run hasn't been done on the real project yet.
3. Look at the scenes at 1280x720:
   ```bash
   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --self-test --scene-shots=shots/s:oil_leak,stuck_valve,starter,brace_wires,magneto,spark_plugs
   ```
   (On Windows drop the `xvfb-run ...` part.) The `_a` shots open with the cowl on; check the `_b` shots.

**Redrawing icons:** `python tools/draw_catalog_icons.py out/` draws every icon into `out/` (needs Pillow; reads `fonts/BigShouldersDisplay.ttf`). Each part is one small function in the file; change it, rerun, copy `icon_*` to `textures/` and the rest to `textures/catalog/`.

**Repainting scene pieces:** `python tools/paint_scene_fixes.py <old textures/work> out/` (needs Pillow and numpy). It paints *on top of the old art*, so point it at the art from **before** this update (`git show` / a checkout of the earlier commit), not the current folder, or the patches get applied twice.

**Still guesses (Thad to check):**
- Magneto flange gasket shape (ring with two eared stud holes); the scene and icon match each other but not a confirmed part.
- Starter pad 5-hole layout vs. the Continental starter adapter figure.
- `spark_test` and `mag_timing` still use the old red leads.

This art is AI/script-made: add it to the disclosure list in section 3.

---

## 6. Open items

- [ ] Run the full game with `UI_FONT_BUNDLED = true` and check the HUD for clipping
- [ ] Test the title menu with a real gamepad
- [ ] Rename and import the ambientCG maps; wire `sky_golden.hdr` into the world
- [ ] Replace Meshy models with Kenney/Quaternius where they match; list what's left
- [ ] Install Sky3D / Terrain3D / ProtonScatter and try them on one airfield
- [ ] Add `CREDITS.txt` to the build and the plugins' MIT licenses
- [ ] Paste the 29 kit jobs into `FAULTS` (see `SETUP.md` from the job-audit package) if not done yet; `FIRST_JOBS` falls back to `bird_nest` without them
- [ ] Full self-test and scene shots for the Nov 13 icon/scene update (section 5)
- [ ] Settle the magneto gasket shape and the starter pad holes
- [ ] Move the raw downloads into `_downloads/` (with `.gdignore`) so they stay out of the build
- [ ] Pack and swap the first Kenney/Quaternius models with `tools/pack_glb.py` (section 2)

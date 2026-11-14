# Quick Design Spec: Work-scene parts match the real parts

**Type**: Art correction
**System**: Work-scene art (`textures/work/`), a few rects in `scripts/work.gd`
**Date**: 2026-11-13

## Change Summary

The icon repass (`docs/ICON_AUDIT.md`) checked every catalog part against photos of the real part. Five work scenes draw a part differently from the real one, or from its own icon, so the scenes should change to match.

Only the **shapes** carry over. The icon style (ink outline, flat fills) doesn't apply to work scenes: `ART_DIRECTION.md` wants them painted and lit, not outlined.

## Scenes to change

| # | Scene | What's drawn now | What the real part looks like | Change | Code? | Confidence |
|---|---|---|---|---|---|---|
| 1 | `oil_leak` (and the rocker cover in the cylinder scene, `work.gd` ~line 1949) | One long flat plate, 440 × 150, "KESTREL", rectangular gasket | One small **domed cast cover per cylinder**, rounded outline with lobes at the screw holes; the gasket follows the same lobed outline | Repaint `oil_leak_rocker.png`, `oil_leak_gasket_new.png`, `_old.png` to the lobed shape. Shrink `rc` to about 260 × 180 and move the six screws onto the lobes. | Yes: `rc` and the six `_at("rocker", …)` points, both scenes | High (photos of covers and gaskets agree) |
| 2 | `brace_wires` | Thin wire with eye ends | Round rods with a **threaded fork (clevis) end** at each end; the fork takes a clevis pin at the tail fitting | Repaint `brace_wires_upper_new/old.png` and `brace_wires_lower_new/old.png` with fork ends; clevis tabs at the attach points in `brace_wires_bg.png` | No | High |
| 3 | `starter` | Round cork gasket with **6** holes; the pad in the background shows 2 | The scene has **5** fasteners (3 nuts + 2 through bolts, Continental 10-25). The gasket is a thin outline gasket with ears at the stud holes | Repaint `starter_gasket.png` with 5 holes at the five fastener positions (`sr` + offsets in `work.gd`); show the 5 studs/holes on the pad in `starter_bg.png` | No (positions already in code) | Medium: check against the Continental parts catalog figure for the starter adapter |
| 4 | `magneto` | Small oval gasket with 2 holes | **Not confirmed online.** The S4LN-21 flange gasket shape didn't turn up. The new icon is a round ring with 2 holes, so the scene and the icon disagree | **Decision needed:** check a real S4LN-21 flange or the catalog figure, then make `magneto_gasket.png` and `textures/catalog/mag_gasket.png` the same shape | No | Low until checked |
| 5 | `spark_plugs`, `spark_test`, `mag_timing` | Red elbow terminals | Shielded, braided leads with an elbow terminal and a coupling nut on the plug | Repaint `spark_plugs_lead0-3.png` braided with a brass/steel coupling nut. Keep red only if it's the game's "this one" highlight | No | Medium |
| 6 | `wire_chafe` | Clamp cushion is black | Cushioned (Adel) clamps come with black or yellow cushions | Make the scene and `textures/catalog/cushion_clamp.png` the same color (black is the safer, period-correct choice) | No | High (either is real; they just need to match) |

## Checked and fine as is

- **`brakes`:** already a Goodyear expander-tube brake with lining blocks, matching the J-3.
- **`tire`, `fuel_strainer`, `oil_change`:** the tire, the glass Tillotson bowl, the drilled-head drain plug and the screen all match.
- **`exhaust_check`, `control_cables`, `trim_cable`, `baffles`, `bungee`:** the muffler, turnbuckles, baffle seal strip and shock cord rings all match.

## Icons fixed in the same pass

The online check also corrected two icons I had drawn wrong. Neither appears in a work scene.

- **Oil sump gasket:** the C-85 sump is a cast, pear-shaped pan, so its gasket is a long pear-shaped band with bolt holes all round, not the round 8-hole ring I drew first.
- **Accessory case cover gasket:** a thin D-shaped band following the cover's edge, not a solid sheet.

## Order

1. **#2 brace wires and #6 clamp color:** art only, high confidence.
2. **#1 rocker cover:** art plus rect and screw positions. Re-run the self-test for `oil_leak` and the cylinder scene.
3. **#3 starter gasket:** after checking the catalog figure.
4. **#4 magneto gasket:** after a real part or figure settles the shape.
5. **#5 leads:** polish.

## Done (2026-11-13)

- **#1 rocker cover:** new `ROCKER_RECT` (320 × 190) and `_rocker_screws()` in `work.gd`, used by `oil_leak` and `stuck_valve`. Six screws on the lobes; gasket follows the lobed outline. `oil_leak_bg.png` repainted (old plate fins rebuilt, lobed flange in its place). "KESTREL" removed.
- **#2 brace wires:** rods with fork ends; clevis tabs added at the fin, stab and fuselage in `brace_wires_bg.png`.
- **#3 starter:** pad repainted with the bore moved off the middle stud and 5 holes; `starter_gasket.png` has the same 5 holes. Gasket task rect is now `Rect2(125, 195, 100, 120)`. Fastener positions unchanged. **Still check against the Continental figure.**
- **#4 magneto:** went with a round ring with an ear at each of the two studs, in the scene and the icon. **Still a guess: check a real S4LN-21 flange.**
- **#5 leads:** `spark_plugs_lead0-3.png` braided with an elbow and a brass coupling nut (leads 2 and 3 had no art before). `spark_test` and `mag_timing` not repainted.
- **#6 clamp:** icon cushion changed to black to match the scene.

## Acceptance Criteria

- [x] Each changed scene passes `godot --headless --path . -- --self-test --faults=<scene>`, plus a few plain `--self-test` runs. (Checked on a partial copy: `scenes=true edges=true`; the overall FAIL there came from missing models/music in the copy and was the same with the old `work.gd`. Re-run on the full project.)
- [x] `--scene-shots` at 1280x720 shows the new pieces lined up with their fastener positions (rocker screws on the lobes, starter gasket holes on the 5 studs).
- [ ] `tools/art_list.gd` reports no missing art for the changed scenes.
- [x] Every part that's both a work-scene piece and a catalog icon has the same shape in both.
- [ ] The art is noted as AI-made in the disclosure list (per the AI decision in `DEV_NOTES.md`), or replaced with human-made art later.

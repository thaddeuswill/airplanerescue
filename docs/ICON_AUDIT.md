# Design audit: icons

A visual-critique pass from [owl-listener/designer-skills](https://github.com/owl-listener/designer-skills) (hierarchy, composition, typography, color, affordance, brand), done the same way as `DESIGN_AUDIT.md`. Dated 2026-11-13.

**What was covered:**
- 66 catalog icons: the 12 job icons `textures/icon_*.png` and the 54 parts-book icons `textures/catalog/*.png`
- The app icon `icon.png`

**How:**
- Each icon was judged at the size the game draws it: 112 × 112 px on the mustard halftone sun over cream paper (`catalog.gd` `_card`).
- Contrast is measured (WCAG relative luminance), not eyeballed. Fill, stroke and duplicate counts were measured from the PNGs.

**Brand sources:** `ART_DIRECTION.md` ("vintage tool catalogs and ads: halftone printing, red/cream/black, stamped part numbers") and the palette constants in `catalog.gd`. There's no `voice.md` or `tokens.md` in the repo, so token-name compliance was skipped, as the skill says.

Contact sheets: `icon_audit_sheet_now.png` (as drawn today) and `icon_audit_sheet_mip.png` (with mipmaps).

## Scores

| Dimension | Rating | One line |
|---|---|---|
| Affordance / recognition | **Major** | 21 of 66 icons are exact copies of another; several don't look like the part |
| Color / figure-ground | **Major** | Line icons are cream on cream (1.15:1); hairline outlines are all that separate them |
| Brand consistency | **Major** | Two unrelated styles; only the 12 job icons match the catalog look |
| Composition | Minor | Object size ranges from 47% to 97% of the tile |
| Stroke weight (typography analog) | Minor | 0.4 to 3 px at display size |
| Hierarchy | Minor | No single feature leads in most line icons; red accents land in random places |
| Outline ink color | **Pass** | Ink on cream 13.6 to 13.9:1, ink on mustard 7.6:1 |

## P1 (critical)

| Issue | Dimension | Measured | Fix |
|---|---|---|---|
| **Duplicates.** Only 45 unique images for 66 parts. Same picture: air box / carb / case cover / rocker / sump gaskets (5); dope / fuel tank / grease / preservative (4); nut 3/8 / nut 7/16 / prop bolts (3); base packing / crank seal / pushrod seal (3); drain / plug / screen gasket (3); exhaust / gascolator / mag gasket (3); expander tube / tube tire; hose 1.5 / hose 1.75; lead 36 / lead 42; lifter / stab screw; bleeder / primer jet; brace wires / tie rod lower | Affordance (recognition) | 21 copies | One drawing per part. Where real parts look alike, the outline follows the real part (rocker gasket: long rounded rectangle with bolt holes; plug gasket: small ring) and the material sets the color (copper, cork tan, rubber black, paper gray). Sizes like 3/8 vs 7/16 can share a drawing if the size is printed on a tag in the icon. |
| **Cream on cream.** The 54 line icons are filled `#FAF6EC` on cream paper `#EEE6CF` | Color (figure-ground) | 1.15:1 fill vs paper; 2.06:1 vs mustard. Non-text graphics need 3:1 (WCAG 1.4.11) | Give every part a mid-tone fill from the palette (steel gray, copper, rubber, red can) so the shape, not just its outline, separates from the paper |
| **Hairline outlines vanish.** The thinnest lines land on the halftone dots | Color / Composition | Trim cable 0.4 px, gaskets and dope cans 1.3 px at display size; gaskets cover only 3% of the tile | Outline at least **4 px at 256** (about 1.75 px shown), inner lines 2 px |

## P2 (important)

| Issue | Dimension | Measured | Fix |
|---|---|---|---|
| **Two styles.** The 12 job icons are colored, labeled catalog drawings (12 VOLT, MAG, red bands). The 54 parts icons are cream line drawings. The brakes icon is the only one with gradient shading. | Brand / Similarity | 12 vs 54 | Keep the job-icon style as the standard: it matches `ART_DIRECTION.md`. Redraw the parts icons into it, with flat fills only. |
| **Generic shapes.** Ignition lead is a zigzag; generator and regulator are a plain cylinder and box; carb is a box on a cylinder | Affordance (recognition) | — | One defining feature each: braided lead with a 90° elbow terminal; generator with pulley and terminal posts; regulator box with 3 terminals; carb with float bowl and throttle arm |
| **Size all over the place** | Composition (rhythm) | Longest side 47% (seals) to 97% (propeller); area 3% to 62% | Longest side about **80%** of the tile. Long thin parts go diagonal. At least 15% area. |
| **No mipmaps.** Icons are drawn at 44% scale with `mipmaps/generate=false` | Composition (render) | Compare the two contact sheets | Turn on mipmaps for `icon_*` and `textures/catalog/*`. Set the canvas default texture filter to Linear Mipmap. |

## P3 (polish)

| Issue | Dimension | Measured | Fix |
|---|---|---|---|
| Text inside icons (12 VOLT, MAG, 122.8) is about 8 px tall when shown | Typography | At the readable limit | Fine as decoration; never the only way to tell parts apart |
| Red lands on a different feature in each job icon (battery band, magneto label, tire hub, plug band, radio knob) | Hierarchy | — | Red on exactly one defining feature per icon |
| App icon: the propeller turns into a red smudge at 16 px; the price tag says "shop" more than "airplane rescue" | Affordance / Brand | Red on mustard 3.19:1, a bare pass for graphics | Thicker propeller filling about 70% of the tag, or a bold plane or prop silhouette. Check it at 16, 32 and 48 px. |

## Overall

Strongest: the **palette and brand of the 12 job icons**. They read as a 1950s tool catalog and their ink outlines measure well (13.6:1 on cream).

Weakest: **recognition**. A third of the parts book shows a copy of another part's picture, and the cream line icons nearly disappear into the paper.

Fix order:
1. Mipmaps (two minutes).
2. Redraw the duplicate groups and the line icons in the job-icon style, with mid-tone fills, 4 px outlines and 80% size.
3. The P3 polish.

## Repass (2026-11-13)

All 54 parts-book icons and the tire and brakes job icons were redrawn by `tools/draw_catalog_icons.py`. Each shape was checked against photos of the real part found by part number and name. After sheet: `icon_audit_sheet_after.png`.

| Measure | Before | After |
|---|---|---|
| Distinct images | 45 of 66 | 66 of 66 (the 54 redrawn icons are all different) |
| Fill vs paper (median contrast) | 1.18:1 | 2.35:1 |
| Pixels as light as the paper | 54% | 12% |
| Longest side | 47% to 97% | 80% to 89% |
| Ink outline at display size | 0.4 to 3 px | about 1.75 px everywhere (4 px at 256), 2 px inner lines |
| Style | cream line drawings + gradients | flat fills from the palette, one red feature, one hard shadow |

**Parts that only differ by size** carry a stamped tag in the icon, like a parts-bin label:
- 3/8" and 7/16" nuts
- 1-1/2" and 1-3/4" hose
- 36 in and 42 in leads
- Upper 41-3/4" and lower 35" tie rods

**Shapes that came from photos:**
- **Engine and ignition:** magneto ring gasket, Bendix-style points and box condenser, C-85 rocker cover gasket (lobed outline, 6 holes), round red sump gasket with 8 holes, black lip crank seal, orange pushrod packing, braided ignition lead with brass coupling nut.
- **Fuel and induction:** MA-3 carburetor, intake pipe with 2-hole flange, 2-bolt exhaust gasket, J-3 slab nose tank.
- **Electrical:** Delco-Remy generator and regulator, Adel cushion clamp.
- **Brakes and wheels:** Goodyear expander tube, brass bleeder, AN900 copper gasket.
- **Airframe:** Cub tail brace wire with fork ends, stabilizer jack screw.

**Still worth a mechanic's look (lower confidence):**
- **Sump gasket and case cover gasket:** corrected after an online check. The sump is a cast, pear-shaped pan, so its gasket is now a pear-shaped band; the case cover gasket is a thin D-shaped band. Exact hole counts aren't confirmed.
- **Magneto flange gasket:** the S4LN-21 shape wasn't confirmed. The icon and the scene now agree (a ring with an ear at each stud), but the shape is still a guess. See `docs/quick-specs/scene-parts-match-2026-11-13.md`.
- **Cushion clamp:** the cushion is now black, to match the `wire_chafe` scene.
- **Points, condenser, dope can, grease tube:** drawn to type, not to the exact 1940s part.

**Not done yet:**
- **Mipmaps:** still off on the icon imports (P2), and they're still the biggest single improvement at 112 px.
- **App icon:** unchanged (P3).

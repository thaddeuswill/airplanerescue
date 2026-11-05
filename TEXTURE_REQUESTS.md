# Texture requests (round 3)

These are what's still blocking a better look. All files are PNG, sRGB, and go in `textures/` unless noted. "Tileable" means seamless on all four edges. I'll wire each one in when it lands.

## 1. Work scenes for the three new jobs (22 files)
The full list with exact sizes and positions is at the bottom of `WORK_SCENES.md`, under "New: jobs for planes that sat for years". It covers `stale_fuel_*`, `door_pin_*` and `pre_oil_*`, and goes in `textures/work/`.

## 2. Fixes to art you already sent
| File | Change |
|---|---|
| `work/tire_bg.png`, `work/brakes_bg.png` | Paint a small jack pad under the wing above where the jack stands (jack art sits at x 80-210 in the tire scene, x 650-780 in the brakes scene), so the jack is pushing on something. |

## 3. 3D world (each one replaces a stand-in I'm generating in code)
| File | Size | What |
|---|---|---|
| `grime_lichen.png` | 1024 x 1024, tileable, RGBA | Years of dirt on a plane that sat out: dark brown-gray grime with pale green-gray lichen patches. Alpha = how much grime covers the paint (mostly 60-90%, with some cleaner streaks where rain ran off). Replaces the rock texture now used as grime. |
| `water_ripples_n.png` | 512 x 512, tileable, normal map (OpenGL / green-up) | Small wind ripples for the pond. Replaces generated noise. |
| `gravel_b.png` | 1024 x 1024, tileable | A second gravel, same stones but a different arrangement and slightly browner, to blend with `gravel.png` and break the repeat. |
| `decal_tire_marks.png` | 1024 x 128, transparent | Black rubber skid marks, two parallel streaks fading in and out. |
| `decal_leaves.png` | 512 x 512, transparent, a 2 x 2 sheet | Dry leaves and twigs, four different clumps, for scattering under trees and in hangar corners. |
| `decal_pebbles.png` | 512 x 512, transparent | A loose scatter of pebbles and a bottle cap, for the edges of the apron. |
| `windsock_fabric.png` | 512 x 256 | Faded orange-and-white windsock stripes, a little frayed at the tail end (right side). |
| `trim_metal.png` | 2048 x 2048 | One trim sheet for the code-built props (desk, radio, crates, posts): rows of panel seams, rivet lines, worn painted edge strips and bolt plates. Plus `trim_metal_rough.png`, the matching roughness map (bright = matte, dark = shiny; scratches and polished edges darker). |

## 4. Models (Meshy), not textures, but still blocking
| Model | Why |
|---|---|
| `tree_pine_a.glb`, `tree_pine_b.glb` | Plain (snowless) pines for the forest regions. The forest still uses code-built cones, the biggest style break left in the 3D world. |
| `jerry_can.glb`, `fuel_tester_cup.glb` | Props for the stale-fuel job and the hangar floor. |

## 5. UI (already in `WORK_SCENES.md`)
`ui/wallet.png`, `ui/clipboard.png`, `ui/logbook.png`, each 64 x 64.

# Typography pass (anti-ai-typography-mastery skill, v2.1)

**Date**: 2026-11-14
**Art direction**: a 1940s field service bulletin (the existing design system, `scripts/style.gd`).

## What the audit found

| Where | Was | Rule | Now |
|---|---|---|---|
| HUD, panels, messages, title menu (`main.gd` `UI_FONT`) | System stack: Bahnschrift, else Segoe UI, else **Arial**. Every Mac and Linux player saw Arial | 324: no default Arial in a game HUD | Big Shoulders Display 600 |
| Headings (`HEAD_FONT`) | The system font smeared bolder with `variation_embolden` | 21: no faux bold | Big Shoulders 800, a real cut, tracked for capitals |
| Work scenes, stations, map, gauges | `ThemeDB.fallback_font`, Godot's built-in face | 324 | Big Shoulders (700 for dial and map lettering) |
| Anything without an override (popups, tooltips) | Godot's built-in face | Godot note in SKILL.md | Project default font `fonts/ui_default.tres` (Big Shoulders at 600; the .ttf alone opens at Thin) |
| Live numbers: flight readouts, the work-scene day and light counter, settings values | Big Shoulders, whose digits are proportional and which has no `tnum` feature | 330: fixed-width digits on every live counter | **Courier Prime** (OFL): a 1940s typewriter face, one width for every digit |
| Panel body size | 16 px in a condensed face, which reads about 2 px small | 326-327: size for the screen, condensed faces at small sizes | 18 px (`Style.SIZE_MD`) |
| All-caps labels | Untracked, or a 1 px guess | 18: track capitals +0.04 to +0.12 em | `Style.caps()`: +0.06 em |
| Licenses | Courier Prime new; the DejaVu license never shipped; no license in the Mac build | OFL: the license travels with the font | Installer copies all four; both export presets pack `fonts/*.txt`; credits name every face |

## Already right

- Big Shoulders Display (OFL) for the world, Yellowtail (Apache) for the logo only, DejaVu Serif
  Condensed for long reading: a chosen, licensed pairing that fits the art direction.
- Message text size and backing are settings (Small to XL, background opacity): rule 352, captions.
- HUD text over the 3D world sits on dark chips or carries outlines: rules 328-329.

## Not done

- MSDF rendering for the large title and the 3D signs (rule 355): worth trying if they blur when scaled.

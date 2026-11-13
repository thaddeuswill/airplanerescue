# Design audit: UI screens

A `/critique-screen` pass from the `visual-critique` skills in
[owl-listener/designer-skills](https://github.com/owl-listener/designer-skills): hierarchy, brand,
composition, typography, color, affordance and information density. It covers the work order, the
radio, the wallet, the parts shed, the manual, a work scene and the new station, at 1280x720.
Screens were captured with the self-test's `--shot` option. Dated 2026-11-12.

## P1 (critical): fixed

| Issue | Dimension | Fix |
|---|---|---|
| What you see and hear (the clue and run-up messages) was drawn under every panel and ran off the right edge. On the work order, half of it was hidden. White outlined text on bright sky | Affordance / Color | The message is a dark card (earth, brass rule) in the top-right corner, outside the panels. It's brought to the front each time, stays up 4 s plus 1 s per 40 characters, and moves into the title strip over work scenes and stations |

## P2 (important): fixed

| Issue | Dimension | Fix |
|---|---|---|
| Every line on the paper panels was the same bold type, so a fault and "Owner waits 30 days" carried equal weight | Hierarchy / Typography | Lines you act on stay bold. Information lines use the same typewriter face at book weight in softer ink |
| "Close (Esc)" was the biggest, greenest button on every panel: the strongest emphasis on the least important action | Hierarchy / Affordance | Close is now a small outlined button at the bottom right. Green is kept for actions |
| Radio and shed buttons stretched to the height of their text block (a 90 px "Fly" button) | Composition | Buttons keep their own height, centered on their row |
| The Back button over a work scene overlapped "Day N" | Composition | Back sits across from the tool roll, at the scene's right edge |
| Station tiles with no painting of their own were blank boxes | Composition | They show the spot's general view |

## P3 (polish): open

| Issue | Dimension | Fix |
|---|---|---|
| Tester, Timing light and Fabric tester have no tool-roll icons; the other six do | Brand / Similarity | Paint `textures/work/tool_tester.png`, `tool_timing.png`, `tool_punch.png` (same style and 96 x 96 px as `tool_ratchet.png`) |
| The wallet lists materials as one run-on line | Density | One line per material, or the icons from the parts shed |
| Work-order action buttons differ in width ("Work on it" vs "Open up the engine") | Composition | A shared minimum width for the action column |
| The work scenes' title strip uses the default UI font while panels use the typewriter face | Brand | Pick one for scene titles (the typewriter face matches the paperwork; the default reads better small) |

## Overall

Strongest: **brand**. The paper, ink, brass and hangar-green palette, typewriter paperwork and painted
scenes all read as one 1950s field shop. Weakest was **hierarchy**: everything shouted at the same
weight, and the one thing the player must read (what they found) was the easiest to miss. Both of
those are fixed. What's left is polish.

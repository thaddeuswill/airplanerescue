# Walk round the engine by arrows; only the jobs you have the tools for (E1)

**Status**: built, iteration 38
**Date**: 2026-11-26
**Code**: `bay.gd` `ARROWS`, `ARROW_NAMES`, `_arrowed`, `_k`, `_origin`, `_build_tabs`, `_place_arrows`,
`actions`, `_open_card`; `tutorial.gd` bay walkthrough; self-test `_engine_walk_ok`

## Why

Thad, 2026-11-25: "moving around the engine in the scenes by click arrow to get to the front bottom
and side of the engine to navigate the engine and only scenes with tools pop up if you have that
tool in inventory".

## What

- **Arrows round the open engine**, in the margins round the picture, each naming where it goes
  ("REAR CASE ▶", "▲ OVER THE TOP", "▼ UNDERNEATH"). From the left side: right to the rear
  accessory case, up over the top, down underneath. From the rear case: left back to the side,
  right on to the firewall, up, down. From the firewall: left back to the rear case, up, down. From
  the top or underneath: back to the side, or right to the rear case. Every view is reached by
  arrows alone.
- The view tabs under the open engine go; "Close the cowl" stays. The picture shrinks slightly to
  leave the arrows their margins (at 1280x720 about 5%). The other spots keep their tabs.
- **No front view yet** (no art): backlog E2.
- **Only jobs you have the tools for**, on every difficulty: a part offers a job only if its tool
  is in your roll (an instrument, in your hand). Easy no longer lists the rest greyed out; a quiet
  line on the card says what would open more ("More work here with the timing light (red
  toolbox)", or "a torque wrench (not in your roll yet)").
- The bay walkthrough mentions the arrows.

## Acceptance

- Self-test `_engine_walk_ok`: from the side, arrows alone reach all five open views; every view
  has arrows, none over the picture or off screen, no view tabs; with an empty roll no part offers
  a job needing a tool, on Easy or Medium; Easy shows the hint line, Medium doesn't.
- Ten runs and the screenshot run (Easy, so the hint shows) pass; screenshots of each view.

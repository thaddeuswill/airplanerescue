# The cockpit checklist, smaller, in a corner, on glass (C1)

**Status**: built, iteration 21
**Date**: 2026-11-24
**Code**: `preflight.gd` (`_draw`, `_glass`, `last_rect`); `tutorial.draw_check` takes a colour

## Why

Thad: "the run up callouts for how to start the engine should be smaller in the corner and a glassy
panel instead".

## What

- Bottom-left corner, 16 px from the edges, clear of the gauges, the top message band and the
  top-right hint. 300 px wide (was 380 at the top left).
- A frosted-glass panel behind the drawing (`show_behind_parent`), with the ticket's tokens and
  shader.
- Type one step down: steps 15, the phase title 18, labels, keys, readings and coaching lines 13.
- Cream text; done steps in brass with a green tick; the current step marked by the mustard focus
  bar; keys as cream chips; the alert band in the loss red.
- The foot line wraps (the audit's cut-off "Can earn: Reads the").
- Every step, key and live reading kept; coaching lines unchanged in content.

## Acceptance

Self-test (`_cockpit_card_ok`) on the flooded start and the take-off: in the corner and inside the
screen, narrower than 380 px and smaller in area than the old card for the same steps (300x290 vs
about 380x288; 300x216 vs about 380x222), the foot wrapped, the glass behind it. Screenshots at
1280x720: before start, flooded, run-up, take-off.

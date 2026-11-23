# The ticket's hierarchy (D4)

**Status**: built, iteration 17
**Date**: 2026-11-23
**Code**: `main._open_mission_card`, `_card_figure`, `_card_heading`; the logbook sheet

## Why

Thad: "theres no hierarchy in the ticket window... all the title text the same size and there is
to much in the top right corner". No new screen for what moves.

## What

- Type scale, largest first: the total (Courier Prime bold 36, label Big Shoulders 900 at 22), the
  registration (Courier Prime bold 28), the line items (18), the owner's words and advice (15),
  the labels (STATION, REGISTRATION, COST YOU EXTRA, ACHIEVEMENTS, DEBRIEF: tracked caps 13, brass).
- Top right: one quiet word, DEBRIEF.
- Moved: the rescued tally (already on the logbook and career sheets as planes rescued); spots
  checked and faults fixed to the job's entry in the logbook.

- Refined in review (Thad: "more appealing spacing", "change wrong guesses to extra parts"; the
  /ux and anti-AI typography reviews): 4 px inside a group, 8-16 px between groups (pay, costs,
  extras, achievements, total, advice), a gap between station and registration; the guess charge
  reads "Extra parts"; a true minus (U+2212) on every loss and curly quotes on the owner's words
  (all three faces carry the glyphs). At 1280x720 the ticket scales to about 96% to fit.

## Acceptance

Self-test measures the sizes: total > registration > line item > label; the corner is one line;
the debrief carries the stats for the logbook. Screenshots at 1280x720 and 1920x1080.

# Take days and hours off the debrief (D1)

**Status**: built, iteration 14
**Date**: 2026-11-23
**Code**: `main.job_debrief`, `debrief_lines`, `_cost_word`, `_open_debrief`; the logbook sheet

## Why

Thad: the day and hour figures "add nothing to the game". The debrief talks money and mistakes.

## What

- The header is the plane and the city; the summary is pay, fuel, parts, rent and net. No day of
  the career, no days on site.
- Each extra cost shows its dollars; one that only cost time shows bare ("Left mag called bad").
- Entries saved before this carry "(0.4 days, $6)" or "(1 h)" or "(a do-over)": `debrief_lines`
  drops the time and keeps the dollars when they're shown, on the debrief and in the logbook. A
  part's own brackets ("Gasket assortment (10)") are left alone. The save itself is unchanged.
- Unchanged: rent still comes from the days; the advice still weighs time when picking the
  mistake that cost most; form (P4) and Clean Job count the lines, not their wording.
- Not in scope: the logbook entry's own "(x days on site)" line and the career's "Days on the road".

## Acceptance

Self-test: the shown sheet has no day or hour figure; old-style lines come out as expected
(dollars kept, part brackets kept); the advice still names the biggest extra. Screenshot at
1280x720.

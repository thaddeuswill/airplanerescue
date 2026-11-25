# Difficulty first on the calls; the plane's papers when you arrive (M1)

**Status**: built, iteration 32
**Date**: 2026-11-25
**Code**: `main._open_travel` (call rows), `_add_row` / `_row_height` (the `call` option),
`_open_papers`, `plane_logbook`, `PAST_WORK`, `PAST_HANDS`, `_travel` (opens the papers)

## Why

Thad: on the calls, the thing that matters is how hard the job is; and the plane's logbook and the
pilot's discrepancy belong after you accept and arrive, before you fix the plane. Keep the owner's
story of what happened.

## What

- Each call reads in four steps: "Difficulty 3 of 5: Moderate" largest; then the station, city, pay
  and what it clears; then the owner's story; then the small print (parts, your fuel, the hangar
  fee, distance). Coloured for the dark map sheet.
- On arrival, before any work, the plane's papers: the pilot's discrepancy (the squawk) on top,
  then three logbook entries, newest first, each with tach hours, the work and who signed; a plane
  that sat ends with being put away for storage. Worked out from the registration (the same plane
  shows the same history), story only: no figures from the manuals, no dates (no clock, D2).
  "Start the walk-around" closes it; a lesson's squawk notes follow.

## Acceptance

Self-test (`_papers_ok`): the papers open on arrival titled with the registration, with the
discrepancy and at least two signed tach entries, no dates, the same history twice; the button
closes them. The map's call rows are rating > where and pay > story > small print by size, in the
sheet's own text colour (a lesson's map has no other calls, by design). Ten runs (two Hard) and
the screenshot run pass, after the colour fix the screenshot caught.

# The logbook, by importance (LB1)

**Status**: built, iteration 19
**Date**: 2026-11-23
**Code**: `main._open_logbook`, `logbook_entry_row`; `_add_row` and `_row_height` options (a large
first line, a grid); `tutorial` logbook walkthrough

## Why

Thad asked what matters most in the log and agreed to this order: what to do next, the record,
then the badges; the money breakdown already showed on each ticket.

## What

- Title: "Logbook" with planes rescued beside it ("Logbook 1 of 10 rescued").
- First: rank and what the next rank needs, the rank in 28 px.
- Then one entry per job, newest first: registration, station and city, what it cleared (signed);
  what was fixed and the spots and faults count; the newest keeps its "Next time". Older entries
  get a worked-out registration.
- Last: the badges as a 4 x 2 grid, earned in ink with the filled icon, not yet muted; the
  standard on hover.
- Gone: each entry's pay, fuel and parts breakdown and its cost-extra list.

## Acceptance

Self-test (`_logbook_ok`): rank first and 28 px, entries next with no money breakdown, the grid of
eight last; a ten-job career paginates to fewer pages than the old layout (2 against 3 at the
test's window, 2 against 6 at 1280x720). Screenshot at 1280x720.

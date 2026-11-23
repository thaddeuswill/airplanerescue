# Difficulty that follows performance (P4)

**Status**: built, iteration 13
**Date**: 2026-11-23
**Code**: `main.performance_form`, `form_line`; `_spawn_job` reads it

## Why

Any player should be able to win, and nobody should coast (performance-proportional difficulty):
cognitive load managed per player, from evidence the game already keeps.

## What

- **Form**: the last three debriefs. +1 a clean job (nothing extra), -1 a rough one (a comeback, a
  part broken by running it unready, or three or more extra costs), 0 otherwise. The sum, -3 to
  +3, worked out from the logbook, never stored.
- **New calls are pitched to it**: the career ramp reads rescues plus form, so strong play brings
  more faults per plane, look-alikes and troubleshooting sooner and tighter deadlines; a struggle
  holds them back, never below a fresh career's. Pay already follows a call's rating (P7).
- **The debrief says which way**: "Your next calls: tougher / about the same / steadier".
- Unchanged: the apprenticeship's calls; what success means.

## Acceptance

Self-test: same seeds, 80 calls each: from a strong record the mean rating is higher than from a
weak one (measured at build: 3.69 against 1.88); form +3 reads "tougher", a weak record "steadier",
an empty logbook 0.

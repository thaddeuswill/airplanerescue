# Signing off is one button (L1)

**Status**: built, iteration 24
**Date**: 2026-11-24
**Code**: `main._sign`, `_sign_logbook`, `logbook_entry_text`, `_hard_take_off`, the work order's
sign row, `_migrate` (version 4), `BADGES`; `tutorial` sign step

## Why

Thad: the logbook is always in accordance with the maintenance manual, so there's no point to the
entry screen: one button signs the plane off.

## What

- The work order's "Write up the logbook" is "Sign off": one press signs, with the entry written for
  you (the work done, to AC 43.13-1B and the manufacturer's data, approved for return to service,
  signed with your certificate type and number). The SIGNED OFF banner follows as before.
- On Hard, "Sign off & take off" at the cabin now signs first. Before this it didn't, and
  `_start_ferry` refused the unsigned plane: a soft-lock on Hard, found by this iteration's run.
- Gone: the entry sheet and its choices, the inspector's aid for a wrong entry and its advice line,
  the sign-off walkthrough.
- By the Book is retired (Thad's choice): seven badges. Saves go to version 4; `_migrate` drops it
  from older careers.
- The task list and the lesson's step read "Sign off".
- The IA rank still needs 6 badges, now of 7; left for B1 (better achievements) to settle.

## Acceptance

Self-test (`_sign_off_ok`): the work order offers Sign off and none of the old choices (Hard: the
combined button, which signs first); pressing it signs with the manual entry; seven badges on the
board and the tracker; an old save loses By the Book. Ten runs pass, two of them Hard.
Screenshot of the work order at 1280x720.

# The "all planes rescued" ending as a ticket (E6)

**Status**: built, iteration 20
**Date**: 2026-11-23
**Code**: `main._open_ending`, `career_cleared`, `_glass_card`, `_show_glass_card` (shared with the
debrief ticket); `Style.glass_button`

## Why

Thad: the ending should look like the finished-mission screen, with nothing on it that doesn't
pertain to the game or help.

## What

- The same centred frosted-glass card as the ticket, from the same code.
- Top: CAREER label, "All 10 planes rescued", the progress ring full (green) at the right.
- Two figures, large Courier Prime with small labels: cleared over the career (every ticket's
  total added up; older entries count pay less fuel and parts) and cash in hand.
- Achievements: the rank and each badge earned, then "x of 8 badges earned".
- Keep flying is the one red primary; Main menu and Start a new career are quiet glass buttons.
- Cut as not serving play: the two lines of closing prose and "Longest neglected".
- It still can't be closed by accident. The game-over sheet is unchanged (U4).

## Acceptance

Self-test (`_ending_ok`): the glass card, centred, at full size at 1280x720, not closable, one
primary (Keep flying) of three buttons, two figures, the ring at 10 of 10, the rank listed, none of
the old prose. Screenshots at 1280x720 and 1920x1080.

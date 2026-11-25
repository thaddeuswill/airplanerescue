# One money format and the small text fixes (U5, U6)

**Status**: built, iteration 33
**Date**: 2026-11-25
**Code**: `main._thousands`, `main.sentences_joined`, `main._symptoms`, `main._open_tasks`,
`main._add_row` (`aside`), `main._setup_tracker`; `manual._commas`; `tutorial.gd` calls walkthrough;
self-test `_text_format_ok`, `_next_task_ok`, the tracker check

## Why

The UX audit (`docs/UX_AUDIT_2026-11-23.md`) found money written two ways ("$4250" on the map,
"$4,250" on the ticket), a full stop after a question ("magneto?."), straight quotes in the owner's
words, a calls walkthrough that described the wrong order, a task list where every row said
"To do:" and nothing said what was next, and grey badges that vanished over bright ground.

## What

- **U5**: every money figure the player sees goes through `_thousands`: log lines, the grounding,
  crash and forced-landing sheets, the owner's words, the CONTINUE line, the take-off and supply
  buttons, the map pin tooltip and the parts catalog in the manual. "Need $ more" reads the price
  with its comma.
- **U6**:
  - `sentences_joined` ends each sentence once: no stop after "?" or "!". The run-up log and the
    symptom fallback use it.
  - The owner's words (work order, annual) are in curly quotes.
  - The calls walkthrough: "Open calls first, the best estimate first."
  - Task list: the first task to do is marked "Next:" in the large size ("Next, try again:" for a
    retry); plain to-dos carry no prefix; Done, Can't be done and Try again keep their word.
  - Badge offers ("Can earn: ...") sit under the task in the 13 px quiet style (row option `aside`).
  - The badge row sits on a dark rounded strip (earth at 55%).

## Acceptance

- Self-test reads the map, the logbook, the game-over card, the cash line and the message band:
  no "$" followed by four or more bare digits, no "?." or "!.".
- Self-test opens the task list on arrival: one row marked next (none if nothing is left), no
  "To do:", no "Can earn" in a row's own text; the owner's words in curly quotes.
- The badge row has its backing and hides over sheets.
- Ten runs and the 1280x720 screenshot run pass; screenshots show the map, ticket and logbook
  with commas fitting their rows.

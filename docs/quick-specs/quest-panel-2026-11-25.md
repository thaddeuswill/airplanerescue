# The apprenticeship as a side-panel quest (A2)

**Status**: built, iteration 34
**Date**: 2026-11-25
**Code**: `tutorial.quest_rows`, `_draw_card`, `reward_text`, `fold`, `STEP_H`, `last_rect`;
the `quest` key (Q) in `main.DEFAULT_KEYS` and `settings_ui.BINDS`; self-test `_quest_after_lesson_ok`

## Why

Thad, 2026-11-23: "i dont want that apprenticeship to be a pop up"; "it should be more of a
sidepanel quest type behavior". The sign-off card covered the call list on the map and had to be
dismissed.

## What

- The checklist card is now a quest panel, top left: QUEST, "Apprenticeship, 3 jobs", and each
  job as a line with its state (DONE with a tick, IN PROGRESS, LOCKED) and its reward ("Reward:
  $200 bonus and a compression tester"). The job in progress lists its steps under it, ticking as
  before; only the step you're on is explained.
- When a lesson ends nothing pops up. The bonus is on the ticket as before. The panel ticks the
  job and, under it in the accent ink, says what it taught and the line that says what comes next.
  The note stays (saved in `tut.reward`) until you start the walk-around on the next plane; after the
  third job the panel then retires.
- Q (rebindable, "Fold the quest panel") folds it to the title, the job in progress and the
  step you're on; again opens it. The state is saved.
- Hidden over every sheet, work scene, the cockpit, the ticket and the menu, as the card was.
- To fit eleven steps and a finished job's note above the pockets at 1280x720: step rows are
  21 px, and a done job drops its reward line.

## Acceptance

- After each lesson: the map opens with no card over it; in the world the panel shows the three
  jobs' states (done/now/locked, or all done after the third), the "Learned" note and the next line,
  every job's reward, the next job's current step; it ends above the pockets row; the same rows
  after a save and load; Q folds it; the note goes once the next walk-around begins.
- The ticket opens with the panel hidden.
- Ten runs, the screenshot run (lesson 1) and the tutorial screenshot run pass.

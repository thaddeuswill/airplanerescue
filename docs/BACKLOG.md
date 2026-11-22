# Backlog

Ordered: the top is next. Thad sets the order (`docs/PROCESS.md`). Each item has its acceptance
criteria. Done items move to the iteration log in `docs/PROCESS.md`.

## Current iteration

**Iteration 2: the learning design.** Goal: every part of the game answers Mager's three questions.

1. **Learning-design document** (`docs/LEARNING_DESIGN.md`)
   - For every aspect of the game (each lesson, each menu, each system: walk-around, write-up, repair,
     run-up, troubleshooting, logistics, paperwork, ferry flight, career), it answers:
     what must the player know or do (the goal); how they learn it (method and media in the game);
     how we know they've learned it (the measure: what the game checks).
   - Every measure names the code or self-test check that measures it, or is marked **gap** with the
     backlog item that would close it.
   - Acceptance: no aspect without all three answers; every gap is a backlog item below.

## Next

2. **A wall of saved planes in the hangar, and the rescue tally on the map** (audit item 5).
   Acceptance: a photo per rescue appears by the map; the map shows "N of 10 back in the air";
   screenshot at 1280x720; self-test checks the count matches the logbook.
3. **Merge the two shops; merge the wallet and the parts table** (audit item 6).
   Acceptance: one store with shelf and mail-order prices side by side; one pocket for what you
   carry; walkthroughs updated; self-tests pass.
4. **"Do it the way you know" for repeated jobs; "Same as always" for the logbook entry** (audit
   item 7). Acceptance: after three clean runs of a job, one hold does it at the same time cost;
   after three correct entries, one click signs; self-test covers both.
5. **A first-time card for each new system after the apprenticeship** (audit item 8): long-sat
   wreck, look-alike faults, annual, grounding. Acceptance: each shows once, when it first appears.
6. **Graphics settings: detail rows under Advanced** (audit item 9). Acceptance: the preset and
   window rows show; 12 detail rows fold; settings screenshot checked.

## Bugs and debts

- **Screenshot-mode starter:** under xvfb with a display, the self-test's engine start never
  catches, so `start failures` is false in `--shot` runs (headless is fine; it predates iteration 1).
  Acceptance: `--shot` runs reach the flight.
- **Rare self-test hang:** one plain run in about twenty stopped in `_scene_tests` with no result
  (seen once, 2026-11-16; not reproduced). Acceptance: found and fixed, or 50 runs clean.
- **README controls are out of date** (says M for the manual; it's N). Acceptance: README matches
  the bindings.

## Process items

(None. Requests to change how we work go here and are decided between iterations.)

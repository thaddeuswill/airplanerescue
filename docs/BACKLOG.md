# Backlog

Ordered: the top is next. Thad sets the order (`docs/PROCESS.md`). Each item has its acceptance
criteria. Done items move to the iteration log in `docs/PROCESS.md`.

## Current iteration

(None. Iteration 1 is in review; see the log in `docs/PROCESS.md`.)

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

## Learning-design gaps (from `docs/LEARNING_DESIGN.md`)

- **G1. Squawk comprehension measure.** Log the first spot opened after the squawk notes and
  whether it matches the note's look-first spot. Acceptance: a play-log line per lesson; a
  self-test check that it's written.
- **G2. What players do after a walkthrough.** Log the first action taken in each menu after its
  walkthrough, and the time to it. Acceptance: a play-log line per menu; self-test check.
- **G3. Judge the mag drop.** On the run-up the player calls each mag good or bad before the game
  says (75 rpm max, C-85); a wrong call is explained and costs time, not money. Acceptance: the
  call is on the cockpit checklist; self-test covers right and wrong calls.
- **G4. Learning events in the play log.** Count wrong verdicts per fault, purchases the job didn't
  need, spots skipped at sign-off, and run-ups with "don't run it yet" work open. Acceptance: each
  writes a play-log line; a self-test check reads them.
- **G5. Help fading in repairs.** Count H-hint uses and wrong-tool attempts per job. Acceptance:
  play-log lines; the numbers fall across a career in a scripted self-test.
- **G7. One overlay at a time.** Tick slips wait while a walkthrough, the tour or a notes card is
  open, then show. Acceptance: screenshot; self-test check that slips are held.

## Bugs and debts

- **Screenshot-mode starter:** under xvfb with a display, the self-test's engine start never
  catches, so `start failures` is false in `--shot` runs (headless is fine; it predates iteration 1).
  Acceptance: `--shot` runs reach the flight.
- **Rare self-test hang:** one plain run in about twenty stopped in `_scene_tests` with no result
  (seen 2026-11-16 and again 2026-11-23, one run in nine; not reproduced on a rerun). Acceptance:
  found and fixed, or 50 runs clean.
- **README controls are out of date** (says M for the manual; it's N). Acceptance: README matches
  the bindings.

## Process items

(None. Requests to change how we work go here and are decided between iterations.)

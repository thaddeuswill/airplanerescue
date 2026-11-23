# How this game is built: the process

**Settled 2026-11-23 by Thad. Agile iterations with a Spiral risk gate.** This is fixed. It is not
changed mid-iteration, whatever is asked in the middle of one (see "Changing the process").

## Roles

- **Thad: product owner.** Decides what goes in the backlog and its order, and accepts or rejects
  what an iteration delivers.
- **Claude: the team.** Plans each iteration, runs the risk gate, builds, verifies, reports. May
  propose backlog items and order; doesn't reorder without Thad.

## The backlog

`docs/BACKLOG.md`: one ordered list. Each item says what it is and how we'll know it's done
(acceptance criteria). Every new request goes here first.

## One iteration

An iteration is one goal and the few items that serve it, finished and shipped before the next
begins.

1. **Plan.** Take the top of the backlog. Write the iteration goal and its items, with acceptance
   criteria, under "Current iteration" in `docs/BACKLOG.md`.
2. **Risk gate (spiral).** Before building, list what this could break and how the check will
   catch it: saves (`SAVE_VERSION` and `_migrate`), soft-locks (`solve()`), real values (CLAUDE.md:
   don't invent a number), the money rules, the 1280x720 layout. A risk with no check gets a new
   self-test check, or the item is cut down until it has one.
3. **Build.** Only the planned items.
4. **Verify: the definition of done.**
   - Self-test passes: plain (x3), `--difficulty=easy`, `--difficulty=hard`, `--all-faults`,
     `--tutorial=1`, `--tutorial=2`, `--tutorial=3`.
   - New behavior has a self-test check.
   - Any screen that changed is screenshotted at 1280x720 and looked at.
   - The spec (`docs/quick-specs/`), CLAUDE.md and the backlog are updated.
   - Committed and pushed to the working branch.
5. **Review.** Report to Thad what was planned, what shipped, what didn't and why, with
   screenshots. Thad accepts it or sends items back to the backlog.
6. **Retro.** One line in the iteration log below: what to keep, what to change.

## Requests that arrive mid-iteration

- **It corrects or refines an item being built in this iteration** (a fix to the screen in
  progress, a change to its wording or layout): it's part of that item and goes into this iteration.
- **Anything else** goes into the backlog, at the position Thad gives it, and waits for its own
  iteration. The current iteration finishes first.
- **The one exception, the hotfix lane:** a crash, lost or corrupted saves, a soft-lock, or a build
  that won't run. Fixed at once, in its own commit, then the iteration resumes.

## Changing the process

The method above doesn't change mid-iteration, whatever is asked in the middle of one. A request
to change how we work goes into the backlog as a process item. It's discussed at the review, and
only adopted, by Thad, between iterations, written into this file with the date.

## Iteration log

| # | Dates | Goal | Shipped | Retro |
|---|---|---|---|---|
| 0 | 2026-11-22 to 23 (before this process) | Onboarding: apprenticeship, walkthroughs, take-off checklist, map | Apprenticeship (3 lessons), squawk notes, menu walkthroughs, cockpit checklist, locked map during lessons, difficulty per call, NEEDED stamps, dead screens cut | Requests arrived mid-build and were folded in as they came. Under this process they go to the backlog unless they refine the item in progress |
| 1 | 2026-11-23 | The learning design: Mager's three questions and the four flow conditions for every part of the game | `docs/LEARNING_DESIGN.md`: 5 lesson aspects, 10 systems, 11 menus; every measure tied to code or a self-test check; 7 gaps, each a backlog item (G1-G5, G7, and item 5 for G6) | Accepted by Thad 2026-11-23. Keep: verifying every code reference before writing it down. Change: the self-test hang showed up in the definition-of-done run; it should be fixed soon, as it weakens the gate |
| 2 | 2026-11-23 | A self-test you can trust: fix the rare hang | The "hang" was an engine crash (segfault) making Label3D nodes: the parts table rebuilt every label each time a job finished, dozens of times in one frame during the scene tests. Now it rebuilds once per frame (self-test check 71). A watchdog fails any run that stops, saying where (`--hang-test` proves it). 3 crashes in 40 runs before; 0 in 40 after; then 50 plain runs in a row and the full definition-of-done set, 56 of 56 | Accepted by Thad 2026-11-23. Keep: reproducing in bulk with isolated runs, which turned a "hang" into a crash with a location. Change: parallel runs need their own `user://` folder; now in CLAUDE.md |
| 3 | 2026-11-23 | Judge the mag drop (G3) | After each mag's drop is read the player calls it good (G) or bad (B); right calls say why, a wrong call says why, costs time and asks again; the run-up only finishes with both called; the 75 rpm limit shown on Easy and Medium, not Hard; a play-log line per call. Self-test covers wrong and right calls and the three reasons. Definition-of-done set 9 of 9 | Accepted by Thad 2026-11-23. Keep: checking a suspicious screenshot before calling it a bug (the ticks were 0.1 s old). Change: the first test ordering was wrong; write the 'doesn't finish yet' check before the step that finishes it |
| 4 | 2026-11-23 | The five categories of learning-game elements (E1) | `docs/LEARNING_DESIGN.md` section D: all 20 subcategories of Goals, Control, Actions, Guidance and Feedback mapped to the code; 16 done, 4 partly or gaps, each a backlog item (E2 replay, E3 reopen a walkthrough, E4 more help after repeated misses, E5 a job debrief). Every reference grep-checked. Definition-of-done set 9 of 9 | Accepted by Thad 2026-11-23. Keep: grep-checking every reference. Change: catch unsupported counts ("50-odd scenes") while writing, not at the check |
| 5 | 2026-11-23 | A job debrief (E5) | Each job records what cost extra as it happens (`note_cost`); on delivery a paper Debrief sheet: days, pay, fuel, parts, rent, net, each extra cost with its time or money, and advice for the biggest; kept in the logbook. Self-test: the debrief lists the test's wrong mag call with advice; a comeback shows with its advice. Definition-of-done set 9 of 9 | Accepted by Thad 2026-11-23. Keep: building the sheet's screenshot from a real job's record when screenshot mode can't fly. Change: the starter bug in screenshot mode keeps forcing workarounds; it should be fixed soon |
| 6 | 2026-11-23 | Screenshot mode flies | The cause was the test harness, not the game: it held the starter (and timed the hung start and the flight) by the wall clock, while the game counts in game time; under a slow display game time falls behind, so the test let go before the engine could catch. Waits now run on game time; the watchdog allows 30 min with a display. A `--shot` run now plays the whole rescue and passes (start failures true, take-off checklist all five, 92 screenshots); the flooded-start screenshot workaround is gone. Definition-of-done set 9 of 9; watchdog proof both ways | Accepted by Thad 2026-11-23. Keep: printing the game's own counters next to the test's, which showed the clock mismatch at once. Change: test waits should always count game time |
| 7 | 2026-11-23 | A task list with states (P3) | T opens the job's task list (a fifth pocket): the walk-around, each written-up fault, each thing heard but not tracked down (named by its next test), run-up, cowl, parking, fuel, logbook, fly out. Four states with symbol and word: Done, Can't be done, Try again, To do. Built from what you know only. Self-test check 73 covers all four states and that unfound faults never show. Definition-of-done set 9 of 9 | Accepted by Thad 2026-11-23. Keep: deciding up front what the list must never show (unfound faults) and testing that. Change: the screenshot showed only To do on a fresh job; a mid-job shot with all four states would review better |
| 8 | 2026-11-23 | Error-activated guidance (E4) | Five mistakes switch on help aimed at them, for the next try only: a wrong mag call puts the rule on the cockpit card (Hard too); a wrong verdict offers the manual page for the test; an entry sent back shows what the inspector wants; running it unready marks the remaining don't-run-it-yet items; a ground loop brings a straight-line rudder cue. Each logs when it appears. Self-test: each absent before, shown after, gone after the next try. Definition-of-done set 9 of 9; screenshot run passes | Accepted by Thad 2026-11-23. Keep: testing "absent before" as well as "shown after", which is what proves better players never see it. Change: none |
| 9 | 2026-11-23 | Achievement badges (P8) | Eight badges, one per skill, earned once at the moment the standard is met (Sharp Eyes, To Spec, Reads the Drop, Detective, By the Book, Clean Start, Straight and True, Clean Job); banner, chime and play-log line on earning; the board atop the logbook shows earned and not yet with each standard; task list and cockpit card name what's on offer. Self-test: exactly the two earned whose standards the run met, the four it missed withheld. Definition-of-done set 9 of 9; screenshot run passes | Accepted by Thad 2026-11-23 (before verification finished; it then passed). Keep: deriving each badge from a mistake record that already exists. Change: don't edit scripts while a verification run is still launching tests from the working tree |
| 10 | 2026-11-23 | Achievement tracker on the main screen (P13) | The eight badges as a row of small icons, bottom centre, greyed until earned, coloured in with a pulse and the name shown for a moment; hidden over sheets, jobs and the cockpit; refreshed after a load. Self-test: icons per badge, shown in the world, hidden over a sheet. Definition-of-done set 9 of 9; screenshot run passes | Accepted by Thad 2026-11-23. Keep: running the screenshot mode, which caught a check that only passed headless. Change: a check that reads the HUD should refresh it first rather than count on frame timing |
| 11 | 2026-11-23 | Job status: a career ladder (P19) | Apprentice, A&P Mechanic, Lead Mechanic, IA, earned from the record (planes, clean jobs, badges, no recent comeback) and never lost; Lead pays 10% more, IA 20% and opens annual inspections (none below IA); the logbook shows rank, next and what it needs; promotion banner on delivery; older careers get the rank their record earns. Self-test: promotion, holding back, the raise, no annual below IA. Definition-of-done set 9 of 9; screenshot run passes | Accepted by Thad 2026-11-23. Keep: stating in the game that the ladder's numbers are game rules, not FAA requirements. Change: seed both random generators when a test compares two spawned calls |
| 12 | 2026-11-23 | An economy that teaches (P7) | Pay follows the objective: +$300 per step of a call's rating, the rank's raise, and outgrown work discounted 10% a step below the career level (floor 70%, lesson calls exempt); amounts in `ECONOMY`, marked game balance for playtest tuning. Self-test: harder pays more, easy pays less later, floor and exemption hold. Definition-of-done set 9 of 9; screenshot run passes (map shows rating and pay) | Accepted by Thad 2026-11-23. Keep: one pay function (`_pay_for`) the spawn and the test both use. Change: the amounts need a playtest; P4 (difficulty from performance) should come before more tuning |
| 13 | 2026-11-23 | Difficulty that follows performance (P4) | Form from the last three debriefs (+1 clean, -1 rough) pitches the career ramp for new calls, never below a fresh career; the debrief says whether the next calls lean tougher, the same or steadier. Self-test, same seeds: mean call rating 3.69 after strong work against 1.88 after a struggle. Definition-of-done set 9 of 9; screenshot run passes | Keep: measuring the effect (mean ratings) rather than only that the code ran. Change: the economy (P7) and form now interact; a playtest should tune both together |

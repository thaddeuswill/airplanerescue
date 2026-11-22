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
| 1 | 2026-11-23 | The learning design: Mager's three questions and the four flow conditions for every part of the game | `docs/LEARNING_DESIGN.md`: 5 lesson aspects, 10 systems, 11 menus; every measure tied to code or a self-test check; 7 gaps, each a backlog item (G1-G5, G7, and item 5 for G6) | Keep: verifying every code reference before writing it down. Change: the self-test hang showed up in the definition-of-done run; it should be fixed soon, as it weakens the gate |

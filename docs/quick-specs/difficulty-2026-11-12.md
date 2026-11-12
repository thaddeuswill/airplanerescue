# Quick Design Spec: Easy, medium and hard

**Type**: New Small System
**System**: Guidance: markers, clues, the work order, the run-up, work scenes, sign-off (`main.gd`, `work.gd`)
**GDD Reference**: none: `CLAUDE.md` and `docs/quick-specs/run-it-unready-2026-11-12.md`
**Date**: 2026-11-12

## Overview

One setting decides how much the game tells you. **Easy** is an apprentice with the boss watching:
it points at the work, says why a step can't happen yet, and won't let you start an engine you know
isn't ready. **Medium** is a licensed mechanic: you get the facts and the paperwork, and the
mistakes are yours. **Hard** is the real job: nobody tells you what to do next, when you can run
it, or whether it's ready to sign off. You have the plane, the tools and the manual (M), and
signing off something unairworthy comes back on you.

The setting is on the title screen and can be changed any time. It's saved with the career.
Existing saves start on Medium, the closest to how the game played before.

## Core Rules

| Guidance | Easy | Medium | Hard |
|---|---|---|---|
| Spot markers over the plane | `?` unchecked, `!` work waiting, `OK` | `?` only | none |
| Walk-around clues | What you see, and what it means | Same | What you see only ("an engine that sat this long can't be cranked dry: pre-oil it first" becomes "a dry varnish film on the dipstick, and the log shows no run in years") |
| Troubleshooting: which test next | Named, and at which spot | Same | Not named. Every test at your spot is offered; the wrong one reads normal and costs time |
| Where to do a repair | "Work on it at the engine" | Same | Just the finding |
| Run-up with known don't-run-it work undone | Refuses and says why | Runs: parts break (see the run-it-unready spec) | Same as Medium |
| Run-up that won't start | Says what's stopping it and "can't run it up until that's fixed" | Same | Only what happened |
| Work scene: blocked step | Says what's in the way ("Take off the cowl first") | Same | "Not yet." |
| Work scene: tool for a step | Shown on hover | Shown | Not shown: the wrong tool says "Wrong tool for that." |
| Work scene: task labels on the hotspots | Shown | Shown | Only on hover |
| Sign-off | The "Airworthy!" checklist; take-off only once it's all done | Same | "Sign off & take off" from the cabin whenever it's fuelled and outside. No airworthy stamp |
| Signing off with work still open | Can't | Can't | A comeback: the owner's next mechanic finds it. Pay drops by twice each missed part's cost plus $200 per item. A missed no-field-fix fault (metal in the oil, prop strike) pays nothing |
| Wrong verdict or quiz answer | Costs time | Costs time | Costs time |

Things that are just the world are the same on every level: the fuel gauge and "needs half tanks",
the hangar door, part stock, the manual, and the readings themselves.

## Tuning Knobs

- `DIFFICULTIES` in `main.gd` (the names and title-screen lines), and `guide(level)`: guidance
  tagged `easy` shows only on Easy, guidance tagged `medium` on Easy and Medium.
- `HARD_CLUES`: the observation-only clue text.
- The comeback penalty, in `_sign_off`.

## Acceptance Criteria

- [ ] Easy: a run-up with a found `pre_oil` refuses, says why, and breaks nothing.
- [ ] Medium: the same run-up breaks the cylinder (unchanged behavior).
- [ ] Hard: no markers. The pre-oil clue is observation only. Test rows list every test at the
  spot, and a wrong test reads normal and costs time.
- [ ] Hard: take-off is offered with work open, and signing off with an open fault pays less and
  logs a comeback.
- [ ] The setting saves, loads, and an old save without it reads as Medium.
- [ ] The self-test passes on all three levels.

## Not yet (later passes)

- Hard: fault names in the work order still name the diagnosis once found ("Sticking valve"). A
  later pass could show only what you saw, and make you pick the repair.
- Difficulty-specific pay (more for Hard).

## Career ramp (every difficulty)

The calls get harder as you rescue more planes (`rescued`, out of the 10 to win). It's set in `_spawn_job`.

| Rescues so far | 0-1 | 2-3 | 4-5 | 6-7 | 8-9 |
|---|---|---|---|---|---|
| Faults per plane | 1-2 | 1-3 | 2-4 | 2-5 | 3-5 |
| Faults that need troubleshooting | no | yes | yes | yes | yes |
| Longest a plane sat (years) | 4-5 | 7-8 | 10-11 | 13-14 | 15 |
| Unfixable planes (6%) | no | yes | yes | yes | yes |
| Annuals, no complaints (15%) | no | from 3 | yes | yes | yes |
| Owner's patience (days) | 7-15 | 7-15 | 6-14 | 6-14 | 5-13 |

Sitting longer brings the neglect faults with it: 5+ years means a dry or pickled engine, and 8+
can mean a seized door pin and tired shock cords. Pay already follows the work: twice the parts,
plus $150 per year sat.

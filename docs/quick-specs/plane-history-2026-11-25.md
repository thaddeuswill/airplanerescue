# The plane's history, deeper (H1)

**Status**: built, iteration 35
**Date**: 2026-11-25
**Code**: `main.LOG_CLUES`, `STORAGE_WHY`, `PAST_OWNERS`, `plane_logbook`, `_open_papers`;
self-test `_history_ok` (from `_papers_ok`)

## Why

Thad, 2026-11-25: "i think the history of the airplane on the log books lets expand on that". The
papers on arrival (M1) showed three generic entries that told a mechanic nothing. Reading the
logbooks is real A&P work: what's missing, who signed, what was put off.

## What

- Six to eight entries, newest first, with tach times (the game's own, as before), paged on the
  papers sheet. A plane with many faults can run longer.
- **Trails**: 26 faults leave entries that point toward them without naming the fault or its part:
  - a missing entry: on a plane with its oil long overdue, the newest oil change is the oldest
    entry, hundreds of hours back, and no other oil change appears;
  - work signed by someone who can't sign for it: the left ignition unit overhauled at home by the
    owner, signed "owner (no certificate number)";
  - a follow-up never logged: a wood prop reinstalled "to be re-torqued after the first runs";
  - the same fix again: the brakes adjusted twice a few hours apart;
  - a finding put off: flakes, paste or specks in a cut-open oil filter, "owner to monitor" (on the
    grounded metal-in-the-oil faults);
  - work that leads to it: painted fuel caps and all (a plugged vent), a speaker on the panel
    (the compass), a new radio with no clamps (a chafed wire), new tires and cushions (weight and
    balance), cracked cap gaskets (water in the fuel), and others.
- **Its past**: a sale to a past owner ("Logbooks transferred with the airplane"), and why it sat
  if it did ("The owner's medical lapsed").
- Nothing misleading on purpose yet: a trail appears only for a fault the plane has; generic entries
  that would contradict a trail are left out on that plane.
- The same plane reads the same every time (built from its registration and faults). No save change.

## Acceptance

- Self-test, for every fault with a trail: a plane with it shows its entries; none names its fault
  or part; a plane without it doesn't show it; six or more entries, tach falling and above zero;
  the oil-change trail is the oldest, 300+ hours before the next.
- On the run's own plane every trail entry matches one of its faults; the papers still close to
  the walk-around.
- Ten runs and the screenshot run (a plane with its oil overdue and a bad magneto) pass.

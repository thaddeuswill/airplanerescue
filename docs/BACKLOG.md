# Backlog

Ordered: the top is next. Thad sets the order (`docs/PROCESS.md`). Each item has its acceptance
criteria. Done items move to the iteration log in `docs/PROCESS.md`.

## Current iteration

(None. Iteration 8 is in review; see the log in `docs/PROCESS.md`.)

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
- ~~**G3. Judge the mag drop.**~~ Done in iteration 3. On the run-up the player calls each mag good or bad before the game
  says (75 rpm max, C-85); a wrong call is explained and costs time, not money. Acceptance: the
  call is on the cockpit checklist; self-test covers right and wrong calls.
- **G4. Learning events in the play log.** Count wrong verdicts per fault, purchases the job didn't
  need, spots skipped at sign-off, and run-ups with "don't run it yet" work open. Acceptance: each
  writes a play-log line; a self-test check reads them.
- **G5. Help fading in repairs.** Count H-hint uses and wrong-tool attempts per job. Acceptance:
  play-log lines; the numbers fall across a career in a scripted self-test.
- **G7. One overlay at a time.** Tick slips wait while a walkthrough, the tour or a notes card is
  open, then show. Acceptance: screenshot; self-test check that slips are held.

## Learning-game elements (2026-11-23)

- ~~**E1. Map the game against the five categories**~~ In iteration 4.

- **E2. Replay a lesson or a job.** From the title screen or the logbook: play any of the three
  lessons again, or a job you've done, without touching your career. Acceptance: a replay leaves
  the career save unchanged; self-test checks it.
- **E3. Open a walkthrough again.** A "?" on each menu (or F1) shows its walkthrough any time.
  Acceptance: every menu with a walkthrough has the way back in; self-test opens one a second time.
- ~~**E4. Error-activated guidance**~~ In iteration 8. (the pattern, 2026-11-23). A specific error, or a pattern of them,
  switches on help aimed at that error, for a limited time so nobody leans on it; better players
  never see it. Each error type gets its own aid: a wrong mag call puts the 75 rpm limit and the
  three cases on the cockpit card (even on Hard) for that run-up; a wrong verdict opens the
  manual's page for that test; a logbook entry sent back shows the approved-data wording beside
  the choices; running it unready lights the "don't run it yet" items on the work order; a ground
  loop shows the rudder cue on the next take-off. Each aid lasts one attempt or a minute, then
  goes; the next error brings it back. Acceptance: each trigger shows its aid, the aid expires,
  and a player who makes no errors never sees one; self-test covers each.
- **P1. Missions.** Each rescue call as a mission with a clear start and end state, the next set
  of learning objectives (and earlier ones mixed in), changing contexts so learning generalizes, a
  thread of story across calls, and a choice between several calls. The game has the shape (a call
  to delivery, three calls to choose from) but not the targeting or the story. Acceptance: after
  the apprenticeship each call names what it practises; calls tie into a running story (with F2);
  the ramp in `_spawn_job` picks faults for the next objectives.
- **P2. On-demand objectives list.** A key (and an icon) opens this job's objectives in the game's
  terms without giving away the answer ("Find out why it runs rough", not "Replace the plugs"),
  updated as the job changes. Acceptance: available any time at a field after the apprenticeship;
  never names a fault you haven't found; self-test checks it.
- ~~**P3. Task completion list with states.**~~ In iteration 7. For the job in hand: done (green check), failed and
  can't be retried (red cross), tried and can be retried (yellow flag), not tried yet (grey
  question mark). Extends the apprentice checklist to every job, on demand so it doesn't take the
  screen. Acceptance: each state shows in the right case; self-test covers all four.

- **P4. Performance-proportional difficulty.** After each job, assess how it went (the debrief's
  record: wrong calls, verdicts, comebacks, days) and pick the next calls' difficulty from it:
  harder for strong play, easier for weak, so any player can win. Vary the factors that matter for
  the objectives (faults per plane, troubleshooting, look-alikes, scaffolding such as hints and
  limits on the card, deadlines). Pay rises with difficulty. Strongest at the start and the end of
  a career. Acceptance: a scripted strong career gets harder calls than a scripted weak one;
  success still means fixing the plane right; self-test covers both.

- **P5. A familiarization exercise after the apprenticeship.** Low-stress tasks in the real setting
  that walk the player through parts of the hangar and field they haven't needed yet (the parts
  table, the radio, the TOOLS box, the hangar doors, pushing the plane in and out, the fuel truck),
  with nothing at stake, to cut later overload and help transfer. (The pattern's name was cut off
  in the source page; its description fits a familiarization or orientation exercise.)
  Acceptance: offered once after job 3; every task touches a place not yet used; no money or
  deadline; self-test plays it.
- **P6. Every fault as a problem-solving exercise.** Check each fault against the pattern: a
  specific problem, the tools to solve it, and solving it means applying the learning objective
  through natural actions (no menu answer standing in for the skill). Acceptance: a table in
  `docs/LEARNING_DESIGN.md` of every fault, its objective and the action that demonstrates it; any
  fault where a menu stands in for the skill becomes a backlog item.

- **P7. An economy that teaches.** Transactions should reflect the trade-offs the objectives teach.
  Today money and time are two currencies and tools buy capability. Missing: pay that rises with the
  difficulty of the objective a job exercises (not just its parts), easier, earlier kinds of job
  paying less as the career moves on, and spending that unlocks new kinds of work. Playtest to
  tune it. Acceptance: pay per call follows `call_difficulty`; a scripted career shows easy calls
  paying less later; self-test covers it. (The pattern's name was cut off in the source page.)
- **A1. Audit actions against the seven criteria.** (a) easy to understand and use; (b) not too many
  possibilities at once, especially for weaker players; (c) efficient, steady progress toward the
  objectives; (d) choices that fit the current context; (e) never giving the answer away by
  accident; (f) supporting the instructional methods and sequence; (g) actions introduced so they
  build agency and fit the story. Every action in the game against each, with fixes as backlog
  items. Acceptance: a table in `docs/LEARNING_DESIGN.md`; every "no" a backlog item.

- **P8. Achievement badges.** A badge per skill, earned by meeting the standard for that learning
  objective (`docs/LEARNING_DESIGN.md`, "mastered by the end"): torque to spec first try, both mags
  called right, a troubleshooting chain with no wrong calls, a clean walk-around (nothing missed),
  a correct logbook entry first time, a clean start, a debrief with nothing extra. Grouped by
  system; a badge board (a pocket or the hangar wall, with P2's tally) shows earned and not yet
  earned; activities that can earn one show its small icon. Acceptance: each badge awarded only
  when its standard is met; the board shows both; self-test awards one and withholds one.
- **P9. Task order as evidence** (the assigned-task pattern). The game already always has a task
  (next-step icon, checklist, task list) and makes completion clear. Missing: recording the order
  a player does a procedure's steps in (walk-around before run-up, the don't-run-it-yet items
  first, test before verdict), since order shows understanding. Acceptance: a play-log line per
  task completed, in order; the debrief notes an order that cost something; self-test checks the
  lines.
- **P10. Iconic directions.** The game's icons (next-step icon, ? and ! markers, the task-state
  symbols) should draw the eye when they change (a brief pulse or a sound) and be playtested so
  players read them right. Acceptance: a pulse when the next-step icon or a marker changes;
  a playtest note in `docs/` with what players took each icon to mean.

- **P11. Real-world supplementary activities.** Before and after play, tied to the real world with as
  few trips out of the game as possible: (a) before a job type, a short reading list (its service
  manual chapter and the AC 43.13-1B section, from `reference/`); (b) after a session, an
  after-action review the player or an instructor can print: each job's debrief, the play-log
  learning events (mag calls, verdicts, aids shown), and what to review; (c) a follow-up quiz per
  ATA chapter for the jobs done. Acceptance: the review exports from the logbook to a file; the
  reading list shows on the call; quiz questions come from the manual data, never invented
  values; self-test checks the export.

## Fun (Lazzaro's four types, 2026-11-23)

Hard fun is the core (mastering real procedures) and serious fun comes from the repair ritual.
Easy fun is weak and social fun barely there; top games have at least three of the four.

- **F1. Odd things found in planes** (easy fun: surprise, curiosity). Now and then a spot holds
  something with a story: an old logbook page, a tool left in 1946, a mouse nest with a lost ring.
  No effect on the job; it goes on the hangar wall. Acceptance: shows once per find; self-test
  checks a find is recorded and shown.
- **F2. Owners with stories who call you back** (social fun: bonding). Owners you've saved call
  again years later with the same plane; their squawk mentions your last job. Acceptance: a
  returning owner's call names your earlier work; self-test covers one return.
- **F3. The same-plane challenge** (social fun: fiero, rivalry, offline). A short job code; enter
  it and you get the same plane and faults; the logbook shows days and cost to compare.
  Acceptance: the same code gives the same job; self-test checks it.
- **F4. Keep the repair ritual a choice** (serious fun). Note on item 4: "Do it the way you know"
  is offered, never forced; the hands-on way stays the default.

## Bugs and debts

- **README controls are out of date** (says M for the manual; it's N). Acceptance: README matches
  the bindings.

## Process items

(None. Requests to change how we work go here and are decided between iterations.)

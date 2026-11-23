# Backlog

Ordered: the top is next. Thad sets the order (`docs/PROCESS.md`). Each item has its acceptance
criteria. Done items move to the iteration log in `docs/PROCESS.md`.

## Current iteration

**Iteration 15 (2026-11-23): the end-of-mission screen, redone (D3).**

- **Goal**: the debrief as a centred glass card: gains in green, losses in red, the job's stats and
  what it earned.
- **Items**: a centred card on a translucent, blurred earth-glass panel (the scene shows through);
  money as a column of signed figures (+ green, − red, the net by its sign), the extra costs in red;
  stats (planes rescued, spots checked, faults fixed, cash in hand); achievements: badges earned on
  this job (recorded as they're earned) and a promotion; the advice and form line kept; the
  RESCUED banner gives way to the card, which carries its words.
- **Risk gate**: design system: its mood says "not glassy"; Thad asked for glass, so the product
  owner's call wins for this screen, kept in the system's earth, brass and cream with two new HUD
  tokens for gain and loss, contrast checked over the brightest scene (white snow): green 6.6:1,
  red 5.4:1. Colour never alone: every figure carries its + or − sign. Saves: the logbook's
  debrief gains `badges` and `promoted`, read with defaults, so old entries still open; no
  `SAVE_VERSION` bump. Layout: centred at 1280x720 and 1920x1080, screenshots. Flow: the button
  and Esc behave as before (on to the map; Esc closes). Checks: self-test reads the card's colours
  by sign, the badge list (earned this job only, "none" when none), and that it's centred.
- **Acceptance**: as D3 below.

## Next

- ~~**D3. The end-of-mission screen, redone** (Thad, 2026-11-23: "in the middle of the screen glassy
  background with colors of green and red for the positive and negative and the stats and
  achievements").~~ In iteration 15. The debrief moves from the paper sheet on the left to a card centred on screen,
  on a translucent glass panel with the rescue scene showing through. Money in green (pay, net when
  positive) and red (fuel, parts, rent, each extra cost, net when negative). Shows the job's stats
  and the achievements: badges earned on this job, and any promotion. Big Shoulders and Courier
  Prime figures per the design system. Acceptance: centred at 1280x720 and larger windows; every
  figure coloured by its sign; badges earned on the job listed, none when none; the "Next time"
  advice and form line kept; self-test checks the colours and the badge list; screenshots.

- **D2. No days counted, no job timed** (Thad, 2026-11-23, in three steps: "i dont want any clock
  time unless it has anything to do with your score or achievements"; "rent days can stay but
  anything maintenance wise with days should go"; then "i dont want days to be counted or how long a
  job takes").
  - **What it means:** the game stops keeping a day count (`day`, `_advance`) and stops timing jobs.
    Every day figure and every "a day's wait", "half a day lost", "x days on site" goes.
  - **What runs on days today, each needing a replacement (Thad to choose):**
    - Rent is charged per day. Option: a flat hangar fee per job, shown as money.
    - Calls expire when the owner's wait runs out. Option: calls don't expire.
    - Guessing costs time (settled in CLAUDE.md: a wrong verdict, a wrong mag call). Option: a
      wrong guess costs money instead (a small charge), or costs nothing but the try.
    - Mail order arrives "in a day". Option: it arrives at once for its 25% markup.
    - Odd jobs take 3 days. Option: they just pay.
    - Difficulty ratings use the deadline's tightness; the economy pays for it. Option: drop that
      term from the rating.
  - **Saves:** `day` and job deadlines are saved; a `SAVE_VERSION` bump and a `_migrate` step.
  - Acceptance: no day figure anywhere the player looks (self-test reads every sheet, the HUD and
    the cards); the replacements above work as chosen; old saves load.

- **T1. A parse error must fail the self-test, not hang it** (found in iteration 14, proposed by
  Claude). The watchdog lives in `selftest.gd`, so a script that doesn't parse leaves Godot idle
  with no output until something outside kills it. Acceptance: a deliberate parse error ends the
  run non-zero within a minute, saying where.

- ~~**D1. Take days and hours off the debrief** (Thad, 2026-11-23: "it adds nothing to the game").~~ In iteration 14.
  The sheet drops "x days on site" and the time each extra cost took ("0.4 days", "3 h"); money
  stays (pay, fuel, parts, rent, net, and the dollars of each extra cost). A time-only mistake (a
  wrong verdict, a wrong mag call) still shows, by what happened, with no figure. Acceptance:
  self-test reads the sheet and finds no day or hour figure; the debrief advice still names the
  biggest extra; screenshot at 1280x720.

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

- ~~**P4. Performance-proportional difficulty.**~~ In iteration 13. After each job, assess how it went (the debrief's
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
- **P6. Every fault as a problem-solving exercise, applied directly** (with the apply-method-directly
  pattern, 2026-11-23). Check each fault against both patterns: a specific problem, the tools to
  solve it, and solving it means doing the real action in a realistic setting (hold the fastener,
  read the needle or the tach, trace the lead), with little abstraction and room to do it wrong in
  a natural way. Known gaps: troubleshooting verdicts and the logbook entry are picked from lists,
  so a menu stands in for the skill (e.g. the verdict could become pointing at the cylinder or
  the part the reading implicates; the entry could be assembled from the job's own record).
  Acceptance: a table in `docs/LEARNING_DESIGN.md` of every fault, its objective and the action
  that shows it; every place a menu stands in for the skill becomes a backlog item.
- ~~**P7. An economy that teaches.**~~ In iteration 12. Transactions should reflect the trade-offs the objectives teach.
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

- ~~**P8. Achievement badges.**~~ In iteration 9. A badge per skill, earned by meeting the standard for that learning
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

- **P12. Exploration constraints in early jobs.** The map already locks other calls during the
  lessons, with a clear "Locked" and why. Decide whether early jobs should also fence off parts of
  the field (the hangar's catalog, the radio) with easy-to-read signs, to cut load. Acceptance: a
  decision recorded; if yes, each constraint has a visible reason and lifts on schedule.
- ~~**P13. Achievement tracker on the main screen.**~~ In iteration 10. The eight badges as a row of small greyed icons
  on the HUD that colour in, with a sound, when earned; ordered by the process (walk-around to
  flight). Acceptance: shown at a field, out of the way of the squawk and next-step icon; colours in
  on earning; screenshot.
- **P14. Unlock by demonstrated objectives.** New kinds of call open when the player has shown the
  skills they need (e.g. Detective opens troubleshooting-heavy calls, Reads the Drop opens
  ignition work), instead of only by rescue count; transitions make sense in the story.
  Acceptance: each kind of call names its prerequisites; self-test unlocks one by earning its badge.
- **P15. Natural information sources.** The game uses the squawk sheet, the service manual, the
  logbook and the owner on the radio. Add a hangar bulletin board with notices (an airworthiness
  alert, parts on special, a regular's thanks) that point at what to look at next. Acceptance:
  a notice can lead to a finding; nothing on it is invented data.
- **P16. Instructional affordances in the spot views.** The work scenes turn the cursor into the
  tool in your hand; the spot views and the walk-around don't. A magnifier over a part you can
  look closer at, the tool when the part offers a job with it. Acceptance: the cursor changes
  over parts; playtest note on how players read it.

- **P17. A challenge bonus.** The game has player-chosen difficulty both ways: Easy, Medium, Hard for
  the career (guidance falling), and each call's rating, 1 to 5, chosen on the map. Missing: pay
  that rises with the call's rating (a challenge multiplier) and a bonus for a job done with no aid
  switched on (E4) and no guidance needed. Pairs with P7. Acceptance: pay shown per call follows its
  rating; the bonus shows on the debrief when earned; self-test covers both.

- **P18. A planning exercise before each call.** Taking a call asks for a short plan, in the game's
  terms: which parts and tools to bring (they ride in the truck), which spots to check first, and
  a guess at what's wrong from the squawk. The plan shapes what's at hand on site; the debrief
  compares it with what happened. Natural, not a form: picking from the parts shed and a few
  checkboxes on the call sheet. Acceptance: the plan is optional on Easy; the debrief shows plan
  against outcome; self-test covers a plan that matched and one that didn't.

- ~~**P19. Job status: a career ladder.**~~ In iteration 11. Good reports (clean debriefs, badges, no comebacks, owners
  who call back) move you up: Apprentice (the lessons), A&P Mechanic, Lead Mechanic, then an
  Inspection Authorization (IA). Each rung is a tangible benefit: better pay, harder and better
  work. In real life annual inspections need an IA, so annual calls open only once you hold one.
  Pairs with P14 (unlock by demonstrated objectives) and P7 (the economy). Acceptance: each rung
  names what earns it and what it opens; the logbook shows your rung and the next; self-test
  promotes on the record and holds back without it.

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

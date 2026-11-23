# Learning design

Iteration 1 (2026-11-23). Every part of the game, against two frames:

- **Mager's three questions** (Mager, 1984): the **goal** (what the player must know or do), the
  **method** (how the game teaches it: methods and media), the **measure** (how we know they've
  learned it: what the game checks).
- **The four conditions of flow**: **goals** (they always know what they're trying to do),
  **feedback** (they know at once how they're doing), **balance** (the challenge fits their skill and
  rises with it), **few distractions** (nothing pulls them out of the task).

Every measure and flow claim names the code or self-test check behind it. Where there's none, it's
marked **gap** with the backlog item that closes it (`docs/BACKLOG.md`, items G1-G7).

---

## A. The apprenticeship

### A1. The tour (home base, first launch)
| | |
|---|---|
| Goal | Know what the game is for (ten planes back in the air, don't go broke) and where the controls and pockets are |
| Method | Six cards, each pointing at what it explains, the rest dimmed; keys from the bindings (`tutorial.gd _tour_pages`) |
| Measure | Tour finished or skipped (`tut.tour`, the "Get your bearings" tick). **Gap G2:** nothing measures whether they then use the pockets |
| Flow | **Goals** the first card states the goal and the risk. **Feedback** n of 6 on each card. **Balance** four short ideas, no task yet. **Distractions** the world is frozen behind it (`player.frozen`) |

### A2. Lesson 1: your first rescue (bird nest or water in the fuel)
| | |
|---|---|
| Goal | Do the whole loop once: call, squawk, walk-around, write-up, fix, run-up, sign, fuel, fly |
| Method | Learning by doing with a self-ticking checklist; only the current step is explained (`tutorial.gd steps`); a reward card names what was learned |
| Measure | Each step ticks from game state, never a button (`tutorial.gd _poll`). Self-test `--tutorial=1` checks every step ticked by delivery, the bonus paid and lesson 2 began |
| Flow | **Goals** the checklist and its current line. **Feedback** a drawn check, pen scratch and a slip at the top, over any sheet. **Balance** one fault, starter tools only, a clean plane, one open call (`call_locked`). **Distractions** other calls locked; **gap G7:** a slip can draw over an open walkthrough |

### A3. Lesson 2: tools of the trade (flat main tire)
| | |
|---|---|
| Goal | Buy the tools and part a job needs; know that mail order is a day and 25% more |
| Method | A job that needs two tools you don't own (`_missing_tools`); NEEDED stamps in the shops (`job_needs`); the shop walkthrough's tool guide |
| Measure | "Get the tools" and "Get the part" ticks (`tutorial.gd steps`); `--tutorial=2`. **Gap G4:** no measure of buying things the job didn't need |
| Flow | **Goals** the step names the missing tools. **Feedback** NEEDED stamps, the tick. **Balance** one new idea (logistics) on a familiar loop. **Distractions** as A2 |

### A4. Lesson 3: listen to the engine (sticking valve)
| | |
|---|---|
| Goal | Find a fault with no outside sign: hear it on the run-up, prove it with an instrument, make the call |
| Method | The compression tester as lesson 2's reward; steps for listen, take the tester, prove it (`tutorial.gd steps`) |
| Measure | Ticks; `--tutorial=3`; a wrong verdict costs time (`_verdict`). **Gap G4:** wrong verdicts aren't counted per fault |
| Flow | **Goals** each step. **Feedback** test readings, the verdict. **Balance** the first troubleshooting, with the instrument already in hand. **Distractions** as A2 |

### A5. Reading the squawk
| | |
|---|---|
| Goal | Turn what the pilot felt, heard, saw or smelled into where to look first |
| Method | Notes card on arrival: each telling phrase and what it means, then "Look first" (`tutorial.gd NOTES`, `_show_notes`); the note stays pinned under the squawk (`squawk_note`) |
| Measure | **Gap G1:** reading is ticked by the Go look button; nothing checks the first spot they then open against the note |
| Flow | **Goals** "Look first" names the spot. **Feedback** **gap G1** (nothing confirms the first look was right). **Balance** four lesson faults, written for. **Distractions** one card, one button |

---

## B. The systems

### B1. Walk-around
| | |
|---|---|
| Goal | Check all eight spots and know what each can hide |
| Method | Floating markers: ? unchecked, ! written up (`_refresh_markers`); two hours a spot (`_inspect_zone`) |
| Measure | `job.checked`; a skipped fault strikes on the climb-out or comes back as a comeback deduction (`_sign_off`). Self-test 68 (the walk-around finds what's visible) and 69 (! stays until fixed) |
| Flow | **Goals** the next-step icon and markers (`_objective`). **Feedback** markers change; "N of 8 spots". **Balance** the time cost against the deadline; Hard hides the ? markers. **Distractions** minimal HUD (`_update_hud`) |

### B2. Write-up (finding)
| | |
|---|---|
| Goal | Find a visible fault on the real part and write it up |
| Method | Painted spot views with the damage drawn on the part (`bay.gd _draw_pieces`, tells); Look closer (`bay_look`); a full write-up (`writeup`) |
| Measure | `job.found`; self-test 70 (a written-up job is first on its part's card) |
| Flow | **Goals** the red ! and the red button. **Feedback** the write-up toast, the ! appears. **Balance** tells loud on Easy, faint on Hard. **Distractions** one card at a time |

### B3. Repair (work scenes)
| | |
|---|---|
| Goal | Take a job apart and put it back: the right tool, the right order, nothing left loose |
| Method | Hold-to-turn fasteners, the tool roll, the bench and tray; H shows every possible step; the step pulses after 20 s idle (`IDLE_HINT`, `_draw_next_marks`) |
| Measure | The job finishes only complete (`work.gd`); every scene solvable (`_scene_tests`); no tools means nothing comes apart (self-test 120, 122). **Gap G5:** hint uses and wrong-tool attempts aren't counted, so we can't see help fading |
| Flow | **Goals** "N of M steps in place". **Feedback** sounds per action, pieces fly to the bench, a blocked step says why. **Balance** **gap:** the fifth oil change plays like the first (backlog item 4, "do it the way you know"). **Distractions** the world is hidden behind the scene |

### B4. Torque
| | |
|---|---|
| Goal | Bring plugs (300-360 in-lb) and wood prop bolts (175-225 in-lb) into the band and hold them |
| Method | A needle that sags; click to bring it up; it has to stay in the green (`work.gd RANGE`) |
| Measure | The wrench clicks only in the band (`_torque_test`) |
| Flow | **Goals** the band on the gauge. **Feedback** the needle, the click. **Balance** the sag rate. **Distractions** none |

### B5. Run-up
| | |
|---|---|
| Goal | Start it, hold 2,100 rpm, read each mag's drop (75 max), check carb heat |
| Method | The cockpit checklist card with live readings (`preflight.gd`, `ferry.card`); readings written in as taken |
| Measure | The drops are read and logged (`ferry.gd _runup`); running with "don't run it yet" work open breaks a part you pay for (`RUNUP_DAMAGE`); self-test 72. The player calls each mag good or bad (`ferry.gd call_mag`): a wrong call is explained and costs time, and every call writes a play-log line (closed G3, iteration 3) |
| Flow | **Goals** the checklist. **Feedback** the tach, the log lines. **Balance** Easy stops an unready run-up. **Distractions** the cockpit only |

### B6. Troubleshooting
| | |
|---|---|
| Goal | Follow a chain (spark test, plug reading, cold cylinder, compression, oil screen) to the cause |
| Method | The work order names the next test (`_test_for`); tests appear only with the right instrument in hand (`bay.gd actions`); a verdict question |
| Measure | A wrong verdict costs time (`_verdict`). **Gap G4:** not counted per fault |
| Flow | **Goals** "Next: <test>". **Feedback** readings, then the verdict. **Balance** starts at rescue 3 (`_spawn_job`). **Distractions** one test at a time |

### B7. Logistics (shops, tools, parts, money)
| | |
|---|---|
| Goal | Know what to buy and when; shelf or mail; keep enough cash to keep flying |
| Method | NEEDED stamps listed first (`job_needs`); the shop walkthroughs and tool guide; net estimate per call (`call_estimate`) |
| Measure | Money; game over or odd jobs (`_open_game_over`, `_odd_jobs`). **Gap G4:** unneeded purchases aren't counted |
| Flow | **Goals** the stamp. **Feedback** cash on the page, the parts table. **Balance** rent ($40 a day) and mail order's 25%. **Distractions** **gap:** two stores to compare (backlog item 3, merge them) |

### B8. Paperwork (the logbook entry)
| | |
|---|---|
| Goal | Write a correct return-to-service entry: the data you worked to, who signs |
| Method | Three choices each with a reason when wrong (`ENTRY_STEPS`) |
| Measure | A wrong pick costs time and explains why (`_entry_pick`) |
| Flow | **Goals** "Nothing flies until you sign". **Feedback** the reason on a wrong pick. **Balance** **gap:** the same three questions every job (backlog item 4, "same as always"). **Distractions** none |

### B9. Ferry flight
| | |
|---|---|
| Goal | Start the engine by the checklist and take off: full power, centerline, tail up, rotate at about 40 mph, climb |
| Method | The cockpit checklist: before start, the fix for a failed start on a red band, the take-off stages for the first two deliveries (`preflight.gd`) |
| Measure | The start only catches when done right (`ferry.gd _attempt`); ground loops, crashes and aborts are logged (`playlog`, "ferry flight"). Self-test: start failures reach the card, a good take-off ticks all five stages |
| Flow | **Goals** the card. **Feedback** the engine, the tach, the red band with the fix. **Balance** coached twice, then the bare checklist. **Distractions** the cockpit view only |

### B10. Career
| | |
|---|---|
| Goal | Choose calls well, beat deadlines, stay solvent, reach ten rescues |
| Method | The map with difficulty, net estimate and the closest you can afford (`call_difficulty`, `call_estimate`); the ramp in `_spawn_job`; the logbook |
| Measure | `rescued` of `GOAL`; owners giving up; game over. **Gap:** the tally isn't visible where decisions are made (backlog item 2) |
| Flow | **Goals** ten planes (tour card 1, reward cards). **Feedback** pay, logbook, radio news from saved planes. **Balance** faults per plane rise every two rescues; locked calls during the lessons. **Distractions** **gap G6:** after the apprenticeship several new systems can appear at once (backlog item 5, first-time cards) |

---

## C. The menus

Each menu's first-time walkthrough (`tutorial.gd walk_pages`) is its **method**; the menu itself is
its **media**. Shared **measure gap G2**: we log that a walkthrough was seen (`tut.menus`), not what
the player did next.

| Menu | Goal | Measure today |
|---|---|---|
| Work order (J) | Know what's found, what it needs, what's left | Faults move to OK; sign-off unlocks |
| Map | Pick a call you can afford and finish | Fare paid, owner didn't give up |
| Wallet (Tab) | Know cash, parts, tools, rent | None (G2) |
| Logbook (L) | See progress to ten | `rescued` |
| Service manual (N) | Read the page before the job | None (G2) |
| Parts counter / mail order | Buy what's stamped NEEDED | Part in hand when the job needs it; unneeded buys not counted (G4) |
| Red toolbox | Take the instrument the work order asks for | The test appears only with it in hand |
| Job screen and tool roll | Pick the tool, work in order | Job completes |
| Spot views | Look closer, then fix | `job.found`, self-test 70 |
| Fuel truck | Half tanks, on the apron, never on stale gas | Take-off allowed only then |
| Logbook entry | Sign correctly | `_entry_pick` |

Flow for menus as a whole: **goals** each walkthrough opens with one bold line saying the point;
**feedback** NEEDED stamps, OK rows, the ! and ticks; **balance** each walkthrough shows once, the
first time it's needed; **distractions** the walkthrough dims everything but what it describes, and
"Hide walkthroughs" turns them all off.

---

## D. The five categories of learning-game elements (iteration 4)

Goals, Control, Actions, Guidance and Feedback, each with its four subcategories. "Where" names the
code; every name was checked against the source. Gaps are backlog items E2-E5 or earlier items.

### Goals
| Subcategory | Where the game does it | |
|---|---|---|
| Introduce goals | Tour card 1: ten planes, don't go broke (`tutorial.gd _tour_pages`); each lesson's checklist title; the pilot's squawk, pinned top right (`_update_squawk`); the work order (`_open_inspection`) | done |
| Encourage buy-in | Real procedures and real values (the C-85, AC 43.13-1B); the owner's thanks on delivery (`THANKS`, `_sign_off`); radio news from planes you saved; reward cards (`_show_reward`) | done; owners with stories would deepen it (F2) |
| Reinforce goals | The next-step icon (`_objective`); markers ? and ! (`_refresh_markers`); the checklist's current line; the look-first note under the squawk (`squawk_note`) | done |
| Indicate progress | Ticks and slips (`tutorial.gd _poll`); "N of 8 spots"; "N of M steps in place" in a job; "Planes back in the air: N of 10" on reward cards; the logbook | partly: the task list shows each job's progress with its four states (T, iteration 7); the tally isn't where calls are chosen (item 2) |

### Control
| Subcategory | Where the game does it | |
|---|---|---|
| Control progression | The three lessons (`tutorial.gd`); only the lesson's call open during them (`call_locked`); the career ramp (`_spawn_job`): look-alikes and troubleshooting from rescue 3, faults per plane rising every two rescues | done |
| Manage information | Only the current step explained; each walkthrough once (`tut.menus`); part cards fold "Other work here" (`bay.gd _open_card`); paged work order (`_paginate`); the manual opens at your job (`_manual_job`) | done |
| Support replay | A new career; the difficulty per career; work left mid-job stays as you left it | **gap E2:** no way to replay a lesson or a job |
| Provide challenge | Easy, Medium, Hard (`DIFFICULTIES`, `guide`); difficulty per call, 1-5 (`call_difficulty`); deadlines; Hard hides the ? markers and the run-up limit | done |

### Actions
| Subcategory | Where the game does it | |
|---|---|---|
| Deliver activities | Walk-around and spot views (`bay.gd`); a hands-on work scene for every job (`work.gd scenes`); tests; the run-up and ferry flight (`ferry.gd`); shops; the logbook entry | done |
| Elicit behaviors | Tool-gating, the right instrument in hand (`bay.gd actions`); the mag call (`call_mag`); verdicts (`_verdict`); the logbook entry's choices (`_entry_pick`); the gamble on skipping spots | done |
| Enable actions | E to use; the tool roll (wheel or 1-9); part cards; every key rebindable; quick-hold for holds | done |
| Create drivers | Pay and rent ($40 a day, `DAILY_COST`); owner deadlines; the goal of ten; NEEDED stamps (`job_needs`); net estimate per call (`call_estimate`) | done |

### Guidance
| Subcategory | Where the game does it | |
|---|---|---|
| Determine need | Difficulty decides how much help (`guide`); first-time walkthroughs; the first two take-offs coached (`preflight.gd coached`); a job's next step pulses after 20 s idle (`IDLE_HINT`) | done: error-activated aids for wrong mag calls, verdicts, logbook entries, running it unready and ground loops (iteration 8) |
| Give suggestions | The current step's how-to; "closest you can afford"; NEEDED; Easy lists greyed actions with where the tool is; Easy stops an unready run-up | done |
| Provide aids | The service manual (N), with figures; H outlines every possible step (`_draw_next_marks`); D lays the wiring diagram over a job (`show_diagram`); live readings on the cockpit card | done |
| Access guidance | N, H and J any time; the checklist setting | partly: **gap E3**, a walkthrough can't be opened again |

### Feedback
| Subcategory | Where the game does it | |
|---|---|---|
| Convey performance | Ticks and slips; the mag call's right or wrong with the reason; test readings and verdicts; the "!" clearing; the logbook's pay, costs and net | done |
| Give rewards | Pay; lesson bonuses and the compression tester; the owner's thanks; reward cards | done |
| Impose consequences | Running it unready breaks a part you pay for (`RUNUP_DAMAGE`); comebacks cost pay (`_sign_off`); wrong calls and verdicts cost time; owners give up; a crash costs $1,500 (`CRASH_BILL`); game over | done |
| Facilitate reflection | The why line when a job's fixed (`WHY`, `_work_done`); the reward card's "You learned..."; the logbook | done: the debrief on delivery, what cost extra and the advice for next time (`job_debrief`, iteration 5) |

---

### Pause and continue (pattern check, iteration 9)

Done: Esc pauses and hides the world (no exploring while paused); the game saves after every step
and Continue picks up where you left off; pausing changes no score or pay; quitting is blocked
during an emergency in flight (`_can_quit`), the one place timing is the lesson.

### Interact physically (pattern check, 2026-11-23)

Done: the work scenes are physical manipulation tied to the objectives (hold to turn a fastener,
lift panels to the bench, screws to the magnetic tray, fit the new part, torque against the
needle); the field too (jack the wheel, push the plane in and out of the hangar, fuel at the truck).
Wrong manipulations have natural consequences: an over-torque backs the fastener off, running it
unready breaks a part you pay for, the wrong suspect swapped costs its part. Caution kept: no
interaction is added that the learning objectives don't need.

## Gaps (all in `docs/BACKLOG.md`)

| Gap | What's missing | Backlog |
|---|---|---|
| G1 | Squawk: no check that the first spot opened matches the note | G1 |
| G2 | Menus: no record of what the player did after a walkthrough | G2 |
| G3 | ~~Run-up: the player never judges a mag drop~~ closed in iteration 3 | done |
| G4 | Wrong verdicts, unneeded purchases and skipped spots aren't counted | G4 |
| G5 | Repair: hint uses and wrong-tool tries aren't counted | G5 |
| G6 | Balance after the apprenticeship: several new systems at once | item 5 (first-time cards) |
| G7 | Distraction: a tick slip can draw over an open walkthrough | G7 |
| E2 | Support replay: no way to replay a lesson or a job | E2 |
| E3 | Access guidance: a walkthrough can't be opened again | E3 |
| E4 | ~~Determine need~~ closed in iteration 8 (error-activated guidance) | done |
| E5 | ~~Facilitate reflection: no debrief~~ closed in iteration 5 | done |

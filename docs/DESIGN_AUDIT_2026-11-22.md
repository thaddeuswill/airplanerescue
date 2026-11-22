# Design audit: guidance, progress, friction, menus

2026-11-22. Written after the apprenticeship landed (`docs/quick-specs/apprenticeship-2026-11-22.md`).
Part 1 answers the eight design questions. Part 2 checks every screen against the five UX
qualities. Part 3 is the keep / merge / cut list for menus. Part 4 is the analysis-paralysis audit.
Items marked **Done** are in the game; everything else is a recommendation waiting for a yes.

---

## Part 1. The eight questions

### 1. How much do we guide, and how much do we let players explore?

**Rule: guide the controls and the rules; never guide the diagnosis after job 3.**

| Phase | Guidance | Where players explore |
|---|---|---|
| Jobs 1-3 (apprenticeship) | Checklist, one new idea per job, every step explained when it's current | Which spot first, how to take the job apart |
| Easy | Next-step icon, markers, "!" on written-up parts, greyed actions say where the tool is, the boss stops an unready run-up | Which call, which test, the order of work |
| Medium | Next-step icon, markers, facts and paperwork. Mistakes are yours | Everything above, plus whether to check every spot |
| Hard | None: no "?" markers, no clues beyond what you see, no "not ready" warnings. "!" stays (it's your own note) | All of it |

The choices that *are* the game stay open on every difficulty: which call to take, how many spots
to check (time against risk), which test to run, which suspect to replace, shelf against mail order.

### 2. Where would analytics track the choices players make?

There's already a local playtest log (`main.playlog()`, `user://playtest_log.txt`, F8 marks "something's
off here"). It's written only in hand-played sessions and never leaves the machine. Recommended events,
with the function where each is written:

| Question it answers | Event | Where |
|---|---|---|
| Which calls look worth taking? | call taken: pay, miles, days left, fault count, the other calls offered | `_travel` |
| Do players gamble on spots? | spots unchecked at sign-off, and whether a missed fault bit them | `_open_signoff`, `_sign_off` |
| Is the squawk read right? | squawk quiz answer, per fault (tutorial) | `tutorial.gd _show_decode` |
| Which faults get misdiagnosed? | wrong verdicts and wrong suspects, per fault | `_verdict`, the suspect pick |
| Where do players stall? | seconds on each step; idle time inside a work scene | `playlog` already stamps time; `work.gd _idle` |
| Shelf or mail? | part or tool bought: shed or mail order, price | `_buy_supply`, the shop |
| Do they run it unready? | run-up with "don't run it yet" work open, and the damage paid | `_run_up_result` |
| Where do careers end? | owner gave up, game over, the last step before a session ended | `_advance`, `_open_game_over` |
| Is the tutorial working? | each tick (already logged as `tutorial: <step>`), skip, time per lesson | `tutorial.gd` |

Keep it local. If it ever goes online, ask first, send nothing personal, and say so on the title screen.

### 3. What should players feel at each milestone?

| Milestone | Feeling | What makes it land |
|---|---|---|
| Tour, first look at the hangar | "I know what I'm here for" | The point of the game on card 1: ten planes, don't go broke |
| Reading the first squawk | "I can decode this" | The what-the-pilot-means card, every answer explained |
| First write-up | "I found it myself" | "Look closer" on the real part, a red "!" that stays |
| First fix | Competence | Each bolt by hand, the tick and pen scratch |
| First flight out, first pay | Pride, relief | The take-off, owner's thanks, the reward card |
| Job 2, part not on the shelf | Mild pressure, then resourcefulness | Mail order: a day's wait and 25% more, and you still deliver |
| Job 3, the test proves it | The detective's "aha" | A fault with no outside sign, found by the instrument you were just given |
| Graduation | Trust, independence | "You're on your own now", +$500, what's coming |
| First long-sat wreck | Daunted, then proud | Grime, stale fuel, dry engine: a big job that pays more |
| First grounding | Responsibility | Saying no to an owner is the right call, and it's written up |
| Tenth plane | Mastery, legacy | The ending, the logbook of every plane saved |

### 4. What signals show players they're making progress?

**Have now**: checklist ticks and slips (Done); "!" that clears when fixed (Done); markers going
from "?" to "!" to nothing; work-order rows turning "OK"; cash; a tool roll that grows; logbook
entries; "Planes back in the air: N of 10" on the reward card (Done); radio news from planes you saved.

**Missing (recommend)**:
- **A wall of saved planes in the hangar**: a photo per rescue on the wall by the map. You walk past
  your progress every time you take a call.
- **The tally on the map**: "3 of 10 back in the air" in the map's corner, where every career decision starts.
- **A tool board in the hangar** that fills in as you buy tools. Ownership you can see.

### 5. Where might players get stuck?

| Friction | Why | Fix |
|---|---|---|
| Finding the map on day 1 | It's one object on a workbench | **Done**: tour and checklist step 1 name it; the next-step icon is the map |
| What the squawk means | Pilot language, not a diagnosis | **Done** for jobs 1-3 (the quiz). Later: keep the manual's Troubleshooting chapter one key away |
| Run-up happens from the cabin | Not obvious that you sit in | **Done**: checklist step. Recommend: the cabin marker shows a "run-up" icon once the work's done |
| Can't sign off: cowl still open | A rule you learn by failing | Work order says so on Medium; recommend the engine's 3D marker shows "!" while the cowl's open |
| Fuel refused in the hangar | Real rule, surprising | The fuel truck already says why; checklist step mentions the apron (Done) |
| Missing tool mid-job | You learn the roll inside the job | **Done**: job 2 teaches it; the roll says where to get each tool |
| **The ferry start** (flooded, hung start, no fuel) | The checklist, keys and the failure modes arrive at once | Biggest risk. Recommend: the first two ferry starts show the start checklist step by step with ticks, like the apprenticeship |
| Reading the mag drop | A number on a gauge, under time pressure | Recommend: on Easy, the tach marks the 75 rpm band |
| Look-alikes from job 3 on | Two suspects; picking wrong costs a part | Intended. The work order already says which test separates them |
| Money spiral | Rent every day, mail order costs more | Odd jobs exist. Recommend: the map shows an estimated net per call so a bad pick is visible before it's made |

### 6. How does difficulty and complexity escalate?

Already in `_spawn_job` (spec: `docs/quick-specs/difficulty-2026-11-12.md`), plus the apprenticeship in front:

| Rescues done | New |
|---|---|
| 0-2 | The apprenticeship: one fault, clean planes, one new idea per job (Done) |
| 2+ | Look-alike faults, troubleshooting chains, faults hidden behind the cowl, the rare grounding |
| 3+ | Annual inspections (no squawk at all) |
| Every 2 | One more fault per plane (up to 5) |
| Every 4 | One more minimum fault, owners wait a day less |
| Any | Planes that sat for years (grime, stale fuel, pre-oil, pickled engines, door pins, bungees), growing with your career |

**Recommend**: after the apprenticeship, introduce one new system per rescue, each with a single
"first time" card (not a checklist): rescue 4 the first long-sat wreck (wash, sump, pre-oil); 5 the
first look-alike; 6 the first annual; 7 the first grounding. Then everything can mix. Escalation
then feels earned instead of random.

### 7. Does the game suit different playstyles?

| Style | Supported by | Gap |
|---|---|---|
| Thorough (check everything) | Eight spots, the manual, write-ups with figures | None |
| Gambler (skip spots for time) | Two hours a spot, deadlines; a skipped fault strikes on the climb-out | Make the odds readable: the work order could say how many spots are left unchecked |
| Route planner / businessperson | Pay, miles, days, shelf against mail order | Show estimated net per call (see 5) |
| Tinkerer | Hold-the-mouse fastener work, torque wrench | **Repetition**: the 5th oil change plays like the 1st. Recommend "done it before": after three clean runs of a job, offer *Do it the way you know* (one hold, same time cost) |
| Learner / reader | Service manual, parts book, the "why" line at the end of each job | None |
| Accessibility | Rebinding, text size, color vision, checklist toggle, hold-or-toggle | Recommend a "slower ferry" or auto-trim option for players who struggle with the take-off |

### 8. What should players have mastered by the end?

1. Turning a pilot's squawk into where to look.
2. A disciplined walk-around: eight spots, and knowing what each can hide.
3. Taking a job apart and putting it back: the right tool, fastener order, nothing left loose.
4. Torque to spec (plugs 300-360 in-lb, wood prop bolts 175-225 in-lb, star pattern).
5. Reading a run-up: mag drop (75 rpm max), carb heat drop, oil pressure.
6. Troubleshooting chains: spark test, reading plugs, cold cylinder, compression, oil screen.
7. Telling look-alikes apart before buying the part.
8. Logistics: shelf or mail, which tools to own, money against days.
9. Paperwork: a correct logbook entry (approved data, who signs).
10. Judgment: when a plane can't be fixed where it sits, and grounding it.
11. The ferry: start checklist, take-off, getting it home.

---

## Part 2. Every screen against the five UX qualities

M meaningful, C convenient, U usable, R reliable, F functional. ✓ meets it, ~ partly, ✗ doesn't.

| Screen | M | C | U | R | F | Fix |
|---|---|---|---|---|---|---|
| Tour (new) | ✓ | ✓ | ✓ | ✓ | ✓ | Skippable on card 1 |
| Apprentice checklist (new) | ✓ | ✓ | ✓ | ✓ | ✓ | Ticks come from game state, never a button |
| Squawk card (top right) | ✓ | ✓ | ✓ | ✓ | ✓ | |
| What-the-pilot-means card (new) | ✓ | ✓ | ✓ | ✓ | ✓ | Only faults with a written decoder; add more over time |
| Next-step icon | ✓ | ✓ | ~ | ✓ | ✓ | An icon alone; recommend hovering or a key shows its words |
| 3D markers ? and ! | ✓ | ✓ | ✓ | ✓ | ✓ | "!" stays on every difficulty (Done) |
| Spot views (bay) | ✓ | ~ | ~ | ✓ | ✓ | Too many actions per part (Part 4) |
| Work scenes | ✓ | ~ | ✓ | ✓ | ✓ | Repetition; nine tools in the roll (Part 4) |
| Work order (J) | ✓ | ~ | ~ | ✓ | ✓ | Two pages; status rows push actions down; duplicate "Open up" rows |
| Write-ups | ✓ | ✓ | ✓ | ✓ | ✓ | Done this week |
| Wallet (Tab) | ~ | ✓ | ✓ | ✓ | ✓ | Holds "Start a new career": a destructive button in a pocket |
| Logbook (L) | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Service manual (N) | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Map / calls | ✓ | ✓ | ~ | ✓ | ✓ | Compare-heavy: no net estimate, no recommended call |
| PARTS shed (town) | ✓ | ~ | ~ | ✓ | ✓ | Split from the TOOLS box: two stores to compare |
| TOOLS box (mail order) | ~ | ~ | ~ | ✓ | ✓ | Same |
| Parts-on-hand table | ~ | ✗ | ~ | ✓ | ✓ | Shows what the wallet already lists |
| Red toolbox (instruments) | ✓ | ~ | ✓ | ✓ | ✓ | A walk each swap is the point (tool-gating); keep |
| Fuel truck | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Logbook entry (sign-off) | ✓ | ✗ | ✓ | ✓ | ✓ | Same three questions every job |
| Run-up | ✓ | ~ | ~ | ✓ | ✓ | Mag-drop reading (Part 1, 5) |
| Ferry start checklist | ✓ | ~ | ✗ | ✓ | ✓ | The biggest friction (Part 1, 5) |
| Pause menu | ✓ | ✓ | ✓ | ✓ | ✓ | Rebuilt 2026-11-16 |
| Settings | ~ | ✓ | ~ | ✓ | ✓ | 17 graphics rows at once |
| Title screen and tip of the day | ✓ | ✓ | ✓ | ✓ | ✓ | |
| Shop radio | ✓ | ✓ | ✓ | ✓ | ✓ | Mood, out of the way |

---

## Part 3. Menus: keep, merge or cut

| Menu | Call | Benefit of the call | Cost of the other choice |
|---|---|---|---|
| Work order (J) | **Keep, slim** | It's the job's paperwork and its action list | Cutting it removes the one place every fault is listed |
| Spot views (bay) | **Keep** | Real parts, the "!", tool-gating, the heart of the game | |
| Service manual (N) | **Keep** | Teaches real procedures, figures and specs | |
| Logbook (L) | **Keep** | Your career, made of planes you saved | |
| Map / calls | **Keep, improve** | The one big decision each trip | |
| Red toolbox | **Keep** | Makes instruments physical; job 3 teaches it | Folding it into the roll loses the "fetch the right tool" moment |
| Fuel truck, shop radio | **Keep** | Short, diegetic, no decisions to stall on | |
| Logbook entry at sign-off | **Keep, shorten after 3** | Certification is the point of being an A&P | Asked every job, it becomes a chore: after three correct entries, offer "Same as always" with one click |
| PARTS shed + TOOLS box | **Merge** | One store, two columns: *on the shelf here* / *by mail (1 day, +25%)*. One place to compare means no hunting | Two stores means walking between them to compare prices |
| Wallet + parts-on-hand table | **Merge** | One "truck" pocket for cash, parts, tools and materials | The table repeats the wallet. Keep the 3D table as decoration, without its own menu |
| "Start a new career" in the wallet | **Cut (move)** | To the title screen and pause menu, behind the confirm | Today it's one Tab away mid-job |
| Pause: Controls | **Cut** | Settings already has a Controls tab; "Controls" opens it there | Two places to change one thing |
| Pause: Credits | **Cut (move)** | Title screen only | One less choice in a menu you open to stop |
| `scripts/station.gd` (station grid) | **Cut** | Dead since spots became views (nothing opens it) | Dead code to maintain |
| `look_<zone>` flashlight scenes in `work.gd` | **Cut** | Dead for the same reason | |
| Settings: graphics detail | **Collapse** | Show the preset and window rows; put the 12 detail rows under "Advanced" | 17 rows at once to someone who just wants it to run |

---

## Part 4. Analysis paralysis

A choice belongs in the game when the choosing *is* the game (which call, which test, gamble on a
spot). Everywhere else there should be **one obvious next action**. Where that fails today:

| Where | Why it stalls | Fix |
|---|---|---|
| The map | Three calls, each with pay, parts, miles, days, wait. Nothing to anchor the comparison | Show **estimated net** (pay minus fuel, parts, rent for the days). Mark one call "closest you can afford". Keep it at three |
| Part cards in the spot views | The left-side plugs offer up to six actions | On Medium and Easy, list what's written up (with its "!") first and fold the rest under *Other work here* |
| Work order | Status rows (days left, spots checked, fuel, parked) sit above actions and push it to two pages | Actions first, status in one compact line at the top, "OK" rows collapsed |
| Tool roll in a job | Nine tools, any of which might be next | H already shows what's next. Recommend: on Easy, clicking a piece with the wrong tool switches to the right one if you own it |
| Shops | Shed, mail order, parts table: three places, three prices | Merge (Part 3) |
| Settings | 17 graphics rows | Collapse (Part 3) |
| Suspects (look-alikes) | Two candidates, a part's cost on the line | Keep: the choice is the game. The work order already names the test that separates them |
| Spots to check | Eight spots, time against risk | Keep: the gamble is designed. Show how many are left on the clipboard |
| Logbook entry | Three questions every job | "Same as always" after three correct (Part 3) |

---

## Next step

Tell me which recommendations to build. In rough order of value for the least work:
1. **Done (2026-11-22).** Cut the dead station grid and flashlight scenes; "Start a new career" moved from the wallet to the pause menu (and the title screen); Controls and Credits out of the pause menu.
2. **Done.** Net estimate per call (`main.call_estimate`), calls sorted best first, and "closest you can afford" marked.
3. **Done.** Part cards: written-up work first as the red button (and on Easy/Medium the test the work order names next); two or more other actions fold under *Other work here* (`bay.gd _due`). Self-test check 70.
4. Ferry start checklist that ticks, for the first two flights.
5. A wall of saved planes in the hangar, and the tally on the map.
6. Merge the two stores; merge wallet and parts table.
7. "Do it the way you know" for repeated jobs; "Same as always" for the logbook entry.
8. One "first time" card per new system after the apprenticeship (rescues 4-7).
9. Collapse graphics settings under Advanced.

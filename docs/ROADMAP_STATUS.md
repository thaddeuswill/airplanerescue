# Roadmap status

Where the game stands against `docs/DEVELOPMENT_STAGES.md` (the five stages and 50 tips).
Checked against the code on 2026-11-12, version 0.9.3. Status: **Done**, **Partial** (some of
it exists) or **Not started**. Tips that assume a 3D wrenching view are marked
**N/A (2D scenes)**, because repairs happen in flat 2D work scenes.

## Verdict: Alpha, with Vertical Slice gaps

The wrenching and troubleshooting core is past prototype: 57 work scenes, real fault chains, and a
solver test that proves every scene can be finished. Content is Alpha-sized, with 57 faults across
ignition, fuel, electrical, airframe and gear. What holds the game back from a clean Alpha is the
Vertical Slice layer: tool and cargo packing, the diegetic menu, sound tied to the work, and
landing the ferry flight.

## Stage 1: Prototype

| # | Tip | Status | Where / notes |
|---|---|---|---|
| 1 | Dependency graph | Done | `work.gd` `needs` / `with` / `requires` / `out`. A part can't come off until what blocks it is off |
| 2 | Primitive geometry first | Done | Scenes draw placeholders until art exists |
| 3 | Fastener state machines | Done | tight → loose → out and back; torque snug → tight. 2D, so no axial backing-out |
| 4 | Diagnostic tools read real state | Done | `main.reading()` reads the job's real cylinder, valve and lead |
| 5 | One end-to-end fault tree | Done | Many: `FAULTS[...].diags`, e.g. reading plugs → cold cylinder → compression |
| 6 | No tunneling on dropped parts | N/A (2D scenes) | Fasteners go to the magnetic tray |
| 7 | Container/slot inventory | Partial | Parts and tools by count; no weight or slots |
| 8 | Simple flight stub | Partial | `ferry.gd` does take-off only. Travel between towns is a card |
| 9 | Simulation separate from visuals | Done | The job is a plain dictionary; the self-test plays whole rescues headless |
| 10 | Debug inspector overlay | Not started | No hotkey shows fault flags or values |

## Stage 2: Vertical Slice

| # | Tip | Status | Where / notes |
|---|---|---|---|
| 11 | Whole loop, menu to payout | Partial | Menu → radio → fly → walk-around → repair → sign-off → payout all work. There's no tool-packing step, and no return flight |
| 12 | Diegetic main menu | Partial | A text menu over the hangar interior; the radio, clipboard and toolbox aren't clickable objects there |
| 13 | Radio symptoms that don't name the part | Done | `_symptoms()`: the owner's words, never the fault |
| 14 | Cargo weight and space | Not started | |
| 15 | Run-up check | Done | `_run_up()`: start, mag check, gauges as text. Since today, running it before it's ready breaks parts |
| 16 | Logbook sign-off that validates squawks | Done | Work order and logbook; Hard mode lets you sign off and logs comebacks |
| 17 | Golden-hour lighting pipeline | Partial | Sun by city, haze, bounce light, dust motes, a High/Low switch. Not profiled (see 47) |
| 18 | Foley hooks on every action | Partial | `sound.gd` has clink, tick, chime, pen and tone, and the wrench tick is the only per-action sound |
| 19 | Reliable save/load | Done | Atomic write with a `.bak`, versioned with migration, and tested by corrupting it |
| 20 | Cold-start onboarding test | Not started | Needs a person who hasn't played it. Easy mode is built for this |

## Stage 3: Alpha

| # | Tip | Status | Where / notes |
|---|---|---|---|
| 21 | Fault modules across all systems | Done | 57 faults. See `JOBS_ATA.md` |
| 22 | Layered squawks | Done | 1-5 per plane, ramping with rescues; a dead starter cuts the run-up short and hides what it would have shown |
| 23 | Multiple locations | Done | Towns with their own terrain (plains, hills, mountains, snow, desert) |
| 24 | Weather and time of day | Partial | Snow towns need a preheat. No wind, overcast or carb-ice clues yet |
| 25 | Parts catalog and economy | Partial | Town sheds, mail order (+25%, a day), tools to buy. No upgraded tools |
| 26 | Consumables | Done | Safety wire, cotter pins, penetrant, gaskets, brake fluid, dope, oil |
| 27 | Menu souvenirs | Not started | A framed photo and shop log on the hangar wall, but not tied to milestones |
| 28 | Several aircraft archetypes | Partial | Five plane types on the radio, but every one uses the Cub model and scenes |
| 29 | Owner personalities and wrong guesses | Not started | Owners report symptoms; nobody guesses wrong yet |
| 30 | Field-expedient ferry fixes | Not started | |

## Stage 4: Beta

| # | Tip | Status | Where / notes |
|---|---|---|---|
| 31 | Highlights on tiny fasteners | Done | Hover ring and box in the work scenes |
| 32 | Layered, randomized foley | Not started | Sounds are procedural single tones |
| 33 | Cranking sounds tied to faults | Not started | The run-up is text |
| 34 | Close-up camera ergonomics | N/A (2D scenes) | |
| 35 | Torque feedback | Partial | Torque is a separate step; no click or shake at torque |
| 36 | Radio tuning | Not started | |
| 37 | Ground handling and landing | Not started | Take-off only |
| 38 | Visible wear states | Done | Old and new art for each part; grime and lichen on long-sat planes |
| 39 | Quick tool switching | Done | Tool roll buttons and the mouse wheel |
| 40 | Accessibility pass | Not started | Keys aren't remappable; no text-size option |

## Stage 5: Release

| # | Tip | Status | Where / notes |
|---|---|---|---|
| 41 | Lost & Found for fasteners | Done | Nothing can be dropped; fasteners go to the tray |
| 42 | No unwinnable missions | Partial | Every scene is proven finishable by `solve()`, and mail order covers missing parts. Not yet: a sim of running out of money mid-job |
| 43 | Your own plane can't strand you | Partial | One call is always within reach; broke while grounded is game over by design |
| 44 | Save compatibility | Done | `SAVE_VERSION` and `_migrate`; a save from a newer build is never overwritten |
| 45 | Economy sim over 20+ jobs | Not started | A good next balance-check |
| 46 | Draw calls and colliders | Not started | |
| 47 | Grass, shadow and particle budget | Partial | A Low preset exists; no frame-time numbers |
| 48 | Clean state on scene changes | Partial | The self-test ends with one leaked object warning |
| 49 | First-launch settings | Not started | |
| 50 | Golden-master playthrough | Not started | |

## Next, by the roadmap's weighting

The game sits in Alpha, where the roadmap puts 30% on the loop, 25% on art and 20% on mechanics. In
that order, the open Vertical Slice and Alpha items that matter most:

1. **Debug inspector (10)**: cheap, and it speeds up everything else.
2. **Run-up sounds tied to faults (33, 18)**: the run-up is the game's main diagnostic moment, and it's text.
3. **Owner personalities and wrong guesses (29)**: fits the radio calls as they are and rewards real diagnosis.
4. **Field-expedient fixes (30)**: a lower-paying way out when you're missing a part.
5. **Economy sim (45)**: run 20+ jobs through the real code, now that damage and comebacks cost money.
6. **Tool packing and cargo weight (14, 11)**.
7. **Landing the ferry flight (37, 8)**.

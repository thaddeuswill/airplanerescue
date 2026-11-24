# CLAUDE.md

Guidance for Claude Code (and anyone else) working in this repository.

## What this is

Airplane Rescue: a first-person Godot 4.7 game about a traveling A&P mechanic. You fly to stranded
planes, find what's wrong on a walk-around and run-up, fix it in flat 2D work scenes, and fly the plane
out. The player-facing overview is `README.md`. Mechanical values come from real FAA and Continental
documents, and `JOBS_ATA.md` is where they're kept. **Don't invent a number:** if a value isn't in
`JOBS_ATA.md`, `data/c85_manual.json` or `reference/`, list it as missing and ask.

## Run and verify

The engine is Godot **4.7.2**. There's no CI. The self-test is the regression gate: it plays real
rescues through the real code and exits non-zero on failure.

```bash
godot --headless --path . -- --self-test                       # one random job; prints SELF-TEST PASS/FAIL
godot --headless --path . -- --self-test --all-faults          # every fault one plane can have at once
godot --headless --path . -- --self-test --faults=tire,magneto # a chosen set
godot --headless --path . -- --self-test --difficulty=hard     # easy, medium (default) or hard
godot --headless --path . -- --self-test --tutorial=2         # play apprenticeship lesson 1, 2 or 3
```

- Run the plain self-test several times: faults are random, so one pass proves little.
- A run that stops never passes or waits forever: a watchdog thread fails it with `SELF-TEST FAIL hang`
  and the last place it reached (frames stopped for 60 s, or the run past 420 s).
  `--hang-test=wait|frozen` hangs on purpose to prove the watchdog works.
- A script that won't parse can't start the self-test (or its watchdog): the `BootGuard` autoload
  (`scripts/boot_guard.gd`) fails the run at once with `SELF-TEST FAIL load: <file>`, and fails it if
  the self-test hasn't started within 60 s for any other reason.
- Many runs at once: give each its own `user://` folder, or they fight over one save file:
  `XDG_DATA_HOME=/tmp/run1 godot --headless --path . -- --self-test` (Linux).
- The `ERROR: Condition "(uint32_t)buff.size() != len"` line is expected. The test deliberately
  corrupts the save file to check the fallback to `.bak`.
- Screenshot runs (`--shot`) play the whole rescue like headless ones but slowly (about 15 min; the
  watchdog allows 30 with a display). The test waits on game time, not the wall clock, so a slow
  display can't cut a step short.
- Screenshots need a display: `xvfb-run -a -s "-screen 0 1280x800x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 -- --self-test --shot=prefix`.
- `--scene-shots=prefix[:scene,scene]` shoots every work scene (or the listed ones) at its start and
  part-way through. Use it to check art placement. Check at **1280x720**, the smallest supported
  window: the tool roll has to fit under the 1000 px scene.
- `godot --headless --path . --script tools/art_list.gd > art_list.json` lists every work-scene piece
  and whether its art exists (it feeds `ART_PROMPTS.md`).

## Where things live

| Path | What |
|---|---|
| `scripts/main.gd` | Game state, world, panels. `FAULTS` (every fault: name, part, cost, zone, symptom, diagnosis chain, `ground`, quiz), `TESTS` (inspections), `RUNUP_FAULTS`, `SUPPLIES`, `PLANE_TYPES`, save/load/migrate |
| `scripts/work.gd` | The 2D work scenes. `scenes()` holds every job as data; the rules and drawing are generic |
| `scripts/bay.gd` | Every walk-around spot, opened up. The engine: cowled → open → left, top, rear, underneath, firewall (`VIEWS`/`PARTS`). Every other spot is built from its jobs' paintings (`_build_spot`): the parts as installed, the broken one drawn from its `_old` art. Parts offer what you can do with what you carry (tool-gating); a written-up part keeps a "!" until it's fixed |
| `scripts/tutorial.gd` | The apprenticeship: the first three jobs taught by doing them (tour, self-ticking checklist, what-the-pilot-means quiz, rewards). State in `main.tut`. Spec: `docs/quick-specs/apprenticeship-2026-11-22.md` |
| `scripts/preflight.gd` | The cockpit checklist card (before start, run-up, take-off) drawn from `ferry.card()`; explains each step and the take-off for the first two deliveries |
| `scripts/selftest.gd` | The self-test, including `_scene_tests` (every scene solved through `solve()`) and edge tests |
| `scripts/manual.gd`, `scripts/parts_book.gd` | The M-key service manual and parts book, read from `data/c85_manual.json` and `data/c85_parts.json` |
| `scripts/updater.gd` | GitHub Releases auto-update (Windows installs the setup; Mac opens the download page) |
| `JOBS_ATA.md` | Every job by ATA chapter with real-world values and what's still missing |
| `ART_PROMPTS.md`, `docs/JOB_ART_GUIDE.md`, `WORK_SCENES.md` | Art requests and how scene art is cut and named |
| `reference/` | The FAA source documents (AC 43.13-1B) |
| `docs/DEVELOPMENT_STAGES.md`, `docs/ROADMAP_STATUS.md` | The five-stage roadmap and where the game stands on each of its 50 tips |
| `docs/quick-specs/` | Short design specs for each change (what, why, acceptance criteria) |

## Work scenes (`scripts/work.gd`)

Each scene is a list of elements: `fastener`, `cover`, `part`, `task` or `view`. The header comment of
`work.gd` is the reference for the keys (`needs`, `with`, `out`, `requires`, `free`, `rest`, `note`,
`turns_prop`, `trap`, `optional`, `hook`, `dyn`, `art`, `art_rect`, `start`...).

- Scene ids match `FAULTS`/`TESTS` keys (the exception is `hand_prop`, which is started from the run-up).
- Art is `textures/work/<art>_<piece>.png`, with `_old`/`_new` for parts. `<art>` is the scene id
  unless the scene sets `"art"` to borrow another scene's set. Missing art draws a placeholder, so
  a scene works before it's painted.
- Every new scene must be solvable by `solve()`. `_scene_tests` checks this automatically. A scene it
  can't solve is a soft-lock for the player.
- Readings and dynamic art come from `main.reading()` and `main.view_art()`. Task hooks call `main.task_done()`.

## How we work (settled 2026-11-23, fixed)

**Agile iterations with a Spiral risk gate: `docs/PROCESS.md`.** Read it before starting work.
Every request goes into `docs/BACKLOG.md` first; work happens in iterations (plan, risk gate,
build, verify against the definition of done, review, retro). A mid-iteration request that refines
the item being built joins it; anything else waits in the backlog. Only crashes, lost saves,
soft-locks or a broken build jump the queue. The process itself only changes between iterations,
by Thad, written into `docs/PROCESS.md`.

## Settled decisions (don't change without asking)

- The Cub is a J-3 with a **C85-12 with a starter** (not the C-65), drum brakes with expander tubes.
- Real values beat game feel. Where the manuals disagree, the Continental/Piper manual for that
  airplane wins over AC 43.13-1B. Contradictions found so far are resolved in `JOBS_ATA.md`.
- Faults with `"ground": true` have no field fix: the plane is grounded and the owner called.
- Money: the owner pays for the job, its parts (in the quoted pay) and the supplies it used
  (paid back at sign-off). Anything you mess up comes out of your pocket: damage from running it
  unready, supplies used on it or on a place with nothing wrong, and comeback deductions.
- No clock (changed by Thad 2026-11-23, D2): the game counts no days and times no job. Rent is a
  flat hangar fee per job (`HANGAR_FEE`, $60); calls never expire; mail order arrives at once.
- Guessing costs a small charge (`WRONG_GUESS`, $25): a wrong verdict, mag call, test or weight
  and balance; a wrong move in a work scene costs only the try. Running the engine
  with "don't run it yet" work undone breaks a part you pay for (`RUNUP_DAMAGE` in `main.gd`,
  `docs/quick-specs/run-it-unready-2026-11-12.md`).
- Saves: `SAVE_VERSION` in `main.gd`. Bump it when the layout changes and add the step to `_migrate`.
  A save from a newer build is never overwritten.
- The updater only runs files from this repo's own release downloads.
- Shipping: bump `config/version` in `project.godot`, run `tools/build_release.ps1`, and attach the
  setup .exe and the `-mac.zip` to a `v<version>` release.

## Open decisions (need a value from the user)

Missing manual values are listed under "Values still needed" at the bottom of `JOBS_ATA.md`. Still
open at the time of writing: audit step 6 art (starter ring gear, both magnetos, tail tie rods,
bungee boot, tire proportions, jack pad, fabric look inside the older 2D scenes).

Settled from the manuals: C-85 mag timing right 28°, left 30° (the timing jobs work on the left mag);
mag drop 75 rpm max; prop track 1/16 in; oil SAE 40 above 40 °F, SAE 20 below.
Settled by Thad (2026-11-13): wood prop hub bolts 175-225 in-lb (AN6, 3/8 in.), not the 200-220 in
the design-pass zip. Spark plugs 300-360 in-lb.

## Conventions

- Type: Big Shoulders Display for all UI (`Style.display(weight)`, `Style.caps()` for capitals),
  Courier Prime for numbers that change while you watch (`Style.figures()`), DejaVu Serif Condensed
  for long reading, Yellowtail for the logo only. Never a system font or `ThemeDB.fallback_font`.
  The project skill `.claude/skills/anti-ai-typography-mastery` has the rules.
- GDScript 4 with static types (`:=` or `: Type`) and `-> Type` returns. Leave a value untyped only
  when it really is a Variant (JSON, save data, a nullable job).
- `##` doc comments on functions and constants explain *why*, in plain words.
- The service manual has a page for every fault, each with a picture (`textures/manual/ref_<id>.png`,
  656 x 448, the job's scene art). Figures are numbered per ATA chapter in reading order by
  `manual.gd` (`Figure 74-5`); never write a figure number into the data. The self-test fails a
  fault with no page or picture.
- Job text (work scenes) is in service-manual style, settled by Thad 2026-11-13: imperative, the
  manuals' terms ("Remove... / Install... / Safety-wire with new wire"), paraphrased, never copied.
  It lives in `data/job_text.json`, keyed by scene and piece id; `work.gd` `_apply_text` lays it over
  the built-in text. Other player text (radio, owners, messages) stays short and plain.

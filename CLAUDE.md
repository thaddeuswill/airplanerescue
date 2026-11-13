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
```

- Run the plain self-test several times: faults are random, so one pass proves little.
- The `ERROR: Condition "(uint32_t)buff.size() != len"` line is expected. The test deliberately
  corrupts the save file to check the fallback to `.bak`.
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

## Settled decisions (don't change without asking)

- The Cub is a J-3 with a **C85-12 with a starter** (not the C-65), drum brakes with expander tubes.
- Real values beat game feel. Where the manuals disagree, the Continental/Piper manual for that
  airplane wins over AC 43.13-1B. Contradictions found so far are resolved in `JOBS_ATA.md`.
- Faults with `"ground": true` have no field fix: the plane is grounded and the owner called.
- Money: the owner pays for the job, its parts (in the quoted pay) and the supplies it used
  (paid back at sign-off). Anything you mess up comes out of your pocket: damage from running it
  unready, supplies used on it or on a place with nothing wrong, and comeback deductions.
- Guessing costs time only: a wrong verdict or quiz answer advances the clock. Running the engine
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

## Conventions

- GDScript 4 with static types (`:=` or `: Type`) and `-> Type` returns. Leave a value untyped only
  when it really is a Variant (JSON, save data, a nullable job).
- `##` doc comments on functions and constants explain *why*, in plain words.
- Player-facing text sounds like a mechanic talking: short sentences, no jargon a pilot wouldn't use.

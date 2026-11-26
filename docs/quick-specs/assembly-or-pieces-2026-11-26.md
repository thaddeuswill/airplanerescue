# The full assembly or the piece parts: the magneto (AP1)

**Status**: built, iteration 37
**Date**: 2026-11-26
**Code**: `main.PIECE_ROUTES`, `route_fault`, `piece_part`, `_open_shop`, `_repair`, `_station_done`,
`_manual_job`, `PLACES`; `work.gd` scene `magneto_points`, `setup`; `bay.gd` rear-view magneto acts;
`data/job_text.json` `magneto_points`; self-test `_routes_ok`, `_scene_tests`

## Why

Thad, 2026-11-25: "so when you repair stuff will you have to buy these separate or full assy for
the players id love full assys and indiv".

## Decisions (Thad, 2026-11-25)

- The parts book's game prices stand as balance, marked unverified as before; BT4 checks them.
- The magneto first. The carburetor has no piece parts in the data (float, needle and seat) and
  waits for them.
- The breaker point gap shows no number until Thad supplies one; it stays listed as missing in
  `JOBS_ATA.md`.

## What

- Each magneto in the engine's rear view offers both routes: **Swap the magneto** (the overhauled
  magneto, as before) and **Replace the points and condenser** (new).
- The piece-part scene: cowl off, breaker cover off, P-lead off; remove the breaker points and
  install a new set; remove the condenser and install a new one; set the point gap with a feeler
  gauge to the magneto manufacturer's figure; time it to the engine (No. 1 at 30 deg BTC, the
  settled left-mag figure); P-lead, cover and cowl back on. It borrows the swap's art.
- Finishing either route fixes the magneto. The route's scene id maps to the fault wherever a scene
  is read as a fault (finishing, the healthy check, the manual page), so the long way is never
  counted as a wrong suspect.
- The parts counter sells the breaker points set ($38) and the condenser ($22) from the parts book,
  with their part numbers, shelf or 25% more by mail like every part; listed first while a bad
  magneto is written up.
- Money: the owner's quote is unchanged (it prices the overhauled magneto, $1,400). The pieces cost
  you far less; the swap saves steps. The pieces are parts, not supplies, so they aren't billed to
  the owner a second time.

## Acceptance

- `_scene_tests` solves `magneto_points` on a plane with a bad magneto.
- `_routes_ok`: for each route, a fresh job with a bad magneto and nothing in stock; the counter sells
  the magneto and both piece parts; buying what the route needs and solving it from the rear view
  fixes the magneto, never as a wrong suspect; the pieces cost under a fifth of the swap.
- Ten runs, the screenshot run (a bad magneto) and the scene screenshots pass.

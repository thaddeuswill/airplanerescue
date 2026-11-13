# Quick Design Spec: Running it unready breaks things

**Type**: Addition (plus a tuning pass on ignition values)
**System**: Run-up and diagnosis (`scripts/main.gd` `_run_up`, `_run_up_result`, `_call`, `_quiz`)
**GDD Reference**: none: the design record is `JOBS_ATA.md` and the source manuals (Continental
C75/C85/C90/O-200 Overhaul Manual, Aug 2011; J-3 Cub manual; M-0)
**Date**: 2026-11-12

## Change Summary

Guessing is cheap and running the engine before it's ready is expensive. A wrong call on a test or
a wrong quiz answer only costs time (it already does). Running the engine up with known
"don't run it yet" work still undone now damages the plane: a new fault to repair and a part you
pay for yourself. The owner doesn't pay for damage you caused.

## Motivation

The run-up was a free probe: with a dry or pickled engine it just refused and told you why. Real
mechanics treat these as hard rules because breaking them costs a cylinder or a prop. Making the
rule bite teaches the procedure the manuals insist on, and gives the walk-around a purpose.

## Design Delta

Before: `pre_oil` and `storage` both blocked the run-up with a message, and nothing broke.

After: running up with any of these still unfixed adds damage. The damage fault is added as
already found, with no troubleshooting. If it was fixed earlier, it breaks again and needs a new part.

| Left undone | What running does | Damage fault (part, cost) | Source |
|---|---|---|---|
| `pre_oil` (sat for years) | Fires dry: scuffs a cylinder wall and rings before oil gets there | `worn_rings` (Cylinder assembly, $1,600) | Pre-oil before the first start: M-0 5-2.9, overhaul manual p.107. The damage is the reason; neither manual prices it |
| `prop_bolts` (bolts loose) | The wood prop works on its flange: charred wood, elongated bolt holes | `propeller` (Propeller, $2,600) | AC 43.13-1B 8-92 and Fig. 8-29 |
| `bird_nest` (nest in the cowl) | The straw smoulders on the exhaust and scorches the baffle seals | `baffles` (Baffle seal strip, $25) | No manual figure: a well-known field hazard |

`storage` (a pickled engine) stays a block with no damage. Its plug holes hold dehydrator plugs,
so nothing can fire. M-0 6-5.2 says hydraulic-lock damage comes from the other cylinders firing.

Rules:
- The engine has to actually run. A start blocked by something else (door pin, storage, dead
  starter) breaks nothing.
- `door_pin` stays a block (you can't get in), and `storage` stays one too (it can't fire).
- The original fault stays open: you still pre-oil, depreserve, torque the bolts or pull the nest.
- The run-up message says plainly what you did and what it cost.

## Ignition values (consulting the manuals)

| Value | Was | Now | Source |
|---|---|---|---|
| Mag timing in the `mag_timing` job | 28° BTC | 30° BTC, on the **left** mag (the same mag as the `magneto` job) | Overhaul manual Table X: C85 right 28°, left 30° |
| Manual page: timing | 28° BTC for both | Right 28°, left 30° | Table X |
| Manual page: mag drop | 125 rpm max | 75 rpm max on either mag | Overhaul manual 7A ground test (d); Cub manual; already what the run-up says |
| Prop track | 1/16 in | 1/16 in (no change) | AC 43.13-1B 8-108; the overhaul manual gives no number |
| Oil grade | SAE 40 above 40 °F, SAE 20 below | No change | Overhaul manual Table XVIII |

## Tuning Knobs

- The damage table, `RUNUP_DAMAGE` in `main.gd`. Keep it to faults the walk-around reveals and the
  radio call hints at, so the player is always warned first.

## Acceptance Criteria

- [ ] A run-up with `pre_oil` unfixed adds `worn_rings` (found) and the engine runs.
- [ ] A run-up with `storage` unfixed still blocks and adds nothing.
- [ ] A run-up with `prop_bolts` or `bird_nest` unfixed adds `propeller` or `baffles`.
- [ ] Damage that was already fixed breaks again (removed from `fixed`, its scene reset).
- [ ] A wrong verdict or quiz answer still only advances the clock.
- [ ] The self-test passes a run with these faults and repairs the damage they cause.
- [ ] The `mag_timing` scene, its readings, the art and the manual all say left mag 30°.

## Balance note (balance-check, economy)

Pay is base ($1,500-3,500) + 2x the parts cost of the owner's faults + $150 a year sat. Damage isn't
in that pay, so the cost comes out of the player's pocket. A cracked prop ($2,600) is close to a
whole job's pay, and nearly all of the $3,000 starting cash. Verdict: **CONCERNS**. It's harsh, but
the walk-around warns in plain words first, and it is the real-world price. If playtests show
early-game bankruptcies from it, the knob is to drop `prop_bolts` from the table or make that a
chance instead of certain.

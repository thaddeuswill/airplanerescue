# You don't pay for the owner's fuel (F5)

**Status**: built, iteration 30
**Date**: 2026-11-25
**Code**: `main._fuel_plane`, `_open_truck`, `_buy_can`, `_can_finish_here`, `call_estimate`, the
map row; `tutorial` truck walkthrough; CLAUDE.md money rule

## Why

Thad: "I don't think we should pay for the fuel in the plane because it's not our plane."

## What

- The fuel truck fills the owner's plane on the owner's account: it costs you nothing and never
  needs your cash. Recorded on the job as `owner_fuel`.
- A jerry can of fresh avgas for a stale-fuel job you're working is the owner's too; bought with no
  such job at the field it costs you $90, so it can't be free stock.
- Your own flight to the job stays yours: the ticket's Fuel line is your trip only; the map's
  estimate and the finish check leave the plane's fuel out.
- No payment wording on the truck (Thad, in review: "no need for text on the fuel truck"): the rows
  read "Fuel the [plane]: N gal of 100LL" with Pump, and the jerry can row; the walkthrough's cost
  line is gone.

## Acceptance

Self-test (`_owner_fuel_ok`): with $0 the pump fills a dry plane, cash and the job's own spending
unchanged; the can for the owner's plane is filled for nothing; a stock can costs $90; the
estimate leaves the plane's fuel out. The edge test finds a job with dry tanks and no money
finishable. Ten runs (two Hard) and the screenshot run pass.

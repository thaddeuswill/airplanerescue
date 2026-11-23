# Error-activated guidance (E4)

**Status**: built, iteration 8
**Date**: 2026-11-23
**Code**: `main.verdict_aid`, `entry_hint`, `ENTRY_HINTS`, `_aid_on`/`_aid_off` (job.aid); `ferry.gd _aid_mag`, `_aid_rudder`

## Why

Help should reach the player who needs it, when they need it, without distracting the player who
doesn't (the error-activated guidance pattern; `docs/LEARNING_DESIGN.md` gap E4).

## What

A mistake switches on help aimed at that mistake, for the next try only. A player who makes no
mistakes never sees any of it. Each aid writes a play-log line when it appears.

| Mistake | Aid | Gone after |
|---|---|---|
| A wrong mag call | The rule on the cockpit card: good drops a little, no more than 75 rpm, smooth; bad is past 75 and rough, or no drop. On every difficulty, Hard too | That run-up |
| A wrong verdict | The verdict sheet offers the manual's page for that test (the reading, not the call) | The next call |
| A logbook entry sent back | "What the inspector wants": the rule for that step, not the option | The next pick |
| Running it unready | The work order marks each remaining "don't run it yet" item | The next run-up |
| A ground loop | A straight-line rudder cue on the take-off roll | Airborne |

No money or time changes: the mistakes already cost time.

## Acceptance

Self-test: each aid is absent before its mistake, shows after it, and is gone after the next try
(mag call, verdict, logbook entry, run-unready marks, ground-loop cue).

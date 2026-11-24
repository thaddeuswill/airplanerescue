# A parse error fails the self-test, not hangs it (T1)

**Status**: built, iteration 29
**Date**: 2026-11-24
**Code**: `scripts/boot_guard.gd` (autoload `BootGuard` in `project.godot`); `selftest.run` sets
`Engine` meta `selftest_started`

## Why

The self-test's watchdog lives in `selftest.gd`, and `main.gd` starts the self-test: when either
didn't parse, nothing started and the run hung silently until an outside timeout (7-10 minutes).
It happened four times in this run of iterations.

## What

- An autoload that depends on nothing else, so it loads even when other scripts don't.
- In a self-test run it loads every script in `scripts/`; any that won't parse fails the run at
  once: `SELF-TEST FAIL load: <files> won't parse`, exit 1 (scripts that load a broken one are
  listed with it).
- If the self-test hasn't started 60 s after launch for any other reason, it fails the run.
- Outside a self-test run it does nothing.

## Acceptance

In copies of the project with a deliberate parse error: in `tutorial.gd`, the run fails in about
1 s naming it (with `main.gd` and `preflight.gd`, which load it); in `main.gd`, the same. The full
set (ten runs, two Hard) and the screenshot run pass with the guard in; both `--hang-test` modes
still report where they stopped.

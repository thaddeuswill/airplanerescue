# One message at a time at the top (U3)

**Status**: built, iteration 22
**Date**: 2026-11-24
**Code**: `main._say`, `_banner`, `_clear_top`, `_update_hud` (message band), `_update_squawk`;
the run-up and ferry start; `_open_pause`

## Why

The U1 audit found up to four text layers at the top at once (the cockpit card, the centre band, a
banner and the top-right hint), with stale messages from the last sheet, and the squawk shown twice
under the notes card. Thad ordered it next.

## What

- In the cockpit (run-up and ferry flight) every message and banner goes to the cockpit's one list
  at the top right; nothing is lost, it's in the list. Climbing in clears the centre band and any
  banner from the walk-around.
- The pause clears the band and any banner.
- While the squawk notes card is open, the centre band and the pinned squawk are hidden.
- Outside the cockpit the band works as before, so sheets keep their feedback.

## Acceptance

Self-test (`_top_bands_ok`): after a message and a banner in the cockpit, no centre band, banner or
squawk (they went to the list); behind the pause, none; under the notes card, none. Screenshots of
the run-up, the pause and the notes at 1280x720.

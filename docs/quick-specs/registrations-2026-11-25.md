# Registration numbers instead of plane descriptions (R1)

**Status**: built, iteration 36
**Date**: 2026-11-25
**Code**: `main.MAKE_MODEL`, `BASE_PAY`, `plane_name`, `_spawn_job`, `_hand_propped`; `bay.gd`
header; self-test `_names_ok`

## Why

Thad, 2026-11-23: "the red plane or this other plane kinda looks sloppy, it doesn't really look like
something that you would see in the real world". Settled 2026-11-25: "only difference between
planes is tail number". Every plane is a Piper J-3 with a C85-12.

## What

- The five type descriptions ("Rag-wing taildragger" and the rest) are gone. The plane is named by
  its N-number:
  - the arrival line ("Walk around N591UZ");
  - the work order and clipboard ("Work order: N591UZ, Piper J-3");
  - the task list ("N591UZ, Piper J-3 at Omaha");
  - the fuel truck ("Fuel N591UZ: 11 gal of 100LL");
  - the spot header ("N591UZ · ENGINE");
  - the grounded and crash messages;
  - radio news of a plane you saved.
- The grounded and crashed entries in your logbook now carry the registration as delivered ones do.
- **Pay**: each type had its own base ($1,500 to $3,500). With one airplane there's one base,
  `BASE_PAY` $2,500, the average, so a career pays the same on average. Faults, years, an annual
  and the call's difficulty still set each call's pay. A game value, to be checked by BT4.
- Old saves: their jobs keep the stored `type` field (an old job without a stored N-number makes one
  from its fields), never shown. No save change.
- Paint schemes so planes also look different are P1, later.

## Acceptance

- Self-test: the arrival line names the plane by its N-number; the work order title reads
  "N-number, Piper J-3"; the task list "N-number, Piper J-3 at city"; none of the arrival line, work
  order, clipboard, task list or fuel truck shows any of the five old names. No old name is left in
  the scripts, data or specs.
- Ten runs and the screenshot run pass.

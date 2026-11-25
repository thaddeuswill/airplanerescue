# The references within reach (K1)

**Status**: built, iteration 31
**Date**: 2026-11-25
**Code**: `manual.gd` (`tab`, `current_tab`, `_figure_for_job`, `_catalog`, the tab bar, catalog
spreads); `main._open_inspection` (References row)

## Why

Thad: the parts catalog, the maintenance manual and the IPC's exploded diagrams should be easily
accessible. The manual opened on N, but the IPC drawing for the job's part took paging and the
parts catalog only opened at the parts shed or the mail-order box.

## What

- Three tabs above the manual, one click each: **Procedure** (the job's page), **IPC drawing**
  (the exploded figure for the job's part: the part that fixes the fault names its figure, else the
  chapter's), **Parts catalog** (every part in `c85_parts.json`: part number, description, price;
  opens at the page with the job's parts, marked JOB; a look-up only, buying stays at the counter
  or by mail).
- Opened by N from the walk-around and from a work scene (closing goes back to the work), and by
  a References button on the work order.
- Part numbers and prices come from the existing parts data; nothing new invented.

## Acceptance

Self-test (`_references_ok`): References on the work order opens the manual; for the magneto the
tabs land on its procedure, the ignition drawing (fig_ignition) and the catalog page with H4LN-21
marked JOB, with nothing to buy; N from a work scene opens it and closing returns to the work.
Ten runs (two Hard) and the screenshot run pass; after the header fix three plain runs and the
screenshot run pass.

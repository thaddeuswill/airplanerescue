# The catalog's "arrives in 1 day" (U2)

**Status**: built, iteration 27
**Date**: 2026-11-24
**Code**: `catalog.gd` stock line; `selftest._no_days_ok`

## Why

The U1 audit found the catalog still saying "MAIL ORDER - ARRIVES IN 1 DAY" after D2 took the
clock out: D2's check read text sheets, and the catalog is built as cards, so it slipped past.

## What

- The mail-order line reads "MAIL ORDER · 25% OVER SHELF" (it comes at once; the markup is the
  cost). The stock lines' hyphen and bar separators are middle dots ("IN STOCK AT THIS COUNTER ·
  YOU HAVE 0", "NEEDED · IN STOCK").
- The self-test's no-days check opens the parts counter and the mail-order catalog, every section
  and spread, and reads every card's text; it also requires the new mail-order line to be seen.

## Acceptance

Run against the old catalog, the check fails, listing each "ARRIVES IN 1 DAY" card; against the
fixed one it passes. Ten runs (two Hard) and the screenshot run pass.

# No wallet; cash at the top right (W1)

**Status**: built, iteration 23
**Date**: 2026-11-24
**Code**: `main.cash_label` (built with the HUD, set in `_update_hud`), `_money_pop`, `_pop`;
the pocket keys and strip; the squawk's place; `settings_ui` binds; `tutorial` tour page

## Why

Thad: "remove the wallet menu just show your cash at the top right of the screen instead".

## What

- The wallet sheet, its pocket icon, its walkthrough and its line on the opening tour are gone;
  the tour says "Four things you carry... Your cash is top right."
- Cash shows top right: Courier Prime bold 28 with thousands separators, cream with a dark outline
  against the world. Shown in the world and beside sheets; hidden in the cockpit, menus, the pause,
  the catalog (which shows cash on hand itself) and while a field loads.
- Money pops sit on the cash's line, just to its left, in the gain green or loss red, with a true
  minus and separators. A change while one is showing adds to it: one figure on screen. In the
  cockpit they go to its list.
- The pinned squawk moved down under the cash.
- Tab (the old wallet action, kept by name so saved bindings load) still turns the catalog's
  sections; Settings lists it as "Catalog: Next section".
- What the wallet listed is elsewhere already: parts and materials on the parts table and in the
  catalog, tools in the work scenes and the catalog foot, the hangar fee on the map.

## Acceptance

Self-test (`_cash_ok`): the old pocket opens nothing and there's no wallet function; the label
reads the money with separators after a change; shown beside a sheet, hidden in the pause; two
quick changes make one pop, clear of the cash and the squawk; the squawk clear of the cash.
Screenshots at 1280x720.

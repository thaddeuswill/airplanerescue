# Stats read value-first: game over (U4)

**Status**: built, iteration 28
**Date**: 2026-11-24
**Code**: `main._open_game_over` (on the shared `_glass_card`), `_money_pop` (zero sums);
`_career_stats` removed; cards tagged with `card` meta

## Why

The U1 audit: on stat screens the label was large and the figure small. The ending (E6), badge
board (LB1, B1) and wallet (W1) were already done; game over remained, over two pages.

## What

- Game over is a glass card: "Grounded / Out of money", three figures large in Courier Prime with
  small labels (cash in hand, the cheapest flight in the loss red, planes rescued), one line on what
  happened, one on next time; "Odd jobs here +$900" the one primary, Start over and Main menu quiet.
  One page; still can't be closed by accident.
- Money pops that sum to zero (a charge undone at once) go instead of showing "$0".
- Glass cards carry a `card` tag the checks and `ticket_open` read, since Godot can rename a node
  while the previous one is still freeing.

## Acceptance

Self-test (`_game_over_ok`): the card, each figure over twice its label's size, one primary of
three buttons, fits at full size, can't be closed, odd jobs pays and closes it. The no-days check
reads its labels. A pop summing to zero is gone. Ten runs (two Hard) and the screenshot run pass.

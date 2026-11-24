# Stats read value-first: game over (U4)

**Status**: built, iteration 28
**Date**: 2026-11-24
**Code**: `main._open_game_over` (on the shared `_glass_card`), `_write_checkpoint` (in `_travel`),
`has_checkpoint`, `_restore_checkpoint`, `_retry_last_plane`, `_delete_save`; `_money_pop` (zero sums);
`_career_stats` removed; cards tagged with `card` meta

## Why

The U1 audit: on stat screens the label was large and the figure small. The ending (E6), badge
board (LB1, B1) and wallet (W1) were already done; game over remained, over two pages.

## What

- Game over is a glass card: "Grounded / Out of money", three figures large in Courier Prime with
  small labels (cash in hand, the cheapest flight in the loss red, planes rescued), one line on what
  happened, one on next time. One page; still can't be closed by accident.
- The ways on (refined in review, Thad: no handouts): "Start over from the last plane" (the one
  primary) puts back the checkpoint saved as you flew out to your last job; "Start a new career"
  for a run of bad jobs; "Main menu". With no checkpoint yet, the new career is the primary.
  Odd jobs (+$900 when broke) are gone.
- Money pops that sum to zero (a charge undone at once) go instead of showing "$0".
- Glass cards carry a `card` tag the checks and `ticket_open` read, since Godot can rename a node
  while the previous one is still freeing.

## Acceptance

Self-test (`_game_over_ok`): the card, each figure over twice its label's size, the three ways on in
order with no odd jobs, fits at full size, can't be closed. `_checkpoint_ok`: a checkpoint restored
puts the save back to its cash (the replaced save kept as .bak) and loads. The no-days check
reads its labels. A pop summing to zero is gone. Ten runs (two Hard) and the screenshot run pass.

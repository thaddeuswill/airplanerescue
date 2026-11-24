# The pilot squawk card, in short pages (U7)

**Status**: built, iteration 26
**Date**: 2026-11-24
**Code**: `tutorial.sentences`, `notes_pages`, `_show_notes`, `_notes_page`, `_fit_notes`,
`NOTES_PAGE_SENTENCES`

## Why

Thad: the squawk card was too crowded; long write-ups are fine, shown about three sentences at a
time; a long squawk in smaller chunks, not one long page.

## What

- The pilot's own words first, three sentences a page at most: a long squawk takes several pages.
- Then each telling phrase with what it means, a page each; "how to read a squawk" (one sentence)
  ahead of the first.
- Last: "Look first" and GO LOOK, which ticks the squawk step and closes the card.
- Next (Enter) and Back, with "2 of 4"; the card shrinks to each page and stays centred.
- More space between parts, curly quotes, the same words.

## Acceptance

Self-test (`_notes_pages_ok`): for the longest and shortest lesson squawks, no page over three
sentences, every sentence there, Next, Back and GO LOOK work, the card fits its page; a
seven-sentence squawk splits 3, 3 and 1 in order, and page 2 shows the second chunk. The lesson
runs page through to GO LOOK. Ten runs (two Hard) and the screenshot run pass.

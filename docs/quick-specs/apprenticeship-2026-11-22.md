# Apprenticeship: the first three jobs, taught by doing them

**Status**: built
**Date**: 2026-11-22
**Code**: `scripts/tutorial.gd` (state in `main.tut`, saved; `SAVE_VERSION` 2)

## Why

The only guide was a small next-step icon. New players didn't know where the buttons were, what
the game was for, or what the pilot's squawk meant, and nothing told them when they'd done
something right.

## What

1. **Tour** (first time at home base): six cards, each pointing at what it explains: what the game
   is for (ten planes back in the air; run out of money and you're grounded), walking and E, the
   next-step icon, the checklist, the pockets (keys read from the bindings), Esc. "Skip the
   lessons" on the first card.
2. **Checklist card** (top left) for jobs 1-3. Steps tick themselves the moment the game state
   says you did them right: a red check drawn in, the line struck through, a pen scratch and a
   slip at the top of the screen (shown over any sheet or job, so a tick is never missed). Only
   the current step is explained. Steps can be done in any order; a tick never comes off.
3. **What the pilot means**: on arrival a card shows the pilot's own words and asks where you'd
   look first. Every answer says why it's right or wrong. A wrong answer costs nothing; the right
   one ticks the step. (Pilots say what they felt, heard, saw or smelled, never the cause.)
4. **One new thing per job**, so no lesson repeats the last:

| Job | Lesson | The job | New |
|---|---|---|---|
| 1 | Your first rescue | bird nest or water in the fuel (starter tools only) | the loop: call, squawk, walk-around, write-up, fix, run-up, sign, fuel, fly |
| 2 | Tools of the trade | flat main tire (needs the ratchet and pliers you don't own) | buying tools and parts, mail order when the shed's out |
| 3 | Listen to the engine | sticking valve (nothing shows outside) | a fault you hear, the red toolbox, a test that proves it |

   Every call on the map during a lesson is that lesson's job, on a clean plane (no years in the
   weather, no annual, no hidden or grounding faults).
5. **Rewards**: job 1 +$300; job 2 +$200 and the compression tester (job 3 needs it); job 3 +$500
   and the hand-off: what's coming (long-sat wrecks, look-alikes, annuals, groundings).
6. Settings, Gameplay: "Apprentice checklist" on/off hides the card and slips.

Hand tools come in on job 1; the instruments and the engine's insides wait for job 3, so the
first two jobs never ask for more than one new idea.

## Acceptance

- `--self-test --tutorial=N` (N = 1, 2, 3) plays that lesson's job through the real code: a wrong
  squawk answer doesn't tick, the right one does, every step ticks by delivery, the bonus is paid,
  the next lesson begins and the map's calls are its job.
- `--self-test --tutorial-shot=prefix` shoots the tour, checklist, quiz and reward card.
- A save from before (version 1) skips the apprenticeship.

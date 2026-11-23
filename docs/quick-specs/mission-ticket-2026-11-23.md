# The end-of-mission ticket (D3)

**Status**: built, iteration 15
**Date**: 2026-11-23
**Code**: `main._open_mission_card`, `_place_card`, `_card_figure`, `_card_stat`, `registration`,
`make_registration`, `STATIONS`, `_job_record`, `_signed_off`, `ticket_open`, `map_open`;
`shaders/glass.gdshader`; `Style` glass, gain and loss tokens; `tutorial` reward and slips

## Why

Thad: the end of a job in the middle of the screen, on glass, gains green and losses red, with the
stats and achievements; then, laid out like a ticket, and everything about the delivery on it.

## What

- A card centred on screen, on frosted earth glass (the scene blurred behind). Sized from its
  contents once its text has wrapped, re-centred when they change, scaled down to fit a small window.
- Laid out like a ticket. Top left the station (the airport's identifier and the city) and the
  plane's registration; top right the tally and the job's stats (spots checked, faults fixed).
- The owner's words, or the comeback news, under it.
- Line items with signed figures down the right: pay and an apprenticeship bonus in green, fuel,
  parts and hangar rent in red, a zero in brass. The extra costs are listed as already in those
  figures (up to three; the logbook keeps the rest). The total at the foot, under a double rule, is
  the line items added up.
- Achievements: badges earned on this job and a promotion; "No new badges" when none.
- The advice and the form line, then On to the next call.
- Delivery shows nothing else: no RESCUED banner, no "+$" pop, no owner's line at the top, no badge
  or promotion banners at sign-off, no checklist slips over the ticket. The tenth plane's ending
  keeps the banner (it has no ticket). A lesson's sign-off card opens on the map after the ticket.
- Registrations: 14 CFR 47.15 format (N, a first digit 1-9, up to five characters, at most two
  letters at the end, no I or O), made when a call comes in; older jobs and entries get one worked
  out from what they are.
- Stations: each city's primary airport, ICAO identifier (`STATIONS`). To confirm with Thad:
  Dallas KDAL (Love Field), Chicago KMDW (Midway), Seattle KBFI (Boeing Field), New York KJFK.
- Colours: glass `EARTH_950` at 0.86; gain `#9AD18A` 6.6:1 and loss `#F29A8C` 5.4:1, measured over
  white snow behind the glass. The design system's mood says "not glassy"; this one screen is
  glass by Thad's call.

## Acceptance

Self-test (`_mission_card_ok`): no banner, pop or top line; owner's words on it; centred and fits;
every figure's colour matches its sign; registration format; station codes for every city; total
equals the line items; badges are this job's (Sharp Eyes at sign-off), none says so; an old entry
opens; in lessons the sign-off card waits for the map and opens there. Screenshots at 1280x720 and
1920x1080.

# Proposal: one engine bay, tool-gated, faults you can see

**Status**: proposal, for alignment before building
**Type**: New system (replaces the station grid, the `look_<zone>` flashlight scenes and job menus at the plane)
**Date**: 2026-11-14

## The loop

Read the squawk → walk up to the Cub → open it up layer by layer → look → fetch the right tool
from the red toolbox → the test or repair shows up on the part you're holding it to → put it back
together → run it up → sign the logbook. No list of jobs anywhere. The squawk stays pinned in the
top corner the whole time.

## 1. Depth: the "Russian doll"

Each layer is reached by doing something physical to the one above it. Nothing is picked from a menu.

| Depth | What you see | How you get in |
|---|---|---|
| 0. Walk-around (3D) | The whole Cub: belly fabric, cowl, stacks, gear, prop | Walk up to it |
| 1. Cowl open | The C-85 from one side: two cylinders end-on, baffles, leads, stacks | Unlatch the side cowl (4 Camloc fasteners, screwdriver), swing it up |
| 2. Region close-up | Cylinder head and rocker cover · accessory case (both mags, starter, oil screen) · carburetor and air box · exhaust and heat muff · firewall and gascolator · sump from below | Click the region. Back steps out one layer |
| 3. Component | Today's work scenes, unchanged in rules: spark plugs, magneto, rocker cover, carb bowl... | Click the part, with the right tool in hand |

Back (or Esc) always goes up one layer. The cowl stays open between regions; you close it once,
on the way out. That's the shared-cowl rule we already have, now physical.

The stations grid goes away. Regions replace its 27 tiles: 6 regions per side instead of a list.

## 2. Tool-gating triggers

**One tool in hand.** You hold one tool at a time, shown in the corner and as the cursor. The red
toolbox stands on the ground next to the plane at every field (you fly with it). Swapping a tool
means going to the toolbox.

**A part only offers what the tool in your hand can do there.** Each part has a list of
interactions, as data:

```gdscript
{"part": "mag_left", "tool": "timing", "verb": "Clip the timing light on",
 "needs": ["cowl_open", "plug_1_top_out"], "depth": 2, "gives": "mag_timing_test"}
```

The trigger rule, in order:

1. **Visible?** The part is drawn at the current depth (a plug isn't, with the cowl shut).
2. **Tool fits?** The held tool has an interaction on this part. If not, hovering shows the part's
   name and nothing else. Bare hands can always *look closer* and work latches.
3. **Ready?** Everything in `needs` is done. If not: Easy and Medium say what's first ("Pull the
   No. 1 top plug first"); Hard says "Not yet".
4. **Do it.** Hold the mouse, as now. Time passes. The result is a reading, a part off, or a
   finding written onto the squawk sheet.

The C-85 scenarios, first pass:

| Tool | Part | What it offers | Needs |
|---|---|---|---|
| Hands / flashlight | Anything at depth 1-2 | Look closer (finds visible faults) | — |
| Screwdriver | Cowl Camlocs, baffle screws, air box | Open, remove | — |
| Spark plug socket (ratchet) | Each plug | Pull, reinstall (torque wrench to finish) | Lead off |
| Compression tester | Each cylinder's top plug hole | Differential compression test | Plug out, piston at TDC |
| Timing light ("buzz box") | Each magneto | Check or set timing | Plug out on No. 1, leads clipped |
| Safety-wire pliers | Safety wire at the oil screen, prop bolts, drain plug | Cut, re-wire | — |
| Torque wrench | Plugs, prop bolts, cylinder nuts | Final torque | Run down snug first |
| Rag | Leak sites | Wipe clean (to see if it comes back after the run-up) | — |

Tests appear only with their tool in hand. That is the point: "I need a compression check" becomes
a walk to the toolbox, not a menu item.

## 3. Faults you can see

Every fault that shows on the outside gets a tell at the layer where a mechanic would see it:
first from a distance, then clearly up close.

| Fault | Depth 0 (walk-around) | Depth 1-2 (cowl open, close-up) |
|---|---|---|
| Oil leak, cylinder base or pushrod tube | Oil streak down the belly, drips under the nose | Wet, dark oil weeping at the base gasket or tube seal; dust stuck to it |
| Cracked exhaust stack or muffler | Dark soot streak on the cowl behind the stack | Gray-white exhaust staining at the crack |
| Leaking carb (float needle) | Blue stain on the belly fabric, raw-gas smell line in the squawk | Blue-green stain and wet fuel under the bowl |
| Chafed ignition lead | — | Frayed braid, rubbed bare where it crosses the baffle |
| Loose or missing safety wire | — | Wire hanging, or the nut turned off its witness mark |
| Bird nest | Straw at the cowl inlet | Nest packed on the cylinder fins |
| Clogged air filter | — | Filter caked gray |
| Fuel line leak | Blue stain on the firewall | Wet fitting |

Inside faults (bad mag points, a sticking valve, worn rings) have no tell. The squawk and the
run-up point at them, and the tool tests prove them. This is what keeps troubleshooting honest.

**Difficulty** sets how loud the tells are. Easy draws them strong and adds a faint glint. Medium
shows them plainly. Hard keeps them subtle: you have to look closely.

## 4. The squawk

A pilot writes it: what they felt, heard, saw or smelled, never the cause. It's pinned in the top
corner from the radio call to sign-off. Examples for our Cub faults:

| Fault | Squawk |
|---|---|
| Bad left mag | "Engine stumbled and dropped nearly 250 RPM when I switched to the left mag during run-up. Right mag sounds fine." |
| Leaking carb | "Smelled strong raw gas after shutting down, and there's a blue stain dripping onto the belly fabric." |
| Sticking exhaust valve | "Felt sluggish on the takeoff roll and had to fight it off the grass. Pulling the prop through, one blade comes over easy and goes chuff-chuff." |
| Cracked muffler | "Got a headache on the way home and the cabin smells like the exhaust. There's a black streak on the cowl that wasn't there last week." |
| Oil leak | "Oil all down the belly after an hour. I've been adding a quart every couple of flights." |
| Chafed lead | "Runs fine most of the time, then coughs over bumps on the grass. Did it twice on taxi." |
| Clogged air filter | "Down on power on climb-out, and the RPM drops way more than usual when I pull carb heat." |

Every fault gets one, written in that voice. Several faults on one plane combine into one note.

## Build order

1. The squawk card, pinned, and pilot-voice squawks for every fault (small, no new art).
2. Tool in hand and the interaction table; tests gated by tool. The existing work scenes keep
   working as depth 3.
3. The cowl-open view and region close-ups (depth 1-2), replacing the station grid and flashlight
   look scenes. **Needs art**: one painted overview per engine side, plus the bottom, cut into regions.
4. Visual tells: decal art per fault, placed at each depth. **Needs art**: oil weep, soot,
   blue stain, frayed lead, loose wire, at two sizes each.

## Built (2026-11-14)

Decisions taken where the questions went unanswered (change them if they're wrong):
- **Painted 2D layers**, not 3D: the existing scene paintings are the bay's views.
- **Hand tools in your roll, instruments in hand.** Screwdriver, ratchet, pliers, torque wrench and
  rag ride in your roll, since one repair uses several in turn. The compression tester, timing
  light and fabric punch live in the red toolbox by the plane (`main._open_kit`); you hold one at a
  time, and only it works.

What's in:
1. **Squawks**: `main.SQUAWKS`, pinned top right (`main._update_squawk`). Self-test guards: every
   reportable fault has one; a hidden fault's squawk never names it or its part.
2. **Toolbox and instruments**: `main.INSTRUMENTS`, `main.held`, `work.gd usable()`.
3. **The engine bay**: `scripts/bay.gd`, replacing the station grid and the flashlight look for the
   engine. Cowled → unlatch (screwdriver) → left side, top, rear accessory case, underneath,
   firewall. Each part offers what you can do there with what you carry; "Look closer" writes up a
   visible fault. On Medium and Hard the work order sends engine work through the bay.
4. **Tells**: drawn over the parts, stronger on Easy (with a glint), faint on Hard. Placeholders in
   code until the art in `ART_PROMPTS.md` section 7 exists.

Not yet: the other spots (cabin, gear, tail, wings, prop) still use the flashlight look and the
station grid; the same treatment would fit them. A 3D cowl you physically unlatch.

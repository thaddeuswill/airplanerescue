# Job catalog by ATA code

Every job on the airplane, sorted by ATA chapter, with the real-world values each one needs.

- **Sources of values:**
  - FAA AC 43.13-1B CHG 1, pages 6-31 to the end (PDFs and searchable text in `reference/ac43-13-1b/`). Paragraph and table numbers below point into it.
  - Piper J3C-65 Cub Special owner's manual, May 15, 1946. Cited below as "Cub p.N" using the page numbers printed in the manual. The scan itself is not in the repo.
- **Codes** are ATA chapter-section. Drop the dash to get the FAA's four-digit JASC code (32-40 is JASC 3240).
- **In game** names the existing fault id in `scripts/main.gd` when the job is already built.
- **Status:** `HAVE` means every number the job needs is on this page. `PARTIAL` means the general rule is here but an airplane-specific number is missing. `NEED` means AC 43.13-1B gives no value at all.
- Everything missing is collected in one list at the bottom: [Values still needed](#values-still-needed).

AC 43.13-1B is a general-practice book. It deliberately leaves model-specific numbers to the manufacturer. The Cub manual fills the airframe ones. What is still open comes mostly from two documents: the Continental A-65 engine manual and the propeller maker's instructions.

Two things to know before building from this:

1. **Parts 1 to 3 of the AC are not in the repo yet.** They hold Chapters 1 to 5 and most of 6: wood, fabric, plastics and windshields, metal structure and welding, inspection methods, and corrosion treatment of aluminum. Every job that depends on them is marked `NEED (AC parts 1-3)`.
2. **The real Cub has no electrical system** ("not standard equipment", Cub p.34). No battery, starter or radio; it is hand-propped. The game's `battery`, `starter` and `avionics` jobs are fine for the other four plane types, but on the Cub they are a liberty. Its brakes are hydraulic expansion units inside the wheel, not discs, and its propeller is wood.
3. **The game's tire pressure is wrong for a Cub.** `scripts/work.gd` says 18 psi; the manual says 15.

## Shared tables

These are used by many jobs, so they are written out once.

### Bolt and nut torque (Table 7-1, inch-pounds, fine thread, dry clean cadmium-plated threads)

| Thread | Tension nut (AN310, MS20365) | Shear nut (AN320, MS20364) | Max, tension nut | Max, shear nut |
|---|---|---|---|---|
| 8-36 | 12-15 | 7-9 | 20 | 12 |
| 10-32 | 20-25 | 12-15 | 40 | 25 |
| 1/4-28 | 50-70 | 30-40 | 100 | 60 |
| 5/16-24 | 100-140 | 60-85 | 225 | 140 |
| 3/8-24 | 160-190 | 95-110 | 390 | 240 |
| 7/16-20 | 450-500 | 270-300 | 840 | 500 |
| 1/2-20 | 480-690 | 290-410 | 1100 | 660 |
| 9/16-18 | 800-1000 | 480-600 | 1600 | 960 |
| 5/8-18 | 1100-1300 | 600-780 | 2400 | 1400 |
| 3/4-16 | 2300-2500 | 1300-1500 | 5000 | 3000 |

Coarse thread: 8-32 12-15, 10-24 20-25, 1/4-20 40-50, 5/16-18 80-90, 3/8-16 160-185, 7/16-14 235-255, 1/2-13 400-480 (tension nuts). The full table, including larger sizes, is in `reference/ac43-13-1b/part4_ch6-8.txt`.

Rules (7-43, 7-126, 8-92): threads dry, clean and unlubricated. For a castellated nut, torque to the low end of the range, then keep tightening only until a slot lines up with the hole. Never loosen or over-torque to line up a hole; swap the bolt or add a washer.

### Reused self-locking nuts (Table 7-2, minimum prevailing torque, inch-pounds)

7/16-20: 8. 1/2-20: 10. 9/16-18: 13. 5/8-18: 18. 3/4-16: 27. A nut that turns below this is scrap. Fiber-insert lock nuts are limited to 250 °F (8-9).

### Safety wire and cotter pins (7-122 to 7-127)

- Double-twist wire: 0.032 in minimum where the hole is larger than 0.045 in. 0.020 in is allowed for holes 0.045 to 0.062 in when the parts are less than 2 in apart.
- Leave a pigtail of 4 to 6 full turns (1/2 to 5/8 in) and bend it under, toward the part.
- The wire must pull each fastener in the tightening direction. Taut but not over-twisted. Never nicked or kinked, never reused.
- Seals on emergency equipment: copper 0.020 in only.
- Cotter pins: the largest that fits the hole, never reused. The prong bent over the bolt must not be longer than the bolt diameter; the prong bent down must lie flat on the nut and clear the washer.

### Tubing and hose (8-31, 9-30, Table 9-2)

| Tube OD | Flare nut torque, aluminum tube (in-lb) | Steel tube (in-lb) | Min bend radius, aluminum | Max spacing between clamps |
|---|---|---|---|---|
| 1/8 | 20-30 | 75-85 | 3/8 in | 9 in |
| 3/16 | 25-35 | 95-105 | 7/16 in | 9 in |
| 1/4 | 50-65 | 135-150 | 9/16 in | 12 in |
| 5/16 | 70-90 | 170-200 | 3/4 in | 12 in |
| 3/8 | 110-130 | 270-300 | 15/16 in | 16 in |
| 1/2 | 230-260 | 450-500 | 1-1/4 in | 16 in |
| 5/8 | 330-360 | 650-700 | 1-1/2 in | 22 in |
| 3/4 | 460-500 | 900-1000 | 1-3/4 in | 22 in |

- Flares are 37 degrees. A 45-degree automotive flare is a failure. Double flare on soft aluminum 3/8 in and under.
- A bend may flatten to no less than 75% of the original diameter.
- Scratches up to 10% of wall thickness can be burnished out (not in the heel of a bend). A dent under 20% of tube diameter is acceptable (not in the heel of a bend).
- Hose: 5 to 8% slack, supported at least every 24 in.
- No Teflon tape on fuel lines (8-38).

### Control cable (7-140 to 7-184)

| Cable | Construction | Minimum breaking strength | Turnbuckle safety wire (Table 7-8) |
|---|---|---|---|
| 1/16 in | 7x7 | 480 lb | single wrap, 0.040 copper or brass |
| 3/32 in | 7x7 | 920 lb | single wrap, 0.040 copper or brass |
| 1/8 in | 7x19 | 2,000 lb | single wrap 0.040 stainless, or double wrap 0.040 copper or brass |
| 5/32 in | 7x19 | 2,800 lb | double wrap 0.040 stainless, or single 0.057 stainless |
| 3/16 in | 7x19 | 4,200 lb | double wrap 0.040 stainless, or single 0.057 stainless |

- Replace the cable for **one broken wire** in a critical fatigue area: anywhere it runs over a pulley or through a fairlead, or within 1 ft of a swaged fitting.
- Replace when the outer wires are worn 40 to 50% (the wires in a strand look blended together).
- Find broken wires by wiping with a cloth, then bend the cable to open hidden breaks. 7-power magnifier for suspects.
- Fairlead deflection: 3 degrees maximum. No splice within 2 in of a fairlead or pulley.
- New terminals: proof-load to 60% of breaking strength for 3 minutes.
- Turnbuckle: no more than 3 threads showing at either end. Safety wire wrapped 4 turns around each shank.
- Rust prevention on carbon steel cable: MIL-C-16173 grade 4, tack-free in 24 hours at 77 °F.

### Electrical wiring (Chapter 11, Sections 8 to 15)

- Clamp every 24 in or less. Sag between clamps: 1/2 in maximum.
- Bend radius: 10 times the diameter of the largest wire (3 times where supported at a terminal). Coax: 6 times.
- Keep 6 in from fuel, oil and oxygen lines, and route above them. Absolute minimum 2 in.
- Keep 1/2 in from moving controls under light hand pressure. 3/8 in clearance, or a grommet, where a bundle passes through a bulkhead.
- Splices: none within 12 in of a terminal, no more than one per 10 ft of wire, staggered in a bundle.
- Damaged strands (Table 11-13): wire sizes 24 to 14, 2 nicked and none broken. Sizes 12 to 10, 4 nicked and none broken. Aluminum wire, none at all.
- Identification marks every 15 in.
- Bonding: 0.003 ohm maximum per jumper connection. Fuel system parts 1 ohm or less to structure. Equipment cases 0.0025 ohm.

## Piper J3C-65 values

Everything the Cub manual gives, in one place. These fill the airframe gaps for the Cub only; the other four plane types still need their own.

**Identity and dimensions (Cub p.9, 11, 12).** Two-seat tandem, Continental A-65-8, wood spars or aluminum spars, fabric cover, welded steel tube fuselage, door on the right. Span 35 ft 2-1/2 in. Length 22 ft 4-1/2 in. Height 6 ft 8 in. Wing chord 5 ft 3 in, area 178.5 sq ft, root incidence 2 degrees. Wheel tread 71 in. Baggage 20 lb.

**Servicing.**
- Fuel: 12 US gallons, 73 octane minimum, aviation grade preferred (p.31, 49). The cap gauge rod stands 11 in above the cap when full (p.37).
- Oil: 4 quarts on the stick. SAE 20 below 32 °F, SAE 30 from 32 to 70 °F, SAE 40 from 70 to 100 °F (p.38, 49).
- Main tires 8.00 x 4 at 15 psi. Tailwheel 2.00 x 6 solid rubber (p.12, 19).
- Brake fluid: Univis No. 40, about 1 pint (p.20, 21).
- Hinges and gear fittings: light engine oil. Tailwheel: wheel-bearing grease weekly, daily in mud or dust. Shock struts: strip and grease with high-temperature grease at 250 hours (p.22, 25, 50, 51).
- Never oil or grease the stabilizer trim cable; it drives by friction (p.30, 35).
- Wash with warm water and alkali-free soap, low-pressure rinse only. Windshield: mild soap, cool water, bare hand, then clear wax for scratches (p.49, 50).

**Engine limits and run-up (p.39, 41, 49).**
- Oil pressure must show within 30 seconds of start, or shut down. Minimum 30 psi. Oil temperature maximum 220 °F.
- Idle 550 to 600 rpm warm. Warm up at 800 to 1,200 rpm until oil reaches 90 °F.
- Mag check at 2,100 rpm: drop of 75 rpm at most. No more than 30 seconds on one magneto.
- Take-off 2,300 rpm. Cruise 2,150 rpm at 73 mph. Full throttle for 3 minutes at most.
- Carb heat on should cost about 50 rpm.
- Cowl winter plate fitted only at 40 °F or colder (p.51).

**Speeds (p.41, 47).** Lifts off at about 39 mph. Best climb 55 mph. Glide 50 to 60 mph. Stall 38 mph. Never exceed 122 mph. These are miles per hour; the game's ferry flight uses 55 knots to rotate.

**Hand-prop start (p.38, 39).** Chock the wheels. Switch off, and check it. Throttle one-tenth open. Fuel on. Pull the prop through several times. Switch on. Swing the prop. If it won't start: switch off, 3 or 4 strokes of primer, lock the primer, try again. If flooded: switch off, throttle wide open, turn the prop backwards several times.

**Wheels and brakes (p.19 to 22).**
- New tire: inflate to about 35 psi to seat the beads, then let down to 15.
- Axle nut: tighten while spinning the wheel until a slight drag is felt, back off one castellation, fit the cotter pin.
- Brake bleeding: pump fluid in from the bleeder tee at the wheel until the system is full, close the tee, open the cap screw on the pressure unit half a turn, hold the front pedal in about 1 in, tighten the cap screw. A soft "fading" pedal means air. Keep fluid off the linings and the fabric. Never press the brakes with a wheel off.
- Tools the manual lists for it: slot screwdriver, crescent wrench, hand pump, bleeder tee (Piper part 460 770).

**Jacking and leveling (p.16).** Lift the wing at the lift-strut-to-spar joint and put a jack under each axle extension, clear of the brake line. Tail on a tripod jack under the tail spring clamp. Level sideways with a 30 in level on two 2-1/2 in blocks on the rear wing butt fittings. Level fore and aft with a 20 in level on the left cockpit longeron.

**Rigging (p.16, 17, 26, 29).**
- Dihedral: a string stretched tip to tip over the front spar sits 2-1/8 in above the center section. Adjust at the front lift strut clevises.
- Wash-out: 30 in level under the rib at the outer end of the aileron, with a 3/8 in block at the rear end, reads level. Adjust at the rear struts.
- Ailerons: sticks centered, aileron trailing edge in line with the wing's. Loosen one turnbuckle and take up the other by the same amount.
- Turnbuckles: 2 threads showing at most (tighter than the AC's 3). Safety with one strand of 0.040 brass wire.
- Tail brace wires: only tight enough to hold the stabilizers level. Wrap friction tape on the wire before gripping it. Threads must show through the end of each nipple.
- Wing drag wires have 6-40 right-hand threads at both ends. Replace a bent wire. Never mark one with pliers.

**Control cables (p.28, 30).** Elevator: two 1/8 in 7x19 cables with turnbuckles at the elevator horns. Stabilizer trim: endless 1/16 in 7x7 cable, tension set by an idler pulley behind the inspection plate on the left side of the tail.

**Fuel system (p.31 to 33).** Strainer bowl checked daily for water, removed and cleaned every 10 hours, bail nut safetied afterwards. Tank drain plug pulled every 20 hours with the tail down. Tank finger strainer cleaned every 100 hours. The tank comes out through the cockpit after removing the diagonal tube behind the firewall.

**Structure (p.13 to 15, 23, 24).**
- Fuselage tubes are 1025 steel with chrome-moly in the high-stress members. Splice with sleeves. Prime repairs with zinc chromate.
- Check the lower longerons near the tailpost for rust.
- A cracked engine mount is replaced, not repaired. Mount bolts snug, never over-tightened.
- Lift struts: sand and repaint corroded spots. Do not over-tighten jury strut bolts; it crushes the strut.
- Aileron hinge pin holes checked for stretch every 100 hours.
- Keep every drain grommet open. Lost sheet-metal screws are replaced one size larger.

**Ground handling (p.42, 51).** Push and lift only at the lift strut ends, the wing tip at the spars, and the handle at the tail. Never the strut middle, trailing edge, stabilizer or brace wires. Tie down with 1/2 to 5/8 in rope at the tail handle and the top of both front lift struts, no slack. Lock the controls with the front seat belt around the rear stick. Leave a wood prop horizontal when parked outside.

**Inspection schedule (p.35, 36).**
- Line check (daily): engine mount, exhaust manifolds, fuel strainer, propeller, controls free, lift and jury strut bolts and cotters, aileron and tail hinge pins, brace wires, gear bolts safetied, tires, fabric.
- Every 20 hours: all of the above, drain the tank, check elevator and rudder controls for corrosion, lubricate controls and gear, check brakes, pull the exhaust shrouds and check for scale, cracks and leaks, check engine controls and piping, clean the engine bay, check tailwheel play and lubricate it, open the tailpost cover and check the elevator cable ends and trim screw, clean and re-oil the carburetor air filter.
- Every 100 hours: the CAA Form 319 periodic inspection.

## 05 Time limits and maintenance checks

| Code | Job | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|
| 05-20 | Annual / 100-hour inspection | Open every panel, work a checklist across all chapters below | 8-2, 7-149, 9-2 | Intervals in the table under this one | HAVE for the Cub (line, 20-hour and 100-hour lists, Cub p.35-36) |
| 05-50 | Prop-strike (sudden stoppage) inspection | Dial-indicate the crankshaft flange, turning it in 90-degree steps | 8-2 | Method only | PARTIAL: need the runout limit |
| 05-50 | Return to service after years of storage | Wash, sump, pre-oil, free stuck parts (the neglect jobs) | Cub p.24, 49-52 | Clean out dirt trapped between tubes and fabric, check lower longerons at the tailpost, open drain grommets, re-tighten wood prop bolts | PARTIAL: need the engine side (pre-oil, preservation) |
| 05-50 | Aircraft recovered from water | Flush with fresh water, dry, re-preserve | 6-220 to 6-223 | Removed parts into hot water or oil at 180 °F. Substitute cleaner: 1 part compound to 9 parts water | HAVE |

Intervals the AC gives: control cables every annual or 100 hours. Fixed-pitch prop bolt torque after the first flight, at 25 hours, then every 50 hours. Bungee cords replaced near 5 years. ELT inspected every 12 months. Static system, altimeter and transponder every 24 months. Life preservers every 12 months. First-aid kit every 120 days. Oxygen cylinder hydrostatic test every 5 years (3 years for lightweight cylinders).

## 06 to 11 Dimensions, lifting, weighing, towing, parking, placards

| Code | Job | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|
| 06-00 | Dimensions and areas | Reference data, no job | Cub p.11-12 | See Cub values | HAVE for the Cub |
| 07-10 | Jacking | Jack the gear clear of the ground before wheel, brake and gear work. In game as a step of `tire` and `brakes` | 9-2 | Jack for every 100-hour or annual gear inspection | HAVE for the Cub (p.16) |
| 08-10 | Weighing and balance | Level the plane, weigh at each wheel, compute empty weight and CG | 10-14 to 10-23, Figs 10-4, 10-5 | Formulas for tailwheel and nosewheel types | PARTIAL: leveling is in hand (Cub p.16). Need datum, CG limits, empty weight |
| 09-10 | Ground handling | Push the plane in and out of the hangar. In game | Cub p.24, 51 | Where you may and may not push or lift | HAVE for the Cub |
| 10-20 | Tie-down and chocks | Chock and tie down on arrival | Cub p.42 | Rope size, three tie points, control lock | HAVE for the Cub |
| 11-20 | Placards and markings | Check required placards and instrument markings are present and legible | 8-37, 12-37 | Rule only | PARTIAL: need the placard list |

## 12 Servicing

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 12-10 | Refuel | fuel truck | Ground the plane, fuel outdoors | 8-38, 11-191 | Aircraft grounded. Extinguisher at hand. Open lines capped. Bond 1 ohm or less | HAVE for the Cub: 12 gal, 73 octane minimum |
| 12-10 | Drain and replace stale fuel | `stale_fuel` | Sump each drain until clean, refill | 8-38 | Drain plug at the rear of the tank, strainer bowl in the engine bay (Cub p.32-33) | PARTIAL: need how to judge bad fuel |
| 12-10 | Oil change | no | Drain, check the screen for metal, refill | 8-5, 8-6 | Fine metal is normal on a new engine only. An unusual amount means teardown | PARTIAL: 4 quarts, grade by temperature (Cub p.38, 49). Need change interval |
| 12-10 | Pre-oil a dry engine | `pre_oil` | Pull top plugs, turn the prop until oil pressure shows | Cub p.39 | After start, pressure within 30 seconds or shut down. 30 psi minimum | PARTIAL: need the pre-oil procedure itself |
| 12-10 | Tire inflation | step of `tire` | Seat the tube, inflate | 9-15, 9-18, Cub p.19 | Cub: inflate to about 35 psi to seat the beads, let down to 15 psi (p.19). The game's 18 psi should become 15 | HAVE for the Cub |
| 12-20 | Lubrication | no | Grease gear pivots and wheel bearings, oil cables | 9-3, 7-150, Cub p.22-51 | See Cub values, Servicing | HAVE for the Cub |
| 12-30 | Wash down | wash | Wash off grime before inspecting | 6-220, Cub p.49-50 | Warm water, alkali-free soap, low-pressure rinse. Windshield by bare hand | HAVE |

## 20 Standard practices

These are the hand skills every other job reuses. All values are in the shared tables above.

| Code | Job | Status |
|---|---|---|
| 20-10 | Torque a bolt or nut | HAVE |
| 20-10 | Check a reused self-locking nut | HAVE |
| 20-20 | Safety wire | PARTIAL: need twists per inch |
| 20-30 | Cotter pin | HAVE |
| 20-40 | Make up and fit a rigid line (cut, flare, bend, clamp) | HAVE |
| 20-40 | Replace a flexible hose | HAVE |
| 20-50 | Bonding jumper | HAVE |
| 20-60 | Remove corrosion from steel | PARTIAL: prime within 1 hour of sanding; glass-bead blast at 40 to 50 psi. Depth limits are in AC parts 1-3 |
| 20-60 | Remove and treat corrosion on aluminum | NEED (AC parts 1-3) |

## 21 to 26 Cabin systems

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 21-40 | Cabin heat: muffler shroud leak check | no | Pull the heat shroud, look for cracks, pressure-test | 8-46, 8-49, Cub p.36 | Shrouds off every 20 hours. Plug the openings, 2 psi inside, submerge in water, watch for bubbles. Damaged: replace | HAVE |
| 22-10 | Autopilot | no | Not fitted to a Cub | 12-18 | Per manufacturer only | NEED (other plane types only) |
| 23-10 | Radio and antenna | `avionics` | Replace the antenna, coax and set, check bonding | 12-8, 12-9 | Bond about 0.003 ohm. Coax bend radius 6 times its diameter. Check insulators, sealant at the base, safety wire | HAVE |
| 23-60 | Static wicks | no | Check each wick is present, secure and bonded | 12-9 | Base to skin 0.1 ohm maximum. 1 in of braid showing | HAVE |
| 24-30 | Battery | `battery` | Test, charge or replace, neutralize spilled acid | 11-15 to 11-22 | See battery values below | PARTIAL: need battery size and type per plane |
| 24-30 | Generator or alternator | no | Check output, belt, brushes | 11-33 | none | NEED |
| 24-50 | Wiring repair: splice, terminal, clamp | no | Cut out damage, splice, re-clamp | Ch 11 Sec 8-15 | Shared wiring rules | HAVE |
| 24-60 | Fuses, breakers, switches | no | Replace a blown fuse or weak breaker with the right rating | 11-47 to 11-53, Table 11-4 | Rating tables are in `part6_ch11.txt` | PARTIAL: tables need typing up |
| 25-10 | Seats and belts | no | Check seat frames, belt webbing and buckles | 9-60 | Interior materials rule only | NEED |
| 25-60 | ELT | no | Inspect, test | 12-21, 12-22 | Every 12 months. Test only in the first 5 minutes of the hour, 3 sweeps at most. An AM radio held 6 in from the antenna should pick up the tone | PARTIAL: need battery replacement rule |
| 25-60 | Survival gear (larger types) | no | Leak-test life vests and rafts | 9-37 to 9-44 | Vest: 2 psi, must stay firm 12 hours. Raft: 2 psi, after 24 hours must hold above 1 psi | HAVE |
| 26-20 | Hand fire extinguisher | no | Check charge, seal and mount | 7-123 | Seal wire: copper 0.020 in | PARTIAL: need weight check and interval |

Battery values (11-15 to 11-22): fully charged specific gravity 1.275. One-third discharged 1.240, two-thirds discharged 1.200, read at 80 °F. Temperature correction: add 4 points for every 10 °F above 80, subtract 4 for every 10 °F below (a 1.260 reading at 40 °F is really 1.244). Sealed 12-volt battery open-circuit voltage: 12.9 full, 12.7 at 75%, 12.4 at 50%, 12.0 at 25%. Charge at no more than 2.35 volts per cell. Never use a high-amperage car charger. Neutralize acid and clean corrosion with a 10% baking soda solution. 

## 27 Flight controls

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 27-10 | Aileron cables and pulleys | no | Inspect, replace, rig, safety | 7-149, Cub p.28-29 | Shared cable table. Cub rigging steps. Phenolic pulleys | PARTIAL: need cable size and travel in degrees |
| 27-20 | Rudder cables | `control_cables` | Replace the cable, tension both turnbuckles, safety wire | 7-147 to 7-182, Cub p.29 | Shared cable table. Check at the fairleads under the seat and where the cables leave the fuselage. Pedal return springs hold the pedals forward | PARTIAL: need cable size and travel in degrees |
| 27-30 | Elevator cables | no | Same as rudder | 7-149, Cub p.28 | Two 1/8 in 7x19 cables (2,000 lb). Lubricate the bellcrank behind the rear seat | PARTIAL: need travel in degrees |
| 27-40 | Stabilizer trim | no | Inspect the trim screw, tension the drive cable at the idler | Cub p.26, 30 | 1/16 in 7x7 endless cable. Never lubricate it. Do not over-tighten the idler | HAVE for the Cub |
| 27-50 | Flaps (not on a Cub) | no | Inspect tracks, cables, travel | none | none | NEED |
| 27-00 | Pulleys and fairleads | no | Spin each pulley, check for flat spots and alignment | 7-149 | Rotate pulleys that only turn a small arc to give the cable a fresh surface. Fairlead deflection 3 degrees maximum | HAVE |

## 28 Fuel

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 28-10 | Fuel tank repair | no | Remove, purge, repair, leak-test | 8-32 | Never weld or solder until purged of fumes. Flux cleaned off with a 5% nitric or sulfuric acid dip | PARTIAL: need leak-test pressure |
| 28-20 | Fuel line | `fuel_line` | Replace the line, clamp it, wipe up | 8-31, Table 9-2 | Shared tubing table. Route below wiring | HAVE |
| 28-20 | Fuel strainer | no | Drop the bowl, clean bowl and screen, flush, safety the nut | 8-36, Cub p.32-33 | Check daily, clean every 10 hours, safety the nut under the bowl | HAVE for the Cub |
| 28-10 | Tank drain and finger strainer | no | Pull the drain plug; pull the outlet fitting and clean the strainer | Cub p.33, 35 | Drain every 20 hours with the tail down. Finger strainer every 100 hours | HAVE for the Cub |
| 28-20 | Fuel shut-off valve | no | Check it moves freely and does not leak | 8-34, Cub p.9, 31 | Push-pull shut-off on the left side, wire-operated | HAVE (no value needed) |
| 28-40 | Fuel quantity gauge | no | Clean the float rod so it slides freely | 8-37, Cub p.37 | Rod in the tank cap, 11 in showing when full. Polish with crocus cloth | HAVE for the Cub |

## 29 to 38 Systems a Cub mostly does not have

| Code | Job | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|
| 29-10 | Hydraulic power (larger types) | Check fluid, lines, leaks | 9-25 to 9-30 | Shared tubing table. Never mix fluid types | PARTIAL: need system pressure and fluid type |
| 30-30 | Pitot heat (larger types) | Check the heater works | none | none | NEED |
| 31-10 | Instrument panel and markings | Check each gauge is marked and reads | 8-37, 8-95 | A tachometer more than 2% off is replaced. Cub limits are under Cub values | HAVE for the Cub |
| 32 | Landing gear | See its own section below | | | |
| 33-40 | Lights (larger types) | Replace a lamp, check wiring | Ch 11 | Shared wiring rules | NEED: lamp types |
| 34-10 | Pitot-static leak test | Pump the static side down and the pitot side up, watch for leaks | 12-58, 12-59 | Static: pull to 1,000 ft (1.07 in Hg), lose no more than 100 ft in 1 minute. Pitot: push to 150 knots (1.1 in Hg), lose no more than 10 knots in 1 minute. No corrosion within 1/2 in of the probe tip | HAVE |
| 34-10 | Altimeter check | Compare against a known altitude | 12-19 | Difference 125 ft maximum. Every 24 months | HAVE |
| 34-20 | Compass swing | Turn the plane on a compass rose, adjust, write the card | 12-37 | Read with engine at about 1,700 rpm. Set N-S screw on north, E-W screw on east. On south and west, take out half the error. Record every 30 degrees. No heading more than 10 degrees off | HAVE |
| 34-50 | Transponder (larger types) | Test | 12-20 | Every 24 months | PARTIAL |
| 35-10 | Oxygen (larger types) | Leak-test and refill | 9-47 to 9-51, Table 9-5 | Normal charge 1,800 psi at 70 °F. Leak test: 1 hour, drop of 100 psi maximum, temperature steady within 10 °F. Fill to 1,975 psi at 70 °F so it cools to 1,850. No oil or grease anywhere near it | HAVE |
| 36-00 | Pneumatic | Not fitted | none | none | not applicable |
| 37-10 | Vacuum (venturi) | Check suction to the gyros | 12-38 | 4 in Hg for attitude gyros, 2 in Hg for the turn and slip | HAVE |
| 38-00 | Water and waste | Not fitted | none | none | not applicable |

## 32 Landing gear

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 32-10 | Main gear structure | no | Jack, check attach bolts and holes for cracks and stretch | 9-2 to 9-7, Figs 9-2 to 9-6 | Inspection method | PARTIAL: Cub hinge fittings have replaceable steel bushings, oiled with engine oil, end play shimmed with washers (p.22). Need bolt sizes |
| 32-10 | Shock (bungee) cords | no | Read the date threads, replace old cords | 9-2, Table 9-1, Cub p.51 | Replace near 5 years. Year thread by last digit: 0 or 5 black, 1 or 6 green, 2 or 7 red, 3 or 8 blue, 4 or 9 yellow. Quarter thread: 1st red, 2nd blue, 3rd green, 4th yellow | HAVE |
| 32-20 | Tailwheel | no | Check the 3-leaf spring, steering springs, spindle play; grease | Cub p.9, 22, 36, 50 | 2.00 x 6 solid tire. Grease weekly. Spring nut snug and cottered | HAVE for the Cub |
| 32-40 | Tire and tube | `tire` | Jack, pull the wheel, swap, inflate, cotter pin | 9-14 to 9-21 | Remove when worn to the bottom of any groove, when fabric shows, or for a cut over half a rib wide and deeper than half the groove. Never probe a cut on an inflated tire | HAVE for the Cub: 15 psi, axle nut by feel (Cub values) |
| 32-40 | Wheel bearings | no | Clean, inspect, repack, set the axle nut | 9-7, 9-21 | Bearing and race stay a matched set. Cub: Timken tapered rollers, good for several hundred hours between greasing. Slight drag, back off one castellation, cotter (p.19-20) | HAVE for the Cub |
| 32-40 | Brakes | `brakes` | Pull the wheel, replace worn parts, bleed | 9-7, Cub p.20-22 | Univis No. 40 fluid and the bleeding steps under Cub values. Discolored discs (other planes) are overheated: replace | PARTIAL: need lining wear limit |
| 32-70 | Skis and floats | no | Inspect, leak-test a float | 9-8, 9-9 | Float: fill with water, leave 24 hours. Ski runner split up to 10% of its length is repairable | HAVE |

## 51 to 57 Structure

Almost everything here waits on AC parts 1 to 3.

| Code | Job | In game | What the player does | Status |
|---|---|---|---|---|
| 51-10 | Fabric patch and re-dope | no | Cut out damage, sew or cement a patch, dope | NEED (AC parts 1-3, Ch 2) |
| 51-10 | Fabric strength test | no | Punch-test old fabric | NEED (AC parts 1-3, Ch 2) |
| 51-20 | Wood repair: spar or rib splice | no | Scarf, glue, clamp | NEED (AC parts 1-3, Ch 1) |
| 51-30 | Steel tube weld repair | no | Sleeve or patch a rusted tube | PARTIAL: Cub tube steels, sleeve splices and zinc chromate primer (p.23). Weld details in AC parts 1-3, Ch 4 |
| 51-40 | Rivet a sheet-metal patch | no | Drill, deburr, rivet | NEED (AC parts 1-3, Ch 4). Rivet part-number tables are in hand (Table 7-10) |
| 52-10 | Cabin door hinge pin | `door_pin` | Soak, drive out, replace, cotter pin | NEED: pin size. Cotter pin rule is in hand |
| 53-10 | Fuselage tube corrosion | no | Clean out trapped dirt, probe the lower longerons at the tailpost | PARTIAL: where to look (Cub p.24). Limits in AC parts 1-3 |
| 55-10 | Tail surfaces and brace wires | no | Level the stabilizers with the brace wires, oil the hinges, open the drain grommets | HAVE for the Cub (p.17-18, 25-27) |
| 56-10 | Windshield | `windshield` | Remove retainers, scrape sealant, fit new | PARTIAL: one-piece formed Plexiglas, cleaning and scratch care (Cub p.50). Fitting rules in AC parts 1-3, Ch 3 |
| 57-10 | Wing spars, ribs, fittings | no | Inspect through the access holes; check drag wires, hinge brackets, leading edge | PARTIAL: what to check (Cub p.13-15). Wood limits in AC parts 1-3, Ch 1 |
| 57-10 | Wing rigging | no | Set dihedral and wash-out at the lift struts | HAVE for the Cub (p.16-17) |
| 57-40 | Lift struts | no | Check for dents and rust, check jury strut bolts | HAVE for the Cub (p.15) |

## 61 Propeller

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 61-10 | Replace the propeller | `propeller` | Spinner off, cut the wire, pull the bolts, swap, torque, safety wire | 8-92, 7-43, Cub p.51-52 | Threads dry and clean. Re-check torque after the first flight, at 25 hours, then every 50. Wood shrinks in dry weather and loosens the bolts | PARTIAL: need hub bolt torque |
| 61-10 | Dress a nick in a metal blade | no | File the nick into a smooth dish, polish, check limits | 8-73, 8-74, Figs 8-24 to 8-28 | Fine file, finish with #00 sandpaper or crocus cloth, etch to check for cracks. Limit charts are images | PARTIAL: limit charts need reading off the figures |
| 61-10 | Bent blade | part of `propeller` | Reject it | 8-73 | Never straighten in the field, not even for shipping. Any sign of heating or straightening is a reject | HAVE |
| 61-10 | Wood prop inspection | no | Check for cracks, loose glue lines, charring at the hub | 8-92 | Charred wood at the flange means the bolts ran loose. Touch up worn varnish before refitting | HAVE |
| 61-10 | Oversize hub bolt holes | no | Ream for the next bolt size | 8-76, Fig 8-29 | Bolts 1/16 in larger, 0.005 in clearance at most | HAVE |
| 61-10 | Track check | no | Block at the tip, turn each blade past it | 8-108 | Each blade within 1/16 in of the other. Pull one plug per cylinder first | HAVE |
| 61-10 | Prop corrosion | no | Clean light surface corrosion | 8-93 | More than 6 sq in, or anything deeper than light surface corrosion, goes to a prop shop | HAVE |

## 71 to 80 Engine

| Code | Job | In game | What the player does | AC ref | Values | Status |
|---|---|---|---|---|---|---|
| 71-10 | Cowling | step in engine jobs | Remove and refit | Cub p.51 | Check the rubber cowl support washers; worn ones let the cowl crack | PARTIAL: need fastener type and count |
| 71-10 | Nest or debris in the cowl | `bird_nest` | Pull the nest, sweep out the straw | none | none | HAVE (no value needed) |
| 71-20 | Engine mount | no | Check tubes for cracks, bolts for snugness | Cub p.24 | Cracked mount: replace, do not repair. Bolts snug, never over-tight | HAVE for the Cub |
| 71-60 | Air filter and carb heat | no | Clean and re-oil the filter, check the heat control | Cub p.32, 36, 41 | Filter every 20 hours. Carb heat on drops about 50 rpm | HAVE for the Cub |
| 72-30 | Compression test | no | Differential tester on each cylinder | 8-14, Fig 8-1 | 80 psi in. Supply 100 to 120 psi. Orifice 0.040 in for bores under 5 in, 0.060 in for 5 in and over. Losing more than 25% (reading under 60 over 80) makes the cylinder suspect; run the engine 3 minutes and test again | HAVE |
| 72-30 | Rocker cover gasket | `oil_leak` | Cover off, scrape, new gasket, wipe down | 8-9 | Fiber lock nuts good to 250 °F | PARTIAL: need cover screw torque |
| 73-10 | Primer | no | Check the plunger seats and locks | Cub p.31 | A leaking primer makes the engine run rough | HAVE for the Cub |
| 73-10 | Carburetor | no | Clean the inlet screen, check for leaks and float level | none | none | NEED |
| 74-10 | Magneto | `magneto` | Swap the magneto, set timing | 8-19, 8-20 | Good points look frosted grey; deep pits or burns are scrap. Always turn the crank in its normal direction when timing. Re-time after any point adjustment. Never advance past the engine's spec | PARTIAL: mag drop 75 rpm at 2,100 rpm (Cub p.39). Need timing angle and point gap |
| 74-10 | Find a dead cylinder | no | Run on the bad mag, mark the stacks, see which stays cold | 8-2 | 30 seconds at 1,200 rpm, grease-pencil mark 1 in from each exhaust flange | HAVE |
| 74-20 | Spark plugs | `spark_plugs` | Pull, read, clean, gap, refit | 8-15 to 8-17, Figs 8-6 | New gasket every time. A dropped plug is scrap. Anti-seize on the threads only. It must screw in by hand to within 2 or 3 threads of the gasket. Reach: 14 mm long 1/2 in, short 3/8 in; 18 mm long 13/16 in, short 1/2 in | PARTIAL: need gap and torque |
| 74-20 | Ignition leads | no | Check for chafing, cracked insulators, loose clamps | 8-18 | Inspection only | HAVE |
| 75-00 | Cooling baffles | no | Check for cracks and missing seals | none | none | NEED |
| 76-10 | Throttle and carb heat controls | no | Check full travel, free movement, safetied ends | Cub p.9, 36, 39 | Idle 550 to 600 rpm warm. Checked every 20 hours | HAVE for the Cub |
| 77-10 | Tachometer check | no | Compare with a test tach | 8-95 | More than 2% off: replace | HAVE |
| 78-10 | Exhaust inspection | no | Look for cracks, leaks, loose baffles | 8-45 to 8-52, Cub p.36 | Never mark exhaust parts with a lead pencil (it causes cracks). Leak test at 2 psi under water. Outlet guard: 3/16 in stainless rod, U-shaped, 3 in long, reaching 2 in into the outlet | HAVE |
| 79-10 | Oil screen check | no | Pull the screen, look for metal | 8-6 | Shared with the oil change above | HAVE |
| 79-20 | Oil lines and cooler | no | Check for chafing and leaks | 8-5 | Shared tubing table | HAVE |
| 79-30 | Oil pressure and temperature gauge | no | Check it reads on start | Cub p.39 | Pressure within 30 seconds, 30 psi minimum, 220 °F maximum | HAVE for the Cub |
| 80-10 | Starter | `starter` | Disconnect the cable, unbolt, swap | none | none | NEED: mount bolt size and torque (not on a Cub) |
| 80-00 | Hand-prop start | no | Chock, prime, swing the prop | Cub p.38-39 | Steps under Cub values | HAVE for the Cub |

Chapters 49 (APU), 81 to 84 (turbine systems) and everything for pressurized or jet aircraft do not apply to any plane in the game.

## Values still needed

Grouped by the document that has them.

**Still open on the Cub airframe (type certificate data sheet A-691 and the Piper parts catalog have these):**
- Control surface travel in degrees. Rudder and aileron cable sizes.
- Weight and balance: datum, CG range, empty weight, gross weight.
- Brake lining wear limit.
- Required placards.
- Door hinge pin size. Cowling fasteners. Landing gear attach bolt sizes.

**The other four plane types** (high-wing trainer, bush plane, vintage tourer, utility hauler) have no manual yet. Each needs what the Cub manual gave: tire pressure, fluids, oil and fuel, engine limits, rigging, jack points, inspection list, plus battery and electrical details.

**Engine overhaul manual:**
- Spark plug gap and torque.
- Magneto timing angle and point gap.
- Oil change interval.
- Rocker cover screw torque. Starter mount torque.
- Crankshaft runout limit after a prop strike.
- Pre-oil and return-from-storage procedure.
- Carburetor checks.

**Propeller manufacturer:**
- Hub bolt torque, wood and metal.
- Blade repair limits as numbers (the AC only has them as charts in Figures 8-27 and 8-28).
- Static rpm range.

**AC 43.13-1B parts 1 to 3 (upload them and I can fill these in):**
- Fabric repair and testing. Wood repair. Steel tube welding. Sheet-metal riveting.
- Windshield and plastics.
- Corrosion limits and aluminum treatment.

**Other sources:**
- Safety wire twists per inch.
- ELT battery replacement rule (14 CFR 91.207).
- Hand fire extinguisher inspection.
- Seat belt condemnation criteria.
- Stale fuel: how to judge it and how much to sump.
- Fuel tank leak-test pressure.

**Still to type up from the PDFs already in the repo:** breaker and fuse rating tables, wire current capacity (Tables 11-9 to 11-12), switch derating (Table 11-4), the full hardware part-number tables (Tables 7-10 to 7-15), and the weight-and-balance worked examples.

Nothing in this file is maintenance guidance for a real aircraft.

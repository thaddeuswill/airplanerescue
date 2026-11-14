# Playtest notes, v0.9.3-work (2026-11-07)

**How this was played:** one scripted job, run headless (Minneapolis, seed 7: oil leak, dead battery, stale fuel, dry engine, rusted door pin), plus a read of every step a player goes through, plus a money simulation of 20,000 jobs using the game's own formulas. No one looked at the screen, so these notes say nothing about how the game looks or feels in the hand.

The lens is the five things that make play fun: **absorption** (the challenge matches your skill), **autonomy** (your choices steer things), **surprise**, **low stakes** (failing is cheap and interesting) and **shared play** (someone reacts to you).

## The loop, step by step

| Step | Fun | Teaching | Notes |
|---|---|---|---|
| Pick a call on the chart | Weak | OK | All three calls make good money, so the only real question is "how far". |
| Wash a neglected plane | OK | Good | Grime hiding damage is true to life. |
| Walk-around, 8 spots | Weak | Weak | Clicking a spot shows the fault in words. You never have to *look*. |
| Run-up | Weak | Weak | One button, then a line of text that names the fault. |
| Repair scene | Good at first | Good | Real order of work: negative cable first, cotter pins, safety wire, torque. It gets repetitive after a few jobs. |
| Buy parts and tools | OK | OK | Shelf or mail order is a fair small choice. |
| Sign the logbook | Weak | Weak | One click on a fixed text. |
| Start and fly out | **Best part** | **Best part** | Real checklist, flooded and hung starts, a hidden fault striking in the climb. |
| Crash or forced landing | Good | **Very good** | "What you missed" is the best teaching moment in the game. |

## What's lacking, most important first

1. **Money stops mattering after the first job.** A job pays $6,400 on average and costs about $1,100 to fly to plus the part. In 20,000 simulated jobs, 1 in 200 lost money. You start with $3,000, so game over is almost impossible after one rescue. Without some pressure, choices don't count.
   *Fix:* pay closer to the real cost (for example the plane's base value plus parts at 1.2 times, not 2 times), and add one running cost such as hangar rent or insurance per day.

2. **The game diagnoses for you.** The owner's complaint plus the clue text name the fault ("Battery's dead"). For a mechanic, the real skill and the real fun is working out *what* is wrong from what you see and hear. Right now the player is never asked to decide anything technical.
   *Fix:* let the clue show evidence, not the answer. "Runs rough, 250 rpm drop on the left mag" could be plugs or a magneto. The player picks the job. A wrong pick costs a part and a day, and the next run-up shows it didn't help. This one change adds challenge, choice and real teaching at once.

3. **Skipping spots is a choice that costs nothing.** Checking a spot takes about an hour of game time, and deadlines are 7 to 15 days, so there is no reason to skip anything. The "sign anyway" risk never comes up.
   *Fix:* tighten deadlines or give each spot real time, so that skipping is a real gamble. Or drop the option.

4. **Nothing surprises you mid-job.** What the owner says is everything that's wrong. Rebuild Rescue episodes live on "we pulled the cowling and found…".
   *Fix:* sometimes an extra fault shows up only once a cover is off: a cracked exhaust stack behind the cowling, corrosion under the battery tray. You find it in the work scene, not on the walk-around.

5. **The run-up is a button.** The start-up in the cockpit is great hands-on play; the run-up that finds engine faults is not.
   *Fix:* reuse the cockpit for the run-up: 1,700 rpm, mag check with real numbers (drop limit and the difference between mags), oil pressure and temperature in the green, carb heat drop. The player reads the gauges and decides.

6. **Repair scenes say "to spec" but never give the spec.** Torque has no number, spark plugs aren't torqued or gapped, the fuel line gets no leak check after the fuel goes back on.
   *Fix:* show the number and where it comes from ("prop bolts: torque to the value in the prop manufacturer's manual"; "spark plugs: about 300 to 360 in-lb, new copper gasket"). Add a leak check step to the fuel line job. You know which of these numbers are safe to show.

7. **No "why" after a job.** The steps are taught by being blocked ("Take off the hubcap first"), which is fine, but the reason is never said. Why the negative comes off first, why safety wire, why pre-oil.
   *Fix:* one line on the FIXED banner or in the logbook entry: "Negative off first: a wrench touching the airframe can't short the battery."

8. **The logbook entry is not a real one.** A real entry has the work described, the approved data it was done to (AC 43.13-1B or the manual), the date, a signature and the certificate type and number. The game's text mixes inspection wording into a repair entry.
   *Fix:* let the player build the entry from parts (work done, reference, signature) and have it checked. It teaches 14 CFR 43.9, and you'd catch any mistakes in it at a glance.

9. **Repair scenes repeat.** There are 13 scenes and each is always laid the same way, so by job 6 you're clicking from memory.
   *Fix:* the surprises in item 4, plus some variety: a seized bolt that needs penetrant (it's already sold in the catalog), a stripped screw, a different plane type with a different panel layout.

10. **Nobody reacts to you.** Owners are a line of quoted text. There is no one to share the moment with when a plane flies out.
    *Fix:* a short note or radio call from the owner on hand-off, one line with a name and a personality, and a callback later ("The Cub you saved in Fargo flew 40 hours this summer").

11. **The choice between calls is shallow.** You see pay, distance and symptoms. Since money is loose (item 1), you take the nearest one.
    *Fix:* once item 1 is done, this becomes a real choice by itself. The symptoms could also hint at hard work (prop, magneto) versus easy work.

## Status (same day)

All 11 worked on. Not done: plane types with different panel layouts and stripped screws (item 9), a separate carb heat check in the run-up (item 5). Torque values from the A&P: prop bolts 175-225 in-lb (AN6, wood prop), plugs 300-360 in-lb (Continental); mag limit 175 drop, 50 apart. Pay is now the plane's base value plus parts at cost, and the money simulation puts the average profit at about $1,950 a job, with about 4% of jobs losing money before wrong guesses and crashes.

## What already works, keep it

- The start-up checklist with flooded and hung starts.
- A hidden fault striking in the climb, and the "What you missed" card afterwards.
- Neglect jobs: wash first, stale fuel, a dry engine that needs pre-oiling, a door pin rusted solid.
- Real order of work in the repair scenes, with the tool in your hand as the cursor.
- A failure costs something but never ends the game outright.

## Not checked

- Anything visual or by feel: camera, controls, sound mix, how long a scene takes by hand.
- The later game (jobs 5 to 10) beyond reading the code.
- Whether the numbers in items 5 and 6 match the Cub's real manuals: that's your call.

## Round 2 (2026-11-08)

- Playtest log: a hand-played session writes each step's real time to `%APPDATA%\Godot\app_userdata\Airplane Rescue\playtest_log.txt`. F8 marks a note there.
- First two jobs: no look-alike faults, nothing hidden behind the cowl.
- New run-up faults: a broken P-lead (one mag shows no drop at all) and a broken carb heat cable (no drop with carb heat pulled, H in the cockpit). The owner of a carb heat job just says "runs rough", like plugs and magneto.
- Money: a career simulation (start $3,000 to 10 rescues, nearest call each time) never went broke from wrong guesses alone, even at 30% wrong. Crashes are what break a career: at a 10% crash rate, 11% of careers ran dry before job 3. So broke now offers three days of odd jobs at the field for $900 instead of ending the game.

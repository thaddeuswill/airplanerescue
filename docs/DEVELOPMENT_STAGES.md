# Development Stage Allocation & Programmer Roadmap

The table below outlines target engineering and production focus across each phase so effort stays aligned with proving core wrenching and troubleshooting fun before scaling content:

| Development Stage | Core Mechanics & Wrenching | Flight, World & Rescue Loop | Art, Atmosphere & Diegetic UI | Audio, Foley & Polish | Testing, Balancing & Optimization |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Prototype (Greybox)** | **65%** | **20%** | **5%** | **5%** | **5%** |
| **2. Vertical Slice** | **35%** | **25%** | **25%** | **10%** | **5%** |
| **3. Alpha (Content & Loop)** | **20%** | **30%** | **25%** | **10%** | **15%** |
| **4. Beta (Polish & Feel)** | **10%** | **10%** | **25%** | **25%** | **30%** |
| **5. Release / Launch** | **5%** | **5%** | **15%** | **20%** | **55%** |

---

## 50 Engineering & Implementation Tips by Stage

### Stage 1: Prototype (Greybox) — Focus: Core Mechanics & Wrenching (65%)
1. **Build a data-driven dependency graph early:** Define aircraft assemblies as parent-child node trees (e.g., Cowling $\rightarrow$ Spark Plug Lead $\rightarrow$ Spark Plug) so parts cannot be pulled until blocking fasteners and covers are removed.
2. **Keep geometry strictly primitive:** Use color-coded cubes and cylinders for engine blocks, magnetos, and bolts—never block engineering progress waiting on 3D art assets.
3. **Nailed fastener state machines:** Implement clean states for every bolt and screw (`Torqued`, `Loose`, `Unthreaded`, `Detached`) with smooth interpolated rotation and axial backing-out.
4. **Prototype diagnostic tools as real state readers:** Have the multimeter, compression tester, and fuel pressure gauge query actual live variables on the aircraft components rather than hardcoded UI triggers.
5. **Create one complete "end-to-end" fault tree:** Build a single realistic troubleshooting chain (e.g., *Engine won't start $\rightarrow$ Check spark $\rightarrow$ Test magneto output $\rightarrow$ Replace fouled plug & re-torque*) to prove the detective loop is fun.
6. **Prevent physics tunneling on dropped parts:** Give detached bolts and small tools continuous collision detection (CCD) or snap-to-tray behavior so they don't fall through the ground collider.
7. **Implement a basic container/slot inventory:** Build the underlying grid or weight-based cargo system for the player's toolbox and rescue plane baggage compartment now.
8. **Stub out flight physics simply:** Use a lightweight, forgiving bush-plane flight controller with basic takeoff, cruise, and grass-landing states—refine aerodynamics later.
9. **Separate simulation state from visuals:** Store aircraft health, wear values, torque specs, and fluid levels in pure C#/C++ data structs so saving/loading and headless testing are trivial.
10. **Add a debug inspector overlay:** Build an in-game developer hotkey that displays live component health, torque values, and fault flags on hover to speed up debugging.

---

### Stage 2: Vertical Slice — Focus: Atmosphere & One Full Rescue (35% Mech / 25% Loop / 25% Art & UI)
11. **Wire the entire loop from menu to payout:** Connect the diegetic main menu $\rightarrow$ mission selection $\rightarrow$ tool packing $\rightarrow$ flight $\rightarrow$ field repair $\rightarrow$ logbook sign-off $\rightarrow$ return flight.
12. **Build the diegetic main menu interaction framework:** Set up camera spline transitions and world-space raycast hover highlights for the radio (Settings), clipboard (Dispatch), and toolbox (Loadout).
13. **Implement radio mission generation (single handcrafted case):** Create the audio/subtitle dispatch system that gives the player symptom clues (*"rough idle, black smoke on mag check"*) without explicitly naming the broken part.
14. **Lock in the cargo weight & space trade-off:** Enforce weight/volume limits when loading the player's plane so packing the right spare parts matters before takeoff.
15. **Add the post-repair run-up check:** Require the player to climb into the stranded plane's cockpit, prime, crank the starter, and verify RPM/oil pressure gauges before signing off the job.
16. **Implement the A&P Logbook sign-off UI:** Create a tactile clipboard sign-off screen that validates whether all required squawks were fixed and calculates the invoice payout.
17. **Establish the golden-hour lighting & shader pipeline:** Lock in directional sun angles, warm rim lighting, wind-swaying grass shaders, and dust-mote particle systems to validate target frame rates.
18. **Integrate placeholder foley hooks everywhere:** Trigger distinct audio events on every wrench click, bolt thread, cowling unlatch, and radio knob turn so the timing of sound-to-action feels tight.
19. **Build a reliable save/load serializer:** Serialize the player's profile, A&P certificate data, plane inventory, and world state cleanly at the end of every rescue.
20. **Test cold-start onboarding:** Have someone unfamiliar with the game play the Vertical Slice from `New Game` registration to their first repair without verbal guidance.

---

### Stage 3: Alpha — Focus: Scaling Squawks, Locations & Progression (30% Loop / 25% Art / 20% Mech)
21. **Expand fault modules across all major aircraft systems:** Build modular fault generators for Ignition (magnetos, harnesses, plugs), Fuel (clogged strainers, stuck floats, air locks), Electrical (dead batteries, bad relays), and Airframe/Gear (flat oleo struts, frayed control cables).
22. **Introduce procedural squawk combinations:** Allow stranded planes to spawn with 1–3 layered issues (e.g., a dead battery hiding a clogged fuel screen) for higher-paying contracts.
23. **Build multi-location world streaming or scene loading:** Support 5+ distinct rural grass strips, farm pastures, and dirt roads with varying runway lengths, wind conditions, and obstacles.
24. **Add dynamic weather and time-of-day variations:** Implement overcast, breezy, and dusk conditions that affect both bush-flying visibility and diagnostic clues (e.g., carb ice risk).
25. **Implement the parts catalog and economy loop:** Let players order replacement parts via radio/catalog, manage cash flow, and buy upgraded tools (faster ratchets, digital multimeters, portable compressors).
26. **Add safety-wire and consumable mechanics:** Implement consumables like safety wire, shop rags, aviation oil, and gasket sealant that deplete and must be restocked.
27. **Create dynamic menu souvenirs:** Automatically spawn physical mementos on the main menu table/cockpit (thank-you postcards, bent pushrods, tail-number tags) tied to completed save milestones.
28. **Support multiple stranded aircraft archetypes:** Abstract the aircraft controller so new airframes (high-wing taildragger, low-wing trainer, radial biplane) plug into the same tool and diagnostic systems.
29. **Add owner NPC voice/text flavor:** Give stranded owners distinct personalities and inaccurate initial guesses (*"I think it's the alternator"* when it's actually a sheared mag drive) to reward real diagnostics.
30. **Implement emergency field-expedient fixes:** Allow temporary "ferry permit" patches (e.g., cleaning a fouled plug instead of replacing it) for lower pay when the player forgot a spare part.

---

### Stage 4: Beta — Focus: Tactile "Juice", Foley & UX Clarity (30% Testing / 25% Art / 25% Audio)
31. **Add subtle highlights for tiny fasteners:** Implement a clean outline or glint shader when hovering near small bolts, cotter pins, and safety-wire holes so players never pixel-hunt.
32. **Layer dynamic foley audio:** Randomize pitch and volume across multiple recorded samples for ratchet clicks, wrench clinks, sheet-metal flex, and radio static crackles.
33. **Polish engine cranking and failure acoustics:** Tie engine start attempts directly to fault states—weak battery slows starter crank RPM, dead mag causes sputtering misfires, good fix roars smoothly to life.
34. **Refine camera ergonomics during close-up wrenching:** Add smooth focus zoom, subtle head-bob damping, and automatic flashlight/work-lamp angling when leaning into dark engine bays.
35. **Clarify torque and tightness feedback:** Provide unmistakable visual, audio, and subtle controller/camera-shake cues when a fastener hits proper torque vs. over-torqued.
36. **Polish the diegetic radio tuning experience:** Make tuning the army radio dial smoothly crossfade static, ambient 1950s broadcasts, and incoming rescue beacons.
37. **Improve bush-plane ground handling and braking:** Tune tailwheel steering, suspension bounce on rough grass, and brake feel so landing in tight pastures feels rewarding rather than frustrating.
38. **Add clear visual wear states on parts:** Ensure worn, cracked, oil-fouled, or corroded parts are visually readable through texture swaps or decals before the player even pulls out a meter.
39. **Streamline tool-switching ergonomics:** Support both diegetic grabbing from the open toolbox and quick-select hotkeys/radial wheels so repetitive tasks stay snappy.
40. **Conduct full UI/UX accessibility pass:** Add scalable subtitle text for radio dispatches, colorblind-friendly wire/gauge indicators, and remappable controls.

---

### Stage 5: Release / Launch — Focus: Soft-Lock Prevention, Balancing & Optimization (55% Testing & Balancing)
41. **Build a "Lost & Found" bolt recovery safeguard:** Automatically return any dropped fastener or critical tool to the player's red toolbox tray after 5 seconds on the grass so players can never soft-lock a repair.
42. **Audit every mission for unwinnable states:** Verify that if a player arrives at a remote strip without a required spare part, they can either fly back to base to fetch it or perform a field repair—never trapping the save file.
43. **Prevent player aircraft stranding:** Ensure the player's own rescue plane cannot run out of fuel or break down in a way that leaves them permanently stuck away from home base.
44. **Stress-test save file backward compatibility:** Validate that player saves survive mid-mission quits, alt-tabs, and version patches without corrupting aircraft component states.
45. **Balance contract payouts vs. part costs:** Run economy simulations across 20+ consecutive jobs to ensure steady progression without tedious grinding or trivializing money too early.
46. **Optimize draw calls and physics colliders on aircraft:** Merge static airframe meshes and disable rigidbody physics on installed bolts until the player actively interacts with them.
47. **Profile grass, shadow, and particle budgets:** Ensure dense grass strips and golden-hour volumetric/rim lighting maintain locked 60+ FPS on mid-range target hardware.
48. **Verify clean state resets on scene transitions:** Confirm zero memory leaks, lingering audio loops, or duplicate UI listeners when cycling between the main menu and rescue strips repeatedly.
49. **Polish first-launch settings detection:** Auto-detect native resolution, sensible graphics presets, and audio device routing on first boot before the diegetic menu loads.
50. **Execute a zero-patch "golden master" playthrough:** Complete a fresh full-career test build from registration clipboard to final unlockable aircraft with zero debug tools enabled.
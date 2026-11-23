extends Node3D
## Airplane Rescue: walk up to stranded planes, inspect them in a 2D panel,
## fix each fault (the 3D model updates), then sign off and fly to the next call.
## The plane and repair parts are .glb models from models/ (made by tools/optimize_models.py);
## buildings and nature are still primitives built in code. Art direction: ART_DIRECTION.md.

const Player := preload("res://scripts/player.gd")
const Ferry := preload("res://scripts/ferry.gd")
const Sound := preload("res://scripts/sound.gd")
const Terrain := preload("res://scripts/terrain.gd")
const Work := preload("res://scripts/work.gd")
const CatalogUI := preload("res://scripts/catalog.gd")
const RadioUI := preload("res://scripts/radio.gd")
const Gauge := preload("res://scripts/gauge.gd")
const Updater := preload("res://scripts/updater.gd")
const Chart := preload("res://scripts/chart.gd")
var chart := Chart.new(self)
const GOAL := 10
const MAX_JOBS := 3
const START_CITY := "Wichita"
const FUEL_PER_MILE := 0.9
const NEAR_MILES := 650.0  # one radio call is always this close (under $600 to fly; Miami-Atlanta is 601 mi)

# city: [lon, lat, region, map_x, map_y] â€” map_x/y are pixels on textures/us_map.png (2048x1280),
# fitted from landmarks and checked by plotting.
const CITIES := {
	"Wichita": [-97.3, 37.7, "plains", 998, 672], "Omaha": [-96.0, 41.3, "plains", 1036, 533],
	"Dallas": [-96.8, 32.8, "plains", 1013, 867], "Chicago": [-87.6, 41.9, "plains", 1276, 498],
	"Billings": [-108.5, 45.8, "plains", 703, 342], "Miami": [-80.2, 25.8, "plains", 1554, 1112],
	"New York": [-74.0, 40.7, "plains", 1681, 481], "Seattle": [-122.3, 47.6, "forest", 358, 200],
	"Portland": [-122.7, 45.5, "forest", 334, 276], "Atlanta": [-84.4, 33.7, "forest", 1390, 808],
	"Nashville": [-86.8, 36.2, "forest", 1310, 716], "Bangor": [-68.8, 44.8, "forest", 1817, 289],
	"Los Angeles": [-118.2, 34.1, "desert", 392, 751], "Phoenix": [-112.1, 33.4, "desert", 563, 811],
	"Las Vegas": [-115.1, 36.2, "desert", 488, 684], "Albuquerque": [-106.6, 35.1, "desert", 726, 762],
	"Denver": [-105.0, 39.7, "snow", 781, 585], "Salt Lake City": [-111.9, 40.8, "snow", 593, 519],
	"Fargo": [-96.8, 46.9, "snow", 1018, 321], "Minneapolis": [-93.3, 45.0, "snow", 1113, 391],
}
# grass/wheat: how many grass cards to scatter
const REGIONS := {
	"plains": {"tex": "ground_grass", "ground": Color(0.45, 0.62, 0.3), "prop": "tree", "count": 800, "grass": 14000, "wheat": 4000},
	"forest": {"tex": "ground_forest", "ground": Color(0.28, 0.45, 0.22), "prop": "pine", "count": 2000, "grass": 9000, "wheat": 0},
	"desert": {"tex": "dirt_red", "ground": Color(0.82, 0.68, 0.45), "prop": "cactus", "count": 400, "grass": 1500, "wheat": 0},
	"snow": {"tex": "ground_snow", "ground": Color(0.92, 0.94, 0.97), "prop": "snowpine", "count": 1000, "grass": 0, "wheat": 0},
}
# symptom: what the owner reports on the radio. zone: where on the plane you find it.
# A new fault (say, out of the Cub manual) is playable from two lines: a row here, added at the
# end, and its CLUES line. It then turns up on jobs, hides at its zone on the walk-around, sells
# its part in the catalog, and is repaired behind a plain access panel until it gets a scene of
# its own in work.gd. Optional in the row: "ref" (the manual section, shown in the repair),
# "torque" (Vector2i in-lb: its bolts get the torque wrench), "diagram" (textures/diagrams/<name>.png,
# default the fault's id: D shows it in the repair). Optional elsewhere: TROUBLE (what it does in
# flight if missed), WHY, CATALOG_BLURB, textures/icon_<id>.png. The self-test checks the rows.
# Faults are found one of three ways: seen on the walk-around (CLUES), heard on the run-up
# (RUNUP_FAULTS), or tracked down with troubleshooting tests ("diags": possible chains of
# TESTS; one is picked per job). "ground": no field fix, the engine has to come out.
# Values and procedures: JOBS_ATA.md (AC 43.13-1B, the J3C-65 manual, Continental M-0).
const FAULTS := {
	"tire": {"name": "Flat main tire", "part": "Tire & tube", "cost": 180, "zone": "gear_l", "symptom": "sits low on the left side"},
	"brakes": {"name": "Worn brake shoes", "part": "Brake shoe set", "cost": 260, "zone": "gear_r", "symptom": "grinds when it taxis"},
	"battery": {"name": "Weak battery", "part": "Battery", "cost": 350, "zone": "battery", "symptom": "won't crank, the starter just clicks"},
	"spark_plugs": {"name": "Worn-out spark plugs", "part": "Spark plug set", "cost": 220, "zone": "engine", "symptom": "runs rough, puffs black smoke",
		"diags": [["spark_test"], ["reading_plugs"]]},
	"oil_leak": {"name": "Oil leak", "part": "Gasket kit", "cost": 150, "zone": "engine", "symptom": "oil spots under the nose"},
	"bird_nest": {"name": "Bird nest on the cowling", "part": "", "cost": 0, "zone": "engine", "symptom": "birds flying out of the cowling"},
	"fuel_line": {"name": "Leaking fuel line", "part": "Fuel line kit", "cost": 300, "zone": "engine", "symptom": "smells of avgas around the firewall"},
	"windshield": {"name": "Cracked windshield", "part": "Windshield", "cost": 900, "zone": "cabin", "symptom": "got caught in a hailstorm"},
	"starter": {"name": "Seized starter", "part": "Starter motor", "cost": 1100, "zone": "engine", "symptom": "won't crank, the starter just clicks"},
	"control_cables": {"name": "Jammed rudder cables", "part": "Control cable set", "cost": 650, "zone": "tail", "symptom": "rudder pedals are stiff"},
	"magneto": {"name": "Bad magneto", "part": "Magneto", "cost": 1400, "zone": "engine", "symptom": "dies on the mag check", "diags": [["spark_test"]]},
	"avionics": {"name": "Broken radio antenna", "part": "Antenna & radio", "cost": 1800, "zone": "cabin", "symptom": "radio's dead, can't raise anyone"},
	"propeller": {"name": "Cracked propeller", "part": "Propeller", "cost": 2600, "zone": "prop", "symptom": "found a crack in the prop at preflight"},
	# Neglect jobs: only planes that sat for years get these (see _spawn_job).
	"stale_fuel": {"name": "Stale fuel in the tank", "part": "Fresh avgas", "cost": 90, "zone": "cabin", "symptom": "hasn't had fresh gas in years"},
	"pre_oil": {"name": "Dry engine: pre-oil before start", "part": "", "cost": 0, "zone": "engine", "symptom": "hasn't been started in years"},
	"door_pin": {"name": "Door pin rusted solid", "part": "Door pin & cotter", "cost": 120, "zone": "cabin", "symptom": "can't even get the door open"},
	# Found only on the run-up's gauges (kept last so the catalog's part numbers don't shift).
	"carb_heat": {"name": "Carb heat cable broken", "part": "Carb heat cable", "cost": 140, "zone": "engine", "symptom": "runs rough"},
	"tmp_strut": {"name": "Cracked lift strut fork", "part": "Strut fork", "cost": 200, "zone": "wing_l", "symptom": "wing creaks", "torque": Vector2i(50, 70), "ref": "J-3 Service Manual, sec. 4-12", "diagram": "tmp"},
	"storage": {"name": "Engine pickled for storage", "part": "", "cost": 0, "zone": "engine", "symptom": "the engine was put up properly for storage"},
	"oil_change": {"name": "Oil long overdue", "part": "", "cost": 0, "zone": "engine", "symptom": "nobody remembers the last oil change"},
	"bungee": {"name": "Tired shock cords", "part": "Bungee cords", "cost": 90, "zone": "gear_l", "symptom": "sags on its gear and bangs on landing"},
	"tie_down": {"name": "Rotten tie-downs", "part": "", "cost": 0, "zone": "tail", "symptom": "it's been rocking at its tie-downs all season"},
	# Tracked down with troubleshooting tests.
	"ign_lead": {"name": "Chafed ignition lead", "part": "Ignition lead", "cost": 85, "zone": "engine", "symptom": "drops a lot of rpm on one mag", "diags": [["spark_test"]]},
	"primer_leak": {"name": "Leaking primer", "part": "Primer seal kit", "cost": 45, "zone": "cabin", "symptom": "runs rich and sooty", "diags": [["reading_plugs"]]},
	"stuck_valve": {"name": "Sticking valve", "part": "Rocker cover gasket", "cost": 25, "zone": "engine", "symptom": "shakes at every rpm",
		"diags": [["cold_cylinder", "compression"]]},
	"worn_rings": {"name": "Worn rings, low cylinder", "part": "Cylinder assembly", "cost": 1600, "zone": "engine", "symptom": "shakes and burns oil",
		"diags": [["cold_cylinder", "compression"], ["reading_plugs", "compression"]]},
	"relief_valve": {"name": "Sticking oil relief valve", "part": "", "cost": 0, "zone": "engine", "symptom": "oil pressure sags", "diags": [["oil_screen"]]},
	"cam_wear": {"name": "Steel in the oil: cam or lifters", "part": "", "cost": 0, "zone": "engine", "symptom": "oil pressure sags", "diags": [["oil_screen"]], "ground": true},
	"piston_scuff": {"name": "Aluminum in the oil: a piston", "part": "", "cost": 0, "zone": "engine", "symptom": "oil pressure sags", "diags": [["oil_screen"]], "ground": true},
	"bronze_bushing": {"name": "Bronze in the oil: pin bushings", "part": "", "cost": 0, "zone": "engine", "symptom": "oil pressure sags", "diags": [["oil_screen"]], "ground": true},
	# Heard on the run-up.
	"hot_mag": {"name": "Hot magneto (broken P-lead)", "part": "P-lead", "cost": 30, "zone": "engine", "symptom": "no drop at all on the mag check"},
	"mag_timing": {"name": "Magneto timing drifted", "part": "", "cost": 0, "zone": "engine", "symptom": "sluggish and runs hot"},
	"brake_bleed": {"name": "Air in the brake line", "part": "", "cost": 0, "zone": "gear_r", "symptom": "the right brake pedal goes soft"},
	"wire_chafe": {"name": "Chafed wire behind the panel", "part": "Wire & splices", "cost": 15, "zone": "cabin", "symptom": "the radio cuts out over bumps"},
	# Seen on the walk-around.
	"exhaust_check": {"name": "Cracked muffler", "part": "Muffler", "cost": 380, "zone": "engine", "symptom": "the cabin smells of exhaust and the owner gets headaches"},
	"air_filter": {"name": "Clogged air filter", "part": "Air filter & flapper", "cost": 45, "zone": "engine", "symptom": "down on power, slow to climb"},
	"baffles": {"name": "Packed fins, loose baffle seal", "part": "Baffle seal strip", "cost": 25, "zone": "engine", "symptom": "oil temperature climbs past 220"},
	"fuel_vent": {"name": "Plugged fuel tank vent", "part": "", "cost": 0, "zone": "engine", "symptom": "starts, runs a minute, then quits"},
	"water_fuel": {"name": "Water in the fuel", "part": "", "cost": 0, "zone": "engine", "symptom": "coughs and quits once it's warm"},
	"fuel_strainer": {"name": "Clogged fuel strainer", "part": "", "cost": 0, "zone": "engine", "symptom": "loses power at full throttle"},
	"aileron_rigging": {"name": "Ailerons out of rig", "part": "Aileron cable", "cost": 110, "zone": "wing_l", "symptom": "flies with the left wing low"},
	"wing_rig": {"name": "Wings out of rig", "part": "Strut forks", "cost": 60, "zone": "wing_l", "symptom": "won't fly straight hands-off"},
	"elevator_cable": {"name": "Frayed elevator cable", "part": "Elevator cable", "cost": 120, "zone": "tail", "symptom": "the stick feels notchy fore and aft"},
	"trim_cable": {"name": "Slipping trim cable", "part": "", "cost": 0, "zone": "tail", "symptom": "the trim crank spins and nothing happens"},
	"brace_wires": {"name": "Kinked tail brace wire", "part": "Brace wire set", "cost": 120, "zone": "tail", "symptom": "the tail shakes in gusts"},
	"tailwheel": {"name": "Sloppy tailwheel", "part": "Tailwheel springs", "cost": 35, "zone": "tail", "symptom": "the tailwheel shimmies and won't steer"},
	"prop_dress": {"name": "Stone nick in the prop", "part": "", "cost": 0, "zone": "prop", "symptom": "picked up a stone on the gravel strip"},
	"prop_track": {"name": "Prop out of track", "part": "", "cost": 0, "zone": "prop", "symptom": "shakes the whole panel at cruise"},
	"compass": {"name": "Compass way off", "part": "", "cost": 0, "zone": "cabin", "symptom": "the compass is twenty degrees out"},
	"pitot_static": {"name": "Leaking static line", "part": "Static hose", "cost": 15, "zone": "cabin", "symptom": "the airspeed and altimeter wander"},
	"weight_balance": {"name": "Weight and balance out of date", "part": "", "cost": 0, "zone": "cabin", "symptom": "new tires and seat cushions, and paperwork from 1946", "quiz": true},
	"jet_fuel": {"name": "Run on jet fuel", "part": "", "cost": 0, "zone": "engine", "symptom": "the line boy fueled it with Jet-A and they ran it", "ground": true},
	"prop_strike": {"name": "Prop strike", "part": "", "cost": 0, "zone": "prop", "symptom": "nosed over in soft mud; the prop hit and the engine stopped dead", "ground": true},
	# Round 3.
	"fabric_test": {"name": "Fabric due a punch test", "part": "", "cost": 0, "zone": "wing_l", "symptom": "the wing fabric looks chalky and tired"},
	"brake_master": {"name": "Leaking brake master cylinder", "part": "Master cylinder", "cost": 95, "zone": "cabin", "symptom": "the left brake pedal sinks and there's red fluid on the floor"},
	"instrument_swap": {"name": "Dead tachometer", "part": "Tachometer", "cost": 160, "zone": "cabin", "symptom": "the tach needle never leaves zero"},
	"prop_bolts": {"name": "Loose prop bolts", "part": "", "cost": 0, "zone": "prop", "symptom": "a clunk at the nose when it idles"},
	# Only ever added: a punch test that fails, or a socket you closed the cowl on.
	"fabric_rot": {"name": "Fabric failed the punch test", "part": "", "cost": 0, "zone": "wing_l", "symptom": "", "ground": true,
		"ground_why": "The fabric's rotten: the airplane has to be recovered. That's a shop job, not a field one."},
	"fod": {"name": "Socket loose under the cowl", "part": "", "cost": 0, "zone": "engine", "symptom": ""},
}
const NEGLECT_FAULTS := ["stale_fuel", "pre_oil", "door_pin", "storage", "oil_change", "bungee", "tie_down"]
const GROUND_FAULTS := ["jet_fuel", "prop_strike"]  # the oil-screen ones come up through diagnosis
# What an unfound fault does on the ferry flight. roll: bites on the runway, not in the climb.
# Faults found on the run-up are absent: the run-up is required, so they can't be missed.
const TROUBLE := {
	"tire": {"roll": true, "text": "The left tire lets go and the plane swings hard for the grass!"},
	"brakes": {"roll": true, "text": "The right brake drags, then grabs. It won't hold a straight line!"},
	"oil_leak": {"roll": false, "text": "Oil streaks up the windshield and the pressure needle drops to nothing!"},
	"bird_nest": {"roll": false, "text": "Smoke pours out of the cowling. Something up there is on fire!"},
	"fuel_line": {"roll": false, "text": "A sharp smell of avgas, and the engine starves and coughs!"},
	"stale_fuel": {"roll": false, "text": "Years-old gas reaches the carburetor. The engine sputters and quits!"},
	"windshield": {"roll": false, "text": "The windshield bursts in. You chop the power and can't see ahead!"},
	"control_cables": {"roll": false, "text": "The rudder jams solid. You pull the power and head for the nearest field!"},
	"propeller": {"roll": false, "text": "A violent shake through the whole airframe. You pull the power before the bent prop tears the engine off!"},
}
const CRASH_BILL := 1500  # your insurance excess
const DAILY_COST := 40  # hangar rent back home and insurance, every day you're in business
const OWNERS := ["Earl", "Dale", "Marge", "Rosa", "Hank", "June", "Walt", "Bev", "Gus", "Lorraine",
	"Vern", "Dot", "Cal", "Inez", "Roy", "Pearl", "Abe", "Nell", "Otis", "Fern"]
const THANKS := ["She hasn't sounded that good since my dad flew her.", "I'd about given up on her. Thank you.",
	"First time she's left the ground in years. I may have cried a little.", "You saved me a long, sad trip to the scrap yard.",
	"I'll take her up first thing tomorrow.", "My grandkids are going to learn to fly in her."]
## Faults that look alike from the cockpit: the evidence fits both, and you pick which to fix.
const SUSPECTS := {"battery": "starter", "starter": "battery"}  # plugs vs magneto: the spark test tells them apart
## Behind the cowling: found only once the cowl comes off for another engine job.
const HIDDEN_CLUES := {"oil_leak": "Behind the cowling: the rocker cover gasket is weeping oil, out of sight from outside",
	"bird_nest": "Behind the cowling: a nest packed against the cylinder baffles, out of sight from the inlets"}
## One line on why the job is done the way it is, shown when it's finished.
const WHY := {
	"tire": "New cotter pin every time: a used one is work-hardened and can snap.",
	"brakes": "Rust pits a disc until the brake grabs instead of squeezing, and that's what drags the plane sideways.",
	"battery": "Negative off first and on last: then a wrench touching the airframe can't short the battery.",
	"spark_plugs": "New gaskets every time: a crushed old one won't seal, and the plug can work loose.",
	"oil_leak": "Every scrap of old gasket comes off, or the new one sits on a ridge and leaks again.",
	"bird_nest": "A nest against a hot cylinder is a fire. Always look inside the cowl on a plane that's been sitting.",
	"fuel_line": "Fuel off before you crack a line, and check it for leaks with the fuel back on before you close it up.",
	"windshield": "The old sealant comes off completely, or the new windshield is stressed at the high spots and cracks.",
	"starter": "The starter cable comes straight off the battery: master off before you put a wrench near it.",
	"control_cables": "Turnbuckles get safety wire so vibration can't unwind them and let the cable go slack.",
	"magneto": "A new magneto has to be timed to the engine, or it fires at the wrong moment and runs rough or not at all.",
	"avionics": "A loose or dirty coax connector makes a radio that works on the ground and quits in the air.",
	"propeller": "Prop bolts are torqued and safety-wired. A wood prop shrinks and swells, so check the torque again after the first few hours.",
	"stale_fuel": "Old gas turns to varnish that clogs the carburetor: drain all of it, don't just top it up.",
	"pre_oil": "After years of sitting there's no oil on the cam and bearings. Cranking it dry wipes them out.",
	"door_pin": "Penetrant needs time to wick in. Forcing a rusted pin bends the hinge.",
	"hot_mag": "No drop on a mag means its P-lead isn't grounding it: that mag is live with the key off, and the prop can start the engine if anyone turns it by hand.",
	"carb_heat": "Carb heat should cost a little rpm on the run-up. No drop means no hot air, and nothing to clear carburetor ice in flight.",
}
# Southeast and Midwest: fields cut out of solid woods.
const THICK_WOODS := ["Atlanta", "Nashville", "Miami", "Wichita", "Omaha", "Chicago", "Fargo", "Minneapolis"]
const HERO_TREES := 150  # full-detail trees around a field in the woods
const WOODS_TREES := 80000  # 100x the plains count. Canopies already touch at this density, so it's also the cap
# How you find each fault. Seen on the walk-around (clue = what you notice at that spot), or only
# heard/felt on the run-up from the cockpit. magneto and spark_plugs are here for saves made
# before troubleshooting existed; new jobs track those down with tests.
## Running the engine with this work still undone breaks something: [fault it breaks, what you
## see]. Only for things the walk-around shows and the radio call hints at, so you're always
## warned first. The owner doesn't pay for damage you did. (docs/quick-specs/run-it-unready-2026-11-12.md)
const RUNUP_DAMAGE := {
	"pre_oil": ["worn_rings", "It fired dry. A screech for the first seconds before the oil got there: cylinder %d's wall and rings are scuffed. That's a new cylinder",
		"Pre-oil it first: started dry, it'll scuff a cylinder."],
	"prop_bolts": ["propeller", "The prop worked on its loose bolts: the wood's charred at the flange and the bolt holes are oval. It's scrap",
		"Torque the prop bolts first: run loose, they'll ruin the prop."],
	"bird_nest": ["baffles", "Smoke from the cowl: the nest caught on the exhaust and scorched the baffle seals",
		"Pull that nest first: it'll catch fire on the exhaust."],
}
const RUNUP_FAULTS := ["battery", "starter", "avionics", "magneto", "spark_plugs", "hot_mag", "mag_timing", "brake_bleed", "wire_chafe", "instrument_swap", "carb_heat"]

# Troubleshooting tests (M-0 Chapter 8). clue: what the run-up tells you; symptom: what the
# owner says on the radio; options: [what you call, its key]. TEST_KEY maps a fault to the
# right key ("@cyl": the cold cylinder, "@valve": which valve is sticking).
const TESTS := {
	"spark_test": {"name": "Spark test", "zone": "engine", "symptom": "drops a lot of rpm on the left mag",
		"clue": "Big drop on the left mag and it runs rough on it. Plug, lead or magneto?",
		"ask": "What's killing the left mag?",
		"options": [["Not one plug fires: the magneto", "magneto"], ["Same lead dead with a good plug: the ignition lead", "lead"],
			["A good plug fires on that lead: the spark plugs", "plugs"]]},
	"reading_plugs": {"name": "Reading the plugs", "zone": "engine", "symptom": "runs rough and puffs smoke",
		"clue": "Rough and smoky at idle. Pull the plugs and read them",
		"ask": "What do the plugs say?",
		"options": [["Thin, worn electrodes: replace the set", "worn"], ["Dry black soot on every one: running rich, check the primer", "rich"],
			["One cylinder's plugs wet with oil: test that cylinder", "oily"]]},
	"cold_cylinder": {"name": "Cold cylinder hunt", "zone": "engine", "symptom": "shakes at every rpm",
		"clue": "Rough on both mags at every rpm: one cylinder isn't pulling its weight",
		"ask": "Which cylinder isn't firing?",
		"options": [["Cylinder 1", "c0"], ["Cylinder 2", "c1"], ["Cylinder 3", "c2"], ["Cylinder 4", "c3"]]},
	"compression": {"name": "Compression test", "zone": "engine", "symptom": "",
		"clue": "",
		"ask": "Where's the air getting out?",
		"options": [["Hiss at the tailpipe: an exhaust valve", "exhaust"], ["Hiss at the carb air scoop: an intake valve", "intake"],
			["Hiss at the oil filler: the rings", "rings"]]},
	"oil_screen": {"name": "Oil screen check", "zone": "engine", "symptom": "oil pressure sags once it's warm",
		"clue": "Oil pressure sags to 20 once it's warm; the manual wants 30. Pull the oil screen",
		"ask": "What's in the screen?",
		"options": [["Clean: it's the relief valve", "clean"], ["Steel, sticks to the magnet: cam or lifters", "steel"],
			["Bright aluminum: a piston", "aluminum"], ["Gold bronze: piston pin bushings", "bronze"]]},
}
const TEST_KEY := {
	"spark_test": {"magneto": "magneto", "ign_lead": "lead", "spark_plugs": "plugs"},
	"reading_plugs": {"spark_plugs": "worn", "primer_leak": "rich", "worn_rings": "oily"},
	"cold_cylinder": {"stuck_valve": "@cyl", "worn_rings": "@cyl"},
	"compression": {"stuck_valve": "@valve", "worn_rings": "rings"},
	"oil_screen": {"relief_valve": "clean", "cam_wear": "steel", "piston_scuff": "aluminum", "bronze_bushing": "bronze"},
}
## Hard: what you see, without what it means (the rest of CLUES already only describe).
const HARD_CLUES := {
	"pre_oil": "a dry varnish film on the dipstick, and the engine log shows no run in years",
	"fabric_test": "the wing fabric is chalky and ringworm-cracked",
	"mag_timing": "Slow to pick up and the oil temperature climbs",
	"hot_mag": "Mag check: no drop at all on the right mag",
	"fod": "CLANK: something loose rattles under the cowl as it fires",
}


func clue(id: String) -> String:
	return HARD_CLUES[id] if not guide("medium") and HARD_CLUES.has(id) else CLUES[id]


const CLUES := {
	"tire": "the left tire is squashed flat on its rim",
	"brakes": "black grit round the right wheel, and the brake blocks show worn thin through the drum's inspection gap",
	"oil_leak": "fresh oil dripping off the bottom of the cowling",
	"bird_nest": "straw poking out of the cowl inlet, and chirping inside",
	"fuel_line": "a blue stain and a sharp avgas smell at the firewall",
	"windshield": "a long crack right across the windshield",
	"control_cables": "the rudder flops loose; its cables feel slack",
	"propeller": "a crack running in from one blade tip",
	"battery": "Starter clicks, and the panel lights dim to almost nothing while you hold it",
	"starter": "Starter clicks, but the panel lights stay bright while you hold it",
	"avionics": "Radio's dead silent, not even a hiss. The antenna's snapped too",
	"magneto": "Mag check: big drop and rough running on the left mag",
	"spark_plugs": "Mag check: big drop and rough running on the left mag",
	"stale_fuel": "the sumped fuel smells like varnish and comes out dark",
	"pre_oil": "an engine that sat this long can't be cranked dry: pre-oil it first",
	"door_pin": "the cabin door won't budge; the handle moves but the pin doesn't",
	"carb_heat": "Carb heat at 2,100: no rpm drop at all",
	"tmp_strut": "a hairline crack across the lift strut fork",
	"storage": "a tag on the prop: DO NOT TURN PROPELLER - ENGINE PRESERVED, and red streamers on plugs in the exhaust",
	"oil_change": "the dipstick oil is black as tar",
	"bungee": "the gear sags and the shock cords are cracked and sun-checked",
	"tie_down": "the tie-down ropes are rotted through and it's weathervaning in the gusts",
	"hot_mag": "Mag check: no drop at all on the right mag. It's hot: the prop is live even with the switch OFF",
	"mag_timing": "Slow to pick up and the oil temperature climbs: the timing's off",
	"brake_bleed": "Holding the brakes for the run-up, the right pedal sinks to the floor",
	"wire_chafe": "Tap the panel and the radio cuts out",
	"exhaust_check": "a crack along the muffler seam, with gray-white exhaust streaks",
	"air_filter": "the air filter is packed with chaff and the carb heat door hangs half open",
	"baffles": "mud dauber nests packed in the cylinder fins and a baffle seal flapping loose",
	"fuel_vent": "the fuel cap's vent tube is plugged with a mud dauber nest",
	"water_fuel": "a sump sample comes up with clear water beads under the fuel",
	"fuel_strainer": "the strainer bowl is full of rust-colored sediment",
	"aileron_rigging": "with the stick centered, the left aileron hangs below the wing's trailing edge",
	"wing_rig": "sighting down the wings, the left one sits flatter than the right",
	"elevator_cable": "a broken strand at the elevator horn terminal",
	"trim_cable": "turn the trim crank and the stabilizer doesn't move",
	"brace_wires": "a kinked tail brace wire, with plier marks on it",
	"tailwheel": "the tailwheel flops side to side and a steering spring hangs loose",
	"prop_dress": "a stone nick in one blade's leading edge",
	"prop_track": "sighting across the prop, one tip sits ahead of the other",
	"compass": "the compass reads 25 degrees off the runway heading",
	"pitot_static": "the static hose behind the panel is cracked and stiff",
	"weight_balance": "the weight and balance in the logbook predates the big tires and the cushions",
	"jet_fuel": "the sump cup smells of kerosene, and the owner says they ran it like that",
	"prop_strike": "a prop tip broken off, mud on the cowl: it nosed over and the engine stopped dead",
	"fabric_test": "the wing fabric is chalky and ringworm-cracked: it needs a punch test",
	"brake_master": "red fluid pooled on the rear floorboard under the left heel pedal",
	"instrument_swap": "The tach needle sits on zero the whole run-up, and its glass is cracked",
	"prop_bolts": "a dark gap between the hub and the wood, and the prop bolts turn by hand",
	"fabric_rot": "the fabric tester punched right through",
	"fod": "CLANK: something loose rattles under the cowl as it fires. A dropped tool?",
}
# Walk-around inspection spots, in plane-local coords (nose -Z), probed from the plane model.
const ZONES := {
	"prop": {"name": "propeller", "pos": Vector3(0, 1.2, -1.45), "size": Vector3(1.9, 1.9, 0.3)},
	"engine": {"name": "engine", "pos": Vector3(0, 1.15, -0.9), "size": Vector3(1.0, 0.9, 0.8)},
	"cabin": {"name": "cabin & windshield", "pos": Vector3(0, 1.6, 0.4), "size": Vector3(0.9, 0.9, 1.6)},
	"gear_l": {"name": "left main gear", "pos": Vector3(-0.85, 0.3, 0), "size": Vector3(0.6, 0.7, 0.7)},
	"gear_r": {"name": "right main gear", "pos": Vector3(0.85, 0.3, 0), "size": Vector3(0.6, 0.7, 0.7)},
	"wing_l": {"name": "left wing", "pos": Vector3(-2.4, 1.95, 0.8), "size": Vector3(2.4, 0.6, 1.8)},
	"battery": {"name": "battery bay", "pos": Vector3(0.45, 1.45, 1.7), "size": Vector3(0.3, 0.6, 0.8)},
	"tail": {"name": "tail & rudder", "pos": Vector3(0, 2.0, 4.7), "size": Vector3(1.6, 1.6, 1.4)},
}
# Name, base pay, and the faults this type never gets. The rag-wing is the J-3 Cub with a
# Continental C85-12 (starter, generator, battery); its brakes are drums with expander tubes, and
# the brake job shows exactly that (blocks round the tube), so every type can get it.
const PLANE_TYPES := [["High-wing trainer", 1500, []],
	["Rag-wing taildragger", 2000, []],
	["Bush plane", 2500, []], ["Vintage tourer", 3000, []], ["Utility hauler", 3500, []]]


## True for planes with no starter: you swing the prop by hand. (Every type has one now that
## the Cub runs a C85-12; a flat battery still means hand-propping, see _run_up.)
func _hand_propped(job: Dictionary) -> bool:
	return PLANE_TYPES.any(func(t): return t[0] == job.type and "starter" in t[2])

var money := 3000:
	set(v):
		if is_node_ready() and v != money and not _quiet_money:
			_money_pop(v - money)
		money = v
var _quiet_money := false  # the delivery's pay goes on the end-of-mission card, not a pop (D3)
var day := 1.0  # travel, inspections and repairs take time; calls have deadlines
var rescued := 0
var location := START_CITY
var inventory := {}
var jobs: Array = []
var current_job = null  # Dictionary of the plane at this field, or null
var logbook: Array = []  # one entry per rescue: {day, city, type, pay, faults}
## How much the game tells you (docs/quick-specs/difficulty-2026-11-12.md). Old saves: medium.
const DIFFICULTIES := {
	"easy": "Points at the work, says why a step can't happen yet, and won't let you run an engine that isn't ready.",
	"medium": "You get the facts and the paperwork. The mistakes are yours.",
	"hard": "Nobody tells you what's next, when it can run, or if it's ready. Sign off bad work and it comes back.",
}
var difficulty := "medium"
static var keep_difficulty := ""  # carried across "start over"
var graphics := "high"  # "low" drops haze, bounce light, ambient occlusion and dust (weaker PCs)
var rng := RandomNumberGenerator.new()

var world: Node3D
var plane: Node3D
var cub: Node3D  # the plane model; its parts (tyre_l, rudder, antenna_elt...) are named nodes
var visuals := {}  # fault id -> Node3D showing broken/fixed state
var player
var ui: CanvasLayer
var hud: Control  # the pocket strip (wallet, clipboard, logbook keys)
var prompt: Label
var msg: Label
var preflight  # scripts/preflight.gd: the cockpit checklist card
const Preflight := preload("res://scripts/preflight.gd")
var _banner_node: Control
var _saved: TextureRect
var _saved_fade: Tween
var cross: Reticle
var panel: Control
var panel_closable := true
var msg_time := 0.0
var close_frame := -1  # frame a panel was closed with E, so the same press doesn't reopen it
var tools := {}  # tool id -> true for each tool taken from the hangar toolbox (see Work.TOOLS)
var ferry: Node = null  # active ferry flight
var sound
var env: Environment
var sun: DirectionalLight3D
var terrain  # Terrain for the current field


func _ready() -> void:
	assert(absf(miles("New York", "Los Angeles") - 2450.0) < 60.0, "miles() is off")
	rng.randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS  # menus keep working while the game is paused
	_setup_input()
	_setup_environment()
	_setup_ui()
	player = Player.new()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	sound = Sound.new()
	add_child(sound)
	_load_settings()
	sound.tune(clampi(settings.station, 0, Sound.STATIONS.size() - 1), true)
	var args := OS.get_cmdline_user_args()
	if "--self-test" in args:
		save_path = "user://selftest.save"  # never touch the player's game
		_delete_save()
		test_seed = randi()
		for a in args:
			if a.begins_with("--seed="):  # replay a failed run's job and faults
				test_seed = int(a.trim_prefix("--seed="))
		rng.seed = test_seed
		seed(test_seed)
	elif "--monkey" in args:
		save_path = "user://monkey.save"
		if not get_tree().root.has_node("Monkey"):
			var monkey: Node = load("res://scripts/monkey.gd").new()
			monkey.name = "Monkey"
			get_tree().root.add_child.call_deferred(monkey)
	had_save = _load_game()
	_refresh_tracker()  # the HUD was built before the save loaded: show its badges
	if rank_index(earned_rank()) > rank_index(rank) or rank == "":
		rank = earned_rank()  # a career from before the ladder gets the rank its record earns
	if keep_difficulty != "":
		difficulty = keep_difficulty
		keep_difficulty = ""
	if had_save:
		_load_field(location, current_job)
		_greeting = "Welcome back. Day %d in %s." % [floori(day), location]
	elif save_locked:
		while jobs.size() < MAX_JOBS:
			_spawn_job()
		_load_field(START_CITY, null)
		_greeting = "Couldn't read your saved game, so it was left untouched. This session won't be saved over it."
	else:
		tools = STARTER_TOOLS.duplicate()  # a new career starts with a screwdriver and a rag
		inventory = STARTER_SUPPLIES.duplicate()  # and a few consumables in the truck
		if not "--self-test" in args:  # three taught jobs first (tutorial.gd); the self-test turns it on with --tutorial
			tut = {"lesson": 1, "tour": false, "done": {}, "base": 0}
		while jobs.size() < MAX_JOBS:
			_spawn_job()
		_load_field(START_CITY, null)
		_greeting = "Home base. Take a rescue call from the map on the hangar workbench. WASD walks, E uses things, Esc pauses."
	_warm_assets()
	if not "--self-test" in args and not skip_menu:
		_open_menu()  # it clears messages, so the greeting waits for it to close
	else:
		_say(_greeting)
		_greeting = ""
	skip_menu = false
	if "--self-test" in args:
		var test = load("res://scripts/selftest.gd").new()
		add_child(test)
		test.run(self, args)
	elif not "--monkey" in args:
		_playlog = PLAYLOG_PATH
		playlog("session start, day %.1f, $%d, %d rescued" % [day, money, rescued])
		updater = Updater.new()
		add_child(updater)
		updater.available.connect(_offer_update)
		updater.check()


# ---------- playtest log ----------

## Where each step of a hand-played session went, in real seconds, plus F8 notes. Never written by tests.
const PLAYLOG_PATH := "user://playtest_log.txt"
var _playlog := ""
var _play_t := 0


func playlog(what: String) -> void:
	if _playlog == "":
		return
	var f := FileAccess.open(_playlog, FileAccess.READ_WRITE if FileAccess.file_exists(_playlog) else FileAccess.WRITE)
	if not f:
		return
	var now := Time.get_ticks_msec()
	f.seek_end()
	f.store_line("%s  day %.2f  +%ds  %s" % [Time.get_datetime_string_from_system(), day, (now - _play_t) / 1000, what])
	_play_t = now


# ---------- auto-update ----------

var updater


func _offer_update(version: String, notes: String) -> void:
	if panel_kind == "menu":
		_pending_update = [version, notes]  # show it once they leave the title screen
		return
	if panel and not panel_closable:
		return  # mid game-over or win screen: offer next launch
	var rows := [["Version %s is out (you have %s)." % [version, ProjectSettings.get_setting("application/config/version")]]]
	if notes.strip_edges() != "":
		rows.append([notes.left(400)])
	rows.append(["Your game is saved and carries over.", "Install now", _install_update, true])
	_open_panel("Update available", rows)


func _install_update() -> void:
	_save_game()
	_open_panel("Downloading the update...", [["The game closes and the installer takes it from here."]], false)
	updater.install(func(_ok, message): _open_panel("Update", [[message]]))


# ---------- save / load ----------

var save_path := "user://airplane_rescue.save"
var test_seed := 0  # printed with every self-test result
const SAVE_KEYS := ["money", "day", "rescued", "location", "inventory", "tools", "jobs", "logbook", "graphics", "difficulty", "held", "tut", "badges", "rank"]
const SAVE_VERSION := 2  # bump when the layout changes, and teach _migrate the step
var _greeting := ""  # the first message of this session
var had_save := false  # a career was loaded at launch (so the title screen offers Continue)
var save_locked := false  # a save we couldn't read is never overwritten (it might be newer, or fixable)


## Autosaves after anything that changes the game (time passing, buying, travel, tools).
## Writes a temp file and swaps it in, keeping the previous save as .bak: a crash or power
## cut mid-write can never leave the only copy half-written.
func _save_game() -> void:
	if save_locked:
		return
	var data := {"version": SAVE_VERSION, "current": jobs.find(current_job)}
	for k in SAVE_KEYS:
		data[k] = get(k)
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if not f:
		_say("Couldn't save your game. Check that the disk isn't full.")
		return
	f.store_var(data)
	f.close()
	if _commit_save(tmp):
		_saved_mark()


## Swaps the finished temp file in, but only if it reads back: on a full disk the write can
## fail silently, and a bad file here would push the last good save out of .bak too.
func _commit_save(tmp: String) -> bool:
	if not _read_save(tmp) is Dictionary:
		DirAccess.remove_absolute(tmp)
		_say("Couldn't save your game. Check that the disk isn't full.")
		return false
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path + ".bak")
		DirAccess.rename_absolute(save_path, save_path + ".bak")
	DirAccess.rename_absolute(tmp, save_path)
	return true


## Loads the save, falling back to the .bak copy. Older layouts are migrated; anything
## unreadable or from a newer build is left untouched on disk and the game won't autosave
## over it (it starts a fresh session in memory and says so).
func _load_game() -> bool:
	if not FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path + ".bak"):
		return false
	for path in [save_path, save_path + ".bak"]:
		var data = _read_save(path)
		if data is Dictionary and int(data.get("version", 0)) <= SAVE_VERSION:
			_migrate(data)
			for k in SAVE_KEYS:
				if data.has(k):
					set(k, data[k])  # missing keys keep their fresh-game defaults
			var idx: int = data.get("current", -1)
			current_job = jobs[idx] if idx >= 0 and idx < jobs.size() else null
			return true
		if data is Dictionary:  # from a newer version of the game: never overwrite it
			save_locked = true
			return false
	save_locked = true  # both copies unreadable: keep them for recovery
	return false


func _read_save(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_var() if f else null


## Upgrades an older save in place, one version step at a time.
func _migrate(data: Dictionary) -> void:
	var inv: Dictionary = data.get("inventory", {})
	if inv.has("Brake disc"):  # the drum-brake part was renamed
		inv["Brake shoe set"] = inv.get("Brake shoe set", 0) + inv["Brake disc"]
		inv.erase("Brake disc")
	for j in data.get("jobs", []):  # fields added after the first saves shipped
		for key in ["years", "washed", "spent", "work", "fuel", "parked"]:
			if not j.has(key):
				j[key] = {"years": 0, "washed": true, "spent": {"fuel": 0, "parts": 0, "mail": 0}, "work": {}, "fuel": 0.2, "parked": "apron"}[key]
	if int(data.get("version", 0)) < 2:  # 2: the apprenticeship. A career already under way skips it.
		data["tut"] = {"lesson": 0, "tour": true, "done": {}, "base": int(data.get("rescued", 0))}
	data.version = SAVE_VERSION


func _delete_save() -> void:
	for ext in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(save_path + ext)
	save_locked = false


# ---------- game state ----------

func miles(a: String, b: String) -> float:
	var p: Array = CITIES[a]
	var q: Array = CITIES[b]
	var r := PI / 180.0
	var dlat: float = (q[1] - p[1]) * r
	var dlon: float = (q[0] - p[0]) * r
	var h: float = sin(dlat / 2) ** 2 + cos(p[1] * r) * cos(q[1] * r) * sin(dlon / 2) ** 2
	return 2.0 * 3959.0 * asin(sqrt(h))


func _spawn_job() -> void:
	var taken := jobs.map(func(j): return j.city)
	var options := CITIES.keys().filter(func(c): return c != location and not taken.has(c))
	# Always keep one call within a short hop, so a thin wallet can still reach work.
	var near := options.filter(func(c): return miles(location, c) < NEAR_MILES)
	if near.size() > 0 and not jobs.any(func(j): return j.city != location and miles(location, j.city) < NEAR_MILES):
		options = near
	var t: Array = PLANE_TYPES[rng.randi() % PLANE_TYPES.size()]
	# The career ramps up with every rescue (docs/quick-specs/difficulty-2026-11-12.md): the first
	# calls are things you can see or hear; troubleshooting, long-sat wrecks, annuals and planes
	# that can't be saved come later, and so do more faults per plane and owners in a hurry.
	var r: int = maxi(0, rescued + performance_form())  # pitched to how the last jobs went (P4); never below a fresh career
	var ids := FAULTS.keys().filter(func(id): return not id in NEGLECT_FAULTS and not id in GROUND_FAULTS and id != "fod" \
		and not id in t[2] and not FAULTS[id].get("ground", false) and (r >= 2 or (FAULTS[id].get("diags", []).is_empty() and not SUSPECTS.has(id))))  # look-alikes start on job 3
	ids.shuffle()
	var most: int = mini(5, 2 + r / 2)
	var fewest: int = mini(most, 1 + r / 4)
	var picks := ids.slice(0, rng.randi_range(fewest, most))
	# Some planes were just parked; others sat in the weather for years (Rebuild Rescue style):
	# grimy, stale gas, a dry or pickled engine, old oil, tired cords, maybe a door rusted shut.
	var first := r == 0 and jobs.is_empty() and not "--self-test" in OS.get_cmdline_user_args()
	if first:  # the first win comes fast
		var easy := FIRST_JOBS.filter(func(id): return FAULTS.has(id))
		if easy.size() > 0:
			picks = [easy[0]]
	# During the apprenticeship one call on the map is the lesson's job (tutorial.gd), on a clean
	# plane; the others are real calls, locked until the lessons are done.
	var lesson := 0
	if int(tut.get("lesson", 0)) > 0 and not jobs.any(func(j): return j.get("lesson", false)):
		lesson = int(tut.lesson)
		picks = tutorial.lesson_faults(rng)
		first = true  # no years in the weather, no extras
	var years := 0 if first or rng.randf() < 0.45 else rng.randi_range(2, mini(15, 4 + r * 3 / 2))
	if years >= 2:
		picks += ["stale_fuel", "oil_change"]
		if rng.randf() < 0.3:
			picks.append("tie_down")
	if years >= 5:
		picks.append("storage" if rng.randf() < 0.3 else "pre_oil")  # some owners pickled it properly
	if years >= 8:
		if rng.randf() < 0.6:
			picks.append("door_pin")
		if rng.randf() < 0.5:
			picks.append("bungee")
	if r >= 2 and lesson == 0 and rng.randf() < 0.06:  # now and then a plane that can't be fixed where it sits
		picks.push_front(GROUND_FAULTS[rng.randi() % GROUND_FAULTS.size()])
	var job := {"city": options[rng.randi() % options.size()], "type": t[0], "years": years, "washed": years == 0, "lesson": lesson > 0,
		"fixed": {}, "found": {}, "checked": {}, "work": {}, "annual": rank == "ia" and lesson == 0 and rng.randf() < 0.15,  # an annual needs an IA
		"spent": {"fuel": 0, "parts": 0, "mail": 0}, "fuel": rng.randf_range(0.03, 0.3), "parked": "apron",
		"owner": OWNERS[rng.randi() % OWNERS.size()], "tried": {}, "hidden": "",
		"deadline": day + 5 - mini(1, r / 4) + rng.randi() % 5}  # each spot takes two hours: skipping one is a real gamble
	job["reg"] = make_registration(rng)  # its N-number, for the ticket (D3)
	_assign_faults(job, picks)
	var cost := 0
	for id in job.faults:
		cost += FAULTS[id].cost + (60 if job.diag.has(id) else 0)  # troubleshooting pays too
	job.reward = _pay_for(t[1] + cost + years * 150 + (250 if job.annual else 0), call_difficulty(job), lesson > 0)
	# Sometimes the cowl comes off for one job and shows you another behind it.
	if r >= 2 and lesson == 0 and job.faults.any(func(id): return FAULTS[id].zone == "engine") and rng.randf() < 0.35:
		var pick := HIDDEN_CLUES.keys().filter(func(id): return not job.faults.has(id))
		if pick.size() > 0:
			job.hidden = pick[rng.randi() % pick.size()]
	jobs.append(job)


## Sets a job's faults, picking a troubleshooting chain for each fault that needs one. Two
## faults never share a test (their readings would contradict), so a clash drops the second.
## Also rolls the hidden details the tests read: the bad cylinder, lead and valve.
func _assign_faults(job: Dictionary, picks: Array) -> void:
	job.faults = []
	job.diag = {}
	job.dstep = {}
	job.sym = {}
	job.cyl = rng.randi() % 4
	job.lead = rng.randi() % 4
	job.valve = ["exhaust", "intake"][rng.randi() % 2]
	var tl := 52 + rng.randi() % 14
	job.wb = {"l": 290 + rng.randi() % 16, "r": 288 + rng.randi() % 16, "t": tl}
	job.fabric_bad = rng.randi() % 3 if rng.randf() < 0.3 else -1  # a failed punch test grounds it
	var used := {}
	for id in picks:
		if id in job.faults:
			continue
		var chains: Array = FAULTS[id].get("diags", [])
		if chains.size() > 0:
			var free := chains.filter(func(c): return not c.any(func(t): return used.has(t)))
			if free.is_empty():
				continue
			var chain: Array = free[rng.randi() % free.size()]
			for t in chain:
				used[t] = true
			job.diag[id] = chain
		job.faults.append(id)


## How a fault in this job gets found: "walk" (walk-around), "runup", or "diag" (tests).
func _how(job: Dictionary, id: String) -> String:
	if job.get("diag", {}).has(id):
		return "diag"
	return "runup" if id in RUNUP_FAULTS else "walk"


## What the owner tells you on the radio: every fault's symptom, in random order.
## What the pilot wrote on the squawk sheet: what they felt, heard, saw or smelled, never the
## cause. A plane with several faults gets every line. Faults found only by testing describe the
## symptom, and look-alike causes share their wording (all four oil-pressure faults read the same)
## so the squawk starts the trail without handing over the answer. Two versions where it helps,
## so a regular can't learn "this sentence means that part".
const SQUAWKS := {
	"tire": ["It's sitting low on the left side, and it pulled hard left on the last landing roll.",
		"Left main looks squashed. I had to hold a lot of right rudder just to taxi in."],
	"brakes": ["Grinding from the right wheel every time I touch the brake, and it barely slows me down.",
		"Right brake squeals, then grinds. Takes forever to stop on the ramp."],
	"battery": ["Hit the starter this morning and got one weak click, then nothing. The lights are dim too."],
	"spark_plugs": ["Runs a little rough at idle and puffs black smoke on start-up. It's been getting worse.",
		"Rough on the run-up on both mags, and the exhaust stack is black and sooty."],
	"oil_leak": ["Oil spots on the hangar floor under the nose, and the belly has an oily film after every flight.",
		"I've been adding a quart every couple of flights, and there's oil streaked down the belly."],
	"bird_nest": ["Birds flew out of the cowling when I pulled the cover off. Haven't flown it since."],
	"fuel_line": ["Strong smell of gas in the cockpit on climb-out, and there's a blue stain on the firewall."],
	"windshield": ["Got caught in a hailstorm on the ramp. There's a long crack right across the windshield."],
	"starter": ["The starter just clicks, or grinds, and won't turn the prop over. The battery's new."],
	"control_cables": ["Rudder pedals are stiff, almost binding. Hard to keep it straight on the takeoff roll."],
	"magneto": ["Engine stumbled and dropped nearly 250 RPM when I switched to the left mag on the run-up. The right mag sounds fine."],
	"avionics": ["Radio's dead silent. Can't raise anyone, not even a hiss in the headset."],
	"propeller": ["Found a crack running in from one blade tip on my walk-around. I didn't fly it."],
	"stale_fuel": ["It's been sitting a long time. The last gas went in years ago, and what I sumped smells off."],
	"pre_oil": ["Hasn't been started in years. I didn't want to crank it before somebody looked at it."],
	"door_pin": ["Can't get the cabin door open. The handle turns but the door won't budge."],
	"carb_heat": ["Ran rough on a damp morning, and pulling carb heat didn't change a thing. The knob feels loose."],
	"tmp_strut": ["The left wing creaks when I rock it, and something at the bottom of the strut doesn't look right."],
	"storage": ["The engine was put up properly for storage. There's a tag on the prop that says not to turn it."],
	"oil_change": ["Honestly, nobody remembers the last oil change. What's on the dipstick looks black."],
	"bungee": ["Sits low on its gear and bangs hard on every landing, even the soft ones."],
	"tie_down": ["It's been rocking at its tie-downs all season. The ropes look rough."],
	"ign_lead": ["Lost a good chunk of RPM on one mag on the run-up, and it coughed a couple of times taxiing over bumps.",
		"Runs fine on both mags, but on one alone it shakes and drops off. Worse when it's damp out."],
	"primer_leak": ["Runs rich and sooty at idle, and I smell gas in the cockpit right after I prime it."],
	"stuck_valve": ["Felt sluggish on the takeoff roll today and had to fight it off the grass. Pulling the prop through, there's a rhythmic chuffing sound.",
		"Shakes at every RPM, worst when it's cold. One blade comes over way too easy when I pull the prop through."],
	"worn_rings": ["Shakes a little and it's burning a quart every few hours. Blue smoke when it starts.",
		"Down on power, a bit rough, and the oil's going somewhere: no drips, but I keep adding it."],
	"relief_valve": ["Oil pressure starts out normal, then sags toward 20 once it's warm. The temperature's fine."],
	"cam_wear": ["Oil pressure starts out normal, then sags toward 20 once it's warm. The temperature's fine."],
	"piston_scuff": ["Oil pressure starts out normal, then sags toward 20 once it's warm. The temperature's fine."],
	"bronze_bushing": ["Oil pressure starts out normal, then sags toward 20 once it's warm. The temperature's fine."],
	"hot_mag": ["On the mag check there's no drop at all on one mag. My buddy says that's good, but it seems too good to me."],
	"mag_timing": ["Feels sluggish and slow to pick up, and the oil temperature runs higher than it used to."],
	"brake_bleed": ["The right brake pedal goes soft and sinks almost to the floor. Pumping it firms it up a little."],
	"wire_chafe": ["The radio cuts in and out over bumps on the grass. Sitting still it works fine."],
	"exhaust_check": ["Got a headache on the way home and the cabin smells like exhaust. There's a black streak on the cowl that wasn't there last week."],
	"air_filter": ["Down on power on climb-out, and the RPM drops way more than usual when I pull carb heat."],
	"baffles": ["Oil temperature climbs toward the red line on a long climb. It never used to."],
	"fuel_vent": ["Starts fine, runs a minute or two, then quits. It'll restart after it sits a while."],
	"water_fuel": ["Coughed and quit once it warmed up, after a week of rain. It restarted rough."],
	"fuel_strainer": ["Loses power at full throttle on takeoff, then it's fine once I pull it back."],
	"aileron_rigging": ["Flies with the left wing low. I'm holding right stick the whole flight."],
	"wing_rig": ["Won't fly straight hands-off. It always wants to turn a little left."],
	"elevator_cable": ["The stick feels notchy moving fore and aft, like it catches on something."],
	"trim_cable": ["I crank the trim and nothing happens. The crank just spins."],
	"brace_wires": ["The tail shakes in gusty air, and one of the wires back there looks bowed."],
	"tailwheel": ["The tailwheel shimmies on pavement and won't steer with the pedals."],
	"prop_dress": ["Picked up a stone on the gravel strip. Heard a sharp tick from the prop."],
	"prop_track": ["Smooth on the ground, but the whole panel shakes at cruise power."],
	"compass": ["The compass reads about twenty degrees off the runway heading."],
	"pitot_static": ["Airspeed and altimeter wander around in smooth air, worse when I open the window."],
	"weight_balance": ["Put on big tires and new seat cushions. The weight paperwork in the logbook is from 1946."],
	"jet_fuel": ["The line boy filled it with Jet-A, and we ran it a while before anybody noticed."],
	"prop_strike": ["Nosed over in soft mud on landing. The prop hit and the engine stopped dead."],
	"fabric_test": ["The wing fabric looks chalky and tired, with little cracks all over the paint."],
	"brake_master": ["The left brake pedal sinks to the floor, and there's red fluid on the floor under it."],
	"instrument_swap": ["The tach needle never leaves zero. The engine sounds normal."],
	"prop_bolts": ["There's a clunk from the nose at idle, and the prop seems to move a hair when I push on it."],
}


## One line from the squawk sheet for this fault on this plane (the version is fixed per job).
func squawk_line(job: Dictionary, id: String) -> String:
	var v: Array = SQUAWKS.get(id, [])
	if v.is_empty():
		return ""
	return v[(job.get("cyl", 0) + int(job.get("seed_squawk", 0)) + id.length()) % v.size()]


func _symptoms(job: Dictionary) -> String:
	var years: int = job.get("years", 0)
	var sat := (" Sat out in the weather %d years." % years) if years > 0 else ""
	if job.get("annual", false):  # no complaints: it's your job to find what's wrong
		return "\"Annual's due. Go over it nose to tail and sign it off.\"" + sat
	var s: PackedStringArray = []
	for id in job.faults:
		var line := squawk_line(job, id)
		if line == "":  # no squawk written (found only on site): fall back to the short symptom
			line = (TESTS[job.diag[id][0]].symptom if job.get("diag", {}).has(id) else FAULTS[id].symptom)
			line = (line[0].to_upper() + line.substr(1) + ".") if line != "" else ""
		if line != "" and not line in s:
			s.append(line)
	if s.is_empty():
		s.append("Just get it flying, please.")
	return "\"" + " ".join(s) + "\"" + sat


func _advance(days: float) -> void:
	day += days
	var bill := (floori(day) - floori(day - days)) * DAILY_COST  # charged as each new day starts
	if bill > 0:
		money = maxi(0, money - bill)
	for j in jobs.duplicate():
		if day > j.deadline:
			jobs.erase(j)
			_say("The owner in %s gave up waiting and scrapped the %s." % [j.city, j.type])
			if j == current_job:  # the plane you're standing next to is gone
				current_job = null
				if plane:
					plane.queue_free()
					plane = null
	while jobs.size() < MAX_JOBS:
		_spawn_job()
	_save_game()


## What a job cost you, itemized for the logbook (like the end of a Rebuild Rescue episode).
## Records something that cost extra on this job, as it happens, for the debrief on delivery
## (E5): what kind (DEBRIEF_ADVICE keys), the days and money it cost, and what it was.
func note_cost(kind: String, days: float, cash: int, what: String) -> void:
	if current_job == null:
		return
	current_job.get_or_add("lost", []).append({"kind": kind, "days": days, "money": cash, "what": what})


func _spend(job: Dictionary, what: String, amount: int) -> void:
	if not job.has("spent"):
		job.spent = {"fuel": 0, "parts": 0, "mail": 0}
	job.spent[what] = job.spent.get(what, 0) + amount


const FLIGHT_SECONDS := 3.0
const ARRIVAL_SECONDS := 0.7  # least time the arrival card stays up, so a fast load doesn't flash it


## A trip is two scenes. The flight is pure show: nothing loads, so the plane on the chart never
## stutters. Then a still card, with nothing on it to stutter, covers the real work.
func _travel(job: Dictionary, cost: int) -> void:
	if is_instance_valid(_loader):  # already on the way
		return
	playlog("fly to %s, $%d, faults %s" % [job.city, cost, ",".join(job.faults)])
	money -= cost
	_spend(job, "fuel", cost)
	_close_panel()
	var nm := roundi(miles(location, job.city) * 0.869)
	var days := miles(location, job.city) / 700.0
	_show_loading("Flying to %s" % job.city, "%d NM, about %.1f days on the road and in the air.\nThe owner: %s" % [nm, days, _symptoms(job)], location, job.city)
	sound.cruise(true)
	get_viewport().disable_3d = true  # the card hides the world, and drawing it cost more than building it
	await _load_step(100, FLIGHT_SECONDS)
	location = job.city  # before _advance saves: closing the game mid-trip must not lose the fare
	current_job = job
	_advance(days)
	job.arrived = day
	var alive := jobs.has(job)  # false: ran out of time on the way
	_arrival_card(job.city)
	await get_tree().process_frame  # two frames: the card is on screen before the freeze begins
	await get_tree().process_frame
	var card_up := Time.get_ticks_msec()
	_load_field(job.city, job if alive else null)
	get_viewport().disable_3d = false
	await get_tree().process_frame  # the new field's first, slow render happens behind the card
	await get_tree().process_frame
	await get_tree().create_timer(maxf(ARRIVAL_SECONDS - (Time.get_ticks_msec() - card_up) / 1000.0, 0.05)).timeout
	sound.cruise(false)
	_hide_loading()
	if alive:
		_say("Arrived in %s. Walk around the %s: the floating markers show each spot to inspect (E)." % [job.city, job.type])


## The still scene that covers the field build: the logo and where you've landed.
func _arrival_card(city: String) -> void:
	var card := ColorRect.new()
	card.color = C_EARTH
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loader.add_child(card)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 28)
	card.add_child(box)
	var logo := TextureRect.new()
	logo.texture = load("res://textures/logo_title.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(640, 171)
	box.add_child(logo)
	var where := Label.new()
	where.text = "Arriving at %s, %s" % [city, STATE[city]]
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where.add_theme_font_override("font", HEAD_FONT)
	where.add_theme_font_size_override("font_size", 34)
	where.add_theme_color_override("font_color", C_PAPER)
	box.add_child(where)
	_arrived = card


var _loader: CanvasLayer
var _bar: ProgressBar
var _arrived: Control  # the arrival card, once the trip reaches it


static var _walls := {}  # mesh -> collision shape: building one for the hangar took a third of a second
static var _kept := {}  # path -> resource. Held so a trip never re-reads a model or texture from disk
var _warming := PackedStringArray()


## Starts loading every world model and texture on background threads, from the title screen on.
func _warm_assets() -> void:
	for dir in ["res://models/", "res://textures/"]:
		for f in ResourceLoader.list_directory(dir):
			if (f.ends_with(".glb") or f.ends_with(".png")) and not _kept.has(dir + f) and ResourceLoader.load_threaded_request(dir + f) == OK:
				_warming.append(dir + f)


## One finished load collected per frame.
func _warm_step() -> void:
	var path := _warming[-1]
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_kept[path] = ResourceLoader.load_threaded_get(path)
	if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_warming.remove_at(_warming.size() - 1)


## Glides the bar, and the plane on the chart with it.
func _load_step(percent: float, seconds: float) -> void:
	var glide := _bar.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glide.tween_property(_bar, "value", percent, seconds)
	await glide.finished


## Full-screen travel card over the chart while the next field builds.
func _show_loading(title: String, detail: String, from: String, to: String) -> void:
	_hide_loading()
	_loader = CanvasLayer.new()
	_loader.layer = 20
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.06, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loader.add_child(bg)
	var map := TextureRect.new()
	map.texture = load("res://textures/us_map.png")
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.offset_bottom = -170.0  # the words sit under the chart, not over the route
	map.modulate = Color(0.93, 1.0, 0.93)
	_loader.add_child(map)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	box.offset_left = 40.0
	box.offset_right = -40.0
	box.offset_bottom = -14.0
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.add_theme_constant_override("separation", 4)
	for t in [[title, 32, Color(1.0, 0.93, 0.78)], [detail, 15, Color(0.9, 0.85, 0.75)], ["In the air", 13, Color(0.75, 0.7, 0.62)]]:
		var l := Label.new()
		l.add_theme_font_override("font", UI_FONT)
		l.text = t[0]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", t[1])
		l.add_theme_color_override("font_color", t[2])
		l.add_theme_constant_override("outline_size", 6)
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		box.add_child(l)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(460, 12)
	_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for part in [["background", Color(0.0, 0.0, 0.0, 0.6)], ["fill", C_BRASS]]:
		var look := StyleBoxFlat.new()
		look.bg_color = part[1]
		_bar.add_theme_stylebox_override(part[0], look)
	box.add_child(_bar)
	_loader.add_child(box)
	map.draw.connect(func(): chart.draw_trip(map, from, to, _bar.value / 100.0))
	_bar.value_changed.connect(func(_v): map.queue_redraw())
	add_child(_loader)
	player.frozen = true  # no wandering off while the next field loads


func _hide_loading() -> void:
	if is_instance_valid(_loader):
		_loader.queue_free()
		player.frozen = panel != null
	_loader = null
	_bar = null


## Walk-around inspection of one spot. The first time you open it up and look it over (bay.gd:
## the parts themselves, painted, where you look closer at each); after that it's the work order,
## which opens it up again. A first look at a spot is about two hours, so skipping one saves real
## time: that's the gamble. (The engine's first look is opening the cowl.)
func _inspect_zone(zone: String) -> void:
	standing_at = zone
	if not current_job.get("washed", true):  # years of dirt and lichen hide everything
		_say("It's caked in grime and lichen. You can't tell what's damage and what's dirt: wash it down first.")
		_open_inspection()
		return
	if current_job.checked.has(zone):
		_open_inspection()
		return
	current_job.checked[zone] = true
	playlog("inspect " + zone)
	if zone != "engine" and not _work_time(0.08):  # the owner gave up while you were looking
		return
	_open_bay(zone)


## Bucket, brush and a hose: an afternoon's work, and then you can see what you bought.
func _wash() -> void:
	playlog("wash")
	_advance(0.2)
	if not current_job:
		return
	current_job.washed = true
	_grime(false)
	_say("Washed it down. Under all that it's... %s." % ["better than it looked", "about what you feared", "a real airplane again"][rng.randi() % 3])
	_save_game()
	_open_inspection()
	_refresh_markers()


## Dirt and lichen over the whole plane until it's washed.
func _grime(on: bool) -> void:
	var m: Material = null
	if on:
		# Years of grime and lichen; texture alpha = coverage. Kept fine and partly see-through, so it
		# reads as dull, dirty paint rather than a camouflage pattern.
		var dirt := tmat("grime_lichen", Color(0.85, 0.8, 0.7, 0.62), 1.4)
		dirt.roughness = 1.0
		dirt.metallic = 0.0
		dirt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m = dirt
	for mi: MeshInstance3D in cub.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = m


## Sit in and run the engine up: master, crank, radio, mag check. What you hear and feel finds
## the faults a walk-around can't. A dead battery or starter stops the test there. On a Cub
## there's no starter: you swing the prop yourself first (the hand_prop scene).
func _run_up() -> void:
	var job: Dictionary = current_job
	var broken := func(id): return job.faults.has(id) and not job.fixed.has(id)
	if CITIES[job.city][2] == "snow" and not job.get("preheated", false):
		_say("It's well below 20 F and the engine's cold-soaked: the oil's like tar. Preheat it first (at the engine).")
		_open_inspection("cabin")
		return
	if guide("easy"):  # the boss stops you: known work that has to come before a start
		var wait: Array = RUNUP_DAMAGE.keys().filter(func(id): return broken.call(id) and job.found.has(id))
		if not wait.is_empty():
			_say("Not yet. " + " ".join(wait.map(func(id): return RUNUP_DAMAGE[id][2])))
			_open_inspection("cabin")
			return
	var blocked: bool = ["door_pin", "storage"].any(func(id): return broken.call(id))
	if (_hand_propped(job) or broken.call("battery")) and not blocked:  # flat battery: swing it by hand
		job.work.erase("hand_prop")  # the starting drill, fresh every time
		_open_work("hand_prop", _run_up_result)
		return
	_run_up_result()


func _run_up_result() -> void:
	var job: Dictionary = current_job
	_advance(0.04)
	if not current_job:
		return
	var heard: PackedStringArray = []
	var broken := func(id): return job.faults.has(id) and not job.fixed.has(id)
	var hear := func(id):
		job.found[id] = true
		var said: String = clue(id)
		if id in ["magneto", "spark_plugs", "hot_mag", "ign_lead"]:
			said = _mag_line(job)
		if not said in heard:
			heard.append(said)
	if broken.call("door_pin"):  # you can't run it up from outside
		hear.call("door_pin")
		job.runup = "dead"
	elif broken.call("storage"):  # preservative oil in the cylinders: hydraulic lock waiting to happen
		hear.call("storage")
		job.runup = "dead"
	else:
		if broken.call("battery"):  # you hand-propped it; it runs, but the battery still needs fixing
			hear.call("battery")
		if broken.call("avionics"):
			hear.call("avionics")
		if broken.call("starter") and not broken.call("battery"):  # hand-propped, the starter never came into it
			hear.call("starter")
			job.runup = "dead"
		else:
			for cause in RUNUP_DAMAGE:  # it ran before the work it needed: now something's broken
				if broken.call(cause):
					job.found[cause] = true
					var hurt := _run_damage(job, cause)
					if hurt != "":
						heard.append(hurt)
			for id in ["magneto", "spark_plugs", "hot_mag", "mag_timing", "brake_bleed", "wire_chafe", "instrument_swap", "carb_heat"]:
				if broken.call(id) and _how(job, id) == "runup":
					hear.call(id)
			for id in job.faults:  # trouble you can hear but not yet name: troubleshoot it
				if _how(job, id) == "diag" and not job.found.has(id) and not job.get("sym", {}).has(id):
					job.sym[id] = true
					heard.append(TESTS[job.diag[id][0]].clue)
			if job.get("fod", false):
				job.fod = false
				if not job.faults.has("fod"):
					job.faults.append("fod")
					job.fixed.erase("fod")
					job.work.erase("fod")
				hear.call("fod")
			if heard.is_empty():
				heard.append("Fires right up. %s, both smooth. Carb heat drops %d. Oil pressure in the green" % [_mag_line(job), carb_drop(job)])
			job.runup = "ran"
	for c in job.get("tried", {}):
		job.tried[c] = true  # this run-up shows whether the swap cured it
	log_clear()
	log_line(". ".join(heard) + ("." if job.runup == "ran" or not guide("medium") else ". Can't run it up until that's fixed."))
	playlog("run-up result: " + ". ".join(heard))
	_save_game()
	_open_inspection("cabin")


## rpm lost on the left and right mag alone at 2,100 rpm. Healthy: under the C-85's 75 (JOBS_ATA.md).
func mag_drops(job: Dictionary) -> Vector2i:
	var d := Vector2i(35, 50)
	var bad := func(id): return job.faults.has(id) and not job.fixed.has(id)
	if bad.call("spark_plugs"):
		d.x += 185  # plugs fouled on the left mag's side
	if bad.call("magneto"):
		d.x += 225
	if bad.call("ign_lead"):
		d.x += 160  # one dead plug on that mag
	if bad.call("hot_mag"):
		d.y = 0  # the mag never switches off, so switching to the other one alone costs nothing
	return d


## rpm lost when carb heat is pulled at 2,100: about 50 (Cub manual). None if the cable's broken.
func carb_drop(job: Dictionary) -> int:
	return 0 if job.faults.has("carb_heat") and not job.fixed.has("carb_heat") else 50


func _mag_line(job: Dictionary) -> String:
	var d := mag_drops(job)
	var say := func(n: int) -> String: return "no drop at all" if n == 0 else ("drops %d rpm and runs rough" % n if n > 75 else "drops %d" % n)
	return "Mag check at 2,100: left %s, right %s" % [say.call(d.x), say.call(d.y)]


## Climb in for a run-up: start it, 2,100 rpm, check each mag, shut down (ferry.gd, run-up mode).
func _start_runup() -> void:
	var job: Dictionary = current_job
	_aid_off("runup")  # the next run-up: the marks have had their try
	if job.get("parked", "apron") == "hangar":
		_say("Roll it out first. Never run an engine up inside the hangar.")
		return
	if job.faults.any(func(id): return id in ["door_pin", "pre_oil"] and not job.fixed.has(id)):
		_run_up()  # you can't get in, or mustn't crank it: found from outside
		return
	_close_panel()
	playlog("run-up start")
	player.frozen = true
	var before := plane.get_children()
	_build_gauges()
	ferry = Ferry.new()
	ferry.mode = "runup"
	ferry.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ferry)
	for id in ["battery", "starter"]:
		if job.faults.has(id) and not job.fixed.has(id):
			ferry.no_start = id
			break
	ferry.drops = mag_drops(job)
	ferry.carb_drop = carb_drop(job)
	ferry.radio_dead = job.faults.has("avionics") and not job.fixed.has("avionics")
	ferry.runup_done.connect(_runup_done)
	ferry.start(self, plane, visuals["propeller"].get_child(-1))
	_cockpit_extra = plane.get_children().filter(func(c): return not before.has(c))
	log_clear()
	log_line("Start it, bring it up to 2,100 rpm, check each mag and the carb heat.")


var _cockpit_extra: Array = []  # gauges and the seat camera, cleared when you climb out of a run-up


func _runup_done() -> void:
	for c in _cockpit_extra:
		if is_instance_valid(c):
			c.queue_free()
	_cockpit_extra = []
	gauges.clear()
	ferry.queue_free()
	ferry = null
	prompt.text = ""
	sound.engine = 0.0
	sound.stop_loop()
	player.cam.make_current()
	player.frozen = false
	_run_up()


## Taking the cowl off for one job, you find another behind it. You ring the owner, who pays for it.
func _found_hidden() -> void:
	var h: String = current_job.get("hidden", "")
	if h == "":
		return
	current_job.hidden = ""
	if current_job.faults.has(h):  # already on the work order
		return
	current_job.faults.append(h)
	current_job.found[h] = true
	var extra := int(round(FAULTS[h].cost * 1.2 / 50.0)) * 50
	current_job.reward += extra
	visuals[h].queue_free()
	visuals[h] = _part_visual(h, false)
	sound.chime()
	log_line("%s. You call %s, who okays the extra work: +$%d." % [HIDDEN_CLUES[h], current_job.get("owner", "the owner"), extra])
	_save_game()


## Supplies the job used: the owner pays for them at sign-off, at what they cost you. What went
## into undoing your own mistakes (damage you caused, taking apart a place with nothing wrong)
## is yours to pay.
func used_supply(scene: String, item: String, wasted: bool) -> void:
	var job: Dictionary = current_job
	if job == null or not SUPPLIES.has(item):
		return
	var unit: float = float(SUPPLIES[item].cost) / SUPPLIES[item].get("qty", 1)
	var mine: bool = wasted or job.get("caused", {}).has(scene)
	job.get_or_add("supplies", {"billed": 0.0, "mine": 0.0})["mine" if mine else "billed"] += unit


## Breaks what running with `cause` undone breaks: added found (no troubleshooting), or broken
## again if you'd already fixed it, so its part is bought and fitted a second time. Returns what
## you saw, or "" if it was broken already.
func _run_damage(job: Dictionary, cause: String) -> String:
	var hit: String = RUNUP_DAMAGE[cause][0]
	if job.faults.has(hit) and not job.fixed.has(hit):
		return ""
	if not job.faults.has(hit):
		job.faults.append(hit)
	job.fixed.erase(hit)
	job.work.erase(hit)  # a fresh repair, from the start
	job.get_or_add("caused", {})[hit] = true  # its supplies are on you
	if job == current_job:
		note_cost("runup_damage", 0.0, FAULTS[hit].cost, "%s, from running it unready" % FAULTS[hit].name)
		_aid_on("runup", true)  # the work order marks what else mustn't be run, until the next run-up
	job.found[hit] = true
	if visuals.has(hit):
		visuals[hit].queue_free()
		visuals[hit] = _part_visual(hit, false)
	var msg: String = RUNUP_DAMAGE[cause][1]
	return msg % (job.get("cyl", 0) + 1) if "%d" in msg else msg


## Below 20 F the whole engine needs warming, not just enough to fire (M-0 7-4.1).
func _preheat() -> void:
	_advance(0.15)
	if not current_job:
		return
	current_job.preheated = true
	_say("Engine cover on, the heater ducted in under it for a couple of hours. The oil's thin again.")
	_open_inspection(standing_at)


## Opens the 2D work scene for this fault: real tools, every screw and bolt (scripts/work.gd).
func _repair(id: String) -> void:
	playlog("repair start " + id)
	_open_work(id, func(): _work_done(id))


var _last_work: Array = []  # [scene, on_done] of the work scene last opened


# ---------- spots: every place you can work at one spot (opened up in scripts/bay.gd) ----------

var station_zone := ""  # the spot a work scene was opened from: Esc goes back there

## What each place at a spot is called: the place or the job, never the diagnosis.
const PLACES := {
	"propeller": "Prop hub & blades", "prop_dress": "Blade leading edges", "prop_track": "Track the blades", "prop_bolts": "Prop bolts",
	"spark_plugs": "Spark plugs", "oil_leak": "Rocker cover gaskets", "bird_nest": "Top of the engine", "starter": "Starter",
	"magneto": "Swap a magneto", "fuel_line": "Fuel line, firewall", "pre_oil": "Pre-oil", "spark_test": "Spark test",
	"cold_cylinder": "Cold cylinder check", "compression": "Compression test", "reading_plugs": "Read the plugs",
	"oil_screen": "Oil screen", "hot_mag": "Magneto P-leads", "fuel_vent": "Fuel cap vent", "water_fuel": "Sump the gascolator",
	"oil_change": "Change the oil", "fuel_strainer": "Fuel strainer", "exhaust_check": "Muffler & heat muff",
	"air_filter": "Air filter & carb heat", "mag_timing": "Magneto timing", "baffles": "Baffles & fins",
	"storage": "Depreserve the engine", "ign_lead": "Ignition leads", "stuck_valve": "Rocker arms & valves",
	"worn_rings": "Pull a cylinder", "relief_valve": "Oil relief valve", "fod": "Under the cowl",
	"tire": "Tire & tube", "bungee": "Shock cords", "brakes": "Brake shoes", "brake_bleed": "Bleed the brakes",
	"battery": "Battery", "windshield": "Windshield", "avionics": "Radio & antenna", "stale_fuel": "Fuel tank",
	"door_pin": "Door hinge pins", "wire_chafe": "Wiring behind the panel", "brake_master": "Brake master cylinders",
	"instrument_swap": "Tachometer", "primer_leak": "Primer", "compass": "Swing the compass", "pitot_static": "Pitot-static lines",
	"weight_balance": "Weigh it", "control_cables": "Rudder cables", "tailwheel": "Tailwheel", "elevator_cable": "Elevator cable",
	"trim_cable": "Trim cable", "brace_wires": "Tail tie rods", "tie_down": "Tie-downs", "aileron_rigging": "Aileron cables",
	"wing_rig": "Wing rigging", "fabric_test": "Fabric punch test",
}


## Every place at this spot: its work scenes and tests (the socket hunt only once there's a socket).
func station_places(zone: String) -> Array:
	var out := []
	for id in Work.scenes():
		var z: String = FAULTS[id].zone if FAULTS.has(id) else (TESTS[id].zone if TESTS.has(id) else "")
		if z == zone and PLACES.has(id) and (id != "fod" or current_job.faults.has("fod")):
			out.append(id)
	return out


## The shared engine cowling: on, and every screw tight.
func cowl_closed(job: Dictionary) -> bool:
	var c: Dictionary = job.work.get("_cowl", {})
	return c.get("cowl", "on") == "on" and range(6).all(func(k): return c.get("cowl_f%d" % k, "tight") == "tight")


func _open_station(zone: String) -> void:
	if not current_job.get("washed", true):
		_say("It's caked in grime and lichen. Wash it down first.")
		return
	if not current_job.checked.has(zone):
		_inspect_zone(zone)  # the first look comes first: it counts as checking the spot
		return
	_open_bay(zone)


# ---------- the engine bay (scripts/bay.gd) ----------

const Bay := preload("res://scripts/bay.gd")
const Tutorial := preload("res://scripts/tutorial.gd")
var tutorial  # scripts/tutorial.gd: the first three jobs, taught by doing them
## The apprenticeship's saved state (tutorial.gd): lesson 1-3 or 0, tour seen, steps done this
## lesson, rescues when it began, a reward still to show.
var tut := {"lesson": 0, "tour": true, "done": {}, "base": 0}
var bay_view := "cowled"  # where you were standing at the engine, so a job's Back returns there
var spot_view := {}  # the same at every other spot: zone -> view


func _open_bay(zone := "engine") -> void:
	tutorial.walk("bay")  # first time here: a walkthrough of this menu (tutorial.gd)
	standing_at = zone
	station_zone = zone
	_close_panel()
	var b = Bay.new()
	b.setup(self, zone)
	ui.add_child(b)
	panel = b
	panel_closable = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


## Look closer at one part: a visible fault whose tell is there gets written up.
func bay_look(part: Dictionary) -> void:
	var job: Dictionary = current_job
	_advance(0.005)
	if not current_job:
		return
	var seen: PackedStringArray = []
	for id in part.look:
		if job.faults.has(id) and not job.fixed.has(id) and _how(job, id) == "walk":
			if not job.found.has(id):
				job.found[id] = true
			seen.append(clue(id))
	_say(("%s: %s." % [part.name, "; ".join(seen)]) if seen.size() > 0 else "%s: looks fine." % part.name)
	_save_game()


## The shared engine cowl (work.gd keeps it in job.work._cowl): six screws out, swing it up.
func bay_open_cowl() -> bool:
	if not tools.has("screwdriver"):
		_say("The cowl's on Camloc fasteners: you need a screwdriver.")
		return false
	_advance(0.02)
	if not current_job:
		return false
	var c: Dictionary = current_job.work.get_or_add("_cowl", {})
	c["cowl"] = "off"
	for k in 6:
		c["cowl_f%d" % k] = "out"
	sound.sfx("tray")
	_save_game()
	return true


## Close it up: only once nothing is left apart under it. Returns why not, or "".
func bay_close_cowl() -> String:
	var c: Dictionary = current_job.work.get_or_add("_cowl", {})
	var apart: Array = c.get("apart", {}).keys().filter(func(k): return c.apart[k])
	if apart.size() > 0:
		return "Finish up at %s first: it's still apart under there." % PLACES.get(apart[0], apart[0]).to_lower()
	_advance(0.02)
	if not current_job:
		return "The owner gave up waiting."
	c["cowl"] = "on"
	for k in 6:
		c["cowl_f%d" % k] = "tight"
	sound.sfx("tray")
	_save_game()
	return ""


## A job or a test on a part, from the bay; Back comes home to the bay.
func bay_open_scene(scene: String, zone := "engine") -> void:
	station_zone = zone
	standing_at = zone
	if TESTS.has(scene):
		_run_test(scene)
	else:
		station_open(zone, scene)


## Opens one place from a station. A fault you can see is found by looking at it; one inside a
## part (a bad mag, a sticking valve) looks fine until a run-up or a test has found it.
func station_open(zone: String, id: String) -> void:
	var job: Dictionary = current_job
	standing_at = zone
	station_zone = zone
	if TESTS.has(id):
		_run_test(id)
		return
	if job.faults.has(id) and not job.found.has(id) and _how(job, id) == "walk":
		job.found[id] = true
		_save_game()
	_open_work(id, func(): _station_done(id))


func _station_done(id: String) -> void:
	var job: Dictionary = current_job
	if job.faults.has(id) and job.found.has(id) and not job.fixed.has(id):
		_work_done(id)


## After a job, a test or a call: back to the station you came from, else the work order.
func _back(zone: String) -> void:
	if station_zone != "":
		_open_station(station_zone)
	else:
		_open_inspection(zone)


# ---------- the service manual (scripts/manual.gd, data/c85_manual.json) ----------

const ManualUI := preload("res://scripts/manual.gd")
const PartsBook := preload("res://scripts/parts_book.gd")
var parts_book := PartsBook.new()
var manual_data := ManualUI.load_data("res://data/c85_manual.json")
var parts_data := ManualUI.load_data("res://data/c85_parts.json")
var _manual_back := false  # opened from a work scene: closing it goes back there


## The page for what you're working on: the scene in front of you, else the first open fault.
func _manual_job() -> String:
	if panel is Work:
		return panel.fault
	if current_job:
		for id in current_job.faults:
			var t := _test_for(current_job, id)
			if t != "" and current_job.get("sym", {}).has(id):
				return t
			if current_job.found.has(id) and not current_job.fixed.has(id):
				return id
	return ""


func _open_manual(job := "") -> void:
	tutorial.walk("manual")
	_manual_back = panel is Work
	var fresh := not (panel is ManualUI)
	if panel:  # keep the work scene's state; just put it away
		panel.queue_free()
		panel = null
	var m := ManualUI.new()
	m.setup(manual_data, sound.pen, job, parts_data)
	m.close_requested.connect(_close_manual)
	ui.add_child(m)
	panel = m
	panel_kind = "manual"
	panel_closable = true
	if fresh:
		m.fade_in()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


func _close_manual() -> void:
	_close_panel()
	if _manual_back and _last_work.size() == 2 and current_job:
		_open_work(_last_work[0], _last_work[1])
	_manual_back = false


## Any work scene: a repair, a troubleshooting test, or the hand-prop drill.
func _open_work(scene: String, on_done: Callable) -> void:
	tutorial.walk("work")
	_last_work = [scene, on_done]
	_close_panel()
	var w = Work.new()
	w.setup(self, scene, current_job)
	w.finished.connect(on_done)
	ui.add_child(w)
	panel = w
	panel_closable = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


## Time spent on one step of a job. False if the owner gave up meanwhile (the scene closes).
func _work_time(days: float) -> bool:
	_advance(days)
	if current_job:
		return true
	_close_panel()
	return false


func _work_done(id: String) -> void:
	playlog(("repair done " if current_job.faults.has(id) else "wrong guess, swapped ") + id)
	if not current_job.faults.has(id):  # a suspect that wasn't the trouble: the part and the time are spent
		note_cost("suspect", 0.0, FAULTS[id].cost, "A %s that wasn't the trouble" % FAULTS[id].part.to_lower())
		current_job.tried[id] = false
		current_job.runup = ""
		sound.pen()
		_say("Swapped the %s. Run it up again to see if that cured it." % FAULTS[id].part.to_lower())
		_open_inspection(FAULTS[id].zone)
		return
	if FAULTS[id].get("quiz", false) and not current_job.fixed.has(id):
		_quiz(id)  # the work's done; now the sum
		return
	current_job.fixed[id] = true
	if id in RUNUP_FAULTS:
		current_job.runup = ""  # a run-up after the work proves the fix
	if id == "stale_fuel":
		current_job.fuel = 1.0  # you refilled it with fresh 100LL
	if id == "brake_master" and not current_job.faults.has("brake_bleed"):  # new cylinder: now bleed it at the wheel
		current_job.faults.append("brake_bleed")
		current_job.found["brake_bleed"] = true
	_refresh_parts_table()
	if visuals.has(id):
		visuals[id].queue_free()
		visuals[id] = _part_visual(id, true)
	_say("Fixed: %s. %s" % [FAULTS[id].name, WHY.get(id, "")])
	sound.pen()  # signed off on the work order
	sound.done_tone()
	_banner("FIXED", FAULTS[id].name)
	_back(FAULTS[id].zone)


# ---------- troubleshooting ----------

## The test this fault is waiting on, or "" once it's found.
func _test_for(job: Dictionary, id: String) -> String:
	var chain: Array = job.get("diag", {}).get(id, [])
	var step: int = job.get("dstep", {}).get(id, 0)
	return chain[step] if step < chain.size() and not job.found.has(id) else ""


## Which fault a test is tracking down in this job ("" if none: then it reads healthy).
func _cause(test: String) -> String:
	if not current_job:
		return ""
	for id in current_job.faults:
		if _test_for(current_job, id) == test:
			return id
	return ""


func _answer(id: String, test: String) -> String:
	var k: String = TEST_KEY[test].get(id, "")
	if k == "@cyl":
		return "c%d" % current_job.get("cyl", 0)
	if k == "@valve":
		return current_job.get("valve", "exhaust")
	return k


func _diagnose(id: String) -> void:
	var t := _test_for(current_job, id)
	_open_work(t, func():
		current_job.get_or_add("dready", {})[id] = true
		_verdict(id))


## Hard: run whichever test you choose. If it's the next one for a symptom you've heard, it's the
## real thing; otherwise everything reads normal and you've spent the time.
func _run_test(t: String) -> void:
	var id := _cause(t)
	if id != "" and current_job.get("sym", {}).has(id):
		_diagnose(id)
		return
	_open_work(t, func():
		current_job.work.erase(t)  # nothing to keep: run it fresh next time
		_advance(0.05)
		if current_job:
			_say("Everything reads normal. That's not where the trouble is.")
			_back(standing_at))


## Hard: try to start it if it's never run; otherwise it's your signature on the logbook.
func _hard_take_off() -> void:
	if current_job.get("runup", "") != "ran":
		_run_up()
		return
	_start_ferry()


## What do you make of it? The right call moves you on; a wrong one costs time.
func _verdict(id: String) -> void:
	var t := _test_for(current_job, id)
	var rows: Array = [[TESTS[t].ask]]
	if verdict_aid(id):  # after a wrong call on this trail: the manual's page for the test, for the next try
		rows.append(["Not sure? The manual's page for the %s says what each reading means." % TESTS[t].name.to_lower(),
			"Open the manual (%s)" % key_name("manual"), func(): _open_manual(t), true])
	for o in TESTS[t].options:
		rows.append(["", o[0], func(): _call(id, o[1]), true])
	rows.append(["", "Look at it again", func(): _diagnose(id), true])
	_open_panel(TESTS[t].name, rows, true)


## Error-activated aids (E4), switched on by a mistake and gone after the next try: job.aid holds
## which are live. The cockpit's two (mag limits, rudder cue) live in ferry.gd.
func verdict_aid(id: String) -> bool:
	return current_job != null and current_job.get("aid", {}).get("verdict", "") == id


func _aid_on(kind: String, value) -> void:
	if current_job == null:
		return
	var aid: Dictionary = current_job.get_or_add("aid", {})
	if not aid.has(kind):
		playlog("aid: %s" % kind)
	aid[kind] = value


func _aid_off(kind: String) -> void:
	if current_job != null:
		current_job.get("aid", {}).erase(kind)


func _call(id: String, key: String) -> void:
	var job: Dictionary = current_job
	var t := _test_for(job, id)
	_aid_off("verdict")  # one try with the aid; a wrong call brings it back
	if key != _answer(id, t):
		_aid_on("verdict", id)
		note_cost("verdict", 0.05, 0, "A wrong call on the %s" % TESTS[t].name.to_lower())
		var misses: Dictionary = job.get_or_add("misses", {})
		misses[id] = misses.get(id, 0) + 1
		_advance(0.05)
		if not current_job:
			return
		_say("That doesn't square with what you saw. Look again.")
		_verdict(id)
		return
	job.get_or_add("dready", {}).erase(id)
	job.work.erase(t)
	var step: int = job.get_or_add("dstep", {}).get(id, 0) + 1
	job.dstep[id] = step
	if step >= job.diag[id].size():
		job.found[id] = true
		_say("That's it: %s." % FAULTS[id].name)
		sound.pen()
		if job.get("misses", {}).get(id, 0) == 0:
			earn_badge("detective")
	else:
		var why := "Its plugs are wet with oil" if t == "reading_plugs" else "It runs cold"
		job.get_or_add("dnote", {})[id] = "%s: cylinder %d. Next, a %s on it." % [why, job.get("cyl", 0) + 1, TESTS[job.diag[id][step]].name.to_lower()]
		_say(job.dnote[id])
	_save_game()
	_back(standing_at)


## A hot magneto fires the engine while you turn the prop by hand. Returns [message, days lost].
func turn_prop() -> Array:
	var job = current_job
	if job == null or not job.faults.has("hot_mag") or job.fixed.has("hot_mag") \
			or job.work.get("hot_mag", {}).get("plead", "") == "new" or rng.randf() > 0.5:
		return ["", 0.0]
	var first: bool = not job.found.has("hot_mag")
	job.found["hot_mag"] = true
	return ["It KICKED! The engine fired%s. The blade cracked your knuckles: half a day lost to a bandaged hand." %
		(" with the switch OFF: the mag is hot, its P-lead isn't grounding it" if first else " on the hot mag again"), 0.5]


## The test readings and painted states a work scene shows, worked out from this job.
func reading(scene: String, eid: String) -> String:
	var job: Dictionary = current_job if current_job else {}
	var cause := _cause(scene)
	var cyl: int = job.get("cyl", 0)
	match scene:
		"spark_test":
			var fire := _sparks(cause, eid == "turn2")
			if eid == "turn1":
				var dead := range(4).filter(func(i): return not fire[i])
				return "All four plugs spark." if dead.is_empty() else ("Not one plug sparks." if dead.size() == 4
					else "The %s plug doesn't spark; the rest do." % ", ".join(dead.map(func(i): return Work.SPARK_PLUGS[i])))
			return "Good plug on that lead: it sparks." if fire.all(func(f): return f) else "Good plug on that lead: still nothing."
		"cold_cylinder":
			if cause == "":
				return "Every mark melted: all four are firing."
			return "Every riser's mark melted but cylinder %d's. Cylinder %d isn't firing." % [cyl + 1, cyl + 1]
		"compression":
			var i := int(eid.substr(1))
			if cause == "" or i != cyl:
				return "Cylinder %d: 76/80. Healthy." % (i + 1)
			var place: String = {"exhaust": "the tailpipe", "intake": "the carb air scoop", "rings": "the oil filler"}[_answer(cause, "compression")]
			return "Cylinder %d: 48/80, and air hissing out at %s." % [i + 1, place]
		"reading_plugs":
			var c := int(eid.substr(1))
			var look: String = {"tan": "tan, light gray: healthy", "black": "dry black soot", "oily": "wet and oily", "eroded": "thin, worn electrodes"}[_plug_look(cause, c)]
			return "Cyl %d %s: %s" % [c + 1, "top" if eid[0] == "t" else "bottom", look]
		"oil_screen":
			var metal: String = {"cam_wear": "steel", "piston_scuff": "aluminum", "bronze_bushing": "bronze"}.get(cause, "")
			if eid == "rinse":
				return {"": "Sludge rinses off and the towel stays clean. The screen's fine.", "steel": "Gray slivers on the towel.",
					"aluminum": "Bright silvery flakes on the towel.", "bronze": "Gold-colored flakes on the towel."}[metal]
			return "They jump to the magnet: steel." if metal == "steel" else "Nothing sticks to the magnet."
		"water_fuel":
			return {"sump1": "Clear beads of water under the blue in the cup.", "sump2": "All blue now: no water."}[eid]
		"fuel_vent":
			return "Air whistles through: the vent's clear."
		"hot_mag":
			return "Switch OFF: no spark. The P-lead grounds the mag."
		"pre_oil":
			return "Oil pressure shows on the gauge: it's oiled through."
		"oil_change":
			return "A few fine flakes, nothing on the magnet: normal wear."
		"exhaust_check":
			return "Bubbles streaming from the seam: it's cracked through."
		"bungee":
			return "Green and red threads: made in a year ending 1 or 6, third quarter. Well past five years: replace them."
		"aileron_rigging", "elevator_cable":
			return {"tb_b": "Tensiometer reads 30 lb: in range (25-35, game value).",
				"sight": "Stick centered: trailing edges in line, two threads showing at each turnbuckle."}[eid]
		"wing_rig":
			return {"measure": "1-3/8 in under the string at the root. It wants 2-1/8.", "measure2": "2-1/8 in. Dihedral's right.",
				"washout": "Bubble off toward the trailing edge: the wash-out's wrong.", "rear": "Bubble centered."}[eid]
		"trim_cable":
			return "Tensiometer reads 15 lb: in range (12-18, game value). The crank turns the stabilizer, no slip."
		"brace_wires":
			return "Stabilizer level, threads showing through each nipple."
		"prop_dress":
			return "No crack under the etch. It's clean."
		"prop_track":
			return {"t1": "Blade 1 just touches the block.", "t2": "Blade 2 passes 3/16 in clear. The limit is 1/16.",
				"t3": "Within 1/32 in. In track."}[eid]
		"mag_timing":
			return {"tdc": "Pointer on 30 degrees before top center, #1 on compression.", "rotate": "The light comes on right at 30 degrees BTC. That's the left mag's number; the right one fires at 28."}[eid]
		"brake_bleed":
			return "Clear fluid, no bubbles in the jar. Pedal's firm."
		"storage":
			return {"tag": "Preserved 6 years ago: desiccant in the intake and exhaust, dehydrator plugs in. DO NOT TURN PROPELLER.",
				"turn": "Preservative oil spits out of the plug holes."}[eid]
		"compass":
			return {"n": "Facing north it reads 018.", "e": "Facing east it reads 097.", "s": "Facing south it reads 186: took out half, 183.",
				"w": "Facing west it reads 276: took out half, 273.", "swing": "Every 30 degrees, worst error 4. Under the 10 degree limit. Card filled in."}[eid]
		"pitot_static":
			return {"static1": "Lost 300 ft in a minute. The limit is 100.", "static2": "Lost 40 ft in a minute: good.",
				"pitot": "Held 150 knots, lost 3 in a minute: good."}[eid]
		"weight_balance":
			var wb: Dictionary = job.get("wb", {"l": 295, "r": 293, "t": 58})
			return {"l": "Left main: %d lb." % wb.l, "r": "Right main: %d lb." % wb.r,
				"t": "Tail: %d lb. Tail scale is 187.5 in behind the main axle." % wb.t}[eid]
		"wire_chafe":
			return "Wiggle test: the radio stays on."
		"fod":
			return "A 7/16 socket, wedged behind the number 3 baffle."
		"fabric_test":
			var i := int(eid.substr(1))
			if job.get("fabric_bad", -1) == i:
				return "Spot %d: it punched right through. This fabric's done." % (i + 1)
			return "Spot %d: in the green band. Good fabric." % (i + 1)
		"prop_bolts":
			return "A dark gap all round the hub seat: the wood's shrunk. Torque the six in a star."
		"brake_master":
			return ""
	return ""


func view_art(scene: String, eid: String) -> String:
	var job: Dictionary = current_job if current_job else {}
	var w: Dictionary = job.get("work", {}).get(scene, {})
	var cause := _cause(scene)
	var cyl: int = job.get("cyl", 0)
	match scene:
		"spark_test":
			var phase := "turn2" if w.get("turn2") == "done" else ("turn1" if w.get("turn1") == "done" else "")
			if phase == "" or w.get("replug") == "done":
				return ""
			return "work/spark_test_spark" if _sparks(cause, phase == "turn2")[int(eid.substr(5))] else ""
		"cold_cylinder":
			if w.get("pencil") != "done":
				return ""
			var melted: bool = w.get("run") == "done" and (cause == "" or Work.RISERS[int(eid.substr(4))][0] - 1 != cyl)
			return "work/cold_cylinder_" + ("melted" if melted else "mark")
		"compression":
			var last: String = w.get("_last", "")
			if not last.begins_with("p") or w.get("hose") != "on":
				return ""
			var bad: bool = cause != "" and int(last.substr(1)) == cyl
			if eid == "tester":
				return "work/compression_tester_" + ("low" if bad else "good")
			return "work/compression_hiss" if bad and eid == "hiss_" + _answer(cause, "compression") else ""
		"reading_plugs":
			return "work/reading_plugs_" + _plug_look(cause, int(eid.substr(1)))
		"oil_screen":
			var metal: String = {"cam_wear": "steel", "piston_scuff": "aluminum", "bronze_bushing": "bronze"}.get(cause, "")
			match eid:
				"screen":
					if w.get("pull") != "done" or w.get("back") == "done":
						return ""
					return "work/oil_screen_screen_" + ("clean" if w.get("rinse") == "done" else "dirty")
				"metal":
					return "work/oil_screen_metal_" + metal if metal != "" and w.get("rinse") == "done" else ""
				"magnet_v":
					return "work/oil_screen_magnet_" + ("steel" if metal == "steel" and w.get("magnet") == "done" else "bare")
		"water_fuel":
			return "work/water_fuel_cup_" + ("clean" if w.get("sump2") == "done" else "water")
		"oil_change":
			return "work/oil_change_stream" if w.get("plug") == "off" and w.get("pan") == "on" and w.get("drain") != "done" else ""
		"brake_bleed":
			if w.get("hose") != "on" and w.get("close") != "done":
				return ""
			return "work/brake_bleed_jar_" + ("clear" if w.get("close") == "done" else "bubbles")
		"aileron_rigging", "elevator_cable":
			return "work/aileron_rigging_tensio_" + ("set" if w.get("tb_b") == "done" else "slack")
		"mag_timing":
			return "work/mag_timing_light_" + ("on" if w.get("rotate") == "done" else "off")
		"prop_dress":
			var filed: bool = w.get("file") == "done"
			return ("work/prop_dress_dressed" if filed else "") if eid == "dressed" else ("" if filed else "work/prop_dress_nick")
		"prop_track":
			match eid:
				"blade":
					return "" if w.get("t1") != "done" else "work/prop_track_blade_" + ("b" if w.get("t2") == "done" and w.get("t3") != "done" else "a")
				"mark_a":
					return "work/prop_track_mark_a" if w.get("t1") == "done" else ""
				"mark_b":
					return "work/prop_track_mark_b" if w.get("t2") == "done" else ""
		"wing_rig":
			return "work/wing_rig_ruler" if w.get("string") == "on" else ""
		"fabric_test":
			var i := int(eid.substr(4))
			var tested: bool = w.get("t%d" % i) == "done"
			var bad: bool = job.get("fabric_bad", -1) == i
			if eid.begins_with("read"):
				return ("work/fabric_test_read_" + ("fail" if bad else "pass")) if tested else ""
			if not tested:
				return ""
			if w.get("s%d" % i) == "done":
				return "work/fabric_test_seal"
			return "work/fabric_test_" + ("hole" if bad else "dent")
		"prop_bolts":
			if eid == "hub":
				var tight: bool = range(6).all(func(k): return w.get("hub_f%d" % k) == "tight")
				return "work/prop_bolts_hub_" + ("new" if tight else "old")
			var torquing: bool = w.get("wire") == "off" and range(6).any(func(k): return w.get("hub_f%d" % k) == "snug")
			return "work/prop_bolts_order" if torquing else ""
	return ""


## Which of the four plugs spark: a dead mag fires none; a bad lead or plug kills one, and a
## good plug on that lead only fixes it if the plug was the problem.
func _sparks(cause: String, good_plug: bool) -> Array:
	var lead: int = current_job.get("lead", 0) if current_job else 0
	match cause:
		"magneto": return [false, false, false, false]
		"ign_lead": return range(4).map(func(i): return i != lead)
		"spark_plugs": return range(4).map(func(i): return good_plug or i != lead)
	return [true, true, true, true]


func _plug_look(cause: String, c: int) -> String:
	match cause:
		"spark_plugs": return "eroded"
		"primer_leak": return "black"
		"worn_rings": return "oily" if c == current_job.get("cyl", 0) else "tan"
	return "tan"


## A work-scene step just finished that the game reacts to.
func task_done(scene: String, eid: String) -> void:
	if scene == "fabric_test" and current_job and current_job.get("fabric_bad", -1) == int(eid.substr(1)):
		if not current_job.faults.has("fabric_rot"):  # punched through: the plane needs recovering
			current_job.faults.append("fabric_rot")
		current_job.found["fabric_rot"] = true


## Names and parts for the work-scene title and bench.
func scene_info(id: String) -> Dictionary:
	if FAULTS.has(id):
		return {"name": FAULTS[id].name, "part": FAULTS[id].part}
	if TESTS.has(id):
		return {"name": TESTS[id].name, "part": ""}
	return {"name": {"hand_prop": "Hand-propping it"}.get(id, id.capitalize()), "part": ""}


## Weight and balance: the work gives you three scale readings; the sum is yours.
func _quiz(id: String) -> void:
	var wb: Dictionary = current_job.wb
	var cg: float = wb.t * 187.5 / float(wb.l + wb.r + wb.t)
	if not wb.has("opts"):
		var o := [cg, cg * 1.2, cg * 0.8]
		o.shuffle()
		wb.opts = o
	var rows: Array = [["Empty weight %d lb. Datum: the main axle; the tail scale sits 187.5 in aft.\nWhere's the empty-weight CG?" % (wb.l + wb.r + wb.t)]]
	for v in wb.opts:
		rows.append(["", "%.1f in aft of the axle" % v, func():
			if absf(v - cg) < 0.01:
				current_job.fixed[id] = true
				_say("CG %.1f in aft of the axle. New weight and balance written up and signed." % cg)
				sound.pen()
				_open_inspection(FAULTS[id].zone)
			else:
				_advance(0.05)
				if current_job:
					_say("That doesn't balance. Moment is weight times arm; divide by the total.")
					_quiz(id), true])
	_open_panel("Weight and balance", rows, true)


## No field fix (prop strike, wrong fuel, metal in the oil): tell the owner, bill your time, move on.
func _ground_job() -> void:
	var job: Dictionary = current_job
	var fee := int(round((80 + job.reward * 0.15) / 10.0)) * 10
	money += fee
	var why: Array = job.faults.filter(func(id): return FAULTS[id].get("ground", false) and job.found.has(id))
	logbook.append({"day": floori(day), "city": job.city, "type": job.type, "pay": fee, "grounded": true,
		"work": why.map(func(id): return "Grounded: " + FAULTS[id].name), "years": job.get("years", 0),
		"fuel": job.spent.get("fuel", 0), "parts": job.spent.get("parts", 0), "days": day - job.get("arrived", day)})
	jobs.erase(job)
	current_job = null
	if plane:
		plane.queue_free()
		plane = null
	while jobs.size() < MAX_JOBS:
		_spawn_job()
	_say("Grounded the %s and told the owner straight. They paid $%d for the diagnosis." % [job.type, fee])
	sound.pen()
	_save_game()
	_open_travel()


func _buy(part: String, cost: int, mail := false) -> void:
	money -= cost
	inventory[part] = inventory.get(part, 0) + 1
	if current_job:
		_spend(current_job, "parts", cost)
	if mail:
		note_cost("mail", 1.0, cost - roundi(cost / 1.25), "%s by mail" % part)
		_advance(1.0)
		_say("The %s came on the morning mail truck." % part)
	_refresh_parts_table()
	_save_game()
	_open_shop()


## Climb in: the camera moves to the pilot's seat and ferry.gd runs the takeoff.
func _start_ferry() -> void:
	if not current_job.get("signed", false):
		_say("The logbook isn't signed. Write it up before this plane goes anywhere.")
		return
	playlog("ferry flight start")
	_close_panel()
	player.frozen = true
	env.sdfgi_enabled = false  # its light probes rebuild as the camera races along, which hitches the flight
	for c in plane.get_children():
		if c.has_meta("kind"):
			c.queue_free()  # inspection spots
	_build_gauges()
	ferry = Ferry.new()
	ferry.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ferry)
	ferry.finished.connect(_ferry_done)
	ferry.failed.connect(_flight_failed)
	var missed: Array = current_job.faults.filter(func(id): return not current_job.fixed.has(id) and TROUBLE.has(id))
	ferry.trouble = missed[0] if missed.size() > 0 else ""
	ferry.start(self, plane, visuals["propeller"].get_child(-1))
	log_clear()
	log_line("Run the checklist, then hold %s to start her up." % key_name("starter"))


## The Cub panel's four dial holes (probed: front face z=-0.202, y=1.382, r 0.044 m).
var gauges := {}


func _build_gauges() -> void:
	var at := func(x: float) -> Vector3: return Vector3(x, 1.382, -0.199)
	gauges.asi = Gauge.make(plane, at.call(-0.197), 0.044, func(g):
		g.title = "AIRSPEED MPH"; g.hi = 120.0; g.marks = 6; g.green = Vector2(45, 85))
	gauges.alt = Gauge.make(plane, at.call(-0.091), 0.044, func(g):
		g.title = "ALT x100"; g.hi = 1000.0; g.marks = 10; g.full_turn = true)
	gauges.tach = Gauge.make(plane, at.call(0.104), 0.044, func(g):
		g.title = "RPM x100"; g.hi = 3000.0; g.marks = 6; g.label_scale = 0.01; g.green = Vector2(2100, 2350))
	gauges.oil = Gauge.make(plane, at.call(0.197), 0.044, func(g):
		g.title = "OIL PSI"; g.hi = 100.0; g.marks = 5; g.green = Vector2(30, 60))


## Ferry flight feeds the dials every frame.
func update_gauges(speed_ms: float, alt_m: float, rpm: float) -> void:
	if gauges.is_empty():
		return
	gauges.asi.value = speed_ms * 2.237
	gauges.alt.value = alt_m * 3.281
	gauges.tach.value = rpm
	gauges.oil.value = 0.0 if rpm < 300.0 else 25.0 + rpm / 2300.0 * 35.0


func _ferry_done() -> void:
	_apply_graphics()
	gauges.clear()
	ferry.queue_free()
	ferry = null
	prompt.text = ""
	player.cam.make_current()
	player.frozen = false
	_sign_off()
	plane.queue_free()  # flown off to its owner
	plane = null
	if _pending_debrief.is_empty() or rescued == GOAL:  # the card says RESCUED itself (D3); the ending has no card
		_banner("RESCUED", "%d of %d planes back in the air" % [rescued, GOAL])
	_after_flight()


## The aircraft logbook entry: what was done, in your words, over your signature.
## A maintenance record has to say what was done, to what data, and who did it (14 CFR 43.9).
## You build it a line at a time; an inspector would hand back a wrong one, and so does this.
const ENTRY_STEPS := [
	["Done in accordance with", [["AC 43.13-1B and the manufacturer's data", ""],
		["The owner's say-so", "The owner can't approve the method. Work is done to approved or acceptable data, like AC 43.13-1B."],
		["How I've always done it", "Memory isn't data. Cite what you worked to, like AC 43.13-1B or the manual."]]],
	["Signed by", [["You, with your mechanic certificate type and number", ""],
		["Just your signature", "The entry needs your certificate type and number as well as your signature."],
		["The owner, since it's their plane", "The person who did the work signs for it. That's you."]]],
]


func _open_signoff(step := 0) -> void:
	if step == 0:
		tutorial.walk("signoff")
	if step == 0:
		playlog("logbook entry")
	var job: Dictionary = current_job
	var work: PackedStringArray = []
	for id in job.faults:
		if job.fixed.has(id):
			work.append(FAULTS[id].name)
	var rows := [["%s, at %s, day %d" % [job.type, job.city, floori(day)]],
		["Work performed\n" + (", ".join(work) if work.size() > 0 else "Inspection only, no defects found.") + ". Ground run-up satisfactory."]]
	if step < ENTRY_STEPS.size():
		var s: Array = ENTRY_STEPS[step]
		rows.append([s[0] + "..."])
		if entry_hint(step) != "":  # after an entry was sent back: the rule, for the next pick
			rows.append(["What the inspector wants\n" + entry_hint(step)])
		var picks: Array = s[1].duplicate()
		picks.sort_custom(func(a, b): return a[0] < b[0])  # alphabetical: the right one isn't always first
		for p in picks:
			rows.append([p[0], "Write this", func(): _entry_pick(step, p[1]), true])
	else:
		rows.append(["In accordance with AC 43.13-1B and the manufacturer's data. Approved for return to service.\nSigned, mechanic certificate type and number.", "Sign it", _sign_logbook, true])
	_open_panel("Aircraft logbook", rows)


## What an inspector wants at each step of the entry: the rule, not the option (E4).
const ENTRY_HINTS := [
	"The data you worked to: approved or acceptable data, such as an advisory circular or the maker's manual. Not a person, not habit.",
	"Who signs: the person who did the work, with the type and number of their certificate.",
]


func entry_hint(step: int) -> String:
	return ENTRY_HINTS[step] if current_job != null and current_job.get("aid", {}).get("entry", -1) == step and step < ENTRY_HINTS.size() else ""


func _entry_pick(step: int, wrong: String) -> void:
	_aid_off("entry")
	if wrong != "":
		_aid_on("entry", step)
		note_cost("entry", 0.0, 0, "A logbook entry sent back")
		sound.sfx("deny")
		_say("An inspector would hand that back. " + wrong)
		_open_signoff(step)
		return
	sound.pen()
	_open_signoff(step + 1)


func _sign_logbook() -> void:
	current_job.signed = true
	if not current_job.get("lost", []).any(func(l): return l.kind == "entry"):
		earn_badge("by_the_book")
	sound.pen()
	_save_game()
	_open_inspection()
	_banner("SIGNED OFF", "Approved for return to service")


## The fault you never found caught up with you. Down safely: it costs a day and a quarter of
## the pay, and the job reopens. Crashed: the job and the excess are gone, and you walk away.
func _flight_failed(result: String) -> void:
	var id: String = ferry.trouble
	playlog("ferry flight %s, cause %s" % [result, id])
	var job: Dictionary = current_job
	_apply_graphics()
	gauges.clear()
	ferry.queue_free()
	ferry = null
	prompt.text = ""
	sound.engine = 0.0
	player.cam.make_current()
	player.frozen = false
	var hill := id == ""  # nothing failed: you flew it into rising ground
	var what: String = "Flew into rising ground" if hill else FAULTS[id].name
	var missed := "What happened\nThe land climbs away from the strip, and you stayed too low to clear it." if hill \
		else "What you missed\n%s, at the %s. %s" % [what, ZONES[FAULTS[id].zone].name,
			"You looked there, and looked right past it." if job.checked.has(FAULTS[id].zone) else "You never looked there."]
	if result == "crash":
		var bill := mini(money, CRASH_BILL)
		money -= bill
		var spent: Dictionary = job.get("spent", {})
		logbook.append({"day": floori(day), "city": job.city, "type": job.type, "pay": 0, "work": ["Crashed on the ferry flight: " + what],
			"years": job.get("years", 0), "fuel": spent.get("fuel", 0), "parts": spent.get("parts", 0), "days": day - job.get("arrived", day)})
		jobs.erase(job)
		_load_field(location, null)
		while jobs.size() < MAX_JOBS:
			_spawn_job()
		_save_game()
		sound.low_tone()
		_open_panel("Crashed", [["You walked away. The %s didn't.\nHit too hard, or stalled on the way down." % job.type], [missed],
			["What it cost\nThe job, and $%d insurance excess. It's in your logbook." % bill],
			["Next time\n" + ("Hold the Down arrow after lift-off and keep climbing until you're clear." if hill
				else "Check every spot before you sign. If the engine quits, Up arrow lowers the nose: keep above 45 kt, then Down arrow to flare.")]])
		return
	var was: int = job.reward
	job.reward = int(job.reward * 0.75 / 50.0) * 50
	job.found[id] = true
	job.checked[FAULTS[id].zone] = true
	job.signed = false
	_load_field(location, job)
	_advance(1.0)  # towing it back and explaining yourself to the owner
	if not current_job:  # that day was the last of the owner's patience
		return
	_save_game()
	_open_panel("Aborted take-off" if result == "abort" else "Forced landing", [["You got it down safely, and it's back at the field.\nA day lost getting it home."], [missed],
		["What it cost\nThe owner knocked the pay from $%d to $%d." % [was, job.reward]],
		["Next\nFix it, then sign the logbook again."]])


## Called when the ferry flight gets the plane airborne.
func _sign_off() -> void:
	var job: Dictionary = current_job
	playlog("delivered, paid $%d" % job.reward)
	# Hard lets you sign off with work open. The owner's next mechanic finds it: a comeback.
	var missed: Array = job.faults.filter(func(id): return not job.fixed.has(id))
	var pay: int = job.reward
	for id in missed:
		pay -= FAULTS[id].cost * 2 + 200
	var open_cowl := not cowl_closed(job)
	if open_cowl:
		pay -= 200  # flew it off with the cowling loose
	if missed.any(func(id): return FAULTS[id].get("ground", false)):
		pay = 0  # flew off with metal in the oil or a struck prop
	pay = maxi(0, pay)
	var supplies: int = roundi(job.get("supplies", {}).get("billed", 0.0))  # the owner pays for what the job used
	pay += supplies
	_quiet_money = true
	money += pay
	_quiet_money = false
	rescued += 1
	jobs.erase(job)
	current_job = null
	var spent: Dictionary = job.get("spent", {})
	logbook.append({"day": floori(day), "city": job.city, "type": job.type, "reg": registration(job), "pay": pay, "supplies": supplies, "owner": job.get("owner", "The owner"),
		"work": job.faults.map(func(id): return ("Comeback: " if id in missed else "") + FAULTS[id].name), "years": job.get("years", 0),
		"fuel": spent.get("fuel", 0), "parts": spent.get("parts", 0), "days": day - job.get("arrived", day)})
	var found_later: Array = missed.map(func(id): return FAULTS[id].name.to_lower())
	if open_cowl:
		found_later.append("the engine cowling not screwed down")
	logbook[-1]["debrief"] = job_debrief(job, pay, missed, open_cowl)
	_pending_debrief = logbook[-1]
	if job.get("checked", {}).size() >= ZONES.size() and missed.is_empty():
		earn_badge("sharp_eyes")
	if logbook[-1].debrief.extra.is_empty():
		earn_badge("clean_job")
	_check_promotion()
	# The owner's words go on the end-of-mission card (D3), not across the top of the screen.
	if found_later.is_empty():
		logbook[-1].debrief["said"] = "%s: \"%s\"%s" % [job.get("owner", "The owner"), THANKS[rng.randi() % THANKS.size()],
			("  The pay includes $%d of supplies." % supplies) if supplies > 0 else ""]
	else:
		logbook[-1].debrief["said"] = "A comeback: the owner's next mechanic found %s. Owner paid $%d of $%d." % [", ".join(found_later), pay, job.reward]
	var earlier := logbook.filter(func(e): return e.pay > 0 and e.has("owner") and e.city != job.city)
	if earlier.size() > 0 and rng.randf() < 0.4:  # now and then, word from a plane you saved before
		var e: Dictionary = earlier[rng.randi() % earlier.size()]
		var news := "Radio: %s in %s says the %s flew %d hours this season, not a squawk." % [e.owner, e.city, e.type, rng.randi_range(12, 60)]
		get_tree().create_timer(9.0).timeout.connect(func(): if is_node_ready(): log_line(news))
	if tutorial.rescued_one():  # a lesson done: the calls on the map become the next lesson's
		jobs.clear()
	while jobs.size() < MAX_JOBS:
		_spawn_job()
	sound.chime()  # a new call on the radio
	_save_game()


func _after_flight() -> void:
	if rescued == GOAL:
		_open_ending()  # the tenth plane's debrief is in the logbook
	elif not _pending_debrief.is_empty():
		_open_debrief()
	else:
		_open_travel()


# ---------- the debrief (E5): what a job took, what cost extra, and what to do next time ----------

var _pending_debrief := {}  # the logbook entry just made, shown once after the flight

## One line for next time, for the kind of thing that cost the most.
const DEBRIEF_ADVICE := {
	"mag_call": "Read each drop against the limit: more than 75 rpm is bad, and no drop at all is bad too.",
	"verdict": "Let the test decide: read the result against the manual page before you make the call.",
	"entry": "Write what you worked to: AC 43.13-1B and the manufacturer's data. Not memory, not the owner's say-so.",
	"mail": "Check the town's shed before you fly out, and carry the parts every plane seems to need.",
	"suspect": "Two suspects? Run the test that tells them apart before you buy the part.",
	"runup_damage": "Finish the don't-run-it-yet work before the engine turns a single time.",
	"wasted": "Use supplies where something's wrong: on a sound part they come out of your pocket.",
	"comeback": "Check every spot before you sign. What you don't look at comes back.",
	"open_cowl": "Close the cowl and screw it down before you sign the logbook.",
}


## The debrief for a delivered job: pay, costs and net (rent included), what cost extra with its
## money, and the advice for whatever cost the most. Time is weighed for the advice but never shown:
## Thad found the day and hour figures added nothing (D1). Kept in the logbook entry.
func job_debrief(job: Dictionary, pay: int, missed: Array, open_cowl: bool) -> Dictionary:
	var spent: Dictionary = job.get("spent", {})
	var days: float = day - job.get("arrived", day)
	var lost: Array = job.get("lost", []).duplicate(true)
	var wasted: int = roundi(job.get("supplies", {}).get("mine", 0.0))
	if wasted > 0:
		lost.append({"kind": "wasted", "days": 0.0, "money": wasted, "what": "Supplies used where nothing was wrong"})
	for id in missed:
		lost.append({"kind": "comeback", "days": 0.0, "money": FAULTS[id].cost * 2 + 200, "what": "Comeback: %s" % FAULTS[id].name.to_lower()})
	if open_cowl:
		lost.append({"kind": "open_cowl", "days": 0.0, "money": 200, "what": "Flew off with the cowl loose"})
	var extra: PackedStringArray = []
	var weight := {}
	for l in lost:
		extra.append("%s  ($%d)" % [l.what, l.money] if l.money > 0 else String(l.what))  # time isn't shown (D1)
		weight[l.kind] = weight.get(l.kind, 0.0) + l.money + l.days * DAILY_COST + 1.0  # a do-over still counts
	var worst := ""
	for k in weight:
		if worst == "" or weight[k] > weight[worst]:
			worst = k
	var rent := roundi(days * DAILY_COST)
	return {"days": days, "pay": pay, "fuel": spent.get("fuel", 0), "parts": spent.get("parts", 0), "rent": rent,
		"net": pay - spent.get("fuel", 0) - spent.get("parts", 0) - rent, "extra": extra,
		"badges": job.get("earned_badges", []).duplicate(), "promoted": job.get("earned_promoted", []).duplicate(),
		"checked": job.get("checked", {}).size(), "fixed": job.get("fixed", {}).size(), "faults": job.faults.size(),
		"next": DEBRIEF_ADVICE.get(worst, "") if worst != "" else "Clean job: nothing cost you extra. Do it like that again."}


## The debrief's extra-cost lines as shown, with any time figure taken out: entries saved before D1
## carry "(0.4 days, $120)" or "(3 h)"; the money stays, a time-only cost shows bare.
func debrief_lines(d: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var rx := RegEx.create_from_string("\\s*\\(([^()]*)\\)$")
	for line in d.get("extra", []):
		var s := String(line)
		var m := rx.search(s)
		if m and Array(m.get_string(1).split(",")).all(func(x: String) -> bool: return _cost_word(x.strip_edges())):
			var keep: PackedStringArray = []
			for part in m.get_string(1).split(","):
				var p := part.strip_edges()
				if p.begins_with("$"):
					keep.append(p)
			s = s.substr(0, m.get_start()) + ("  (%s)" % ", ".join(keep) if keep.size() > 0 else "")
		out.append(s)
	return out


## Whether a word in a debrief line's brackets is a cost this code wrote ("$120", "0.4 days", "3 h",
## "a do-over"), so a part's own brackets ("Gasket assortment (10)") are never touched.
func _cost_word(w: String) -> bool:
	return w.begins_with("$") or w == "a do-over" or RegEx.create_from_string("^[0-9.]+ (h|days?)$").search(w) != null


func _open_debrief() -> void:
	var e: Dictionary = _pending_debrief
	_pending_debrief = {}
	if is_instance_valid(_banner_node):
		_banner_node.queue_free()  # the card says RESCUED itself
	_open_mission_card(e)


## Each city's station: its airport's ICAO identifier (the city's primary airport; FAA Order JO
## 7350 location identifiers with the K prefix of the contiguous US).
const STATIONS := {
	"Wichita": "KICT", "Omaha": "KOMA", "Dallas": "KDAL", "Chicago": "KMDW", "Billings": "KBIL",
	"Miami": "KMIA", "New York": "KJFK", "Seattle": "KBFI", "Portland": "KPDX", "Atlanta": "KATL",
	"Nashville": "KBNA", "Bangor": "KBGR", "Los Angeles": "KLAX", "Phoenix": "KPHX", "Las Vegas": "KLAS",
	"Albuquerque": "KABQ", "Denver": "KDEN", "Salt Lake City": "KSLC", "Fargo": "KFAR", "Minneapolis": "KMSP",
}


func station_code(city: String) -> String:
	return STATIONS.get(city, city.to_upper())


## A US registration in the 14 CFR 47.15 format: N, then one to five characters, the first a digit
## 1-9, up to two letters at the end, never I or O (they read as 1 and 0). Made when the call comes in
## and saved on the job and its logbook entry; a job or entry from an older save gets one worked out
## from what it is, so it reads the same every time.
func registration(job: Dictionary) -> String:
	if job.has("reg"):
		return job.reg
	var r := RandomNumberGenerator.new()
	r.seed = hash("%s|%s|%s" % [job.get("city", ""), job.get("type", ""), job.get("day", job.get("deadline", 0))])
	return make_registration(r)


static func make_registration(r: RandomNumberGenerator) -> String:
	const LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ"
	var letters := r.randi_range(0, 2)
	var n := "N%d" % r.randi_range(1, 9)
	for i in (r.randi_range(2, 3) if letters < 2 else 2):
		n += str(r.randi_range(0, 9))
	for i in letters:
		n += LETTERS[r.randi_range(0, LETTERS.length() - 1)]
	return n


## The end-of-mission card (D3): centred, on frosted earth glass with the scene showing through.
## Money as a column of signed figures, gains green and losses red (the sign says it without the
## colour); what cost extra; the job's stats; the badges and promotion it earned; the advice.
func _open_mission_card(e: Dictionary) -> void:
	_close_panel()
	panel_closable = true
	_list_title = "Debrief"
	_paper_sheet = false
	var d: Dictionary = e.debrief
	var card := PanelContainer.new()
	card.name = "MissionCard"
	panel = card
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.custom_minimum_size.x = 600
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_GLASS
	sb.set_corner_radius_all(Style.RADIUS_MD * 2)
	sb.set_border_width_all(1)
	sb.border_width_top = 2
	sb.border_color = Style.COLOR_GLASS_EDGE
	sb.anti_aliasing = true
	sb.set_content_margin_all(Style.SPACE_6)
	sb.content_margin_left = Style.SPACE_8
	sb.content_margin_right = Style.SPACE_8
	card.add_theme_stylebox_override("panel", sb)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/glass.gdshader")
	card.material = mat
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", Style.SPACE_2)
	card.add_child(vb)
	var shine := ColorRect.new()  # the lit top edge
	shine.color = Style.COLOR_GLASS_SHINE
	shine.custom_minimum_size.y = 1
	vb.add_child(shine)
	# Laid out like a ticket (Thad): station and registration top left, the line items with their
	# figures down the right, the achievements, and the total added up at the bottom.
	var head := HBoxContainer.new()
	vb.add_child(head)
	var ids := VBoxContainer.new()
	ids.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ids.add_theme_constant_override("separation", 0)
	head.add_child(ids)
	ids.add_child(_card_heading("Station"))
	var station := Style.label("%s  %s" % [station_code(e.city), e.city.to_upper()], "hud", Style.SIZE_LG, 800)
	station.name = "Station"
	ids.add_child(station)
	ids.add_child(_card_heading("Registration"))
	var reg := Style.label(registration(e), "hud", Style.SIZE_XL)
	reg.name = "Registration"
	reg.add_theme_font_override("font", Style.figures(true))
	ids.add_child(reg)
	# The job's stats, top right beside the registration: they're about the plane, not the money.
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 0)
	head.add_child(side)
	var tally := Style.label("DEBRIEF\n%d of %d RESCUED" % [rescued, GOAL], "hud_muted", Style.SIZE_SM, 800)
	tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	side.add_child(tally)
	_card_stat(side, "Spots checked", "%d of %d" % [d.get("checked", 0), ZONES.size()])
	_card_stat(side, "Faults fixed", "%d of %d" % [d.get("fixed", 0), d.get("faults", 0)])
	if d.get("said", "") != "":
		var said := Style.label(d.said, "loss" if String(d.said).begins_with("A comeback") else "hud_muted", Style.SIZE_SM)
		said.name = "Said"
		said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		said.custom_minimum_size.x = 536
		vb.add_child(said)
	var lesson: Dictionary = tutorial.reward_summary(int(tut.reward)) if tut.has("reward") else {}
	if not lesson.is_empty():  # a lesson's sign-off lives on the ticket too, not on a card of its own
		var lt := Style.label(lesson.title.to_upper(), "gain", Style.SIZE_LG, 800)
		lt.name = "Lesson"
		vb.add_child(lt)
		var ll := Style.label("%s %s" % [lesson.learned, lesson.line], "hud", Style.SIZE_SM)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size.x = 536
		vb.add_child(ll)
	vb.add_child(_glass_rule())
	# The line items, signed. The total below is these added up, nothing else.
	var bonus := int(d.get("bonus", 0))
	_card_figure(vb, "Paid by the owner", d.pay)
	if bonus > 0:
		_card_figure(vb, "Apprenticeship bonus", bonus)
	_card_figure(vb, "Fuel", -int(d.fuel))
	_card_figure(vb, "Parts", -int(d.parts))
	_card_figure(vb, "Hangar rent", -int(d.rent))
	# What cost extra is already in the figures above (a comeback cut the pay, a mail order raised
	# the parts): listed so you can see why, not added again.
	var lines := debrief_lines(d)
	if not lines.is_empty():
		vb.add_child(_card_heading("Cost you extra (in the figures above)"))
	const MAX_SHOWN := 3  # the ticket fits a 720 px window; the logbook keeps the full list
	for i in mini(lines.size(), MAX_SHOWN):
		var what: String = lines[i]
		var amt := 0
		var m := RegEx.create_from_string("\\s*\\(\\$([0-9]+)\\)$").search(what)
		if m:  # the dollars ride at the end of the line: "Gasket kit by mail  ($30)"
			amt = int(m.get_string(1))
			what = what.substr(0, m.get_start())
		_card_figure(vb, "- " + what if amt == 0 else what, -amt, false, "loss", true)
	if lines.size() > MAX_SHOWN:
		vb.add_child(Style.label("and %d more, in your logbook" % (lines.size() - MAX_SHOWN), "hud_muted", Style.SIZE_SM))
	vb.add_child(_card_heading("Achievements"))
	var got: Array = d.get("badges", [])
	var ach := HFlowContainer.new()
	ach.name = "Achievements"
	ach.add_theme_constant_override("h_separation", Style.SPACE_4)
	vb.add_child(ach)
	for r in d.get("promoted", []):
		ach.add_child(_card_award("hud/badge.svg", "Promoted: " + rank_title(r)))
	for id in got:
		ach.add_child(_card_award("hud/badge.svg", badge_name(id)))
	if lesson.get("gift", "") != "":
		var gift := _card_award("hud/badge.svg", "Gift: " + lesson.gift)
		gift.name = "Gift"  # not an earned badge: the badge count leaves it out
		ach.add_child(gift)
	if got.is_empty() and d.get("promoted", []).is_empty() and lesson.get("gift", "") == "":
		ach.add_child(Style.label("No new badges on this job. %d of %d earned." % [badges.size(), BADGES.size()], "hud_muted", Style.SIZE_SM))
	# The total, like the foot of a ticket: a double rule, then the sum.
	vb.add_child(_glass_rule())
	vb.add_child(_glass_rule())
	var total := int(d.net) + bonus
	_card_figure(vb, "Total", total, true)
	vb.get_child(vb.get_child_count() - 1).name = "Total"
	vb.add_child(_glass_rule())
	var advice := Style.label("Next time: " + d.next, "hud", Style.SIZE_MD)
	advice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	advice.custom_minimum_size.x = 536
	vb.add_child(advice)
	vb.add_child(Style.label(form_line(), "hud_muted", Style.SIZE_SM))
	var go := Button.new()
	go.text = "On to the next call"
	Style.button(go, "primary")
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go.custom_minimum_size = Vector2(240, 46)
	go.pressed.connect(sound.sfx.bind("thread"))
	go.pressed.connect(_open_travel)
	vb.add_child(go)
	ui.add_child(card)
	if not lesson.is_empty():  # seen on the ticket, however it closes: the lesson's own card is done with
		card.tree_exiting.connect(tutorial._close_reward)
	go.grab_focus.call_deferred()
	card.modulate.a = 0.0
	_fit_card.call_deferred(card)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


## True while the end-of-mission ticket is up (the lesson's own sign-off card waits for it).
func ticket_open() -> bool:
	return panel != null and is_instance_valid(panel) and panel.name == "MissionCard"


## Size, centre and fit the card: its own size, centred in the window, scaled down about its centre
## if the window is too small for it. Run again whenever its contents change size, since wrapped
## text first lays out far too tall and settles a frame later.
func _place_card(card: Control) -> void:
	if not is_instance_valid(card):
		return
	var vp := get_viewport().get_visible_rect().size
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.size = card.get_combined_minimum_size()
	card.position = ((vp - card.size) / 2.0).round()
	card.pivot_offset = card.size / 2.0
	var k := minf(1.0, minf((vp.y - 24.0) / card.size.y, (vp.x - 24.0) / card.size.x))
	card.scale = Vector2(k, k)


func _fit_card(card: Control) -> void:
	if not is_instance_valid(card):
		return
	card.minimum_size_changed.connect(_place_card.bind(card))
	_place_card(card)
	card.create_tween().tween_property(card, "modulate:a", 1.0, Style.MOTION_BASE)


## One money row on the card: words left, the signed figure right in Courier Prime, green for a
## gain and red for a loss, a zero in brass. The sign is always printed, so colour never stands alone.
func _card_figure(box: Control, what: String, amount: int, big := false, force_role := "", small := false) -> void:
	var row := HBoxContainer.new()
	row.name = "Figure"
	box.add_child(row)
	var l := Style.label(what, "hud", Style.SIZE_LG if big else Style.SIZE_SM if small else Style.SIZE_MD, 800 if big else 600)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 390  # wrapped text with no width yet lays out thousands of px tall
	row.add_child(l)
	var role := force_role if force_role != "" else ("gain" if amount > 0 else "loss" if amount < 0 else "hud_muted")
	var fig := Style.label("" if amount == 0 and force_role == "loss" else ("%s$%s" % ["+" if amount > 0 else "-" if amount < 0 else "", _thousands(absi(amount))]), role)
	fig.name = role
	fig.add_theme_font_override("font", Style.figures(true))
	fig.add_theme_font_size_override("font_size", Style.SIZE_XL if big else Style.SIZE_SM if small else Style.SIZE_MD)
	fig.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fig.custom_minimum_size.x = 130
	row.add_child(fig)
	if force_role == "loss":
		l.add_theme_color_override("font_color", Style.COLOR_TEXT_LOSS)


## A stat line on the ticket: words left, the figure right, in brass (no sign: it isn't money).
func _card_stat(box: Control, what: String, value: String) -> void:
	var row := HBoxContainer.new()
	box.add_child(row)
	row.add_theme_constant_override("separation", Style.SPACE_3)
	var l := Style.label(what, "hud_muted", Style.SIZE_SM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(l)
	var v := Style.label(value, "hud", Style.SIZE_SM)
	v.add_theme_font_override("font", Style.figures(true))
	row.add_child(v)


func _card_heading(text: String) -> Label:
	var l := Style.label(text.to_upper(), "hud_muted", Style.SIZE_SM, 800)
	l.add_theme_font_override("font", Style.caps(800, Style.SIZE_SM))
	return l


func _glass_rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Style.COLOR_GLASS_EDGE
	r.custom_minimum_size.y = 1
	return r


func _card_award(icon: String, text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "Award"
	h.add_theme_constant_override("separation", Style.SPACE_2)
	var t := TextureRect.new()
	t.texture = load("res://textures/" + icon)
	t.custom_minimum_size = Vector2(26, 26)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(t)
	var l := Style.label(text, "gain", Style.SIZE_MD, 800)
	l.name = "gain"
	h.add_child(l)
	return h


func _career_stats() -> Array:
	var paid := 0
	var costs := 0
	var longest := 0
	for e in logbook:
		paid += e.pay
		costs += e.get("fuel", 0) + e.get("parts", 0)
		longest = maxi(longest, e.get("years", 0))
	var rows := [["Days on the road\n%d" % floori(day)], ["Earned\n$%d, with $%d spent on fuel and parts" % [paid, costs]], ["Cash in hand\n$%d" % money]]
	if longest > 0:
		rows.append(["Longest neglected\nA plane that sat %d years" % longest])
	return rows


func _open_ending() -> void:
	sound.done_tone()
	_open_panel("All %d planes rescued" % GOAL, [["Every one of them flew out on your signature. Somewhere a hangar door stands open, and a field is a little less quiet."]]
		+ _career_stats() + [["", "Keep flying", _open_travel, true], ["", "Main menu", _quit_to_title, true], ["", "Start a new career", _restart, true]], false)


func _open_game_over(cheapest: int) -> void:
	sound.low_tone()
	_open_panel("Out of money and grounded", [["You rescued %d of %d planes\nThat work still counts: every one is in your logbook." % [rescued, GOAL]],
		["What happened\nYou have $%d. The cheapest flight to a call costs $%d, and you can't afford to finish the job here." % [money, cheapest]],
		["Next time\nKeep enough cash back to fly to the next call, and check the parts bill before you take a job."]]
		+ _career_stats() + [["Odd jobs at the field here: %d days, +$%d" % [ODD_JOB_DAYS, ODD_JOB_PAY], "Take it", _odd_jobs, true],
		["", "Start over", _restart, true], ["", "Main menu", _quit_to_title, true]], false)


const ODD_JOB_DAYS := 3
const ODD_JOB_PAY := 900  # covers the nearest call (under $600) with some left for parts


## Broke is a setback, not the end: fuel planes and mow the strip for a few days. Calls may expire meanwhile.
func _odd_jobs() -> void:
	_close_panel()
	money += ODD_JOB_PAY
	_money_pop(ODD_JOB_PAY)
	_advance(ODD_JOB_DAYS)
	_say("%d days fueling planes and mowing the strip at %s. It pays the bills." % [ODD_JOB_DAYS, location])
	playlog("broke: took odd jobs")


func _can_finish_here() -> bool:
	if current_job == null:
		return false
	var need := 0
	var tools_needed := {}
	var mats_needed := {}
	for id in current_job.faults:
		var f: Dictionary = FAULTS[id]
		if current_job.fixed.has(id):
			continue
		if f.get("ground", false):
			return true  # grounding it pays a fee, so it's never a dead end
		for t in current_job.get("diag", {}).get(id, []):
			tools_needed.merge(Work.needs_for(t, {})[0])
		if f.part != "" and inventory.get(f.part, 0) == 0:
			need += _price(id)
		var n: Array = Work.needs_for(id, f)
		tools_needed.merge(n[0])
		for m in n[1]:
			mats_needed[m] = mats_needed.get(m, 0) + n[1][m]
	for t in tools_needed:  # a missing tool blocks the repair as surely as a missing part
		if not tools.has(t) and SUPPLIES.has(t):
			need += _supply_price(t)
	for m in mats_needed:
		var short: int = mats_needed[m] - inventory.get(m, 0)
		if short > 0:
			need += ceili(float(short) / SUPPLIES[m].qty) * _supply_price(m)
	var refilled: bool = current_job.faults.has("stale_fuel") and not current_job.fixed.has("stale_fuel")  # that job fills the tanks
	if current_job.get("fuel", 1.0) < 0.5 and not refilled:
		need += _fuel_bill(current_job)
	return money >= need


func _restart() -> void:
	if not save_locked:  # a save we couldn't read stays for recovery, whatever this session does
		_delete_save()  # "Play again" means a fresh career
	keep_difficulty = difficulty
	skip_menu = true  # straight into the new career, not back to the title screen
	get_tree().reload_current_scene()


static var skip_menu := false
var _pending_update := []  # an update offer that arrived while the title screen was up


## Design-doc palette (MyAP GDD): dark earth, aged paper, hangar green, worn brass,
## fault red, serviceable green, pending amber. Clean DIN-style type on screen.
const C_EARTH := Color("1C1810")
const C_PAPER := Color("F5F0E6")
const C_GREEN := Color("2E5339")
const C_BRASS := Color("C8B99A")
const C_RED := Color("8B2020")
const C_OK := Color("285A32")
const C_AMBER := Color("8B6914")


static var UI_FONT := _ui_font()
static var HEAD_FONT := _head_font()


## The HUD and panel face: Big Shoulders at book weight, the same family as the books and
## catalog. It used to be a system stack (Bahnschrift, else Segoe UI, else Arial), which meant
## Arial on every Mac and Linux machine.
static func _ui_font() -> Font:
	return Style.display(600)


static func _head_font() -> Font:
	return Style.caps(800, Style.SIZE_LG)  # a real heavier cut, tracked for capitals; not a smeared faux bold


# Message of the day: shop wisdom, paged with Q / E on the title screen.
const MOTD := [
	["SHOP WISDOM", "The pilot either flies away happy or finds out what you missed. Check every spot and do a run-up before you sign it off.", "icon_magneto"],
	["FROM THE LOGBOOK", "Planes that sat for years hide their trouble under grime. Wash them down first, then look.", "icon_fuel_line"],
	["PARTS COUNTER", "Each town's shed stocks only some parts. The rest come on the mail truck: slower, and a quarter dearer.", "icon_tire"],
	["FUEL TRUCK", "No fueling indoors, and never on top of stale gas. Drain and sump it, then fill it at the truck.", "icon_propeller"],
]
var _menu := {}  # sel, items, rows, motd page, card shown, confirm


## Title screen: the field itself is the backdrop, framed through the hangar, with a text
## list on the left (W/S or arrows, Enter), shop wisdom bottom left (Q/E pages, V hides)
## and the build number. It doubles as the startup loading moment.
func _open_menu() -> void:
	_close_panel()
	if _menu.is_empty():
		_menu = {"sel": 0, "page": 0, "card": true, "confirm": false}
	var m := Control.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = UI_FONT
	m.theme = th
	var fade := TextureRect.new()  # dark on the left for the text, clear over the scene
	var g := GradientTexture2D.new()
	g.gradient = Gradient.new()
	g.gradient.set_color(0, Color(C_EARTH, 0.94))
	g.gradient.set_color(1, Color(C_EARTH, 0.0))
	g.gradient.set_offset(1, 0.62)
	fade.texture = g
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(fade)
	var logo := TextureRect.new()
	logo.texture = load("res://textures/logo_title.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	logo.position = Vector2(48, 20)
	logo.size = Vector2(570, 152)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(logo)
	var has_save := had_save
	var items := []
	if _menu.confirm:
		items = [["YES, START OVER", "Throws away your money, logbook and every job in progress.", _restart],
			["BACK", "", _menu_back]]
	else:
		if has_save:
			items.append(["CONTINUE", "Day %d  -  %s  -  $%d  -  %d of %d rescued" % [floori(day), location.to_upper(), money, rescued, GOAL], _close_menu])
			items.append(["NEW CAREER", "", _menu_confirm])
		else:
			items.append(["START", "Home base: %s" % START_CITY.to_upper(), _close_menu])
		items.append(["DIFFICULTY: %s" % difficulty.to_upper(), DIFFICULTIES[difficulty], _menu_difficulty])
		items.append(["SETTINGS", "", _open_settings.bind(_open_menu)])
		items.append(["CREDITS", "", _open_credits.bind(_open_menu)])
		items.append(["QUIT GAME", "", _quit_game])
	_menu.sel = clampi(_menu.sel, 0, items.size() - 1)
	_menu.items = items
	_menu.rows = []
	for i in items.size():
		var row := _menu_text(m, items[i][0], 26, C_PAPER, Vector2(104, 200 + i * 54))
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.mouse_entered.connect(func(): _menu_select(i))
		row.gui_input.connect(_menu_click)
		var hint := _menu_text(m, items[i][1], 13, C_BRASS, Vector2(106, 233 + i * 54))
		_menu.rows.append([row, hint])
	_menu.arrow = _menu_text(m, "\u25B8", 26, Color(0.78, 0.2, 0.17), Vector2(72, 200))
	_menu.card_node = _motd_card(m)
	var foot := _menu_text(m, "V  %s MESSAGE OF THE DAY      ENTER  SELECT" % ("HIDE" if _menu.card else "SHOW"), 14, C_BRASS, Vector2.ZERO)
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	foot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	foot.position -= Vector2(28, 52)
	var build := _menu_text(m, "BUILD %s" % ProjectSettings.get_setting("application/config/version"), 12, Color(C_BRASS, 0.6), Vector2.ZERO)
	build.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	build.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	build.grow_vertical = Control.GROW_DIRECTION_BEGIN
	build.position -= Vector2(28, 26)
	ui.add_child(m)
	panel = m
	panel_closable = false
	panel_kind = "menu"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true
	_menu_camera()
	_menu_select(_menu.sel)
	msg.text = ""


func _menu_text(parent: Control, text: String, size: int, color: Color, at: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = at
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_outline_color", Color(C_EARTH, 0.7))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _motd_card(parent: Control) -> Control:
	var page: Array = MOTD[_menu.page]
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_EARTH, 0.88)
	sb.border_color = Color(C_BRASS, 0.5)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", sb)
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card.position += Vector2(72, -40)
	card.visible = _menu.card
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var h := Label.new()
	h.text = "MESSAGE OF THE DAY"
	h.add_theme_font_size_override("font_size", 14)
	h.add_theme_color_override("font_color", C_BRASS)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(h)
	var pg := Label.new()
	pg.text = "Q  %d/%d  E" % [_menu.page + 1, MOTD.size()]
	pg.add_theme_font_size_override("font_size", 14)
	pg.add_theme_color_override("font_color", C_BRASS)
	head.add_child(pg)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	vb.add_child(body)
	if ResourceLoader.exists("res://textures/%s.png" % page[2]):
		var icon := TextureRect.new()
		icon.texture = load("res://textures/%s.png" % page[2])
		icon.custom_minimum_size = Vector2(72, 72)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.add_child(icon)
	var txt := VBoxContainer.new()
	body.add_child(txt)
	var t := Label.new()
	t.text = page[0]
	t.add_theme_font_size_override("font_size", 18)
	t.add_theme_color_override("font_color", C_PAPER)
	txt.add_child(t)
	var b := Label.new()
	b.text = page[1]
	b.custom_minimum_size.x = 380
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color(C_PAPER, 0.85))
	txt.add_child(b)
	parent.add_child(card)
	return card


func _menu_select(i: int) -> void:
	_menu.sel = i
	for j in _menu.rows.size():
		_menu.rows[j][0].add_theme_color_override("font_color", C_PAPER if j == i else Color(C_PAPER, 0.55))
		_menu.rows[j][1].visible = j == i
	_menu.arrow.position.y = 200 + i * 54


func _menu_activate() -> void:
	_menu.items[_menu.sel][2].call()


func _menu_click(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_menu_activate()


## Keys on the title screen. True if the key was the menu's.
func _menu_key(e: InputEventKey) -> bool:
	match e.physical_keycode:
		KEY_W, KEY_UP: _menu_select(posmod(_menu.sel - 1, _menu.items.size()))
		KEY_S, KEY_DOWN: _menu_select(posmod(_menu.sel + 1, _menu.items.size()))
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: _menu_activate()
		KEY_Q, KEY_E:
			_menu.page = posmod(_menu.page + (1 if e.physical_keycode == KEY_E else -1), MOTD.size())
			_open_menu()
		KEY_V:
			_menu.card = not _menu.card
			_open_menu()
		_: return false
	return true


## Gamepad on the title menu: d-pad, A to pick, shoulder buttons page the shop wisdom like Q / E.
## The stick is left out: past the deadzone it repeats every frame.
func _menu_pad(e: InputEventJoypadButton) -> bool:
	match e.button_index:
		JOY_BUTTON_DPAD_UP: _menu_select(posmod(_menu.sel - 1, _menu.items.size()))
		JOY_BUTTON_DPAD_DOWN: _menu_select(posmod(_menu.sel + 1, _menu.items.size()))
		JOY_BUTTON_A: _menu_activate()
		JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER:
			_menu.page = posmod(_menu.page + (1 if e.button_index == JOY_BUTTON_RIGHT_SHOULDER else -1), MOTD.size())
			_open_menu()
		_: return false
	return true


var _menu_cam: Camera3D
var _menu_t := 0.0


## The backdrop: looking into the hangar from its open door, lamps over the toolbox and radio,
## the plane in view if it's parked inside. Drifts slowly, like a held breath.
func _menu_camera() -> void:
	if not is_instance_valid(_menu_cam):
		_menu_cam = Camera3D.new()
		_menu_cam.fov = 58
		world.add_child(_menu_cam)
	_menu_cam.make_current()
	_menu_drift(0.0)


func _menu_drift(delta: float) -> void:
	_menu_t += delta
	_menu_cam.position = Vector3(-12.6 + sin(_menu_t * 0.11) * 0.3, 1.8 + sin(_menu_t * 0.07) * 0.08, -10.5)
	_menu_cam.look_at(Vector3(-17.8, 1.4, -21.0), Vector3.UP)


func _menu_confirm() -> void:
	_menu.confirm = true
	_menu.sel = 1  # BACK: never one Enter away from wiping a career
	_open_menu()


func _menu_back() -> void:
	_menu.confirm = false
	_menu.sel = 1
	_open_menu()


func _close_menu() -> void:
	_close_panel()
	if is_instance_valid(_menu_cam):
		_menu_cam.queue_free()
	player.cam.make_current()
	if _greeting != "":
		_say(_greeting)
		_greeting = ""
	if not _pending_update.is_empty():
		_offer_update(_pending_update[0], _pending_update[1])
		_pending_update = []


func _menu_difficulty() -> void:
	var order: Array = DIFFICULTIES.keys()
	difficulty = order[(order.find(difficulty) + 1) % order.size()]
	_save_game()
	_open_menu()


## True when this guidance is shown: "easy" guidance only on Easy, "medium" on Easy and Medium.
func guide(level: String) -> bool:
	var order: Array = DIFFICULTIES.keys()
	return order.find(difficulty) <= order.find(level)


# ---------- per-frame + input ----------

func _setup_input() -> void:
	var keys := DEFAULT_KEYS
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func _process(delta: float) -> void:
	if not _warming.is_empty():
		_warm_step()
	_update_hud()
	sound.set_mood("pause" if get_tree().paused else "menu" if is_instance_valid(_menu_cam) else "flight" if ferry or is_instance_valid(_loader) else "work" if panel is Work else "world")
	if get_tree().paused:
		return
	_animate_birds()
	if msg_time > 0.0:
		msg_time -= delta
		if msg_time <= 0.0:
			msg.text = ""
	if is_instance_valid(_menu_cam) and panel_kind == "menu":
		_menu_drift(delta)
	act.visible = false
	if ferry:
		return  # the ferry flight drives its own prompt
	prompt.text = ""
	if panel:
		cross.set_live(false)
		_light_marker("")
		return
	var t: Object = player.target()
	var kind: String = t.get_meta("kind") if t and t.has_meta("kind") else ""
	if kind == "zone" and current_job == null:
		kind = ""
	var zone := _aimed_marker()
	if zone == "" and kind == "zone":
		zone = t.get_meta("zone")
	if zone != "":
		kind = "zone"
	cross.set_live(kind != "")
	_light_marker(zone)
	if kind != "":
		var icon: String = ACT_ICONS.get(kind, "")
		if kind == "zone":
			icon = "wrench" if current_job.checked.has(zone) else "inspect"
		_act_icon.texture = load("res://textures/hud/%s.svg" % icon)
		act.visible = true
	if kind != "" and Input.is_action_just_pressed("interact") and close_frame != Engine.get_process_frames():
		match kind:
			"zone": _inspect_zone(zone)
			"shop": _open_shop()
			"radio": _open_radio()
			"map": _open_travel()
			"toolbox": _open_toolbox()
			"kit": _open_kit()
			"truck": _open_truck()
			"parts_table": _open_parts_table()


func _input(e: InputEvent) -> void:  # before the GUI, so Tab isn't eaten by focus navigation
	if e.is_action_pressed("playtest_note") and _playlog != "":
		playlog("NOTE (F8): panel=%s spot=%s cockpit=%s" % [panel.get_class() if is_instance_valid(panel) else "none", standing_at, ferry.state if ferry else "no"])
		log_line("Noted in the playtest log.")
	if is_instance_valid(_loader):  # the field is half built: no panels until it's done
		return
	if panel is CatalogUI or panel is RadioUI:  # full-screen sets: the pocket keys don't reach through them
		if panel is CatalogUI and e.is_action_pressed("wallet"):
			panel.next_section(e.shift_pressed)
			get_viewport().set_input_as_handled()
		return
	for kind in ["wallet", "clipboard", "logbook", "manual", "tasks"]:
		if e.is_action_pressed(kind):
			_pocket(kind)
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(e: InputEvent) -> void:
	if is_instance_valid(_loader):
		return
	if panel_kind == "menu":
		var view := get_viewport()  # a menu key can restart the game, which leaves the tree
		if e is InputEventKey and e.pressed and not e.echo and _menu_key(e):
			view.set_input_as_handled()
		elif e is InputEventJoypadButton and e.pressed and _menu_pad(e):
			view.set_input_as_handled()  # the title menu works from a gamepad too
		return
	if e.is_action_pressed("interact") and panel and panel_closable:  # E toggles panels shut too
		if panel_kind == "manual":
			_close_manual()
		else:
			_close_panel()
		close_frame = Engine.get_process_frames()
		return
	if e.is_action_pressed("ui_cancel"):
		if _sub_back.is_valid():
			_sub_back.call()
		elif panel:
			if panel_kind == "manual":
				_close_manual()
			elif panel is Work and station_zone != "":
				_open_station(station_zone)
			elif panel is Bay:
				if is_instance_valid(panel.card):
					panel._close_card()
				elif panel.zone == "engine" and panel.view != "cowled" and panel.view != "left":
					panel._go("left")  # step back out of a close view to the open cowl
				else:
					station_zone = ""
					_open_inspection(panel.zone)
			elif panel_closable:
				_close_panel()
		elif not is_instance_valid(_loader):
			_open_pause()
	elif e is InputEventMouseButton and e.pressed and not panel:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ---------- 2D UI ----------

## The gameplay cursor, in the same style as the repair crosshair: quiet ticks around a dot, and
## a green ring whenever E will do something.
class Reticle extends Control:
	var live := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_CENTER)
		custom_minimum_size = Vector2(44, 44)
		offset_left = -22.0
		offset_top = -22.0
		offset_right = 22.0
		offset_bottom = 22.0

	func set_live(on: bool) -> void:
		if on != live:
			live = on
			queue_redraw()

	func _draw() -> void:
		var c := size / 2
		var ink := Color(0.45, 0.95, 0.5) if live else Color(0.96, 0.94, 0.9, 0.8)
		for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			draw_line(c + d * 6.0, c + d * 12.0, Color(0, 0, 0, 0.55), 4.0)
			draw_line(c + d * 6.0, c + d * 12.0, ink, 2.0)
		draw_circle(c, 2.5, Color(0, 0, 0, 0.55))
		draw_circle(c, 1.6, ink)
		if live:
			draw_arc(c, 16.0, 0, TAU, 40, Color(0, 0, 0, 0.5), 4.0, true)
			draw_arc(c, 16.0, 0, TAU, 40, ink, 2.0, true)


func _setup_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var tl := CanvasLayer.new()  # the apprenticeship sits over every sheet and job, so a tick is always seen
	tl.layer = ui.layer + 1
	add_child(tl)
	tutorial = Tutorial.new()
	tutorial.setup(self)
	tl.add_child(tutorial)
	_setup_pockets()
	cross = Reticle.new()
	ui.add_child(cross)
	prompt = _chip(17, 0.72, 0.8)
	_setup_act()
	_setup_quest()
	_setup_tracker()
	_setup_log()
	msg = _chip(16, 0.03, 0.2)
	_setup_squawk()
	_apply_hud.call_deferred()  # text size, backing, counters: now there's a message to style
	preflight = Preflight.new()  # the cockpit checklist, top left (preflight.gd)
	preflight.setup(self)
	ui.add_child(preflight)


const ACT_ICONS := {"shop": "shop", "radio": "radio", "map": "map", "toolbox": "toolbox", "truck": "fuel", "parts_table": "parts", "kit": "toolbox"}
var act: Control  # what E will do here, under the cursor
var _act_icon: TextureRect
var quest: Control  # what to do next, top left
var _quest_icon: TextureRect
var _quest_count: Label


const LOG_LINES := 2
const LOG_SECONDS := 8.0
var _log: Control  # the engine log, top right: everything the start-up and run-up tell you
var _log_list: VBoxContainer
var _log_now: Label  # what's happening this second: cranking, a hung start
var _log_until := 0


func _setup_log() -> void:
	var sheet := PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	sheet.offset_left = -376
	sheet.offset_right = -16
	sheet.offset_top = 16
	sheet.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.z_index = 5
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_EARTH, 0.8)
	sb.border_width_left = 3
	sb.border_color = C_BRASS
	sb.set_content_margin_all(10)
	sheet.add_theme_stylebox_override("panel", sb)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	sheet.add_child(column)
	_log_list = VBoxContainer.new()
	_log_list.add_theme_constant_override("separation", 5)
	column.add_child(_log_list)
	_log_now = _log_label("")
	_log_now.add_theme_color_override("font_color", Color(CatalogUI.MUSTARD))
	column.add_child(_log_now)
	ui.add_child(sheet)
	_log = sheet
	_log.visible = false


func _log_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 340
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", UI_FONT)
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", C_PAPER)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Adds a line to the engine log. Older lines dim, and the oldest drops off.
func log_line(text: String) -> void:
	_log_list.add_child(_log_label(text))
	if _log_list.get_child_count() > LOG_LINES:
		var oldest := _log_list.get_child(0)
		_log_list.remove_child(oldest)
		oldest.queue_free()
	_log_tidy()
	_log_until = Time.get_ticks_msec() + int(LOG_SECONDS * 1000.0)


func log_live(text: String) -> void:
	_log_now.text = text
	if _log_now.visible != (text != ""):
		_log_now.visible = text != ""
		_log_tidy()


## Never more than LOG_LINES on show: the live line takes one of the places.
func _log_tidy() -> void:
	var lines := _log_list.get_children()
	var room: int = LOG_LINES - (1 if _log_now.visible else 0)
	for i in lines.size():
		lines[i].visible = i >= lines.size() - room
		lines[i].modulate.a = 1.0 if i == lines.size() - 1 else 0.6


func log_clear() -> void:
	for l in _log_list.get_children():
		_log_list.remove_child(l)
		l.queue_free()
	log_live("")


func _setup_act() -> void:
	var box_ := CenterContainer.new()
	box_.anchor_right = 1.0
	box_.anchor_top = 0.68
	box_.anchor_bottom = 0.8
	box_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var key := _keycap("E", 18)
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(key)
	_act_icon = _hud_icon("inspect", 44)
	row.add_child(_act_icon)
	box_.add_child(row)
	ui.add_child(box_)
	act = box_
	act.visible = false


## The achievement tracker (P13): the eight badges as small icons, bottom centre, in process order,
## greyed until earned. Earning one colours it in with a pulse and shows its name for a moment.
var tracker: HBoxContainer
var _tracker_name: Label
var _tracker_name_t := 0.0


func _setup_tracker() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_bottom = -12
	box.alignment = BoxContainer.ALIGNMENT_END
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	_tracker_name = Style.label("", "hud", Style.SIZE_SM, 800)
	_tracker_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tracker_name.add_theme_constant_override("outline_size", 6)
	_tracker_name.add_theme_color_override("font_outline_color", Style.COLOR_SURFACE_HUD)
	box.add_child(_tracker_name)
	tracker = HBoxContainer.new()
	tracker.alignment = BoxContainer.ALIGNMENT_CENTER
	tracker.add_theme_constant_override("separation", 6)
	tracker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for b in BADGES:
		var t := TextureRect.new()
		t.name = b[0]
		t.custom_minimum_size = Vector2(26, 26)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.tooltip_text = "%s: %s" % [b[1], b[3]]
		tracker.add_child(t)
	box.add_child(tracker)
	ui.add_child(box)
	_refresh_tracker()


func _refresh_tracker() -> void:
	if tracker == null:
		return
	for t: TextureRect in tracker.get_children():
		var got: bool = badges.has(String(t.name))
		t.texture = load("res://textures/hud/badge.svg" if got else "res://textures/hud/badge_none.svg")
		t.modulate.a = 1.0 if got else 0.55


## The moment a badge is earned: its icon colours in with a pulse, and its name shows above the row.
func _tracker_pulse(id: String) -> void:
	_refresh_tracker()
	var t: TextureRect = tracker.get_node_or_null(id) if tracker else null
	if t == null:
		return
	t.pivot_offset = t.custom_minimum_size / 2
	var tw := t.create_tween()
	tw.tween_property(t, "scale", Vector2(1.6, 1.6), 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(t, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN_OUT)
	_tracker_name.text = badge_name(id).to_upper()
	_tracker_name_t = 4.0


func _setup_quest() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(16, 14)
	row.add_theme_constant_override("separation", 8)
	row.modulate.a = 0.8
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_icon = _hud_icon("map", 40)
	row.add_child(_quest_icon)
	_quest_count = Label.new()
	_quest_count.add_theme_font_override("font", CatalogUI.BLACK)
	_quest_count.add_theme_font_size_override("font_size", 22)
	_quest_count.add_theme_color_override("font_color", C_PAPER)
	_quest_count.add_theme_constant_override("outline_size", 8)
	_quest_count.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	row.add_child(_quest_count)
	ui.add_child(row)
	quest = row


## A small dark caption, centered in a band of the screen. Hidden while it has no text.
func _chip(size: int, top: float, bottom: float) -> Label:
	var box_ := CenterContainer.new()
	box_.anchor_right = 1.0
	box_.anchor_top = top
	box_.anchor_bottom = bottom
	box_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.add_theme_font_override("font", UI_FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", C_PAPER)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_EARTH, 0.82)
	sb.border_width_left = 3
	sb.border_color = C_BRASS
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box_.add_child(l)
	ui.add_child(box_)
	return l


## A short moment for something finished, over the open part of the screen.
func _banner(title: String, sub: String) -> void:
	if is_instance_valid(_banner_node):
		_banner_node.queue_free()
	var box_ := CenterContainer.new()
	box_.anchor_right = 1.0
	box_.anchor_bottom = 0.5
	box_.offset_left = _sheet_edge()
	box_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	box_.add_child(vb)
	for t in [[title, HEAD_FONT, 44, C_BRASS], [sub, UI_FONT, 17, C_PAPER]]:
		var l := Label.new()
		l.text = t[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", t[1])
		l.add_theme_font_size_override("font_size", t[2])
		l.add_theme_color_override("font_color", t[3])
		l.add_theme_constant_override("outline_size", 8)
		l.add_theme_color_override("font_outline_color", Color(C_EARTH, 0.85))
		vb.add_child(l)
	ui.add_child(box_)
	_banner_node = box_
	box_.modulate.a = 0.0
	var tw := box_.create_tween()
	tw.tween_property(box_, "modulate:a", 1.0, 0.18)
	tw.tween_interval(1.6)
	tw.tween_property(box_, "modulate:a", 0.0, 0.5)
	tw.tween_callback(box_.queue_free)


func _money_pop(change: int) -> void:
	var l := Label.new()
	l.text = "%s$%d" % ["+" if change > 0 else "-", absi(change)]
	l.anchor_left = 1.0
	l.anchor_right = 1.0
	l.offset_left = -220
	l.offset_right = -24
	l.offset_top = 22
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_override("font", HEAD_FONT)
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(0.6, 0.85, 0.55) if change > 0 else Color(0.95, 0.6, 0.45))
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(C_EARTH, 0.85))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "offset_top", 2.0, 1.4)
	tw.tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)


func _saved_mark() -> void:
	if _saved == null:
		_saved = _hud_icon("saved", 24)
		_saved.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		_saved.offset_left = -40
		_saved.offset_top = -40
		_saved.offset_right = -16
		_saved.offset_bottom = -16
		ui.add_child(_saved)
	if _saved_fade:
		_saved_fade.kill()
	_saved.modulate.a = 1.0
	_saved_fade = _saved.create_tween()
	_saved_fade.tween_interval(0.8)
	_saved_fade.tween_property(_saved, "modulate:a", 0.0, 0.5)


## What to do next, spelled out one step at a time. This is the game's running tutorial.
## What to do next as [icon, count]: the markers on the plane say where.
func _objective() -> Array:
	if current_job == null:
		return ["map", ""]
	var j: Dictionary = current_job
	if j.checked.size() < ZONES.size():
		return ["question", "%d/%d" % [j.checked.size(), ZONES.size()]]
	if j.faults.any(func(id): return j.found.has(id) and not j.fixed.has(id)):
		return ["wrench", ""]
	if j.get("runup", "") != "ran":
		return ["runup", ""]
	if not j.get("signed", false):
		return ["sign", ""]
	if j.get("fuel", 1.0) < 0.5:
		return ["fuel", ""]
	if j.get("parked", "apron") == "hangar":
		return ["hangar", ""]
	return ["fly", ""]


## Almost no HUD (ART_DIRECTION.md): money, parts and career live in things you take out.
func _update_hud() -> void:
	hud.visible = panel == null and ferry == null
	cross.visible = hud.visible and settings.crosshair
	prompt.visible = prompt.text != ""
	prompt.custom_minimum_size.x = 620.0 if ferry else 0.0  # flight numbers change every frame; a fixed box doesn't shake
	prompt.add_theme_font_override("font", Style.figures() if ferry else UI_FONT)  # and one-width digits don't jitter inside it
	msg.visible = msg.text != ""
	var checking: bool = preflight.wanted()  # the checklist card draws itself (preflight.gd)
	var has_lines: bool = _log_list.get_child_count() > 0 or _log_now.visible
	_log.visible = has_lines and (checking or Time.get_ticks_msec() < _log_until)
	quest.visible = hud.visible
	tracker.get_parent().visible = hud.visible  # the badge row: in the world only, never over a sheet, job or cockpit
	if _tracker_name_t > 0.0:
		_tracker_name_t -= get_process_delta_time()
		if _tracker_name_t <= 0.0:
			_tracker_name.text = ""
	_update_squawk()
	held_label.text = ("IN HAND: " + SUPPLIES[held].name.to_upper()) if held != "" else ""
	if quest.visible:
		var next := _objective()
		_quest_icon.texture = load("res://textures/hud/%s.svg" % next[0])
		_quest_count.text = next[1]
	# Toasts sit over the open half of the screen, never on top of a side sheet.
	msg.get_parent().offset_left = _sheet_edge()


## The pilot's squawk, pinned top right the whole time you're at their plane: a paper slip, the
## owner's words in type. It's the trail you start from, so it never leaves the screen.
var squawk: PanelContainer
var _squawk_text: Label
var _squawk_note: Label
var _squawk_for := ""


func _setup_squawk() -> void:
	squawk = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER
	sb.set_corner_radius_all(Style.RADIUS_SM)
	sb.set_content_margin_all(Style.SPACE_3)
	sb.border_width_top = 4
	sb.border_color = Style.COLOR_TEXT_PAPER_ACCENT
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	squawk.add_theme_stylebox_override("panel", sb)
	squawk.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	squawk.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	squawk.position += Vector2(-16, 16)
	squawk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.SPACE_1)
	squawk.add_child(col)
	col.add_child(Style.label("PILOT SQUAWK", "accent", Style.SIZE_SM, 900))
	_squawk_text = Label.new()
	_squawk_text.add_theme_font_override("font", Style.figures())  # typed on the sheet
	_squawk_text.add_theme_font_size_override("font_size", Style.SIZE_SM)
	_squawk_text.add_theme_color_override("font_color", Style.COLOR_TEXT_PAPER)
	_squawk_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_squawk_text.custom_minimum_size.x = 340
	col.add_child(_squawk_text)
	_squawk_note = Style.label("", "accent", Style.SIZE_SM, 800)  # during the lessons: where to look first
	_squawk_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_squawk_note.custom_minimum_size.x = 340
	_squawk_note.visible = false
	col.add_child(_squawk_note)
	squawk.visible = false
	ui.add_child(squawk)


func _update_squawk() -> void:
	var job = current_job
	var here: bool = job != null and job.city == location and ferry == null
	squawk.visible = here and (hud.visible or panel is Bay) and not _log.visible
	if here:
		var note: String = tutorial.squawk_note()
		if note != _squawk_note.text:
			_squawk_note.text = note
			_squawk_note.visible = note != ""
			squawk.size = Vector2.ZERO
		var t := _symptoms(job)
		if t != _squawk_for:
			_squawk_for = t
			_squawk_text.text = t
			squawk.size = Vector2.ZERO


var held_label: Label


## Bottom-left: what you carry, as icons, each with the key that opens it.
func _setup_pockets() -> void:
	var strip := HBoxContainer.new()
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	strip.offset_left = 16
	strip.offset_top = -54
	strip.offset_bottom = -14
	strip.add_theme_constant_override("separation", 8)
	strip.modulate.a = 0.55  # always there, never asking for attention
	for p in [["wallet", "Tab"], ["clipboard", "J"], ["logbook", "L"], ["manual", "N"], ["tasks", "T"]]:
		var icon := _hud_icon(p[0], 40)
		var key := _keycap(p[1], 10)
		key.position = Vector2(20 if p[1] == "Tab" else 28, 27)
		icon.add_child(key)
		strip.add_child(icon)
	held_label = Style.label("", "hud", Style.SIZE_SM, 800)  # the instrument in your hand, by your pockets
	held_label.add_theme_constant_override("outline_size", 4)
	held_label.add_theme_color_override("font_outline_color", Style.COLOR_SURFACE_HUD)
	held_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	strip.add_child(held_label)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = strip
	ui.add_child(hud)


func _hud_icon(icon: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load("res://textures/hud/%s.svg" % icon)
	t.custom_minimum_size = Vector2(px, px)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## A little key, so an icon still says how to use it.
func _keycap(key: String, px: int) -> Label:
	var l := Label.new()
	l.text = key
	l.add_theme_font_override("font", CatalogUI.BLOCK)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", C_EARTH)
	var sb := StyleBoxFlat.new()
	sb.bg_color = C_PAPER
	sb.set_corner_radius_all(3)
	sb.content_margin_left = px * 0.4
	sb.content_margin_right = px * 0.4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


var panel_kind := ""  # which pocket panel is open, so its key closes it again


func _pocket(kind: String) -> void:
	if ferry or get_tree().paused or panel_kind == "menu" or (panel and not panel_closable):
		return
	if panel and panel_kind == kind:
		if kind == "manual":
			_close_manual()
		else:
			_close_panel()
		return
	match kind:
		"wallet": _open_wallet()
		"clipboard":
			if current_job:
				_open_inspection("")  # read-only: work happens at the plane
			else:
				_open_panel("Clipboard", [["No plane at this field. Take a call from the MAP on the hangar workbench."]])
		"logbook": _open_logbook()
		"tasks": _open_tasks()
		"manual":
			_open_manual(_manual_job())
			return  # _open_manual sets panel_kind
	panel_kind = kind


# ---------- job status (P19): a career ladder earned from the record ----------

## [id, title, raise on new calls]. The numbers that earn each rank are game rules for this ladder,
## not real-world requirements (a real IA needs an A&P held three years and a test).
const RANKS := [["apprentice", "Apprentice", 0.0], ["ap", "A&P Mechanic", 0.0], ["lead", "Lead Mechanic", 0.10],
	["ia", "Inspection Authorization (IA)", 0.20]]
const LEAD_NEEDS := {"planes": 5, "clean": 3, "no_comeback_in": 3}
const IA_NEEDS := {"planes": 8, "badges": 6, "no_comeback_in": 5}
var rank := ""  # saved; never lost once earned


func rank_index(id: String) -> int:
	for i in RANKS.size():
		if RANKS[i][0] == id:
			return i
	return 0


func rank_title(id: String) -> String:
	return RANKS[rank_index(id)][1]


func rank_raise() -> float:
	return RANKS[rank_index(rank)][2]


## What the record shows: delivered planes, clean jobs (nothing extra on the debrief), and whether
## the last n deliveries came back.
func _record() -> Dictionary:
	var clean := logbook.filter(func(e): return e.has("debrief") and e.debrief.extra.is_empty()).size()
	var came_back := func(n: int) -> bool:
		return logbook.slice(maxi(0, logbook.size() - n)).any(func(e): return Array(e.get("work", [])).any(func(w): return String(w).begins_with("Comeback")))
	return {"planes": rescued, "clean": clean, "badges": badges.size(),
		"clean_last_lead": not came_back.call(LEAD_NEEDS.no_comeback_in), "clean_last_ia": not came_back.call(IA_NEEDS.no_comeback_in)}


## The highest rank the record earns now.
func earned_rank() -> String:
	if int(tut.get("lesson", 0)) > 0:
		return "apprentice"
	var r := _record()
	if r.planes >= IA_NEEDS.planes and r.badges >= IA_NEEDS.badges and r.clean_last_ia:
		return "ia"
	if r.planes >= LEAD_NEEDS.planes and r.clean >= LEAD_NEEDS.clean and r.clean_last_lead:
		return "lead"
	return "ap"


## The next rank and what it still needs, in figures, for the logbook ("" at the top).
func rank_next_line() -> String:
	var r := _record()
	match rank:
		"apprentice":
			return "Next: A&P Mechanic. Finish the three apprentice jobs."
		"ap":
			return "Next: Lead Mechanic (calls pay 10%% more). %d planes delivered (you have %d), %d clean jobs (%d), no comeback in your last %d (%s)." \
				% [LEAD_NEEDS.planes, r.planes, LEAD_NEEDS.clean, r.clean, LEAD_NEEDS.no_comeback_in, "yes" if r.clean_last_lead else "not yet"]
		"lead":
			return "Next: Inspection Authorization (calls pay 20%% more, and annual inspections open). %d planes (you have %d), %d badges (%d), no comeback in your last %d (%s)." \
				% [IA_NEEDS.planes, r.planes, IA_NEEDS.badges, r.badges, IA_NEEDS.no_comeback_in, "yes" if r.clean_last_ia else "not yet"]
	return "The top of the ladder: you can sign off annual inspections."


## Checked on each delivery: a rank earned is a banner, a chime and a play-log line. Never lost.
func _check_promotion() -> void:
	var e := earned_rank()
	if rank_index(e) <= rank_index(rank):
		return
	rank = e
	_job_record("promoted", rank)
	playlog("promoted: " + rank)
	sound.chime()
	if _signed_off():
		return  # the end-of-mission card shows it (D3)
	_banner("PROMOTED: " + rank_title(rank).to_upper(), rank_next_line())


# ---------- achievement badges (P8): one per skill, earned when its standard is met ----------

## [id, name, the system it belongs to, the standard in words]. In board order, grouped by system.
const BADGES := [
	["sharp_eyes", "Sharp Eyes", "Walk-around", "Deliver a plane with all 8 spots checked and nothing coming back."],
	["to_spec", "To Spec", "Repair", "Finish a job with torqued fasteners and no over-torque."],
	["reads_the_drop", "Reads the Drop", "Run-up", "Call both mags right on a run-up, with no wrong call."],
	["detective", "Detective", "Troubleshooting", "Follow a trail to its cause with no wrong call."],
	["by_the_book", "By the Book", "Paperwork", "Sign the logbook with no entry sent back."],
	["clean_start", "Clean Start", "Flight", "Start the engine with no failed attempt."],
	["straight_and_true", "Straight and True", "Flight", "Take off with no ground loop."],
	["clean_job", "Clean Job", "Career", "Deliver a plane with nothing extra on the debrief."],
]
var badges := {}  # id -> the day it was earned (saved)


func badge_name(id: String) -> String:
	for b in BADGES:
		if b[0] == id:
			return b[1]
	return id


## Earns a badge the moment its standard is met, once per career: a banner and a play-log line.
func earn_badge(id: String) -> void:
	if badges.has(id):
		return
	badges[id] = floori(day)
	_job_record("badges", id)
	playlog("badge: " + id)
	_tracker_pulse(id)
	sound.chime()
	_save_game()
	if _signed_off():
		return  # earned at sign-off: the end-of-mission card shows it (D3)
	_banner("BADGE: " + badge_name(id).to_upper(), "%d of %d earned. See them in your logbook (%s)." % [badges.size(), BADGES.size(), key_name("logbook")])


## The unearned badge an activity can earn, for the task list and the cockpit card ("" if none).
## Notes an achievement against the job it came on, for its end-of-mission card (D3): on the job
## while it's open, on the debrief once it's signed off (Sharp Eyes, Clean Job and a promotion come
## at sign-off, after the job has closed).
func _job_record(key: String, value: String) -> void:
	if current_job != null:
		current_job.get_or_add("earned_" + key, []).append(value)
	elif not _pending_debrief.is_empty():
		_pending_debrief.debrief.get_or_add(key, []).append(value)


## True between sign-off and the end-of-mission card: what's earned now is shown on the card.
func _signed_off() -> bool:
	return current_job == null and not _pending_debrief.is_empty()


func badge_on_offer(id: String) -> String:
	return "" if badges.has(id) else badge_name(id)


# ---------- the task list (P3): what's done, failed, to try again, not tried yet ----------

## The four states, each with its symbol and its word (never color alone).
const TASK_STATES := {
	"done": ["Done", "hud/task_done.svg"], "failed": ["Can't be done", "hud/task_failed.svg"],
	"retry": ["Try again", "hud/task_retry.svg"], "todo": ["To do", "hud/task_todo.svg"],
}


## This job's tasks as it stands: [{state, text, note}]. Built from what you know, so a fault you
## haven't found never appears; something heard but not tracked down is named by its next test.
func task_list(job: Dictionary) -> Array:
	var out := []
	var add := func(state: String, text: String, note := ""): out.append({"state": state, "text": text, "note": note})
	var n: int = job.get("checked", {}).size()
	add.call("done" if n >= ZONES.size() else "todo", "Check all %d spots" % ZONES.size(), "%d of %d checked" % [n, ZONES.size()])
	var swapped_wrong: Array = job.get("tried", {}).keys().filter(func(c): return job.tried[c] == false)
	for id in job.faults:
		var f: Dictionary = FAULTS[id]
		if job.get("sym", {}).has(id) and not job.found.has(id):  # heard, not tracked down: the trail, not the cause
			var t := _test_for(job, id)
			var missed: int = job.get("misses", {}).get(id, 0)
			add.call("retry" if missed > 0 else "todo", "Track it down: next, the %s" % (TESTS[t].name.to_lower() if t != "" else "run-up"),
				("%d wrong call%s so far" % [missed, "" if missed == 1 else "s"]) if missed > 0 else String(TESTS[t].clue if t != "" else ""))
			continue
		if not job.found.has(id):
			continue
		if f.get("ground", false):
			add.call("failed", f.name, "No field fix here: ground it and call the owner.")
		elif job.fixed.has(id):
			add.call("done", "Fix: " + f.name)
		elif job.get("caused", {}).has(id):
			add.call("retry", "Fix: " + f.name, "You broke it running it unready: the part's on you.")
		elif swapped_wrong.has(SUSPECTS.get(id, "")):
			add.call("retry", "Fix: " + f.name, "The %s you swapped wasn't it." % FAULTS[SUSPECTS[id]].part.to_lower())
		else:
			add.call("todo", "Fix: " + f.name, "Started" if job.get("work", {}).has(id) else "")
	var r: String = job.get("runup", "")
	add.call("done" if r == "ran" else ("retry" if r == "dead" else "todo"), "Run it up from the cabin",
		"It wouldn't start: fix what stopped it, then try again." if r == "dead" else "")
	if not cowl_closed(job):
		add.call("todo", "Close the engine cowl", "Screw it down before you sign.")
	if job.get("parked", "apron") == "hangar":
		add.call("todo", "Roll it out to the apron")
	add.call("done" if job.get("fuel", 1.0) >= 0.5 else "todo", "Fuel it: half tanks at least")
	var sent_back: bool = job.get("lost", []).any(func(l): return l.kind == "entry")
	add.call("done" if job.get("signed", false) else ("retry" if sent_back else "todo"), "Sign the logbook",
		"An entry was sent back: write what you worked to." if sent_back and not job.get("signed", false)
		else (("Can earn: " + badge_on_offer("by_the_book")) if badge_on_offer("by_the_book") != "" and not job.get("signed", false) else ""))
	var offer: PackedStringArray = []
	for b in ["clean_start", "straight_and_true", "clean_job", "sharp_eyes"]:
		if badge_on_offer(b) != "":
			offer.append(badge_on_offer(b))
	add.call("todo", "Fly it out to the owner", ("Can earn: " + ", ".join(offer)) if offer.size() > 0 else "")
	return out


func _open_tasks() -> void:
	tutorial.walk("tasks")
	var job = current_job
	if job == null or job.city != location:
		_open_panel("Task list", [["No plane here. Take a call from the MAP on the hangar workbench."]])
		return
	var rows := [["%s at %s" % [job.type, job.city]]]
	for t in task_list(job):
		var st: Array = TASK_STATES[t.state]
		rows.append(["%s: %s%s" % [st[0], t.text, ("\n" + t.note) if t.note != "" else ""], "", null, false, st[1]])
	_open_panel("Task list", rows)


func _open_wallet() -> void:
	tutorial.walk("wallet")  # first time here: a walkthrough of this menu (tutorial.gd)
	var rows := [["Cash: $%d" % money], ["Day %d, at %s" % [floori(day), location]]]
	var inv: PackedStringArray = []
	for k in inventory:
		if inventory[k] > 0 and not SUPPLIES.has(k):  # materials are listed on their own line
			inv.append("%s x%d" % [k, inventory[k]])
	rows.append(["Parts in the truck: " + (", ".join(inv) if inv.size() > 0 else "none")])
	var have: PackedStringArray = []
	for t in tools:
		have.append(Work.TOOLS[t])
	rows.append(["Tool roll: " + (", ".join(have) if have.size() > 0 else "empty")])
	rows.append(["Materials: " + ", ".join(SUPPLIES.keys().filter(func(k): return SUPPLIES[k].has("qty")).map(func(k): return "%s %d" % [k, inventory.get(k, 0)]))])
	rows.append(["Hangar rent and insurance: $%d a day" % DAILY_COST])
	_open_panel("Wallet", rows)


func _set_graphics(level: String) -> void:
	graphics = level
	_apply_graphics()
	_save_game()


## High: everything. Low: no volumetric haze, bounce light, ambient occlusion or dust motes,
## the effects that cost frames on built-in laptop graphics.
func _apply_graphics() -> void:
	graphics = "low" if settings.quality == "low" else "high"  # the tree count still reads this
	var low := "--low" in OS.get_cmdline_user_args()
	if env:
		env.volumetric_fog_enabled = settings.haze and not low
		env.sdfgi_enabled = settings.bounce and not low
		env.ssao_enabled = settings.ao and not low
		env.glow_enabled = settings.bloom
	if sun:
		sun.directional_shadow_max_distance = {"low": 50.0, "medium": 70.0, "high": 90.0, "ultra": 140.0}[settings.shadows]
	if motes:
		motes.emitting = settings.dust and not low
		motes.visible = settings.dust and not low


func _confirm_restart() -> void:
	_open_panel("Start over?", [["This throws away your money, logbook and every job in progress."],
		["", "Yes, start over", _restart, true], ["", "Keep playing", _close_panel, true]])


func _open_logbook() -> void:
	tutorial.walk("logbook")  # first time here: a walkthrough of this menu (tutorial.gd)
	var rows := [["Planes back in the air: %d of %d" % [rescued, GOAL]]]
	rows.append(["Rank: %s\n%s" % [rank_title(rank), rank_next_line()]])  # job status (P19)
	# The badge board: every badge, earned or not, with its standard (P8).
	rows.append(["Badges: %d of %d" % [badges.size(), BADGES.size()]])
	for b in BADGES:
		var got: bool = badges.has(b[0])
		rows.append(["%s  (%s)%s\n%s" % [b[1], b[2], ("  earned day %d" % badges[b[0]]) if got else "", b[3]], "", null, false,
			"hud/badge.svg" if got else "hud/badge_none.svg"])
	for i in range(logbook.size() - 1, -1, -1):
		var e: Dictionary = logbook[i]
		var net: int = e.pay - e.get("fuel", 0) - e.get("parts", 0)
		rows.append(["Day %d  %s  -  %s%s%s\n%s\nPaid $%d - fuel $%d - parts $%d = %s$%d   (%.1f days on site)" % [e.day, e.city, e.type,
			"  (GROUNDED)" if e.get("grounded", false) else "",
			(", sat %d yrs" % e.years) if e.get("years", 0) > 0 else "", ", ".join(e.work), e.pay, e.get("fuel", 0), e.get("parts", 0),
			"" if net >= 0 else "-", absi(net), e.get("days", 0.0)]])
		var d: Dictionary = e.get("debrief", {})  # entries from before the debrief (E5) have none
		if not d.is_empty():
			rows.append([("Cost extra: " + "; ".join(debrief_lines(d)) if d.extra.size() > 0 else "Nothing cost extra.") + "\nNext time: " + d.next])
	if logbook.is_empty():
		rows.append(["No entries yet. Your first rescue goes here."])
	_open_panel("Logbook", rows)


func _say(text: String) -> void:
	msg.text = text
	var long := text.length() > 70  # long messages wrap instead of running off both edges
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if long else TextServer.AUTOWRAP_OFF
	msg.custom_minimum_size.x = 560.0 if long else 0.0
	msg_time = 4.0 + text.length() / 40.0  # long run-up reports stay up long enough to read


const SHEET_W := 660.0
var _list_title := ""
var _pages := []
var _page := 0
var _list: VBoxContainer
var _page_label: Label
var _side: Control  # something shown beside the sheet, like the chart: goes when the sheet goes


## One look for every screen: warm near-black enamel, paper-colored type, thin brass lines.
## The paperwork sheets: what a mechanic writes on or carries in a pocket goes on cream stock with
## ink (the design system's paper surface), like the catalog and the manual. Menus stay on the
## dark hangar surface.
const PAPER_SHEETS := ["Work order", "Clipboard", "Logbook", "Aircraft logbook", "Wallet", "Toolbox", "Parts on hand", "Weight and balance", "Fuel truck", "Debrief", "Task list"]
var _paper_sheet := false


func _is_paper(title: String) -> bool:
	return PAPER_SHEETS.any(func(p): return title.begins_with(p))


## The paper sheet's look: ink text, quiet outlined buttons (the edge at 4.2:1 on cream), a
## mustard focus ring.
func _paper_theme() -> Theme:
	var t := Theme.new()
	t.default_font = UI_FONT
	t.default_font_size = Style.SIZE_MD
	t.set_color("font_color", "Label", Style.COLOR_TEXT_PAPER)
	var fills := {"normal": 0.0, "hover": 0.12, "pressed": 0.22, "hover_pressed": 0.22, "disabled": 0.0}
	for state in fills:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Style.COLOR_TEXT_PAPER, fills[state])
		sb.set_border_width_all(1)
		sb.border_color = Color(Style.COLOR_TEXT_PAPER, 0.3 if state == "disabled" else 0.6)
		sb.set_corner_radius_all(Style.RADIUS_SM)
		sb.set_content_margin_all(7)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		t.set_stylebox(state, "Button", sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", Style.COLOR_TEXT_PAPER)
	t.set_color("font_disabled_color", "Button", Color(Style.COLOR_TEXT_PAPER, 0.4))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.border_color = Style.COLOR_FOCUS
	focus.set_corner_radius_all(Style.RADIUS_SM)
	t.set_stylebox("focus", "Button", focus)
	return t


func _ui_theme() -> Theme:
	var t := Theme.new()
	t.default_font = UI_FONT
	t.default_font_size = Style.SIZE_MD  # Big Shoulders is condensed: it reads about 2 px smaller than a regular sans at the same size
	t.set_color("font_color", "Label", C_PAPER)
	var fills := {"normal": Color(C_BRASS, 0.1), "hover": C_BRASS, "pressed": C_BRASS.darkened(0.2),
		"hover_pressed": C_BRASS, "disabled": Color(C_BRASS, 0.04)}
	for state in fills:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fills[state]
		sb.set_border_width_all(1)
		sb.border_color = Color(C_BRASS, 0.2 if state == "disabled" else 0.75)
		sb.set_corner_radius_all(2)
		sb.set_content_margin_all(7)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		t.set_stylebox(state, "Button", sb)
	t.set_color("font_color", "Button", C_PAPER)
	for s in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(s, "Button", C_EARTH)
	t.set_color("font_disabled_color", "Button", Color(C_BRASS, 0.5))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.border_color = C_PAPER
	focus.set_corner_radius_all(2)
	t.set_stylebox("focus", "Button", focus)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(C_BRASS, 0.25)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", track)
	return t


## rows: [text] or [text, button_text, callable, enabled] with an optional 5th icon texture name.
## A row's first line is its headline, the rest smaller detail. Opens as a full-height sheet on the
## left so the plane stays in view. Returns the content box so callers can add more.
func _open_panel(title: String, rows: Array, closable := true, stamp := "") -> VBoxContainer:
	var fresh := panel == null
	var same_list := not fresh and title == _list_title  # buying something keeps you on your page
	_close_panel()
	panel_closable = closable
	_list_title = title
	var sheet := PanelContainer.new()
	panel = sheet
	sheet.anchor_bottom = 1.0
	sheet.offset_right = SHEET_W
	_paper_sheet = _is_paper(title)
	sheet.theme = _paper_theme() if _paper_sheet else _ui_theme()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER if _paper_sheet else Color(C_EARTH, 0.96)
	sb.border_width_right = 4 if _paper_sheet else 1
	sb.border_color = Style.COLOR_TEXT_PAPER_ACCENT if _paper_sheet else Color(C_BRASS, 0.6)
	sb.shadow_color = Color(0, 0, 0, 0.35 if _paper_sheet else 0.0)
	sb.shadow_size = 10 if _paper_sheet else 0
	sb.content_margin_left = 32
	sb.content_margin_right = 28
	sb.content_margin_top = 26
	sb.content_margin_bottom = 22
	sheet.add_theme_stylebox_override("panel", sb)
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 12)
	sheet.add_child(frame)
	var top := HBoxContainer.new()
	frame.add_child(top)
	var head := Label.new()
	head.text = title.to_upper()
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size.x = 440
	head.add_theme_font_override("font", HEAD_FONT)
	head.add_theme_font_size_override("font_size", 24)
	top.add_child(head)
	if stamp != "":
		var holder := Control.new()  # containers undo rotation, so the stamp sits in a plain holder
		holder.custom_minimum_size = Vector2(130, 50)
		top.add_child(holder)
		var s := TextureRect.new()
		s.texture = load("res://textures/%s.png" % stamp)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # must come before size, or size snaps to the image
		s.size = Vector2(130, 65)
		s.rotation = -0.12
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(s)
	if _paper_sheet:
		head.add_theme_color_override("font_color", Style.COLOR_TEXT_PAPER_ACCENT)  # a red heading, like the catalog's
	var rule := ColorRect.new()
	rule.color = Style.COLOR_TEXT_PAPER_ACCENT if _paper_sheet else C_BRASS
	rule.custom_minimum_size.y = 2
	frame.add_child(rule)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	frame.add_child(vb)
	var chrome := 48.0 + ceilf(title.length() * 17.0 / 540.0) * 32.0 + 50.0 + (40.0 if closable else 0.0) + 44.0
	_pages = _paginate(rows, get_viewport().get_visible_rect().size.y - chrome)
	_page = clampi(_page, 0, _pages.size() - 1) if same_list else 0
	_list = vb
	_show_page()
	if _pages.size() > 1:
		var pager := HBoxContainer.new()
		pager.alignment = BoxContainer.ALIGNMENT_CENTER
		pager.add_theme_constant_override("separation", 16)
		frame.add_child(pager)
		var prev := Button.new()
		prev.text = "Previous"
		prev.pressed.connect(_turn_page.bind(-1))
		pager.add_child(prev)
		_page_label = Label.new()
		_page_label.custom_minimum_size.x = 110
		_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_page_label.text = "Page %d of %d" % [_page + 1, _pages.size()]
		pager.add_child(_page_label)
		var next := Button.new()
		next.text = "Next"
		next.pressed.connect(_turn_page.bind(1))
		pager.add_child(next)
	if closable:
		var close := Button.new()
		close.text = "Close (Esc)"
		close.pressed.connect(sound.sfx.bind("thread"))
		close.pressed.connect(_close_panel)
		frame.add_child(close)
	ui.add_child(sheet)
	if not closable:  # a screen you must answer: Enter takes the likeliest choice
		var first: Array = sheet.find_children("*", "Button", true, false).filter(func(b): return not b.disabled)
		if first.size() > 0:
			first[0].grab_focus.call_deferred()
	if fresh:  # slides out from the edge; a sheet replacing a sheet just swaps
		sheet.modulate.a = 0.0
		sheet.position.x = -30.0
		var tw := sheet.create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(sheet, "modulate:a", 1.0, 0.16)
		tw.tween_property(sheet, "position:x", 0.0, 0.16)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true
	return vb


## Roughly how tall a row will be once wrapped. Errs tall, so a page never overflows the screen.
func _row_height(r: Array) -> float:
	var w := _text_width(r)
	var tall := 0.0
	if r.size() > 4 and r[4] != "":
		tall = 40.0
	if r.size() > 1 and r[1] != "":
		tall = 38.0
	var lines: PackedStringArray = r[0].split("\n")
	var h := 0.0
	for i in lines.size():
		h += ceilf(lines[i].length() * (8.6 if i == 0 else 7.0) / w) * (21.0 if i == 0 else 17.0)
	return maxf(h, tall) + 21.0  # plus the rule and spacing under it


## Room for a row's words beside its icon and button. Set up front: wrapped text with no width
## yet lays out thousands of pixels tall.
func _text_width(r: Array) -> float:
	var w := SHEET_W - 62.0
	if r.size() > 4 and r[4] != "":
		w -= 54.0
	if r.size() > 1 and r[1] != "":
		w -= 44.0 + r[1].length() * 9.0
	return w


func _paginate(rows: Array, room: float) -> Array:
	var pages := [[]]
	var used := 0.0
	for r in rows:
		var h := _row_height(r)
		if used + h > room and pages[-1].size() > 0:
			pages.append([])
			used = 0.0
		pages[-1].append(r)
		used += h
	return pages


func _show_page() -> void:
	for n in _list.get_children():
		n.queue_free()
	for r in _pages[_page]:
		_add_row(_list, r)


func _turn_page(by: int) -> void:
	sound.sfx("thread")
	_page = posmod(_page + by, _pages.size())
	_page_label.text = "Page %d of %d" % [_page + 1, _pages.size()]
	_show_page()


func _add_row(vb: VBoxContainer, r: Array) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	if r.size() > 4 and r[4] != "":
		var icon := TextureRect.new()
		icon.texture = load(("res://textures/%s" if r[4].ends_with(".svg") else "res://textures/%s.png") % r[4])
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(icon)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 1)
	hb.add_child(words)
	var parts: PackedStringArray = r[0].split("\n", true, 1)
	for i in parts.size():
		if parts[i] == "":
			continue
		var l := Label.new()
		l.text = parts[i]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = _text_width(r)
		l.add_theme_font_size_override("font_size", Style.SIZE_MD if i == 0 else Style.SIZE_SM)
		if i > 0:
			l.add_theme_color_override("font_color", Style.COLOR_TEXT_PAPER_MUTED if _paper_sheet else C_BRASS)
		words.add_child(l)
	if r.size() > 1 and r[1] != "":
		var b := Button.new()
		b.text = r[1]
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.mouse_entered.connect(sound.sfx.bind("deny"))
		b.pressed.connect(sound.sfx.bind("thread"))
		if r[2] is Callable:  # a "Locked" button has nothing behind it
			b.pressed.connect(r[2])
		b.disabled = not r[3]
		hb.add_child(b)
		if b.disabled and "$" in r[1]:  # a greyed-out price says what's missing
			var short := "Need $%d more" % (int(r[1].get_slice("$", 1)) - money)
			b.tooltip_text = short
			var why := Label.new()
			why.text = short
			why.custom_minimum_size.x = _text_width(r)
			why.add_theme_font_size_override("font_size", Style.SIZE_SM)
			why.add_theme_color_override("font_color", Style.COLOR_STATUS_WARN if _paper_sheet else Style.COLOR_TEXT_HUD_BLOCKED)
			words.add_child(why)
	var line := ColorRect.new()
	line.color = Color(Style.COLOR_TEXT_PAPER, 0.15) if _paper_sheet else Color(C_BRASS, 0.14)
	line.custom_minimum_size.y = 1
	vb.add_child(line)


func _close_panel() -> void:
	if panel:
		panel.queue_free()
		panel = null
	if is_instance_valid(_side):
		_side.queue_free()
	panel_kind = ""
	_sub_back = Callable()
	get_tree().paused = false
	player.frozen = ferry != null
	_recapture.call_deferred()


## Waits to see if a panel reopened this frame (buying, turning a page): capturing the mouse
## and letting it go again would snap the cursor to the middle of the screen.
func _recapture() -> void:
	if panel == null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ---------- pause, settings, credits ----------

var _sub_back := Callable()  # where Esc goes from a screen opened off the title or pause menu
var settings := SETTING_DEFAULTS.duplicate(true)
## Everything the settings sheet (scripts/settings_ui.gd) can change, with its default. Saved to
## user://settings.cfg, apart from the career save, so it carries across careers.
const SETTING_DEFAULTS := {
	# Graphics and video
	"display_mode": "windowed", "resolution": "1280x720", "vsync": "on", "max_fps": 0,
	"quality": "high", "render_scale": 1.0, "upscaler": "fsr", "aa": "fxaa", "shadows": "high",
	"draw": "high", "detail": "high", "aniso": 8,
	"bloom": true, "haze": true, "bounce": true, "ao": true, "dust": true,
	# Audio
	"master": 1.0, "music": 0.7, "sfx": 0.9, "ambience": 0.8, "night": false, "mono": false, "station": 0,
	# Controls
	"sens": 1.0, "invert": false, "quick_hold": false, "keys": {},
	# Gameplay and interface
	"fov": 75.0, "crosshair": true, "fps_counter": false, "shake": true, "checklist": true,
	# Accessibility
	"text_size": "medium", "text_bg": 0.82, "colorblind": "off",
}
const SETTING_TABS := {
	"video": ["display_mode", "resolution", "vsync", "max_fps", "quality", "render_scale", "upscaler", "aa", "shadows", "draw", "detail", "aniso", "bloom", "haze", "bounce", "ao", "dust"],
	"audio": ["master", "music", "sfx", "ambience", "night", "mono"],
	"controls": ["sens", "invert", "quick_hold", "keys"],
	"game": ["fov", "crosshair", "fps_counter", "shake", "checklist"],
	"access": ["text_size", "text_bg", "colorblind"],
}
## What each quality preset sets. Changing any of these by hand makes the preset "custom".
const QUALITY := {
	"low": {"render_scale": 0.75, "aa": "off", "shadows": "low", "draw": "low", "detail": "low", "aniso": 0,
		"bloom": true, "haze": false, "bounce": false, "ao": false, "dust": false},
	"medium": {"render_scale": 1.0, "aa": "fxaa", "shadows": "medium", "draw": "medium", "detail": "medium", "aniso": 4,
		"bloom": true, "haze": true, "bounce": false, "ao": false, "dust": true},
	"high": {"render_scale": 1.0, "aa": "fxaa", "shadows": "high", "draw": "high", "detail": "high", "aniso": 8,
		"bloom": true, "haze": true, "bounce": true, "ao": true, "dust": true},
	"ultra": {"render_scale": 1.0, "aa": "smaa", "shadows": "ultra", "draw": "high", "detail": "high", "aniso": 16,
		"bloom": true, "haze": true, "bounce": true, "ao": true, "dust": true},
}
const SettingsUI := preload("res://scripts/settings_ui.gd")
const RESOLUTIONS := ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440", "3840x2160"]
const SETTINGS_PATH := "user://settings.cfg"
const CREDITS := [
	["Game\nthaddeuswill. Built with Godot Engine 4.7 (MIT license)."],
	["Plane model: Piper J-3 Cub for FlightGear\nDon Lavelle (model), David Megginson and Jim Wilson, GPLv3. Converted for this game. Source: github.com/wlbragg/J3Cub, and models_raw/j3cub_fg in this game's repository."],
	["Fonts: Big Shoulders Display and Courier Prime (SIL Open Font License), Yellowtail (Apache 2.0), DejaVu Serif Condensed (Bitstream Vera license)\nThe full license texts ship with the game: in the licenses folder on Windows, inside the game data (fonts/) on Mac."],
	["Music: One Step at a Time, La Da Da Guitar\nFrom OpenGameArt.org, CC0 (public domain)."],
	["Music: Apple Cider\nFrom OpenGameArt.org, CC0 (public domain)."],
	["Tool and shop recordings: 68 Workshop Sounds\nFrom OpenGameArt.org, CC0 (public domain)."],
	["100 CC0 Metal and Wood SFX\nFrom OpenGameArt.org, CC0 (public domain)."],
	["Mechanical Sounds, by Brian MacIntosh\nFrom OpenGameArt.org, CC0 (public domain)."],
	["Room tone: The Shop, by LEGIT Audio\nFrom OpenGameArt.org, CC0 (public domain)."],
	["202 More Sound Effects, 100 CC0 SFX #2\nFrom OpenGameArt.org, CC0 (public domain)."],
]


func _load_settings() -> void:
	var f := ConfigFile.new()
	if f.load(SETTINGS_PATH) == OK:
		for key in settings:
			settings[key] = f.get_value("game", key, settings[key])
		if f.get_value("game", "fullscreen", false) and not f.has_section_key("game", "display_mode"):
			settings.display_mode = "borderless"  # from before the settings sheet: one fullscreen switch
	_apply_settings()


func _apply_settings() -> void:
	_apply_audio()
	_apply_keys()
	player.sens = Player.MOUSE_SENS * settings.sens
	player.invert = settings.invert
	if player.cam:
		player.cam.fov = settings.fov
	_apply_display()
	_apply_viewport()
	_apply_graphics()
	_apply_hud()


func _apply_audio() -> void:
	for b in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"], ["Ambience", "ambience"]]:
		var i := AudioServer.get_bus_index(b[0])
		if i >= 0:
			AudioServer.set_bus_volume_db(i, linear_to_db(settings[b[1]]))
	# Night mode and mono live on the master bus: added once, then switched on and off.
	if AudioServer.get_bus_effect_count(0) == 0:
		var comp := AudioEffectCompressor.new()  # loud tool hits come down, quiet room tone comes up
		comp.threshold = -18.0
		comp.ratio = 4.0
		comp.gain = 6.0
		AudioServer.add_bus_effect(0, comp)
		var mono := AudioEffectStereoEnhance.new()
		mono.pan_pullout = 0.0  # no stereo width: both ears get the same mix
		AudioServer.add_bus_effect(0, mono)
	AudioServer.set_bus_effect_enabled(0, 0, settings.night)
	AudioServer.set_bus_effect_enabled(0, 1, settings.mono)


## Display mode and size last applied: a slider drag mustn't resize the window. Static, so it
## outlives a scene reload (quit to title, a new career): reapplying it then snapped a window
## you'd resized or maximized back to the settings size and recentered it.
static var _applied_display := ""


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode({"on": DisplayServer.VSYNC_ENABLED, "adaptive": DisplayServer.VSYNC_ADAPTIVE,
		"off": DisplayServer.VSYNC_DISABLED}[settings.vsync])
	Engine.max_fps = int(settings.max_fps)
	var want: String = settings.display_mode + "@" + settings.resolution
	if want == _applied_display:
		return
	_applied_display = want
	match settings.display_mode:
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"exclusive":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var wh: PackedStringArray = settings.resolution.split("x")
			var size := Vector2i(int(wh[0]), int(wh[1]))
			var screen := DisplayServer.screen_get_usable_rect().size
			size = Vector2i(mini(size.x, screen.x), mini(size.y, screen.y))
			DisplayServer.window_set_size(size)
			DisplayServer.window_set_position(DisplayServer.screen_get_usable_rect().position + (screen - size) / 2)


## Window sizes that fit this screen, for the settings sheet.
func resolution_choices() -> Array:
	var screen := DisplayServer.screen_get_size() if DisplayServer.get_name() != "headless" else Vector2i(3840, 2160)
	var out := []
	for r in RESOLUTIONS:
		var wh: PackedStringArray = r.split("x")
		if int(wh[0]) <= screen.x and int(wh[1]) <= screen.y:
			out.append([r, r.replace("x", " x ")])
	return out


func renderer_has_fsr() -> bool:
	return RenderingServer.get_current_rendering_method() != "gl_compatibility"


## Render scale, upscaling, anti-aliasing, model detail and texture filtering.
func _apply_viewport() -> void:
	var vp := get_viewport()
	var fsr := renderer_has_fsr()
	var scale: float = settings.render_scale
	vp.scaling_3d_scale = scale
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR if not fsr else {"bilinear": Viewport.SCALING_3D_MODE_BILINEAR,
		"fsr": Viewport.SCALING_3D_MODE_FSR, "fsr2": Viewport.SCALING_3D_MODE_FSR2}[settings.upscaler]
	var fsr2_smooths: bool = fsr and settings.upscaler == "fsr2" and scale < 1.0  # FSR 2 does its own anti-aliasing
	var aa: String = "off" if fsr2_smooths else settings.aa
	vp.screen_space_aa = {"fxaa": Viewport.SCREEN_SPACE_AA_FXAA, "smaa": Viewport.SCREEN_SPACE_AA_SMAA}.get(aa, Viewport.SCREEN_SPACE_AA_DISABLED)
	vp.msaa_3d = {"msaa2": Viewport.MSAA_2X, "msaa4": Viewport.MSAA_4X}.get(aa, Viewport.MSAA_DISABLED)
	vp.use_taa = aa == "taa"
	vp.mesh_lod_threshold = {"low": 4.0, "medium": 2.0, "high": 1.0}[settings.detail]
	vp.anisotropic_filtering_level = {0: Viewport.ANISOTROPY_DISABLED, 2: Viewport.ANISOTROPY_2X, 4: Viewport.ANISOTROPY_4X,
		8: Viewport.ANISOTROPY_8X, 16: Viewport.ANISOTROPY_16X}.get(int(settings.aniso), Viewport.ANISOTROPY_8X)
	RenderingServer.directional_shadow_atlas_set_size({"low": 1024, "medium": 2048, "high": 4096, "ultra": 8192}[settings.shadows], true)
	if player.cam:
		player.cam.far = {"low": 600.0, "medium": 1500.0, "high": 4000.0}[settings.draw]


## The settings sheet reads through this: the career's difficulty lives in the save, the rest here.
func get_setting(key: String):
	return difficulty if key == "difficulty" else settings[key]


## Sets one value, saves and applies it. A quality preset fills in everything it covers; touching
## any of those by hand turns the preset to "custom".
func set_setting(value, key: String, _rebuild := true) -> void:
	if key == "difficulty":
		difficulty = value
		_save_game()
		return
	settings[key] = value
	if key == "quality" and QUALITY.has(value):
		for k in QUALITY[value]:
			settings[k] = QUALITY[value][k]
	elif QUALITY.high.has(key):
		settings.quality = "custom"
	_save_settings()


func current_career_locked() -> bool:
	return false  # difficulty can change mid-career: it only decides how much you're told


## A sample to judge a new volume by, once the slider is let go.
func slider_released(key: String) -> void:
	if key in ["master", "sfx", "ambience"]:
		sound.sfx("tray")


func reset_settings(tab: String) -> void:
	for k in SETTING_TABS.get(tab, []):
		settings[k] = SETTING_DEFAULTS[k].duplicate(true) if SETTING_DEFAULTS[k] is Dictionary else SETTING_DEFAULTS[k]
	_save_settings()


# ---------- keys ----------

## Every rebindable action's default keys (the first one is what the settings sheet shows).
const DEFAULT_KEYS := {
	"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE], "interact": [KEY_E],
	"wallet": [KEY_TAB], "clipboard": [KEY_J], "logbook": [KEY_L],
	"throttle_up": [KEY_W], "throttle_down": [KEY_S], "rudder_left": [KEY_A], "rudder_right": [KEY_D],
	"stick_forward": [KEY_UP], "stick_back": [KEY_DOWN], "starter": [KEY_SPACE],
	"fuel_valve": [KEY_F], "master": [KEY_M], "primer": [KEY_P], "mags": [KEY_I], "carb_heat": [KEY_H],
	"playtest_note": [KEY_F8], "manual": [KEY_N], "call_good": [KEY_G], "call_bad": [KEY_B], "tasks": [KEY_T],
}


func _apply_keys() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var custom: Dictionary = settings.keys
		for k in ([int(custom[action])] if custom.has(action) else DEFAULT_KEYS[action]):
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func rebind(action: String, keycode: int) -> void:
	var custom: Dictionary = settings.keys.duplicate()
	custom[action] = keycode
	set_setting(custom, "keys")


## The key an action is on now, as printed on the keycap ("W", "Space").
func key_name(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode) if DisplayServer.get_name() != "headless" else ev.physical_keycode)
	return "-"


# ---------- interface and accessibility ----------

var fps_label: Label
var _color_filter: ColorRect


## Message size and backing, the frame counter and the color-vision filter.
func _apply_hud() -> void:
	if msg == null:
		return
	msg.add_theme_font_size_override("font_size", {"small": 14, "medium": 16, "large": 20, "xl": 24}[settings.text_size])
	var sb: StyleBoxFlat = msg.get_theme_stylebox("normal").duplicate()
	sb.bg_color = Color(C_EARTH, settings.text_bg)
	msg.add_theme_stylebox_override("normal", sb)
	if fps_label == null:
		fps_label = Label.new()
		fps_label.add_theme_font_override("font", Style.display(700))
		fps_label.add_theme_font_size_override("font_size", Style.SIZE_SM)
		fps_label.add_theme_color_override("font_color", Style.COLOR_TEXT_HUD)
		fps_label.add_theme_constant_override("outline_size", 4)
		fps_label.add_theme_color_override("font_outline_color", Style.COLOR_SURFACE_HUD)
		fps_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		fps_label.position += Vector2(-90, 6)
		fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var layer := CanvasLayer.new()
		layer.layer = 99
		add_child(layer)
		layer.add_child(fps_label)
		_color_filter = ColorRect.new()  # over everything, 3D and UI alike
		_color_filter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_color_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/color_vision.gdshader")
		_color_filter.material = mat
		var top := CanvasLayer.new()
		top.layer = 100
		add_child(top)
		top.add_child(_color_filter)
	fps_label.visible = settings.fps_counter
	_color_filter.visible = settings.colorblind != "off"
	(_color_filter.material as ShaderMaterial).set_shader_parameter("mode", {"off": 0, "protan": 1, "deutan": 2, "tritan": 3}[settings.colorblind])


func _save_settings() -> void:
	var testing: bool = "--monkey" in OS.get_cmdline_user_args() or "--self-test" in OS.get_cmdline_user_args()
	if testing:  # random sliders and test stations must not reach the player's settings
		_apply_settings()
		return
	var f := ConfigFile.new()
	for key in settings:
		f.set_value("game", key, settings[key])
	f.save(SETTINGS_PATH)
	_apply_settings()


func _set_setting(value, key: String) -> void:
	set_setting(value, key)


## A screen opened from the title or pause menu: `back` returns there, by button or by Esc.
func _sub_panel(title: String, rows: Array, back: Callable) -> VBoxContainer:
	var was_paused := get_tree().paused
	var vb := _open_panel(title, rows + [["", "Back", back, true]], false)
	get_tree().paused = was_paused
	_sub_back = back
	return vb


## Once something has gone wrong in flight the outcome has to land, or quitting would dodge it.
func _can_quit() -> bool:
	return ferry == null or not (ferry.struck or ferry._result != "")


func _open_pause() -> void:
	var parked_in_cockpit: bool = ferry != null and ferry.alt <= 0.0 and ferry.speed < 1.0 and ferry._result == ""
	var fresh := panel == null
	_close_panel()
	panel_closable = true
	# The world dims behind an opaque menu: nothing shows through the words.
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.5)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(scrim)
	var sheet := PanelContainer.new()
	sheet.anchor_bottom = 1.0
	sheet.offset_right = PAUSE_W
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_HUD
	sb.border_width_right = 2
	sb.border_color = Color(C_BRASS, 0.5)
	sb.content_margin_left = Style.SPACE_8 + Style.SPACE_2
	sb.content_margin_right = Style.SPACE_8
	sb.content_margin_top = Style.SPACE_8 + Style.SPACE_4
	sb.content_margin_bottom = Style.SPACE_8
	sheet.add_theme_stylebox_override("panel", sb)
	root.add_child(sheet)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.SPACE_2)
	sheet.add_child(col)
	col.add_child(Style.label("AIRPLANE RESCUE", "hud_muted", Style.SIZE_XS, 800))
	col.get_child(-1).add_theme_font_override("font", Style.caps(800, Style.SIZE_XS))
	var title := Style.label("PAUSED", "hud", Style.SIZE_3XL, 900)
	title.add_theme_font_override("font", Style.caps(900, Style.SIZE_3XL))
	col.add_child(title)
	# Where you stand, in figures: the day, the town, the money (the paused game, at a glance).
	var at := Label.new()
	at.text = "DAY %d   %s   $%s" % [floori(day), location.to_upper(), _thousands(money)]
	at.add_theme_font_override("font", Style.figures(true))
	at.add_theme_font_size_override("font_size", Style.SIZE_SM)
	at.add_theme_color_override("font_color", Style.COLOR_TEXT_HUD_MUTED)
	col.add_child(at)
	var gap := Control.new()
	gap.custom_minimum_size.y = Style.SPACE_6
	col.add_child(gap)
	var first := _pause_button(col, "Resume", _close_panel, "primary", "Esc")
	if parked_in_cockpit:
		_pause_button(col, "Climb out of the plane", _leave_cockpit)
	_pause_button(col, "Settings", _open_settings.bind(_open_pause))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(fill)
	var rule := ColorRect.new()
	rule.color = Color(C_BRASS, 0.35)
	rule.custom_minimum_size.y = 1
	col.add_child(rule)
	if _can_quit():
		var note := Style.label("Saved after every step: quitting loses nothing.", "hud_muted", Style.SIZE_SM, 600)
		col.add_child(note)
		_pause_button(col, "Quit to title", _quit_to_title)
		_pause_button(col, "Quit to desktop", _quit_game)
		_pause_button(col, "Start a new career", _confirm_restart)  # here and on the title screen, behind a yes: never in a pocket
	else:
		var note := Style.label("Finish the emergency first: what happens next counts.", "blocked", Style.SIZE_SM, 700)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(note)
	root.set_meta("pause", true)
	ui.add_child(root)
	panel = root
	first.grab_focus.call_deferred()
	if fresh:  # slides out from the edge, like the paperwork
		sheet.modulate.a = 0.0
		sheet.position.x = -30.0
		var tw := sheet.create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(sheet, "modulate:a", 1.0, 0.16)
		tw.tween_property(sheet, "position:x", 0.0, 0.16)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true
	get_tree().paused = true


const PAUSE_W := 420.0  # a menu, not a page of paperwork: narrower than SHEET_W


## Where the open sheet ends on the left, so a message centers in the world beside it, not under it.
func _sheet_edge() -> float:
	if panel is PanelContainer:
		return SHEET_W
	if is_instance_valid(panel) and panel.has_meta("pause"):
		return PAUSE_W
	return 0.0


## 12450 -> "12,450" (negative too): money reads at a glance.
static func _thousands(n: int) -> String:
	var t := str(absi(n))
	var out := ""
	while t.length() > 3:
		out = "," + t.substr(t.length() - 3) + out
		t = t.substr(0, t.length() - 3)
	return ("-" if n < 0 else "") + t + out


## One pause-menu item: full width, left-aligned so the words line up down the column, with an
## optional key on the right. "primary" is the one red button (Resume); the rest are quiet.
func _pause_button(col: VBoxContainer, text: String, act: Callable, kind := "quiet", key := "") -> Button:
	var b := Button.new()
	b.text = text.to_upper()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 48
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", Style.caps(800, Style.SIZE_MD))
	b.add_theme_font_size_override("font_size", Style.SIZE_MD)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var st := StyleBoxFlat.new()
		if kind == "primary":
			st.bg_color = Style.COLOR_ACTION_PRIMARY.lightened(0.08 if state in ["hover", "focus"] else 0.0)
		else:
			st.bg_color = Color(Style.COLOR_TEXT_HUD, {"hover": 0.1, "focus": 0.1, "pressed": 0.16}.get(state, 0.0))
		if state == "focus":
			st.border_color = Style.COLOR_FOCUS
			st.set_border_width_all(2)
			st.draw_center = true
		st.set_corner_radius_all(Style.RADIUS_SM)
		st.content_margin_left = Style.SPACE_4
		st.content_margin_right = Style.SPACE_4
		b.add_theme_stylebox_override(state, st)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Style.COLOR_ACTION_PRIMARY_TEXT if kind == "primary" else Style.COLOR_TEXT_HUD)
	b.pressed.connect(sound.sfx.bind("thread"))
	b.pressed.connect(act)
	col.add_child(b)
	if key != "":
		var k := Label.new()
		k.text = key.to_upper()
		k.add_theme_font_override("font", Style.caps(700, Style.SIZE_XS))
		k.add_theme_font_size_override("font_size", Style.SIZE_XS)
		k.add_theme_color_override("font_color", Color(Style.COLOR_ACTION_PRIMARY_TEXT if kind == "primary" else Style.COLOR_TEXT_HUD_MUTED, 0.8))
		k.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		k.offset_left = -60
		k.offset_right = -Style.SPACE_4
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		k.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(k)
	return b


func _notification(what: int) -> void:  # alt-tabbing away shouldn't leave a take-off running
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and panel == null and not is_instance_valid(_loader) and not "--self-test" in OS.get_cmdline_user_args() and not "--monkey" in OS.get_cmdline_user_args():
		_open_pause()


## Back out of the cockpit before take-off: nothing lost, the plane's where you left it.
func _leave_cockpit() -> void:
	_apply_graphics()
	gauges.clear()
	ferry.queue_free()
	ferry = null
	prompt.text = ""
	sound.engine = 0.0
	sound.stop_loop()
	player.cam.make_current()
	_close_panel()
	_load_field(location, current_job)


func _quit_game() -> void:
	if "--monkey" in OS.get_cmdline_user_args():  # the monkey test keeps running past a quit button
		_quit_to_title()
	else:
		get_tree().quit()


func _quit_to_title() -> void:
	_save_game()
	get_tree().paused = false
	get_tree().reload_current_scene()


## The settings sheet (scripts/settings_ui.gd), over the title screen or the pause menu. Esc and
## Back return to where it was opened from; a paused game stays paused.
func _open_settings(back: Callable) -> void:
	var was_paused := get_tree().paused
	_close_panel()
	get_tree().paused = was_paused
	var sheet = SettingsUI.new()
	ui.add_child(sheet)
	sheet.setup(self, back)
	panel = sheet
	panel_closable = false
	_sub_back = back
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


func _open_credits(back: Callable) -> void:
	_sub_panel("Credits", CREDITS, back)


var standing_at := ""  # the inspection spot you last pressed E at ("" = reading the clipboard)

const HANGAR_SPOT := Vector3(-16, 0, -13)  # plane origin when parked inside (main wheels), nose to the door
const TANK_GAL := 12  # the Cub's tank
const AVGAS_PER_GAL := 6.5


func _toggle_parked() -> void:
	_move_plane("apron" if current_job.get("parked", "apron") == "hangar" else "hangar")


## Push the plane into the hangar or roll it back out (by hand: a quarter hour of work).
func _move_plane(to: String) -> void:
	current_job.parked = to
	_advance(0.01)
	if not current_job:
		return
	plane.queue_free()
	visuals.clear()
	_build_plane(current_job)
	_say("Pushed it into the hangar." if to == "hangar" else "Rolled it out onto the apron.")
	_save_game()
	_open_inspection()


## Fuel the plane to full from the truck (on the apron, never inside, no stale fuel in the
## tanks). Returns what it cost (0 if nothing was pumped).
## Filling the tanks is the only choice the pump offers, so this is what fueling costs.
func _fuel_bill(job: Dictionary) -> int:
	return roundi(roundi((1.0 - job.get("fuel", 1.0)) * TANK_GAL) * AVGAS_PER_GAL)


func _fuel_plane() -> int:
	var job: Dictionary = current_job
	var gal := roundi((1.0 - job.get("fuel", 1.0)) * TANK_GAL)
	var cost := _fuel_bill(job)
	var blocked: bool = job.get("parked", "apron") == "hangar" or (job.faults.has("stale_fuel") and not job.fixed.has("stale_fuel"))
	if gal <= 0 or money < cost or blocked:  # never indoors, never onto stale gas
		return 0
	money -= cost
	_spend(job, "fuel", cost)
	job.fuel = 1.0
	_advance(0.01)
	_say("Pumped %d gal of 100LL into the %s ($%d)." % [gal, job.type, cost])
	_save_game()
	return cost


func _pump_and_reopen() -> void:
	_fuel_plane()
	_open_truck()


## The fuel truck by the hangar: fuel the plane, or fill a jerry can for a stale-fuel job.
func _open_truck() -> void:
	tutorial.walk("truck")  # first time here: a walkthrough of this menu (tutorial.gd)
	var rows := []
	var job = current_job
	if job:
		var gal := roundi((1.0 - job.get("fuel", 1.0)) * TANK_GAL)
		var cost := _fuel_bill(job)
		if job.faults.has("stale_fuel") and not job.fixed.has("stale_fuel"):
			rows.append(["The %s's tanks are full of stale fuel. Drain and sump them first (left wing)." % job.type])
		elif job.get("parked", "apron") == "hangar":
			rows.append(["The plane's in the hangar. Roll it out to the apron first: no fueling indoors."])
		elif gal <= 0:
			rows.append(["The %s's tanks are full." % job.type])
		else:
			rows.append(["Fuel the %s: %d gal of 100LL at $%.2f a gallon" % [job.type, gal, AVGAS_PER_GAL], "Pump $%d" % cost,
				_pump_and_reopen, money >= cost])
	else:
		rows.append(["No plane to fuel at this field."])
	rows.append(["Jerry can of fresh avgas, for a stale-fuel job (have %d)" % inventory.get("Fresh avgas", 0), "$90",
		_buy_can, money >= 90])
	_open_panel("Fuel truck", rows)


func _buy_can() -> void:
	money -= 90
	inventory["Fresh avgas"] = inventory.get("Fresh avgas", 0) + 1
	if current_job:
		_spend(current_job, "fuel", 90)
	_refresh_parts_table()
	_save_game()
	_open_truck()


## Model shown on the parts table for a part you own (a labeled crate if there's no model).
const PART_MODELS := {"Brake shoe set": "brakes_ok", "Magneto": "magneto_ok", "Starter motor": "starter_ok",
	"Battery": "battery_ok", "Propeller": "propeller_ok", "Tire & tube": "tire_ok"}
var _parts_table: Node3D


## A trestle table by the apron: every part and material you've bought sits on it, labeled.
func _build_parts_table() -> void:
	var at := Vector3(-6.5, 0, 4.0)
	box(world, Vector3(3.2, 0.08, 1.1), at + Vector3(0, 0.86, 0), tmat("workbench_top", Color.WHITE, 0.8), true)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(world, Vector3(0.08, 0.82, 0.08), at + Vector3(sx * 1.45, 0.41, sz * 0.45), tmat("bark", Color(0.55, 0.45, 0.35)))
	interactable(world, at + Vector3(0, 1.1, 0), Vector3(3.4, 1.0, 1.3), "parts_table")
	_icon3d("parts", at + Vector3(0, 2.0, 0))
	_parts_table = Node3D.new()
	_parts_table.position = at + Vector3(0, 0.9, 0)
	world.add_child(_parts_table)
	_refresh_parts_table()


var _parts_table_dirty := false


## Asks for the parts table to be rebuilt, once, at the end of the frame. Finishing a run of jobs
## (or buying several things) used to rebuild every label each time, all in one frame; that many
## Label3D nodes made and freed back to back crashed the engine now and then (iteration 2).
func _refresh_parts_table() -> void:
	if _parts_table_dirty:
		return
	_parts_table_dirty = true
	_rebuild_parts_table.call_deferred()


func _rebuild_parts_table() -> void:
	_parts_table_dirty = false
	if not is_instance_valid(_parts_table):
		return
	for ch in _parts_table.get_children():
		_parts_table.remove_child(ch)  # gone now, not at the end of the frame
		ch.queue_free()
	var items := []
	for k in inventory:
		if inventory[k] > 0:
			items.append(k)
	for i in mini(items.size(), 10):
		var k: String = items[i]
		var x := -1.35 + (i % 5) * 0.68
		var z := -0.25 if i < 5 else 0.25
		if PART_MODELS.has(k):
			model(_parts_table, PART_MODELS[k], Vector3(x, 0.18, z), 0.36)
		else:
			box(_parts_table, Vector3(0.34, 0.22, 0.26), Vector3(x, 0.11, z), tmat("workbench_top", Color(0.9, 0.75, 0.55), 2.0))
		var l := Label3D.new()
		l.text = ("%s x%d" % [k, inventory[k]]) if inventory[k] > 1 else k
		l.font_size = 22
		l.pixel_size = 0.004
		l.outline_size = 8
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.position = Vector3(x, 0.42 + (i % 2) * 0.2, z)  # staggered so neighbors don't overlap
		_parts_table.add_child(l)


func _open_parts_table() -> void:
	tutorial.walk("parts_table")  # first time here: a walkthrough of this menu (tutorial.gd)
	var rows := []
	for k in inventory:
		if inventory[k] > 0:
			rows.append(["%s  x%d" % [k, inventory[k]]])
	if rows.is_empty():
		rows.append(["Nothing yet. Buy parts at the PARTS shed, or mail-order tools and materials from the hangar."])
	rows.append(["At the plane, open the work scene and pick the new part up off the bench to fit it."])
	_open_panel("Parts on hand", rows)


## Floating markers over the plane's inspection spots, visible through it so you can find them:
## yellow "?" not checked yet, orange "!" something found there still needs work, green "OK" done.
func _refresh_markers() -> void:
	if not plane or not current_job:
		return
	var job: Dictionary = current_job
	for z in ZONES:
		var m: Label3D = plane.get_node_or_null("marker_" + z)
		if not m:
			m = Label3D.new()
			m.name = "marker_" + z
			m.set_meta("kind", "marker")  # cleared with the other inspection helpers at take-off
			m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			m.no_depth_test = true
			m.font_size = 72
			m.fixed_size = true  # the same size at any distance: up close they used to fill the view
			m.pixel_size = 0.00085
			m.outline_size = 18
			m.position = ZONES[z].pos + Vector3(0, ZONES[z].size.y * 0.5 + 0.25, 0)
			m.render_priority = 2
			m.outline_render_priority = 1
			m.add_child(_marker_sprite("glow", [[0.0, 0.8], [0.55, 0.45], [1.0, 0.0]], 0.0012))
			m.add_child(_marker_sprite("ring", [[0.0, 0.0], [0.83, 0.0], [0.86, 1.0], [0.93, 1.0], [0.96, 0.0], [1.0, 0.0]], 0.00075))
			plane.add_child(m)
		var open: bool = job.faults.any(func(id): return FAULTS[id].zone == z and job.found.has(id) and not job.fixed.has(id))
		if z == "cabin" and job.get("runup", "") != "ran" and job.checked.has(z):
			open = true  # the run-up still waits here
		# "?" (not looked at yet) on Easy and Medium; "!" (written up, not fixed) on every difficulty:
		# you wrote it up, so it's your own note, not a hint, and it stays until the job's done.
		m.visible = open or (guide("medium") and not job.checked.has(z))
		if open:
			m.text = "!"
			m.modulate = Color(1.0, 0.55, 0.15)
		elif not job.checked.has(z):
			m.text = "?"
			m.modulate = Color(1.0, 0.9, 0.3)
		else:
			m.text = ""
		var ring: Sprite3D = m.get_node("ring")
		ring.visible = m.text != ""
		ring.modulate = m.modulate
		ring.scale = Vector3.ONE
		m.get_node("glow").visible = false
		m.set_meta("tint", m.modulate)
	_lit_zone = ""


## One billboard behind a marker, drawn from a radial gradient: stops are [offset, alpha].
func _marker_sprite(sprite_name: String, stops: Array, pixel: float) -> Sprite3D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	g.colors = PackedColorArray(stops.map(func(s): return Color(1, 1, 1, s[1])))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var s := Sprite3D.new()
	s.name = sprite_name
	s.texture = tex
	s.pixel_size = pixel
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.fixed_size = true
	s.shaded = false
	s.visible = false
	return s


const MARKER_REACH := 6.0  # meters
var _lit_zone := ""


## The spot whose marker is under the cursor, or "". Markers float above their spots and have no
## body for the interact ray to hit, so this goes by where they sit on screen.
func _aimed_marker() -> String:
	if not plane or not current_job:
		return ""
	var cam: Camera3D = player.cam
	var screen := get_viewport().get_visible_rect().size
	var closest := 24.0 * screen.y / 720.0  # about the ring's radius
	var aimed := ""
	for z in ZONES:
		var m: Label3D = plane.get_node_or_null("marker_" + z)
		if not m or m.text == "" or cam.is_position_behind(m.global_position) or cam.global_position.distance_to(m.global_position) > MARKER_REACH:
			continue
		var off: float = cam.unproject_position(m.global_position).distance_to(screen / 2)
		if off < closest:
			closest = off
			aimed = z
	return aimed


## Lights the marker you're aiming at, the moment E would select it.
func _light_marker(zone: String) -> void:
	if zone == _lit_zone or not plane:
		return
	for z in [_lit_zone, zone]:
		var m: Label3D = plane.get_node_or_null("marker_" + z) if z != "" else null
		if not m or m.text == "":
			continue
		var on: bool = z == zone
		var tint: Color = m.get_meta("tint")
		var ring: Sprite3D = m.get_node("ring")
		var glow: Sprite3D = m.get_node("glow")
		m.modulate = Color.WHITE if on else tint
		ring.modulate = Color.WHITE if on else tint
		ring.scale = Vector3.ONE * (1.25 if on else 1.0)
		glow.modulate = tint
		glow.visible = on
	_lit_zone = zone


## The work order: what the owner reported, which spots you've checked, and what you found.
## `at` is the spot you're standing at: you can only start work there (repairs at their own
## spot, the run-up and take-off from the cabin). From the clipboard ("") it's read-only.
func _open_inspection(at := standing_at) -> void:
	tutorial.walk("work_order")  # first time here: a walkthrough of this menu (tutorial.gd)
	station_zone = ""
	var job: Dictionary = current_job
	var rows := [["Owner reports: " + _symptoms(job)],
		["Owner waits %d more day(s)" % maxi(0, ceili(job.deadline - day))],
		["Walk-around: %d of %d spots checked" % [job.checked.size(), ZONES.size()]]]
	var tried: Dictionary = job.get("tried", {})
	var shown := {}
	if job.get("annual", false):
		rows.append(["Annual inspection: no complaints to go on. Find what you find."])
	if at != "" and job.get("washed", true):
		rows.append(["Open it up and work on anything at the %s." % ZONES[at].name, "Open up the " + ZONES[at].name, func(): _open_station(at), true])
	if CITIES[job.city][2] == "snow" and not job.get("preheated", false):
		rows.append(["Cold-soaked below 20 F: preheat before any run-up.", "Preheat the engine" if at == "engine" else "", _preheat, at == "engine"])
	for id in job.faults:
		var t := _test_for(job, id)
		if t != "" and job.get("sym", {}).has(id):  # heard it, can't name it yet
			var what: String = job.get("dnote", {}).get(id, TESTS[job.diag[id][0]].clue)
			var tz: String = TESTS[t].zone
			if job.get("dready", {}).has(id):
				rows.append(["%s\n%s done: make your call." % [what, TESTS[t].name], "Make the call", func(): _verdict(id), true])
			elif not guide("medium"):  # hard: you pick the test
				rows.append([what])
			elif at == tz:
				rows.append(["%s\nNext: %s." % [what, TESTS[t].name.to_lower()], "Run the " + TESTS[t].name.to_lower(), func(): _diagnose(id), true])
			else:
				rows.append(["%s\nNext: %s, at the %s." % [what, TESTS[t].name.to_lower(), ZONES[tz].name]])
			continue
		if not job.found.has(id) or shown.has(id):
			continue
		var f: Dictionary = FAULTS[id]
		if f.get("ground", false):
			rows.append(["%s\n%s Ground it and call the owner." % [f.name, f.get("ground_why", "No field fix: the engine comes out for a teardown.")],
				"Ground it" if at != "" else "", _ground_job, at != ""])
			continue
		if job.fixed.has(id):
			shown[id] = true
			rows.append(["OK  -  " + FAULTS[id].name, "", null, false, _fault_icon(id)])
			continue
		var alt: String = SUSPECTS.get(id, "")
		var could := [id]
		if alt != "" and not tried.has(alt) and not job.fixed.has(alt):
			could = [id, alt]
			could.sort()  # alphabetical, so the order doesn't give the answer away
		for c in could:
			if not shown.has(c):
				shown[c] = true
				rows.append(_fault_row(c, at, could.size() > 1))
	for c in tried:
		rows.append(["Replaced: %s. %s" % [FAULTS[c].name, "It made no difference." if tried[c] else "Run it up again to see if that cured it."], "", null, false, _fault_icon(c)])
	if not job.get("washed", true):
		rows.append(["Sat %d years: filthy, lichen on the wings." % job.years, "Wash it down" if at != "" else "", _wash, at != ""])
	var ran: bool = job.get("runup", "") == "ran"
	var runup_text: String = "Run-up: " + {"": "not done yet", "dead": "wouldn't start", "ran": "engine runs"}[job.get("runup", "")]
	if at == "cabin":
		rows.append([runup_text, "Sit in & run it up", _start_runup, true])
	else:
		rows.append([runup_text + ". Done from the cabin."])
	var all_checked: bool = job.checked.size() == ZONES.size() and ran
	var fuel: float = job.get("fuel", 1.0)
	rows.append(["Fuel: %d of %d gal%s" % [roundi(fuel * TANK_GAL), TANK_GAL, "" if fuel >= 0.5 else ". Needs at least half tanks to fly out: fuel it at the truck by the hangar."]])
	var in_hangar: bool = job.get("parked", "apron") == "hangar"
	if at != "":
		rows.append(["Parked %s." % ("in the hangar" if in_hangar else "on the apron"),
			"Roll it out to the apron" if in_hangar else "Push it into the hangar", _toggle_parked, true])
	var open_item: bool = job.faults.any(func(id): return job.found.has(id) and not job.fixed.has(id))
	var done: bool = ran and not open_item and cowl_closed(job)  # you can sign what you've seen; what you skipped is on you
	if ran and not open_item and not cowl_closed(job) and guide("medium"):
		rows.append(["The engine cowling's still off: close it up at the engine before you sign it off."])
	if not guide("medium"):  # hard: signing off is your call, and so is what's wrong with it
		if at == "cabin" and fuel >= 0.5 and not in_hangar:
			rows.append(["Sign the logbook and fly it out to the owner.", "Sign off & take off", _hard_take_off, true])
		_open_panel(("Work order: " if at != "" else "Clipboard: ") + job.type + (("  (at the %s)" % ZONES[at].name) if at != "" else ""), rows, true)
		_refresh_markers()
		return
	var signed: bool = job.get("signed", false)
	var ready: bool = done and signed and fuel >= 0.5 and not in_hangar
	if done and not signed:
		var skipped: int = ZONES.size() - job.checked.size()
		rows.append(["Logbook not signed\n" + ("No plane leaves until the work is written up and signed for return to service." if skipped == 0
			else "%d spot%s never checked. You can sign anyway, but anything you didn't look at will find you in the air." % [skipped, "" if skipped == 1 else "s"]),
			"Write up the logbook" if at != "" else "", _open_signoff, at != ""])
	elif ready and at == "cabin":
		rows.append(["Airworthy! Fly it out to the owner.", "Climb in & take off (+$%d)" % job.reward, _start_ferry, true])
	elif done:
		rows.append(["Airworthy! " + ("Roll it out of the hangar, " if in_hangar else "") + ("fuel it at the truck, " if fuel < 0.5 else "") + "then climb in at the cabin to fly it out."])
	elif not all_checked:
		rows.append(["Check every spot and do a run-up before you sign it off."])
	_open_panel(("Work order: " if at != "" else "Clipboard: ") + job.type + (("  (at the %s)" % ZONES[at].name) if at != "" else ""), rows, true,
		"stamp_airworthy" if done and signed else ("stamp_inspected" if all_checked else ""))
	_refresh_markers()


func _fault_icon(id: String) -> String:
	return "icon_" + id if ResourceLoader.exists("res://textures/icon_%s.png" % id) else ""


func _fault_row(id: String, at: String, suspect: bool) -> Array:
	var f: Dictionary = FAULTS[id]
	var title: String = ("Suspect: " if suspect else "") + f.name
	if current_job != null and current_job.get("aid", {}).get("runup", false) and RUNUP_DAMAGE.has(id) and not current_job.fixed.has(id):
		title = "DON'T RUN IT YET: " + title + ". " + RUNUP_DAMAGE[id][2]  # after running one unready (E4)
	var text := "%s\n%s" % [title, "\n".join(writeup(id))]
	if f.zone != "engine" or guide("easy"):
		if at == f.zone:
			return [text, "Work on it", func(): _repair(id), true, _fault_icon(id)]
	var where := "Open up the %s and work on it there." % ZONES[f.zone].name if at == f.zone else "Work on it at the %s." % ZONES[f.zone].name
	return [text + "\n" + where, ("Open up the " + ZONES[f.zone].name) if at == f.zone else "", func(): _open_bay(f.zone), at == f.zone, _fault_icon(id)]


## The service manual page for a job: the one whose "job" (or id) is this scene.
func manual_page(id: String) -> Dictionary:
	for p in manual_data.get("pages", []):
		if p.get("job", "") == id or p.id == id:
			return p
	return {}


var _fig_cache := {}


## A discrepancy write-up as a mechanic puts it on the work order: what was found and where, what
## it takes to put right (the manual's page and figure, so you can look it up), and the parts with
## their numbers and how many you have. Lines, without the title.
func writeup(id: String) -> PackedStringArray:
	var f: Dictionary = FAULTS[id]
	var out: PackedStringArray = []
	var job: Dictionary = current_job if current_job else {}
	var seen: String = clue(id) if CLUES.has(id) else String(job.get("dnote", {}).get(id, f.get("symptom", f.name)))
	var at: String = PLACES.get(id, ZONES[f.zone].name)
	out.append("Found: %s%s (%s, %s)." % [seen.substr(0, 1).to_upper(), seen.substr(1).trim_suffix("."), ZONES[f.zone].name, at.to_lower()])
	var p := manual_page(id)
	if not p.is_empty():
		if _fig_cache.is_empty():
			_fig_cache = ManualUI.figure_numbers(manual_data)
		var ch: String = String(p.ata)
		for c in manual_data.get("chapters", []):
			if c.ata == p.ata:
				ch = "%s, %s" % [c.ata, String(c.title).to_lower()]
		var fig: String = _fig_cache.get("page:" + p.id, "")
		out.append("Fix: service manual chapter %s, \"%s\"%s. Press %s." % [ch, String(p.title), (", figure " + fig) if fig != "" else "", key_name("manual")])
		var steps: Array = p.get("steps", [])
		if steps.size() > 0:
			out.append("First: " + String(steps[0]))
	var pns: PackedStringArray = []
	for pid in p.get("parts", []):
		for q in parts_data.get("parts", []):
			if q.id == pid and String(q.get("no", "")) != "":
				pns.append(String(q.no))
	var need := "None" if f.part == "" else "%s, have %d in stock" % [f.part, inventory.get(f.part, 0)]
	out.append("Parts: %s%s." % [need, ("  (P/N " + ", ".join(pns.slice(0, 3)) + ")") if pns.size() > 0 else ""])
	if String(p.get("caution", "")) != "":
		out.append("Caution: " + String(p.caution))
	return out


## Each town's shed stocks only some parts (fixed per town); the rest come by mail, slower and dearer.
func _stocked(part_id: String) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(location + part_id)
	return r.randf() < 0.6


## What this town's shed charges for a fault's part: shelf price, or +25% by mail.
func _price(id: String) -> int:
	return FAULTS[id].cost if _stocked(id) else int(FAULTS[id].cost * 1.25)


# ---------- test instruments: one in hand at a time ----------

## The test instruments. Hand tools ride in your roll; these live in the red toolbox by the plane,
## and only the one in your hand works: its tests show up on the parts it fits, nothing else does.
## (docs/quick-specs/engine-bay-proposal-2026-11-14.md, tool-gating.)
const INSTRUMENTS := ["tester", "timing", "punch"]
var held := ""  # the instrument in your hand ("" = none)


func _open_kit() -> void:
	tutorial.walk("kit")  # first time here: a walkthrough of this menu (tutorial.gd)
	var rows := [["Your test instruments. Take one in hand; its tests show up on the parts it fits."]]
	for t in INSTRUMENTS:
		var name: String = SUPPLIES[t].name
		if not tools.has(t):
			rows.append(["%s: not in the box. Buy one at a parts counter or from the hangar catalog." % name])
		elif held == t:
			rows.append(["%s: in your hand." % name, "Put it back", func(): _hold(""), true])
		else:
			rows.append([name, "Take it", func(): _hold(t), true])
	_open_panel("Toolbox", rows)


func _hold(t: String) -> void:
	held = t
	sound.sfx("tray")
	_say(("You've got the %s." % SUPPLIES[t].name.to_lower()) if t != "" else "Put it back in the box.")
	_save_game()
	_open_kit()


## The hangar toolbox: take tools into your roll (they travel with you) or put them back.
## Tools and the materials repairs use up. Nothing is free: buy at a parts shed that stocks
## it, or mail-order it from the hangar (1 day, +25%). You start with a screwdriver and a rag.
const SUPPLIES := {
	"ratchet": {"name": "Ratchet & sockets", "cost": 140, "tool": true},
	"torque": {"name": "Torque wrench", "cost": 260, "tool": true},
	"pliers": {"name": "Safety-wire pliers", "cost": 75, "tool": true},
	"tester": {"name": "Differential compression tester", "cost": 180, "tool": true},
	"timing": {"name": "Timing light", "cost": 90, "tool": true},
	"punch": {"name": "Fabric punch tester", "cost": 45, "tool": true},
	"Dope": {"name": "Dope (can, 6 uses)", "cost": 14, "qty": 6},
	"Aviation oil": {"name": "Aviation oil (quart)", "cost": 9, "qty": 1},
	"Gasket": {"name": "Gasket assortment (10)", "cost": 30, "qty": 10},
	"Brake fluid": {"name": "Brake fluid (can, 2 uses)", "cost": 12, "qty": 2},
	"Safety wire": {"name": "Safety wire (spool, 10 uses)", "cost": 25, "qty": 10},
	"Cotter pin": {"name": "Cotter pins (box of 10)", "cost": 15, "qty": 10},
	"Penetrant": {"name": "Penetrant (can, 3 uses)", "cost": 12, "qty": 3},
}
const STARTER_TOOLS := {"screwdriver": true, "rag": true}
## A new career's shelf: enough consumables that the first jobs don't stall for one gasket.
const STARTER_SUPPLIES := {"Gasket": 4, "Safety wire": 5, "Cotter pin": 5}
## A career's first call is one short job you can do with the starter screwdriver and rag.
const FIRST_JOBS := ["water_fuel", "bird_nest"]


## Each town's shed stocks a fixed part of the list.
func _on_shelf(key: String) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(location + key)
	return r.randf() < 0.55


## What it costs to get this from where you stand: shelf price, or mail order at +25%.
func _supply_price(key: String) -> int:
	return int(SUPPLIES[key].cost) if _on_shelf(key) else int(SUPPLIES[key].cost * 1.25)


func _supply_have(key: String) -> String:
	var s: Dictionary = SUPPLIES[key]
	if s.get("tool", false):
		return "owned" if tools.has(key) else "not owned"
	return "%d left" % inventory.get(key, 0)


func _supply_row(key: String, mail: bool) -> Array:
	var s: Dictionary = SUPPLIES[key]
	var owned: bool = s.get("tool", false) and tools.has(key)
	var price := int(s.cost * 1.25) if mail else int(s.cost)
	var icon: String = "work/tool_" + key if ResourceLoader.exists("res://textures/work/tool_%s.png" % key) else ""
	if owned:
		return ["%s  -  owned" % s.name, "", null, false, icon]
	return ["%s  (%s)%s" % [s.name, _supply_have(key), "
Mail order: arrives in 1 day" if mail else ""],
		("Order $%d" if mail else "$%d") % price, func(): _buy_supply(key, price, mail), money >= price, icon]


func _buy_supply(key: String, cost: int, mail: bool) -> void:
	money -= cost
	var s: Dictionary = SUPPLIES[key]
	if s.get("tool", false):
		tools[key] = true
	else:
		inventory[key] = inventory.get(key, 0) + int(s.qty)
	if current_job:
		_spend(current_job, "parts", cost)
	_refresh_parts_table()
	if mail:
		note_cost("mail", 1.0, cost - roundi(cost / 1.25), "%s by mail" % s.name)
		_advance(1.0)
		_say("The %s came on the morning mail truck." % s.name)
	_save_game()
	if mail:
		_open_toolbox()
	else:
		_open_shop()


## Catalog copy for each part and supply, in the voice of a 1950s parts book.
const CATALOG_BLURB := {
	"tire": "6.00-6 four-ply tire with a fresh inner tube. Mounts on the stock split wheel.",
	"brakes": "Machined steel brake disc, ground dead flat. Ends the grinding on taxi.",
	"battery": "12-volt, 25 amp-hour aircraft battery, charged and ready to fit.",
	"spark_plugs": "Matched set of aviation plugs, gapped at the factory and ready to torque.",
	"oil_leak": "Rocker cover gasket kit: cork gasket and fresh hardware.",
	"fuel_line": "Aluminum fuel line, flared both ends, with brass B-nut fittings.",
	"windshield": "Clear acrylic windshield, cut to fit. Retainer screws included.",
	"starter": "Rebuilt 12-volt starter motor with a new drive gear.",
	"control_cables": "Pre-swaged rudder cable set with turnbuckles. Safety wire sold separately.",
	"magneto": "Overhauled magneto, timed on the bench, harness cap included.",
	"avionics": "Panel radio with a new whip antenna and coax lead.",
	"propeller": "Laminated wood propeller, balanced and varnished, yellow tips.",
	"stale_fuel": "Fresh blue 100LL, enough to fill a trainer's tanks.",
	"door_pin": "Steel hinge pin with a new cotter. Soak the old one first.",
	"hot_mag": "Shielded magneto ground lead with terminal. Grounds the mag when the key is off.",
	"carb_heat": "Push-pull carb heat control cable with clamp and swivel.",
	"ratchet": "Quarter-inch drive with SAE sockets in a steel case.",
	"torque": "Click type, 20 to 150 inch-pounds. Prop bolts need it.",
	"pliers": "Twists safety wire tight in one pull, then cuts it clean.",
	"Safety wire": ".032 stainless lockwire. Ten jobs to the spool.",
	"Cotter pin": "Assorted cotter pins, a box of ten.",
	"Penetrant": "Frees rusted pins and seized bolts. Three soaks to a can.",
}
const CATALOG_ICON := {
	"stale_fuel": "work/stale_fuel_cap", "door_pin": "work/door_pin_pin_new",
	"Safety wire": "work/propeller_wire", "Cotter pin": "work/tire_pin", "Penetrant": "work/door_pin_soak",
}


func _catalog_icon(key: String, fallback: String) -> String:
	for name in [CATALOG_ICON.get(key, ""), fallback]:
		if name != "" and ResourceLoader.exists("res://textures/%s.png" % name):
			return "res://textures/%s.png" % name
	return ""


## A supply as a catalog listing. mail: ordered from the hangar (1 day, +25%).
## What the job you're on still needs, so the shops can stamp it NEEDED: the tools its open
## write-ups (and the test the work order names next) use that you don't own, and materials it'll
## use up beyond what you carry. {"tools": {key: true}, "materials": {key: short by}}.
func job_needs() -> Dictionary:
	var out := {"tools": {}, "materials": {}}
	var job = current_job
	if job == null:
		return out
	var scenes: Array = job.faults.filter(func(id): return job.found.has(id) and not job.fixed.has(id) and not FAULTS[id].get("ground", false))
	for id in job.faults:
		var t := _test_for(job, id)
		if t != "" and job.get("sym", {}).has(id):
			scenes.append(t)
	var uses := {}
	for id in scenes:
		for e in Work.scene_for(id, FAULTS.get(id, {})).els:
			var tool: String = e.get("tool", "hand")
			if SUPPLIES.has(tool) and not tools.has(tool):
				out.tools[tool] = true
			var item: String = e.get("uses", "")
			if item != "":
				uses[item] = uses.get(item, 0) + 1
	for item in uses:
		if SUPPLIES.has(item) and uses[item] > inventory.get(item, 0):
			out.materials[item] = uses[item] - inventory.get(item, 0)
	return out


func _supply_entry(key: String, mail: bool) -> Dictionary:
	var s: Dictionary = SUPPLIES[key]
	var needs := job_needs()
	var price := int(s.cost * 1.25) if mail else int(s.cost)
	var tool: bool = s.get("tool", false)
	return {"name": s.name, "no": "AR-T%02d" % (20 + SUPPLIES.keys().find(key)), "blurb": CATALOG_BLURB.get(key, ""),
		"icon": _catalog_icon(key, "work/tool_" + key), "price": price, "mail": mail,
		"have": "" if tool else str(inventory.get(key, 0)), "owned": tool and tools.has(key),
		"needed": needs.tools.has(key) or needs.materials.has(key),
		"can": money >= price, "short": maxi(0, price - money), "buy": func(): _buy_supply(key, price, mail)}


func _supply_sections(keys: Array, mail: bool) -> Array:
	var t := []
	var m := []
	for key in keys:
		(t if SUPPLIES[key].get("tool", false) else m).append(_supply_entry(key, mail))
	for list in [t, m]:  # what this job needs comes first, as with parts
		list.sort_custom(func(a, b): return a.needed and not b.needed)
	return [{"id": "tools", "tab": "Tools", "head": "Section B: Hand tools", "items": t},
		{"id": "materials", "tab": "Materials", "head": "Section C: Shop supplies", "items": m}]


func _open_radio() -> void:
	_close_panel()
	var r := RadioUI.new()
	r.setup(sound, _media_key, _tuned)
	r.close_requested.connect(_close_panel)
	ui.add_child(r)
	panel = r
	panel_closable = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


func _tuned(i: int) -> void:
	settings.station = i
	_save_settings()


var media_sent := []  # what tests pressed, in place of the real key


## Presses a media key, the same as the play and skip keys on a keyboard, so it reaches whatever
## music app is running without signing in to anything. Windows only, like the game.
func _media_key(code: int) -> void:
	var args := OS.get_cmdline_user_args()
	if "--self-test" in args or "--monkey" in args:  # never touch the tester's own music
		media_sent.append(code)
		return
	OS.create_process("powershell", ["-NoProfile", "-WindowStyle", "Hidden", "-Command", "(New-Object -ComObject WScript.Shell).SendKeys([char]%d)" % code])


## Opens the Field Service Catalog (scripts/catalog.gd) as the current sheet. Buying reopens it
## on the same page, so it only fades in the first time.
func _open_catalog(title: String, town: String, sections: Array, note := "") -> void:
	var fresh := not (panel is CatalogUI)
	_close_panel()
	var c := CatalogUI.new()
	c.setup(title, town, money, sections, note, sound.sfx.bind("thread"))
	c.close_requested.connect(_close_panel)
	ui.add_child(c)
	panel = c
	panel_closable = true
	if fresh:
		c.fade_in()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


## The hangar's TOOLS box: what you own, and a mail-order catalog for what you don't.
const STATE := {"Wichita": "Kan.", "Omaha": "Neb.", "Dallas": "Tex.", "Chicago": "Ill.", "Billings": "Mont.", "Miami": "Fla.",
	"New York": "N.Y.", "Seattle": "Wash.", "Portland": "Ore.", "Atlanta": "Ga.", "Nashville": "Tenn.", "Bangor": "Me.",
	"Los Angeles": "Calif.", "Phoenix": "Ariz.", "Las Vegas": "Nev.", "Albuquerque": "N.M.", "Denver": "Colo.",
	"Salt Lake City": "Utah", "Fargo": "N.D.", "Minneapolis": "Minn."}


func _roll_note() -> String:
	return "In your roll: " + ", ".join(tools.keys().map(func(t): return Work.TOOLS[t]))


func _open_toolbox() -> void:
	tutorial.walk("mailorder")  # first time here: a walkthrough of this menu (tutorial.gd)
	_open_catalog("Mail-order catalog", "Mail order from the hangar: arrives in 1 day, 25% over shelf price",
		_supply_sections(SUPPLIES.keys(), true), _roll_note())


func _open_shop() -> void:
	tutorial.walk("shop")  # first time here: a walkthrough of this menu (tutorial.gd)
	var needed := {}
	if current_job:
		for id in current_job.found:
			if not current_job.fixed.has(id):
				needed[FAULTS[id].part] = true
	var parts := []
	var i := 0
	var listed := {}
	for id in FAULTS:
		var f: Dictionary = FAULTS[id]
		i += 1
		if f.part == "" or listed.has(f.part):
			continue
		listed[f.part] = true
		var price := _price(id)
		var mail := not _stocked(id)
		var part: String = f.part
		parts.append({"name": part, "no": "AR-%d" % (1100 + i * 7), "blurb": CATALOG_BLURB.get(id, f.name),
			"icon": _catalog_icon(id, "icon_" + id), "price": price, "mail": mail,
			"have": str(inventory.get(part, 0)), "needed": needed.has(part), "can": money >= price, "short": maxi(0, price - money),
			"buy": func(): _buy(part, price, mail)})
	parts.sort_custom(func(a, b): return a.needed and not b.needed)  # what this job needs comes first
	var shelf := SUPPLIES.keys().filter(_on_shelf)  # the rest is mail order from the hangar
	var sections := [{"id": "parts", "tab": "Parts", "head": "Section A: Aircraft parts", "items": parts}]
	_open_catalog("Parts counter", "Parts counter at %s, %s" % [location, STATE[location]], sections + _supply_sections(shelf, false), _roll_note())


func _open_travel() -> void:
	var rows := []
	var can_fly := false
	var calls_here: Array = jobs.filter(func(j): return j != current_job)
	# One anchor for the comparison: the nearest open call you can pay the fare and the parts for.
	var closest = null
	for job in calls_here:
		var est := call_estimate(job)
		if not call_locked(job) and money >= est.fare + est.parts and (closest == null or est.fare < call_estimate(closest).fare):
			closest = job
	# Open calls first, best estimate first; locked ones after, easiest first.
	calls_here.sort_custom(func(a, b):
		if call_locked(a) != call_locked(b):
			return not call_locked(a)
		return call_estimate(a).net > call_estimate(b).net)
	for job in calls_here:
		var est := call_estimate(job)
		var cost: int = est.fare
		var d := call_difficulty(job)
		var rating := "Difficulty %d of 5: %s" % [d, DIFFICULTY_NAMES[d - 1]]
		if call_locked(job):
			rows.append(["%s: %s\n%s. Locked until your apprenticeship is done (%d of 3 jobs).\n%s" % [job.city, job.type, rating,
				int(tut.lesson) - 1, _symptoms(job)], "Locked", Callable(), false])
			continue
		can_fly = can_fly or money >= cost
		rows.append(["%s: %s%s\n%s. Pays $%d, clears about $%d after parts $%d, fuel $%d and %.1f days' rent. %d NM, waits %d days.\n%s" % [
			job.city, job.type, "   (closest you can afford)" if job == closest else "", rating, job.reward, est.net, est.parts, est.fare + est.plane_fuel,
			est.days, roundi(miles(location, job.city) * 0.869), maxi(0, ceili(job.deadline - day)), _symptoms(job)],
			"Fly ($%d)" % cost, func(): _travel(job, cost), money >= cost])
	if not can_fly and not _can_finish_here():
		var fares := jobs.filter(func(j): return j != current_job and not call_locked(j)).map(func(j): return int(miles(location, j.city) * FUEL_PER_MILE))
		_open_game_over(fares.min() if fares.size() > 0 else 0)
		return
	_open_panel("Rescue calls", rows)
	tutorial.walk("map")
	# Sectional-style nav chart: graticule, airport symbols, compass rose on your field and a
	# magenta course line (true course + nautical miles) to each call. Click a field to fly.
	var map := TextureRect.new()
	map.texture = load("res://textures/us_map.png")
	map.position = Vector2(SHEET_W + 22, 130)
	map.custom_minimum_size = Vector2(576, 360)
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_SCALE
	map.modulate = Color(0.93, 1.0, 0.93)  # pale green cast of a sectional chart
	ui.add_child(map)
	_side = map
	var calls := jobs.filter(func(j): return j != current_job)
	map.draw.connect(func(): chart.draw(map, calls))
	for job in calls:
		var cost := int(miles(location, job.city) * FUEL_PER_MILE)
		var pin := Button.new()
		pin.flat = true
		pin.text = job.city.to_upper()
		pin.add_theme_font_size_override("font_size", 11)
		pin.add_theme_color_override("font_color", Chart.MAGENTA)
		pin.add_theme_color_override("font_hover_color", Color(0.9, 0.1, 0.5))
		pin.position = chart.px(job.city) + Vector2(6, -24)
		pin.disabled = money < cost or call_locked(job)
		pin.tooltip_text = ("%s: locked for now" % job.city) if call_locked(job) else "Fly to %s ($%d fuel)" % [job.city, cost]
		pin.pressed.connect(func(): _travel(job, cost))
		map.add_child(pin)


const DIFFICULTY_NAMES := ["Routine", "Light", "Moderate", "Heavy", "Expert"]


## Form (P4): how the last three jobs went, from their debriefs: +1 a clean job (nothing extra),
## -1 a rough one (a comeback, a part broken by running it unready, or three or more extra costs),
## 0 otherwise. The sum, -3 to +3, pitches the next calls. Worked out, never stored.
func performance_form() -> int:
	var form := 0
	for e in logbook.slice(maxi(0, logbook.size() - 3)):
		if not e.has("debrief"):
			continue
		var extra: Array = Array(e.debrief.extra)
		if extra.is_empty():
			form += 1
		elif extra.size() >= 3 or extra.any(func(x): return String(x).begins_with("Comeback") or String(x).contains("running it unready")):
			form -= 1
	return form


## The debrief's word on what's coming, from the form.
func form_line() -> String:
	var f := performance_form()
	if f >= 2:
		return "Your next calls: tougher, to match how well your last jobs went."
	if f <= -2:
		return "Your next calls: steadier, while you get your feet back under you."
	return "Your next calls: about the same."

## The economy that teaches (P7): game balance, not real-world values; tune in playtests.
## per_step: dollars added per step of a call's rating above Routine. outgrown: the share of pay
## lost per step a call sits below where your career is. floor: the least an outgrown call pays.
const ECONOMY := {"per_step": 300, "outgrown": 0.10, "floor": 0.70}


## Where your career is, on the same 1-5 scale as a call's rating: up one every two rescues.
func career_level() -> int:
	return clampi(1 + rescued / 2, 1, 5)


## What a call pays: its base (plane type, parts at cost, years sat, annual), plus a premium for
## each step of its rating, times the rank's raise, times a discount if it's work you've outgrown.
## A lesson's call is never discounted. Rounded to $50, as owners quote.
func _pay_for(base: int, rating: int, lesson_call: bool) -> int:
	var pay: float = (base + (rating - 1) * ECONOMY.per_step) * (1.0 + rank_raise())
	var below: int = career_level() - rating
	if below > 0 and not lesson_call:
		pay *= maxf(ECONOMY.floor, 1.0 - ECONOMY.outgrown * below)
	return int(round(pay / 50.0)) * 50


## How hard a call is, 1 to 5, before you take it: one more for each extra fault (up to two), a
## plane that sat for years, troubleshooting, look-alike faults, an annual with no squawk, and a
## plane that may have to be grounded. The long-sat chores (stale gas, old oil, ropes) count once.
func call_difficulty(job: Dictionary) -> int:
	var core: Array = job.faults.filter(func(id): return not id in NEGLECT_FAULTS)
	var d := 1 + clampi(core.size() - 1, 0, 2)
	if job.get("years", 0) >= 2:
		d += 1
	if not job.get("diag", {}).is_empty():
		d += 1
	if job.faults.any(func(id): return SUSPECTS.has(id)):
		d += 1
	if job.get("annual", false):
		d += 1
	if job.faults.any(func(id): return FAULTS[id].get("ground", false)):
		d += 1
	return clampi(d, 1, 5)


## During the apprenticeship only the lesson's call is open: the rest of the map shows what's
## coming, locked until the three lessons are done. After that nothing is locked; every call shows
## its difficulty and the choice is yours.
func call_locked(job: Dictionary) -> bool:
	if int(tut.get("lesson", 0)) <= 0 or job.get("lesson", false):
		return false
	return jobs.any(func(j): return j.get("lesson", false) and j != current_job)  # (an older save with no lesson call locks nothing)


## What a call would leave in your pocket, roughly: its pay (which already covers the parts at
## cost) minus the parts, the fare there, fuel for the plane's flight out and rent for the days.
## Days: the trip, two hours a spot for the walk-around, and a half day per fault on the plane
## (a game estimate for comparing calls, not a promise: mail orders and wrong guesses cost more).
func call_estimate(job: Dictionary) -> Dictionary:
	var fare := int(miles(location, job.city) * FUEL_PER_MILE)
	var parts := 0
	for id in job.faults:
		parts += FAULTS[id].cost
	var days: float = miles(location, job.city) / 700.0 + ZONES.size() * 0.08 + job.faults.size() * 0.5
	var plane_fuel := _fuel_bill(job)
	return {"fare": fare, "parts": parts, "plane_fuel": plane_fuel, "days": days,
		"net": job.reward - parts - fare - plane_fuel - roundi(days * DAILY_COST)}


# ---------- 3D world ----------

func _setup_environment() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = load("res://textures/sky_golden.png")
	sky.sky_material = pano
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH  # clear up close, haze from ~30% of the view out
	env.fog_density = 1.0
	env.fog_depth_curve = 1.6
	env.fog_aerial_perspective = 0.45  # far haze takes on the sky color: distant hills go blue-gray
	# Thin volumetric haze, scattering forward: sun shafts through trees, the hangar door, windows.
	# (On/off with the rest of the expensive effects in _apply_graphics.)
	env.volumetric_fog_density = 0.007  # 0.012 washed out trees at 50 m; strong forward scatter keeps the shafts
	env.volumetric_fog_albedo = Color(1.0, 0.92, 0.8)
	env.volumetric_fog_anisotropy = 0.85
	env.volumetric_fog_length = 90.0
	env.sdfgi_use_occlusion = true  # soft bounce light: the red truck tints the gravel, the hangar glows inside
	env.fog_light_color = Color(0.92, 0.8, 0.62)  # warm haze
	env.fog_sky_affect = 0.15  # keep the golden panorama visible
	# Warm sun vs cool shadows: the ambient fill that lights shadowed sides is pulled toward blue.
	env.ambient_light_color = Color(0.45, 0.58, 0.95)
	env.ambient_light_sky_contribution = 0.35
	env.ambient_light_energy = 0.8
	env.glow_enabled = true  # gentle bloom on bright sky and sunlit paint only
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true  # grounds wheels, props and trees
	env.ssao_intensity = 2.2
	# Grade: a touch of teal in the darks, warm highlights (each channel looks up its own curve).
	var grade := Gradient.new()
	grade.set_color(0, Color(0.0, 0.02, 0.04))
	grade.set_color(1, Color(1.0, 0.97, 0.9))
	grade.add_point(0.3, Color(0.25, 0.3, 0.34))
	grade.add_point(0.75, Color(0.81, 0.75, 0.67))
	var curve := GradientTexture1D.new()
	curve.gradient = grade
	env.adjustment_enabled = true
	env.adjustment_color_correction = curve
	env.adjustment_saturation = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0  # the tree shadow pass was the costliest part of the frame
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.light_energy = 1.35  # strong warm key against the blue fill = warm/cool contrast
	sun.light_angular_distance = 0.8  # the sun has a size: shadow edges soften with distance (Vulkan/Metal)
	sun.shadow_blur = 1.6  # and a little blur on the basic renderer, which has no soft shadows
	add_child(sun)
	var vignette := TextureRect.new()  # soft dark corners pull the eye to the middle
	var vg := GradientTexture2D.new()
	vg.fill = GradientTexture2D.FILL_RADIAL
	vg.fill_from = Vector2(0.5, 0.5)
	vg.fill_to = Vector2(1.15, 0.5)
	vg.gradient = Gradient.new()
	vg.gradient.set_color(0, Color(0, 0, 0, 0))
	vg.gradient.set_color(1, Color(0.05, 0.03, 0.08, 0.45))
	vg.gradient.set_offset(0, 0.55)
	vignette.texture = vg
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var layer := CanvasLayer.new()
	layer.layer = -1  # over the 3D view, under the HUD and panels
	layer.add_child(vignette)
	add_child(layer)


## A few dozen dust motes / pollen drifting around the player (snowflakes up north).
func _add_motes(region_name: String) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 110
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-12, -4, -12), Vector3(24, 10, 24))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(10, 3, 10)
	pm.gravity = Vector3(0, -0.6 if region_name == "snow" else -0.02, 0)
	pm.direction = Vector3(1, 0.2, 0.3)
	pm.spread = 60
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.4
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.3
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2.ONE * (0.05 if region_name == "snow" else 0.035)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.8) if region_name == "snow" else Color(1.0, 0.95, 0.78, 0.85)
	var dot := GradientTexture2D.new()  # soft round speck instead of a square
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.gradient = Gradient.new()
	dot.gradient.set_color(1, Color(1, 1, 1, 0))
	m.albedo_texture = dot
	q.material = m
	p.draw_pass_1 = q
	p.position.y = 1.5
	player.add_child(p)
	return p


## A small flock wheeling slowly over the field; wings flap now and then, otherwise glide.
func _add_birds() -> void:
	flock = Node3D.new()
	flock.position = Vector3(r_bird.randf_range(-20, 20), 22, r_bird.randf_range(-30, 0))  # low over the field, easy to spot
	world.add_child(flock)
	var c := Color(0.12, 0.1, 0.1)
	for i in 7:
		var b := Node3D.new()
		b.position = Vector3(32 + r_bird.randf_range(-4, 4), r_bird.randf_range(-3, 3), i * 2.6 - 8)
		for s in [-1, 1]:
			var wing := box(b, Vector3(0.8, 0.04, 0.26), Vector3(s * 0.4, 0, 0), c)
			wing.set_meta("side", s)
		box(b, Vector3(0.14, 0.1, 0.5), Vector3.ZERO, c)
		b.set_meta("phase", r_bird.randf() * TAU)
		flock.add_child(b)


var r_bird := RandomNumberGenerator.new()
var motes: GPUParticles3D
var flock: Node3D  # the current field's birds (freed with the world)


func _animate_birds() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if is_instance_valid(sock):  # same wind as the grass: from the west-southwest, in gusts
		var gust := sin(sock.position.x * 0.07 + sock.position.z * 0.04 - t * 1.3) * 0.5 + 0.5
		sock.rotation = Vector3(sin(t * 3.1) * 0.06 * gust, -0.42 + sin(t * 0.6) * 0.12, -0.32 + gust * 0.28)  # near level in a breeze, lifting in gusts
	if not is_instance_valid(flock):
		return
	flock.rotation.y = -t * 0.08  # ~80 s per lap
	for b in flock.get_children():
		var ph: float = b.get_meta("phase")
		var flap := sin(t * 9.0 + ph) * 0.6 * float(sin(t * 0.7 + ph) > 0.2)  # bursts of flapping
		for w in b.get_children():
			if w.has_meta("side"):
				w.rotation.z = flap * w.get_meta("side")
				w.position.x = cos(flap) * 0.4 * w.get_meta("side")
				w.position.y = sin(flap) * 0.4


## Each region gets its own light: golden plains, hot hazy desert, green-tinged forest, cold snow.
const REGION_LIGHT := {
	"plains": {"sun": Color(1.0, 0.85, 0.65), "fog": Color(0.92, 0.8, 0.62), "elev": -20.0, "haze": 750.0},
	"desert": {"sun": Color(1.0, 0.8, 0.55), "fog": Color(0.96, 0.76, 0.55), "elev": -19.0, "haze": 600.0},
	"forest": {"sun": Color(1.0, 0.9, 0.75), "fog": Color(0.72, 0.8, 0.7), "elev": -18.0, "haze": 650.0},
	"snow": {"sun": Color(0.95, 0.93, 0.92), "fog": Color(0.86, 0.88, 0.93), "elev": -14.0, "haze": 700.0,
		# Snow throws light back up: brighter, paler fill so shadows go blue-gray instead of black,
		# and a touch less exposure so the open snow doesn't glare.
		"amb": 1.3, "amb_color": Color(0.68, 0.76, 0.95), "exposure": 0.86},
}


func _apply_light(region_name: String) -> void:
	var l: Dictionary = REGION_LIGHT[region_name]
	sun.light_color = l.sun
	sun.rotation_degrees = Vector3(l.elev, 30, 0)
	env.fog_light_color = l.fog
	env.fog_depth_begin = 190.0  # about 30% of the ~650 m view: clear near, hazy far
	env.fog_depth_end = l.haze  # meters to full haze
	env.ambient_light_energy = l.get("amb", 0.8)
	env.ambient_light_color = l.get("amb_color", Color(0.45, 0.58, 0.95))
	env.tonemap_exposure = l.get("exposure", 1.0)


func _load_field(city: String, job) -> void:
	location = city
	current_job = job
	if world:
		world.queue_free()
	world = Node3D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	plane = null
	visuals.clear()
	var region: Dictionary = REGIONS[CITIES[city][2]]
	_apply_light(CITIES[city][2])
	var r := RandomNumberGenerator.new()
	r.seed = hash(city)
	terrain = Terrain.new(CITIES[city][2], hash(city))
	terrain.build(world, region.tex)
	var floor_body := StaticBody3D.new()  # safety net under the terrain and pond
	floor_body.position.y = -3.0
	var fs := CollisionShape3D.new()
	fs.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(fs)
	world.add_child(floor_body)
	box(world, Vector3(160, 0.04, 12), Vector3(0, 0.02, 20), _flat_ground("runway_asphalt", 0.15))
	for x in range(-76, 80, 10):
		box(world, Vector3(5, 0.05, 0.4), Vector3(x, 0.03, 20), Color(0.95, 0.95, 0.9))
	# No gravel apron pad: the plane, the truck and the parts table sit on the grass.
	_build_windsock(Vector3(32, 0, 30))  # beside the strip, clear of the wingtips
	_scatter_litter(r)
	var probe := ReflectionProbe.new()  # glass and paint pick up the sky and the field around them
	probe.size = Vector3(60, 24, 60)
	probe.position = Vector3(0, 4, 8)
	world.add_child(probe)
	# Lived-in clutter: old oil drips on the apron, rubber skid marks at the runway's touchdown zones.
	for i in 5:
		var stain := decal(world, Vector2.ONE * r.randf_range(0.5, 1.4), Vector3(r.randf_range(-8, 8), 0.035, r.randf_range(2, 13)), "oil_puddle", Vector3.UP)
		stain.mesh.material.albedo_color = Color(1, 1, 1, r.randf_range(0.3, 0.6))
		stain.rotate_y(r.randf() * TAU)
	for end_x in [-55.0, 55.0]:
		for i in 6:
			var skid := decal(world, Vector2(r.randf_range(5, 9), 0.6), Vector3(end_x + r.randf_range(-12, 12), 0.045, 20 + r.randf_range(-2.5, 2.5)), "decal_tire_marks", Vector3.UP)
			skid.mesh.material.albedo_color = Color(1, 1, 1, r.randf_range(0.5, 0.85))
	_build_hangar(Vector3(-16, 0, -14), r)
	_build_shed(Vector3(14, 0, -8))
	_build_sign(Vector3(9, 0, 4), city)
	prop("fuel_truck", Vector3(-8, 0, -1), 7.0, null, PI / 2)  # parked by the hangar, cab toward the runway
	interactable(world, Vector3(-8, 1.3, -1), Vector3(3.2, 2.6, 7.2), "truck")
	_build_parts_table()
	_scatter(region, r)
	var field := Rect2(-120, -120, 240, 240)
	if region.grass > 0:
		_cards("grass_card", region.grass, 0.9, field, r, Color(1, 0.85, 0.6) if region.prop == "cactus" else Color.WHITE)
	if region.wheat > 0:
		_cards("wheat_card", region.wheat, 1.2, Rect2(25, -120, 95, 130), r)  # a wheat field east of the strip
	if job:
		_build_plane(job)
	_add_birds()
	if motes:
		motes.queue_free()
	motes = _add_motes(CITIES[city][2])
	_apply_graphics()
	player.velocity = Vector3.ZERO
	player.position = Vector3(4, 0.1, -2)
	player.rotation = Vector3(0, PI, 0)
	player.cam.rotation = Vector3.ZERO
	_save_game()  # arriving somewhere is a checkpoint


## The bench at the back of the hangar: the chart laid out for rescue calls, the shop radio beside it.
func _build_workbench(at: Vector3) -> void:
	box(world, Vector3(3.5, 0.08, 1.0), at + Vector3(0, 0.88, 0), tmat("workbench_top", Color.WHITE, 0.6))
	box(world, Vector3(3.3, 0.05, 0.85), at + Vector3(0, 0.3, 0), tmat("wood_planks", Color(0.7, 0.6, 0.48), 1.2))  # shelf
	var leg := tmat("wood_planks", Color(0.6, 0.48, 0.36), 1.2)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(world, Vector3(0.1, 0.84, 0.1), at + Vector3(sx * 1.65, 0.42, sz * 0.42), leg)
	var body := box(world, Vector3(3.5, 0.92, 1.0), at + Vector3(0, 0.46, 0), Color.WHITE, true)  # one block to walk into
	body.visible = false
	var chart_at := at + Vector3(-0.62, 0.925, 0)
	decal(world, Vector2(1.76, 1.1) * 0.9, chart_at, "us_map", Vector3.UP).mesh.material.albedo_color = Color(0.62, 0.62, 0.55)  # the bench lamp washes it out
	interactable(world, chart_at + Vector3(0, 0.15, 0.05), Vector3(1.8, 0.5, 1.2), "map")
	_icon3d("map", chart_at + Vector3(0, 0.75, 0))
	var set_at := at + Vector3(1.05, 1.1, -0.1)  # middle of the radio's case
	box(world, Vector3(0.66, 0.36, 0.3), set_at, tmat("wood_planks", Color(0.36, 0.22, 0.13), 2.0))
	box(world, Vector3(0.26, 0.26, 0.012), set_at + Vector3(-0.17, 0, 0.152), Color(0.16, 0.11, 0.08))  # speaker cloth
	box(world, Vector3(0.3, 0.09, 0.012), set_at + Vector3(0.14, 0.07, 0.152), Color(0.94, 0.87, 0.68))  # dial
	box(world, Vector3(0.012, 0.09, 0.016), set_at + Vector3(0.1, 0.07, 0.156), Color(0.66, 0.15, 0.12))  # needle
	for x in [0.06, 0.22]:
		box(world, Vector3(0.06, 0.06, 0.03), set_at + Vector3(x, -0.08, 0.16), Color(0.82, 0.74, 0.55))  # knobs
	interactable(world, set_at + Vector3(0, 0.05, 0.3), Vector3(1.0, 0.8, 0.9), "radio")
	_icon3d("radio", set_at + Vector3(0, 0.6, 0))


func _build_hangar(at: Vector3, r: RandomNumberGenerator) -> void:
	# Quonset-hut model: open end faces +Z (the runway). Longest side is its depth;
	# 15.8 m deep makes it 14 m wide and 7 m tall. Back wall sits near at.z - 7.2.
	prop("hangar", at, 15.8, null, 0.0, "mesh")
	# The model's floor is uneven triangles the player's capsule could wedge into: walk on a flat slab instead.
	var slab := box(world, Vector3(13.6, 0.12, 15.2), at + Vector3(0, 0.06, -0.2), Color.WHITE, true)
	slab.visible = false
	const BACK := -7.0
	box(world, Vector3(5, 2.4, 0.05), at + Vector3(-1.5, 2.0, BACK + 0.1), tmat("pegboard", Color.WHITE, 0.5))
	decal(world, Vector2(4.2, 2.9), at + Vector3(0, 4.75, BACK + 0.08), "logo_ghost", Vector3.BACK)  # old paint above the pegboard
	prop("toolbox", at + Vector3(-4.5, 0, BACK + 0.6), 1.1, tmat("toolbox_red", Color.WHITE, 1.5))  # drawers face +Z
	interactable(world, at + Vector3(-4.5, 0.6, BACK + 1.0), Vector3(1.4, 1.2, 1.2), "toolbox")
	_icon3d("toolbox", at + Vector3(-4.5, 1.7, BACK + 0.6))
	_lamp(at + Vector3(-4.5, 2.6, BACK + 1.2))  # over the toolbox
	decal(world, Vector2(0.62, 0.44), at + Vector3(-4.03, 0.75, BACK + 0.6), "logo_decal", Vector3.RIGHT)
	var drum_paint := [Color(0.45, 0.6, 0.85), Color(0.8, 0.35, 0.3), Color(0.5, 0.6, 0.45)]
	for p in [Vector3(8.3, 0, -4), Vector3(9.0, 0, -3.2), Vector3(8.4, 0, -2.4), Vector3(-5.0, 0, 3)]:
		prop("barrel_a", at + p, 0.9, tmat("galvanized_metal", drum_paint[r.randi() % 3], 2.0), r.randf() * TAU)
	for p in [Vector3(-8.7, 0, 4), Vector3(-8.8, 0, 5.2)]:
		prop("crate_a", at + p, 1.0, tmat("wood_planks", Color(0.9, 0.8, 0.65), 1.5), r.randf_range(-0.3, 0.3))
	_build_workbench(at + Vector3(3, 0, BACK + 0.65))
	_lamp(at + Vector3(3, 2.9, BACK + 1.2))  # over the workbench
	# A framed photo of an old rescue, sepia, over the desk.
	box(world, Vector3(0.62, 0.5, 0.03), at + Vector3(1.1, 2.1, BACK + 0.07), tmat("wood_planks", Color(0.35, 0.22, 0.12), 2.0))
	var photo := StandardMaterial3D.new()
	photo.albedo_texture = load("res://textures/rescue_photo.png")
	photo.albedo_color = Color(0.95, 0.78, 0.55)  # faded to sepia
	photo.roughness = 0.9
	box(world, Vector3(0.5, 0.38, 0.01), at + Vector3(1.1, 2.1, BACK + 0.09), photo)


func _build_shed(at: Vector3) -> void:
	# Parts-counter model: open stocked counter faces +Z, "AIRCRAFT PARTS" painted on the +X side.
	# 5.4 m wide -> about 2.8 m deep and 3.7 m tall.
	prop("parts_shed", at, 5.4, null, 0.0, "mesh")
	interactable(world, at + Vector3(0, 1.2, 1.1), Vector3(4.6, 1.6, 1.2), "shop")
	_lamp(at + Vector3(0, 3.0, 1.6))  # over the counter
	var crate := tmat("wood_planks", Color(0.9, 0.8, 0.65), 1.5)
	prop("crate_a", at + Vector3(3.4, 0, -1.2), 1.0, crate, 0.2)  # delivery stack beside the shed
	prop("crate_a", at + Vector3(3.5, 0.87, -1.2), 0.9, crate, -0.3)
	prop("crate_a", at + Vector3(3.3, 0, 0.1), 1.0, crate, 0.5)
	prop("barrel_a", at + Vector3(-3.2, 0, -1.6), 0.9, tmat("galvanized_metal", Color(0.8, 0.35, 0.3), 2.0))


## "MUNICIPAL AIRPORT" board on two posts, the town name lettered into its blank panel.
func _build_sign(at: Vector3, city: String) -> void:
	var facing := (Vector3(4, 0, -2) - at).normalized()  # toward the player's arrival spot
	for s in [-1, 1]:
		var post := box(world, Vector3(0.15, 2.2, 0.15), at + facing.cross(Vector3.UP) * s * 1.7 + Vector3(0, 1.1, 0), tmat("wood_planks"))
		post.basis = Basis.looking_at(-facing, Vector3.UP)
	var board := decal(world, Vector2(4, 2), at + Vector3(0, 2.2, 0) + facing * 0.09, "airfield_sign", facing)
	var back := box(world, Vector3(4.1, 2.1, 0.1), at + Vector3(0, 2.2, 0), tmat("wood_planks"))
	back.basis = board.basis
	var l := Label3D.new()
	l.text = city.to_upper()
	l.font_size = 72
	l.pixel_size = 0.005
	l.modulate = Color(0.55, 0.12, 0.1)
	l.outline_size = 0
	l.position = at + Vector3(0, 2.05, 0) + facing * 0.11  # the blank box sits just below center
	l.basis = board.basis
	world.add_child(l)


func _scatter(region: Dictionary, r: RandomNumberGenerator) -> void:
	var rows := []  # windbreak tree lines along the field edges, like prairie shelterbelts
	if region.prop != "cactus":
		for z in [-58.0 + r.randf_range(-8, 8), 72.0 + r.randf_range(-8, 8)]:
			var x := -170.0
			while x < 170.0:
				rows.append(Vector3(x, 0, z + r.randf_range(-1.5, 1.5)))
				x += r.randf_range(6.0, 10.0)
	trunks = StaticBody3D.new()  # one body; every tree adds a post shape to it
	world.add_child(trunks)
	var cones: Array[Transform3D] = []  # forest pines, drawn as two MultiMeshes below
	var placed := 0
	# The woods fill the distance, so detailed trees are only worth drawing near the field.
	var thick: bool = location in THICK_WOODS
	var hero_count: int = mini(region.count, HERO_TREES) if thick else region.count
	var hero_reach := 150.0 if thick else 400.0
	while placed < hero_count + rows.size():
		var pos: Vector3
		if placed < rows.size():
			pos = rows[placed]
			placed += 1
			if terrain.in_water(pos.x, pos.z):
				continue
		else:
			pos = Vector3(r.randf_range(-hero_reach, hero_reach), 0, r.randf_range(-hero_reach, hero_reach))
			# same lot/runway rule as the grass, plus extra room so canopies clear the wingtips
			if _kept_clear(pos) or pos.length() < 32 or absf(pos.z - 14) < 16:
				continue
			# groves and clearings; nothing in the pond or on cliffs
			if r.randf() > terrain.grove(pos.x, pos.z) or terrain.in_water(pos.x, pos.z) or terrain.slope(pos.x, pos.z) > 0.35:
				continue
			placed += 1
		pos.y = terrain.height(pos.x, pos.z) - 0.1
		var h := r.randf_range(3.0, 6.0)
		match region.prop:
			"tree":
				var kind: String = TREE_SPLIT.keys()[r.randi() % TREE_SPLIT.size()]
				var tree := prop(kind, pos, r.randf_range(5.5, 9.0), null, r.randf() * TAU, "trunk")
				tree.set_meta("tree", true)
				_paint_tree(tree, TREE_SPLIT[kind], Color.WHITE.darkened(r.randf() * 0.25))
				_near_only(tree, 240.0 if thick else 420.0)
			"pine":  # shortcut: code-built cones until a plain (snowless) pine model exists
				cones.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * h), pos))
				_trunk(pos)
			"snowpine":
				var pine := prop("tree_pine_snow_a", pos, r.randf_range(6.0, 11.0), null, r.randf() * TAU, "trunk")
				pine.set_meta("tree", true)
				_near_only(pine, 240.0 if thick else 420.0)
			"cactus":
				var roll := r.randf()
				if roll < 0.7:  # tall saguaros, one or two arms
					var kind := "cactus_a" if roll < 0.4 else "cactus_b"
					prop(kind, pos, r.randf_range(3.0, 6.0), null, r.randf() * TAU, "trunk").set_meta("tree", true)
				else:  # low barrel-cactus clump
					prop("cactus_c", pos, r.randf_range(1.0, 1.8), null, r.randf() * TAU)
				if r.randf() < 0.5:
					var s := r.randf_range(0.6, 1.4)
					_crag(Vector3(pos.x + 3, terrain.height(pos.x + 3, pos.z + 2) - 0.2, pos.z + 2), s, s * 1.1, Color(0.95, 0.75, 0.6), r)
	if cones.size() > 0:  # meshes for h = 1 (trunk sized for an average 4.5 m pine); each instance scales by h
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.2 / 4.5
		trunk.bottom_radius = 0.3 / 4.5
		trunk.height = 1.2 / 4.5
		trunk.radial_segments = 5
		trunk.material = tmat("bark")
		# Three stacked, drooping tiers read as a fir; one plain cone read as a party hat.
		var st := SurfaceTool.new()
		for tier in [[0.34, 0.7, 0.55], [0.26, 0.6, 0.95], [0.17, 0.5, 1.32]]:  # radius, height, center y
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = tier[0]
			c.height = tier[1]
			c.radial_segments = 7
			c.rings = 1
			st.append_from(c, 0, Transform3D(Basis(), Vector3(0, tier[2], 0)))
		var crown := st.commit()
		crown.surface_set_material(0, tmat("foliage", Color(0.38, 0.55, 0.42)))
		_multi(trunk, cones.map(func(t): return t.translated_local(Vector3(0, 0.6 / 4.5, 0))))
		_multi(crown, cones)
	if location in THICK_WOODS:
		_woods(region, r)
	var rocks := 0  # outcrops half-buried in hillsides (the hills and mountains themselves are terrain)
	var tries := 0
	while rocks < (0 if region.prop == "tree" else 18) and tries < 2000:
		tries += 1
		var p := Vector3(r.randf_range(-300, 300), 0, r.randf_range(-300, 300))
		if p.length() < 70 or terrain.slope(p.x, p.z) < 0.2 or terrain.height(p.x, p.z) < 4.0:
			continue
		rocks += 1
		var s := r.randf_range(2.0, 6.0)
		_crag(p + Vector3(0, terrain.height(p.x, p.z) - s * 0.35, 0), s, s * 0.7, region.ground.lerp(Color(0.55, 0.5, 0.48), 0.7), r)


## Stops drawing a detailed model past this distance. The fog hides the edge.
func _near_only(m: Node3D, reach: float) -> void:
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = reach


## The woods behind the hero trees: low-poly crowns in 100 m blocks, so off-screen blocks cost
## nothing, and none cast shadows (they cost more than the trees). shortcut: no collision, you can walk through them;
## add trunks if players start exploring the woods on foot.
func _woods(region: Dictionary, r: RandomNumberGenerator) -> void:
	var want: int = WOODS_TREES / (8 if graphics == "low" or "--low" in OS.get_cmdline_user_args() else 1)
	var blocks := {}
	var placed := 0
	var tries := 0
	while placed < want and tries < want * 3:
		tries += 1
		var pos := Vector3(r.randf_range(-400, 400), 0, r.randf_range(-400, 400))
		if _kept_clear(pos) or pos.length() < 45 or absf(pos.z - 14) < 18 or terrain.in_water(pos.x, pos.z) or terrain.slope(pos.x, pos.z) > 0.45:
			continue
		pos.y = terrain.height(pos.x, pos.z) - 0.1
		var key := Vector2i(floori(pos.x / 100.0), floori(pos.z / 100.0))
		if not blocks.has(key):
			blocks[key] = []
		blocks[key].append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(5.0, 9.0)), pos))
		placed += 1
	var conifer: bool = region.prop != "tree"
	var look := tmat("foliage", Color.WHITE)
	look.vertex_color_use_as_albedo = true
	look.uv1_scale = Vector3(4, 4, 4)  # at tree size the leaf texture was stretching into big plates
	var st := SurfaceTool.new()
	if conifer:
		for tier in [[0.3, 0.55, 0.5], [0.23, 0.5, 0.85], [0.14, 0.42, 1.18]]:  # radius, height, center y
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = tier[0]
			cone.height = tier[1]
			cone.radial_segments = 6
			cone.rings = 1
			st.append_from(cone, 0, Transform3D(Basis(), Vector3(0, tier[2], 0)))
	else:  # three uneven lobes read as a canopy; one ball read as a lollipop
		for lobe in [[0.3, Vector3(-0.14, 0.62, 0.05)], [0.27, Vector3(0.17, 0.68, -0.1)], [0.22, Vector3(0.02, 0.86, 0.12)]]:
			var ball_ := SphereMesh.new()
			ball_.radius = lobe[0]
			ball_.height = lobe[0] * 1.6
			ball_.radial_segments = 6
			ball_.rings = 3
			st.append_from(ball_, 0, Transform3D(Basis(), lobe[1]))
	var mesh: ArrayMesh = st.commit()
	mesh.surface_set_material(0, look)
	var wood := SurfaceTool.new()
	var stem := CylinderMesh.new()
	stem.top_radius = 0.012
	stem.bottom_radius = 0.028
	stem.height = 0.6
	stem.radial_segments = 4
	stem.rings = 1
	wood.append_from(stem, 0, Transform3D(Basis(), Vector3(0, 0.3, 0)))
	wood.commit(mesh)
	mesh.surface_set_material(1, tmat("bark"))
	var base := Color(0.36, 0.48, 0.38) if conifer else Color(0.5, 0.56, 0.32)
	for key in blocks:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = blocks[key].size()
		for i in blocks[key].size():
			mm.set_instance_transform(i, blocks[key][i])
			mm.set_instance_color(i, base.darkened(r.randf() * 0.3))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.visibility_range_end = 380.0
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(mmi)


## Faceted, jagged rock: 3 jittered rings tapering to an off-center peak, flat-shaded.
func _crag(pos: Vector3, radius: float, height: float, base: Color, r: RandomNumberGenerator) -> void:
	const N := 9
	var rings := [[0.0, 1.0], [0.4, 0.62], [0.75, 0.3]]  # [height fraction, radius fraction]
	var pts := []
	var a0 := r.randf() * TAU
	for ring in rings:
		var row := []
		for i in N:
			var a: float = a0 + TAU * i / N + r.randf_range(-0.2, 0.2)
			var rad: float = radius * ring[1] * r.randf_range(0.7, 1.2)
			row.append(Vector3(cos(a) * rad, height * ring[0] * (r.randf_range(0.85, 1.15) if ring[0] > 0 else 1.0), sin(a) * rad))
		pts.append(row)
	var peak := Vector3(r.randf_range(-0.15, 0.15) * radius, height, r.randf_range(-0.15, 0.15) * radius)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := func(a: Vector3, b: Vector3, c: Vector3):
		var out := (a + b + c) / 3.0 * Vector3(1, 0, 1) + Vector3.UP * radius * 0.3
		var n := (b - a).cross(c - a)
		if n.dot(out) > 0:  # Godot front faces wind clockwise seen from outside
			var t := b
			b = c
			c = t
			n = -n
		n = -n.normalized()
		for v in [a, b, c]:
			st.set_normal(n)
			st.set_color(base)
			st.add_vertex(v)
	for k in pts.size() - 1:
		for i in N:
			var j := (i + 1) % N
			tri.call(pts[k][i], pts[k + 1][i], pts[k][j])
			tri.call(pts[k][j], pts[k + 1][i], pts[k + 1][j])
	for i in N:
		tri.call(pts[-1][i], peak, pts[-1][(i + 1) % N])
	var m := tmat("rock", Color.WHITE, 2.0 / radius)
	m.vertex_color_use_as_albedo = true
	var mesh := st.commit()
	mesh.surface_set_material(0, m)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	world.add_child(mi)


func _build_plane(job: Dictionary) -> void:
	plane = Node3D.new()
	if job.get("parked", "apron") == "hangar":  # inside, nose to the open door
		plane.rotation = Vector3(SIT_PITCH, PI, 0)
		plane.position = HANGAR_SPOT + Vector3(0, MAIN_Z * sin(SIT_PITCH), 0)
	else:
		plane.rotation = Vector3(SIT_PITCH, PI / 2, 0)  # nose down the runway (-X), resting back on the tailwheel
		plane.position = Vector3(0, MAIN_Z * sin(SIT_PITCH), 8)  # keeps the main tires on the ground
	world.add_child(plane)
	# Your red toolbox, set down on the ground by the nose wherever the plane sits. The test
	# instruments live in it: you walk over and take one in hand (see _open_kit).
	var level := Node3D.new()
	level.rotation.x = -SIT_PITCH  # undo the sit pitch: the box stands on the ground, not tilted
	plane.add_child(level)
	model(level, "toolbox", Vector3(-1.9, 0, -1.6), 0.8, Vector3(0, PI / 2, 0), tmat("toolbox_red", Color.WHITE, 1.5))
	interactable(level, Vector3(-1.9, 0.45, -1.6), Vector3(1.0, 0.9, 1.0), "kit")
	# FlightGear J-3 Cub (GPL, real scale: 10.65 m span). Model faces -X with wings along Z;
	# turned so the nose is -Z. Plane origin = between the main tires on the ground.
	# Probed parts (plane space): tyres x=Â±0.9 z=0, nose z=-1.33, cowl z -1.16..-0.69,
	# windshield y 1.37..1.96 z -0.53..0.09, wing yâ‰ˆ1.95, rudder hinge z=4.44, tailwheel z=5.2.
	cub = model(plane, "plane_cub", Vector3(-0.005, 1.37, 2.025), 10.65, Vector3(0, -PI / 2, 0))
	var hull := StaticBody3D.new()  # keeps the player from walking through the plane
	var hs := CollisionShape3D.new()
	hs.shape = BoxShape3D.new()
	hs.shape.size = Vector3(0.9, 1.7, 6.6)
	hs.position = Vector3(0, 1.55, 2.0)
	hull.add_child(hs)
	plane.add_child(hull)
	for id in FAULTS:
		visuals[id] = _part_visual(id, job.fixed.has(id) or not job.faults.has(id))
	_grime(not job.get("washed", true))
	_refresh_markers()
	for z in ZONES:
		interactable(plane, ZONES[z].pos, ZONES[z].size, "zone").set_meta("zone", z)
	for sx in [-0.9, 0.9]:  # yellow wooden chocks fore and aft of each main tire, pulled at take-off
		for sz in [-0.3, 0.3]:
			var chock := box(plane, Vector3(0.16, 0.12, 0.14), Vector3.ZERO, Color(0.85, 0.65, 0.15))
			chock.global_position = plane.to_global(Vector3(sx, 0, sz)) * Vector3(1, 0, 1) + Vector3(0, 0.06, 0)
			chock.global_rotation = Vector3(0, plane.rotation.y, 0)
			chock.set_meta("kind", "chock")


## Taildragger stance: the Cub model is built level, tailwheel bottom 1.04 m up at z=5.2 behind the mains.
const MAIN_Z := 0.0  # main tire contact, plane space (the pitch pivot)
const SIT_PITCH := 0.197  # atan(1.04 / 5.2): the real three-point attitude, about 11 degrees


## Swings one of the Cub's named parts about a hinge (model space point and axis); angle 0 = as built.
func _hinge(part: String, pivot: Vector3, axis: Vector3, angle: float) -> void:
	var p: Node3D = cub.find_child(part, true, false)
	p.transform = Transform3D(Basis(axis, angle), pivot) * Transform3D(Basis(), -pivot)


## The piece of the plane each fault lives on, drawn broken or fixed.
func _part_visual(id: String, ok: bool) -> Node3D:
	var n := Node3D.new()
	plane.add_child(n)
	var axle_x := Vector3(0, PI / 2, 0)  # wheel/disc models spin around Z; turn them to X
	var level := Node3D.new()  # undoes the sit pitch, for things that hang plumb or lie on the ground
	level.rotation.x = -SIT_PITCH
	n.add_child(level)
	match id:
		"tire":  # the Cub's own tyre, swapped for a flat one sagging on its rim
			cub.find_child("tyre_l", true, false).visible = ok
			if not ok:
				model(level, "tire_broken", Vector3(-0.9, 0.2, 0), 0.5, axle_x)
		"brakes":  # disc on the inboard side of the wheel, where it really sits
			model(n, "brakes_ok" if ok else "brakes_broken", Vector3(0.77, 0.25, 0), 0.22, axle_x)
		"spark_plugs":
			if not ok:
				decal(n, Vector2(0.5, 0.3), Vector3(0.35, 1.1, -0.92), "decal_soot", Vector3.RIGHT)
		"oil_leak":
			if not ok:
				decal(level, Vector2(1.4, 1.4), Vector3(0, 0.02, -1.2), "oil_puddle", Vector3.UP)
		"bird_nest":
			if not ok:
				cyl(n, 0.25, 0.16, 0.16, Vector3(0, 1.6, -0.95), tmat("bark", Color(0.8, 0.65, 0.45)), 7)
				ball(n, 0.06, Vector3(0.04, 1.71, -0.95), Color(0.75, 0.88, 0.95))
		"fuel_line":  # wing tank seeping at the left wing root
			if not ok:
				decal(level, Vector2(1.4, 1.4), Vector3(-1.4, 0.02, 0.6), "decal_fuel_stain", Vector3.UP)
				box(level, Vector3(0.03, 1.65, 0.03), Vector3(-1.4, 0.84, 0.6), Color(0.35, 0.5, 0.85))  # drip
		"windshield":
			if not ok:  # fogged glass + crack over the windshield (45 degrees, up and back)
				var face := Vector3(0, 0.7, -0.7).normalized()
				var glass := decal(n, Vector2(0.72, 0.82), Vector3(0, 1.68, -0.24), "", face)
				glass.mesh.material.albedo_color = Color(0.45, 0.47, 0.48, 0.85)
				decal(n, Vector2(0.65, 0.7), Vector3(0, 1.685, -0.245), "windshield_cracked", face)
		"magneto":
			model(n, "magneto_ok" if ok else "magneto_broken", Vector3(0.4, 1.3, -0.72), 0.25, Vector3(0, PI / 2, 0))
		"control_cables":  # slack cables let the rudder flop hard over
			_hinge("rudder", Vector3(4.47, 0, 0), Vector3.UP, 0.0 if ok else 0.6)
		"avionics":  # antenna mast snapped over at its base
			_hinge("antenna_elt", Vector3(0.44, 0.17, 0.38), Vector3.RIGHT, 0.0 if ok else 1.4)
		"propeller":
			if ok:
				model(n, "propeller_ok", Vector3(0, 1.2, -1.42), 1.85, Vector3.ZERO, tmat("prop_wood", Color.WHITE, 1.0))
			else:
				model(n, "propeller_broken", Vector3(0, 1.2, -1.42), 1.85)
	return n


# ---------- mesh helpers ----------

## Smudges and wear: roughness multiplier between 0.7 and 1.0, so nothing is one flat sheen.
static var ROUGH_TEX := _rough_tex()


static func _rough_tex() -> NoiseTexture2D:
	var t := NoiseTexture2D.new()
	t.seamless = true
	t.noise = FastNoiseLite.new()
	t.noise.frequency = 0.04
	t.noise.fractal_octaves = 4
	t.color_ramp = Gradient.new()
	t.color_ramp.set_color(0, Color.WHITE * 0.7)
	t.color_ramp.set_color(1, Color.WHITE)
	return t


const METALS := ["galvanized_metal", "metal_rust", "metal_steel", "cowling_metal"]


func mat(c) -> Material:  # c: Color, or an already-built Material
	if c is Material:
		return c
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95  # x0.7..1.0 from the smudge map
	m.roughness_texture = ROUGH_TEX
	return m


## Textured material from textures/<tex>.png. Triplanar mapping, so no mesh UVs needed;
## scale = repeats per meter. Tint multiplies the texture.
func tmat(tex: String, tint := Color.WHITE, scale := 0.5) -> StandardMaterial3D:
	var m: StandardMaterial3D = mat(tint)
	m.albedo_texture = load("res://textures/%s.png" % tex)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	if tex in METALS:  # worn metal: 0.42..0.6, with a real metallic response
		m.roughness = 0.6
		m.metallic = 0.55
	return m


## Flat see-through quad (stains, cracks, signs) facing `normal`. tex "" = plain quad.
func decal(parent: Node, size: Vector2, pos: Vector3, tex: String, normal: Vector3) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	if tex != "":
		m.albedo_texture = load("res://textures/%s.png" % tex)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	var mi := _place(parent, q, pos, false)
	var up := Vector3.UP if absf(normal.normalized().y) < 0.9 else Vector3.FORWARD
	mi.basis = Basis.looking_at(-normal, up)  # quads face +Z; looking_at aims -Z
	return mi


## Instance res://models/<name>.glb, scaled so its longest side is `size` meters and its
## bounding-box center sits at `pos` (measured, so any model's export scale works).
func model(parent: Node, name: String, pos: Vector3, size: float, rot := Vector3.ZERO, override: Material = null) -> Node3D:
	var m: Node3D = load("res://models/%s.glb" % name).instantiate()
	parent.add_child(m)
	var bounds := AABB()
	var first := true
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (m.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
		if override:
			mi.material_override = override
	m.rotation = rot
	m.scale = Vector3.ONE * size / bounds.get_longest_axis_size()
	m.position = pos - m.basis * bounds.get_center()
	m.set_meta("bounds", bounds)  # unscaled, in the model's own space
	return m


## A model resting on the floor at `at` (x/z). collide: "box" = invisible box around it,
## "mesh" = exact walls (buildings you walk into), "trunk" = thin post (trees).
func prop(name: String, at: Vector3, size: float, look: Material, yaw := 0.0, collide := "box") -> Node3D:
	var m := model(world, name, at, size, Vector3(0, yaw, 0), look)
	var bounds := AABB()
	var first := true
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (world.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		bounds = b if first else bounds.merge(b)
		first = false
	m.position.y += at.y - bounds.position.y  # drop it onto the floor
	match collide:
		"box":
			var hit := box(world, bounds.size, Vector3(at.x, at.y + bounds.size.y / 2, at.z), Color.WHITE, true)
			hit.visible = false
		"mesh":
			for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
				var body := StaticBody3D.new()
				var wall := CollisionShape3D.new()
				if not _walls.has(mi.mesh):
					_walls[mi.mesh] = mi.mesh.create_trimesh_shape()
				wall.shape = _walls[mi.mesh]
				body.add_child(wall)
				mi.add_child(body)
		"trunk":
			_trunk(at)
	return m


const TREE_SPLIT := {"tree_broadleaf_a": 0.33, "tree_broadleaf_b": 0.12, "tree_broadleaf_c": 0.42}  # trunk share of height
var _tree_shader: Shader

## The tree models come untextured as one mesh: bark below `split` of the height, leaves above.
func _paint_tree(m: Node3D, split: float, tint: Color) -> void:
	if not _tree_shader:
		_tree_shader = Shader.new()
		_tree_shader.code = """
shader_type spatial;
uniform sampler2D bark : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaves : source_color, filter_linear_mipmap, repeat_enable;
uniform float y0;
uniform float h = 1.0;
uniform float split = 0.3;
uniform vec3 tint = vec3(1.0);
varying vec3 lp;
void vertex() {
	lp = VERTEX;
	float s = smoothstep(split, 1.0, (VERTEX.y - y0) / h);  // canopy sways, trunk stays put
	vec3 w = MODEL_MATRIX[3].xyz;
	VERTEX.xz += vec2(sin(TIME * 1.1 + w.x * 0.3), cos(TIME * 0.9 + w.z * 0.3)) * 0.012 * h * s;
}
void fragment() {
	float t = (lp.y - y0) / h;
	vec3 b = texture(bark, vec2(lp.x + lp.z, lp.y) * 6.0).rgb;
	vec3 l = texture(leaves, (lp.xz + lp.y) * 5.0).rgb * tint;
	ALBEDO = mix(b, l, smoothstep(split - 0.03, split + 0.03, t));
	ROUGHNESS = 0.9;
}"""
	var bounds: AABB = m.get_meta("bounds")
	var sm := ShaderMaterial.new()
	sm.shader = _tree_shader
	sm.set_shader_parameter("bark", load("res://textures/bark.png"))
	sm.set_shader_parameter("leaves", load("res://textures/foliage.png"))
	sm.set_shader_parameter("y0", bounds.position.y)
	sm.set_shader_parameter("h", bounds.size.y)
	sm.set_shader_parameter("split", split)
	sm.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = sm


## Scatter `count` crossed-quad cards of textures/<tex>.png (grass, wheat) as one MultiMesh.
func _cards(tex: String, count: int, height: float, area: Rect2, r: RandomNumberGenerator, tint := Color.WHITE) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(height * 1.2, height)
	q.center_offset = Vector3(0, height / 2, 0)
	var st := SurfaceTool.new()
	st.append_from(q, 0, Transform3D.IDENTITY)
	st.append_from(q, 0, Transform3D(Basis(Vector3.UP, PI / 2), Vector3.ZERO))
	var mesh := st.commit()
	if not _grass_shader:
		_grass_shader = Shader.new()
		_grass_shader.code = GRASS_SHADER
	var m := ShaderMaterial.new()
	m.shader = _grass_shader
	m.set_shader_parameter("tex", load("res://textures/%s.png" % tex))
	m.set_shader_parameter("tint", tint)
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var i := 0
	while i < count:
		var p := Vector3(r.randf_range(area.position.x, area.end.x), 0, r.randf_range(area.position.y, area.end.y))
		if _kept_clear(p) or terrain.in_water(p.x, p.z) or terrain.slope(p.x, p.z) > 0.4:
			continue
		p.y = terrain.height(p.x, p.z) - 0.05
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.7, 1.3))
		mm.set_instance_transform(i, Transform3D(b, p))
		i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mmi)


var _grass_shader: Shader
# Cards bend from the root with the wind; gusts roll across the field as a slow wave.
# Normals point up so cards light like the ground they stand on instead of flat paper.
const GRASS_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float bend = pow(1.0 - UV.y, 1.5);
	float gust = sin(dot(w.xz, vec2(0.07, 0.04)) - TIME * 1.3) * 0.5 + 0.5;
	float flutter = sin(TIME * 4.0 + w.x * 1.7 + w.z * 1.3) * 0.04;
	vec3 wind = vec3(1.0, 0.0, 0.45) * ((0.05 + 0.22 * gust) * bend + flutter * bend);
	VERTEX += inverse(mat3(MODEL_MATRIX)) * wind;
	NORMAL = inverse(mat3(MODEL_MATRIX)) * vec3(0.0, 1.0, 0.0);
}
void fragment() {
	vec4 c = texture(tex, UV);
	ALBEDO = c.rgb * tint.rgb * mix(0.55, 1.0, 1.0 - UV.y);
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.4;
	ROUGHNESS = 0.9;
}
"""


## Runway and apron surface: the texture at two scales, blended by a big noise mask, plus a
## patchy tint and roughness, so the gravel doesn't repeat like wallpaper.
static var FLAT_SHADER := _flat_shader()


static func _flat_shader() -> Shader:
	var s := Shader.new()
	s.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D mask : repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap, repeat_enable;
uniform float scale = 0.4;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float m = texture(mask, wp.xz * 0.02).r;
	float m2 = texture(mask, wp.xz * 0.11 + 0.37).r;
	vec3 a = texture(tex, wp.xz * scale).rgb;
	vec3 b = texture(tex_b, wp.xz * scale * 0.83 + vec2(0.13, 0.71)).rgb;  // second texture (gravel_b) at a nearby scale
	vec3 c = mix(a, b, smoothstep(0.35, 0.65, m));
	ALBEDO = c * mix(0.82, 1.08, m2) * mix(vec3(0.95, 0.93, 0.9), vec3(1.0), m);
	ROUGHNESS = mix(0.75, 0.98, m2);
}
"""
	return s


var _mask_tex: NoiseTexture2D  # full 0..1 range (ROUGH_TEX is squeezed to 0.7..1)


func _flat_ground(tex: String, scale: float, tex_b := "") -> ShaderMaterial:
	var sm := ShaderMaterial.new()
	sm.shader = FLAT_SHADER
	sm.set_shader_parameter("tex", load("res://textures/%s.png" % tex))
	sm.set_shader_parameter("tex_b", load("res://textures/%s.png" % (tex_b if tex_b != "" else tex)))
	if not _mask_tex:
		_mask_tex = NoiseTexture2D.new()
		_mask_tex.seamless = true
		_mask_tex.noise = FastNoiseLite.new()
		_mask_tex.noise.frequency = 0.02
	sm.set_shader_parameter("mask", _mask_tex)
	sm.set_shader_parameter("scale", scale)
	return sm


## Orange-and-white windsock on a pole beside the strip; it swings and lifts with the gusts.
var sock: Node3D


func _build_windsock(at: Vector3) -> void:
	cyl(world, 0.05, 0.07, 6.0, at + Vector3(0, 3.0, 0), _trim(Color(0.85, 0.85, 0.82)), 8, true)
	ball(world, 0.09, at + Vector3(0, 6.05, 0), Color(0.8, 0.2, 0.1))
	sock = Node3D.new()
	sock.position = at + Vector3(0, 5.75, 0)
	world.add_child(sock)
	cyl(sock, 0.025, 0.025, 0.7, Vector3(0.0, 0.0, 0.0), Color(0.3, 0.3, 0.3))  # swivel arm
	var fabric := ShaderMaterial.new()  # stripes run along the sleeve: the texture's x maps to its length
	fabric.shader = SOCK_SHADER
	fabric.set_shader_parameter("tex", load("res://textures/windsock_fabric.png"))
	var sleeve := cyl(sock, 0.14, 0.3, 2.3, Vector3(1.4, 0, 0), fabric, 12)
	sleeve.rotation.z = -PI / 2  # cylinder axis Y -> +X, narrow end out


const SOCK_SHADER_CODE := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
void fragment() {
	ALBEDO = texture(tex, vec2(1.0 - UV.y, UV.x)).rgb;  // cylinder v runs along the sleeve; tail (top) = texture's right
	ROUGHNESS = 0.9;
}
"""
static var SOCK_SHADER := _code_shader(SOCK_SHADER_CODE)


static func _code_shader(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


## Worn metal from the team's trim sheet (panel seams, rivets, chipped edges) with its roughness map.
func _trim(tint: Color) -> StandardMaterial3D:
	var m := tmat("trim_metal", tint, 1.2)
	m.roughness = 1.0
	m.roughness_texture = load("res://textures/trim_metal_rough.png")
	m.metallic = 0.45
	return m


## Dry leaves under the windbreak and in the hangar corners, pebbles along the apron edges.
func _scatter_litter(r: RandomNumberGenerator) -> void:
	for i in 40:
		var p := Vector3(r.randf_range(-60, 60), 0, r.randf_range(-70, 75))
		if _kept_clear(p) and not (p.x < -9 and p.x > -23 and p.z < -7 and p.z > -21):  # runway/lot stay clean, hangar floor ok
			continue
		if terrain.in_water(p.x, p.z):
			continue
		p.y = terrain.height(p.x, p.z) + 0.03
		var leaf := decal(world, Vector2.ONE * r.randf_range(0.6, 1.3), p, "decal_leaves", Vector3.UP)
		var cell := Vector2(r.randi() % 2, r.randi() % 2) * 0.5  # one clump of the 2x2 sheet
		leaf.mesh.material.uv1_scale = Vector3(0.5, 0.5, 1)
		leaf.mesh.material.uv1_offset = Vector3(cell.x, cell.y, 0)
		leaf.rotate_y(r.randf() * TAU)
	for i in 14:  # loose stones kicked off the apron edges
		var side := r.randi() % 4
		var p := Vector3(r.randf_range(-9, 9), 0.035, r.randf_range(1, 14))
		if side == 0: p.x = -9.3
		elif side == 1: p.x = 9.3
		elif side == 2: p.z = 0.8
		else: p.z = 14.2
		var peb := decal(world, Vector2.ONE * r.randf_range(0.4, 0.9), p, "decal_pebbles", Vector3.UP)
		peb.rotate_y(r.randf() * TAU)


## A bare warm bulb: lights the spots you walk up to (radio, toolbox, parts counter).
func _lamp(at: Vector3) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.72, 0.42)
	l.light_energy = 3.0
	l.omni_range = 7.0
	l.position = at
	world.add_child(l)
	var bulb := ball(world, 0.07, at + Vector3(0, 0.08, 0), Color(1.0, 0.85, 0.55))
	bulb.mesh.material.emission_enabled = true
	bulb.mesh.material.emission = Color(1.0, 0.75, 0.4)
	bulb.mesh.material.emission_energy_multiplier = 3.0


## Draws one mesh at many transforms in a single draw call.
func _multi(mesh: Mesh, xforms: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	world.add_child(mmi)


var trunks: StaticBody3D  # this field's tree trunks, one shared shape each
static var TRUNK_SHAPE := _trunk_shape()


static func _trunk_shape() -> CylinderShape3D:
	var s := CylinderShape3D.new()
	s.radius = 0.3
	s.height = 3.0
	return s


## A 3 m post the player bumps into instead of walking through a tree.
func _trunk(at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = TRUNK_SHAPE
	cs.position = at + Vector3(0, 1.5, 0)
	trunks.add_child(cs)


## Runway, apron and building lot stay free of grass and props.
func _kept_clear(p: Vector3) -> bool:
	return absf(p.z - 20) < 7.5 or (p.x > -26 and p.x < 20 and p.z > -24 and p.z < 15)


func box(parent: Node, size: Vector3, pos: Vector3, c, solid := false) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat(c)
	return _place(parent, bm, pos, solid)


func cyl(parent: Node, top: float, bottom: float, h: float, pos: Vector3, c, segs := 6, solid := false) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	cm.material = mat(c)
	return _place(parent, cm, pos, solid)


func ball(parent: Node, radius: float, pos: Vector3, c) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2
	sm.radial_segments = 6
	sm.rings = 3
	sm.material = mat(c)
	return _place(parent, sm, pos, false)


func _place(parent: Node, mesh: Mesh, pos: Vector3, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	parent.add_child(mi)
	if solid:
		mi.create_convex_collision()
	return mi


## Invisible box the player's look-ray can hit (layer 2) to get an "E:" prompt.
func interactable(parent: Node, pos: Vector3, size: Vector3, kind: String) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 2
	b.collision_mask = 0
	b.position = pos
	b.set_meta("kind", kind)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	parent.add_child(b)
	return b


func _icon3d(icon: String, pos: Vector3) -> void:
	var s3 := Sprite3D.new()
	s3.texture = load("res://textures/hud/%s.svg" % icon)
	s3.fixed_size = true
	s3.pixel_size = 0.0008
	s3.shaded = false
	s3.visibility_range_end = 6.0  # only near enough to matter
	s3.visibility_range_end_margin = 1.5
	s3.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	s3.position = pos
	s3.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	world.add_child(s3)

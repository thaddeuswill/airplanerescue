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
const FAULTS := {
	"tire": {"name": "Flat main tire", "part": "Tire & tube", "cost": 180, "zone": "gear_l", "symptom": "sits low on the left side"},
	"brakes": {"name": "Rusted brake disc", "part": "Brake disc", "cost": 260, "zone": "gear_r", "symptom": "grinds when it taxis"},
	"battery": {"name": "Dead battery", "part": "Battery", "cost": 350, "zone": "battery", "symptom": "won't crank, everything's dead"},
	"spark_plugs": {"name": "Fouled spark plugs", "part": "Spark plug set", "cost": 220, "zone": "engine", "symptom": "runs rough, puffs black smoke"},
	"oil_leak": {"name": "Oil leak", "part": "Gasket kit", "cost": 150, "zone": "engine", "symptom": "oil spots under the nose"},
	"bird_nest": {"name": "Bird nest on the cowling", "part": "", "cost": 0, "zone": "engine", "symptom": "birds flying out of the cowling"},
	"fuel_line": {"name": "Leaking fuel line", "part": "Fuel line kit", "cost": 300, "zone": "wing_l", "symptom": "smells of avgas under the wing"},
	"windshield": {"name": "Cracked windshield", "part": "Windshield", "cost": 900, "zone": "cabin", "symptom": "got caught in a hailstorm"},
	"starter": {"name": "Seized starter", "part": "Starter motor", "cost": 1100, "zone": "engine", "symptom": "the starter just clicks"},
	"control_cables": {"name": "Jammed rudder cables", "part": "Control cable set", "cost": 650, "zone": "tail", "symptom": "rudder pedals are stiff"},
	"magneto": {"name": "Bad magneto", "part": "Magneto", "cost": 1400, "zone": "engine", "symptom": "dies on the mag check"},
	"avionics": {"name": "Broken radio antenna", "part": "Antenna & radio", "cost": 1800, "zone": "cabin", "symptom": "radio's dead, can't raise anyone"},
	"propeller": {"name": "Bent propeller", "part": "Propeller", "cost": 2600, "zone": "prop", "symptom": "hit a fence post taxiing"},
	# Neglect jobs: only planes that sat for years get these (see _spawn_job).
	"stale_fuel": {"name": "Stale fuel in the tanks", "part": "Fresh avgas", "cost": 90, "zone": "wing_l", "symptom": "hasn't had fresh gas in years"},
	"pre_oil": {"name": "Dry engine: pre-oil before start", "part": "", "cost": 0, "zone": "engine", "symptom": "hasn't been started in years"},
	"door_pin": {"name": "Door pin rusted solid", "part": "Door pin & cotter", "cost": 120, "zone": "cabin", "symptom": "can't even get the door open"},
}
const NEGLECT_FAULTS := ["stale_fuel", "pre_oil", "door_pin"]
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
# Southeast and Midwest: fields cut out of solid woods.
const THICK_WOODS := ["Atlanta", "Nashville", "Miami", "Wichita", "Omaha", "Chicago", "Fargo", "Minneapolis"]
const HERO_TREES := 150  # full-detail trees around a field in the woods
const WOODS_TREES := 80000  # 100x the plains count. Canopies already touch at this density, so it's also the cap
# How you find each fault. Seen on the walk-around (clue = what you notice at that spot), or only
# heard/felt on the run-up from the cockpit.
const RUNUP_FAULTS := ["battery", "starter", "avionics", "magneto", "spark_plugs"]
const CLUES := {
	"tire": "the left tire is squashed flat on its rim",
	"brakes": "orange rust and deep grooves on the right brake disc",
	"oil_leak": "fresh oil dripping off the bottom of the cowling",
	"bird_nest": "straw poking out of the cowl inlet, and chirping inside",
	"fuel_line": "a blue stain and a sharp avgas smell under the wing root",
	"windshield": "a long crack right across the windshield",
	"control_cables": "the rudder flops loose; its cables feel slack",
	"propeller": "a prop tip bent back and the blade edge chewed up",
	"battery": "Master ON: nothing. No ammeter flicker, no lights. Battery's dead",
	"starter": "Starter just clicks and won't turn the prop over",
	"avionics": "Radio's dead silent, not even a hiss. The antenna's snapped too",
	"magneto": "Mag check: big drop on the left mag, the engine nearly quits",
	"spark_plugs": "Runs rough on both mags and puffs black smoke",
	"stale_fuel": "the sumped fuel smells like varnish and comes out dark",
	"pre_oil": "an engine that sat this long can't be cranked dry: pull the plugs and pre-oil it first",
	"door_pin": "the cabin door won't budge; the handle moves but the pin doesn't",
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
const PLANE_TYPES := [["High-wing trainer", 1500], ["Rag-wing taildragger", 2000],
	["Bush plane", 2500], ["Vintage tourer", 3000], ["Utility hauler", 3500]]

var money := 3000:
	set(v):
		if is_node_ready() and v != money:
			_money_pop(v - money)
		money = v
var day := 1.0  # travel, inspections and repairs take time; calls have deadlines
var rescued := 0
var location := START_CITY
var inventory := {}
var jobs: Array = []
var current_job = null  # Dictionary of the plane at this field, or null
var logbook: Array = []  # one entry per rescue: {day, city, type, pay, faults}
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
var goal: Label
var _banner_node: Control
var _saved: Label
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
	if had_save:
		_load_field(location, current_job)
		_say("Welcome back. Day %d in %s." % [floori(day), location])
	elif save_locked:
		while jobs.size() < MAX_JOBS:
			_spawn_job()
		_load_field(START_CITY, null)
		_say("Couldn't read your saved game, so it was left untouched. This session won't be saved over it.")
	else:
		tools = STARTER_TOOLS.duplicate()  # a new career starts with a screwdriver and a rag
		while jobs.size() < MAX_JOBS:
			_spawn_job()
		_load_field(START_CITY, null)
		_say("Home base. You own a screwdriver and a rag; buy the rest. WASD walks, E uses things, Esc pauses.")
	_warm_assets()
	if not "--self-test" in args and not skip_menu:
		_open_menu()
	skip_menu = false
	if "--self-test" in args:
		var test = load("res://scripts/selftest.gd").new()
		add_child(test)
		test.run(self, args)
	elif not "--monkey" in args:
		updater = Updater.new()
		add_child(updater)
		updater.available.connect(_offer_update)
		updater.check()


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
const SAVE_KEYS := ["money", "day", "rescued", "location", "inventory", "tools", "jobs", "logbook", "graphics"]
const SAVE_VERSION := 1  # bump when the layout changes, and teach _migrate the step
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
	for j in data.get("jobs", []):  # fields added after the first saves shipped
		for key in ["years", "washed", "spent", "work", "fuel", "parked"]:
			if not j.has(key):
				j[key] = {"years": 0, "washed": true, "spent": {"fuel": 0, "parts": 0, "mail": 0}, "work": {}, "fuel": 0.2, "parked": "apron"}[key]
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
	var ids := FAULTS.keys().filter(func(id): return not id in NEGLECT_FAULTS)
	ids.shuffle()
	var faults := ids.slice(0, 1 + rng.randi() % mini(4, 2 + rescued / 3))
	# Some planes were just parked; others sat in the weather for years (Rebuild Rescue style):
	# grimy, stale gas, a dry engine, maybe a door rusted shut. Those pay more.
	var years := 0 if rng.randf() < 0.45 else rng.randi_range(2, 15)
	if years >= 2:
		faults.append("stale_fuel")
	if years >= 5:
		faults.append("pre_oil")
	if years >= 8 and rng.randf() < 0.6:
		faults.append("door_pin")
	var cost := 0
	for id in faults:
		cost += FAULTS[id].cost
	jobs.append({"city": options[rng.randi() % options.size()], "type": t[0], "faults": faults,
		"fixed": {}, "found": {}, "checked": {}, "work": {}, "years": years, "washed": years == 0,
		"spent": {"fuel": 0, "parts": 0, "mail": 0}, "fuel": rng.randf_range(0.03, 0.3), "parked": "apron",
		"reward": int(round((t[1] + cost * 2.0 + years * 150) / 50.0)) * 50,
		"deadline": day + 7 + rng.randi() % 9})


## What the owner tells you on the radio: every fault's symptom, in random order.
func _symptoms(job: Dictionary) -> String:
	var s: PackedStringArray = []
	for id in job.faults:
		s.append(FAULTS[id].symptom)
	var t := "; ".join(s)
	var years: int = job.get("years", 0)
	var sat := (" Sat out in the weather %d years." % years) if years > 0 else ""
	return "\"" + t[0].to_upper() + t.substr(1) + ".\"" + sat


func _advance(days: float) -> void:
	day += days
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


## Walk-around inspection of one spot: reveals any faults there.
func _inspect_zone(zone: String) -> void:
	standing_at = zone
	if not current_job.get("washed", true):  # years of dirt and lichen hide everything
		_say("It's caked in grime and lichen. You can't tell what's damage and what's dirt: wash it down first.")
		_open_inspection()
		return
	if not current_job.checked.has(zone):
		current_job.checked[zone] = true
		_advance(0.05)
		if not current_job:  # the owner gave up while you were looking
			return
		var seen: PackedStringArray = []
		for id in current_job.faults:
			if FAULTS[id].zone == zone and not id in RUNUP_FAULTS:  # the rest only show on the run-up
				current_job.found[id] = true
				seen.append(CLUES[id])
		_say(("%s: %s." % [ZONES[zone].name.capitalize(), "; ".join(seen)]) if seen.size() > 0
			else "%s: nothing wrong you can see." % ZONES[zone].name.capitalize())
	if current_job:
		_open_inspection()


## Bucket, brush and a hose: an afternoon's work, and then you can see what you bought.
func _wash() -> void:
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
		var dirt := tmat("grime_lichen", Color(1, 1, 1, 0.95), 0.6)  # years of grime and lichen; texture alpha = coverage
		dirt.roughness = 1.0
		dirt.metallic = 0.0
		dirt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m = dirt
	for mi: MeshInstance3D in cub.find_children("*", "MeshInstance3D", true, false):
		mi.material_overlay = m


## Sit in and run the engine up: master, crank, radio, mag check. What you hear and feel finds
## the faults a walk-around can't. A dead battery or starter stops the test there.
func _run_up() -> void:
	var job: Dictionary = current_job
	_advance(0.04)
	if not current_job:
		return
	var heard: PackedStringArray = []
	var broken := func(id): return job.faults.has(id) and not job.fixed.has(id)
	var hear := func(id):
		job.found[id] = true
		heard.append(CLUES[id])
	if broken.call("door_pin"):  # you can't run it up from outside
		hear.call("door_pin")
		job.runup = "dead"
	elif broken.call("pre_oil"):  # cranking a dry engine that sat for years wipes the cam
		hear.call("pre_oil")
		job.runup = "dead"
	elif broken.call("battery"):
		hear.call("battery")
		job.runup = "dead"
	else:
		if broken.call("avionics"):
			hear.call("avionics")
		if broken.call("starter"):
			hear.call("starter")
			job.runup = "dead"
		else:
			for id in ["magneto", "spark_plugs"]:
				if broken.call(id):
					hear.call(id)
			if heard.is_empty():
				heard.append("Fires right up, smooth on both mags, oil pressure in the green")
			job.runup = "ran"
	_say(". ".join(heard) + ("." if job.runup == "ran" else ". Can't run it up until that's fixed."))
	_save_game()
	_open_inspection("cabin")


## Opens the 2D work scene for this fault: real tools, every screw and bolt (scripts/work.gd).
func _repair(id: String) -> void:
	_close_panel()
	var w = Work.new()
	w.setup(self, id, current_job)
	w.finished.connect(func(): _work_done(id))
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
	current_job.fixed[id] = true
	if id == "stale_fuel":
		current_job.fuel = 1.0  # you refilled it with fresh 100LL
	_refresh_parts_table()
	visuals[id].queue_free()
	visuals[id] = _part_visual(id, true)
	_say("Fixed: " + FAULTS[id].name)
	sound.pen()  # signed off on the work order
	sound.done_tone()
	_open_inspection(FAULTS[id].zone)
	_banner("FIXED", FAULTS[id].name)


func _buy(part: String, cost: int, mail := false) -> void:
	money -= cost
	inventory[part] = inventory.get(part, 0) + 1
	if current_job:
		_spend(current_job, "parts", cost)
	if mail:
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
	_say("Run the checklist, then hold Space to start her up.")


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
	_after_flight()
	_banner("RESCUED", "%d of %d planes back in the air" % [rescued, GOAL])


## The aircraft logbook entry: what was done, in your words, over your signature.
func _open_signoff() -> void:
	var job: Dictionary = current_job
	var work: PackedStringArray = []
	for id in job.faults:
		if job.fixed.has(id):
			work.append(FAULTS[id].name)
	_open_panel("Aircraft logbook", [["%s, at %s, day %d" % [job.type, job.city, floori(day)]],
		["Work performed\n" + (", ".join(work) if work.size() > 0 else "Inspection only, no defects found.")],
		["Inspection\nWalk-around: %d of %d spots checked. Engine run-up satisfactory." % [job.checked.size(), ZONES.size()]],
		["Return to service\nI certify this aircraft has been inspected and is approved for return to service.", "Sign it", _sign_logbook, true]])


func _sign_logbook() -> void:
	current_job.signed = true
	sound.pen()
	_save_game()
	_open_inspection()
	_banner("SIGNED OFF", "Approved for return to service")


## The fault you never found caught up with you. Down safely: it costs a day and a quarter of
## the pay, and the job reopens. Crashed: the job and the excess are gone, and you walk away.
func _flight_failed(result: String) -> void:
	var id: String = ferry.trouble
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
		else "What you missed\n%s, at the %s. You never looked there." % [what, ZONES[FAULTS[id].zone].name]
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
	money += job.reward
	rescued += 1
	jobs.erase(job)
	current_job = null
	var spent: Dictionary = job.get("spent", {})
	logbook.append({"day": floori(day), "city": job.city, "type": job.type, "pay": job.reward,
		"work": job.faults.map(func(id): return FAULTS[id].name), "years": job.get("years", 0),
		"fuel": spent.get("fuel", 0), "parts": spent.get("parts", 0), "days": day - job.get("arrived", day)})
	_say("The %s is back in the air! Owner paid $%d." % [job.type, job.reward])
	while jobs.size() < MAX_JOBS:
		_spawn_job()
	sound.chime()  # a new call on the radio
	_save_game()


func _after_flight() -> void:
	if rescued == GOAL:
		_open_ending()
	else:
		_open_travel()


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
	_open_panel("Out of money and grounded. Game over.", [["You rescued %d of %d planes\nThat work still counts: every one is in your logbook." % [rescued, GOAL]],
		["What happened\nYou have $%d. The cheapest flight to a call costs $%d, and you can't afford to finish the job here." % [money, cheapest]],
		["Next time\nKeep enough cash back to fly to the next call, and check the parts bill before you take a job."]]
		+ _career_stats() + [["", "Play again", _restart, true], ["", "Main menu", _quit_to_title, true]], false)


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
		if f.part != "" and inventory.get(f.part, 0) == 0:
			need += _price(id)
		var n: Array = Work.needs_for(id)
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
	skip_menu = true  # straight into the new career, not back to the title screen
	get_tree().reload_current_scene()


static var skip_menu := false
var _pending_update := []  # an update offer that arrived while the title screen was up


## Design-doc palette (MyAP GDD): dark earth, aged paper, hangar green, worn brass,
## fault red, serviceable green, pending amber. Clean DIN-style type on screen; the typewriter
## face is only for the paper shop log on the hangar wall.
const C_EARTH := Color("1C1810")
const C_PAPER := Color("F5F0E6")
const C_GREEN := Color("2E5339")
const C_BRASS := Color("C8B99A")
const C_RED := Color("8B2020")
const C_OK := Color("285A32")
const C_AMBER := Color("8B6914")
static var TYPE_FONT := _type_font()


static var UI_FONT := _ui_font()
static var HEAD_FONT := _head_font()


static func _ui_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Arial", "sans-serif"])
	return f


static func _head_font() -> FontVariation:
	var f := FontVariation.new()
	f.base_font = UI_FONT
	f.variation_embolden = 0.5
	f.spacing_glyph = 1
	return f


static func _type_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Courier New", "Courier Prime", "Courier", "Nimbus Mono PS", "monospace"])
	f.font_weight = 700
	return f


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
	if not _pending_update.is_empty():
		_offer_update(_pending_update[0], _pending_update[1])
		_pending_update = []


# ---------- per-frame + input ----------

func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "interact": [KEY_E],
		"wallet": [KEY_TAB], "clipboard": [KEY_J], "logbook": [KEY_L],
		"throttle_up": [KEY_W], "throttle_down": [KEY_S], "rudder_left": [KEY_A], "rudder_right": [KEY_D],
		"stick_forward": [KEY_UP], "stick_back": [KEY_DOWN], "starter": [KEY_SPACE],
		"fuel_valve": [KEY_F], "master": [KEY_M], "primer": [KEY_P], "mags": [KEY_I],
	}
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
	cross.set_live(kind != "")
	_light_marker(t.get_meta("zone") if kind == "zone" else "")
	match kind:
		"zone":
			var z: String = t.get_meta("zone")
			prompt.text = ("E: Work order  (%s checked)" if current_job.checked.has(z) else "E: Inspect %s") % ZONES[z].name
		"shop": prompt.text = "E: Parts shed"
		"radio": prompt.text = "E: Radio"
		"map": prompt.text = "E: Map - rescue calls"
		"toolbox": prompt.text = "E: Toolbox"
		"truck": prompt.text = "E: Fuel truck"
		"parts_table": prompt.text = "E: Parts on hand"
	if kind != "" and Input.is_action_just_pressed("interact") and close_frame != Engine.get_process_frames():
		match kind:
			"zone": _inspect_zone(t.get_meta("zone"))
			"shop": _open_shop()
			"radio": _open_radio()
			"map": _open_travel()
			"toolbox": _open_toolbox()
			"truck": _open_truck()
			"parts_table": _open_parts_table()


func _input(e: InputEvent) -> void:  # before the GUI, so Tab isn't eaten by focus navigation
	if is_instance_valid(_loader):  # the field is half built: no panels until it's done
		return
	for kind in ["wallet", "clipboard", "logbook"]:
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
		return
	if e.is_action_pressed("interact") and panel and panel_closable:  # E toggles panels shut too
		_close_panel()
		close_frame = Engine.get_process_frames()
		return
	if e.is_action_pressed("ui_cancel"):
		if _sub_back.is_valid():
			_sub_back.call()
		elif panel:
			if panel_closable:
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
	_setup_pockets()
	cross = Reticle.new()
	ui.add_child(cross)
	prompt = _chip(17, 0.72, 0.8)
	msg = _chip(16, 0.03, 0.2)
	goal = _chip(14, 0.0, 0.0)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	var strip: CenterContainer = goal.get_parent()
	strip.anchor_right = 0.0  # top-left corner, the same spot all game
	strip.offset_left = 20
	strip.offset_top = 18


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
	box_.offset_left = SHEET_W if panel is PanelContainer else 0.0
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
		_saved = Label.new()
		_saved.text = "Saved"
		_saved.anchor_left = 1.0
		_saved.anchor_right = 1.0
		_saved.anchor_top = 1.0
		_saved.anchor_bottom = 1.0
		_saved.offset_left = -100
		_saved.offset_right = -20
		_saved.offset_top = -34
		_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_saved.add_theme_font_override("font", UI_FONT)
		_saved.add_theme_font_size_override("font_size", 13)
		_saved.add_theme_color_override("font_color", C_BRASS)
		_saved.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(_saved)
	if _saved_fade:
		_saved_fade.kill()
	_saved.modulate.a = 1.0
	_saved_fade = _saved.create_tween()
	_saved_fade.tween_interval(0.8)
	_saved_fade.tween_property(_saved, "modulate:a", 0.0, 0.5)


## What to do next, spelled out one step at a time. This is the game's running tutorial.
func _objective() -> String:
	if current_job == null:
		return "NEXT  Walk into the hangar and press E at the MAP on the workbench to take a rescue call"
	var j: Dictionary = current_job
	if j.checked.size() < ZONES.size():
		return "NEXT  Walk around the plane, press E at each ? marker  (%d of %d)" % [j.checked.size(), ZONES.size()]
	for id in j.faults:
		if j.found.has(id) and not j.fixed.has(id):
			return "NEXT  Fix: %s. Press E at the ! marker on the %s" % [FAULTS[id].name, ZONES[FAULTS[id].zone].name]
	if j.get("runup", "") != "ran":
		return "NEXT  Press E at the cabin and run the engine up"
	if not j.get("signed", false):
		return "NEXT  Press E at the plane and write up the logbook"
	if j.get("fuel", 1.0) < 0.5:
		return "NEXT  Fuel it at the truck by the hangar: at least half tanks"
	if j.get("parked", "apron") == "hangar":
		return "NEXT  Press E at the plane and roll it out of the hangar"
	return "NEXT  Press E at the cabin, climb in and fly it to the owner"


## Almost no HUD (ART_DIRECTION.md): money, parts and career live in things you take out.
func _update_hud() -> void:
	hud.visible = panel == null and ferry == null
	cross.visible = hud.visible
	prompt.visible = prompt.text != ""
	prompt.custom_minimum_size.x = 620.0 if ferry else 0.0  # flight numbers change every frame; a fixed box doesn't shake
	msg.visible = msg.text != ""
	var preflight: bool = ferry != null and ferry.state != "run" and panel == null
	goal.visible = hud.visible or preflight
	if preflight:
		goal.text = ferry.checklist()
	elif goal.visible:
		goal.text = _objective()
	# Toasts sit over the open half of the screen, never on top of a side sheet.
	msg.get_parent().offset_left = SHEET_W if panel is PanelContainer else 0.0


## Bottom-left strip of key hints (icons from textures/ui/ when the art exists).
func _setup_pockets() -> void:
	var strip := HBoxContainer.new()
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	strip.offset_left = 16
	strip.offset_top = -48
	strip.offset_bottom = -12
	strip.add_theme_constant_override("separation", 18)
	for p in [["wallet", "Tab", "Wallet"], ["clipboard", "J", "Clipboard"], ["logbook", "L", "Logbook"]]:
		var tex := "res://textures/ui/%s.png" % p[0]
		if ResourceLoader.exists(tex):
			var icon := TextureRect.new()
			icon.texture = load(tex)
			icon.custom_minimum_size = Vector2(40, 40)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.modulate = Color(1, 1, 1, 0.8)
			strip.add_child(icon)
		var l := Label.new()
		l.text = "%s  %s" % [p[1], p[2]]
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_constant_override("outline_size", 5)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.modulate = Color(1, 1, 1, 0.75)
		strip.add_child(l)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud = strip
	ui.add_child(hud)


var panel_kind := ""  # which pocket panel is open, so its key closes it again


func _pocket(kind: String) -> void:
	if ferry or get_tree().paused or panel_kind == "menu" or (panel and not panel_closable):
		return
	if panel and panel_kind == kind:
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
	panel_kind = kind


func _open_wallet() -> void:
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
	rows.append(["Materials: " + ", ".join(["Safety wire", "Cotter pin", "Penetrant"].map(func(k): return "%s %d" % [k, inventory.get(k, 0)]))])
	rows.append(["", "Start a new career", _confirm_restart, true])
	_open_panel("Wallet", rows)


func _set_graphics(level: String) -> void:
	graphics = level
	_apply_graphics()
	_save_game()


## High: everything. Low: no volumetric haze, bounce light, ambient occlusion or dust motes,
## the effects that cost frames on built-in laptop graphics.
func _apply_graphics() -> void:
	var high := graphics == "high" and not "--low" in OS.get_cmdline_user_args()
	env.volumetric_fog_enabled = high
	env.sdfgi_enabled = high
	env.ssao_enabled = high
	if motes:
		motes.emitting = high
		motes.visible = high


func _confirm_restart() -> void:
	_open_panel("Start over?", [["This throws away your money, logbook and every job in progress."],
		["", "Yes, start over", _restart, true], ["", "Keep playing", _close_panel, true]])


func _open_logbook() -> void:
	var rows := [["Planes back in the air: %d of %d" % [rescued, GOAL]]]
	for i in range(logbook.size() - 1, -1, -1):
		var e: Dictionary = logbook[i]
		var net: int = e.pay - e.get("fuel", 0) - e.get("parts", 0)
		rows.append(["Day %d  %s  -  %s%s\n%s\nPaid $%d - fuel $%d - parts $%d = %s$%d   (%.1f days on site)" % [e.day, e.city, e.type,
			(", sat %d yrs" % e.years) if e.get("years", 0) > 0 else "", ", ".join(e.work), e.pay, e.get("fuel", 0), e.get("parts", 0),
			"" if net >= 0 else "-", absi(net), e.get("days", 0.0)]])
	if logbook.is_empty():
		rows.append(["No entries yet. Your first rescue goes here."])
	_open_panel("Logbook", rows)


func _say(text: String) -> void:
	msg.text = text
	var long := text.length() > 70  # long messages wrap instead of running off both edges
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if long else TextServer.AUTOWRAP_OFF
	msg.custom_minimum_size.x = 560.0 if long else 0.0
	msg_time = 5.0


const SHEET_W := 660.0
var _list_title := ""
var _pages := []
var _page := 0
var _list: VBoxContainer
var _page_label: Label
var _side: Control  # something shown beside the sheet, like the chart: goes when the sheet goes


## One look for every screen: warm near-black enamel, paper-colored type, thin brass lines.
func _ui_theme() -> Theme:
	var t := Theme.new()
	t.default_font = UI_FONT
	t.default_font_size = 16
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
	sheet.theme = _ui_theme()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(C_EARTH, 0.96)
	sb.border_width_right = 1
	sb.border_color = Color(C_BRASS, 0.6)
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
	var rule := ColorRect.new()
	rule.color = C_BRASS
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
		icon.texture = load("res://textures/%s.png" % r[4])
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
		l.add_theme_font_size_override("font_size", 16 if i == 0 else 14)
		if i > 0:
			l.add_theme_color_override("font_color", C_BRASS)
		words.add_child(l)
	if r.size() > 1 and r[1] != "":
		var b := Button.new()
		b.text = r[1]
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.mouse_entered.connect(sound.sfx.bind("deny"))
		b.pressed.connect(sound.sfx.bind("thread"))
		b.pressed.connect(r[2])
		b.disabled = not r[3]
		hb.add_child(b)
		if b.disabled and "$" in r[1]:  # a greyed-out price says what's missing
			var short := "Need $%d more" % (int(r[1].get_slice("$", 1)) - money)
			b.tooltip_text = short
			var why := Label.new()
			why.text = short
			why.custom_minimum_size.x = _text_width(r)
			why.add_theme_font_size_override("font_size", 14)
			why.add_theme_color_override("font_color", Color(0.95, 0.65, 0.4))
			words.add_child(why)
	var line := ColorRect.new()
	line.color = Color(C_BRASS, 0.14)
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
var settings := {"master": 1.0, "music": 0.7, "sfx": 0.9, "sens": 1.0, "fullscreen": false, "invert": false, "shake": true, "station": 0}
const SETTINGS_PATH := "user://settings.cfg"
const CREDITS := [
	["Game\nthaddeuswill. Built with Godot Engine 4.7 (MIT license)."],
	["Plane model: Piper J-3 Cub for FlightGear\nDon Lavelle (model), David Megginson and Jim Wilson, GPLv3. Converted for this game. Source: github.com/wlbragg/J3Cub, and models_raw/j3cub_fg in this game's repository."],
	["Fonts: Yellowtail (Apache 2.0), Big Shoulders Display (SIL Open Font License)\nThe full license texts are in the licenses folder where the game is installed."],
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
	_apply_settings()


func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.master))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.music))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(settings.sfx))
	player.sens = Player.MOUSE_SENS * settings.sens
	player.invert = settings.invert
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


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
	settings[key] = value
	_save_settings()


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
	_open_panel("Paused", [["Everything stops until you come back."], ["", "Resume", _close_panel, true]]
		+ ([["", "Climb out of the plane", _leave_cockpit, true]] if parked_in_cockpit else []) + [
		["", "Settings", _open_settings.bind(_open_pause), true], ["", "Controls", _open_controls, true],
		["", "Credits", _open_credits.bind(_open_pause), true],
		] + ([["Your game saves after every step.", "Quit to title", _quit_to_title, true], ["", "Quit to desktop", _quit_game, true]] if _can_quit()
		else [["Finish the emergency first: what happens next counts."]]))
	get_tree().paused = true


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


func _open_settings(back: Callable) -> void:
	var vb := _sub_panel("Settings", [
		["Graphics: %s\nLow drops haze, bounce light and dust for weaker PCs." % graphics.capitalize(), "Switch", _switch_graphics.bind(back), true],
		["Display: %s" % ("Fullscreen" if settings.fullscreen else "Window"), "Switch", _switch_setting.bind("fullscreen", back), true],
		["Invert mouse look: %s" % ("On" if settings.invert else "Off"), "Switch", _switch_setting.bind("invert", back), true],
		["Screen shake: %s" % ("On" if settings.shake else "Off"), "Switch", _switch_setting.bind("shake", back), true]], back)
	var at := 0
	for s in [["Master volume", "master", 0.0, 1.0], ["Music volume", "music", 0.0, 1.0], ["Sound effects volume", "sfx", 0.0, 1.0], ["Mouse sensitivity", "sens", 0.3, 2.5]]:
		var hb := HBoxContainer.new()
		var l := Label.new()
		l.text = s[0]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		var sl := HSlider.new()
		sl.custom_minimum_size = Vector2(240, 24)
		sl.min_value = s[2]
		sl.max_value = s[3]
		sl.step = 0.01
		sl.value = settings[s[1]]
		sl.value_changed.connect(_set_setting.bind(s[1]))
		hb.add_child(sl)
		var pct := Label.new()
		pct.custom_minimum_size.x = 52
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.text = "%d%%" % roundi(sl.value * 100)
		sl.value_changed.connect(func(v): pct.text = "%d%%" % roundi(v * 100))
		sl.drag_ended.connect(func(_changed): sound.sfx("tray"))  # a sample to judge the new level by
		hb.add_child(pct)
		vb.add_child(hb)
		vb.move_child(hb, at)
		at += 1


func _switch_graphics(back: Callable) -> void:
	var was_paused := get_tree().paused
	_set_graphics("low" if graphics == "high" else "high")
	get_tree().paused = was_paused
	_open_settings(back)


func _switch_setting(key: String, back: Callable) -> void:
	_set_setting(not settings[key], key)
	_open_settings(back)


func _open_controls() -> void:
	_sub_panel("Controls", [["On foot\nW A S D walk, mouse looks, Space jumps, E uses what you're looking at."],
		["Tab / J / L\nWallet, clipboard, logbook."], ["Esc\nPause. On a screen, closes it."],
		["In a repair\nHold the left mouse to turn. Wheel or 1-6 switches tools."],
		["Starting the engine\nF fuel, M master, P primer, I mags, W/S throttle, hold Space for the starter."],
		["Flying\nW/S throttle, A/D rudder, Up arrow stick forward, Down arrow stick back."]], _open_pause)


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
const PART_MODELS := {"Brake disc": "brakes_ok", "Magneto": "magneto_ok", "Starter motor": "starter_ok",
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
	_text3d("PARTS ON HAND", at + Vector3(0, 2.0, 0), 36)
	_parts_table = Node3D.new()
	_parts_table.position = at + Vector3(0, 0.9, 0)
	world.add_child(_parts_table)
	_refresh_parts_table()


func _refresh_parts_table() -> void:
	if not is_instance_valid(_parts_table):
		return
	for ch in _parts_table.get_children():
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
			m.pixel_size = 0.007  # readable from across the apron
			m.outline_size = 18
			m.position = ZONES[z].pos + Vector3(0, ZONES[z].size.y * 0.5 + 0.25, 0)
			m.render_priority = 2
			m.outline_render_priority = 1
			m.add_child(_marker_sprite("glow", [[0.0, 0.8], [0.55, 0.45], [1.0, 0.0]], 0.012))
			m.add_child(_marker_sprite("ring", [[0.0, 0.0], [0.83, 0.0], [0.86, 1.0], [0.93, 1.0], [0.96, 0.0], [1.0, 0.0]], 0.0065))
			plane.add_child(m)
		var open: bool = job.faults.any(func(id): return FAULTS[id].zone == z and job.found.has(id) and not job.fixed.has(id))
		if z == "cabin" and job.get("runup", "") != "ran" and job.checked.has(z):
			open = true  # the run-up still waits here
		if not job.checked.has(z):
			m.text = "?"
			m.modulate = Color(1.0, 0.9, 0.3)
		elif open:
			m.text = "!"
			m.modulate = Color(1.0, 0.55, 0.15)
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
	s.shaded = false
	s.visible = false
	return s


var _lit_zone := ""


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
	var job: Dictionary = current_job
	var rows := [["Owner reports: " + _symptoms(job)],
		["Owner waits %d more day(s)" % maxi(0, ceili(job.deadline - day))],
		["Walk-around: %d of %d spots checked" % [job.checked.size(), ZONES.size()]]]
	for id in job.faults:
		if not job.found.has(id):
			continue
		var f: Dictionary = FAULTS[id]
		var icon: String = "icon_" + id if ResourceLoader.exists("res://textures/icon_%s.png" % id) else ""
		if job.fixed.has(id):
			rows.append(["OK  -  " + f.name, "", null, false, icon])
			continue
		var need := "No part needed" if f.part == "" else "Needs %s (have %d)" % [f.part, inventory.get(f.part, 0)]
		if at == f.zone:
			rows.append(["%s\n%s" % [f.name, need], "Work on it", func(): _repair(id), true, icon])
		else:
			rows.append(["%s\n%s. Work on it at the %s." % [f.name, need, ZONES[f.zone].name], "", null, false, icon])
	if not job.get("washed", true):
		rows.append(["Sat %d years: filthy, lichen on the wings." % job.years, "Wash it down" if at != "" else "", _wash, at != ""])
	var ran: bool = job.get("runup", "") == "ran"
	var runup_text: String = "Run-up: " + {"": "not done yet", "dead": "wouldn't start", "ran": "engine runs"}[job.get("runup", "")]
	if at == "cabin":
		rows.append([runup_text, "Sit in & run it up", _run_up, true])
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
	var done: bool = ran and not open_item  # you can sign what you've seen; what you skipped is on you
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


## Each town's shed stocks only some parts (fixed per town); the rest come by mail, slower and dearer.
func _stocked(part_id: String) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(location + part_id)
	return r.randf() < 0.6


## What this town's shed charges for a fault's part: shelf price, or +25% by mail.
func _price(id: String) -> int:
	return FAULTS[id].cost if _stocked(id) else int(FAULTS[id].cost * 1.25)


## The hangar toolbox: take tools into your roll (they travel with you) or put them back.
## Tools and the materials repairs use up. Nothing is free: buy at a parts shed that stocks
## it, or mail-order it from the hangar (1 day, +25%). You start with a screwdriver and a rag.
const SUPPLIES := {
	"ratchet": {"name": "Ratchet & sockets", "cost": 140, "tool": true},
	"torque": {"name": "Torque wrench", "cost": 260, "tool": true},
	"pliers": {"name": "Safety-wire pliers", "cost": 75, "tool": true},
	"Safety wire": {"name": "Safety wire (spool, 10 uses)", "cost": 25, "qty": 10},
	"Cotter pin": {"name": "Cotter pins (box of 10)", "cost": 15, "qty": 10},
	"Penetrant": {"name": "Penetrant (can, 3 uses)", "cost": 12, "qty": 3},
}
const STARTER_TOOLS := {"screwdriver": true, "rag": true}


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
func _supply_entry(key: String, mail: bool) -> Dictionary:
	var s: Dictionary = SUPPLIES[key]
	var price := int(s.cost * 1.25) if mail else int(s.cost)
	var tool: bool = s.get("tool", false)
	return {"name": s.name, "no": "AR-T%02d" % (20 + SUPPLIES.keys().find(key)), "blurb": CATALOG_BLURB.get(key, ""),
		"icon": _catalog_icon(key, "work/tool_" + key), "price": price, "mail": mail,
		"have": "" if tool else str(inventory.get(key, 0)), "owned": tool and tools.has(key),
		"can": money >= price, "buy": func(): _buy_supply(key, price, mail)}


func _supply_sections(keys: Array, mail: bool) -> Array:
	var t := []
	var m := []
	for key in keys:
		(t if SUPPLIES[key].get("tool", false) else m).append(_supply_entry(key, mail))
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
	_open_catalog("Mail-order catalog", "Mail order from the hangar: arrives in 1 day, 25% over shelf price",
		_supply_sections(SUPPLIES.keys(), true), _roll_note())


func _open_shop() -> void:
	var needed := {}
	if current_job:
		for id in current_job.found:
			if not current_job.fixed.has(id):
				needed[FAULTS[id].part] = true
	var parts := []
	var i := 0
	for id in FAULTS:
		var f: Dictionary = FAULTS[id]
		i += 1
		if f.part == "":
			continue
		var price := _price(id)
		var mail := not _stocked(id)
		var part: String = f.part
		parts.append({"name": part, "no": "AR-%d" % (1100 + i * 7), "blurb": CATALOG_BLURB.get(id, f.name),
			"icon": _catalog_icon(id, "icon_" + id), "price": price, "mail": mail,
			"have": str(inventory.get(part, 0)), "needed": needed.has(part), "can": money >= price,
			"buy": func(): _buy(part, price, mail)})
	parts.sort_custom(func(a, b): return a.needed and not b.needed)  # what this job needs comes first
	var shelf := SUPPLIES.keys().filter(_on_shelf)  # the rest is mail order from the hangar
	var sections := [{"id": "parts", "tab": "Parts", "head": "Section A: Aircraft parts", "items": parts}]
	_open_catalog("Parts counter", "Parts counter at %s, %s" % [location, STATE[location]], sections + _supply_sections(shelf, false), _roll_note())


func _open_travel() -> void:
	var rows := []
	var can_fly := false
	for job in jobs:
		if job == current_job:
			continue
		var cost := int(miles(location, job.city) * FUEL_PER_MILE)
		can_fly = can_fly or money >= cost
		var trip := miles(location, job.city) / 700.0
		rows.append(["%s: %s, pays $%d. %d NM, %.1f days, owner waits %d\n%s" % [job.city, job.type, job.reward,
			roundi(miles(location, job.city) * 0.869), trip, maxi(0, ceili(job.deadline - day)), _symptoms(job)],
			"Fly ($%d)" % cost, func(): _travel(job, cost), money >= cost])
	if not can_fly and not _can_finish_here():
		var fares := jobs.filter(func(j): return j != current_job).map(func(j): return int(miles(location, j.city) * FUEL_PER_MILE))
		_open_game_over(fares.min() if fares.size() > 0 else 0)
		return
	_open_panel("Rescue calls", rows)
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
		pin.disabled = money < cost
		pin.tooltip_text = "Fly to %s ($%d fuel)" % [job.city, cost]
		pin.pressed.connect(func(): _travel(job, cost))
		map.add_child(pin)


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
	"snow": {"sun": Color(0.95, 0.93, 0.92), "fog": Color(0.86, 0.88, 0.93), "elev": -14.0, "haze": 700.0},
}


func _apply_light(region_name: String) -> void:
	var l: Dictionary = REGION_LIGHT[region_name]
	sun.light_color = l.sun
	sun.rotation_degrees = Vector3(l.elev, 30, 0)
	env.fog_light_color = l.fog
	env.fog_depth_begin = 190.0  # about 30% of the ~650 m view: clear near, hazy far
	env.fog_depth_end = l.haze  # meters to full haze


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
	box(world, Vector3(18, 0.03, 13), Vector3(0, 0.015, 7.5), _flat_ground("gravel", 0.4, "gravel_b"))  # apron
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
	_text3d("MAP", chart_at + Vector3(0, 0.75, 0), 48)
	var set_at := at + Vector3(1.05, 1.1, -0.1)  # middle of the radio's case
	box(world, Vector3(0.66, 0.36, 0.3), set_at, tmat("wood_planks", Color(0.36, 0.22, 0.13), 2.0))
	box(world, Vector3(0.26, 0.26, 0.012), set_at + Vector3(-0.17, 0, 0.152), Color(0.16, 0.11, 0.08))  # speaker cloth
	box(world, Vector3(0.3, 0.09, 0.012), set_at + Vector3(0.14, 0.07, 0.152), Color(0.94, 0.87, 0.68))  # dial
	box(world, Vector3(0.012, 0.09, 0.016), set_at + Vector3(0.1, 0.07, 0.156), Color(0.66, 0.15, 0.12))  # needle
	for x in [0.06, 0.22]:
		box(world, Vector3(0.06, 0.06, 0.03), set_at + Vector3(x, -0.08, 0.16), Color(0.82, 0.74, 0.55))  # knobs
	interactable(world, set_at + Vector3(0, 0.05, 0.3), Vector3(1.0, 0.8, 0.9), "radio")
	_text3d("RADIO", set_at + Vector3(0, 0.6, 0), 48)


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
	_text3d("TOOLS", at + Vector3(-4.5, 1.6, BACK + 0.6), 40)
	_lamp(at + Vector3(-4.5, 2.6, BACK + 1.2))  # over the toolbox
	decal(world, Vector2(0.62, 0.44), at + Vector3(-4.03, 0.75, BACK + 0.6), "logo_decal", Vector3.RIGHT)
	var drum_paint := [Color(0.45, 0.6, 0.85), Color(0.8, 0.35, 0.3), Color(0.5, 0.6, 0.45)]
	for p in [Vector3(8.3, 0, -4), Vector3(9.0, 0, -3.2), Vector3(8.4, 0, -2.4), Vector3(-5.0, 0, 3)]:
		prop("barrel_a", at + p, 0.9, tmat("galvanized_metal", drum_paint[r.randi() % 3], 2.0), r.randf() * TAU)
	for p in [Vector3(-8.7, 0, 4), Vector3(-8.8, 0, 5.2)]:
		prop("crate_a", at + p, 1.0, tmat("wood_planks", Color(0.9, 0.8, 0.65), 1.5), r.randf_range(-0.3, 0.3))
	_build_workbench(at + Vector3(3, 0, BACK + 0.65))
	_lamp(at + Vector3(3, 2.9, BACK + 1.2))  # over the workbench
	_build_shop_log(at + Vector3(5.3, 1.8, BACK + 0.08))
	# A framed photo of an old rescue, sepia, over the desk.
	box(world, Vector3(0.62, 0.5, 0.03), at + Vector3(1.1, 2.1, BACK + 0.07), tmat("wood_planks", Color(0.35, 0.22, 0.12), 2.0))
	var photo := StandardMaterial3D.new()
	photo.albedo_texture = load("res://textures/rescue_photo.png")
	photo.albedo_color = Color(0.95, 0.78, 0.55)  # faded to sepia
	photo.roughness = 0.9
	box(world, Vector3(0.5, 0.38, 0.01), at + Vector3(1.1, 2.1, BACK + 0.09), photo)


## The shop's own maintenance log, tacked to the back wall: years of entries by hands long gone.
const SHOP_LOG := """SHOP LOG
4/12  Replaced L mag. Timed 25 BTC. R.H.
4/19  Tailwheel spring, new bolts, safetied. R.H.
5/02  Owner says "runs funny". Fouled plugs. Cleaned, gapped. J.T.
5/02  Same plane. Owner says still funny. Found mouse nest. J.T.
6/11  Prop dressed, tracked within 1/16. R.H.
7/04  Shop closed. Went flying."""


func _build_shop_log(pos: Vector3) -> void:
	box(world, Vector3(1.0, 1.25, 0.02), pos, tmat("paper_catalog", Color(0.92, 0.86, 0.72), 1.0))
	var l := Label3D.new()
	l.text = SHOP_LOG
	l.font = TYPE_FONT
	l.font_size = 20
	l.pixel_size = 0.0022
	l.modulate = C_EARTH
	l.outline_size = 0
	l.width = 420
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.position = pos + Vector3(0, 0, 0.02)
	world.add_child(l)


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


func _text3d(text: String, pos: Vector3, size: int) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 16
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	world.add_child(l)

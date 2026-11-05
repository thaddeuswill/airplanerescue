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
const GOAL := 10
const MAX_JOBS := 3
const START_CITY := "Wichita"
const FUEL_PER_MILE := 0.9

# city: [lon, lat, region, map_x, map_y] — map_x/y are pixels on textures/us_map.png (2048x1280),
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

var money := 3000
var day := 1.0  # travel, inspections and repairs take time; calls have deadlines
var rescued := 0
var location := START_CITY
var inventory := {}
var jobs: Array = []
var current_job = null  # Dictionary of the plane at this field, or null
var rng := RandomNumberGenerator.new()

var world: Node3D
var plane: Node3D
var cub: Node3D  # the plane model; its parts (tyre_l, rudder, antenna_elt...) are named nodes
var visuals := {}  # fault id -> Node3D showing broken/fixed state
var player
var ui: CanvasLayer
var hud: Label
var prompt: Label
var msg: Label
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
	_setup_input()
	_setup_environment()
	_setup_ui()
	player = Player.new()
	add_child(player)
	sound = Sound.new()
	add_child(sound)
	while jobs.size() < MAX_JOBS:
		_spawn_job()
	_load_field(START_CITY, null)
	_say("Home base. Walk into the hangar and use the RADIO to take a rescue call.")
	var args := OS.get_cmdline_user_args()
	if "--self-test" in args:
		_self_test(args)


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
	var t: Array = PLANE_TYPES[rng.randi() % PLANE_TYPES.size()]
	var ids := FAULTS.keys()
	ids.shuffle()
	var faults := ids.slice(0, 1 + rng.randi() % mini(4, 2 + rescued / 3))
	var cost := 0
	for id in faults:
		cost += FAULTS[id].cost
	jobs.append({"city": options[rng.randi() % options.size()], "type": t[0], "faults": faults,
		"fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": int(round((t[1] + cost * 2.0) / 50.0)) * 50,
		"deadline": day + 7 + rng.randi() % 9})


## What the owner tells you on the radio: every fault's symptom, in random order.
func _symptoms(job: Dictionary) -> String:
	var s: PackedStringArray = []
	for id in job.faults:
		s.append(FAULTS[id].symptom)
	var t := "; ".join(s)
	return "\"" + t[0].to_upper() + t.substr(1) + ".\""


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


func _travel(job: Dictionary, cost: int) -> void:
	money -= cost
	_close_panel()
	_advance(miles(location, job.city) / 700.0)
	if not jobs.has(job):  # ran out of time on the way
		_load_field(job.city, null)
		return
	_load_field(job.city, job)
	_say("Arrived in %s. Walk around the %s and press E on each part to inspect it." % [job.city, job.type])


## Walk-around inspection of one spot: reveals any faults there.
func _inspect_zone(zone: String) -> void:
	if not current_job.checked.has(zone):
		current_job.checked[zone] = true
		_advance(0.05)
		if not current_job:  # the owner gave up while you were looking
			return
		var found: PackedStringArray = []
		for id in current_job.faults:
			if FAULTS[id].zone == zone:
				current_job.found[id] = true
				found.append(FAULTS[id].name)
		_say(("%s: found %s" % [ZONES[zone].name.capitalize(), ", ".join(found)]) if found.size() > 0
			else "%s: looks good." % ZONES[zone].name.capitalize())
	if current_job:
		_open_inspection()


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
	visuals[id].queue_free()
	visuals[id] = _part_visual(id, true)
	_say("Fixed: " + FAULTS[id].name)
	_open_inspection()


func _buy(part: String, cost: int, mail := false) -> void:
	money -= cost
	inventory[part] = inventory.get(part, 0) + 1
	if mail:
		_advance(1.0)
		_say("The %s came on the morning mail truck." % part)
	_open_shop()


## Climb in: the camera moves to the pilot's seat and ferry.gd runs the takeoff.
func _start_ferry() -> void:
	_close_panel()
	player.frozen = true
	for c in plane.get_children():
		if c.has_meta("kind"):
			c.queue_free()  # inspection spots
	ferry = Ferry.new()
	add_child(ferry)
	ferry.finished.connect(_ferry_done)
	ferry.start(self, plane, visuals["propeller"].get_child(-1))
	_say("Hold W to open the throttle. At 55 knots, hold S to lift off.")


func _ferry_done() -> void:
	ferry.queue_free()
	ferry = null
	prompt.text = ""
	player.cam.make_current()
	player.frozen = false
	_sign_off()
	plane.queue_free()  # flown off to its owner
	plane = null
	_after_flight()


## Called when the ferry flight gets the plane airborne.
func _sign_off() -> void:
	var job: Dictionary = current_job
	money += job.reward
	rescued += 1
	jobs.erase(job)
	current_job = null
	_say("The %s is back in the air! Owner paid $%d." % [job.type, job.reward])
	while jobs.size() < MAX_JOBS:
		_spawn_job()


func _after_flight() -> void:
	if rescued >= GOAL:
		_open_panel("You rescued %d planes!" % GOAL, [["Nice flying.", "Play again", _restart, true]], false)
	else:
		_open_travel()


func _can_finish_here() -> bool:
	if current_job == null:
		return false
	var need := 0
	for id in current_job.faults:
		var f: Dictionary = FAULTS[id]
		if not current_job.fixed.has(id) and f.part != "" and inventory.get(f.part, 0) == 0:
			need += _price(id)
	return money >= need


func _restart() -> void:
	get_tree().reload_current_scene()


# ---------- per-frame + input ----------

func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "interact": [KEY_E],
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
	_update_hud()
	_animate_birds()
	if msg_time > 0.0:
		msg_time -= delta
		if msg_time <= 0.0:
			msg.text = ""
	if ferry:
		return  # the ferry flight drives its own prompt
	prompt.text = ""
	if panel:
		return
	var t: Object = player.target()
	var kind: String = t.get_meta("kind") if t and t.has_meta("kind") else ""
	if kind == "zone" and current_job == null:
		kind = ""
	match kind:
		"zone":
			var z: String = t.get_meta("zone")
			prompt.text = ("E: Work order  (%s checked)" if current_job.checked.has(z) else "E: Inspect %s") % ZONES[z].name
		"shop": prompt.text = "E: Parts shed"
		"radio": prompt.text = "E: Radio - rescue calls"
		"toolbox": prompt.text = "E: Toolbox"
	if kind != "" and Input.is_action_just_pressed("interact") and close_frame != Engine.get_process_frames():
		match kind:
			"zone": _inspect_zone(t.get_meta("zone"))
			"shop": _open_shop()
			"radio": _open_travel()
			"toolbox": _open_toolbox()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") and panel and panel_closable:  # E toggles panels shut too
		_close_panel()
		close_frame = Engine.get_process_frames()
		return
	if e.is_action_pressed("ui_cancel"):
		if panel:
			if panel_closable:
				_close_panel()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e is InputEventMouseButton and e.pressed and not panel:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ---------- 2D UI ----------

func _setup_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	hud = _label(20, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	hud.offset_left = 16
	hud.offset_top = 12
	_label(26, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER).text = "+"
	prompt = _label(22, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_BOTTOM)
	prompt.offset_bottom = -120
	msg = _label(22, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_TOP)
	msg.offset_top = 70


func _label(size: int, h: HorizontalAlignment, v: VerticalAlignment) -> Label:
	var l := Label.new()
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = h
	l.vertical_alignment = v
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(l)
	return l


func _update_hud() -> void:
	var inv: PackedStringArray = []
	for k in inventory:
		if inventory[k] > 0:
			inv.append("%s x%d" % [k, inventory[k]])
	var due := ""
	if current_job:
		due = "    Owner waits %d more day(s)" % maxi(0, ceili(current_job.deadline - day))
	hud.text = "$%d    Day %d    Rescued %d/%d    %s%s\nParts: %s    Tool roll: %d of %d tools" % [money, floori(day), rescued, GOAL, location, due,
		", ".join(inv) if inv.size() > 0 else "none", tools.size(), Work.TOOLS.size() - 1]


func _say(text: String) -> void:
	msg.text = text
	msg_time = 5.0


## Vintage tool-catalog look: dark ink on paper, toolbox-red buttons.
func _catalog_theme() -> Theme:
	var t := Theme.new()
	var ink := Color(0.2, 0.13, 0.08)
	t.set_color("font_color", "Label", ink)
	var states := {"normal": Color(0.7, 0.13, 0.1), "hover": Color(0.82, 0.2, 0.14),
		"pressed": Color(0.5, 0.08, 0.06), "disabled": Color(0.55, 0.5, 0.45, 0.6)}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = states[state]
		sb.set_corner_radius_all(3)
		sb.set_content_margin_all(6)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		t.set_stylebox(state, "Button", sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		t.set_color(c, "Button", Color(0.98, 0.94, 0.85))
	t.set_color("font_disabled_color", "Button", Color(0.95, 0.92, 0.85, 0.7))
	return t


## rows: [text] or [text, button_text, callable, enabled] with an optional 5th icon texture name.
## Docked left so the plane stays visible. Returns the content box so callers can add more.
func _open_panel(title: String, rows: Array, closable := true, paper := "paper_catalog", stamp := "") -> VBoxContainer:
	_close_panel()
	panel_closable = closable
	panel = Control.new()
	panel.position = Vector2(20, 70)
	panel.theme = _catalog_theme()
	var box_ := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://textures/%s.png" % paper)
	sb.set_content_margin_all(28)
	box_.add_theme_stylebox_override("panel", sb)
	panel.add_child(box_)
	var scroll := ScrollContainer.new()  # long lists scroll instead of running off screen
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box_.add_child(scroll)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)
	vb.minimum_size_changed.connect(func():
		var want := vb.get_combined_minimum_size()
		scroll.custom_minimum_size = Vector2(want.x, minf(want.y, 590)))
	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 26)
	vb.add_child(head)
	for r in rows:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		vb.add_child(hb)
		if r.size() > 4 and r[4] != "":
			var icon := TextureRect.new()
			icon.texture = load("res://textures/%s.png" % r[4])
			icon.custom_minimum_size = Vector2(36, 36)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb.add_child(icon)
		var l := Label.new()
		l.text = r[0]
		l.custom_minimum_size.x = 420
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(l)
		if r.size() > 1 and r[1] != "":
			var b := Button.new()
			b.text = r[1]
			b.pressed.connect(r[2])
			b.disabled = not r[3]
			hb.add_child(b)
	if closable:
		var c := Button.new()
		c.text = "Close (Esc)"
		c.pressed.connect(_close_panel)
		vb.add_child(c)
	if stamp != "":
		var s := TextureRect.new()
		s.texture = load("res://textures/%s.png" % stamp)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # must come before size, or size snaps to the image
		s.size = Vector2(170, 85)
		s.rotation = -0.15
		box_.resized.connect(func(): s.position = Vector2(box_.size.x - 130, -30))  # overhang the top-right corner
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(s)
	ui.add_child(panel)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true
	return vb


func _close_panel() -> void:
	if panel:
		panel.queue_free()
		panel = null
	player.frozen = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## The work order: what the owner reported, which spots you've checked, and what you found.
func _open_inspection() -> void:
	var job: Dictionary = current_job
	var rows := [["Owner reports: " + _symptoms(job)],
		["Walk-around: %d of %d spots checked" % [job.checked.size(), ZONES.size()]]]
	for id in job.faults:
		if not job.found.has(id):
			continue
		var f: Dictionary = FAULTS[id]
		var icon: String = "icon_" + id if ResourceLoader.exists("res://textures/icon_%s.png" % id) else ""
		if job.fixed.has(id):
			rows.append(["OK  -  " + f.name, "", null, false, icon])
		elif f.part == "":
			rows.append(["%s\nNo part needed" % f.name, "Work on it", func(): _repair(id), true, icon])
		else:
			var have: int = inventory.get(f.part, 0)
			rows.append(["%s\nNeeds %s (have %d)" % [f.name, f.part, have],
				"Work on it", func(): _repair(id), true, icon])
	var all_checked: bool = job.checked.size() == ZONES.size()
	var done: bool = all_checked and job.fixed.size() == job.faults.size()
	if done:
		rows.append(["Airworthy! Fly it out to the owner.", "Climb in & take off (+$%d)" % job.reward, _start_ferry, true])
	elif not all_checked:
		rows.append(["Check every spot before you sign it off."])
	_open_panel("Work order: " + job.type, rows, true, "paper_catalog",
		"stamp_airworthy" if done else ("stamp_inspected" if all_checked else ""))


## Each town's shed stocks only some parts (fixed per town); the rest come by mail, slower and dearer.
func _stocked(part_id: String) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(location + part_id)
	return r.randf() < 0.6


## What this town's shed charges for a fault's part: shelf price, or +25% by mail.
func _price(id: String) -> int:
	return FAULTS[id].cost if _stocked(id) else int(FAULTS[id].cost * 1.25)


## The hangar toolbox: take tools into your roll (they travel with you) or put them back.
func _open_toolbox() -> void:
	var rows := []
	for t in Work.TOOLS:
		if t == "hand":
			continue
		var have := tools.has(t)
		rows.append(["%s%s" % [Work.TOOLS[t], "   (in your roll)" if have else ""], "Put back" if have else "Take",
			func(): _take_tool(t, not have), true, "work/tool_" + t if ResourceLoader.exists("res://textures/work/tool_%s.png" % t) else ""])
	rows.append(["", "Take everything", func(): _take_tool("", true), tools.size() < Work.TOOLS.size() - 1])
	_open_panel("Toolbox", rows)


## t "" = every tool.
func _take_tool(t: String, take: bool) -> void:
	for k in (Work.TOOLS.keys() if t == "" else [t]):
		if k == "hand":
			continue
		if take:
			tools[k] = true
		else:
			tools.erase(k)
	_open_toolbox()


func _open_shop() -> void:
	var needed := {}
	if current_job:
		for id in current_job.found:
			if not current_job.fixed.has(id):
				needed[FAULTS[id].part] = true
	var rows := []
	for id in FAULTS:
		var f: Dictionary = FAULTS[id]
		if f.part == "":
			continue
		var tag := "   << NEEDED" if needed.has(f.part) else ""
		var icon: String = "icon_" + id if ResourceLoader.exists("res://textures/icon_%s.png" % id) else ""
		var price := _price(id)
		if _stocked(id):
			rows.append(["%s (have %d)%s" % [f.part, inventory.get(f.part, 0), tag],
				"$%d" % price, func(): _buy(f.part, price), money >= price, icon])
		else:
			rows.append(["%s (have %d)%s\nNot in stock: mail order, 1 day" % [f.part, inventory.get(f.part, 0), tag],
				"Order $%d" % price, func(): _buy(f.part, price, true), money >= price, icon])
	_open_panel("Parts & Supply  -  " + location, rows)


func _open_travel() -> void:
	var rows := []
	var can_fly := false
	for job in jobs:
		if job == current_job:
			continue
		var cost := int(miles(location, job.city) * FUEL_PER_MILE)
		can_fly = can_fly or money >= cost
		var trip := miles(location, job.city) / 700.0
		rows.append(["%s: %s, pays $%d. %d mi, %.1f days, owner waits %d\n%s" % [job.city, job.type, job.reward,
			int(miles(location, job.city)), trip, maxi(0, ceili(job.deadline - day)), _symptoms(job)],
			"Fly ($%d)" % cost, func(): _travel(job, cost), money >= cost])
	if not can_fly and not _can_finish_here():
		_open_panel("Out of money and grounded. Game over.",
			[["You rescued %d planes." % rescued, "Play again", _restart, true]], false)
		return
	var vb := _open_panel("Rescue calls", rows)
	# Sectional-style nav chart: graticule, airport symbols, compass rose on your field and a
	# magenta course line (true course + nautical miles) to each call. Click a field to fly.
	var map := TextureRect.new()
	map.texture = load("res://textures/us_map.png")
	map.custom_minimum_size = Vector2(576, 360)
	map.mouse_filter = Control.MOUSE_FILTER_PASS  # let the wheel scroll the panel
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_SCALE
	map.modulate = Color(0.93, 1.0, 0.93)  # pale green cast of a sectional chart
	vb.add_child(map)
	vb.move_child(map, 1)
	var calls := jobs.filter(func(j): return j != current_job)
	map.draw.connect(func(): _draw_chart(map, calls))
	for job in calls:
		var cost := int(miles(location, job.city) * FUEL_PER_MILE)
		var pin := Button.new()
		pin.flat = true
		pin.text = job.city.to_upper()
		pin.add_theme_font_size_override("font_size", 11)
		pin.add_theme_color_override("font_color", CHART_MAGENTA)
		pin.add_theme_color_override("font_hover_color", Color(0.9, 0.1, 0.5))
		pin.position = _chart_px(job.city) + Vector2(6, -24)
		pin.disabled = money < cost
		pin.tooltip_text = "Fly to %s ($%d fuel)" % [job.city, cost]
		pin.pressed.connect(func(): _travel(job, cost))
		map.add_child(pin)


const CHART_MAGENTA := Color(0.62, 0.12, 0.45)
const CHART_BLUE := Color(0.16, 0.3, 0.55)
const CHART_K := 576.0 / 2048.0
# Quadratic fit lon/lat -> us_map.png pixels (same fit the CITIES pixels came from), for gridlines.
const MAP_X := [5046.137508, 44.595404, -25.016715, 0.038367, 0.056775, -0.215379]
const MAP_Y := [917.976027, -28.316197, -46.63631, -0.143734, 0.114237, 0.012057]


func _chart_px(city: String) -> Vector2:
	var c: Array = CITIES[city]
	return Vector2(c[3], c[4]) * CHART_K


func _lonlat_px(lon: float, lat: float) -> Vector2:
	var v := [1.0, lon, lat, lon * lon, lat * lat, lon * lat]
	var p := Vector2.ZERO
	for i in 6:
		p += Vector2(MAP_X[i], MAP_Y[i]) * v[i]
	return p * CHART_K


## Initial great-circle true course from a to b, degrees 0..360.
func course(a: String, b: String) -> float:
	var r := PI / 180.0
	var p: Array = CITIES[a]
	var q: Array = CITIES[b]
	var dl: float = (q[0] - p[0]) * r
	var y := sin(dl) * cos(q[1] * r)
	var x: float = cos(p[1] * r) * sin(q[1] * r) - sin(p[1] * r) * cos(q[1] * r) * cos(dl)
	return fposmod(rad_to_deg(atan2(y, x)), 360.0)


func _draw_chart(map: Control, calls: Array) -> void:
	var font := ThemeDB.fallback_font
	var grid := Color(CHART_BLUE, 0.35)
	for lon in range(-125, -64, 5):  # meridians
		var pts := PackedVector2Array()
		for lat in range(24, 51):
			pts.append(_lonlat_px(lon, lat))
		map.draw_polyline(pts, grid, 1.0)
		map.draw_string(font, _lonlat_px(lon, 24.5) + Vector2(2, -2), "%d°W" % -lon, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, grid)
	for lat in range(25, 51, 5):  # parallels
		var pts := PackedVector2Array()
		for lon in range(-126, -65):
			pts.append(_lonlat_px(lon, lat))
		map.draw_polyline(pts, grid, 1.0)
		map.draw_string(font, _lonlat_px(-125.5, lat) + Vector2(2, -2), "%d°N" % lat, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, grid)
	# every known field as a small non-towered airport symbol
	for city in CITIES:
		var p := _chart_px(city)
		map.draw_arc(p, 3.5, 0, TAU, 12, Color(CHART_MAGENTA, 0.55), 1.2)
	var home := _chart_px(location)
	# compass rose around your field, 10° ticks, longer every 30°, N up (true)
	var rose := 34.0
	map.draw_arc(home, rose, 0, TAU, 48, CHART_BLUE, 1.2)
	for d in range(0, 360, 10):
		var a := deg_to_rad(d - 90.0)
		var tick := 7.0 if d % 30 == 0 else 3.5
		map.draw_line(home + Vector2(cos(a), sin(a)) * (rose - tick), home + Vector2(cos(a), sin(a)) * rose, CHART_BLUE, 1.0)
	map.draw_string(font, home + Vector2(-4, -rose - 3), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CHART_BLUE)
	# course lines with true course / distance boxed at the midpoint
	for job in calls:
		var to := _chart_px(job.city)
		map.draw_dashed_line(home, to, CHART_MAGENTA, 2.0, 8.0)
		var tag := "%03d°  %d NM" % [roundi(course(location, job.city)), roundi(miles(location, job.city) * 0.869)]
		var mid := home.lerp(to, clampf((rose + 45.0) / maxf(home.distance_to(to), 1.0), 0.5, 0.8))  # clear of the rose
		var sz := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		map.draw_rect(Rect2(mid - Vector2(sz.x / 2 + 3, 10), sz + Vector2(6, 4)), Color(1, 1, 0.94, 0.9))
		map.draw_rect(Rect2(mid - Vector2(sz.x / 2 + 3, 10), sz + Vector2(6, 4)), CHART_MAGENTA, false, 1.0)
		map.draw_string(font, mid - Vector2(sz.x / 2, -1), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, CHART_MAGENTA)
		_draw_airport(map, to, CHART_MAGENTA)
	_draw_airport(map, home, Color(0.1, 0.45, 0.2))
	var hw := font.get_string_size(location.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	map.draw_string(font, home + Vector2(-hw / 2, rose + 13), location.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.1, 0.45, 0.2))


## Sectional airport symbol: ring with four ticks and a runway bar.
func _draw_airport(map: Control, p: Vector2, c: Color) -> void:
	map.draw_circle(p, 5.5, Color(1, 1, 0.94))
	map.draw_arc(p, 5.5, 0, TAU, 16, c, 2.0)
	for a in [0.0, PI / 2, PI, PI * 1.5]:
		map.draw_line(p + Vector2(cos(a), sin(a)) * 5.5, p + Vector2(cos(a), sin(a)) * 8.5, c, 2.0)
	map.draw_line(p + Vector2(-3, 2), p + Vector2(3, -2), c, 2.0)


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
	env.fog_density = 0.003
	env.fog_light_color = Color(0.92, 0.8, 0.62)  # warm haze
	env.fog_sky_affect = 0.15  # keep the golden panorama visible
	# Warm sun vs cool shadows: the ambient fill that lights shadowed sides is pulled toward blue.
	env.ambient_light_color = Color(0.55, 0.65, 0.85)
	env.ambient_light_sky_contribution = 0.6
	env.glow_enabled = true  # gentle bloom on bright sky and sunlit paint only
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true  # grounds wheels, props and trees
	env.ssao_intensity = 1.5
	# Grade: a touch of teal in the darks, warm highlights (each channel looks up its own curve).
	var grade := Gradient.new()
	grade.set_color(0, Color(0.0, 0.02, 0.04))
	grade.set_color(1, Color(1.0, 0.97, 0.9))
	grade.add_point(0.3, Color(0.27, 0.3, 0.32))
	grade.add_point(0.75, Color(0.79, 0.75, 0.7))
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
	p.amount = 60
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
	q.size = Vector2.ONE * (0.05 if region_name == "snow" else 0.02)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.8) if region_name == "snow" else Color(1.0, 0.92, 0.7, 0.55)
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
	flock.position = Vector3(r_bird.randf_range(-40, 40), 38, r_bird.randf_range(-60, 20))
	world.add_child(flock)
	var c := Color(0.12, 0.1, 0.1)
	for i in 7:
		var b := Node3D.new()
		b.position = Vector3(55 + r_bird.randf_range(-6, 6), r_bird.randf_range(-3, 3), i * 2.2 - 7)
		for s in [-1, 1]:
			var wing := box(b, Vector3(0.55, 0.03, 0.18), Vector3(s * 0.27, 0, 0), c)
			wing.set_meta("side", s)
		box(b, Vector3(0.1, 0.08, 0.35), Vector3.ZERO, c)
		b.set_meta("phase", r_bird.randf() * TAU)
		flock.add_child(b)


var r_bird := RandomNumberGenerator.new()
var motes: GPUParticles3D
var flock: Node3D  # the current field's birds (freed with the world)


func _animate_birds() -> void:
	if not is_instance_valid(flock):
		return
	var t := Time.get_ticks_msec() / 1000.0
	flock.rotation.y = -t * 0.08  # ~80 s per lap
	for b in flock.get_children():
		var ph: float = b.get_meta("phase")
		var flap := sin(t * 9.0 + ph) * 0.6 * float(sin(t * 0.7 + ph) > 0.2)  # bursts of flapping
		for w in b.get_children():
			if w.has_meta("side"):
				w.rotation.z = flap * w.get_meta("side")
				w.position.x = cos(flap) * 0.27 * w.get_meta("side")
				w.position.y = sin(flap) * 0.27


## Each region gets its own light: golden plains, hot hazy desert, green-tinged forest, cold snow.
const REGION_LIGHT := {
	"plains": {"sun": Color(1.0, 0.85, 0.65), "fog": Color(0.92, 0.8, 0.62), "elev": -20.0, "haze": 0.003},
	"desert": {"sun": Color(1.0, 0.8, 0.55), "fog": Color(0.96, 0.76, 0.55), "elev": -30.0, "haze": 0.0045},
	"forest": {"sun": Color(1.0, 0.9, 0.75), "fog": Color(0.72, 0.8, 0.7), "elev": -18.0, "haze": 0.004},
	"snow": {"sun": Color(0.95, 0.93, 0.92), "fog": Color(0.86, 0.88, 0.93), "elev": -14.0, "haze": 0.0035},
}


func _apply_light(region_name: String) -> void:
	var l: Dictionary = REGION_LIGHT[region_name]
	sun.light_color = l.sun
	sun.rotation_degrees = Vector3(l.elev, 30, 0)
	env.fog_light_color = l.fog
	env.fog_density = l.haze


func _load_field(city: String, job) -> void:
	location = city
	current_job = job
	if world:
		world.queue_free()
	world = Node3D.new()
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
	box(world, Vector3(160, 0.04, 12), Vector3(0, 0.02, 20), tmat("runway_asphalt", Color.WHITE, 0.15))
	for x in range(-76, 80, 10):
		box(world, Vector3(5, 0.05, 0.4), Vector3(x, 0.03, 20), Color(0.95, 0.95, 0.9))
	box(world, Vector3(18, 0.03, 13), Vector3(0, 0.015, 7.5), tmat("gravel", Color.WHITE, 0.4))  # apron
	_build_hangar(Vector3(-16, 0, -14), r)
	_build_shed(Vector3(14, 0, -8))
	_build_sign(Vector3(9, 0, 4), city)
	prop("fuel_truck", Vector3(-8, 0, -1), 7.0, null, PI / 2)  # parked by the hangar, cab toward the runway
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
	player.velocity = Vector3.ZERO
	player.position = Vector3(4, 0.1, -2)
	player.rotation = Vector3(0, PI, 0)
	player.cam.rotation = Vector3.ZERO


func _build_hangar(at: Vector3, r: RandomNumberGenerator) -> void:
	# Quonset-hut model: open end faces +Z (the runway). Longest side is its depth;
	# 15.8 m deep makes it 14 m wide and 7 m tall. Back wall sits near at.z - 7.2.
	prop("hangar", at, 15.8, null, 0.0, "mesh")
	const BACK := -7.0
	box(world, Vector3(5, 2.4, 0.05), at + Vector3(-1.5, 2.0, BACK + 0.1), tmat("pegboard", Color.WHITE, 0.5))
	prop("toolbox", at + Vector3(-4.5, 0, BACK + 0.6), 1.1, tmat("toolbox_red", Color.WHITE, 1.5))  # drawers face +Z
	interactable(world, at + Vector3(-4.5, 0.6, BACK + 1.0), Vector3(1.4, 1.2, 1.2), "toolbox")
	_text3d("TOOLS", at + Vector3(-4.5, 1.6, BACK + 0.6), 40)
	decal(world, Vector2(0.5, 0.5), at + Vector3(-4.03, 0.75, BACK + 0.6), "sticker_sheet", Vector3.RIGHT)
	var drum_paint := [Color(0.45, 0.6, 0.85), Color(0.8, 0.35, 0.3), Color(0.5, 0.6, 0.45)]
	for p in [Vector3(8.3, 0, -4), Vector3(9.0, 0, -3.2), Vector3(8.4, 0, -2.4), Vector3(-5.0, 0, 3)]:
		prop("barrel_a", at + p, 0.9, tmat("galvanized_metal", drum_paint[r.randi() % 3], 2.0), r.randf() * TAU)
	for p in [Vector3(-8.7, 0, 4), Vector3(-8.8, 0, 5.2)]:
		prop("crate_a", at + p, 1.0, tmat("wood_planks", Color(0.9, 0.8, 0.65), 1.5), r.randf_range(-0.3, 0.3))
	box(world, Vector3(2, 1, 0.8), at + Vector3(3, 0.5, BACK + 0.6), tmat("workbench_top", Color.WHITE, 0.6), true)  # desk
	box(world, Vector3(0.7, 0.4, 0.4), at + Vector3(3, 1.2, BACK + 0.6), Color(0.15, 0.22, 0.15))  # radio
	interactable(world, at + Vector3(3, 1.2, BACK + 0.9), Vector3(1.4, 0.9, 1.2), "radio")
	_text3d("RADIO", at + Vector3(3, 2.2, BACK + 0.6), 48)


func _build_shed(at: Vector3) -> void:
	# Parts-counter model: open stocked counter faces +Z, "AIRCRAFT PARTS" painted on the +X side.
	# 5.4 m wide -> about 2.8 m deep and 3.7 m tall.
	prop("parts_shed", at, 5.4, null, 0.0, "mesh")
	interactable(world, at + Vector3(0, 1.2, 1.1), Vector3(4.6, 1.6, 1.2), "shop")
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
	while placed < region.count + rows.size():
		var pos: Vector3
		if placed < rows.size():
			pos = rows[placed]
			placed += 1
			if terrain.in_water(pos.x, pos.z):
				continue
		else:
			pos = Vector3(r.randf_range(-400, 400), 0, r.randf_range(-400, 400))
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
			"pine":  # shortcut: code-built cones until a plain (snowless) pine model exists
				cones.append(Transform3D(Basis.from_scale(Vector3.ONE * h), pos))
				_trunk(pos)
			"snowpine":
				var pine := prop("tree_pine_snow_a", pos, r.randf_range(6.0, 11.0), null, r.randf() * TAU, "trunk")
				pine.set_meta("tree", true)
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
		var cone := CylinderMesh.new()
		cone.top_radius = 0
		cone.bottom_radius = 0.3
		cone.height = 1.5
		cone.radial_segments = 6
		cone.material = tmat("foliage", Color(0.55, 0.7, 0.6))
		_multi(trunk, cones.map(func(t): return t.translated_local(Vector3(0, 0.6 / 4.5, 0))))
		_multi(cone, cones.map(func(t): return t.translated_local(Vector3(0, 0.75 + 1.0 / 4.5, 0))))
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
	plane.rotation = Vector3(SIT_PITCH, PI / 2, 0)  # nose down the runway (-X), resting back on the tailwheel
	plane.position = Vector3(0, MAIN_Z * sin(SIT_PITCH), 8)  # keeps the main tires on the ground
	world.add_child(plane)
	# FlightGear J-3 Cub (GPL, real scale: 10.65 m span). Model faces -X with wings along Z;
	# turned so the nose is -Z. Plane origin = between the main tires on the ground.
	# Probed parts (plane space): tyres x=±0.9 z=0, nose z=-1.33, cowl z -1.16..-0.69,
	# windshield y 1.37..1.96 z -0.53..0.09, wing y≈1.95, rudder hinge z=4.44, tailwheel z=5.2.
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
	for z in ZONES:
		interactable(plane, ZONES[z].pos, ZONES[z].size, "zone").set_meta("zone", z)


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
		"brakes":  # disc on the outboard hub so it shows on the walk-around
			model(n, "brakes_ok" if ok else "brakes_broken", Vector3(1.04, 0.25, 0), 0.22, axle_x)
		"battery":  # access hatch on the right side of the turtle deck
			var hatch := box(n, Vector3(0.03, 0.35, 0.5), Vector3(0.36, 1.45, 1.7), tmat("plane_body_worn", Color(0.95, 0.8, 0.3)))
			if not ok:  # hatch hanging open, corroded battery pulled half out
				hatch.position = Vector3(0.55, 1.45, 1.98)
				hatch.rotation.y = -1.2
				model(n, "battery_broken", Vector3(0.45, 1.45, 1.7), 0.35)
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
		"starter":
			model(n, "starter_ok", Vector3(-0.42, 1.0, -0.85), 0.3, Vector3.ZERO,
				null if ok else tmat("metal_rust", Color.WHITE, 3.0))
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

func mat(c) -> Material:  # c: Color, or an already-built Material
	if c is Material:
		return c
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


## Textured material from textures/<tex>.png. Triplanar mapping, so no mesh UVs needed;
## scale = repeats per meter. Tint multiplies the texture.
func tmat(tex: String, tint := Color.WHITE, scale := 0.5) -> StandardMaterial3D:
	var m: StandardMaterial3D = mat(tint)
	m.albedo_texture = load("res://textures/%s.png" % tex)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
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
				mi.create_trimesh_collision()
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


# ---------- self-test: godot --path . -- --self-test [--shot=prefix] [--all-faults] ----------

func _self_test(args: PackedStringArray) -> void:
	var shot := ""
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	var edges_ok := _edge_tests()
	var job: Dictionary = jobs[0]
	if "--all-faults" in args:  # every broken part on one plane, for screenshots
		job.faults = FAULTS.keys()
	for a in args:
		if a.begins_with("--city="):  # pick the field, e.g. a plains town to see trees
			job.city = a.trim_prefix("--city=")
	var start := money
	job.deadline = day + 30  # don't let a long test trip expire the job
	_travel(job, 0)
	await _snap(shot, "broken", 1.5)
	if shot != "":  # wheels close up, while any flat tire is still flat
		for v in [["gear", Vector3(2.2, 0.1, 4.6), Vector3(0, 0, 7.1)], ["gear_l", Vector3(2.2, 0.1, 11.4), Vector3(0, 0, 8.9)],
				["gear_front", Vector3(-7.5, 0.1, 8.6), Vector3(0, 0, 8)], ["tail", Vector3(8.5, 0.1, 5.0), Vector3(5, 0, 8)],
				["side", Vector3(1.5, 0.1, 1.0), Vector3(1.5, 0, 8)]]:
			player.position = v[1]
			player.look_at(Vector3(v[2].x, player.position.y, v[2].z), Vector3.UP)
			player.cam.rotation.x = -0.35
			await _snap(shot, v[0])
		_load_field(location, job)
	_open_travel()
	await _snap(shot, "radio")
	var first_zone: String = FAULTS[job.faults[0]].zone
	_inspect_zone(first_zone)  # one spot: the work order shows only what that spot revealed
	await _snap(shot, "inspect")
	var ok: bool = job.found.size() < job.faults.size() or job.faults.all(func(id): return FAULTS[id].zone == first_zone)
	for z in ZONES:
		_inspect_zone(z)
	ok = ok and job.found.size() == job.faults.size() and job.checked.size() == ZONES.size()
	_open_shop()
	await _snap(shot, "shop")
	# Work scenes: with no tools nothing comes apart; with tools but no part it stalls at the
	# empty slot; with both, the whole job gets done bolt by bolt.
	var id0: String = job.faults[0]
	tools.clear()
	_repair(id0)
	ok = ok and panel is Work
	await _snap(shot, "work_" + id0)
	ok = ok and not panel.solve() and not job.fixed.has(id0)
	for t in Work.TOOLS:
		if t != "hand":
			tools[t] = true
	# Mouse path: hover the first screw/bolt, hold the button with its tool, let go.
	# Fed to the scene directly so the real cursor (windowed runs) can't interfere.
	var w = panel
	var f0: Dictionary = w.els.filter(func(e): return e.type == "fastener" and w.action(e).verb == "loosen")[0]
	w.tool = f0.tool
	var mv := InputEventMouseMotion.new()
	mv.position = w._origin() + f0.pos
	w._gui_input(mv)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = mv.position
	press.pressed = true
	w._gui_input(press)
	await get_tree().create_timer(1.2).timeout
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	w._gui_input(release)
	ok = ok and w.st[f0.id] == "loose"
	if w.st[f0.id] != "loose":
		print("MOUSE HOLD did not loosen ", f0.id, ": ", w.st[f0.id], " hover=", w.hover)
	if FAULTS[id0].part != "":
		inventory.erase(FAULTS[id0].part)
		ok = ok and not panel.solve() and not job.fixed.has(id0)
		await _snap(shot, "work_apart")
	for id in job.faults:
		var part: String = FAULTS[id].part
		if part != "":
			inventory[part] = 1
		if id != id0:
			_repair(id)
			await _snap(shot, "work_" + id, 0.1)
		var solved: bool = panel.solve()
		ok = ok and solved and job.fixed.has(id)
		if not solved:
			print("WORK STUCK on ", id)
	await _snap(shot, "airworthy")
	_close_panel()
	await _snap(shot, "fixed")
	if shot != "":  # extra viewpoints of the hangar and the parts shed
		for v in [["hangar_out", Vector3(-10, 0.1, 4), Vector3(-16, 0, -14)], ["hangar", Vector3(-14, 0.1, -12), Vector3(-19, 0, -20)],
				["drums", Vector3(-3.5, 0.1, -13), Vector3(-7.5, 0, -17)], ["shed", Vector3(18, 0.1, -1), Vector3(14, 0, -8)],
				["truck", Vector3(-1, 0.1, 4), Vector3(-8, 0, -1)],				["trees", Vector3(-20, 0.1, -25), Vector3(-60, 0, -60)],
			["vista_n", Vector3(0, 0.1, -28), Vector3(0, 0, -300)], ["vista_e", Vector3(100, 0.1, 25), Vector3(400, 0, 60)],
			["vista_w", Vector3(-100, 0.1, 10), Vector3(-400, 0, -40)]]:
			player.position = v[1]
			player.look_at(Vector3(v[2].x, player.position.y, v[2].z), Vector3.UP)
			player.cam.rotation.x = 0.02 if v[0].begins_with("vista") else -0.35
			if v[0] == "vista_n":
				await get_tree().create_timer(2.0).timeout
				print("FPS at vista: ", Engine.get_frames_per_second())
			await _snap(shot, v[0])
		if flock:  # look up at the birds
			var bird: Vector3 = flock.get_child(0).global_position
			player.position = Vector3(bird.x + 25, 0.1, bird.z + 25)
			player.look_at(Vector3(bird.x, player.position.y, bird.z), Vector3.UP)
			player.cam.rotation.x = atan2(bird.y - 1.7, Vector2(25, 25).length())
			await _snap(shot, "birds")
		if terrain.pond != Vector3.INF:
			var pd: Vector3 = terrain.pond
			player.position = Vector3(pd.x + pd.z + 6, terrain.height(pd.x + pd.z + 6, pd.y) + 0.2, pd.y)
			player.look_at(Vector3(pd.x, player.position.y, pd.y), Vector3.UP)
			player.cam.rotation.x = -0.2
			await _snap(shot, "pond")
		var trees := world.get_children().filter(func(n): return n.has_meta("tree"))
		for i in mini(3, trees.size()):  # close-ups to check the bark/leaf split
			var spot: Vector3 = trees[i].position
			player.position = Vector3(spot.x + 9, terrain.height(spot.x + 9, spot.z + 9) + 0.2, spot.z + 9)
			player.look_at(Vector3(spot.x, player.position.y, spot.z), Vector3.UP)
			player.cam.rotation.x = 0.15
			await _snap(shot, "tree%d" % i)
		_load_field(location, job)  # put the player back by the plane
	ok = ok and job.fixed.size() == job.faults.size()
	# Fly it out for real: hold throttle, pull back once past rotate speed.
	_start_ferry()
	Input.action_press("move_forward")
	await _snap(shot, "cockpit", 1.0)
	var t0 := Time.get_ticks_msec()
	while ferry and Time.get_ticks_msec() - t0 < 30000:
		if ferry.speed >= Ferry.ROTATE:
			Input.action_press("move_back")
		if shot != "" and ferry.alt > 8 and not FileAccess.file_exists(shot + "_climb.png"):
			await _snap(shot, "climb", 0.0)
		await get_tree().process_frame
	Input.action_release("move_forward")
	Input.action_release("move_back")
	ok = ok and ferry == null and rescued == 1 and money == start + job.reward and jobs.size() == MAX_JOBS
	print("SELF-TEST ", "PASS" if ok and edges_ok else "FAIL", " edges=", edges_ok, " faults=", job.faults, " day=%.1f" % day)
	get_tree().quit(0 if ok else 1)


## Money and deadline edges, run at home before the main test; restores what it touches.
func _edge_tests() -> bool:
	var saved := [money, jobs, current_job, day]
	var fake := func(id: String, deadline: float) -> Dictionary:
		return {"city": location, "type": "Test", "faults": [id], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0, "deadline": deadline}
	var ok := true
	# 1. Broke, no flight, the needed part is mail-order only: shelf price is affordable but the
	#    real price isn't, so it must be game over rather than a dead end.
	var mail_only := FAULTS.keys().filter(func(id): return FAULTS[id].part != "" and not _stocked(id))
	if mail_only.size() > 0:
		var id: String = mail_only[0]
		jobs = []
		current_job = fake.call(id, day + 30)
		money = FAULTS[id].cost
		_open_travel()
		ok = ok and panel != null and not panel_closable  # the game-over panel can't be closed
		_close_panel()
	# 2. The owner's deadline passes during an inspection: the job is dropped cleanly.
	jobs = [fake.call("tire", day + 0.01)]
	current_job = jobs[0]
	_inspect_zone("gear_l")
	ok = ok and current_job == null and panel == null  # before the fix this line ran after a script error
	money = saved[0]
	jobs = saved[1]
	current_job = saved[2]
	day = saved[3]
	return ok


func _snap(prefix: String, name: String, wait := 0.4) -> void:
	if prefix == "":
		return
	await get_tree().create_timer(wait).timeout
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [prefix, name])

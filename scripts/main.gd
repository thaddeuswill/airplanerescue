extends Node3D
## Airplane Rescue: walk up to stranded planes, inspect them in a 2D panel,
## fix each fault (the 3D model updates), then sign off and fly to the next call.
## The plane and repair parts are .glb models from models/ (made by tools/optimize_models.py);
## buildings and nature are still primitives built in code. Art direction: ART_DIRECTION.md.

const Player := preload("res://scripts/player.gd")
const Ferry := preload("res://scripts/ferry.gd")
const Sound := preload("res://scripts/sound.gd")
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
	"plains": {"tex": "ground_grass", "ground": Color(0.45, 0.62, 0.3), "prop": "tree", "count": 30, "grass": 6000, "wheat": 3000},
	"forest": {"tex": "ground_forest", "ground": Color(0.28, 0.45, 0.22), "prop": "pine", "count": 110, "grass": 4000, "wheat": 0},
	"desert": {"tex": "dirt_red", "ground": Color(0.82, 0.68, 0.45), "prop": "cactus", "count": 40, "grass": 600, "wheat": 0},
	"snow": {"tex": "ground_snow", "ground": Color(0.92, 0.94, 0.97), "prop": "snowpine", "count": 55, "grass": 0, "wheat": 0},
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
	"prop": {"name": "propeller", "pos": Vector3(0, 1.3, -4.7), "size": Vector3(2.4, 2.4, 0.3)},
	"engine": {"name": "engine", "pos": Vector3(0, 1.2, -3.8), "size": Vector3(1.7, 1.3, 1.4)},
	"cabin": {"name": "cabin & windshield", "pos": Vector3(0, 2.2, -2.3), "size": Vector3(1.7, 1.0, 1.6)},
	"gear_l": {"name": "left main gear", "pos": Vector3(-0.95, 0.45, -2.1), "size": Vector3(0.8, 0.9, 1.0)},
	"gear_r": {"name": "right main gear", "pos": Vector3(0.95, 0.45, -2.1), "size": Vector3(0.8, 0.9, 1.0)},
	"wing_l": {"name": "left wing", "pos": Vector3(-2.6, 2.3, -1.7), "size": Vector3(2.0, 0.7, 1.6)},
	"battery": {"name": "battery bay", "pos": Vector3(0.75, 1.2, 1.0), "size": Vector3(0.4, 0.8, 1.0)},
	"tail": {"name": "tail & rudder", "pos": Vector3(0, 2.4, 4.2), "size": Vector3(1.6, 2.0, 1.4)},
}
const DIFFICULTY := {1: "easy", 2: "fiddly", 3: "tricky"}  # by part cost, see _difficulty()
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
var mg = null  # active repair mini-game state (Dictionary) or null
var ferry: Node = null  # active ferry flight
var sound
var env: Environment
var sun: DirectionalLight3D


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
		"fixed": {}, "found": {}, "checked": {}, "reward": int(round((t[1] + cost * 2.0) / 50.0)) * 50,
		"deadline": day + 7 + rng.randi() % 9, "color": Color.from_hsv(rng.randf(), 0.55, 0.85)})


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
		var found: PackedStringArray = []
		for id in current_job.faults:
			if FAULTS[id].zone == zone:
				current_job.found[id] = true
				found.append(FAULTS[id].name)
		_say(("%s: found %s" % [ZONES[zone].name.capitalize(), ", ".join(found)]) if found.size() > 0
			else "%s: looks good." % ZONES[zone].name.capitalize())
	if current_job:
		_open_inspection()


func _difficulty(id: String) -> int:
	var c: int = FAULTS[id].cost
	return 1 if c < 400 else (2 if c < 1200 else 3)


## Starts the wrench-timing mini-game; _finish_repair applies the result.
func _repair(id: String) -> void:
	var d := _difficulty(id)
	var vb := _open_panel("Repair: " + FAULTS[id].name, [["Stop the needle in the green. %s job%s." % [DIFFICULTY[d].capitalize(),
		", a slip can ruin the part" if d > 1 else ""]]], true, "paper_catalog")
	var bar := ColorRect.new()
	bar.color = Color(0.85, 0.8, 0.7)
	bar.custom_minimum_size = Vector2(440, 34)
	vb.add_child(bar)
	vb.move_child(bar, vb.get_child_count() - 2)  # above the Close button
	var width := 0.34 - d * 0.08
	var zone := ColorRect.new()
	zone.color = Color(0.3, 0.6, 0.3)
	var zl := rng.randf_range(0.05, 0.95 - width)
	zone.position = Vector2(zl * 440, 0)
	zone.size = Vector2(width * 440, 34)
	bar.add_child(zone)
	var needle := ColorRect.new()
	needle.color = Color(0.7, 0.13, 0.1)
	needle.size = Vector2(5, 42)
	needle.position.y = -4
	bar.add_child(needle)
	var b := Button.new()
	b.text = "Tighten! (Space)"
	b.pressed.connect(func(): _finish_repair(id, absf(mg.pos - (zl + width / 2)) <= width / 2))
	vb.add_child(b)
	vb.move_child(b, vb.get_child_count() - 2)  # above Close
	b.grab_focus()
	mg = {"id": id, "pos": 0.0, "dir": 1.0, "speed": 0.55 + d * 0.4, "needle": needle}


func _finish_repair(id: String, hit: bool) -> void:
	mg = null
	var f: Dictionary = FAULTS[id]
	_advance(0.25)
	if not current_job:
		_close_panel()
		return
	if hit:
		if f.part != "":
			inventory[f.part] -= 1
		current_job.fixed[id] = true
		visuals[id].queue_free()
		visuals[id] = _part_visual(id, true)
		sound.clink()
		_say("Fixed: " + f.name)
	elif f.part != "" and rng.randf() < (_difficulty(id) - 1) * 0.15:
		inventory[f.part] -= 1
		_say("The wrench slipped and ruined the %s. You'll need another." % f.part)
	else:
		_say("The wrench slipped. Try again.")
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
	decal(plane, Vector2(1.25, 0.55), Vector3(0, 1.72, -2.25), "cockpit_panel", Vector3.BACK)
	ferry = Ferry.new()
	add_child(ferry)
	ferry.finished.connect(_ferry_done)
	ferry.start(self, plane, visuals["propeller"].get_child(0))
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
			need += f.cost
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
	if msg_time > 0.0:
		msg_time -= delta
		if msg_time <= 0.0:
			msg.text = ""
	if mg:  # repair mini-game needle sweeps back and forth
		mg.pos += mg.dir * mg.speed * delta
		if mg.pos > 1.0 or mg.pos < 0.0:
			mg.dir = -mg.dir
			mg.pos = clampf(mg.pos, 0.0, 1.0)
		mg.needle.position.x = mg.pos * 440 - 2
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
	if kind != "" and Input.is_action_just_pressed("interact") and close_frame != Engine.get_process_frames():
		match kind:
			"zone": _inspect_zone(t.get_meta("zone"))
			"shop": _open_shop()
			"radio": _open_travel()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("interact") and panel and panel_closable:  # E toggles panels shut too
		mg = null
		_close_panel()
		close_frame = Engine.get_process_frames()
		return
	if e.is_action_pressed("ui_cancel"):
		mg = null
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
	hud.text = "$%d    Day %d    Rescued %d/%d    %s%s\nToolbox: %s" % [money, floori(day), rescued, GOAL, location, due,
		", ".join(inv) if inv.size() > 0 else "empty"]


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
			rows.append(["%s\nNo part needed" % f.name, "Repair", func(): _repair(id), true, icon])
		else:
			var have: int = inventory.get(f.part, 0)
			rows.append(["%s\nNeeds %s (have %d)" % [f.name, f.part, have],
				"Repair", func(): _repair(id), have > 0, icon])
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
		if _stocked(id):
			rows.append(["%s (have %d)%s" % [f.part, inventory.get(f.part, 0), tag],
				"$%d" % f.cost, func(): _buy(f.part, f.cost), money >= f.cost, icon])
		else:
			var mail := int(f.cost * 1.25)
			rows.append(["%s (have %d)%s\nNot in stock: mail order, 1 day" % [f.part, inventory.get(f.part, 0), tag],
				"Order $%d" % mail, func(): _buy(f.part, mail, true), money >= mail, icon])
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
	# Vintage map with a pin per rescue call (click to fly) and a green one for you.
	var map := TextureRect.new()
	map.texture = load("res://textures/us_map.png")
	map.custom_minimum_size = Vector2(576, 360)
	map.mouse_filter = Control.MOUSE_FILTER_PASS  # let the wheel scroll the panel
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.stretch_mode = TextureRect.STRETCH_SCALE
	vb.add_child(map)
	vb.move_child(map, 1)
	var k := 576.0 / 2048.0
	var here: Array = CITIES[location]
	var you := ColorRect.new()
	you.color = Color(0.1, 0.6, 0.2)
	you.size = Vector2(12, 12)
	you.position = Vector2(here[3], here[4]) * k - Vector2(6, 6)
	map.add_child(you)
	for job in jobs:
		if job == current_job:
			continue
		var c: Array = CITIES[job.city]
		var cost := int(miles(location, job.city) * FUEL_PER_MILE)
		var pin := Button.new()
		pin.text = job.city
		pin.add_theme_font_size_override("font_size", 13)
		pin.position = Vector2(c[3], c[4]) * k - Vector2(8, 12)
		pin.disabled = money < cost
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
	env.fog_density = 0.003
	env.fog_light_color = Color(0.92, 0.8, 0.62)  # warm haze
	env.fog_sky_affect = 0.15  # keep the golden panorama visible
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)


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
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	pm.material = tmat(region.tex, Color.WHITE, 0.2)
	ground.mesh = pm
	world.add_child(ground)
	var floor_body := StaticBody3D.new()
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
	var placed := 0
	while placed < region.count:
		var pos := Vector3(r.randf_range(-150, 150), 0, r.randf_range(-150, 150))
		if pos.length() < 32 or absf(pos.z - 14) < 16:  # keep the apron and runway clear
			continue
		placed += 1
		var h := r.randf_range(3.0, 6.0)
		match region.prop:
			"tree":
				var kind: String = TREE_SPLIT.keys()[r.randi() % TREE_SPLIT.size()]
				var tree := prop(kind, pos, r.randf_range(5.5, 9.0), null, r.randf() * TAU, "trunk")
				tree.set_meta("tree", true)
				_paint_tree(tree, TREE_SPLIT[kind], Color.WHITE.darkened(r.randf() * 0.25))
			"pine":  # shortcut: code-built cones until a plain (snowless) pine model exists
				cyl(world, 0.2, 0.3, 1.2, pos + Vector3(0, 0.6, 0), tmat("bark"), 5, true)
				cyl(world, 0, h * 0.3, h * 1.5, pos + Vector3(0, 1.0 + h * 0.75, 0), tmat("foliage", Color(0.55, 0.7, 0.6)), 6)
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
					_crag(pos + Vector3(3, 0, 2), s, s * 1.1, Color(0.95, 0.75, 0.6), r)
	var snowy: bool = region.prop == "snowpine"
	for i in 12:  # distant mountain ring
		var a := r.randf() * TAU
		var height := r.randf_range(25.0, 70.0)
		_crag(Vector3(cos(a), 0, sin(a)) * r.randf_range(165, 200), r.randf_range(25, 50), height,
			region.ground.lightened(0.15).lerp(Color(0.55, 0.5, 0.48), 0.6), r, 0.45 if snowy else (0.75 if height > 50 else 2.0))


## Faceted, jagged rock: 3 jittered rings tapering to an off-center peak, flat-shaded,
## with vertex-colored snow above `snow` (fraction of height; >1 = no snow).
func _crag(pos: Vector3, radius: float, height: float, base: Color, r: RandomNumberGenerator, snow := 2.0) -> void:
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
			st.set_color(Color(0.97, 0.98, 1.0) if v.y > height * snow else base)
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
	plane.position = Vector3(0, 0, 8)
	plane.rotation.y = PI / 2  # nose points down the runway (-X)
	world.add_child(plane)
	# Model faces -X with wings along Z; turn it so the nose is -Z like the rest of this layout.
	# Positions below come from probing the mesh: nose z=-4.5, mains at x=±0.9 z=-2.1,
	# high wing y≈2.4 z -2.4..-1.0, fin z 3.1..4.3, cabin roof y≈2.5.
	var body := model(plane, "plane_trainer", Vector3(0, 0.33 * 10.0 / 1.9, 0), 10.0, Vector3(0, -PI / 2, 0))
	var tint: Color = Color.WHITE.lerp(job.color, 0.5)  # gentle: the tint also lands on tires and glass
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var m: StandardMaterial3D = mi.get_active_material(s).duplicate()
			m.albedo_color = tint
			mi.set_surface_override_material(s, m)
	var hull := StaticBody3D.new()  # keeps the player from walking through the plane
	var hs := CollisionShape3D.new()
	hs.shape = BoxShape3D.new()
	hs.shape.size = Vector3(1.4, 2.0, 9.0)
	hs.position = Vector3(0, 1.2, 0)
	hull.add_child(hs)
	plane.add_child(hull)
	for id in FAULTS:
		visuals[id] = _part_visual(id, job.fixed.has(id) or not job.faults.has(id))
	for z in ZONES:
		interactable(plane, ZONES[z].pos, ZONES[z].size, "zone").set_meta("zone", z)


## The piece of the plane each fault lives on, drawn broken or fixed.
func _part_visual(id: String, ok: bool) -> Node3D:
	var n := Node3D.new()
	plane.add_child(n)
	var axle_x := Vector3(0, PI / 2, 0)  # wheel/disc models spin around Z; turn them to X
	match id:
		"tire":
			model(n, "tire_ok" if ok else "tire_broken", Vector3(-0.9, 0.45, -2.1), 0.95, axle_x)
		"brakes":
			model(n, "tire_ok", Vector3(0.9, 0.45, -2.1), 0.95, axle_x)
			model(n, "brakes_ok" if ok else "brakes_broken", Vector3(1.22, 0.45, -2.1), 0.55, axle_x)
		"battery":
			var hatch := box(n, Vector3(0.05, 0.5, 0.7), Vector3(0.49, 1.2, 1.0), tmat("plane_body_worn", current_job.color))
			if not ok:  # hatch hanging open, corroded battery pulled half out
				hatch.position = Vector3(0.8, 1.2, 1.32)
				hatch.rotation.y = -1.2
				model(n, "battery_broken", Vector3(0.62, 1.2, 1.0), 0.45)
		"spark_plugs":
			if not ok:
				decal(n, Vector2(0.9, 0.45), Vector3(0.71, 1.05, -3.7), "decal_soot", Vector3.RIGHT)
		"oil_leak":
			if not ok:
				decal(n, Vector2(1.8, 1.8), Vector3(0, 0.02, -3.9), "oil_puddle", Vector3.UP)
		"bird_nest":
			if not ok:
				cyl(n, 0.35, 0.22, 0.22, Vector3(0, 1.8, -3.8), tmat("bark", Color(0.8, 0.65, 0.45)), 7)
				ball(n, 0.08, Vector3(0.05, 1.94, -3.8), Color(0.75, 0.88, 0.95))
		"fuel_line":
			if not ok:
				decal(n, Vector2(1.8, 1.8), Vector3(-2.5, 0.02, -1.7), "decal_fuel_stain", Vector3.UP)
				box(n, Vector3(0.04, 2.2, 0.04), Vector3(-2.5, 1.12, -1.7), Color(0.35, 0.5, 0.85))  # drip
		"windshield":
			if not ok:  # fogged glass + crack over the model's windshield (slopes up and back)
				var face := Vector3(0, 0.6, -0.8).normalized()
				var glass := decal(n, Vector2(1.15, 0.85), Vector3(0, 2.12, -2.78), "", face)
				glass.mesh.material.albedo_color = Color(0.45, 0.47, 0.48, 0.85)
				decal(n, Vector2(1.0, 0.75), Vector3(0, 2.13, -2.79), "windshield_cracked", face)
		"starter":
			model(n, "starter_ok", Vector3(-0.78, 1.0, -3.6), 0.45, Vector3.ZERO,
				null if ok else tmat("metal_rust", Color.WHITE, 3.0))
		"magneto":
			model(n, "magneto_ok" if ok else "magneto_broken", Vector3(0.8, 1.35, -3.4), 0.4, Vector3(0, PI / 2, 0))
		"control_cables":
			var rudder := box(n, Vector3(0.08, 1.4, 0.45), Vector3(0, 2.6, 4.45), tmat("plane_body_worn", Color(0.85, 0.2, 0.15)))
			if not ok:
				rudder.rotation = Vector3(0.3, 0.6, 0.2)
		"avionics":
			var ant := box(n, Vector3(0.04, 0.6, 0.04), Vector3(0, 2.41, 0.3), Color(0.08, 0.08, 0.08))
			if not ok:  # snapped and lying flat
				ant.rotation.x = 1.4
				ant.position.y = 2.15
		"propeller":
			if ok:
				model(n, "propeller_ok", Vector3(0, 1.29, -4.6), 2.3, Vector3.ZERO, tmat("prop_wood", Color.WHITE, 1.0))
			else:
				model(n, "propeller_broken", Vector3(0, 1.29, -4.6), 2.3)
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
## uv_cell picks one cell of a 2x2 sprite sheet (e.g. ghost_signs), (-1,-1) = whole image.
func decal(parent: Node, size: Vector2, pos: Vector3, tex: String, normal: Vector3, uv_cell := Vector2i(-1, -1)) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	if tex != "":
		m.albedo_texture = load("res://textures/%s.png" % tex)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if uv_cell.x >= 0:
		m.uv1_scale = Vector3(0.5, 0.5, 1)
		m.uv1_offset = Vector3(uv_cell.x * 0.5, uv_cell.y * 0.5, 0)
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
			var t := cyl(world, 0.3, 0.3, 3.0, Vector3(at.x, at.y + 1.5, at.z), Color.WHITE, 6, true)
			t.visible = false
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
void vertex() { lp = VERTEX; }
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
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://textures/%s.png" % tex)
	m.albedo_color = tint
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var i := 0
	while i < count:
		var p := Vector3(r.randf_range(area.position.x, area.end.x), 0, r.randf_range(area.position.y, area.end.y))
		if _kept_clear(p):
			continue
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * r.randf_range(0.7, 1.3))
		mm.set_instance_transform(i, Transform3D(b, p))
		i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mmi)


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
	var id0: String = job.faults[0]
	if FAULTS[id0].part != "":
		inventory[FAULTS[id0].part] = 1
	_repair(id0)  # opens the timing mini-game
	ok = ok and mg != null
	await _snap(shot, "minigame")
	_finish_repair(id0, false)  # a miss never fixes it
	ok = ok and not job.fixed.has(id0)
	for id in job.faults:
		var part: String = FAULTS[id].part
		if part != "":
			inventory[part] = 1
		_finish_repair(id, true)
	await _snap(shot, "airworthy")
	_close_panel()
	await _snap(shot, "fixed")
	if shot != "":  # extra viewpoints of the hangar and the parts shed
		for v in [["hangar_out", Vector3(-10, 0.1, 4), Vector3(-16, 0, -14)], ["hangar", Vector3(-14, 0.1, -12), Vector3(-19, 0, -20)],
				["drums", Vector3(-3.5, 0.1, -13), Vector3(-7.5, 0, -17)], ["shed", Vector3(18, 0.1, -1), Vector3(14, 0, -8)],
				["truck", Vector3(-1, 0.1, 4), Vector3(-8, 0, -1)],
				["trees", Vector3(-20, 0.1, -25), Vector3(-60, 0, -60)]]:
			player.position = v[1]
			player.look_at(Vector3(v[2].x, player.position.y, v[2].z), Vector3.UP)
			player.cam.rotation.x = -0.35
			await _snap(shot, v[0])
		var trees := world.get_children().filter(func(n): return n.has_meta("tree"))
		for i in mini(3, trees.size()):  # close-ups to check the bark/leaf split
			var spot: Vector3 = trees[i].position
			player.position = Vector3(spot.x + 9, 0.1, spot.z + 9)
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
	print("SELF-TEST ", "PASS" if ok else "FAIL", " faults=", job.faults, " day=%.1f" % day)
	get_tree().quit(0 if ok else 1)


func _snap(prefix: String, name: String, wait := 0.4) -> void:
	if prefix == "":
		return
	await get_tree().create_timer(wait).timeout
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [prefix, name])

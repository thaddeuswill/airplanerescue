extends Node3D
## Airplane Rescue: walk up to stranded planes, inspect them in a 2D panel,
## fix each fault (the 3D model updates), then sign off and fly to the next call.
## All geometry is low-poly primitives built in code. Flat colors are placeholders
## until the textures listed in TEXTURES.md arrive.

const Player := preload("res://scripts/player.gd")
const GOAL := 10
const MAX_JOBS := 3
const START_CITY := "Wichita"
const FUEL_PER_MILE := 0.9

# city: [lon, lat, region]
const CITIES := {
	"Wichita": [-97.3, 37.7, "plains"], "Omaha": [-96.0, 41.3, "plains"],
	"Dallas": [-96.8, 32.8, "plains"], "Chicago": [-87.6, 41.9, "plains"],
	"Billings": [-108.5, 45.8, "plains"], "Miami": [-80.2, 25.8, "plains"],
	"New York": [-74.0, 40.7, "plains"], "Seattle": [-122.3, 47.6, "forest"],
	"Portland": [-122.7, 45.5, "forest"], "Atlanta": [-84.4, 33.7, "forest"],
	"Nashville": [-86.8, 36.2, "forest"], "Bangor": [-68.8, 44.8, "forest"],
	"Los Angeles": [-118.2, 34.1, "desert"], "Phoenix": [-112.1, 33.4, "desert"],
	"Las Vegas": [-115.1, 36.2, "desert"], "Albuquerque": [-106.6, 35.1, "desert"],
	"Denver": [-105.0, 39.7, "snow"], "Salt Lake City": [-111.9, 40.8, "snow"],
	"Fargo": [-96.8, 46.9, "snow"], "Minneapolis": [-93.3, 45.0, "snow"],
}
const REGIONS := {
	"plains": {"ground": Color(0.45, 0.62, 0.3), "prop": "tree", "count": 30},
	"forest": {"ground": Color(0.28, 0.45, 0.22), "prop": "pine", "count": 110},
	"desert": {"ground": Color(0.82, 0.68, 0.45), "prop": "cactus", "count": 40},
	"snow": {"ground": Color(0.92, 0.94, 0.97), "prop": "snowpine", "count": 70},
}
const FAULTS := {
	"tire": {"name": "Flat main tire", "part": "Tire & tube", "cost": 180},
	"brakes": {"name": "Rusted brake disc", "part": "Brake disc", "cost": 260},
	"battery": {"name": "Dead battery", "part": "Battery", "cost": 350},
	"spark_plugs": {"name": "Fouled spark plugs", "part": "Spark plug set", "cost": 220},
	"oil_leak": {"name": "Oil leak", "part": "Gasket kit", "cost": 150},
	"bird_nest": {"name": "Bird nest on the cowling", "part": "", "cost": 0},
	"fuel_line": {"name": "Leaking fuel line", "part": "Fuel line kit", "cost": 300},
	"windshield": {"name": "Cracked windshield", "part": "Windshield", "cost": 900},
	"starter": {"name": "Seized starter", "part": "Starter motor", "cost": 1100},
	"control_cables": {"name": "Jammed rudder cables", "part": "Control cable set", "cost": 650},
	"magneto": {"name": "Bad magneto", "part": "Magneto", "cost": 1400},
	"avionics": {"name": "Broken radio antenna", "part": "Antenna & radio", "cost": 1800},
	"propeller": {"name": "Bent propeller", "part": "Propeller", "cost": 2600},
}
const PLANE_TYPES := [["High-wing trainer", 1500], ["Rag-wing taildragger", 2000],
	["Bush plane", 2500], ["Vintage tourer", 3000], ["Utility hauler", 3500]]

var money := 3000
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


func _ready() -> void:
	assert(absf(miles("New York", "Los Angeles") - 2450.0) < 60.0, "miles() is off")
	rng.randomize()
	_setup_input()
	_setup_environment()
	_setup_ui()
	player = Player.new()
	add_child(player)
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
		"fixed": {}, "reward": int(round((t[1] + cost * 1.6) / 50.0)) * 50,
		"color": Color.from_hsv(rng.randf(), 0.55, 0.85)})


func _travel(job: Dictionary, cost: int) -> void:
	money -= cost
	_close_panel()
	_load_field(job.city, job)
	_say("Arrived in %s. Walk up to the %s and press E to inspect it." % [job.city, job.type])


func _repair(id: String) -> void:
	var f: Dictionary = FAULTS[id]
	if f.part != "":
		inventory[f.part] -= 1
	current_job.fixed[id] = true
	visuals[id].queue_free()
	visuals[id] = _part_visual(id, true)
	_say("Fixed: " + f.name)
	_open_inspection()


func _buy(part: String, cost: int) -> void:
	money -= cost
	inventory[part] = inventory.get(part, 0) + 1
	_open_shop()


func _sign_off() -> void:
	var job: Dictionary = current_job
	money += job.reward
	rescued += 1
	jobs.erase(job)
	current_job = null
	_close_panel()
	_say("The %s is airworthy! Owner paid $%d." % [job.type, job.reward])
	for c in plane.get_children():
		if c.has_meta("kind"):
			c.queue_free()
	var start := plane.position
	var fwd := plane.basis * Vector3.FORWARD
	var tw := create_tween()
	tw.tween_property(plane, "position", start + fwd * 60, 3.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(plane, "position", start + fwd * 220 + Vector3.UP * 50, 4.0)
	tw.tween_callback(_after_flight)
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
	prompt.text = ""
	if panel:
		return
	var t: Object = player.target()
	var kind: String = t.get_meta("kind") if t and t.has_meta("kind") else ""
	if kind == "plane" and current_job == null:
		kind = ""
	match kind:
		"plane": prompt.text = "E: Inspect the " + current_job.type
		"shop": prompt.text = "E: Parts shed"
		"radio": prompt.text = "E: Radio - rescue calls"
	if kind != "" and Input.is_action_just_pressed("interact"):
		match kind:
			"plane": _open_inspection()
			"shop": _open_shop()
			"radio": _open_travel()


func _unhandled_input(e: InputEvent) -> void:
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
	hud.text = "$%d    Rescued %d/%d    %s\nToolbox: %s" % [money, rescued, GOAL, location,
		", ".join(inv) if inv.size() > 0 else "empty"]


func _say(text: String) -> void:
	msg.text = text
	msg_time = 5.0


## rows: [text] or [text, button_text, callable, enabled]. Docked left so the plane stays visible.
func _open_panel(title: String, rows: Array, closable := true) -> void:
	_close_panel()
	panel_closable = closable
	panel = PanelContainer.new()
	panel.position = Vector2(20, 80)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.1, 0.13, 0.92)
	sb.set_content_margin_all(16)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var head := Label.new()
	head.text = title
	head.add_theme_font_size_override("font_size", 22)
	vb.add_child(head)
	for r in rows:
		var hb := HBoxContainer.new()
		vb.add_child(hb)
		var l := Label.new()
		l.text = r[0]
		l.custom_minimum_size.x = 380
		hb.add_child(l)
		if r.size() > 1:
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
	ui.add_child(panel)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.frozen = true


func _close_panel() -> void:
	if panel:
		panel.queue_free()
		panel = null
	player.frozen = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_inspection() -> void:
	var rows := []
	for id in current_job.faults:
		var f: Dictionary = FAULTS[id]
		if current_job.fixed.has(id):
			rows.append(["[OK]  " + f.name])
		elif f.part == "":
			rows.append(["[!!]  %s - no part needed" % f.name, "Repair", func(): _repair(id), true])
		else:
			var have: int = inventory.get(f.part, 0)
			rows.append(["[!!]  %s - needs %s (have %d)" % [f.name, f.part, have],
				"Repair", func(): _repair(id), have > 0])
	if current_job.fixed.size() == current_job.faults.size():
		rows.append(["Airworthy!", "Test flight & sign off (+$%d)" % current_job.reward, _sign_off, true])
	_open_panel("Inspection: " + current_job.type, rows)


func _open_shop() -> void:
	var needed := {}
	if current_job:
		for id in current_job.faults:
			if not current_job.fixed.has(id):
				needed[FAULTS[id].part] = true
	var rows := []
	for id in FAULTS:
		var f: Dictionary = FAULTS[id]
		if f.part == "":
			continue
		var tag := "   << needed" if needed.has(f.part) else ""
		rows.append(["%s (have %d)%s" % [f.part, inventory.get(f.part, 0), tag],
			"$%d" % f.cost, func(): _buy(f.part, f.cost), money >= f.cost])
	_open_panel("Parts shed", rows)


func _open_travel() -> void:
	var rows := []
	var can_fly := false
	for job in jobs:
		if job == current_job:
			continue
		var cost := int(miles(location, job.city) * FUEL_PER_MILE)
		can_fly = can_fly or money >= cost
		rows.append(["%s: %s, pays $%d (%d mi)" % [job.city, job.type, job.reward, int(miles(location, job.city))],
			"Fly ($%d)" % cost, func(): _travel(job, cost), money >= cost])
	if not can_fly and not _can_finish_here():
		_open_panel("Out of money and grounded. Game over.",
			[["You rescued %d planes." % rescued, "Play again", _restart, true]], false)
		return
	_open_panel("Rescue calls", rows)


# ---------- 3D world ----------

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_density = 0.003
	env.fog_light_color = Color(0.75, 0.82, 0.9)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	add_child(sun)


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
	var r := RandomNumberGenerator.new()
	r.seed = hash(city)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	pm.material = mat(region.ground)
	ground.mesh = pm
	world.add_child(ground)
	var floor_body := StaticBody3D.new()
	var fs := CollisionShape3D.new()
	fs.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(fs)
	world.add_child(floor_body)
	box(world, Vector3(160, 0.04, 12), Vector3(0, 0.02, 20), Color(0.28, 0.28, 0.3))  # runway
	for x in range(-76, 80, 10):
		box(world, Vector3(5, 0.05, 0.4), Vector3(x, 0.03, 20), Color(0.95, 0.95, 0.9))
	_build_hangar(Vector3(-16, 0, -14))
	_build_shed(Vector3(14, 0, -8))
	_text3d(city.to_upper() + " FIELD", Vector3(-16, 7.5, -8), 160)
	_scatter(region, r)
	if job:
		_build_plane(job)
	player.velocity = Vector3.ZERO
	player.position = Vector3(4, 0.1, -2)
	player.rotation = Vector3(0, PI, 0)
	player.cam.rotation = Vector3.ZERO


func _build_hangar(at: Vector3) -> void:
	var c := Color(0.62, 0.64, 0.66)
	box(world, Vector3(14, 6, 0.3), at + Vector3(0, 3, -6), c, true)
	for s in [-1, 1]:
		box(world, Vector3(0.3, 6, 12), at + Vector3(s * 7, 3, 0), c, true)
	box(world, Vector3(14.6, 0.3, 12.6), at + Vector3(0, 6.1, 0), c.darkened(0.3), true)
	box(world, Vector3(13.4, 0.04, 11.6), at + Vector3(0, 0.03, 0), Color(0.4, 0.4, 0.42))
	box(world, Vector3(2, 1, 0.8), at + Vector3(3, 0.5, -5.3), Color(0.45, 0.3, 0.2), true)  # desk
	box(world, Vector3(0.7, 0.4, 0.4), at + Vector3(3, 1.2, -5.3), Color(0.15, 0.22, 0.15))  # radio
	interactable(world, at + Vector3(3, 1.2, -5.0), Vector3(1.4, 0.9, 1.2), "radio")
	_text3d("RADIO", at + Vector3(3, 2.2, -5.3), 48)


func _build_shed(at: Vector3) -> void:
	var c := Color(0.55, 0.25, 0.2)
	box(world, Vector3(5, 3, 0.2), at + Vector3(0, 1.5, -2.5), c, true)
	for s in [-1, 1]:
		box(world, Vector3(0.2, 3, 5), at + Vector3(s * 2.5, 1.5, 0), c, true)
	box(world, Vector3(5.6, 0.2, 5.6), at + Vector3(0, 3.1, 0), Color(0.3, 0.3, 0.32))
	box(world, Vector3(3, 1, 0.8), at + Vector3(0, 0.5, -1.5), Color(0.45, 0.3, 0.2), true)  # counter
	for i in 4:
		box(world, Vector3(0.5, 0.4, 0.5), at + Vector3(-1.2 + i * 0.8, 1.2, -1.5), Color.from_hsv(i * 0.2, 0.5, 0.7))
	interactable(world, at + Vector3(0, 1.2, -1.2), Vector3(3.2, 1.2, 1.4), "shop")
	_text3d("PARTS", at + Vector3(0, 3.9, 0), 72)


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
				cyl(world, 0.2, 0.3, 1.6, pos + Vector3(0, 0.8, 0), Color(0.4, 0.27, 0.15), 5, true)
				ball(world, h * 0.35, pos + Vector3(0, 1.4 + h * 0.3, 0), Color(0.3, 0.55, 0.22).lightened(r.randf() * 0.2))
			"pine", "snowpine":
				cyl(world, 0.2, 0.3, 1.2, pos + Vector3(0, 0.6, 0), Color(0.35, 0.23, 0.13), 5, true)
				cyl(world, 0, h * 0.3, h * 1.5, pos + Vector3(0, 1.0 + h * 0.75, 0), Color(0.15, 0.35, 0.18), 6)
				if region.prop == "snowpine":
					cyl(world, 0, h * 0.12, h * 0.6, pos + Vector3(0, 1.0 + h * 1.2, 0), Color(0.95, 0.97, 1.0), 6)
			"cactus":
				var g := Color(0.3, 0.55, 0.3)
				cyl(world, 0.25, 0.3, h * 0.6, pos + Vector3(0, h * 0.3, 0), g, 6, true)
				box(world, Vector3(0.9, 0.3, 0.3), pos + Vector3(0.45, h * 0.3, 0), g)
				box(world, Vector3(0.3, 0.9, 0.3), pos + Vector3(0.8, h * 0.3 + 0.45, 0), g)
				if r.randf() < 0.5:
					ball(world, r.randf_range(0.5, 1.5), pos + Vector3(3, 0.2, 2), Color(0.6, 0.45, 0.35))
	for i in 8:  # distant mountains
		var a := r.randf() * TAU
		var height := r.randf_range(25.0, 60.0)
		cyl(world, 0, r.randf_range(25, 45), height, Vector3(cos(a) * 180, height / 2, sin(a) * 180),
			region.ground.darkened(0.35), 5)


func _build_plane(job: Dictionary) -> void:
	plane = Node3D.new()
	plane.position = Vector3(0, 0, 8)
	plane.rotation.y = PI / 2  # nose points down the runway (-X)
	world.add_child(plane)
	var c: Color = job.color
	var dark := Color(0.15, 0.15, 0.17)
	box(plane, Vector3(1.2, 1.2, 6), Vector3(0, 1.4, 0), c, true)  # fuselage
	box(plane, Vector3(1.22, 0.18, 5), Vector3(0, 1.15, 0.4), Color.WHITE)  # stripe
	box(plane, Vector3(1.1, 1.1, 1.0), Vector3(0, 1.4, -3.4), Color(0.22, 0.22, 0.24))  # cowling
	box(plane, Vector3(10, 0.15, 1.6), Vector3(0, 2.1, -0.8), c)  # wing
	box(plane, Vector3(3.4, 0.1, 0.9), Vector3(0, 1.6, 2.9), c)  # tailplane
	box(plane, Vector3(0.1, 1.3, 0.8), Vector3(0, 2.3, 2.8), c.darkened(0.2))  # fin
	var spinner := cyl(plane, 0.05, 0.3, 0.4, Vector3(0, 1.4, -4.1), dark, 8)
	spinner.rotation.x = -PI / 2
	var tailwheel := cyl(plane, 0.15, 0.15, 0.12, Vector3(0, 0.15, 2.8), dark, 8)
	tailwheel.rotation.z = PI / 2
	for s in [-1, 1]:
		var strut := box(plane, Vector3(0.08, 2.17, 0.08), Vector3(s * 1.55, 1.5, -0.8), Color(0.6, 0.6, 0.62))
		strut.rotation.z = -s * 1.07  # fuselage bottom to wing
		var leg := box(plane, Vector3(0.1, 0.9, 0.1), Vector3(s * 0.8, 0.7, -1.2), Color(0.6, 0.6, 0.62))
		leg.rotation.z = s * 0.4
	for id in FAULTS:
		visuals[id] = _part_visual(id, job.fixed.has(id) or not job.faults.has(id))
	interactable(plane, Vector3(0, 1.4, -0.5), Vector3(1.4, 1.4, 7.4), "plane")
	interactable(plane, Vector3(0, 2.1, -0.8), Vector3(10.2, 0.4, 1.8), "plane")


## The piece of the plane each fault lives on, drawn broken or fixed.
func _part_visual(id: String, ok: bool) -> Node3D:
	var n := Node3D.new()
	plane.add_child(n)
	var black := Color(0.08, 0.08, 0.08)
	var steel := Color(0.78, 0.78, 0.8)
	var rust := Color(0.55, 0.28, 0.12)
	var wood := Color(0.15, 0.12, 0.1)
	match id:
		"tire":
			var w := cyl(n, 0.35, 0.35, 0.25, Vector3(-1.0, 0.35, -1.2), black, 10)
			w.rotation.z = PI / 2
			if not ok:  # squashed flat
				w.scale.x = 0.55
				w.position.y = 0.2
		"brakes":
			var w := cyl(n, 0.35, 0.35, 0.25, Vector3(1.0, 0.35, -1.2), black, 10)
			w.rotation.z = PI / 2
			var d := cyl(n, 0.22, 0.22, 0.04, Vector3(1.15, 0.35, -1.2), steel if ok else rust, 10)
			d.rotation.z = PI / 2
		"battery":
			var hatch := box(n, Vector3(0.05, 0.5, 0.7), Vector3(0.62, 1.2, 1.0), Color(0.5, 0.5, 0.52))
			if not ok:  # hatch hanging open, corroded battery showing
				hatch.position = Vector3(0.95, 1.2, 1.3)
				hatch.rotation.y = -1.2
				box(n, Vector3(0.3, 0.3, 0.4), Vector3(0.5, 1.2, 1.0), rust)
		"spark_plugs":
			if not ok:
				box(n, Vector3(0.02, 0.4, 0.9), Vector3(0.57, 1.25, -3.3), black)  # soot streak
		"oil_leak":
			if not ok:
				cyl(n, 0.8, 0.8, 0.02, Vector3(0, 0.01, -3.2), black, 10)
		"bird_nest":
			if not ok:
				cyl(n, 0.35, 0.22, 0.22, Vector3(0, 2.06, -3.3), Color(0.45, 0.32, 0.18), 7)
				ball(n, 0.08, Vector3(0.05, 2.2, -3.3), Color(0.85, 0.9, 1.0))
		"fuel_line":
			if not ok:
				var fuel := Color(0.35, 0.5, 0.85)
				cyl(n, 0.9, 0.9, 0.02, Vector3(-2.5, 0.01, -0.8), fuel, 10)
				box(n, Vector3(0.04, 1.9, 0.04), Vector3(-2.5, 1.0, -0.8), fuel)  # drip
		"windshield":
			box(n, Vector3(1.0, 0.55, 0.08), Vector3(0, 2.05, -2.0), Color(0.55, 0.8, 0.95) if ok else Color(0.3, 0.32, 0.34))
			if not ok:
				var crack := box(n, Vector3(0.9, 0.03, 0.1), Vector3(0, 2.05, -2.01), Color.WHITE)
				crack.rotation.z = 0.5
		"starter":
			box(n, Vector3(0.25, 0.25, 0.4), Vector3(-0.62, 1.2, -3.5), steel if ok else rust)
		"magneto":
			box(n, Vector3(0.25, 0.25, 0.3), Vector3(0.62, 1.7, -3.3), steel if ok else rust)
		"control_cables":
			var rudder := box(n, Vector3(0.08, 1.1, 0.5), Vector3(0, 2.3, 3.45), Color(0.85, 0.2, 0.15))
			if not ok:
				rudder.rotation = Vector3(0.3, 0.6, 0.2)
		"avionics":
			var ant := box(n, Vector3(0.04, 0.6, 0.04), Vector3(0, 2.3, 1.0), black)
			if not ok:  # snapped and lying flat
				ant.rotation.x = 1.4
				ant.position.y = 2.05
		"propeller":
			if ok:
				box(n, Vector3(0.15, 2.4, 0.08), Vector3(0, 1.4, -3.97), wood)
			else:
				box(n, Vector3(0.15, 1.2, 0.08), Vector3(0, 2.0, -3.97), wood)
				var bent := box(n, Vector3(0.15, 1.2, 0.08), Vector3(0, 0.9, -3.85), wood)
				bent.rotation.x = -0.7
	return n


# ---------- mesh helpers ----------

func mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


func box(parent: Node, size: Vector3, pos: Vector3, c: Color, solid := false) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	bm.material = mat(c)
	return _place(parent, bm, pos, solid)


func cyl(parent: Node, top: float, bottom: float, h: float, pos: Vector3, c: Color, segs := 6, solid := false) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = bottom
	cm.height = h
	cm.radial_segments = segs
	cm.rings = 1
	cm.material = mat(c)
	return _place(parent, cm, pos, solid)


func ball(parent: Node, radius: float, pos: Vector3, c: Color) -> MeshInstance3D:
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


# ---------- self-test: godot --path . -- --self-test [--shot=prefix] ----------

func _self_test(args: PackedStringArray) -> void:
	var shot := ""
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	var job: Dictionary = jobs[0]
	var start := money
	_travel(job, 0)
	await get_tree().create_timer(1.0).timeout
	if shot:
		get_viewport().get_texture().get_image().save_png(shot + "_broken.png")
	for id in job.faults:
		var part: String = FAULTS[id].part
		if part != "":
			inventory[part] = 1
		_repair(id)
	if shot:
		_close_panel()
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png(shot + "_fixed.png")
	var ok: bool = job.fixed.size() == job.faults.size()
	_sign_off()
	ok = ok and rescued == 1 and money == start + job.reward and jobs.size() == MAX_JOBS
	print("SELF-TEST ", "PASS" if ok else "FAIL", " faults=", job.faults)
	get_tree().quit(0 if ok else 1)

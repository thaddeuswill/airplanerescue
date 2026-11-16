extends Control
## The engine bay: one place, opened up layer by layer instead of picked from a list. You start at
## the cowled engine, unlatch the cowl, then move around it: left side, top, rear accessory case,
## underneath, firewall. Every part you can click offers what you can do there with what you have:
## your hands (look closer), a hand tool from your roll, or the one test instrument in your hand.
## Nothing that needs a tool you aren't carrying shows up (docs/quick-specs/engine-bay-proposal-2026-11-14.md).
## Visible faults leave tells on the parts (oil weep, soot, blue fuel stain, straw...): look closer
## at a tell and it's written up. Faults inside a part only show on a run-up or in a test.

const Work := preload("res://scripts/work.gd")
const VIEW := Vector2(820, 560)  # the painted part of each scene's background (the bench is cut off)

## The views, in walking order. "art" is the scene background; "cowl" draws the closed cowl over it.
const VIEWS := {
	"cowled": {"name": "Engine, cowl closed", "art": "spark_plugs", "cowl": true},
	"left": {"name": "Left side, cowl open", "art": "spark_plugs"},
	"top": {"name": "From the top: fins and baffles", "art": "baffles"},
	"rear": {"name": "Rear accessory case", "art": "starter"},
	"below": {"name": "Underneath", "art": "oil_change"},
	"firewall": {"name": "Firewall", "art": "fuel_strainer"},
}
const OPEN_VIEWS := ["left", "top", "rear", "below", "firewall"]

## Parts per view: id, name, rects (one part can sit in several places), "look" (visible faults
## whose tell is here) and "acts" ([tool, what you do, scene or #action]). Scenes in main.TESTS open
## as tests; the rest as repairs (a part with nothing wrong opens healthy, see work.gd).
const PARTS := {
	"cowled": [
		{"id": "latches", "name": "Cowl latches", "rects": [Rect2(40, 40, 760, 300)], "look": [],
			"acts": [["screwdriver", "Unlatch the side cowl and swing it up", "#open"]]},
		{"id": "scoop", "name": "Carb air scoop", "rects": [Rect2(70, 380, 140, 88)], "look": ["air_filter"], "acts": []},
		{"id": "tailpipe", "name": "Tailpipe", "rects": [Rect2(695, 335, 55, 160)], "look": ["exhaust_check"], "acts": []},
		{"id": "belly", "name": "Lower cowl and belly", "rects": [Rect2(240, 360, 340, 150)], "look": ["oil_leak", "fuel_line"], "acts": []},
		{"id": "oildoor", "name": "Oil door and dipstick", "rects": [Rect2(600, 430, 100, 50)], "look": ["oil_change", "pre_oil"], "acts": []},
	],
	"left": [
		{"id": "plugs", "name": "Spark plugs", "rects": [Rect2(160, 145, 60, 55), Rect2(300, 245, 60, 55), Rect2(460, 145, 60, 55), Rect2(600, 245, 60, 55)],
			"look": ["storage"], "acts": [["ratchet", "Pull and replace the spark plugs", "spark_plugs"],
				["ratchet", "Pull the plugs and read them", "reading_plugs"], ["ratchet", "Spark test on the leads", "spark_test"],
				["tester", "Differential compression test", "compression"], ["ratchet", "Plugs out, pressure pot on: pre-oil", "pre_oil", "found"],
				["screwdriver", "Take it out of storage", "storage", "found"]]},
		{"id": "rockers", "name": "Rocker covers", "rects": [Rect2(215, 95, 85, 185), Rect2(515, 95, 85, 185)], "look": ["oil_leak"],
			"acts": [["screwdriver", "New rocker cover gaskets", "oil_leak"], ["screwdriver", "Rocker cover off: check the valves", "stuck_valve"],
				["ratchet", "Pull the cylinder", "worn_rings"]]},
		{"id": "leads", "name": "Ignition leads", "rects": [Rect2(180, 25, 620, 70)], "look": [],
			"acts": [["ratchet", "Replace an ignition lead", "ign_lead"]]},
		{"id": "filler", "name": "Oil filler and dipstick", "rects": [Rect2(392, 55, 60, 70)], "look": ["oil_change", "pre_oil"],
			"acts": [["pliers", "Drain and change the oil", "oil_change"]]},
		{"id": "stack", "name": "Exhaust stack", "rects": [Rect2(695, 335, 55, 160)], "look": ["exhaust_check"], "acts": []},
		{"id": "socket", "name": "Behind the baffle", "rects": [Rect2(560, 236, 120, 50)], "look": ["fod"], "only": "fod",
			"acts": [["hand", "Fish out what's in there", "fod"]]},
	],
	"top": [
		{"id": "fins", "name": "Cylinder fins and baffle seals", "rects": [Rect2(60, 80, 230, 240), Rect2(550, 80, 230, 240)],
			"look": ["baffles", "bird_nest"], "acts": [["rag", "Clean the fins, fix the baffle seal", "baffles"],
				["hand", "Pull the nest out", "bird_nest"]]},
		{"id": "cap", "name": "Oil filler cap", "rects": [Rect2(445, 275, 60, 60)], "look": ["oil_change", "pre_oil"],
			"acts": [["pliers", "Drain and change the oil", "oil_change"]]},
	],
	"rear": [
		{"id": "starter", "name": "Starter", "rects": [Rect2(115, 185, 125, 135)], "look": [], "acts": [["ratchet", "Swap the starter", "starter"]]},
		{"id": "mag_l", "name": "Left magneto", "rects": [Rect2(415, 80, 120, 100)], "look": [],
			"acts": [["timing", "Check and set the timing", "mag_timing"], ["screwdriver", "Check the P-lead and switch wire", "hot_mag"],
				["ratchet", "Swap the magneto", "magneto"]]},
		{"id": "mag_r", "name": "Right magneto", "rects": [Rect2(555, 80, 120, 100)], "look": [],
			"acts": [["timing", "Check and set the timing", "mag_timing"], ["screwdriver", "Check the P-lead and switch wire", "hot_mag"],
				["ratchet", "Swap the magneto", "magneto"]]},
		{"id": "relief", "name": "Oil pressure relief valve", "rects": [Rect2(400, 235, 45, 45)], "look": [],
			"acts": [["ratchet", "Pull and clean the relief valve", "relief_valve"]]},
	],
	"below": [
		{"id": "airbox", "name": "Carb air box and filter", "rects": [Rect2(50, 140, 240, 220)], "look": ["air_filter"],
			"acts": [["screwdriver", "Air filter and carb heat box", "air_filter"], ["screwdriver", "Carb heat cable", "carb_heat"]]},
		{"id": "sump", "name": "Oil sump and drain plug", "rects": [Rect2(300, 140, 300, 170)], "look": ["oil_leak", "oil_change"], "no_tell": ["oil_change"],
			"acts": [["pliers", "Drain and change the oil", "oil_change"]]},
		{"id": "screen", "name": "Oil suction screen", "rects": [Rect2(600, 190, 80, 80)], "look": [],
			"acts": [["pliers", "Pull the screen and look at it", "oil_screen"]]},
		{"id": "muffler", "name": "Muffler and heat muff", "rects": [Rect2(690, 105, 95, 280)], "look": ["exhaust_check"],
			"acts": [["ratchet", "Pull the shroud and check the muffler", "exhaust_check"]]},
		{"id": "risers", "name": "Exhaust risers", "rects": [Rect2(275, 55, 55, 55), Rect2(545, 55, 55, 55), Rect2(335, 365, 55, 55), Rect2(605, 365, 55, 55)],
			"look": [], "acts": [["hand", "Run it a minute, then feel each riser", "cold_cylinder"]]},
	],
	"firewall": [
		{"id": "strainer", "name": "Gascolator", "rects": [Rect2(415, 165, 150, 220)], "look": ["fuel_strainer", "water_fuel", "jet_fuel"],
			"acts": [["pliers", "Pull the bowl and clean the screen", "fuel_strainer"], ["hand", "Drain a fuel sample", "water_fuel"]]},
		{"id": "lines", "name": "Fuel lines", "rects": [Rect2(150, 105, 270, 90), Rect2(560, 70, 210, 120)], "look": ["fuel_line"],
			"acts": [["ratchet", "Replace the fuel line", "fuel_line"]]},
		{"id": "vent", "name": "Tank vent line", "rects": [Rect2(720, 40, 60, 60)], "look": ["fuel_vent"],
			"acts": [["pliers", "Clear the tank vent", "fuel_vent"]]},
	],
}

var main
var zone := "engine"  # which spot: the engine (VIEWS/PARTS above) or any other (built from its jobs' art)
var view := "cowled"
var hover := ""
var card: PanelContainer
var font: Font = Style.display(600)
var _tex := {}
var _t := 0.0


func setup(m, z := "engine") -> void:
	main = m
	zone = z
	if zone == "engine":
		view = m.bay_view if not m.cowl_closed(m.current_job) or m.bay_view == "cowled" else "cowled"
	else:
		_build_spot()
		view = m.spot_view.get(zone, "")
		if not _spot.defs.has(view):
			view = _spot.order[0]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_tabs()


# ---------- the other spots: views made from the jobs' own paintings ----------

## Every spot but the engine is built from its jobs: one view per painting (the tire job's wheel,
## the windshield job's windshield...), showing the parts themselves as installed, with no access
## panels or covers over them. A part that's broken and shows from outside is drawn as its "old"
## painting (the flat tire, the cracked windshield): that's the tell. Each view is one part you
## look closer at, and offers every job and test done there.
var _spot := {}  # order: [view ids], defs: view -> {name, art, scenes, pieces}, parts: view -> [part]


func _build_spot() -> void:
	var order := []
	var defs := {}
	var loose := []  # jobs with no painting of their own: offered on the first view
	var places: Array = main.station_places(zone)
	for id in main.FAULTS:  # faults with no job of their own here (grounding finds) still show
		if main.FAULTS[id].zone == zone and not id in places:
			places.append(id)
	for id in places:
		var d: Dictionary = Work.scene_for(id, main.FAULTS.get(id, {}))
		var a: String = d.get("art", id)
		if not ResourceLoader.exists("res://textures/work/%s_bg.png" % a):
			loose.append(id)
			continue
		if not defs.has(a):
			order.append(a)
			defs[a] = {"name": String(main.PLACES.get(id, d.get("title", id))), "art": a, "scenes": [], "pieces": []}
		defs[a].scenes.append(id)
		for e in d.els:
			if e.type == "part":
				defs[a].pieces.append({"scene": id, "art": e.get("art", e.id), "rect": e.get("art_rect", e.rect)})
	if order.is_empty():
		order.append("none")
		defs["none"] = {"name": main.ZONES[zone].name.capitalize(), "art": "", "scenes": [], "pieces": []}
	defs[order[0]].scenes.append_array(loose)
	var parts := {}
	for v in order:
		var r := Rect2()
		for pc in defs[v].pieces:
			r = pc.rect if r.size == Vector2.ZERO else r.merge(pc.rect)
		r = r.intersection(Rect2(Vector2.ZERO, VIEW)) if r.size != Vector2.ZERO else Rect2(Vector2(30, 30), VIEW - Vector2(60, 60))
		if r.size.x < 120 or r.size.y < 90:
			r = r.grow_individual(maxf(0, (120 - r.size.x) / 2), maxf(0, (90 - r.size.y) / 2), maxf(0, (120 - r.size.x) / 2), maxf(0, (90 - r.size.y) / 2))
		var acts := []
		for id in defs[v].scenes:
			if main.PLACES.has(id):
				acts.append([_gate(id), String(main.PLACES[id]), id])
		parts[v] = [{"id": v, "name": defs[v].name, "rects": [r],
			"look": defs[v].scenes.filter(func(id): return main.FAULTS.has(id) and main.FAULTS[id].zone == zone), "acts": acts}]
	_spot = {"order": order, "defs": defs, "parts": parts}


## The tool a job at this spot is offered with: the test instrument it needs, else the first hand
## tool it uses, else your hands. The job itself still asks for every tool in turn.
func _gate(id: String) -> String:
	var d: Dictionary = Work.scene_for(id, main.FAULTS.get(id, {}))
	var first := "hand"
	for e in d.els:
		var t: String = e.get("tool", "hand")
		if t in main.INSTRUMENTS:
			return t
		if first == "hand" and t != "hand" and Work.TOOLS.has(t):
			first = t
	return first


func views() -> Array:
	return OPEN_VIEWS if zone == "engine" else _spot.order


func vdef(v: String) -> Dictionary:
	return VIEWS[v] if zone == "engine" else _spot.defs[v]


# ---------- layout ----------

func _k() -> float:
	return minf(size.x / VIEW.x, (size.y - 150) / VIEW.y)


func _origin() -> Vector2:
	return Vector2((size.x - VIEW.x * _k()) / 2, 86)


func _to_view(p: Vector2) -> Vector2:
	return (p - _origin()) / _k()


var _tabs: HBoxContainer


func _build_tabs() -> void:
	if _tabs:
		_tabs.queue_free()
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", Style.SPACE_2)
	add_child(_tabs)
	if view == "cowled":
		return
	for v in views():
		var b := Button.new()
		b.text = vdef(v).name.split(":")[0].split(",")[0].to_upper()
		if v == view:
			Style.button(b, "primary")
		else:
			_hud_quiet(b)
		b.add_theme_font_size_override("font_size", Style.SIZE_SM)
		b.custom_minimum_size.y = 40
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): _go(v))
		_tabs.add_child(b)
	var close := Button.new()
	close.text = "CLOSE THE COWL" if zone == "engine" else "DONE HERE"
	_hud_quiet(close)
	close.add_theme_font_size_override("font_size", Style.SIZE_SM)
	close.custom_minimum_size.y = 40
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(func():
		if zone != "engine":
			main.station_zone = ""
			main._open_inspection(zone)
			return
		var why: String = main.bay_close_cowl()
		if why != "":
			main._say(why)
		else:
			_go("cowled"))
	_tabs.add_child(close)


## A quiet button on the dark hangar surface: cream text, brass edge (the paper "quiet" style is
## ink on a light tint and disappears here).
func _hud_quiet(b: Button) -> void:
	Style.button(b, "quiet")
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(Style.COLOR_TEXT_HUD, {"normal": 0.0, "hover": 0.12, "pressed": 0.2, "disabled": 0.0}[state])
		sb.border_color = Color(Style.COLOR_TEXT_HUD_MUTED, 0.8)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(Style.RADIUS_SM)
		sb.content_margin_left = Style.SPACE_3
		sb.content_margin_right = Style.SPACE_3
		b.add_theme_stylebox_override(state, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Style.COLOR_TEXT_HUD)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _tabs:
		_tabs.position = Vector2(_origin().x, _origin().y + VIEW.y * _k() + 10)


func _go(v: String) -> void:
	view = v
	if zone == "engine":
		main.bay_view = v
	else:
		main.spot_view[zone] = v
	_close_card()
	_build_tabs()
	_notification(NOTIFICATION_RESIZED)
	queue_redraw()


# ---------- parts ----------

func parts() -> Array:
	var job: Dictionary = main.current_job
	if zone != "engine":
		return _spot.parts[view]
	return PARTS[view].filter(func(p): return not p.has("only") or job.faults.has(p.only) and not job.fixed.has(p.only))


func _hit(p: Vector2) -> String:
	for part in parts():
		for r in part.rects:
			if r.has_point(p):
				return part.id
	return ""


func _part(id: String) -> Dictionary:
	for p in parts():
		if p.id == id:
			return p
	return {}


## What you can do at this part with what you have: look closer always; a tool's job only if the
## tool is in your roll (or, for an instrument, in your hand). Easy also lists the rest, greyed,
## with where the tool is.
func actions(part: Dictionary) -> Array:
	var out := [{"text": "Look closer", "do": "#look", "ok": true}]
	var job: Dictionary = main.current_job
	for a in part.acts:
		if a.size() > 3 and a[3] == "found" and not job.found.has(a[2]):
			continue  # a procedure for an engine you've seen needs it (the storage tag, a dry dipstick), not a repair to try
		var ok: bool = a[0] == "hand" or (main.tools.has(a[0]) and (not a[0] in main.INSTRUMENTS or main.held == a[0]))
		if ok:
			out.append({"text": a[1], "do": a[2], "ok": true, "tool": a[0]})
		elif main.guide("easy"):
			var where: String = "take the %s from your toolbox" % main.SUPPLIES[a[0]].name.to_lower() if main.tools.has(a[0]) \
				else "you don't own a %s yet" % Work.TOOLS[a[0]].to_lower()
			out.append({"text": "%s (%s)" % [a[1], where], "do": "", "ok": false})
	return out


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := _hit(_to_view(ev.position))
		if h != hover:
			hover = h
			queue_redraw()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var h := _hit(_to_view(ev.position))
		if h == "":
			_close_card()
		else:
			_open_card(_part(h), ev.position)


func _open_card(part: Dictionary, at: Vector2) -> void:
	_close_card()
	card = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER
	sb.set_corner_radius_all(Style.RADIUS_SM)
	sb.set_content_margin_all(Style.SPACE_3)
	sb.border_width_top = 4
	sb.border_color = Style.COLOR_TEXT_PAPER_ACCENT
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 8
	card.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.SPACE_2)
	card.add_child(col)
	col.add_child(Style.label(part.name.to_upper(), "accent", Style.SIZE_MD, 900))
	for a in actions(part):
		var b := Button.new()
		b.text = a.text
		Style.button(b, "quiet")
		b.add_theme_font_size_override("font_size", Style.SIZE_MD)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 40
		b.disabled = not a.ok
		b.focus_mode = Control.FOCUS_NONE
		var what: String = a.do
		b.pressed.connect(func(): _do(part, what))
		col.add_child(b)
	add_child(card)
	card.reset_size()
	card.position = Vector2(clampf(at.x + 12, 8, size.x - card.size.x - 8), clampf(at.y + 12, 8, size.y - card.size.y - 8))


func _close_card() -> void:
	if is_instance_valid(card):
		card.queue_free()
	card = null


func _do(part: Dictionary, what: String) -> void:
	_close_card()
	match what:
		"#look":
			main.bay_look(part)
			queue_redraw()
		"#open":
			if main.bay_open_cowl():
				_go("left")
		_:
			main.bay_open_scene(what, zone)


## Self-test helper: open it up, look closer at every part in every view, close it back up and
## hand over to the work order, as the flashlight walk-around did.
func solve() -> bool:
	if zone != "engine":
		for v in views():
			view = v
			for p in parts():
				main.bay_look(p)
		main._open_inspection(zone)
		return true
	main.tools["screwdriver"] = true
	if main.cowl_closed(main.current_job) and not main.bay_open_cowl():
		return false
	for v in ["cowled"] + OPEN_VIEWS:
		view = v
		for p in parts():
			main.bay_look(p)
	if main.bay_close_cowl() != "":
		return false
	main._open_inspection("engine")
	return true


# ---------- drawing ----------

func _process(delta: float) -> void:
	_t += delta
	if main.guide("easy"):
		queue_redraw()  # the glint on a tell pulses on Easy


func _art(name: String) -> Texture2D:
	if not _tex.has(name):
		var p := "res://textures/%s.png" % name
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]


func _draw() -> void:
	var job = main.current_job
	if job == null:
		return
	var o := _origin()
	var k := _k()
	draw_rect(Rect2(Vector2.ZERO, size), Style.COLOR_SURFACE_HUD)
	draw_string(Style.caps(900, Style.SIZE_XL), Vector2(o.x, 38), "%s  -  %s" % [job.type.to_upper(), vdef(view).name.to_upper()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XL, Style.COLOR_TEXT_HUD)
	var status: String = ("Cowl closed and fastened. Unlatch it with the screwdriver to get in." if view == "cowled"
		else "Cowl open. Close it up before you leave the engine." if zone == "engine"
		else "The %s. Look closer at each part; the tabs below walk you round it." % main.ZONES[zone].name)
	if main.held != "":
		status += "   In hand: " + main.SUPPLIES[main.held].name + "."
	draw_string(font, Vector2(o.x, 64), status + "   Click a part. Esc steps back.", HORIZONTAL_ALIGNMENT_LEFT, size.x - o.x * 2, Style.SIZE_SM, Style.COLOR_TEXT_HUD_MUTED)
	draw_set_transform(o, 0.0, Vector2(k, k))
	var bg := _art("work/%s_bg" % vdef(view).art)
	if bg:
		draw_texture_rect_region(bg, Rect2(Vector2.ZERO, VIEW), Rect2(Vector2.ZERO, VIEW))
	else:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.2, 0.19, 0.18))
	if zone != "engine":
		_draw_pieces()
	if vdef(view).get("cowl", false):
		var cowl := _art("work/spark_plugs_cowl")
		if cowl:
			draw_texture_rect(cowl, Rect2(40, 40, 760, 300), false)
	for p in parts():
		_draw_tells(p)
	for p in parts():
		_draw_written_up(p)
	for p in parts():
		if p.id == hover:
			for r in p.rects:
				draw_rect(r, Style.COLOR_FOCUS, false, 3.0 / k)
	draw_set_transform(Vector2.ZERO)
	if hover != "":
		var mp := get_local_mouse_position() + Vector2(18, 22)
		var name: String = _part(hover).get("name", "")
		var w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_MD).x + 16
		draw_rect(Rect2(mp - Vector2(8, 20), Vector2(w, 28)), Color(Style.COLOR_SURFACE_HUD, 0.9))
		draw_string(font, mp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_MD, Style.COLOR_TEXT_HUD)


## A spot's parts as installed: each job's part painting, "old" (the damage) while that fault is on
## the plane and shows from outside, else the sound one. One painting per piece, the damaged one first.
func _draw_pieces() -> void:
	var job: Dictionary = main.current_job
	var d: Dictionary = vdef(view)
	var drawn := {}
	for bad in [true, false]:
		for pc in d.pieces:
			var id: String = pc.scene
			var broken: bool = job.faults.has(id) and not job.fixed.has(id) and main._how(job, id) == "walk"
			if broken != bad or drawn.has(pc.art):
				continue
			var t := _art("work/%s_%s_%s" % [d.art, pc.art, "old" if bad else "new"])
			if t == null:
				t = _art("work/%s_%s_%s" % [d.art, pc.art, "new" if bad else "old"])
			if t:
				drawn[pc.art] = true
				draw_texture_rect(t, pc.rect, false)


## Written up and not fixed yet: a "!" stays on the part until the job's done, on every difficulty
## (you wrote it, so it's no hint). Looks at the faults you can see here and the jobs done here.
func _draw_written_up(p: Dictionary) -> void:
	var job: Dictionary = main.current_job
	var ids: Array = p.look + p.acts.map(func(a): return a[2])
	if not ids.any(func(id): return job.faults.has(id) and job.found.has(id) and not job.fixed.has(id)):
		return
	var r: Rect2 = p.rects[0]
	var c := Vector2(minf(r.end.x - 4, VIEW.x - 22), maxf(r.position.y + 4, 22))
	draw_circle(c, 17, Color(0.08, 0.06, 0.04, 0.6))
	draw_circle(c, 15, Style.COLOR_TEXT_PAPER_ACCENT)
	draw_arc(c, 15, 0, TAU, 32, Style.COLOR_TEXT_HUD, 2.0)
	var f := Style.display(900)
	var w := f.get_string_size("!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	draw_string(f, c + Vector2(-w / 2, 9), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Style.COLOR_TEXT_HUD)


## The tells of visible faults, painted over the part. Strength follows the difficulty: plain on
## Medium, stronger with a pulsing glint on Easy, faint on Hard (you have to look closely).
## Tells that are one object (a nest, a socket, a dipstick): drawn once, at the part's first spot,
## not repeated on every spot the part has (oil on both rocker covers is right; two nests aren't).
const ONCE := ["bird_nest", "fod", "fuel_vent", "air_filter", "fuel_strainer", "water_fuel", "jet_fuel", "oil_change"]


func _draw_tells(p: Dictionary) -> void:
	var job: Dictionary = main.current_job
	var strength: float = 1.0 if main.guide("easy") else (0.75 if main.guide("medium") else 0.45)
	for id in p.look:
		if not job.faults.has(id) or job.fixed.has(id) or main._how(job, id) != "walk":
			continue
		if id in p.get("no_tell", []):  # found by looking here, but nothing of it shows (a dipstick on the sump)
			continue
		for r in (p.rects.slice(0, 1) if id in ONCE else p.rects):
			_tell(id, r, strength)
		if main.guide("easy") and not job.found.has(id):
			var c: Vector2 = p.rects[0].get_center()
			draw_arc(c, 18.0 + 4.0 * sin(_t * 4.0), 0, TAU, 32, Color(Style.COLOR_FOCUS, 0.8), 3.0)


func _tell(id: String, r: Rect2, a: float) -> void:
	var art := _art("bay/tell_" + id)  # painted tells (ART_PROMPTS.md section 7) replace the placeholders
	if art:
		# Fitted inside the part at its own proportions (never stretched), centered, and never
		# blown up past a little over its painted size.
		var sz := art.get_size()
		var k := minf(minf(r.size.x / sz.x, r.size.y / sz.y), 1.25)
		draw_texture_rect(art, Rect2(r.get_center() - sz * k / 2, sz * k), false, Color(1, 1, 1, a))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id + str(r.position))  # the same smear every frame
	match id:
		"oil_leak", "oil_change":  # dark, wet oil weeping and running down
			var oil := Color(0.12, 0.08, 0.03, 0.75 * a) if id == "oil_leak" else Color(0.05, 0.04, 0.03, 0.6 * a)
			for i in 5:
				var p := r.position + Vector2(rng.randf() * r.size.x, r.size.y * (0.5 + rng.randf() * 0.5))
				draw_circle(p, 6.0 + rng.randf() * 8.0, oil)
				draw_line(p, p + Vector2(rng.randf_range(-3, 3), 20 + rng.randf() * 40), oil, 4.0)
		"exhaust_check":  # gray-black soot streaking back from the crack
			for i in 6:
				var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y * 0.6)
				draw_line(p, p + Vector2(rng.randf_range(10, 30), rng.randf_range(20, 60)), Color(0.08, 0.08, 0.08, 0.55 * a), 8.0)
		"fuel_line", "jet_fuel":  # blue 100LL stain (straw-colored for kerosene), dried at the edges
			var dye := Color(0.25, 0.45, 0.85, 0.45 * a) if id == "fuel_line" else Color(0.75, 0.65, 0.3, 0.4 * a)
			for i in 4:
				var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
				draw_circle(p, 10.0 + rng.randf() * 14.0, dye)
				draw_line(p, p + Vector2(0, 30 + rng.randf() * 30), dye, 5.0)
		"bird_nest":  # straw sticking out
			for i in 14:
				var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
				draw_line(p, p + Vector2.from_angle(rng.randf() * TAU) * (12 + rng.randf() * 18), Color(0.82, 0.68, 0.35, 0.95 * a), 2.0)
		"baffles":  # mud dauber nests packed in the fins, a seal flapping loose
			for i in 5:
				var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
				draw_rect(Rect2(p, Vector2(18, 10 + rng.randf() * 14)), Color(0.45, 0.33, 0.2, 0.85 * a))
		"air_filter":  # caked gray with chaff
			draw_rect(r.grow(-6), Color(0.55, 0.52, 0.45, 0.55 * a))
			for i in 8:
				var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
				draw_line(p, p + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8)), Color(0.8, 0.72, 0.45, 0.8 * a), 2.0)
		"fuel_strainer", "water_fuel":  # rust sediment in the bowl, or clear water beads under the fuel
			var c := Color(0.55, 0.28, 0.1, 0.7 * a) if id == "fuel_strainer" else Color(0.75, 0.88, 1.0, 0.7 * a)
			for i in 7:
				draw_circle(r.position + Vector2(r.size.x * (0.3 + rng.randf() * 0.4), r.size.y * (0.6 + rng.randf() * 0.35)), 3.0 + rng.randf() * 3.0, c)
		"fuel_vent":  # a mud dauber nest plugging the vent
			draw_circle(r.get_center(), 14.0, Color(0.45, 0.33, 0.2, 0.9 * a))
		"storage":  # red streamers on the dehydrator plugs
			draw_line(r.get_center(), r.get_center() + Vector2(6, 36), Color(0.85, 0.12, 0.1, 0.95 * a), 4.0)
		"pre_oil":  # nothing to see from here: the dipstick tells it (look closer)
			pass
		"fod":  # a socket glinting behind the baffle
			draw_circle(r.get_center(), 9.0, Color(0.85, 0.86, 0.9, 0.9 * a))
			draw_circle(r.get_center(), 4.0, Color(0.2, 0.2, 0.22, 0.9 * a))

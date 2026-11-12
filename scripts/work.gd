extends Control
## A 2D work scene: one fixed, flat view of one spot on the plane, where you do the job for
## real. Pick a tool from your roll, take out every screw and bolt, lift panels off onto the
## bench, swap the part, clean up, then put it all back and tighten (and torque) everything.
##
## Each scene is data (see scenes()). Pieces:
##   fastener  screw/bolt/nut on a host piece: tight -> loose -> out, and back (torque: snug -> tight)
##   cover     anything that comes off and goes back: panels, cowling, safety wire, a jack, a lead
##   part      the thing being replaced: old -> out -> new (uses one part from the parts shed)
##   task      work with no part: cleaning, pulling a nest, adjusting turnbuckles
##   view      art only, chosen by main.view_art() from the job (a spark, a gauge, a melted mark)
## "needs" lists covers that must be off first; "with" lists covers that must be on (a tester
## hose, a DANGER tag). A cover goes back only once everything that needed it off is complete.
## Covers with "rest": "off" start on the bench and must end there (test gear, tags).
## Tasks: "note" shows a reading once done (main.reading), "turns_prop" turns the engine by hand
## (main.turn_prop may kick back), "trap" is a wrong move that only costs time and a lesson,
## "optional" isn't needed to finish. State lives in job.work[scene], so you can step away.
## Art: textures/work/<scene>_<piece>.png (parts: _old/_new); until it exists, placeholders.

signal finished

const W := 1000.0
const H := 560.0
const BENCH := Rect2(828, 14, 160, 532)
const TOOLS := {
	"hand": "Hands", "screwdriver": "Screwdriver", "ratchet": "Ratchet & sockets",
	"torque": "Torque wrench", "pliers": "Safety-wire pliers", "rag": "Shop rag",
	"tester": "Compression tester", "timing": "Timing light",
}
const FOD_CHANCE := 0.12  # chance a scene with a cowling has a socket you drop behind a baffle
const DAYS := {"loosen": 0.003, "tighten": 0.003, "torque": 0.004, "out": 0.001, "insert": 0.001,
	"off": 0.003, "on": 0.004, "remove": 0.008, "install": 0.012, "do": 0.012}
const SKIN := Color(0.93, 0.74, 0.22)
const METAL := Color(0.62, 0.63, 0.66)
const ENGINE := Color(0.3, 0.3, 0.32)
const RUBBER := Color(0.13, 0.13, 0.13)

var main  # main.gd: tools, inventory, time
var fault: String  # the scene id: a fault, a troubleshooting test, or "hand_prop"
var job: Dictionary
var title_name := ""
var part_name: String
var def: Dictionary
var els: Array = []
var by_id := {}
var st: Dictionary  # piece id -> state, plus "_paid"
var tool := "hand"
var hover := ""
var hold := 0.0
var pressing := false  # left button held down over the scene
var holding := false  # the new part is in your hand (picked up from the bench)
const PART_TILE := Rect2(836, 442, 144, 96)  # where the new part sits on the bench
var held_done := false  # an action finished under the held mouse: wait for release before the next
var tick_t := 0.0
var note := ""
var font := ThemeDB.fallback_font
var toolbar: HBoxContainer


func setup(m, scene_id: String, j: Dictionary) -> void:
	main = m
	job = j
	fault = scene_id
	var info: Dictionary = m.scene_info(scene_id)
	part_name = info.part
	title_name = info.name
	def = scenes()[scene_id]
	els = def.els.duplicate()
	if not job.work.has(scene_id):
		job.work[scene_id] = {"_paid": false}
	st = job.work[scene_id]
	if not st.has("_fod") and scene_id != "fod" and els.any(func(e): return e.id == "cowl"):
		st._fod = m.rng.randf() < FOD_CHANCE
	if st.get("_fod", false):  # drawn under the cowling: you only see it with the cowl off
		els.push_front(_task("fod", "Pick up the socket you dropped behind the baffle", Rect2(560, 236, 120, 50), "hand", ["cowl"],
			{"optional": true, "col": Color(0.7, 0.72, 0.78, 0.95)}))
	for e in els:
		by_id[e.id] = e
		if e.type != "view" and not st.has(e.id):  # also fills in pieces added since a save
			st[e.id] = {"fastener": "tight", "cover": e.get("start", "on"), "part": "old", "task": "todo"}[e.type]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # offsets too, or it stays 64x64 and misses clicks
	mouse_filter = Control.MOUSE_FILTER_STOP
	toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	add_child(toolbar)
	_build_toolbar()
	_preload_art()


func _build_toolbar() -> void:
	# The mouse becomes the tool in your hand, drawn big (96 px) so you always know what you hold.
	var cur := "res://textures/work/cursor_%s.png" % tool
	if ResourceLoader.exists(cur):
		var img: Image = load(cur).get_image()
		img.decompress()
		img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(10, 10))
	else:
		Input.set_custom_mouse_cursor(null)
	for c in toolbar.get_children():
		c.queue_free()
	for t in TOOLS:
		if t != "hand" and not main.tools.has(t):
			continue
		var b := Button.new()
		b.text = TOOLS[t]
		b.toggle_mode = true
		b.button_pressed = t == tool
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			tool = t
			_build_toolbar())
		var icon := "res://textures/work/tool_%s.png" % t
		if ResourceLoader.exists(icon):
			b.icon = load(icon)
			b.add_theme_constant_override("icon_max_width", 36)  # fixed size: long names squeezed it to nothing
			b.custom_minimum_size = Vector2(0, 48)
		toolbar.add_child(b)


func _origin() -> Vector2:
	return Vector2(maxf(0, (size.x - W) / 2), 72)


# ---------- rules ----------

func done() -> bool:
	return els.all(func(e): return _complete(e))


func _complete(e: Dictionary) -> bool:
	match e.type:
		"view": return true
		"fastener": return st[e.id] == "tight"
		"task": return st[e.id] == "done" or e.get("optional", false) or e.has("trap")
		"cover":
			if e.get("rest", "on") == "off":
				return st[e.id] == "off"
			return st[e.id] == "on" and _fasteners(e.id).all(func(f): return st[f.id] == "tight")
		_: return st[e.id] == "new" and _fasteners(e.id).all(func(f): return st[f.id] == "tight")


func _fasteners(host: String) -> Array:
	return els.filter(func(f): return f.type == "fastener" and f.host == host)


func _blocker(e: Dictionary) -> String:  # first cover in the way, or ""
	for n in e.get("needs", []):
		if st[n] == "on":
			return n
	return ""


func _present(host: Dictionary) -> bool:  # is the host piece there to screw into?
	return st[host.id] == "on" if host.type == "cover" else st[host.id] != "out"


## What clicking/holding on piece e does now: verb, tool, hold seconds, and why not if blocked.
func action(e: Dictionary) -> Dictionary:
	var a := {"verb": "", "tool": "hand", "hold": 0.0, "why": ""}
	if e.type == "view":
		return a
	var s: String = st[e.id]
	match e.type:
		"fastener":
			var host: Dictionary = by_id[e.host]
			if not _present(host):
				return a
			var b := _blocker(host)
			if b != "":
				a.why = "Take off the %s first." % by_id[b].name
				return a
			match s:
				"tight":
					a.merge({"verb": "loosen", "tool": e.tool, "hold": 0.7}, true)
				"snug":  # run down by hand tool; only the torque wrench finishes it
					a.merge({"verb": "torque", "tool": "torque", "hold": 1.0}, true)
				"loose":
					a.merge({"verb": "out", "tool": "hand"}, true)
					if tool == e.tool:
						a.merge({"verb": "tighten", "tool": e.tool, "hold": 0.7}, true)
				"out":
					a.verb = "insert"
		"cover":
			var b := _blocker(e)
			if b != "":
				a.why = "Take off the %s first." % by_id[b].name
				return a
			if s == "on":
				var left := _fasteners(e.id).filter(func(f): return st[f.id] != "out").size()
				if left > 0:
					a.why = "Remove its %d %s first." % [left, _fasteners(e.id)[0].kind + ("s" if left > 1 else "")]
					return a
				a.merge({"verb": "off", "tool": e.tool, "hold": 0.0 if e.tool == "hand" else 0.8}, true)
			elif e.get("rest", "on") == "off":  # test gear and tags: on to use it, off when done
				a.merge({"verb": "on", "tool": e.tool, "hold": 0.0 if e.tool == "hand" else 0.8}, true)
			else:
				var waiting := els.filter(func(x): return x.type not in ["fastener", "view"] and not x.get("optional", false) \
					and not x.has("trap") and e.id in x.get("needs", []) and not _complete(x))
				if waiting.size() > 0:
					a.why = "Finish the %s before this goes back." % waiting[0].name
					return a
				if _out_of(e) != "":
					a.why = _out_of(e)
					return a
				a.merge({"verb": "on", "tool": e.tool, "hold": 0.0 if e.tool == "hand" else 0.8}, true)
		"part":
			var b := _blocker(e)
			if b != "":
				a.why = "Take off the %s first." % by_id[b].name
				return a
			var t: String = e.get("tool", "hand")
			var hold_s := 0.0 if t == "hand" else 0.9
			if s == "old":
				var left := _fasteners(e.id).filter(func(f): return st[f.id] != "out").size()
				if left > 0:
					a.why = "Remove its %d %s first." % [left, _fasteners(e.id)[0].kind + ("s" if left > 1 else "")]
					return a
				for x in e.get("after", []):  # work that has to happen before it'll come out (soak a seized pin)
					if st[x] != "done":
						a.why = "%s first." % by_id[x].label
						return a
				a.merge({"verb": "remove", "tool": t, "hold": hold_s}, true)
			elif s == "out":
				var req := _unmet(e)
				if req != "":
					a.why = req
					return a
				if not st._paid and main.inventory.get(part_name, 0) <= 0:
					a.why = "You need a new %s. Get one from the parts shed." % part_name
					return a
				if not holding:
					a.why = "Pick up the new %s from the bench first (click it)." % part_name
					return a
				a.merge({"verb": "install", "tool": t, "hold": hold_s}, true)
		"task":
			if s == "todo":
				var b := _blocker(e)
				if b != "":
					a.why = "Take off the %s first." % by_id[b].name
					return a
				var req := _unmet(e)
				if req != "":
					a.why = req
					return a
				if _out_of(e) != "":
					a.why = _out_of(e)
					return a
				a.merge({"verb": "do", "tool": e.tool, "hold": e.get("hold", 1.5)}, true)
	return a


## Material this step uses up (safety wire, a cotter pin, penetrant) that you're out of, or "".
func _out_of(e: Dictionary) -> String:
	var item: String = e.get("uses", "")
	if item == "" or main.inventory.get(item, 0) > 0:
		return ""
	return "Out of %s. Buy it at a parts shed, or mail-order it from the hangar TOOLS box." % item.to_lower()


func _unmet(e: Dictionary) -> String:
	for r in e.get("requires", []):
		var x: Dictionary = by_id[r]
		if (x.type == "part" and st[r] != "new") or (x.type == "task" and st[r] != "done"):
			return ("Fit the new %s first." if x.type == "part" else "%s first.") % (x.name if x.type == "part" else x.label)
	for c in e.get("with", []):  # gear that has to be in place: a tester hose, a timing light
		if st[c] != "on":
			return "%s first." % by_id[c].get("verb_on", "Put on the " + by_id[c].name)
	return ""


func _verb_text(e: Dictionary, v: String) -> String:
	match v:
		"loosen": return "Loosen the " + e.kind
		"tighten": return "Tighten the " + e.kind
		"torque": return "Torque the %s to spec" % e.kind
		"out": return "Take the %s out (to the tray)" % e.kind
		"insert": return "Put a %s back in" % e.kind
		"off": return e.get("verb_off", "Take off the " + e.name)
		"on": return e.get("verb_on", "Put the %s back on" % e.name)
		"remove": return e.get("verb_remove", "Pull the old %s out" % e.name)
		"install": return e.get("verb_install", "Fit the new " + e.name)
		"do": return e.label
	return ""


## Applies a verb (tool already checked). Returns false if the job ended (owner gave up).
func perform(e: Dictionary, v: String) -> bool:
	match v:
		"loosen": st[e.id] = "loose"
		"tighten": st[e.id] = "snug" if e.get("torque", false) else "tight"
		"torque": st[e.id] = "tight"
		"out": st[e.id] = "out"
		"insert": st[e.id] = "loose"
		"off": st[e.id] = "off"
		"on": st[e.id] = "on"
		"remove": st[e.id] = "out"
		"install":
			if not st._paid:
				main.inventory[part_name] -= 1
				st._paid = true
			st[e.id] = "new"
			if not els.any(func(x): return x.type == "part" and st[x.id] != "new"):
				holding = false  # nothing left to fit (a set like 4 plugs stays in hand until all are in)
		"do":
			if e.has("trap"):  # the wrong move: it costs a little time and teaches why
				note = e.trap
				main.sound.tick()
				var ok: bool = main._work_time(0.03)
				queue_redraw()
				return ok
			st[e.id] = "done"
			st["_last"] = e.id
	var extra := 0.0
	if v == "do":
		note = main.reading(fault, e.id) if e.get("note", false) else ""
		if e.get("turns_prop", false):  # a hot magneto can fire it while you turn it by hand
			var kick: Array = main.turn_prop()
			if kick[0] != "":
				note = kick[0]
				extra = kick[1]
	if v in ["on", "do"] and e.get("uses", "") != "":
		main.inventory[e.uses] -= 1  # a fresh length of safety wire, a new cotter pin, a squirt of penetrant
	if v in ["torque", "install", "on"]:
		main.sound.clink()
	if not main._work_time(DAYS[v] + extra):
		return false
	hover = _hit(get_local_mouse_position() - _origin())  # what was under the cursor may have moved
	if done():
		if st.get("_fod", false) and st.get("fod", "") != "done":
			job["fod"] = true  # closed up with the socket still in there: it rattles on the run-up
			st._fod = false
		finished.emit()
	queue_redraw()
	return true


## Self-test helper: does the whole job with the tools you carry, no mouse. True if finished.
## Takes things apart until every part and task is done, then puts it all back. When a step
## needs a cover back on mid-job (oil refill with the drain plug in), it puts that one back.
func solve() -> bool:
	holding = true  # the test fits parts straight from the bench
	var placed := {}  # covers put back mid-job: don't take them off again
	for _i in 3000:
		if done():
			return true
		var apart := els.any(func(e): return (e.type == "part" and st[e.id] != "new") \
			or (e.type == "task" and st[e.id] != "done" and not e.has("trap")))
		var r := _solve_step(apart, placed)
		if r == "" and apart:
			r = _solve_step(false, placed)
			if r != "" and by_id[r].type == "cover":
				placed[r] = true
		if r == "":
			return false
		if r == "!":
			return false  # the owner gave up mid-job
	return done()


## One move: the first piece that can make progress. Returns its id, "" if none, "!" if the job ended.
func _solve_step(apart: bool, placed: Dictionary) -> String:
	var allowed := ["loosen", "out", "off", "remove", "install", "do"] if apart else ["insert", "tighten", "torque", "on"]
	for e in els:
		if e.type == "view" or e.has("trap"):
			continue
		for try_tool in ["torque", e.get("tool", "hand"), "hand"]:
			tool = try_tool
			var a := action(e)
			var verb_ok: bool = a.verb in allowed
			if e.type == "cover" and e.get("rest", "on") == "off":  # test gear goes on while working, off after
				verb_ok = a.verb != "" and (a.verb == "on") == apart
			if verb_ok and a.verb == "off" and placed.has(e.id):
				verb_ok = false
			if verb_ok and (a.tool == "hand" or main.tools.has(a.tool)) and a.tool == tool:
				if not perform(e, a.verb):
					return "!"
				return e.id
	return ""


# ---------- input ----------

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := _hit(ev.position - _origin())
		if h != hover:
			hover = h
			hold = 0.0
			note = ""
		queue_redraw()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var bp: Vector2 = ev.position - _origin()
		if ev.pressed and part_name != "" and PART_TILE.has_point(bp):  # the new part on the bench
			var have_part: bool = st._paid or main.inventory.get(part_name, 0) > 0
			var waiting: bool = els.any(func(x): return x.type == "part" and st[x.id] != "new")
			if have_part and waiting:
				holding = not holding
				note = ("Holding the new %s. Click where it goes." % part_name) if holding else "Put it back on the bench."
			elif not have_part:
				note = "No new %s on the bench. Buy one at the parts shed (or mail-order it)." % part_name
			queue_redraw()
			return
		if ev.pressed and hover != "":
			var e: Dictionary = by_id[hover]
			var a := action(e)
			note = ""
			if a.verb == "":
				note = a.why
			elif a.tool != tool:
				note = "Use the %s for that%s." % [TOOLS[a.tool],
					"" if a.tool == "hand" or main.tools.has(a.tool) else " (it's in the hangar toolbox)"]
			elif a.hold == 0.0:
				held_done = true
				perform(e, a.verb)
		pressing = ev.pressed
		if not ev.pressed:
			hold = 0.0
			held_done = false
		queue_redraw()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var keys := TOOLS.keys().filter(func(t): return t == "hand" or main.tools.has(t))
		var i := (keys.find(tool) + (1 if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1) + keys.size()) % keys.size()
		tool = keys[i]
		_build_toolbar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Input.set_custom_mouse_cursor(null)  # back to the normal pointer outside the scene
	if what == NOTIFICATION_RESIZED and toolbar:
		toolbar.position = _origin() + Vector2(0, H + 8)


var _settle := 3  # redraw the first few frames so freshly uploaded art shows without a mouse move


func _process(delta: float) -> void:
	if _settle > 0:
		_settle -= 1
		queue_redraw()
	if hover == "" or held_done or not pressing:
		return
	var e: Dictionary = by_id[hover]
	var a := action(e)
	if a.verb == "" or a.hold == 0.0 or a.tool != tool:
		return
	hold += delta
	tick_t -= delta
	if tick_t <= 0.0:  # ratchet clicks while you turn
		main.sound.tick()
		tick_t = 0.11
	if hold >= a.hold:
		hold = 0.0
		held_done = true
		perform(e, a.verb)
	queue_redraw()


## Covers lying on the bench, as clickable rows (click one to put it back).
func _bench_rows() -> Array:
	var out := []
	var y := BENCH.position.y + 56
	for e in els:
		if (e.type == "cover" and st[e.id] == "off") or (e.type == "part" and st[e.id] == "out"):
			out.append([Rect2(BENCH.position.x + 4, y, BENCH.size.x - 8, 22), e])
			y += 24
	return out


func _hit(p: Vector2) -> String:
	for row in _bench_rows():
		if row[0].has_point(p) and row[1].type == "cover":
			return row[1].id
	for i in range(els.size() - 1, -1, -1):
		var e: Dictionary = els[i]
		if e.type == "view" or not _visible(e):
			continue
		if e.type == "fastener":
			if p.distance_to(e.pos) < 15:
				return e.id
		elif e.rect.has_point(p):
			return e.id
	return ""


func _visible(e: Dictionary) -> bool:
	match e.type:
		"fastener":
			var host: Dictionary = by_id[e.host]
			return _visible(host) and _present(host)
		"cover": return st[e.id] == "on"
		"task":
			if e.has("show_after") and st[e.show_after] != "done":
				return false
			if e.has("hide_after") and st[e.hide_after] == "done":
				return false
			return st[e.id] == "todo" or e.get("fixture", false)  # fixtures (turnbuckles) stay put once done
	return true


# ---------- drawing (placeholders until textures/work/ art exists) ----------

var _texcache := {}


## Textures are loaded once and kept: one first loaded mid-draw shows up blank for that frame.
func _tex(name: String) -> Texture2D:
	if not _texcache.has(name):
		var p := "res://textures/%s.png" % name
		_texcache[name] = load(p) if ResourceLoader.exists(p) else null
	return _texcache[name]


func _preload_art() -> void:
	for n in ["work/%s_bg" % fault, "work/screw", "work/bolt", "work/nut", "icon_" + fault]:
		_tex(n)
	for e in els:
		if e.type == "view":
			continue
		for n in ["work/%s_%s" % [fault, e.id], "work/%s_%s_old" % [fault, e.id], "work/%s_%s_new" % [fault, e.id], e.get("tex", "")]:
			if n != "":
				_tex(n)


func _draw() -> void:
	var o := _origin()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.08, 0.07))  # the work fills the screen; HUD stays hidden
	draw_string(font, Vector2(o.x + W - 220, 30), "Day %d" % floori(main.day), HORIZONTAL_ALIGNMENT_RIGHT, 220, 16, Color(0.85, 0.82, 0.75))
	draw_set_transform(o)
	var bg := _tex("work/%s_bg" % fault)
	if bg:
		draw_texture_rect(bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.2, 0.19, 0.18))
		for d in def.get("deco", []):
			_fill(d[0], d[1], d[2], d[3] if d.size() > 3 else "rect")
	for e in els:
		if _visible(e):
			_draw_piece(e)
	_draw_bench()
	if hover != "":
		_draw_hover(by_id[hover])
	_draw_notes()
	draw_set_transform(Vector2.ZERO)
	draw_string(font, Vector2(o.x, 30), "%s  -  %s" % [title_name, def.title], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.98, 0.94, 0.85))
	draw_string(font, Vector2(o.x, 54), "Hover a piece to see what it needs. Hold the mouse to turn. Wheel: switch tools. Esc: step away (work is kept).",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.85, 0.82, 0.75))
	if holding and _tex("icon_" + fault):  # the part rides along with the cursor until it's fitted
		draw_texture_rect(_tex("icon_" + fault), Rect2(get_local_mouse_position() + Vector2(30, -10), Vector2(64, 64)), false)
	# What's in your hand, riding just under the cursor.
	var mp := get_local_mouse_position() + Vector2(34, 78)
	var tname: String = TOOLS[tool]
	var tw := font.get_string_size(tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_rect(Rect2(mp - Vector2(6, 16), Vector2(tw + 12, 22)), Color(0.1, 0.08, 0.05, 0.85))
	draw_string(font, mp, tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.85, 0.35))


func _fill(r: Rect2, texname: String, tint: Color, shape := "rect") -> void:
	var t := _tex(texname) if texname != "" else null
	if shape == "circle":
		draw_circle(r.get_center(), r.size.x / 2, tint)
		draw_arc(r.get_center(), r.size.x / 2, 0, TAU, 48, tint.darkened(0.4), 2.0)
		return
	if t:
		draw_texture_rect(t, r, true, tint)
	else:
		draw_rect(r, tint)
	draw_rect(r, tint.darkened(0.45), false, 2.0)


## Readings from tests you've done, on a strip of notebook paper in the corner of the scene.
func _draw_notes() -> void:
	var lines: PackedStringArray = []
	for e in els:
		if e.type == "task" and e.get("note", false) and st[e.id] == "done":
			lines.append(main.reading(fault, e.id))
	if lines.is_empty():
		return
	var n := mini(lines.size(), 7)
	var r := Rect2(8, H - 12 - n * 18, 600, n * 18 + 6)
	draw_rect(r, Color(0.98, 0.95, 0.85, 0.92))
	draw_rect(r, Color(0.4, 0.3, 0.2), false, 1.0)
	for i in n:
		draw_string(font, r.position + Vector2(8, 16 + i * 18), lines[lines.size() - n + i], HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 13, Color(0.15, 0.1, 0.05))


func _draw_piece(e: Dictionary) -> void:
	if e.type == "view":
		var v: String = main.view_art(fault, e.id)
		if v == "":
			return
		var t := _tex(v)
		if t:
			draw_texture_rect(t, e.rect, false)
		else:
			draw_rect(e.rect, Color(0.95, 0.88, 0.55, 0.85))
			_label(e.rect, v.get_file().trim_prefix(fault + "_").replace("_", " "))
		return
	var s: String = st[e.id]
	match e.type:
		"cover":
			var art := _tex("work/%s_%s" % [fault, e.id])
			if art:
				draw_texture_rect(art, e.rect, false)
				return
			_fill(e.rect, e.get("tex", "plane_body_worn"), e.get("col", SKIN), e.get("shape", "rect"))
			_label(e.rect, e.name)
		"part":
			if s == "out":  # the bare spot shows through; a faint outline says where the new one goes
				var painted := _tex("work/%s_bg" % fault) != null
				if not painted:
					draw_rect(e.rect, Color(0, 0, 0, 0.35))
				draw_dashed_line(e.rect.position, e.rect.position + Vector2(e.rect.size.x, 0), Color(1, 1, 1, 0.5), 2.0, 8.0)
				draw_dashed_line(e.rect.end, e.rect.end - Vector2(e.rect.size.x, 0), Color(1, 1, 1, 0.5), 2.0, 8.0)
				if not painted:
					_label(e.rect, "(empty: new %s goes here)" % e.name)
				return
			var art := _tex("work/%s_%s_%s" % [fault, e.id, s])
			if art:
				draw_texture_rect(art, e.rect, false)
				return  # the painting speaks for itself
			else:
				var c: Color = e.get("col", METAL)
				_fill(e.rect, e.get("tex", "metal_steel"), c.darkened(0.25) if s == "old" else c.lightened(0.1), e.get("shape", "rect"))
				var icon := _tex("icon_" + fault)
				if icon:
					var side := minf(minf(e.rect.size.x, e.rect.size.y) * 0.8, 72)
					draw_texture_rect(icon, Rect2(e.rect.get_center() - Vector2(side, side) / 2, Vector2(side, side)), false,
						Color(0.75, 0.55, 0.4) if s == "old" else Color.WHITE)
			_label(e.rect, ("Old " if s == "old" else "New ") + e.name)
		"task":
			var name := "work/%s_%s" % [fault, e.id]
			if e.get("dyn", false):  # art picked by what the test shows (a plug's condition)
				name = main.view_art(fault, e.id) if s == "done" else ""
			elif e.get("art_done", false):
				name = name if s == "done" else ""
			var art := _tex(name) if name != "" else null
			if art:
				draw_texture_rect(art, e.rect, false)
				return
			if (e.get("dyn", false) or e.get("art_done", false)) and s == "done":
				_fill(e.rect, "", Color(0.85, 0.82, 0.72, 0.9))
				_label(e.rect, main.reading(fault, e.id) if e.get("dyn", false) else e.name)
				return
			if _tex("work/%s_bg" % fault):  # painted scene: a quiet hotspot, not a big block
				draw_rect(e.rect, Color(0.05, 0.04, 0.03, 0.45))
				draw_rect(e.rect, Color(1, 0.9, 0.6, 0.7), false, 1.5)
				var sz := font.get_string_size(e.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
				draw_string(font, Vector2(e.rect.get_center().x - minf(sz.x, e.rect.size.x) / 2, e.rect.get_center().y + 5), e.label,
					HORIZONTAL_ALIGNMENT_LEFT, e.rect.size.x, 13, Color(1, 0.95, 0.85))
				return
			_fill(e.rect, e.get("tex", ""), e.get("col", Color(0.15, 0.12, 0.08, 0.8)))
			_label(e.rect, e.label)
		"fastener":
			_draw_fastener(e, s)


func _draw_fastener(e: Dictionary, s: String) -> void:
	var p: Vector2 = e.pos
	if s == "out":
		draw_circle(p, 5, Color(0.05, 0.05, 0.05))  # empty hole
		return
	var lift := Vector2(-3, -3) if s == "loose" else Vector2.ZERO
	var r := 9.0 if e.kind == "screw" else 11.0
	if s == "loose":
		draw_circle(p + Vector2(2, 2), r, Color(0, 0, 0, 0.4))  # backed out: casts a shadow
	var head := Color(0.78, 0.78, 0.8) if s != "loose" else Color(0.9, 0.9, 0.92)
	var sprite := _tex("work/" + e.kind)
	if sprite:  # painted head; loose ones sit raised and a touch brighter
		draw_texture_rect(sprite, Rect2(p + lift - Vector2(12, 12), Vector2(24, 24)), false, Color(1.15, 1.15, 1.15) if s == "loose" else Color.WHITE)
	elif e.kind == "screw":
		draw_circle(p + lift, r, head)
		draw_line(p + lift + Vector2(-6, -2), p + lift + Vector2(6, 2), Color(0.2, 0.2, 0.22), 2.5)
	else:
		var pts := PackedVector2Array()
		for i in 6:
			pts.append(p + lift + Vector2.from_angle(i * TAU / 6 + 0.3) * r)
		draw_colored_polygon(pts, head)
		pts.append(pts[0])
		draw_polyline(pts, Color(0.25, 0.25, 0.27), 1.5)
	if s == "snug":  # tightened by hand tool, still needs the torque wrench
		draw_arc(p, r + 3, 0, TAU, 20, Color(0.95, 0.75, 0.15), 2.0)


func _label(r: Rect2, t: String) -> void:
	var sz := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, Vector2(r.get_center().x - sz.x / 2, r.end.y - 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.08, 0.06))


func _draw_bench() -> void:
	var painted := _tex("work/%s_bg" % fault) != null  # the background already has a wooden bench
	draw_rect(BENCH, Color(0.12, 0.08, 0.05, 0.45) if painted else Color(0.36, 0.27, 0.18))
	draw_rect(BENCH, Color(0.2, 0.14, 0.08), false, 2.0)
	var y := BENCH.position.y + 22
	draw_string(font, Vector2(BENCH.position.x + 10, y), "BENCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.95, 0.88, 0.7))
	var tray := els.filter(func(f): return f.type == "fastener" and st[f.id] == "out").size()
	y += 22
	draw_string(font, Vector2(BENCH.position.x + 10, y), "Magnetic tray: %d" % tray, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.85, 0.75))
	for row in _bench_rows():
		var e: Dictionary = row[1]
		var r: Rect2 = row[0]
		draw_rect(r, Color(0.45, 0.35, 0.24) if e.type == "cover" else Color(0.3, 0.22, 0.15))
		var t: String = ("Old " + e.name + " (scrap)") if e.type == "part" else e.name
		draw_string(font, r.position + Vector2(6, 16), t, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10, 13, Color(0.95, 0.9, 0.8))
	var have: int = main.inventory.get(part_name, 0) if part_name != "" else 0
	if part_name != "":  # the new part, sitting on the bench: click to pick it up
		var r := PART_TILE
		draw_rect(r, Color(0.95, 0.85, 0.4, 0.35) if holding else Color(0.2, 0.14, 0.08, 0.75))
		draw_rect(r, Color(0.95, 0.8, 0.4) if holding else Color(0.55, 0.42, 0.25), false, 2.0)
		var icon := _tex("icon_" + fault)
		if icon and (have > 0 or st._paid) and not holding:
			draw_texture_rect(icon, Rect2(r.position + Vector2(r.size.x / 2 - 26, 4), Vector2(52, 52)), false)
		# Name and status on separate lines: long names ("Door pin & cotter") were clipped mid-word.
		draw_string(font, r.position + Vector2(6, 72), "New " + part_name, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 12, Color(0.95, 0.9, 0.8))
		var status := "none: buy one" if have == 0 and not st._paid else ("in your hand" if holding else ("fitted" if st._paid else "click to pick up"))
		draw_string(font, r.position + Vector2(6, 88), status, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 12,
			Color(0.95, 0.8, 0.45) if have == 0 and not st._paid else Color(0.9, 0.85, 0.75))


func _draw_hover(e: Dictionary) -> void:
	if e.type == "fastener":
		draw_arc(e.pos, 16, 0, TAU, 24, Color(1, 1, 0.6), 2.0)
	else:
		draw_rect(e.rect, Color(1, 1, 0.6), false, 2.0)
	var a := action(e)
	var line: String = e.name if e.type != "fastener" else by_id[e.host].name + " " + e.kind
	if e.type == "task":
		line = e.label
		if st[e.id] == "done" and e.get("note", false):
			line = main.reading(fault, e.id)
	var how := ""
	if a.verb != "":
		how = "%s  [%s%s]" % [_verb_text(e, a.verb), TOOLS[a.tool], ", hold" if a.hold > 0 else ""]
		if a.tool != "hand" and not main.tools.has(a.tool):
			how += "  - get it from the hangar toolbox"
	else:
		how = a.why if a.why != "" else "Nothing to do here."
	if note != "":
		how = note
	var m := get_local_mouse_position() - _origin() + Vector2(16, 18)
	var w := maxf(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, font.get_string_size(how, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x) + 16
	m.x = minf(m.x, W - w)
	draw_rect(Rect2(m, Vector2(w, 42)), Color(0.98, 0.95, 0.85, 0.95))
	draw_string(font, m + Vector2(8, 16), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.15, 0.1, 0.05))
	draw_string(font, m + Vector2(8, 34), how, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.45, 0.1, 0.08))
	if hold > 0.0 and a.hold > 0.0:
		var c: Vector2 = e.pos if e.type == "fastener" else e.rect.get_center()
		draw_arc(c, 22, -PI / 2, -PI / 2 + TAU * hold / a.hold, 32, Color(0.95, 0.75, 0.15), 4.0)


# ---------- the scenes ----------

static func _cover(id: String, name: String, r: Rect2, needs := [], o := {}) -> Dictionary:
	var e := {"id": id, "type": "cover", "name": name, "rect": r, "needs": needs, "tool": "hand"}
	e.merge(o, true)
	return e


static func _part(id: String, name: String, r: Rect2, needs := [], o := {}) -> Dictionary:
	var e := {"id": id, "type": "part", "name": name, "rect": r, "needs": needs}
	e.merge(o, true)
	return e


static func _task(id: String, label: String, r: Rect2, tool: String, needs := [], o := {}) -> Dictionary:
	var e := {"id": id, "type": "task", "name": label, "label": label, "rect": r, "tool": tool, "needs": needs}
	e.merge(o, true)
	return e


## n fasteners evenly round a circle.
static func _ring(host: String, c: Vector2, r: float, n: int, kind: String, tool: String, torque := false, a0 := 0.0) -> Array:
	var out := []
	for i in n:
		out.append({"id": "%s_f%d" % [host, i], "type": "fastener", "host": host, "kind": kind, "tool": tool,
			"torque": torque, "pos": c + Vector2.from_angle(a0 + i * TAU / n) * r})
	return out


## Fasteners at given points.
static func _at(host: String, pts: Array, kind: String, tool: String) -> Array:
	var out := []
	for i in pts.size():
		out.append({"id": "%s_f%d" % [host, i], "type": "fastener", "host": host, "kind": kind, "tool": tool, "torque": false, "pos": pts[i]})
	return out


## Fasteners at the four corners of a rect, inset.
static func _corners(host: String, r: Rect2, kind: String, tool: String, inset := 16.0) -> Array:
	var g := r.grow(-inset)
	return _at(host, [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)], kind, tool)


static func _cowl(needs := []) -> Array:  # the side cowling, same on every engine job
	var r := Rect2(40, 40, 760, 300)
	return [_cover("cowl", "Cowling", r, needs, {"tex": "cowling_metal", "col": SKIN})] + _at("cowl",
		[Vector2(60, 60), Vector2(420, 52), Vector2(780, 60), Vector2(780, 320), Vector2(420, 328), Vector2(60, 320)], "screw", "screwdriver")


static var _scenes := {}


## Tools and materials a repair can't be finished without: {tool ids} and {material: uses}.
## Torqued fasteners need the torque wrench as well as their own tool.
static func needs_for(fault_id: String) -> Array:
	var tools := {}
	var mats := {}
	for e in scenes()[fault_id].els:
		tools[e.get("tool", "hand")] = true
		if e.get("torque", false):
			tools["torque"] = true
		if e.has("uses"):
			mats[e.uses] = mats.get(e.uses, 0) + 1
	tools.erase("hand")
	return [tools, mats]


static func scenes() -> Dictionary:
	if _scenes.size() > 0:
		return _scenes
	var engine_deco := [[Rect2(30, 30, 780, 500), "", Color(0.16, 0.16, 0.17)], [Rect2(80, 80, 680, 260), "metal_steel", ENGINE]]
	var s := {}

	# Propeller, nose seen head-on: spinner screws, safety wire, six torqued bolts.
	var hub := Vector2(410, 280)
	s.propeller = {"title": "Nose, head-on", "deco": [[Rect2(250, 120, 320, 320), "", SKIN.darkened(0.3), "circle"]],
		"els": [_part("prop", "Propeller", Rect2(40, 245, 740, 70), ["spinner", "wire"], {"tex": "prop_wood", "col": Color(0.62, 0.4, 0.2)})]
		+ _ring("prop", hub, 52, 6, "bolt", "ratchet", true)
		+ [_cover("wire", "Safety wire", Rect2(hub - Vector2(70, 70), Vector2(140, 140)), ["spinner"],
			{"tool": "pliers", "col": Color(0.75, 0.75, 0.78, 0.35), "verb_off": "Cut the safety wire", "verb_on": "Safety-wire the bolts", "uses": "Safety wire"}),
		_cover("spinner", "Prop face plate", Rect2(hub - Vector2(105, 105), Vector2(210, 210)), [], {"col": Color(0.85, 0.86, 0.88)})]
		+ _ring("spinner", hub, 88, 4, "screw", "screwdriver", false, PI / 4)}

	# Spark plugs, engine left side: cowling, four ignition leads, four plugs.
	var plugs := []
	for i in 4:
		var x := 150 + i * 170
		plugs += [_part("plug%d" % i, "Plug %d" % (i + 1), Rect2(x, 160, 60, 110), ["cowl", "lead%d" % i], {"tool": "ratchet", "col": Color(0.85, 0.85, 0.8),
			"requires": ["gap"], "verb_install": "Fit the new plug, new gasket, 300-360 in-lb"}),
			_cover("lead%d" % i, "Lead %d" % (i + 1), Rect2(x - 10, 130, 80, 50), ["cowl"], {"col": Color(0.55, 0.12, 0.1), "verb_off": "Pull the ignition lead", "verb_on": "Push the lead back on"})]
	s.spark_plugs = {"title": "Engine, left side", "deco": engine_deco, "els": [_task("gap", "Gap the new plugs .016-.021 in", Rect2(150, 290, 520, 36), "hand", ["cowl"], {"hold": 1.5})]
		+ plugs + _cowl()}

	# Oil leak: wipe the mess, rocker cover off, scrape, new gasket.
	var rc := Rect2(200, 130, 440, 150)
	s.oil_leak = {"title": "Engine, left side", "deco": engine_deco, "els": [
		_part("gasket", "Rocker cover gasket", rc.grow(-20), ["cowl", "rocker"], {"col": Color(0.75, 0.35, 0.15), "requires": ["scrape"]}),
		_task("scrape", "Scrape off the old gasket", Rect2(rc.position.x + 20, rc.end.y - 50, rc.size.x - 40, 30), "rag", ["cowl", "rocker"], {"hold": 2.0}),
		_cover("rocker", "Rocker cover", rc, ["cowl"], {"tex": "metal_steel", "col": METAL})]
		+ _at("rocker", [rc.position + Vector2(18, 18), Vector2(rc.get_center().x, rc.position.y + 18), Vector2(rc.end.x - 18, rc.position.y + 18),
			rc.end - Vector2(18, 18), Vector2(rc.get_center().x, rc.end.y - 18), Vector2(rc.position.x + 18, rc.end.y - 18)], "bolt", "ratchet")
		+ [_task("wipe", "Wipe the oil off the engine", Rect2(120, 290, 600, 40), "rag", ["cowl"], {"tex": "oil_puddle", "col": Color(0.2, 0.15, 0.05, 0.9), "hold": 2.0})]
		+ _cowl()}

	# Bird nest: reach in and pull it out by the handful, then clean up the straw.
	s.bird_nest = {"title": "Engine, top", "deco": engine_deco, "els": [
		_task("straw", "Sweep out the loose straw", Rect2(140, 250, 540, 60), "rag", ["cowl"], {"requires": ["nest"], "col": Color(0.7, 0.6, 0.35, 0.8)}),
		_task("nest", "Pull the nest out", Rect2(300, 110, 240, 140), "hand", ["cowl"], {"tex": "bark", "col": Color(0.75, 0.6, 0.4), "hold": 2.5})] + _cowl()}

	# Starter: cable nut off, two mount bolts, swap.
	var sr := Rect2(130, 200, 260, 110)
	s.starter = {"title": "Engine, lower left", "deco": engine_deco, "els": [
		_part("starter", "Starter motor", sr, ["cowl", "cable"], {"col": Color(0.25, 0.25, 0.28)})]
		+ _at("starter", [sr.position + Vector2(20, 20), Vector2(sr.position.x + 20, sr.end.y - 20)], "bolt", "ratchet")
		+ [_cover("cable", "Starter cable", Rect2(400, 230, 260, 40), ["cowl"], {"col": Color(0.55, 0.12, 0.1)})]
		+ _at("cable", [Vector2(420, 250)], "nut", "ratchet") + _cowl()}

	# Magneto: harness cap off, two clamp nuts, swap, time it.
	var mr := Rect2(470, 130, 220, 170)
	s.magneto = {"title": "Engine, rear accessory case", "deco": engine_deco, "els": [
		_task("timing", "Set the magneto timing", Rect2(130, 260, 260, 50), "screwdriver", ["cowl"], {"fixture": true, "requires": ["magneto"], "col": Color(0.2, 0.3, 0.2, 0.85), "hold": 3.0}),
		_part("magneto", "Magneto", mr, ["cowl", "cap"], {"col": Color(0.15, 0.15, 0.17)})]
		+ _at("magneto", [Vector2(mr.position.x - 14, mr.end.y - 30), Vector2(mr.end.x + 14, mr.end.y - 30)], "nut", "ratchet")
		+ [_cover("cap", "Harness cap", Rect2(mr.position + Vector2(30, 20), Vector2(160, 70)), ["cowl"], {"col": Color(0.2, 0.2, 0.5)})]
		+ _at("cap", [mr.position + Vector2(44, 55), mr.position + Vector2(176, 55)], "screw", "screwdriver") + _cowl()}

	# Flat tire: jack the wing, hubcap, cotter pin, axle nut, swap, pump up, lower.
	var wc := Vector2(400, 300)
	var wheel_deco := [[Rect2(0, 470, 820, 90), "gravel", Color(0.7, 0.68, 0.62)], [Rect2(380, 40, 40, 160), "", SKIN.darkened(0.2)]]
	s.tire = {"title": "Left main wheel, outside", "deco": wheel_deco, "els": [
		_task("pump", "Pump to 35 psi to seat the beads, let down to 15", Rect2(600, 380, 200, 70), "hand", [], {"requires": ["tire"], "col": Color(0.4, 0.15, 0.1, 0.9), "hold": 2.5}),
		_part("tire", "Tire & tube", Rect2(wc - Vector2(170, 170), Vector2(340, 340)), ["jack", "hubcap", "pin"], {"shape": "circle", "col": RUBBER})]
		+ _at("tire", [wc], "nut", "ratchet")
		+ [_cover("pin", "Cotter pin", Rect2(wc - Vector2(22, 40), Vector2(44, 24)), ["hubcap"], {"tool": "pliers", "col": Color(0.8, 0.7, 0.3), "verb_off": "Pull the cotter pin", "verb_on": "Fit a new cotter pin and bend it", "uses": "Cotter pin"}),
		_cover("hubcap", "Hubcap", Rect2(wc - Vector2(70, 70), Vector2(140, 140)), [], {"shape": "circle", "col": METAL})]
		+ _ring("hubcap", wc, 52, 3, "screw", "screwdriver", false, -PI / 2)
		+ [_cover("jack", "Jack", Rect2(80, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Jack the wing up", "verb_on": "Lower the plane back down"})]}

	# Brake disc: jack, cotter pin, axle nut, wheel off, caliper off, new disc.
	var bc := Vector2(330, 290)
	s.brakes = {"title": "Right main wheel, inside", "deco": wheel_deco, "els": [
		_part("disc", "Brake disc", Rect2(bc - Vector2(120, 120), Vector2(240, 240)), ["wheel", "caliper"], {"shape": "circle", "col": Color(0.55, 0.45, 0.4)})]
		+ _ring("disc", bc, 80, 4, "bolt", "ratchet", false, PI / 4)
		+ [_cover("wheel", "Wheel", Rect2(bc - Vector2(160, 160), Vector2(320, 320)), ["jack", "pin"], {"shape": "circle", "col": RUBBER})]
		+ _at("wheel", [bc], "nut", "ratchet")
		+ [_cover("pin", "Cotter pin", Rect2(bc - Vector2(22, 40), Vector2(44, 24)), [], {"tool": "pliers", "col": Color(0.8, 0.7, 0.3), "verb_off": "Pull the cotter pin", "verb_on": "Fit a new cotter pin and bend it", "uses": "Cotter pin"}),
		_cover("caliper", "Brake caliper", Rect2(520, 160, 120, 150), [], {"col": Color(0.6, 0.15, 0.12)})]
		+ _at("caliper", [Vector2(580, 185), Vector2(580, 285)], "bolt", "ratchet")
		+ [_cover("jack", "Jack", Rect2(650, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Jack the wing up", "verb_on": "Lower the plane back down"})]}

	# Battery: hatch, negative off first, positive, hold-down strap, swap.
	var br := Rect2(260, 170, 300, 200)
	s.battery = {"title": "Battery bay, right side", "deco": [[Rect2(40, 40, 760, 480), "plane_body_worn", SKIN.darkened(0.15)], [Rect2(200, 120, 420, 320), "", Color(0.12, 0.12, 0.12)]],
		"els": [_part("battery", "Battery", br, ["hatch", "neg", "pos", "strap"], {"col": Color(0.15, 0.15, 0.15)}),
		_cover("strap", "Hold-down strap", Rect2(br.position.x - 20, br.get_center().y - 14, br.size.x + 40, 28), ["hatch"], {"col": Color(0.5, 0.5, 0.52)})]
		+ _at("strap", [Vector2(br.position.x - 8, br.get_center().y), Vector2(br.end.x + 8, br.get_center().y)], "nut", "ratchet")
		+ [_cover("pos", "Positive (+) cable", Rect2(br.end.x - 90, br.position.y - 20, 70, 50), ["hatch", "neg"], {"tool": "ratchet", "col": Color(0.75, 0.12, 0.1), "verb_off": "Undo the + terminal", "verb_on": "Do up the + terminal"}),
		_cover("neg", "Negative (-) cable", Rect2(br.position.x + 20, br.position.y - 20, 70, 50), ["hatch"], {"tool": "ratchet", "col": Color(0.1, 0.1, 0.1), "verb_off": "Undo the - terminal (always first off)", "verb_on": "Do up the - terminal (always last on)"}),
		_cover("hatch", "Access hatch", Rect2(180, 100, 460, 360), [], {"col": SKIN})]
		+ _corners("hatch", Rect2(180, 100, 460, 360), "screw", "screwdriver")}

	# Fuel line: fuel OFF, wing-root fairing, two B-nuts, swap, mop up, fuel ON.
	var fr := Rect2(120, 150, 560, 230)
	s.fuel_line = {"title": "Firewall, lower cowl open", "deco": [[Rect2(20, 40, 790, 480), "plane_body_worn", SKIN.darkened(0.2)]],
		"els": [_task("mop", "Wipe up the spilled fuel", Rect2(140, 330, 520, 40), "rag", ["fairing"], {"col": Color(0.3, 0.45, 0.8, 0.6), "hold": 2.0}),
		_part("line", "Fuel line", Rect2(180, 240, 440, 34), ["fairing", "valve"], {"col": Color(0.3, 0.3, 0.75)})]
		+ _at("line", [Vector2(190, 257), Vector2(610, 257)], "nut", "ratchet")
		+ [_cover("fairing", "Lower cowl panel", fr, [], {"col": SKIN})]
		+ _at("fairing", [fr.position + Vector2(16, 16), Vector2(fr.get_center().x, fr.position.y + 16), Vector2(fr.end.x - 16, fr.position.y + 16),
			fr.end - Vector2(16, 16), Vector2(fr.get_center().x, fr.end.y - 16), Vector2(fr.position.x + 16, fr.end.y - 16)], "screw", "screwdriver")
		+ [_cover("valve", "Fuel selector", Rect2(700, 420, 100, 90), [], {"col": Color(0.6, 0.1, 0.1), "verb_off": "Turn the fuel OFF", "verb_on": "Turn the fuel back ON"})]}

	# Windshield: three retainer strips, scrape sealant, new screen.
	var ws := Rect2(140, 90, 540, 330)
	s.windshield = {"title": "Windshield, from the front", "deco": [[Rect2(60, 60, 700, 420), "plane_body_worn", SKIN.darkened(0.15)]],
		"els": [_part("screen", "Windshield", ws, ["top", "left", "right"], {"col": Color(0.7, 0.8, 0.85, 0.55), "requires": ["sealant"]}),
		_task("sealant", "Scrape off the old sealant", Rect2(ws.position.x, ws.end.y - 30, ws.size.x, 26), "rag", ["top", "left", "right"], {"hold": 2.0}),
		_cover("top", "Top retainer strip", Rect2(ws.position.x - 10, ws.position.y - 26, ws.size.x + 20, 30), [], {"col": METAL}),
		_cover("left", "Left retainer strip", Rect2(ws.position.x - 30, ws.position.y, 30, ws.size.y), [], {"col": METAL}),
		_cover("right", "Right retainer strip", Rect2(ws.end.x, ws.position.y, 30, ws.size.y), [], {"col": METAL})]
		+ _at("top", [Vector2(170, 75), Vector2(300, 75), Vector2(410, 75), Vector2(520, 75), Vector2(650, 75)], "screw", "screwdriver")
		+ _at("left", [Vector2(125, 140), Vector2(125, 255), Vector2(125, 370)], "screw", "screwdriver")
		+ _at("right", [Vector2(695, 140), Vector2(695, 255), Vector2(695, 370)], "screw", "screwdriver")}

	# Rudder cables: inspection plate, cut safety wire, new cable, tension both turnbuckles, re-wire.
	var pr := Rect2(80, 110, 660, 320)
	s.control_cables = {"title": "Tail, inspection panel", "deco": [[Rect2(20, 60, 790, 420), "plane_body_worn", SKIN.darkened(0.2)], [pr.grow(-10), "", Color(0.1, 0.09, 0.08)]],
		"els": [_part("cable", "Rudder cable", Rect2(100, 255, 620, 14), ["plate", "wire_a", "wire_b"], {"col": Color(0.7, 0.7, 0.72)}),
		_task("tb_a", "Tension the left turnbuckle", Rect2(180, 230, 120, 60), "screwdriver", ["plate", "wire_a"], {"fixture": true, "requires": ["cable"], "col": Color(0.6, 0.55, 0.3, 0.9), "hold": 2.5}),
		_task("tb_b", "Tension the right turnbuckle", Rect2(520, 230, 120, 60), "screwdriver", ["plate", "wire_b"], {"fixture": true, "requires": ["cable"], "col": Color(0.6, 0.55, 0.3, 0.9), "hold": 2.5}),
		_cover("wire_a", "Left safety wire", Rect2(170, 220, 140, 80), ["plate"], {"tool": "pliers", "col": Color(0.75, 0.75, 0.78, 0.35), "verb_off": "Cut the safety wire", "verb_on": "Safety-wire the turnbuckle", "uses": "Safety wire"}),
		_cover("wire_b", "Right safety wire", Rect2(510, 220, 140, 80), ["plate"], {"tool": "pliers", "col": Color(0.75, 0.75, 0.78, 0.35), "verb_off": "Cut the safety wire", "verb_on": "Safety-wire the turnbuckle", "uses": "Safety wire"}),
		_cover("plate", "Inspection plate", pr, [], {"tex": "plane_body_worn", "col": SKIN})]
		+ _corners("plate", pr, "screw", "screwdriver")}

	# Radio & antenna: unplug the coax, four antenna screws; radio out of the panel.
	var ar := Rect2(470, 120, 90, 240)
	var rr := Rect2(90, 300, 260, 120)
	s.avionics = {"title": "Cabin roof and instrument panel", "deco": [[Rect2(20, 40, 790, 240), "plane_body_worn", SKIN.darkened(0.1)], [Rect2(20, 280, 790, 250), "", Color(0.12, 0.12, 0.13)]],
		"els": [_part("antenna", "Antenna", ar, ["coax"], {"col": Color(0.1, 0.1, 0.1)})]
		+ _at("antenna", [Vector2(ar.position.x - 14, ar.end.y - 16), Vector2(ar.end.x + 14, ar.end.y - 16), Vector2(ar.position.x - 14, ar.end.y - 50), Vector2(ar.end.x + 14, ar.end.y - 50)], "screw", "screwdriver")
		+ [_cover("coax", "Coax cable", Rect2(560, 300, 160, 30), [], {"col": Color(0.25, 0.25, 0.25), "verb_off": "Unplug the coax", "verb_on": "Plug the coax back in"}),
		_part("radio", "Radio", rr, [], {"col": Color(0.2, 0.2, 0.22)})]
		+ _corners("radio", rr, "screw", "screwdriver", 12.0)}

	# Stale fuel (sat for years): open the cap, drain the old gas, sump both tanks clean, refill.
	var wing_deco := [[Rect2(20, 40, 790, 480), "plane_body_worn", SKIN.darkened(0.2)]]
	s.stale_fuel = {"title": "Fuselage tank, behind the firewall", "deco": wing_deco, "els": [
		_part("fuel", "Avgas", Rect2(160, 170, 500, 120), ["cap"], {"col": Color(0.45, 0.35, 0.12, 0.85), "requires": ["sump_l", "sump_r"],
			"verb_remove": "Drain out the stale fuel", "verb_install": "Fill up with fresh 80 octane or better"}),
		_task("sump_l", "Pull the tank drain until it runs clean", Rect2(160, 330, 220, 60), "hand", [], {"col": Color(0.3, 0.45, 0.8, 0.7), "hold": 2.5}),
		_task("sump_r", "Sump the gascolator until it runs clean", Rect2(440, 330, 220, 60), "hand", [], {"col": Color(0.3, 0.45, 0.8, 0.7), "hold": 2.5}),
		_cover("cap", "Fuel cap", Rect2(380, 90, 80, 60), [], {"col": METAL, "verb_off": "Open the fuel cap", "verb_on": "Close the fuel cap"})]}

	# Door pin rusted into the hinge: trim panel off, soak it, pull the cotter, drive the pin out.
	var dp := Rect2(260, 120, 300, 320)
	s.door_pin = {"title": "Cabin door, hinge side", "deco": [[Rect2(20, 40, 790, 480), "plane_body_worn", SKIN.darkened(0.15)], [Rect2(320, 140, 180, 280), "", Color(0.12, 0.11, 0.1)]],
		"els": [_part("pin", "Door pin", Rect2(395, 150, 30, 260), ["trim", "cotter"], {"tool": "pliers", "col": Color(0.55, 0.35, 0.2), "after": ["soak"],
			"verb_remove": "Work the seized pin out"}),
		_task("soak", "Soak the pin in penetrant", Rect2(370, 360, 80, 60), "rag", ["trim"], {"col": Color(0.5, 0.3, 0.15, 0.8), "hold": 3.0, "uses": "Penetrant"}),
		_cover("cotter", "Cotter pin", Rect2(388, 410, 44, 24), ["trim"], {"tool": "pliers", "col": Color(0.8, 0.7, 0.3), "verb_off": "Pull the cotter pin", "verb_on": "Fit a new cotter pin and bend it", "uses": "Cotter pin"}),
		_cover("trim", "Door trim panel", dp, [], {"col": Color(0.4, 0.3, 0.22)})]
		+ _corners("trim", dp, "screw", "screwdriver")}

	# Pre-oil a dry engine before its first start in years (Continental M-0 5-2.9): rocker
	# covers off, a pressure pot at 50 psi on the oil gallery until oil runs at the rockers.
	var po := []
	var rockers := []
	for i in 4:
		var rk := Rect2(110 + i * 170, 118, 140, 84)
		rockers.append("rocker%d" % i)
		po += [_cover("rocker%d" % i, "Rocker cover %d" % (i + 1), rk, ["cowl"], {"tex": "metal_steel", "col": METAL})]
		po += _at("rocker%d" % i, [rk.position + Vector2(16, 42), rk.end - Vector2(16, 42)], "screw", "screwdriver")
	for f in po.filter(func(e): return e.type == "fastener"):
		f.torque = true  # rocker cover screws 55-65 in-lb
	s.pre_oil = {"title": "Engine, left side", "deco": engine_deco, "els": [
		_task("turn", "Pre-oiler at 50 psi: open it until oil runs at the rockers", Rect2(150, 290, 520, 40), "hand", ["cowl"] + rockers,
			{"col": Color(0.65, 0.5, 0.15, 0.85), "hold": 4.0, "note": true})] + po + _cowl()}

	_troubleshooting(s, engine_deco)
	_more_jobs(s, engine_deco, wheel_deco, wing_deco)
	_scenes = s
	return s


## The troubleshooting tests and the art-backed fixes that go with them (DIAG_SCENES.md).
static func _troubleshooting(s: Dictionary, _engine_deco: Array) -> void:
	var bench_deco := [[Rect2(0, 0, 820, 560), "workbench_top", Color(0.62, 0.48, 0.32)]]
	var four := ["plug0", "plug1", "plug2", "plug3"]

	# Spark test (M-0 8-6.1): plugs out on their leads, grounded on the case; turn it through
	# and watch which fire, then a known-good plug on the dead lead tells plug from lead.
	var st_els := [_task("turn1", "Switch ON, turn it through, watch the plugs", Rect2(60, 420, 230, 46), "hand", ["cowl"],
			{"requires": four, "turns_prop": true, "note": true, "hold": 2.5}),
		_task("swap", "Good plug on the lead that didn't fire", Rect2(300, 420, 230, 46), "ratchet", ["cowl"], {"requires": ["turn1"], "hold": 1.2}),
		_task("turn2", "Turn it through again, watch that lead", Rect2(540, 420, 230, 46), "hand", ["cowl"],
			{"requires": ["swap"], "turns_prop": true, "note": true, "hold": 2.5}),
		_task("replug", "Plugs back in: new gaskets, 300-360 in-lb", Rect2(300, 476, 300, 40), "torque", ["cowl"], {"requires": ["turn2"], "hold": 2.0})]
	for i in 4:
		st_els.append(_task("plug%d" % i, "Pull plug %d, lay it on the case" % (i + 1), Rect2(110 + i * 170, 290, 140, 60), "ratchet", ["cowl"],
			{"fixture": true, "art_done": true, "hide_after": "replug", "hold": 0.8}))
		st_els.append({"id": "spark%d" % i, "type": "view", "name": "Spark %d" % (i + 1), "rect": Rect2(222 + i * 170, 295, 50, 50)})
	s.spark_test = {"title": "Engine, left side", "desc": "Engine left side, cowling off, the four top plug holes empty and the leads hanging down to the crankcase",
		"els": st_els + _cowl()}

	# Cold cylinder (AC 43.13-1B 8-2): a heat crayon mark on each stack, run it briefly, and
	# the stack whose mark didn't melt belongs to the cylinder that isn't firing.
	var cc := [_task("pencil", "Mark each stack 1 in below the flange", Rect2(600, 500, 130, 30), "hand", ["cowl"], {"hold": 2.0}),
		_task("run", "Run it 30 seconds at 1,200 rpm", Rect2(60, 470, 260, 46), "hand", [], {"requires": ["pencil"], "note": true, "hold": 2.5})]
	for i in 4:
		cc.append({"id": "mark%d" % i, "type": "view", "name": "Mark %d" % (i + 1), "rect": Rect2(150 + i * 170, 392, 60, 40)})
	s.cold_cylinder = {"title": "Engine, exhaust stacks", "desc": "Engine left side with the four exhaust stacks running down through the lower cowl", "els": cc + _cowl()}

	# Compression (M-0 6-4.11.2): 80 psi into each cylinder at top center; where the air
	# hisses out names the leak: exhaust valve, intake valve or rings.
	var cp := [{"id": "tester", "type": "view", "name": "Tester", "rect": Rect2(580, 370, 220, 150)},
		{"id": "hiss_exhaust", "type": "view", "name": "Hiss at the exhaust", "rect": Rect2(738, 452, 80, 60)},
		{"id": "hiss_intake", "type": "view", "name": "Hiss at the air filter", "rect": Rect2(210, 400, 80, 60)},
		{"id": "hiss_rings", "type": "view", "name": "Hiss at the oil filler", "rect": Rect2(446, 66, 80, 60)}]
	for i in 4:
		cp.append(_task("p%d" % i, "Cyl %d: top center, 80 psi in" % (i + 1), Rect2(98 + i * 170, 118, 124, 64), "tester", ["cowl"],
			{"with": ["hose"], "turns_prop": true, "note": true, "fixture": true, "hold": 2.0}))
	cp.append(_cover("hose", "Tester hose", Rect2(172, 252, 420, 130), ["cowl"], {"start": "off", "rest": "off",
		"verb_on": "Pull a top plug, screw in the tester hose", "verb_off": "Tester hose out, plug back in", "col": Color(0.1, 0.1, 0.1, 0.8)}))
	s.compression = {"title": "Engine, differential compression", "desc": "Engine left side with the air filter, exhaust outlet and oil filler showing, top plug of cylinder 1 out",
		"els": cp + _cowl()}

	# Reading plugs: lay them in the tray in order and read each firing end.
	var rp := []
	for i in 4:
		for row in [["t", "top", 160], ["b", "bottom", 310]]:
			rp.append(_task("%s%d" % [row[0], i], "Cyl %d %s plug to the tray" % [i + 1, row[1]], Rect2(110 + i * 115, row[2], 100, 100), "ratchet", [],
				{"fixture": true, "dyn": true, "note": true, "hold": 0.6}))
	var all8 := rp.map(func(e): return e.id)
	rp.append(_task("back", "Clean, gap .016-.021, new gaskets, back in", Rect2(110, 440, 440, 46), "torque", [], {"requires": all8, "hold": 2.5}))
	s.reading_plugs = {"title": "Bench, plug tray", "deco": bench_deco, "desc": "Workbench with a numbered plug tray (top and bottom row, cylinders 1 to 4) and a plug-reading chart", "els": rp}

	# Oil screen (M-0 6-4.8.2): rinse it over a white towel, sort the metal with a magnet.
	s.oil_screen = {"title": "Bench, oil screen", "deco": bench_deco, "desc": "Workbench with a solvent pan, a white shop towel and a card on what the metal means", "els": [
		{"id": "screen", "type": "view", "name": "Screen", "rect": Rect2(80, 200, 240, 110)},
		{"id": "metal", "type": "view", "name": "Metal", "rect": Rect2(420, 300, 200, 110)},
		{"id": "magnet_v", "type": "view", "name": "Magnet", "rect": Rect2(660, 380, 120, 70)},
		_task("pull", "Cut the wire, pull the oil screen", Rect2(80, 330, 240, 46), "pliers", [], {"hold": 1.5}),
		_task("rinse", "Rinse it over the towel", Rect2(80, 150, 240, 40), "rag", [], {"requires": ["pull"], "note": true, "hold": 2.0}),
		_task("magnet", "Touch the magnet to the flakes", Rect2(640, 460, 160, 40), "hand", [], {"requires": ["rinse"], "note": true, "hold": 1.0}),
		_task("back", "Screen in: new crush gasket, 500-520 in-lb, wired", Rect2(80, 470, 400, 46), "torque", [], {"requires": ["magnet"], "uses": "Safety wire", "hold": 2.0})]}

	# Hot magneto: tag the prop first, then a new P-lead so the switch grounds the mag again.
	s.hot_mag = {"title": "Rear accessory case", "desc": "Rear accessory case with the left magneto installed; its P-lead terminal (the switch ground) is empty", "els": [
		_task("check", "Switch OFF, pull it through: no spark", Rect2(300, 420, 300, 46), "hand", ["cowl"], {"requires": ["plead"], "with": ["tag"], "turns_prop": true, "note": true, "hold": 2.0}),
		_part("plead", "P-lead", Rect2(510, 170, 300, 60), ["cowl"], {"with": ["tag"], "col": Color(0.3, 0.3, 0.32)})]
		+ _at("plead", [Vector2(526, 200)], "nut", "ratchet")
		+ [_cover("tag", "DANGER tag", Rect2(90, 120, 110, 150), [], {"start": "off", "rest": "off", "col": Color(0.8, 0.12, 0.1),
			"verb_on": "Hang the DANGER tag on the prop", "verb_off": "Take the DANGER tag down"})] + _cowl()}

	# Fuel vent: a mud dauber nest in the cap's vent tube starves the engine a minute after start.
	s.fuel_vent = {"title": "Fuel cap, nose deck", "desc": "Close-up of the Cub's fuel cap on the nose deck, its vent tube pointing forward", "els": [
		_task("nest", "Pull the nest out of the vent", Rect2(470, 100, 160, 110), "hand", [], {"hold": 2.5}),
		_task("wire", "Run a wire through the vent tube", Rect2(560, 400, 230, 46), "pliers", [], {"requires": ["nest"], "hold": 1.5}),
		_task("crumbs", "Brush the mud off the deck", Rect2(400, 330, 300, 40), "rag", [], {"requires": ["nest"], "hold": 1.2}),
		_task("blow", "Blow through the vent", Rect2(560, 456, 230, 46), "hand", [], {"requires": ["wire"], "note": true, "hold": 1.0})]}

	# Water in the fuel: sump until the cup comes up all blue.
	s.water_fuel = {"title": "Under the nose, gascolator", "desc": "Under the nose: the gascolator bowl and its drain, gear legs either side", "els": [
		{"id": "cup", "type": "view", "name": "Fuel tester", "rect": Rect2(360, 270, 140, 180)},
		_task("sump1", "Sump the gascolator into the cup", Rect2(560, 250, 230, 46), "hand", [], {"note": true, "hold": 1.5}),
		_task("tank", "Pull the tank drain till it runs clean", Rect2(560, 306, 230, 46), "hand", [], {"requires": ["sump1"], "hold": 2.5}),
		_task("sump2", "Sump it again", Rect2(560, 362, 230, 46), "hand", [], {"requires": ["tank"], "note": true, "hold": 1.5}),
		_task("spill", "Rake the spilled fuel into the gravel", Rect2(280, 480, 300, 40), "rag", [], {"show_after": "sump1", "requires": ["sump2"], "hold": 1.2})]}


## Everything else from JOBS_ATA.md: placeholders until art exists (ART_PROMPTS.md).
static func _more_jobs(s: Dictionary, engine_deco: Array, wheel_deco: Array, wing_deco: Array) -> void:
	var panel_deco := [[Rect2(20, 40, 790, 480), "", Color(0.13, 0.12, 0.11)], [Rect2(60, 80, 700, 200), "cockpit_panel", Color(0.5, 0.45, 0.38)]]
	var tail_deco := [[Rect2(20, 60, 790, 420), "plane_body_worn", SKIN.darkened(0.2)]]
	var prop_deco := [[Rect2(250, 120, 320, 320), "", SKIN.darkened(0.3), "circle"], [Rect2(40, 245, 740, 70), "prop_wood", Color(0.62, 0.4, 0.2)]]

	s.ign_lead = {"title": "Engine, left side", "deco": engine_deco, "desc": "Engine left side, cowling off, the ignition harness running from the magneto to each plug", "els": [
		_task("route", "Route it clear of the exhaust, clamp it", Rect2(200, 250, 420, 40), "hand", ["cowl"], {"requires": ["lead"], "hold": 1.5}),
		_part("lead", "Ignition lead", Rect2(200, 170, 420, 30), ["cowl", "clamp"], {"col": Color(0.55, 0.12, 0.1)})]
		+ _at("lead", [Vector2(214, 185), Vector2(606, 185)], "nut", "ratchet")
		+ [_cover("clamp", "Lead clamp", Rect2(400, 140, 90, 50), ["cowl"], {"col": METAL})] + _at("clamp", [Vector2(445, 165)], "screw", "screwdriver") + _cowl()}

	s.primer_leak = {"title": "Instrument panel, primer", "deco": panel_deco, "desc": "Cub instrument panel close up, the brass primer pump knob on the right of the panel", "els": [
		_task("test", "Pump it: it seats and locks", Rect2(330, 340, 240, 46), "hand", [], {"requires": ["seals"], "with": ["valve"], "hold": 1.5}),
		_part("seals", "Primer seals", Rect2(380, 170, 120, 110), ["nut", "valve"], {"col": Color(0.6, 0.5, 0.2)}),
		_cover("nut", "Packing nut", Rect2(405, 130, 70, 40), [], {"tool": "ratchet", "col": Color(0.7, 0.6, 0.3)}),
		_cover("valve", "Fuel shut-off", Rect2(700, 420, 100, 90), [], {"col": Color(0.6, 0.1, 0.1), "verb_off": "Turn the fuel OFF", "verb_on": "Turn the fuel back ON"})]}

	var rc := Rect2(200, 130, 440, 150)
	var rocker := [_cover("rocker", "Rocker cover", rc, ["cowl"], {"tex": "metal_steel", "col": METAL})] + _corners("rocker", rc, "screw", "screwdriver", 18.0)
	for f in rocker.filter(func(e): return e.type == "fastener"):
		f.torque = true  # 55-65 in-lb
	s.stuck_valve = {"title": "Engine, rocker cover off", "deco": engine_deco, "desc": "One cylinder head with its rocker cover off: rocker arms, valve springs and stems showing", "els": [
		_part("gasket", "Rocker cover gasket", rc.grow(-24), ["cowl", "rocker"], {"col": Color(0.75, 0.35, 0.15), "requires": ["free"]}),
		_task("soak", "Soak the valve stem", Rect2(260, 180, 150, 50), "rag", ["cowl", "rocker"], {"uses": "Penetrant", "hold": 2.0}),
		_task("free", "Work the valve free", Rect2(430, 180, 160, 50), "hand", ["cowl", "rocker"], {"requires": ["soak"], "hold": 3.0})]
		+ rocker + _cowl()}

	var cy := Rect2(250, 90, 300, 240)
	s.worn_rings = {"title": "Engine, one cylinder", "deco": engine_deco, "desc": "One cylinder of a small flat-four with the intake pipe, exhaust stack and rocker cover still on it", "els": [
		_part("cyl", "Cylinder", cy, ["cowl", "intake", "exhaust", "rocker"], {"col": Color(0.35, 0.35, 0.37), "verb_install": "Fit the new cylinder, oil the rings"})]
		+ _ring("cyl", cy.get_center() + Vector2(0, 40), 120, 8, "nut", "ratchet", true)
		+ [_cover("intake", "Intake pipe", Rect2(140, 300, 160, 40), ["cowl"], {"col": METAL})] + _at("intake", [Vector2(160, 320), Vector2(280, 320)], "screw", "screwdriver")
		+ [_cover("exhaust", "Exhaust stack", Rect2(520, 300, 160, 40), ["cowl"], {"col": Color(0.4, 0.3, 0.25)})] + _at("exhaust", [Vector2(540, 320), Vector2(660, 320)], "nut", "ratchet")
		+ [_cover("rocker", "Rocker cover", Rect2(290, 100, 220, 70), ["cowl"], {"tex": "metal_steel", "col": METAL})] + _at("rocker", [Vector2(310, 135), Vector2(490, 135)], "screw", "screwdriver")
		+ _cowl()}

	s.relief_valve = {"title": "Engine, oil relief valve", "deco": engine_deco, "desc": "Rear of the crankcase: the oil pressure relief valve cap, safety-wired, beside the oil screen housing", "els": [
		_task("clean", "Clean the plunger and seat", Rect2(300, 200, 220, 50), "rag", ["cowl", "cap"], {"hold": 2.0}),
		_task("shim", "Add a shim under the spring", Rect2(300, 260, 220, 50), "hand", ["cowl", "cap"], {"requires": ["clean"], "hold": 1.5}),
		_cover("cap", "Relief valve cap", Rect2(330, 150, 160, 160), ["cowl", "wire"], {"col": METAL})] + _at("cap", [Vector2(410, 230)], "nut", "ratchet")
		+ [_wire("wire", "Safety wire", Rect2(320, 140, 180, 180), ["cowl"])] + _cowl()}

	var oc := [_part("oil", "Engine oil", Rect2(140, 360, 520, 60), [], {"col": Color(0.15, 0.12, 0.08), "after": ["drain"], "with": ["plug", "screen"],
			"verb_remove": "Pour the old oil in the waste drum", "verb_install": "Pour in 4 quarts, check the stick"}),
		_task("drain", "Drain the old oil into the pan", Rect2(140, 430, 300, 46), "hand", ["plug"], {"hold": 2.5}),
		_task("rinse", "Rinse the screen, try the magnet", Rect2(470, 430, 300, 46), "rag", ["screen"], {"note": true, "hold": 2.0}),
		_cover("plug", "Drain plug", Rect2(220, 280, 80, 60), ["wire"], {"tool": "ratchet", "col": METAL}),
		_wire("wire", "Drain plug safety wire", Rect2(200, 260, 120, 100)),
		_cover("screen", "Oil screen", Rect2(520, 260, 160, 80), ["swire"], {"col": METAL})] + _at("screen", [Vector2(600, 300)], "nut", "ratchet") \
		+ [_wire("swire", "Screen safety wire", Rect2(510, 250, 180, 100))]
	_torque_on(oc, "screen")  # 500-520 in-lb with a new crush gasket
	s.oil_change = {"title": "Engine, oil sump", "deco": engine_deco, "desc": "Bottom of the engine: the oil sump drain plug, safety-wired, and the oil screen housing at the back", "els": oc}

	var ms := Rect2(300, 150, 300, 130)
	var ex := [_part("muffler", "Muffler", ms, ["cowl", "shroud"], {"col": Color(0.4, 0.3, 0.25), "after": ["leak"]}),
		_task("leak", "Plug it, 2 psi in, dunk the seam", Rect2(300, 300, 300, 46), "hand", ["cowl", "shroud"], {"note": true, "hold": 2.5})] \
		+ _at("muffler", [ms.position + Vector2(20, 20), Vector2(ms.end.x - 20, ms.position.y + 20)], "nut", "ratchet") \
		+ [_cover("shroud", "Heat shroud", ms.grow(16), ["cowl"], {"tex": "metal_steel", "col": METAL})] + _corners("shroud", ms.grow(16), "screw", "screwdriver") + _cowl()
	_torque_on(ex, "muffler")  # flange nuts 100-110 in-lb
	s.exhaust = {"title": "Engine, muffler and heat shroud", "deco": engine_deco, "desc": "Underside of the engine: the muffler and its cabin-heat shroud, exhaust stacks running into it", "els": ex}

	var ab := Rect2(260, 300, 300, 150)
	s.air_filter = {"title": "Nose, airbox", "deco": engine_deco, "desc": "Front of the cowl from below: the carburetor airbox, its filter and the carb-heat flapper door", "els": [
		_part("filter", "Air filter", ab.grow(-30), ["airbox"], {"col": Color(0.55, 0.5, 0.35)}),
		_task("flap", "Free the carb heat door", Rect2(600, 360, 200, 46), "hand", ["airbox"], {"hold": 1.5}),
		_cover("airbox", "Airbox cover", ab, [], {"col": METAL})] + _corners("airbox", ab, "screw", "screwdriver")}

	var mg := Rect2(470, 130, 220, 170)
	var mt := [_task("tdc", "#1 to top center, prop forward", Rect2(120, 180, 260, 46), "hand", ["cowl", "plug1"], {"turns_prop": true, "note": true, "hold": 2.0}),
		_task("rotate", "Rotate the mag till the light comes on", Rect2(120, 240, 260, 46), "timing", ["cowl", "clamp"], {"requires": ["tdc"], "with": ["light"], "note": true, "hold": 2.5}),
		_task("back", "Turn it backward to get there", Rect2(120, 300, 260, 40), "hand", ["cowl"], {"trap": "Never back up: turn the crank in its normal direction when timing, or gear backlash throws the reading off (M-0 6-4.9)."}),
		_cover("light", "Timing light", Rect2(480, 320, 200, 60), ["cowl"], {"start": "off", "rest": "off", "col": Color(0.15, 0.15, 0.18),
			"verb_on": "Clip the timing light to the mag", "verb_off": "Unclip the timing light"}),
		_cover("clamp", "Magneto clamp", mg, ["cowl"], {"col": Color(0.15, 0.15, 0.17), "verb_off": "Slack the clamp so the mag turns", "verb_on": "Snug the clamp"})] \
		+ _at("clamp", [Vector2(mg.position.x - 14, mg.end.y - 30), Vector2(mg.end.x + 14, mg.end.y - 30)], "nut", "ratchet") \
		+ [_cover("plug1", "#1 top plug", Rect2(160, 110, 60, 60), ["cowl"], {"tool": "ratchet", "col": Color(0.85, 0.85, 0.8)})] + _cowl()
	_torque_on(mt, "clamp")  # 100-120 in-lb
	s.mag_timing = {"title": "Rear accessory case, timing", "deco": engine_deco, "desc": "Rear accessory case with both magnetos, a timing light clipped on, and the #1 top plug hole with a top-center locator", "els": mt}

	s.baffles = {"title": "Engine, cylinder fins", "deco": engine_deco, "desc": "Engine left side, cowling off: cooling fins packed with mud dauber nests, a baffle seal strip flapping loose", "els": [
		_task("fins", "Scrape the nests out of the fins", Rect2(120, 150, 560, 70), "rag", ["cowl"], {"hold": 3.0}),
		_part("seal", "Baffle seal", Rect2(120, 240, 560, 30), ["cowl"], {"col": Color(0.2, 0.2, 0.2)})]
		+ _at("seal", [Vector2(140, 255), Vector2(400, 255), Vector2(660, 255)], "screw", "screwdriver") + _cowl()}

	var sr := []
	var dh := []
	for i in 4:
		sr.append(_task("dehyd%d" % i, "Dehydrator plug %d out" % (i + 1), Rect2(150 + i * 170, 160, 90, 60), "hand", ["cowl"], {"hold": 0.6}))
		dh.append("dehyd%d" % i)
	s.storage_return = {"title": "Engine, out of preservation", "deco": engine_deco, "desc": "Engine left side, cowling off, blue dehydrator plugs in the plug holes, red REMOVE BEFORE FLIGHT streamers, a DO NOT TURN PROPELLER tag", "els": sr + [
		_task("bag_l", "Desiccant bag out of the left stack", Rect2(80, 420, 220, 46), "hand", [], {"hold": 0.8}),
		_task("bag_r", "Desiccant bag out of the right stack", Rect2(320, 420, 220, 46), "hand", [], {"hold": 0.8}),
		_task("tag", "Take down the DO NOT TURN tag", Rect2(560, 420, 220, 46), "hand", [], {"requires": dh + ["bag_l", "bag_r"], "hold": 0.5}),
		_task("turn", "Turn it through by hand", Rect2(80, 476, 220, 40), "hand", [], {"requires": ["tag"], "turns_prop": true, "note": true, "hold": 2.5}),
		_task("oil", "Drain the preservative oil, refill", Rect2(320, 476, 220, 40), "hand", [], {"requires": ["turn"], "hold": 2.5}),
		_task("plugs", "Plugs in, gapped, 300-360 in-lb", Rect2(150, 240, 520, 40), "torque", ["cowl"], {"requires": ["oil"], "hold": 2.0}),
		_task("start", "Prime it and pull it through", Rect2(560, 476, 240, 40), "hand", [], {"trap": "Not yet: preservative oil still in there can hydraulic-lock a cylinder and bend a rod (M-0 6-5.2). Clear it first."})]
		+ _cowl()}

	var bowl := Rect2(360, 200, 120, 140)
	s.fuel_strainer = {"title": "Firewall, fuel strainer", "deco": engine_deco, "desc": "Lower firewall with the glass fuel strainer bowl hanging under its bail, a safety-wired thumb nut, the fuel line in", "els": [
		_part("gasket", "Strainer gasket", Rect2(370, 190, 100, 16), ["cowl", "bowl"], {"col": Color(0.6, 0.3, 0.1), "requires": ["screen"]}),
		_task("screen", "Rinse the screen and bowl", Rect2(520, 220, 220, 46), "rag", ["cowl", "bowl"], {"hold": 2.0}),
		_cover("bowl", "Strainer bowl", bowl, ["cowl", "valve", "wire"], {"col": Color(0.7, 0.75, 0.6, 0.7)})] + _at("bowl", [Vector2(420, 330)], "nut", "ratchet")
		+ [_wire("wire", "Bail nut safety wire", Rect2(380, 310, 80, 50), ["cowl"]),
		_cover("valve", "Fuel shut-off", Rect2(700, 420, 100, 90), [], {"col": Color(0.6, 0.1, 0.1), "verb_off": "Turn the fuel OFF", "verb_on": "Turn the fuel back ON"})] + _cowl()}

	# Brake bleeding, the Cub manual's way: pump fluid up from the wheel, crack the cap screw.
	s.brake_bleed = {"title": "Right wheel and floorboard", "deco": wheel_deco, "desc": "Right main wheel from inside, the bleeder tee on the brake line, a hand pump, and the floorboard with the heel brake pedal above", "els": [
		_part("fluid", "Brake fluid", Rect2(380, 60, 40, 260), ["screw"], {"col": Color(0.75, 0.2, 0.15), "with": ["pump"],
			"verb_remove": "Open the bleeder tee", "verb_install": "Pump fluid up till the system's full"}),
		_task("cap", "Crack the cap screw half a turn", Rect2(540, 80, 260, 46), "ratchet", [], {"requires": ["fluid"], "hold": 1.0}),
		_task("pedal", "Pedal in 1 in, snug the cap screw", Rect2(540, 136, 260, 46), "ratchet", [], {"requires": ["cap"], "note": true, "hold": 2.0}),
		_task("wipe", "Wipe the fluid off the floorboard", Rect2(540, 192, 260, 46), "rag", [], {"requires": ["pedal"], "hold": 1.2}),
		_task("lining", "Squirt fluid on the lining to free it", Rect2(540, 248, 260, 40), "hand", [], {"trap": "No: fluid on the lining ruins it, and on the fabric it lifts the dope (Cub manual p.22)."}),
		_cover("pump", "Hand pump", Rect2(120, 330, 160, 100), ["screw"], {"start": "off", "rest": "off", "col": Color(0.3, 0.3, 0.6),
			"verb_on": "Hook the hand pump to the bleeder tee", "verb_off": "Unhook the pump"}),
		_cover("screw", "Bleeder tee screw", Rect2(300, 330, 70, 50), [], {"tool": "screwdriver", "col": Color(0.7, 0.6, 0.3)})]}

	s.bungee = {"title": "Left main gear, shock cords", "deco": wheel_deco, "desc": "Left main gear leg close up: the wrapped bungee shock cords around the gear vee, their colored date threads", "els": [
		_task("read", "Read the date threads", Rect2(480, 60, 240, 46), "hand", [], {"note": true, "hold": 1.0}),
		_part("cords", "Bungee cords", Rect2(330, 110, 140, 180), ["jack"], {"tool": "pliers", "col": Color(0.85, 0.8, 0.7), "requires": ["read"]}),
		_cover("jack", "Jack", Rect2(80, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Jack it up off its gear", "verb_on": "Lower it back down"})]}

	s.tailwheel = {"title": "Tailwheel", "deco": wheel_deco, "desc": "Cub tailwheel close up: the leaf spring, the steering arm with its two little chain-and-spring links to the rudder horn", "els": [
		_part("springs", "Steering springs", Rect2(200, 160, 300, 50), ["stand"], {"col": Color(0.6, 0.6, 0.62)}),
		_task("grease", "Grease the spindle", Rect2(380, 260, 200, 46), "rag", ["stand", "pin"], {"hold": 1.5}),
		_cover("pin", "Cotter pin", Rect2(400, 320, 44, 24), ["stand"], {"tool": "pliers", "col": Color(0.8, 0.7, 0.3), "verb_off": "Pull the cotter pin", "verb_on": "Fit a new cotter pin and bend it", "uses": "Cotter pin"}),
		_cover("stand", "Tail stand", Rect2(80, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Lift the tail onto the stand", "verb_on": "Set the tail back down"})]}

	s.aileron_rig = {"title": "Left wing, aileron cables", "deco": wing_deco, "desc": "Underside of the left wing at the aileron: an inspection hole showing two turnbuckles on the upper and lower aileron cables", "els": [
		_task("center", "Center the stick", Rect2(560, 400, 220, 46), "hand", [], {"hold": 0.8}),
		_task("up", "Back off the upper turnbuckle", Rect2(180, 170, 200, 50), "screwdriver", ["plate", "wire_up"], {"requires": ["center"], "fixture": true, "hold": 2.0}),
		_task("lo", "Take up the lower one the same", Rect2(440, 170, 200, 50), "screwdriver", ["plate", "wire_lo"], {"requires": ["up"], "fixture": true, "hold": 2.0}),
		_task("sight", "Sight the trailing edges", Rect2(560, 456, 220, 46), "hand", [], {"requires": ["lo"], "note": true, "hold": 1.0}),
		_wire("wire_up", "Upper turnbuckle wire", Rect2(170, 160, 220, 70), ["plate"]),
		_wire("wire_lo", "Lower turnbuckle wire", Rect2(430, 160, 220, 70), ["plate"])] + _plate(Rect2(140, 110, 540, 180))}

	s.wing_rig = {"title": "Wings, dihedral and wash-out", "deco": wing_deco, "desc": "A Cub's wing seen from behind with a string stretched tip to tip over the front spar, and a long spirit level with a small spacer block against a rib", "els": [
		_task("string", "String tip to tip, measure at the center", Rect2(60, 60, 300, 46), "hand", [], {"note": true, "hold": 1.5}),
		_task("front", "Turn the front strut forks out", Rect2(60, 200, 260, 46), "ratchet", ["fjam"], {"requires": ["string"], "fixture": true, "hold": 2.0}),
		_task("string2", "Measure again", Rect2(60, 256, 260, 46), "hand", [], {"requires": ["front"], "note": true, "hold": 1.0}),
		_task("level", "Level and 3/8 block on the outer rib", Rect2(420, 60, 300, 46), "hand", [], {"requires": ["string2"], "note": true, "hold": 1.5}),
		_task("rear", "Adjust the rear struts till it centers", Rect2(420, 200, 300, 46), "ratchet", ["rjam"], {"requires": ["level"], "note": true, "fixture": true, "hold": 2.0}),
		_cover("fjam", "Front strut jam nuts", Rect2(60, 330, 220, 60), [], {"tool": "ratchet", "col": METAL, "verb_off": "Slack the front jam nuts", "verb_on": "Snug the front jam nuts"}),
		_cover("rjam", "Rear strut jam nuts", Rect2(420, 330, 220, 60), [], {"tool": "ratchet", "col": METAL, "verb_off": "Slack the rear jam nuts", "verb_on": "Snug the rear jam nuts"}),
		_task("middle", "Push on the middle of the strut", Rect2(60, 420, 300, 40), "hand", [], {"trap": "No: push or pull on a lift strut only near the fuselage end, never its middle (Cub manual p.15)."})]}

	s.elevator_cable = {"title": "Tail post, elevator horn", "deco": tail_deco, "desc": "Tail post with its inspection cover off: the elevator horn, two cable terminals and a turnbuckle", "els": [
		_part("cable", "Elevator cable", Rect2(100, 255, 620, 14), ["plate", "wire"], {"col": Color(0.7, 0.7, 0.72)}),
		_task("tb", "Tension the turnbuckle", Rect2(340, 230, 120, 60), "screwdriver", ["plate", "wire"], {"fixture": true, "requires": ["cable"], "col": Color(0.6, 0.55, 0.3, 0.9), "hold": 2.5}),
		_wire("wire", "Turnbuckle safety wire", Rect2(330, 220, 140, 80), ["plate"])] + _plate(Rect2(80, 110, 660, 320))}

	s.trim_cable = {"title": "Tail, left side", "deco": tail_deco, "desc": "Left side of the Cub's tail with an inspection plate off: the trim jack screw, its V-groove pulley and the idler pulley on the endless cable", "els": [
		_task("idler", "Take up the idler pulley", Rect2(300, 200, 220, 50), "hand", ["plate", "lock"], {"note": true, "hold": 2.0}),
		_task("oilit", "Oil the cable so it runs smoother", Rect2(300, 260, 220, 46), "rag", ["plate"], {"trap": "Never oil the trim cable: it drives the pulleys by friction and would slip worse (Cub manual p.30)."}),
		_cover("lock", "Idler lock nut", Rect2(540, 200, 70, 50), ["plate"], {"tool": "ratchet", "col": METAL, "verb_off": "Slack the idler lock nut", "verb_on": "Snug the lock nut, not too tight"})]
		+ _plate(Rect2(200, 120, 460, 220))}

	s.tail_brace = {"title": "Tail brace wires", "deco": tail_deco, "desc": "Cub tail from the side: the stabilizer, fin and the streamlined brace wires with threaded nipple fittings at each end", "els": [
		_task("tape", "Friction tape where you'll grip it", Rect2(160, 160, 220, 46), "hand", [], {"hold": 1.0}),
		_part("wire", "Brace wire", Rect2(140, 220, 540, 20), [], {"col": Color(0.7, 0.7, 0.72), "requires": ["tape"]})]
		+ _at("wire", [Vector2(150, 230), Vector2(670, 230)], "nut", "ratchet")
		+ [_task("level", "Turn the nipples till it's level", Rect2(420, 300, 280, 46), "hand", [], {"requires": ["wire"], "note": true, "hold": 2.0})]}

	s.tie_down = {"title": "Tied down on the grass", "deco": wheel_deco, "desc": "A Cub tied down on grass from the side: rope at the tail lift handle, ropes to both front lift struts, chocks at the wheels", "els": [
		_task("chocks", "Chock the wheels", Rect2(60, 420, 200, 46), "hand", [], {"hold": 0.8}),
		_task("tail", "Rope the tail handle, no slack", Rect2(280, 420, 240, 46), "hand", [], {"hold": 1.5}),
		_task("left", "Rope the left strut top", Rect2(60, 360, 200, 46), "hand", [], {"hold": 1.5}),
		_task("right", "Rope the right strut top", Rect2(280, 360, 240, 46), "hand", [], {"hold": 1.5}),
		_task("lock", "Belt round the rear stick", Rect2(540, 360, 260, 46), "hand", [], {"hold": 1.0}),
		_task("struts", "Tie it at the middle of the strut", Rect2(540, 420, 260, 46), "hand", [], {"trap": "Not the middle: never pull or push on the middle of a lift strut. Tie at the top, where it meets the wing (Cub manual p.15, 42)."})]}

	s.prop_nick = {"title": "Propeller blade", "deco": prop_deco, "desc": "One propeller blade close up, laid flat: a stone nick in the leading edge a third of the way in from the tip", "els": [
		_task("file", "Dress the nick into a smooth dish", Rect2(500, 120, 260, 46), "hand", [], {"hold": 2.5}),
		_task("crocus", "Finish it with crocus cloth", Rect2(500, 176, 260, 46), "rag", [], {"requires": ["file"], "hold": 1.5}),
		_task("etch", "Etch it, look for a crack", Rect2(500, 340, 260, 46), "rag", [], {"requires": ["crocus"], "note": true, "hold": 1.5}),
		_task("straighten", "Straighten the tip while you're there", Rect2(500, 396, 260, 46), "hand", [], {"trap": "No: never straighten a blade in the field, not even to ship it (AC 43.13-1B 8-73)."})]}

	var hub := Vector2(410, 280)
	s.prop_track = {"title": "Nose, prop tracking", "deco": prop_deco, "desc": "The propeller from the side with a heavy wooden block on the ground just touching the lower blade tip", "els": [
		_task("t1", "Turn blade 1 past the block", Rect2(580, 400, 220, 46), "hand", [], {"with": ["block", "plugs"], "turns_prop": true, "note": true, "hold": 1.5}),
		_task("t2", "Turn blade 2 past the block", Rect2(580, 456, 220, 46), "hand", [], {"requires": ["t1"], "with": ["block"], "turns_prop": true, "note": true, "hold": 1.5}),
		_task("shim", "Shim the hub on the low side", Rect2(330, 150, 160, 50), "hand", ["bolts"], {"requires": ["t2"], "hold": 2.0}),
		_task("t3", "Track it again", Rect2(580, 344, 220, 46), "hand", [], {"requires": ["shim"], "with": ["block"], "turns_prop": true, "note": true, "hold": 1.5}),
		_cover("bolts", "Prop bolts", Rect2(hub - Vector2(70, 70), Vector2(140, 140)), ["wire"], {"col": Color(0.55, 0.55, 0.58, 0.7), "verb_off": "Slacken the prop bolts", "verb_on": "Snug the prop bolts"})]
		+ _ring("bolts", hub, 52, 6, "bolt", "ratchet", true)
		+ [_wire("wire", "Prop bolt safety wire", Rect2(hub - Vector2(80, 80), Vector2(160, 160))),
		_cover("block", "Wood block", Rect2(380, 470, 80, 60), [], {"start": "off", "rest": "off", "col": Color(0.6, 0.45, 0.25), "verb_on": "Set the block at the tip", "verb_off": "Take the block away"}),
		_cover("plugs", "One plug per cylinder out", Rect2(60, 60, 160, 50), [], {"start": "off", "rest": "off", "tool": "ratchet", "col": Color(0.85, 0.85, 0.8),
			"verb_on": "Pull one plug from each cylinder", "verb_off": "Put the plugs back in"})]}

	s.compass = {"title": "Compass rose", "deco": panel_deco, "desc": "The Cub's whiskey compass above the panel, a compass rose painted on the apron seen through the windshield", "els": [
		_task("n", "Taxi to north, run it at 1,700", Rect2(60, 320, 220, 46), "hand", [], {"note": true, "hold": 1.5}),
		_task("ns", "Set the N-S screw to north", Rect2(300, 320, 220, 46), "screwdriver", [], {"requires": ["n"], "hold": 1.2}),
		_task("e", "Turn to east", Rect2(540, 320, 220, 46), "hand", [], {"requires": ["ns"], "note": true, "hold": 1.5}),
		_task("ew", "Set the E-W screw to east", Rect2(60, 376, 220, 46), "screwdriver", [], {"requires": ["e"], "hold": 1.2}),
		_task("s", "Turn south, take out half", Rect2(300, 376, 220, 46), "screwdriver", [], {"requires": ["ew"], "note": true, "hold": 1.5}),
		_task("w", "Turn west, take out half", Rect2(540, 376, 220, 46), "screwdriver", [], {"requires": ["s"], "note": true, "hold": 1.5}),
		_task("swing", "Swing all twelve headings, fill the card", Rect2(60, 432, 460, 46), "hand", [], {"requires": ["w"], "note": true, "hold": 3.0})]}

	s.pitot_static = {"title": "Behind the panel", "deco": panel_deco, "desc": "Behind the Cub's instrument panel: the airspeed and altimeter cases with rubber static and pitot hoses, a test set hooked up", "els": [
		_task("static1", "Static side to 1,000 ft, time it", Rect2(60, 320, 260, 46), "hand", [], {"with": ["tester"], "note": true, "hold": 2.5}),
		_part("hose", "Static hose", Rect2(360, 200, 300, 24), ["panel"], {"col": Color(0.2, 0.2, 0.2), "requires": ["static1"]}),
		_task("static2", "Test the static side again", Rect2(60, 376, 260, 46), "hand", [], {"requires": ["hose"], "with": ["tester", "panel"], "note": true, "hold": 2.5}),
		_task("pitot", "Pitot side to 150 knots, time it", Rect2(60, 432, 260, 46), "hand", [], {"requires": ["static2"], "with": ["tester"], "note": true, "hold": 2.5}),
		_cover("panel", "Panel back cover", Rect2(340, 100, 380, 200), [], {"col": Color(0.3, 0.28, 0.25)})] + _corners("panel", Rect2(340, 100, 380, 200), "screw", "screwdriver")
		+ [_cover("tester", "Pitot-static tester", Rect2(380, 380, 200, 100), [], {"start": "off", "rest": "off", "col": Color(0.2, 0.25, 0.35),
			"verb_on": "Hook up the pitot-static tester", "verb_off": "Unhook the tester"})]}

	s.weight_balance = {"title": "On the scales", "deco": wheel_deco, "desc": "A Cub sitting level on three platform scales, one under each main wheel and one under the tailwheel, a spirit level on the cockpit longeron", "els": [
		_task("level", "Level it on the left longeron", Rect2(60, 60, 300, 46), "hand", [], {"hold": 1.5}),
		_task("l", "Read the left main scale", Rect2(60, 400, 220, 46), "hand", [], {"requires": ["level"], "note": true, "hold": 1.0}),
		_task("r", "Read the right main scale", Rect2(300, 400, 220, 46), "hand", [], {"requires": ["level"], "note": true, "hold": 1.0}),
		_task("t", "Read the tail scale", Rect2(540, 400, 220, 46), "hand", [], {"requires": ["level"], "note": true, "hold": 1.0})]}

	s.wire_splice = {"title": "Behind the panel, wiring", "deco": panel_deco, "desc": "Behind an instrument panel: a wire bundle with one wire chafed through where it rubs a bracket, near a fuel line", "els": [
		_task("cut", "Cut out the chafed section", Rect2(360, 140, 220, 46), "pliers", ["panel"], {"hold": 1.2}),
		_task("splice", "Splice, heat-shrink, stagger it", Rect2(360, 196, 220, 46), "pliers", ["panel"], {"requires": ["cut"], "hold": 2.0}),
		_task("clamp", "Clamp it 6 in clear of the fuel line", Rect2(360, 252, 220, 46), "screwdriver", ["panel"], {"requires": ["splice"], "hold": 1.5}),
		_task("check", "Wiggle test with the radio on", Rect2(60, 400, 260, 46), "hand", [], {"requires": ["clamp"], "with": ["panel"], "note": true, "hold": 1.5}),
		_cover("panel", "Panel back cover", Rect2(340, 100, 380, 260), [], {"col": Color(0.3, 0.28, 0.25)})] + _corners("panel", Rect2(340, 100, 380, 260), "screw", "screwdriver")}

	s.fod = {"title": "Engine, under the cowl", "deco": engine_deco, "desc": "Engine left side, cowling off: a socket wedged behind a cylinder baffle", "els": [
		_task("fish", "Fish out the loose socket", Rect2(500, 230, 160, 60), "hand", ["cowl"], {"note": true, "hold": 2.0})] + _cowl()}

	# Hand-propping, the Cub manual's starting drill (p.38). Opened by the run-up on a Cub.
	s.hand_prop = {"title": "In front of the prop", "deco": prop_deco, "desc": "Standing in front of a Cub's propeller on grass, chocks at the wheels, the cabin door open to the throttle and switch", "els": [
		_task("chocks", "Chock the wheels", Rect2(40, 380, 180, 46), "hand", [], {"hold": 0.8}),
		_task("off", "Ignition OFF, and check it", Rect2(240, 380, 180, 46), "hand", [], {"requires": ["chocks"], "hold": 0.6}),
		_task("throttle", "Throttle a tenth open", Rect2(440, 380, 180, 46), "hand", [], {"requires": ["chocks"], "hold": 0.6}),
		_task("fuel", "Fuel ON", Rect2(640, 380, 160, 46), "hand", [], {"requires": ["chocks"], "hold": 0.6}),
		_task("pull", "Pull it through several blades", Rect2(40, 440, 260, 46), "hand", [], {"requires": ["off", "throttle", "fuel"], "turns_prop": true, "hold": 1.5}),
		_task("on", "Ignition ON", Rect2(320, 440, 180, 46), "hand", [], {"requires": ["pull"], "hold": 0.5}),
		_task("swing", "Swing it: mid-blade, step back", Rect2(520, 440, 280, 46), "hand", [], {"requires": ["on"], "hold": 1.0}),
		_task("tip", "Grab the blade tip for leverage", Rect2(40, 500, 260, 40), "hand", [], {"trap": "Never the tip: grasp midway, both hands, and stand well back so a kick can't take you with it (Cub manual p.38)."})]}


static func _wire(id: String, name: String, r: Rect2, needs := []) -> Dictionary:
	return _cover(id, name, r, needs, {"tool": "pliers", "col": Color(0.75, 0.75, 0.78, 0.45), "verb_off": "Cut the safety wire", "verb_on": "Safety-wire it", "uses": "Safety wire"})


static func _plate(r: Rect2, name := "Inspection plate") -> Array:
	return [_cover("plate", name, r, [], {"tex": "plane_body_worn", "col": SKIN})] + _corners("plate", r, "screw", "screwdriver")


static func _torque_on(els: Array, host: String) -> void:
	for e in els:
		if e.get("host", "") == host:
			e.torque = true

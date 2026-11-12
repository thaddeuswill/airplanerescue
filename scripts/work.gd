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
## "needs" lists covers that must be off first. A cover goes back only once everything that
## needed it off is complete. State lives in job.work[fault], so you can step away mid-job.
## Art: textures/work/<fault>_<piece>.png (parts: _old/_new); until it exists, placeholders.

signal finished

const W := 1000.0
const H := 560.0
const BENCH := Rect2(828, 14, 160, 532)
const TOOLS := {
	"hand": "Hands", "screwdriver": "Screwdriver", "ratchet": "Ratchet & sockets",
	"torque": "Torque wrench", "pliers": "Safety-wire pliers", "rag": "Shop rag",
}
const DAYS := {"loosen": 0.003, "tighten": 0.003, "torque": 0.004, "out": 0.001, "insert": 0.001,
	"off": 0.003, "on": 0.004, "remove": 0.008, "install": 0.012, "do": 0.012}
const SKIN := Color(0.93, 0.74, 0.22)
const METAL := Color(0.62, 0.63, 0.66)
const ENGINE := Color(0.3, 0.3, 0.32)
const RUBBER := Color(0.13, 0.13, 0.13)

var main  # main.gd: tools, inventory, time
var fault: String
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


func setup(m, fault_id: String, job: Dictionary) -> void:
	main = m
	fault = fault_id
	part_name = m.FAULTS[fault_id].part
	def = scenes()[fault_id]
	els = def.els
	for e in els:
		by_id[e.id] = e
	if not job.work.has(fault_id):
		var s := {"_paid": false}
		for e in els:
			s[e.id] = {"fastener": "tight", "cover": "on", "part": "old", "task": "todo"}[e.type]
		job.work[fault_id] = s
	st = job.work[fault_id]
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
		"fastener": return st[e.id] == "tight"
		"task": return st[e.id] == "done"
		"cover": return st[e.id] == "on" and _fasteners(e.id).all(func(f): return st[f.id] == "tight")
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
			else:
				var waiting := els.filter(func(x): return x.type != "fastener" and e.id in x.get("needs", []) and not _complete(x))
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
		"do": st[e.id] = "done"
	if v in ["on", "do"] and e.get("uses", "") != "":
		main.inventory[e.uses] -= 1  # a fresh length of safety wire, a new cotter pin, a squirt of penetrant
	if v in ["torque", "install", "on"]:
		main.sound.clink()
	if not main._work_time(DAYS[v]):
		return false
	hover = _hit(get_local_mouse_position() - _origin())  # what was under the cursor may have moved
	if done():
		finished.emit()
	queue_redraw()
	return true


## Self-test helper: does the whole job with the tools you carry, no mouse. True if finished.
func solve() -> bool:
	holding = true  # the test fits parts straight from the bench
	for _i in 2000:
		if done():
			return true
		var apart := els.any(func(e): return (e.type == "part" and st[e.id] != "new") or (e.type == "task" and st[e.id] != "done"))
		var allowed := ["loosen", "out", "off", "remove", "install", "do"] if apart else ["insert", "tighten", "torque", "on"]
		var moved := false
		for e in els:
			for try_tool in ["torque", e.get("tool", "hand"), "hand"]:
				tool = try_tool
				var a := action(e)
				if a.verb in allowed and (a.tool == "hand" or main.tools.has(a.tool)) and a.tool == tool:
					if not perform(e, a.verb):
						return false
					moved = true
					break
			if moved:
				break
		if not moved:
			return false
	return done()


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
		if not _visible(e):
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
		"task": return st[e.id] == "todo" or e.get("fixture", false)  # fixtures (turnbuckles) stay put once done
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
	draw_set_transform(Vector2.ZERO)
	draw_string(font, Vector2(o.x, 30), "%s  -  %s" % [main.FAULTS[fault].name, def.title], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.98, 0.94, 0.85))
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


func _draw_piece(e: Dictionary) -> void:
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
			var art := _tex("work/%s_%s" % [fault, e.id])
			if art:
				draw_texture_rect(art, e.rect, false)
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
		_cover("spinner", "Spinner", Rect2(hub - Vector2(105, 105), Vector2(210, 210)), [], {"shape": "circle", "col": Color(0.85, 0.86, 0.88)})]
		+ _ring("spinner", hub, 88, 4, "screw", "screwdriver", false, PI / 4)}

	# Spark plugs, engine left side: cowling, four ignition leads, four plugs.
	var plugs := []
	for i in 4:
		var x := 150 + i * 170
		plugs += [_part("plug%d" % i, "Plug %d" % (i + 1), Rect2(x, 160, 60, 110), ["cowl", "lead%d" % i], {"tool": "ratchet", "col": Color(0.85, 0.85, 0.8)}),
			_cover("lead%d" % i, "Lead %d" % (i + 1), Rect2(x - 10, 130, 80, 50), ["cowl"], {"col": Color(0.55, 0.12, 0.1), "verb_off": "Pull the ignition lead", "verb_on": "Push the lead back on"})]
	s.spark_plugs = {"title": "Engine, left side", "deco": engine_deco, "els": plugs + _cowl()}

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
	s.fuel_line = {"title": "Left wing root, underside", "deco": [[Rect2(20, 40, 790, 480), "plane_body_worn", SKIN.darkened(0.2)]],
		"els": [_task("mop", "Wipe up the spilled fuel", Rect2(140, 330, 520, 40), "rag", ["fairing"], {"col": Color(0.3, 0.45, 0.8, 0.6), "hold": 2.0}),
		_part("line", "Fuel line", Rect2(180, 240, 440, 34), ["fairing", "valve"], {"col": Color(0.3, 0.3, 0.75)})]
		+ _at("line", [Vector2(190, 257), Vector2(610, 257)], "nut", "ratchet")
		+ [_cover("fairing", "Wing-root fairing", fr, [], {"col": SKIN})]
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
	s.stale_fuel = {"title": "Left wing, fuel tank and sumps", "deco": wing_deco, "els": [
		_part("fuel", "Avgas", Rect2(160, 170, 500, 120), ["cap"], {"col": Color(0.45, 0.35, 0.12, 0.85), "requires": ["sump_l", "sump_r"],
			"verb_remove": "Drain out the stale fuel", "verb_install": "Fill up with fresh 100LL"}),
		_task("sump_l", "Sump the left tank until it runs clean", Rect2(160, 330, 220, 60), "hand", [], {"col": Color(0.3, 0.45, 0.8, 0.7), "hold": 2.5}),
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

	# Pre-oil a dry engine before its first start in years: top plugs out, turn it by hand.
	var po := []
	for i in 4:
		po.append(_cover("plug%d" % i, "Top plug %d" % (i + 1), Rect2(150 + i * 170, 160, 60, 110), ["cowl"], {"tool": "ratchet", "col": Color(0.85, 0.85, 0.8),
			"verb_off": "Pull the top plug", "verb_on": "Put the plug back in"}))
	s.pre_oil = {"title": "Engine, left side", "deco": engine_deco, "els": [
		_task("turn", "Turn the prop by hand until oil pressure shows", Rect2(150, 290, 520, 40), "hand", ["cowl", "plug0", "plug1", "plug2", "plug3"],
			{"col": Color(0.65, 0.5, 0.15, 0.85), "hold": 4.0})] + po + _cowl()}

	_scenes = s
	return s

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
##   check     a part to search by flashlight on the walk-around (the look_<zone> scenes): todo -> seen. It's
##             bad while the fault it names is on this plane; looking at it is what finds the fault
## "needs" lists covers that must be off first. A cover goes back only once everything that
## needed it off is complete. State lives in job.work[fault], so you can step away mid-job.
## A piece with a "range" (in-lb) is torqued against the needle: every click pulls it up, it sags
## back by itself, and it has to be kept in the band until the wrench clicks.
## Art: textures/work/<fault>_<piece>.png (parts: _old/_new, checks: _bad); until it exists, placeholders.
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
	"tester": "Compression tester", "timing": "Timing light", "punch": "Fabric tester",
}
## Numbers shown in the work scenes: a Continental engine with a wood prop on 3/8 in. (AN6) bolts.
const SPEC := {"prop_bolts": "175-225 in-lb in a star pattern", "plugs": "300-360 in-lb"}
const RANGE := {"prop_bolts": Vector2i(175, 225), "plugs": Vector2i(300, 360)}  # SPEC, as the needle reads it
const BUMP := 0.1  # one pull on the torque wrench lifts the needle this much of the top of the spec
const SAG := 0.4  # and it sags back by this much of itself every second
const GREEN := 1.0  # seconds the needle has to stay in the band before the wrench clicks
const LIGHT := 15.0  # seconds one look with the flashlight lasts
const BEAM := 100.0  # how far the flashlight reaches around the cursor
## Short names for the tool roll buttons: all nine have to fit under the 1000 px scene.
const TOOL_SHORT := {"hand": "Hands", "screwdriver": "Screwdriver", "ratchet": "Ratchet", "torque": "Torque",
	"pliers": "Pliers", "rag": "Rag", "tester": "Tester", "timing": "Timing light", "punch": "Fabric tester"}
const FOD_CHANCE := 0.12  # chance a scene with a cowling has a socket you drop behind a baffle
const DAYS := {"loosen": 0.003, "tighten": 0.003, "torque": 0.004, "out": 0.001, "insert": 0.001,
	"off": 0.003, "on": 0.004, "remove": 0.008, "install": 0.012, "do": 0.012, "soak": 0.02, "look": 0.0}  # a look is paid for when you start it (main._look)
const SKIN := Color(0.93, 0.74, 0.22)
const METAL := Color(0.62, 0.63, 0.66)
const ENGINE := Color(0.3, 0.3, 0.32)
const RUBBER := Color(0.13, 0.13, 0.13)
const BAR := 104.0  # the tool roll along the bottom of the screen
const IDLE_HINT := 20.0  # seconds with no progress before the next step starts to pulse
const HEAD := 50.0  # the job header along the top
const SHORT := {"hand": "Hands", "screwdriver": "Screwdriver", "ratchet": "Ratchet", "torque": "Torque", "pliers": "Pliers", "rag": "Rag"}
## What a piece sounds like coming off (numbers in ids are dropped: plug0 -> plug). Default: part.
const HIT := {"spinner": "panel", "hubcap": "panel", "cowl": "panel", "rocker": "panel", "hatch": "panel", "fairing": "panel",
	"plate": "panel", "top": "panel", "left": "panel", "right": "panel", "strap": "panel", "caliper": "heavy",
	"wire": "snip", "wire_a": "snip", "wire_b": "snip", "pin": "wire", "cotter": "wire", "lead": "thread", "coax": "thread",
	"neg": "thread", "pos": "thread", "plug": "thread", "jack": "jack", "tire": "heavy", "wheel": "heavy", "battery": "heavy",
	"starter": "heavy", "magneto": "heavy", "prop": "wood", "valve": "latch", "cap": "latch", "fuel": "liquid"}
## What running while the mouse is held sounds like: by piece first, then by tool.
const PIECE_HOLD := {"scrape": "scrape", "sealant": "scrape", "nest": "rustle", "straw": "sweep", "pump": "pump",
	"sump_l": "liquid", "sump_r": "liquid", "soak": "spray", "turn": "crank"}
const TOOL_HOLD := {"ratchet": "ratchet", "screwdriver": "screw", "torque": "torque_turn", "pliers": "wire", "rag": "rag"}

var main  # main.gd: tools, inventory, time
var fault: String  # the scene id: a fault, a troubleshooting test, or "hand_prop"
var job: Dictionary
var title_name := ""
var part_name: String
var art := ""  # texture prefix: the scene id, or another scene whose art it borrows
var def: Dictionary
var els: Array = []
var by_id := {}
var st: Dictionary  # piece id -> state, plus "_paid"
var looking := false  # a walk-around look, not a repair: nothing comes apart
var head: String
var sub: String  # the line under it: where you're looking, and the manual reference if the fault has one
var diagram: Texture2D  # textures/diagrams/<the fault's "diagram", or its id>.png: D lays it over the work
var show_diagram := false
var tool := "hand"
var hover := ""
var hold := 0.0
var needle := 0.0  # what the torque wrench reads, in-lb
var green := 0.0  # seconds the needle has been kept in the band
var light := LIGHT  # seconds of flashlight left on this look
var pressing := false  # left button held down over the scene
var holding := false  # the new part is in your hand (picked up from the bench)
const PART_TILE := Rect2(836, 442, 144, 96)  # where the new part sits on the bench
var held_done := false  # an action finished under the held mouse: wait for release before the next
var tick_t := 0.0
var note := ""
var font: Font
var toolbar: HBoxContainer
var k := 1.0  # the scene is drawn scaled up to fill the window
var _flying := []  # pieces on their way to the bench: [texture, color, from rect, age]
var _puffs := []  # [position, velocity, age]
var _shake := 0.0
var _vignette: GradientTexture2D
var _idle := 0.0  # seconds since the last finished step
var _show_next := false  # H held: outline every step you can do right now
var _beam: GradientTexture2D
const NIGHT := Color(0.02, 0.02, 0.04, 0.97)
## Nothing wrong here (or nothing you can see yet): good parts, finished tasks, nothing to buy.
## You can still take it apart and look; it never "finishes".
var healthy := false
var back_button: Button  # opened from a station: the way back to it, across from the tool roll
var shared: Array = []  # the engine cowling and its screws: one state across every engine scene


func setup(m, fault_id: String, j: Dictionary) -> void:
	main = m
	font = m.UI_FONT
	job = j
	fault = fault_id
	looking = fault_id.begins_with("look_")
	var info: Dictionary = {"name": "Walk-around", "part": ""} if looking else m.scene_info(fault_id)
	part_name = info.part
	title_name = info.name
	def = scene_for(fault_id, {} if looking else m.FAULTS.get(fault_id, {}))
	art = def.get("art", fault_id)
	sub = def.title
	els = def.els.duplicate()
	if looking:  # a fault with no point of its own at this spot (new from the manual) hides anywhere on it
		for id in job.faults:
			if "look_" + m.FAULTS[id].zone == fault_id and m._how(job, id) == "walk" and not els.any(func(e): return e.get("fault", "") == id):
				els = els + [_check("f_" + id, m.FAULTS[id].name, Rect2(40, 40, 740, 480), id, {"bare": true})]
	elif m.FAULTS.has(fault_id):
		diagram = _tex("diagrams/" + m.FAULTS[fault_id].get("diagram", fault_id))
		if m.FAULTS[fault_id].has("ref"):
			sub += "   -   " + m.FAULTS[fault_id].ref
	var is_fault: bool = job.get("faults", []).has(fault_id)
	healthy = m.FAULTS.has(fault_id) and not (is_fault and (job.found.has(fault_id) or m._how(job, fault_id) == "walk"))
	if healthy or (is_fault and not job.found.has(fault_id)):
		title_name = m.PLACES.get(fault_id, title_name)  # the place, not the diagnosis
	if healthy:
		part_name = ""
	head = title_name
	if job.work.has(fault_id) and job.work[fault_id].get("_healthy", false) != healthy:
		job.work.erase(fault_id)  # it was fine when you looked; now there's work to do (or the reverse)
	if not job.work.has(fault_id):
		job.work[fault_id] = {"_paid": false, "_healthy": healthy}
	st = job.work[fault_id]
	if healthy or looking:
		st._fod = false
	if not st.has("_fod") and fault_id != "fod" and els.any(func(e): return e.id == "cowl"):
		st._fod = m.rng.randf() < FOD_CHANCE
	if st.get("_fod", false):  # drawn under the cowling: you only see it with the cowl off
		els.push_front(_task("fod", "Pick up the socket you dropped behind the baffle", Rect2(560, 236, 120, 50), "hand", ["cowl"],
			{"optional": true, "col": Color(0.7, 0.72, 0.78, 0.95)}))
	for e in els:
		by_id[e.id] = e
		if e.type != "view" and not st.has(e.id):  # also fills in pieces added since a save
			st[e.id] = _initial(e)
			if e.type == "check":  # the defect could be anywhere on the part: see _spot
				st["_at_" + e.id] = Vector2(randf(), randf())
	if not st.has("_seized"):  # years of weather: now and then one won't come without penetrant
		var stuck := els.filter(func(e): return e.type == "fastener" and e.kind in ["bolt", "nut"])
		st["_seized"] = stuck[randi() % stuck.size()].id if stuck.size() > 0 and not healthy and randf() < 0.4 else ""
	if by_id.has("cowl") and by_id.cowl.type == "cover":
		shared = ["cowl"] + _fasteners("cowl").map(func(f): return f.id)
		var c: Dictionary = job.work.get_or_add("_cowl", {})
		for id in shared:
			if c.has(id):
				st[id] = c[id]
			else:
				c[id] = st[id]
	if m.station_zone != "":
		var back := Button.new()
		back.text = "Back to the " + m.ZONES[m.station_zone].name
		back.focus_mode = Control.FOCUS_NONE
		back.add_theme_font_size_override("font_size", 15)
		back.pressed.connect(func(): m._open_station(m.station_zone))
		back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)  # across from the tool roll
		back.offset_left = -250
		back.offset_right = -16
		back.offset_top = -BAR + 10
		back.offset_bottom = -8
		back_button = back
		add_child(back)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # offsets too, or it stays 64x64 and misses clicks
	mouse_filter = Control.MOUSE_FILTER_STOP
	_vignette = GradientTexture2D.new()
	_vignette.fill = GradientTexture2D.FILL_RADIAL
	_vignette.fill_from = Vector2(0.5, 0.45)
	_vignette.fill_to = Vector2(1.05, 1.05)
	_vignette.gradient = Gradient.new()
	_vignette.gradient.set_color(0, Color(0, 0, 0, 0))
	_vignette.gradient.set_color(1, Color(0, 0, 0, 0.6))
	_vignette.gradient.set_offset(0, 0.55)
	_beam = GradientTexture2D.new()  # the flashlight: clear in the middle, night at the edge
	_beam.fill = GradientTexture2D.FILL_RADIAL
	_beam.fill_from = Vector2(0.5, 0.5)
	_beam.fill_to = Vector2(1.0, 0.5)
	_beam.gradient = Gradient.new()
	_beam.gradient.set_color(0, Color(NIGHT, 0.0))
	_beam.gradient.set_color(1, NIGHT)
	_beam.gradient.set_offset(0, 0.45)
	toolbar = HBoxContainer.new()
	toolbar.theme = m._ui_theme()
	toolbar.alignment = BoxContainer.ALIGNMENT_CENTER
	toolbar.add_theme_constant_override("separation", 6)
	toolbar.anchor_top = 1.0
	toolbar.anchor_right = 1.0
	toolbar.anchor_bottom = 1.0
	toolbar.offset_top = -BAR + 10
	toolbar.offset_bottom = -8
	toolbar.visible = not looking  # nothing comes apart on a walk-around: all you carry is the light
	add_child(toolbar)
	_build_toolbar()
	_preload_art()


func _build_toolbar() -> void:
	# The mouse becomes the tool in your hand, drawn big (96 px) so you always know what you hold.
	var cur := "res://textures/work/cursor_%s.png" % ("flashlight" if looking else tool)
	if ResourceLoader.exists(cur):
		var img: Image = load(cur).get_image()
		img.decompress()
		img.resize(96, 96, Image.INTERPOLATE_LANCZOS)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(10, 10))
	else:
		Input.set_custom_mouse_cursor(null)
	for c in toolbar.get_children():
		c.queue_free()
	var n := 0
	for t in TOOLS:
		n += 1
		var owned: bool = t == "hand" or main.tools.has(t)
		var b := Button.new()
		b.text = "%d  %s" % [n, SHORT.get(t, TOOL_SHORT.get(t, TOOLS[t]))]
		b.tooltip_text = TOOLS[t] if owned else "%s: not in your roll yet. Buy it from the hangar toolbox." % TOOLS[t]
		b.toggle_mode = true
		b.button_pressed = t == tool
		b.disabled = not owned
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(96, 0)
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func(): _pick_tool(t))
		var icon := "res://textures/work/tool_%s.png" % t
		if ResourceLoader.exists(icon):
			b.icon = load(icon)
			b.add_theme_constant_override("icon_max_width", 48)
		toolbar.add_child(b)


func _pick_tool(t: String) -> void:
	if looking:
		return
	tool = t
	main.sound.sfx("tool")
	_build_toolbar()


func _origin() -> Vector2:
	k = minf(size.x / W, (size.y - BAR - HEAD) / H)
	return Vector2((size.x - W * k) / 2, HEAD + (size.y - BAR - HEAD - H * k) / 2)


func _to_scene(p: Vector2) -> Vector2:
	return (p - _origin()) / k


func _to_screen(p: Vector2) -> Vector2:
	return _origin() + p * k


# ---------- rules ----------

## The job here is finished. The shared cowling doesn't count (it closes once, for the whole
## engine) unless `all`: everything back together, cowling included.
func done(all := false) -> bool:
	return els.all(func(e): return (not all and e.id in shared) or _complete(e))


func _initial(e: Dictionary) -> String:
	if healthy and e.type != "cover":
		return {"fastener": "tight", "part": "new", "task": "done", "check": "todo"}[e.type]
	return e.get("start", {"fastener": "tight", "cover": "on", "part": "old", "task": "todo", "check": "todo"}[e.type])


## Something here is apart and not finished: the shared cowling can't close over it.
func _apart() -> bool:
	return els.any(func(e): return e.type != "view" and not e.id in shared and not e.has("trap") \
		and st[e.id] != _initial(e) and not _complete(e))


func _sync_shared() -> void:
	if shared.is_empty():
		return
	var c: Dictionary = job.work._cowl
	for id in shared:
		c[id] = st[id]
	c.get_or_add("apart", {})[fault] = _apart()


func _complete(e: Dictionary) -> bool:
	match e.type:
		"view": return true
		"fastener": return st[e.id] == "tight"
		"task": return st[e.id] == "done" or e.get("optional", false) or e.has("trap")
		"check": return false  # a look is never finished: it ends when the light does
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


func _bad(e: Dictionary) -> bool:  # is the fault this check point shows on the plane right now?
	return e.fault != "" and job.faults.has(e.fault) and not job.fixed.has(e.fault)


## Where on its part the defect sits on this plane: you have to go and find it with the light.
func _spot(e: Dictionary) -> Vector2:
	var at: Vector2 = st.get("_at_" + e.id, Vector2(0.5, 0.5))
	return e.rect.position + e.rect.size * (Vector2(0.2, 0.2) + at * 0.6)


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
				a.why = "Remove the %s first." % _n(by_id[b].name)
				return a
			match s:
				"tight":
					if st.get("_seized", "") == e.id:
						var out := _out_of({"uses": "Penetrant"})
						if out != "":
							a.why = "Seized solid. " + out
							return a
						a.merge({"verb": "soak", "tool": "hand", "hold": 1.5}, true)
					else:
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
				a.why = "Remove the %s first." % _n(by_id[b].name)
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
					a.why = "Complete the %s before reinstalling." % _n(waiting[0].name)
					return a
				if e.id == "cowl":  # one cowling for the whole engine: nothing else can be left apart under it
					var apart: Array = job.work.get("_cowl", {}).get("apart", {}).keys().filter(func(k): return k != fault and job.work._cowl.apart[k])
					if apart.size() > 0:
						a.why = "Finish up at %s first: it's still apart under there." % main.PLACES.get(apart[0], apart[0]).to_lower()
						return a
				if _out_of(e) != "":
					a.why = _out_of(e)
					return a
				a.merge({"verb": "on", "tool": e.tool, "hold": 0.0 if e.tool == "hand" else 0.8}, true)
		"part":
			var b := _blocker(e)
			if b != "":
				a.why = "Remove the %s first." % _n(by_id[b].name)
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
				if e.get("free", false) or healthy:  # cleaned and refitted, or the good one going back
					a.merge({"verb": "install", "tool": t, "hold": hold_s}, true)
					return a
				if not st._paid and main.inventory.get(part_name, 0) <= 0:
					a.why = "New %s%s required. Obtain one at the parts shed." % [part_name, _part_no()]
					return a
				if not holding:
					a.why = "Pick up the new %s from the bench first (click it)." % part_name
					return a
				a.merge({"verb": "install", "tool": t, "hold": hold_s}, true)
		"task":
			if s == "todo":
				var b := _blocker(e)
				if b != "":
					a.why = "Remove the %s first." % _n(by_id[b].name)
					return a
				var req := _unmet(e)
				if req != "":
					a.why = req
					return a
				for x in e.get("on_first", []):  # a cover that has to be back on first, like the fuel valve
					if st[x] != "on":
						a.why = e.get("on_why", "Reinstall the %s first." % _n(by_id[x].name))
						return a
				if _out_of(e) != "":
					a.why = _out_of(e)
					return a
				a.merge({"verb": "do", "tool": e.tool, "hold": e.get("hold", 1.5)}, true)
		"check":
			if s == "todo" and _bad(e):
				a.merge({"verb": "look", "tool": "hand"}, true)
	if a.tool == "torque" and e.has("range"):
		a.range = e.range  # brought up against the needle, click by click: see _pull
		a.hold = 0.0
	if a.hold > 0.0 and main != null and main.settings.get("quick_hold", false):
		a.hold = 0.15  # Settings > Quick hold: a tap instead of a long press
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
			return ("Install the new %s first." % _n(x.name)) if x.type == "part" else ("First: " + _n(x.label) + ".")
	for p in e.get("out", []):  # a part that has to be off first (rinse the screen once it's out)
		if st[p] == "old":
			return "%s first." % by_id[p].get("verb_remove", "Remove the " + _n(by_id[p].name))
	for c in e.get("with", []):  # gear that has to be in place: a tester hose, a timing light
		if st[c] != "on":
			return "%s first." % by_id[c].get("verb_on", "Install the " + _n(by_id[c].name))
	return ""


func _verb_text(e: Dictionary, v: String) -> String:
	match v:
		"loosen": return "Loosen the " + e.kind
		"tighten": return "Tighten the " + e.kind
		"torque": return "Torque the %s to %s" % [e.kind, e.get("spec", "spec")]
		"soak": return "Seized solid. Soak it in penetrant and let it work"
		"out": return "Remove the %s (to the tray)" % e.kind
		"insert": return "Install the " + e.kind
		"off": return e.get("verb_off", "Remove the " + _n(e.name))
		"on": return e.get("verb_on", "Reinstall the " + _n(e.name))
		"remove": return e.get("verb_remove", "Remove the old " + _n(e.name))
		"install": return e.get("verb_install", "Install the new " + _n(e.name))
		"do": return e.label
		"look": return "Something's wrong here. Write it up"
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
			if not st._paid and not e.get("free", false) and not healthy:
				main.inventory[part_name] -= 1
				st._paid = true
			st[e.id] = "new"
			if not els.any(func(x): return x.type == "part" and not x.get("free", false) and st[x.id] != "new"):
				holding = false  # nothing left to fit (a set like 4 plugs stays in hand until all are in)
		"do":
			if e.has("trap"):  # the wrong move: it costs a little time and teaches why
				note = e.trap
				main.sound.sfx("deny")
				var ok: bool = main._work_time(0.03)
				queue_redraw()
				return ok
			st[e.id] = "done"
			st["_last"] = e.id
			if e.get("hook", false):
				main.task_done(fault, e.id)
		"look":
			st[e.id] = "seen"
			if _bad(e):
				job.found[e.fault] = true
				main.sound.chime()
				main.playlog("found " + e.fault)
		"soak":
			st["_seized"] = ""
			main.inventory["Penetrant"] -= 1
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
		main.used_supply(fault, e.uses, healthy)
	_feel(e, v)
	_idle = 0.0
	_sync_shared()
	if not main._work_time(DAYS[v] + extra):
		return false
	hover = _hit(_to_scene(get_local_mouse_position()))  # what was under the cursor may have moved
	if done() and not healthy:
		if st.get("_fod", false) and st.get("fod", "") != "done":
			job["fod"] = true  # closed up with the socket still in there: it rattles on the run-up
			st._fod = false
		finished.emit()
	queue_redraw()
	return true


## The sound and movement of a finished step, so every action lands.
func _feel(e: Dictionary, v: String) -> void:
	var hit: String = HIT.get(_base(e.id), "part")
	var s: String = {"loosen": "seat" if e.get("kind", "") == "screw" else "breakfree", "tighten": "seat", "torque": "click",
		"out": "tray", "insert": "thread", "off": hit, "remove": hit, "on": "seat_panel" if hit == "panel" else hit,
		"install": "seat_panel" if hit == "panel" else hit, "do": "", "soak": "", "look": "tool"}[v]
	main.sound.sfx(s)
	var c: Vector2 = e.pos if e.type == "fastener" else e.rect.get_center()
	if v == "off" and e.id == "cowl":
		main._found_hidden()  # whatever else was hiding in there
	if v in ["off", "remove"]:
		var art := _tex("work/%s_%s" % [fault, e.id]) if e.type == "cover" else _tex("work/%s_%s_old" % [fault, e.id])
		_flying.append([art, e.get("col", METAL), e.rect, 0.0])
	if not v in ["tighten", "look"]:
		for i in 7:
			_puffs.append([c, Vector2.from_angle(randf() * TAU) * randf_range(20, 70), 0.0])
	if hit == "heavy" and v in ["off", "remove", "on", "install"]:
		_shake = 5.0 if main.settings.shake else 0.0


func _base(id: String) -> String:
	return id.rstrip("0123456789")


## One pull on the torque wrench lifts the needle. Past the top of the band it's over-torqued:
## a fastener comes back off to be run down and brought up fresh.
func _pull(e: Dictionary, a: Dictionary) -> void:
	needle += a.range.y * BUMP
	main.sound.sfx("ratchet")
	if needle > a.range.y:
		note = "%d in-lb: over. Back it off and bring it up again." % int(needle)
		needle = 0.0
		green = 0.0
		main.sound.sfx("deny")
		if e.type == "fastener":
			st[e.id] = "loose"
		main._work_time(DAYS.torque)
	queue_redraw()


## The needle sags between pulls. Keep it in the band long enough and the wrench clicks.
func _sag(delta: float) -> void:
	var a := action(by_id[hover]) if hover != "" else {}
	if not a.has("range") or a.tool != tool:  # the wrench came off
		needle = 0.0
		green = 0.0
		return
	needle -= needle * SAG * delta
	if needle < 5.0:
		needle = 0.0
	green = green + delta if needle >= a.range.x else maxf(0.0, green - delta)
	if green >= GREEN:
		needle = 0.0
		green = 0.0
		perform(by_id[hover], a.verb)
	queue_redraw()


## Self-test helper: does the whole job with the tools you carry, no mouse. True if finished.
## Takes things apart until every part and task is done, then puts it all back. When a step
## needs a cover back on mid-job (oil refill with the drain plug in), it puts that one back.
func solve() -> bool:
	if looking:  # the test finds everything the light could
		for e in els:
			if action(e).verb == "look" and not perform(e, "look"):
				return false
		set_process(false)
		finished.emit()
		return true
	holding = true  # the test fits parts straight from the bench
	var placed := {}  # pieces put back mid-job (a valve back on, its line nuts in): don't undo them
	for _i in 3000:
		if done(true):
			return true
		var apart := els.any(func(e): return (e.type == "part" and st[e.id] != "new") \
			or (e.type == "task" and st[e.id] != "done" and not e.has("trap")))
		var r := _solve_step(apart, placed)
		if r == "" and apart:
			r = _solve_step(false, placed)
			if r != "" and r != "!":
				placed[r] = true
		if r == "":
			return false
		if r == "!":
			return false  # the owner gave up mid-job
	return done(true)


## One move: the first piece that can make progress. Returns its id, "" if none, "!" if the job ended.
func _solve_step(apart: bool, placed: Dictionary) -> String:
	var allowed := ["loosen", "soak", "out", "off", "remove", "install", "do"] if apart else ["insert", "tighten", "torque", "on"]
	for e in els:
		if e.type == "view" or e.has("trap"):
			continue
		for try_tool in ["torque", e.get("tool", "hand"), "hand"]:
			tool = try_tool
			var a := action(e)
			var verb_ok: bool = a.verb in allowed
			if e.type == "cover" and e.get("rest", "on") == "off":  # test gear goes on while working, off after
				verb_ok = a.verb != "" and (a.verb == "on") == apart
			if verb_ok and a.verb in ["off", "out", "loosen"] and placed.has(e.id):
				verb_ok = false
			if verb_ok and (a.tool == "hand" or main.tools.has(a.tool)) and a.tool == tool:
				if not perform(e, a.verb):
					return "!"
				return e.id
	return ""


## " (No. 50483)" for this job's part when the parts book knows it, else "". Read once per scene.
var _no_cache = null


func _part_no() -> String:
	if _no_cache == null:
		_no_cache = ""
		if main != null and main.get("parts_book") != null and main.FAULTS.has(fault):
			var no: String = main.parts_book.no_for_fault(fault)
			_no_cache = "" if no == "" else " (No. %s)" % no
	return _no_cache


## [text, short?]: the part and consumables this job still needs, e.g. "Needs: Gasket x8 (have 2)".
func _need_line() -> Array:
	if looking or healthy:
		return ["", false]
	var mats := {}
	for e in els:
		if e.has("uses") and not _complete(e):
			mats[e.uses] = mats.get(e.uses, 0) + 1
	var bits := []
	var short := false
	if part_name != "" and not st._paid:
		var have: int = main.inventory.get(part_name, 0)
		bits.append("New %s (have %d)" % [part_name, have])
		short = short or have <= 0
	for m in mats:
		var have: int = main.inventory.get(m, 0)
		bits.append("%s x%d (have %d)" % [m, mats[m], have])
		short = short or have < mats[m]
	return ["" if bits.is_empty() else "Needs: " + ", ".join(bits), short]


## The next-step pulse after IDLE_HINT seconds, or every step you can do now while H is held.
func _draw_next_marks() -> void:
	var marks: Array = []
	if _show_next or _idle > IDLE_HINT:
		marks = els.filter(func(e): return e.type != "view" and action(e).verb != "")
		if not _show_next and marks.size() > 0:
			marks = [marks[0]]
	if marks.is_empty():
		return
	var col := Color(Style.COLOR_FOCUS, 0.55 + 0.45 * sin(Time.get_ticks_msec() / 220.0))
	draw_set_transform(_origin(), 0.0, Vector2(k, k))
	for e in marks:
		if e.type == "fastener":
			draw_arc(e.pos, 18, 0, TAU, 24, col, 3.0)
		else:
			var b: Rect2 = e.rect.grow(4)
			for side in [[b.position, Vector2(b.end.x, b.position.y)], [Vector2(b.end.x, b.position.y), b.end],
					[b.end, Vector2(b.position.x, b.end.y)], [Vector2(b.position.x, b.end.y), b.position]]:
				draw_dashed_line(side[0], side[1], col, 3.0, 8.0)
	draw_set_transform(Vector2.ZERO)


# ---------- input ----------

func _gui_input(ev: InputEvent) -> void:
	if show_diagram:  # any click puts the diagram away
		if ev is InputEventMouseButton and ev.pressed:
			show_diagram = false
			queue_redraw()
		return
	if ev is InputEventMouseMotion:
		var h := _hit(_to_scene(ev.position))
		if h != hover:
			hover = h
			hold = 0.0
			note = ""
		queue_redraw()
	elif ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var bp := _to_scene(ev.position)
		if ev.pressed and part_name != "" and PART_TILE.has_point(bp):  # the new part on the bench
			var have_part: bool = st._paid or main.inventory.get(part_name, 0) > 0
			var waiting: bool = els.any(func(x): return x.type == "part" and st[x.id] != "new")
			if have_part and waiting:
				holding = not holding
				main.sound.sfx("tool")
				note = ("Holding the new %s. Click where it goes." % part_name) if holding else "Put it back on the bench."
			elif not have_part:
				note = "No new %s%s on the bench. Buy one at the parts shed (or mail-order it)." % [part_name, _part_no()]
			queue_redraw()
			return
		if ev.pressed and hover != "":
			var e: Dictionary = by_id[hover]
			var a := action(e)
			note = ""
			if a.verb == "":
				note = a.why if main.guide("medium") else "Not yet."
				main.sound.sfx("deny")
			elif a.tool != tool:
				note = ("Use the %s for that%s." % [TOOLS[a.tool],
					"" if a.tool == "hand" or main.tools.has(a.tool) else " (it's in the hangar toolbox)"]) if main.guide("medium") else "Wrong tool for that."
				main.sound.sfx("deny")
			elif a.has("range"):
				_pull(e, a)
			elif a.hold == 0.0:
				held_done = true
				perform(e, a.verb)
		pressing = ev.pressed
		if not ev.pressed:
			hold = 0.0
			held_done = false
		queue_redraw()
	elif ev is InputEventMouseButton and ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var keys := TOOLS.keys().filter(func(t): return t == "hand" or main.tools.has(t))  # tools you own, in roll order
		var i := (keys.find(tool) + (1 if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1) + keys.size()) % keys.size()
		_pick_tool(keys[i])


func _unhandled_key_input(ev: InputEvent) -> void:  # 1-9 pick a tool from the roll, H what's next
	if ev is InputEventKey and ev.physical_keycode == KEY_H and not ev.echo:
		_show_next = ev.pressed  # hold H to see every step you can do now
		queue_redraw()
		get_viewport().set_input_as_handled()
		return
	if ev.pressed and not ev.echo and ev.physical_keycode >= KEY_1 and ev.physical_keycode < KEY_1 + mini(TOOLS.size(), 9):
		var t: String = TOOLS.keys()[ev.physical_keycode - KEY_1]
		if t == "hand" or main.tools.has(t):
			_pick_tool(t)
	elif ev.pressed and not ev.echo and ev.physical_keycode == KEY_D and diagram:
		show_diagram = not show_diagram
		queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Input.set_custom_mouse_cursor(null)  # back to the normal pointer outside the scene
		if is_instance_valid(main) and is_instance_valid(main.sound):
			main.sound.stop_loop()


var _settle := 3  # redraw the first few frames so freshly uploaded art shows without a mouse move


func _process(delta: float) -> void:
	if _settle > 0:
		_settle -= 1
		queue_redraw()
	if not looking:
		_idle += delta
		if _idle > IDLE_HINT:
			queue_redraw()  # keep the pulse moving
	if _flying.size() > 0 or _puffs.size() > 0 or _shake > 0.0:
		for f in _flying:
			f[3] += delta / 0.3
		for p in _puffs:
			p[0] += p[1] * delta
			p[2] += delta / 0.45
		_flying = _flying.filter(func(f): return f[3] < 1.0)
		_puffs = _puffs.filter(func(p): return p[2] < 1.0)
		_shake = maxf(0.0, _shake - delta * 20.0)
		queue_redraw()
	if looking:  # the light runs down whether you find anything or not
		light -= delta
		queue_redraw()
		if light <= 0.0:
			set_process(false)
			finished.emit()
			return
	if needle > 0.0:
		_sag(delta)
	if hover == "" or held_done or not pressing:
		main.sound.stop_loop()
		return
	var e: Dictionary = by_id[hover]
	var a := action(e)
	if a.verb == "" or a.hold == 0.0 or a.tool != tool:
		main.sound.stop_loop()
		return
	main.sound.loop(PIECE_HOLD.get(_base(e.id), TOOL_HOLD.get(a.tool, "")))
	hold += delta
	if hold >= a.hold:
		hold = 0.0
		held_done = true
		main.sound.stop_loop()
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
		if e.type == "check":  # only a defect can be picked out, and only by going right to it
			if action(e).verb == "look" and p.distance_to(_spot(e)) < 26:
				return e.id
		elif e.type == "fastener":
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
	for n in ["work/%s_bg" % art, "work/screw", "work/bolt", "work/nut", "icon_" + fault]:
		_tex(n)
	for e in els:
		if e.type == "view":
			continue
		var a: String = e.get("art", e.id)
		for n in ["work/%s_%s" % [art, a], "work/%s_%s_old" % [art, a], "work/%s_%s_new" % [art, a], "work/%s_%s_bad" % [art, a], e.get("tex", "")]:
			if n != "":
				_tex(n)


func _draw() -> void:
	var o := _origin() + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
	var bg := _tex("work/%s_bg" % art)
	draw_rect(Rect2(Vector2.ZERO, size), main.C_EARTH)
	if bg:  # the same spot, dimmed, fills the window edges instead of black bars
		draw_texture_rect(bg, Rect2(Vector2.ZERO, size), false, Color(0.28, 0.26, 0.24))
	draw_set_transform(o, 0.0, Vector2(k, k))
	if bg:
		draw_texture_rect(bg, Rect2(0, 0, W, H), false)
	else:
		draw_rect(Rect2(0, 0, W, H), Color(0.2, 0.19, 0.18))
		for d in def.get("deco", []):
			_fill(d[0], d[1], d[2], d[3] if d.size() > 3 else "rect")
	for e in els:
		if _visible(e):
			_draw_piece(e)
	if looking:
		_draw_dark()
	_draw_bench()
	for f in _flying:  # lifted off, sliding across to the bench and shrinking
		var t: float = ease(f[3], 0.5)
		var to := Rect2(BENCH.get_center() - Vector2(30, 30), Vector2(60, 60))
		var r := Rect2(f[2].position.lerp(to.position, t), f[2].size.lerp(to.size, t))
		if f[0]:
			draw_texture_rect(f[0], r, false, Color(1, 1, 1, 1.0 - f[3] * 0.6))
		else:
			draw_rect(r, Color(f[1], 1.0 - f[3] * 0.6))
	for p in _puffs:
		draw_circle(p[0], 2.0 + p[2] * 3.0, Color(0.85, 0.8, 0.7, 0.45 * (1.0 - p[2])))
	_draw_notes()
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(_vignette, Rect2(Vector2.ZERO, size), false)
	# Job header, laid over the top of the picture.
	draw_rect(Rect2(0, 0, size.x, HEAD), main.C_EARTH)
	draw_rect(Rect2(0, HEAD - 1, size.x, 1), Color(main.C_BRASS, 0.5))
	draw_string(main.HEAD_FONT, Vector2(24, 24), head.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, main.C_PAPER)
	draw_string(font, Vector2(24, 41), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, main.C_BRASS)
	var need := _need_line()
	if need[0] != "":
		draw_string(font, Vector2(size.x - 264 - 520, 41), need[0], HORIZONTAL_ALIGNMENT_RIGHT, 520, 13,
			Style.COLOR_TEXT_HUD_BLOCKED if need[1] else main.C_BRASS)
	var ok := els.filter(func(e): return _complete(e)).size()
	draw_string(Style.figures(), Vector2(size.x - 244, 22), ("Day %d   %d s of light left" % [floori(main.day), ceili(light)]) if looking
		else "Day %d   %d of %d steps in place" % [floori(main.day), ok, els.size()], HORIZONTAL_ALIGNMENT_RIGHT, 220, Style.SIZE_XS, main.C_BRASS)  # a counter: one-width digits
	draw_rect(Rect2(size.x - 244, 31, 220, 4), Color(main.C_BRASS, 0.2))
	draw_rect(Rect2(size.x - 244, 31, 220.0 * (light / LIGHT if looking else float(ok) / els.size()), 4), main.C_BRASS)
	# The tool roll.
	draw_rect(Rect2(0, size.y - BAR, size.x, BAR), main.C_EARTH)
	draw_rect(Rect2(0, size.y - BAR, size.x, 1), Color(main.C_BRASS, 0.5))
	var hint := Vector2(24, size.y - BAR + 40)
	for line in (["Sweep the flashlight over the plane", "Click anything that looks wrong", "Esc: done looking"] if looking
			else ["Hold the mouse to turn", "Wheel or 1-%d: tool    H: what's next" % mini(TOOLS.size(), 9), ("Esc: back to the %s" % main.ZONES[main.station_zone].name) if main.station_zone != "" else "Esc: step away, work is kept"] + (["D: wiring diagram"] if diagram else [])):
		draw_string(font, hint, line, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.HUD_HINT_SIZE, Color(main.C_BRASS, 0.85))
		hint.y += 17
	if holding and _tex("icon_" + fault):  # the part rides along with the cursor until it's fitted
		draw_texture_rect(_tex("icon_" + fault), Rect2(get_local_mouse_position() + Vector2(30, -10), Vector2(64, 64)), false)
	if show_diagram:
		var area := Rect2(0, HEAD, size.x, size.y - HEAD - BAR)
		var fit := minf(area.size.x / diagram.get_width(), area.size.y / diagram.get_height()) * 0.96
		draw_rect(area, Color(main.C_EARTH, 0.94))
		draw_texture_rect(diagram, Rect2(area.get_center() - diagram.get_size() * fit / 2.0, diagram.get_size() * fit), false)
		return
	if not looking:
		_draw_next_marks()
	if hover != "":
		_draw_hover(by_id[hover])
	_draw_crosshair()


## Marks the exact spot the tool is working: the big tool cursor hides it. A green ring means the
## tool in your hand can do something there.
func _draw_crosshair() -> void:
	var m := get_local_mouse_position()
	if m.y < HEAD or m.y > size.y - BAR:
		return
	var a := action(by_id[hover]) if hover != "" else {"verb": "", "tool": ""}
	var ready: bool = a.verb != "" and a.tool == tool
	var col: Color = Color(0.6, 0.9, 0.55) if ready else main.C_PAPER
	for pass_ in [[Color(0, 0, 0, 0.7), 3.5], [col, 1.5]]:  # dark underneath, so it reads on bright paint too
		for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			draw_line(m + d * 5.0, m + d * 13.0, pass_[0], pass_[1])
		if ready:
			draw_arc(m, 17.0, 0.0, TAU, 32, pass_[0], pass_[1])


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
	if healthy and (e.type == "view" or (e.type == "task" and st[e.id] == "done")):
		return  # nothing wrong to show, and no reading to give
	if e.type == "view":
		var v: String = main.view_art(fault, e.id)
		if v == "":
			return
		var t := _tex(v)
		if t:
			draw_texture_rect(t, e.get("art_rect", e.rect), false)
		else:
			draw_rect(e.rect, Color(0.95, 0.88, 0.55, 0.85))
			_label(e.rect, v.get_file().trim_prefix(fault + "_").replace("_", " "))
		return
	var s: String = st[e.id]
	match e.type:
		"cover":
			var cname: String = main.view_art(fault, e.id) if e.get("dyn", false) else "work/%s_%s" % [art, e.get("art", e.id)]
			var cart := _tex(cname) if cname != "" else null
			if cart:
				draw_texture_rect(cart, e.get("art_rect", e.rect), false)
				return
			_fill(e.rect, e.get("tex", "plane_body_worn"), e.get("col", SKIN), e.get("shape", "rect"))
			_label(e.rect, e.name)
		"part":
			if s == "out":  # the bare spot shows through; a faint outline says where the new one goes
				var painted := _tex("work/%s_bg" % art) != null
				if not painted:
					draw_rect(e.rect, Color(0, 0, 0, 0.35))
				draw_dashed_line(e.rect.position, e.rect.position + Vector2(e.rect.size.x, 0), Color(1, 1, 1, 0.5), 2.0, 8.0)
				draw_dashed_line(e.rect.end, e.rect.end - Vector2(e.rect.size.x, 0), Color(1, 1, 1, 0.5), 2.0, 8.0)
				if not painted:
					_label(e.rect, "(empty: new %s goes here)" % e.name)
				return
			var part_art := _tex("work/%s_%s_%s" % [art, e.get("art", e.id), s])
			if part_art:
				draw_texture_rect(part_art, e.get("art_rect", e.rect), false)
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
			var name := "work/%s_%s" % [art, e.get("art", e.id)]
			if e.get("dyn", false):  # art picked by what the test shows (a plug's condition)
				name = main.view_art(fault, e.id) if s == "done" else ""
			elif e.get("art_done", false):
				name = name if s == "done" else ""
			var task_art := _tex(name) if name != "" else null
			if task_art:
				draw_texture_rect(task_art, e.get("art_rect", e.rect), false)
				return
			if (e.get("dyn", false) or e.get("art_done", false)) and s == "done":
				_fill(e.rect, "", Color(0.85, 0.82, 0.72, 0.9))
				_label(e.rect, main.reading(fault, e.id) if e.get("dyn", false) else e.name)
				return
			if _tex("work/%s_bg" % art):  # painted scene: a quiet hotspot, not a big block
				draw_rect(e.rect, Color(0.05, 0.04, 0.03, 0.45))
				draw_rect(e.rect, Color(1, 0.9, 0.6, 0.7), false, 1.5)
				if not main.guide("medium"):
					return  # hard: the step is only named when you hover it
				var sz := font.get_string_size(e.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
				draw_string(font, Vector2(e.rect.get_center().x - minf(sz.x, e.rect.size.x) / 2, e.rect.get_center().y + 5), e.label,
					HORIZONTAL_ALIGNMENT_LEFT, e.rect.size.x, 13, Color(1, 0.95, 0.85))
				return
			_fill(e.rect, e.get("tex", ""), e.get("col", Color(0.15, 0.12, 0.08, 0.8)))
			if main.guide("medium"):
				_label(e.rect, e.label)
		"check":
			if _tex("work/%s_bg" % fault) == null and not e.has("bare"):  # placeholder: the part as a named box
				_fill(e.rect, "", e.get("col", SKIN), e.get("shape", "rect"))
				_label(e.rect, e.name)
			if not _bad(e):
				return
			var p := _spot(e)
			var art := _tex("work/%s_%s_bad" % [fault, e.id])
			if art:  # the defect, small, painted over a background that shows the part sound
				draw_texture_rect(art, Rect2(p - Vector2(32, 32), Vector2(64, 64)), false)
			else:  # placeholder: a rusty patch scored with cracks
				draw_circle(p, 18, Color(0.62, 0.3, 0.1))
				for i in 3:
					var c: Vector2 = p + Vector2(i * 10 - 14, -13)
					draw_polyline([c, c + Vector2(7, 9), c + Vector2(2, 16), c + Vector2(10, 26)], Color(0.1, 0.07, 0.05), 2.0)
		"fastener":
			_draw_fastener(e, s)


## Righty-tighty: a tight fastener backs out counter-clockwise, anything else is going in.
## Positive rotation is clockwise on screen.
static func spin_dir(state: String) -> float:
	return -1.0 if state == "tight" else 1.0


func _draw_fastener(e: Dictionary, s: String) -> void:
	var p: Vector2 = e.pos
	if s == "out":
		draw_circle(p, 5, Color(0.05, 0.05, 0.05))  # empty hole
		return
	var lift := Vector2(-3, -3) if s == "loose" else Vector2.ZERO
	if e.id == hover and hold > 0.0:  # turning under the tool
		var spun := _origin() + (p + lift) * k
		draw_set_transform(spun, hold * 9.0 * spin_dir(s), Vector2(k, k))
		p = -lift
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
	if e.id == hover and hold > 0.0:
		draw_set_transform(_origin(), 0.0, Vector2(k, k))


func _label(r: Rect2, t: String) -> void:
	var sz := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	draw_string(font, Vector2(r.get_center().x - sz.x / 2, r.end.y - 6), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.1, 0.08, 0.06))


func _draw_bench() -> void:
	var painted := _tex("work/%s_bg" % art) != null  # the background already has a wooden bench
	draw_rect(BENCH, Color(0.12, 0.08, 0.05, 0.45) if painted else Color(0.36, 0.27, 0.18))
	draw_rect(BENCH, Color(0.2, 0.14, 0.08), false, 2.0)
	var y := BENCH.position.y + 22
	if looking:  # no bench on a walk-around: this is your write-up of what you've found so far
		draw_string(font, Vector2(BENCH.position.x + 10, y), "WRITE-UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.95, 0.88, 0.7))
		var w := BENCH.size.x - 16
		for e in els:
			if st[e.id] == "seen" and _bad(e):
				var t: String = "%s: %s" % [e.name, main.CLUES[e.fault]]
				y += 24
				draw_multiline_string(font, Vector2(BENCH.position.x + 8, y), t, HORIZONTAL_ALIGNMENT_LEFT, w, 12, -1, Color(0.95, 0.65, 0.4))
				y += font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, w, 12).y - 12
		return
	draw_string(font, Vector2(BENCH.position.x + 10, y), "BENCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.95, 0.88, 0.7))
	var tray := els.filter(func(f): return f.type == "fastener" and st[f.id] == "out").size()
	y += 22
	draw_string(font, Vector2(BENCH.position.x + 10, y), "Magnetic tray: %d" % tray, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.85, 0.75))
	for row in _bench_rows():
		var e: Dictionary = row[1]
		var r: Rect2 = row[0]
		draw_rect(r, Color(0.45, 0.35, 0.24) if e.type == "cover" else Color(0.3, 0.22, 0.15))
		var t: String = e.name
		if e.type == "part":
			t = (e.name + " (to clean)") if e.get("free", false) else ("Old " + e.name + " (scrap)")
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
	draw_set_transform(_origin(), 0.0, Vector2(k, k))
	if e.type == "fastener":
		draw_arc(e.pos, 16, 0, TAU, 24, main.C_BRASS, 2.0)
	elif e.type == "check":
		draw_arc(_spot(e), 26, 0, TAU, 24, main.C_BRASS, 2.0)
	else:
		draw_rect(e.rect, main.C_BRASS, false, 2.0)
	var a := action(e)
	var c: Vector2 = e.pos if e.type == "fastener" else e.rect.get_center()
	if a.has("range") and a.tool == tool:
		_draw_torque(c, a.range)
	elif hold > 0.0 and a.hold > 0.0:
		draw_arc(c, 22, -PI / 2, -PI / 2 + TAU * hold / a.hold, 32, Color(0.95, 0.75, 0.15), 4.0)
	draw_set_transform(Vector2.ZERO)
	var line: String = e.name if e.type != "fastener" else by_id[e.host].name + " " + e.kind
	if e.type == "task":
		line = e.label
		if st[e.id] == "done" and e.get("note", false) and not healthy:
			line = main.reading(fault, e.id)
	var how := ""
	var bad := false
	if a.verb != "" and not main.guide("medium"):  # hard: what you'd do, not what to do it with
		how = _verb_text(e, a.verb)
	elif a.verb != "":
		how = "%s  [%s%s]" % [_verb_text(e, a.verb), TOOLS[a.tool], ", click fast: keep the needle in the green" if a.has("range") else ", hold" if a.hold > 0 else ""]
		if a.tool != "hand" and not main.tools.has(a.tool):
			how += "  - get it from the hangar toolbox"
			bad = true
	elif not main.guide("medium"):
		how = "Not yet." if st[e.id] != "done" and a.why != "" else "Nothing to do here."
	else:
		how = a.why if a.why != "" else "Nothing to do here."
		bad = a.why != ""
	if note != "":
		how = note
		bad = true
	var m := get_local_mouse_position() + Vector2(18, 20)
	var w := maxf(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, font.get_string_size(how, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x) + 24
	m.x = minf(m.x, size.x - w - 8)
	m.y = minf(m.y, size.y - BAR - 58)
	draw_rect(Rect2(m, Vector2(w, 50)), Color(main.C_EARTH, 0.94))
	draw_rect(Rect2(m, Vector2(3, 50)), Color(0.85, 0.45, 0.2) if bad else main.C_BRASS)
	draw_string(font, m + Vector2(12, 20), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, main.C_PAPER)
	draw_string(font, m + Vector2(12, 39), how, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.65, 0.4) if bad else main.C_BRASS)


## A beam torque wrench's scale over the work: the green band is the spec, the needle is your
## pull, and the outer arc fills as you keep it there.
func _draw_torque(c: Vector2, spec: Vector2i) -> void:
	var top := spec.y * 1.4
	draw_arc(c, 44, PI, TAU, 32, Color(0, 0, 0, 0.75), 14.0)  # left to right over the top
	draw_arc(c, 44, PI + PI * spec.x / top, PI + PI * spec.y / top, 12, Color(0.35, 0.75, 0.35), 10.0)
	draw_arc(c, 56, PI, PI + PI * green / GREEN, 24, Color(0.6, 0.9, 0.55), 4.0)
	draw_line(c, c + Vector2.from_angle(PI + PI * needle / top) * 52, main.C_PAPER, 3.0)
	draw_rect(Rect2(c + Vector2(-40, -86), Vector2(80, 22)), Color(0, 0, 0, 0.75))
	draw_string(font, c + Vector2(-40, -70), "%d in-lb" % int(needle), HORIZONTAL_ALIGNMENT_CENTER, 80, 14, main.C_PAPER)


## Night over everything but the pool of the flashlight. What's already written up stays marked.
func _draw_dark() -> void:
	var m := get_local_mouse_position()
	var r := BEAM * k
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(_beam, Rect2(m - Vector2(r, r), Vector2(r, r) * 2.0), false)
	# The four sides round the lit square. One that runs off the window comes out negative and lands outside it.
	for side in [Rect2(0, 0, size.x, m.y - r), Rect2(0, m.y + r, size.x, size.y - m.y - r),
			Rect2(0, m.y - r, m.x - r, r * 2.0), Rect2(m.x + r, m.y - r, size.x - m.x - r, r * 2.0)]:
		draw_rect(side, NIGHT)
	draw_set_transform(_origin(), 0.0, Vector2(k, k))
	for e in els:
		if st[e.id] == "seen" and _bad(e):
			var p := _spot(e)
			draw_arc(p, 26, 0, TAU, 32, main.C_RED, 3.0)
			draw_string(font, p + Vector2(-4, 6), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, main.C_RED)


# ---------- the scenes ----------

## A rect from the art kit's suggested center and size.
static func _c(cx: float, cy: float, w: float, h: float) -> Rect2:
	return Rect2(cx - w / 2, cy - h / 2, w, h)


## A click area at least min_w x min_h around a small piece's art rect.
static func _pad(r: Rect2, min_w := 70.0, min_h := 40.0) -> Rect2:
	var gx := maxf(0, (min_w - r.size.x) / 2)
	var gy := maxf(0, (min_h - r.size.y) / 2)
	return r.grow_individual(gx, gy, gx, gy)


static func _cover(id: String, name: String, r: Rect2, needs := [], o := {}) -> Dictionary:
	var e := {"id": id, "type": "cover", "name": name, "rect": r, "needs": needs, "tool": "hand"}
	e.merge(o, true)
	return e


static func _part(id: String, name: String, r: Rect2, needs := [], o := {}) -> Dictionary:
	var e := {"id": id, "type": "part", "name": name, "rect": r, "needs": needs}
	e.merge(o, true)
	return e


## A walk-around point: sound unless `fault` is on this plane and not yet fixed.
static func _check(id: String, name: String, r: Rect2, fault := "", o := {}) -> Dictionary:
	var e := {"id": id, "type": "check", "name": name, "rect": r, "fault": fault}
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


## The rocker cover and its gasket: one cylinder's domed cover on a lobed flange, as on the C-85,
## with a screw in each of its six lobes. The art (oil_leak_rocker, oil_leak_gasket_*) is cut to this rect.
const ROCKER_RECT := Rect2(260, 110, 320, 190)


## The six cover screws, one per lobe, on an ellipse around the cover's center.
static func _rocker_screws() -> Array:
	var c := ROCKER_RECT.get_center()
	var pts := []
	for i in 6:
		var t := deg_to_rad(60.0 * i)
		pts.append(c + Vector2(cos(t) * 140.0, sin(t) * 80.0))
	return pts


## Fasteners at the four corners of a rect, inset.
static func _corners(host: String, r: Rect2, kind: String, tool: String, inset := 16.0) -> Array:
	var g := r.grow(-inset)
	return _at(host, [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)], kind, tool)


static func _cowl(needs := []) -> Array:  # the side cowling, same on every engine job
	var r := Rect2(40, 40, 760, 300)
	return [_cover("cowl", "Cowling", r, needs, {"tex": "cowling_metal", "col": SKIN})] + _at("cowl",
		[Vector2(60, 60), Vector2(420, 52), Vector2(780, 60), Vector2(780, 320), Vector2(420, 328), Vector2(60, 320)], "screw", "screwdriver")


const TEXT_PATH := "res://data/job_text.json"


## On-screen wording lives in data/job_text.json (service-manual style, keyed by job and piece id), so
## it can be rewritten without touching the job logic. A missing file or key keeps the built-in text.
static func _apply_text(s: Dictionary) -> void:
	if not FileAccess.file_exists(TEXT_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(TEXT_PATH))
	if not d is Dictionary:
		push_warning("work.gd: can't read " + TEXT_PATH)
		return
	for f in d:
		if not s.has(f):
			continue
		if d[f].has("title"):
			s[f].title = d[f].title
		var over: Dictionary = d[f].get("els", {})
		for e in s[f].els:
			if over.has(e.id):
				for key in over[e.id]:
					if key != "label" or e.type == "task":
						e[key] = over[e.id][key]


## A piece's name inside a sentence: "the cowling", but "the No. 4 upper spark plug" and "the P-lead" stay.
static func _n(name: String) -> String:
	if name.length() < 2 or name.begins_with("No. ") or name.substr(1, 1) == name.substr(1, 1).to_upper():
		return name
	return name.substr(0, 1).to_lower() + name.substr(1)


static var _scenes := {}


## Tools and materials a repair can't be finished without: {tool ids} and {material: uses}.
## Torqued fasteners need the torque wrench as well as their own tool.
static func needs_for(fault_id: String, f: Dictionary) -> Array:
	var tools := {}
	var mats := {}
	for e in scene_for(fault_id, f).els:
		tools[e.get("tool", "hand")] = true
		if e.get("torque", false):
			tools["torque"] = true
		if e.has("uses"):
			mats[e.uses] = mats.get(e.uses, 0) + 1
	tools.erase("hand")
	return [tools, mats]


## The scene for a fault (f: its main.FAULTS row). One with no scene of its own yet (new from the
## manual) gets a plain one: an access panel on four screws, over the part on four bolts, which
## are torqued if the row gives a "torque" range. A fault with no part is one job behind the panel.
static func scene_for(id: String, f: Dictionary) -> Dictionary:
	if scenes().has(id):
		return scenes()[id]
	var r := Rect2(300, 190, 220, 180)
	var bolts := _corners("part", r, "bolt", "ratchet")
	if f.has("torque"):
		for b in bolts:
			b.merge({"torque": true, "range": f.torque, "spec": "%d-%d in-lb" % [f.torque.x, f.torque.y]}, true)
	var work: Array = [_part("part", f.part, r, ["panel"])] + bolts if f.part != "" else [_task("fix", "Put it right", r, "hand", ["panel"])]
	var panel := Rect2(220, 120, 380, 320)
	return {"title": "Behind the access panel", "deco": [[Rect2(20, 40, 790, 480), "plane_body_worn", SKIN.darkened(0.2)]],
		"els": work + [_cover("panel", "Access panel", panel)] + _corners("panel", panel, "screw", "screwdriver")}


static func scenes() -> Dictionary:
	if _scenes.size() > 0:
		return _scenes
	var engine_deco := [[Rect2(30, 30, 780, 500), "", Color(0.16, 0.16, 0.17)], [Rect2(80, 80, 680, 260), "metal_steel", ENGINE]]
	var s := {}

	# Propeller, nose head-on (Continental 6-4, 9-3c): mags OFF, cut the safety wire, six hub bolts
	# through the face plate, face plate off, prop off. Back on: bolts torqued 200-220 in-lb in a star,
	# safety-wired in pairs, then track the blades within 1/8 in.
	var hub := Vector2(410, 280)
	s.propeller = {"title": "Nose, head-on: propeller hub", "deco": [[Rect2(250, 120, 320, 320), "", SKIN.darkened(0.3), "circle"]],
		"els": [_task("track", "Track the blades: tips within 1/16 inch", Rect2(560, 400, 220, 50), "hand", ["mags"], {"requires": ["prop"], "col": Color(0.35, 0.3, 0.2, 0.85), "hold": 2.0}),
		_part("prop", "Propeller", Rect2(40, 245, 740, 70), ["mags", "plate"], {"tex": "prop_wood", "col": Color(0.62, 0.4, 0.2)}),
		_cover("plate", "Prop face plate", Rect2(hub - Vector2(105, 105), Vector2(210, 210)), ["mags", "wire"], {"col": Color(0.85, 0.86, 0.88)})]
		+ _ring("plate", hub, 52, 6, "bolt", "ratchet", true)
		+ [_cover("wire", "Safety wire", Rect2(hub - Vector2(70, 70), Vector2(140, 140)), ["mags"],
			{"tool": "pliers", "col": Color(0.75, 0.75, 0.78, 0.35), "verb_off": "Cut the safety wire", "verb_on": "Safety-wire the bolts in pairs", "uses": "Safety wire"}),
		_cover("mags", "Mag switch", Rect2(40, 60, 150, 70), [], {"col": Color(0.2, 0.2, 0.2), "verb_off": "Switch the mags OFF and check the P-leads before touching the prop",
			"verb_on": "Take the OFF tag down: prop done"})]}
	for e in s.propeller.els:
		if e.get("torque", false):
			e.spec = SPEC.prop_bolts
			e.range = RANGE.prop_bolts

	# Spark plugs, engine left side (Continental 9-3g, Table of Limits T-1): cylinders 4 and 2 end-on,
	# a top and a bottom plug in each. Lead elbow nut off, plug out, new copper gasket, plug gapped,
	# in and torqued 300-360 in-lb, lead back on. The right side is the same job.
	var plug_at := [Vector2(160, 66), Vector2(300, 166), Vector2(460, 66), Vector2(600, 166)]
	var plug_name := ["Cyl 4 top plug", "Cyl 4 bottom plug", "Cyl 2 top plug", "Cyl 2 bottom plug"]
	var plugs := []
	for i in 4:
		var p: Vector2 = plug_at[i]
		plugs += [_task("gasket%d" % i, "Fit a new copper gasket", Rect2(p.x + 6, p.y + 84, 48, 22), "hand", ["cowl", "lead%d" % i],
				{"uses": "Gasket", "out": ["plug%d" % i], "col": Color(0.8, 0.5, 0.25, 0.9), "hold": 0.6}),
			_part("plug%d" % i, plug_name[i], Rect2(p.x, p.y, 60, 110), ["cowl", "lead%d" % i], {"col": Color(0.85, 0.85, 0.8), "requires": ["gasket%d" % i, "gap"]})]
		plugs += _at("plug%d" % i, [Vector2(p.x + 30, p.y + 71)], "plug", "ratchet")
		plugs[-1].merge({"torque": true, "spec": SPEC.plugs, "range": RANGE.plugs})
		plugs += [_cover("lead%d" % i, "Lead %d" % (i + 1), Rect2(p.x - 10, p.y - 30, 80, 50), ["cowl"], {"tool": "ratchet", "col": Color(0.55, 0.12, 0.1),
			"verb_off": "Unscrew the lead's elbow nut and pull it straight out", "verb_on": "Seat the lead and run the elbow nut down"})]
	s.spark_plugs = {"title": "Engine, left side (cylinders 4 and 2): the right side is the same", "deco": engine_deco,
		"els": [_task("gap", "Gap the new plugs .016-.021 in", Rect2(150, 400, 520, 36), "hand", ["cowl"], {"hold": 1.5})] + plugs + _cowl()}

	# Oil leak: wipe the mess, rocker cover off, scrape, new gasket.
	var rc := ROCKER_RECT  # one cylinder's domed rocker cover, lobed at its six screws (C-85)
	s.oil_leak = {"title": "Engine, left side: rocker cover", "deco": engine_deco, "els": [
		_part("gasket", "Rocker cover gasket", rc, ["cowl", "rocker"], {"col": Color(0.75, 0.35, 0.15), "requires": ["scrape"]}),
		_task("scrape", "Scrape the old gasket off both faces", Rect2(rc.position.x + 20, rc.end.y - 50, rc.size.x - 40, 30), "rag", ["cowl", "rocker"], {"hold": 2.0}),
		_cover("rocker", "Rocker cover", rc, ["cowl"], {"tex": "metal_steel", "col": METAL})]
		+ _at("rocker", _rocker_screws(), "screw", "screwdriver")
		+ [_task("wipe", "Wipe the engine down so the leak shows", Rect2(120, 290, 600, 40), "rag", ["cowl"], {"tex": "oil_puddle", "col": Color(0.2, 0.15, 0.05, 0.9), "hold": 2.0})]
		+ _cowl()}

	# Bird nest: reach in and pull it out by the handful, then clean up the straw.
	s.bird_nest = {"title": "Engine, top", "deco": engine_deco, "els": [
		_task("straw", "Sweep out the loose straw", Rect2(140, 250, 540, 60), "rag", ["cowl"], {"requires": ["nest"], "col": Color(0.7, 0.6, 0.35, 0.8)}),
		_task("nest", "Pull the nest out", Rect2(300, 110, 240, 140), "hand", ["cowl"], {"tex": "bark", "col": Color(0.75, 0.6, 0.4), "hold": 2.5})] + _cowl()}

	# Starter, C85-12 (Continental 10-25, 10-26): master and ignition OFF, cockpit pull cable off the
	# shift lever, power cable nut off, three nuts and two through bolts, tap it free of its gasket.
	# Back on: scrape the pad, new gasket with paste, bolts run down evenly.
	var sr := Rect2(130, 200, 260, 110)
	var st_f := _at("starter", [sr.position + Vector2(20, 20), Vector2(sr.position.x + 20, sr.get_center().y), Vector2(sr.position.x + 20, sr.end.y - 20),
		Vector2(sr.position.x + 70, sr.position.y + 8), Vector2(sr.position.x + 70, sr.end.y - 8)], "nut", "ratchet")
	st_f[3].kind = "bolt"  # the two through bolts from the front of the crankcase flange
	st_f[4].kind = "bolt"
	s.starter = {"title": "Engine, rear accessory case: starter pad", "deco": engine_deco, "els": [
		_task("gasket", "Scrape the pad, fit a new gasket with paste", Rect2(125, 195, 100, 120), "rag", ["cowl", "master"], {"uses": "Gasket", "out": ["starter"], "col": Color(0.8, 0.5, 0.25, 0.9), "hold": 1.5}),
		_part("starter", "Starter motor", sr, ["cowl", "master", "cable", "pull"], {"col": Color(0.25, 0.25, 0.28), "requires": ["gasket"]})]
		+ st_f
		+ [_cover("pull", "Starter pull cable", Rect2(250, 150, 150, 46), ["cowl"], {"tool": "pliers", "col": Color(0.3, 0.3, 0.32),
			"verb_off": "Unhook the cockpit pull cable from the shift lever", "verb_on": "Hook the pull cable back on and check the lever returns"}),
		_cover("cable", "Starter power cable", Rect2(400, 230, 260, 40), ["cowl", "master"], {"col": Color(0.55, 0.12, 0.1), "verb_off": "Take the power cable off and tape its end"})]
		+ _at("cable", [Vector2(420, 250)], "nut", "ratchet") + _cowl(["master"])
		+ [_cover("master", "Master and ignition", Rect2(690, 420, 120, 80), [], {"col": Color(0.15, 0.15, 0.15),
			"verb_off": "Switch the master and the ignition OFF", "verb_on": "Master back on for the starter test"})]}

	# Magneto (Continental 10-8 to 10-12): harness outlet plate off, P-lead off, two nuts and washers,
	# pull it straight back with its drive gear. Back on: new gasket with paste, No. 1 up on
	# compression at the firing angle (left mag 30 deg BTC), turn the case until the timing light
	# shows the points opening, tighten, then back the crank up and check again.
	var mr := Rect2(470, 130, 220, 170)
	s.magneto = {"title": "Engine, rear accessory case: left magneto", "deco": engine_deco, "els": [
		_task("timing", "Time it: No. 1 at 30 deg BTC, turn the case till the light shows the points opening", Rect2(130, 260, 260, 50), "screwdriver", ["cowl"],
			{"fixture": true, "requires": ["magneto"], "col": Color(0.2, 0.3, 0.2, 0.85), "hold": 3.0}),
		_task("gasket", "Fit a new flange gasket with paste", Rect2(540, 250, 80, 60), "hand", ["cowl", "cap", "plead"], {"uses": "Gasket", "out": ["magneto"], "col": Color(0.8, 0.5, 0.25, 0.9), "hold": 0.8}),
		_part("magneto", "Magneto", mr, ["cowl", "cap", "plead"], {"col": Color(0.15, 0.15, 0.17), "requires": ["gasket"]})]
		+ _at("magneto", [Vector2(mr.position.x - 14, mr.end.y - 30), Vector2(mr.end.x + 14, mr.end.y - 30)], "nut", "ratchet")
		+ [_cover("cap", "Harness outlet plate", Rect2(mr.position + Vector2(30, 20), Vector2(160, 70)), ["cowl"], {"col": Color(0.2, 0.2, 0.5)})]
		+ _at("cap", [mr.position + Vector2(44, 55), mr.position + Vector2(176, 55)], "screw", "screwdriver")
		+ [_cover("plead", "P-lead", Rect2(510, 170, 300, 60), ["cowl"], {"tool": "ratchet", "col": Color(0.6, 0.6, 0.62),
			"verb_off": "Unscrew the P-lead union nut", "verb_on": "Reconnect the P-lead (or the mag stays hot)"})] + _cowl()}

	# Carb heat: cable clamp at the heat box, new cable, then check the door's full travel.
	var cc := Rect2(120, 170, 460, 40)
	s.carb_heat = {"title": "Engine, carb heat box", "deco": engine_deco + [[Rect2(590, 130, 160, 140), "", Color(0.4, 0.4, 0.42)]], "els": [
		_task("travel", "Pull and push the knob: door moves full travel", Rect2(150, 280, 520, 40), "hand", ["cowl"], {"requires": ["cable"], "col": Color(0.2, 0.3, 0.2, 0.85), "hold": 2.0}),
		_part("cable", "Carb heat cable", cc, ["cowl", "swivel"], {"col": Color(0.25, 0.25, 0.27)})]
		+ _at("cable", [Vector2(cc.position.x + 30, cc.position.y + 20)], "screw", "screwdriver")
		+ [_cover("swivel", "Cable swivel", Rect2(560, 165, 50, 50), ["cowl"], {"col": Color(0.7, 0.6, 0.3)})]
		+ _at("swivel", [Vector2(585, 190)], "nut", "ratchet") + _cowl()}

	# Flat tire: jack the wing, hubcap, cotter pin, axle nut, swap, pump up, lower.
	var wc := Vector2(400, 300)
	var wheel_deco := [[Rect2(0, 470, 820, 90), "gravel", Color(0.7, 0.68, 0.62)], [Rect2(380, 40, 40, 160), "", SKIN.darkened(0.2)]]
	s.tire = {"title": "Left main wheel, outside", "deco": wheel_deco, "els": [
		_task("pump", "Pump to 35 psi to seat the beads, let down to 15", Rect2(600, 380, 200, 70), "hand", [], {"requires": ["tire"], "col": Color(0.4, 0.15, 0.1, 0.9), "hold": 2.5}),
		_task("deflate", "Let all the air out (valve core out)", Rect2(440, 120, 90, 60), "hand", ["jack"], {"col": Color(0.3, 0.3, 0.3, 0.8), "hold": 1.5}),
		_part("tire", "Tire & tube", Rect2(wc - Vector2(170, 170), Vector2(340, 340)), ["jack", "hubcap", "pin"], {"shape": "circle", "col": RUBBER, "after": ["deflate"]})]
		+ _at("tire", [wc], "nut", "ratchet")
		+ [_cover("pin", "Cotter pin", Rect2(wc - Vector2(22, 40), Vector2(44, 24)), ["hubcap"], {"tool": "pliers", "col": Color(0.8, 0.7, 0.3), "verb_off": "Pull the cotter pin", "verb_on": "Fit a new cotter pin and bend it", "uses": "Cotter pin"}),
		_cover("hubcap", "Hub cap", Rect2(wc - Vector2(70, 70), Vector2(140, 140)), [], {"shape": "circle", "col": METAL})]
		+ _ring("hubcap", wc, 52, 3, "screw", "screwdriver", false, -PI / 2)
		+ [_cover("jack", "Jack", Rect2(80, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Jack the axle up", "verb_on": "Lower the plane back down"})]}

	# Brake shoes (J-3 parts list Fig. 8): jack the axle, cotter and axle nut, wheel and drum off,
	# brake line off its bracket, four bolts, shoe assembly off the flange. New shoes on, line on,
	# wheel on, then bleed the air out at the bleeder.
	var bc := Vector2(330, 290)
	s.brakes = {"title": "Right main wheel, inside: drum brake", "deco": wheel_deco, "els": [
		_task("bleed", "Bleed the brake until the hose runs clear", Rect2(410, 120, 140, 50), "ratchet", [], {"requires": ["disc"], "col": Color(0.6, 0.1, 0.1, 0.8), "hold": 2.5, "uses": "Brake fluid"}),
		_part("disc", "Brake shoes & expander tube", Rect2(bc - Vector2(120, 120), Vector2(240, 240)), ["wheel", "caliper"], {"shape": "circle", "col": Color(0.55, 0.45, 0.4)})]
		+ _ring("disc", bc, 80, 4, "bolt", "ratchet", false, PI / 4)
		+ [_cover("wheel", "Wheel and drum", Rect2(bc - Vector2(160, 160), Vector2(320, 320)), ["jack", "pin"], {"shape": "circle", "col": RUBBER})]
		+ _at("wheel", [bc], "nut", "ratchet")
		+ [_cover("pin", "Cotter pin", Rect2(bc - Vector2(22, 40), Vector2(44, 24)), ["jack"], {"tool": "pliers", "col": Color(0.8, 0.7, 0.3), "verb_off": "Pull the cotter pin", "verb_on": "Fit a new cotter pin and bend it", "uses": "Cotter pin"}),
		_cover("caliper", "Brake line bracket", Rect2(520, 160, 120, 150), ["jack"], {"col": Color(0.6, 0.15, 0.12), "verb_off": "Break the brake line loose and unbolt its bracket"})]
		+ _at("caliper", [Vector2(580, 185), Vector2(580, 285)], "bolt", "ratchet")
		+ [_cover("jack", "Jack", Rect2(650, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Jack the axle up", "verb_on": "Lower the plane back down"})]}

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
		_task("leak", "Fuel ON: check both B-nuts for leaks", Rect2(150, 200, 500, 30), "hand", ["fairing"],
			{"requires": ["line"], "on_first": ["valve"], "on_why": "Turn the fuel back ON first: a dry line can't show you a leak.", "col": Color(0.3, 0.45, 0.8, 0.5), "hold": 2.0}),
		_part("line", "Fuel line", Rect2(180, 240, 440, 34), ["fairing", "valve"], {"col": Color(0.3, 0.3, 0.75), "verb_remove": "Back off both B-nuts (hold the fitting with a second wrench) and lift the line out"})]
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
		_cover("plate", "Tail inspection panel", pr, [], {"tex": "plane_body_worn", "col": SKIN})]
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
		_task("sump_l", "Drain the tank through the gascolator", Rect2(160, 330, 220, 60), "hand", [], {"col": Color(0.3, 0.45, 0.8, 0.7), "hold": 2.5}),
		_task("sump_r", "Sump the strainer until the sample runs blue", Rect2(440, 330, 220, 60), "hand", [], {"col": Color(0.3, 0.45, 0.8, 0.7), "hold": 2.5}),
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

	# Pre-oil a dry engine (Continental 7-1, 7-3): one plug out of each cylinder on this side so it
	# turns easily, pressure pot on the gallery, turn it by hand until oil pressure shows.
	var po := []
	for i in 4:
		var p: Vector2 = plug_at[i]
		po.append(_cover("plug%d" % i, plug_name[i], Rect2(p.x, p.y, 60, 110), ["cowl"], {"tool": "ratchet", "col": Color(0.85, 0.85, 0.8),
			"verb_off": "Pull the plug", "verb_on": "Put the plug back in"}))
	s.pre_oil = {"title": "Engine, left side", "deco": engine_deco, "els": [
		_task("turn", "Pump the pot and turn the prop by hand until oil pressure shows", Rect2(150, 350, 520, 40), "hand", ["cowl", "plug0", "plug1", "plug2", "plug3"],
			{"col": Color(0.65, 0.5, 0.15, 0.85), "hold": 4.0, "note": true, "turns_prop": true})] + po + _cowl()}

	# Walk-around looks, one per inspection spot (main.ZONES), everything closed up as you find it,
	# in the dark, by flashlight. A point naming a fault hides that defect somewhere on it while
	# this plane has it; the rest are just the parts you see (the placeholder scenery).
	var body := [[Rect2(20, 40, 790, 480), "plane_body_worn", SKIN.darkened(0.2)]]
	var dark := {"col": Color(0.2, 0.2, 0.22)}
	var tyre := {"shape": "circle", "col": RUBBER}
	s.look_prop = {"title": "Nose, head-on", "deco": s.propeller.deco, "els": [
		_check("blade_l", "Left blade", Rect2(40, 245, 265, 70), "", {"col": Color(0.62, 0.4, 0.2)}),
		_check("blade_r", "Right blade", Rect2(515, 245, 265, 70), "propeller", {"col": Color(0.62, 0.4, 0.2)}),
		_check("inlets", "Cowl inlets", Rect2(290, 130, 240, 40), "", dark),
		_check("spinner", "Spinner", Rect2(hub - Vector2(105, 105), Vector2(210, 210)), "", {"shape": "circle", "col": Color(0.85, 0.86, 0.88)})]}
	s.look_engine = {"title": "Engine, left side, cowled", "deco": engine_deco + [[Rect2(40, 40, 760, 300), "cowling_metal", SKIN]], "els": [
		_check("inlet", "Cowl inlet", Rect2(60, 70, 200, 90), "bird_nest", dark),
		_check("screws", "Cowl fasteners", Rect2(300, 180, 180, 100)),
		_check("dipstick", "Oil dipstick", Rect2(520, 90, 90, 150), "pre_oil", {"col": METAL}),
		_check("belly", "Cowl underside", Rect2(200, 350, 440, 60), "oil_leak", {"col": SKIN.darkened(0.25)}),
		_check("exhaust", "Exhaust stack", Rect2(660, 360, 110, 130), "", {"col": METAL})]}
	s.look_cabin = {"title": "Cabin, left side", "deco": body, "els": [
		_check("screen", "Windshield", Rect2(140, 90, 400, 220), "windshield", {"col": Color(0.7, 0.8, 0.85)}),
		_check("strut", "Wing strut fitting", Rect2(140, 360, 160, 80), "", {"col": METAL}),
		_check("hinge", "Door hinge", Rect2(600, 150, 60, 260), "door_pin", {"col": METAL}),
		_check("latch", "Door latch", Rect2(700, 260, 80, 70), "", {"col": METAL})]}
	s.look_gear_l = {"title": "Left main wheel, outside", "deco": wheel_deco, "els": [
		_check("leg", "Gear leg", Rect2(370, 30, 60, 95)),
		_check("line", "Brake line", Rect2(600, 150, 40, 250), "", dark),
		_check("tire", "Tire", Rect2(wc - Vector2(170, 170), Vector2(340, 340)), "", tyre),
		_check("hubcap", "Hubcap", Rect2(wc - Vector2(70, 70), Vector2(140, 140)), "", {"shape": "circle", "col": METAL}),
		_check("tread", "Tread", Rect2(wc + Vector2(-150, 70), Vector2(300, 90)), "tire", {"col": RUBBER.lightened(0.08)})]}
	s.look_gear_r = {"title": "Right main wheel, inside", "deco": wheel_deco, "els": [
		_check("leg", "Gear leg", Rect2(300, 20, 60, 100)),
		_check("caliper", "Brake caliper", Rect2(520, 160, 120, 150), "", {"col": Color(0.6, 0.15, 0.12)}),
		_check("tire", "Tire", Rect2(bc - Vector2(160, 160), Vector2(320, 320)), "", tyre),
		_check("disc", "Brake disc", Rect2(bc - Vector2(100, 100), Vector2(200, 200)), "brakes", {"shape": "circle", "col": METAL})]}
	s.look_wing_l = {"title": "Left wing, underside", "deco": body, "els": [
		_check("cap", "Fuel cap", Rect2(380, 60, 80, 60), "", {"col": METAL}),
		_check("root", "Wing root", Rect2(120, 150, 300, 120), "fuel_line"),
		_check("pitot", "Pitot tube", Rect2(560, 150, 160, 50), "", {"col": METAL}),
		_check("sump", "Fuel sump sample", Rect2(160, 330, 220, 60), "stale_fuel", {"col": Color(0.45, 0.6, 0.9)}),
		_check("aileron", "Aileron hinge", Rect2(520, 330, 240, 60), "", {"col": METAL})]}
	s.look_battery = {"title": "Battery bay, right side", "deco": body, "els": [  # a battery only shows itself on the run-up
		_check("static", "Static port", Rect2(60, 200, 80, 80), "", {"col": METAL}),
		_check("hatch", "Access hatch", Rect2(180, 100, 460, 280)),
		_check("vent", "Battery vent", Rect2(660, 200, 80, 80), "", dark),
		_check("skin", "Belly skin", Rect2(180, 410, 460, 70), "", {"col": SKIN.darkened(0.25)})]}
	s.look_tail = {"title": "Tail, left side", "deco": body, "els": [
		_check("plate", "Inspection plate", Rect2(80, 150, 260, 120)),
		_check("elevator", "Elevator hinge", Rect2(260, 300, 280, 60), "", {"col": METAL}),
		_check("wheel", "Tailwheel", Rect2(380, 420, 110, 110), "", tyre),
		_check("rudder", "Rudder", Rect2(560, 60, 200, 360), "control_cables")]}

	_troubleshooting(s, engine_deco)
	_more_jobs(s, engine_deco, wheel_deco, wing_deco)
	_apply_text(s)
	_scenes = s
	return s


## The left side of a C85 shows cylinders 4 and 2, two plugs each: the spark test lays those four out.
const SPARK_PLUGS := ["cyl 4 top", "cyl 4 bottom", "cyl 2 top", "cyl 2 bottom"]
## Cold cylinder marks, seen from below: the riser of cylinder 4, 2, 3 and 1 in that order.
const RISERS := [[4, Vector2(300, 120)], [2, Vector2(570, 120)], [3, Vector2(360, 368)], [1, Vector2(630, 368)]]


## The troubleshooting tests and the jobs from the art kit (docs/JOB_ART_GUIDE.md). Piece ids
## match the kit's file names; rects come from its suggested centers and sizes.
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
		st_els.append(_task("plug%d" % i, "Pull the %s plug, lay it on the rail" % SPARK_PLUGS[i], _pad(_c(181 + i * 160, 326, 138, 48), 138, 60), "ratchet", ["cowl"],
			{"art_rect": _c(181 + i * 160, 326, 138, 48), "fixture": true, "art_done": true, "hide_after": "replug", "hold": 0.8}))
		st_els.append({"id": "spark%d" % i, "type": "view", "name": "Spark, " + SPARK_PLUGS[i], "rect": _c(247 + i * 160, 326, 50, 50)})
	s.spark_test = {"title": "Engine, left side", "els": st_els + _cowl()}

	# Cold cylinder (AC 43.13-1B 8-2): a heat crayon mark on each stack, run it briefly, and
	# the stack whose mark didn't melt belongs to the cylinder that isn't firing.
	var cc := [_task("pencil", "Mark each riser 1 in below the flange", _pad(_c(668, 515, 117, 14), 150, 40), "hand", [],
			{"art_rect": _c(668, 515, 117, 14), "hold": 2.0}),
		_task("run", "Run it 30 seconds at 1,200 rpm", Rect2(60, 470, 260, 46), "hand", [], {"requires": ["pencil"], "note": true, "hold": 2.5})]
	for i in 4:
		cc.append({"id": "mark%d" % i, "type": "view", "name": "Mark, cylinder %d" % RISERS[i][0], "rect": _c(RISERS[i][1].x, RISERS[i][1].y, 53, 24)})
	s.cold_cylinder = {"title": "Engine from below, exhaust risers", "els": cc}

	# Compression (M-0 6-4.11.2): 80 psi into each cylinder at top center; where the air
	# hisses out names the leak: exhaust valve, intake valve or rings.
	var cp := [{"id": "tester", "type": "view", "name": "Tester", "rect": _c(532, 449, 216, 142)},
		{"id": "hiss_exhaust", "type": "view", "name": "Hiss at the tailpipe", "rect": _c(777, 482, 50, 60)},
		{"id": "hiss_intake", "type": "view", "name": "Hiss at the carb air scoop", "rect": _c(249, 430, 50, 60)},
		{"id": "hiss_rings", "type": "view", "name": "Hiss at the oil filler", "rect": _c(485, 76, 50, 60)}]
	for i in 4:
		cp.append(_task("p%d" % i, "Cyl %d: top center, 80 psi in" % (i + 1), Rect2(30, 120 + i * 50, 190, 44), "tester", ["cowl"],
			{"with": ["hose"], "turns_prop": true, "note": true, "fixture": true, "hold": 2.0}))
	cp.append(_cover("hose", "Tester hose", _c(322, 277, 284, 226), ["cowl"], {"start": "off", "rest": "off",
		"verb_on": "Pull a top plug, screw in the tester hose", "verb_off": "Tester hose out, plug back in", "col": Color(0.1, 0.1, 0.1, 0.8)}))
	s.compression = {"title": "Engine, differential compression", "els": cp + _cowl()}

	# Reading plugs: lay them in the tray in order and read each firing end.
	var rp := []
	for i in 4:
		for row in [["t", "top", 210], ["b", "bottom", 360]]:
			rp.append(_task("%s%d" % [row[0], i], "Cyl %d %s plug to the tray" % [i + 1, row[1]], _c(162 + i * 115, row[2], 96, 100), "ratchet", [],
				{"fixture": true, "dyn": true, "note": true, "hold": 0.6}))
	var all8 := rp.map(func(e): return e.id)
	rp.append(_task("back", "Clean, gap .016-.021, new gaskets, back in", Rect2(114, 440, 440, 46), "torque", [], {"requires": all8, "hold": 2.5}))
	s.reading_plugs = {"title": "Bench, plug tray", "deco": bench_deco, "els": rp}

	# Oil screen (M-0 6-4.8.2): rinse it over a white towel, sort the metal with a magnet.
	s.oil_screen = {"title": "Bench, oil screen", "deco": bench_deco, "els": [
		{"id": "screen", "type": "view", "name": "Screen", "rect": _c(201, 255, 234, 66)},
		{"id": "metal", "type": "view", "name": "Metal", "rect": _c(522, 358, 170, 79)},
		{"id": "magnet_v", "type": "view", "name": "Magnet", "rect": _c(722, 418, 114, 64)},
		_task("pull", "Cut the wire, pull the oil screen", Rect2(84, 300, 234, 40), "pliers", [], {"hold": 1.5}),
		_task("rinse", "Rinse it over the towel", Rect2(84, 170, 234, 40), "rag", [], {"requires": ["pull"], "note": true, "hold": 2.0}),
		_task("magnet", "Touch the magnet to the flakes", Rect2(642, 456, 160, 40), "hand", [], {"requires": ["rinse"], "note": true, "hold": 1.0}),
		_task("back", "Screen in: new crush gasket, 500-520 in-lb, wired", Rect2(84, 470, 400, 46), "torque", [], {"requires": ["magnet"], "uses": "Safety wire", "hold": 2.0})]}

	# Hot magneto: tag the prop first, then a new P-lead so the switch grounds the mag again.
	var pl := _c(657, 200, 294, 47)
	s.hot_mag = {"title": "Rear accessory case", "els": [
		_task("check", "Switch OFF, pull it through: no spark", Rect2(300, 420, 300, 46), "hand", ["cowl"], {"requires": ["plead"], "with": ["tag"], "turns_prop": true, "note": true, "hold": 2.0}),
		_part("plead", "P-lead", pl, ["cowl"], {"with": ["tag"], "col": Color(0.3, 0.3, 0.32)})]
		+ _at("plead", [Vector2(pl.position.x + 14, pl.get_center().y)], "nut", "ratchet")
		+ [_cover("tag", "DANGER tag", _c(145, 195, 110, 150), [], {"start": "off", "rest": "off", "col": Color(0.8, 0.12, 0.1),
			"verb_on": "Hang the DANGER tag on the prop", "verb_off": "Take the DANGER tag down"})] + _cowl()}

	# Fuel vent: a mud dauber nest in the cap's vent tube starves the engine a minute after start.
	s.fuel_vent = {"title": "Fuel cap, nose deck", "els": [
		_task("nest", "Pull the nest out of the vent", _c(554, 164, 112, 82), "hand", [], {"hold": 2.5}),
		_task("wire", "Run a wire through the vent tube", Rect2(560, 400, 230, 46), "pliers", [], {"requires": ["nest"], "hold": 1.5}),
		_task("crumbs", "Brush the mud off the deck", _c(551, 351, 286, 32), "rag", [], {"requires": ["nest"], "hold": 1.2}),
		_task("blow", "Blow through the vent", Rect2(560, 456, 230, 46), "hand", [], {"requires": ["wire"], "note": true, "hold": 1.0})]}

	# Water in the fuel: sump until the cup comes up all blue.
	s.water_fuel = {"title": "Under the nose, gascolator", "els": [
		{"id": "cup", "type": "view", "name": "Fuel tester", "rect": _c(430, 358, 80, 176)},
		_task("sump1", "Sump the gascolator into the cup", Rect2(570, 250, 230, 46), "hand", [], {"note": true, "hold": 1.5}),
		_task("tank", "Pull the tank drain till it runs clean", Rect2(570, 306, 230, 46), "hand", [], {"requires": ["sump1"], "hold": 2.5}),
		_task("sump2", "Sump it again", Rect2(570, 362, 230, 46), "hand", [], {"requires": ["tank"], "note": true, "hold": 1.5}),
		_task("spill", "Rake the spilled fuel into the gravel", _c(430, 500, 300, 31), "rag", [], {"show_after": "sump1", "requires": ["sump2"], "hold": 1.2})]}


## Everything else from JOBS_ATA.md. Kit-backed scenes use the kit's piece names; the rest are
## placeholders until art exists (ART_PROMPTS.md).
static func _more_jobs(s: Dictionary, engine_deco: Array, wheel_deco: Array, wing_deco: Array) -> void:
	var panel_deco := [[Rect2(20, 40, 790, 480), "", Color(0.13, 0.12, 0.11)], [Rect2(60, 80, 700, 200), "cockpit_panel", Color(0.5, 0.45, 0.38)]]
	var tail_deco := [[Rect2(20, 60, 790, 420), "plane_body_worn", SKIN.darkened(0.2)]]
	var prop_deco := [[Rect2(250, 120, 320, 320), "", SKIN.darkened(0.3), "circle"], [Rect2(40, 245, 740, 70), "prop_wood", Color(0.62, 0.4, 0.2)]]

	# ---- from the art kit ----

	# Oil change: pan under, drain plug out, screen out and rinsed (oil_screen can follow), four quarts in.
	var oc := [{"id": "stream", "type": "view", "name": "Draining oil", "rect": _c(446, 345, 9, 70)},
		_task("drain", "Let the old oil drain into the pan", Rect2(570, 456, 230, 46), "hand", ["plug"], {"with": ["pan"], "hold": 2.5}),
		_part("screen", "Oil screen", _c(641, 355, 234, 66), [], {"free": true, "after": ["drain"], "requires": ["rinse"], "tool": "pliers",
			"verb_remove": "Cut the wire, pull the oil screen", "verb_install": "Screen in: new crush gasket, wired"}),
		_task("rinse", "Rinse the screen, try a magnet on it", Rect2(570, 400, 230, 40), "rag", [], {"out": ["screen"], "note": true, "hold": 2.0}),
		_cover("plug", "Drain plug", _pad(_c(452, 304, 44, 42), 60, 50), [], {"art_rect": _c(452, 304, 44, 42), "tool": "ratchet", "uses": "Safety wire",
			"verb_off": "Cut the wire, pull the drain plug", "verb_on": "Drain plug in, safety-wired"}),
		_cover("pan", "Drain pan", _c(445, 516, 280, 80), [], {"start": "off", "rest": "off", "verb_on": "Slide the drain pan under", "verb_off": "Pull the pan out, empty it"})]
	for i in 5:  # the C85 takes 4-1/2 quarts
		oc.append(_task("quart%d" % i, "Pour in quart %d" % (i + 1) if i < 4 else "Pour in the last half quart", _c(76 + i * 64, 508, 64, 100), "hand", [],
			{"art": "quart", "requires": ["screen"], "with": ["plug"], "uses": "Aviation oil", "hold": 1.0}))
	s.oil_change = {"title": "Engine from below, oil sump", "els": oc}

	# Fuel strainer: cut the wire, slack the bail nut, bowl and screen off, rinse, back up and wired.
	s.fuel_strainer = {"title": "Firewall, gascolator", "els": [
		_part("bowl", "Strainer bowl", _c(490, 300, 80, 112), ["nut"], {"free": true, "requires": ["rinse"], "verb_remove": "Drop the bowl", "verb_install": "Bowl back up, new gasket"}),
		_part("screen", "Strainer screen", _c(490, 269, 68, 38), ["nut"], {"free": true, "requires": ["rinse"], "verb_remove": "Pull the screen", "verb_install": "Screen back in"}),
		_task("rinse", "Rinse the bowl and screen in clean fuel", Rect2(570, 220, 230, 46), "rag", [], {"out": ["bowl", "screen"], "hold": 2.0}),
		_cover("nut", "Bail thumb nut", _pad(_c(490, 377, 34, 26), 60, 40), ["wire", "valve"], {"art_rect": _c(490, 377, 34, 26),
			"verb_off": "Slack the bail nut, swing the bail down", "verb_on": "Bail up, thumb nut snug"}),
		_cover("wire", "Bail nut safety wire", _pad(_c(535, 364, 46, 34), 60, 40), [], {"art_rect": _c(535, 364, 46, 34), "tool": "pliers",
			"uses": "Safety wire", "verb_off": "Cut the safety wire", "verb_on": "Safety-wire the thumb nut"}),
		_cover("valve", "Fuel shut-off", Rect2(700, 440, 100, 80), [], {"col": Color(0.6, 0.1, 0.1), "verb_off": "Turn the fuel OFF", "verb_on": "Turn the fuel back ON"})]}

	# Brake bleed: cap off, hose into the jar, open the bleeder and pump until the jar runs clear, top up.
	s.brake_bleed = {"title": "Left main wheel, expander brake", "els": [
		{"id": "jar", "type": "view", "name": "Catch jar", "rect": _c(555, 448, 90, 116)},
		_task("pump", "Open the bleeder, pump the pedal", Rect2(600, 250, 200, 46), "ratchet", ["cap"], {"with": ["hose"], "hold": 3.0}),
		_task("close", "Close the bleeder while it runs clear", Rect2(600, 306, 200, 46), "ratchet", [], {"requires": ["pump"], "note": true, "hold": 1.0}),
		_task("can", "Top up the reservoir", _c(706, 448, 87, 124), "hand", [], {"requires": ["close"], "uses": "Brake fluid", "hold": 1.2}),
		_task("lining", "Squirt fluid on the lining to free it", Rect2(40, 480, 280, 40), "hand", [], {"trap": "No: fluid on the lining ruins it, and on the fabric it lifts the dope (Cub manual p.22)."}),
		_cover("hose", "Bleed hose", _c(486, 301, 143, 190), ["cap"], {"start": "off", "rest": "off", "verb_on": "Bleed hose on, into the jar", "verb_off": "Hose off the bleeder"}),
		_cover("cap", "Bleeder dust cap", _pad(_c(414, 216, 22, 24), 50, 44), [], {"art_rect": _c(414, 216, 22, 24), "verb_off": "Pop the dust cap off", "verb_on": "Dust cap back on"})]}

	# Bungee cords: read the date threads, stretch the new rings on with the bungee tool.
	s.bungee = {"title": "Left main gear, shock cords", "els": [
		_task("read", "Read the date threads", Rect2(520, 60, 240, 46), "hand", ["boot"], {"note": true, "hold": 1.0}),
		_part("cord", "Bungee cords", _c(408, 195, 73, 136), ["jack", "boot"], {"requires": ["read"], "with": ["tool"], "tool": "hand", "hold": 2.0}),
		_cover("boot", "Shock cord boot", _c(410, 195, 156, 190), [], {"verb_off": "Unlace the leather boot", "verb_on": "Lace the boot back on", "hold": 1.0}),
		_cover("tool", "Bungee tool", _c(190, 502, 219, 57), [], {"start": "off", "rest": "off", "verb_on": "Pick up the bungee stretching tool", "verb_off": "Put the bungee tool down"}),
		_cover("jack", "Jack", Rect2(20, 300, 110, 110), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Jack it up off its gear", "verb_on": "Lower it back down"})]}

	# Tailwheel: new leaf spring and steering spring, wipe the fitting, grease it.
	s.tailwheel = {"title": "Tailwheel", "els": [
		_part("leaf", "Leaf spring", _c(646, 355, 128, 66), ["stand"], {"tool": "ratchet"}),
		_part("steer", "Steering spring", _pad(_c(686, 358, 56, 31), 70, 44), ["stand"], {"art_rect": _c(686, 358, 56, 31)}),
		_task("grime", "Wipe the old grease off the fitting", _pad(_c(706, 386, 33, 21), 60, 36), "rag", [], {"art_rect": _c(706, 386, 33, 21), "hold": 1.0}),
		_task("gun", "Grease the fitting", _c(460, 500, 219, 53), "hand", [], {"requires": ["grime", "leaf", "steer"], "hold": 1.5}),
		_cover("stand", "Tail stand", Rect2(60, 330, 130, 140), [], {"col": Color(0.7, 0.15, 0.1), "verb_off": "Lift the tail onto the stand", "verb_on": "Set the tail back down"})]}

	# Aileron cables: plate off, tensiometer on, wires cut, new cable, set both turnbuckles to tension.
	var tension := func(scene_cable: String, name: String, height: float) -> Array:
		return [_part("cable", name, _c(420, 262, 620, height), ["plate", "wire_a", "wire_b"], {"col": Color(0.7, 0.7, 0.72)}),
			_task("tb_a", "Turn the left turnbuckle", _c(240, 264, 120, 34), "screwdriver", ["plate", "wire_a"], {"requires": [scene_cable], "with": ["tensio"], "fixture": true, "hold": 2.0}),
			_task("tb_b", "Turn the right turnbuckle", _c(580, 264, 120, 34), "screwdriver", ["plate", "wire_b"], {"requires": ["tb_a"], "with": ["tensio"], "fixture": true, "note": true, "hold": 2.0}),
			_wire("wire_a", "Left turnbuckle wire", _c(246, 261, 102, 24), ["plate"]),
			_wire("wire_b", "Right turnbuckle wire", _c(586, 261, 102, 24), ["plate"])]
	var win := _c(420, 260, 660, 200)
	var win_screws := []
	for i in 4:  # eight small screws round the frame
		win_screws += [win.position + Vector2(20 + i * 206.7, 14), Vector2(win.position.x + 20 + i * 206.7, win.end.y - 14)]
	s.aileron_rigging = {"title": "Left wing, inspection window", "els": tension.call("cable", "Aileron cable", 14.0) + [
		_cover("tensio", "Tensiometer", _c(432, 260, 196, 98), ["plate"], {"dyn": true, "start": "off", "rest": "off", "verb_on": "Clamp the tensiometer on the cable", "verb_off": "Take the tensiometer off"}),
		_task("sight", "Stick centered: sight the trailing edges", Rect2(560, 460, 240, 46), "hand", [], {"requires": ["tb_b"], "note": true, "hold": 1.0}),
		_cover("plate", "Inspection window", win, [], {"art": "window", "verb_off": "Take the inspection window off", "verb_on": "Inspection window back on"})]
		+ _at("plate", win_screws, "screw", "screwdriver")}
	# The elevator cable is the same kind of run; it borrows the aileron art.
	s.elevator_cable = {"title": "Tail post, elevator cable", "art": "aileron_rigging", "els": tension.call("cable", "Elevator cable", 14.0) + [
		_cover("tensio", "Tensiometer", _c(432, 255, 196, 98), ["plate"], {"dyn": true, "start": "off", "rest": "off", "verb_on": "Clamp the tensiometer on the cable", "verb_off": "Take the tensiometer off"})]
		+ _plate(_c(410, 270, 658, 318))}

	# Trim cable: someone oiled it. Clean it dry, set the turnbuckles; the oil can is the trap.
	s.trim_cable = {"title": "Tail cone, trim cable", "els": [
		_part("cable", "Trim cable", _pad(_c(410, 300, 620, 8), 620, 30), ["plate"], {"art_rect": _c(410, 300, 620, 8), "free": true, "requires": ["degrease"],
			"verb_remove": "Unhook the gummed cable from the drum", "verb_install": "Cable back on the drum, dry"}),
		_task("degrease", "Wipe the oil and grit off the cable", Rect2(160, 420, 240, 46), "rag", ["plate"], {"out": ["cable"], "hold": 2.5}),
		_task("tb_a", "Turn the left turnbuckle", _c(240, 302, 120, 34), "screwdriver", ["plate"], {"requires": ["cable"], "with": ["tensio"], "fixture": true, "hold": 2.0}),
		_task("tb_b", "Turn the right turnbuckle", _c(580, 302, 120, 34), "screwdriver", ["plate"], {"requires": ["tb_a"], "with": ["tensio"], "fixture": true, "note": true, "hold": 2.0}),
		_task("oilcan", "Oil the cable so it runs smoother", _c(682, 476, 105, 99), "hand", [], {"trap": "Never oil the trim cable: it drives the drum by friction and slips worse (Cub manual p.30)."}),
		_cover("tensio", "Tensiometer", _c(402, 355, 196, 98), ["plate"], {"start": "off", "rest": "off", "verb_on": "Clamp the tensiometer on the cable", "verb_off": "Take the tensiometer off"})]
		+ _plate(_c(410, 270, 658, 318), "Tail inspection panel")}

	# Exhaust: SCAT hose and heat shroud off, leak-test the muffler, replace it, torque the flange nuts.
	var mf := _c(730, 245, 70, 280)
	var sh := _c(734, 243, 129, 316)
	var ex := [_part("muffler", "Muffler", mf, ["shroud"], {"after": ["leak"]}),
		_task("leak", "Plug it, 2 psi in, dunk the seam", Rect2(40, 250, 240, 46), "hand", ["shroud"], {"note": true, "hold": 2.5})] \
		+ _at("muffler", [mf.position + Vector2(35, 24), Vector2(mf.position.x + 35, mf.end.y - 24)], "nut", "ratchet") \
		+ [_cover("shroud", "Heat shroud", sh, ["scat"])] + _corners("shroud", sh, "screw", "screwdriver", 14.0) \
		+ [_cover("scat", "SCAT hose", _c(724, 96, 113, 109), [], {"verb_off": "Pull the SCAT hose off the shroud", "verb_on": "SCAT hose back on"})]
	_torque_on(ex, "muffler")  # flange nuts 100-110 in-lb
	s.exhaust_check = {"title": "Engine from below, muffler and heat muff", "els": ex}

	# Air filter and carb heat box: cover off, new filter, new flapper.
	var afc := _c(117, 250, 140, 240)
	s.air_filter = {"title": "Engine from below, carb air box", "els": [
		_part("filter", "Air filter", _c(117, 250, 92, 202), ["cover"]),
		_part("flapper", "Carb heat flapper", _c(232, 250, 70, 90), []),
		_cover("cover", "Filter cover", afc)] + _corners("cover", afc, "screw", "screwdriver", 14.0)}

	# Mag timing, left mag (C-85: left 30 deg BTC, right 28; overhaul manual Table X): leads on, turn the
	# prop to the mark, rotate the mag till the light comes on.
	var mg := Rect2(330, 150, 170, 140)
	var mt := [_task("tdc", "Prop forward to 30 deg on the marks", _c(260, 280, 260, 40), "hand", ["cowl"], {"turns_prop": true, "note": true, "fixture": true, "art": "marks", "hold": 2.0}),
		_task("rotate", "Rotate the mag till the light comes on", Rect2(40, 330, 260, 46), "timing", ["cowl", "clamp"], {"requires": ["tdc"], "with": ["leads", "light"], "note": true, "hold": 2.5}),
		_task("back", "Turn it backward to get there", Rect2(40, 386, 260, 40), "hand", ["cowl"], {"trap": "Never back up: turn the crank in its normal direction when timing, or gear backlash throws the reading off (M-0 6-4.9)."}),
		_cover("light", "Timing light", _c(195, 160, 150, 100), ["cowl"], {"dyn": true, "start": "off", "rest": "off", "verb_on": "Set the timing light where you can see it", "verb_off": "Put the timing light away"}),
		_cover("leads", "Timing light leads", _c(428, 190, 320, 52), ["cowl"], {"start": "off", "rest": "off", "verb_on": "Clip the leads to the P-lead and ground", "verb_off": "Unclip the leads"}),
		_cover("clamp", "Magneto clamp", mg, ["cowl"], {"col": Color(0.15, 0.15, 0.17, 0.6), "verb_off": "Slack the clamp so the mag turns", "verb_on": "Snug the clamp"})] \
		+ _at("clamp", [Vector2(mg.position.x + 16, mg.end.y - 16), Vector2(mg.end.x - 16, mg.end.y - 16)], "nut", "ratchet") + _cowl()
	_torque_on(mt, "clamp")  # 100-120 in-lb
	s.mag_timing = {"title": "Rear accessory case, timing the left mag", "els": mt}

	# Dressing a stone nick out of a metal blade.
	s.prop_dress = {"title": "Prop blade on the bench", "els": [
		{"id": "nick", "type": "view", "name": "Stone nick", "rect": _c(460, 208, 61, 25)},
		{"id": "dressed", "type": "view", "name": "Dressed edge", "rect": _c(460, 201, 160, 10)},
		_task("file", "Dress the nick into a smooth dish", _c(490, 154, 240, 28), "hand", [], {"hold": 2.5}),
		_task("emery", "Finish it with emery cloth", _c(700, 156, 109, 63), "rag", [], {"requires": ["file"], "hold": 1.5}),
		_task("etch", "Etch it, look for a crack", Rect2(40, 400, 260, 46), "rag", [], {"requires": ["emery"], "note": true, "hold": 1.5}),
		_task("straighten", "Straighten the tip while you're there", Rect2(40, 456, 260, 46), "hand", [], {"trap": "No: never straighten a blade in the field, not even to ship it (AC 43.13-1B 8-73)."})]}

	# Prop tracking: block under the tip, mark each blade, shim the hub if they're more than 1/16 apart.
	s.prop_track = {"title": "Nose, prop tracking", "els": [
		{"id": "blade", "type": "view", "name": "Blade down", "rect": _c(532, 320, 33, 319)},
		{"id": "mark_a", "type": "view", "name": "Mark A", "rect": _c(513, 482, 16, 4)},
		{"id": "mark_b", "type": "view", "name": "Mark B", "rect": _c(523, 482, 16, 4)},
		_task("t1", "Blade A down: mark its tip", Rect2(600, 300, 200, 46), "hand", [], {"with": ["block", "plugs"], "turns_prop": true, "note": true, "hold": 1.5}),
		_task("t2", "Turn it, blade B down: mark it", Rect2(600, 356, 200, 46), "hand", [], {"requires": ["t1"], "with": ["block"], "turns_prop": true, "note": true, "hold": 1.5}),
		_task("shim", "Shim the hub on the low blade's side", Rect2(40, 250, 260, 46), "ratchet", [], {"requires": ["t2"], "hold": 2.0}),
		_task("t3", "Track it again", Rect2(600, 412, 200, 46), "hand", [], {"requires": ["shim"], "with": ["block"], "turns_prop": true, "note": true, "hold": 1.5}),
		_cover("block", "Wood block", _c(533, 533, 118, 114), [], {"start": "off", "rest": "off", "verb_on": "Set the block just under the tip", "verb_off": "Take the block away"}),
		_cover("plugs", "One plug per cylinder out", Rect2(40, 60, 200, 46), [], {"start": "off", "rest": "off", "tool": "ratchet", "col": Color(0.85, 0.85, 0.8),
			"verb_on": "Pull one plug from each cylinder", "verb_off": "Put the plugs back in"})]}

	# Wing rigging: string for dihedral, block and level for wash-out, new forks and jam nuts to set them.
	s.wing_rig = {"title": "Wings, dihedral and wash-out", "els": [
		{"id": "ruler", "type": "view", "name": "Ruler", "rect": _c(471, 126, 18, 56)},
		_task("measure", "Read the string at the root", Rect2(20, 500, 190, 40), "hand", [], {"with": ["string"], "note": true, "hold": 1.0}),
		_part("fork_l", "Left strut fork", _pad(_c(167, 143, 20, 42), 50, 50), [], {"art": "fork", "art_rect": _c(167, 143, 20, 42), "tool": "ratchet", "requires": ["measure"],
			"verb_install": "New fork in, threaded out, jammed"}),
		_part("fork_r", "Right strut fork", _pad(_c(653, 143, 20, 42), 50, 50), [], {"art": "fork", "art_rect": _c(653, 143, 20, 42), "tool": "ratchet", "requires": ["measure"],
			"verb_install": "New fork in, threaded out, jammed"}),
		_task("measure2", "Read the string again", Rect2(220, 500, 190, 40), "hand", [], {"requires": ["fork_l", "fork_r"], "with": ["string"], "note": true, "hold": 1.0}),
		_task("washout", "Check the wash-out at the tip", Rect2(420, 500, 190, 40), "hand", [], {"requires": ["measure2"], "with": ["level", "block"], "note": true, "hold": 1.5}),
		_task("rear", "Rear struts till it's level", Rect2(620, 500, 190, 40), "ratchet", [], {"requires": ["washout"], "with": ["level", "block"], "note": true, "hold": 2.0}),
		_task("middle", "Push on the middle of the strut", Rect2(20, 420, 200, 36), "hand", [], {"trap": "No: push or pull on a lift strut only near the fuselage end, never its middle (Cub manual p.15)."}),
		_cover("string", "String", _c(410, 115, 800, 18), [], {"start": "off", "rest": "off", "verb_on": "Stretch a string tip to tip", "verb_off": "Take the string down"}),
		_cover("block", "Rigging block", _c(720, 113, 52, 22), [], {"start": "off", "rest": "off", "verb_on": "Rigging block on the tip rib", "verb_off": "Block off the rib"}),
		_cover("level", "Level", _c(720, 86, 152, 24), [], {"start": "off", "rest": "off", "verb_on": "Level on the block", "verb_off": "Level away"})]}

	# Tail brace wires: bowed and rusty, replaced and set so the stabilizer sits level.
	s.brace_wires = {"title": "Tail tie rods", "els": [
		_task("tape", "Friction tape where you'll grip them", Rect2(40, 60, 260, 46), "hand", [], {"hold": 1.0}),
		_part("upper", "Upper tie rod", _c(630, 175, 148, 178), [], {"requires": ["tape"], "tool": "ratchet"}),
		_part("lower", "Lower tie rod", _c(590, 295, 228, 78), [], {"requires": ["tape"], "tool": "ratchet"}),
		_task("level", "Turn the nipples till it's level", Rect2(40, 400, 260, 46), "hand", [], {"requires": ["upper", "lower"], "note": true, "hold": 2.0})]}

	# Baffles: dig the packed dirt out of the fins, new seals.
	var bf := []
	var packs := [Vector2(170, 135), Vector2(170, 265), Vector2(670, 135), Vector2(670, 265)]
	for i in 4:
		bf.append(_task("packed%d" % i, "Dig the packed dirt out of the fins", _c(packs[i].x, packs[i].y, 212, 102), "rag", [], {"art": "packed", "hold": 2.0}))
	for i in 2:
		var sx: float = [294.0, 554.0][i]
		bf.append(_part("seal%d" % i, "Baffle seal", _pad(_c(sx, 205, 18, 270), 44, 270), [], {"art": "seal", "art_rect": _c(sx, 205, 18, 270), "tool": "screwdriver"}))
	s.baffles = {"title": "Engine from the top, baffles", "els": bf}

	# Chafed wire: splice in a new run, then a cushioned clamp so it can't rub again.
	s.wire_chafe = {"title": "Behind the panel, wiring", "els": [
		_part("wire", "Wire run", _pad(_c(400, 257, 320, 14), 320, 36), [], {"art_rect": _c(400, 257, 320, 14), "tool": "pliers",
			"verb_remove": "Cut out the chafed run", "verb_install": "Splice in new wire, heat-shrink"}),
		_task("check", "Wiggle test with the radio on", Rect2(40, 460, 260, 46), "hand", [], {"requires": ["wire"], "with": ["clamp"], "note": true, "hold": 1.5}),
		_cover("clamp", "Cushioned clamp", _pad(_c(370, 270, 59, 49), 60, 50), [], {"art_rect": _c(370, 270, 59, 49), "start": "off", "tool": "screwdriver",
			"verb_on": "Cushion clamp on, off the bracket", "verb_off": "Take the clamp off"})]}

	# Out of storage: read the tag, bags out, dehydrator plugs out, wipe the preservative, clear it by hand.
	var sr := [_task("tag", "Read the preservation tag", _c(495, 458, 110, 144), "hand", [], {"note": true, "hold": 1.0}),
		_task("bag_intake", "Desiccant bag out of the air scoop", _c(140, 430, 160, 100), "hand", [], {"requires": ["tag"], "hold": 0.8}),
		_task("bag_exhaust", "Desiccant bag out of the tailpipe", _c(721, 470, 130, 100), "hand", [], {"requires": ["tag"], "hold": 0.8})]
	var dh := []
	var holes := [["cyl 4 top", Vector2(190, 150)], ["cyl 4 bottom", Vector2(330, 250)], ["cyl 2 top", Vector2(490, 150)], ["cyl 2 bottom", Vector2(630, 250)]]
	for i in 4:
		sr.append(_task("dehy%d" % i, "Dehydrator plug out, " + holes[i][0], _pad(_c(holes[i][1].x, holes[i][1].y, 50, 72), 70, 72), "hand", ["cowl"],
			{"art": "dehy", "art_rect": _c(holes[i][1].x, holes[i][1].y, 50, 72), "hold": 0.6}))
		dh.append("dehy%d" % i)
	sr.append(_task("dehy_r", "The four on the right side", Rect2(760, 150, 60, 80), "hand", ["cowl"], {"hold": 2.0}))
	dh.append("dehy_r")
	sr += [_task("oil", "Wipe the preservative off the case", _c(410, 326, 500, 33), "rag", ["cowl"], {"requires": dh, "hold": 1.5}),
		_task("turn", "Turn it through by hand", Rect2(40, 60, 220, 46), "hand", [], {"requires": dh + ["bag_intake", "bag_exhaust"], "turns_prop": true, "note": true, "hold": 2.5}),
		_task("refill", "Drain the preservative oil, refill", Rect2(270, 60, 240, 46), "hand", [], {"requires": ["turn"], "hold": 2.5}),
		_task("plugs", "Plugs in, gapped, 300-360 in-lb", Rect2(520, 60, 260, 46), "torque", ["cowl"], {"requires": ["refill"], "hold": 2.0}),
		_task("start", "Prime it and pull it through", Rect2(40, 116, 220, 40), "hand", [], {"trap": "Not yet: preservative oil still in there can hydraulic-lock a cylinder and bend a rod (M-0 6-5.2). Clear it first."})]
	s.storage = {"title": "Engine, out of preservation", "els": sr + _cowl()}

	# ---- round 3 (docs/NEW_SCENES_3.md) ----

	# Fabric punch test: three spots on the wing top, read the band, seal each dent with dope.
	var ft := []
	var spots := [[Vector2(160, 140), Vector2(200, 210)], [Vector2(360, 210), Vector2(400, 280)], [Vector2(560, 120), Vector2(600, 190)]]
	for i in 3:
		var rd: Vector2 = spots[i][0]
		var sp: Vector2 = spots[i][1]
		ft += [{"id": "read%d" % i, "type": "view", "name": "Reading %d" % (i + 1), "rect": Rect2(rd, Vector2(120, 60))},
			{"id": "spot%d" % i, "type": "view", "name": "Test spot %d" % (i + 1), "rect": Rect2(sp, Vector2(40, 40))},
			_task("t%d" % i, "Punch-test spot %d" % (i + 1), Rect2(sp - Vector2(15, 15), Vector2(70, 70)), "punch", [], {"art": "none", "note": true, "hook": true, "hold": 1.5}),
			_task("s%d" % i, "Seal spot %d with dope" % (i + 1), Rect2(40 + i * 200, 470, 180, 46), "rag", [], {"requires": ["t%d" % i], "uses": "Dope", "hold": 1.0})]
	s.fabric_test = {"title": "Left wing, top surface", "els": ft}

	# Brake master cylinder: cover off, wipe up, line off, swap the Scott cylinder, fill it.
	s.brake_master = {"title": "Rear floorboard, brake master cylinders", "els": [
		_part("cylinder", "Master cylinder", Rect2(260, 170, 120, 170), ["cover", "line"], {"tool": "ratchet"}),
		_task("puddle", "Wipe up the spilled fluid", Rect2(220, 300, 260, 130), "rag", ["cover"], {"hold": 1.5}),
		_cover("line", "Brake line B-nut", Rect2(270, 310, 80, 60), ["cover"], {"tool": "ratchet", "verb_off": "Crack the B-nut, line off", "verb_on": "Line on, B-nut snug"}),
		_task("can", "Fill the new cylinder", Rect2(640, 380, 90, 130), "hand", [], {"requires": ["cylinder"], "with": ["line"], "uses": "Brake fluid", "hold": 1.5}),
		_cover("cover", "Inspection cover", Rect2(240, 140, 360, 280))] + _corners("cover", Rect2(240, 140, 360, 280), "screw", "screwdriver", 18.0)}
	s.brake_master.els[2].needs = ["cover", "puddle"]  # you wipe it up first, to see where it's leaking

	# Tachometer swap: bezel screws, drive shaft nut off the back, new gauge in.
	var tach := Rect2(322, 154, 195, 195)
	s.instrument_swap = {"title": "Instrument panel, tachometer", "els": [
		_part("tach", "Tachometer", tach, ["cable"], {"tool": "hand"})]
		+ _corners("tach", tach, "screw", "screwdriver", 14.0)
		+ [_cover("cable", "Tach drive shaft nut", Rect2(320, 231, 120, 70), [], {"tool": "ratchet", "verb_off": "Unscrew the drive shaft nut", "verb_on": "Drive shaft nut back on, snug"})]}

	# Wood prop bolts: wire off, check the hub gap, torque the six in a star, re-wire in pairs.
	var hubc := Vector2(410, 280)
	var pb := [{"id": "order", "type": "view", "name": "Torque order", "rect": Rect2(360, 230, 140, 140)},
		_task("look", "Look for a gap at the hub seat", Rect2(600, 200, 210, 46), "hand", ["wire"], {"note": true, "hold": 1.0}),
		_cover("hub", "Prop hub", Rect2(310, 180, 200, 200), ["wire"], {"dyn": true, "verb_off": "Pull the prop off the hub", "verb_on": "Prop back on the hub"})]
	for f in _ring("hub", hubc, 52, 6, "bolt", "ratchet", true):
		f["start"] = "snug"  # the wood shrank: the bolts are only snug, the torque wrench finishes them
		pb.append(f)
	pb.append(_cover("wire", "Prop bolt safety wire", Rect2(320, 190, 180, 180), [], {"tool": "pliers", "uses": "Safety wire",
		"verb_off": "Cut the safety wire", "verb_on": "Safety-wire the bolts in pairs"}))
	s.prop_bolts = {"title": "Nose, prop bolts", "els": pb}

	# ---- placeholders until art exists ----

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

	var rc := ROCKER_RECT
	var rocker := [_cover("rocker", "Rocker cover", rc, ["cowl"], {"tex": "metal_steel", "col": METAL})] + _at("rocker", _rocker_screws(), "screw", "screwdriver")
	_torque_on(rocker, "rocker")  # 55-65 in-lb
	s.stuck_valve = {"title": "Engine, rocker cover off", "deco": engine_deco, "desc": "One cylinder head with its rocker cover off: rocker arms, valve springs and stems showing", "els": [
		_part("gasket", "Rocker cover gasket", rc, ["cowl", "rocker"], {"col": Color(0.75, 0.35, 0.15), "requires": ["free"]}),
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

	s.tie_down = {"title": "Tied down on the grass", "deco": wheel_deco, "desc": "A Cub tied down on grass from the side: rope at the tail lift handle, ropes to both front lift struts, chocks at the wheels", "els": [
		_task("chocks", "Chock the wheels", Rect2(60, 420, 200, 46), "hand", [], {"hold": 0.8}),
		_task("tail", "Rope the tail handle, no slack", Rect2(280, 420, 240, 46), "hand", [], {"hold": 1.5}),
		_task("left", "Rope the left strut top", Rect2(60, 360, 200, 46), "hand", [], {"hold": 1.5}),
		_task("right", "Rope the right strut top", Rect2(280, 360, 240, 46), "hand", [], {"hold": 1.5}),
		_task("lock", "Belt round the rear stick", Rect2(540, 360, 260, 46), "hand", [], {"hold": 1.0}),
		_task("struts", "Tie it at the middle of the strut", Rect2(540, 420, 260, 46), "hand", [], {"trap": "Not the middle: never pull or push on the middle of a lift strut. Tie at the top, where it meets the wing (Cub manual p.15, 42)."})]}

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

	s.fod = {"title": "Engine, under the cowl", "deco": engine_deco, "desc": "Engine left side, cowling off: a socket wedged behind a cylinder baffle", "els": [
		_task("fish", "Fish out the loose socket", Rect2(500, 230, 160, 60), "hand", ["cowl"], {"note": true, "hold": 2.0})] + _cowl()}

	# Hand-propping, the Cub manual's starting drill (p.38): how you start it with a flat battery.
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

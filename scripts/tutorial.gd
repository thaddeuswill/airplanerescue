extends Control
## The apprenticeship: the first three jobs of a new career, taught by doing them
## (docs/quick-specs/apprenticeship-2026-11-22.md).
##
## - A short tour at home base shows what's on the screen and what the game is for.
## - A checklist card, top left, lists the job's steps. Each one ticks itself off the moment you
##   do it right (nothing is ever clicked to "acknowledge"), with a pen scratch and a slip that says
##   what you just did. Only the step you're on is explained; the rest are one line each.
## - Each job teaches one new thing, so no lesson repeats the one before: job 1 the loop (find it,
##   write it up, fix it, run it up, sign, fly), job 2 tools and parts (it needs two tools you
##   don't own yet, and the shed may not stock the part), job 3 the engine's insides (a fault you
##   hear on the run-up and prove with the compression tester from the red toolbox).
## - Finishing a job pays a bonus and hands over what the next job needs. After the third, the
##   checklist retires and the career opens up.
##
## State lives in main.tut (saved): lesson (1-3, 0 = done or skipped), tour (seen), done (step ids
## ticked this lesson), base (rescues when the lesson began), reward (a lesson's reward to show).

var main

const W_CARD := 340.0
const LESSONS := {
	1: {"title": "Your first rescue", "teaches": "the whole job, start to finish"},
	2: {"title": "Tools of the trade", "teaches": "buying tools and parts, and waiting on the mail"},
	3: {"title": "Listen to the engine", "teaches": "a fault you hear, and a test that proves it"},
}
## What finishing each lesson pays out, and the one line that sends you on.
const REWARDS := {
	1: {"cash": 300, "gift": "", "line": "The flying service liked what they heard. Next call: something you'll need tools for."},
	2: {"cash": 200, "gift": "tester", "line": "They've sent you their old compression tester. It's in the red toolbox by the nose of every plane you work on."},
	3: {"cash": 500, "gift": "", "line": "You're on your own now. Calls get harder from here: planes that sat for years, look-alike faults, annual inspections, and some you'll have to ground."},
}

## Reading the squawk: the pilot says what they felt, heard, saw or smelled, never the cause.
## On arrival each lesson asks where you'd look first, and every answer says why it's right or
## wrong. A wrong one costs nothing here: try again. [answer, right?, why].
const DECODE := {
	"bird_nest": [
		["The engine, under the cowl", true, "Birds don't fly out of a cowl unless they've built in it. A nest packed against a hot cylinder catches fire: open the cowl first."],
		["The cabin", false, "The birds came out of the cowling, not the cabin. Where they came out is where they live."],
		["The tail", false, "Nothing at the tail makes birds fly out of the cowling. Start where the pilot saw them."]],
	"water_fuel": [
		["The fuel: water got into it", true, "Rain, then a quit once it warmed up and a rough restart: that's water in the gas. Water sinks to the low point, the gascolator on the firewall. Drain a sample."],
		["The spark plugs", false, "Fouled plugs run rough all the time and get worse slowly. They don't make it quit once after a week of rain."],
		["The propeller", false, "A bad prop shakes the whole plane. It doesn't make the engine quit and restart rough."]],
	"tire": [
		["The left main tire", true, "Sitting low on one side and pulling to that side on the landing roll: that wheel's tire is flat or soft."],
		["The right brake", false, "A dragging brake pulls toward its own side, the right, and it wouldn't make the plane sit low."],
		["The rudder", false, "A rudder problem shows on the pedals and in the air, not in how the plane sits on the ground."]],
	"stuck_valve": [
		["Inside the engine: a cylinder that isn't sealing", true, "Down on power, and air chuffing out in rhythm as the prop turns: one cylinder isn't holding compression. Nothing shows outside, so you run it up and test it."],
		["The propeller", false, "The prop turns fine. The chuff is air escaping inside the engine, once every turn of that cylinder."],
		["The tires", false, "A soft tire drags on the take-off roll, but it doesn't chuff when you pull the prop through."]],
}

var _card: Control  # the checklist
var _decode: Control
var _slips: Array = []  # [text, age] tick slips sliding in under the card
var _tour: Control
var _tour_i := 0
var _reward: Control
var _t := 0.0
var _at_field := 0.0  # seconds standing at the job's field (the squawk step)
var _flash := {}  # step id -> seconds since it ticked (the check draws itself in)


func setup(m) -> void:
	main = m
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_card = Control.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.draw.connect(_draw_card)
	add_child(_card)


func lesson() -> int:
	return int(main.tut.get("lesson", 0))


func active() -> bool:
	return lesson() > 0


## Faults the lesson's calls are given: every call on the map during a lesson is that lesson's job.
func lesson_faults(rng: RandomNumberGenerator) -> Array:
	match lesson():
		1: return [main.FIRST_JOBS[rng.randi() % main.FIRST_JOBS.size()]]
		2: return ["tire"]
		3: return ["stuck_valve"]
	return []


# ---------- the steps ----------

func _job():
	var j = main.current_job
	return j if j != null and j.city == main.location else null


func _found_all(j: Dictionary) -> bool:
	return j.faults.all(func(id): return j.found.has(id))


func _fixed_all(j: Dictionary) -> bool:
	return j.faults.all(func(id): return j.fixed.has(id))


## Tools the lesson's job asks for that aren't in your roll yet (instruments aside: they're gifts).
func _missing_tools(j: Dictionary) -> Array:
	var out := []
	for id in j.faults:
		for e in main.Work.scene_for(id, main.FAULTS[id]).els:
			var t: String = e.get("tool", "hand")
			if t != "hand" and t != "" and not t in main.INSTRUMENTS and not main.tools.has(t) and not t in out:
				out.append(t)
	return out


## The steps of the lesson you're on: id, the line on the card, how-to for when it's the current
## step, and the check that ticks it. Checks only read the game; they never change it.
func steps() -> Array:
	var j = _job()
	var k: Callable = main.key_name
	var call := {"id": "call", "text": "Take the call and fly there",
		"how": "The map on the hangar workbench: walk up to it and press %s. Pick a call, then fly." % k.call("interact"),
		"ok": func(): return j != null}
	var squawk := {"id": "squawk", "text": "Work out what the pilot means",
		"how": "Top right: the pilot's squawk. They say what they felt, heard, saw or smelled, never the cause. Your job: turn it into where to look.",
		"ok": func(): return j != null and _decode_fault(j) == "" and (_at_field > 6.0 or j.checked.size() > 0)}  # no quiz for this fault: reading is enough
	var walk := {"id": "walk", "text": "Check all 8 spots",
		"how": "Walk up to each yellow ? on the plane and press %s. %d of 8 so far." % [k.call("interact"), j.checked.size() if j else 0],
		"ok": func(): return j != null and j.checked.size() == main.ZONES.size()}
	var writeup := {"id": "writeup", "text": "Find it and write it up",
		"how": "In a spot, click the part and choose Look closer. What you write up keeps a red ! until it's fixed.",
		"ok": func(): return j != null and j.faults.filter(func(id): return main._how(j, id) == "walk").all(func(id): return j.found.has(id))}
	var fix := {"id": "fix", "text": "Fix it",
		"how": "%s at the ! spot, then the job on the part. Pick a tool, hold the mouse on each piece. H shows what's next." % k.call("interact"),
		"ok": func(): return j != null and _found_all(j) and _fixed_all(j)}
	var runup := {"id": "runup", "text": "Run it up",
		"how": "Sit in at the cabin (%s). Fuel on, master, prime, start; hold 1700 rpm and check each mag." % k.call("interact"),
		"ok": func(): return j != null and _fixed_all(j) and j.get("runup", "") == "ran"}
	var sign := {"id": "sign", "text": "Sign the logbook",
		"how": "From the work order at any spot: Write up the logbook. Nobody flies until you sign.",
		"ok": func(): return j != null and j.get("signed", false)}
	var fuel := {"id": "fuel", "text": "Fuel it",
		"how": "The fuel truck by the hangar: half tanks at least, out on the apron.",
		"ok": func(): return j != null and j.get("fuel", 1.0) >= 0.5}
	var fly := {"id": "fly", "text": "Fly it out to the owner",
		"how": "Climb in at the cabin. %s fuel, %s master, %s primer, hold %s to start, then %s throttle and rotate at 55." \
			% [k.call("fuel_valve"), k.call("master"), k.call("primer"), k.call("starter"), k.call("throttle_up")],
		"ok": func(): return main.rescued > int(main.tut.get("base", 0))}
	match lesson():
		1:
			return [{"id": "tour", "text": "Get your bearings", "how": "", "ok": func(): return main.tut.get("tour", false)},
				call, squawk, walk, writeup, fix, runup, sign, fuel, fly]
		2:
			var tools_step := {"id": "tools", "text": "Get the tools for the job",
				"how": "This one needs %s. The PARTS shed by the apron sells them; the hangar TOOLS box mail-orders (a day, 25%% more)." \
					% (", ".join(_missing_tools(j).map(func(t): return main.Work.TOOLS[t].to_lower())) if j and _missing_tools(j).size() > 0 else "tools you have"),
				"ok": func(): return j != null and _found_all(j) and _missing_tools(j).is_empty()}
			var part_step := {"id": "part", "text": "Get the part",
				"how": "PARTS shed. Not on the shelf? Mail-order it: a day's wait and 25% more. That's the trade.",
				"ok": func(): return j != null and _found_all(j) and j.faults.all(func(id): return j.fixed.has(id) or main.FAULTS[id].part == "" or main.inventory.get(main.FAULTS[id].part, 0) > 0)}
			walk.how = "Same as last time, on your own: every ? on the plane. %d of 8." % (j.checked.size() if j else 0)
			return [call, squawk, walk, writeup, tools_step, part_step, fix, runup, sign, fuel, fly]
		3:
			var listen := {"id": "listen", "text": "Run it up and listen",
				"how": "Nothing shows outside. Start it and feel how it runs: the work order turns what you hear into a test to do.",
				"ok": func(): return j != null and (j.get("sym", {}).size() > 0 or j.found.size() > 0)}
			var kit := {"id": "kit", "text": "Take the compression tester in hand",
				"how": "The red toolbox by the nose: %s, then take it. Tests only show up on parts with the right instrument in hand." % k.call("interact"),
				"ok": func(): return j != null and (main.held == "tester" or _found_all(j))}
			var test := {"id": "test", "text": "Prove it and make the call",
				"how": "Open up the engine and run the tests the work order names. Then Make the call on the work order.",
				"ok": func(): return j != null and _found_all(j)}
			var again := runup.duplicate()
			again.text = "Run it up again: prove the fix"
			again.how = "A fix isn't done until it runs right. Back to the cabin."
			return [call, squawk, walk, listen, kit, test, fix, again, sign, fuel, fly]
	return []


# ---------- ticking ----------

func _process(delta: float) -> void:
	_t += delta
	for k in _flash.keys():
		_flash[k] += delta
	for s in _slips:
		s[1] += delta
	_slips = _slips.filter(func(s): return s[1] < 4.0)
	if not active() or main.current_job == null or main.ferry != null:
		_at_field = 0.0
	else:
		_at_field += delta
	if active() and not main.tut.get("tour", true) and main.panel == null and main.panel_kind != "menu" \
			and not is_instance_valid(main._loader) and main.current_job == null and not is_instance_valid(_tour):
		start_tour()
	if active():
		_poll()
		var j = _job()
		if j != null and not main.tut.get("done", {}).has("squawk") and _decode_fault(j) != "" and _at_field > 1.5 \
				and main.panel == null and not is_instance_valid(_decode) and not is_instance_valid(_tour) and not is_instance_valid(_reward) \
				and not is_instance_valid(main._loader):
			_show_decode(j)
	var touring_card: bool = is_instance_valid(_tour) and _tour_pages()[_tour_i][0] == "card"  # the tour page about it shows it
	_card.visible = active() and main.settings.get("checklist", true) and main.panel == null and main.ferry == null \
		and (not is_instance_valid(_tour) or touring_card) and not is_instance_valid(_decode) and not is_instance_valid(main._loader)
	_card.queue_redraw()
	queue_redraw()
	if main.tut.has("reward") and not is_instance_valid(_reward) and main.ferry == null and not is_instance_valid(main._loader) \
			and main.panel_kind != "menu":
		_show_reward(int(main.tut.reward))


## Ticks every step whose check now holds. Steps can be done out of order; a tick never comes off.
func _poll() -> void:
	var done: Dictionary = main.tut.get_or_add("done", {})
	for s in steps():
		if done.has(s.id) or not s.ok.call():
			continue
		done[s.id] = true
		_flash[s.id] = 0.0
		if s.id != "tour":
			_slips.append([s.text, 0.0])
			main.sound.pen()
		main.playlog("tutorial: " + s.id)


## Marks a step done from outside its check (the squawk quiz), with the same tick and slip.
func tick(id: String, text: String) -> void:
	var done: Dictionary = main.tut.get_or_add("done", {})
	if done.has(id):
		return
	done[id] = true
	_flash[id] = 0.0
	_slips.append([text, 0.0])
	main.sound.pen()
	main.playlog("tutorial: " + id)
	main._save_game()


## Called by main when a plane is delivered, before the map refills: the fly step ticks, the lesson
## pays out and the next one begins (and main swaps the calls on the map for the next lesson's).
func rescued_one() -> bool:
	if not active():
		return false
	var l := lesson()
	_poll()  # anything finished in the same moment as the take-off
	main.tut.done["fly"] = true
	main.tut["last"] = main.tut.done.keys()  # what got ticked, for the self-test
	main.tut["reward"] = l
	main.tut.lesson = 0 if l >= 3 else l + 1
	main.tut.done = {}
	main.tut.base = main.rescued
	main.money += REWARDS[l].cash
	if REWARDS[l].gift != "":
		main.tools[REWARDS[l].gift] = true
	return main.tut.lesson > 0


func skip() -> void:
	main.tut.lesson = 0
	main.tut.tour = true
	main._save_game()


# ---------- the checklist card ----------

func _draw_card() -> void:
	var list := steps()
	if list.is_empty():
		return
	var done: Dictionary = main.tut.get("done", {})
	var x := 16.0
	var y := 64.0  # under the next-step icon
	var pad := 14.0
	var w := W_CARD
	var head := Style.caps(800, Style.SIZE_XS)
	var body := Style.display(700)
	var muted := Style.display(600)
	var cur := -1
	for i in list.size():
		if not done.has(list[i].id):
			cur = i
			break
	# height first
	var h := pad + 16 + 26 + 10
	for i in list.size():
		h += 24
		if i == cur and list[i].how != "":
			h += muted.get_multiline_string_size(list[i].how, HORIZONTAL_ALIGNMENT_LEFT, w - pad * 2 - 28, Style.SIZE_SM).y + 6
	h += pad - 4
	var r := Rect2(x, y, w, h)
	_card.draw_rect(r.grow(2), Color(0, 0, 0, 0.25))
	_card.draw_rect(r, Style.COLOR_SURFACE_PAPER)
	_card.draw_rect(Rect2(x, y, w, 4), Style.COLOR_TEXT_PAPER_ACCENT)
	var cy := y + pad + 10
	_card.draw_string(head, Vector2(x + pad, cy), "APPRENTICE CHECKLIST   JOB %d OF 3" % lesson(), HORIZONTAL_ALIGNMENT_LEFT, -1,
		Style.SIZE_XS, Style.COLOR_TEXT_PAPER_ACCENT)
	cy += 26
	_card.draw_string(Style.caps(900, Style.SIZE_LG), Vector2(x + pad, cy), LESSONS[lesson()].title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT,
		w - pad * 2, Style.SIZE_LG, Style.COLOR_TEXT_PAPER)
	cy += 12
	for i in list.size():
		var s: Dictionary = list[i]
		cy += 24
		var box := Rect2(x + pad, cy - 14, 16, 16)
		var is_done: bool = done.has(s.id)
		var ink: Color = Style.COLOR_TEXT_PAPER_MUTED if is_done else (Style.COLOR_TEXT_PAPER if i == cur else Color(Style.COLOR_TEXT_PAPER, 0.55))
		_card.draw_rect(box, Color(Style.COLOR_TEXT_PAPER, 0.7 if i == cur else 0.35), false, 1.5)
		if is_done:
			_check(_card, box, clampf(_flash.get(s.id, 9.0) / 0.35, 0.0, 1.0))
		if i == cur:  # the step you're on: a red bar in the margin, pulsing gently
			_card.draw_rect(Rect2(x, cy - 16, 4, 20), Color(Style.COLOR_TEXT_PAPER_ACCENT, 0.7 + 0.3 * sin(_t * 3.0)))
		_card.draw_string(body if i == cur else muted, Vector2(x + pad + 28, cy), s.text, HORIZONTAL_ALIGNMENT_LEFT, w - pad * 2 - 28,
			Style.SIZE_MD, ink)
		if is_done:  # struck through, as you would on paper
			var tw := muted.get_string_size(s.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_MD).x
			_card.draw_line(Vector2(x + pad + 28, cy - 6), Vector2(x + pad + 28 + minf(tw, w - pad * 2 - 28), cy - 6),
				Color(Style.COLOR_TEXT_PAPER_MUTED, 0.6), 1.0)
		if i == cur and s.how != "":
			var how_h := muted.get_multiline_string_size(s.how, HORIZONTAL_ALIGNMENT_LEFT, w - pad * 2 - 28, Style.SIZE_SM).y
			_card.draw_multiline_string(muted, Vector2(x + pad + 28, cy + 18), s.how, HORIZONTAL_ALIGNMENT_LEFT, w - pad * 2 - 28,
				Style.SIZE_SM, -1, Style.COLOR_TEXT_PAPER_MUTED)
			cy += how_h + 6


## A red check, drawn in as it ticks (t 0 -> 1).
func _check(c: CanvasItem, box: Rect2, t: float) -> void:
	var a := box.position + Vector2(3, box.size.y * 0.55)
	var b := box.position + Vector2(box.size.x * 0.42, box.size.y - 3)
	var e := box.position + Vector2(box.size.x + 3, -3)
	var col := Style.COLOR_TEXT_PAPER_ACCENT
	if t < 0.4:
		c.draw_line(a, a.lerp(b, t / 0.4), col, 3.0)
	else:
		c.draw_line(a, b, col, 3.0)
		c.draw_line(b, b.lerp(e, (t - 0.4) / 0.6), col, 3.0)


## The slips: "done right" lines that slide in at the top of the screen, above any open sheet or
## job, so a tick is seen even mid-job. A few seconds each, then they fade.
func _draw() -> void:
	if not main.settings.get("checklist", true):
		return
	var f := Style.display(700)
	var y := size.y * 0.2 + 12.0  # under the message band (main.msg sits in the top fifth), never on it
	for s in _slips:
		var age: float = s[1]
		var a := clampf(age / 0.2, 0.0, 1.0) * clampf((4.0 - age) / 0.6, 0.0, 1.0)
		var text: String = s[0]
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_MD).x
		var w := tw + 64
		var r := Rect2(size.x / 2 - w / 2, y - 10 * (1.0 - clampf(age / 0.2, 0, 1)), w, 40)
		draw_rect(r, Color(Style.COLOR_SURFACE_PAPER, 0.97 * a))
		draw_rect(Rect2(r.position, Vector2(4, r.size.y)), Color(Style.COLOR_TEXT_PAPER_ACCENT, a))
		var box := Rect2(r.position + Vector2(16, 12), Vector2(16, 16))
		draw_rect(box, Color(Style.COLOR_TEXT_PAPER, 0.5 * a), false, 1.5)
		var col := Color(Style.COLOR_TEXT_PAPER_ACCENT, a)
		var p1 := box.position + Vector2(3, 9)
		var p2 := box.position + Vector2(7, 13)
		var p3 := box.position + Vector2(19, -3)
		var t := clampf(age / 0.35, 0, 1)
		draw_line(p1, p1.lerp(p2, minf(t / 0.4, 1.0)), col, 3.0)
		if t > 0.4:
			draw_line(p2, p2.lerp(p3, (t - 0.4) / 0.6), col, 3.0)
		draw_string(f, r.position + Vector2(44, 27), text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_MD, Color(Style.COLOR_TEXT_PAPER, a))
		y += 48


# ---------- the tour ----------

## Where everything is, the first time you stand in the hangar. [where it points, title, words].
func _tour_pages() -> Array:
	var k: Callable = main.key_name
	return [
		["", "AIRPLANE RESCUE", "You're a traveling A&P mechanic. Owners call when a plane is stuck in a field: you fly out, find what's wrong, fix it right, sign for it and fly it home to them.\n\nPut ten planes back in the air and you've made it. Run out of money and you're grounded."],
		["center", "WALK AND USE", "%s %s %s %s walks, the mouse looks. Point the dot at something and press %s to use it: the map, a spot on a plane, the fuel truck." \
			% [k.call("move_forward"), k.call("move_left"), k.call("move_back"), k.call("move_right"), k.call("interact")]],
		["quest", "YOUR NEXT STEP", "This icon always shows what comes next: the map, a spot to check, a wrench for work, the logbook. The markers floating over the plane say where."],
		["card", "YOUR CHECKLIST", "Your first three jobs come with a checklist. Every step ticks itself off when you do it right. Only the step you're on is explained. After the third job you're on your own."],
		["pockets", "YOUR POCKETS", "%s: wallet (money, parts, tools). %s: clipboard, the work order. %s: logbook, every plane you've saved. %s: the service manual, open at whatever you're working on." \
			% [k.call("wallet"), k.call("clipboard"), k.call("logbook"), k.call("manual")]],
		["", "ESC PAUSES", "Settings, controls and quitting are there. The game saves after every step.\n\nFirst job: walk to the map on the hangar workbench and press %s." % k.call("interact")],
	]


func start_tour() -> void:
	if is_instance_valid(_tour) or main.tut.get("tour", false):
		return
	_tour_i = 0
	_tour = Control.new()
	_tour.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tour.mouse_filter = Control.MOUSE_FILTER_STOP
	_tour.draw.connect(_draw_tour)
	add_child(_tour)
	var row := HBoxContainer.new()
	row.name = "row"
	row.add_theme_constant_override("separation", Style.SPACE_3)
	_tour.add_child(row)
	var skip_b := Button.new()
	skip_b.text = "SKIP THE LESSONS"
	Style.button(skip_b, "quiet")
	skip_b.custom_minimum_size.y = 44
	skip_b.pressed.connect(func():
		skip()
		_end_tour())
	row.add_child(skip_b)
	var next := Button.new()
	next.name = "next"
	Style.button(next, "primary")
	next.custom_minimum_size = Vector2(150, 44)
	next.pressed.connect(_tour_next)
	row.add_child(next)
	main.player.frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_tour_layout()
	next.grab_focus.call_deferred()


func _tour_next() -> void:
	main.sound.sfx("click")
	_tour_i += 1
	if _tour_i >= _tour_pages().size():
		main.tut.tour = true
		main._save_game()
		_end_tour()
		return
	_tour_layout()


func _end_tour() -> void:
	if is_instance_valid(_tour):
		_tour.queue_free()
	_tour = null
	if main.panel == null:
		main.player.frozen = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(ev: InputEvent) -> void:
	if is_instance_valid(_tour) and ev.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_tour_next()
	elif is_instance_valid(_reward) and (ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		_close_reward()


## The callout box: centered for the words that point at nothing, else beside what it points at.
func _tour_box() -> Rect2:
	var p: Array = _tour_pages()[_tour_i]
	var w := 460.0
	# tall enough for its words: eyebrow and title, the text, then the buttons
	var h := 96.0 + Style.text_font().get_multiline_string_size(p[2], HORIZONTAL_ALIGNMENT_LEFT, w - 48, Style.SIZE_MD - 2).y + 82.0
	match p[0]:
		"quest": return Rect2(80, 20, w, h)
		"card": return Rect2(W_CARD + 50, 70, w, h)
		"pockets": return Rect2(24, size.y - h - 90, w, h)
		"center": return Rect2(size.x / 2 - w / 2, size.y / 2 + 50, w, h)
	return Rect2(size.x / 2 - w / 2, size.y / 2 - h / 2, w, h)


func _target() -> Rect2:
	match _tour_pages()[_tour_i][0]:
		"quest": return Rect2(10, 8, 60, 52)
		"card": return Rect2(10, 58, W_CARD + 12, 330)
		"pockets": return Rect2(10, size.y - 62, 230, 54)
		"center": return Rect2(size.x / 2 - 22, size.y / 2 - 22, 44, 44)
	return Rect2()


func _tour_layout() -> void:
	var row: HBoxContainer = _tour.get_node("row")
	var next: Button = row.get_node("next")
	next.text = "GOT IT" if _tour_i == _tour_pages().size() - 1 else "NEXT"
	row.get_child(0).visible = _tour_i == 0
	var b := _tour_box()
	row.reset_size()
	row.position = Vector2(b.end.x - row.size.x - 20, b.end.y - row.size.y - 18)
	_tour.queue_redraw()


func _draw_tour() -> void:
	var t := _target()
	var dim := Color(0, 0, 0, 0.55)
	if t.size == Vector2.ZERO:
		_tour.draw_rect(Rect2(Vector2.ZERO, size), dim)
	else:  # everything dimmed but what it points at
		_tour.draw_rect(Rect2(0, 0, size.x, t.position.y), dim)
		_tour.draw_rect(Rect2(0, t.end.y, size.x, size.y - t.end.y), dim)
		_tour.draw_rect(Rect2(0, t.position.y, t.position.x, t.size.y), dim)
		_tour.draw_rect(Rect2(t.end.x, t.position.y, size.x - t.end.x, t.size.y), dim)
		_tour.draw_rect(t, Style.COLOR_FOCUS, false, 3.0)
	var b := _tour_box()
	var p: Array = _tour_pages()[_tour_i]
	_tour.draw_rect(b.grow(2), Color(0, 0, 0, 0.3))
	_tour.draw_rect(b, Style.COLOR_SURFACE_PAPER)
	_tour.draw_rect(Rect2(b.position, Vector2(b.size.x, 4)), Style.COLOR_TEXT_PAPER_ACCENT)
	_tour.draw_string(Style.caps(800, Style.SIZE_XS), b.position + Vector2(24, 30), "%d OF %d" % [_tour_i + 1, _tour_pages().size()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS, Style.COLOR_TEXT_PAPER_ACCENT)
	_tour.draw_string(Style.caps(900, Style.SIZE_XL), b.position + Vector2(24, 64), p[1], HORIZONTAL_ALIGNMENT_LEFT, b.size.x - 48,
		Style.SIZE_XL, Style.COLOR_TEXT_PAPER)
	_tour.draw_multiline_string(Style.text_font(), b.position + Vector2(24, 96), p[2], HORIZONTAL_ALIGNMENT_LEFT, b.size.x - 48,
		Style.SIZE_MD - 2, -1, Style.COLOR_TEXT_PAPER)


# ---------- what the pilot means ----------

## The first of this job's faults the decoder has an answer for, or "".
func _decode_fault(j: Dictionary) -> String:
	for id in j.faults:
		if DECODE.has(id):
			return id
	return ""


func _show_decode(j: Dictionary) -> void:
	var id := _decode_fault(j)
	_decode = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER
	sb.border_width_top = 6
	sb.border_color = Style.COLOR_TEXT_PAPER_ACCENT
	sb.set_content_margin_all(Style.SPACE_6)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	_decode.add_theme_stylebox_override("panel", sb)
	_decode.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.SPACE_3)
	col.custom_minimum_size.x = 560
	_decode.add_child(col)
	var eyebrow := Style.label("WHAT IS THE PILOT TELLING YOU?", "accent", Style.SIZE_XS, 800)
	eyebrow.add_theme_font_override("font", Style.caps(800, Style.SIZE_XS))
	col.add_child(eyebrow)
	var said := Label.new()  # the pilot's own words, typed as on the squawk sheet
	said.text = "\"%s\"" % main.squawk_line(j, id)
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.custom_minimum_size.x = 560  # wrapped text needs a width, or it lays out a letter per line
	said.add_theme_font_override("font", Style.figures())
	said.add_theme_font_size_override("font_size", Style.SIZE_MD)
	said.add_theme_color_override("font_color", Style.COLOR_TEXT_PAPER)
	col.add_child(said)
	var ask := Style.label("Pilots say what they felt, heard, saw or smelled, never the cause. Where would you look first?", "muted", Style.SIZE_MD, 600)
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.custom_minimum_size.x = 560
	col.add_child(ask)
	var why := Style.label("", "body", Style.SIZE_MD, 600)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size.x = 560
	var go := Button.new()
	go.text = "GO LOOK"
	Style.button(go, "primary")
	go.custom_minimum_size.y = 44
	go.visible = false
	go.pressed.connect(_close_decode)
	var opts: Array = DECODE[id].duplicate()
	opts.shuffle()  # the right answer isn't always first
	for o in opts:
		var b := Button.new()
		b.text = o[0]
		Style.button(b, "quiet")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 44
		b.pressed.connect(func():
			why.text = ("Right. " if o[1] else "Not quite. ") + o[2]
			why.add_theme_color_override("font_color", Style.COLOR_STATUS_OK if o[1] else Style.COLOR_STATUS_WARN)
			if o[1]:
				for c in col.get_children():
					if c is Button and c != go:
						c.disabled = true
				go.visible = true
				go.grab_focus.call_deferred()
				tick("squawk", "Read the squawk: " + o[0].to_lower())
			else:
				b.disabled = true
				main.sound.sfx("deny"))
		col.add_child(b)
	col.add_child(why)
	col.add_child(go)
	add_child(_decode)
	_center.call_deferred(_decode)
	why.resized.connect(func(): _center.call_deferred(_decode))  # an answer's reason makes it taller
	main.player.frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_decode() -> void:
	if is_instance_valid(_decode):
		_decode.queue_free()
	_decode = null
	if main.panel == null:
		main.player.frozen = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Shrinks a card to its contents and centers it on the screen.
func _center(c: Control) -> void:
	if not is_instance_valid(c):
		return
	c.reset_size()
	c.position = ((size - c.size) / 2).floor()
	c.pivot_offset = c.size / 2


# ---------- the reward ----------

func _show_reward(l: int) -> void:
	var r: Dictionary = REWARDS[l]
	_reward = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER
	sb.border_width_top = 6
	sb.border_color = Style.COLOR_TEXT_PAPER_ACCENT
	sb.set_content_margin_all(Style.SPACE_8)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	_reward.add_theme_stylebox_override("panel", sb)
	_reward.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Style.SPACE_3)
	_reward.add_child(col)
	var eyebrow := Style.label("APPRENTICE CHECKLIST   JOB %d OF 3   DONE" % l, "accent", Style.SIZE_XS, 800)
	eyebrow.add_theme_font_override("font", Style.caps(800, Style.SIZE_XS))
	col.add_child(eyebrow)
	var title := Style.label(("SIGNED OFF: " + LESSONS[l].title).to_upper() if l < 3 else "APPRENTICESHIP DONE", "body", Style.SIZE_2XL, 900)
	title.add_theme_font_override("font", Style.caps(900, Style.SIZE_2XL))
	col.add_child(title)
	var learned := Style.label("You learned " + LESSONS[l].teaches + ".", "muted", Style.SIZE_MD, 600)
	col.add_child(learned)
	var bonus := Label.new()
	bonus.text = "BONUS  +$%d" % r.cash + ("     GIFT  COMPRESSION TESTER" if r.gift == "tester" else "")
	bonus.add_theme_font_override("font", Style.figures(true))
	bonus.add_theme_font_size_override("font_size", Style.SIZE_LG)
	bonus.add_theme_color_override("font_color", Style.COLOR_STATUS_OK)
	col.add_child(bonus)
	var line := Style.label(r.line, "body", Style.SIZE_MD, 600)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 480
	col.add_child(line)
	var tally := Style.label("Planes back in the air: %d of %d." % [main.rescued, main.GOAL], "muted", Style.SIZE_SM, 700)
	col.add_child(tally)
	var b := Button.new()
	b.text = "ON TO THE NEXT CALL" if l < 3 else "ON MY OWN"
	Style.button(b, "primary")
	b.custom_minimum_size.y = 44
	b.pressed.connect(_close_reward)
	col.add_child(b)
	add_child(_reward)
	_center(_reward)
	_reward.scale = Vector2(0.92, 0.92)
	_reward.modulate.a = 0.0
	var tw := _reward.create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_reward, "scale", Vector2.ONE, 0.3)
	tw.tween_property(_reward, "modulate:a", 1.0, 0.2)
	main.sound.chime()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	b.grab_focus.call_deferred()


func _close_reward() -> void:
	main.tut.erase("reward")
	main._save_game()
	if is_instance_valid(_reward):
		_reward.queue_free()
	_reward = null
	if main.panel == null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

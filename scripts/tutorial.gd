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
const Work := preload("res://scripts/work.gd")
const Bay := preload("res://scripts/bay.gd")

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
## On arrival each lesson's squawk comes with a mechanic's notes, as you'd pencil them in the
## margin: each telling phrase and what it means, then where to look first. Nothing to answer:
## you read it and go look. {"notes": [[the pilot's phrase, what it means]], "look": where first}.
const NOTES := {
	"bird_nest": {"notes": [
		["Birds flew out of the cowling", "Birds don't leave a cowl unless they've built in it: there's a nest under there."],
		["Haven't flown it since", "Good: a nest packed against a hot cylinder catches fire. Nobody runs it till it's out."]],
		"look": "The engine. Open the cowl and look on top, behind the baffles."},
	"water_fuel": {"notes": [
		["After a week of rain", "Water got in, usually past a fuel cap seal. Water's heavier than gas and sinks to the low point."],
		["Coughed and quit once it warmed up, restarted rough", "Water reaching the carburetor: it runs on what fuel gets through, then stumbles."]],
		"look": "The fuel. The gascolator on the firewall is the low point: drain a sample and look for beads of water."},
	"tire": {"notes": [
		["Sitting low on the left side", "One side down: that wheel's tire is flat or soft."],
		["Pulled hard left on the landing roll", "A soft tire drags and pulls toward its own side. It agrees with the low side."]],
		"look": "The left main gear: the tire and tube."},
	"stuck_valve": {"notes": [
		["Sluggish on the takeoff roll", "Down on power: one cylinder isn't pulling its share."],
		["A rhythmic chuffing pulling the prop through", "Air escaping a cylinder as it comes up on compression: a valve or rings not sealing."]],
		"look": "Inside the engine. Nothing shows outside: run it up, then test each cylinder with the instrument the work order names."},
}

var _card: Control  # the checklist
var _notes: Control  # the squawk notes card
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
		for e in Work.scene_for(id, main.FAULTS[id]).els:
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
		"how": "The map on the hangar workbench: walk up to it and press %s. Take the open call; the others unlock after your apprenticeship." % k.call("interact"),
		"ok": func(): return j != null}
	var squawk := {"id": "squawk", "text": "Read the pilot's squawk",
		"how": "Top right: the pilot's squawk. They say what they felt, heard, saw or smelled, never the cause. Your job: turn it into where to look.",
		"ok": func(): return j != null and _notes_fault(j) == "" and (_at_field > 6.0 or j.checked.size() > 0)}  # no notes for this fault: reading is enough
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
	var sign := {"id": "sign", "text": "Sign off",
		"how": "From the work order at any spot: Sign off. Nobody flies until you sign.",
		"ok": func(): return j != null and j.get("signed", false)}
	var fuel := {"id": "fuel", "text": "Fuel it",
		"how": "The fuel truck by the hangar: half tanks at least, out on the apron.",
		"ok": func(): return j != null and j.get("fuel", 1.0) >= 0.5}
	var fly := {"id": "fly", "text": "Fly it out to the owner",
		"how": "Climb in at the cabin. %s fuel, %s master, %s primer, hold %s to start, then %s full throttle and ease back at 40 mph." \
			% [k.call("fuel_valve"), k.call("master"), k.call("primer"), k.call("starter"), k.call("throttle_up")],
		"ok": func(): return main.rescued > int(main.tut.get("base", 0))}
	match lesson():
		1:
			return [{"id": "tour", "text": "Get your bearings", "how": "", "ok": func(): return main.tut.get("tour", false)},
				call, squawk, walk, writeup, fix, runup, sign, fuel, fly]
		2:
			var tools_step := {"id": "tools", "text": "Get the tools for the job",
				"how": "This one needs %s. The PARTS shed by the apron sells them; the hangar TOOLS box mail-orders (25%% more)." \
					% (", ".join(_missing_tools(j).map(func(t): return Work.TOOLS[t].to_lower())) if j and _missing_tools(j).size() > 0 else "tools you have"),
				"ok": func(): return j != null and _found_all(j) and _missing_tools(j).is_empty()}
			var part_step := {"id": "part", "text": "Get the part",
				"how": "PARTS shed. Not on the shelf? Mail-order it for 25% more. That's the trade.",
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
	var held: bool = main.ticket_open()  # checklist slips wait for the map, never over the ticket (Thad)
	for s in _slips:
		if not held:
			s[1] += delta
	_slips = _slips.filter(func(s): return s[1] < 4.0)
	if not active() or main.current_job == null or main.ferry != null:
		_at_field = 0.0
	else:
		_at_field += delta
	if active() and not main.tut.get("tour", true) and main.panel == null and main.panel_kind != "menu" \
			and not is_instance_valid(main._loader) and main.current_job == null and not is_instance_valid(_tour):
		start_tour()
	if is_instance_valid(_walk) and (main.panel != _walk_panel or main.panel == null):
		_end_walk()  # the menu it was about closed
	elif is_instance_valid(_walk):
		_walk.queue_redraw()
	if active():
		_poll()
		var j = _job()
		if j != null and not main.tut.get("done", {}).has("squawk") and _notes_fault(j) != "" and _at_field > 1.5 \
				and main.panel == null and not is_instance_valid(_notes) and not is_instance_valid(_tour) and not is_instance_valid(_reward) \
				and not is_instance_valid(main._loader):
			_show_notes(j)
	var touring_card: bool = is_instance_valid(_tour) and _tour_pages()[_tour_i][0] == "card"  # the tour page about it shows it
	_card.visible = active() and main.settings.get("checklist", true) and main.panel == null and main.ferry == null \
		and (not is_instance_valid(_tour) or touring_card) and not is_instance_valid(_notes) and not is_instance_valid(main._loader)
	_card.queue_redraw()
	queue_redraw()
	if main.tut.has("reward") and not is_instance_valid(_reward) and main.ferry == null and not is_instance_valid(main._loader) \
			and main.panel_kind != "menu" and main.map_open():  # on the map, after the ticket (Thad)
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


## Marks a step done from outside its check (the squawk notes), with the same tick and slip.
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
	main._quiet_money = true  # the bonus goes on the end-of-mission ticket, not a pop (D3)
	main.money += REWARDS[l].cash
	main._quiet_money = false
	if not main._pending_debrief.is_empty():
		main._pending_debrief.debrief["bonus"] = REWARDS[l].cash
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
			draw_check(_card, box, clampf(_flash.get(s.id, 9.0) / 0.35, 0.0, 1.0))
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


## A red check, drawn in as it ticks (t 0 -> 1). Shared with the cockpit checklist (preflight.gd).
static func draw_check(c: CanvasItem, box: Rect2, t: float, col := Style.COLOR_TEXT_PAPER_ACCENT) -> void:
	var a := box.position + Vector2(3, box.size.y * 0.55)
	var b := box.position + Vector2(box.size.x * 0.42, box.size.y - 3)
	var e := box.position + Vector2(box.size.x + 3, -3)
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
	if main.ticket_open():
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
		["", "AIRPLANE RESCUE", "You're a traveling A&P mechanic: fly out to stranded planes and fly them home.", [
			["THE JOB", "Find what's wrong, fix it right, sign for it."],
			["THE GOAL", "Ten planes back in the air."],
			["THE RISK", "Run out of money and you're grounded."]]],
		["center", "WALK AND USE", "Point the dot at something and press %s." % k.call("interact"), [
			["WALK", "%s %s %s %s" % [k.call("move_forward"), k.call("move_left"), k.call("move_back"), k.call("move_right")]],
			["LOOK", "The mouse."],
			["USE", "%s: the map, a spot on a plane, the fuel truck." % k.call("interact")]]],
		["quest", "YOUR NEXT STEP", "This icon always shows what comes next.", [
			["WHERE", "The markers floating over the plane."]]],
		["card", "YOUR CHECKLIST", "Your first three jobs, one step at a time.", [
			["TICKS", "Each step checks itself off when you do it right."],
			["HELP", "Only the step you're on is explained."]]],
		["pockets", "YOUR POCKETS", "Four things you carry, each on a key. Your cash is top right.", [
			[k.call("clipboard"), "Work order for this plane."],
			[k.call("logbook"), "Logbook: every plane you've saved."],
			[k.call("manual"), "Service manual, open at your job."],
			[k.call("tasks"), "Task list: what's done and what's left."]]],
		["", "READY", "First job: walk to the map on the hangar workbench and press %s." % k.call("interact"), [
			["ESC", "Pause, settings, quit."],
			["SAVING", "Automatic, after every step."]]],
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
	var w := CARD_W
	var h := card_height(p, w)
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
	draw_card(_tour, _tour_box(), _tour_pages()[_tour_i], "%d OF %d" % [_tour_i + 1, _tour_pages().size()])


## Callout cards (tour and walkthroughs) share one layout, so they read the same everywhere:
## a small red eyebrow, the title, one bold line saying the point, then labeled rows (a short
## red term, a one-line detail), then the buttons. A page is [target, title, lead, [[term, detail]]].
const CARD_W := 460.0
const TERM_W := 96.0


static func card_height(p: Array, w: float) -> float:
	var lead_h: float = Style.display(700).get_multiline_string_size(p[2], HORIZONTAL_ALIGNMENT_LEFT, w - 48, Style.SIZE_MD).y
	var h := 70.0 + lead_h + 10.0
	for it in p[3]:
		h += maxf(18.0, Style.text_font().get_multiline_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, w - 48 - TERM_W, Style.SIZE_SM).y) + 8.0
	return h + 64.0  # the buttons


static func draw_card(c: CanvasItem, b: Rect2, p: Array, eyebrow: String) -> void:
	c.draw_rect(b.grow(2), Color(0, 0, 0, 0.3))
	c.draw_rect(b, Style.COLOR_SURFACE_PAPER)
	c.draw_rect(Rect2(b.position, Vector2(b.size.x, 4)), Style.COLOR_TEXT_PAPER_ACCENT)
	var x := b.position.x + 24
	var w := b.size.x - 48
	c.draw_string(Style.caps(800, Style.SIZE_XS), Vector2(x, b.position.y + 26), eyebrow, HORIZONTAL_ALIGNMENT_LEFT, -1,
		Style.SIZE_XS, Style.COLOR_TEXT_PAPER_ACCENT)
	c.draw_string(Style.caps(900, Style.SIZE_LG), Vector2(x, b.position.y + 54), p[1], HORIZONTAL_ALIGNMENT_LEFT, w, Style.SIZE_LG,
		Style.COLOR_TEXT_PAPER)
	var y := b.position.y + 80
	var lead := Style.display(700)
	c.draw_multiline_string(lead, Vector2(x, y), p[2], HORIZONTAL_ALIGNMENT_LEFT, w, Style.SIZE_MD, -1, Style.COLOR_TEXT_PAPER)
	y += lead.get_multiline_string_size(p[2], HORIZONTAL_ALIGNMENT_LEFT, w, Style.SIZE_MD).y - 4
	if p[3].size() > 0:
		c.draw_line(Vector2(x, y), Vector2(x + w, y), Color(Style.COLOR_TEXT_PAPER, 0.18), 1.0)
		y += 6
	for it in p[3]:
		var dh: float = Style.text_font().get_multiline_string_size(it[1], HORIZONTAL_ALIGNMENT_LEFT, w - TERM_W, Style.SIZE_SM).y
		c.draw_string(Style.caps(800, Style.SIZE_XS), Vector2(x, y + 15), String(it[0]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, TERM_W - 8,
			Style.SIZE_XS, Style.COLOR_TEXT_PAPER_ACCENT)
		c.draw_multiline_string(Style.text_font(), Vector2(x + TERM_W, y + 15), it[1], HORIZONTAL_ALIGNMENT_LEFT, w - TERM_W,
			Style.SIZE_SM, -1, Style.COLOR_TEXT_PAPER)
		y += maxf(18.0, dh) + 8.0


# ---------- what the pilot means ----------

## The first of this job's faults with notes written for its squawk, or "".
func _notes_fault(j: Dictionary) -> String:
	for id in j.faults:
		if NOTES.has(id):
			return id
	return ""


## The one-line "look first" note pinned under the squawk while a lesson is on ("" if none).
func squawk_note() -> String:
	var j = _job()
	if not active() or j == null or not main.settings.get("checklist", true):
		return ""
	var id := _notes_fault(j)
	return "" if id == "" else "Look first: " + NOTES[id].look


const NOTES_PAGE_SENTENCES := 3  # the most a squawk page shows (U7, Thad: "smaller chunks")
var _notes_pages: Array = []  # each page: [[kind, text], ...]
var _notes_i := 0
var _notes_col: VBoxContainer


## Splits text into sentences, keeping each one's end mark. Quotes and abbreviations rarely end a
## sentence in these write-ups, so a stop, question or exclamation followed by a space is enough.
static func sentences(text: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var cur := ""
	for i in text.length():
		cur += text[i]
		if text[i] in ".?!" and (i + 1 >= text.length() or text[i + 1] == " "):
			out.append(cur.strip_edges())
			cur = ""
	if cur.strip_edges() != "":
		out.append(cur.strip_edges())
	return out


## The squawk notes as short pages (U7): the pilot's own words first, three sentences a page at most;
## then each telling phrase with what it means, a page each; "Look first" last. Same words, paged.
func notes_pages(j: Dictionary, id: String, wording := "") -> Array:
	var pages: Array = []
	var said := sentences(wording if wording != "" else main.squawk_line(j, id))
	for i in range(0, said.size(), NOTES_PAGE_SENTENCES):
		var chunk := " ".join(said.slice(i, i + NOTES_PAGE_SENTENCES))
		pages.append([["eyebrow", "PILOT SQUAWK"], ["squawk", "\u201c%s\u201d" % chunk]])
	var first := true
	for n in NOTES[id].notes:  # each telling phrase, then what it means (one or two sentences)
		var page: Array = [["eyebrow", "MECHANIC'S NOTES"]]
		if first:  # how to read a squawk, once, ahead of the first clue
			page.append(["intro", "Pilots tell you what they felt, heard, saw or smelled, never the cause: read it for clues to where."])
			first = false
		page.append_array([["phrase", "\u201c%s\u201d" % n[0]], ["means", n[1]]])
		pages.append(page)
	pages.append([["eyebrow", "LOOK FIRST"], ["look", NOTES[id].look]])
	return pages


## `wording` replaces the pilot's words (the self-test's long squawk); "" means the job's own.
func _show_notes(j: Dictionary, wording := "") -> void:
	var id := _notes_fault(j)
	_notes_pages = notes_pages(j, id, wording)
	_notes_i = 0
	_notes = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Style.COLOR_SURFACE_PAPER
	sb.border_width_top = 6
	sb.border_color = Style.COLOR_TEXT_PAPER_ACCENT
	sb.set_content_margin_all(Style.SPACE_8)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 14
	_notes.add_theme_stylebox_override("panel", sb)
	_notes.mouse_filter = Control.MOUSE_FILTER_STOP
	_notes_col = VBoxContainer.new()
	_notes_col.add_theme_constant_override("separation", Style.SPACE_3)
	_notes_col.custom_minimum_size.x = 520.0
	_notes.add_child(_notes_col)
	add_child(_notes)
	_notes_page(0)
	main.player.frozen = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Shows one page of the notes: its parts, then the page count, Back and Next (GO LOOK on the last).
func _notes_page(i: int) -> void:
	_notes_i = clampi(i, 0, _notes_pages.size() - 1)
	for c in _notes_col.get_children():  # out now, not at the frame's end, so the card can shrink to this page
		_notes_col.remove_child(c)
		c.queue_free()
	var w := 520.0
	for part in _notes_pages[_notes_i]:
		var l: Label
		match part[0]:
			"eyebrow":
				l = Style.label(part[1], "accent", Style.SIZE_XS, 800)
				l.add_theme_font_override("font", Style.caps(800, Style.SIZE_XS))
			"squawk":  # the pilot's own words, typed as on the squawk sheet
				l = Label.new()
				l.text = part[1]
				l.add_theme_font_override("font", Style.figures())
				l.add_theme_font_size_override("font_size", Style.SIZE_LG)
				l.add_theme_color_override("font_color", Style.COLOR_TEXT_PAPER)
			"intro":
				l = Style.label(part[1], "muted", Style.SIZE_SM, 600)
			"phrase":
				l = Label.new()
				l.text = part[1]
				l.add_theme_font_override("font", Style.figures(true))
				l.add_theme_font_size_override("font_size", Style.SIZE_MD)
				l.add_theme_color_override("font_color", Style.COLOR_TEXT_PAPER_ACCENT)
			"means":
				l = Style.label(part[1], "body", Style.SIZE_LG, 600)
			"look":
				l = Style.label(part[1], "body", Style.SIZE_LG, 800)
		l.name = String(part[0]).capitalize().replace(" ", "")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = w  # wrapped text needs a width, or it lays out a letter per line
		_notes_col.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size.y = Style.SPACE_2
	_notes_col.add_child(gap)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", Style.SPACE_3)
	_notes_col.add_child(foot)
	var count := Style.label("%d of %d" % [_notes_i + 1, _notes_pages.size()], "muted", Style.SIZE_SM, 700)
	count.name = "Count"
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(count)
	if _notes_i > 0:
		var back := Button.new()
		back.name = "Back"
		back.text = "BACK"
		Style.button(back, "quiet")
		back.custom_minimum_size = Vector2(96, 44)
		back.pressed.connect(func(): _notes_page(_notes_i - 1))
		foot.add_child(back)
	var last := _notes_i == _notes_pages.size() - 1
	var go := Button.new()
	go.name = "GoLook" if last else "Next"
	go.text = "GO LOOK" if last else "NEXT"
	Style.button(go, "primary")
	go.custom_minimum_size = Vector2(160, 44)
	if last:
		go.pressed.connect(func():
			tick("squawk", "Read the squawk")
			_close_notes())
	else:
		go.pressed.connect(func(): _notes_page(_notes_i + 1))
	foot.add_child(go)
	go.grab_focus.call_deferred()  # Enter moves on
	_fit_notes.call_deferred()


## The card fits this page: shrink to its contents (a short page after a long one), then re-centre.
func _fit_notes() -> void:
	if not is_instance_valid(_notes):
		return
	_notes.reset_size()
	_center(_notes)


func _close_notes() -> void:
	if is_instance_valid(_notes):
		_notes.queue_free()
	_notes = null
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
	if r.gift == "tester":  # the bonus is on the ticket with the rest of the money (D3); the gift is here
		var gift := Label.new()
		gift.name = "Gift"
		gift.text = "GIFT  COMPRESSION TESTER"
		gift.add_theme_font_override("font", Style.figures(true))
		gift.add_theme_font_size_override("font_size", Style.SIZE_LG)
		gift.add_theme_color_override("font_color", Style.COLOR_STATUS_OK)
		col.add_child(gift)
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


# ---------- menu walkthroughs ----------
## The first time you open each menu, a few cards walk you round it, each pointing at the part it
## talks about (the rest dimmed). Next (Enter) steps through; Esc or Got it ends it. Seen once
## per career (main.tut.menus), and never again once "Hide walkthroughs" is pressed or the
## apprentice checklist setting is off.

var _walk: Control
var _walk_id := ""
var _walk_i := 0
var _walk_panel  # the menu it's about: if that closes, the walkthrough goes with it
var force_walks := false  # the self-test's --walk-shot shows them even in a test run


func walks_on() -> bool:
	if not main.settings.get("checklist", true) or main.tut.get("menus_off", false):
		return false
	return force_walks or not "--self-test" in OS.get_cmdline_user_args()


## Call when a menu opens. Shows its walkthrough the first time.
func walk(id: String) -> void:
	if not walks_on() or main.tut.get("menus", {}).has(id) or is_instance_valid(_walk) or is_instance_valid(_tour):
		return
	_start_walk.call_deferred(id)


func _start_walk(id: String) -> void:
	await get_tree().process_frame  # the menu lays itself out first (books scale to the window)
	if main.panel == null or is_instance_valid(_walk):
		return
	_walk_id = id
	_walk_i = 0
	_walk_panel = main.panel
	_walk = Control.new()
	_walk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_walk.mouse_filter = Control.MOUSE_FILTER_STOP  # the menu waits underneath
	_walk.draw.connect(_draw_walk)
	add_child(_walk)
	var row := HBoxContainer.new()
	row.name = "row"
	row.add_theme_constant_override("separation", Style.SPACE_3)
	_walk.add_child(row)
	var hide := Button.new()
	hide.text = "HIDE WALKTHROUGHS"
	Style.button(hide, "quiet")
	hide.custom_minimum_size.y = 40
	hide.focus_mode = Control.FOCUS_NONE
	hide.pressed.connect(func():
		main.tut["menus_off"] = true
		_end_walk())
	row.add_child(hide)
	var next := Button.new()
	next.name = "next"
	Style.button(next, "primary")
	next.custom_minimum_size = Vector2(130, 40)
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(_walk_next)
	row.add_child(next)
	_walk_layout()


func _walk_next() -> void:
	main.sound.sfx("click")
	_walk_i += 1
	if _walk_i >= walk_pages(_walk_id).size():
		_end_walk()
		return
	_walk_layout()


func _end_walk() -> void:
	if _walk_id != "":
		main.tut.get_or_add("menus", {})[_walk_id] = true
		main._save_game()
	if is_instance_valid(_walk):
		_walk.queue_free()
	_walk = null
	_walk_id = ""


func _input(ev: InputEvent) -> void:
	if not is_instance_valid(_walk):
		return
	if ev.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_walk_next()
	elif ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_end_walk()


func walking() -> bool:
	return is_instance_valid(_walk)


## [what it points at, title, lead, [[term, detail]]] for each menu. Keys come from the bindings.
func walk_pages(id: String) -> Array:
	var k: Callable = main.key_name
	match id:
		"work_order":
			return [
				["sheet_top", "THE WORK ORDER", "This plane, on one sheet (%s)." % k.call("clipboard"), [
					["SQUAWK", "What the pilot reported."],
					["SPOTS", "How many of the 8 you've checked."]]],
				["sheet_rows", "WRITE-UPS", "Every fault you've found, ready to work.", [
					["FOUND", "What it is and where."],
					["FIX", "The manual page and figure (%s)." % k.call("manual")],
					["PARTS", "Part numbers, and how many you carry."],
					["BUTTON", "Takes you to the work."]]],
				["sheet_bottom", "WHAT'S LEFT", "When nothing's left, it says Airworthy.", [
					["RUN-UP", "From the cabin."],
					["FUEL", "At the truck, on the apron."],
					["LOGBOOK", "Sign it before it flies."]]]]
		"map":
			return [
				["sheet_rows", "RESCUE CALLS", "Pick a plane to rescue. The best pay is first.", [
					["DIFFICULTY", "1 Routine to 5 Expert."],
					["CLEARS", "About what you keep after parts, fuel and the hangar fee."]]],
				["sheet_rows", "WHICH ONE?", "Not sure? Take the one marked (closest you can afford).", [
					["LOCKED", "Calls that open after your apprenticeship."]]],
				["chart", "THE CHART", "Your field and every call.", [
					["COURSE", "The heading and distance to each."],
					["FLY", "Click a town, or Fly on the list."]]]]
		"logbook":
			return [["sheet", "YOUR LOGBOOK", "Every plane you've put back in the air (%s)." % k.call("logbook"), [
				["RANK", "First: what the next rank needs."],
				["EACH ENTRY", "The plane, the station, what you did, what it cleared."],
				["BADGES", "Last: all seven, the ones you've earned in ink."]]]]
		"manual":
			return [
				["book", "THE SERVICE MANUAL", "It opens at whatever you're working on (%s)." % k.call("manual"), [
					["A / D", "Turn the pages."],
					["C", "Contents, by ATA chapter."]]],
				["book_left", "A PAGE PER JOB", "Read the page before you start the job.", [
					["LEFT", "Specs, tools, parts and numbers."],
					["RIGHT", "The figure and the procedure."]]]]
		"shop":
			return [
				["book_mast", "THE PARTS COUNTER", "This town's shed: it stocks only some parts.", [
					["IN STOCK", "Buy it now."],
					["MAIL ORDER", "25% more than the shelf."]]],
				["book_tabs", "THREE SECTIONS", "Tab turns the section.", [
					["PARTS", "For the job."],
					["TOOLS", "Hand tools for your roll."],
					["MATERIALS", "Safety wire, cotter pins, gaskets, oil."]]],
				["book_card", "BUY WHAT'S STAMPED", "NEEDED marks what your written-up job needs. It's listed first.", [
					["EVERYTHING ELSE", "Can wait."]]],
				["", "WHICH TOOL DOES WHAT", "Buy a tool when a job needs it.", _tool_guide()],
				["book_foot", "TURN AND CLOSE", "What you buy rides in your truck.", [
					["PREV / NEXT", "Turn the pages."],
					["CLOSE (ESC)", "Back to the plane."]]]]
		"mailorder":
			return [
				["book_mast", "MAIL ORDER", "Anything in the book, from the hangar.", [
					["ARRIVES", "When you need it."],
					["COSTS", "25% over shelf price."],
					["USE IT", "When the town's shed doesn't have it."]]],
				["book_card", "BUY WHAT'S STAMPED", "NEEDED marks what your job needs.", [
					["OWNED", "Tools you already have."]]],
				["", "WHICH TOOL DOES WHAT", "Buy a tool when a job needs it.", _tool_guide()]]
		"kit":
			return [["sheet", "THE RED TOOLBOX", "Test instruments, by the nose of every plane.", [
				["TAKE ONE", "Its tests appear on the parts it fits."],
				["ONE AT A TIME", "Take the one the work order asks for."]]]]
		"work":
			return [
				["work_head", "THE JOB", "What you're working on.", [
					["LEFT", "The job and its manual reference."],
					["RIGHT", "Parts and materials it still needs."]]],
				["work_roll", "YOUR TOOL ROLL", "Pick the tool for the piece.", [
					["CHOOSE", "Mouse wheel, or 1-9."],
					["GREYED", "Not owned yet, or still in the red toolbox."]]],
				["work_scene", "DO THE WORK", "Hold the mouse on a piece.", [
					["TAKE APART", "Loosen, remove, lift off."],
					["STUCK?", "H shows every step you can do now."]]],
				["work_bench", "THE BENCH", "Where things go while it's apart.", [
					["TRAY", "Screws and bolts."],
					["NEW PART", "Waits at the bottom: pick it up and fit it."]]],
				["", "PUT IT ALL BACK", "Done when the new part is in and everything is tight.", [
					["ESC", "Step away. Your work stays as you left it."]]]]
		"bay":
			return [
				["bay_view", "THE SPOT, OPENED UP", "The real parts. Damage shows on them.", [
					["CLICK", "A part, to see what you can do."]]],
				["bay_view", "LOOK, THEN FIX", "Look closer writes up what you see.", [
					["RED !", "Stays on it until it's fixed."],
					["RED BUTTON", "The written-up job, on that part's card."]]],
				["bay_tabs", "WALK ROUND IT", "The tabs move you round the spot.", [
					["ENGINE", "Close the cowl before you leave."]]]]
		"tasks":
			return [["sheet", "YOUR TASK LIST", "This job, as it stands (%s). Only what you know about." % k.call("tasks"), [
				["DONE", "Green check. Nothing more to do."],
				["TRY AGAIN", "Yellow flag. It went wrong once; it can still be done."],
				["CAN'T BE DONE", "Red cross. No fix here: ground it."],
				["TO DO", "Grey question mark. Not tried yet."]]]]
		"truck":
			return [["sheet", "THE FUEL TRUCK", "Half tanks at least to fly it out.", [
				["WHERE", "On the apron, never in the hangar."],
				["STALE GAS", "Drain it first."]]]]
		"parts_table":
			return [["sheet", "PARTS ON HAND", "Everything you carry, laid out.", [
				["MORE", "PARTS shed, or mail order from the hangar."]]]]
	return []


## Which tool does what (the shops' walkthroughs), as labeled rows.
func _tool_guide() -> Array:
	return [
		["RATCHET", "Most bolts: plugs, wheels, starter, mags."],
		["PLIERS", "Safety wire and cotter pins."],
		["TORQUE", "The final turn on plugs and prop bolts."],
		["INSTRUMENTS", "Tester, timing light, fabric tester: red toolbox."]]


## Screen rectangle of what a walkthrough page points at (empty: nothing, the card sits centered).
func _walk_rect(target: String) -> Rect2:
	var p = main.panel
	var sheet_w: float = main.SHEET_W
	match target:
		"sheet": return Rect2(0, 0, sheet_w, size.y)
		"sheet_top": return Rect2(0, 0, sheet_w, size.y * 0.32)
		"sheet_rows": return Rect2(0, size.y * 0.1, sheet_w, size.y * 0.62)
		"sheet_bottom": return Rect2(0, size.y * 0.62, sheet_w, size.y * 0.38)
		"chart":
			return main._side.get_global_rect() if is_instance_valid(main._side) else Rect2()
	if p != null and "_book" in p and is_instance_valid(p._book):
		var book: Control = p._book
		var bs: Vector2 = p.BOOK
		var at := func(r: Rect2) -> Rect2: return Rect2(book.global_position + r.position * book.scale, r.size * book.scale)
		match target:
			"book": return at.call(Rect2(Vector2.ZERO, bs))
			"book_left": return at.call(Rect2(0, 0, bs.x / 2, bs.y))
			"book_mast": return at.call(Rect2(0, 0, bs.x / 2, 192))
			"book_tabs": return at.call(Rect2(bs.x / 2 + 20, 8, bs.x / 2 - 40, 60))
			"book_card": return at.call(Rect2(20, 186, bs.x / 2 - 40, 210))
			"book_foot": return at.call(Rect2(0, bs.y - 80, bs.x, 80))
	if p is Work:
		var o: Vector2 = p._origin()
		var kk: float = p.k
		match target:
			"work_head": return Rect2(0, 0, size.x, Work.HEAD)
			"work_roll": return Rect2(0, size.y - Work.BAR, size.x, Work.BAR)
			"work_scene": return Rect2(o, Vector2(Work.BENCH.position.x - 8, Work.H) * kk)
			"work_bench": return Rect2(o + Work.BENCH.position * kk, Work.BENCH.size * kk)
	if p is Bay:
		match target:
			"bay_view": return Rect2(p._origin(), p.VIEW * p._k())
			"bay_tabs":
				var tr: Rect2 = p._tabs.get_global_rect() if is_instance_valid(p._tabs) else Rect2()
				return tr if tr.size.x > 4 else Rect2()
	return Rect2()


## Beside what it points at: right, left, below or above, whichever fits; centered if nothing does.
func _walk_box() -> Rect2:
	var pg: Array = walk_pages(_walk_id)[_walk_i]
	var w := CARD_W
	var h := card_height(pg, w)
	var t := _walk_rect(pg[0])
	var screen := Rect2(Vector2.ZERO, size).grow(-12)
	if t.size != Vector2.ZERO:
		for r in [Rect2(t.end.x + 18, t.position.y + 12, w, h), Rect2(t.position.x - w - 18, t.position.y + 12, w, h),
				Rect2(t.get_center().x - w / 2, t.end.y + 14, w, h), Rect2(t.get_center().x - w / 2, t.position.y - h - 14, w, h)]:
			var c := Rect2(Vector2(clampf(r.position.x, 12, size.x - w - 12), clampf(r.position.y, 12, size.y - h - 12)), r.size)
			if screen.encloses(c) and not c.grow(-4).intersects(t):
				return c
	return Rect2(size / 2 - Vector2(w, h) / 2, Vector2(w, h))


func _walk_layout() -> void:
	var row: HBoxContainer = _walk.get_node("row")
	var next: Button = row.get_node("next")
	next.text = "GOT IT" if _walk_i == walk_pages(_walk_id).size() - 1 else "NEXT"
	var b := _walk_box()
	row.reset_size()
	row.position = Vector2(b.end.x - row.size.x - 20, b.end.y - row.size.y - 16)
	_walk.queue_redraw()


func _draw_walk() -> void:
	if _walk_id == "":
		return
	var pages: Array = walk_pages(_walk_id)
	var pg: Array = pages[_walk_i]
	var t := _walk_rect(pg[0])
	var dim := Color(0, 0, 0, 0.5)
	if t.size == Vector2.ZERO:
		_walk.draw_rect(Rect2(Vector2.ZERO, size), dim)
	else:  # everything dimmed but what it points at
		_walk.draw_rect(Rect2(0, 0, size.x, t.position.y), dim)
		_walk.draw_rect(Rect2(0, t.end.y, size.x, size.y - t.end.y), dim)
		_walk.draw_rect(Rect2(0, t.position.y, t.position.x, t.size.y), dim)
		_walk.draw_rect(Rect2(t.end.x, t.position.y, size.x - t.end.x, t.size.y), dim)
		_walk.draw_rect(t, Style.COLOR_FOCUS, false, 3.0)
	draw_card(_walk, _walk_box(), pg, "WALKTHROUGH   %d OF %d" % [_walk_i + 1, pages.size()])

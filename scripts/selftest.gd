extends Node
## The game's self-test: plays a whole rescue through the real code paths (travel, inspect,
## run-up, every work scene bolt by bolt, save/load, the ferry flight) and quits with 0 on
## pass, 1 on fail.  godot --path . -- --self-test [--all-faults] [--city=X] [--seed=N] [--shot=prefix]
## --all-fields flies a forced landing at every field instead: run it before a release.
## Started by main.gd; `g` is the running game.

const Work := preload("res://scripts/work.gd")
const Bay := preload("res://scripts/bay.gd")
const Ferry := preload("res://scripts/ferry.gd")
const Updater := preload("res://scripts/updater.gd")

var g  # main.gd


## The watchdog: a self-test that stops must fail and say where, never pass or wait forever.
## A thread watches from outside the game loop: if frames stop for FROZEN_S (a loop that never
## yields), or the whole run passes LIMIT_S (an await that never resumes), it prints the last
## place the test reported (`_at`) and ends the run as a FAIL.
var FROZEN_S := 60
var LIMIT_S := 420
var phase := "start"
var _phase_t := 0
var _watch: Thread
var _watching := true


func _at(where: String) -> void:
	phase = where
	_phase_t = Time.get_ticks_msec()


func _watchdog() -> void:
	var start := Time.get_ticks_msec()
	var last_frame := Engine.get_process_frames()
	var last_seen := start
	while _watching:
		OS.delay_msec(500)
		var f := Engine.get_process_frames()
		var now := Time.get_ticks_msec()
		if f != last_frame:
			last_frame = f
			last_seen = now
		var frozen: bool = now - last_seen > FROZEN_S * 1000
		if frozen or now - start > LIMIT_S * 1000:
			print("SELF-TEST FAIL hang (%s) at: %s, for %d s; seed=%d" % ["frames stopped" if frozen else "never finished",
				phase, (now - _phase_t) / 1000, g.test_seed if g else 0])
			OS.kill(OS.get_process_id())  # the main thread may be stuck: end the process from here
			return


func _exit_tree() -> void:
	_watching = false
	if _watch and _watch.is_started():
		_watch.wait_to_finish()


var _trip_volume := -80.0
var _trip_saved_at := ""
var _quit_open := false  # the pause menu offered a way out during an emergency


func run(main, args: PackedStringArray) -> void:
	g = main
	_at("run")
	if DisplayServer.get_name() != "headless":
		LIMIT_S = 1800  # a run with a display draws every frame and takes far longer (screenshots)
	for a in args:  # --hang-test=wait|frozen: hang on purpose, to prove the watchdog fails it
		if a.begins_with("--hang-test="):
			LIMIT_S = 8
			FROZEN_S = 4
	_watch = Thread.new()
	_watch.start(_watchdog)
	var shot = ""
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	if "--all-fields" in args:
		var fields_ok: bool = await _all_fields()
		print("ALL-FIELDS ", "PASS" if fields_ok else "FAIL", " seed=", g.test_seed)
		get_tree().quit(0 if fields_ok else 1)
		return
	for a in args:
		if a.begins_with("--manual-shot="):  # manual pages by job id: --manual-shot=prefix:job,job (contents if none)
			var spec := a.trim_prefix("--manual-shot=").split(":")
			for job in (Array(spec[1].split(",")) if spec.size() > 1 else [""]):
				g._open_manual(job)
				await _snap(spec[0], "manual_" + (job if job != "" else "contents"), 0.8)
				g._close_manual()
			get_tree().quit(0)
			return
	for a in args:
		if a.begins_with("--walk-shot="):  # every menu's first-time walkthrough, page by page
			var pre := a.trim_prefix("--walk-shot=")
			var wj: Dictionary = g.jobs[0]
			await g._travel(wj, 0)
			for id in wj.faults:
				wj.found[id] = true
			g.tutorial.force_walks = true
			g.tut["menus"] = {}
			g.tools.merge({"ratchet": true, "pliers": true})
			var openers := {"work_order": func(): g._open_inspection("engine"), "map": g._open_travel,
				"logbook": g._open_logbook, "manual": func(): g._open_manual(""), "shop": g._open_shop, "mailorder": g._open_toolbox,
				"kit": g._open_kit, "work": func(): g._open_work(wj.faults[0], func(): pass), "bay": func(): g._open_bay(g.FAULTS[wj.faults[0]].zone),
				"truck": g._open_truck, "parts_table": g._open_parts_table, "tasks": g._open_tasks}
			for id in openers:
				g._close_panel()
				await get_tree().process_frame
				openers[id].call()
				for _f in 4:
					await get_tree().process_frame
				var n: int = g.tutorial.walk_pages(id).size()
				if not g.tutorial.walking():
					print("WALK ", id, ": no walkthrough came up")
				for i in n:
					await _snap(pre, "%s_%d" % [id, i], 0.3)
					if g.tutorial.walking():
						g.tutorial._walk_next()
				if id == "tasks":  # and the sheet itself, once its walkthrough is done
					await _snap(pre, "tasks_sheet", 0.3)
			get_tree().quit(0)
			return
		if a.begins_with("--tutorial-shot="):  # the apprenticeship: tour pages, checklist, squawk quiz, reward
			var pre := a.trim_prefix("--tutorial-shot=")
			g.tut = {"lesson": 1, "tour": false, "done": {}, "base": 0}
			g.jobs.clear()
			for _i in g.MAX_JOBS:
				g._spawn_job()
			g.tutorial.start_tour()
			for i in g.tutorial._tour_pages().size():
				await _snap(pre, "tour_%d" % i, 0.4)
				g.tutorial._tour_next()
			await _snap(pre, "home_card", 0.4)
			var tj: Dictionary = g.jobs[0]
			await g._travel(tj, 0)
			g.tutorial._show_notes(tj)
			await _snap(pre, "notes", 0.4)
			g.tutorial._close_notes()
			g._inspect_zone("prop")
			g._close_panel()
			await _snap(pre, "field_card", 0.6)
			# The debrief sheet, from this job's own record of what cost extra (E5).
			g.note_cost("mag_call", 0, "Left mag called bad")
			g.note_cost("mail", 30, "Gasket kit by mail")
			g.logbook.append({"city": tj.city, "type": tj.type, "pay": tj.reward, "work": []})
			g.logbook[-1]["debrief"] = g.job_debrief(tj, tj.reward, [], false)
			g._pending_debrief = g.logbook[-1]
			g.tutorial._close_notes()  # the squawk notes belong to the walk-around, not the ticket
			g._open_debrief()
			await _snap(pre, "debrief", 0.5)
			g._close_panel()
			g.tut["reward"] = 2
			await _snap(pre, "reward", 0.8)
			get_tree().quit(0)
			return
		if a.begins_with("--settings-shot="):  # every settings tab, for checking the sheet
			var pre := a.trim_prefix("--settings-shot=")
			g._open_pause()  # the pause menu that leads to it
			await _snap(pre, "pause", 0.5)
			g._open_settings(g._open_pause)
			for t in g.panel.TABS:
				g.panel.tab = t[0]
				g.panel._build()
				await _snap(pre, "settings_" + t[0], 0.5)
			g._close_panel()
			for mode in ["off", "deutan"]:  # the color-vision filter compiles and changes the picture
				g.set_setting(mode, "colorblind")
				await _snap(pre, "vision_" + mode, 0.5)
			g.set_setting("off", "colorblind")
			get_tree().quit(0)
			return
	for a in args:
		if a.begins_with("--scene-shots="):  # every work scene at its start and part-way, for checking art placement
			var spec := a.trim_prefix("--scene-shots=").split(":")  # prefix[:scene,scene] to shoot only some
			await _scene_shots(spec[0], Array(spec[1].split(",")) if spec.size() > 1 else [])
			get_tree().quit(0)
			return
	for a in args:
		if a == "--hang-test=wait":
			_at("hang test: waiting on a signal that never comes")
			await get_tree().create_timer(9999.0).timeout
		elif a == "--hang-test=frozen":
			_at("hang test: a loop that never yields")
			while true:
				OS.delay_msec(100)
	_at("edge tests")
	var edges_ok: bool = _edge_tests() and _torque_test() and _faults_test() and Work.spin_dir("tight") < 0.0 and Work.spin_dir("loose") > 0.0 and Work.spin_dir("snug") > 0.0
	var scenes_ok = _scene_tests()
	var lesson := 0
	for a in args:
		if a.begins_with("--tutorial"):  # --tutorial=N: play lesson N's job (tutorial.gd), checking every step ticks
			lesson = int(a.trim_prefix("--tutorial=")) if a.contains("=") else 1
	if lesson > 0:
		g.tut = {"lesson": lesson, "tour": true, "done": {}, "base": g.rescued}
		if lesson == 3:
			g.tools["tester"] = true  # lesson 2's gift
		g.jobs.clear()
		g._spawn_job()
	var lesson_steps: Array = g.tutorial.steps().map(func(st): return st.id)
	var job: Dictionary = g.jobs[0]
	if "--all-faults" in args:  # every broken part one plane can have at once, for screenshots
		var excl: Array = g.PLANE_TYPES.filter(func(t): return t[0] == job.type)[0][2]
		g._assign_faults(job, g.FAULTS.keys().filter(func(id): return not g.FAULTS[id].get("ground", false) \
			and id != "fod" and not id in excl and id != "storage"))
		job.years = 9  # a long-sat plane: grime, stale fuel, dry engine, stuck door
		job.washed = false
		job.annual = false
	for a in args:
		if a.begins_with("--faults="):  # a chosen set, e.g. --faults=weight_balance,tire
			g._assign_faults(job, Array(a.trim_prefix("--faults=").split(",")))
	job.faults = job.faults.filter(func(id): return not g.FAULTS[id].get("ground", false))  # grounding has its own test
	job.preheated = true  # the cold-start rule has its own test
	job.fabric_bad = -1  # a failed punch test grounds the plane; that has its own test
	for a in args:
		if a.begins_with("--difficulty="):  # easy, medium (default) or hard
			g.difficulty = a.trim_prefix("--difficulty=")
	for a in args:
		if a.begins_with("--city="):  # pick the field, e.g. a plains town to see trees
			job.city = a.trim_prefix("--city=")
	var start = g.money
	while not g._warming.is_empty():  # a player spends this on the title screen
		await get_tree().process_frame
	var trip_start := Time.get_ticks_msec()
	_trip_probe()
	await g._travel(job, 0)
	var trip_ms := Time.get_ticks_msec() - trip_start
	if lesson > 0:  # the squawk notes: no quiz, one button, and it ticks the step
		g.tutorial._show_notes(job)
		var go: Array = g.tutorial._notes_col.find_children("*", "Button", true, false)
		if go.size() != 1 or g.tut.done.has("squawk") or g.tutorial.squawk_note() == "":
			print("TUTORIAL: the squawk notes card should open with one button, tick nothing yet, and pin a look-first note")
			_chk(false, 1)
		for k in g.tutorial._notes_pages.size() - 1:  # page through to GO LOOK (U7)
			g.tutorial._notes_page(g.tutorial._notes_i + 1)
		go = g.tutorial._notes_col.find_children("GoLook", "Button", true, false).filter(func(b): return not b.is_queued_for_deletion())
		if go.size() != 1:
			print("TUTORIAL: no GO LOOK on the last page of the squawk notes")
			_chk(false, 1)
		go[0].pressed.emit()
		if not g.tut.done.has("squawk") or is_instance_valid(g.tutorial._notes):
			print("TUTORIAL: Go look didn't tick the squawk step and close the notes")
			_chk(false, 1)
	var clip: AudioStreamWAV = g.sound._cruise.stream
	var art_ok: bool = ["res://textures/logo_title.png", "res://textures/logo_ghost.png", "res://textures/logo_decal.png", "res://textures/rescue_photo.png", "res://fonts/Yellowtail-Regular.ttf", "res://fonts/BigShouldersDisplay.ttf"].all(func(p): return ResourceLoader.exists(p))
	var trip_ok: bool = art_ok and trip_ms >= 3000 and clip.get_length() > 7.9 and clip.data.count(0) < clip.data.size() / 2 and not is_instance_valid(g._loader) and not g.player.frozen and _trip_volume > -8.0 and _trip_saved_at == job.city and not g.get_viewport().disable_3d
	print("trip %d ms, drone %.1f s at %.1f dB, ok=%s" % [trip_ms, clip.get_length(), _trip_volume, trip_ok])
	await _snap(shot, "broken", 1.5)
	g._light_marker("cabin")  # aiming at a spot lights its ring; looking away puts it out
	var cabin_mark: Label3D = g.plane.get_node("marker_cabin")
	var marks_ok: bool = cabin_mark.get_node("ring").visible and cabin_mark.get_node("glow").visible
	for icon in ["map", "question", "wrench", "runup", "sign", "fuel", "hangar", "fly", "inspect", "saved", "wallet", "clipboard", "logbook"] + g.ACT_ICONS.values():
		marks_ok = marks_ok and ResourceLoader.exists("res://textures/hud/%s.svg" % icon)
	g._light_marker("")
	marks_ok = marks_ok and cabin_mark.get_node("ring").visible and not cabin_mark.get_node("glow").visible
	var was_at: Vector3 = g.player.position  # aiming at the marker itself selects it, from outside the ray's reach
	g.player.global_position = cabin_mark.global_position + Vector3(0, -1.65, -4.5)
	g.player.cam.look_at(cabin_mark.global_position)
	marks_ok = marks_ok and g._aimed_marker() == "cabin"
	g.player.cam.look_at(cabin_mark.global_position + Vector3(3, 0, 0))
	marks_ok = marks_ok and g._aimed_marker() != "cabin"
	g.player.position = was_at
	g.player.cam.rotation = Vector3.ZERO
	g.log_clear()  # the engine log never shows more than two messages, live line included
	for line in ["one", "two", "three"]:
		g.log_line(line)
	var shown := func() -> int: return g._log_list.get_children().filter(func(l): return l.visible).size() + (1 if g._log_now.visible else 0)
	marks_ok = marks_ok and shown.call() == 2
	g.log_live("Cranking...")
	marks_ok = marks_ok and shown.call() == 2
	g.log_clear()
	if shot != "":
		var spot: Vector3 = g.plane.to_global(g.ZONES.prop.pos)  # the prop stands clear of the hull
		var stand: Vector3 = g.plane.to_global(g.ZONES.prop.pos + Vector3(0, 0, -2.0))
		g.player.position = Vector3(stand.x, 0.1, stand.z)
		g.player.look_at(Vector3(spot.x, 0.1, spot.z), Vector3.UP)
		g.player.cam.rotation.x = atan2(spot.y - 1.7, Vector2(stand.x - spot.x, stand.z - spot.z).length())
		await _snap(shot, "marker_lit")
		print("aimed at ", g._lit_zone, " live=", g.cross.live)
	if shot != "":  # title screen and the travel card
		g._open_menu()
		await _snap(shot, "menu")
		g._close_menu()
		g._show_loading("Flying to Omaha", "264 NM.\nThe owner: " + g._symptoms(job), "Dallas", "Omaha")
		g._bar.value = 60
		await _snap(shot, "loading")
		g._arrival_card("Omaha")
		await _snap(shot, "arrival")
		g._hide_loading()
	if shot != "":  # wheels close up, while any flat tire is still flat
		for v in [["gear", Vector3(2.2, 0.1, 4.6), Vector3(0, 0, 7.1)], ["gear_l", Vector3(2.2, 0.1, 11.4), Vector3(0, 0, 8.9)],
				["gear_front", Vector3(-7.5, 0.1, 8.6), Vector3(0, 0, 8)], ["tail", Vector3(8.5, 0.1, 5.0), Vector3(5, 0, 8)],
				["side", Vector3(1.5, 0.1, 1.0), Vector3(1.5, 0, 8)]]:
			g.player.position = v[1]
			g.player.look_at(Vector3(v[2].x, g.player.position.y, v[2].z), Vector3.UP)
			g.player.cam.rotation.x = -0.35
			await _snap(shot, v[0])
		var low := Camera3D.new()  # from between the gear legs: the brake disc sits inboard of the wheel
		g.world.add_child(low)
		low.position = Vector3(1.0, 0.32, 8.0)
		low.look_at(g.plane.to_global(Vector3(0.8, 0.25, 0)), Vector3.UP)
		low.make_current()
		await _snap(shot, "brake_inboard")
		g.player.cam.make_current()
		low.queue_free()
		g._load_field(g.location, job)
	g._open_travel()
	await _snap(shot, "calls")
	g._open_radio()
	await _snap(shot, "radio")
	var set_panel = g.panel
	set_panel.tune(4)  # Your Music: the set goes quiet and the keys reach the PC's player
	var radio_ok: bool = g.sound.station == 4 and g.settings.station == 4 and set_panel._transport.visible and not g.sound._music.playing
	set_panel._press(179)
	radio_ok = radio_ok and g.media_sent == [179]
	await _snap(shot, "radio_yours")
	set_panel.tune(0)
	radio_ok = radio_ok and g.sound.station == 0 and not set_panel._transport.visible
	g._close_panel()
	g._pocket("wallet")  # W1: there's no wallet any more; the old pocket opens nothing
	var pockets_ok = g.panel == null and not g.has_method("_open_wallet")
	pockets_ok = await _cash_ok(shot) and pockets_ok
	g._pocket("logbook")
	await _snap(shot, "logbook")
	g._pocket("logbook")  # same key again puts it away
	pockets_ok = pockets_ok and g.panel == null
	# The service manual opens (to the contents here) and every spread builds.
	g._pocket("manual")
	pockets_ok = pockets_ok and g.panel_kind == "manual" and g.manual_data.get("pages", []).size() > 0
	await _snap(shot, "manual")
	g._pocket("manual")
	pockets_ok = pockets_ok and g.panel == null
	var first_zone: String = g.FAULTS[job.faults[0]].zone
	if not job.washed:  # grime hides everything until it's washed
		await _snap(shot, "grimy")
		g._inspect_zone(first_zone)
		pockets_ok = pockets_ok and job.checked.is_empty() and job.found.is_empty()
		g._wash()
		pockets_ok = pockets_ok and job.washed
	g._inspect_zone(first_zone)  # one spot: nothing is found until you look, then only what that spot shows
	await _snap(shot, "look_" + first_zone)
	pockets_ok = pockets_ok and (g.panel is Work or g.panel is Bay) and job.found.is_empty() and g.panel.solve() and g.panel is PanelContainer
	await _snap(shot, "inspect")
	var ok: bool = pockets_ok and radio_ok and marks_ok and (job.found.size() < job.faults.size() or job.faults.all(func(id): return g.FAULTS[id].zone == first_zone))
	for z in g.ZONES:
		g._inspect_zone(z)
		if g.panel is Work or g.panel is Bay:
			ok = ok and g.panel.solve()
	if shot != "":  # the engine bay: cowled, then each side opened up, and a part's card
		g._open_station("engine")
		await _snap(shot, "bay_cowled")
		g.bay_open_cowl()
		for v in Bay.OPEN_VIEWS:
			g.panel._go(v)
			await _snap(shot, "bay_" + v)
		g.panel._go("left")
		g.tools["tester"] = true
		g.held = "tester"
		var with_work := "plugs"  # the card of a part with written-up work on it, if this plane has one
		for p in g.panel.parts():
			if p.look.any(func(i): return job.faults.has(i)):
				with_work = p.id
		g.panel._open_card(g.panel._part(with_work), Vector2(420, 300))
		await _snap(shot, "bay_card")
		g.held = ""
		g.panel._close_card()
		g.bay_close_cowl()
		g._close_panel()
		for z in g.ZONES:  # every other spot: its parts, as painted
			if z == "engine":
				continue
			g._open_bay(z)
			for v in g.panel.views():
				g.panel._go(v)
				await _snap(shot, "spot_%s_%s" % [z, v])
		g._close_panel()
		g.station_zone = ""
	if not g.guide("medium"):  # hard: no clues; you find things by opening up the right place
		for id in job.faults:
			if g._how(job, id) == "walk" and g.PLACES.has(id):
				g.station_open(g.FAULTS[id].zone, id)
		g._close_panel()
	# The walk-around finds what you can see; the rest shows on a run-up or in troubleshooting.
	ok = ok and job.checked.size() == g.ZONES.size() and job.faults.all(func(id): return job.found.has(id) == (g._how(job, id) == "walk"))
	_chk(ok, 68)
	g._refresh_markers()  # a written-up spot keeps its "!" until the job's done, on every difficulty
	for id in job.faults:
		if job.found.has(id) and not job.fixed.has(id):
			var mk: Label3D = g.plane.get_node_or_null("marker_" + g.FAULTS[id].zone)
			if mk == null or not mk.visible or mk.text != "!":
				print("MARKER ", id, ": written up but its spot shows no \"!\"")
				ok = false
	_chk(ok, 69)
	# A part's card puts what's written up first: its job is "due" there (bay.gd _due), on every difficulty.
	var tools_before: Dictionary = g.tools.duplicate()
	for id in job.faults:
		if job.found.has(id) and not job.fixed.has(id) and g.PLACES.has(id) and not g.FAULTS[id].get("ground", false):
			var bay = Bay.new()
			bay.setup(g, g.FAULTS[id].zone)
			var hit := false
			for v in bay.views():
				bay.view = v
				for p in bay.parts():
					for act in p.acts.filter(func(a): return a[2] == id):
						g.tools.merge({"screwdriver": true, "ratchet": true, "pliers": true, "rag": true, "torque": true, act[0]: true})
						var held_was: String = g.held
						if act[0] in g.INSTRUMENTS:
							g.held = act[0]  # an instrument's job shows with it in hand
						hit = hit or bay.actions(p).any(func(a): return a.do == id and a.get("due", false))
						g.held = held_was
			bay.free()
			if not hit:
				print("CARD ", id, ": written up, but no part card puts its job first")
				ok = false
	g.tools = tools_before
	_chk(ok, 70)
	# The parts table rebuilds once per frame however many times it's asked (many rebuilds in one
	# frame used to crash the engine now and then): asking twice leaves one rebuild pending.
	g._refresh_parts_table()
	g._refresh_parts_table()
	var pending: bool = g._parts_table_dirty
	await get_tree().process_frame
	ok = ok and pending and not g._parts_table_dirty
	_chk(ok, 71)
	# The task list (P3): all four states, and never a fault you haven't found.
	var tj := {"city": job.city, "type": "Test", "faults": [], "found": {}, "fixed": {}, "checked": {"prop": true},
		"work": {}, "tried": {}, "fuel": 0.2, "parked": "apron"}
	g._assign_faults(tj, ["tire", "brakes", "prop_strike", "spark_plugs", "magneto"])
	tj.found = {"tire": true, "brakes": true, "prop_strike": true}
	tj.fixed = {"tire": true}
	tj.caused = {"brakes": true}  # broken by running it unready: to do again
	tj.runup = "dead"
	if tj.diag.has("magneto"):
		tj.sym = {"magneto": true}  # heard, not tracked down, one wrong call so far
		tj.misses = {"magneto": 1}
	var tl: Array = g.task_list(tj)
	var by := func(text: String) -> String:
		for t in tl:
			if String(t.text).contains(text):
				return t.state
		return ""
	var tasks_ok: bool = by.call("Flat main tire") == "done" and by.call("Fix: " + g.FAULTS.brakes.name) == "retry" \
		and by.call(g.FAULTS.prop_strike.name) == "failed" and by.call("Check all") == "todo" and by.call("Run it up") == "retry" \
		and not tl.any(func(t): return String(t.text).contains(g.FAULTS.spark_plugs.name) or String(t.text).contains(g.FAULTS.magneto.name)) \
		and (not tj.diag.has("magneto") or by.call("Track it down") == "retry")
	g._pocket("tasks")
	tasks_ok = tasks_ok and g._list_title == "Task list"
	g._close_panel()
	# E4: running it unready marks what else mustn't be run, until the next run-up. A cause whose
	# damage this plane doesn't have, so its 3D parts aren't touched.
	var cause: String = ""
	for c in g.RUNUP_DAMAGE:
		if not job.faults.has(g.RUNUP_DAMAGE[c][0]):
			cause = c
			break
	if cause != "":
		var real = g.current_job
		var dj := {"city": job.city, "type": "Test", "faults": [cause], "found": {cause: true}, "fixed": {}, "work": {}, "checked": {}}
		g.current_job = dj
		var unmarked: bool = not g._fault_row(cause, "", false)[0].begins_with("DON'T RUN IT YET")
		g._run_damage(dj, cause)
		var marked: bool = g._fault_row(cause, "", false)[0].begins_with("DON'T RUN IT YET")
		g._aid_off("runup")  # what _start_runup does
		var cleared: bool = not g._fault_row(cause, "", false)[0].begins_with("DON'T RUN IT YET")
		g.current_job = real
		if not (unmarked and marked and cleared):
			print("AID run-up: unmarked=", unmarked, " marked=", marked, " cleared=", cleared)
			tasks_ok = false
	if not tasks_ok:
		print("TASK LIST: ", tl)
	ok = ok and tasks_ok
	_chk(ok, 73)
	_run_up()
	# A clean start hears every run-up fault; a dead battery or starter cuts the test short.
	# On Easy the run-up is refused while known don't-run-it work is open.
	var refused: bool = g.guide("easy") and job.faults.any(func(id): return g.RUNUP_DAMAGE.has(id) and job.found.has(id))
	ok = ok and (refused or job.faults.filter(func(id): return g._how(job, id) == "runup").all(func(id):
		return job.found.has(id) or job.runup == "dead"))
	_chk(ok, 72)
	if not refused and job.faults.has("battery") and not job.faults.any(func(id): return id in ["door_pin", "storage"]):
		ok = ok and job.runup == "ran" and job.found.has("battery")  # flat battery: you hand-prop it
		_chk(ok, 75)
	# Save, scramble, load: everything comes back and the job here is still the one you're on.
	g._save_game()
	var before = [g.money, g.rescued, g.jobs.size(), g.current_job.city, g.current_job.checked.size()]
	g.money = -999
	g.current_job = null
	g.jobs = []
	var loaded = g._load_game()
	ok = ok and loaded and [g.money, g.rescued, g.jobs.size(), g.current_job.city, g.current_job.checked.size()] == before \
		and g.jobs.has(g.current_job)
	job = g.current_job  # the loaded copy is the live one now
	# A write that failed partway (full disk) never replaces the good save.
	var bad_tmp = FileAccess.open(g.save_path + ".tmp", FileAccess.WRITE)
	bad_tmp.store_string("not a save")
	bad_tmp.close()
	var good_day = g._read_save(g.save_path).money
	ok = ok and not g._commit_save(g.save_path + ".tmp") and g._read_save(g.save_path).money == good_day \
		and not FileAccess.file_exists(g.save_path + ".tmp")
	# A torn write (garbage in the main file) falls back to the .bak copy.
	g._save_game()  # main = this state, .bak = the one before
	var torn = FileAccess.open(g.save_path, FileAccess.WRITE)
	torn.store_string("not a save")
	torn.close()
	ok = ok and g._load_game() and not g.save_locked
	_chk(ok, 92)
	job = g.current_job
	# A save from a newer game is left alone: not loaded, and never autosaved over.
	var newer_save = FileAccess.open(g.save_path, FileAccess.WRITE)
	newer_save.store_var({"version": g.SAVE_VERSION + 1, "money": 1})
	newer_save.close()
	DirAccess.remove_absolute(g.save_path + ".bak")
	var money_before = g.money
	ok = ok and not g._load_game() and g.save_locked and g.money == money_before
	_chk(ok, 100)
	g._save_game()
	ok = ok and int(g._read_save(g.save_path).version) == g.SAVE_VERSION + 1  # still the newer file
	_chk(ok, 102)
	g.save_locked = false
	g._save_game()
	g._load_field(g.location, job)
	if DisplayServer.get_name() != "headless":  # a closed panel still hands the mouse back to the player
		g._close_panel()
		await get_tree().process_frame
		ok = ok and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	g._open_shop()
	var tab := InputEventKey.new()  # Tab turns to the next section and stays in the catalog
	tab.keycode = KEY_TAB
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	var was_section: int = g.panel._sec
	g._input(tab)
	ok = ok and g.panel.has_method("next_section") and g.panel._sec != was_section
	g.panel._tab(0)
	ok = ok and g.panel.get_child(0).size == g.get_viewport().get_visible_rect().size  # the backdrop covers the world
	await _snap(shot, "shop")
	if shot != "":
		g.panel._tab(1)
		await _snap(shot, "shop_tools")
		g.panel._tab(0)
	# Work scenes: with no tools nothing comes apart; with tools but no part it stalls at the
	# empty slot; with both, the whole job gets done bolt by bolt.
	# A job whose first fixable scene has bolts to turn (a few, like weight and balance, need no tools).
	var bolted: Array = job.faults.filter(func(id): return job.found.has(id) and Work.scene_for(id, g.FAULTS[id]).els.any(func(e): return e.type == "fastener" \
		and Work.scene_for(id, g.FAULTS[id]).els.any(func(h): return h.id == e.host and h.get("needs", []).is_empty() and h.get("start", "on") == "on")))
	if bolted.is_empty():
		job.faults.append("tire")
		job.found["tire"] = true  # added after the walk-around: as if you'd spotted it
		bolted = ["tire"]
	var id0: String = bolted[0]
	g.tools.clear()
	g._repair(id0)
	ok = ok and g.panel is Work
	_chk(ok, 120)
	await _snap(shot, "work_" + id0)
	ok = ok and not g.panel.solve() and not job.fixed.has(id0)
	_chk(ok, 122)
	for t in Work.TOOLS:
		if t != "hand":
			g.tools[t] = true
	# Mouse path: hover the first screw/bolt, hold the button with its tool, let go.
	# Fed to the scene directly so the real cursor (windowed runs) can't interfere.
	var w = g.panel
	var f0: Dictionary = w.els.filter(func(e): return e.type == "fastener" and w.action(e).verb == "loosen")[0]
	w.tool = f0.tool
	var mv = InputEventMouseMotion.new()
	mv.position = w._to_screen(f0.pos)
	w._gui_input(mv)
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = mv.position
	press.pressed = true
	w._gui_input(press)
	for _i in 10:  # 1 s of holding, stepped by hand: no real cursor or frame timing can interfere
		w._gui_input(mv)
		w._process(0.1)
	var release: InputEventMouseButton = press.duplicate()
	release.pressed = false
	w._gui_input(release)
	ok = ok and w.st[f0.id] == "loose"
	_chk(ok, 145)
	if w.st[f0.id] != "loose":
		print("MOUSE HOLD did not loosen ", f0.id, ": ", w.st[f0.id], " hover=", w.hover, " hold=", w.hold, " pressing=", w.pressing, " held_done=", w.held_done, " tool=", w.tool, " action=", w.action(f0))
	if g.FAULTS[id0].part != "":
		g.inventory.erase(g.FAULTS[id0].part)
		ok = ok and not g.panel.solve() and not job.fixed.has(id0)
		_chk(ok, 150)
		await _snap(shot, "work_apart")
	# Out of a material (here cotter pins / safety wire / penetrant): the job stalls at that step.
	var uses_any: bool = g.panel.els.any(func(e): return e.get("uses", "") != "")
	if uses_any:
		if g.FAULTS[id0].part != "":
			g.inventory[g.FAULTS[id0].part] = 1
		for mtl in g.SUPPLIES:
			if g.SUPPLIES[mtl].has("qty"):
				g.inventory[mtl] = 0
		ok = ok and not g.panel.solve() and not job.fixed.has(id0)
		_chk(ok, 159)
	for mtl in g.SUPPLIES:
		if g.SUPPLIES[mtl].has("qty"):
			g.inventory[mtl] = 99
	g._close_panel()
	# Fix what's found, run it up to hear more, troubleshoot what it tells you, repeat.
	for _round in 4:
		for id in job.faults.duplicate():
			if not job.found.has(id) or job.fixed.has(id):
				continue
			var part: String = g.FAULTS[id].part
			if part != "":
				g.inventory[part] = 1
			g._repair(id)
			await _snap(shot, "work_" + id, 0.1)
			var solved: bool = g.panel.solve()
			if g.FAULTS[id].get("quiz", false):
				solved = solved and _answer_quiz(id)
			ok = ok and solved and job.fixed.has(id)
			_chk(ok, 178)
			if not solved:
				print("WORK STUCK on ", id)
		_run_up()
		for id in job.faults:
			while g._test_for(job, id) != "" and job.sym.has(id):
				var diag_ok: bool = _troubleshoot(id)
				ok = ok and diag_ok
				_chk(ok, 186)
				if not diag_ok:
					print("TROUBLESHOOTING STUCK on ", id, " at ", g._test_for(job, id))
					break
	g._close_panel()
	if not (job.runup == "ran" and job.fixed.size() == job.faults.size()):
		print("NOT DONE: runup=", job.get("runup"), " fixed=", job.fixed.keys(), " faults=", job.faults, " found=", job.found.keys())
	ok = ok and job.runup == "ran" and job.fixed.size() == job.faults.size()
	_chk(ok, 193)
	g._start_runup()  # everything fixed: in the cockpit, 2,100 rpm, each mag, and it runs clean
	var rf = g.ferry
	var runup_ok: bool = rf != null and rf.mode == "runup" and rf.no_start == ""
	if rf:
		rf.state = "run"
		rf.throttle = (rf.RUNUP_RPM - 650.0) / 1700.0
		var calls_ok := true
		for step in [[1, false], [2, false], [3, true], [3, false]]:
			rf.mags = step[0]
			rf.carb_heat = step[1]
			rf._mag_t = 0.0
			for i in 120:
				rf._process(1.0 / 60.0)
			if step[0] == 1 and not step[1]:  # judge the left mag: a wrong call first, then the right one
				await _snap(shot, "runup_call", 0.2)
				calls_ok = await _top_bands_ok("cockpit") and calls_ok
				calls_ok = calls_ok and Ferry.mag_reason(0).ends_with("Bad.") and Ferry.mag_reason(Ferry.MAG_LIMIT + 1).ends_with("Bad.") \
					and Ferry.mag_reason(Ferry.MAG_LIMIT).ends_with("Good.") and Ferry.mag_reason(1).ends_with("Good.")
				var m0: int = g.money  # a wrong call costs a small charge, not time (D2)
				calls_ok = calls_ok and not rf._aid_mag  # no mistake yet, no aid
				rf.call_mag(false)  # a fixed plane's mag is good: "bad" is wrong
				calls_ok = calls_ok and rf._aid_mag and String(rf.card().foot).begins_with("Good:")  # E4: the rule on the card
				var wrong_ok: bool = rf._calls[0] == -1 and g.money == m0 - mini(m0, g.WRONG_GUESS) and g._log_list.get_children().any(func(l): return l.text.begins_with("Not quite. Left mag"))
				calls_ok = calls_ok and wrong_ok
				rf.call_mag(true)
				calls_ok = calls_ok and rf._calls[0] == 1
		# Every reading taken, back on BOTH, but the right mag not called yet: it mustn't finish.
		for i in 200:
			rf._process(1.0 / 60.0)
		calls_ok = calls_ok and g.ferry != null and rf._done_t < 0.0
		rf.call_mag(true)
		calls_ok = calls_ok and rf._calls[1] == 1
		if not calls_ok:
			print("MAG CALLS: a wrong call should be explained and cost time, right calls should finish the run-up")
		runup_ok = runup_ok and calls_ok and rf._seen == [rf.drops.x, rf.drops.y, rf.carb_drop] and rf.drops.x <= 75 and rf.drops.y <= 75 and rf.drops.y > 0 and rf.carb_drop > 0
		for i in 200:
			if g.ferry == null:
				break
			rf._process(1.0 / 60.0)
	ok = ok and runup_ok and g.ferry == null and job.runup == "ran"
	if not runup_ok:
		print("RUN-UP FAILED")
	# Hangar: push it in (it moves inside, nose to the door), the truck refuses to fuel it
	# indoors, then roll it back out.
	g._move_plane("hangar")
	ok = ok and g.plane.position.distance_to(g.HANGAR_SPOT) < 0.5 and g._fuel_plane() == 0
	_chk(ok, 198)
	if shot != "":
		g.player.position = g.HANGAR_SPOT + Vector3(6, 0.1, 9)
		g.player.look_at(g.HANGAR_SPOT + Vector3(0, 0.1, 0), Vector3.UP)
		g.player.cam.rotation.x = -0.1
		g._close_panel()
		await _snap(shot, "in_hangar")
	g._move_plane("apron")
	ok = ok and g.plane.position.distance_to(Vector3(0, 0, 8)) < 0.5
	if shot != "":  # the logo in the world: painted on the hangar wall, stuck on the toolbox
		g._close_panel()
		g.player.position = Vector3(-16, 0.1, -12)
		g.player.look_at(Vector3(-16, 0.1, -21), Vector3.UP)
		g.player.cam.rotation.x = 0.3
		await _snap(shot, "ghost_sign")
		g.player.position = Vector3(-18.6, 0.1, -20.4)
		g.player.look_at(Vector3(-20, 0.1, -20.4), Vector3.UP)
		g.player.cam.rotation.x = -0.45
		await _snap(shot, "toolbox_decal")
		g.player.position = Vector3(-13, 0.1, -17.4)
		g.player.look_at(Vector3(-13, 0.1, -21), Vector3.UP)
		g.player.cam.rotation.x = -0.45
		await _snap(shot, "workbench")
	_chk(ok, 206)
	# Fuel truck: low tanks block the take-off until it's fueled.
	job.fuel = 0.1
	var fuel_cost: int = g._fuel_plane()
	ok = ok and fuel_cost > 0 and job.fuel == 1.0
	_chk(ok, 210)
	start -= fuel_cost
	if shot != "":
		g._open_truck()
		await _snap(shot, "fuel_truck_panel")
		g.inventory["Brake shoe set"] = 1
		g._refresh_parts_table()
		g._close_panel()
		g.player.position = Vector3(-6.5, 0.1, 7.5)
		g.player.look_at(Vector3(-6.5, 0.1, 4.0), Vector3.UP)
		g.player.cam.rotation.x = -0.45
		await _snap(shot, "parts_table")
	await _snap(shot, "airworthy")
	g._close_panel()
	await _snap(shot, "fixed")
	if shot != "":  # extra viewpoints of the hangar and the parts shed
		for v in [["hangar_out", Vector3(-10, 0.1, 4), Vector3(-16, 0, -14)], ["hangar", Vector3(-14, 0.1, -12), Vector3(-19, 0, -20)],
				["drums", Vector3(-3.5, 0.1, -13), Vector3(-7.5, 0, -17)], ["shed", Vector3(18, 0.1, -1), Vector3(14, 0, -8)],
				["truck", Vector3(-1, 0.1, 4), Vector3(-8, 0, -1)], ["windsock", Vector3(26, 0.1, 25), Vector3(33, 0, 30)],
				["apron", Vector3(6, 0.1, -1), Vector3(-2, 0, 12)],				["trees", Vector3(-20, 0.1, -25), Vector3(-60, 0, -60)],
			["vista_n", Vector3(0, 0.1, -28), Vector3(0, 0, -300)], ["vista_e", Vector3(100, 0.1, 25), Vector3(400, 0, 60)],
			["vista_w", Vector3(-100, 0.1, 10), Vector3(-400, 0, -40)]]:
			g.player.position = v[1]
			g.player.look_at(Vector3(v[2].x, g.player.position.y, v[2].z), Vector3.UP)
			g.player.cam.rotation.x = 0.02 if v[0].begins_with("vista") else (0.35 if v[0] == "windsock" else -0.35)
			if v[0] == "vista_n":
				await get_tree().create_timer(2.0).timeout
				print("FPS at vista: ", Engine.get_frames_per_second())
				print("frame: %d draw calls, %d objects, %d k triangles, %.1f ms GPU" % [RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
					RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
					RenderingServer.get_frame_setup_time_cpu()])
				var load_t := Time.get_ticks_msec()
				g._load_field(g.location, g.current_job)
				print("field load: %d ms" % (Time.get_ticks_msec() - load_t))
			await _snap(shot, v[0])
		if g.flock:  # look up at the birds
			var bird: Vector3 = g.flock.get_child(0).global_position
			g.player.position = Vector3(bird.x + 25, 0.1, bird.z + 25)
			g.player.look_at(Vector3(bird.x, g.player.position.y, bird.z), Vector3.UP)
			g.player.cam.rotation.x = atan2(bird.y - 1.7, Vector2(25, 25).length())
			await _snap(shot, "birds")
		if g.terrain.pond != Vector3.INF:
			var pd: Vector3 = g.terrain.pond
			g.player.position = Vector3(pd.x + pd.z + 6, g.terrain.height(pd.x + pd.z + 6, pd.y) + 0.2, pd.y)
			g.player.look_at(Vector3(pd.x, g.player.position.y, pd.y), Vector3.UP)
			g.player.cam.rotation.x = -0.2
			await _snap(shot, "pond")
		var trees = g.world.get_children().filter(func(n): return n.has_meta("tree"))
		for i in mini(3, trees.size()):  # close-ups to check the bark/leaf split
			var spot: Vector3 = trees[i].position
			g.player.position = Vector3(spot.x + 9, g.terrain.height(spot.x + 9, spot.z + 9) + 0.2, spot.z + 9)
			g.player.look_at(Vector3(spot.x, g.player.position.y, spot.z), Vector3.UP)
			g.player.cam.rotation.x = 0.15
			await _snap(shot, "tree%d" % i)
		g._load_field(g.location, job)  # put the player back by the plane
	ok = ok and job.fixed.size() == job.faults.size()
	_chk(ok, 259)
	# Fly it out for real: hold throttle, pull back once past rotate speed.
	g._start_ferry()
	ok = ok and g.ferry == null  # an unsigned logbook keeps it on the ground
	ok = await _sign_off_ok(job, shot) and ok
	# Pause really stops the world, and resuming leaves nothing paused behind.
	g._close_panel()
	g._open_pause()
	await _snap(shot, "pause")
	ok = ok and get_tree().paused and g.panel != null
	g._open_settings(g._open_pause)
	await _snap(shot, "settings")
	ok = ok and get_tree().paused
	g._sub_back.call()
	g._close_panel()
	ok = ok and not get_tree().paused and g.panel == null
	g._start_ferry()
	await _snap(shot, "checklist", 0.3)
	_shot = shot
	ok = await _start_failures() and ok
	await _snap(shot, "engine_log", 0.1)
	var before_fly: int = g.money  # the pay lands on top, less the job's hangar fee (D2)
	await _fly(true, shot)
	# The debrief (E5): up after the delivery, with the wrong mag call this test made and advice.
	var deb: Dictionary = g.logbook[-1].get("debrief", {}) if g.logbook.size() > 0 else {}
	var deb_ok: bool = g._list_title == "Debrief" and not deb.is_empty() and deb.next != "" \
		and Array(deb.extra).any(func(x): return x.begins_with("Left mag called bad"))
	if not deb_ok:
		print("DEBRIEF: missing, or without the wrong mag call: ", deb)
	ok = ok and deb_ok
	ok = _debrief_no_time(deb) and ok
	await _snap(shot, "debrief", 0.3)
	ok = await _mission_card_ok(deb) and ok
	ok = _no_days_ok() and ok
	ok = _logbook_ok() and ok
	ok = await _top_bands_ok("pause") and ok
	ok = await _top_bands_ok("notes") and ok
	ok = await _notes_pages_ok(shot) and ok
	# Badges (B1): one delivery earns none of the run badges, but moves their runs. This run checked
	# every spot and nothing came back (Nothing Gets Past You: 1 of 5); it called a mag wrong, so the
	# ticket had extras (Clean Sheet stays 0). Only Barn Find can come in one job, on a 10-year plane.
	var barn: bool = int(g.logbook[-1].get("years", 0)) >= g.BADGE_BARN_YEARS
	var bad: Array = g.badges.keys().filter(func(b): return b != "barn_find" or not barn)
	var runs_ok: bool = int(g.streaks.get("walkround", 0)) == 1 and int(g.streaks.get("clean_sheet", 0)) == 0 \
		and g.badges.has("barn_find") == barn
	print("badges after one delivery: runs %s (walk-around %s, clean sheet %s), earned %s" % [runs_ok, g.streaks.get("walkround", 0), g.streaks.get("clean_sheet", 0), g.badges.keys()])
	if not bad.is_empty() or not runs_ok:
		print("BADGES: earned without the skill ", bad, " or runs off: ", g.streaks)
		ok = false
	ok = _badge_rules_ok() and ok
	g._pocket("logbook")
	await _snap(shot, "badges", 0.3)
	g._close_panel()
	# The tracker (P13): in the world it shows every badge, coloured if earned, greyed if not;
	# over a sheet it's hidden.
	await get_tree().process_frame
	g._update_hud()  # read the HUD as it is now, not as the last frame left it (screenshot runs lag a frame)
	var row: HBoxContainer = g.tracker
	var tracker_ok: bool = row.get_parent().visible and row.get_child_count() == g.BADGES.size()
	for t: TextureRect in row.get_children():
		var want := "badge.svg" if g.badges.has(String(t.name)) else "badge_none.svg"
		tracker_ok = tracker_ok and t.texture.resource_path.ends_with(want)
	await _snap(shot, "tracker", 0.3)
	g._pocket("logbook")
	await get_tree().process_frame
	g._update_hud()
	tracker_ok = tracker_ok and not row.get_parent().visible
	g._close_panel()
	if not tracker_ok:
		print("TRACKER: wrong icons, or shown over a sheet")
	ok = ok and tracker_ok
	# Job status (P19): the record earns the rank; short of it, held back; the raise lands on new
	# calls; no annual below IA. All on a copy of the career, put back after.
	var keep_career := [g.logbook.duplicate(true), g.rescued, g.badges.duplicate(), g.rank, g.jobs.duplicate(true), g.tut.duplicate(true)]
	g.tut.lesson = 0
	var clean_e := {"work": ["Fix"], "debrief": {"extra": []}}
	var messy_e := {"work": ["Fix"], "debrief": {"extra": ["Left mag called bad"]}}
	g.logbook = [clean_e, clean_e, clean_e, messy_e, messy_e]
	g.rescued = 5
	g.badges = {}
	var ladder_ok: bool = g.earned_rank() == "lead"
	g.logbook = [clean_e, clean_e, messy_e, messy_e, messy_e]  # only two clean: held back
	ladder_ok = ladder_ok and g.earned_rank() == "ap"
	g.logbook = [clean_e, clean_e, clean_e, messy_e, {"work": ["Comeback: Flat main tire"], "debrief": {"extra": []}}]
	ladder_ok = ladder_ok and g.earned_rank() == "ap"  # a comeback in the last three: held back
	g.logbook = [clean_e, clean_e, clean_e, clean_e, clean_e, clean_e, clean_e, clean_e]
	g.rescued = 8
	for b in g.BADGES.slice(0, 6):
		g.badges[b[0]] = 1
	ladder_ok = ladder_ok and g.earned_rank() == "ia"
	# The raise: the same call spawned at A&P and at Lead pays 10% more (to the nearest $50).
	g.rescued = 5
	var pays := []
	for rk in ["ap", "lead"]:
		g.rank = rk
		g.jobs = []
		g.rng.seed = 4242
		seed(4242)  # spawning also shuffles with the global generator
		g._spawn_job()
		pays.append(g.jobs[0].reward)
	ladder_ok = ladder_ok and absf(pays[1] - pays[0] * 1.10) <= 50.0 and pays[1] > pays[0]
	seed(g.test_seed + 1)  # hand the global generator back to this run's seed
	# The economy (P7): a harder call pays more than an easy one; an easy call pays less later in a
	# career than early; never below the floor; a lesson's call is never discounted.
	g.rank = "ap"
	g.rescued = 0
	var econ_ok: bool = g._pay_for(2000, 3, false) > g._pay_for(2000, 1, false)
	var early: int = g._pay_for(2000, 1, false)
	g.rescued = 8
	var late: int = g._pay_for(2000, 1, false)
	econ_ok = econ_ok and late < early and late >= int(early * g.ECONOMY.floor) - 50 and g._pay_for(2000, 1, true) == early
	# Form (P4): from a strong record the next calls run harder than from a weak one, same seeds.
	var strong_e := {"work": ["Fix"], "debrief": {"extra": []}}
	var weak_e := {"work": ["Fix"], "debrief": {"extra": ["Comeback: flat main tire", "Left mag called bad", "Gasket kit by mail"]}}
	var mean := {}
	g.rescued = 3
	g.rank = "ap"
	for which in ["strong", "weak"]:
		var e: Dictionary = strong_e if which == "strong" else weak_e
		g.logbook = [e, e, e]
		var total := 0
		g.rng.seed = 777
		seed(777)
		for i in 80:
			g.jobs = []
			g._spawn_job()
			total += g.call_difficulty(g.jobs[0])
		mean[which] = total / 80.0
	print("form: next calls' mean rating after strong work %.2f, after a struggle %.2f" % [mean.strong, mean.weak])
	var form_ok: bool = mean.strong > mean.weak and g.form_line().contains("steadier")
	g.logbook = [strong_e, strong_e, strong_e]
	form_ok = form_ok and g.performance_form() == 3 and g.form_line().contains("tougher")
	g.logbook = []
	form_ok = form_ok and g.performance_form() == 0
	seed(g.test_seed + 2)
	if not form_ok:
		ladder_ok = false
		print("FORM: mean rating strong ", mean.get("strong"), " weak ", mean.get("weak"), "; lines or values wrong")
	if not econ_ok:
		ladder_ok = false
		print("ECONOMY: early ", early, " late ", late, " hard ", g._pay_for(2000, 3, false))
	# Annuals need an IA.
	var annuals := 0
	g.rank = "lead"
	for i in 150:
		g.jobs = []
		g._spawn_job()
		annuals += 1 if g.jobs[0].annual else 0
	ladder_ok = ladder_ok and annuals == 0
	if not ladder_ok:
		print("LADDER: ranks or raise or annuals wrong; pays=", pays, " annuals below IA=", annuals)
	g.logbook = keep_career[0]
	g.rescued = keep_career[1]
	g.badges = keep_career[2]
	g.rank = keep_career[3]
	g.jobs = keep_career[4]
	g.tut = keep_career[5]
	g._pocket("logbook")
	await _snap(shot, "rank", 0.3)
	g._close_panel()
	ok = ok and ladder_ok
	var bonus: int = g.tutorial.REWARDS[lesson].cash if lesson > 0 else 0  # a lesson pays a bonus on delivery
	ok = ok and g.ferry == null and g.rescued == 1 and g.money == before_fly + job.reward + bonus + roundi(job.get("supplies", {}).get("billed", 0.0)) - g.HANGAR_FEE \
		and g.money < start + job.reward + bonus + roundi(job.get("supplies", {}).get("billed", 0.0)) and g.jobs.size() == g.MAX_JOBS
	# The ending and game-over screens both leave a way out and can't be closed by accident.
	var rescued_now = g.rescued
	g.rescued = g.GOAL
	g._after_flight()
	await _snap(shot, "ending")
	ok = ok and g.panel != null and not g.panel_closable
	ok = await _ending_ok() and ok
	g.rescued = rescued_now
	g._open_game_over(500)
	var was := [g.money, g.jobs.duplicate(true)]
	g._odd_jobs()  # broke is a setback: odd jobs pay for the next flight, and no time passes (D2)
	ok = ok and g.money == was[0] + g.ODD_JOB_PAY and g.panel == null and g.jobs.size() == was[1].size()
	g.money = was[0]
	g.jobs = was[1]
	g._open_game_over(500)
	await _snap(shot, "game_over")
	ok = ok and g.panel != null and not g.panel_closable
	g._open_travel()
	# A lesson's sign-off card opens on the map (Thad), not over the ticket.
	await get_tree().process_frame
	await get_tree().process_frame
	var reward_on_map: bool = is_instance_valid(g.tutorial._reward)
	if reward_on_map:
		await _snap(shot, "lesson_on_map", 0.4)
	_chk(ok, 275)
	ok = ok and g.logbook.size() == 1 and g.logbook[0].has("parts")  # the cost sheet was written
	_chk(ok, 276)
	if shot != "":
		g._pocket("logbook")
		await _snap(shot, "logbook_after")
	if lesson > 0:  # the lesson's job is delivered: every step ticked, it paid out and the next began
		var want: Array = lesson_steps.filter(func(id): return id != "tour")
		var missing: Array = want.filter(func(id): return not id in g.tut.get("last", []))
		if not missing.is_empty() or int(g.tut.get("lesson", -1)) != (lesson + 1 if lesson < 3 else 0) \
				or int(g.logbook[-1].get("debrief", {}).get("bonus", 0)) != int(g.tutorial.REWARDS[lesson].cash) \
				or int(g.tut.get("reward", 0)) != lesson or not reward_on_map:
			# The bonus is paid on the ticket (D3); the sign-off card waits for the map and opens there.
			print("TUTORIAL lesson %d: unticked %s, now lesson %s, bonus %s, reward %s, card on the map %s" % [lesson, missing,
				g.tut.get("lesson"), g.logbook[-1].get("debrief", {}).get("bonus"), g.tut.get("reward"), reward_on_map])
			ok = false
		var want_next: Array = ["tire"] if lesson == 1 else ["stuck_valve"]
		var lesson_calls: Array = g.jobs.filter(func(jj): return jj.get("lesson", false))
		if lesson < 3 and (lesson_calls.size() != 1 or lesson_calls[0].faults != want_next or g.call_locked(lesson_calls[0]) \
				or not g.jobs.filter(func(jj): return not jj.get("lesson", false)).all(func(jj): return g.call_locked(jj))):
			print("TUTORIAL: the map should have one open call for the next lesson, the rest locked")
			ok = false
		if lesson == 3 and g.jobs.any(func(jj): return g.call_locked(jj)):
			print("TUTORIAL: after the apprenticeship no call should be locked")
			ok = false
	print("SELF-TEST ", "PASS" if ok and edges_ok and scenes_ok else "FAIL", " edges=", edges_ok, " scenes=", scenes_ok, " city=", job.city, " seed=", g.test_seed, " faults=", job.faults)
	get_tree().quit(0 if ok and edges_ok and scenes_ok else 1)


var overflow := ""


## Opens and closes every sheet 500 times: nodes must come back to where they started.
func _leak_test() -> bool:
	g._close_panel()
	await get_tree().process_frame
	await get_tree().process_frame
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC)
	var opens: Array[Callable] = [g._open_logbook, g._open_shop, g._open_toolbox, g._open_travel, g._open_pause]
	for i in 500:
		opens[i % opens.size()].call()
		await get_tree().process_frame
		g._close_panel()
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var grew = Performance.get_monitor(Performance.OBJECT_NODE_COUNT) - nodes
	print("leak test: %d nodes, %.1f MB after 500 opens" % [grew, (Performance.get_monitor(Performance.MEMORY_STATIC) - mem) / 1048576.0])
	return grew <= 5


## Every field's terrain is different: a good pilot must be able to put it down at all of them.
func _all_fields() -> bool:
	Engine.time_scale = 3.0  # twenty flights in a couple of minutes
	var ok := true
	for city in g.CITIES:
		var j: Dictionary = g.jobs[0]
		j.merge({"faults": ["oil_leak"], "fixed": {}, "found": {}, "checked": {}, "work": {}, "runup": "ran", "fuel": 1.0, "washed": true,
			"signed": true, "parked": "apron", "reward": 4000}, true)
		g._load_field(city, j)
		await _fly(true)
		var landed: bool = g.ferry == null and g.current_job == j and j.found.has("oil_leak")
		g._close_panel()
		# And nothing wrong at all: a clean take-off has to clear the land around every strip.
		j = g.jobs[0]
		j.merge({"faults": [], "fixed": {}, "found": {}, "checked": {}, "work": {}, "runup": "ran", "fuel": 1.0, "washed": true,
			"signed": true, "parked": "apron", "reward": 4000}, true)
		g.rescued = 0
		g._load_field(city, j)
		await _fly(false)
		var delivered: bool = g.ferry == null and g.rescued == 1
		print("field ", city, ": ", "landed" if landed else "CRASHED", ", ", "climbed out" if delivered else "NEVER CLEARED")
		ok = ok and landed and delivered
		g._close_panel()
	Engine.time_scale = 1.0
	return ok


## Flies with a fault nobody looked for, for real: once flown well, once not flown at all.
func _trouble_tests(shot: String) -> bool:
	g._close_panel()
	var j: Dictionary = g.jobs[0]
	j.merge({"faults": ["oil_leak"], "fixed": {}, "found": {}, "checked": {}, "work": {}, "runup": "ran", "fuel": 1.0, "washed": true,
		"signed": true, "parked": "apron", "reward": 4000}, true)
	g._load_field(g.location, j)
	g._open_inspection("cabin")
	var ok: bool = g.panel != null  # nothing found, run-up done: signing is open even with spots unchecked
	g._close_panel()
	g._start_ferry()  # second thoughts: you can always climb back out
	g._open_pause()
	await get_tree().process_frame
	g._leave_cockpit()
	await get_tree().process_frame
	ok = ok and g.ferry == null and g.panel == null and not get_tree().paused and g.plane != null and g.current_job == j
	await _fly(true)
	ok = ok and g.ferry == null and g.current_job == j and j.found.has("oil_leak") and not j.signed and j.reward == 3000 and g.panel != null
	await _snap(shot, "forced_landing")
	g._close_panel()
	var money = g.money
	var rescued = g.rescued
	j.signed = true
	await _fly(false)
	ok = ok and g.ferry == null and g.current_job == null and not g.jobs.has(j) and g.jobs.size() == g.MAX_JOBS
	ok = ok and g.money == maxi(0, money - g.CRASH_BILL) and g.rescued == rescued and g.panel != null
	await _snap(shot, "crash")
	g._close_panel()
	# A tire goes on the runway, before there's anything to land.
	var k: Dictionary = g.jobs[0]
	k.merge({"faults": ["tire"], "fixed": {}, "found": {}, "checked": {}, "work": {}, "runup": "ran", "fuel": 1.0, "washed": true,
		"signed": true, "parked": "apron", "reward": 4000}, true)
	g._load_field(g.location, k)
	await _fly(false)
	ok = ok and g.ferry == null and g.current_job == k and k.found.has("tire") and not k.signed
	ok = ok and not _quit_open
	# Fault-free, but held low into rising ground: that's a crash, not a pass through the hill.
	g._close_panel()
	k.fixed["tire"] = true
	k.signed = true
	g._start_ferry()
	await _good_start(g.ferry)
	var hit = g.ferry
	hit.plane.position.x = -800.0
	hit.alt = 2.0
	hit.speed = 35.0
	hit.trouble = "oil_leak"  # not struck yet: the hill still takes the blame
	var gt := 0.0  # game seconds, not the wall clock: see _crank
	while g.ferry and gt < 6.0:
		await get_tree().process_frame
		gt += get_process_delta_time()
	ok = ok and g.ferry == null and g.current_job == null and not g.jobs.has(k) and g.logbook.back().work[0].contains("rising ground")
	g._close_panel()
	print("trouble tests ", ok)
	return ok


## Every way the start can go wrong, for real, then none of them.
var _shot := ""  # the --shot prefix, for helpers that snap mid-way
var _looped := false  # the ground-loop aid test runs once


func _start_failures() -> bool:
	var f = g.ferry
	await _crank(2.2)
	var ok: bool = f.state == "off"  # master off: dead silence
	ok = ok and g._log.visible and g._log_list.get_children().any(func(l): return l.text.contains("master switch"))
	f.toggle_master()
	await _crank(2.2)
	ok = ok and f.state == "off"  # no fuel
	f.toggle_fuel()
	await _crank(2.2)
	ok = ok and f.state == "off"  # mags off, and nothing primed yet makes no difference without spark
	for i in 3:
		f.next_mags()
	for i in 7:
		f.prime()
	f.throttle = 0.1
	await _crank(2.2)
	ok = ok and f.state == "off" and f.flood > 0.0  # flooded
	ok = ok and String(f.card().alert).begins_with("Flooded")  # and the checklist says how to clear it
	await _snap(_shot, "checklist_flooded", 0.2)  # the real flooded start, with its fix on the card
	ok = await _cockpit_card_ok("flooded start") and ok
	f.throttle = 1.0
	await _crank(3.3)
	ok = ok and f.flood <= 0.0  # cleared with the throttle open
	f.primes = 0
	f.throttle = 0.1
	await _crank(2.2)
	ok = ok and f.state == "hung"  # no prime: hung start
	ok = ok and String(f.card().alert).begins_with("Hung")
	var gt := 0.0
	while f.state == "hung" and gt < 7.0:
		await get_tree().process_frame
		gt += get_process_delta_time()
	ok = ok and f.state == "off"  # left alone, it dies
	f.primes = 1
	await _crank(2.2)
	f.throttle = 0.2
	gt = 0.0
	while f.state == "hung" and gt < 3.0:
		await get_tree().process_frame
		gt += get_process_delta_time()
	ok = ok and f.state == "run"  # a touch of throttle saves it
	ok = ok and f.card().title == "TAKE-OFF" and f.card().alert == ""
	ok = await _cockpit_card_ok("take-off") and ok
	print("start failures ", ok)
	return ok


func _crank(seconds: float) -> void:
	g.ferry._crank_total = 0.0  # the starter-rest limit has its own check below
	g.ferry._cool = 0.0
	Input.action_press("starter")
	# Held for game time, not wall time: the engine counts cranking frame by frame, and under a
	# slow display (screenshot runs) game time falls behind the clock, so a wall-clock hold let go
	# before it could catch. A player holds until it fires; this holds as long as the game needs.
	var gt := 0.0
	while gt < seconds and g.ferry.state == "off":
		await get_tree().process_frame
		gt += get_process_delta_time()
	Input.action_release("starter")
	await get_tree().process_frame


## Starts it by the book.
func _good_start(f) -> void:
	f.toggle_master()
	f.toggle_fuel()
	for i in 3:
		f.prime()
		f.next_mags()
	f.throttle = 0.15
	await _crank(2.2)


## Flies the take-off and, once trouble strikes, either the forced landing or nothing at all.
func _fly(well: bool, shot := "") -> void:
	if g.ferry == null:
		g._start_ferry()
		await _good_start(g.ferry)
	var t0 = Time.get_ticks_msec()
	var worst := 0.0
	var frames := 0
	var last = Time.get_ticks_usec()
	Input.action_press("throttle_up")
	var flown := {}
	var climbed := false
	if well and g.ferry and g.ferry.state == "run" and g.ferry.mode == "fly" and not _looped:
		_looped = true  # E4: one ground loop, on purpose; the straight-line cue shows on the next roll
		var lf = g.ferry
		var aid_ok: bool = not lf._aid_rudder
		lf.z_off = 17.0
		lf._fly(1.0 / 60.0)
		lf.speed = 8.0
		lf._fly(1.0 / 60.0)
		aid_ok = aid_ok and lf._aid_rudder and String(g.prompt.text).contains("STRAIGHT")
		lf._line_up()
		if not aid_ok:
			print("AID rudder: no straight-line cue after a ground loop")
			_chk(false, 3)
	var flight_t := 0.0  # game seconds
	while g.ferry and flight_t < 40.0:
		flight_t += get_process_delta_time()
		var f = g.ferry
		if f.state == "run" and f.mode == "fly" and not f.struck:
			f.card()  # the take-off checklist ticks its stages as they're passed
			flown = f._flown.duplicate()
			climbed = climbed or f.alt >= Ferry.DONE_ALT * 0.5
		worst = maxf(worst, (Time.get_ticks_usec() - last) / 1000.0)
		last = Time.get_ticks_usec()
		frames += 1
		Input.action_release("rudder_left")
		Input.action_release("rudder_right")
		if f.struck:
			_quit_open = _quit_open or g._can_quit()
			Input.action_release("throttle_up")
			Input.action_release("stick_forward")
			Input.action_release("stick_back")
			if well:
				if f.alt - maxf(0.0, g.terrain.height(f.plane.position.x, f.plane.position.z)) < 4.0 and f.speed > Ferry.STALL + 3.0:  # flare, but never below flying speed: ground can rise past the strip
					Input.action_press("stick_back")
				elif f.pitch > -0.1:
					Input.action_press("stick_forward")
		else:
			if f.yaw + f.z_off * 0.05 > 0.0:  # hold the centerline
				Input.action_press("rudder_right")
			else:
				Input.action_press("rudder_left")
			if f.speed >= Ferry.ROTATE:
				Input.action_press("stick_back")
			if shot != "" and f.speed > 12.0 and not FileAccess.file_exists(shot + "_roll.png"):
				await _snap(shot, "roll", 0.0)
			if shot != "" and f.alt > 8 and not FileAccess.file_exists(shot + "_climb.png"):
				await _snap(shot, "climb", 0.0)
		await get_tree().process_frame
	for a in ["throttle_up", "stick_forward", "stick_back", "rudder_left", "rudder_right"]:
		Input.action_release(a)
	if well:
		print("take-off checklist: ", flown.keys(), " climbed=", climbed)
	if well and climbed and flown.size() != 5:
		print("TAKE-OFF CHECKLIST: only ", flown.keys(), " ticked on a good take-off")
		_chk(false, 2)
	print("flight at %s: %.0f fps, worst frame %.0f ms" % [g.location, frames * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0), worst])


## Money and deadline edges, run at home before the main test; restores what it touches.
func _edge_tests() -> bool:
	var saved = [g.money, g.jobs, g.current_job]
	var fake = func(id: String) -> Dictionary:
		return {"city": g.location, "type": "Test", "faults": [id], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0}
	# 0. Update version compare: numeric per part, missing parts are 0.
	var ok: bool = Updater.newer("1.10.0", "1.9.3") and Updater.newer("0.9.1", "0.9") \
		and not Updater.newer("0.9.0", "0.9.0") and not Updater.newer("0.8.9", "0.9.0")
	# 0b. Release check: offers a newer release's setup from this repo; ignores older ones and
	#     anything not hosted on the repo's own release downloads.
	var up = Updater.new()
	add_child(up)
	var offered = []
	up.available.connect(func(v, _n): offered.append(v))
	var release = func(tag: String, url: String) -> PackedByteArray:
		return JSON.stringify({"tag_name": tag, "body": "", "assets": [{"name": url.get_file(), "browser_download_url": url}]}).to_utf8_buffer()
	var good: String = Updater.ASSET_PREFIX + "v9.9.9/AirplaneRescue-9.9.9-setup.exe"
	up._on_latest(HTTPRequest.RESULT_SUCCESS, 200, [], release.call("v9.9.9", good))
	up._on_latest(HTTPRequest.RESULT_SUCCESS, 200, [], release.call("v0.0.1", good.replace("9.9.9", "0.0.1")))
	up._on_latest(HTTPRequest.RESULT_SUCCESS, 200, [], release.call("v9.9.9", "https://evil.example/AirplaneRescue-9.9.9-setup.exe"))
	up._on_latest(HTTPRequest.RESULT_SUCCESS, 404, [], PackedByteArray())
	ok = ok and offered == ["9.9.9"] and up.setup_url == good
	up.queue_free()
	# 1. Broke, no flight, the needed part is mail-order only: shelf price is affordable but the
	#    real price isn't, so it must be game over rather than a dead end.
	var mail_only = g.FAULTS.keys().filter(func(id): return g.FAULTS[id].part != "" and not g._stocked(id))
	if mail_only.size() > 0:
		var id: String = mail_only[0]
		g.jobs = []
		g.current_job = fake.call(id)
		g.money = g.FAULTS[id].cost
		g._open_travel()
		ok = ok and g.panel != null and not g.panel_closable  # the game-over panel can't be closed
		g._close_panel()
	# 1b. Part in hand but no ratchet and no money: the tool blocks the repair, so it's game
	#     over, not a dead end. With every tool and enough wire it's finishable.
	var saved_tools = g.tools
	var saved_inv = g.inventory
	g.jobs = []
	g.current_job = fake.call("propeller")
	g.inventory = {"Propeller": 1}
	g.tools = g.STARTER_TOOLS.duplicate()
	g.money = 0
	ok = ok and not g._can_finish_here()
	g.tools = {"screwdriver": true, "rag": true, "ratchet": true, "torque": true, "pliers": true}
	g.inventory = {"Propeller": 1, "Safety wire": 10}
	g.current_job.fuel = 1.0
	ok = ok and g._can_finish_here()
	# Everything fixed but the tanks are dry and the pump costs more than you have: not finishable.
	g.current_job.fuel = 0.03
	ok = ok and not g._can_finish_here()
	g.money = g._fuel_bill(g.current_job)
	ok = ok and g._can_finish_here()
	g.money = 0
	for key in g.SUPPLIES:  # off the shelf means the mail price
		ok = ok and g._supply_price(key) == (int(g.SUPPLIES[key].cost) if g._on_shelf(key) else int(g.SUPPLIES[key].cost * 1.25))
	g.tools = saved_tools
	g.inventory = saved_inv
	# 1c. A fresh set of calls always has one within a short hop.
	g.jobs = []
	while g.jobs.size() < g.MAX_JOBS:
		g._spawn_job()
	ok = ok and g.jobs.any(func(j): return g.miles(g.location, j.city) < g.NEAR_MILES)
	# 2. No clock (D2): a call never expires, however long you take; a new call has no deadline.
	g.jobs = [fake.call("tire")]
	g.current_job = g.jobs[0]
	g._inspect_zone("gear_l")
	ok = ok and g.current_job != null and g.jobs.size() >= 1 and not "day" in g
	g._close_panel()
	g.jobs = []
	g._spawn_job()
	ok = ok and not g.jobs[0].has("deadline")
	# 3. Look-alikes: a bad magneto reads like fouled plugs. Swapping the plugs is spent, the next
	#    run-up shows no change, and the magneto is left as the one answer.
	g.current_job = fake.call("magneto")
	g.current_job.merge({"tried": {}, "washed": true}, true)
	g.jobs = [g.current_job]
	g._run_up()
	var mj: Dictionary = g.current_job
	ok = ok and mj.found.has("magneto") and mj.runup == "ran" and g.mag_drops(mj).x > 175
	g._work_done("spark_plugs")
	ok = ok and mj.tried == {"spark_plugs": false} and mj.runup == "" and not mj.fixed.has("magneto")
	g._run_up()
	ok = ok and mj.tried == {"spark_plugs": true} and g.mag_drops(mj).x > 175
	# 4. Hot mag and dead carb heat show only as zero drops on the run-up.
	g.current_job = fake.call("hot_mag")
	g.current_job.faults.append("carb_heat")
	g.current_job.merge({"tried": {}, "washed": true}, true)
	g.jobs = [g.current_job]
	g._run_up()
	mj = g.current_job
	ok = ok and mj.found.has("hot_mag") and mj.found.has("carb_heat") and g.mag_drops(mj).y == 0 and g.carb_drop(mj) == 0
	# 5. The first two jobs have no look-alike faults and nothing hidden behind the cowl.
	var was_rescued: int = g.rescued
	g.rescued = 0
	for i in 30:  # one at a time: each call takes a city
		g.jobs = []
		g._spawn_job()
		ok = ok and g.jobs[0].hidden == "" and not g.jobs[0].faults.any(func(id): return g.SUSPECTS.has(id))
	g.rescued = was_rescued
	g._close_panel()
	g.money = saved[0]
	g.jobs = saved[1]
	g.current_job = saved[2]
	return ok


## Every fault row can be played: the keys the game reads, a real zone, a clue. And one with no
## scene of its own gets the access-panel one, with torqued bolts if its row gives a range.
func _faults_test() -> bool:
	var ok := true
	for id in g.FAULTS:
		var f: Dictionary = g.FAULTS[id]
		if not f.has_all(["name", "part", "cost", "zone", "symptom"]) or not g.ZONES.has(f.get("zone", "")) or not (g.CLUES.has(id) or f.has("diags")):  # tests find the diags ones
			print("FAULT ", id, ": needs name, part, cost, zone (one of main.ZONES), symptom, and a CLUES line (or diags)")
			ok = false
		elif f.zone == "engine" and not f.has("diags") and not id in g.RUNUP_FAULTS and not Bay.PARTS.values().any(func(ps): return ps.any(func(p): return id in p.look)):
			print("FAULT ", id, ": a visible engine fault needs a part in bay.gd PARTS whose look lists it, or nobody can find it")
			ok = false
		elif not g.manual_data.get("pages", []).any(func(pg): return pg.get("job", "") == id and ResourceLoader.exists(String(pg.get("picture", "")))):
			print("FAULT ", id, ": needs a service manual page (data/c85_manual.json, job = its id) with a picture")
			ok = false
		elif not id in ["fod", "fabric_rot"] and not g.SQUAWKS.has(id):
			print("FAULT ", id, ": needs a pilot squawk in main.SQUAWKS")
			ok = false
		elif (f.has("diags") or id in g.RUNUP_FAULTS) and g.SQUAWKS.get(id, []).any(func(line): return (f.part != "" and f.part.to_lower() in line.to_lower()) or f.name.to_lower() in line.to_lower()):
			# A fault the pilot can't see: the squawk is the symptom, never the part. (A cracked
			# windshield is what they saw, so visible faults may name the thing.)
			print("FAULT ", id, ": its squawk names the hidden fault or its part; a pilot describes the symptom")
			ok = false
		elif not Work.scenes().has(id):
			print("fault ", id, ": no scene of its own in work.gd yet, repaired behind the access panel")
	var row := {"part": "Widget", "torque": Vector2i(50, 70)}
	var plain: Array = Work.scene_for("not_a_fault", row).els
	return ok and plain.filter(func(e): return e.get("range", Vector2i.ZERO) == row.torque).size() == 4 \
		and Work.needs_for("not_a_fault", row)[0].has_all(["ratchet", "torque", "screwdriver"]) \
		and Work.scene_for("not_a_fault", {"part": ""}).els[0].type == "task"


## The torque wrench: one pull sags away to nothing, mashing past the band backs a prop bolt off,
## and tapping to keep the needle in the green for a second clicks it tight.
func _torque_test() -> bool:
	var saved = [g.current_job, g.tools]
	g.current_job = {"city": g.location, "type": "Test", "faults": ["propeller"], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0}
	g.tools = {"ratchet": true, "torque": true}
	g._repair("propeller")
	var w = g.panel
	var bolt: Dictionary = w.els.filter(func(e): return e.get("torque", false))[0]
	w.st.mags = "off"  # the bolts are behind the mag switch tag and the safety wire
	w.st.wire = "off"
	w.st[bolt.id] = "snug"
	w.tool = "torque"
	w.hover = bolt.id
	w._pull(bolt, w.action(bolt))
	for i in 60:
		w._process(0.1)
	var ok: bool = w.st[bolt.id] == "snug" and w.needle == 0.0
	for i in 20:
		if w.st[bolt.id] == "snug":
			w._pull(bolt, w.action(bolt))
	ok = ok and w.st[bolt.id] == "loose" and w.needle == 0.0
	w.st[bolt.id] = "snug"
	for i in 100:
		if w.st[bolt.id] != "snug":
			break
		if w.needle < bolt.range.x + 10:
			w._pull(bolt, w.action(bolt))
		w._process(0.05)
	ok = ok and w.st[bolt.id] == "tight"
	if not ok:
		print("TORQUE test failed: bolt is ", w.st[bolt.id], ", needle ", w.needle)
	g._close_panel()
	g.current_job = saved[0]
	g.tools = saved[1]
	return ok


func _snap(prefix: String, name: String, wait := 0.4) -> void:
	_at("snap " + name)
	if prefix == "":
		return
	await get_tree().create_timer(wait).timeout
	if g.panel is PanelContainer and g.panel.size.y > get_viewport().get_visible_rect().size.y + 1.0:
		overflow = "%s (%d px)" % [g._list_title, g.panel.size.y]  # no scroll bars, so every sheet must fit
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [prefix, name])


## The drone must be up to volume before the field build starts stalling frames.
func _trip_probe() -> void:
	var t0 := Time.get_ticks_msec()
	var last := t0
	var worst := 0
	while not is_instance_valid(g._arrived):  # the flight scene: nothing loads, so no frame should stall
		await get_tree().process_frame
		var now := Time.get_ticks_msec()
		worst = maxi(worst, now - last)
		last = now
		if _trip_volume < -70.0 and now - t0 >= 1050:
			_trip_volume = g.sound._cruise.volume_db
	print("flight scene worst frame ", worst, " ms")
	_trip_saved_at = g._read_save(g.save_path).location  # the save under the card must already be at the destination


## Run-up through the real path; on a hand-propped plane that's the starting drill first.
func _run_up() -> void:
	g._run_up()
	if g.panel is Work:
		g.panel.solve()


## One troubleshooting step: open the test, do it, make a wrong call (nothing moves), then the right one.
func _troubleshoot(id: String) -> bool:
	var job: Dictionary = g.current_job
	var t: String = g._test_for(job, id)
	var step: int = job.get("dstep", {}).get(id, 0)
	g._diagnose(id)
	if not (g.panel is Work) or not g.panel.solve():
		return false
	var right: String = g._answer(id, t)
	var wrong: Array = g.TESTS[t].options.filter(func(o): return o[1] != right)
	var aid_ok: bool = not g.verdict_aid(id)
	g._call(id, wrong[0][1])
	aid_ok = aid_ok and g.verdict_aid(id)  # E4: a wrong call offers the manual page for the next try
	var stayed: bool = g._test_for(job, id) == t and job.get("dstep", {}).get(id, 0) == step
	g._call(id, right)
	aid_ok = aid_ok and not g.verdict_aid(id)  # and it's gone after that try
	if not aid_ok:
		print("AID verdict: not shown after a wrong call, or not gone after the next")
	return stayed and aid_ok and g._test_for(job, id) != t


## The weight-and-balance sum: the options must include the right CG.
func _answer_quiz(id: String) -> bool:
	var wb: Dictionary = g.current_job.wb
	var cg: float = wb.t * 187.5 / float(wb.l + wb.r + wb.t)
	g.current_job.fixed[id] = true
	return wb.opts.any(func(v): return absf(v - cg) < 0.01)


## Every work scene, fresh, on a plane of its own: it can be finished with the full kit, traps
## don't count, each test's readings lead to the right call for every fault it can find,
## grounding a plane pays and ends the job, and a cold engine needs preheating.
func _scene_tests() -> bool:
	var saved = [g.money, g.jobs, g.current_job, null, g.tools, g.inventory, g.badges.duplicate(), g.streaks.duplicate()]
	var ok := true
	g.tools = {}
	for t in Work.TOOLS:
		if t != "hand":
			g.tools[t] = true
	g.inventory = {}
	for mtl in g.SUPPLIES:
		if g.SUPPLIES[mtl].has("qty"):
			g.inventory[mtl] = 99
	for id in g.FAULTS:
		if g.FAULTS[id].part != "":
			g.inventory[g.FAULTS[id].part] = 5
	var fake = func(faults: Array, type := "Test") -> Dictionary:
		var j := {"city": g.location, "type": type, "faults": [], "fixed": {}, "found": {}, "checked": {}, "work": {},
			"reward": 1000, "spent": {"fuel": 0, "parts": 0, "mail": 0}}
		g._assign_faults(j, faults)
		g.jobs = [j]
		g.current_job = j
		return j
	for scene in Work.scenes():
		_at("scene test " + scene)
		if scene in g.TESTS:  # driven elsewhere
			continue  # driven below, through each fault it can find
		var j: Dictionary = fake.call([scene] if g.FAULTS.has(scene) else [])
		j.found[scene] = true
		if scene == "hand_prop":
			g._open_work(scene, func(): pass)
		else:
			g._repair(scene)
		var w = g.panel
		var solved: bool = w is Work and w.solve() and w.done()
		if not solved:
			print("SCENE STUCK: ", scene)
			if w is Work:
				for e in w.els:
					if e.type != "view":
						print("   ", e.id, " ", w.st[e.id], " ", w.action(e))
		ok = ok and solved
		if w is Work:
			var traps: Array = w.els.filter(func(e): return e.has("trap"))
			if traps.size() > 0:  # a trap costs time, never completes
				var m0: int = g.money  # the wrong move costs the try and teaches why; no charge, no time
				ok = ok and w.perform(traps[0], "do") and w.st[traps[0].id] == "todo" and g.money == m0 and w.note != ""
		g._close_panel()
	# Every test chain, for every fault that uses it.
	for id in g.FAULTS:
		for chain in g.FAULTS[id].get("diags", []):
			var j: Dictionary = fake.call([])
			j.faults = [id]
			j.diag = {id: chain}
			j.sym[id] = true
			for t in chain:
				if not _troubleshoot(id):
					print("TEST STUCK: ", id, " ", chain)
					ok = false
					break
			ok = ok and j.found.has(id)
			g._close_panel()
	# Grounding: a found prop strike pays a fee, logs it and ends the job.
	var gj: Dictionary = fake.call(["prop_strike"])
	gj.found["prop_strike"] = true
	var m0: int = g.money
	var logs: int = g.logbook.size()
	g._ground_job()
	ok = ok and g.current_job == null and not g.jobs.has(gj) and g.money > m0 and g.logbook.size() == logs + 1 and g.logbook[-1].grounded
	ok = ok and g.badges.has("hard_call")  # B1: grounding it for a reason that grounds it is The Hard Call
	g.logbook.resize(logs)
	g._close_panel()
	# A fabric spot that punches through grounds the plane.
	var fj: Dictionary = fake.call(["fabric_test"])
	fj.fabric_bad = 1
	fj.found["fabric_test"] = true
	g._repair("fabric_test")
	g.panel.solve()
	ok = ok and fj.faults.has("fabric_rot") and fj.found.has("fabric_rot")
	g._close_panel()
	# Cold soak: no run-up until it's preheated.
	var cj: Dictionary = fake.call([])
	cj.city = g.CITIES.keys().filter(func(c): return g.CITIES[c][2] == "snow")[0]
	g._run_up()
	ok = ok and not cj.has("runup")
	g._preheat()
	_run_up()
	ok = ok and cj.get("runup", "") == "ran"
	g._close_panel()
	var diff: String = g.difficulty
	g.difficulty = "medium"
	# Running it unready breaks things: a dry start scuffs a cylinder, loose prop bolts wreck the
	# prop, and a part you'd already fitted (the baffle seal) burns again. Found, no troubleshooting.
	var dj: Dictionary = fake.call(["pre_oil", "prop_bolts", "bird_nest", "baffles"])
	dj.preheated = true
	dj.fixed["baffles"] = true
	_run_up()
	ok = ok and dj.get("runup", "") == "ran" and ["worn_rings", "propeller", "baffles"].all(func(id):
		return dj.faults.has(id) and dj.found.has(id) and not dj.fixed.has(id))
	g._close_panel()
	# A pickled engine can't fire (dehydrator plugs in the holes): it refuses, and nothing breaks.
	var sj: Dictionary = fake.call(["storage"])
	sj.preheated = true
	var before: int = sj.faults.size()
	_run_up()
	ok = ok and sj.get("runup", "") == "dead" and sj.faults.size() == before
	g._close_panel()
	# Stations: every place at the engine, one cowling shared across them. A place with nothing
	# wrong shows good parts and never "finishes"; a visible fault is found by opening its place.
	var stj: Dictionary = fake.call(["spark_plugs", "bird_nest"])
	stj.found["spark_plugs"] = true
	var places: Array = g.station_places("engine")
	ok = ok and places.size() >= 20 and not places.has("fod") and places.has("compression")
	g.station_open("engine", "magneto")
	var hw = g.panel
	ok = ok and hw is Work and hw.healthy and hw.part_name == "" and hw.title_name == g.PLACES.magneto and hw.done(true)
	for f in hw.els.filter(func(e): return e.type == "fastener" and e.host == "cowl"):
		hw.perform(f, "loosen")
		hw.perform(f, "out")
	hw.perform(hw.by_id.cowl, "off")
	ok = ok and not stj.fixed.has("magneto") and g.panel == hw  # looking at a good part doesn't end anything
	g.station_open("engine", "bird_nest")
	ok = ok and stj.found.has("bird_nest") and g.panel.st.cowl == "off"  # seen, and the cowl's still off
	g.station_open("engine", "spark_plugs")
	var sw = g.panel
	ok = ok and sw.st.cowl == "off" and not sw.healthy
	g.station_open("engine", "bird_nest")
	ok = ok and g.panel.solve() and stj.fixed.has("bird_nest")
	g.station_open("engine", "spark_plugs")
	ok = ok and g.panel.solve() and stj.fixed.has("spark_plugs") and g.cowl_closed(stj)
	g._close_panel()
	g.station_zone = ""
	# Instruments: owning the compression tester isn't enough, it has to be in your hand.
	var ij: Dictionary = fake.call(["worn_rings"])
	ij.found["worn_rings"] = true
	g.tools["tester"] = true
	g.held = ""
	g._open_work("compression", func(): pass)
	var iw = g.panel
	ok = ok and iw is Work and not iw.usable("tester") and iw.usable("ratchet")
	g._hold("tester")
	ok = ok and g.held == "tester" and iw.usable("tester") and not iw.usable("timing")
	g.held = ""
	g._close_panel()
	# Easy: the boss won't let you start what you know isn't ready, and nothing breaks.
	g.difficulty = "easy"
	var ej: Dictionary = fake.call(["pre_oil"])
	ej.preheated = true
	ej.found["pre_oil"] = true
	_run_up()
	ok = ok and not ej.has("runup") and not ej.faults.has("worn_rings")
	g._close_panel()
	# Hard: clues say only what you see, a test with no symptom behind it reads normal and costs
	# time, and signing off with work open is a comeback that pays less.
	g.difficulty = "hard"
	ok = ok and not g.guide("medium") and g.clue("pre_oil") != g.CLUES["pre_oil"] and g.clue("tire") == g.CLUES["tire"]
	var hj: Dictionary = fake.call(["tire"])
	g._run_test("compression")
	ok = ok and g.panel is Work and g.panel.solve() and hj.get("dready", {}).is_empty()
	g._close_panel()
	var cash: int = g.money
	var r0: int = g.rescued
	g._sign_off()
	ok = ok and g.money - cash == 1000 - (g.FAULTS.tire.cost * 2 + 200) - g.HANGAR_FEE and g.logbook[-1].work[0].begins_with("Comeback")
	ok = ok and Array(g.logbook[-1].debrief.extra).any(func(x): return x.begins_with("Comeback")) and g.logbook[-1].debrief.next == g.DEBRIEF_ADVICE.comeback
	g.rescued = r0
	g.logbook.pop_back()
	# Supplies: the owner pays for what the job used; what you used on a good part is yours.
	g.difficulty = "medium"
	var pj: Dictionary = fake.call(["tire"])
	pj.fixed["tire"] = true
	for _k in 10:
		g.used_supply("tire", "Cotter pin", false)  # $1.50 each
	g.used_supply("magneto", "Gasket", true)
	cash = g.money
	g._sign_off()
	ok = ok and g.money - cash == 1000 + 15 - g.HANGAR_FEE and g.logbook[-1].supplies == 15  # less the job's hangar fee (D2)
	g.rescued = r0
	g.logbook.pop_back()
	g.difficulty = diff
	g.money = saved[0]
	g.jobs = saved[1]
	g.current_job = saved[2]
	g.tools = saved[4]
	g.inventory = saved[5]
	g.badges = saved[6]  # the scene tests' own deliveries and grounding don't count toward the real career
	g.streaks = saved[7]
	g._refresh_tracker()
	if not ok:
		print("SCENE TESTS FAILED")
	return ok


var _said := false


func _chk(ok: bool, where: int) -> void:
	_at("after check %d" % where)
	if not ok and not _said:
		_said = true
		print("FIRST FAILED CHECK at run() line ", where)


## Screenshots of every work scene: fresh, and with the job worked halfway.
func _scene_shots(prefix: String, only := []) -> void:
	g.tools = {}
	for t in Work.TOOLS:
		if t != "hand":
			g.tools[t] = true
	for mtl in g.SUPPLIES:
		if g.SUPPLIES[mtl].has("qty"):
			g.inventory[mtl] = 99
	for id in g.FAULTS:
		if g.FAULTS[id].part != "":
			g.inventory[g.FAULTS[id].part] = 5
	for scene in Work.scenes():
		if only.size() > 0 and not scene in only:
			continue
		var j := {"city": g.location, "type": "Test", "faults": [], "fixed": {}, "found": {}, "checked": {}, "work": {},
			"reward": 1000, "spent": {"fuel": 0, "parts": 0, "mail": 0}}
		var cause: String = scene
		if scene in g.TESTS:
			cause = g.TEST_KEY[scene].keys()[0]
		g._assign_faults(j, [cause] if g.FAULTS.has(cause) else [])
		if scene in g.TESTS:
			j.diag = {cause: [scene]}
			j.dstep = {}
		g.jobs = [j]
		g.current_job = j
		g._open_work(scene, func(): pass)
		var w = g.panel
		w.st["_fod"] = false
		await _snap(prefix, scene + "_a", 0.3)
		for _i in 400:  # work it until half the pieces have moved
			if w.done() or w._solve_step(true, {}) == "":
				break
			if w.els.filter(func(e): return e.type != "view" and e.type != "fastener" and w.st[e.id] != w._initial(e)).size() * 2 >= w.els.filter(func(e): return e.type != "view" and e.type != "fastener").size():
				break
		await _snap(prefix, scene + "_b", 0.3)
		g._close_panel()
	for job in ([] if only.size() > 0 else ["", "spark_test", "oil_change"]):  # the service manual: contents and two job pages
		g._open_manual(job)
		await _snap(prefix, "manual_" + (job if job != "" else "contents"), 0.6)
		g._close_panel()


## D1: the debrief shows money and mistakes, never a day or hour figure; lines saved before D1 are
## cleaned when shown, keeping their dollars, and a part's own brackets survive.
func _debrief_no_time(deb: Dictionary) -> bool:
	var rx := RegEx.create_from_string("[0-9.]+ (h|days?)\\b|days on site|, day [0-9]")
	var sheet: String = g._list_title
	var texts: PackedStringArray = []
	var stack: Array = [g.panel] if g.panel != null else []
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label or n is RichTextLabel or n is Button:
			texts.append(n.text)
		stack.append_array(n.get_children())
	var shown := "\n".join(g.debrief_lines(deb)) + "\n" + "\n".join(texts)
	var old: PackedStringArray = g.debrief_lines({"extra": ["Left mag called bad  (1 h)", "Gasket assortment (10) by mail  (1.0 day, $6)", "A wrong call on the compression  (a do-over)"]})
	var ok: bool = sheet == "Debrief" and rx.search(shown) == null \
		and Array(old) == ["Left mag called bad", "Gasket assortment (10) by mail  ($6)", "A wrong call on the compression"]
	print("debrief without time: %s %s" % [ok, old])
	return ok


## D3: the end-of-mission card is centred; every figure's colour matches its sign (+ green,
## - red, zero brass); the achievements are this job's badges (Sharp Eyes comes at this sign-off)
## and nothing else; a job with none says so; an entry saved before D3 still opens.
func _mission_card_ok(deb: Dictionary) -> bool:
	# Delivery puts everything on the card (Thad): no RESCUED banner, no "+$" pop at the top right,
	# no owner's line across the top; the owner's words are on the card.
	var banner_ok: bool = not is_instance_valid(g._banner_node) or g._banner_node.is_queued_for_deletion()
	var pops: Array = g.ui.get_children().filter(func(n): return n is Label and n.text.begins_with("+$") and not n.is_queued_for_deletion())
	var top_ok: bool = pops.is_empty() and not g.msg.text.contains("paid $")
	var said_ok: bool = String(deb.get("said", "")) != "" and g.panel.find_children("Said", "Label", true, false).size() == 1
	await get_tree().process_frame
	var card: Control = g.panel
	var centre_ok := card != null and card.name == "MissionCard" \
		and card.get_global_rect().get_center().distance_to(card.get_viewport_rect().size / 2.0) < 3.0
	var colour_ok := true
	var n_gain := 0
	var n_loss := 0
	for l: Label in card.find_children("*", "Label", true, false):
		var c: Color = l.get_theme_color("font_color")
		if l.name == "gain":
			n_gain += 1
			colour_ok = colour_ok and c == Style.COLOR_TEXT_GAIN and (l.text.begins_with("+") or String(l.get_parent().name) in ["Award", "Gift"])
		elif l.name == "loss":
			n_loss += 1
			colour_ok = colour_ok and c == Style.COLOR_TEXT_LOSS and (l.text.begins_with("\u2212") or l.text == "")
		elif l.text.begins_with("+$") or l.text.begins_with("\u2212$"):
			colour_ok = false  # a signed figure left uncoloured
	# The ticket: station code and N-number top left; the total is the line items added up; it fits.
	var reg_l: Array = card.find_children("Registration", "Label", true, false)
	var reg_txt: String = reg_l[0].text if reg_l.size() > 0 else ""
	var reg_ok: bool = RegEx.create_from_string("^N[1-9][0-9]{0,4}[A-HJ-NP-Z]{0,2}$").search(reg_txt) != null and reg_txt.length() <= 6 \
		and reg_txt == g.logbook[-1].get("reg", "")
	var st_l: Array = card.find_children("Station", "Label", true, false)
	var station_ok: bool = st_l.size() == 1 and st_l[0].text.begins_with(g.station_code(g.logbook[-1].city)) \
		and g.STATIONS.size() == g.CITIES.size() and g.CITIES.keys().all(func(c): return String(g.STATIONS.get(c, "")).length() == 4)
	var tot_row: Array = card.find_children("Total", "HBoxContainer", true, false)
	var want_total: int = int(deb.pay) + int(deb.get("bonus", 0)) - int(deb.fuel) - int(deb.parts) - int(deb.rent) - int(deb.get("guesses", 0))
	var tot_txt: String = tot_row[0].get_child(1).text if tot_row.size() > 0 else ""
	var total_ok: bool = tot_txt.replace(",", "") == "%s$%d" % ["+" if want_total > 0 else "\u2212" if want_total < 0 else "", absi(want_total)]
	var fit_ok: bool = card.get_global_rect().size.y <= card.get_viewport_rect().size.y
	# A lesson's sign-off is on the ticket, and its own card doesn't open over it.
	# The sign-off card waits for the map, and the checklist's tick slips are held, not drawn over it.
	var lesson_ok: bool = not is_instance_valid(g.tutorial._reward) and g.ticket_open()
	print("ticket: no lesson card over it %s" % lesson_ok)
	# Hierarchy (D4): total > registration > line items > labels, by font size; the corner one line.
	var fsize := func(l: Label) -> int: return l.get_theme_font_size("font_size")
	var tot_fig: Label = tot_row[0].get_child(1) if tot_row.size() > 0 else null
	var item: Array = card.find_children("Figure", "HBoxContainer", true, false).filter(func(r): return r.name != "Total")
	var corner: Array = card.find_children("Corner", "Label", true, false)
	var hier_ok: bool = tot_fig != null and reg_l.size() > 0 and item.size() > 0 and corner.size() == 1 \
		and fsize.call(tot_fig) > fsize.call(reg_l[0]) and fsize.call(reg_l[0]) > fsize.call(item[0].get_child(1)) \
		and fsize.call(corner[0]) < fsize.call(item[0].get_child(0)) and corner[0].text.split("\n").size() == 1 \
		and int(deb.get("checked", -1)) >= 0
	print("ticket: hierarchy %s (total %d, registration %d, item %d, label %d)" % [hier_ok, fsize.call(tot_fig) if tot_fig else 0,
		fsize.call(reg_l[0]) if reg_l.size() else 0, fsize.call(item[0].get_child(1)) if item.size() else 0, fsize.call(corner[0]) if corner.size() else 0])
	var ticket_ok: bool = hier_ok and lesson_ok and reg_ok and station_ok and total_ok and fit_ok
	print("ticket: registration %s %s, station %s, total %s %s, fits %s" % [reg_ok, reg_txt, station_ok, total_ok, tot_txt, fit_ok])
	var awards: Array = card.find_children("Award*", "HBoxContainer", true, false)
	var got: Array = deb.get("badges", [])
	var badge_ok: bool = got.all(func(b): return g.badges.has(b)) and (got.has("barn_find") == (int(g.logbook[-1].get("years", 0)) >= g.BADGE_BARN_YEARS)) \
		and awards.size() == got.size() + deb.get("promoted", []).size()
	# None earned: the card says so. And an older entry (no badges or stats saved) still opens.
	var plain := {"type": "Cub", "city": "Ames", "debrief": {"pay": 900, "fuel": 40, "parts": 0, "rent": 80, "net": 780,
		"extra": ["Left mag called bad  (1 h)"], "next": "x"}}
	plain["day"] = 4
	var derived_ok: bool = g.registration(plain) == g.registration(plain.duplicate(true)) and g.registration(plain).begins_with("N")
	g._open_mission_card(plain)
	await get_tree().process_frame
	var none_ok: bool = derived_ok and g.panel.find_children("Award*", "HBoxContainer", true, false).is_empty() \
		and g.panel.find_children("*", "Label", true, false).any(func(l): return l.text.begins_with("No new badges"))
	g._close_panel()
	var ok := ticket_ok and banner_ok and top_ok and said_ok and centre_ok and colour_ok and n_gain >= 2 and n_loss >= 1 and badge_ok and none_ok
	print("mission card: banner cleared %s, nothing at the top %s, owner's words %s, centred %s, colours %s (%d gain, %d loss), badges %s %s, none %s" % [banner_ok, top_ok, said_ok, centre_ok, colour_ok, n_gain, n_loss, badge_ok, got, none_ok])
	return ok


## D2: no day count anywhere the player looks. Reads every page of the logbook (with the
## badge board), the map, the career on the game-over sheet and the pause readout; the hangar fee
## is shown as a fee per job. And a save from before D2 loses its clock when it loads.
func _no_days_ok() -> bool:
	var rx := RegEx.create_from_string("(?i)\\bday\\s*[0-9]|[0-9.]+\\s*days?\\b|days? (on site|on the road)|\\ba day\\b|waits [0-9]|days' rent|half a day")
	var seen: PackedStringArray = []
	var bad: PackedStringArray = []
	var sheets := {"logbook": func(): g._pocket("logbook"), "map": func(): g._open_travel(),
		"career": func(): g._open_game_over(500)}
	for name in sheets:
		g._close_panel()
		sheets[name].call()
		for page in g._pages:
			for r in page:
				var t := " ".join(PackedStringArray(Array(r).filter(func(x): return x is String)))
				seen.append(t)
				if rx.search(t) != null:
					bad.append("%s: %s" % [name, t.left(80)])
	g._close_panel()
	# U2: the catalogs are drawn as cards, not sheet rows: open the parts counter and the mail-order
	# catalog, every section and every spread, and read every card's text.
	var mail_seen := false
	for opener in [g._open_shop, g._open_toolbox]:
		opener.call()
		var cat = g.panel
		if cat == null or not ("_sections" in cat):  # the catalog sheet (catalog.gd)
			bad.append("catalog didn't open")
			continue
		for sec in cat._sections.size():
			if sec != cat._sec:
				cat._tab(sec)
			for sp in cat._spread_count():
				cat._spread = sp
				cat._build()
				for l in cat.find_children("*", "Label", true, false):
					if l.is_queued_for_deletion():
						continue
					var t: String = l.text
					mail_seen = mail_seen or t.contains("25% OVER SHELF")
					if rx.search(t) != null:
						bad.append("catalog: " + t.left(80))
		g._close_panel()
	var all := "\n".join(seen)
	var fee_ok: bool = all.contains("$%d hangar fee" % g.HANGAR_FEE)  # on the map's estimates (the wallet sheet went in W1)
	var hud_ok: bool = rx.search(g.msg.text) == null and not "day" in g
	# An old save: version 2, with a clock and a deadline.
	var old := {"version": 2, "day": 7.5, "money": 900, "jobs": [{"city": "Omaha", "deadline": 9.0, "arrived": 6.0}]}
	g._migrate(old)
	var migrate_ok: bool = int(old.version) == g.SAVE_VERSION and not old.has("day") and not old.jobs[0].has("deadline") and not old.jobs[0].has("arrived")
	var ok: bool = bad.is_empty() and fee_ok and hud_ok and migrate_ok and mail_seen
	print("no days: shown %s, fee %s, hud %s, old save %s, catalog read with its mail-order line %s" % ["none" if bad.is_empty() else str(bad), fee_ok, hud_ok, migrate_ok, mail_seen])
	return ok



## LB1: the logbook opens on the rank, then the entries newest first with no money breakdown, then
## the badge grid of eight. A ten-job career fits on fewer pages than the old layout did.
func _logbook_ok() -> bool:
	g._close_panel()
	g._open_logbook()
	var rings: Array = g.panel.find_children("Ring", "Control", true, false)
	var ring_ok: bool = g._list_title == "Logbook" and rings.size() == 1 and rings[0].done == g.rescued and rings[0].total == g.GOAL
	var first: Array = g._pages[0]
	var last: Array = g._pages[-1]
	var name_of := func(r: Array) -> String: return String(r[5].get("name", "")) if r.size() > 5 and r[5] is Dictionary else ""
	var flat: Array = []
	for pg in g._pages:
		flat.append_array(pg)
	var order_ok: bool = name_of.call(first[0]) == "Rank" and name_of.call(last[-1]) == "Badges" \
		and flat.slice(1, flat.size() - 1).all(func(r): return name_of.call(r) == "Entry" or g.logbook.is_empty())
	var money_ok: bool = not flat.any(func(r): return String(r[0]).contains("Paid $") or String(r[0]).contains("Cost extra"))
	var shown_ok := false
	var rank_rows: Array = g._list.find_children("Rank", "HBoxContainer", false, false)
	var rank_size: int = rank_rows[0].get_child(0).get_child(0).get_theme_font_size("font_size") if rank_rows.size() > 0 else 0
	g._page = g._pages.size() - 1
	g._show_page()
	var grids: Array = g._list.find_children("Grid", "GridContainer", true, false).filter(func(n): return not n.is_queued_for_deletion() and not n.get_parent().get_parent().is_queued_for_deletion())
	var grid_ok: bool = grids.size() == 1 and grids[0].get_child_count() == g.BADGES.size()
	shown_ok = rank_size == Style.SIZE_XL and grid_ok
	# A ten-job career: new rows against the old layout's (tally, rank, badge header, 8 badges, 3 rows a job).
	var e: Dictionary = g.logbook[-1] if g.logbook.size() > 0 else {"city": "Omaha", "type": "Cub", "pay": 3000, "work": ["Flat main tire"]}
	var new_rows: Array = [first[0]]
	var old_rows: Array = [["Planes back in the air: 10 of 10"], ["Rank: x\n" + g.rank_next_line()], ["Badges: 2 of 8"]]
	for b in g.BADGES:
		old_rows.append(["%s  (%s)  earned\n%s" % [b[1], b[2], b[3]], "", null, false, "hud/badge.svg"])
	for i in 10:
		new_rows.append(g.logbook_entry_row(e, i == 0))
		old_rows.append(["%s  -  %s\n%s\nPaid $3000 - fuel $500 - parts $100 = $2400" % [e.city, e.type, ", ".join(e.work)]])
		old_rows.append(["Spots checked 8 of 8. Faults fixed 1 of 1."])
		old_rows.append(["Cost extra: Left mag called bad\nNext time: Read each drop against the limit."])
	new_rows.append(last[-1])
	var room: float = g.get_viewport().get_visible_rect().size.y - 230.0
	var pages_new: int = g._paginate(new_rows, room).size()
	var pages_old: int = g._paginate(old_rows, room).size()
	g._close_panel()
	var ok: bool = ring_ok and order_ok and money_ok and shown_ok and pages_new < pages_old
	print("logbook: progress ring %s, rank first and large %s, entries without money %s, badge grid %s, ten jobs on %d pages (was %d)" % [ring_ok, order_ok and rank_size == Style.SIZE_XL, money_ok, grid_ok, pages_new, pages_old])
	return ok


## E6: the ending is the ticket's glass card: centred and fitting at full size, not closable, one
## primary button (Keep flying) and quiet others, the two career figures, the ring full, the rank
## among the achievements, and none of the old prose or trivia.
func _ending_ok() -> bool:
	await get_tree().process_frame
	await get_tree().process_frame
	var card: Control = g.panel
	if card == null or card.name != "EndingCard":
		print("ending: not the glass card")
		return false
	var vp: Vector2 = card.get_viewport_rect().size
	var centre_ok: bool = card.get_global_rect().get_center().distance_to(vp / 2.0) < 3.0
	var buttons: Array = card.find_children("*", "Button", true, false)
	var primary: Array = buttons.filter(func(b): return b.name == "Primary")
	var one_primary: bool = primary.size() == 1 and primary[0].text == "Keep flying" and buttons.size() == 3
	var figures: Array = card.find_children("Figure", "Label", true, false)
	var rings: Array = card.find_children("Ring", "Control", true, false)
	var texts := "\n".join(card.find_children("*", "Label", true, false).map(func(l): return l.text))
	var trimmed: bool = not texts.contains("Longest neglected") and not texts.contains("hangar door")
	var rank_ok: bool = texts.contains("Rank: " + g.rank_title(g.rank))
	var ok: bool = centre_ok and not g.panel_closable and one_primary and figures.size() == 2 \
		and rings.size() == 1 and rings[0].done == g.GOAL and trimmed and rank_ok
	print("ending: card centred %s, one primary %s, figures %d, ring %s, trimmed %s, rank %s, scale %.2f" % [centre_ok,
		one_primary, figures.size(), rings.size() == 1 and rings[0].done == g.GOAL, trimmed, rank_ok, card.scale.x])
	return ok



## C1: the cockpit checklist is drawn small in the bottom-left corner on glass: within the screen,
## narrower than the old 380 px card, smaller in area than the old card would be for the same
## steps (380 wide, 26 px rows, a 30 px title), and its foot line wrapped, not cut off.
func _cockpit_card_ok(phase: String) -> bool:
	var pf = g.preflight
	pf.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	if not pf.wanted():
		print("cockpit card (%s): not up" % phase)
		return false
	var r: Rect2 = pf.last_rect
	var vp: Vector2 = pf.size
	var c: Dictionary = g.ferry.card()
	var old_h: float = 14 + 14 + 30 + c.steps.size() * 26 + (26 if c.foot != "" else 0) + 8 + (40 if c.alert != "" else 0)
	var corner_ok: bool = r.position.x <= 16.5 and absf(r.end.y - (vp.y - 16.0)) < 1.0 and r.position.y >= 0.0
	var smaller_ok: bool = r.size.x < 380.0 and r.get_area() < 380.0 * old_h
	var font := Style.display(600)
	var foot_w: float = font.get_string_size(c.foot, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XS).x
	var foot_ok: bool = c.foot == "" or foot_w <= r.size.x - 24.0 or font.get_multiline_string_size(c.foot, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 24.0, Style.SIZE_XS).y > Style.SIZE_XS * 1.5
	var glass_ok: bool = pf._glass.visible and pf._glass.size == r.size
	var ok: bool = corner_ok and smaller_ok and foot_ok and glass_ok
	print("cockpit card (%s): corner %s, %dx%d (old about 380x%d) %s, foot %s, glass %s" % [phase, corner_ok, r.size.x, r.size.y, old_h, smaller_ok, foot_ok, glass_ok])
	return ok



## U3: one band of words at the top at a time. In the cockpit a message and a banner go to the log
## (the centre band and banners stay clear); the pause clears both; the squawk notes card hides
## the centre band and the pinned squawk. Counts what's visible at the top after each.
func _top_bands_ok(where: String) -> bool:
	var bands := func() -> PackedStringArray:
		g._update_hud()
		var out: PackedStringArray = []
		if g.msg.visible:
			out.append("message")
		if is_instance_valid(g._banner_node) and not g._banner_node.is_queued_for_deletion():
			out.append("banner")
		if g.squawk.visible:
			out.append("squawk")
		return out
	var ok := false
	var seen: PackedStringArray = []
	match where:
		"cockpit":
			var lines: int = g._log_list.get_child_count()
			g._say("A test line in the cockpit.")
			g._banner("FIXED", "A test fix")
			await get_tree().process_frame
			seen = bands.call()
			ok = seen.is_empty() and g._log_list.get_child_count() > mini(lines, g.LOG_LINES - 2)
		"pause":
			g._close_panel()
			g._say("Said just before the pause.")
			g._banner("BADGE: TEST", "before the pause")
			g._open_pause()
			await get_tree().process_frame
			seen = bands.call()
			ok = seen.is_empty()
			g._close_menu()
		"notes":
			g._close_panel()
			var id: String = g.tutorial.NOTES.keys()[0]
			var j := {"city": g.location, "type": "Test", "faults": [id], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0}
			var was = g.current_job
			g.current_job = j
			g._say("Arrived: walk around the plane.")
			g.tutorial._show_notes(j)
			await get_tree().process_frame
			seen = bands.call()
			ok = seen.is_empty() and is_instance_valid(g.tutorial._notes)
			g.tutorial._close_notes()
			g.current_job = was
			g._say("")
	print("top bands (%s): %s, %s" % [where, "only one" if ok else "too many", seen])
	return ok



## W1: cash is on screen, top right: it reads what you have (thousands separated) and follows a
## change; it shows in the world and beside a sheet, not in the pause; money pops sit under it, and
## neither overlaps the pinned squawk.
func _cash_ok(shot: String) -> bool:
	var c: Label = g.cash_label
	var m0: int = g.money
	g._close_panel()
	g.money = m0 + 1234
	g._update_hud()
	await get_tree().process_frame
	var reads_ok: bool = c.text == "$" + g._thousands(g.money) and c.visible
	await _snap(shot, "cash", 0.2)
	g._pocket("logbook")
	g._update_hud()
	var beside_sheet: bool = c.visible
	g._close_panel()
	g._open_pause()
	g._update_hud()
	var hidden_in_pause: bool = not c.visible
	g._close_menu()
	g.money += 1  # a fresh pop to measure
	g.money += 1  # and a second at once: it adds to the first, one figure on screen
	await get_tree().process_frame
	var pops: Array = g.ui.get_children().filter(func(n): return n is Label and n.has_meta("sum") and not n.is_queued_for_deletion())
	var cash_r := c.get_global_rect()
	var font := Style.figures(true)
	var cash_ink := Rect2(cash_r.end.x - font.get_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Style.SIZE_XL).x, cash_r.position.y, 9999, cash_r.size.y)
	var sq_r: Rect2 = g.squawk.get_global_rect() if g.squawk.visible else Rect2()
	var pop_ok: bool = pops.size() == 1 and pops.all(func(p):
		var pr: Rect2 = p.get_global_rect()
		var ink := Rect2(pr.end.x - font.get_string_size(p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x, pr.position.y, 9999, pr.size.y)
		ink.size.x = pr.end.x - ink.position.x
		return not ink.intersects(cash_ink) and not ink.intersects(sq_r))
	var sq_ok: bool = not g.squawk.visible or g.squawk.get_global_rect().position.y >= cash_r.end.y
	g._quiet_money = true
	g.money = m0
	g._quiet_money = false
	g._update_hud()
	var ok: bool = reads_ok and beside_sheet and hidden_in_pause and pop_ok and sq_ok
	print("cash: reads %s (%s), beside a sheet %s, hidden in the pause %s, pops clear of cash and squawk %s, squawk clear %s" % [reads_ok, c.text, beside_sheet, hidden_in_pause, pop_ok, sq_ok])
	return ok



## L1: signing off is one press. The work order offers "Sign off" (never the old entry choices);
## pressing it signs with the entry written to the manual; there are seven badges, none of them By
## the Book; an old save holding By the Book loses it on load.
func _sign_off_ok(job: Dictionary, shot: String) -> bool:
	g._open_inspection()
	var labels: PackedStringArray = []
	for pg in g._pages:
		for r in pg:
			if r.size() > 1:
				labels.append(String(r[1]))
	var hard: bool = not g.guide("medium")  # Hard offers one press at the cabin: "Sign off & take off"
	var button_ok: bool = (hard or labels.has("Sign off")) and not labels.has("Write this") and not labels.has("Write up the logbook")
	await _snap(shot, "signoff")
	var sign: Array = []
	for pg in g._pages:
		for r in pg:
			if r.size() > 2 and String(r[1]) == "Sign off":
				sign.append(r[2])
	if sign.size() > 0:
		sign[0].call()
	elif hard:
		g._sign(job)  # what Hard's "Sign off & take off" does before it takes off (checked in source below)
		button_ok = button_ok and "_sign(current_job)" in (g.get_script() as GDScript).source_code.get_slice("func _hard_take_off", 1).get_slice("\nfunc ", 0)
	var signed_ok: bool = job.get("signed", false) and String(job.get("entry", "")).contains("AC 43.13-1B") \
		and String(job.entry).contains("certificate")
	var badges_ok: bool = g.BADGES.size() == 8 and not g.BADGES.any(func(b): return b[0] == "by_the_book") \
		and g.tracker.get_child_count() == 8
	var old := {"version": 3, "badges": {"by_the_book": 1, "sharp_eyes": 2}, "jobs": []}
	g._migrate(old)  # L1 drops By the Book; B1 drops the rest of the old set and starts the runs empty
	var migrate_ok: bool = old.badges.is_empty() and old.get("streaks", null) == {} and int(old.version) == g.SAVE_VERSION
	var ok: bool = button_ok and signed_ok and badges_ok and migrate_ok
	print("sign off: one button %s, signed to the manual %s, eight badges %s, old save %s" % [button_ok, signed_ok, badges_ok, migrate_ok])
	return ok



## B1: every badge reachable, and only at its standard. Each hook driven to one short (withheld),
## through a break (reset), and to the run (earned); the extra conditions (two bad mags, a
## look-alike) hold them back until met. On a copy of the career, put back after.
func _badge_rules_ok() -> bool:
	var keep := [g.badges.duplicate(), g.streaks.duplicate()]
	g.badges = {}
	g.streaks = {}
	var out := {}
	var full := {"checked": {}, "years": 0}
	for z in g.ZONES:
		full.checked[z] = true
	# Clean Sheet: 4, a break, then 5.
	for i in 4:
		g.badge_after_delivery({}, ["x"], true)
	var short_ok: bool = not g.badges.has("clean_sheet")
	g.badge_after_delivery({}, ["x"], false)
	for i in 4:
		g.badge_after_delivery({}, ["x"], true)
	out["clean_sheet"] = short_ok and not g.badges.has("clean_sheet")
	g.badge_after_delivery({}, ["x"], true)
	out["clean_sheet"] = out.clean_sheet and g.badges.has("clean_sheet")
	# Nothing Gets Past You: 4 full walk-arounds, then a comeback breaks it, then 5.
	for i in 4:
		g.badge_after_delivery(full, [], false)
	short_ok = not g.badges.has("walkround")
	g.badge_after_delivery(full, ["tire"], false)
	for i in 5:
		g.badge_after_delivery(full, [], false)
	out["walkround"] = short_ok and g.badges.has("walkround")
	# Calibrated Hand: 9 clean torque jobs, an over-torque, a job with no torque (no change), then 10.
	for i in 9:
		g.badge_after_delivery({"torqued": true}, ["x"], false)
	short_ok = not g.badges.has("calibrated")
	g.badge_after_delivery({"over": true, "torqued": true}, ["x"], false)
	g.badge_after_delivery({}, ["x"], false)
	var reset_ok: bool = int(g.streaks.get("calibrated", -1)) == 0
	for i in 10:
		g.badge_after_delivery({"torqued": true}, ["x"], false)
	out["calibrated"] = short_ok and reset_ok and g.badges.has("calibrated")
	# Mag Whisperer: 10 clean run-ups with only one bad mag: withheld; one more with a bad mag: earned.
	for i in 10:
		g.badge_after_runup(true, 1 if i == 0 else 0)
	short_ok = not g.badges.has("mag_whisperer")
	g.badge_after_runup(true, 1)
	out["mag_whisperer"] = short_ok and g.badges.has("mag_whisperer")
	# Troubleshooter: 5 clean trails on a fault that's no look-alike: withheld; a look-alike: earned.
	var plain_ids: Array = g.FAULTS.keys().filter(func(id): return not g.FAULTS[id].get("diags", []).is_empty() and not g.is_look_alike(id))
	var alike_ids: Array = g.FAULTS.keys().filter(func(id): return not g.FAULTS[id].get("diags", []).is_empty() and g.is_look_alike(id))
	for i in 5:
		g.badge_after_trail(plain_ids[0], true)
	short_ok = not g.badges.has("troubleshooter")
	g.badge_after_trail(alike_ids[0], false)  # a trail with a wrong call doesn't count
	var still_short: bool = not g.badges.has("troubleshooter")
	g.badge_after_trail(alike_ids[0], true)
	out["troubleshooter"] = short_ok and still_short and g.badges.has("troubleshooter") and not plain_ids.is_empty() and not alike_ids.is_empty()
	# Steady Hands: 9 clean flights, a forced landing, then 10.
	for i in 9:
		g.badge_after_flight(true)
	short_ok = not g.badges.has("steady_hands")
	g.badge_after_flight(false)
	for i in 9:
		g.badge_after_flight(true)
	var nine_after_break: bool = not g.badges.has("steady_hands")
	g.badge_after_flight(true)
	out["steady_hands"] = short_ok and nine_after_break and g.badges.has("steady_hands")
	# Barn Find: 9 years no; 10 years with a comeback no; 10 years clean yes.
	g.badge_after_delivery({"years": 9}, [], false)
	g.badge_after_delivery({"years": 10}, ["tire"], false)
	short_ok = not g.badges.has("barn_find")
	g.badge_after_delivery({"years": 10}, [], false)
	out["barn_find"] = short_ok and g.badges.has("barn_find")
	# The board shows a run's progress under a badge not yet earned.
	g.badges = {}
	g.streaks = {"clean_sheet": 3}
	var progress_ok: bool = g.badge_progress("clean_sheet") == "3 of 5" and g.badge_progress("barn_find") == ""
	g.badges = keep[0]
	g.streaks = keep[1]
	g._refresh_tracker()  # the row shows the real career again
	g._clear_top()  # and the test's badge banners go
	var ok: bool = out.values().all(func(v): return v) and progress_ok and g.IA_NEEDS.badges == 4
	print("badge rules: %s, progress %s" % [out, progress_ok])
	return ok



## U7: the squawk notes in short pages. For the longest and the shortest squawk the game has: no
## page over three sentences (labels and quoted phrases aside), every sentence of the write-up on a
## page, Next to move on and Back to return, GO LOOK only on the last page, and pressing it closes
## the card.
func _notes_pages_ok(shot: String) -> bool:
	var tut = g.tutorial
	var ids: Array = tut.NOTES.keys().filter(func(id): return g.SQUAWKS.has(id))
	var by_len := func(id: String) -> int: return g.SQUAWKS[id].map(func(v): return String(v).length()).max()
	var long_id: String = ids[0]
	var short_id: String = ids[0]
	for id in ids:
		if by_len.call(id) > by_len.call(long_id):
			long_id = id
		if by_len.call(id) < by_len.call(short_id):
			short_id = id
	var ok := true
	var report: PackedStringArray = []
	for id in [long_id, short_id]:
		var variants: Array = g.SQUAWKS[id]
		var longest: int = 0
		for k in variants.size():
			if String(variants[k]).length() > String(variants[longest]).length():
				longest = k
		var j := {"city": g.location, "type": "Test", "faults": [id], "fixed": {}, "found": {}, "checked": {}, "work": {},
			"reward": 0, "cyl": 0, "seed_squawk": 0}
		for s0 in variants.size():  # pick the seed that gives the longest wording
			j.seed_squawk = s0
			if g.squawk_line(j, id) == variants[longest]:
				break
		var pages: Array = tut.notes_pages(j, id)
		var counted := true
		var text_in_order := ""
		for pg in pages:
			var n := 0
			for part in pg:
				if part[0] in ["squawk", "intro", "means", "look"]:
					n += tut.sentences(part[1]).size()
				if part[0] in ["squawk", "phrase", "means", "look"]:
					text_in_order += " " + String(part[1])
			counted = counted and n <= tut.NOTES_PAGE_SENTENCES
		var said: String = g.squawk_line(j, id)
		var all_there: bool = Array(tut.sentences(said)).all(func(x): return text_in_order.contains(x)) \
			and tut.NOTES[id].notes.all(func(nn): return text_in_order.contains(nn[1])) and text_in_order.contains(tut.NOTES[id].look)
		# Page through it for real: Next, Back, then GO LOOK on the last page.
		g.current_job = j
		tut._show_notes(j)
		await get_tree().process_frame
		var live := func(name: String) -> Array:
			return tut._notes_col.find_children(name, "Button", true, false).filter(func(b): return not b.is_queued_for_deletion())
		var path_ok: bool = live.call("GoLook").is_empty() == (pages.size() > 1)
		if pages.size() > 1:
			live.call("Next")[0].pressed.emit()
			await get_tree().process_frame
			path_ok = path_ok and tut._notes_i == 1
			if id == long_id:
				await _snap(shot, "notes_page2", 0.3)
			live.call("Back")[0].pressed.emit()
			await get_tree().process_frame
			path_ok = path_ok and tut._notes_i == 0
		for k in pages.size() - 1:
			live.call("Next")[0].pressed.emit()
			await get_tree().process_frame
		var go: Array = live.call("GoLook")
		path_ok = path_ok and go.size() == 1 and tut._notes_i == pages.size() - 1
		await get_tree().process_frame
		var fits: bool = tut._notes.size.y <= tut._notes.get_combined_minimum_size().y + 1.0  # no empty space left from a longer page
		path_ok = path_ok and fits
		if id == long_id:
			await _snap(shot, "notes_last", 0.3)
		if go.size() == 1:
			go[0].pressed.emit()
		await get_tree().process_frame
		path_ok = path_ok and not is_instance_valid(tut._notes)
		ok = ok and counted and all_there and path_ok
		report.append("%s: %d pages, three or fewer a page %s, all there %s, Next/Back/GO LOOK %s" % [id, pages.size(), counted, all_there, path_ok])
	# A long squawk, as long as the map's (seven sentences): it splits into chunks of three at most,
	# in order, across pages you can page through and back.
	var long_said := "Right brake squeals, then grinds. Takes forever to stop on the ramp. It's been sitting a long time. The last gas went in years ago, and what I sumped smells off. Nobody remembers the last oil change. What's on the dipstick looks black. The ropes look rough."
	var lj := {"city": g.location, "type": "Test", "faults": [long_id], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0}
	var lpages: Array = tut.notes_pages(lj, long_id, long_said)
	var chunks: PackedStringArray = []
	var chunk_ok := true
	for pg in lpages:
		for part in pg:
			if part[0] == "squawk":
				var inner: String = String(part[1]).trim_prefix("\u201c").trim_suffix("\u201d")
				chunk_ok = chunk_ok and tut.sentences(inner).size() <= tut.NOTES_PAGE_SENTENCES
				chunks.append(inner)
	var in_order: bool = " ".join(chunks) == long_said and chunks.size() == 3  # 3 + 3 + 1 sentences
	g.current_job = lj
	tut._show_notes(lj, long_said)
	await get_tree().process_frame
	await _snap(shot, "notes_long_1", 0.3)
	tut._notes_page(1)
	await get_tree().process_frame
	await _snap(shot, "notes_long_2", 0.3)
	var shown: Array = tut._notes_col.find_children("*", "Label", true, false).filter(func(l): return not l.is_queued_for_deletion() and String(l.text).begins_with("\u201c"))
	var page2_ok: bool = shown.size() == 1 and String(shown[0].text).contains(chunks[1] if chunks.size() > 1 else "?") and tut._notes_i == 1
	tut._close_notes()
	ok = ok and chunk_ok and in_order and page2_ok
	report.append("long squawk (7 sentences): %d squawk pages %s, three or fewer each %s, in order %s, page 2 shows the next chunk %s" % [chunks.size(), chunks.size() == 3, chunk_ok, in_order, page2_ok])
	g.current_job = null
	print("squawk pages: ", "; ".join(report))
	return ok

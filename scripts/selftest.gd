extends Node
## The game's self-test: plays a whole rescue through the real code paths (travel, inspect,
## run-up, every work scene bolt by bolt, save/load, the ferry flight) and quits with 0 on
## pass, 1 on fail.  godot --path . -- --self-test [--all-faults] [--city=X] [--seed=N] [--shot=prefix]
## --all-fields flies a forced landing at every field instead: run it before a release.
## Started by main.gd; `g` is the running game.

const Work := preload("res://scripts/work.gd")
const Ferry := preload("res://scripts/ferry.gd")
const Updater := preload("res://scripts/updater.gd")

var g  # main.gd


var _trip_volume := -80.0
var _trip_saved_at := ""
var _quit_open := false  # the pause menu offered a way out during an emergency


func run(main, args: PackedStringArray) -> void:
	g = main
	var shot = ""
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	if "--all-fields" in args:
		var fields_ok: bool = await _all_fields()
		print("ALL-FIELDS ", "PASS" if fields_ok else "FAIL", " seed=", g.test_seed)
		get_tree().quit(0 if fields_ok else 1)
		return
	var edges_ok: bool = _edge_tests() and _torque_test() and _faults_test() and Work.spin_dir("tight") < 0.0 and Work.spin_dir("loose") > 0.0 and Work.spin_dir("snug") > 0.0
	var job: Dictionary = g.jobs[0]
	if "--all-faults" in args:  # every broken part on one plane, for screenshots
		job.faults = g.FAULTS.keys()
		job.years = 9  # a long-sat plane: grime, stale fuel, dry engine, stuck door
		job.washed = false
	for a in args:
		if a.begins_with("--city="):  # pick the field, e.g. a plains town to see trees
			job.city = a.trim_prefix("--city=")
	var start = g.money
	job.deadline = g.day + 30  # don't let a long test trip expire the job
	while not g._warming.is_empty():  # a player spends this on the title screen
		await get_tree().process_frame
	var trip_start := Time.get_ticks_msec()
	_trip_probe()
	await g._travel(job, 0)
	var trip_ms := Time.get_ticks_msec() - trip_start
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
		g._show_loading("Flying to Omaha", "264 NM, about 0.4 days on the road and in the air.\nThe owner: " + g._symptoms(job), "Dallas", "Omaha")
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
	g._pocket("wallet")
	var pockets_ok = g.panel != null and g.panel_kind == "wallet"
	await _snap(shot, "wallet")
	g._pocket("logbook")
	await _snap(shot, "logbook")
	g._pocket("logbook")  # same key again puts it away
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
	pockets_ok = pockets_ok and g.panel is Work and job.found.is_empty() and g.panel.solve() and g.panel is PanelContainer
	await _snap(shot, "inspect")
	var ok: bool = pockets_ok and radio_ok and marks_ok and (job.found.size() < job.faults.size() or job.faults.all(func(id): return g.FAULTS[id].zone == first_zone))
	for z in g.ZONES:
		g._inspect_zone(z)
		if g.panel is Work:
			ok = ok and g.panel.solve()
	# The walk-around finds what you can see; the rest only shows on a run-up.
	ok = ok and job.checked.size() == g.ZONES.size() and job.faults.all(func(id): return job.found.has(id) != (id in g.RUNUP_FAULTS))
	g._run_up()
	# A clean start hears every run-up fault; a dead battery or starter cuts the test short.
	ok = ok and job.faults.filter(func(id): return id in g.RUNUP_FAULTS).all(func(id):
		return job.found.has(id) or job.runup == "dead")
	if job.faults.has("battery"):
		ok = ok and job.runup == "dead"  # dead battery: nothing to hear past the master switch
	# Save, scramble, load: everything comes back and the job here is still the one you're on.
	g._save_game()
	var before = [g.money, g.day, g.jobs.size(), g.current_job.city, g.current_job.checked.size()]
	g.money = -999
	g.current_job = null
	g.jobs = []
	var loaded = g._load_game()
	ok = ok and loaded and [g.money, g.day, g.jobs.size(), g.current_job.city, g.current_job.checked.size()] == before \
		and g.jobs.has(g.current_job)
	job = g.current_job  # the loaded copy is the live one now
	# A write that failed partway (full disk) never replaces the good save.
	var bad_tmp = FileAccess.open(g.save_path + ".tmp", FileAccess.WRITE)
	bad_tmp.store_string("not a save")
	bad_tmp.close()
	var good_day = g._read_save(g.save_path).day
	ok = ok and not g._commit_save(g.save_path + ".tmp") and g._read_save(g.save_path).day == good_day \
		and not FileAccess.file_exists(g.save_path + ".tmp")
	# A torn write (garbage in the main file) falls back to the .bak copy.
	g._save_game()  # main = this state, .bak = the one before
	var torn = FileAccess.open(g.save_path, FileAccess.WRITE)
	torn.store_string("not a save")
	torn.close()
	ok = ok and g._load_game() and not g.save_locked
	job = g.current_job
	# A save from a newer game is left alone: not loaded, and never autosaved over.
	var newer_save = FileAccess.open(g.save_path, FileAccess.WRITE)
	newer_save.store_var({"version": g.SAVE_VERSION + 1, "money": 1})
	newer_save.close()
	DirAccess.remove_absolute(g.save_path + ".bak")
	var money_before = g.money
	ok = ok and not g._load_game() and g.save_locked and g.money == money_before
	g._save_game()
	ok = ok and int(g._read_save(g.save_path).version) == g.SAVE_VERSION + 1  # still the newer file
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
	var id0: String = job.faults[0]
	g.tools.clear()
	g._repair(id0)
	ok = ok and g.panel is Work
	await _snap(shot, "work_" + id0)
	ok = ok and not g.panel.solve() and not job.fixed.has(id0)
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
	if w.st[f0.id] != "loose":
		print("MOUSE HOLD did not loosen ", f0.id, ": ", w.st[f0.id], " hover=", w.hover, " hold=", w.hold, " pressing=", w.pressing, " held_done=", w.held_done, " tool=", w.tool, " action=", w.action(f0))
	if g.FAULTS[id0].part != "":
		g.inventory.erase(g.FAULTS[id0].part)
		ok = ok and not g.panel.solve() and not job.fixed.has(id0)
		await _snap(shot, "work_apart")
	# Out of a material (here cotter pins / safety wire / penetrant): the job stalls at that step.
	var uses_any: bool = g.panel.els.any(func(e): return e.get("uses", "") != "")
	if uses_any:
		if g.FAULTS[id0].part != "":
			g.inventory[g.FAULTS[id0].part] = 1
		for mtl in ["Safety wire", "Cotter pin", "Penetrant"]:
			g.inventory[mtl] = 0
		ok = ok and not g.panel.solve() and not job.fixed.has(id0)
	for mtl in ["Safety wire", "Cotter pin", "Penetrant"]:
		g.inventory[mtl] = 99
	for id in job.faults:
		var part: String = g.FAULTS[id].part
		if part != "":
			g.inventory[part] = 1
		if id != id0:
			g._repair(id)
			await _snap(shot, "work_" + id, 0.1)
			if id == "tmp_strut":
				var tw = g.panel
				tw.show_diagram = true
				tw.queue_redraw()
				await _snap(shot, "diagram", 0.1)
				tw.show_diagram = false
				tw.st.panel = "off"
				tw.st.part_f0 = "snug"
				tw.tool = "torque"
				tw.hover = "part_f0"
				tw.needle = 62.0
				tw.green = 0.6
				tw.set_process(false)
				tw.queue_redraw()
				await _snap(shot, "torque", 0.1)
				tw.set_process(true)
				tw.st.panel = "on"
				tw.st.part_f0 = "tight"
		var solved: bool = g.panel.solve()
		ok = ok and solved and job.fixed.has(id)
		if not solved:
			print("WORK STUCK on ", id)
	g._start_runup()  # everything fixed: in the cockpit, 1700 rpm, each mag, and it runs clean
	var rf = g.ferry
	var runup_ok: bool = rf != null and rf.mode == "runup" and rf.no_start == ""
	if rf:
		rf.state = "run"
		rf.throttle = (rf.RUNUP_RPM - 650.0) / 1700.0
		for step in [[1, false], [2, false], [3, true], [3, false]]:
			rf.mags = step[0]
			rf.carb_heat = step[1]
			rf._mag_t = 0.0
			for i in 120:
				rf._process(1.0 / 60.0)
		runup_ok = runup_ok and rf._seen == [rf.drops.x, rf.drops.y, rf.carb_drop] and rf.drops.x < 150 and rf.drops.y > 0 and rf.carb_drop > 0
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
	# Fuel truck: low tanks block the take-off until it's fueled.
	job.fuel = 0.1
	var fuel_cost: int = g._fuel_plane()
	ok = ok and fuel_cost > 0 and job.fuel == 1.0
	start -= fuel_cost
	if shot != "":
		g._open_truck()
		await _snap(shot, "fuel_truck_panel")
		g.inventory["Brake disc"] = 1
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
	# Fly it out for real: hold throttle, pull back once past rotate speed.
	g._start_ferry()
	ok = ok and g.ferry == null  # an unsigned logbook keeps it on the ground
	g._open_signoff()
	await _snap(shot, "signoff")
	g._sign_logbook()
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
	ok = await _start_failures() and ok
	await _snap(shot, "engine_log", 0.1)
	var before_fly: int = g.money  # rent has come out day by day since the start; the pay lands on top
	await _fly(true, shot)
	ok = ok and g.ferry == null and g.rescued == 1 and g.money == before_fly + job.reward and g.money < start + job.reward and g.jobs.size() == g.MAX_JOBS
	# The ending and game-over screens both leave a way out and can't be closed by accident.
	var rescued_now = g.rescued
	g.rescued = g.GOAL
	g._after_flight()
	await _snap(shot, "ending")
	ok = ok and g.panel != null and not g.panel_closable
	g.rescued = rescued_now
	g._open_game_over(500)
	var was := [g.money, g.day, g.jobs.duplicate(true)]
	g._odd_jobs()  # broke is a setback: a few days' odd jobs pay for the next flight
	ok = ok and g.money > was[0] and g.panel == null
	g.money = was[0]
	g.day = was[1]
	g.jobs = was[2]
	g._open_game_over(500)
	await _snap(shot, "game_over")
	ok = ok and g.panel != null and not g.panel_closable
	g._open_travel()
	ok = ok and g.logbook.size() == 1 and g.logbook[0].has("parts")  # the cost sheet was written
	if shot != "":
		g._pocket("logbook")
		await _snap(shot, "logbook_after")
	ok = await _trouble_tests(shot) and ok
	ok = await _leak_test() and ok and trip_ok and g._warming.is_empty() and g._kept.size() > 50  # assets stayed loaded
	if overflow != "":
		print("PANEL OVERFLOW: ", overflow)
		ok = false
	print("SELF-TEST ", "PASS" if ok and edges_ok else "FAIL", " edges=", edges_ok, " city=", job.city, " seed=", g.test_seed, " faults=", job.faults, " day=%.1f" % g.day)
	get_tree().quit(0 if ok else 1)


var overflow := ""


## Opens and closes every sheet 500 times: nodes must come back to where they started.
func _leak_test() -> bool:
	g._close_panel()
	await get_tree().process_frame
	await get_tree().process_frame
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var mem = Performance.get_monitor(Performance.MEMORY_STATIC)
	var opens: Array[Callable] = [g._open_wallet, g._open_logbook, g._open_shop, g._open_toolbox, g._open_travel, g._open_pause]
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
			"signed": true, "parked": "apron", "reward": 4000, "deadline": g.day + 30}, true)
		g._load_field(city, j)
		await _fly(true)
		var landed: bool = g.ferry == null and g.current_job == j and j.found.has("oil_leak")
		g._close_panel()
		# And nothing wrong at all: a clean take-off has to clear the land around every strip.
		j = g.jobs[0]
		j.merge({"faults": [], "fixed": {}, "found": {}, "checked": {}, "work": {}, "runup": "ran", "fuel": 1.0, "washed": true,
			"signed": true, "parked": "apron", "reward": 4000, "deadline": g.day + 30}, true)
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
		"signed": true, "parked": "apron", "reward": 4000, "deadline": g.day + 30}, true)
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
		"signed": true, "parked": "apron", "reward": 4000, "deadline": g.day + 30}, true)
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
	var t0 = Time.get_ticks_msec()
	while g.ferry and Time.get_ticks_msec() - t0 < 6000:
		await get_tree().process_frame
	ok = ok and g.ferry == null and g.current_job == null and not g.jobs.has(k) and g.logbook.back().work[0].contains("rising ground")
	g._close_panel()
	print("trouble tests ", ok)
	return ok


## Every way the start can go wrong, for real, then none of them.
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
	f.throttle = 1.0
	await _crank(3.3)
	ok = ok and f.flood <= 0.0  # cleared with the throttle open
	f.primes = 0
	f.throttle = 0.1
	await _crank(2.2)
	ok = ok and f.state == "hung"  # no prime: hung start
	var t0 = Time.get_ticks_msec()
	while f.state == "hung" and Time.get_ticks_msec() - t0 < 7000:
		await get_tree().process_frame
	ok = ok and f.state == "off"  # left alone, it dies
	f.primes = 1
	await _crank(2.2)
	f.throttle = 0.2
	t0 = Time.get_ticks_msec()
	while f.state == "hung" and Time.get_ticks_msec() - t0 < 3000:
		await get_tree().process_frame
	ok = ok and f.state == "run"  # a touch of throttle saves it
	print("start failures ", ok)
	return ok


func _crank(seconds: float) -> void:
	g.ferry._crank_total = 0.0  # the starter-rest limit has its own check below
	g.ferry._cool = 0.0
	Input.action_press("starter")
	var t0 = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < seconds * 1000.0 and g.ferry.state == "off":
		await get_tree().process_frame
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
	while g.ferry and Time.get_ticks_msec() - t0 < 40000:
		var f = g.ferry
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
	print("flight at %s: %.0f fps, worst frame %.0f ms" % [g.location, frames * 1000.0 / maxf(1.0, Time.get_ticks_msec() - t0), worst])


## Money and deadline edges, run at home before the main test; restores what it touches.
func _edge_tests() -> bool:
	var saved = [g.money, g.jobs, g.current_job, g.day]
	var fake = func(id: String, deadline: float) -> Dictionary:
		return {"city": g.location, "type": "Test", "faults": [id], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0, "deadline": deadline}
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
		g.current_job = fake.call(id, g.day + 30)
		g.money = g.FAULTS[id].cost
		g._open_travel()
		ok = ok and g.panel != null and not g.panel_closable  # the game-over panel can't be closed
		g._close_panel()
	# 1b. Part in hand but no ratchet and no money: the tool blocks the repair, so it's game
	#     over, not a dead end. With every tool and enough wire it's finishable.
	var saved_tools = g.tools
	var saved_inv = g.inventory
	g.jobs = []
	g.current_job = fake.call("propeller", g.day + 30)
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
	# 2. The owner's deadline passes during an inspection: the job is dropped cleanly.
	g.jobs = [fake.call("tire", g.day + 0.01)]
	g.current_job = g.jobs[0]
	g._inspect_zone("gear_l")
	ok = ok and g.current_job == null and g.panel == null  # before the fix this line ran after a script error
	# 3. Look-alikes: a bad magneto reads like fouled plugs. Swapping the plugs is spent, the next
	#    run-up shows no change, and the magneto is left as the one answer.
	g.current_job = fake.call("magneto", g.day + 30)
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
	g.current_job = fake.call("p_lead", g.day + 30)
	g.current_job.faults.append("carb_heat")
	g.current_job.merge({"tried": {}, "washed": true}, true)
	g.jobs = [g.current_job]
	g._run_up()
	mj = g.current_job
	ok = ok and mj.found.has("p_lead") and mj.found.has("carb_heat") and g.mag_drops(mj).y == 0 and g.carb_drop(mj) == 0
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
	g.day = saved[3]
	return ok


## Every fault row can be played: the keys the game reads, a real zone, a clue. And one with no
## scene of its own gets the access-panel one, with torqued bolts if its row gives a range.
func _faults_test() -> bool:
	var ok := true
	for id in g.FAULTS:
		var f: Dictionary = g.FAULTS[id]
		if not f.has_all(["name", "part", "cost", "zone", "symptom"]) or not g.ZONES.has(f.get("zone", "")) or not g.CLUES.has(id):
			print("FAULT ", id, ": needs name, part, cost, zone (one of main.ZONES), symptom, and a CLUES line")
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
	g.current_job = {"city": g.location, "type": "Test", "faults": ["propeller"], "fixed": {}, "found": {}, "checked": {}, "work": {}, "reward": 0, "deadline": g.day + 30}
	g.tools = {"ratchet": true, "torque": true}
	g._repair("propeller")
	var w = g.panel
	var bolt: Dictionary = w.els.filter(func(e): return e.get("torque", false))[0]
	w.st.spinner = "off"  # the bolts are under the spinner and the safety wire
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

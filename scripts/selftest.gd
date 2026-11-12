extends Node
## The game's self-test: plays a whole rescue through the real code paths (travel, inspect,
## run-up, every work scene bolt by bolt, save/load, the ferry flight) and quits with 0 on
## pass, 1 on fail.  godot --path . -- --self-test [--all-faults] [--city=X] [--shot=prefix]
## Started by main.gd; `g` is the running game.

const Work := preload("res://scripts/work.gd")
const Ferry := preload("res://scripts/ferry.gd")
const Updater := preload("res://scripts/updater.gd")

var g  # main.gd


func run(main, args: PackedStringArray) -> void:
	g = main
	var shot = ""
	for a in args:
		if a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
	for a in args:
		if a.begins_with("--scene-shots="):  # every work scene at its start and part-way, for checking art placement
			await _scene_shots(a.trim_prefix("--scene-shots="))
			get_tree().quit(0)
			return
	var edges_ok = _edge_tests()
	var scenes_ok = _scene_tests()
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
	for a in args:
		if a.begins_with("--city="):  # pick the field, e.g. a plains town to see trees
			job.city = a.trim_prefix("--city=")
	var start = g.money
	job.deadline = g.day + 30  # don't let a long test trip expire the job
	await g._travel(job, 0)
	await _snap(shot, "broken", 1.5)
	if shot != "":  # title screen and the travel card
		g._open_menu()
		await _snap(shot, "menu")
		g._close_menu()
		g._show_loading("Flying to Omaha", "264 NM, about 0.4 days on the road and in the air.")
		await _snap(shot, "loading")
		g._hide_loading()
	if shot != "":  # wheels close up, while any flat tire is still flat
		for v in [["gear", Vector3(2.2, 0.1, 4.6), Vector3(0, 0, 7.1)], ["gear_l", Vector3(2.2, 0.1, 11.4), Vector3(0, 0, 8.9)],
				["gear_front", Vector3(-7.5, 0.1, 8.6), Vector3(0, 0, 8)], ["tail", Vector3(8.5, 0.1, 5.0), Vector3(5, 0, 8)],
				["side", Vector3(1.5, 0.1, 1.0), Vector3(1.5, 0, 8)]]:
			g.player.position = v[1]
			g.player.look_at(Vector3(v[2].x, g.player.position.y, v[2].z), Vector3.UP)
			g.player.cam.rotation.x = -0.35
			await _snap(shot, v[0])
		g._load_field(g.location, job)
	g._open_travel()
	await _snap(shot, "radio")
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
	g._inspect_zone(first_zone)  # one spot: the work order shows only what that spot revealed
	await _snap(shot, "inspect")
	var ok: bool = pockets_ok and (job.found.size() < job.faults.size() or job.faults.all(func(id): return g.FAULTS[id].zone == first_zone))
	for z in g.ZONES:
		g._inspect_zone(z)
	# The walk-around finds what you can see; the rest shows on a run-up or in troubleshooting.
	ok = ok and job.checked.size() == g.ZONES.size() and job.faults.all(func(id): return job.found.has(id) == (g._how(job, id) == "walk"))
	_chk(ok, 68)
	_run_up()
	# A clean start hears every run-up fault; a dead battery or starter cuts the test short.
	ok = ok and job.faults.filter(func(id): return g._how(job, id) == "runup").all(func(id):
		return job.found.has(id) or job.runup == "dead")
	_chk(ok, 72)
	if job.faults.has("battery") and not job.faults.any(func(id): return id in ["door_pin", "pre_oil", "storage"]):
		ok = ok and job.runup == "ran" and job.found.has("battery")  # flat battery: you hand-prop it
		_chk(ok, 75)
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
	g._open_shop()
	await _snap(shot, "shop")
	# Work scenes: with no tools nothing comes apart; with tools but no part it stalls at the
	# empty slot; with both, the whole job gets done bolt by bolt.
	# A job whose first fixable scene has bolts to turn (a few, like weight and balance, need no tools).
	var bolted: Array = job.faults.filter(func(id): return Work.scenes()[id].els.any(func(e): return e.type == "fastener" \
		and Work.scenes()[id].els.any(func(h): return h.id == e.host and h.get("needs", []).is_empty() and h.get("start", "on") == "on")))
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
	mv.position = w._origin() + f0.pos
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
	Input.action_press("move_forward")
	await _snap(shot, "cockpit", 1.0)
	var t0 = Time.get_ticks_msec()
	while g.ferry and Time.get_ticks_msec() - t0 < 30000:
		if g.ferry.speed >= Ferry.ROTATE:
			Input.action_press("move_back")
		if shot != "" and g.ferry.alt > 8 and not FileAccess.file_exists(shot + "_climb.png"):
			await _snap(shot, "climb", 0.0)
		await get_tree().process_frame
	Input.action_release("move_forward")
	Input.action_release("move_back")
	ok = ok and g.ferry == null and g.rescued == 1 and g.money == start + job.reward and g.jobs.size() == g.MAX_JOBS
	_chk(ok, 275)
	ok = ok and g.logbook.size() == 1 and g.logbook[0].has("parts")  # the cost sheet was written
	_chk(ok, 276)
	if shot != "":
		g._pocket("logbook")
		await _snap(shot, "logbook_after")
	print("SELF-TEST ", "PASS" if ok and edges_ok and scenes_ok else "FAIL", " edges=", edges_ok, " scenes=", scenes_ok, " faults=", job.faults, " day=%.1f" % g.day)
	get_tree().quit(0 if ok and edges_ok and scenes_ok else 1)


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
	ok = ok and g._can_finish_here()
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
	g.money = saved[0]
	g.jobs = saved[1]
	g.current_job = saved[2]
	g.day = saved[3]
	return ok


func _snap(prefix: String, name: String, wait := 0.4) -> void:
	if prefix == "":
		return
	await get_tree().create_timer(wait).timeout
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [prefix, name])


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
	g._call(id, wrong[0][1])
	var stayed: bool = g._test_for(job, id) == t and job.get("dstep", {}).get(id, 0) == step
	g._call(id, right)
	return stayed and g._test_for(job, id) != t


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
	var saved = [g.money, g.jobs, g.current_job, g.day, g.tools, g.inventory]
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
			"reward": 1000, "deadline": g.day + 60, "spent": {"fuel": 0, "parts": 0, "mail": 0}}
		g._assign_faults(j, faults)
		g.jobs = [j]
		g.current_job = j
		return j
	for scene in Work.scenes():
		if scene in g.TESTS:
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
				var d0: float = g.day
				ok = ok and w.perform(traps[0], "do") and w.st[traps[0].id] == "todo" and g.day > d0
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
	g.logbook.resize(logs)
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
	g.money = saved[0]
	g.jobs = saved[1]
	g.current_job = saved[2]
	g.day = saved[3]
	g.tools = saved[4]
	g.inventory = saved[5]
	if not ok:
		print("SCENE TESTS FAILED")
	return ok


var _said := false


func _chk(ok: bool, where: int) -> void:
	if not ok and not _said:
		_said = true
		print("FIRST FAILED CHECK at run() line ", where)


## Screenshots of every work scene: fresh, and with the job worked halfway.
func _scene_shots(prefix: String) -> void:
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
		var j := {"city": g.location, "type": "Test", "faults": [], "fixed": {}, "found": {}, "checked": {}, "work": {},
			"reward": 1000, "deadline": g.day + 60, "spent": {"fuel": 0, "parts": 0, "mail": 0}}
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

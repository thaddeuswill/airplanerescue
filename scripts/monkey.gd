extends Node
## Monkey test: mashes random keys and clicks to shake out crashes and soft-locks.
##   godot --path . -- --monkey [--monkey-min=60] [--monkey-seed=123]
## Never in a normal game: main.gd only adds it for --monkey, and that mode swaps in a throwaway
## save and blocks quitting, updates and settings writes. Every input goes to user://monkey_log.txt
## and is flushed each frame, so after a crash the last lines are the repro steps. Same seed, same
## inputs. Also logs: stuck (no change in 60 s), low FPS, and memory once a minute.

const KEYS := [KEY_W, KEY_A, KEY_S, KEY_D, KEY_E, KEY_SPACE, KEY_ESCAPE, KEY_TAB, KEY_J, KEY_L, KEY_UP, KEY_DOWN, KEY_ENTER,
	KEY_F, KEY_M, KEY_P, KEY_I, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_Q, KEY_V]
const STUCK_AFTER := 60.0  # seconds with no change in anything the player can affect
const REPORT_EVERY := 60.0

var log_file: FileAccess
var minutes := 10.0
var rng := RandomNumberGenerator.new()
var recent: Array[String] = []
var held := {}
var stuck_t := 0.0
var last_state := ""
var report_t := 0.0
var low_fps_t := 0.0
var started := 0
var counts := {"inputs": 0, "stuck": 0, "low_fps": 0}
var seen := {}  # screens the monkey has reached


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.seed = Time.get_ticks_usec()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--monkey-min="):
			minutes = a.trim_prefix("--monkey-min=").to_float()
		elif a.begins_with("--monkey-seed="):
			rng.seed = a.trim_prefix("--monkey-seed=").to_int()
	log_file = FileAccess.open("user://monkey_log.txt", FileAccess.WRITE)
	started = Time.get_ticks_msec()
	_log("START seed=%d minutes=%.1f" % [rng.seed, minutes])


func _log(line: String) -> void:
	log_file.store_line("%d %s" % [Time.get_ticks_msec() - started, line])
	log_file.flush()


func _key(code: int, down: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = down
	Input.parse_input_event(ev)
	held[code] = down
	_note("key %s %s" % [OS.get_keycode_string(code), "down" if down else "up"])


func _click() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	var at := Vector2(rng.randf() * size.x, rng.randf() * size.y)
	var buttons := get_tree().root.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree() and not b.disabled)
	if buttons.size() > 0 and rng.randf() < 0.7:  # mostly aim at something real, or it rarely gets past a screen
		var b: Button = buttons[rng.randi() % buttons.size()]
		at = b.get_global_rect().get_center()
		_note("button '%s'" % b.text)
	var hold := rng.randf() < 0.4  # repair steps need the mouse held
	for down in ([true] if hold else [true, false]):
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = at
		ev.global_position = at
		ev.pressed = down
		Input.parse_input_event(ev)
	held[-1] = hold
	_note("click %d,%d%s" % [at.x, at.y, " hold" if hold else ""])


func _release_mouse() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	Input.parse_input_event(ev)
	held[-1] = false


func _note(line: String) -> void:
	counts.inputs += 1
	recent.append(line)
	if recent.size() > 10:
		recent.pop_front()
	_log(line)


func _physics_process(_delta: float) -> void:
	if rng.randf() < 0.2:
		_key(KEYS[rng.randi() % KEYS.size()], true)
	for code in held.keys():
		if code != -1 and held[code] and rng.randf() < 0.1:
			_key(code, false)
	if rng.randf() < 0.08:
		_click()
	if held.get(-1, false) and rng.randf() < 0.03:
		_release_mouse()
	if rng.randf() < 0.3:
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(rng.randf_range(-30, 30), rng.randf_range(-10, 10))
		ev.position = get_viewport().get_visible_rect().size * Vector2(rng.randf(), rng.randf())
		Input.parse_input_event(ev)


## Random walking rarely finds the radio or the plane, so every few seconds it jumps somewhere.
func _visit(g) -> void:
	if g.ferry and g.ferry.state != "run" and not get_tree().paused:  # random keys rarely start it
		_note("visit leave cockpit")
		g._open_pause()
		g._leave_cockpit()
		return
	if g.ferry or is_instance_valid(g._loader) or get_tree().paused:
		return
	if g.panel_kind == "menu":
		g._close_menu()
		return
	var j = g.current_job
	var picks := ["shop", "toolbox", "travel", "radio"]
	if not j and g.jobs.size() > 0:
		picks += ["job", "job", "job", "job"]
	if j:
		picks += ["zone", "zone", "repair", "repair", "repair", "runup", "sign", "fly", "truck", "hangar"]
	var pick: String = picks[rng.randi() % picks.size()]
	_note("visit " + pick)
	match pick:
		"job": g._travel(g.jobs[rng.randi() % g.jobs.size()], 0)
		"shop": g._open_shop()
		"toolbox": g._open_toolbox()
		"travel": g._open_travel()
		"radio": g._open_radio()
		"truck": g._open_truck()
		"hangar": g._toggle_parked()
		"zone": g._inspect_zone(g.ZONES.keys()[rng.randi() % g.ZONES.size()])
		"repair": g._repair(j.faults[rng.randi() % j.faults.size()])
		"runup": g._run_up()
		"sign": g._sign_logbook()
		"fly":
			g._close_panel()
			g._start_ferry()


func _process(delta: float) -> void:
	var g = get_tree().current_scene
	if g == null or not g.has_method("_objective"):
		return
	if rng.randf() < 0.004:
		_visit(g)
	var screen: String = "ferry" if g.ferry else g.panel_kind if g.panel_kind != "" else g._list_title if g.panel is PanelContainer else "work" if g.panel else "walking"
	if not seen.has(screen):
		seen[screen] = true
		_log("SCREEN %s" % screen)
	_watch_stuck(g, delta, screen)
	_watch_speed(delta)
	if (Time.get_ticks_msec() - started) / 60000.0 >= minutes:
		_log("DONE inputs=%d stuck=%d low_fps=%d screens=%s" % [counts.inputs, counts.stuck, counts.low_fps, ",".join(seen.keys())])
		print("MONKEY DONE inputs=%d stuck=%d low_fps=%d screens=%d" % [counts.inputs, counts.stuck, counts.low_fps, seen.size()])
		get_tree().quit()


## A soft-lock: nothing the player can affect has changed for a minute, despite constant input.
func _watch_stuck(g, delta: float, screen: String) -> void:
	var pos: Vector3 = g.player.global_position
	var state := "%s %d %d %d %.3f %d" % [screen, roundi(pos.x), roundi(pos.z), g.money, g.day, g.rescued]
	if g.ferry:
		state += " %s %d" % [g.ferry.state, g.ferry.speed]
	stuck_t = 0.0 if state != last_state else stuck_t + delta
	last_state = state
	if stuck_t >= STUCK_AFTER:
		stuck_t = 0.0
		counts.stuck += 1
		_log("STUCK %s at %s, last inputs: %s" % [screen, pos, " | ".join(recent)])
		print("STUCK on %s" % screen)


func _watch_speed(delta: float) -> void:
	var fps := Engine.get_frames_per_second()
	low_fps_t -= delta
	if fps < 30 and low_fps_t <= 0.0 and not DisplayServer.get_name() == "headless":
		low_fps_t = 5.0
		counts.low_fps += 1
		_log("LOW FPS %d" % fps)
	report_t += delta
	if report_t >= REPORT_EVERY:
		report_t = 0.0
		_log("MEMORY %d MB, %d nodes, %d fps" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), fps])

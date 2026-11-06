extends Node
## Ferry flight, from the cockpit. Start the engine yourself: fuel on, master on, prime it, crack
## the throttle, mags to both, hold the starter. Get that wrong and it won't catch: no fuel, no
## spark, flooded (clear it with the throttle open), or a hung start (catches, hangs at low rpm and
## dies unless you ease in throttle). Then fly it: W/S throttle, A/D rudder against the swing,
## Down arrow to rotate at 55 kt. Emits `finished` once climbing out.
## A fault you never found (`trouble`) strikes on the roll, or in the climb, where you lose the
## engine: Up arrow lowers the nose, Down flares. Emits `failed` with "abort", "landed" or "crash".

signal finished
signal failed(result: String)

const LINE_UP_X := 70.0    # runway runs along X at z=20; the plane points -X down it
const RUNWAY_END_X := -78.0
const RUNWAY_Z := 20.0
const HALF_WIDTH := 6.5    # meters of asphalt each side of the centerline
const ROTATE := 28.0       # m/s, about 55 knots
const TOP_SPEED := 42.0
const DONE_ALT := 35.0     # meters climbed before the job counts as delivered
const TROUBLE_ROLL := 15.0  # m/s: a bad tire or brake shows itself here
const TROUBLE_ALT := 20.0  # meters: everything else waits until you're committed
const STALL := 20.0        # m/s, about 39 knots: the nose drops on its own below this
const SAFE_SINK := 3.5     # m/s at touchdown, the most the gear can take
const MAGS := ["OFF", "LEFT", "RIGHT", "BOTH"]
const CATCH_AFTER := 1.6   # seconds of cranking before it fires or doesn't
const STARTER_LIMIT := 8.0  # seconds of cranking before the starter needs a rest

var main
var plane: Node3D
var prop: Node3D
var cam: Camera3D
var speed := 0.0
var pitch := 0.0
var alt := 0.0
var yaw := 0.0  # + is left of the runway heading
var z_off := 0.0
var done := false
var trouble := ""  # the fault id you flew with, or ""
var struck := false
var _result := ""
var _end_t := 0.0
var _bank := 0.0

var state := "off"  # off, hung, run
var fuel_on := false
var master := false
var mags := 0
var primes := 0
var flood := 0.0  # seconds of cranking with the throttle open left to clear it
var throttle := 0.0
var rpm := 0.0
var _crank_t := 0.0
var _crank_total := 0.0
var _cool := 0.0
var _hang_t := 0.0
var _judged := false  # this press of the starter has had its result


func start(m, p: Node3D, prop_node: Node3D) -> void:
	main = m
	plane = p
	prop = prop_node
	cam = Camera3D.new()
	cam.fov = 70
	# Seated eye in the back seat (Cubs fly solo from there): cushion top 1.33 m, roof 1.89 m.
	cam.position = Vector3(0, 1.62, 0.85)
	cam.rotation.x = -0.1
	plane.add_child(cam)
	cam.make_current()
	_line_up()


func _line_up() -> void:
	speed = 0.0
	pitch = main.SIT_PITCH
	alt = 0.0
	yaw = 0.0
	z_off = 0.0
	throttle = minf(throttle, 0.1)
	plane.position = Vector3(LINE_UP_X, main.MAIN_Z * sin(pitch), RUNWAY_Z)
	plane.rotation = Vector3(pitch, PI / 2, 0)


func toggle_fuel() -> void:
	fuel_on = not fuel_on
	main.sound.sfx("latch")


func toggle_master() -> void:
	master = not master
	main.sound.sfx("click")


func prime() -> void:
	primes += 1
	main.sound.sfx("thread")


func next_mags() -> void:
	mags = (mags + 1) % MAGS.size()
	main.sound.sfx("click")
	if mags == 0 and state != "off":
		_die("Mags off. The engine winds down.")


func _unhandled_input(e: InputEvent) -> void:
	if done or _result != "":
		return
	if e.is_action_pressed("fuel_valve"):
		toggle_fuel()
	elif e.is_action_pressed("master"):
		toggle_master()
	elif e.is_action_pressed("primer"):
		prime()
	elif e.is_action_pressed("mags"):
		next_mags()


## The card on screen until the engine is running.
func checklist() -> String:
	var box := func(on: bool) -> String: return "[x]" if on else "[  ]"
	return "BEFORE START\n%s  F  Fuel: %s\n%s  M  Master: %s\n%s  P  Prime 2-5 strokes: %d\n%s  W/S  Throttle cracked: %d%%\n%s  I  Mags: %s\nHold SPACE: starter" % [
		box.call(fuel_on), "ON" if fuel_on else "OFF", box.call(master), "ON" if master else "OFF", box.call(primes >= 2 and primes <= 5), primes,
		box.call(throttle >= 0.05 and throttle <= 0.4), roundi(throttle * 100), box.call(mags == 3), MAGS[mags]]


func _process(delta: float) -> void:
	if _result != "":
		_roll_out(delta)
		return
	if done:
		return
	throttle = clampf(throttle + Input.get_axis("throttle_down", "throttle_up") * 0.6 * delta, 0.0, 1.0)
	if state != "run":
		_starting(delta)
		_spin(delta)
		main.update_gauges(0.0, 0.0, rpm)
		return
	if struck:
		_forced_landing(delta)
		return
	_fly(delta)


func _spin(delta: float) -> void:
	if is_instance_valid(prop):
		prop.rotate_object_local(Vector3.FORWARD, rpm * 0.03 * delta)


## Everything before the engine runs: the starter, and how the start goes wrong.
func _starting(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	if state == "hung":
		_hung(delta)
		return
	var cranking := Input.is_action_pressed("starter")
	if not cranking:
		main.sound.stop_loop()
		main.sound.engine = 0.0
		rpm = move_toward(rpm, 0.0, 400.0 * delta)
		_crank_t = 0.0
		_crank_total = maxf(0.0, _crank_total - delta * 0.5)
		_judged = false
		main.log_live("Starter hot: give it %d more seconds" % ceili(_cool) if _cool > 0.0 else "")
		return
	if _cool > 0.0:
		return
	if not master:
		if not _judged:
			_judged = true
			main.sound.sfx("deny")
			main.log_line("Nothing. The master switch is off.")
		return
	main.sound.loop("crank")
	main.sound.engine = 0.12
	rpm = 180.0
	_crank_t += delta
	_crank_total += delta
	main.log_live("Cranking...")
	if _crank_total >= STARTER_LIMIT:
		_cool = 6.0
		_crank_total = 0.0
		main.sound.stop_loop()
		main.log_line("That's enough cranking. Let the starter cool before you burn it out.")
		return
	if flood > 0.0:
		if throttle >= 0.7:
			flood -= delta
			if flood <= 0.0:
				primes = 2
				_judged = true  # let go of the starter before the next try
				main.log_line("That's cleared it. Close the throttle back down and try again.")
		return
	if _crank_t >= CATCH_AFTER and not _judged:
		_judged = true
		_attempt()


## What happens when the engine has turned over long enough to fire.
func _attempt() -> void:
	if not fuel_on:
		main.log_line("It turns over but never fires. No fuel getting to the carburetor.")
	elif mags == 0:
		main.log_line("It turns over but never fires. No spark: check the mags.")
	elif primes >= 6:
		flood = 3.0
		main.log_line("Wet and heavy, a strong smell of gas. It's flooded. Throttle wide open and crank to clear it.")
	elif primes < 2 or throttle < 0.05:
		state = "hung"
		_hang_t = 0.0
		main.sound.stop_loop()
		main.sound.sfx("crank")
		main.log_line("It catches, then hangs at 350 rpm and won't come up. Ease in some throttle!")
	else:
		_run("It fires and settles into a lumpy idle." if throttle <= 0.4 else "It catches and roars straight up. Way too much throttle: ease it back!")


## Hung start: barely running. The right touch of throttle saves it. Nothing, or too much, kills it.
func _hung(delta: float) -> void:
	_hang_t += delta
	rpm = 350.0 + sin(_hang_t * 11.0) * 60.0
	main.sound.engine = 0.14
	main.log_live("HUNG START  %d rpm\nThrottle to 12-35%%  (now %d%%)" % [rpm, throttle * 100])
	if throttle >= 0.12 and throttle <= 0.35 and _hang_t >= 1.0:
		_run("It picks up and runs. Nicely caught.")
	elif throttle > 0.5 or _hang_t >= 5.0:
		_die("It hung, coughed and died. More prime and a crack of throttle next time.")


func _run(text: String) -> void:
	state = "run"
	main.sound.stop_loop()
	main.sound.sfx("jack")
	main.log_live("")
	main.log_line(text)
	_judged = false


func _die(text: String) -> void:
	_judged = false
	state = "off"
	primes = 0
	main.sound.engine = 0.0
	main.sound.sfx("deny")
	main.log_live("")
	main.log_line(text)


func _fly(delta: float) -> void:
	var fwd := Input.is_action_pressed("stick_forward")
	var back := Input.is_action_pressed("stick_back")
	var rudder := Input.get_axis("rudder_right", "rudder_left")
	var one_mag := mags != 3
	var on_ground := alt < 0.05
	var on_grass := on_ground and absf(z_off) > HALF_WIDTH
	rpm = lerpf(rpm, (650.0 + throttle * 1700.0) * (0.93 if one_mag else 1.0), minf(1.0, delta * 3.0))
	var target := TOP_SPEED * throttle * (0.85 if one_mag else 1.0) * (0.55 if on_grass else 1.0)
	speed = move_toward(speed, target, (7.0 if target > speed else 3.0) * delta)
	if speed >= ROTATE and back:
		pitch = move_toward(pitch, 0.22, 0.3 * delta)
	elif on_ground:  # the tail lifts off its wheel as speed builds, sooner with the stick forward
		pitch = move_toward(pitch, main.SIT_PITCH * (1.0 - clampf(speed / (ROTATE * (0.55 if fwd else 0.8)), 0.0, 1.0)), 0.6 * delta)
	elif fwd:
		pitch = maxf(-0.02, pitch - 0.2 * delta)
	if speed >= ROTATE * 0.9:
		alt = maxf(0.0, alt + speed * sin(pitch) * delta)
	# Power swings a taildragger left. Only the rudder holds it, and it bites harder with speed.
	var bite := clampf(speed / ROTATE, 0.0, 1.0)
	var swing := throttle * maxf(bite, 0.15) * (0.12 if on_ground else 0.03)
	yaw = clampf(yaw + (swing + rudder * (0.12 + bite * 0.4)) * delta, -1.0, 1.0)
	yaw -= yaw * 0.6 * delta
	var along := speed * cos(pitch)
	plane.position.x -= along * cos(yaw) * delta
	z_off += along * sin(yaw) * delta
	plane.position.z = RUNWAY_Z + z_off
	plane.position.y = alt + main.MAIN_Z * sin(pitch)  # pitch pivots on the main tires
	_bank = lerpf(_bank, 0.0 if on_ground else -rudder * 0.08, minf(1.0, delta * 3.0))  # eases in: a stepped bank jerks the view
	plane.rotation = Vector3(pitch, PI / 2 + yaw, _bank)  # positive pitch raises the nose
	_spin(delta)
	main.sound.engine = clampf(rpm / 2350.0, 0.0, 1.0)
	main.update_gauges(speed, alt, rpm)
	if not on_ground and alt <= main.terrain.height(plane.position.x, plane.position.z):
		main._say("The ground came up faster than you did!")
		trouble = ""  # the report blames the hill, not a fault that hadn't struck yet
		_end("crash")
		return
	var kt := speed * 1.94
	var hint := "W: throttle up. A/D: rudder, hold the centerline."
	if on_grass:
		hint = "Off the runway! Rudder back to the asphalt."
	elif kt >= 55 and on_ground:
		hint = "55 kt: Down arrow to rotate."
	elif not on_ground:
		hint = "Climbing out..."
	elif kt > 15:
		hint = "Up arrow lifts the tail. A/D: rudder, she'll swing left."
	main.prompt.text = "%d kt     %d ft     %d rpm\n%s" % [kt, alt * 3.28, rpm, hint]
	if trouble != "":
		var t: Dictionary = main.TROUBLE[trouble]
		if t.roll and speed >= TROUBLE_ROLL:
			main._say(t.text)
			_end("abort")
			return
		if not t.roll and alt >= TROUBLE_ALT:
			struck = true
			main.sound.sfx("jack")
			main._say(t.text)
			return
	if on_ground and (absf(z_off) > 16.0 or absf(yaw) > 0.75):
		main._say("Ground loop! She got away from you. Taxi back and line up again.")
		_line_up()
	elif plane.position.x < RUNWAY_END_X and alt < 2.0:
		main._say("Ran out of runway! Lining up to try again.")
		_line_up()
	elif alt >= DONE_ALT:
		done = true
		main.sound.engine = 0.0
		finished.emit()


## No power. Trade height for speed, keep it flying, and flare just before the ground.
func _forced_landing(delta: float) -> void:
	var down := Input.is_action_pressed("stick_forward")
	var flare := Input.is_action_pressed("stick_back")
	pitch = clampf(pitch + ((-0.25 if down else 0.0) + (0.3 if flare else 0.0)) * delta, -0.3, 0.22)
	if speed < STALL:
		pitch = maxf(-0.3, pitch - 0.5 * delta)
	speed = clampf(speed + (-sin(pitch) * 9.8 - 1.2) * delta, 0.0, TOP_SPEED)
	alt += speed * sin(pitch) * delta
	plane.position.x -= speed * cos(pitch) * delta
	plane.position.y = alt + main.MAIN_Z * sin(pitch)
	plane.rotation = Vector3(pitch, PI / 2 + yaw, 0)
	rpm = move_toward(rpm, 500.0, 900.0 * delta)
	_spin(delta)
	main.sound.engine = 0.1 + 0.08 * sin(Time.get_ticks_msec() * 0.012)  # coughing, not running
	main.update_gauges(speed, alt, rpm)
	main.prompt.text = "ENGINE TROUBLE     %d kt     %d ft\nUp arrow: nose down, keep above 45 kt.   Down arrow: flare just before the ground." % [speed * 1.94, alt * 3.28]
	if alt <= maxf(0.0, main.terrain.height(plane.position.x, plane.position.z)):
		_end("landed" if speed * sin(-pitch) < SAFE_SINK and speed >= 15.0 else "crash")


func _end(result: String) -> void:
	_result = result
	_end_t = 1.6
	main.sound.engine = 0.0
	main.sound.sfx("heavy")
	main.prompt.text = {"abort": "Aborting the take-off.", "landed": "Down in one piece.", "crash": ""}[result]


func _roll_out(delta: float) -> void:
	_end_t -= delta
	speed = move_toward(speed, 0.0, 14.0 * delta)
	plane.position.x -= speed * delta
	if _result == "crash" and main.settings.shake:
		cam.h_offset = randf_range(-0.04, 0.04) * _end_t
		cam.v_offset = randf_range(-0.04, 0.04) * _end_t
	if _end_t <= 0.0 and not done:
		done = true
		failed.emit(_result)

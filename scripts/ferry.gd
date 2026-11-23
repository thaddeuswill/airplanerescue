extends Node
## Ferry flight, from the cockpit. Start the engine yourself: fuel on, master on, prime it, crack
## the throttle, mags to both, hold the starter. Get that wrong and it won't catch: no fuel, no
## spark, flooded (clear it with the throttle open), or a hung start (catches, hangs at low rpm and
## dies unless you ease in throttle). Then fly it: W/S throttle, A/D rudder against the swing,
## Down arrow to rotate at 40 mph. Emits `finished` once climbing out.
## A fault you never found (`trouble`) strikes on the roll, or in the climb, where you lose the
## engine: Up arrow lowers the nose, Down flares. Emits `failed` with "abort", "landed" or "crash".

signal finished
signal failed(result: String)
signal runup_done

const LINE_UP_X := 70.0    # runway runs along X at z=20; the plane points -X down it
const RUNWAY_END_X := -78.0
const RUNWAY_Z := 20.0
const HALF_WIDTH := 6.5    # meters of asphalt each side of the centerline
const ROTATE := 17.5       # m/s: the Cub lifts off at about 39 mph (owner's manual)
const TOP_SPEED := 42.0
const DONE_ALT := 35.0     # meters climbed before the job counts as delivered
const TROUBLE_ROLL := 15.0  # m/s: a bad tire or brake shows itself here
const TROUBLE_ALT := 20.0  # meters: everything else waits until you're committed
const STALL := 16.0        # m/s, about 36 mph: the nose drops on its own below this
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

var mode := "fly"  # "runup": start it on the chocks, check the mags, shut down
var no_start := ""  # run-up: "battery" or "starter" keeps it from cranking
var drops := Vector2i(35, 50)  # run-up: rpm lost on the left and right mag alone
var radio_dead := false
var carb_drop := 50  # run-up: rpm lost with carb heat pulled
var carb_heat := false
var _seen := [-1, -1, -1]  # the drops the pilot has held long enough to read: left, right, carb heat
var _calls := [-1, -1]  # the pilot's call on each mag once read: 1 good, 0 bad, -1 not called yet
const MAG_LIMIT := 75  # rpm: the most a C-85 mag may drop at the run-up (JOBS_ATA.md)
## Error-activated aids (E4): switched on by a mistake, for the rest of this try only.
var _aid_mag := false  # a wrong mag call: the limit and the three cases on the card, even on Hard
var _aid_rudder := false  # a ground loop: a straight-line cue on the roll until it's airborne
var _failed_starts := 0  # starts that didn't catch this time in the seat (the Clean Start badge)
var _looped := false  # a ground loop on this flight (the Straight and True badge)
var _mag_t := 0.0
var _done_t := -1.0
var _warned := false
var _radio_told := false
const RUNUP_RPM := 2100.0  # the Cub's mag check (JOBS_ATA.md)
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
	if mode == "fly":
		_line_up()  # a run-up stays put, on the chocks


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
	if master and radio_dead and not _radio_told:
		_radio_told = true
		main.log_line(main.CLUES.avionics + ".")


func prime() -> void:
	primes += 1
	main.sound.sfx("thread")


func next_mags() -> void:
	_mag_t = 0.0
	_warned = false
	if mode == "runup" and state == "run":
		mags = mags % 3 + 1  # BOTH, LEFT, RIGHT, BOTH: a run-up never goes through OFF
	else:
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
	elif e.is_action_pressed("carb_heat") and mode == "runup" and state == "run":
		toggle_carb()
	elif e.is_action_pressed("call_good") and mode == "runup" and state == "run":
		call_mag(true)
	elif e.is_action_pressed("call_bad") and mode == "runup" and state == "run":
		call_mag(false)


## The pilot judges each mag once its drop is read: good is a drop above zero and no more than
## MAG_LIMIT, running smooth. A right call says why; a wrong one says why, costs time and has to be
## called again. Every call goes in the play log: it's how we see the run-up being learned.
func call_mag(good: bool) -> void:
	var which := -1
	for i in 2:
		if _seen[i] >= 0 and _calls[i] < 0:
			which = i
			break
	if which < 0:
		return
	var drop: int = _seen[which]
	var right: bool = drop > 0 and drop <= MAG_LIMIT
	var side: String = ["Left", "Right"][which]
	main.playlog("mag call %s: said %s, drop %d, %s" % [side.to_lower(), "good" if good else "bad", drop, "right" if good == right else "wrong"])
	if good == right:
		_calls[which] = 1 if good else 0
		if not _calls.has(-1) and not _aid_mag:
			main.earn_badge("reads_the_drop")  # both called right, no wrong call this run-up (P8)
		main.sound.sfx("click")
		main.log_line("Right. %s mag: %s" % [side, mag_reason(drop)])
	else:
		main.sound.sfx("deny")
		main.log_line("Not quite. %s mag: %s Call it again." % [side, mag_reason(drop)])
		main._wrong_guess("%s mag called %s" % [side, "good" if good else "bad"], "mag_call")  # a charge, not time (D2)
		if not _aid_mag:
			_aid_mag = true
			main.playlog("aid: mag limits on the card")


## "Can earn: <badge>" while that badge is still to earn, for the card's foot (P8).
func _offer(badge: String) -> String:
	var n: String = main.badge_on_offer(badge)
	return ("Can earn: " + n) if n != "" else ""


## Why a drop is good or bad, in a mechanic's words.
static func mag_reason(drop: int) -> String:
	if drop == 0:
		return "no drop at all means it isn't grounding when switched off: a broken P-lead, a hot mag. Bad."
	if drop > MAG_LIMIT:
		return "%d is past the %d rpm limit and it runs rough: that side's plugs, lead or mag. Bad." % [drop, MAG_LIMIT]
	return "%d is inside the %d rpm limit and it runs smooth. Good." % [drop, MAG_LIMIT]


func toggle_carb() -> void:
	carb_heat = not carb_heat
	_mag_t = 0.0
	_warned = false
	main.sound.sfx("click")


## Take-off steps already done this flight: they stay ticked once done (throttle back off full
## doesn't untick "full throttle").
var _flown := {}


## The cockpit checklist as data, drawn by preflight.gd: the phase, a problem to fix right now
## (flooded, hung, starter hot) and the steps. Before start, a step is ticked while its switch is
## right; the run-up ticks each reading as you take it; the take-off ticks each stage as you pass it.
## Keys come from the player's bindings.
func card() -> Dictionary:
	var k: Callable = main.key_name
	var throttle_keys: String = "%s/%s" % [k.call("throttle_up"), k.call("throttle_down")]
	var alert := ""
	if flood > 0.0:
		alert = "Flooded. Throttle wide open (%s) and hold %s to clear it." % [k.call("throttle_up"), k.call("starter")]
	elif state == "hung":
		alert = "Hung start. Ease the throttle to 12-35%% (now %d%%)." % roundi(throttle * 100)
	elif _cool > 0.0:
		alert = "Starter hot. Let it rest %d s." % ceili(_cool)
	var before := [
		{"text": "Fuel on", "key": k.call("fuel_valve"), "ok": fuel_on, "read": "ON" if fuel_on else "OFF",
			"how": "Fuel to the carburetor. Off, it turns over and never fires."},
		{"text": "Master on", "key": k.call("master"), "ok": master, "read": "ON" if master else "OFF",
			"how": "Power for the starter. Off, nothing happens at all."},
		{"text": "Prime 2-5 strokes", "key": k.call("primer"), "ok": primes >= 2 and primes <= 5, "read": str(primes),
			"how": "Too many already: it'll flood. Start it anyway, then clear it." if primes >= 6
				else "A little fuel in a cold engine's cylinders. Six or more floods it."},
		{"text": "Throttle cracked", "key": throttle_keys, "ok": throttle >= 0.05 and throttle <= 0.4, "read": "%d%%" % roundi(throttle * 100),
			"how": "Just open, 5-40%. Closed, it hangs; wide open, it roars."},
		{"text": "Mags on BOTH", "key": k.call("mags"), "ok": mags == 3, "read": MAGS[mags],
			"how": "The spark. Press until it reads BOTH."},
		{"text": "Start it", "key": "hold " + k.call("starter"), "ok": state == "run", "read": "",
			"how": "Hold the starter until it fires, then let go. Eight seconds at most, then let it cool."},
	]
	if mode == "runup":
		if state != "run":
			return {"title": "BEFORE START", "alert": alert, "steps": before, "foot": _offer("clean_start")}
		var shown := func(i: int) -> String: return "" if _seen[i] < 0 else "-%d rpm" % _seen[i]
		var called := func(i: int) -> String: return "" if _calls[i] < 0 else ("GOOD" if _calls[i] == 1 else "BAD")
		var call_keys: String = "%s / %s" % [k.call("call_good"), k.call("call_bad")]
		# The limit on the card on Easy and Medium; on Hard you know it, or it's in the manual (N).
		var foot := "Mag drop %d rpm max (C-85). Carb heat: about 50." % MAG_LIMIT if main.guide("medium") else ""
		if _offer("reads_the_drop") != "" and not _aid_mag:
			foot = (foot + "   " if foot != "" else "") + _offer("reads_the_drop")
		if _aid_mag:  # after a wrong call: the rule in full, on every difficulty, for this run-up
			foot = "Good: drops a little, no more than %d rpm, runs smooth. Bad: past %d and rough, or no drop at all." % [MAG_LIMIT, MAG_LIMIT]
		return {"title": "RUN-UP", "alert": alert, "foot": foot, "steps": [
			{"text": "Hold %d rpm" % RUNUP_RPM, "key": throttle_keys, "ok": _at_rpm() or not _seen.has(-1), "read": "%d" % rpm,
				"how": "Throttle up until the tach reads %d. A check at idle tells you nothing." % RUNUP_RPM},
			{"text": "Left mag alone", "key": k.call("mags"), "ok": _seen[0] >= 0, "read": shown.call(0),
				"how": "Switch to LEFT and hold it while you read the drop off the tach."},
			{"text": "Call the left mag", "key": call_keys, "ok": _calls[0] >= 0, "read": called.call(0),
				"how": "Good (%s) or bad (%s)? Good drops a little, no more than the limit, and runs smooth." % [k.call("call_good"), k.call("call_bad")]},
			{"text": "Right mag alone", "key": k.call("mags"), "ok": _seen[1] >= 0, "read": shown.call(1),
				"how": "Switch to RIGHT and read the drop."},
			{"text": "Call the right mag", "key": call_keys, "ok": _calls[1] >= 0, "read": called.call(1),
				"how": "Good (%s) or bad (%s)? No drop at all is bad too." % [k.call("call_good"), k.call("call_bad")]},
			{"text": "Carb heat", "key": k.call("carb_heat"), "ok": _seen[2] >= 0, "read": shown.call(2),
				"how": "Back on BOTH, pull the carb heat: a small drop says it works."},
			{"text": "Back to BOTH, heat off", "key": "%s %s" % [k.call("mags"), k.call("carb_heat")],
				"ok": mags == 3 and not carb_heat and not _seen.has(-1) and not _calls.has(-1), "read": "", "how": "Then it shuts down on its own."}]}
	if state != "run":
		return {"title": "BEFORE START", "alert": alert, "steps": before, "foot": _offer("clean_start")}
	# The take-off, stage by stage.
	var on_ground := alt < 0.05
	if throttle >= 0.95:
		_flown["full"] = true
	if speed >= ROTATE * 0.6 and on_ground and absf(z_off) <= HALF_WIDTH:
		_flown["straight"] = true
	if speed > 3.0 and pitch <= main.SIT_PITCH * 0.5:
		_flown["tail"] = true
	if alt > 0.5:
		_flown["rotate"] = true
	if alt >= DONE_ALT * 0.5:
		_flown["climb"] = true
	return {"title": "TAKE-OFF", "alert": alert, "foot": _offer("straight_and_true"), "steps": [
		{"text": "Full throttle", "key": k.call("throttle_up"), "ok": _flown.has("full"), "read": "%d%%" % roundi(throttle * 100),
			"how": "All the way in. The Cub needs every horse it has."},
		{"text": "Hold the centerline", "key": "%s/%s" % [k.call("rudder_left"), k.call("rudder_right")], "ok": _flown.has("straight"), "read": "",
			"how": "Power swings a taildragger left: right rudder holds it straight, more as it speeds up."},
		{"text": "Tail up", "key": k.call("stick_forward"), "ok": _flown.has("tail"), "read": "",
			"how": "A touch of forward stick lifts the tail so it can pick up speed."},
		{"text": "Ease back at 40 mph", "key": k.call("stick_back"), "ok": _flown.has("rotate"), "read": "%d mph" % roundi(speed * 2.237),
			"how": "It lifts off at about 39 mph. Ease the stick back."},
		{"text": "Climb out", "key": "", "ok": _flown.has("climb"), "read": "%d ft" % roundi(alt * 3.28),
			"how": "Keep the power in and climb straight ahead. The owner pays once you're up."}]}


func _process(delta: float) -> void:
	if _result != "":
		_roll_out(delta)
		return
	if _done_t >= 0.0:  # the run-up's over: a moment to read it, then out
		_done_t -= delta
		if _done_t < 0.0:
			done = true
			runup_done.emit()
		return
	if done:
		return
	throttle = clampf(throttle + Input.get_axis("throttle_down", "throttle_up") * 0.6 * delta, 0.0, 1.0)
	if state != "run":
		_starting(delta)
		_spin(delta)
		main.update_gauges(0.0, 0.0, rpm)
		return
	if mode == "runup":
		_runup(delta)
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
	if no_start != "":  # clicks and won't turn: the panel lights tell you which
		if not _judged:
			_judged = true
			main.sound.sfx("click")
			main.log_line(main.CLUES[no_start] + ".")
			_done_t = 2.5
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
	if not fuel_on or mags == 0 or primes >= 6 or primes < 2 or throttle < 0.05:
		_failed_starts += 1  # it won't catch cleanly: no fuel, no spark, flooded, or a hung start
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
	if _failed_starts == 0:
		main.earn_badge("clean_start")  # started with no failed attempt (P8)
	main.sound.stop_loop()
	main.sound.sfx("jack")
	main.log_live("")
	main.log_line(text)
	_judged = false


func _die(text: String) -> void:
	_failed_starts += 1
	_judged = false
	state = "off"
	primes = 0
	main.sound.engine = 0.0
	main.sound.sfx("deny")
	main.log_live("")
	main.log_line(text)


func _at_rpm() -> bool:
	return absf(650.0 + throttle * 1700.0 - RUNUP_RPM) <= 100.0


## On the chocks at 2,100: switch to each mag alone and read the drop off the tach.
func _runup(delta: float) -> void:
	var drop: int = (0 if mags == 3 else (drops.x if mags == 1 else drops.y)) + (carb_drop if carb_heat else 0)
	var rough := 40.0 if drop > 75 and not carb_heat else 0.0
	rpm = lerpf(rpm, 650.0 + throttle * 1700.0 - drop + sin(Time.get_ticks_msec() * 0.03) * rough, minf(1.0, delta * 3.0))
	_spin(delta)
	main.sound.engine = clampf(rpm / 2350.0, 0.0, 1.0)
	main.update_gauges(0.0, 0.0, rpm)
	var testing := mags != 3 or carb_heat
	if testing and not _at_rpm():
		if not _warned:
			_warned = true
			main.log_line("Bring it up to %d first. A check at idle tells you nothing." % RUNUP_RPM)
	elif testing:
		_mag_t += delta
		var which := 2 if mags == 3 else mags - 1  # carb heat is read on BOTH
		if _mag_t >= 1.5 and _seen[which] < 0 and not (carb_heat and mags != 3):
			_seen[which] = drop
			if which == 2:
				main.log_line("Carb heat: drops %d rpm." % drop)
			else:
				main.log_line("%s mag: %s." % [MAGS[mags].capitalize(), "no drop at all" if drop == 0 else "drops %d rpm%s" % [drop, " and runs rough" if rough > 0.0 else ""]])
	if not _seen.has(-1) and not _calls.has(-1) and mags == 3 and not carb_heat and _done_t < 0.0:
		main.log_line("Run-up done. Throttle back and shut it down.")
		_done_t = 2.0


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
	var mph := speed * 2.237  # the Cub's airspeed dial reads miles per hour
	var k: Callable = main.key_name
	var rudder_keys: String = "%s/%s" % [k.call("rudder_left"), k.call("rudder_right")]
	var hint := "%s: throttle up. %s: rudder, hold the centerline." % [k.call("throttle_up"), rudder_keys]
	if alt > 2.0:
		_aid_rudder = false  # it's flying: the cue has done its job
	if on_grass:
		hint = "Off the runway! Rudder back to the asphalt."
	elif mph >= 40 and on_ground:
		hint = "40 mph: %s to rotate." % k.call("stick_back")
	elif not on_ground:
		hint = "Climbing out..."
	elif mph > 17:
		hint = "%s lifts the tail. %s: rudder, she'll swing left." % [k.call("stick_forward"), rudder_keys]
	if _aid_rudder and on_ground and not on_grass and mph < 40:  # after a ground loop: the straight-line cue, this roll only
		hint = "STRAIGHT: power swings it left. %s, small and early, more as it speeds up." % k.call("rudder_right")
	main.prompt.text = "%d mph     %d ft     %d rpm\n%s" % [mph, alt * 3.28, rpm, hint]
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
		_looped = true
		if not _aid_rudder:
			main.playlog("aid: rudder cue on the take-off roll")
		_aid_rudder = true
		_line_up()
	elif plane.position.x < RUNWAY_END_X and alt < 2.0:
		main._say("Ran out of runway! Lining up to try again.")
		_line_up()
	elif alt >= DONE_ALT:
		if not _looped:
			main.earn_badge("straight_and_true")  # off the ground with no ground loop (P8)
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
	main.prompt.text = "ENGINE TROUBLE     %d mph     %d ft\nUp arrow: nose down, keep above 45 mph.   Down arrow: flare just before the ground." % [speed * 2.237, alt * 3.28]
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

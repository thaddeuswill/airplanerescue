extends Node
## Ferry flight: you take the repaired plane off yourself, from the cockpit.
## Hold W for throttle; past rotate speed hold S to pull back. Lift off before the
## runway ends or you abort and line up again. Emits `finished` once climbing out.

signal finished

const LINE_UP_X := 70.0    # runway runs along X at z=20; the plane points -X down it
const RUNWAY_END_X := -78.0
const ROTATE := 28.0       # m/s, about 55 knots
const TOP_SPEED := 42.0
const DONE_ALT := 35.0     # meters climbed before the job counts as delivered

var main
var plane: Node3D
var prop: Node3D
var cam: Camera3D
var speed := 0.0
var pitch := 0.0
var alt := 0.0
var done := false


func start(m, p: Node3D, prop_node: Node3D) -> void:
	main = m
	plane = p
	prop = prop_node
	cam = Camera3D.new()
	cam.fov = 70
	cam.position = Vector3(0, 2.05, -1.65)  # pilot's eye, looking over the panel
	cam.rotation.x = -0.1
	plane.add_child(cam)
	cam.make_current()
	_line_up()


func _line_up() -> void:
	speed = 0.0
	pitch = 0.0
	alt = 0.0
	plane.position = Vector3(LINE_UP_X, 0, 20)
	plane.rotation = Vector3(0, PI / 2, 0)


func _process(delta: float) -> void:
	if done:
		return
	var throttle := Input.is_action_pressed("move_forward")
	speed = move_toward(speed, TOP_SPEED if throttle else 0.0, (7.0 if throttle else 3.0) * delta)
	if speed >= ROTATE and Input.is_action_pressed("move_back"):
		pitch = move_toward(pitch, 0.22, 0.3 * delta)
	elif alt < 0.05:
		pitch = move_toward(pitch, 0.0, 0.6 * delta)
	if speed >= ROTATE * 0.9:
		alt = maxf(0.0, alt + speed * sin(pitch) * delta)
	plane.position.x -= speed * cos(pitch) * delta
	plane.position.y = alt
	plane.rotation = Vector3(pitch, PI / 2, 0)  # positive pitch raises the nose
	if is_instance_valid(prop):
		prop.rotate_object_local(Vector3.FORWARD, (speed * 1.5 + (25.0 if throttle else 6.0)) * delta)
	main.sound.engine = clampf(speed / TOP_SPEED * 0.7 + (0.3 if throttle else 0.0), 0.0, 1.0)
	var kt := speed * 1.94
	main.prompt.text = "W: throttle     S: pull back     %d kt     %d ft\n%s" % [kt, alt * 3.28,
		"Rotate at 55 kt" if kt < 55 and alt < 1 else ("Pull back!" if alt < 1 else "Climbing out...")]
	if plane.position.x < RUNWAY_END_X and alt < 2.0:
		main._say("Ran out of runway! Lining up to try again.")
		_line_up()
	elif alt >= DONE_ALT:
		done = true
		main.sound.engine = 0.0
		finished.emit()

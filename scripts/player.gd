extends CharacterBody3D
## First-person walker. Builds its own collision, camera and interact ray.

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENS := 0.0025

var frozen := false  # true while a 2D panel is open
var cam: Camera3D
var ray: RayCast3D


func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)
	cam = Camera3D.new()
	cam.position.y = 1.65
	cam.fov = 75
	add_child(cam)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -3.5)
	ray.collision_mask = 3  # walls (1) block, interactables (2) are hit
	ray.add_exception(self)
	cam.add_child(ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(e: InputEvent) -> void:
	if frozen or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if e is InputEventMouseMotion:
		rotate_y(-e.relative.x * MOUSE_SENS)
		cam.rotate_x(-e.relative.y * MOUSE_SENS)
		cam.rotation.x = clampf(cam.rotation.x, -1.4, 1.4)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var dir := Vector3.ZERO
	if not frozen:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		var inp := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = (transform.basis * Vector3(inp.x, 0, inp.y)).normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	move_and_slide()


func target() -> Object:
	var t: Object = ray.get_collider() if ray.is_colliding() else null
	return t if is_instance_valid(t) else null

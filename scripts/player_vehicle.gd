extends Node2D

# What you drive yourself: the ranger on foot, a gyrosphere, a jeep or the helicopter.
# Arrows or ZQSD to move, Échap to get out. The helicopter climbs with Espace and comes down with Maj.

const Art := preload("res://scripts/art.gd")
const T := 16
const MAX_ALTITUDE := 120.0
const SPEEDS := {"walk": 3.5, "gyro": 5.0, "jeep": 7.0, "heli": 10.0}

var park: Node2D
var kind := "walk"
var sprite: Sprite2D
var shadow: Sprite2D
var velocity := Vector2.ZERO
var facing := "down"
var travelled := 0.0
var altitude := 0.0
var rotor_speed := 0.0
var rotor_angle := 0.0
var notify_timer := 0.0


func setup(owner_park: Node2D, vehicle_kind: String, at: Vector2) -> void:
	park = owner_park
	kind = vehicle_kind
	position = at
	if kind == "heli":
		shadow = Art.sprite(Art.shadow(26))
		shadow.centered = true
		shadow.offset = Vector2.ZERO
		shadow.z_as_relative = false
		shadow.z_index = -1
		add_child(shadow)
	match kind:
		"walk":
			sprite = Art.sprite(Art.person("down", 0, Art.RANGER))
		"gyro":
			sprite = Art.sprite(Art.gyro(0), Vector2(10, 19))
		"jeep":
			sprite = Art.sprite(Art.jeep(0), Vector2(15, 19))
		"heli":
			sprite = Art.sprite(Art.helicopter(0), Vector2(18, 20))
	add_child(sprite)


func _process(delta: float) -> void:
	var input := Vector2.ZERO
	if _pressed([KEY_UP, KEY_Z, KEY_W]):
		input.y -= 1.0
	if _pressed([KEY_DOWN, KEY_S]):
		input.y += 1.0
	if _pressed([KEY_LEFT, KEY_Q, KEY_A]):
		input.x -= 1.0
	if _pressed([KEY_RIGHT, KEY_D]):
		input.x += 1.0
	input = input.normalized()

	var max_speed: float = SPEEDS[kind] * T
	if kind == "heli":
		_fly(delta)
		# It cannot move while sitting on the ground.
		if altitude <= park.ground_height(position) + 1.0:
			max_speed = 0.0
	var accel := max_speed * (4.0 if kind == "walk" else 1.5)
	velocity = velocity.move_toward(input * max_speed, maxf(accel, 200.0) * delta)
	_move(velocity * delta)
	_animate(input)

	notify_timer -= delta
	if notify_timer <= 0.0:
		notify_timer = 0.7
		park.on_vehicle_moved(position)


# Moves along x then y, so we slide along fences instead of sticking to them.
func _move(step: Vector2) -> void:
	for axis in [Vector2(step.x, 0), Vector2(0, step.y)]:
		var next: Vector2 = position + axis
		if kind == "heli":
			next = next.clamp(Vector2.ZERO, Vector2(park.GRID * T))
			position = next
		elif park.is_blocked_for_vehicle(kind, Vector2i((next / T).floor())):
			if axis.x != 0.0:
				velocity.x = 0.0
			else:
				velocity.y = 0.0
		else:
			position = next
	travelled += step.length()


func _fly(delta: float) -> void:
	var lift := 0.0
	if _pressed([KEY_SPACE, KEY_R]):
		lift += 1.0
	if _pressed([KEY_SHIFT, KEY_F]):
		lift -= 1.0
	var ground: float = park.ground_height(position)
	var airborne := altitude > ground + 1.0
	rotor_speed = move_toward(rotor_speed, 25.0 if airborne or lift > 0.0 else 4.0, delta * 15.0)
	if rotor_speed > 20.0:
		altitude += lift * 40.0 * delta
	altitude = clampf(altitude, ground, MAX_ALTITUDE)
	rotor_angle += rotor_speed * delta
	sprite.position.y = -altitude
	shadow.scale = Vector2.ONE * clampf(1.0 - altitude / 200.0, 0.4, 1.0)
	z_index = 1 if altitude > 6.0 else 0


func _animate(input: Vector2) -> void:
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	var frame := int(travelled / 4.0)
	match kind:
		"walk":
			if input.x != 0.0:
				facing = "side"
			elif input.y != 0.0:
				facing = "down" if input.y > 0.0 else "up"
				sprite.flip_h = false
			sprite.texture = Art.person(facing, frame % 2 if velocity.length() > 2.0 else 0, Art.RANGER)
		"gyro":
			sprite.texture = Art.gyro(frame % 4)
		"jeep":
			sprite.texture = Art.jeep(frame % 4)
		"heli":
			sprite.texture = Art.helicopter(int(rotor_angle) % 2)


func _pressed(keys: Array) -> bool:
	for key in keys:
		if Input.is_key_pressed(key):
			return true
	return false

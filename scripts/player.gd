extends Node2D

# Your character in the adventure mode: walks with the arrows, ZQSD or the joystick, and uses
# what is in its hand on the cell in front of it (Espace or the action button).
# Holding the action button with a fence or a path in hand while walking lays one on every step.
# On a dinosaur's back, the character rides it; the action button gets off.
# With a vehicle in hand, the action button gets on it; the action button again gets off.
# The helicopter takes off by itself and flies over everything, and lands to let the character off.

const Art := preload("res://scripts/art.gd")
const Items := preload("res://scripts/items.gd")
const T := 16
const SPEED := 4.0 * T
const HIT_DELAY := 0.35
const FLIGHT_HEIGHT := 48.0

var park: Node2D
var look: Dictionary
var sprite: Sprite2D
var tool_sprite: Sprite2D
var facing := Vector2i.DOWN
var velocity := Vector2.ZERO
var travelled := 0.0
var cooldown := 0.0
var swing := 0.0
var last_cell := Vector2i.ZERO
var notify_timer := 0.0
var mount: Node2D = null
var blink_time := 0.0
var vehicle := ""  # what the character drives ("bike", "moto", "car", "heli"), or "" on foot
var vehicle_sprite: Sprite2D
var shadow: Sprite2D
var altitude := 0.0  # of the helicopter
var landing := false
var rotor := 0.0
var pushing := Vector2i.ZERO  # the direction the player is walking towards, ZERO when standing still


func setup(owner_park: Node2D, player_look: Dictionary, at: Vector2) -> void:
	park = owner_park
	look = player_look
	position = at
	last_cell = cell()
	sprite = Art.sprite(Art.hero("down", 0, look))
	add_child(sprite)
	tool_sprite = Art.sprite(Art.resource("axe"), Vector2(3, 14))
	tool_sprite.scale = Vector2(0.75, 0.75)
	tool_sprite.visible = false
	add_child(tool_sprite)
	# The shadow on the ground: small under the feet, bigger under the helicopter.
	shadow = Art.sprite(Art.shadow(12))
	shadow.centered = true
	shadow.offset = Vector2.ZERO
	shadow.z_index = -1
	add_child(shadow)
	vehicle_sprite = Sprite2D.new()
	vehicle_sprite.centered = false
	vehicle_sprite.visible = false
	add_child(vehicle_sprite)


# Blinks for a while after being bumped by a dinosaur.
func blink(duration: float) -> void:
	blink_time = duration


func cell() -> Vector2i:
	return Vector2i((position / T).floor())


func front() -> Vector2i:
	return cell() + facing


func _process(delta: float) -> void:
	# In the building mode, the character waits while the joystick moves the camera.
	if park.builder != null and park.builder.active:
		velocity = Vector2.ZERO
		pushing = Vector2i.ZERO
		_animate(delta, park.inventory.current())
		return
	var input := Vector2.ZERO
	var acting := false
	if not park.hud.menu_open():
		if _pressed([KEY_UP, KEY_Z, KEY_W]):
			input.y -= 1.0
		if _pressed([KEY_DOWN, KEY_S]):
			input.y += 1.0
		if _pressed([KEY_LEFT, KEY_Q, KEY_A]):
			input.x -= 1.0
		if _pressed([KEY_RIGHT, KEY_D]):
			input.x += 1.0
		input = (input + park.hud.stick_vector()).limit_length(1.0)
		acting = _pressed([KEY_SPACE, KEY_ENTER]) or park.hud.action_held()
	if input != Vector2.ZERO:
		if absf(input.x) > absf(input.y):
			facing = Vector2i.RIGHT if input.x > 0.0 else Vector2i.LEFT
		else:
			facing = Vector2i.DOWN if input.y > 0.0 else Vector2i.UP
	pushing = facing if input != Vector2.ZERO else Vector2i.ZERO
	var speed: float = SPEED * park.inventory.walk_bonus()
	if mount:
		speed = ride_speed()
	elif vehicle != "":
		speed = Items.VEHICLES[vehicle].speed * T
		if vehicle == "heli":
			_fly(delta)
			# On the ground, the helicopter waits for its rotor.
			if altitude < FLIGHT_HEIGHT * 0.6:
				input = Vector2.ZERO
	var grip := 8.0 if vehicle == "" else 4.0
	velocity = velocity.move_toward(input * speed, speed * grip * delta)
	_move(velocity * delta)

	cooldown -= delta
	if vehicle != "":
		_drive()
		if acting and cooldown <= 0.0 and not landing:
			cooldown = 0.5
			if vehicle != "heli":
				park.player_leave_vehicle()
			elif park.player_blocked(cell()):
				park.float_text(position + Vector2(0, -altitude - 16), "Pose-toi sur un endroit libre !", Color("ffab91"))
			else:
				landing = true
		last_cell = cell()
		return
	if mount:
		_ride()
		if acting and cooldown <= 0.0:
			cooldown = 0.5
			park.player_dismount()
		last_cell = cell()
		return
	var holding: String = park.inventory.current()
	var building: bool = Items.kind_of(holding) == "build"
	if acting and building and cell() != last_cell:
		# Walking with a fence in hand: lay it on the cell we just left.
		park.place_item(holding, last_cell)
	elif acting and cooldown <= 0.0 and not (building and input != Vector2.ZERO):
		# (While walking with something to build, it is laid behind us, never in our way.)
		cooldown = HIT_DELAY
		swing = 0.25
		park.player_action(front())
	last_cell = cell()
	_animate(delta, holding)

	notify_timer -= delta
	if notify_timer <= 0.0 and park.away == null:
		notify_timer = 0.7
		park.on_vehicle_moved(position)


# Moves along x then y, so we slide along fences instead of sticking to them.
# A quick raptor runs, a giant sauropod walks slowly.
func ride_speed() -> float:
	return mount.species.speed * T * 3.0 + 30.0


func mount_on(dino: Node2D) -> void:
	mount = dino
	dino.ridden = true
	dino.route.clear()
	dino.following = null
	position = dino.position
	velocity = Vector2.ZERO
	tool_sprite.visible = false
	shadow.visible = false
	_ride()


func get_off(at: Vector2) -> void:
	mount.ridden = false
	mount.ride_moving = false
	mount = null
	position = at
	sprite.position = Vector2.ZERO
	sprite.z_index = 0
	shadow.visible = true


# The dinosaur stays right under the character; the character sits on its saddle.
func _ride() -> void:
	mount.position = position - Vector2(0, 0.5)
	mount.cell = cell()
	mount.ride_moving = velocity.length() > 4.0
	if absf(velocity.x) > 2.0:
		mount.sprite.flip_h = velocity.x < 0.0
	sprite.texture = Art.hero("side", 0, look)
	sprite.flip_h = mount.sprite.flip_h
	sprite.position = Vector2(0, -mount.seat_height() + 8)
	# Always drawn over the saddle.
	sprite.z_index = 1


func _move(step: Vector2) -> void:
	if vehicle == "heli":
		var area: Rect2 = park.player_area()
		position = (position + step).clamp(area.position, area.end - Vector2.ONE)
		travelled += step.length()
		return
	for axis in [Vector2(step.x, 0), Vector2(0, step.y)]:
		var next: Vector2 = position + axis
		# Test the feet a little ahead, so the body does not overlap what blocks it.
		var probe: Vector2 = next + axis.sign() * 4.0
		if park.player_blocked(Vector2i((probe / T).floor())):
			if axis.x != 0.0:
				velocity.x = 0.0
			else:
				velocity.y = 0.0
		else:
			position = next
	travelled += step.length()


func board(id: String) -> void:
	vehicle = id
	velocity = Vector2.ZERO
	altitude = 0.0
	landing = false
	rotor = 0.0
	tool_sprite.visible = false
	vehicle_sprite.visible = true
	shadow.visible = id == "heli"
	shadow.texture = Art.shadow(26)
	_drive()


func leave_vehicle() -> void:
	vehicle = ""
	landing = false
	altitude = 0.0
	velocity = Vector2.ZERO
	vehicle_sprite.visible = false
	shadow.visible = true
	shadow.texture = Art.shadow(12)
	shadow.scale = Vector2.ONE
	sprite.visible = true
	sprite.position = Vector2.ZERO
	sprite.z_index = 0
	z_index = 0


func flying() -> bool:
	return vehicle == "heli" and altitude > 6.0


# The helicopter climbs as soon as we are in, and comes down to land.
func _fly(delta: float) -> void:
	rotor = move_toward(rotor, 25.0, delta * 15.0)
	if landing:
		velocity = Vector2.ZERO
		altitude = move_toward(altitude, 0.0, 30.0 * delta)
		if altitude <= 0.0:
			park.player_leave_vehicle()
			return
	elif rotor > 20.0:
		altitude = move_toward(altitude, FLIGHT_HEIGHT, 30.0 * delta)


# The character sits on the bike or the moto, in the car, or in the helicopter's cockpit.
func _drive() -> void:
	if vehicle == "":
		return
	# It turns where the character goes: seen from the side, from the front or from the back.
	var direction := "side"
	if facing.y != 0:
		direction = "down" if facing.y > 0 else "up"
	var left := facing == Vector2i.LEFT
	var frame := int(rotor * 3.0) % 2 if vehicle == "heli" else int(travelled / 4.0)
	var texture := Art.vehicle(vehicle, frame, direction)
	vehicle_sprite.texture = texture
	vehicle_sprite.flip_h = left
	vehicle_sprite.offset = -Vector2(floorf(texture.get_width() / 2.0), texture.get_height())
	vehicle_sprite.position = Vector2(0, -altitude)
	sprite.texture = Art.hero(direction, 0, look)
	sprite.flip_h = left
	sprite.visible = vehicle != "heli"
	var back := 0.0 if direction != "side" else (2.0 if left else -2.0)
	match vehicle:
		"bike":
			sprite.position = Vector2(back, -4)
			sprite.z_index = 1
		"moto":
			sprite.position = Vector2(back, -5)
			sprite.z_index = 1
		"car":
			# Drawn behind the car: only the head shows over the door.
			sprite.position = Vector2(back * 1.5, -6 if direction == "side" else -9)
			sprite.z_index = -1
	shadow.scale = Vector2.ONE * clampf(1.0 - altitude / 160.0, 0.5, 1.0)
	# High up, it flies over the trees.
	z_index = 1 if altitude > 6.0 else 0


func _animate(delta: float, holding: String) -> void:
	var direction := "side"
	if facing.y != 0:
		direction = "down" if facing.y > 0 else "up"
	sprite.flip_h = facing == Vector2i.LEFT
	var frame := int(travelled / 4.0) % 4 if velocity.length() > 4.0 else 0
	sprite.texture = Art.hero(direction, frame, look)

	blink_time = maxf(blink_time - delta, 0.0)
	sprite.visible = blink_time <= 0.0 or int(blink_time * 12.0) % 2 == 0
	swing = maxf(swing - delta, 0.0)
	var is_tool: bool = Items.kind_of(holding) in ["tool", "weapon"]
	tool_sprite.visible = is_tool and facing != Vector2i.UP
	if is_tool:
		tool_sprite.texture = Art.resource(holding)
		var side := -1.0 if facing == Vector2i.LEFT else 1.0
		tool_sprite.flip_h = side < 0.0
		tool_sprite.position = Vector2(5.0 * side, -9.0) if facing.x != 0 else Vector2(7, -8)
		tool_sprite.offset = Vector2(-13 if side < 0.0 else -3, -14)
		tool_sprite.rotation = side * (-0.9 + 2.2 * (1.0 - swing / 0.25)) if swing > 0.0 else 0.0
	# Draw the tool behind the character when it faces away.
	tool_sprite.z_index = 0 if facing == Vector2i.DOWN or facing.x != 0 else -1


func _pressed(keys: Array) -> bool:
	for key in keys:
		if Input.is_key_pressed(key):
			return true
	return false

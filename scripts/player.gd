extends Node2D

# Your character in the adventure mode: walks with the arrows, ZQSD or the joystick, and uses
# what is in its hand on the cell in front of it (Espace or the action button).
# Holding the action button with a fence or a path in hand while walking lays one on every step.
# On a dinosaur's back, the character rides it; the action button gets off.

const Art := preload("res://scripts/art.gd")
const Items := preload("res://scripts/items.gd")
const T := 16
const SPEED := 4.0 * T
const HIT_DELAY := 0.35

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


func setup(owner_park: Node2D, player_look: Dictionary, at: Vector2) -> void:
	park = owner_park
	look = player_look
	position = at
	last_cell = cell()
	sprite = Art.sprite(Art.person("down", 0, look), Vector2(6, 16))
	add_child(sprite)
	tool_sprite = Art.sprite(Art.resource("axe"), Vector2(3, 14))
	tool_sprite.scale = Vector2(0.75, 0.75)
	tool_sprite.visible = false
	add_child(tool_sprite)


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
	var speed := ride_speed() if mount else SPEED
	velocity = velocity.move_toward(input * speed, speed * 8.0 * delta)
	_move(velocity * delta)

	cooldown -= delta
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
	_ride()


func get_off(at: Vector2) -> void:
	mount.ridden = false
	mount.ride_moving = false
	mount = null
	position = at
	sprite.position = Vector2.ZERO
	sprite.z_index = 0


# The dinosaur stays right under the character; the character sits on its saddle.
func _ride() -> void:
	mount.position = position - Vector2(0, 0.5)
	mount.cell = cell()
	mount.ride_moving = velocity.length() > 4.0
	if absf(velocity.x) > 2.0:
		mount.sprite.flip_h = velocity.x < 0.0
	sprite.texture = Art.person("side", 0, look)
	sprite.flip_h = mount.sprite.flip_h
	sprite.position = Vector2(0, -mount.seat_height() + 6)
	# Always drawn over the saddle.
	sprite.z_index = 1


func _move(step: Vector2) -> void:
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


func _animate(delta: float, holding: String) -> void:
	var direction := "side"
	if facing.y != 0:
		direction = "down" if facing.y > 0 else "up"
	sprite.flip_h = facing == Vector2i.LEFT
	var frame := int(travelled / 5.0) % 2 if velocity.length() > 4.0 else 0
	sprite.texture = Art.person(direction, frame, look)

	blink_time = maxf(blink_time - delta, 0.0)
	sprite.visible = blink_time <= 0.0 or int(blink_time * 12.0) % 2 == 0
	swing = maxf(swing - delta, 0.0)
	var is_tool: bool = Items.kind_of(holding) in ["tool", "weapon"]
	tool_sprite.visible = is_tool and facing != Vector2i.UP
	if is_tool:
		tool_sprite.texture = Art.resource(holding)
		var side := -1.0 if facing == Vector2i.LEFT else 1.0
		tool_sprite.flip_h = side < 0.0
		tool_sprite.position = Vector2(5.0 * side, -5.0) if facing.x != 0 else Vector2(6, -4)
		tool_sprite.offset = Vector2(-13 if side < 0.0 else -3, -14)
		tool_sprite.rotation = side * (-0.9 + 2.2 * (1.0 - swing / 0.25)) if swing > 0.0 else 0.0
	# Draw the tool behind the character when it faces away.
	tool_sprite.z_index = 0 if facing == Vector2i.DOWN or facing.x != 0 else -1


func _pressed(keys: Array) -> bool:
	for key in keys:
		if Input.is_key_pressed(key):
			return true
	return false

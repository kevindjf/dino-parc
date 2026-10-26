extends Camera2D

# The camera: the wheel, a pinch or the HUD buttons zoom (whole steps, so pixels stay square),
# arrows / ZQSD, a two-finger swipe or a middle-button drag move around.
# When driving, it follows the vehicle.

const ZOOMS := [1, 2, 3, 4, 5, 6]

var zoom_index := 2
var bounds := Rect2()
var follow_target: Node2D = null
var pinch := 1.0


func setup(center: Vector2, area: Rect2) -> void:
	position = center
	bounds = area
	_apply_zoom()


func zoom_step(direction: int) -> void:
	zoom_index = clampi(zoom_index + direction, 0, ZOOMS.size() - 1)
	_apply_zoom()


func follow(target: Node2D) -> void:
	follow_target = target


func unfollow() -> void:
	follow_target = null


func _apply_zoom() -> void:
	zoom = Vector2.ONE * ZOOMS[zoom_index]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_step(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_step(-1)
	elif event is InputEventMagnifyGesture:
		pinch *= event.factor
		if pinch > 1.3:
			pinch = 1.0
			zoom_step(1)
		elif pinch < 0.77:
			pinch = 1.0
			zoom_step(-1)
	elif event is InputEventPanGesture and follow_target == null:
		position += event.delta * 12.0 / zoom.x
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		position -= event.relative / zoom.x


func _process(delta: float) -> void:
	if follow_target and is_instance_valid(follow_target):
		position = position.lerp(follow_target.position, 1.0 - exp(-8.0 * delta))
	else:
		var move := Vector2.ZERO
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Q):
			move.x -= 1
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			move.x += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_Z):
			move.y -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			move.y += 1
		position += move.normalized() * delta * 500.0 / zoom.x
	# Keep the park on screen; center it when it is smaller than the view.
	var half := get_viewport_rect().size / zoom / 2.0
	for axis in 2:
		var low := bounds.position[axis] + half[axis]
		var high := bounds.end[axis] - half[axis]
		position[axis] = (bounds.position[axis] + bounds.end[axis]) / 2.0 if low > high else clampf(position[axis], low, high)

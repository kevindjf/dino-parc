extends Control

# A virtual joystick for tablets: put a finger on it and slide. Works with several fingers at once
# (one on the stick, one on the action button). With a mouse, click and drag.

const RADIUS := 64.0

var vector := Vector2.ZERO
var finger := -1
var knob := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS, RADIUS) * 2.0 + Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			_update(event.position)
		elif not event.pressed and event.index == finger:
			finger = -1
			knob = Vector2.ZERO
			vector = Vector2.ZERO
			queue_redraw()
		accept_event()
	elif event is InputEventScreenDrag and event.index == finger:
		_update(event.position)
		accept_event()


func _update(at: Vector2) -> void:
	knob = (at - size / 2.0).limit_length(RADIUS)
	vector = knob / RADIUS
	if vector.length() < 0.25:
		vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, RADIUS + 6, Color(0.95, 0.97, 1.0, 0.35))
	draw_arc(center, RADIUS + 6, 0, TAU, 48, Color("405878"), 3.0, true)
	draw_circle(center + knob, 30, Color("f8f8f8"))
	draw_arc(center + knob, 30, 0, TAU, 32, Color("405878"), 3.0, true)

extends Control

# A big round button for tablets that can be held down while another finger moves the joystick.

signal pressed

var held := false
var finger := -1
var icon: Texture2D
var caption := ""
var radius := 52.0
var color := Color("e85a4a")


func setup(text: String, size_radius: float, fill: Color) -> void:
	caption = text
	radius = size_radius
	color = fill
	custom_minimum_size = Vector2(radius, radius) * 2.0 + Vector2(8, 8)
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_icon(texture: Texture2D) -> void:
	icon = texture
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1:
			finger = event.index
			held = true
			pressed.emit()
		elif not event.pressed and event.index == finger:
			finger = -1
			held = false
		queue_redraw()
		accept_event()


func _draw() -> void:
	var center := size / 2.0
	var fill := color.darkened(0.2) if held else color
	draw_circle(center + Vector2(0, 3), radius, Color(0, 0, 0, 0.25))
	draw_circle(center, radius, fill)
	# A rim of wood around the coloured button, like the plank buttons of the interface.
	draw_arc(center, radius - 2, 0, TAU, 48, Color("a86e3a"), 5.0, true)
	draw_arc(center, radius, 0, TAU, 48, Color("2a1a0c"), 3.0, true)
	draw_arc(center, radius - 5, PI * 1.1, PI * 1.6, 12, fill.lightened(0.4), 3.0, true)
	var font := get_theme_default_font()
	if icon:
		var icon_size := icon.get_size()
		draw_texture(icon, center - icon_size / 2.0 - Vector2(0, 8))
		var font_size := 14 if caption.length() <= 12 else 11
		draw_string(font, center + Vector2(-radius - 6, radius * 0.62), caption, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0 + 12, font_size, Color.WHITE)
	else:
		draw_string(font, center + Vector2(-radius, 7), caption, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 20, Color.WHITE)

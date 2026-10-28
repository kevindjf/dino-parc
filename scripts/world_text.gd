extends Node2D

# A text that follows a point of the park but is drawn crisp, in screen space, above the game:
# speech bubbles, wooden signs with the name of a place, roars and floating "+10". The label lives in the shared text layer.

const STYLES := {
	"bubble": {"size": 13, "color": Color("303040")},
	"sign": {"size": 14, "color": Color("fff0d0")},
	"shout": {"size": 20, "color": Color("fff59d")},
	"float": {"size": 18, "color": Color.WHITE},
}

static var layer: CanvasLayer

var control: Control
var label: Label
var shown := true


static func make(parent: Node, at: Vector2, text: String, style: String, color := Color.TRANSPARENT) -> Node2D:
	var node: Node2D = load("res://scripts/world_text.gd").new()
	node.position = at
	node._build(text, style, color)
	parent.add_child(node)
	return node


func _build(text: String, style: String, color: Color) -> void:
	var settings: Dictionary = STYLES[style]
	label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", settings.size)
	label.add_theme_color_override("font_color", color if color.a > 0.0 else settings.color)
	if style == "bubble" or style == "sign":
		var panel := PanelContainer.new()
		var box := StyleBoxFlat.new()
		box.bg_color = Color("f8f8f8")
		box.border_color = Color("405878")
		box.set_border_width_all(2)
		box.set_corner_radius_all(5)
		box.content_margin_left = 6
		box.content_margin_right = 6
		box.content_margin_top = 1
		box.content_margin_bottom = 1
		if style == "sign":
			# A plank like the wooden signs of the world: light wood, a dark contour, thicker at
			# the bottom for its edge, and cream letters carved in it.
			box.bg_color = Color("b07840")
			box.border_color = Color("3a2410")
			box.border_width_bottom = 4
			box.set_corner_radius_all(2)
			box.content_margin_left = 8
			box.content_margin_right = 8
			box.shadow_color = Color(0, 0, 0, 0.25)
			box.shadow_size = 2
			box.shadow_offset = Vector2(0, 2)
			label.add_theme_constant_override("outline_size", 4)
			label.add_theme_color_override("font_outline_color", Color("5a3818"))
		panel.add_theme_stylebox_override("panel", box)
		panel.add_child(label)
		control = panel
	else:
		label.add_theme_constant_override("outline_size", 6)
		label.add_theme_color_override("font_outline_color", Color("202830"))
		control = label
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_text(text: String, color := Color.TRANSPARENT) -> void:
	label.text = text
	if color.a > 0.0:
		label.add_theme_color_override("font_color", color)
	control.reset_size()


func set_shown(value: bool) -> void:
	shown = value


func _ready() -> void:
	layer.add_child(control)
	_sync()


func _process(_delta: float) -> void:
	_sync()


# Hidden with its zone (the village while the player is in a house): even when the zone is
# paused, the label goes away at once.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and control != null:
		_sync()


func _sync() -> void:
	control.visible = shown and is_visible_in_tree() and label.text != ""
	if control.visible:
		control.modulate = modulate
		var screen := get_global_transform_with_canvas().origin
		control.position = (screen - control.size * Vector2(0.5, 1.0)).round()


func _exit_tree() -> void:
	if is_instance_valid(control):
		control.queue_free()

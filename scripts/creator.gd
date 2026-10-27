extends CanvasLayer

# The character creation screen: a big preview and rows of colours to tap.

signal done(look: Dictionary)

const Hud := preload("res://scripts/hud.gd")
const Art := preload("res://scripts/art.gd")

const SKINS := ["ffdbac", "f1c27d", "e0ac69", "c68642", "8d5524"]
const HAIRS := ["2a1a10", "5a3a1a", "a0602a", "e8c860", "c04020", "202020", "f0f0f0", "7050c0"]
const CLOTHES := ["a08a70", "e53935", "fb8c00", "fdd835", "43a047", "1e88e5", "8e24aa", "ec407a", "f5f5f5", "37474f"]
const PANTS := ["6d5a3a", "37474f", "3a5a9a", "2e7d32", "c62828"]
const STYLES := [["short", "Courts"], ["long", "Queue de cheval"]]

var look := {
	"name": "", "skin": Color("f1c27d"), "hair": Color("5a3a1a"), "shirt": Color("a08a70"),
	"pants": Color("6d5a3a"), "style": "short", "cap": Color("a08a70"),
}
var previews: Array[TextureRect] = []
var name_edit: LineEdit
var time := 0.0


func _ready() -> void:
	layer = 3
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Hud.make_theme()
	add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0.1, 0.2, 0.15, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	panel.add_child(columns)

	# Left: the character, seen from the front, the side and the back.
	var left := VBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_child(left)
	var title := Label.new()
	title.text = "Crée ton personnage"
	title.add_theme_font_size_override("font_size", 26)
	left.add_child(title)
	var figures := HBoxContainer.new()
	figures.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(figures)
	for i in 3:
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(96, 128) if i > 0 else Vector2(144, 192)
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.size_flags_vertical = Control.SIZE_SHRINK_END
		figures.add_child(preview)
		previews.append(preview)
	var name_title := Label.new()
	name_title.text = "Ton prénom"
	left.add_child(name_title)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Écris ton prénom"
	name_edit.max_length = 14
	name_edit.custom_minimum_size = Vector2(300, 52)
	name_edit.add_theme_font_size_override("font_size", 22)
	left.add_child(name_edit)

	# Right: the choices.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	_swatches(right, "Peau", SKINS, "skin")
	_styles(right)
	_swatches(right, "Cheveux", HAIRS, "hair")
	_swatches(right, "Chapeau", CLOTHES, "cap")
	_swatches(right, "Chemise", CLOTHES, "shirt")
	_swatches(right, "Short", PANTS, "pants")
	var go := Button.new()
	go.text = "C'est parti !"
	go.custom_minimum_size = Vector2(0, 64)
	go.add_theme_font_size_override("font_size", 24)
	go.focus_mode = Control.FOCUS_NONE
	go.pressed.connect(_finish)
	right.add_child(go)
	_update()


func _swatches(parent: Control, title: String, colors: Array, key: String) -> Control:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var label := Label.new()
	label.text = title
	box.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var group := ButtonGroup.new()
	for hex in colors:
		var color := Color(hex)
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(48, 48)
		var fill := StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(8)
		fill.border_color = Color("3a2410")
		fill.set_border_width_all(2)
		var chosen: StyleBoxFlat = fill.duplicate()
		chosen.border_color = Color("f0c040")
		chosen.set_border_width_all(5)
		button.add_theme_stylebox_override("normal", fill)
		button.add_theme_stylebox_override("hover", fill)
		button.add_theme_stylebox_override("pressed", chosen)
		button.add_theme_stylebox_override("hover_pressed", chosen)
		button.button_pressed = color.is_equal_approx(look[key])
		button.pressed.connect(func() -> void:
			look[key] = color
			_update())
		row.add_child(button)
	return box


func _styles(parent: Control) -> void:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var label := Label.new()
	label.text = "Coiffure"
	box.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var group := ButtonGroup.new()
	for style in STYLES:
		var button := Button.new()
		button.text = style[1]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(120, 48)
		button.button_pressed = look.style == style[0] or (look.style == "cap" and style[0] == "short")
		button.pressed.connect(func() -> void:
			look.style = style[0]
			_update())
		row.add_child(button)


# The colours as the sprites expect them. (Characters made before the explorer had a "cap"
# style: they get short hair and a hat of their cap colour.)
static func colors_of(data: Dictionary) -> Dictionary:
	return {"hair": data.hair, "skin": data.skin, "shirt": data.shirt, "pants": data.pants,
		"style": "long" if data.style == "long" else "short", "hat": data.get("cap", Art.KHAKI)}


func _update() -> void:
	var colors := colors_of(look)
	var frame := int(time * 6.0) % 4
	previews[0].texture = Art.hero("down", frame, colors)
	previews[1].texture = Art.hero("side", frame, colors)
	previews[2].texture = Art.hero("up", frame, colors)


func _process(delta: float) -> void:
	var before := int(time * 6.0)
	time += delta
	if int(time * 6.0) != before:
		_update()


func _finish() -> void:
	look.name = name_edit.text.strip_edges()
	if look.name == "":
		look.name = "Explorateur"
	done.emit(look)
	queue_free()

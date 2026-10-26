extends CanvasLayer

# The title screen: continue the adventure, start a new one, or build freely in creative mode.

signal chosen(choice: String)  # "continue", "new", "creative"

const Hud := preload("res://scripts/hud.gd")
const Art := preload("res://scripts/art.gd")

var has_save := false


func _ready() -> void:
	layer = 3
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Hud.make_theme()
	add_child(root)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 14)
	root.add_child(column)

	var title := Label.new()
	title.text = "DINO PARC"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color("fff3c0"))
	title.add_theme_constant_override("outline_size", 18)
	title.add_theme_color_override("font_outline_color", Color("405878"))
	column.add_child(title)

	var dinos := HBoxContainer.new()
	dinos.alignment = BoxContainer.ALIGNMENT_CENTER
	dinos.add_theme_constant_override("separation", 24)
	column.add_child(dinos)
	for id in ["triceratops", "trex", "pteranodon", "stegosaurus"]:
		var picture := TextureRect.new()
		picture.texture = Art.icon("dino:" + id)
		picture.custom_minimum_size = Vector2(96, 96)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dinos.add_child(picture)

	if has_save:
		_choice(column, "Continuer l'aventure", "continue")
	_choice(column, "Nouvelle aventure", "new")
	_choice(column, "Mode créatif", "creative")


func _choice(parent: Control, text: String, choice: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 72)
	button.add_theme_font_size_override("font_size", 26)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		chosen.emit(choice)
		queue_free())
	parent.add_child(button)

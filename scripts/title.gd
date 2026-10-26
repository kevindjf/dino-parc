extends CanvasLayer

# The title screen: the list of worlds to play, and the screen to create a new one,
# like in Minecraft. A world is either an adventure or a sandbox park.

signal chosen(info: Dictionary)  # the world to play (just created or picked in the list)

const Hud := preload("res://scripts/hud.gd")
const Art := preload("res://scripts/art.gd")
const Worlds := preload("res://scripts/worlds.gd")

const MODE_TEXT := {
	"adventure": "Explore, récolte et attrape des dinos",
	"creative": "Construis ton parc comme tu veux",
}
const MODE_ICON := {"adventure": "dino:trex", "creative": "dino:triceratops"}

var page: VBoxContainer  # the part under the title, replaced when going from one screen to another


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
		dinos.add_child(_picture("dino:" + id, 80))

	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	column.add_child(page)
	if Worlds.list().is_empty():
		_show_create()
	else:
		_show_list()
	_check_for_update()


# On the web the game is kept by the browser to start fast. When a new version has been
# published, the browser fetches it in the background: install it while on the title screen,
# where nothing is being played (it reloads the page).
func _check_for_update() -> void:
	if not OS.has_feature("web"):
		return
	if JavaScriptBridge.pwa_needs_update():
		_update()
	else:
		JavaScriptBridge.pwa_update_available.connect(_update)


func _update() -> void:
	_clear_page()
	_heading("Nouvelle version du jeu !\nMise à jour…")
	JavaScriptBridge.pwa_update()


func _clear_page() -> void:
	for child in page.get_children():
		page.remove_child(child)
		child.queue_free()


# The worlds already made, the last played on top, and a button to make a new one.
func _show_list() -> void:
	_clear_page()
	_heading("Mes mondes")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	for info in Worlds.list():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		rows.add_child(row)
		var play := _button(row, "", 22, func() -> void: _play(info))
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.custom_minimum_size.y = 84
		play.icon = Art.icon(MODE_ICON[info.mode])
		play.expand_icon = false
		play.alignment = HORIZONTAL_ALIGNMENT_LEFT
		play.text = "  %s\n  %s · %s" % [info.name, Worlds.MODES[info.mode], Worlds.played_text(info)]
		var remove := _button(row, "Supprimer", 16, func() -> void: _show_delete(info))
		remove.custom_minimum_size = Vector2(110, 84)
	var create := _button(page, "Créer un nouveau monde", 26, _show_create)
	create.custom_minimum_size.y = 72


# Name the world, choose its mode and its settings.
func _show_create() -> void:
	_clear_page()
	var panel := PanelContainer.new()
	page.add_child(panel)
	var form := VBoxContainer.new()
	form.custom_minimum_size.x = 640
	form.add_theme_constant_override("separation", 10)
	panel.add_child(form)
	var heading := _label(form, "Nouveau monde", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_label(form, "Nom du monde", 18)
	var name_edit := LineEdit.new()
	name_edit.text = Worlds.unique_name("Mon monde")
	name_edit.max_length = 24
	name_edit.select_all_on_focus = true
	name_edit.custom_minimum_size = Vector2(0, 56)
	name_edit.add_theme_font_size_override("font_size", 24)
	form.add_child(name_edit)

	_label(form, "Mode de jeu", 18)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 10)
	form.add_child(modes)
	var settings_box := VBoxContainer.new()
	var choice := {"mode": "adventure", "settings": Worlds.defaults("adventure")}
	var group := ButtonGroup.new()
	for mode in Worlds.MODES:
		var button := _button(modes, "%s\n%s" % [Worlds.MODES[mode], MODE_TEXT[mode]], 18, func() -> void:
			choice.mode = mode
			choice.settings = Worlds.defaults(mode)
			_fill_settings(settings_box, mode, choice.settings))
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = mode == choice.mode
		button.icon = Art.icon(MODE_ICON[mode])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 96
	form.add_child(settings_box)
	_fill_settings(settings_box, choice.mode, choice.settings)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	form.add_child(buttons)
	if not Worlds.list().is_empty():
		_button(buttons, "Retour", 22, _show_list).custom_minimum_size = Vector2(160, 64)
	var go := _button(buttons, "Créer le monde", 24, func() -> void:
		var world_name := name_edit.text.strip_edges()
		if world_name == "":
			world_name = Worlds.unique_name("Mon monde")
		_play(Worlds.create(world_name, choice.mode, choice.settings)))
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size.y = 64


# One switch or one row of choices per setting of the chosen mode.
func _fill_settings(box: VBoxContainer, mode: String, settings: Dictionary) -> void:
	for child in box.get_children():
		child.queue_free()
	for setting in Worlds.SETTINGS:
		if not mode in setting.modes:
			continue
		match setting.type:
			"bool":
				var check := CheckButton.new()
				check.text = setting.label
				check.button_pressed = settings[setting.key]
				check.focus_mode = Control.FOCUS_NONE
				check.add_theme_font_size_override("font_size", 18)
				check.toggled.connect(func(on: bool) -> void: settings[setting.key] = on)
				box.add_child(check)
			"choice":
				_label(box, setting.label, 18)
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 8)
				box.add_child(row)
				var group := ButtonGroup.new()
				for option in setting.options:
					var button := _button(row, option[1], 18, func() -> void: settings[setting.key] = option[0])
					button.toggle_mode = true
					button.button_group = group
					button.button_pressed = settings[setting.key] == option[0]
					button.custom_minimum_size.y = 52


func _show_delete(info: Dictionary) -> void:
	_clear_page()
	var panel := PanelContainer.new()
	page.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 640
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var question := _label(box, "Supprimer le monde « %s » ?\nIl sera perdu pour toujours." % info.name, 24)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)
	var keep := _button(buttons, "Non, je le garde", 22, _show_list)
	keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep.custom_minimum_size.y = 64
	var remove := _button(buttons, "Oui, supprimer", 22, func() -> void:
		Worlds.delete(info.id)
		if Worlds.list().is_empty():
			_show_create()
		else:
			_show_list())
	remove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove.custom_minimum_size.y = 64
	remove.add_theme_color_override("font_color", Color("c62828"))


func _play(info: Dictionary) -> void:
	chosen.emit(info)
	queue_free()


func _heading(text: String) -> void:
	var label := _label(page, text, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("fff3c0"))
	label.add_theme_constant_override("outline_size", 10)
	label.add_theme_color_override("font_outline_color", Color("405878"))


func _label(parent: Control, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, size: int, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", size)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _picture(id: String, size: int) -> TextureRect:
	var picture := TextureRect.new()
	picture.texture = Art.icon(id)
	picture.custom_minimum_size = Vector2(size, size)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return picture

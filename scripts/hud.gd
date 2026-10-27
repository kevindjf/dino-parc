extends CanvasLayer

# The interface, rustic like the world: parchment windows in wooden frames and plank buttons
# (drawn in ui_skin.gd).

signal tool_selected(id: String)
signal zoom_requested(direction: int)
signal exit_vehicle
signal menu_requested
signal pen_toggled(on: bool)
signal undo_requested

const Catalog := preload("res://scripts/catalog.gd")
const Art := preload("res://scripts/art.gd")
const UiSkin := preload("res://scripts/ui_skin.gd")
const INK := UiSkin.INK

var money_label: Label
var visitors_label: Label
var goal_label: Label
var message_label: Label
var message_panel: PanelContainer
var info_label: Label
var exit_button: Button
var item_row: HBoxContainer
var message_tween: Tween
var tool_group := ButtonGroup.new()
var current_tool := "path"
var pen_button: Button


func _ready() -> void:
	layer = 2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = make_theme()
	add_child(root)
	_build_top_bar(root)
	_build_toolbar(root)
	_build_info(root)
	_build_drawing_tools(root)

	message_panel = PanelContainer.new()
	message_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_panel.offset_top = 84
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.modulate.a = 0.0
	root.add_child(message_panel)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_panel.add_child(message_label)


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 15
	theme.set_stylebox("panel", "PanelContainer", UiSkin.panel())
	for state in ["normal", "hover", "pressed", "disabled"]:
		theme.set_stylebox(state, "Button", UiSkin.button(state))
	theme.set_stylebox("hover_pressed", "Button", UiSkin.button("pressed"))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	# Letters carved in the wood: cream with a dark brown contour, golden on the chosen one.
	for state in ["font_color", "font_hover_color", "font_focus_color"]:
		theme.set_color(state, "Button", UiSkin.CREAM)
	for state in ["font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, "Button", Color("ffe48a"))
	theme.set_color("font_disabled_color", "Button", Color("e0d8c8"))
	theme.set_color("font_outline_color", "Button", Color("3a2410"))
	theme.set_constant("outline_size", "Button", 4)
	theme.set_color("font_color", "Label", INK)
	theme.set_stylebox("normal", "LineEdit", UiSkin.field(false))
	theme.set_stylebox("focus", "LineEdit", UiSkin.field(true))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color("a08a68"))
	for check in ["CheckButton", "CheckBox"]:
		theme.set_color("font_color", check, INK)
		theme.set_color("font_hover_color", check, INK)
		theme.set_color("font_pressed_color", check, INK)
		theme.set_color("font_hover_pressed_color", check, INK)
	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", bar, UiSkin.bar(Color("d8c49c")))
		theme.set_stylebox("grabber", bar, UiSkin.bar(UiSkin.WOOD.normal))
		theme.set_stylebox("grabber_highlight", bar, UiSkin.bar(UiSkin.WOOD.hover))
		theme.set_stylebox("grabber_pressed", bar, UiSkin.bar(UiSkin.WOOD.pressed))
	return theme


func _build_top_bar(root: Control) -> void:
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 8
	top.offset_right = -8
	top.offset_top = 8
	root.add_child(top)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 22)
	top.add_child(stats)
	money_label = _label(stats, 20)
	visitors_label = _label(stats, 15)
	goal_label = _label(stats, 15)
	goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.add_theme_color_override("font_color", Color("b03018"))
	exit_button = _small_button(stats, "Descendre (Échap)")
	exit_button.pressed.connect(func() -> void: exit_vehicle.emit())
	exit_button.visible = false
	var menu := _small_button(stats, "Menu")
	menu.custom_minimum_size.x = 76
	menu.pressed.connect(func() -> void: menu_requested.emit())
	for direction in [-1, 1]:
		var zoom := _small_button(stats, "Zoom −" if direction < 0 else "Zoom +")
		zoom.custom_minimum_size.x = 76
		zoom.pressed.connect(func() -> void: zoom_requested.emit(direction))


func _build_toolbar(root: Control) -> void:
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_left = 8
	bottom.offset_right = -8
	bottom.offset_bottom = -8
	root.add_child(bottom)
	var column := VBoxContainer.new()
	bottom.add_child(column)

	var tabs_scroll := ScrollContainer.new()
	tabs_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs_scroll.custom_minimum_size.y = 40
	column.add_child(tabs_scroll)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	tabs_scroll.add_child(tabs)
	var tab_group := ButtonGroup.new()
	for i in Catalog.CATEGORIES.size():
		var tab := Button.new()
		tab.text = Catalog.CATEGORIES[i].name
		tab.toggle_mode = true
		tab.button_group = tab_group
		tab.focus_mode = Control.FOCUS_NONE
		tab.custom_minimum_size = Vector2(0, 36)
		tab.add_theme_font_size_override("font_size", 14)
		tab.button_pressed = i == 0
		tab.pressed.connect(func() -> void: _show_category(i))
		tabs.add_child(tab)

	var items_scroll := ScrollContainer.new()
	items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	items_scroll.custom_minimum_size.y = 64
	column.add_child(items_scroll)
	item_row = HBoxContainer.new()
	item_row.add_theme_constant_override("separation", 6)
	items_scroll.add_child(item_row)
	_show_category(0)


func _build_info(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 8
	panel.offset_bottom = -140
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	info_label = Label.new()
	info_label.custom_minimum_size.x = 440
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 14)
	panel.add_child(info_label)


# The same helpers as the building mode of the adventure: whole enclosures, eraser, undo.
func _build_drawing_tools(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -8
	panel.offset_bottom = -140
	root.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	pen_button = _small_button(row, "Enclos")
	pen_button.toggle_mode = true
	pen_button.tooltip_text = "Avec une barrière : tire d'un coin à l'autre pour faire tout l'enclos, avec un portail"
	pen_button.toggled.connect(func(on: bool) -> void: pen_toggled.emit(on))
	var eraser := _small_button(row, "Gomme")
	eraser.pressed.connect(func() -> void:
		current_tool = "bulldozer"
		tool_selected.emit("bulldozer"))
	var undo := _small_button(row, "Annuler")
	undo.pressed.connect(func() -> void: undo_requested.emit())


func _show_category(index: int) -> void:
	for child in item_row.get_children():
		child.queue_free()
	for id in Catalog.CATEGORIES[index].tools:
		var info := Catalog.tool_info(id)
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = tool_group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150, 58)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = info.name if info.cost == 0 else "%s\n%d pièces" % [info.name, info.cost]
		button.icon = Art.icon(id)
		button.tooltip_text = info.info
		button.add_theme_font_size_override("font_size", 13)
		button.button_pressed = id == current_tool
		button.pressed.connect(func() -> void:
			current_tool = id
			tool_selected.emit(id))
		item_row.add_child(button)


func update_stats(money: int, on_site: int, total: int, attraction: int) -> void:
	money_label.text = "Pièces : %d" % money
	visitors_label.text = "Visiteurs : %d (total %d)\nAttractivité : %d" % [on_site, total, attraction]


func set_goal(text: String) -> void:
	goal_label.text = text


func set_info(text: String) -> void:
	info_label.text = text
	info_label.get_parent().visible = text != ""


func set_driving(driving: bool) -> void:
	exit_button.visible = driving


func flash(text: String, duration := 1.5) -> void:
	message_label.text = text
	message_panel.reset_size()
	message_panel.modulate.a = 1.0
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(duration)
	message_tween.tween_property(message_panel, "modulate:a", 0.0, 0.5)


func _label(parent: Control, size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _small_button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(96, 44)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	return button

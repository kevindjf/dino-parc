extends CanvasLayer

# The screen of the adventure mode, made for tablets first: a joystick on the left, a big action
# button on the right, the tool bar at the bottom and the bag in the middle.
# Keyboard: arrows / ZQSD to walk, Espace to act, 1 to 8 to change tool, I or Tab for the bag.

const Hud := preload("res://scripts/hud.gd")
const Art := preload("res://scripts/art.gd")
const Items := preload("res://scripts/items.gd")
const Catalog := preload("res://scripts/catalog.gd")
const TouchStick := preload("res://scripts/touch_stick.gd")
const TouchButton := preload("res://scripts/touch_button.gd")
const Market := preload("res://scripts/market.gd")

var park: Node2D
var inventory: RefCounted
var root: Control
var stick: Control
var action: Control
var name_label: Label
var money_label: Label
var hearts_row: HBoxContainer
var visitors_label: Label
var goal_label: Label
var slots: Array[Button] = []
var bag: PanelContainer
var bag_grid: GridContainer
var recipe_list: VBoxContainer
var message_panel: PanelContainer
var message_label: Label
var message_tween: Tween
var bag_open := false
var riding := false
var dex: PanelContainer
var hotbar_panel: PanelContainer
var bag_button: Control
var build_button: Control
var builder: Node2D
var build_panel: PanelContainer
var build_status: Label
var build_items: HBoxContainer
var build_tools := {}  # tool id -> Button
var pocket: PanelContainer  # "Mes dinos": the caught dinosaurs, waiting to be released
var pocket_grid: GridContainer
var dex_grid: GridContainer
var shop: PanelContainer  # the shop of the village
var shop_grid: GridContainer
var shop_money: Label
var shop_tabs := {}  # "buy" / "sell" -> Button
var shop_selling := false
var dex_title: Label


func setup(owner_park: Node2D, player_inventory: RefCounted, player_name: String) -> void:
	park = owner_park
	inventory = player_inventory
	layer = 2
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Hud.make_theme()
	add_child(root)
	_build_top(player_name)
	_build_controls()
	_build_hotbar()
	_build_bag()
	_build_dex()
	_build_pocket()
	_build_shop()
	_build_message()
	inventory.changed.connect(_refresh)
	_refresh()


# --- Layout -----------------------------------------------------------------

func _build_top(player_name: String) -> void:
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 8
	top.offset_right = -8
	top.offset_top = 8
	root.add_child(top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	top.add_child(row)
	name_label = _label(row, player_name, 20)
	name_label.add_theme_color_override("font_color", Color("2860c0"))
	hearts_row = HBoxContainer.new()
	hearts_row.add_theme_constant_override("separation", 2)
	row.add_child(hearts_row)
	money_label = _label(row, "", 18)
	visitors_label = _label(row, "", 14)
	goal_label = _label(row, "", 15)
	goal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_label.add_theme_color_override("font_color", Color("b03018"))
	_button(row, "Sac", 80, toggle_bag)
	_button(row, "Mes dinos", 110, toggle_pocket)
	_button(row, "Dinodex", 100, toggle_dex)
	_button(row, "Menu", 80, park.back_to_menu)
	_button(row, "Zoom −", 80, func() -> void: park.camera.zoom_step(-1))
	_button(row, "Zoom +", 80, func() -> void: park.camera.zoom_step(1))


func _build_controls() -> void:
	stick = TouchStick.new()
	stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stick.grow_vertical = Control.GROW_DIRECTION_BEGIN
	stick.offset_left = 20
	stick.offset_bottom = -20
	root.add_child(stick)

	action = TouchButton.new()
	action.setup("Action", 60.0, Color("e85a4a"))
	action.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	action.grow_vertical = Control.GROW_DIRECTION_BEGIN
	action.offset_right = -24
	action.offset_bottom = -28
	root.add_child(action)

	bag_button = TouchButton.new()
	bag_button.setup("Sac", 36.0, Color("4a7ad8"))
	bag_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	bag_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	bag_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bag_button.offset_right = -160
	bag_button.offset_bottom = -110
	bag_button.pressed.connect(toggle_bag)
	root.add_child(bag_button)


func _build_hotbar() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -10
	root.add_child(panel)
	hotbar_panel = panel
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	var group := ButtonGroup.new()
	for i in inventory.SLOTS:
		var slot := Button.new()
		slot.toggle_mode = true
		slot.button_group = group
		slot.focus_mode = Control.FOCUS_NONE
		slot.custom_minimum_size = Vector2(66, 72)
		slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		slot.add_theme_font_size_override("font_size", 13)
		slot.pressed.connect(func() -> void: inventory.select(i))
		row.add_child(slot)
		slots.append(slot)


func _build_bag() -> void:
	bag = PanelContainer.new()
	bag.set_anchors_preset(Control.PRESET_CENTER)
	bag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bag.grow_vertical = Control.GROW_DIRECTION_BOTH
	bag.custom_minimum_size = Vector2(860, 500)
	bag.visible = false
	root.add_child(bag)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	bag.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label(header, "Mon sac", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Fermer", 110, toggle_bag)
	var hint := _label(column, "Touche un objet pour le mettre dans la case choisie de ta barre d'outils.", 14)
	hint.add_theme_color_override("font_color", Color("607080"))

	var halves := HBoxContainer.new()
	halves.add_theme_constant_override("separation", 16)
	halves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(halves)
	var left := ScrollContainer.new()
	left.custom_minimum_size = Vector2(420, 380)
	left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	halves.add_child(left)
	bag_grid = GridContainer.new()
	bag_grid.columns = 4
	bag_grid.add_theme_constant_override("h_separation", 6)
	bag_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(bag_grid)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	halves.add_child(right)
	_label(right, "Fabriquer", 20)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	recipe_list = VBoxContainer.new()
	recipe_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_list.add_theme_constant_override("separation", 6)
	scroll.add_child(recipe_list)


func _build_message() -> void:
	message_panel = PanelContainer.new()
	message_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_panel.offset_top = 90
	message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_panel.modulate.a = 0.0
	root.add_child(message_panel)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_panel.add_child(message_label)


# --- Updates --------------------------------------------------------------------

func _refresh() -> void:
	for i in slots.size():
		var id: String = inventory.hotbar[i]
		var slot := slots[i]
		slot.button_pressed = i == inventory.selected
		slot.icon = Art.bag_icon(id)
		if id == "":
			slot.text = ""
		elif Items.kind_of(id) == "tool":
			slot.text = ""
		elif Items.kind_of(id) == "weapon":
			slot.text = "×%d" % inventory.count(Items.WEAPONS[id].ammo)
		else:
			slot.text = "×%d" % inventory.count(id)
		slot.modulate.a = 0.45 if id != "" and inventory.count(id) == 0 else 1.0
	var current: String = inventory.current()
	action.caption = "Descendre" if riding else Items.name_of(current)
	action.set_icon(Art.resource("saddle") if riding else Art.bag_icon(current))
	if bag_open:
		_fill_bag()


func _fill_bag() -> void:
	for child in bag_grid.get_children():
		child.queue_free()
	var ids: Array = inventory.counts.keys().filter(func(id: String) -> bool: return Items.kind_of(id) != "dino")
	if ids.is_empty():
		_label(bag_grid, "Ton sac est vide.\nFrappe un arbre pour avoir du bois !", 15)
	for id in ids:
		var button := Button.new()
		button.custom_minimum_size = Vector2(100, 92)
		button.focus_mode = Control.FOCUS_NONE
		button.icon = Art.bag_icon(id)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.text = "%s\n×%d" % [Items.name_of(id), inventory.count(id)]
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(func() -> void:
			inventory.assign(id)
			flash("%s dans la case %d" % [Items.name_of(id), inventory.selected + 1], 1.0))
		bag_grid.add_child(button)

	for child in recipe_list.get_children():
		child.queue_free()
	for recipe in Items.RECIPES:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		recipe_list.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Art.bag_icon(recipe.make)
		icon.custom_minimum_size = Vector2(44, 44)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		var text := _label(row, "%s%s\n%s" % [Items.name_of(recipe.make), " ×%d" % recipe.count if recipe.count > 1 else "",
			Items.describe_needs(recipe.needs)], 13)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ok: bool = inventory.has_all(recipe.needs)
		var make := _button(row, "Fabriquer", 110, func() -> void:
			if inventory.craft(recipe):
				flash("Tu as fabriqué : %s !" % Items.name_of(recipe.make), 1.5))
		make.disabled = not ok


func toggle_bag() -> void:
	bag_open = not bag_open
	bag.visible = bag_open
	dex.visible = false
	pocket.visible = false
	shop.visible = false
	if bag_open:
		_fill_bag()


# --- The Dinodex: every species, coloured once caught ------------------------------------

func _build_dex() -> void:
	dex = PanelContainer.new()
	dex.set_anchors_preset(Control.PRESET_CENTER)
	dex.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dex.grow_vertical = Control.GROW_DIRECTION_BOTH
	dex.visible = false
	root.add_child(dex)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	dex.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	dex_title = _label(header, "", 24)
	dex_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Fermer", 110, toggle_dex)
	dex_grid = GridContainer.new()
	dex_grid.columns = 7
	dex_grid.add_theme_constant_override("h_separation", 8)
	dex_grid.add_theme_constant_override("v_separation", 8)
	column.add_child(dex_grid)


func toggle_dex() -> void:
	dex.visible = not dex.visible
	pocket.visible = false
	if bag_open:
		bag_open = false
		bag.visible = false
	if not dex.visible:
		return
	for child in dex_grid.get_children():
		child.queue_free()
	dex_title.text = "Dinodex : %d / %d espèces" % [park.caught.size(), Catalog.DINOS.size()]
	for id in Catalog.DINOS:
		var known: bool = park.caught.has(id)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(108, 0)
		dex_grid.add_child(cell)
		var picture := TextureRect.new()
		picture.texture = Art.icon("dino:" + id)
		picture.custom_minimum_size = Vector2(64, 56)
		picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		# Unknown species are shown as a black shadow, like in the games.
		picture.modulate = Color.WHITE if known else Color(0.1, 0.12, 0.18, 0.75)
		cell.add_child(picture)
		var name := _label(cell, Catalog.DINOS[id].name if known else "???", 12)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var where: String = Catalog.BIOMES[Catalog.DINOS[id].biome].name if Catalog.DINOS[id].has("biome") else \
			("Volière" if Catalog.DINOS[id].habitat == "air" else "Lagon")
		var hint := _label(cell, where, 11)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color("708090"))


# --- The building mode ------------------------------------------------------------

func setup_builder(owner_builder: Node2D) -> void:
	builder = owner_builder
	builder.changed.connect(refresh_build)
	inventory.changed.connect(refresh_build)
	build_button = TouchButton.new()
	build_button.setup("Construire", 36.0, Color("e09030"))
	build_button.set_icon(Art.resource("hammer"))
	build_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	build_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	build_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	build_button.offset_right = -60
	build_button.offset_bottom = -190
	build_button.pressed.connect(toggle_build)
	root.add_child(build_button)

	build_panel = PanelContainer.new()
	build_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	build_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	build_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	build_panel.offset_bottom = -10
	build_panel.visible = false
	root.add_child(build_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	build_panel.add_child(column)
	build_status = _label(column, "", 16)
	build_status.custom_minimum_size.x = 760
	build_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	build_items = HBoxContainer.new()
	build_items.add_theme_constant_override("separation", 6)
	column.add_child(build_items)
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 6)
	column.add_child(tools)
	var group := ButtonGroup.new()
	for entry in [["draw", "Tracer"], ["pen", "Enclos"], ["erase", "Gomme"]]:
		var button := _button(tools, entry[1], 120, builder.set_tool.bind(entry[0]))
		button.toggle_mode = true
		button.button_group = group
		button.custom_minimum_size.y = 52
		build_tools[entry[0]] = button
	_button(tools, "Annuler", 120, builder.undo).custom_minimum_size.y = 52
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(spacer)
	_button(tools, "Terminé", 140, toggle_build).custom_minimum_size.y = 52


func toggle_build() -> void:
	if builder.active:
		builder.close()
	elif park.away == null and park.player.mount == null:
		if bag_open:
			toggle_bag()
		dex.visible = false
		pocket.visible = false
		builder.open()


func refresh_build() -> void:
	if builder == null:
		return
	var building: bool = builder.active
	build_panel.visible = building
	hotbar_panel.visible = not building
	action.visible = not building
	bag_button.visible = not building
	build_button.visible = not building and park.away == null
	if not building:
		return
	build_status.text = builder.status()
	for child in build_items.get_children():
		child.queue_free()
	var group := ButtonGroup.new()
	for id in builder.buildable():
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = id == builder.item
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(66, 72)
		button.icon = Art.bag_icon(id)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.text = "×%d" % inventory.count(id)
		button.add_theme_font_size_override("font_size", 13)
		button.tooltip_text = Items.name_of(id)
		button.pressed.connect(builder.choose.bind(id))
		build_items.add_child(button)
	if builder.buildable().is_empty():
		_label(build_items, "Rien à poser : fabrique des barrières, un chemin ou une mangeoire dans le Sac.", 14)
	for id in build_tools:
		build_tools[id].button_pressed = id == builder.tool
	build_tools["pen"].disabled = not builder._is_fence(builder.item)


func _build_pocket() -> void:
	pocket = PanelContainer.new()
	pocket.set_anchors_preset(Control.PRESET_CENTER)
	pocket.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pocket.grow_vertical = Control.GROW_DIRECTION_BOTH
	pocket.custom_minimum_size = Vector2(760, 0)
	pocket.visible = false
	root.add_child(pocket)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	pocket.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := _label(header, "Mes dinos", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Fermer", 110, toggle_pocket)
	var hint := _label(column, "Les dinos que tu as attrapés t'attendent ici. Touche « Relâcher », puis vise une case libre dans un enclos et appuie sur Action.", 14)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("607080"))
	pocket_grid = GridContainer.new()
	pocket_grid.columns = 5
	pocket_grid.add_theme_constant_override("h_separation", 10)
	pocket_grid.add_theme_constant_override("v_separation", 10)
	column.add_child(pocket_grid)


func toggle_pocket() -> void:
	pocket.visible = not pocket.visible
	dex.visible = false
	shop.visible = false
	if bag_open:
		bag_open = false
		bag.visible = false
	if pocket.visible:
		_fill_pocket()


func _fill_pocket() -> void:
	for child in pocket_grid.get_children():
		child.queue_free()
	var dinos: Dictionary = inventory.dinos()
	if dinos.is_empty():
		_label(pocket_grid, "Tu n'as pas encore de dino.\nLance 3 baies à un herbivore, ou attrape un dino avec une capsule !", 16)
		return
	for id in dinos:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(136, 0)
		pocket_grid.add_child(cell)
		var picture := TextureRect.new()
		picture.texture = Art.icon("dino:" + id)
		picture.custom_minimum_size = Vector2(120, 80)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(picture)
		var name := _label(cell, "%s%s" % [Catalog.DINOS[id].name, " ×%d" % dinos[id] if dinos[id] > 1 else ""], 14)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var release := _button(cell, "Relâcher", 136, func() -> void:
			inventory.hold("dino:" + id)
			toggle_pocket()
			flash("%s est dans ta main !\nVise une case libre dans un enclos et appuie sur Action." % Catalog.DINOS[id].name, 3.0))
		release.custom_minimum_size.y = 48


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_I, KEY_TAB:
			toggle_bag()
		KEY_B:
			if builder != null:
				toggle_build()
		KEY_ESCAPE:
			if builder != null and builder.active:
				toggle_build()
			elif bag_open:
				toggle_bag()
			elif dex.visible:
				toggle_dex()
			elif pocket.visible:
				toggle_pocket()
			elif shop.visible:
				close_shop()
		_:
			if event.keycode >= KEY_1 and event.keycode <= KEY_8:
				inventory.select(event.keycode - KEY_1)


# --- The shop of the village: buy with coins, sell what you have too much of ------------

func _build_shop() -> void:
	shop = PanelContainer.new()
	shop.set_anchors_preset(Control.PRESET_CENTER)
	shop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	shop.grow_vertical = Control.GROW_DIRECTION_BOTH
	shop.custom_minimum_size = Vector2(860, 520)
	shop.visible = false
	root.add_child(shop)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	shop.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	_label(header, "Boutique", 24)
	var group := ButtonGroup.new()
	for entry in [["buy", "Acheter"], ["sell", "Vendre"]]:
		var tab := _button(header, entry[1], 120, func() -> void:
			shop_selling = entry[0] == "sell"
			_fill_shop())
		tab.toggle_mode = true
		tab.button_group = group
		shop_tabs[entry[0]] = tab
	shop_money = _label(header, "", 20)
	shop_money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shop_money.add_theme_color_override("font_color", Color("a07000"))
	_button(header, "Fermer", 110, close_shop)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	shop_grid = GridContainer.new()
	shop_grid.columns = 5
	shop_grid.add_theme_constant_override("h_separation", 8)
	shop_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(shop_grid)


func open_shop() -> void:
	if bag_open:
		toggle_bag()
	dex.visible = false
	pocket.visible = false
	shop_selling = false
	shop.visible = true
	_fill_shop()


func close_shop() -> void:
	shop.visible = false


func _fill_shop() -> void:
	shop_tabs.buy.button_pressed = not shop_selling
	shop_tabs.sell.button_pressed = shop_selling
	shop_money.text = "Tes pièces : %d" % park.money
	for child in shop_grid.get_children():
		child.queue_free()
	if shop_selling:
		var any := false
		for id in Market.SELL:
			if inventory.count(id) > 0:
				any = true
				_sell_card(id)
		if not any:
			_label(shop_grid, "Tu n'as rien à vendre.\nLe marchand achète le bois, les pierres, les baies,\nles minerais et les fossiles.", 16)
		return
	for entry in Market.BUY:
		_buy_card(entry)


# One thing for sale: its picture, its name, and a button with its price.
func _buy_card(entry: Dictionary) -> void:
	var card := _shop_card(entry.id, "%s%s" % [Items.name_of(entry.id), " ×%d" % entry.count if entry.count > 1 else ""])
	var price := _button(card, "%d pièces" % entry.price, 150, func() -> void:
		if park.buy(entry):
			flash("Tu as acheté : %s !" % Items.name_of(entry.id), 1.5)
		else:
			flash("Pas assez de pièces !", 1.5)
		_fill_shop())
	price.custom_minimum_size.y = 48
	if park.money < entry.price:
		price.modulate = Color(1, 1, 1, 0.5)


func _sell_card(id: String) -> void:
	var count: int = inventory.count(id)
	var each: int = Market.SELL[id]
	var card := _shop_card(id, "%s ×%d" % [Items.name_of(id), count])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	card.add_child(row)
	_button(row, "1 → %d" % each, 73, func() -> void:
		park.sell(id, 1)
		_fill_shop())
	_button(row, "Tout → %d" % (each * count), 73, func() -> void:
		var earned: int = park.sell(id, count)
		flash("+%d pièces" % earned, 1.2)
		_fill_shop())
	for button in row.get_children():
		button.add_theme_font_size_override("font_size", 13)


func _shop_card(id: String, text: String) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(150, 0)
	shop_grid.add_child(card)
	var picture := TextureRect.new()
	picture.texture = Art.bag_icon(id)
	picture.custom_minimum_size = Vector2(150, 48)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	card.add_child(picture)
	var name := _label(card, text, 14)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return card


# A window is open over the game: the character waits.
func menu_open() -> bool:
	return bag_open or dex.visible or pocket.visible or shop.visible


# --- What the park expects from a HUD ----------------------------------------------

func stick_vector() -> Vector2:
	return stick.vector


func action_held() -> bool:
	return action.held


func flash(text: String, duration := 1.5) -> void:
	message_label.text = text
	message_panel.reset_size()
	message_panel.modulate.a = 1.0
	if message_tween:
		message_tween.kill()
	message_tween = create_tween()
	message_tween.tween_interval(duration)
	message_tween.tween_property(message_panel, "modulate:a", 0.0, 0.5)


func update_stats(money: int, on_site: int, total: int, _attraction: int) -> void:
	money_label.text = "Pièces : %d" % money
	visitors_label.text = "Visiteurs : %d\n(total %d)" % [on_site, total]


# The player's hearts: full ones, then empty ones.
func set_hearts(full: int, total: int) -> void:
	if hearts_row.get_child_count() != total:
		for child in hearts_row.get_children():
			child.queue_free()
		for i in total:
			var heart := TextureRect.new()
			heart.custom_minimum_size = Vector2(24, 24)
			heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hearts_row.add_child(heart)
	for i in total:
		hearts_row.get_child(i).texture = Art.heart(i < full)


func set_goal(text: String) -> void:
	goal_label.text = text


func set_riding(value: bool) -> void:
	riding = value
	_refresh()


func set_info(_text: String) -> void:
	pass


func set_driving(_driving: bool) -> void:
	pass


func _label(parent: Control, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, width: float, action_callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(width, 48)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action_callback)
	parent.add_child(button)
	return button

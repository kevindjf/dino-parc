extends Node2D

# The building mode of the adventure, made for fingers: the character waits, a grid shows on
# the land, and things are laid by touching or drawing on the screen.
#   draw:  a touch lays one thing; with fences, paths and bridges, the finger draws a line
#   pen:   from one corner to the other, a whole enclosure with a gate in the middle of a side
#   erase: takes things back into the bag (berry bushes can be dug up and planted elsewhere)
# Cells turn green where it works and red where it does not; nothing is laid before the finger
# is lifted. "Annuler" takes the last drawing back.
# Big buildings are not ready at once: scaffolding goes up, and tapping it helps the workers.

signal changed  # the HUD shows the tool, the item and the counter

const Art := preload("res://scripts/art.gd")
const Items := preload("res://scripts/items.gd")
const Catalog := preload("res://scripts/catalog.gd")
const T := 16
const NONE := Vector2i(-1, -1)
const LINES := ["fence", "path"]  # kinds that are drawn as lines
const BUILD_TIME := {"feeder": 15.0, "shop": 20.0, "staff": 20.0, "gyro_station": 30.0, "garage": 30.0, "heliport": 40.0}  # seconds of work for big buildings, by kind
const TAP_HELP := 1.5  # seconds of work saved by each tap on scaffolding
const CAMERA_SPEED := 420.0
const OK := Color(0.3, 0.9, 0.35, 0.45)
const BAD := Color(0.95, 0.25, 0.2, 0.5)

var park: Node2D
var active := false
var item := ""  # the bag item being laid
var tool := "draw"
var finger := -1  # index of the touch drawing, -1 when none
var start := NONE
var stroke: Array[Vector2i] = []
var plan: Array[Dictionary] = []  # {cell, id, ok, why}: what would be laid on lifting the finger
var history: Array[Dictionary] = []  # {cells, items}: drawings that can be taken back
var sites: Array[Dictionary] = []  # buildings under construction
var hover := NONE


func setup(owner_park: Node2D) -> void:
	park = owner_park
	z_index = 40


func open() -> void:
	active = true
	park.camera.unfollow()
	if item == "" or park.inventory.count(item) <= 0:
		var owned := buildable()
		item = owned[0] if not owned.is_empty() else ""
	changed.emit()


func close() -> void:
	active = false
	finger = -1
	stroke.clear()
	plan.clear()
	park.camera.follow(park.player)
	changed.emit()


# The things of the bag that can be laid on the land.
func buildable() -> Array:
	return park.inventory.counts.keys().filter(func(id: String) -> bool: return Items.kind_of(id) in ["build", "ground"])


func choose(id: String) -> void:
	item = id
	if tool == "pen" and not _is_fence(id):
		tool = "draw"
	changed.emit()


func set_tool(id: String) -> void:
	tool = id
	changed.emit()


# What the HUD writes above the palette.
func status() -> String:
	if not plan.is_empty():
		if tool == "erase":
			return "Gomme : %d à enlever" % plan.filter(func(p: Dictionary) -> bool: return p.ok).size()
		var needed := plan.filter(func(p: Dictionary) -> bool: return p.id == item).size()
		var have: int = park.inventory.count(item)
		var text := "%d × %s (tu en as %d)" % [needed, Items.name_of(item), have]
		var gates := plan.filter(func(p: Dictionary) -> bool: return p.id == "gate_wood").size()
		if gates > 0:
			text += " + 1 portail"
		var why := plan.filter(func(p: Dictionary) -> bool: return not p.ok)
		if not why.is_empty():
			text += "  —  " + why[0].why
		return text
	match tool:
		"pen":
			return "Enclos : tire d'un coin à l'autre"
		"erase":
			return "Gomme : touche ce que tu veux enlever"
	if item == "":
		return "Fabrique des barrières ou des chemins dans le Sac !"
	if _is_line(item):
		return "Trace avec ton doigt pour poser : %s" % Items.name_of(item)
	return "Touche le sol pour poser : %s" % Items.name_of(item)


func _is_fence(id: String) -> bool:
	return Items.ITEMS.has(id) and Items.ITEMS[id].get("place", "") != "" \
		and Catalog.ITEMS[Items.ITEMS[id].place].kind == "fence" and id != "gate_wood"


func _is_line(id: String) -> bool:
	if Items.kind_of(id) == "ground":
		return true
	return Items.ITEMS.has(id) and Catalog.ITEMS[Items.ITEMS[id].place].kind in LINES and id != "gate_wood"


func _process(delta: float) -> void:
	_work(delta)
	if active:
		var move: Vector2 = park.hud.stick_vector()
		if move != Vector2.ZERO:
			park.camera.position += move * CAMERA_SPEED * delta / park.camera.zoom.x
	queue_redraw()


# --- Touches -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	var cell := _cell_at(event.position)
	if not active:
		# Out of the building mode, a tap on scaffolding helps build.
		if event is InputEventScreenTouch and event.pressed and _help(cell):
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed and finger < 0:
			finger = event.index
			start = cell
			stroke = [cell]
			_update_plan()
		elif not event.pressed and event.index == finger:
			finger = -1
			_commit()
	elif event.index == finger and (stroke.is_empty() or cell != stroke[-1]):
		_extend(cell)
		_update_plan()


func _cell_at(screen: Vector2) -> Vector2i:
	var at: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen
	return Vector2i((at / T).floor())


# Adds the cells between the last one and `cell`, side by side so fences join up.
func _extend(cell: Vector2i) -> void:
	if tool != "erase" and not _is_line(item):
		stroke = [cell]
		return
	var last: Vector2i = stroke[-1]
	while last != cell:
		var step := cell - last
		if absi(step.x) >= absi(step.y):
			last.x += signi(step.x)
		else:
			last.y += signi(step.y)
		if not last in stroke:
			stroke.append(last)


func _update_plan() -> void:
	plan.clear()
	if tool == "erase":
		for cell in stroke:
			var why := _erase_refused(cell)
			if why != "skip":
				plan.append({"cell": cell, "id": "", "ok": why == "", "why": why})
		changed.emit()
		return
	if item == "":
		return
	var cells: Array[Vector2i] = []
	var gate := NONE
	if tool == "pen":
		cells = _rectangle(start, stroke[-1])
		if park.inventory.count("gate_wood") > 0 and cells.size() >= 8:
			# The gate goes in the middle of the bottom side.
			gate = Vector2i((start.x + stroke[-1].x) / 2, maxi(start.y, stroke[-1].y))
	else:
		cells = stroke.duplicate()
	var left: int = park.inventory.count(item)
	for cell in cells:
		var id := "gate_wood" if cell == gate else item
		var why: String = park.build_refused(cell, id)
		if why == "" and id == item:
			left -= 1
			if left < 0:
				why = "Il en manque : fabrique-en dans le Sac"
		plan.append({"cell": cell, "id": id, "ok": why == "", "why": why})
	changed.emit()


func _rectangle(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var low := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var high := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	for x in range(low.x, high.x + 1):
		cells.append(Vector2i(x, low.y))
		if high.y != low.y:
			cells.append(Vector2i(x, high.y))
	for y in range(low.y + 1, high.y):
		cells.append(Vector2i(low.x, y))
		if high.x != low.x:
			cells.append(Vector2i(high.x, y))
	return cells


func _commit() -> void:
	if tool == "erase":
		for step in plan:
			if step.ok:
				park.erase_at(step.cell)
		park.refresh_after_building()
	else:
		var done := {"cells": [], "items": []}
		var i := 0
		for step in plan:
			if not step.ok:
				continue
			var building: Dictionary = park.build_at(step.cell, step.id)
			done.cells.append(step.cell)
			done.items.append(step.id)
			if building.is_empty():
				continue
			_pop(building, i)
			var work: float = BUILD_TIME.get(building.kind, 0.0)
			if work > 0.0:
				building.build_left = work
				building.build_total = work
				if building.root:
					building.root.modulate.a = 0.4
				sites.append(building)
			i += 1
		if not done.cells.is_empty():
			history.append(done)
			park.refresh_after_building()
	stroke.clear()
	plan.clear()
	changed.emit()


# Each new thing pops up in turn along the line.
func _pop(building: Dictionary, order: int) -> void:
	var node: Node2D = building.root
	if node == null:
		return
	node.scale = Vector2.ZERO
	var tween := node.create_tween()
	tween.tween_interval(order * 0.03)
	tween.tween_property(node, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func undo() -> void:
	if history.is_empty():
		park.float_text(park.camera.position, "Rien à annuler", Color("e0e0e0"))
		return
	var done: Dictionary = history.pop_back()
	for i in done.cells.size():
		park.take_back_at(done.cells[i], done.items[i])
	park.refresh_after_building()
	changed.emit()


# "" if the eraser can take what is on this cell, a reason if it cannot, "skip" if there is nothing.
func _erase_refused(cell: Vector2i) -> String:
	var building = park.occupied.get(cell)
	if building == null:
		return "skip"
	# Trees and rocks give wood and stone: they are cut and broken, not erased.
	if building.id in ["tree", "pine", "palm", "cactus"]:
		return "Coupe-le avec la hache"
	if building.id == "rock":
		return "Casse-le avec la pioche"
	if building.fixed or Items.item_for_building(building.id) == "":
		return "On ne peut pas enlever ça"
	return ""


# --- Building sites ------------------------------------------------------------

func _work(delta: float) -> void:
	for site in sites.duplicate():
		if not park.buildings.has(site):
			sites.erase(site)
			continue
		site.build_left -= delta
		if site.build_left <= 0.0:
			_finish(site)


func _help(cell: Vector2i) -> bool:
	for site in sites:
		if site.origin == cell:
			site.build_left -= TAP_HELP
			park.float_text(park.cell_center(cell), "Toc !", Color("fff59d"))
			park.shake(site.root)
			if site.build_left <= 0.0:
				_finish(site)
			return true
	return false


func _finish(site: Dictionary) -> void:
	sites.erase(site)
	site.build_left = 0.0
	if site.root:
		site.root.modulate.a = 1.0
	park.float_text(park.cell_center(site.origin), "Terminé !", Color("a5f0a8"))


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	for site in sites:
		_scaffolding(site)
	if not active:
		return
	# A light grid over what the camera shows.
	var view_size: Vector2 = get_viewport_rect().size / park.camera.zoom
	var view := Rect2(park.camera.position - view_size / 2.0, view_size)
	var grid := Color(1, 1, 1, 0.12)
	for x in range(floori(view.position.x / T), ceili(view.end.x / T) + 1):
		draw_line(Vector2(x * T, view.position.y), Vector2(x * T, view.end.y), grid)
	for y in range(floori(view.position.y / T), ceili(view.end.y / T) + 1):
		draw_line(Vector2(view.position.x, y * T), Vector2(view.end.x, y * T), grid)
	for step in plan:
		var rect := Rect2(Vector2(step.cell * T), Vector2(T, T))
		draw_rect(rect, OK if step.ok else BAD)
		draw_rect(rect, Color(1, 1, 1, 0.6) if step.ok else Color(0.6, 0.1, 0.1, 0.8), false, 1.0)
		if step.id != "" and (step.id != item or not _is_line(item)):
			var icon := Art.bag_icon(step.id)
			draw_texture_rect(icon, rect.grow(-1), false, Color(1, 1, 1, 0.85))


func _scaffolding(site: Dictionary) -> void:
	var at := Vector2(site.origin * T)
	var wood := Color("a07848")
	draw_rect(Rect2(at + Vector2(1, -10), Vector2(14, 25)), wood, false, 1.0)
	draw_line(at + Vector2(1, -10), at + Vector2(15, 15), wood)
	draw_line(at + Vector2(15, -10), at + Vector2(1, 15), wood)
	var done: float = 1.0 - site.build_left / site.build_total
	draw_rect(Rect2(at + Vector2(-1, -15), Vector2(18, 4)), Color("1a1a24"))
	draw_rect(Rect2(at + Vector2(0, -14), Vector2(16.0 * done, 2)), Color("f0c020"))

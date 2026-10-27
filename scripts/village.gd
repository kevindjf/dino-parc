extends Node2D

# The village, west of the park, at the end of the road that leaves through the park gate:
# houses, a well, the shop where coins buy what is hard to make, and abandoned houses with a
# chest each. Villagers stroll around the square.
#
# It is a zone of its own, like the mines: built when the player walks in, freed when they leave.
# The world grows this way, zone by zone, and only the zone the player is in is in memory, so a
# very big world still runs on a tablet. A new zone = a script like this one with the same
# functions (setup, bounds, is_solid, kind_at, cell_center, arrival, is_exit), entered from main.gd.

const Art := preload("res://scripts/art.gd")
const WorldText := preload("res://scripts/world_text.gd")
const T := 16
const SIZE := Vector2i(44, 30)
const ROAD := 14  # the road to the park takes this row and the next one, out of the east edge
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
# Houses of 4 x 3 cells: [top-left cell, look]. Each one has a resident inside (see house.gd).
const HOUSES := [
	[Vector2i(4, 9), 0], [Vector2i(9, 9), 1], [Vector2i(4, 17), 2], [Vector2i(9, 17), 0],
	[Vector2i(31, 9), 2], [Vector2i(36, 9), 1], [Vector2i(31, 18), 1], [Vector2i(36, 18), 0],
]
const HOUSE_SIZE := Vector2i(4, 3)
const SHOP := Vector2i(17, 9)
const SHOP_SIZE := Vector2i(4, 2)
const WELL := Vector2i(25, 16)
# Abandoned houses: walls around 5 x 4 cells, a door in the bottom wall, a chest inside.
const RUINS := [Vector2i(4, 22), Vector2i(33, 22), Vector2i(13, 3), Vector2i(33, 3)]
const RUIN_SIZE := Vector2i(5, 4)
# What the chest of each abandoned house holds, in the order of RUINS ("coins" are pièces).
const CHESTS := [
	{"coins": 100, "capsule_iron": 2},
	{"coins": 60, "saddle": 1},
	{"coins": 80, "bow": 1, "arrow": 10},
	{"coins": 150, "capsule_gold": 1},
]
# Streets and the square, as rectangles of path: [top-left cell, size].
const STREETS := [
	[Vector2i(15, 11), Vector2i(14, 8)],  # the square
	[Vector2i(29, ROAD), Vector2i(15, 2)],  # the road to the park
	[Vector2i(2, ROAD), Vector2i(13, 2)],  # west street
	[Vector2i(23, 2), Vector2i(2, 9)],  # north street
	[Vector2i(21, 19), Vector2i(2, 9)],  # south street
]
const TREES := [Vector2i(15, 22), Vector2i(27, 4), Vector2i(19, 25), Vector2i(28, 25), Vector2i(3, 5),
	Vector2i(41, 5), Vector2i(41, 24), Vector2i(19, 5)]
const VILLAGERS := 5
const BORDER := 2

var state: Dictionary  # {"opened": [chest index, ...], "gifts": [house index, ...]}, saved with the game
var solid := {}  # Vector2i -> "tree", "house", "shop", "wall", "chest" or "well"
var paths := {}  # Vector2i -> true
var floors := {}  # Vector2i -> true: inside an abandoned house
var chests := {}  # Vector2i -> index in CHESTS
var chest_sprites := {}  # index -> Sprite2D
var image: Image
var ground: Sprite2D
var player: Node2D = null  # set by the park while the player is here
var shop_label: Node2D


func setup(village_state: Dictionary) -> void:
	state = village_state
	# (Numbers come back from the JSON save as decimals.)
	state.opened = state.get("opened", []).map(func(index) -> int: return int(index))
	y_sort_enabled = true
	_lay_out()
	image = Image.create(SIZE.x * T, SIZE.y * T, false, Image.FORMAT_RGBA8)
	for y in SIZE.y:
		for x in SIZE.x:
			_paint(Vector2i(x, y))
	ground = Sprite2D.new()
	ground.centered = false
	ground.texture = ImageTexture.create_from_image(image)
	ground.z_index = -10
	add_child(ground)
	_place_sprites()
	for i in VILLAGERS:
		var villager := Villager.new()
		add_child(villager)
		villager.setup(self, i)


func bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(SIZE * T))


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * T


func is_solid(cell: Vector2i) -> bool:
	return not Rect2i(Vector2i.ZERO, SIZE).has_point(cell) or solid.has(cell)


func kind_at(cell: Vector2i) -> String:
	return solid.get(cell, "")


# Where the player stands when coming from the park.
func arrival() -> Vector2:
	return cell_center(Vector2i(SIZE.x - 3, ROAD))


# The last cells of the road: walking there goes back to the park.
func is_exit(cell: Vector2i) -> bool:
	return cell.x >= SIZE.x - 1 and (cell.y == ROAD or cell.y == ROAD + 1)


# The house standing on this cell, or -1.
func house_at(cell: Vector2i) -> int:
	for i in HOUSES.size():
		if Rect2i(HOUSES[i][0], HOUSE_SIZE).has_point(cell):
			return i
	return -1


# The house whose door is just above this cell (walking up there goes in), or -1.
func house_door_below(cell: Vector2i) -> int:
	for i in HOUSES.size():
		var door: Vector2i = HOUSES[i][0] + Vector2i(1, HOUSE_SIZE.y)
		if cell == door or cell == door + Vector2i.RIGHT:
			return i
	return -1


# Where the player stands when coming out of a house: in front of its door.
func house_door(index: int) -> Vector2:
	return cell_center(HOUSES[index][0] + Vector2i(1, HOUSE_SIZE.y)) + Vector2(T / 2.0, 0)


# Close to the merchant, the sign tells how to open the shop.
func show_shop_hint(near: bool) -> void:
	shop_label.set_text("Boutique\nAppuie sur Action !" if near else "Boutique")


func near_shop(at: Vector2) -> bool:
	return Rect2(Vector2(SHOP * T), Vector2(SHOP_SIZE * T)).grow(1.5 * T).has_point(at)


# Opens the chest on this cell. Returns what it held, or {} if it was already empty.
func open_chest(cell: Vector2i) -> Dictionary:
	var index: int = chests.get(cell, -1)
	if index < 0 or index in state.opened:
		return {}
	state.opened.append(index)
	chest_sprites[index].texture = Art.chest(true)
	return CHESTS[index]


func _lay_out() -> void:
	for street in STREETS:
		for c in _cells(street[0], street[1]):
			paths[c] = true
	# Little paths from the doors of the houses north of the road down to it.
	for house in HOUSES:
		var door: Vector2i = house[0] + Vector2i(1, HOUSE_SIZE.y)
		if door.y < ROAD:
			for y in range(door.y, ROAD):
				paths[Vector2i(door.x, y)] = true
				paths[Vector2i(door.x + 1, y)] = true
		for c in _cells(house[0], HOUSE_SIZE):
			solid[c] = "house"
	for c in _cells(SHOP, SHOP_SIZE):
		solid[c] = "shop"
	for c in _cells(WELL, Vector2i(2, 2)):
		solid[c] = "well"
	for i in RUINS.size():
		var corner: Vector2i = RUINS[i]
		for c in _cells(corner, RUIN_SIZE):
			var inside := Rect2i(corner + Vector2i.ONE, RUIN_SIZE - Vector2i(2, 2)).has_point(c)
			var door := c == corner + Vector2i(RUIN_SIZE.x / 2, RUIN_SIZE.y - 1)
			if inside or door:
				floors[c] = true
			else:
				solid[c] = "wall"
		var chest: Vector2i = corner + Vector2i(RUIN_SIZE.x / 2, 1)
		solid[chest] = "chest"
		chests[chest] = i
	for c in TREES:
		solid[c] = "tree"
	# A thick wood all around, open where the road leaves for the park.
	for y in SIZE.y:
		for x in SIZE.x:
			var edge := x < BORDER or y < BORDER or x >= SIZE.x - BORDER or y >= SIZE.y - BORDER
			if edge and not (x >= SIZE.x - BORDER and (y == ROAD or y == ROAD + 1)):
				solid[Vector2i(x, y)] = "tree"
				paths.erase(Vector2i(x, y))


func _paint(cell: Vector2i) -> void:
	var at := cell * T
	var seed := hash(cell) + 77
	if floors.has(cell) or chests.has(cell):
		Art.paint_planks(image, at, seed)
	elif paths.has(cell):
		var edges := []
		for dir in DIRS:
			if not paths.has(cell + dir) and (cell + dir).x < SIZE.x:
				edges.append(dir)
		Art.paint_path(image, at, edges, true, seed)
	else:
		Art.paint_biome(image, at, "prairie", seed)


func _place_sprites() -> void:
	for i in HOUSES.size():
		var house: Node2D = _stand(Art.village_house(HOUSES[i][1]), HOUSES[i][0], HOUSE_SIZE)
		# Every other house shows its left side, so the streets do not look copied.
		house.flip_h = i % 2 == 1
	var stall := _stand(Art.market_stall(), SHOP, SHOP_SIZE)
	shop_label = WorldText.make(stall, Vector2(0, -64), "Boutique", "bubble", Color("2860c0"))
	_stand(Art.well(), WELL, Vector2i(2, 2))
	for i in RUINS.size():
		var corner: Vector2i = RUINS[i]
		for c in _cells(corner, RUIN_SIZE):
			if solid.get(c, "") == "wall":
				_stand(Art.ruin_wall(hash(c) % 4), c, Vector2i.ONE)
		var chest: Vector2i = corner + Vector2i(RUIN_SIZE.x / 2, 1)
		chest_sprites[i] = _stand(Art.chest(i in state.opened), chest, Vector2i.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for c in solid:
		if solid[c] == "tree":
			var tree := Art.sprite(Art.border_tree(rng.randi() % 3))
			Art.ground_shadow(tree, 22)
			tree.position = Vector2((c.x + 0.5) * T + rng.randi_range(-2, 2), (c.y + 1) * T + 2)
			add_child(tree)
	var sign := _stand(Art.signpost(), Vector2i(SIZE.x - 4, ROAD - 1), Vector2i.ONE)
	WorldText.make(sign, Vector2(0, -24), "Parc →", "bubble", Color("2a7a3a"))


# A standing sprite, its bottom center at the bottom middle of its cells.
func _stand(texture: Texture2D, origin: Vector2i, size: Vector2i) -> Sprite2D:
	var node := Art.sprite(texture)
	node.position = Vector2((origin.x + size.x / 2.0) * T, (origin.y + size.y) * T - 1)
	if texture.get_width() > 16:
		Art.ground_shadow(node, int(texture.get_width() * 0.85))
	add_child(node)
	return node


func _cells(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	for y in size.y:
		for x in size.x:
			list.append(origin + Vector2i(x, y))
	return list


# Someone of the village (a dinosaur in clothes), strolling along the streets and greeting the player.
class Villager extends Node2D:
	const SCALES := [Color("c8a050"), Color("4a8ab0"), Color("d0b060"), Color("c05030"), Color("6a9a50"), Color("9a70b0")]
	const GREETINGS := ["Bonjour !", "Salut !", "Il fait beau !", "Tu viens du parc ?", "As-tu vu la boutique ?"]

	var village: Node2D
	var kind := ""
	var colors := {}
	var sprite: Sprite2D
	var target := Vector2.ZERO
	var wait := 0.0
	var walked := 0.0
	var greeted := 0.0
	var bubble: Node2D

	func setup(owner: Node2D, index: int) -> void:
		village = owner
		var rng := RandomNumberGenerator.new()
		rng.seed = index * 31 + 5
		kind = Art.FOLK_KINDS[index % Art.FOLK_KINDS.size()]
		colors = {"skin": SCALES[rng.randi() % SCALES.size()], "shirt": Color.from_hsv(rng.randf(), 0.5, 0.75),
			"crest": Color.from_hsv(rng.randf(), 0.6, 0.7)}
		var spots: Array = village.paths.keys()
		position = village.cell_center(spots[rng.randi() % spots.size()])
		var shadow := Art.sprite(Art.shadow(12))
		shadow.centered = true
		shadow.offset = Vector2.ZERO
		add_child(shadow)
		sprite = Art.sprite(Art.dino_folk(kind, "down", 0, colors))
		add_child(sprite)
		bubble = WorldText.make(self, Vector2(0, -27), "", "bubble")
		_choose_target()

	func _choose_target() -> void:
		var spots: Array = village.paths.keys()
		target = village.cell_center(spots.pick_random()) + Vector2(randf_range(-4, 4), randf_range(-4, 4))
		wait = randf_range(0.5, 3.0)

	func _process(delta: float) -> void:
		greeted -= delta
		if greeted < 2.0:
			bubble.set_text("")
		var player: Node2D = village.player
		if player != null and greeted <= 0.0 and position.distance_to(player.position) < 22.0:
			greeted = 8.0
			bubble.set_text(GREETINGS.pick_random())
		if wait > 0.0:
			wait -= delta
			sprite.texture = Art.dino_folk(kind, "down", 0, colors)
			return
		var to_target := target - position
		if to_target.length() < 2.0:
			_choose_target()
			return
		var step := to_target.normalized() * 22.0 * delta
		var next := position + step
		if village.is_solid(Vector2i((next / T).floor())):
			_choose_target()
			return
		position = next
		walked += step.length()
		var frame := int(walked / 4.0) % 4
		if absf(to_target.x) > absf(to_target.y):
			sprite.texture = Art.dino_folk(kind, "side", frame, colors)
			sprite.flip_h = to_target.x < 0.0
		else:
			sprite.texture = Art.dino_folk(kind, "down" if to_target.y > 0.0 else "up", frame, colors)
			sprite.flip_h = false

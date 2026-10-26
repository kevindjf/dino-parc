extends Node2D

# Underground: a cave dug into the mountain, with ores in its walls. Each mine has three levels
# linked by ladders; the deeper, the rarer the ores. Whatever has been dug stays dug.

const Art := preload("res://scripts/art.gd")
const T := 16
const SIZE := Vector2i(48, 36)
const LEVELS := 3
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
# Ores hidden in the walls, per level: [ore, chance in % for each wall touching the cave].
const ORES := {
	1: [["copper", 7.0], ["iron", 4.0]],
	2: [["iron", 6.0], ["copper", 3.0], ["crystal", 3.0], ["fossil", 2.5]],
	3: [["crystal", 4.0], ["gold", 3.0], ["amber", 2.5], ["fossil", 3.0], ["iron", 3.0]],
}
# What digging gives, and whether the iron pickaxe is needed.
const DROPS := {
	"rock": {"gives": {"stone": 1}, "hits": 2, "iron": false},
	"copper": {"gives": {"copper": 2}, "hits": 3, "iron": false},
	"iron": {"gives": {"iron": 2}, "hits": 3, "iron": false},
	"crystal": {"gives": {"crystal": 1}, "hits": 3, "iron": true},
	"gold": {"gives": {"gold": 1}, "hits": 3, "iron": true},
	"amber": {"gives": {"amber": 1}, "hits": 4, "iron": true},
	"fossil": {"gives": {"fossil": 1}, "hits": 3, "iron": true},
}

var key := ""  # which mine: "x,y" of its entrance
var level := 1
var state: Dictionary  # {"seed": int, "dug": {"1": [[x, y], ...], ...}}, saved with the game
var cells := {}  # Vector2i -> "floor", "rock", an ore, "up" or "down"
var up_cell := Vector2i.ZERO
var down_cell := Vector2i(-1, -1)
var hits := {}  # Vector2i -> hits taken
var image: Image
var ground: Sprite2D
var light: PointLight2D


func setup(mine_key: String, mine_state: Dictionary, mine_level: int) -> void:
	key = mine_key
	state = mine_state
	level = mine_level
	_generate()
	image = Image.create(SIZE.x * T, SIZE.y * T, false, Image.FORMAT_RGBA8)
	for y in SIZE.y:
		for x in SIZE.x:
			_paint(Vector2i(x, y))
	ground = Sprite2D.new()
	ground.centered = false
	ground.texture = ImageTexture.create_from_image(image)
	ground.z_index = -10
	add_child(ground)
	# It is dark down there: only the player's lamp lights around.
	var dark := CanvasModulate.new()
	dark.color = Color(0.1, 0.09, 0.14)
	add_child(dark)


func make_light() -> PointLight2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.92, 0.75, 1))
	gradient.set_color(1, Color(1, 0.9, 0.7, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	light = PointLight2D.new()
	light.texture = texture
	light.texture_scale = 0.6
	light.energy = 1.6
	return light


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * T


func bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(SIZE * T))


func kind_at(cell: Vector2i) -> String:
	return cells.get(cell, "rock")


func is_solid(cell: Vector2i) -> bool:
	var kind := kind_at(cell)
	return kind != "floor" and kind != "up" and kind != "down"


# Digs the wall in front of the player. Returns what it gave, or a message to show.
func dig(cell: Vector2i, tool: String) -> Dictionary:
	var kind := kind_at(cell)
	if not DROPS.has(kind) or cell.x <= 0 or cell.y <= 0 or cell.x >= SIZE.x - 1 or cell.y >= SIZE.y - 1:
		return {}
	var drop: Dictionary = DROPS[kind]
	if tool != "pickaxe" and tool != "pickaxe_iron":
		return {"message": "Il faut une pioche pour creuser"}
	if drop.iron and tool != "pickaxe_iron":
		return {"message": "Il faut une pioche en fer pour ça !"}
	hits[cell] = hits.get(cell, 0) + 1
	if hits[cell] < drop.hits:
		return {"hit": true}
	hits.erase(cell)
	cells[cell] = "floor"
	var dug: Array = state.dug.get(str(level), [])
	dug.append([cell.x, cell.y])
	state.dug[str(level)] = dug
	for c in [cell, cell + Vector2i.UP]:
		if Rect2i(Vector2i.ZERO, SIZE).has_point(c):
			_paint(c)
	ground.texture.update(image)
	var gives: Dictionary = drop.gives.duplicate()
	# Plain rock only sometimes gives a stone.
	if kind == "rock" and randf() < 0.5:
		gives = {}
	return {"gives": gives, "ore": kind}


func _paint(cell: Vector2i) -> void:
	var kind := kind_at(cell)
	Art.paint_cave(image, cell * T, kind, not is_solid(cell + Vector2i.DOWN), hash(cell) + level)


# Caves grown like in Minecraft: random rock smoothed a few times, keeping the part reachable
# from the ladder. Same seed, same cave.
func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state.seed) + level * 7919
	var rock := {}
	for y in SIZE.y:
		for x in SIZE.x:
			var edge := x == 0 or y == 0 or x == SIZE.x - 1 or y == SIZE.y - 1
			rock[Vector2i(x, y)] = edge or rng.randf() < 0.44
	for smoothing in 4:
		var next := {}
		for y in SIZE.y:
			for x in SIZE.x:
				var c := Vector2i(x, y)
				var walls := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if rock.get(c + Vector2i(dx, dy), true):
							walls += 1
				var edge := x == 0 or y == 0 or x == SIZE.x - 1 or y == SIZE.y - 1
				next[c] = edge or walls >= 5
		rock = next
	# The ladder up is near the top middle; open a room around it.
	up_cell = Vector2i(SIZE.x / 2, 3)
	for dy in range(-1, 3):
		for dx in range(-2, 3):
			rock[up_cell + Vector2i(dx, dy)] = false
	# Keep only the cave reachable from the ladder, dig a corridor if it is too small.
	var reach := _reachable(rock, up_cell)
	var target := Vector2i(rng.randi_range(6, SIZE.x - 7), SIZE.y - 6)
	if reach.size() < 300 or not reach.has(target):
		var c := up_cell
		while c != target:
			rock[c] = false
			rock[c + Vector2i.RIGHT] = false
			if rng.randf() < 0.5 and c.x != target.x:
				c.x += signi(target.x - c.x)
			else:
				c.y += signi(target.y - c.y) if c.y != target.y else 0
				if c.y == target.y:
					c.x += signi(target.x - c.x)
		reach = _reachable(rock, up_cell)
	cells.clear()
	for c in rock:
		cells[c] = "floor" if reach.has(c) else "rock"
	cells[up_cell] = "up"
	# The ladder down is the farthest point of the cave.
	if level < LEVELS:
		var far := up_cell
		for c in reach:
			if reach[c] > reach[far]:
				far = c
		down_cell = far
		cells[down_cell] = "down"
	# Ores in the walls that touch the cave.
	for c in cells:
		if cells[c] != "rock" or c.x == 0 or c.y == 0 or c.x == SIZE.x - 1 or c.y == SIZE.y - 1:
			continue
		var touches := false
		for dir in DIRS:
			if reach.has(c + dir):
				touches = true
		if not touches:
			continue
		var roll := rng.randf_range(0.0, 100.0)
		for ore in ORES[level]:
			roll -= ore[1]
			if roll < 0.0:
				cells[c] = ore[0]
				break
	for cell in state.dug.get(str(level), []):
		cells[Vector2i(int(cell[0]), int(cell[1]))] = "floor"


func _reachable(rock: Dictionary, from: Vector2i) -> Dictionary:
	var distance := {from: 0}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for dir in DIRS:
			var n: Vector2i = c + dir
			if not distance.has(n) and not rock.get(n, true):
				distance[n] = distance[c] + 1
				queue.append(n)
	return distance

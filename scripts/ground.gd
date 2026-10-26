extends Node2D

# The ground of the park, painted cell by cell with biomes, water, paths, roads and cliffs.
# It is cut into square chunks, so changing a cell only re-uploads one small texture.

const Art := preload("res://scripts/art.gd")
const T := 16
const CHUNK := 32  # cells per side of a chunk
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var park: Node2D
var chunks := {}  # Vector2i -> {image, texture, sprite}
var dirty := {}  # chunk -> true


func setup(owner_park: Node2D) -> void:
	park = owner_park
	var count := Vector2i(ceili(park.GRID.x / float(CHUNK)), ceili(park.GRID.y / float(CHUNK)))
	for cy in count.y:
		for cx in count.x:
			var image := Image.create(CHUNK * T, CHUNK * T, false, Image.FORMAT_RGBA8)
			var sprite := Sprite2D.new()
			sprite.centered = false
			sprite.position = Vector2(cx, cy) * CHUNK * T
			add_child(sprite)
			chunks[Vector2i(cx, cy)] = {"image": image, "sprite": sprite}
	refresh(park.GRID / 2, maxi(park.GRID.x, park.GRID.y))
	_upload()


# Repaints a cell and its neighbours within `radius` (paths and cliffs depend on their neighbours).
func refresh(cell: Vector2i, radius := 1) -> void:
	for y in range(maxi(cell.y - radius, 0), mini(cell.y + radius + 1, park.GRID.y)):
		for x in range(maxi(cell.x - radius, 0), mini(cell.x + radius + 1, park.GRID.x)):
			_paint(Vector2i(x, y))


func _process(_delta: float) -> void:
	_upload()


func _upload() -> void:
	for key in dirty:
		var chunk: Dictionary = chunks[key]
		if chunk.sprite.texture == null:
			chunk.sprite.texture = ImageTexture.create_from_image(chunk.image)
		else:
			chunk.sprite.texture.update(chunk.image)
	dirty.clear()


func _paint(cell: Vector2i) -> void:
	var key := cell / CHUNK
	var image: Image = chunks[key].image
	dirty[key] = true
	var at := (cell - key * CHUNK) * T
	var seed := hash(cell)
	var building = park.occupied.get(cell)
	if park.is_water(cell):
		var shore := []
		for dir in DIRS:
			if park.in_grid(cell + dir) and not park.is_water(cell + dir):
				shore.append(dir)
		Art.paint_water(image, at, shore, seed)
		if building != null and building.id == "bridge":
			var across: bool = park.is_water(cell + Vector2i.UP) or park.is_water(cell + Vector2i.DOWN)
			Art.paint_bridge(image, at, not across or park.is_path(cell + Vector2i.LEFT) or park.is_path(cell + Vector2i.RIGHT))
		return
	Art.paint_biome(image, at, park.biome_at(cell), seed)
	if building == null:
		return
	match building.kind:
		"path":
			var edges := []
			for dir in DIRS:
				var open: bool = park.is_path(cell + dir) or park.is_road(cell + dir) or (cell == park.ENTRANCE and dir == Vector2i.LEFT)
				if not open:
					edges.append(dir)
			Art.paint_path(image, at, edges, park.distance.has(cell), seed)
		"road":
			var links := []
			for dir in DIRS:
				if park.is_road(cell + dir):
					links.append(dir)
			Art.paint_road(image, at, links, seed)
		"mountain", "mine":
			var lower := []
			var level: int = park.mountain_level(cell)
			for dir in DIRS:
				if park.mountain_level(cell + dir) < level:
					lower.append(dir)
			Art.paint_mountain(image, at, level, lower, seed)

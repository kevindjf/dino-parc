extends RefCounted

# Makes the wild land of a new adventure. The map is laid out in regions, like a real island:
# meadows and a forest around the entrance in the west, a swamp with lakes in the south-west,
# a jungle crossed by a river, a desert with canyons in the east, snowy mountains with mines
# in the north-east, and the sea with its beach along the east coast.

const Wild := preload("res://scripts/wild.gd")

const NATURE := {
	"prairie": [["tree", 4.0], ["bush", 2.0], ["rock", 1.5], ["fern", 1.0]],
	"jungle": [["tree", 7.0], ["palm", 5.0], ["fern", 5.0], ["bush", 3.0]],
	"desert": [["cactus", 3.0], ["rock", 4.0], ["palm", 0.5]],
	"marais": [["tree", 3.0], ["fern", 6.0], ["bush", 1.5]],
	"neige": [["pine", 7.0], ["rock", 3.0]],
}
# Region centers (in a 128 x 96 map) and their biome; borders are made wavy with noise.
const REGIONS := [
	[Vector2(14, 48), "prairie"], [Vector2(32, 28), "prairie"], [Vector2(40, 54), "prairie"],
	[Vector2(30, 10), "prairie"], [Vector2(18, 80), "marais"], [Vector2(40, 84), "marais"],
	[Vector2(62, 66), "jungle"], [Vector2(80, 86), "jungle"], [Vector2(58, 40), "jungle"],
	[Vector2(88, 52), "desert"], [Vector2(104, 66), "desert"], [Vector2(76, 30), "desert"],
	[Vector2(92, 16), "neige"], [Vector2(114, 22), "neige"], [Vector2(60, 12), "neige"],
]
const SEA_WIDTH := 7


static func generate(park: Node2D, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var warp := FastNoiseLite.new()
	warp.seed = seed
	warp.frequency = 0.04
	var scale := Vector2(park.GRID) / Vector2(128, 96)
	var centers := []
	for region in REGIONS:
		centers.append([region[0] * scale + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5)), region[1]])

	# Biomes: the nearest region center, with wavy borders.
	for y in park.GRID.y:
		for x in park.GRID.x:
			var cell := Vector2i(x, y)
			var p := Vector2(x, y) + Vector2(warp.get_noise_2d(x, y), warp.get_noise_2d(x + 500, y)) * 9.0
			var best := ""
			var best_distance := INF
			for center in centers:
				var d: float = p.distance_squared_to(center[0])
				if d < best_distance:
					best_distance = d
					best = center[1]
			park.biomes[park.index_of(cell)] = "prairie" if _near_entrance(cell, park) else best

	# The sea along the east coast, with a sandy beach.
	for y in park.GRID.y:
		var coast: int = park.GRID.x - SEA_WIDTH + int(round(warp.get_noise_2d(0, y * 3) * 3.0))
		for x in range(coast - 4, park.GRID.x):
			var cell := Vector2i(x, y)
			if x >= coast:
				park.set_water(cell, true)
			else:
				park.biomes[park.index_of(cell)] = "desert"

	# A river from the snowy mountains down to the sea, and lakes in the swamp.
	_river(park, rng, Vector2(70, 20) * scale, Vector2(park.GRID.x - 4, 74 * scale.y))
	for center in [Vector2(20, 82), Vector2(38, 88), Vector2(28, 70)]:
		_blob(park, rng, center * scale, rng.randi_range(3, 5), "water")

	# Snowy mountain ranges and desert canyons, each with a mine dug into its southern cliff.
	for range_center in [[Vector2(96, 14), 10], [Vector2(62, 10), 7], [Vector2(100, 56), 5]]:
		var center: Vector2 = range_center[0] * scale
		var cells := _blob(park, rng, center, range_center[1], "mountain")
		_mine_entrance(park, cells, center)

	# Nature everywhere, with a dense forest north of the entrance.
	for y in park.GRID.y:
		for x in park.GRID.x:
			var cell := Vector2i(x, y)
			if _near_entrance(cell, park) or park.occupied.has(cell) or park.is_water(cell):
				continue
			var forest: bool = park.biome_at(cell) == "prairie" and Vector2(cell).distance_to(Vector2(22, 18) * scale) < 12.0 \
				and warp.get_noise_2d(x * 3, y * 3) > -0.2
			var id := "tree" if forest and rng.randf() < 0.35 else pick(park.biome_at(cell), rng)
			if id != "":
				park.add_natural(id, cell)


# Makes a zone of the Wild Lands (see wild.gd): patches of biomes drawn from where it is in the
# world, lakes in the wet ones, mountains with a mine in the cold and dry ones, rivers, and
# nature everywhere, thicker than in the park.
static func generate_zone(park: Node2D, zone: Vector2i, world_seed: int) -> void:
	var seed := Wild.seed_of(world_seed, zone)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var warp := FastNoiseLite.new()
	warp.seed = seed
	warp.frequency = 0.04
	# The biomes follow the whole world, so that they go on from one zone to the next.
	var climate := FastNoiseLite.new()
	climate.seed = world_seed
	climate.frequency = 0.012
	for y in park.GRID.y:
		for x in park.GRID.x:
			var world := Vector2(zone * park.GRID + Vector2i(x, y))
			park.biomes[park.index_of(Vector2i(x, y))] = Wild.biome_at(world, park.GRID, climate)
	var weights := {}
	var total := 0.0
	for biome in park.biomes:
		weights[biome] = weights.get(biome, 0.0) + 1.0
		total += 1.0
	var share := func(biome: String) -> float: return weights.get(biome, 0.0) / total
	for i in int(round(share.call("marais") * 8.0)) + rng.randi_range(0, 1):
		_blob(park, rng, _inside(park, rng, 10), rng.randi_range(3, 6), "water")
	if rng.randf() < 0.6:
		var side := rng.randi_range(0, 1)
		var from := Vector2(rng.randf_range(20, park.GRID.x - 20), 1) if side == 0 else Vector2(1, rng.randf_range(15, park.GRID.y - 15))
		var to := Vector2(rng.randf_range(20, park.GRID.x - 20), park.GRID.y - 2) if side == 0 else Vector2(park.GRID.x - 2, rng.randf_range(15, park.GRID.y - 15))
		_river(park, rng, from, to)
	for i in int(round((share.call("neige") + share.call("desert")) * 5.0)) + 1:
		var center := _inside(park, rng, 16)
		var cells := _blob(park, rng, center, rng.randi_range(4, 9), "mountain")
		_mine_entrance(park, cells, center)

	for y in park.GRID.y:
		for x in park.GRID.x:
			var cell := Vector2i(x, y)
			if park.occupied.has(cell) or park.is_water(cell):
				continue
			var id := pick(park.biome_at(cell), rng)
			if id == "" and warp.get_noise_2d(x * 3, y * 3) > 0.35 and rng.randf() < 0.3:
				id = "pine" if park.biome_at(cell) == "neige" else ("cactus" if park.biome_at(cell) == "desert" else "tree")
			if id != "":
				park.add_natural(id, cell)


static func _inside(park: Node2D, rng: RandomNumberGenerator, margin: int) -> Vector2:
	return Vector2(rng.randf_range(margin, park.GRID.x - margin), rng.randf_range(margin, park.GRID.y - margin))


static func pick(biome: String, rng: RandomNumberGenerator) -> String:
	var roll := rng.randf_range(0.0, 100.0)
	for entry in NATURE[biome]:
		roll -= entry[1]
		if roll < 0.0:
			return entry[0]
	return ""


# A wavy round patch of water or mountain. Returns its cells.
static func _blob(park: Node2D, rng: RandomNumberGenerator, center: Vector2, radius: float, what: String) -> Array:
	var cells := []
	var wobble := rng.randf() * TAU
	for y in range(int(center.y - radius * 1.4), int(center.y + radius * 1.4) + 1):
		for x in range(int(center.x - radius * 1.6), int(center.x + radius * 1.6) + 1):
			var cell := Vector2i(x, y)
			if not park.in_grid(cell) or _near_entrance(cell, park) or park.is_water(cell):
				continue
			var offset := (Vector2(cell) - center) / Vector2(1.4, 1.0)
			var r := radius * (1.0 + 0.25 * sin(offset.angle() * 3.0 + wobble))
			if offset.length() > r:
				continue
			if what == "water":
				park.set_water(cell, true)
			else:
				park.biomes[park.index_of(cell)] = "neige" if park.biome_at(cell) != "desert" else "desert"
				park.add_natural("mountain", cell)
			cells.append(cell)
	return cells


# A meandering river, two cells wide.
static func _river(park: Node2D, rng: RandomNumberGenerator, from: Vector2, to: Vector2) -> void:
	var p := from
	var steps := 0
	while p.distance_to(to) > 1.5 and steps < 600:
		steps += 1
		var direction := (to - p).normalized().rotated(rng.randf_range(-0.9, 0.9))
		p += direction
		for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN]:
			var cell: Vector2i = Vector2i(p.round()) + offset
			if park.in_grid(cell) and not _near_entrance(cell, park):
				park.set_water(cell, true)


# Digs a mine into the southern cliff of a mountain range, facing open ground.
static func _mine_entrance(park: Node2D, cells: Array, center: Vector2) -> void:
	var best := Vector2i(-1, -1)
	for cell in cells:
		var below: Vector2i = cell + Vector2i.DOWN
		if park.in_grid(below) and not park.occupied.has(below) and not park.is_water(below) \
			and (best.x < 0 or absf(cell.x - center.x) + (center.y - cell.y) * 0.2 < absf(best.x - center.x) + (center.y - best.y) * 0.2):
			best = cell
	if best.x < 0:
		return
	park.remove_natural(best)
	park.add_natural("mine_entrance", best)


static func _near_entrance(cell: Vector2i, park: Node2D) -> bool:
	return cell.x < 14 and absi(cell.y - park.ENTRANCE.y) < 8

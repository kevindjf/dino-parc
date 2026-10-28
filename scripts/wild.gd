extends RefCounted

# The Wild Lands: the world of the adventure is a grid of zones, each one as big as the park.
# The park is the base, in the middle; around it, wild zones get colder to the north, hotter to
# the south, wetter to the west and drier to the east, and wilder the further they are: bigger
# dinosaurs, rarer species. Walking off the edge of a zone leads into the next one. Only the
# zone where the player is lives in memory (see main.gd, travel()).
# A zone is a Vector2i in the grid; Wild.BASE is the park.

const SIZE := Vector2i(7, 7)
const BASE := Vector2i(3, 3)
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
# The park opens on the wild lands by trails through its forest: how many on each side. The gate
# on the left leads to the village; on the right, a sandy causeway crosses the sea.
const BASE_TRAILS := {Vector2i.UP: 3, Vector2i.DOWN: 3, Vector2i.LEFT: 2, Vector2i.RIGHT: 1}


static func key(zone: Vector2i) -> String:
	return "%d,%d" % [zone.x, zone.y]


static func from_key(text: String) -> Vector2i:
	var parts := text.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


static func in_world(zone: Vector2i) -> bool:
	return zone.x >= 0 and zone.y >= 0 and zone.x < SIZE.x and zone.y < SIZE.y


# 0 for the park, then 1, 2, 3 going away from it: the further, the wilder.
static func level(zone: Vector2i) -> int:
	var d := (zone - BASE).abs()
	return maxi(d.x, d.y)


# Whether one can go from this zone to the next one in this direction.
static func open_edge(zone: Vector2i, dir: Vector2i) -> bool:
	var next := zone + dir
	if not in_world(next):
		return false
	if zone == BASE:
		return BASE_TRAILS.has(dir)
	if next == BASE:
		return BASE_TRAILS.has(-dir)
	return true


static func seed_of(world_seed: int, zone: Vector2i) -> int:
	return hash("%d:%s" % [world_seed, key(zone)])


# The biome at a point of the world, in cells from the top left of the world: colder to the
# north, hotter to the south, wetter to the west, drier to the east, in big wavy patches.
# climate: a noise made with the seed of the world.
static func biome_at(world: Vector2, grid: Vector2i, climate: FastNoiseLite) -> String:
	var d := _from_base(world, grid)
	var cold := -d.y + climate.get_noise_2d(world.x, world.y) * 0.5
	var wet := -d.x + climate.get_noise_2d(world.x + 9000, world.y) * 0.5
	return _biome(cold, wet)


# Where a point is from the middle of the park: -1 to 1 three zones away on each side.
static func _from_base(world: Vector2, grid: Vector2i) -> Vector2:
	var middle := (Vector2(BASE) + Vector2(0.5, 0.5)) * Vector2(grid)
	return (world - middle) / (Vector2(grid) * 3.0)


static func _biome(cold: float, wet: float) -> String:
	if cold > 0.4:
		return "neige"
	if cold < -0.4:
		return "jungle"
	if wet > 0.4:
		return "marais"
	if wet < -0.4:
		return "desert"
	return "prairie"


static func main_biome(zone: Vector2i) -> String:
	var d := _from_base((Vector2(zone) + Vector2(0.5, 0.5)) * Vector2(128, 96), Vector2i(128, 96))
	return _biome(-d.y, -d.x)


const NAMES := {
	"neige": ["Toundra glacée", "Montagnes blanches", "Pics gelés"],
	"jungle": ["Jungle profonde", "Forêt des fougères", "Jungle du volcan"],
	"marais": ["Marais brumeux", "Lacs verts", "Marécage des roseaux"],
	"desert": ["Désert des canyons", "Dunes rouges", "Plateau brûlant"],
	"prairie": ["Grandes plaines", "Collines vertes", "Vallée des fleurs"],
}


static func name_of(zone: Vector2i) -> String:
	if zone == BASE:
		return "Ton parc"
	var names: Array = NAMES[main_biome(zone)]
	return names[(zone.x * 7 + zone.y * 3) % names.size()]

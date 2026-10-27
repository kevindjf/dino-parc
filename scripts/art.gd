extends RefCounted

# Every sprite and ground tile of the park, drawn in code as pixel art, 16 x 16 pixels per cell.
# Textures are drawn once and cached. Sprites are anchored at their bottom center unless noted.

const Painter := preload("res://scripts/painter.gd")
const Catalog := preload("res://scripts/catalog.gd")
const DinoArt := preload("res://scripts/dino_art.gd")
const Items := preload("res://scripts/items.gd")
const T := 16
const OUTLINE := Color("283038")
const WOOD := Color("9a6a40")

static var _cache := {}


static func cached(key: String, make: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


# A sprite whose `anchor` pixel sits on the node position (bottom center by default).
static func sprite(texture: Texture2D, anchor := Vector2(-1, -1)) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = texture
	node.centered = false
	if anchor.x < 0:
		anchor = Vector2(floorf(texture.get_width() / 2.0), texture.get_height())
	node.offset = -anchor
	return node


static func _painter(size: Vector2i) -> Painter:
	var p := Painter.new()
	p.start(size)
	return p


# Small ASCII drawings: each letter of a row is a palette key, "." is transparent.
static func _stamp(image: Image, at: Vector2i, rows: Array, palette: Dictionary) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var key := row[x]
			if palette.has(key):
				var p := at + Vector2i(x, y)
				if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height():
					image.set_pixelv(p, palette[key])


# --- Ground -----------------------------------------------------------------

const GROUND := {
	"prairie": {"base": Color("88d498"), "dark": Color("5fb074"), "light": Color("b4ecb8")},
	"jungle": {"base": Color("4f9e5c"), "dark": Color("2f7440"), "light": Color("78c47c")},
	"desert": {"base": Color("ecd59a"), "dark": Color("cfb070"), "light": Color("f8ead0")},
	"marais": {"base": Color("7d8f52"), "dark": Color("5a6c3c"), "light": Color("9cae6c")},
	"neige": {"base": Color("eef3fa"), "dark": Color("cbd8e8"), "light": Color("ffffff")},
}
const TUFT := [".d.d.", "d.d.d"]
const TALL_GRASS := ["..d...d.", ".dld.dld", "dlll.lll"]
const FLOWER := [".p.", "pyp", ".p."]
const REED := ["l.", "d.", "dl", "d.", "d."]


static func paint_biome(image: Image, at: Vector2i, biome: String, seed: int) -> void:
	var colors: Dictionary = GROUND[biome]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	image.fill_rect(Rect2i(at, Vector2i(T, T)), colors.base)
	var palette := {"d": colors.dark, "l": colors.light}
	match biome:
		"prairie":
			for i in rng.randi_range(1, 3):
				_stamp(image, at + Vector2i(rng.randi_range(0, 11), rng.randi_range(1, 13)), TUFT, palette)
			if rng.randf() < 0.08:
				var petal: Color = [Color("f06060"), Color("ffffff"), Color("f8d030"), Color("b080f0")][rng.randi() % 4]
				_stamp(image, at + Vector2i(rng.randi_range(1, 12), rng.randi_range(1, 12)), FLOWER, {"p": petal, "y": Color("f8e070")})
		"jungle":
			if rng.randf() < 0.6:
				for spot in [Vector2i(0, 1), Vector2i(8, 5), Vector2i(1, 9), Vector2i(8, 13)]:
					_stamp(image, at + spot, TALL_GRASS, palette)
			else:
				for i in 3:
					_stamp(image, at + Vector2i(rng.randi_range(0, 11), rng.randi_range(1, 13)), TUFT, palette)
		"desert":
			for i in 7:
				image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), colors.dark)
			for i in 3:
				image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), colors.light)
			if rng.randf() < 0.15:
				var p := at + Vector2i(rng.randi_range(1, 12), rng.randi_range(1, 13))
				_stamp(image, p, ["ll.", "ddd"], {"l": Color("c8b08a"), "d": Color("9c8460")})
		"marais":
			if rng.randf() < 0.35:
				var c := at + Vector2i(rng.randi_range(4, 10), rng.randi_range(4, 11))
				for y in range(-2, 3):
					for x in range(-4, 5):
						if x * x / 16.0 + y * y / 4.0 <= 1.0:
							image.set_pixelv(c + Vector2i(x, y), Color("4a7a80"))
				image.set_pixelv(c + Vector2i(-1, -1), Color("8cc0c4"))
				image.set_pixelv(c + Vector2i(0, -1), Color("8cc0c4"))
			for i in rng.randi_range(1, 2):
				_stamp(image, at + Vector2i(rng.randi_range(0, 13), rng.randi_range(0, 10)), REED, {"l": Color("c0a050"), "d": colors.dark})
			for i in 2:
				_stamp(image, at + Vector2i(rng.randi_range(0, 11), rng.randi_range(1, 13)), TUFT, palette)
		"neige":
			for i in 4:
				image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), colors.dark)
			if rng.randf() < 0.3:
				var p := at + Vector2i(rng.randi_range(1, 13), rng.randi_range(1, 13))
				_stamp(image, p, [".l.", "lll", ".l."], {"l": Color("ffffff")})


# edges: directions where the path stops.
static func paint_path(image: Image, at: Vector2i, edges: Array, connected: bool, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var base := Color("e8d4a0") if connected else Color("c4bba4")
	image.fill_rect(Rect2i(at, Vector2i(T, T)), base)
	for i in 5:
		image.set_pixelv(at + Vector2i(rng.randi_range(1, 14), rng.randi_range(1, 14)), base.darkened(0.1))
	for i in 2:
		image.set_pixelv(at + Vector2i(rng.randi_range(1, 14), rng.randi_range(1, 14)), base.lightened(0.25))
	_edges(image, at, edges, base.darkened(0.35), base.darkened(0.14))


static func paint_road(image: Image, at: Vector2i, links: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var base := Color("6e7078")
	image.fill_rect(Rect2i(at, Vector2i(T, T)), base)
	for i in 6:
		image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), base.darkened(0.12) if i % 2 == 0 else base.lightened(0.1))
	var edges := []
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not dir in links:
			edges.append(dir)
	_edges(image, at, edges, Color("8e8e96"), Color("cfd0d6"))
	var horizontal := Vector2i.LEFT in links or Vector2i.RIGHT in links
	var vertical := Vector2i.UP in links or Vector2i.DOWN in links
	var paint := Color("f0d040")
	if horizontal != vertical:
		for a in [2, 10]:
			for i in 4:
				image.set_pixelv(at + (Vector2i(a + i, 7) if horizontal else Vector2i(7, a + i)), paint)
				image.set_pixelv(at + (Vector2i(a + i, 8) if horizontal else Vector2i(8, a + i)), paint)


static func _edges(image: Image, at: Vector2i, edges: Array, outer: Color, inner: Color) -> void:
	for dir in edges:
		for i in T:
			match dir:
				Vector2i.LEFT:
					image.set_pixelv(at + Vector2i(1, i), inner)
				Vector2i.RIGHT:
					image.set_pixelv(at + Vector2i(14, i), inner)
				Vector2i.UP:
					image.set_pixelv(at + Vector2i(i, 1), inner)
				Vector2i.DOWN:
					image.set_pixelv(at + Vector2i(i, 14), inner)
	for dir in edges:
		for i in T:
			match dir:
				Vector2i.LEFT:
					image.set_pixelv(at + Vector2i(0, i), outer)
				Vector2i.RIGHT:
					image.set_pixelv(at + Vector2i(15, i), outer)
				Vector2i.UP:
					image.set_pixelv(at + Vector2i(i, 0), outer)
				Vector2i.DOWN:
					image.set_pixelv(at + Vector2i(i, 15), outer)


# shore: directions where the land is. Waves like the old handheld games, sand along the shore.
static func paint_water(image: Image, at: Vector2i, shore: Array, seed: int) -> void:
	var base := Color("4a7ee0")
	for y in T:
		for x in T:
			var color := base
			var wave := (at.y + y + int(round(1.5 * sin((at.x + x) * TAU / 16.0)))) % 8
			if wave == 0:
				color = Color("78b0f4")
			elif wave == 1:
				color = Color("5c94ec")
			image.set_pixel(at.x + x, at.y + y, color)
	var sand := Color("e2cc94")
	var deep := Color("3a68c8")
	for dir in shore:
		for i in T:
			for d in 3:
				var p: Vector2i
				match dir:
					Vector2i.LEFT:
						p = Vector2i(d, i)
					Vector2i.RIGHT:
						p = Vector2i(T - 1 - d, i)
					Vector2i.UP:
						p = Vector2i(i, d)
					_:
						p = Vector2i(i, T - 1 - d)
				image.set_pixelv(at + p, sand if d < 2 else deep)


# Wooden planks over the water; `along_x` when the bridge crosses from left to right.
static func paint_bridge(image: Image, at: Vector2i, along_x: bool) -> void:
	var plank := Color("c8a060")
	for y in T:
		for x in T:
			var a := x if along_x else y
			var b := y if along_x else x
			if b < 2 or b > 13:
				continue
			var color := plank if a % 4 != 3 else plank.darkened(0.35)
			if b == 2 or b == 13:
				color = Color("7a5230")
			image.set_pixel(at.x + x, at.y + y, color)


# Inside a mine: floor, rock walls (with a cliff face above open floor), ores and ladders.
const ORE_COLORS := {
	"copper": [Color("e07838"), Color("ffb070")], "iron": [Color("b8a8a0"), Color("e8dcd4")],
	"crystal": [Color("60d8f8"), Color("d0f8ff")], "gold": [Color("f0c830"), Color("fff0a0")],
	"amber": [Color("f09818"), Color("ffd070")], "fossil": [Color("efe6d0"), Color("ffffff")],
}


static func paint_cave(image: Image, at: Vector2i, kind: String, open_below: bool, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	if kind == "floor" or kind == "up" or kind == "down":
		var floor_color := Color("43342a")
		image.fill_rect(Rect2i(at, Vector2i(T, T)), floor_color)
		for i in 6:
			image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), floor_color.darkened(0.2))
		for i in 2:
			image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), floor_color.lightened(0.15))
		if kind == "down":
			for y in range(3, 13):
				for x in range(3, 13):
					if Vector2(x - 7.5, y - 7.5).length() < 5.5:
						image.set_pixel(at.x + x, at.y + y, Color("100c0a"))
		if kind == "up" or kind == "down":
			var wood := Color("c08a50")
			for y in range(1 if kind == "up" else 4, 15):
				image.set_pixel(at.x + 5, at.y + y, wood)
				image.set_pixel(at.x + 10, at.y + y, wood)
			for y in range(3 if kind == "up" else 6, 15, 3):
				for x in range(5, 11):
					image.set_pixel(at.x + x, at.y + y, wood.darkened(0.15))
		if kind == "up":
			for y in range(0, 3):
				for x in range(3, 13):
					image.set_pixel(at.x + x, at.y + y, Color("f8f0c0"))
		return
	# Rock (with or without ore).
	var top := Color("8e7a68")
	image.fill_rect(Rect2i(at, Vector2i(T, T)), top)
	for i in 7:
		image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), top.darkened(0.15))
	for i in 3:
		image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), top.lightened(0.15))
	if open_below:
		var face := Color("4e3c30")
		image.fill_rect(Rect2i(at + Vector2i(0, 9), Vector2i(T, 7)), face)
		image.fill_rect(Rect2i(at + Vector2i(0, 9), Vector2i(T, 1)), top.lightened(0.2))
		for x in range(rng.randi_range(0, 2), T, 3):
			image.fill_rect(Rect2i(at + Vector2i(x, 11), Vector2i(1, rng.randi_range(2, 4))), face.darkened(0.3))
	if ORE_COLORS.has(kind):
		var colors: Array = ORE_COLORS[kind]
		for spot in [Vector2i(2, 1), Vector2i(9, 2), Vector2i(5, 5), Vector2i(11, 6)]:
			var p: Vector2i = at + spot + Vector2i(rng.randi_range(-1, 1), rng.randi_range(0, 1) if open_below else rng.randi_range(0, 4))
			image.fill_rect(Rect2i(p - Vector2i(1, 1), Vector2i(5, 4)), colors[0].darkened(0.55))
			image.fill_rect(Rect2i(p, Vector2i(3, 2)), colors[0])
			image.set_pixelv(p, colors[1])


const ROCK_LEVELS := [Color("b39a76"), Color("a68e6e"), Color("998468"), Color("e8eef6"), Color("f2f6fb"), Color("ffffff")]


# lower: directions where the neighbour is lower (or not a mountain): a cliff is drawn there.
static func paint_mountain(image: Image, at: Vector2i, level: int, lower: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var snowy := level >= 3
	var top: Color = ROCK_LEVELS[clampi(level, 0, 5)]
	image.fill_rect(Rect2i(at, Vector2i(T, T)), top)
	for i in 7:
		image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), top.darkened(0.12))
	for i in 3:
		var p := at + Vector2i(rng.randi_range(0, 14), rng.randi_range(0, 14))
		image.set_pixelv(p, top.lightened(0.2))
		image.set_pixelv(p + Vector2i(1, 0), top.lightened(0.2))
	if snowy and rng.randf() < 0.5:
		var p := at + Vector2i(rng.randi_range(2, 12), rng.randi_range(2, 8))
		_stamp(image, p, ["dd.", "ddd"], {"d": Color("8a7a6a")})
	if Vector2i.UP in lower:
		image.fill_rect(Rect2i(at, Vector2i(T, 1)), top.lightened(0.3))
	if Vector2i.LEFT in lower:
		image.fill_rect(Rect2i(at, Vector2i(1, T)), top.darkened(0.25))
	if Vector2i.RIGHT in lower:
		image.fill_rect(Rect2i(at + Vector2i(15, 0), Vector2i(1, T)), top.darkened(0.3))
	if Vector2i.DOWN in lower:
		var face := Color("8a6a4c") if not snowy else Color("a8b8cc")
		image.fill_rect(Rect2i(at + Vector2i(0, 9), Vector2i(T, 7)), face)
		image.fill_rect(Rect2i(at + Vector2i(0, 9), Vector2i(T, 1)), top.lightened(0.25))
		for x in range(rng.randi_range(0, 2), T, 3):
			var length := rng.randi_range(2, 5)
			image.fill_rect(Rect2i(at + Vector2i(x, 11), Vector2i(1, length)), face.darkened(0.25))
		image.fill_rect(Rect2i(at + Vector2i(0, 15), Vector2i(T, 1)), face.darkened(0.45))


# --- Nature ------------------------------------------------------------------

static func decor(style: String) -> Texture2D:
	return cached("decor:" + style, func() -> Texture2D:
		match style:
			"tree":
				return _round_tree(Color("6cc048"))
			"pine":
				return _pine()
			"palm":
				return _palm()
			"fern":
				return _fern()
			"bush":
				return _bush(true)
			"bush_empty":
				return _bush(false)
			"cactus":
				return _cactus()
			"rock":
				return _rock()
			"volcano":
				return _volcano()
		return _round_tree(Color("6cc048")))


static func border_tree(variant: int) -> Texture2D:
	return cached("border:%d" % variant, func() -> Texture2D:
		return _round_tree([Color("5cb040"), Color("4fa040"), Color("68b848")][variant % 3]))


static func _round_tree(leaf: Color) -> Texture2D:
	var p := _painter(Vector2i(24, 30))
	p.box(Rect2(9, 21, 6, 7), WOOD, true)
	p.ellipse(Vector2(12, 15), Vector2(10.5, 8), leaf.darkened(0.15))
	p.ellipse(Vector2(6.5, 13), Vector2(5, 5), leaf)
	p.ellipse(Vector2(17.5, 13), Vector2(5, 5), leaf)
	p.ellipse(Vector2(12, 8), Vector2(7, 6), leaf)
	p.ellipse(Vector2(12, 15), Vector2(5, 4), leaf)
	for spot in [Vector2(8, 7), Vector2(14, 5), Vector2(4, 12), Vector2(16, 11), Vector2(10, 14)]:
		p.dot(spot, leaf.lightened(0.4), 2)
	for spot in [Vector2(11, 18), Vector2(6, 17), Vector2(17, 17)]:
		p.dot(spot, leaf.darkened(0.45))
	return p.finish()


static func _pine() -> Texture2D:
	var p := _painter(Vector2i(20, 32))
	p.box(Rect2(8, 25, 4, 5), WOOD, true)
	var green := Color("2f8050")
	for i in 3:
		var y := 26.0 - i * 7.0
		var w := 9.0 - i * 2.0
		p.polygon(PackedVector2Array([Vector2(10 - w, y), Vector2(10, y - 12), Vector2(10 + w, y)]), green.lightened(i * 0.08), true)
	p.dot(Vector2(8, 10), Color("5fb07a"), 2)
	p.dot(Vector2(6, 18), Color("5fb07a"), 2)
	return p.finish()


static func _palm() -> Texture2D:
	var p := _painter(Vector2i(28, 32))
	var trunk := Color("b08850")
	for i in 5:
		p.limb(Vector2(12 + i * 0.6, 30 - i * 4.5), Vector2(12.6 + i * 0.6, 26 - i * 4.5), 2.2, 2.0, trunk if i % 2 == 0 else trunk.darkened(0.12), true)
	var top := Vector2(15, 8)
	for leaf in [Vector2(-12, 4), Vector2(-9, -5), Vector2(0, -7), Vector2(9, -5), Vector2(12, 5), Vector2(-4, 6), Vector2(5, 7)]:
		p.limb(top, top + leaf, 2.4, 0.6, Color("58a838"), true)
	p.ellipse(top + Vector2(-1, 2), Vector2(2, 2), Color("7a5030"))
	p.ellipse(top + Vector2(2, 2), Vector2(2, 2), Color("8a6038"))
	return p.finish()


static func _fern() -> Texture2D:
	var p := _painter(Vector2i(20, 16))
	var base := Vector2(10, 15)
	for leaf in [Vector2(-9, -5), Vector2(-5, -10), Vector2(0, -12), Vector2(5, -10), Vector2(9, -5)]:
		p.limb(base, base + leaf, 2.0, 0.6, Color("3f9a44"), true)
	return p.finish()


static func _bush(berries: bool) -> Texture2D:
	var p := _painter(Vector2i(20, 16))
	p.ellipse(Vector2(10, 9.5), Vector2(9, 5.5), Color("3a9044"))
	p.ellipse(Vector2(6, 7.5), Vector2(4.5, 4), Color("48a64c"))
	p.ellipse(Vector2(14, 7.5), Vector2(4.5, 4), Color("48a64c"))
	p.ellipse(Vector2(10, 5.5), Vector2(4, 3.5), Color("52b056"))
	if berries:
		for spot in [Vector2(5, 8), Vector2(9, 5), Vector2(13, 10), Vector2(15, 6), Vector2(8, 11)]:
			p.dot(spot, Color("d8243e"), 2)
			p.dot(spot + Vector2(-0.5, -0.5), Color("ff8a9a"))
	return p.finish()


static func _cactus() -> Texture2D:
	var p := _painter(Vector2i(18, 26))
	var green := Color("5e9e3a")
	p.limb(Vector2(4, 13), Vector2(4, 8), 2, 2, green, true)
	p.limb(Vector2(4, 14), Vector2(8, 14), 2, 2, green, true)
	p.limb(Vector2(14, 11), Vector2(14, 6), 2, 2, green, true)
	p.limb(Vector2(14, 12), Vector2(10, 12), 2, 2, green, true)
	p.limb(Vector2(9, 24), Vector2(9, 4), 3.3, 3, green, true)
	for y in [7, 12, 17]:
		p.dot(Vector2(8, y), green.lightened(0.4))
	p.dot(Vector2(9, 2.5), Color("f06090"), 2)
	return p.finish()


static func _rock() -> Texture2D:
	var p := _painter(Vector2i(18, 14))
	p.ellipse(Vector2(9, 8), Vector2(8, 5.5), Color("9a9aa2"))
	p.ellipse(Vector2(6, 6), Vector2(3, 2), Color("b8b8c0"))
	p.dot(Vector2(12, 9), Color("70707a"), 2)
	return p.finish()


static func _volcano() -> Texture2D:
	var p := _painter(Vector2i(50, 46))
	var rock := Color("7a5236")
	p.polygon(PackedVector2Array([Vector2(1, 44), Vector2(17, 10), Vector2(33, 10), Vector2(49, 44)]), rock)
	p.polygon(PackedVector2Array([Vector2(1, 44), Vector2(17, 10), Vector2(24, 10), Vector2(16, 44)]), rock.darkened(0.15))
	p.ellipse(Vector2(25, 10), Vector2(8, 2.5), Color("3a2418"))
	p.ellipse(Vector2(25, 10.5), Vector2(6, 1.5), Color("ff8a20"))
	for lava in [[Vector2(21, 11), Vector2(17, 26)], [Vector2(28, 11), Vector2(32, 30)], [Vector2(25, 12), Vector2(26, 20)]]:
		p.limb(lava[0], lava[1], 1.4, 0.8, Color("ff7020"))
	p.ellipse(Vector2(10, 42), Vector2(4, 2), Color("5a8a3a"))
	return p.finish()


# The entrance of a mine, dug into a cliff: 16 x 20 pixels, anchored at its bottom center.
static func mine_entrance() -> Texture2D:
	return cached("mine_entrance", func() -> Texture2D:
		var p := _painter(Vector2i(18, 20))
		p.ellipse(Vector2(9, 13), Vector2(7, 7), Color("2a2018"))
		p.box(Rect2(2, 6, 14, 14), Color("2a2018"))
		p.flat(Rect2(4, 8, 10, 12), Color("120c08"))
		p.box(Rect2(1, 5, 3, 15), WOOD, true)
		p.box(Rect2(14, 5, 3, 15), WOOD, true)
		p.box(Rect2(0, 3, 18, 3), WOOD.lightened(0.1), true)
		p.flat(Rect2(6, 15, 6, 1), Color("807060"))
		p.flat(Rect2(6, 18, 6, 1), Color("807060"))
		return p.finish())


# --- Fences ------------------------------------------------------------------
# 16 x 40 images: the cell is the bottom 16 rows, the fence stands on its center, pixel (8, 32).

const FENCE_ANCHOR := Vector2(8, 32)
const FENCE_HEIGHT := {"bamboo": 12, "wood": 12, "stone": 13, "glass": 16, "concrete": 17, "electric": 20, "gate": 14}


# sign: a danger sign on electric fences; open: a gate standing open.
static func fence(style: String, links: Array, sign := false, open := false) -> Texture2D:
	var key := "fence:%s:%s:%s:%s:%s:%s:%s" % [style, Vector2i.LEFT in links, Vector2i.RIGHT in links, Vector2i.UP in links, Vector2i.DOWN in links, sign, open]
	return cached(key, func() -> Texture2D:
		var p := _painter(Vector2i(16, 40))
		if style == "stone" or style == "concrete":
			_wall(p, style, links)
		elif style == "gate":
			_gate(p, links, open)
		else:
			_rail_fence(p, style, links, sign)
		return p.finish())


static func _rail_fence(p: Painter, style: String, links: Array, sign: bool) -> void:
	var h: int = FENCE_HEIGHT[style]
	var base := 32
	var post := Color("c8b45a")
	var rail := Color("a8963e")
	var rails := [4, 9]
	match style:
		"wood":
			post = Color("8d6040")
			rail = Color("b08058")
		"glass":
			post = Color("78909c")
			rail = Color("90a4ae")
			rails = [1, h - 1]
		"electric":
			post = Color("4a4a50")
			rail = Color("fff176")
			rails = [4, 8, 12, 16]
	# Rails going north and south are seen from above: they are drawn first, behind the post.
	for r in rails:
		if Vector2i.UP in links:
			p.box(Rect2(7, base - r - 16, 2, 16), rail, style != "electric")
		if Vector2i.DOWN in links:
			p.box(Rect2(7, base - r, 2, 8), rail, style != "electric")
	if style == "glass":
		for dir in [Vector2i.LEFT, Vector2i.RIGHT]:
			if dir in links:
				var x := 0 if dir == Vector2i.LEFT else 8
				p.flat(Rect2(x, base - h, 8, h), Color(0.72, 0.9, 1.0, 0.45))
				p.flat(Rect2(x + 2, base - h + 2, 1, h - 6), Color(1, 1, 1, 0.55))
	for r in rails:
		for dir in [Vector2i.LEFT, Vector2i.RIGHT]:
			if dir in links:
				var x := 0 if dir == Vector2i.LEFT else 8
				if style == "electric":
					p.flat(Rect2(x, base - r, 8, 1), rail)
				else:
					p.box(Rect2(x, base - r - 1, 8, 2), rail, true)
	if style == "bamboo":
		for dir in [Vector2i.LEFT, Vector2i.RIGHT]:
			if dir in links:
				var x := 2 if dir == Vector2i.LEFT else 12
				p.box(Rect2(x, base - h + 2, 2, h - 1), post.darkened(0.08), true)
	p.box(Rect2(6, base - h, 4, h + 1), post, true)
	match style:
		"bamboo":
			p.flat(Rect2(6, base - h + 4, 4, 1), post.darkened(0.35))
			p.flat(Rect2(6, base - h + 9, 4, 1), post.darkened(0.35))
		"electric":
			p.box(Rect2(5, base - h - 2, 6, 3), Color("fdd835"), true)
			if sign:
				p.box(Rect2(4, base - 13, 8, 7), Color("fdd835"), true)
				p.flat(Rect2(7, base - 12, 2, 3), Color("202020"))
				p.flat(Rect2(7, base - 8, 2, 1), Color("202020"))
		_:
			p.flat(Rect2(6, base - h, 4, 1), post.lightened(0.3))


# A wooden gate between two posts. Across a north-south fence, it is seen from above.
static func _gate(p: Painter, links: Array, open: bool) -> void:
	var h: int = FENCE_HEIGHT.gate
	var base := 32
	var wood := Color("a0703c")
	var post := Color("7a4e2c")
	if Vector2i.UP in links or Vector2i.DOWN in links:
		p.box(Rect2(6, base - h - 9, 4, 4), post, true)
		p.box(Rect2(6, base - h + 7, 4, 4), post, true)
		if not open:
			p.box(Rect2(7, base - h - 6, 2, 14), wood, true)
		return
	p.box(Rect2(0, base - h - 1, 3, h + 2), post, true)
	p.box(Rect2(13, base - h - 1, 3, h + 2), post, true)
	if open:
		# The door swung against the left post: seen edge-on.
		p.box(Rect2(3, base - h + 1, 2, h - 1), wood.darkened(0.15), true)
		return
	p.box(Rect2(3, base - h + 1, 10, h - 1), wood, true)
	for x in [5, 8, 11]:
		p.flat(Rect2(x, base - h + 1, 1, h - 1), wood.darkened(0.3))
	p.line(Vector2(3.5, base - 1.5), Vector2(12.5, base - h + 1.5), wood.darkened(0.35))
	p.flat(Rect2(11, base - h / 2 - 1, 1, 2), Color("e0c040"))


static func _wall(p: Painter, style: String, links: Array) -> void:
	var h: int = FENCE_HEIGHT[style]
	var base := 32
	var face := Color("9a9aa0") if style == "stone" else Color("c4ccd0")
	var top := Color("c8c8cc") if style == "stone" else Color("eef2f4")
	var segments := [Rect2(5, base - 3 - h, 6, 6)]
	if Vector2i.LEFT in links:
		segments.append(Rect2(0, base - 3 - h, 8, 6))
	if Vector2i.RIGHT in links:
		segments.append(Rect2(8, base - 3 - h, 8, 6))
	if Vector2i.UP in links:
		segments.append(Rect2(5, base - 3 - h - 10, 6, 10))
	if Vector2i.DOWN in links:
		segments.append(Rect2(5, base + 3 - h, 6, 10))
	# Front faces: under the horizontal parts and under the pillar when the wall stops here.
	var faces := []
	if Vector2i.LEFT in links:
		faces.append(Rect2(0, base + 3 - h, 8, h))
	if Vector2i.RIGHT in links:
		faces.append(Rect2(8, base + 3 - h, 8, h))
	if not Vector2i.DOWN in links:
		faces.append(Rect2(5, base + 3 - h, 6, h))
	for rect in faces:
		p.box(rect, face, true)
		if style == "stone":
			for y in range(int(rect.position.y) + 3, int(rect.end.y), 4):
				p.flat(Rect2(rect.position.x, y, rect.size.x, 1), face.darkened(0.25))
				var offset := 2 if (y / 4) % 2 == 0 else 5
				for x in range(int(rect.position.x) + offset, int(rect.end.x), 6):
					p.flat(Rect2(x, y - 3, 1, 3), face.darkened(0.25))
		else:
			p.flat(Rect2(rect.position.x, rect.position.y + 1, rect.size.x, 2), Color("f2c230"))
	for rect in segments:
		p.box(rect, top, true)


# --- Buildings ---------------------------------------------------------------

static func item(id: String) -> Texture2D:
	var data: Dictionary = Catalog.ITEMS[id]
	match data.kind:
		"decor":
			return decor(data.style)
		"shop":
			return shop(data)
		"feeder":
			return feeder(data.diet)
		"aviary":
			return aviary(Catalog.size_of(data))
		"lagoon":
			return lagoon(Catalog.size_of(data), 0)
		"gyro_station":
			return gyro_station()
		"garage":
			return garage()
		"heliport":
			return heliport()
		"fence":
			return fence(data.style, [Vector2i.LEFT, Vector2i.RIGHT])
	return null


static func shop(data: Dictionary) -> Texture2D:
	return cached("shop:" + data.style, func() -> Texture2D:
		var p := _painter(Vector2i(18, 30))
		var color: Color = data.color
		p.box(Rect2(2, 17, 14, 11), Color("f4ecdc"), true)
		p.flat(Rect2(2, 21, 14, 2), color)
		p.box(Rect2(3, 12, 2, 6), Color("8a8a90"), true)
		p.box(Rect2(13, 12, 2, 6), Color("8a8a90"), true)
		p.box(Rect2(1, 9, 16, 5), Color.WHITE, true)
		for x in range(1, 17, 4):
			p.flat(Rect2(x, 9, 2, 5), color)
		match data.style:
			"icecream":
				p.polygon(PackedVector2Array([Vector2(6, 4), Vector2(12, 4), Vector2(9, 9)]), Color("d7a35c"), true)
				p.ellipse(Vector2(9, 3.5), Vector2(3.5, 3), Color("f48fb1"), true)
			"burger":
				p.ellipse(Vector2(9, 4), Vector2(5, 2.5), Color("e0a040"), true)
				p.box(Rect2(4, 5, 10, 1), Color("5a8a2a"))
				p.box(Rect2(4, 6, 10, 2), Color("7a3a20"), true)
			"souvenir":
				p.box(Rect2(5, 2, 8, 7), Color("7e57c2"), true)
				p.flat(Rect2(8, 2, 2, 7), Color("fdd835"))
				p.flat(Rect2(5, 5, 8, 1), Color("fdd835"))
		return p.finish())


static func feeder(diet: String) -> Texture2D:
	return cached("feeder:" + diet, func() -> Texture2D:
		var p := _painter(Vector2i(16, 22))
		if diet == "herb":
			p.box(Rect2(1, 14, 14, 6), WOOD, true)
			for x in [3, 7, 11]:
				p.ellipse(Vector2(x + 1, 13), Vector2(3, 2.5), Color("c0d040"))
			p.dot(Vector2(6, 12), Color("e8f070"), 2)
		else:
			p.box(Rect2(3, 4, 2, 17), WOOD, true)
			p.box(Rect2(3, 3, 11, 2), WOOD, true)
			p.ellipse(Vector2(11, 11), Vector2(3.5, 4), Color("c62828"), true)
			p.box(Rect2(10, 5, 1, 3), Color("eeeeee"))
			p.dot(Vector2(10, 15), Color("eeeeee"), 2)
		return p.finish())


static func gyro_station() -> Texture2D:
	return cached("gyro_station", func() -> Texture2D:
		var p := _painter(Vector2i(32, 40))
		p.box(Rect2(2, 18, 28, 20), Color("e8f4fa"), true)
		p.box(Rect2(12, 27, 8, 11), Color("4a6a80"), true)
		p.box(Rect2(4, 22, 6, 5), Color("a8e0f8"), true)
		p.box(Rect2(22, 22, 6, 5), Color("a8e0f8"), true)
		p.box(Rect2(0, 11, 32, 8), Color("4fb3e7"), true)
		p.ellipse(Vector2(16, 7), Vector2(6, 6), Color(0.7, 0.9, 1.0, 0.8), true)
		p.box(Rect2(10, 6, 12, 2), Color("ff9800"))
		p.dot(Vector2(14, 4), Color.WHITE, 2)
		return p.finish())


static func garage() -> Texture2D:
	return cached("garage", func() -> Texture2D:
		var p := _painter(Vector2i(32, 36))
		p.box(Rect2(2, 14, 28, 20), Color("d0b08a"), true)
		p.box(Rect2(6, 20, 20, 14), Color("9ea0a6"), true)
		for y in range(22, 34, 3):
			p.flat(Rect2(6, y, 20, 1), Color("7e8086"))
		p.box(Rect2(0, 8, 32, 7), Color("6d4c41"), true)
		p.box(Rect2(10, 3, 12, 5), Color("6d8f3a"), true)
		p.flat(Rect2(12, 5, 8, 1), Color("f0e070"))
		return p.finish())


static func heliport() -> Texture2D:
	return cached("heliport", func() -> Texture2D:
		var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
		for y in 48:
			for x in 48:
				var d := _rounded_distance(x, y, 48, 48, 5)
				if d < 0.0:
					continue
				var color := Color("8a9098") if d >= 3.0 else Color("6a7078")
				if d < 1.0:
					color = OUTLINE
				var r := Vector2(x - 23.5, y - 23.5).length()
				if r > 15.0 and r < 18.0:
					color = Color("f2c230")
				image.set_pixel(x, y, color)
		_stamp(image, Vector2i(17, 16), [
			"ww.....ww", "ww.....ww", "ww.....ww", "ww.....ww", "wwwwwwwww", "wwwwwwwww",
			"ww.....ww", "ww.....ww", "ww.....ww", "ww.....ww"], {"w": Color("f8f8f8")})
		for corner in [Vector2i(4, 4), Vector2i(42, 4), Vector2i(4, 42), Vector2i(42, 42)]:
			image.fill_rect(Rect2i(corner, Vector2i(2, 2)), Color("ff5252") if corner.y < 20 else Color("69f0ae"))
		return ImageTexture.create_from_image(image))


static func lagoon(size: Vector2i, frame: int) -> Texture2D:
	return cached("lagoon:%s:%d" % [size, frame], func() -> Texture2D:
		var w := size.x * T
		var h := size.y * T
		var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in w:
				var d := _rounded_distance(x, y, w, h, 10)
				if d < 0.0:
					continue
				var color: Color
				if d < 1.0:
					color = Color("6a5030")
				elif d < 5.0:
					color = Color("e2cc94") if (x * 7 + y * 3) % 11 != 0 else Color("c8ae74")
				elif d < 6.0:
					color = Color("2a50a8")
				elif d < 8.0:
					color = Color("3a68c8")
				else:
					color = Color("4a7ee0")
					var wave := (y + int(round(2.0 * sin((x + frame * 4) * TAU / 24.0)))) % 10
					if wave == 0:
						color = Color("78b0f4")
					elif wave == 1:
						color = Color("5c94ec")
				image.set_pixel(x, y, color)
		return ImageTexture.create_from_image(image))


# Distance from the border of a rectangle with rounded corners (negative outside).
static func _rounded_distance(x: int, y: int, w: int, h: int, radius: int) -> float:
	var q := Vector2(maxf(maxf(radius - x - 0.5, x + 0.5 - (w - radius)), 0.0), maxf(maxf(radius - y - 0.5, y + 0.5 - (h - radius)), 0.0))
	var inner := minf(minf(x + 0.5, w - x - 0.5), minf(y + 0.5, h - y - 0.5))
	if q == Vector2.ZERO:
		return inner
	return radius - q.length()


# The cage of an aviary, seen from above: a net roof lifted by its posts, and the front net.
const AVIARY_HEIGHT := 30


static func aviary(size: Vector2i) -> Texture2D:
	return cached("aviary:%s" % size, func() -> Texture2D:
		var w := size.x * T
		var h := size.y * T
		var image := Image.create(w, h + AVIARY_HEIGHT, false, Image.FORMAT_RGBA8)
		var net := Color(0.9, 0.94, 1.0, 0.32)
		var frame := Color("6a7a88")
		for y in h:
			for x in w:
				if x % 6 == 0 or y % 6 == 0:
					image.set_pixel(x, y, net)
		for y in range(h, h + AVIARY_HEIGHT):
			for x in w:
				if x % 6 == 0 or (y - h) % 6 == 0:
					image.set_pixel(x, y, Color(net, 0.25))
		image.fill_rect(Rect2i(0, 0, w, 2), frame)
		image.fill_rect(Rect2i(0, h - 2, w, 2), frame)
		image.fill_rect(Rect2i(0, 0, 2, h), frame)
		image.fill_rect(Rect2i(w - 2, 0, 2, h), frame)
		for x in range(0, w, 32) + [w - 3]:
			image.fill_rect(Rect2i(x, h - 2, 3, AVIARY_HEIGHT + 2), frame)
			image.fill_rect(Rect2i(x, h - 2, 1, AVIARY_HEIGHT + 2), frame.lightened(0.35))
		return ImageTexture.create_from_image(image))


# The park gate, standing outside the left edge of the map: 16 x 64 pixels.
static func gate() -> Texture2D:
	return cached("gate", func() -> Texture2D:
		var p := _painter(Vector2i(20, 72))
		var stone := Color("a8a098")
		p.box(Rect2(4, 24, 12, 4), Color("e8d4a0"))
		p.box(Rect2(5, 10, 10, 13), stone, true)
		p.box(Rect2(5, 56, 10, 13), stone, true)
		p.box(Rect2(7, 8, 6, 52), Color("8d6040"), true)
		p.box(Rect2(2, 2, 16, 8), Color("c0392b"), true)
		p.flat(Rect2(4, 4, 12, 1), Color("fdd835"))
		p.flat(Rect2(4, 7, 12, 1), Color("fdd835"))
		p.ellipse(Vector2(10, 32), Vector2(5, 5), Color("6cc048"), true)
		p.dot(Vector2(11, 31), EYE_DARK)
		return p.finish())


const EYE_DARK := Color("181818")


# --- People and vehicles --------------------------------------------------------

const PERSON := {
	"down": [
		["....oooo....", "..oohhhhoo..", ".ohhhhhhhho.", ".ohhhhhhhho.", ".ohssssssho.", ".ossessesso.",
		"..osssssso..", ".occcccccco.", "osccccccccso", "osccccccccso", ".oCCCCCCCCo.", "..oppppppo..",
		"..opp..ppo..", "..opo..opo..", "..obo..obo..", "..ooo..ooo.."],
		["....oooo....", "..oohhhhoo..", ".ohhhhhhhho.", ".ohhhhhhhho.", ".ohssssssho.", ".ossessesso.",
		"..osssssso..", ".occcccccco.", "osccccccccso", "osccccccccso", ".oCCCCCCCCo.", "..oppppppo..",
		"..opp..ppo..", "..obo..opo..", "..ooo..obo..", ".......ooo.."],
	],
	"up": [
		["....oooo....", "..oohhhhoo..", ".ohhhhhhhho.", ".ohhhhhhhho.", ".ohhhhhhhho.", ".ohhhhhhhho.",
		"..ohhhhhho..", ".occcccccco.", "osccccccccso", "osccccccccso", ".oCCCCCCCCo.", "..oppppppo..",
		"..opp..ppo..", "..opo..opo..", "..obo..obo..", "..ooo..ooo.."],
		["....oooo....", "..oohhhhoo..", ".ohhhhhhhho.", ".ohhhhhhhho.", ".ohhhhhhhho.", ".ohhhhhhhho.",
		"..ohhhhhho..", ".occcccccco.", "osccccccccso", "osccccccccso", ".oCCCCCCCCo.", "..oppppppo..",
		"..opp..ppo..", "..opo..obo..", "..obo..ooo..", "..ooo......."],
	],
	"side": [
		["....oooo....", "...ohhhhoo..", "..ohhhhhhho.", "..ohhhhhhhho", "..ohhhsssso.", "..ohhssesso.",
		"...osssssso.", "..occcccco..", "..occcscco..", "..occcscco..", "..oCCCsCCo..", "...oppppo...",
		"...oppppo...", "..opo..opo..", "..obo..obo..", "..ooo..ooo.."],
		["....oooo....", "...ohhhhoo..", "..ohhhhhhho.", "..ohhhhhhhho", "..ohhhsssso.", "..ohhssesso.",
		"...osssssso.", "..occcccco..", "..occcscco..", "..occcscco..", "..oCCCsCCo..", "...oppppo...",
		"...oppppo...", "....oppo....", "....obbo....", "....oooo...."],
	],
}


# Extra hair for the "long" style, drawn over the base drawing ("." keeps what is there).
const LONG_HAIR := {
	"down": ["oh........ho", "oh........ho", "oh........ho", "oh........ho", "oh........ho"],
	"up": ["oh........ho", "oh........ho", "oh.hhhhhh.ho", "oh.hhhhhh.ho", "oh.hhhhhh.ho", "...hhhhhh..."],
	"side": [".oh.........", ".ohh........", ".ohh........", ".oh.........", ".oh........."],
}


# colors: hair, skin, shirt, pants, optionally hat (a cap) and style ("long" hair).
# Feet at the bottom center (6, 16).
static func person(direction: String, frame: int, colors: Dictionary) -> Texture2D:
	var key := "person:%s:%d:%s" % [direction, frame, colors.values()]
	return cached(key, func() -> Texture2D:
		var image := Image.create(12, 16, false, Image.FORMAT_RGBA8)
		var rows: Array = PERSON[direction][frame].duplicate()
		if colors.has("hat"):
			for y in 3:
				rows[y] = rows[y].replace("h", "k")
		var shirt: Color = colors.shirt
		var palette := {
			"o": OUTLINE, "h": colors.hair, "k": colors.get("hat", Color.BLACK), "s": colors.skin, "e": Color("202020"),
			"c": shirt, "C": shirt.darkened(0.25), "p": colors.pants, "b": Color("3a3a40"),
		}
		_stamp(image, Vector2i.ZERO, rows, palette)
		if colors.get("style", "") == "long":
			_stamp(image, Vector2i(0, 4), LONG_HAIR[direction], palette)
		return ImageTexture.create_from_image(image))


# --- The hero: a little explorer with a bush hat ------------------------------------------
# Bigger than the other people (16 x 24 pixels, feet at the bottom center): a big head under a
# bush hat, a shirt with a pocket, shorts, white socks and red sneakers, 4 walking frames.
# colors: skin, hair, shirt, pants, hat, and style: "short" hair, or "long" (a ponytail).
# Letters: o outline, H/h/K hat/brim/band, R/r hair, s/S skin, e eye, w white, m mouth, b blush,
# B hair tie, c/C shirt, p/P shorts, k socks, n sneakers.

const KHAKI := Color("a08a70")

const HERO_SIDE_HEAD := [
	"....oooooo......",
	"...oHHHHHHoo....",
	"..oHHHHHHHHHo...",
	"..oHHHHHHHHHo...",
	"..oKKKKKKKKKKo..",
	".ohhhhhhhhhhhhho",
	".ooRRRRRRssssoo.",
	"..oRRRRRsswesso.",
	"..oRRRRSsswesso.",
	"..oRRRRRssssssso",
	"...oRRRsssssmo..",
	"....oooossssoo..",
]

const HERO_SIDE_ARMS := {
	"hang": [".....occccco....", "....occcccco....", "....occCcCco....", "....occCcCco....", "....occcssco...."],
	"front": [".....occccco....", "....occccccco...", "....occccoCcso..", "....occcco.osso.", "....occcco..oo.."],
	"back": [".....occccco....", "...oocccccco....", "..osCoccccco....", ".osso.occcco....", "..oo..occcco...."],
}

const HERO_SIDE_SHORTS := [
	"....opppppPo....",
	"....opppppPo....",
]

const HERO_SIDE_LEGS := {
	"together": [".....oso.oso....", ".....oko.oko....", ".....oko.oko....", ".....onnnonnno..", ".....oooooooo..."],
	"apart": ["....oso..oso....", "...oso....oso...", "...oko....oko...", "..onnno...onnno.", "..ooooo...ooooo."],
}

# Seen from the front and the back: the left half, mirrored.

const HERO_FRONT_HEAD := [
	".....ooo",
	"....oHHH",
	"...oHHHH",
	"...oHHHH",
	"...oKKKK",
	".ohhhhhh",
	".ooRRRRR",
	"..oRssss",
	"..oRsess",
	"..oRsess",
	"..oRbssm",
	"...oosss",
]

const HERO_BACK_HEAD := [
	".....ooo",
	"....oHHH",
	"...oHHHH",
	"...oHHHH",
	"...oKKKK",
	".ohhhhhh",
	".ooRRRRR",
	"..oRRRRR",
	"..oRRRRR",
	"..oRRRRR",
	"..orRRRR",
	"...oorrs",
]

const HERO_FRONT_BODY := [
	"....ocCs",
	"...occcc",
	"..oCcccc",
	"..oscccc",
	"..osoccc",
	"....oppp",
	"....oppp",
]

const HERO_BACK_BODY := [
	"....occc",
	"...occcc",
	"..oCcccc",
	"..oscccc",
	"..osoccc",
	"....oppp",
	"....oppp",
]

const HERO_LEGS := [
	"....osso",
	"....okko",
	"....okko",
	"...onnno",
	"...ooooo",
]

# The ponytail ("long" style), drawn over the rest from a row ("." keeps what is there).

const HERO_SIDE_TAIL := [
	"..B.............",
	"oRRo............",
	"oRRo............",
	"oRro............",
	".oRo............",
	"..o.............",
]

const HERO_FRONT_TAIL := [
	"................",
	".oRo........oRo.",
	".oRo........oRo.",
	".oRo........oRo.",
	".oRo........oRo.",
	"..o..........o..",
]

const HERO_BACK_TAIL := [
	".......BB.......",
	"......oRRo......",
	"......oRRo......",
	"......oRro......",
	".......oo.......",
	"................",
]


static func hero(direction: String, frame: int, colors: Dictionary) -> Texture2D:
	frame = frame % 4
	var key := "hero:%s:%d:%s" % [direction, frame, colors.values()]
	return cached(key, func() -> Texture2D:
		var long: bool = colors.get("style", "") == "long"
		var rows: Array = []
		if direction == "side":
			rows = HERO_SIDE_HEAD + HERO_SIDE_ARMS[["hang", "front", "hang", "back"][frame]] + HERO_SIDE_SHORTS \
				+ HERO_SIDE_LEGS["together" if frame % 2 == 0 else "apart"]
			if long:
				rows = _over(rows, 6, HERO_SIDE_TAIL)
		else:
			var front := direction == "down"
			var legs := _mirror(HERO_LEGS)
			# Walking towards us or away: one foot up, then the other.
			if frame == 1:
				legs = _lift(legs, 0)
			elif frame == 3:
				legs = _lift(legs, 8)
			rows = _mirror(HERO_FRONT_HEAD if front else HERO_BACK_HEAD) + _mirror(HERO_FRONT_BODY if front else HERO_BACK_BODY) + legs
			if long:
				rows = _over(rows, 6, HERO_FRONT_TAIL) if front else _over(rows, 8, HERO_BACK_TAIL)
		var hat: Color = colors.get("hat", KHAKI)
		var palette := {
			"o": OUTLINE, "H": hat, "h": hat.darkened(0.12), "K": hat.darkened(0.55),
			"R": colors.hair, "r": colors.hair.darkened(0.25), "s": colors.skin, "S": colors.skin.darkened(0.2),
			"e": Color("2a1a10"), "w": Color.WHITE, "m": Color("c0505a"), "b": Color("f4a0a0"), "B": Color("2a8adf"),
			"c": colors.shirt, "C": colors.shirt.darkened(0.2), "p": colors.pants, "P": colors.pants.darkened(0.25),
			"k": Color("f4f4f4"), "n": Color("e53935"),
		}
		var image := Image.create(16, 24, false, Image.FORMAT_RGBA8)
		_stamp(image, Vector2i.ZERO, rows, palette)
		return ImageTexture.create_from_image(image))


static func _mirror(half: Array) -> Array:
	return half.map(func(row: String) -> String: return row + row.reverse())


# Draws `over` on `rows` from the row `top`; "." keeps what is there.
static func _over(rows: Array, top: int, over: Array) -> Array:
	rows = rows.duplicate()
	for i in over.size():
		var row: String = rows[top + i]
		for x in over[i].length():
			if over[i][x] != ".":
				row[x] = over[i][x]
		rows[top + i] = row
	return rows


# The leg in the 8 columns from `left` one pixel higher.
static func _lift(legs: Array, left: int) -> Array:
	var out := []
	for y in legs.size():
		var row: String = legs[y]
		var below: String = legs[y + 1] if y + 1 < legs.size() else ".".repeat(16)
		out.append(row.substr(0, left) + below.substr(left, 8) + row.substr(left + 8))
	return out


const RANGER := {"hair": Color("5a3a1a"), "skin": Color("f1c27d"), "shirt": Color("d8c080"), "pants": Color("6d5a3a"), "hat": Color("4f7a2a")}


static func ice_cream() -> Texture2D:
	return cached("ice_cream", func() -> Texture2D:
		var image := Image.create(4, 6, false, Image.FORMAT_RGBA8)
		_stamp(image, Vector2i.ZERO, [".pp.", "pppp", "cccc", ".cc.", ".cc.", "..c."], {"p": Color("f48fb1"), "c": Color("d7a35c")})
		return ImageTexture.create_from_image(image))


# A rolling gyrosphere: the orange band turns with the frame. Centered on the ball.
static func gyro(frame: int) -> Texture2D:
	return cached("gyro:%d" % frame, func() -> Texture2D:
		var p := _painter(Vector2i(20, 20))
		p.ellipse(Vector2(10, 10), Vector2(8.5, 8.5), Color(0.72, 0.9, 1.0, 0.6))
		p.box(Rect2(7, 11, 6, 4), Color("e05050"), true)
		p.ellipse(Vector2(10, 8.5), Vector2(2.5, 2.5), Color("f1c27d"), true)
		var squash: float = [1.0, 0.6, 0.15, 0.6][frame % 4]
		for i in 40:
			var a := TAU * i / 40.0
			p.dot(Vector2(10 + cos(a) * 8.0 * squash, 10 + sin(a) * 8.0), Color("ff9800"))
		p.dot(Vector2(6, 5), Color.WHITE, 2)
		return p.finish())


# The jeep, side view facing right.
static func jeep(frame: int) -> Texture2D:
	return cached("jeep:%d" % frame, func() -> Texture2D:
		var p := _painter(Vector2i(30, 20))
		var body := Color("6d8f3a")
		p.box(Rect2(3, 8, 24, 7), body, true)
		p.box(Rect2(20, 6, 7, 3), body, true)
		p.box(Rect2(18, 2, 2, 6), Color("a8e0f8"), true)
		p.limb(Vector2(6, 8), Vector2(7, 2), 0.8, 0.8, Color("404040"))
		p.limb(Vector2(7, 2), Vector2(17, 2), 0.8, 0.8, Color("404040"))
		p.ellipse(Vector2(10, 5), Vector2(2, 2), Color("f1c27d"), true)
		p.ellipse(Vector2(14.5, 5), Vector2(2, 2), Color("8d5524"), true)
		p.flat(Rect2(3, 11, 24, 1), Color("f0e070"))
		for x in [8, 22]:
			p.ellipse(Vector2(x, 16), Vector2(3.5, 3.5), Color("303034"), true)
			var a := frame * PI / 2.0
			p.dot(Vector2(x, 16) + Vector2(cos(a), sin(a)) * 1.5, Color("b0b0b8"))
		return p.finish())


# The helicopter, side view facing right; the rotor blurs between frames. Anchor (17, 20).
static func helicopter(frame: int) -> Texture2D:
	return cached("heli:%d" % frame, func() -> Texture2D:
		var p := _painter(Vector2i(36, 22))
		var red := Color("e53935")
		p.limb(Vector2(12, 11), Vector2(2, 7), 2.2, 1.2, red)
		p.polygon(PackedVector2Array([Vector2(1, 9), Vector2(1, 3), Vector2(5, 7)]), red.darkened(0.2), true)
		p.ellipse(Vector2(2, 8), Vector2(2.5, 2.5), Color(0.3, 0.3, 0.3, 0.6) if frame == 0 else Color(0.5, 0.5, 0.5, 0.4))
		p.ellipse(Vector2(19, 12), Vector2(9, 6), red)
		p.ellipse(Vector2(23, 11), Vector2(4.5, 4), Color("a8e0f8"))
		p.dot(Vector2(22, 9), Color.WHITE, 2)
		p.box(Rect2(18, 4, 2, 3), Color("404040"))
		p.box(Rect2(12, 19, 16, 1), Color("404040"))
		p.box(Rect2(15, 17, 1, 2), Color("404040"))
		p.box(Rect2(24, 17, 1, 2), Color("404040"))
		if frame == 0:
			p.flat(Rect2(2, 3, 34, 1), Color("303030"))
		else:
			p.flat(Rect2(11, 3, 16, 1), Color("303030"))
			p.flat(Rect2(5, 3, 6, 1), Color(0.2, 0.2, 0.2, 0.35))
			p.flat(Rect2(27, 3, 6, 1), Color(0.2, 0.2, 0.2, 0.35))
		return p.finish())


static func shadow(width: int) -> Texture2D:
	width = clampi(width, 4, 120)
	return cached("shadow:%d" % width, func() -> Texture2D:
		var h := maxi(width / 3, 2)
		var image := Image.create(width, h, false, Image.FORMAT_RGBA8)
		for y in h:
			for x in width:
				var d := Vector2((x + 0.5) / width * 2.0 - 1.0, (y + 0.5) / h * 2.0 - 1.0)
				if d.length_squared() <= 1.0:
					image.set_pixel(x, y, Color(0.05, 0.15, 0.05, 0.28))
		return ImageTexture.create_from_image(image))


# --- Things in the bag -----------------------------------------------------------

static func resource(id: String) -> Texture2D:
	return cached("resource:" + id, func() -> Texture2D:
		var p := _painter(Vector2i(16, 16))
		match id:
			"wood":
				p.limb(Vector2(3, 9), Vector2(12, 7), 3.5, 3.5, WOOD, true)
				p.ellipse(Vector2(12.5, 7), Vector2(2.5, 3.5), Color("e8c080"), true)
				p.dot(Vector2(12.5, 7), Color("b08050"))
			"stone":
				p.ellipse(Vector2(8, 9), Vector2(6.5, 5), Color("9a9aa2"))
				p.ellipse(Vector2(6, 7), Vector2(2.5, 1.5), Color("c0c0c8"))
			"berries":
				p.ellipse(Vector2(8, 3), Vector2(3, 1.5), Color("4aa84c"))
				for spot in [Vector2(5, 9), Vector2(11, 9), Vector2(8, 12), Vector2(8, 6.5)]:
					p.ellipse(spot, Vector2(2.6, 2.6), Color("d8243e"))
					p.dot(spot + Vector2(-1, -1), Color("ff9aaa"))
			"meat":
				p.limb(Vector2(3, 13), Vector2(7, 9), 1.3, 1.3, Color("f4ecd8"), true)
				p.ellipse(Vector2(2.5, 13.5), Vector2(2, 2), Color("f4ecd8"), true)
				p.ellipse(Vector2(10, 6), Vector2(5.5, 4.5), Color("c0443a"), true, -0.7)
				p.ellipse(Vector2(9, 5), Vector2(2.5, 1.5), Color("e8806a"), false, -0.7)
			"axe":
				p.limb(Vector2(4, 15), Vector2(11, 2), 1.2, 1.2, WOOD, true)
				p.polygon(PackedVector2Array([Vector2(9, 1), Vector2(15, 0), Vector2(16, 7), Vector2(11, 6)]), Color("b0b4bc"), true)
			"brush":
				p.limb(Vector2(2, 13), Vector2(8, 7), 1.2, 1.2, WOOD, true)
				p.box(Rect2(7, 2, 8, 6), Color("c08040"), true)
				for x in range(8, 15, 2):
					p.flat(Rect2(x, 8, 1, 3), Color("f0e0a0"))
			"saddle":
				p.ellipse(Vector2(8, 9), Vector2(7, 4), Color("8a4a24"), true)
				p.ellipse(Vector2(4, 6), Vector2(2.5, 3), Color("a05a2c"), true)
				p.ellipse(Vector2(12, 6.5), Vector2(2, 2.5), Color("a05a2c"), true)
				p.box(Rect2(7, 11, 2, 4), Color("5a3018"))
				p.dot(Vector2(8, 14), Color("e0c040"), 2)
			"copper", "iron", "crystal", "gold", "amber":
				var colors: Array = ORE_COLORS[id]
				if id == "crystal":
					p.polygon(PackedVector2Array([Vector2(8, 1), Vector2(13, 7), Vector2(8, 15), Vector2(3, 7)]), colors[0], true)
					p.dot(Vector2(7, 5), colors[1], 2)
				elif id == "amber":
					p.ellipse(Vector2(8, 8.5), Vector2(6, 5.5), colors[0], true)
					p.dot(Vector2(8, 9), Color("3a2a10"), 2)
					p.dot(Vector2(5.5, 6), colors[1], 2)
				else:
					p.polygon(PackedVector2Array([Vector2(1, 12), Vector2(4, 5), Vector2(12, 3), Vector2(15, 10), Vector2(10, 14)]), colors[0], true)
					p.dot(Vector2(6, 7), colors[1], 2)
					p.dot(Vector2(11, 9), colors[1])
			"fossil":
				p.limb(Vector2(3, 12), Vector2(13, 4), 1.6, 1.6, ORE_COLORS.fossil[0], true)
				p.ellipse(Vector2(3, 12), Vector2(2.5, 2.5), ORE_COLORS.fossil[0], true)
				p.ellipse(Vector2(13, 4), Vector2(2.5, 2.5), ORE_COLORS.fossil[0], true)
			"pickaxe_iron":
				p.limb(Vector2(4, 15), Vector2(10, 3), 1.2, 1.2, WOOD, true)
				p.limb(Vector2(3, 4), Vector2(10, 1.5), 1.6, 1.4, Color("e0e4ec"), true)
				p.limb(Vector2(10, 1.5), Vector2(15, 7), 1.4, 0.6, Color("e0e4ec"), true)
				p.dot(Vector2(9, 2), Color("70a0e0"), 2)
			"cage":
				p.box(Rect2(1, 3, 14, 12), Color("c8a070"), true)
				p.box(Rect2(3, 5, 10, 8), Color("4a3a2a"))
				for x in [4, 7, 10]:
					p.box(Rect2(x, 4, 2, 10), Color("a07848"), true)
				p.box(Rect2(0, 1, 16, 3), WOOD, true)
			"pickaxe":
				p.limb(Vector2(4, 15), Vector2(10, 3), 1.2, 1.2, WOOD, true)
				p.limb(Vector2(3, 4), Vector2(10, 1.5), 1.6, 1.4, Color("b0b4bc"), true)
				p.limb(Vector2(10, 1.5), Vector2(15, 7), 1.4, 0.6, Color("b0b4bc"), true)
			"boots", "boots_fast":
				var leather := Color("8a5a30") if id == "boots" else Color("e53935")
				p.box(Rect2(4, 1, 6, 10), leather, true)
				p.ellipse(Vector2(9, 12.5), Vector2(6, 2.8), leather, true)
				p.flat(Rect2(3, 14, 13, 1), Color("3a2a1a"))
				if id == "boots_fast":
					p.flat(Rect2(4, 5, 6, 2), Color.WHITE)
					p.polygon(PackedVector2Array([Vector2(10, 3), Vector2(15, 1), Vector2(13, 5)]), Color("fdd835"), true)
				else:
					p.flat(Rect2(4, 2, 6, 1), leather.lightened(0.3))
			"hammer":
				p.limb(Vector2(4, 15), Vector2(10, 5), 1.3, 1.3, WOOD, true)
				p.limb(Vector2(5, 3), Vector2(14, 7), 2.4, 2.4, Color("b0b4bc"), true)
				p.dot(Vector2(7, 3), Color("e0e4ec"), 2)
			"slingshot":
				p.limb(Vector2(8, 15), Vector2(8, 9), 1.3, 1.3, WOOD, true)
				p.limb(Vector2(8, 9), Vector2(3, 2), 1.2, 1.0, WOOD, true)
				p.limb(Vector2(8, 9), Vector2(13, 2), 1.2, 1.0, WOOD, true)
				p.line(Vector2(3, 2), Vector2(8, 6), Color("d84a3a"))
				p.line(Vector2(13, 2), Vector2(8, 6), Color("d84a3a"))
				p.dot(Vector2(8, 6), Color("7a5030"), 2)
			"bow":
				for i in 8:
					var a := -1.25 + 2.5 * i / 7.0
					var b := -1.25 + 2.5 * (i + 1) / 7.0
					p.limb(Vector2(4 + 9 * cos(a), 8 + 7 * sin(a)), Vector2(4 + 9 * cos(b), 8 + 7 * sin(b)), 1.1, 1.1, WOOD, true)
				p.line(Vector2(7, 1), Vector2(7, 15), Color("f0e8d0"))
			"arrow":
				p.limb(Vector2(2, 14), Vector2(12, 4), 0.7, 0.7, Color("c09060"), true)
				p.polygon(PackedVector2Array([Vector2(15, 1), Vector2(10, 3), Vector2(13, 6)]), Color("b0b4bc"), true)
				p.polygon(PackedVector2Array([Vector2(1, 15), Vector2(1, 11), Vector2(4, 13), Vector2(5, 15)]), Color("e8e0f0"), true)
			"bolas":
				p.line(Vector2(8, 8), Vector2(3, 4), Color("a07848"))
				p.line(Vector2(8, 8), Vector2(13, 5), Color("a07848"))
				p.line(Vector2(8, 8), Vector2(8, 14), Color("a07848"))
				for spot in [Vector2(3, 4), Vector2(13, 5), Vector2(8, 13)]:
					p.ellipse(spot, Vector2(2.6, 2.6), Color("9a9aa2"), true)
					p.dot(spot + Vector2(-1, -1), Color("d0d0d8"))
			"capsule_copper", "capsule_iron", "capsule_gold":
				var metal: Array = ORE_COLORS[id.substr(8)]
				p.ellipse(Vector2(8, 8.5), Vector2(6.5, 6.5), Color("f4ecd8"), true)
				p.ellipse(Vector2(8, 6), Vector2(6.3, 4.2), metal[0])
				p.dot(Vector2(5, 4), metal[1], 2)
				p.flat(Rect2(2, 8, 13, 1), Color("4a3a2a"))
				p.ellipse(Vector2(8, 8.5), Vector2(2.3, 2.3), Color("f09818"), true)
				p.dot(Vector2(7.5, 8), Color("ffd070"))
		return p.finish())


# A heart of the player's life bar, full or empty.
static func heart(full: bool) -> Texture2D:
	return cached("heart:%s" % full, func() -> Texture2D:
		var p := _painter(Vector2i(11, 10))
		var color := Color("e53950") if full else Color("d8d0d8")
		p.ellipse(Vector2(3, 3.5), Vector2(2.6, 2.6), color, true)
		p.ellipse(Vector2(8, 3.5), Vector2(2.6, 2.6), color, true)
		p.polygon(PackedVector2Array([Vector2(0.6, 4.5), Vector2(10.4, 4.5), Vector2(5.5, 9.5)]), color, true)
		if full:
			p.dot(Vector2(2.5, 2.5), Color("ffb0c0"))
		return p.finish())


# What flies through the air when shooting: a pebble, an arrow, a dart, bolas or a capsule.
static func projectile(weapon: String) -> Texture2D:
	return cached("projectile:" + weapon, func() -> Texture2D:
		match weapon:
			"slingshot":
				var p := _painter(Vector2i(6, 6))
				p.ellipse(Vector2(3, 3), Vector2(2.2, 2.2), Color("9a9aa2"), true)
				return p.finish()
			"bow":
				var p := _painter(Vector2i(16, 6))
				p.limb(Vector2(2, 3), Vector2(12, 3), 0.6, 0.6, Color("c09060"), true)
				p.polygon(PackedVector2Array([Vector2(15, 3), Vector2(11, 0.5), Vector2(11, 5.5)]), Color("b0b4bc"), true)
				p.polygon(PackedVector2Array([Vector2(0, 0.5), Vector2(4, 3), Vector2(0, 5.5)]), Color("e8e0f0"), true)
				return p.finish()
			"dart":
				return _dart()
		var image: Image = resource(weapon).get_image()
		image.resize(10, 10, Image.INTERPOLATE_NEAREST)
		return ImageTexture.create_from_image(image))


# The icon of anything that can be in the bag.
static func bag_icon(id: String) -> Texture2D:
	if id == "":
		return null
	if id.begins_with("dino:"):
		return icon(id)
	# Not a bag item (like the hammer of the building mode): its drawing alone.
	var item: Dictionary = Items.ITEMS.get(id, {"kind": ""})
	if item.kind == "build":
		return icon(item.place)
	if id == "dart":
		return icon("dart")
	if item.kind == "vehicle":
		return cached("bag:" + id, func() -> Texture2D:
			return _fit(vehicle(id, 0).get_image()))
	return cached("bag:" + id, func() -> Texture2D:
		return _fit(resource(id).get_image()))


# --- Toolbar icons -------------------------------------------------------------

const ICON_SIZE := 40


static func icon(id: String) -> Texture2D:
	return cached("icon:" + id, func() -> Texture2D:
		return _fit(_icon_image(id)))


static func _icon_image(id: String) -> Image:
	if id.begins_with("biome:"):
		var image := Image.create(T, T, false, Image.FORMAT_RGBA8)
		paint_biome(image, Vector2i.ZERO, id.substr(6), 7)
		return image
	if id.begins_with("dino:"):
		return DinoArt.frames(id.substr(5)).walk[0].get_image()
	match id:
		"path":
			var image := Image.create(T, T, false, Image.FORMAT_RGBA8)
			paint_path(image, Vector2i.ZERO, [Vector2i.UP, Vector2i.DOWN], true, 3)
			return image
		"road":
			var image := Image.create(T, T, false, Image.FORMAT_RGBA8)
			paint_road(image, Vector2i.ZERO, [Vector2i.LEFT, Vector2i.RIGHT], 3)
			return image
		"mountain":
			var image := Image.create(T, T, false, Image.FORMAT_RGBA8)
			paint_mountain(image, Vector2i.ZERO, 1, [Vector2i.DOWN], 3)
			return image
		"bridge":
			var image := Image.create(T, T, false, Image.FORMAT_RGBA8)
			paint_water(image, Vector2i.ZERO, [], 3)
			paint_bridge(image, Vector2i.ZERO, true)
			return image
		"drive:walk":
			return person("down", 0, RANGER).get_image()
		"drive:gyro":
			return gyro(0).get_image()
		"drive:jeep":
			return jeep(0).get_image()
		"drive:heli":
			return helicopter(0).get_image()
		"bulldozer":
			return _bulldozer().get_image()
		"dart":
			return _dart().get_image()
	var texture := item(id)
	if texture == null:
		return Image.create(T, T, false, Image.FORMAT_RGBA8)
	var image := texture.get_image()
	if Catalog.ITEMS[id].kind == "fence":
		return image.get_region(Rect2i(0, 12, 16, 22))
	return image


static func _fit(image: Image) -> Texture2D:
	var size := image.get_size()
	var biggest := maxi(size.x, size.y)
	if biggest <= ICON_SIZE:
		var factor := maxi((ICON_SIZE + 8) / biggest, 1)
		image.resize(size.x * factor, size.y * factor, Image.INTERPOLATE_NEAREST)
	else:
		var ratio := float(ICON_SIZE) / biggest
		image.resize(maxi(int(size.x * ratio), 1), maxi(int(size.y * ratio), 1), Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(image)


static func _bulldozer() -> Texture2D:
	var p := _painter(Vector2i(24, 18))
	p.box(Rect2(4, 4, 10, 8), Color("f9a825"), true)
	p.box(Rect2(6, 6, 5, 4), Color("a8e0f8"))
	p.box(Rect2(14, 8, 4, 4), Color("f9a825"), true)
	p.box(Rect2(18, 5, 3, 10), Color("8a8a90"), true)
	p.box(Rect2(2, 12, 16, 5), Color("404048"), true)
	return p.finish()


static func _dart() -> Texture2D:
	var p := _painter(Vector2i(22, 10))
	p.limb(Vector2(3, 5), Vector2(15, 5), 1.6, 1.6, Color("e0e0e8"), true)
	p.limb(Vector2(15, 5), Vector2(21, 5), 0.6, 0.5, Color("909098"))
	p.polygon(PackedVector2Array([Vector2(1, 1), Vector2(6, 5), Vector2(1, 9)]), Color("ab47bc"), true)
	return p.finish()


# --- The village ---------------------------------------------------------------

const VILLAGE_WALLS := [Color("f4e4c4"), Color("e8d0b0"), Color("dfe8f0")]
const VILLAGE_ROOFS := [Color("c0503a"), Color("4a78b8"), Color("6a9a40")]
const MERCHANT := {"hair": Color("b0b0b8"), "skin": Color("f1c27d"), "shirt": Color("3a8a5a"), "pants": Color("5a4a3a"), "hat": Color("8a5a2a")}
const RUIN_STONE := Color("a8a098")


# --- Rustic village style: logs, thatch, leaves and stones ---------------------------------
# Textures painted pixel by pixel with a little noise, then the dark outline of the Painter.

const LOG := [Color("5a3818"), Color("8a5a30"), Color("b07840"), Color("d8a868")]  # dark, base, light, cut end
const THATCH := [Color("6a4a1a"), Color("a07428"), Color("d8a840"), Color("f0cc68")]
const LEAVES := [Color("1e4a1a"), Color("2e6a24"), Color("4a8a30"), Color("7ab848")]
const STONES := [Color("3a3a38"), Color("6a6a66"), Color("8e8c86"), Color("b4b0a8")]  # mortar, dark, base, light


static func _in(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()


static func _put(img: Image, x: int, y: int, color: Color) -> void:
	if _in(img, x, y):
		img.set_pixel(x, y, color)


# Horizontal logs, 4 pixels high, with knots and their cut ends sticking out on both sides.
static func _logs(img: Image, rect: Rect2i, rng: RandomNumberGenerator) -> void:
	for top in range(rect.position.y, rect.end.y, 4):
		for x in range(rect.position.x, rect.end.x):
			for dy in 4:
				var y := top + dy
				if y >= rect.end.y:
					continue
				var c: Color = [LOG[2], LOG[1], LOG[1], LOG[0]][dy]
				if dy == 1 and rng.randf() < 0.08:
					c = LOG[0]
				_put(img, x, y, c)
		for end in [rect.position.x - 2, rect.end.x - 1]:
			for dy in range(0, 3):
				for dx in 3:
					_put(img, end + dx, top + dy, LOG[3] if dy == 1 and dx == 1 else LOG[2])
			_put(img, end + 1, top + 1, LOG[1])


# Upright planks, 3 pixels wide.
static func _planks(img: Image, rect: Rect2i, rng: RandomNumberGenerator) -> void:
	for x in range(rect.position.x, rect.end.x):
		var plank := (x - rect.position.x) % 3
		for y in range(rect.position.y, rect.end.y):
			var c: Color = [LOG[0], LOG[1], LOG[2]][plank]
			if plank == 1 and rng.randf() < 0.06:
				c = LOG[0]
			_put(img, x, y, c)


# A stone base: mortar, then rows of stones of different sizes, lit on top.
static func _stones(img: Image, rect: Rect2i, rng: RandomNumberGenerator) -> void:
	img.fill_rect(rect, STONES[0])
	var y := rect.position.y
	while y < rect.end.y:
		var h := rng.randi_range(3, 4)
		var x := rect.position.x - rng.randi_range(0, 3)
		while x < rect.end.x:
			var w := rng.randi_range(4, 7)
			for sy in range(y, mini(y + h - 1, rect.end.y)):
				for sx in range(maxi(x, rect.position.x), mini(x + w - 1, rect.end.x)):
					var c: Color = STONES[2]
					if sy == y:
						c = STONES[3]
					elif sy == y + h - 2 or sx == x + w - 2:
						c = STONES[1]
					_put(img, sx, sy, c)
			x += w
		y += h


# Fills a polygon with straw: streaks running down, a ragged dark fringe at the bottom.
static func _thatch(img: Image, points: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	var streak := {}
	for x in range(int(box.position.x), int(box.end.x) + 1):
		streak[x] = rng.randi_range(0, 3)
	for y in range(int(box.position.y), int(box.end.y) + 1):
		for x in range(int(box.position.x), int(box.end.x) + 1):
			if not Geometry2D.is_point_in_polygon(Vector2(x, y) + Vector2(0.5, 0.5), points):
				continue
			var n: int = (streak[x] + (y / 3 + x * 7) % 5) % 4
			var c: Color = THATCH[1] if n == 0 else (THATCH[3] if n == 3 and (x + y) % 3 == 0 else THATCH[2])
			# Layers of straw, one under the other.
			if (y - int(box.position.y)) % 9 == 8 and (x + streak[x]) % 4 != 0:
				c = THATCH[0]
			# Darker at the bottom edge, where the straw is cut.
			if not Geometry2D.is_point_in_polygon(Vector2(x, y + 2) + Vector2(0.5, 0.5), points):
				c = THATCH[0] if (x + rng.randi_range(0, 1)) % 2 == 0 else THATCH[1]
			_put(img, x, y, c)


# Fills a polygon with leaves: overlapping round clumps in three greens.
static func _leaf_roof(img: Image, points: PackedVector2Array, rng: RandomNumberGenerator) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	for y in range(int(box.position.y), int(box.end.y) + 1):
		for x in range(int(box.position.x), int(box.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y) + Vector2(0.5, 0.5), points):
				_put(img, x, y, LEAVES[1])
	for i in int(box.size.x * box.size.y / 9.0):
		var at := Vector2(rng.randf_range(box.position.x, box.end.x), rng.randf_range(box.position.y, box.end.y))
		if not Geometry2D.is_point_in_polygon(at, points):
			continue
		var r := rng.randf_range(1.5, 2.8)
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var d := Vector2(dx, dy).length()
				if d <= r:
					_put(img, int(at.x) + dx, int(at.y) + dy, LEAVES[3] if dy < -r * 0.4 and dx < 0 else (LEAVES[2] if d < r - 0.8 else LEAVES[0]))


# Little clumps of moss or ivy here and there.
static func _moss(img: Image, area: Rect2i, count: int, rng: RandomNumberGenerator) -> void:
	for i in count:
		var x := rng.randi_range(area.position.x, area.end.x - 1)
		var y := rng.randi_range(area.position.y, area.end.y - 1)
		if img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1)).a == 0.0:
			continue
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(1, 1)]:
			_put(img, x + d.x, y + d.y, LEAVES[2] if d.y == 0 else LEAVES[1])


# A window: dark wooden frame, dark glass with a reflection, a cross, and a sill.
static func _window(img: Image, rect: Rect2i, flowers := false) -> void:
	img.fill_rect(rect.grow(1), LOG[0])
	img.fill_rect(rect, Color("1e2a38"))
	img.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x / 2, rect.size.y / 2)), Color("2e4258"))
	_put(img, rect.position.x + 1, rect.position.y + 1, Color("8ab0c8"))
	img.fill_rect(Rect2i(rect.position.x + rect.size.x / 2, rect.position.y, 1, rect.size.y), LOG[1])
	img.fill_rect(Rect2i(rect.position.x, rect.position.y + rect.size.y / 2, rect.size.x, 1), LOG[1])
	img.fill_rect(Rect2i(rect.position.x - 2, rect.end.y + 1, rect.size.x + 4, 2), LOG[2])
	if flowers:
		for x in range(rect.position.x - 1, rect.end.x + 1):
			_put(img, x, rect.end.y, LEAVES[2] if x % 2 == 0 else LEAVES[1])
			if x % 3 == 0:
				_put(img, x, rect.end.y - 1, [Color("e53950"), Color("f0c830"), Color("e080f0")][x % 9 / 3])


# A plank door with its frame and a handle.
static func _door(img: Image, rect: Rect2i) -> void:
	img.fill_rect(rect.grow(1), LOG[0])
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_put(img, x, y, [Color("6a4020"), Color("7a4c26"), Color("5a3418")][(x - rect.position.x) % 3])
	img.fill_rect(Rect2i(rect.position.x, rect.position.y + 3, rect.size.x, 1), LOG[0])
	img.fill_rect(Rect2i(rect.position.x, rect.end.y - 5, rect.size.x, 1), LOG[0])
	_put(img, rect.end.x - 2, rect.position.y + rect.size.y / 2, Color("f0c830"))


# A stone chimney.
static func _chimney(img: Image, rect: Rect2i, rng: RandomNumberGenerator) -> void:
	_stones(img, rect, rng)
	img.fill_rect(Rect2i(rect.position.x - 1, rect.position.y, rect.size.x + 2, 2), STONES[1])


# A house of the village, 4 x 3 cells, door in the middle of the bottom: 64 x 84 pixels.
# 0: a small thatched hut of planks, 1: a thatched log cottage with a dormer and flowers,
# 2: a big log house under a roof of leaves.
static func village_house(variant: int) -> Texture2D:
	return cached("village_house:%d" % variant, func() -> Texture2D:
		var p := _painter(Vector2i(64, 84))
		var img := p.image
		var rng := RandomNumberGenerator.new()
		rng.seed = 400 + variant
		match variant % 3:
			0:
				_chimney(img, Rect2i(12, 8, 8, 26), rng)
				_planks(img, Rect2i(8, 48, 48, 30), rng)
				img.fill_rect(Rect2i(8, 54, 48, 3), LOG[0])
				_stones(img, Rect2i(7, 76, 50, 7), rng)
				_thatch(img, PackedVector2Array([Vector2(1, 52), Vector2(24, 18), Vector2(40, 18), Vector2(63, 52), Vector2(56, 54), Vector2(8, 54)]), rng)
				_moss(img, Rect2i(6, 22, 52, 28), 14, rng)
				# Crossed poles at the top of the roof.
				p.line(Vector2(26, 13), Vector2(34, 21), LOG[1])
				p.line(Vector2(38, 13), Vector2(30, 21), LOG[1])
				_window(img, Rect2i(13, 59, 7, 6))
				_door(img, Rect2i(26, 60, 12, 18))
				_window(img, Rect2i(45, 59, 7, 6))
			1:
				_logs(img, Rect2i(8, 46, 48, 32), rng)
				img.fill_rect(Rect2i(8, 52, 48, 3), LOG[0])
				_stones(img, Rect2i(6, 74, 52, 9), rng)
				_thatch(img, PackedVector2Array([Vector2(0, 50), Vector2(6, 28), Vector2(16, 14), Vector2(32, 9), Vector2(48, 14), Vector2(58, 28), Vector2(64, 50), Vector2(56, 52), Vector2(8, 52)]), rng)
				_moss(img, Rect2i(6, 14, 52, 34), 12, rng)
				# The round dormer window in the straw.
				p.ellipse(Vector2(32, 30), Vector2(7, 6), THATCH[1])
				img.fill_rect(Rect2i(28, 27, 8, 8), LOG[0])
				_window(img, Rect2i(29, 28, 6, 6))
				_window(img, Rect2i(12, 57, 8, 7), true)
				_window(img, Rect2i(44, 57, 8, 7), true)
				_door(img, Rect2i(26, 58, 12, 18))
				for spot in [Vector2(7, 79), Vector2(57, 79)]:
					p.ellipse(spot, Vector2(3, 3), Color("b0603a"), true)
					p.ellipse(spot + Vector2(0, -3), Vector2(3, 2), LEAVES[2])
			_:
				_chimney(img, Rect2i(44, 2, 8, 20), rng)
				_logs(img, Rect2i(6, 44, 52, 32), rng)
				img.fill_rect(Rect2i(6, 50, 52, 3), LOG[0])
				_stones(img, Rect2i(4, 72, 56, 11), rng)
				_leaf_roof(img, PackedVector2Array([Vector2(0, 48), Vector2(14, 16), Vector2(50, 14), Vector2(64, 48), Vector2(58, 50), Vector2(6, 50)]), rng)
				# The ridge log on top of the leaves.
				p.limb(Vector2(13, 15), Vector2(51, 13), 1.8, 1.8, LOG[1], true)
				_window(img, Rect2i(11, 55, 8, 7))
				_window(img, Rect2i(45, 55, 8, 7))
				_door(img, Rect2i(26, 56, 12, 20))
		return p.finish())


# The furniture inside a village house, standing on its cells (bottom center).
static func furniture(kind: String, look: int) -> Texture2D:
	return cached("furniture:%s:%d" % [kind, look], func() -> Texture2D:
		var cloth: Color = VILLAGE_ROOFS[look % VILLAGE_ROOFS.size()]
		match kind:
			"bed":
				var p := _painter(Vector2i(32, 36))
				p.box(Rect2(1, 1, 30, 10), WOOD, true)
				p.box(Rect2(2, 9, 28, 26), Color("f4f0e8"), true)
				p.box(Rect2(6, 11, 20, 6), Color.WHITE, true)
				p.box(Rect2(2, 18, 28, 17), cloth, true)
				p.flat(Rect2(3, 19, 26, 2), cloth.lightened(0.3))
				return p.finish()
			"table":
				var p := _painter(Vector2i(32, 22))
				p.box(Rect2(3, 10, 3, 11), WOOD.darkened(0.2), true)
				p.box(Rect2(26, 10, 3, 11), WOOD.darkened(0.2), true)
				p.box(Rect2(0, 3, 32, 9), WOOD, true)
				p.flat(Rect2(1, 4, 30, 2), WOOD.lightened(0.25))
				p.ellipse(Vector2(10, 4), Vector2(4, 2), Color("f4ecd8"), true)
				p.dot(Vector2(9, 3), Color("d8243e"), 2)
				p.box(Rect2(21, 0, 4, 5), Color("a8d8f0"), true)
				return p.finish()
			"chair":
				var p := _painter(Vector2i(12, 14))
				p.box(Rect2(1, 5, 10, 4), WOOD, true)
				p.box(Rect2(2, 8, 2, 6), WOOD.darkened(0.2), true)
				p.box(Rect2(8, 8, 2, 6), WOOD.darkened(0.2), true)
				return p.finish()
			"cupboard":
				var p := _painter(Vector2i(16, 30))
				p.box(Rect2(0, 0, 16, 30), WOOD, true)
				p.box(Rect2(2, 3, 12, 11), WOOD.darkened(0.25), true)
				p.box(Rect2(2, 16, 12, 12), WOOD.lightened(0.1), true)
				p.flat(Rect2(8, 16, 1, 12), WOOD.darkened(0.3))
				for x in [4, 7, 10]:
					p.box(Rect2(x, 8, 2, 6), [Color("d84a3a"), Color("f0c830"), Color("4a78b8")][x % 3], true)
				return p.finish()
			"stove":
				var p := _painter(Vector2i(16, 28))
				p.box(Rect2(6, 0, 4, 12), Color("5a5a62"), true)
				p.box(Rect2(1, 11, 14, 16), Color("4a4a52"), true)
				p.box(Rect2(4, 16, 8, 8), Color("2a1a10"), true)
				p.ellipse(Vector2(8, 21), Vector2(3, 3), Color("f09818"))
				p.dot(Vector2(8, 22), Color("fff070"), 2)
				return p.finish()
			"plant":
				var p := _painter(Vector2i(14, 20))
				for leaf in [Vector2(4, 6), Vector2(10, 6), Vector2(7, 3), Vector2(7, 9)]:
					p.ellipse(leaf, Vector2(3.5, 2.5), Color("4aa84c"), true)
				p.box(Rect2(3, 11, 8, 8), Color("c06a3a"), true)
				return p.finish()
			"window":
				var p := _painter(Vector2i(24, 14))
				p.box(Rect2(0, 0, 24, 14), Color("a8d8f0"), true)
				p.flat(Rect2(12, 1, 1, 12), Color.WHITE)
				p.flat(Rect2(1, 7, 22, 1), Color.WHITE)
				p.box(Rect2(-1, 0, 4, 14), cloth, false)
				p.box(Rect2(21, 0, 4, 14), cloth, false)
				return p.finish()
		return null)


# The market stall of the village with the merchant behind the counter: 4 x 2 cells, 64 x 56 pixels.
static func market_stall() -> Texture2D:
	return cached("market_stall", func() -> Texture2D:
		var p := _painter(Vector2i(64, 56))
		p.box(Rect2(3, 10, 3, 30), WOOD, true)
		p.box(Rect2(58, 10, 3, 30), WOOD, true)
		p.image.blend_rect(person("down", 0, MERCHANT).get_image(), Rect2i(0, 0, 12, 16), Vector2i(26, 22))
		p.box(Rect2(2, 35, 60, 20), WOOD, true)
		p.flat(Rect2(2, 35, 60, 2), WOOD.lightened(0.3))
		for x in range(6, 60, 12):
			p.flat(Rect2(x, 40, 1, 14), WOOD.darkened(0.25))
		p.ellipse(Vector2(10, 33), Vector2(3, 2.5), Color("d8243e"), true)
		p.ellipse(Vector2(16, 33), Vector2(3, 2.5), Color("e86a2a"), true)
		p.ellipse(Vector2(47, 32.5), Vector2(3, 3), Color("f4ecd8"), true)
		p.dot(Vector2(47, 31), ORE_COLORS.gold[0], 2)
		p.polygon(PackedVector2Array([Vector2(53, 35), Vector2(55, 29), Vector2(57, 35)]), ORE_COLORS.crystal[0], true)
		p.box(Rect2(0, 4, 64, 10), Color.WHITE, true)
		for x in range(0, 64, 8):
			p.flat(Rect2(x, 4, 4, 10), Color("d84a3a"))
		for x in range(4, 64, 8):
			p.ellipse(Vector2(x, 14), Vector2(4, 2.5), Color("d84a3a") if (x / 8) % 2 == 0 else Color.WHITE)
		return p.finish())


# A wall of an abandoned house, standing on its cell: 16 x 28 pixels, broken at different heights.
static func ruin_wall(variant: int) -> Texture2D:
	return cached("ruin_wall:%d" % variant, func() -> Texture2D:
		var p := _painter(Vector2i(16, 28))
		var height: int = [20, 15, 24, 12][variant % 4]
		p.box(Rect2(0, 27 - height, 16, height), RUIN_STONE, true)
		for y in range(27 - height + 4, 27, 5):
			p.flat(Rect2(1, y, 14, 1), RUIN_STONE.darkened(0.25))
			p.flat(Rect2(4 + (y % 2) * 6, y - 4, 1, 4), RUIN_STONE.darkened(0.25))
		p.dot(Vector2(3, 27 - height + 2), Color("6a9a40"), 2)
		p.dot(Vector2(12, 24), Color("6a9a40"), 2)
		return p.finish())


# The broken plank floor inside an abandoned house.
static func paint_planks(image: Image, at: Vector2i, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var base := Color("a07a4a")
	image.fill_rect(Rect2i(at, Vector2i(T, T)), base)
	for y in range(3, T, 4):
		image.fill_rect(Rect2i(at + Vector2i(0, y), Vector2i(T, 1)), base.darkened(0.3))
	if rng.randf() < 0.35:
		image.fill_rect(Rect2i(at + Vector2i(rng.randi_range(1, 9), rng.randi_range(0, 2) * 4), Vector2i(5, 3)), Color("3a2a1a"))


# A treasure chest, closed or opened: 16 x 16 pixels.
static func chest(open: bool) -> Texture2D:
	return cached("chest:%s" % open, func() -> Texture2D:
		var p := _painter(Vector2i(16, 16))
		var gold: Color = ORE_COLORS.gold[0]
		if open:
			p.box(Rect2(1, 0, 14, 5), WOOD.darkened(0.15), true)
			p.box(Rect2(1, 6, 14, 9), WOOD, true)
			p.flat(Rect2(2, 6, 12, 3), Color("3a2a1a"))
		else:
			p.box(Rect2(1, 6, 14, 9), WOOD, true)
			p.box(Rect2(1, 3, 14, 5), WOOD.lightened(0.12), true)
			p.dot(Vector2(8, 8), gold, 2)
		for x in [3, 12]:
			p.flat(Rect2(x, 3 if not open else 6, 1, 12 if not open else 9), gold)
		return p.finish())


# The well in the middle of the village square: 2 x 2 cells, 32 x 40 pixels.
static func well() -> Texture2D:
	return cached("well", func() -> Texture2D:
		var p := _painter(Vector2i(32, 40))
		p.box(Rect2(5, 9, 3, 20), WOOD, true)
		p.box(Rect2(24, 9, 3, 20), WOOD, true)
		p.polygon(PackedVector2Array([Vector2(1, 12), Vector2(16, 1), Vector2(31, 12)]), Color("c0503a"), true)
		p.box(Rect2(3, 24, 26, 15), RUIN_STONE, true)
		p.flat(Rect2(6, 24, 20, 3), Color("2a4a70"))
		for x in range(5, 28, 6):
			p.flat(Rect2(x, 30, 1, 9), RUIN_STONE.darkened(0.25))
		p.box(Rect2(14, 15, 4, 5), Color("8a6a4a"), true)
		return p.finish())


# A wooden sign by the road: 16 x 22 pixels.
static func signpost() -> Texture2D:
	return cached("signpost", func() -> Texture2D:
		var p := _painter(Vector2i(16, 22))
		p.box(Rect2(7, 8, 2, 13), WOOD, true)
		p.polygon(PackedVector2Array([Vector2(1, 3), Vector2(12, 3), Vector2(15, 6.5), Vector2(12, 10), Vector2(1, 10)]), WOOD.lightened(0.25), true)
		p.flat(Rect2(3, 6, 8, 1), WOOD.darkened(0.3))
		return p.finish())


# --- What the character drives in the adventure ------------------------------------------
# Side views facing right, anchored at their bottom center; frames turn the wheels.
# direction "down" draws it coming towards us, "up" going away (seen from the back).

static func vehicle(id: String, frame: int, direction := "side") -> Texture2D:
	if direction != "side":
		return _vehicle_end(id, frame, direction == "down")
	match id:
		"bike":
			return _bike(frame % 4)
		"moto":
			return _moto(frame % 4)
		"car":
			return _car(frame % 4)
	return helicopter(frame % 2)


# A vehicle seen from the front (coming towards us) or from the back.
static func _vehicle_end(id: String, frame: int, front: bool) -> Texture2D:
	return cached("vehicle_end:%s:%d:%s" % [id, frame % 4, front], func() -> Texture2D:
		var light := Color("fff176") if front else Color("e53935")
		match id:
			"bike", "moto":
				var moto := id == "moto"
				var color := Color("1e88e5") if moto else Color("e53935")
				var p := _painter(Vector2i(16, 18))
				var width := 3.0 if moto else 2.0
				# The wheel, seen edge-on: its tread runs down as it turns.
				p.box(Rect2(8 - width / 2.0, 9, width, 8), Color("303034"), true)
				p.flat(Rect2(8 - width / 2.0 + 0.5, 10 + (frame % 4) * 2, width - 1.0, 1), Color("70707a"))
				if moto:
					p.box(Rect2(5, 6, 6, 5), color, true)
					p.dot(Vector2(8, 8), light, 2)
				else:
					p.limb(Vector2(8, 5), Vector2(8, 10), 0.8, 0.8, color)
				p.limb(Vector2(1, 5), Vector2(15, 5), 0.7, 0.7, Color("303034"))
				return p.finish(false)
			"car":
				var p := _painter(Vector2i(28, 20))
				var orange := Color("fb8c00")
				for x in [2, 21]:
					p.box(Rect2(x, 13, 5, 6), Color("303034"), true)
				p.box(Rect2(1, 8, 26, 9), orange, true)
				p.box(Rect2(5, 3, 18, 6), orange, true)
				p.box(Rect2(7, 4, 14, 4), Color("a8e0f8"), true)
				p.flat(Rect2(2, 12, 24, 1), Color.WHITE)
				for x in [3, 22]:
					p.box(Rect2(x, 9, 3, 2), light)
				p.box(Rect2(10, 14, 8, 2), Color("d0d0d8") if front else Color("303034"))
				return p.finish()
		# The helicopter: its round cabin, the skids and the rotor spinning above.
		var p := _painter(Vector2i(36, 24))
		var red := Color("e53935")
		p.box(Rect2(9, 21, 18, 1), Color("404040"))
		for x in [12, 23]:
			p.box(Rect2(x, 18, 1, 3), Color("404040"))
		if not front:
			p.limb(Vector2(18, 12), Vector2(18, 22), 2.0, 1.4, red)
		p.ellipse(Vector2(18, 13), Vector2(8, 6.5), red, true)
		if front:
			p.ellipse(Vector2(18, 12.5), Vector2(5.5, 4), Color("a8e0f8"))
			p.dot(Vector2(16, 11), Color.WHITE, 2)
		else:
			p.polygon(PackedVector2Array([Vector2(15, 19), Vector2(21, 19), Vector2(18, 23)]), red.darkened(0.2), true)
		p.box(Rect2(17, 4, 2, 3), Color("404040"))
		if frame % 2 == 0:
			p.flat(Rect2(1, 3, 34, 1), Color("303030"))
		else:
			p.flat(Rect2(11, 3, 14, 1), Color("303030"))
			p.flat(Rect2(3, 3, 7, 1), Color(0.2, 0.2, 0.2, 0.35))
			p.flat(Rect2(26, 3, 7, 1), Color(0.2, 0.2, 0.2, 0.35))
		return p.finish())


static func _wheel(p: Painter, center: Vector2, radius: float, frame: int, filled: bool) -> void:
	if filled:
		p.ellipse(center, Vector2(radius, radius), Color("303034"), true)
		p.dot(center, Color("b0b0b8"), 2)
	else:
		for i in 28:
			var a := TAU * i / 28.0
			p.dot(center + Vector2(cos(a), sin(a)) * radius, Color("303034"))
	var a := frame * PI / 2.0
	p.line(center, center + Vector2(cos(a), sin(a)) * (radius - 1.0), Color("b0b0b8"))


static func _bike(frame: int) -> Texture2D:
	return cached("bike:%d" % frame, func() -> Texture2D:
		var p := _painter(Vector2i(24, 16))
		var red := Color("e53935")
		_wheel(p, Vector2(5, 11), 4.5, frame, false)
		_wheel(p, Vector2(19, 11), 4.5, frame, false)
		for bar in [[Vector2(5, 11), Vector2(11, 11)], [Vector2(11, 11), Vector2(9, 4)], [Vector2(9, 5), Vector2(17, 5)],
				[Vector2(17, 5), Vector2(11, 11)], [Vector2(9, 5), Vector2(5, 11)], [Vector2(17, 4), Vector2(19, 11)]]:
			p.limb(bar[0], bar[1], 0.7, 0.7, red)
		p.box(Rect2(7, 2.5, 5, 1.5), Color("303034"))
		p.limb(Vector2(16, 2), Vector2(18, 3), 0.6, 0.6, Color("303034"))
		return p.finish(false))


static func _moto(frame: int) -> Texture2D:
	return cached("moto:%d" % frame, func() -> Texture2D:
		var p := _painter(Vector2i(28, 18))
		var blue := Color("1e88e5")
		p.limb(Vector2(3, 12), Vector2(12, 12), 1.0, 1.0, Color("9a9aa2"))
		p.limb(Vector2(20, 5), Vector2(22, 14), 1.0, 1.0, Color("9a9aa2"))
		_wheel(p, Vector2(6, 14), 3.5, frame, true)
		_wheel(p, Vector2(22, 14), 3.5, frame, true)
		p.box(Rect2(9, 9, 9, 4), Color("70707a"), true)
		p.polygon(PackedVector2Array([Vector2(9, 6), Vector2(18, 5), Vector2(21, 9), Vector2(10, 10)]), blue, true)
		p.box(Rect2(4, 6, 8, 2), Color("303034"), true)
		p.limb(Vector2(19, 3), Vector2(22, 4), 0.7, 0.7, Color("303034"))
		p.dot(Vector2(23, 7), Color("fff176"), 2)
		return p.finish())


static func _car(frame: int) -> Texture2D:
	return cached("car:%d" % frame, func() -> Texture2D:
		var p := _painter(Vector2i(32, 18))
		var red := Color("fb8c00")
		p.box(Rect2(2, 7, 28, 7), red, true)
		p.box(Rect2(21, 5, 9, 3), red, true)
		p.limb(Vector2(20, 7), Vector2(18, 1), 0.8, 0.8, Color("a8e0f8"))
		p.flat(Rect2(2, 10, 28, 1), Color.WHITE)
		p.flat(Rect2(13, 8, 1, 5), red.darkened(0.3))
		p.dot(Vector2(29, 8), Color("fff176"), 2)
		_wheel(p, Vector2(8, 14), 3.5, frame, true)
		_wheel(p, Vector2(24, 14), 3.5, frame, true)
		return p.finish())

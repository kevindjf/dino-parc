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


# A soft shadow on the ground under a standing sprite (anchored at its feet), drawn under
# everything that stands. The light comes from the top left, so it slips a little to the right.
static func ground_shadow(node: Sprite2D, width: int) -> Sprite2D:
	var shadow := Sprite2D.new()
	shadow.texture = shadow(width)
	shadow.position = Vector2(width * 0.12, -1)
	shadow.z_index = -1
	node.add_child(shadow)
	return shadow


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
	"prairie": {"base": Color("78b85a"), "dark": Color("5a9a44"), "light": Color("a2d47a")},
	"jungle": {"base": Color("4a8a44"), "dark": Color("2e6a30"), "light": Color("74b45a")},
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
			# Grass of two greens, a few tufts, sometimes a pebble.
			for i in 10:
				image.set_pixelv(at + Vector2i(rng.randi_range(0, 15), rng.randi_range(0, 15)), colors.base.darkened(0.08))
			for i in rng.randi_range(1, 3):
				_stamp(image, at + Vector2i(rng.randi_range(0, 11), rng.randi_range(1, 13)), TUFT, palette)
			if rng.randf() < 0.04:
				_stamp(image, at + Vector2i(rng.randi_range(1, 12), rng.randi_range(1, 13)), ["ll.", "ddd"], {"l": STONES[3], "d": STONES[1]})
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
	var base := Color("d4b47a") if connected else Color("b8aa90")
	image.fill_rect(Rect2i(at, Vector2i(T, T)), base)
	for i in 8:
		image.set_pixelv(at + Vector2i(rng.randi_range(1, 14), rng.randi_range(1, 14)), base.darkened(0.12))
	for i in 3:
		image.set_pixelv(at + Vector2i(rng.randi_range(1, 14), rng.randi_range(1, 14)), base.lightened(0.2))
	# Pebbles in the dirt.
	for i in (1 if rng.randf() < 0.3 else 0):
		var pebble := at + Vector2i(rng.randi_range(2, 12), rng.randi_range(2, 12))
		image.set_pixelv(pebble, STONES[3])
		image.set_pixelv(pebble + Vector2i(1, 0), STONES[2])
		image.set_pixelv(pebble + Vector2i(0, 1), STONES[1])
		image.set_pixelv(pebble + Vector2i(1, 1), STONES[1])
	_edges(image, at, edges, Color("5a7a34"), base.darkened(0.22))


# A road of cobblestones (the jeeps drive on it).
static func paint_road(image: Image, at: Vector2i, links: Array, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var mortar := Color("5a5852")
	image.fill_rect(Rect2i(at, Vector2i(T, T)), mortar)
	for row in 4:
		var x := -((row * 3 + seed) % 4)
		while x < T:
			var w := rng.randi_range(3, 5)
			var c: Color = [Color("8e8a80"), Color("9a958a"), Color("837f76")][rng.randi() % 3]
			for y in range(row * 4, row * 4 + 3):
				for xx in range(maxi(x, 0), mini(x + w - 1, T)):
					var shade := c.lightened(0.18) if y == row * 4 else (c.darkened(0.15) if y == row * 4 + 2 else c)
					image.set_pixel(at.x + xx, at.y + y, shade)
			x += w
	var edges := []
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not dir in links:
			edges.append(dir)
	_edges(image, at, edges, Color("5a7a34"), Color("6a6860"))


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
	var base := Color("2f6fb8")
	for y in T:
		for x in T:
			var color := base
			var wave := (at.y + y + int(round(1.5 * sin((at.x + x) * TAU / 16.0)))) % 8
			if wave == 0:
				color = Color("6aaee8")
			elif wave == 1:
				color = Color("4a8ed0")
			image.set_pixel(at.x + x, at.y + y, color)
	var sand := Color("e2cc94")
	var deep := Color("d8f0ff")  # foam where the waves meet the sand
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


const ROCK_LEVELS := [Color("9a8c7a"), Color("8e8070"), Color("827466"), Color("e8eef6"), Color("f2f6fb"), Color("ffffff")]


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
		_stamp(image, p, ["dd.", "ddd"], {"d": Color("7a6e62")})
	elif not snowy and rng.randf() < 0.6:
		# A crack in the rock.
		var p := at + Vector2i(rng.randi_range(2, 10), rng.randi_range(2, 8))
		_stamp(image, p, ["d...", ".dd.", "...d"], {"d": top.darkened(0.3)})
	if Vector2i.UP in lower:
		image.fill_rect(Rect2i(at, Vector2i(T, 1)), top.lightened(0.3))
	if Vector2i.LEFT in lower:
		image.fill_rect(Rect2i(at, Vector2i(1, T)), top.darkened(0.25))
	if Vector2i.RIGHT in lower:
		image.fill_rect(Rect2i(at + Vector2i(15, 0), Vector2i(1, T)), top.darkened(0.3))
	if Vector2i.DOWN in lower:
		var face := Color("6e6258") if not snowy else Color("a8b8cc")
		image.fill_rect(Rect2i(at + Vector2i(0, 9), Vector2i(T, 7)), face)
		image.fill_rect(Rect2i(at + Vector2i(0, 9), Vector2i(T, 1)), top.lightened(0.25))
		# Layers of rock and cracks running down the cliff.
		image.fill_rect(Rect2i(at + Vector2i(0, 12), Vector2i(T, 1)), face.darkened(0.18))
		for x in range(rng.randi_range(0, 2), T, 3):
			var length := rng.randi_range(2, 5)
			image.fill_rect(Rect2i(at + Vector2i(x, 10), Vector2i(1, length)), face.darkened(0.3))
			if rng.randf() < 0.3 and x + 1 < T:
				image.set_pixelv(at + Vector2i(x + 1, 10), face.lightened(0.2))
		image.fill_rect(Rect2i(at + Vector2i(0, 15), Vector2i(T, 1)), face.darkened(0.45))


# --- Nature ------------------------------------------------------------------

static func decor(style: String) -> Texture2D:
	return cached("decor:" + style, func() -> Texture2D:
		match style:
			"tree":
				return _round_tree(Color("4e9a34"))
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
		return _round_tree(Color("4e9a34")))


static func border_tree(variant: int) -> Texture2D:
	return cached("border:%d" % variant, func() -> Texture2D:
		return _round_tree([Color("4a8a30"), Color("3e7e2c"), Color("5a9a38")][variant % 3], variant))


# A blob of leaves: a dark mass, then round clumps lighter towards the top left.
static func _clumps(img: Image, center: Vector2, radius: Vector2, rng: RandomNumberGenerator, leaf: Color) -> void:
	var dark := leaf.darkened(0.4)
	for y in range(int(center.y - radius.y) - 1, int(center.y + radius.y) + 2):
		for x in range(int(center.x - radius.x) - 1, int(center.x + radius.x) + 2):
			if ((Vector2(x, y) + Vector2(0.5, 0.5) - center) / radius).length_squared() <= 1.0:
				_put(img, x, y, dark)
	for i in int(radius.x * radius.y * 0.5):
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.85
		var at := center + Vector2(cos(a), sin(a)) * radius * r
		var size := rng.randf_range(1.6, 2.8)
		# Clumps high on the left catch the sun, low ones stay in the shade.
		var lit := ((at - center) / radius).dot(Vector2(-0.6, -0.8))
		var color := leaf.lightened(0.25) if lit > 0.35 else (leaf if lit > -0.35 else leaf.darkened(0.2))
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var d := Vector2(dx, dy).length()
				if d <= size:
					_put(img, int(at.x) + dx, int(at.y) + dy, color if d < size - 0.9 or dy > 0 else color.darkened(0.25))


# A leafy tree: a trunk with bark and roots under a big round crown of clumps.
static func _round_tree(leaf: Color, seed := 0) -> Texture2D:
	var p := _painter(Vector2i(28, 34))
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + seed
	p.polygon(PackedVector2Array([Vector2(10, 33), Vector2(12, 20), Vector2(16, 20), Vector2(18, 33)]), LOG[1], true)
	p.image.fill_rect(Rect2i(13, 22, 1, 10), LOG[0])
	p.image.fill_rect(Rect2i(15, 24, 1, 6), LOG[2])
	_clumps(p.image, Vector2(14, 13), Vector2(12, 10), rng, leaf)
	return p.finish()


static func _pine() -> Texture2D:
	var p := _painter(Vector2i(22, 34))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	p.box(Rect2(9, 27, 4, 6), LOG[1], true)
	var green := Color("2e6a40")
	for i in 4:
		var y := 29.0 - i * 6.5
		var w := 10.0 - i * 2.2
		p.polygon(PackedVector2Array([Vector2(11 - w, y), Vector2(11, y - 11), Vector2(11 + w, y)]), green.lightened(i * 0.06), true)
		# Needles: little lighter strokes on the left of each layer.
		for k in 4:
			var x := rng.randi_range(int(11 - w * 0.7), 11)
			p.image.set_pixel(x, int(y) - rng.randi_range(2, 4), green.lightened(0.3 + i * 0.05))
	return p.finish()


static func _palm() -> Texture2D:
	var p := _painter(Vector2i(28, 32))
	var trunk := Color("b08850")
	for i in 5:
		p.limb(Vector2(12 + i * 0.6, 30 - i * 4.5), Vector2(12.6 + i * 0.6, 26 - i * 4.5), 2.2, 2.0, trunk if i % 2 == 0 else trunk.darkened(0.12), true)
	var top := Vector2(15, 8)
	for leaf in [Vector2(-12, 4), Vector2(-9, -5), Vector2(0, -7), Vector2(9, -5), Vector2(12, 5), Vector2(-4, 6), Vector2(5, 7)]:
		p.limb(top, top + leaf, 2.4, 0.6, Color("4a8a30"), true)
	p.ellipse(top + Vector2(-1, 2), Vector2(2, 2), Color("7a5030"))
	p.ellipse(top + Vector2(2, 2), Vector2(2, 2), Color("8a6038"))
	return p.finish()


static func _fern() -> Texture2D:
	var p := _painter(Vector2i(20, 16))
	var base := Vector2(10, 15)
	for leaf in [Vector2(-9, -5), Vector2(-5, -10), Vector2(0, -12), Vector2(5, -10), Vector2(9, -5)]:
		p.limb(base, base + leaf, 2.0, 0.6, Color("3a7e34"), true)
	return p.finish()


static func _bush(berries: bool) -> Texture2D:
	var p := _painter(Vector2i(20, 16))
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	_clumps(p.image, Vector2(10, 9), Vector2(8.5, 6), rng, Color("3e8a3a"))
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
	p.ellipse(Vector2(9, 8), Vector2(8, 5.5), STONES[2])
	p.polygon(PackedVector2Array([Vector2(3, 6), Vector2(8, 3), Vector2(12, 5), Vector2(7, 8)]), STONES[3])
	p.line(Vector2(8, 8), Vector2(12, 11), STONES[1])
	p.line(Vector2(12, 5), Vector2(15, 8), STONES[1])
	for spot in [Vector2(4, 10), Vector2(5, 11), Vector2(14, 11)]:
		p.dot(spot, LEAVES[2])
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


# The entrance of a mine, dug into a cliff: a dark hole held by a wooden frame, and rails coming
# out of it. 20 x 22 pixels, anchored at its bottom center.
static func mine_entrance() -> Texture2D:
	return cached("mine_entrance", func() -> Texture2D:
		var p := _painter(Vector2i(20, 22))
		p.ellipse(Vector2(10, 14), Vector2(8, 8), STONES[1])
		p.box(Rect2(2, 7, 16, 15), STONES[1])
		p.flat(Rect2(4, 8, 12, 14), Color("120c08"))
		# The rails and their wooden ties.
		for y in [14, 17, 20]:
			p.flat(Rect2(6, y, 8, 1), LOG[0])
		p.line(Vector2(7, 12), Vector2(6, 21), Color("9a9aa2"))
		p.line(Vector2(12, 12), Vector2(13, 21), Color("9a9aa2"))
		# The frame: two posts, a lintel and a brace.
		p.box(Rect2(2, 6, 3, 16), LOG[1], true)
		p.box(Rect2(15, 6, 3, 16), LOG[1], true)
		p.box(Rect2(0, 3, 20, 4), LOG[2], true)
		p.flat(Rect2(1, 5, 18, 1), LOG[0])
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
			post = LOG[1]
			rail = LOG[2]
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
	var wood := LOG[2]
	var post := LOG[1]
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
	var face := STONES[2] if style == "stone" else Color("c4ccd0")
	var top := STONES[3] if style == "stone" else Color("eef2f4")
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
			# Stones of different sizes, lit on top.
			for y in range(int(rect.position.y) + 3, int(rect.end.y), 4):
				p.flat(Rect2(rect.position.x, y, rect.size.x, 1), STONES[0])
				var offset := 2 if (y / 4) % 2 == 0 else 5
				for x in range(int(rect.position.x) + offset, int(rect.end.x), 6):
					p.flat(Rect2(x, y - 3, 1, 3), STONES[0])
					p.flat(Rect2(x + 1, y - 3, 3, 1), STONES[3])
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


# A small building in three quarters: the front rectangle, the side wall going back (darker) on
# the right, and the floor of its roof. wall(x, y) colours the walls.
static func _block3q(img: Image, front: Rect2i, depth: Vector2i, wall: Callable) -> void:
	var right := front.end.x
	_fill_poly(img, PackedVector2Array([Vector2(right, front.position.y), Vector2(right + depth.x, front.position.y + depth.y),
		Vector2(right + depth.x, front.end.y + depth.y), Vector2(right, front.end.y)]), func(x: int, y: int) -> Color:
			return wall.call(x, y).darkened(0.3))
	for y in range(front.position.y, front.end.y):
		for x in range(front.position.x, right):
			_put(img, x, y, wall.call(x, y))


static func _plank_wall(x: int, y: int) -> Color:
	return [LOG[0], LOG[1], LOG[2]][x % 3]


static func _log_wall(x: int, y: int) -> Color:
	return [LOG[2], LOG[1], LOG[1], LOG[0]][y % 4]


static func _stone_wall(x: int, y: int) -> Color:
	var row := y / 4
	var brick := (x + row * 3) / 5
	if y % 4 == 3 or (x + row * 3) % 5 == 0:
		return STONES[0]
	return STONES[3] if y % 4 == 0 else (STONES[2] if (brick + row) % 3 != 0 else STONES[1])


# A stand of the park in three quarters: a wooden kiosk with a striped awning of its colour,
# and what it sells on top. 1 cell, 22 x 32 pixels.
static func shop(data: Dictionary) -> Texture2D:
	return cached("shop:" + data.style, func() -> Texture2D:
		var p := _painter(Vector2i(22, 32))
		var img := p.image
		var color: Color = data.color
		_block3q(img, Rect2i(2, 14, 14, 17), Vector2i(4, -3), _plank_wall)
		img.fill_rect(Rect2i(3, 15, 12, 5), Color("2a1a10"))
		img.fill_rect(Rect2i(2, 20, 14, 2), LOG[2])
		p.box(Rect2(2, 9, 18, 6), Color.WHITE, true)
		for x in range(2, 20, 4):
			p.flat(Rect2(x, 9, 2, 6), color)
		p.flat(Rect2(2, 14, 18, 1), color.darkened(0.3))
		match data.style:
			"icecream":
				p.polygon(PackedVector2Array([Vector2(7, 4), Vector2(13, 4), Vector2(10, 9)]), Color("d7a35c"), true)
				p.ellipse(Vector2(10, 3.5), Vector2(3.5, 3), Color("f48fb1"), true)
			"burger":
				p.ellipse(Vector2(10, 4), Vector2(5, 2.5), Color("e0a040"), true)
				p.box(Rect2(5, 5, 10, 1), Color("5a8a2a"))
				p.box(Rect2(5, 6, 10, 2), Color("7a3a20"), true)
			"souvenir":
				p.box(Rect2(6, 2, 8, 7), Color("7e57c2"), true)
				p.flat(Rect2(9, 2, 2, 7), Color("fdd835"))
				p.flat(Rect2(6, 5, 8, 1), Color("fdd835"))
		return p.finish())


# A feeder: a wooden trough full of hay for the herbivores, a rack with meat for the carnivores.
static func feeder(diet: String) -> Texture2D:
	return cached("feeder:" + diet, func() -> Texture2D:
		var p := _painter(Vector2i(18, 22))
		var img := p.image
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		if diet == "herb":
			_block3q(img, Rect2i(1, 14, 13, 7), Vector2i(3, -3), _plank_wall)
			_thatch(img, PackedVector2Array([Vector2(1, 14), Vector2(4, 8), Vector2(10, 7), Vector2(16, 10), Vector2(14, 14)]), rng)
			p.dot(Vector2(6, 10), Color("c0d040"), 2)
		else:
			p.box(Rect2(2, 4, 3, 17), LOG[1], true)
			p.box(Rect2(13, 4, 3, 17), LOG[1], true)
			p.box(Rect2(1, 3, 16, 3), LOG[2], true)
			for x in [6, 11]:
				p.line(Vector2(x, 6), Vector2(x, 8), Color("c8b080"))
				p.ellipse(Vector2(x, 11), Vector2(2.5, 3), Color("c0443a"), true)
				p.dot(Vector2(x, 14.5), Color("f4ecd8"), 2)
			p.box(Rect2(1, 17, 16, 4), STONES[2], true)
		return p.finish())


# The station of the gyrospheres: a stone and wood building with a glass ball on its roof.
# 2 x 2 cells, 36 x 42 pixels.
static func gyro_station() -> Texture2D:
	return cached("gyro_station", func() -> Texture2D:
		var p := _painter(Vector2i(36, 42))
		var img := p.image
		_block3q(img, Rect2i(2, 20, 28, 21), Vector2i(5, -4), _stone_wall)
		img.fill_rect(Rect2i(2, 20, 28, 3), LOG[2])
		p.box(Rect2(12, 28, 8, 13), Color("2a3a4a"), true)
		_window(img, Rect2i(5, 27, 5, 5))
		_window(img, Rect2i(22, 27, 5, 5))
		_fill_poly(img, PackedVector2Array([Vector2(0, 21), Vector2(5, 15), Vector2(34, 15), Vector2(35, 17), Vector2(31, 21)]), func(x: int, y: int) -> Color:
			return Color("2f8fc8") if (x / 3) % 2 == 0 else Color("3aa0d8"))
		p.ellipse(Vector2(17, 9), Vector2(7, 7), Color(0.7, 0.9, 1.0, 0.85), true)
		p.box(Rect2(10, 8, 14, 2), Color("ff9800"))
		p.dot(Vector2(14, 5), Color.WHITE, 2)
		return p.finish())


# The jeep garage: a wooden barn with a big plank door under a straw roof. 2 x 2 cells, 36 x 40.
static func garage() -> Texture2D:
	return cached("garage", func() -> Texture2D:
		var p := _painter(Vector2i(36, 40))
		var img := p.image
		var rng := RandomNumberGenerator.new()
		rng.seed = 8
		_block3q(img, Rect2i(2, 18, 28, 21), Vector2i(5, -4), _log_wall)
		_door(img, Rect2i(7, 24, 18, 15))
		img.fill_rect(Rect2i(7, 31, 18, 1), LOG[0])
		_thatch(img, PackedVector2Array([Vector2(0, 20), Vector2(6, 6), Vector2(36, 2), Vector2(36, 14), Vector2(32, 20)]), rng)
		p.box(Rect2(10, 12, 12, 5), LOG[2], true)
		p.flat(Rect2(12, 14, 8, 1), Color("6d8f3a"))
		return p.finish())


# The heliport, flat on the ground: a round pad of stones in a wooden ring, a big H and lights.
static func heliport() -> Texture2D:
	return cached("heliport", func() -> Texture2D:
		var image := Image.create(48, 48, false, Image.FORMAT_RGBA8)
		for y in 48:
			for x in 48:
				var d := _rounded_distance(x, y, 48, 48, 5)
				if d < 0.0:
					continue
				var color := _stone_wall(x, y)
				if d < 3.0:
					color = LOG[1] if d >= 1.0 else LOG[0]
				var r := Vector2(x - 23.5, y - 23.5).length()
				if r > 15.0 and r < 18.0:
					color = Color("e8c040") if r < 17.0 else Color("b08a20")
				image.set_pixel(x, y, color)
		_stamp(image, Vector2i(17, 16), [
			"ww.....ww", "ww.....ww", "ww.....ww", "ww.....ww", "wwwwwwwww", "wwwwwwwww",
			"ww.....ww", "ww.....ww", "ww.....ww", "ww.....ww"], {"w": Color("f4f0e4")})
		for corner in [Vector2i(4, 4), Vector2i(42, 4), Vector2i(4, 42), Vector2i(42, 42)]:
			image.fill_rect(Rect2i(corner, Vector2i(2, 2)), Color("ff5252") if corner.y < 20 else Color("69f0ae"))
		return ImageTexture.create_from_image(image))


# The lagoon: a pool with a rim of stones, deep water in the middle, animated waves.
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
					color = STONES[0]
				elif d < 5.0:
					color = _stone_wall(x, y)
				elif d < 6.0:
					color = Color("d8f0ff")
				elif d < 9.0:
					color = Color("3a8ac8")
				else:
					color = Color("2f6fb8")
					var wave := (y + int(round(2.0 * sin((x + frame * 4) * TAU / 24.0)))) % 10
					if wave == 0:
						color = Color("6aaee8")
					elif wave == 1:
						color = Color("4a8ed0")
				image.set_pixel(x, y, color)
		return ImageTexture.create_from_image(image))


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
		var frame: Color = LOG[1]
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


# The park gate, standing outside the left edge of the map: two big log posts on stone bases
# and a wooden sign with a green dinosaur head. 20 x 72 pixels.
static func gate() -> Texture2D:
	return cached("gate", func() -> Texture2D:
		var p := _painter(Vector2i(20, 72))
		var rng := RandomNumberGenerator.new()
		rng.seed = 3
		p.box(Rect2(4, 24, 12, 4), Color("d4b47a"))
		_stones(p.image, Rect2i(4, 12, 12, 10), rng)
		_stones(p.image, Rect2i(4, 58, 12, 11), rng)
		p.box(Rect2(7, 8, 6, 52), LOG[1], true)
		p.flat(Rect2(8, 9, 1, 50), LOG[2])
		p.box(Rect2(1, 1, 18, 9), LOG[2], true)
		p.flat(Rect2(2, 4, 16, 1), LOG[1])
		p.flat(Rect2(2, 7, 16, 1), LOG[1])
		p.ellipse(Vector2(10, 32), Vector2(5, 5), Color("5a9a38"), true)
		p.dot(Vector2(11, 31), EYE_DARK)
		_moss(p.image, Rect2i(4, 58, 12, 4), 2, rng)
		return p.finish())


const EYE_DARK := Color("181818")


# --- People and vehicles --------------------------------------------------------

# People of the park (visitors, the ranger): drawn like the hero, with a bush hat only when
# `colors` has a "hat". colors: hair, skin, shirt, pants, optionally hat and style ("long").
static func person(direction: String, frame: int, colors: Dictionary) -> Texture2D:
	return hero(direction, frame, colors)


# --- The dinosaurs of the village ----------------------------------------------------------
# Villagers are dinosaurs in clothes, 12 x 18 pixels, feet at the bottom center: a head of
# their kind ("trike", "raptor", "ptero" or "rex"), a tunic, scaly legs and a tail.
# colors: skin, shirt, optionally crest; apron: true for craftsmen (seen from the front).
# Letters: o outline, s/S skin, R crest or frill, L horns and beak, e eye, w white or teeth,
# c/C tunic, a apron.
const FOLK_KINDS := ["trike", "raptor", "ptero", "rex"]
const FOLK_HEADS := {
	"trike": {
		"side": ["..o....o....", ".oRo..oLo...", "oRRRo.oLo.o.", "oRSssssssoLo", "oRSsssweesso", "oRSsssssssLo", ".oSssssssLo.", "..oossssoo..", "....oooo...."],
		"down": [".ooooo", "oRRRRR", "oRoLRR", "oRsLss", "oRswes", "oRssss", ".oSsss", "..ossL", "...ooo"],
		"up": [".ooooo", "oRRRRR", "oRRRRR", "oRRRRR", "oRSSSS", "oRSSSS", ".oSSSS", "..oSSS", "...ooo"],
	},
	"raptor": {
		"side": ["............", "...oooo.....", "..oRRsso....", ".oRssssooo..", ".oRsswesssoo", ".oSsssssssso", "..oSsLLLLLo.", "...oossoooo.", "....oo......"],
		"down": ["......", "...ooo", "..oRRs", ".oRsss", ".oswes", ".ossss", "..osss", "...osL", "....oo"],
		"up": ["......", "...ooo", "..oRRS", ".oRSSS", ".oSSSS", ".oSSSS", "..oSSS", "...oSS", "....oo"],
	},
	"ptero": {
		"side": ["oooo........", "oRRRoo......", ".ooRRso.....", "...oswesoo..", "...osssLLLoo", "...osssoLLLo", "....ossoooo.", ".....oo.....", "............"],
		"down": ["....oo", "...oRR", "...oRR", "..osss", ".oswes", ".ossss", "..ossL", "...oLL", "....oo"],
		"up": ["....oo", "...oRR", "...oRR", "..oSSS", ".oSSSS", ".oSSSS", "..oSSS", "...oSS", "....oo"],
	},
	"rex": {
		"side": ["...ooooo....", "..oSssssoo..", ".oSsssweesoo", ".oSsssssssso", ".oSsssswwwwo", ".oSssssooooo", "..oSssLLLLo.", "...ooossooo.", "....ooo....."],
		"down": ["..oooo", ".oSsss", "oSswes", "oSssss", "oSssss", "oSwwww", ".oSLLL", "..osss", "...ooo"],
		"up": ["..oooo", ".oSSSS", "oSSSSS", "oSSSSS", "oSSSSS", "oSSSSS", ".oSSSS", "..oSSS", "...ooo"],
	},
}
const FOLK_SIDE_BODY := {
	"hang": ["...occcco...", "..occcccco..", "..occCcCco..", "..occcssco..", "..oCCCCCCo.."],
	"front": ["...occcco...", "..occccccoo.", "..occccoCsso", "..occcco.oo.", "..oCCCCCo..."],
	"back": ["...occcco...", ".oocccccco..", "osCoccccco..", ".oo.occcco..", "..oCCCCCCo.."],
}
const FOLK_SIDE_LEGS := {
	"together": ["...oSo.oSo..", "...oSo.oSo..", "..oSSSoSSSSo", "..oooooooooo"],
	"apart": ["..oSo..oSo..", ".oSo....oSo.", "oSSSo...oSSo", "ooooo...oooo"],
}
const FOLK_SIDE_TAIL := ["............", "............", "oo..........", "oSo.........", ".oSo........"]
const FOLK_BODY := ["...occ", "..occc", ".oCccc", ".osccc", "..oCCC"]
const FOLK_LEGS := ["...oSo", "...oSo", "..oSSS", "..oooo"]
const FOLK_BACK_TAIL := ["....oSSo....", "....oSSo....", ".....oo....."]
const FOLK_APRON := ["............", "....oaao....", "....oaao....", "....oaao....", "....oaao...."]


static func dino_folk(kind: String, direction: String, frame: int, colors: Dictionary) -> Texture2D:
	frame = frame % 4
	var key := "folk:%s:%s:%d:%s" % [kind, direction, frame, colors.values()]
	return cached(key, func() -> Texture2D:
		var head: Dictionary = FOLK_HEADS[kind]
		var rows: Array
		if direction == "side":
			rows = head.side + FOLK_SIDE_BODY[["hang", "front", "hang", "back"][frame]] \
				+ FOLK_SIDE_LEGS["together" if frame % 2 == 0 else "apart"]
			rows = _over(rows, 9, FOLK_SIDE_TAIL)
		else:
			var legs := _mirror(FOLK_LEGS)
			if frame == 1:
				legs = _lift(legs, 0)
			elif frame == 3:
				legs = _lift(legs, 6)
			rows = _mirror(head[direction]) + _mirror(FOLK_BODY) + legs
			if direction == "up":
				rows = _over(rows, 13, FOLK_BACK_TAIL)
			elif colors.get("apron", false):
				rows = _over(rows, 9, FOLK_APRON)
		var skin: Color = colors.skin
		var palette := {
			"o": OUTLINE, "s": skin, "S": skin.darkened(0.22), "R": colors.get("crest", skin.darkened(0.35)),
			"L": Color("f0e4c8"), "e": EYE_DARK, "w": Color.WHITE, "c": colors.shirt, "C": colors.shirt.darkened(0.22),
			"a": Color("e6dcc8"),
		}
		var image := Image.create(12, 18, false, Image.FORMAT_RGBA8)
		_stamp(image, Vector2i.ZERO, rows, palette)
		_volume(image)
		return ImageTexture.create_from_image(image))


# --- The hero: a little explorer with a bush hat ------------------------------------------
# Drawn like the characters of Stardew Valley: 16 x 28 pixels (almost two cells high), feet at the
# bottom center, a round head under a bush hat, a shirt with lit shoulders, a backpack, shorts,
# white socks and red sneakers, 4 walking frames, shaded by hand.
# colors: skin, hair, shirt, pants, optionally hat, and style: "short" hair, or "long" (a ponytail).
# Letters: o outline, H/h/k/K hat light/base/shade/band, R/r hair, s/S skin, e eye, w white,
# m mouth, b blush, B hair tie, L/c/C shirt light/base/shade, p/P shorts, W socks, n sneakers,
# G/g backpack.

const KHAKI := Color("b09a78")

const HERO_SIDE_HEAD := [
	"................",
	"....oooooo......",
	"...oHHHHHHo.....",
	"..ohhhhhhhhko...",
	"..oKKKKKKKKKo...",
	".ohhhhhhhhhhhoo.",
	"ohhhhhhhhhhhhhko",
	".oookkkkkkkkkoo.",
	"..oRRRRRSSSSSo..",
	"..oRrRRSssrrso..",
	"..oRRrSSssweso..",
	"..oRrRSSssseso..",
	"..oRRRSsbsssso..",
	"...oRRsssssmo...",
	"....ooossso.....",
]

const HERO_SIDE_ARMS := {
	"hang": [".oGGoLcccco.....", ".oGGoLccCcco....", ".oGgocccCCco....", ".oGgocccCCco....", ".oggocccssco....", "..ooocccssco...."],
	"front": [".oGGoLcccco.....", ".oGGoLcccccoo...", ".oGgoccccco.Cso.", ".oGgoccccco..so.", ".oggoccccco..oo.", "..ooocccccco...."],
	"back": [".oGGoLcccco.....", ".oGGoLcccco.....", ".oGgocccccCo....", ".oGgocccccCo....", ".oggocccccCo....", "..ooocccccCo...."],
}

const HERO_SIDE_HIPS := [
	"....oppppppo....",
	".....opppPpo....",
	".....oppppo.....",
]

const HERO_SIDE_LEGS := {
	"together": [".....osooso.....", ".....oWooWo.....", ".....onnonnno...", ".....oooooooo..."],
	"apart": ["....oso..oso....", "...oWo....oWo...", "..onnno...onnno.", "..ooooo...ooooo."],
}

# The top of the head without a hat (people of the park), replacing rows 0 to 7.

const HERO_SIDE_HAIR := ["................", "................", "................", "....oRRRRRo.....", "...oRRRRRRRo....", "...oRRRRRRRRo...", "...oRRRRRRRRo...", "...oRRRRRRRRo..."]

const HERO_HAIR := ["........", "........", "........", "....oRRR", "...oRRRR", "..oRRRRR", "..oRRRRR", "..oRRRRR"]

# Seen from the front and the back: the left half, mirrored.

const HERO_FRONT_HEAD := [
	"........",
	".....ooo",
	"....oHHH",
	"...ohhhh",
	"...oKKKK",
	".oohhhhh",
	"ohhhhhhh",
	".ookkkkk",
	"..oRRSSS",
	"..oRssss",
	"..oRsess",
	"..oRsess",
	"..oRbsss",
	"...oossm",
	"....ooss",
]

const HERO_BACK_HEAD := [
	"........",
	".....ooo",
	"....oHHH",
	"...ohhhh",
	"...oKKKK",
	".oohhhhh",
	"ohhhhhhh",
	".ookkkkk",
	"..oRRRRR",
	"..oRRRRR",
	"..oRRRRR",
	"..oRRRRR",
	"..orRRRR",
	"...oorrr",
	"....ooss",
]

const HERO_BODY := [
	"...ooccc",
	"..ocLccc",
	".ocCcccc",
	".ocCcccc",
	".ocCcccc",
	".osCcccc",
	".ossoppp",
	"...opppp",
	"...opppp",
]

const HERO_LEGS := [
	"...ossso",
	"...oWWWo",
	"..onnnno",
	"..oooooo",
]

# The backpack: seen from the back (rows 16 to 20), its straps from the front (rows 15 to 17).

const HERO_BACKPACK := [
	"....oGGGGGGo....",
	"....oGggggGo....",
	"....oGGGGGGo....",
	"....oGGGGGGo....",
	"....oggggggo....",
]

const HERO_STRAPS := [
	".....g....g.....",
	".....g....g.....",
	".....g....g.....",
]

# The ponytail ("long" style), drawn over the rest from a row ("." keeps what is there).

const HERO_SIDE_TAIL := [
	"..B.",
	"oRRo",
	"oRRo",
	"oRRo",
	"oRo.",
	".o..",
]

const HERO_FRONT_TAIL := [
	".oR..........Ro.",
	".oR..........Ro.",
	".oR..........Ro.",
	".oR..........Ro.",
	"..o..........o..",
]

const HERO_BACK_TAIL := [
	".......BB.......",
	"......oRRo......",
	"......oRRo......",
	"......oRRo......",
]


static func hero(direction: String, frame: int, colors: Dictionary) -> Texture2D:
	frame = frame % 4
	var key := "hero:%s:%d:%s" % [direction, frame, colors.values()]
	return cached(key, func() -> Texture2D:
		var long: bool = colors.get("style", "") == "long"
		var rows: Array = []
		if direction == "side":
			rows = HERO_SIDE_HEAD + HERO_SIDE_ARMS[["hang", "front", "hang", "back"][frame]] + HERO_SIDE_HIPS \
				+ HERO_SIDE_LEGS["together" if frame % 2 == 0 else "apart"]
			if not colors.has("hat"):
				rows = HERO_SIDE_HAIR + rows.slice(8)
			if long:
				rows = _over(rows, 8, HERO_SIDE_TAIL)
		else:
			var front := direction == "down"
			var legs := _mirror(HERO_LEGS)
			# Walking towards us or away: one foot up, then the other.
			if frame == 1:
				legs = _lift(legs, 0)
			elif frame == 3:
				legs = _lift(legs, 8)
			rows = _mirror(HERO_FRONT_HEAD if front else HERO_BACK_HEAD) + _mirror(HERO_BODY) + legs
			if not colors.has("hat"):
				rows = _mirror(HERO_HAIR) + rows.slice(8)
			rows = _over(rows, 15, HERO_STRAPS) if front else _over(rows, 16, HERO_BACKPACK)
			if long:
				rows = _over(rows, 9, HERO_FRONT_TAIL) if front else _over(rows, 12, HERO_BACK_TAIL)
		var hat: Color = colors.get("hat", KHAKI)
		var shirt: Color = colors.shirt
		var palette := {
			"o": Color("281e1e"), "H": hat.lightened(0.18), "h": hat, "k": hat.darkened(0.25), "K": hat.darkened(0.55),
			"R": colors.hair, "r": colors.hair.darkened(0.25), "s": colors.skin, "S": colors.skin.darkened(0.18),
			"e": Color("281a14"), "w": Color.WHITE, "m": Color("b44646"), "b": Color("f4968c"), "B": Color("2a8adf"),
			"L": shirt.lightened(0.15), "c": shirt, "C": shirt.darkened(0.22), "p": colors.pants, "P": colors.pants.darkened(0.25),
			"W": Color("f0f0f0"), "n": Color("d2322d"), "G": Color("966437"), "g": Color("694426"),
		}
		var image := Image.create(16, 28, false, Image.FORMAT_RGBA8)
		_stamp(image, Vector2i.ZERO, rows, palette)
		return ImageTexture.create_from_image(image))


# Gives volume to a flat pixel sprite, lit from the top left: every part (an arm, the body, the
# head) becomes a little cylinder, light on its left, dark on its right, lit on top and darker at
# the bottom. The outline, eyes, whites and tiny details are kept.
static func _volume(image: Image) -> void:
	var source: Image = image.duplicate()
	var w := image.get_width()
	var h := image.get_height()
	var at := func(x: int, y: int) -> Color:
		return source.get_pixel(x, y) if x >= 0 and y >= 0 and x < w and y < h else Color(0, 0, 0, 0)
	var edge := func(c: Color) -> bool:
		return c.a < 0.5 or c.is_equal_approx(OUTLINE)
	for y in h:
		var x := 0
		while x < w:
			var c: Color = at.call(x, y)
			var length := 1
			while x + length < w and at.call(x + length, y).is_equal_approx(c):
				length += 1
			if not edge.call(c) and c.get_luminance() > 0.12 and c.get_luminance() < 0.95 and length >= 3:
				for i in length:
					var shaded := c
					if i == 0:
						shaded = c.lightened(0.16)
					elif i == length - 1:
						shaded = c.darkened(0.24)
					elif length >= 6 and i == length - 2:
						shaded = c.darkened(0.1)
					if edge.call(at.call(x + i, y - 1)):
						shaded = shaded.lightened(0.1)
					elif edge.call(at.call(x + i, y + 1)):
						shaded = shaded.darkened(0.12)
					image.set_pixel(x + i, y, shaded)
			x += length


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


# The leg in the half starting at column `left`, one pixel higher.
static func _lift(legs: Array, left: int) -> Array:
	var out := []
	for y in legs.size():
		var row: String = legs[y]
		var half := row.length() / 2
		var below: String = legs[y + 1] if y + 1 < legs.size() else ".".repeat(row.length())
		out.append(row.substr(0, left) + below.substr(left, half) + row.substr(left + half))
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
const MERCHANT := {"skin": Color("c8a050"), "shirt": Color("3a8a5a"), "crest": Color("8a6a30"), "apron": true}
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


# Fills a polygon pixel by pixel: color(x, y) gives each pixel.
static func _fill_poly(img: Image, points: PackedVector2Array, color: Callable) -> void:
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	for y in range(int(box.position.y), int(ceil(box.end.y)) + 1):
		for x in range(int(box.position.x), int(ceil(box.end.x)) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x, y) + Vector2(0.5, 0.5), points):
				_put(img, x, y, color.call(x, y))


# A house of the village seen from three quarters, 4 x 3 cells: 80 x 72 pixels. The front wall
# with the door (in the middle, where the player walks in), the right wall going back in the
# shade, and the right slope of the roof.
# 0: a small hut of planks under straw, 1: a log cottage under straw with flowers,
# 2: a big log house under a roof of leaves.
const HOUSE_DEPTH := Vector2(16, -12)


static func village_house(variant: int) -> Texture2D:
	return cached("village_house:%d" % variant, func() -> Texture2D:
		var p := _painter(Vector2i(80, 72))
		var img := p.image
		var rng := RandomNumberGenerator.new()
		rng.seed = 400 + variant
		var logs := variant % 3 != 0
		var leaves := variant % 3 == 2
		var d := HOUSE_DEPTH
		# The right wall, in the shade: logs or planks following the slope.
		var side := PackedVector2Array([Vector2(60, 45), Vector2(60, 45) + d, Vector2(60, 71) + d, Vector2(60, 71)])
		_fill_poly(img, side, func(x: int, y: int) -> Color:
			var v := float(y) + (x - 60) * 0.75
			var c: Color = [LOG[1], LOG[1], LOG[0], LOG[2]][int(v) % 4] if logs else [LOG[0], LOG[1], LOG[1]][x % 3]
			if v > 64.0:
				c = STONES[1] if (int(v) + x / 3) % 4 != 0 else STONES[0]
			return c.darkened(0.3))
		# The front wall and its stone base.
		if logs:
			_logs(img, Rect2i(20, 44, 40, 22), rng)
		else:
			_planks(img, Rect2i(20, 44, 40, 22), rng)
		_stones(img, Rect2i(19, 64, 42, 8), rng)
		# The gable above the front wall.
		_fill_poly(img, PackedVector2Array([Vector2(20, 45), Vector2(40, 30), Vector2(60, 45)]), func(x: int, y: int) -> Color:
			return [LOG[0], LOG[1], LOG[2]][x % 3] if not logs else [LOG[2], LOG[1], LOG[1], LOG[0]][y % 4])
		# Shadow of the roof on the wall.
		img.fill_rect(Rect2i(20, 44, 40, 2), LOG[0])
		# The roof: its right slope going back, and the rim over the gable.
		var apex := Vector2(40, 27)
		var eave := Vector2(65, 48)
		var slope := PackedVector2Array([apex, eave, eave + d, apex + d])
		var rim := PackedVector2Array([apex + Vector2(0, -2), Vector2(15, 48), Vector2(21, 50), apex + Vector2(0, 5)])
		if leaves:
			_leaf_roof(img, slope, rng)
			_leaf_roof(img, rim, rng)
		else:
			_thatch(img, slope, rng)
			_thatch(img, rim, rng)
			_moss(img, Rect2i(18, 18, 60, 30), 10, rng)
		if variant % 3 != 1:
			_chimney(img, Rect2i(62, 14, 6, 14), rng)
		p.limb(apex + Vector2(0, -1), apex + d + Vector2(0, -1), 1.6, 1.6, LOG[1], true)
		if variant % 3 == 0:
			# Crossed poles at the front of the ridge.
			p.line(apex + Vector2(-4, -5), apex + Vector2(2, 1), LOG[1])
			p.line(apex + Vector2(4, -5), apex + Vector2(-2, 1), LOG[1])
		# Door, windows, flowers.
		_door(img, Rect2i(34, 52, 12, 20))
		_window(img, Rect2i(24, 52, 6, 6), variant % 3 == 1)
		_window(img, Rect2i(50, 52, 6, 6), variant % 3 == 1)
		if variant % 3 == 1:
			for spot in [Vector2(17, 69), Vector2(63, 69)]:
				p.ellipse(spot, Vector2(3, 3), Color("b0603a"), true)
				p.ellipse(spot + Vector2(0, -3), Vector2(3, 2), LEAVES[2])
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
				# A stone fireplace with a fire.
				var p := _painter(Vector2i(16, 28))
				for y in 27:
					for x in range(1 if y > 8 else 4, 15 if y > 8 else 12):
						_put(p.image, x, y, _stone_wall(x, y))
				p.box(Rect2(0, 8, 16, 2), LOG[2], true)
				p.box(Rect2(4, 16, 8, 10), Color("1a1008"), true)
				p.ellipse(Vector2(8, 22), Vector2(3, 3.5), Color("f09818"))
				p.ellipse(Vector2(8, 23), Vector2(1.5, 2), Color("fff070"))
				p.flat(Rect2(4, 25, 8, 1), LOG[1])
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


# The market stall of the village in three quarters: posts, a patchwork awning, shelves of pots
# and bottles at the back, the merchant behind a counter of goods, and a sign with a paw print.
# 4 x 2 cells, 64 x 60 pixels.
static func market_stall() -> Texture2D:
	return cached("market_stall", func() -> Texture2D:
		var p := _painter(Vector2i(64, 60))
		var img := p.image
		var rng := RandomNumberGenerator.new()
		rng.seed = 31
		# Back wall of planks with two shelves of pots and bottles.
		_planks(img, Rect2i(8, 16, 48, 28), rng)
		for shelf in [26, 36]:
			img.fill_rect(Rect2i(8, shelf, 48, 2), LOG[2])
			img.fill_rect(Rect2i(8, shelf + 2, 48, 1), LOG[0])
			for x in range(10, 54, 5):
				var kind := rng.randi() % 3
				if kind == 0:
					p.ellipse(Vector2(x + 1.5, shelf - 2.5), Vector2(2, 2.5), Color("b0603a"), true)
				elif kind == 1:
					p.box(Rect2(x + 0.5, shelf - 5, 2, 5), [Color("8a50c0"), Color("40a060"), Color("d04050")][rng.randi() % 3], true)
					p.dot(Vector2(x + 1, shelf - 4), Color.WHITE)
				else:
					p.ellipse(Vector2(x + 1.5, shelf - 2), Vector2(2.5, 2), Color("e0c090"), true)
		img.blend_rect(dino_folk("trike", "down", 0, MERCHANT).get_image(), Rect2i(0, 0, 12, 18), Vector2i(26, 28))
		# Posts.
		for x in [3, 58]:
			p.box(Rect2(x, 10, 4, 48), LOG[1], true)
		# The counter with its goods: pumpkins, cloth, a basket.
		p.box(Rect2(4, 42, 56, 16), LOG[1], true)
		_planks(img, Rect2i(5, 46, 54, 11), rng)
		img.fill_rect(Rect2i(4, 42, 56, 4), LOG[2])
		p.ellipse(Vector2(12, 40), Vector2(3.5, 3), Color("e8902a"), true)
		p.ellipse(Vector2(17, 40.5), Vector2(3, 2.5), Color("f0a838"), true)
		p.box(Rect2(38, 38, 8, 4), Color("3a7ab8"), true)
		p.box(Rect2(39, 35, 7, 3), Color("c04040"), true)
		p.ellipse(Vector2(52, 39.5), Vector2(4, 2.5), Color("c8a060"), true)
		p.dot(Vector2(51, 37.5), Color("d8243e"), 2)
		# The patchwork awning with its scalloped edge.
		var patches := [Color("d84a6a"), Color("f0a020"), Color("3a9ad0"), Color("6ab040"), Color("8a50c0")]
		for y in range(2, 16):
			for x in range(0, 64):
				var c: Color = patches[(x / 11 + (y / 7) * 2) % patches.size()]
				_put(img, x, y, c.darkened(0.15) if y > 12 else (c.lightened(0.15) if y < 4 else c))
		for x in range(0, 64, 8):
			p.ellipse(Vector2(x + 4, 16), Vector2(4, 2.5), patches[(x / 8) % patches.size()].darkened(0.15))
		# The sign with a paw print.
		p.box(Rect2(22, 0, 20, 8), LOG[2], true)
		for spot in [Vector2(30, 5), Vector2(28, 2.5), Vector2(31, 1.5), Vector2(34, 2.5)]:
			p.dot(spot, LOG[0], 2 if spot.y > 4 else 1)
		p.ellipse(Vector2(37, 4), Vector2(2.5, 1.5), LOG[0])
		return p.finish())


# A wall of an abandoned house, standing on its cell: 16 x 28 pixels of stones, broken at different
# heights, with moss.
static func ruin_wall(variant: int) -> Texture2D:
	return cached("ruin_wall:%d" % variant, func() -> Texture2D:
		var p := _painter(Vector2i(16, 28))
		var rng := RandomNumberGenerator.new()
		rng.seed = 60 + variant
		var height: int = [20, 15, 24, 12][variant % 4]
		_stones(p.image, Rect2i(0, 27 - height, 16, height + 1), rng)
		# A broken top: a few stones missing.
		for x in rng.randi_range(2, 5):
			p.image.fill_rect(Rect2i(rng.randi_range(0, 13), 27 - height, 3, 2), Color(0, 0, 0, 0))
		_moss(p.image, Rect2i(0, 27 - height, 16, 6), 3, rng)
		_moss(p.image, Rect2i(0, 22, 16, 5), 2, rng)
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


# The well in the middle of the village square: a round wall of stones with dark water, two posts,
# a little straw roof and a bucket. 2 x 2 cells, 32 x 44 pixels.
static func well() -> Texture2D:
	return cached("well", func() -> Texture2D:
		var p := _painter(Vector2i(32, 44))
		var img := p.image
		var rng := RandomNumberGenerator.new()
		rng.seed = 12
		p.box(Rect2(5, 12, 3, 20), LOG[1], true)
		p.box(Rect2(24, 12, 3, 20), LOG[1], true)
		p.limb(Vector2(6, 16), Vector2(26, 16), 1, 1, LOG[2], true)
		p.line(Vector2(16, 17), Vector2(16, 22), Color("c8b080"))
		p.box(Rect2(13.5, 22, 5, 5), LOG[2], true)
		# The round wall: its top seen from above, its front face of stones.
		_stones(img, Rect2i(2, 30, 28, 13), rng)
		p.ellipse(Vector2(16, 30), Vector2(14, 5), STONES[2], true)
		p.ellipse(Vector2(16, 30), Vector2(10.5, 3), Color("1a2a3a"))
		p.ellipse(Vector2(14, 29.5), Vector2(3, 1), Color("3a5a7a"))
		_moss(img, Rect2i(2, 36, 28, 6), 3, rng)
		# The straw roof.
		_thatch(img, PackedVector2Array([Vector2(0, 14), Vector2(16, 2), Vector2(32, 14), Vector2(28, 16), Vector2(4, 16)]), rng)
		p.limb(Vector2(4, 13), Vector2(16, 3), 0.8, 0.8, LOG[0])
		return p.finish())


# A wooden sign by the road: a rough post and a plank arrow, 16 x 24 pixels.
static func signpost() -> Texture2D:
	return cached("signpost", func() -> Texture2D:
		var p := _painter(Vector2i(16, 24))
		p.box(Rect2(6.5, 8, 3, 15), LOG[1], true)
		p.flat(Rect2(7, 9, 1, 13), LOG[0])
		p.polygon(PackedVector2Array([Vector2(1, 3), Vector2(12, 3), Vector2(15, 6.5), Vector2(12, 10), Vector2(1, 10)]), LOG[2], true)
		p.flat(Rect2(2, 5, 10, 1), LOG[1])
		p.flat(Rect2(2, 8, 10, 1), LOG[1])
		p.dot(Vector2(3, 6.5), LOG[0])
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

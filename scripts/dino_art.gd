extends RefCounted

# The sprites of every species, drawn by hand in dino_hand.gd, turned into textures once.
# Land dinosaurs are seen from the side (facing right), from the front and from the back;
# flyers are seen from below with their wings spread, swimmers from the side.

const Catalog := preload("res://scripts/catalog.gd")
const Hand := preload("res://scripts/dino_hand.gd")

static var _cache := {}


# Returns {walk: [4 Texture2D], roar, sleep, origin: where the dinosaur stands (or the middle of
# its body for flyers and swimmers), size, height}. Land dinosaurs also have "down" and "up"
# (4 frames each, seen from the front and the back) and front_origin.
static func frames(id: String, variant := "") -> Dictionary:
	if variant != "" and Catalog.VARIANTS.has(variant) and Catalog.VARIANTS[variant].has("hue"):
		var key := id + "@" + variant
		if not _cache.has(key):
			_cache[key] = _recolor(frames(id), Catalog.VARIANTS[variant])
		return _cache[key]
	if _cache.has(id):
		return _cache[id]
	var sp: Dictionary = Catalog.DINOS[id]
	var tex := func(direction: String, frame: int, pose := "walk") -> Texture2D:
		return ImageTexture.create_from_image(_scales(Hand.draw(id, sp, direction, frame, pose)))
	var origin := Hand.origin(id, "side")
	var result := {
		"walk": [], "roar": tex.call("side", 0, "roar"), "sleep": tex.call("side", 0, "sleep"),
		"origin": origin, "size": Hand.canvas(id, "side"), "height": origin.y,
	}
	var directions := ["side"]
	if Hand.has_front(id):
		directions = ["side", "down", "up"]
		result.down = []
		result.up = []
		result.front_origin = Hand.origin(id, "down")
	for frame in 4:
		for direction in directions:
			result["walk" if direction == "side" else direction].append(tex.call(direction, frame))
	_cache[id] = result
	return result


# The frames of a rare dinosaur: the same drawing, with its skin painted in the rare colour.
# The outline, the eyes and the teeth are kept.
static func _recolor(base: Dictionary, variant: Dictionary) -> Dictionary:
	var paint := func(texture: Texture2D) -> Texture2D:
		var image := texture.get_image()
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				if c.a < 0.5 or c.get_luminance() < 0.15:
					continue
				var value: float = lerpf(variant.low, variant.high, c.v)
				image.set_pixel(x, y, Color.from_hsv(variant.hue + (c.h - 0.25) * 0.08, variant.sat * (0.6 + 0.4 * c.s), value, c.a))
		return ImageTexture.create_from_image(image)
	var result := base.duplicate()
	for key in ["walk", "down", "up"]:
		if base.has(key):
			result[key] = base[key].map(paint)
	result.roar = paint.call(base.roar)
	result.sleep = paint.call(base.sleep)
	return result


# Little scales all over the skin: a few darker and lighter pixels in a regular pattern, so the
# dinosaurs look hand drawn like the rest of the world. The outline, eyes and teeth are kept.
static func _scales(image: Image) -> Image:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() < 0.15 or c.get_luminance() > 0.9 or c.s < 0.12:
				continue
			if (x * 7 + y * 13) % 19 == 0:
				image.set_pixel(x, y, c.darkened(0.12))
			elif (x * 5 + y * 3) % 29 == 0:
				image.set_pixel(x, y, c.lightened(0.1))
	return image

extends RefCounted

# Hand-drawn looking sprites made of parts, in pixels. Each part is a shape (ellipses, polygons,
# tapered limbs, boxes) filled with one color and shaded like pixel art lit from the top left:
# a light rim on top, a darker band at the bottom and a dark right edge. Then it gets its own
# outline and is laid over the parts drawn before, so a leg or a head keeps its contour over the
# body behind it.
#
#   var layers := Layers.new(Vector2i(52, 34))
#   layers.part([layers.ellipse(23, 17, 14, 9)], Color.GREEN)
#   layers.dot(40, 12, Color.BLACK)
#   var image := layers.image

var image: Image
var size: Vector2i


func _init(canvas: Vector2i) -> void:
	size = canvas
	image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)


# --- Shapes: each returns a mask (a set of pixels), to give to part() ---------------------------

func ellipse(cx: float, cy: float, rx: float, ry: float) -> PackedByteArray:
	return _shape(func(x: float, y: float) -> bool:
		return pow((x - cx) / rx, 2) + pow((y - cy) / ry, 2) <= 1.0)


func poly(points: Array) -> PackedByteArray:
	var polygon := PackedVector2Array(points)
	return _shape(func(x: float, y: float) -> bool:
		return Geometry2D.is_point_in_polygon(Vector2(x, y), polygon))


# A tapered tube from a to b, radius ra at a and rb at b: legs, necks, tails, horns.
func limb(a: Vector2, b: Vector2, ra: float, rb: float) -> PackedByteArray:
	var ab := b - a
	var length_sq := maxf(ab.length_squared(), 0.0001)
	return _shape(func(x: float, y: float) -> bool:
		var p := Vector2(x, y)
		var t := clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
		return p.distance_to(a + ab * t) <= lerpf(ra, rb, t))


func box(x: int, y: int, w: int, h: int) -> PackedByteArray:
	return _shape(func(px: float, py: float) -> bool:
		return px >= x and px < x + w and py >= y and py < y + h)


func _shape(inside: Callable) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			if inside.call(x + 0.5, y + 0.5):
				mask[y * size.x + x] = 1
	return mask


# --- Drawing ----------------------------------------------------------------------------------

# Fills the union of `shapes` with `color`, shaded and outlined. rim: rows of light on top;
# low: rows of shade at the bottom. outline: false for a flat detail without contour.
func part(shapes: Array, color: Color, rim := 1, low := 2, outline := true) -> void:
	var mask := PackedByteArray()
	mask.resize(size.x * size.y)
	for shape in shapes:
		for i in mask.size():
			mask[i] = mask[i] | shape[i]
	var has := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < size.x and y < size.y and mask[y * size.x + x] == 1
	var light := color.lightened(0.22)
	var dark := color.darkened(0.2)
	var deep := color.darkened(0.36)
	for y in size.y:
		for x in size.x:
			if not has.call(x, y):
				if outline and (has.call(x + 1, y) or has.call(x - 1, y) or has.call(x, y + 1) or has.call(x, y - 1)):
					image.set_pixel(x, y, color.darkened(0.72))
				continue
			var c := color
			var up := 0
			while up < rim and has.call(x, y - up - 1):
				up += 1
			var down := 0
			while down < low and has.call(x, y + down + 1):
				down += 1
			if up < rim:
				c = light
			if down < low:
				c = deep if down == 0 and low > 1 else dark
			elif not has.call(x + 1, y):
				c = dark
			image.set_pixel(x, y, c)


func dot(x: float, y: float, color: Color) -> void:
	var at := Vector2i(floori(x), floori(y))
	if Rect2i(Vector2i.ZERO, size).has_point(at):
		image.set_pixel(at.x, at.y, color)


func flipped() -> Image:
	var copy: Image = image.duplicate()
	copy.flip_x()
	return copy

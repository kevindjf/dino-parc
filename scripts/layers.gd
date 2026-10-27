extends RefCounted

# Hand-drawn looking sprites made of parts, in pixels. Each part is a shape (ellipses, polygons,
# tapered limbs, boxes) filled with one color and shaded like pixel art lit from the top left:
# a light rim on top, a darker band at the bottom and a dark right edge. Then it gets its own
# outline and is laid over the parts drawn before, so a leg or a head keeps its contour over the
# body behind it.
#
# Shapes are given in design units: a pixel times `k`, moved by `shift`, so that one drawing
# serves several species of different sizes.
#
#   var layers := Layers.new(Vector2i(52, 34))
#   layers.part([layers.ellipse(23, 17, 14, 9)], Color.GREEN)
#   layers.dot(40, 12, Color.BLACK)
#   var image := layers.image

var image: Image
var size: Vector2i
var k := 1.0
var shift := Vector2.ZERO
var design := Vector2i.ZERO  # the size of the drawing in design units, for the code that draws


func _init(canvas: Vector2i, scale := 1.0, offset := Vector2.ZERO) -> void:
	size = canvas
	k = scale
	shift = offset
	design = Vector2i((Vector2(canvas) / k).round())
	image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)


func _at(x: float, y: float) -> Vector2:
	return Vector2(x, y) * k + shift


func _radius(r: float) -> float:
	return maxf(r * k, 0.55)


# --- Shapes: each returns a mask (a set of pixels), to give to part() ---------------------------

func ellipse(cx: float, cy: float, rx: float, ry: float) -> PackedByteArray:
	var c := _at(cx, cy)
	var r := Vector2(_radius(rx), _radius(ry))
	return _shape(Rect2(c - r, r * 2.0), func(x: float, y: float) -> bool:
		return pow((x - c.x) / r.x, 2) + pow((y - c.y) / r.y, 2) <= 1.0)


func poly(points: Array) -> PackedByteArray:
	var polygon := PackedVector2Array(points.map(func(p: Vector2) -> Vector2: return _at(p.x, p.y)))
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for p in polygon:
		bounds = bounds.expand(p)
	return _shape(bounds, func(x: float, y: float) -> bool:
		return Geometry2D.is_point_in_polygon(Vector2(x, y), polygon))


# A tapered tube from a to b, radius ra at a and rb at b: legs, necks, tails, horns.
func limb(a: Vector2, b: Vector2, ra: float, rb: float) -> PackedByteArray:
	a = _at(a.x, a.y)
	b = _at(b.x, b.y)
	ra = _radius(ra)
	rb = _radius(rb)
	var ab := b - a
	var length_sq := maxf(ab.length_squared(), 0.0001)
	var reach := maxf(ra, rb)
	var bounds := Rect2(a, Vector2.ZERO).expand(b).grow(reach)
	return _shape(bounds, func(x: float, y: float) -> bool:
		var p := Vector2(x, y)
		var t := clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
		return p.distance_to(a + ab * t) <= lerpf(ra, rb, t))


func box(x: float, y: float, w: float, h: float) -> PackedByteArray:
	var from := _at(x, y)
	var to := _at(x + w, y + h)
	return _shape(Rect2(from, to - from), func(px: float, py: float) -> bool:
		return px >= from.x and px < to.x and py >= from.y and py < to.y)


# The pixels inside `bounds` (in pixels) for which `inside` is true.
func _shape(bounds: Rect2, inside: Callable) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(size.x * size.y)
	var area := Rect2i(bounds.position.floor(), bounds.size.ceil() + Vector2.ONE).intersection(Rect2i(Vector2i.ZERO, size))
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if inside.call(x + 0.5, y + 0.5):
				mask[y * size.x + x] = 1
	return mask


# --- Drawing ----------------------------------------------------------------------------------

# Fills the union of `shapes` with `color`, shaded and outlined. rim: rows of light on top;
# low: rows of shade at the bottom. outline: false for a flat detail without contour.
func part(shapes: Array, color: Color, rim := 1, low := 2, outline := true) -> void:
	var mask: PackedByteArray = shapes[0].duplicate()
	for shape in shapes.slice(1):
		for i in range(maxi(shape.find(1), 0), shape.rfind(1) + 1):
			mask[i] = mask[i] | shape[i]
	var first := mask.find(1)
	if first < 0:
		return
	var has := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < size.x and y < size.y and mask[y * size.x + x] == 1
	var light := color.lightened(0.22)
	var dark := color.darkened(0.2)
	var deep := color.darkened(0.36)
	# Only the rows of the part, and the outline just around them.
	for y in range(maxi(first / size.x - 1, 0), mini(mask.rfind(1) / size.x + 2, size.y)):
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
	var at := Vector2i(_at(x, y).floor())
	if Rect2i(Vector2i.ZERO, size).has_point(at):
		image.set_pixel(at.x, at.y, color)


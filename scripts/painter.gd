extends RefCounted

# A tiny pixel-art painter. Shapes are given in "units" and drawn into an Image at `scale` pixels
# per unit (scale 1 and origin 0 means units are pixels). Every shape gets a base colour, a darker
# shade on its lower side and a highlight on top, like hand-shaded sprites; `finish()` then adds a
# dark outline around the whole silhouette. Shapes drawn with `outlined = true` also get their own
# outline, so a near leg stands out from the body behind it.
# After `measure()`, nothing is drawn: `bounds` collects the size of the drawing instead.

const SHADE := 0.24
const LIGHT := 0.22

var image: Image
var scale := 1.0
var origin := Vector2.ZERO
var measuring := false
var bounds := Rect2()
var _measured := false


func start(size: Vector2i, px_per_unit := 1.0, unit_origin := Vector2.ZERO) -> void:
	image = Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	scale = px_per_unit
	origin = unit_origin
	measuring = false


func measure() -> void:
	measuring = true
	_measured = false
	bounds = Rect2()


func ellipse(center: Vector2, radius: Vector2, color: Color, outlined := false, angle := 0.0) -> void:
	radius = radius.max(Vector2.ONE * _min_radius())
	var inside := func(p: Vector2) -> bool:
		return ((p - center).rotated(-angle) / radius).length_squared() <= 1.0
	var side := func(p: Vector2) -> float:
		return (p - center).rotated(-angle).y / radius.y
	var extent := maxf(radius.x, radius.y)
	var rect := Rect2(center - radius, radius * 2.0) if angle == 0.0 else Rect2(center - Vector2.ONE * extent, Vector2.ONE * extent * 2.0)
	_fill(rect, inside, side, color, outlined)


# A tapered tube from a to b: legs, necks, tails.
func limb(a: Vector2, b: Vector2, radius_a: float, radius_b: float, color: Color, outlined := false) -> void:
	radius_a = maxf(radius_a, _min_radius())
	radius_b = maxf(radius_b, _min_radius())
	var ab := b - a
	var length_sq := maxf(ab.length_squared(), 0.000001)
	var normal := Vector2(-ab.y, ab.x).normalized()
	if normal == Vector2.ZERO:
		normal = Vector2.DOWN
	# Shade the underside, or the right side of an upright limb.
	if normal.y < -0.01 or (absf(normal.y) <= 0.01 and normal.x < 0.0):
		normal = -normal
	var closest := func(p: Vector2) -> float:
		return clampf((p - a).dot(ab) / length_sq, 0.0, 1.0)
	var inside := func(p: Vector2) -> bool:
		var t: float = closest.call(p)
		var r := lerpf(radius_a, radius_b, t)
		return p.distance_squared_to(a + ab * t) <= r * r
	var side := func(p: Vector2) -> float:
		var t: float = closest.call(p)
		return (p - a - ab * t).dot(normal) / lerpf(radius_a, radius_b, t)
	_fill(Rect2(a, Vector2.ZERO).expand(b).grow(maxf(radius_a, radius_b)), inside, side, color, outlined)


func polygon(points: PackedVector2Array, color: Color, outlined := false) -> void:
	var rect := Rect2(points[0], Vector2.ZERO)
	for point in points:
		rect = rect.expand(point)
	var center := rect.get_center()
	var half := maxf(rect.size.y / 2.0, 0.0001)
	_fill(rect, func(p: Vector2) -> bool: return Geometry2D.is_point_in_polygon(p, points),
		func(p: Vector2) -> float: return (p.y - center.y) / half, color, outlined)


func box(rect: Rect2, color: Color, outlined := false) -> void:
	var center := rect.get_center()
	var half := maxf(rect.size.y / 2.0, 0.0001)
	_fill(rect, func(p: Vector2) -> bool: return rect.has_point(p),
		func(p: Vector2) -> float: return (p.y - center.y) / half, color, outlined)


# Plain fill without shading, for details.
func flat(rect: Rect2, color: Color) -> void:
	if measuring:
		return
	var from := Vector2i((rect.position * scale + origin).round())
	var to := Vector2i((rect.end * scale + origin).round())
	for y in range(from.y, maxi(to.y, from.y + 1)):
		for x in range(from.x, maxi(to.x, from.x + 1)):
			px(x, y, color)


# A square dot of `size` pixels centered on a point.
func dot(at: Vector2, color: Color, size := 1) -> void:
	if measuring:
		return
	var corner := Vector2i((at * scale + origin).floor()) - Vector2i.ONE * (size / 2)
	for y in size:
		for x in size:
			px(corner.x + x, corner.y + y, color)


func line(a: Vector2, b: Vector2, color: Color) -> void:
	if measuring:
		return
	var from := a * scale + origin
	var to := b * scale + origin
	var steps := maxi(int(ceil(from.distance_to(to))), 1)
	for i in steps + 1:
		var at := from.lerp(to, float(i) / steps).floor()
		px(int(at.x), int(at.y), color)


func px(x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
		image.set_pixel(x, y, color)


# Adds the dark outline around everything drawn so far and returns the texture.
func finish(outline := true) -> ImageTexture:
	if outline:
		var source: Image = image.duplicate()
		var w := image.get_width()
		var h := image.get_height()
		for y in h:
			for x in w:
				if source.get_pixel(x, y).a > 0.0:
					continue
				for offset: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var n: Vector2i = Vector2i(x, y) + offset
					if n.x < 0 or n.y < 0 or n.x >= w or n.y >= h:
						continue
					var neighbor := source.get_pixelv(n)
					if neighbor.a > 0.5:
						var dark := neighbor.darkened(0.68)
						dark.a = 1.0
						image.set_pixel(x, y, dark)
						break
	return ImageTexture.create_from_image(image)


func _min_radius() -> float:
	return 0.0 if measuring else 0.5 / scale


# inside(p) tells if a point (in units) is in the shape; side(p) goes from -1 on its lit top
# to 1 on its shaded underside.
func _fill(rect: Rect2, inside: Callable, side: Callable, color: Color, outlined: bool) -> void:
	if measuring:
		bounds = rect if not _measured else bounds.merge(rect)
		_measured = true
		return
	var size := image.get_size()
	var from := (Vector2i((rect.position * scale + origin).floor()) - Vector2i(2, 2)).clamp(Vector2i.ZERO, size - Vector2i.ONE)
	var to := (Vector2i((rect.end * scale + origin).ceil()) + Vector2i(2, 2)).clamp(Vector2i.ZERO, size - Vector2i.ONE)
	var w := to.x - from.x + 1
	var h := to.y - from.y + 1
	var hits := PackedFloat32Array()
	hits.resize(w * h)
	hits.fill(INF)
	var any := false
	for y in h:
		for x in w:
			var p := (Vector2(from.x + x, from.y + y) + Vector2(0.5, 0.5) - origin) / scale
			if inside.call(p):
				hits[y * w + x] = side.call(p)
				any = true
	if not any:
		# Smaller than a pixel: keep one dot so thin horns and claws do not vanish.
		var center := Vector2i((rect.get_center() * scale + origin).floor())
		px(center.x, center.y, color)
		return
	var shade := color.darkened(SHADE)
	var light := color.lightened(LIGHT)
	var edge := color.darkened(0.62)
	edge.a = 1.0
	for y in h:
		for x in w:
			var s := hits[y * w + x]
			if s != INF:
				# A checker where the tones meet, like hand-shaded pixel art.
				var checker := (from.x + x + from.y + y) % 2 == 0
				var c := color
				if s > 0.45 or (s > 0.3 and checker):
					c = shade
				elif s < -0.62 or (s < -0.48 and checker):
					c = light
				image.set_pixel(from.x + x, from.y + y, c)
			elif outlined and _touches(hits, x, y, w, h):
				image.set_pixel(from.x + x, from.y + y, edge)


func _touches(hits: PackedFloat32Array, x: int, y: int, w: int, h: int) -> bool:
	return (x > 0 and hits[y * w + x - 1] != INF) or (x < w - 1 and hits[y * w + x + 1] != INF) \
		or (y > 0 and hits[(y - 1) * w + x] != INF) or (y < h - 1 and hits[(y + 1) * w + x] != INF)

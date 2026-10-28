extends RefCounted

# Every species drawn by hand, part by part (see layers.gd): a land dinosaur is seen from the side
# (facing right), from the front ("down") and from the back ("up"), with 4 walking frames, a roar
# and a sleep. Flyers are seen from below with their wings spread (4 flaps), swimmers from the
# side (4 strokes).
#
# Each family has one drawing ("plan"), in design units, that the species tune with their
# features (catalog.gd) and a size `k`. Sizes are chosen so that no dinosaur is smaller than the
# explorer (25 pixels high).

const Layers := preload("res://scripts/layers.gd")

# k: size of the drawing; top: room added above it (a sail, a crest); accent: the frill or the
# plates when the catalog's second color is not the right one; head: the head of a small biped;
# neck: how much higher a small biped holds its head; crest: the crest of a flyer; pattern: marks
# on the back (stripes, spots or bands).
const SPECIES := {
	"triceratops": {"plan": "quad", "k": 1.0, "accent": Color("e8a040"), "pattern": "spots"},
	"pachyrhinosaurus": {"plan": "quad", "k": 0.82, "accent": Color("d8b878"), "pattern": "spots"},
	"stegosaurus": {"plan": "quad", "k": 1.0, "pattern": "bands"},
	"ankylosaurus": {"plan": "quad", "k": 0.9},
	"trex": {"plan": "theropod", "k": 1.0},
	"carnotaurus": {"plan": "theropod", "k": 0.78},
	"dilophosaurus": {"plan": "theropod", "k": 0.62, "top": 4, "pattern": "spots"},
	"yutyrannus": {"plan": "theropod", "k": 0.84, "pattern": "bands"},
	"spinosaurus": {"plan": "theropod", "k": 1.08, "top": 14},
	"velociraptor": {"plan": "small", "k": 1.0, "head": "raptor", "pattern": "stripes"},
	"pachycephalosaurus": {"plan": "small", "k": 1.1, "head": "dome", "pattern": "spots"},
	"gallimimus": {"plan": "small", "k": 1.12, "head": "beak", "neck": 6, "top": 6, "pattern": "stripes"},
	"parasaurolophus": {"plan": "small", "k": 1.45, "head": "duck", "top": 5, "pattern": "stripes"},
	"diplodocus": {"plan": "sauropod", "k": 1.0, "pattern": "bands"},
	"brachiosaurus": {"plan": "sauropod", "k": 1.0, "tall": true, "top": 4, "pattern": "spots"},
	"pteranodon": {"plan": "flyer", "k": 1.0, "crest": "long"},
	"quetzalcoatlus": {"plan": "flyer", "k": 1.35, "crest": "short"},
	"dimorphodon": {"plan": "flyer", "k": 0.72, "crest": "none"},
	"tapejara": {"plan": "flyer", "k": 0.85, "crest": "sail"},
	"mosasaurus": {"plan": "mosasaur", "k": 1.0},
	"plesiosaurus": {"plan": "plesio", "k": 1.0, "pattern": "spots"},
	"styracosaurus": {"plan": "quad", "k": 0.92, "top": 6, "accent": Color("d8a060"), "pattern": "spots"},
	"protoceratops": {"plan": "quad", "k": 0.7, "pattern": "spots"},
	"kentrosaurus": {"plan": "quad", "k": 0.82, "pattern": "bands"},
	"nodosaurus": {"plan": "quad", "k": 0.85},
	"maiasaura": {"plan": "small", "k": 1.4, "head": "bill", "pattern": "spots"},
	"corythosaurus": {"plan": "small", "k": 1.4, "head": "helmet", "top": 3, "pattern": "stripes"},
	"iguanodon": {"plan": "small", "k": 1.55, "head": "beak", "neck": 2, "pattern": "bands"},
	"stygimoloch": {"plan": "small", "k": 1.0, "head": "dome", "pattern": "stripes"},
	"oviraptor": {"plan": "small", "k": 0.95, "head": "beak", "neck": 3, "top": 3, "pattern": "stripes"},
	"deinonychus": {"plan": "small", "k": 1.2, "head": "raptor", "pattern": "stripes"},
	"utahraptor": {"plan": "small", "k": 1.55, "head": "raptor", "pattern": "stripes"},
	"microraptor": {"plan": "small", "k": 0.88, "head": "raptor", "pattern": "stripes"},
	"allosaurus": {"plan": "theropod", "k": 0.9, "pattern": "bands"},
	"ceratosaurus": {"plan": "theropod", "k": 0.76, "pattern": "bands"},
	"baryonyx": {"plan": "theropod", "k": 0.82, "pattern": "spots"},
	"giganotosaurus": {"plan": "theropod", "k": 1.12, "pattern": "bands"},
	"apatosaurus": {"plan": "sauropod", "k": 0.95, "pattern": "spots"},
	"argentinosaurus": {"plan": "sauropod", "k": 1.25, "pattern": "bands"},
	"rhamphorhynchus": {"plan": "flyer", "k": 0.7, "crest": "none"},
	"pterodactylus": {"plan": "flyer", "k": 0.66, "crest": "short"},
	"ichthyosaurus": {"plan": "mosasaur", "k": 0.55},
	"liopleurodon": {"plan": "mosasaur", "k": 0.75},
	"elasmosaurus": {"plan": "plesio", "k": 1.25, "pattern": "spots"},
}
# side / front: design size seen from the side / from the front and the back. feet: x of the
# feet on the side drawing. anchor: for flyers and swimmers, the middle of the body.
const PLANS := {
	"quad": {"side": Vector2i(52, 34), "front": Vector2i(36, 34), "feet": 24},
	"theropod": {"side": Vector2i(66, 46), "front": Vector2i(46, 46), "feet": 31},
	"small": {"side": Vector2i(40, 29), "front": Vector2i(30, 29), "feet": 18},
	"sauropod": {"side": Vector2i(100, 56), "front": Vector2i(44, 56), "feet": 50},
	"flyer": {"side": Vector2i(44, 26), "anchor": Vector2(22, 13)},
	"mosasaur": {"side": Vector2i(90, 26), "anchor": Vector2(45, 13)},
	"plesio": {"side": Vector2i(48, 32), "anchor": Vector2(22, 20)},
}
# Room left around every drawing (design units), so that a head going up while walking, a tail
# or a wing tip is never cut by the edge of the picture.
const MARGIN := 4
const HORN := Color("f2e8cc")
const BEAK := Color("6e6256")
const EYE := Color("1e1612")
const MOUTH := Color("7a1c1c")


static func has(id: String) -> bool:
	return SPECIES.has(id)


static func has_front(id: String) -> bool:
	return PLANS[SPECIES[id].plan].has("front")


# The size in pixels of a drawing.
static func canvas(id: String, direction: String) -> Vector2i:
	var info: Dictionary = SPECIES[id]
	var plan: Dictionary = PLANS[info.plan]
	var design: Vector2i = plan.side if direction == "side" else plan.front
	return Vector2i(((Vector2(design) + Vector2(MARGIN * 2, info.get("top", 0) + MARGIN)) * info.k).ceil())


# Where the dinosaur stands (or the middle of its body for flyers and swimmers), in pixels.
static func origin(id: String, direction: String) -> Vector2:
	var info: Dictionary = SPECIES[id]
	var plan: Dictionary = PLANS[info.plan]
	var shift := Vector2(MARGIN, info.get("top", 0) + MARGIN)
	if plan.has("anchor"):
		return (plan.anchor + shift) * info.k
	if direction == "side":
		return (Vector2(plan.feet, plan.side.y) + shift) * info.k
	return (Vector2(plan.front.x / 2.0, plan.front.y) + shift) * info.k


# pose: "walk" (frames 0 to 3), "roar" or "sleep". direction: "side", "down" or "up".
static func draw(id: String, sp: Dictionary, direction: String, frame: int, pose := "walk") -> Image:
	var info: Dictionary = SPECIES[id]
	var plan: Dictionary = PLANS[info.plan]
	var l := Layers.new(canvas(id, direction), info.k, Vector2(MARGIN, info.get("top", 0) + MARGIN) * info.k)
	l.design = plan.side if direction == "side" else plan.front
	var features: Array = sp.get("features", [])
	var bob := -1 if frame % 2 == 1 else 0
	match info.plan:
		"quad":
			_quad(l, sp, info, features, direction, frame, pose, bob)
		"theropod":
			_theropod(l, sp, features, direction, frame, pose, bob)
		"small":
			_small(l, sp, info, features, direction, frame, pose, bob)
		"sauropod":
			_sauropod(l, sp, info, direction, frame, pose, bob)
		"flyer":
			_flyer(l, sp, info, frame, pose)
		"mosasaur":
			_mosasaur(l, sp, frame, pose)
		"plesio":
			_plesio(l, sp, frame, pose)
	if info.has("pattern"):
		_pattern(l.image, info.pattern, sp.color, info.k)
	return l.image


# Darker marks on the back, measured from the top of the skin in each column, so that they follow
# the body when it bobs up and down. Only the skin is marked, not the frill, plates or eyes.
static func _pattern(image: Image, kind: String, skin: Color, k: float) -> void:
	var reach := roundi(7 * k)
	for x in image.get_width():
		var back := -1
		for y in image.get_height():
			var c := image.get_pixel(x, y)
			if c.a < 0.5 or not _is_skin(c, skin):
				continue
			if back < 0:
				back = y
			var depth := y - back
			if depth < 1 or depth > reach:
				continue
			var mark := false
			match kind:
				"stripes":
					# Thin stripes going down from the spine, shorter every other one.
					mark = x % 5 < 2 and depth <= reach - (2 if (x / 5) % 2 == 0 else 0)
				"bands":
					mark = x % 9 < 4 and depth <= reach - 2
				"spots":
					# A grid of 4 x 4 cells, every other row shifted, most of them holding a spot.
					var row := depth / 4
					var sx := x + (2 if row % 2 == 1 else 0)
					var cell := Vector2i(sx / 4, row)
					if (cell.x * 7 + cell.y * 13) % 5 < 3:
						var inside := Vector2i(sx % 4, depth % 4)
						mark = inside.x in [1, 2] and inside.y in [1, 2]
			if mark:
				image.set_pixel(x, y, c.darkened(0.3))


# True for the skin color and its shades, not the outline nor the other colors.
static func _is_skin(c: Color, skin: Color) -> bool:
	if c.get_luminance() < skin.get_luminance() * 0.45:
		return false
	if skin.s < 0.2:
		# A grey or pale skin has no real hue: its shades are the colors as grey as it.
		return c.s < skin.s + 0.1 and c.get_luminance() < 0.95
	var hue := absf(c.h - skin.h)
	return minf(hue, 1.0 - hue) < 0.04 and absf(c.s - skin.s) < 0.25


# A side eye looking ahead (to the right): white, a big dark pupil with a spark of light, and a
# brow above it. Closed, a curved line.
static func _eye(l: Layers, x: float, y: float, closed: bool) -> void:
	if closed:
		l.dot(x, y + 1, EYE)
		l.dot(x + 1, y + 1.5, EYE)
		l.dot(x + 2, y + 1, EYE)
		return
	for dx in 3:
		l.shade(x + dx, y - 1.2, 0.45)
	l.dot(x, y, Color.WHITE)
	l.dot(x, y + 1, Color.WHITE)
	l.dot(x + 1, y, Color.WHITE)
	l.dot(x + 2, y, EYE)
	l.dot(x + 1, y + 1, EYE)
	l.dot(x + 2, y + 1, EYE)


# An eye seen from the front: a dark round pupil with a spark of light, under a brow.
static func _front_eye(l: Layers, x: float, y: float, closed: bool) -> void:
	if closed:
		l.dot(x, y + 1, EYE)
		l.dot(x + 1, y + 1, EYE)
		return
	l.shade(x, y - 1.2, 0.45)
	l.shade(x + 1, y - 1.2, 0.45)
	l.dot(x, y, Color.WHITE)
	l.dot(x + 1, y, EYE)
	l.dot(x, y + 1, EYE)
	l.dot(x + 1, y + 1, EYE)


static func _toes(l: Layers, x: float, y: float, steps: Array) -> void:
	for dx in steps:
		l.dot(x + dx, y, HORN)


static func _union(masks: Array) -> PackedByteArray:
	var out: PackedByteArray = masks[0].duplicate()
	for mask in masks.slice(1):
		for i in out.size():
			out[i] = out[i] | mask[i]
	return out


# --- Quadrupeds: triceratops, pachyrhinosaurus, stegosaurus, ankylosaurus -------------------

static func _quad(l: Layers, sp: Dictionary, info: Dictionary, f: Array, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var accent: Color = info.get("accent", sp.color2)
	var belly: Color = skin.lightened(0.5)
	var g := l.design.y - 1
	var frilled := "frill" in f
	var plates := "plates" in f
	var armor := "armor" in f
	var sleep := pose == "sleep"
	var roar := pose == "roar"
	if direction == "side":
		var y := 7 if sleep else bob
		var sw: int = [0, 2, 0, -2][frame]
		if not sleep:
			l.part([_pillar(l, Vector2(18, 22 + y), 18 + sw, g), _pillar(l, Vector2(34, 22 + y), 34 - sw, g)], skin.darkened(0.2))
		if plates:
			for i in 5:
				var x: float = 12 + i * 5.5
				var h: float = [5, 7, 8.5, 7, 5][i]
				l.part([l.poly([Vector2(x - 3, 13 + y), Vector2(x - 0.5, 12 - h + y), Vector2(x + 3, 13 + y)])], accent, 1, 1)
		if armor:
			l.part([l.limb(Vector2(14, 19 + y), Vector2(3, 21 + y), 3.5, 2)], skin)
		elif plates:
			l.part([l.poly([Vector2(0, 17 + y), Vector2(13, 12 + y), Vector2(17, 21 + y), Vector2(5, 20 + y)])], skin)
		else:
			l.part([l.poly([Vector2(0, 25 + y), Vector2(13, 13 + y), Vector2(17, 22 + y), Vector2(6, 25 + y)])], skin)
		if "tail_spikes" in f:
			l.part([l.limb(Vector2(3, 17 + y), Vector2(0, 11 + y), 1.2, 0.4), l.limb(Vector2(6, 16 + y), Vector2(4, 10 + y), 1.2, 0.4)], HORN, 0, 1)
		if "club" in f:
			l.part([l.ellipse(3, 21 + y, 3.5, 3)], sp.color2)
		if armor:
			l.part([l.ellipse(24, 19 + y, 15, 8)], skin)
		else:
			l.part([l.ellipse(23, 17 + y, 14, 9)], skin)
		l.part([l.ellipse(24, 23.5 + y, 10, 2.6)], belly, 0, 1, false)
		if armor:
			for i in 7:
				var x: float = 12 + i * 4
				l.part([l.ellipse(x, 12 + y + absf(i - 3) * 0.6, 1.8, 1.5)], sp.color2.lightened(0.15), 1, 1)
			for x in [14, 22, 30]:
				l.part([l.poly([Vector2(x - 1.5, 22 + y), Vector2(x, 26 + y), Vector2(x + 1.5, 22 + y)])], HORN, 0, 1)
		if not sleep:
			l.part([_pillar(l, Vector2(15, 22 + y), 15 - sw, g)], skin)
		if frilled:
			l.part([l.ellipse(34, 9 + y, 6.5, 9)], accent, 1, 1)
			for spot in [Vector2(32, 4), Vector2(31, 8), Vector2(32, 12), Vector2(34, 6), Vector2(34, 10)]:
				l.dot(spot.x, spot.y + y, accent.darkened(0.25))
			if "nose_boss" in f:
				for spike in [Vector2(30, 1), Vector2(34, 0), Vector2(37, 2)]:
					l.part([l.limb(Vector2(spike.x, spike.y + 3 + y), Vector2(spike.x, spike.y + y), 1, 0.4)], HORN, 0, 1)
			if "spiky_frill" in f:
				# Long spikes all around the frill, like a crown.
				for angle in [-170.0, -135.0, -100.0, -70.0]:
					var out := Vector2(6.5 * cos(deg_to_rad(angle)), 9 * sin(deg_to_rad(angle)))
					l.part([l.limb(Vector2(34, 9 + y) + out * 0.8, Vector2(34, 9 + y) + out * 1.6, 1.3, 0.4)], HORN, 0, 1)
			l.part([l.poly([Vector2(35, 10 + y), Vector2(42, 9 + y), Vector2(48, 14 + y), Vector2(47, 20 + y), Vector2(39, 21 + y), Vector2(35, 18 + y)])], skin)
			l.part([l.poly([Vector2(46, 13 + y), Vector2(51, 17 + y), Vector2(47, 21 + y), Vector2(45, 19 + y)])], BEAK, 0, 1)
			if roar:
				l.part([l.poly([Vector2(40, 19 + y), Vector2(48, 19 + y), Vector2(46, 24 + y), Vector2(40, 22 + y)])], MOUTH, 0, 1)
			if "three_horns" in f:
				l.part([l.limb(Vector2(40, 10 + y), Vector2(49, 3 + y), 1.5, 0.5)], HORN, 0, 1)
				l.part([l.limb(Vector2(46, 13 + y), Vector2(47, 10 + y), 1.1, 0.4)], HORN, 0, 1)
			if "nose_boss" in f:
				l.part([l.ellipse(44, 12 + y, 3, 2)], accent.darkened(0.1), 1, 1)
			if "nose_horn" in f:
				l.part([l.limb(Vector2(45, 13 + y), Vector2(47, 3 + y), 1.7, 0.5)], HORN, 0, 1)
			_eye(l, 39, 12 + y, sleep)
			if not roar:
				for x in range(42, 46):
					l.dot(x, 18 + y, skin.darkened(0.72))
		else:
			# A small head held low, at the end of a short neck.
			l.part([l.limb(Vector2(34, 17 + y), Vector2(42, 21 + y), 4, 3)], skin)
			var head := [Vector2(39, 17 + y), Vector2(46, 18 + y), Vector2(50, 21 + y), Vector2(47, 25 + y), Vector2(39, 24 + y)]
			if armor:
				head = [Vector2(37, 16 + y), Vector2(45, 16 + y), Vector2(49, 20 + y), Vector2(47, 25 + y), Vector2(37, 24 + y)]
				l.part([l.poly([Vector2(37, 18 + y), Vector2(35, 14 + y), Vector2(40, 16 + y)])], HORN, 0, 1)
			l.part([l.poly(head)], skin)
			if roar:
				l.part([l.poly([Vector2(44, 22 + y), Vector2(50, 22 + y), Vector2(48, 26 + y)])], MOUTH, 0, 0)
			else:
				for x in range(44, 49):
					l.dot(x, 22 + y, skin.darkened(0.72))
			_eye(l, 42, 18 + y, sleep)
		if not sleep:
			l.part([_pillar(l, Vector2(32, 22 + y), 32 + sw, g)], skin)
			_toes(l, 15 - sw, g - 1, [-1, 1, 3])
			_toes(l, 32 + sw, g - 1, [-1, 1, 3])
		return
	var cx := l.design.x / 2.0
	var y := bob
	var lift: int = [0, 1, 0, 0][frame]
	var lift2: int = [0, 0, 0, 1][frame]
	var front := direction == "down"
	var top := 24 if armor else 22
	var legs := func() -> void:
		l.part([l.box(cx - 10, top + y, 7, g - top - y - lift + 1)], skin)
		l.part([l.box(cx + 3, top + y, 7, g - top - y - lift2 + 1)], skin)
		if front:
			_toes(l, cx - 9, g - lift, [0, 2, 4])
			_toes(l, cx + 4, g - lift2, [0, 2, 4])
	if not front:
		legs.call()
	if plates:
		for dx in [-7, -2.5, 2.5, 7]:
			var h: float = 9 - absf(dx) * 0.4
			l.part([l.poly([Vector2(cx + dx - 2.5, 16 + y), Vector2(cx + dx, 16 - h + y), Vector2(cx + dx + 2.5, 16 + y)])], accent, 1, 1)
	if armor:
		l.part([l.ellipse(cx, 21 + y, 15, 7)], skin)
		for dx in [-10, -5, 0, 5, 10]:
			l.part([l.ellipse(cx + dx, 16 + y + absf(dx) * 0.15, 2, 1.6)], sp.color2.lightened(0.15), 1, 1)
	else:
		l.part([l.ellipse(cx, 19 + y, 12, 8)], skin)
	if not front:
		if frilled:
			l.part([l.ellipse(cx, 8 + y, 15, 8)], accent, 1, 1)
			l.part([l.ellipse(cx, 9 + y, 12, 5.5)], accent.darkened(0.25), 0, 0, false)
		var tail := [l.limb(Vector2(cx, 22 + y), Vector2(cx, g - 1), 3.5, 1.6)]
		if "club" in f:
			l.part(tail, skin)
			l.part([l.ellipse(cx, g - 2, 4, 2.6)], sp.color2)
		else:
			l.part(tail, skin)
		if "tail_spikes" in f:
			l.part([l.limb(Vector2(cx - 2, g - 4), Vector2(cx - 6, g - 7), 1, 0.4), l.limb(Vector2(cx + 2, g - 4), Vector2(cx + 6, g - 7), 1, 0.4)], HORN, 0, 1)
		return
	legs.call()
	if frilled:
		l.part([l.ellipse(cx, 9 + y, 15, 8.5)], accent, 1, 1)
		for dx in [-9, -4, 0, 4, 9]:
			l.dot(cx + dx, 4 + y, accent.darkened(0.25))
		if "nose_boss" in f:
			for dx in [-8, -3, 3, 8]:
				l.part([l.limb(Vector2(cx + dx, 3 + y), Vector2(cx + dx * 1.15, y), 1, 0.4)], HORN, 0, 1)
		if "spiky_frill" in f:
			for dx in [-13, -8, -3, 3, 8, 13]:
				l.part([l.limb(Vector2(cx + dx * 0.8, 4 + y), Vector2(cx + dx * 1.1, -5 + y + absf(dx) * 0.3), 1.2, 0.4)], HORN, 0, 1)
		l.part([l.ellipse(cx, 15 + y, 6.5, 7.5)], skin)
		l.part([l.poly([Vector2(cx - 3, 19 + y), Vector2(cx + 3, 19 + y), Vector2(cx + 1.5, 25 + y), Vector2(cx - 1.5, 25 + y)])], BEAK, 0, 1)
		if "three_horns" in f:
			l.part([l.limb(Vector2(cx - 4, 11 + y), Vector2(cx - 7, 2 + y), 1.4, 0.5), l.limb(Vector2(cx + 4, 11 + y), Vector2(cx + 7, 2 + y), 1.4, 0.5)], HORN, 0, 1)
			l.part([l.limb(Vector2(cx, 19 + y), Vector2(cx, 16 + y), 1.1, 0.4)], HORN, 0, 1)
		if "nose_boss" in f:
			l.part([l.ellipse(cx, 17 + y, 3, 2.2)], accent.darkened(0.1), 1, 1)
		if "nose_horn" in f:
			l.part([l.limb(Vector2(cx, 19 + y), Vector2(cx, 10 + y), 1.6, 0.5)], HORN, 0, 1)
		if roar:
			l.part([l.ellipse(cx, 24 + y, 2.5, 1.5)], MOUTH, 0, 0)
		for x in [cx - 5, cx + 3]:
			_front_eye(l, x, 13 + y, sleep)
		return
	# A small head low in front of the body.
	var hy := 25 if armor else 23
	l.part([l.ellipse(cx, hy + y, 6 if armor else 4.5, 4)], skin)
	l.part([l.ellipse(cx, hy + 2.5 + y, 2.5, 1.5)], MOUTH if roar else BEAK, 0, 0)
	for x in [cx - 4, cx + 2]:
		_front_eye(l, x, hy - 2 + y, sleep)


# A heavy leg: a round thigh at the shoulder or the hip, a shin narrowing down to the ankle, and a
# wide round foot on the ground.
static func _pillar(l: Layers, top: Vector2, foot_x: float, ground: int, thick := 3.4) -> PackedByteArray:
	var thigh := l.ellipse(top.x + (foot_x - top.x) * 0.2, top.y + thick * 0.6, thick * 1.25, thick * 1.2)
	var shin := l.limb(top + Vector2(0, thick), Vector2(foot_x, ground - 3), thick * 0.95, thick * 0.75)
	return _union([thigh, shin, l.ellipse(foot_x + 0.5, ground - 1.2, thick + 0.6, 1.8)])


# --- Big meat eaters: T-Rex, carnotaurus, dilophosaurus, yutyrannus, spinosaurus --------------

static func _theropod(l: Layers, sp: Dictionary, f: Array, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var accent: Color = sp.color2
	var belly: Color = skin.lightened(0.45)
	var g := l.design.y - 1
	var roar := pose == "roar"
	var sleep := pose == "sleep"
	var stripes: Color = accent if not "feathers" in f else skin.darkened(0.25)
	if direction == "side":
		var y := 9 if sleep else bob
		var sw: int = [0, 4, 0, -4][frame]
		if not sleep:
			_trex_leg(l, Vector2(31, 28 + y), 31 + sw, g, skin.darkened(0.2))
		if "sail" in f:
			l.part([l.ellipse(31, 14 + y, 14, 14)], accent, 1, 1)
			for x in [22, 27, 32, 37]:
				l.part([l.limb(Vector2(x, 16 + y), Vector2(x - 1, 3 + y + absf(x - 30) * 0.5), 0.5, 0.4)], accent.darkened(0.3), 0, 0, false)
		l.part([l.limb(Vector2(26, 22 + y), Vector2(1, 15 + y), 8, 1.2)], skin)
		l.part([l.ellipse(31, 23 + y, 13, 10)], skin)
		l.part([l.ellipse(35, 29 + y, 9, 3.5)], belly, 0, 1, false)
		for x in [20, 25, 30, 12]:
			l.part([l.limb(Vector2(x, 14 + y + (2 if x < 16 else 0)), Vector2(x - 2, 19 + y), 1.0, 0.5)], stripes, 0, 0, false)
		if "feathers" in f:
			for x in [6, 12, 18, 24, 30, 36]:
				var top := 13.0 + y + absf(x - 28) * 0.12 + (2 if x < 16 else 0)
				l.part([l.poly([Vector2(x - 2, top + 2), Vector2(x - 3, top - 2), Vector2(x + 2, top + 1)])], accent, 1, 0)
		if "frill" in f and roar:
			l.part([l.ellipse(44, 15 + y, 7, 9)], accent, 1, 1)
		l.part([l.limb(Vector2(38, 18 + y), Vector2(44, 12 + y), 6, 5)], skin)
		if roar:
			l.part([l.poly([Vector2(44, 17 + y), Vector2(61, 21 + y), Vector2(58, 27 + y), Vector2(46, 24 + y)])], skin.darkened(0.12))
			l.part([l.poly([Vector2(45, 16 + y), Vector2(62, 15 + y), Vector2(59, 22 + y), Vector2(46, 21 + y)])], MOUTH, 0, 0, false)
			for x in [48, 52, 56]:
				l.dot(x, 22 + y, Color.WHITE)
		var up := -2 if roar else 0
		if "double_crest" in f:
			for dx in [0, 3]:
				l.part([l.poly([Vector2(43 + dx, 8 + y + up), Vector2(53 + dx, 0 + y + up), Vector2(56 + dx, 6 + y + up)])], accent, 1, 1)
		var head := [Vector2(40, 7), Vector2(55, 5), Vector2(64, 9), Vector2(64, 15), Vector2(56, 17), Vector2(44, 19), Vector2(39, 14)]
		if "sail" in f or "long_snout" in f:
			# A long thin snout, like a crocodile.
			head = [Vector2(40, 8), Vector2(52, 8), Vector2(65, 11), Vector2(65, 15), Vector2(52, 16), Vector2(44, 19), Vector2(39, 14)]
		l.part([l.poly(head.map(func(p: Vector2) -> Vector2: return p + Vector2(0, y + up)))], skin)
		if not roar:
			l.part([l.poly([Vector2(44, 16 + y), Vector2(62, 15 + y), Vector2(60, 20 + y), Vector2(46, 21 + y)])], skin.darkened(0.08))
			for x in range(46, 62):
				l.dot(x, 16 + y, skin.darkened(0.72))
			for x in [48, 52, 56, 60]:
				l.dot(x, 17 + y, Color.WHITE)
		l.part([l.limb(Vector2(46, 8 + y + up), Vector2(52, 7 + y + up), 1.2, 1.0)], skin.darkened(0.25), 0, 0, false)
		if "horns" in f:
			l.part([l.poly([Vector2(45, 7 + y + up), Vector2(47, 1 + y + up), Vector2(50, 6 + y + up)])], skin.darkened(0.1), 1, 1)
		if "nose_horn" in f:
			l.part([l.poly([Vector2(56, 6 + y + up), Vector2(58, 0 + y + up), Vector2(60, 7 + y + up)])], HORN, 1, 1)
		_eye(l, 49, 9 + y + up, sleep)
		l.dot(62, 9 + y + up, skin.darkened(0.6))
		l.part([l.limb(Vector2(42, 25 + y), Vector2(46, 29 + y), 1.6, 1.1)], skin)
		l.dot(47, 30 + y, HORN)
		if not sleep:
			_trex_leg(l, Vector2(28, 28 + y), 28 - sw, g, skin)
		return
	# From the front and the back, the head is turned a little to the right (three-quarters), so
	# the long snout full of teeth shows; the tail sticks out on the left.
	var cx := l.design.x / 2.0
	var y := bob
	var lift: int = [0, 2, 0, 0][frame]
	var lift2: int = [0, 0, 0, 2][frame]
	var dark := skin.darkened(0.72)
	var front := direction == "down"
	if "sail" in f:
		l.part([l.ellipse(cx, 18 + y, 3, 16)], accent, 1, 1)
	l.part([l.limb(Vector2(cx - 4, 30 + y), Vector2(cx - 15, 37), 5, 2.6), l.limb(Vector2(cx - 15, 37), Vector2(cx - 21, 43), 2.6, 1)], skin.darkened(0.1))
	for side in [-1, 1]:
		var foot_y: int = g - (lift if side < 0 else lift2)
		l.part([l.ellipse(cx + side * 7, 31 + y, 5, 6), l.limb(Vector2(cx + side * 7, 33 + y), Vector2(cx + side * 7, foot_y - 2), 3, 2.4), l.ellipse(cx + side * 7, foot_y - 1, 4, 1.8)], skin)
		if front:
			_toes(l, cx + side * 7 - 2, foot_y, [0, 2, 4])
	l.part([l.ellipse(cx, 26 + y, 11, 9)], skin)
	if front:
		l.part([l.ellipse(cx + 1, 29 + y, 7, 5)], belly, 0, 1, false)
		for x in [-9, -6]:
			l.part([l.limb(Vector2(cx + x, 21 + y), Vector2(cx + x + 1, 25 + y), 0.8, 0.5)], stripes, 0, 0, false)
	else:
		for row in [20, 24, 28]:
			l.part([l.limb(Vector2(cx - 7, row + y), Vector2(cx + 7, row + y - 1), 0.8, 0.8)], stripes, 0, 0, false)
	if "feathers" in f:
		for dx in [-9, -5, 5, 9]:
			l.part([l.poly([Vector2(cx + dx - 2, 20 + y), Vector2(cx + dx, 16 + y), Vector2(cx + dx + 2, 20 + y)])], accent, 1, 0)
	# Tiny arms with two claws.
	for x in [-6, 6]:
		l.part([l.limb(Vector2(cx + x, 24 + y), Vector2(cx + x + 2, 28 + y), 1.6, 1.1)], skin)
		l.dot(cx + x + 2, 29 + y, HORN)
		l.dot(cx + x + 3, 29 + y, HORN)
	if "frill" in f and roar:
		l.part([l.ellipse(cx, 14 + y, 13, 9)], accent, 1, 1)
	l.part([l.ellipse(cx, 18 + y, 7, 6)], skin)
	var open := 4 if roar else 0
	if "double_crest" in f:
		for dx in [-3, 1]:
			l.part([l.poly([Vector2(cx + dx - 1, 6 + y), Vector2(cx + dx + 3, -2 + y), Vector2(cx + dx + 3, 6 + y)])], accent, 1, 1)
	if front:
		# The lower jaw, then the head with its long snout.
		l.part([l.poly([Vector2(cx - 5, 15 + y), Vector2(cx + 15, 16 + y + open), Vector2(cx + 13, 21 + y + open), Vector2(cx - 3, 21 + y)])], skin.darkened(0.1))
		if roar:
			l.part([l.poly([Vector2(cx - 3, 15 + y), Vector2(cx + 15, 14 + y), Vector2(cx + 14, 17 + y + open), Vector2(cx - 2, 18 + y)])], MOUTH, 0, 0, false)
		l.part([l.ellipse(cx - 1, 10 + y, 9, 7.5), l.poly([Vector2(cx - 2, 5 + y), Vector2(cx + 13, 9 + y), Vector2(cx + 16, 13 + y), Vector2(cx + 15, 16 + y), Vector2(cx - 5, 16 + y)])], skin)
		for x in range(-4, 16):
			l.dot(cx + x, 16 + y, dark)
		for x in [-1, 3, 7, 11]:
			l.dot(cx + x, 17 + y + open, Color.WHITE)
			l.dot(cx + x + 1, 15 + y, Color.WHITE)
		# Brow ridge and eyes: the near one big, the far one just a dot.
		l.part([l.limb(Vector2(cx, 6 + y), Vector2(cx + 5, 6 + y), 1.1, 0.9)], skin.darkened(0.25), 0, 0, false)
		if "horns" in f:
			for dx in [-6, 1]:
				l.part([l.poly([Vector2(cx + dx, 5 + y), Vector2(cx + dx + 2, -1 + y), Vector2(cx + dx + 4, 5 + y)])], skin.darkened(0.1), 1, 1)
		if "nose_horn" in f:
			l.part([l.poly([Vector2(cx + 8, 8 + y), Vector2(cx + 10, 2 + y), Vector2(cx + 12, 9 + y)])], HORN, 1, 1)
		_eye(l, cx + 2, 7 + y, sleep)
		l.dot(cx - 7, 8 + y, EYE)
		l.dot(cx + 14, 10 + y, skin.darkened(0.6))
	else:
		l.part([l.poly([Vector2(cx + 4, 7 + y), Vector2(cx + 15, 10 + y), Vector2(cx + 15, 15 + y), Vector2(cx + 4, 16 + y)])], skin.darkened(0.08))
		l.part([l.ellipse(cx - 1, 10 + y, 9, 7.5)], skin)
		for x in [-5, -1, 3]:
			l.part([l.limb(Vector2(cx + x, 5 + y), Vector2(cx + x + 1, 8 + y), 0.6, 0.5)], stripes, 0, 0, false)
		if "horns" in f:
			for dx in [-6, 1]:
				l.part([l.poly([Vector2(cx + dx, 5 + y), Vector2(cx + dx + 2, -1 + y), Vector2(cx + dx + 4, 5 + y)])], skin.darkened(0.1), 1, 1)


static func _trex_leg(l: Layers, hip: Vector2, foot_x: float, g: int, color: Color) -> void:
	l.part([l.ellipse(hip.x, hip.y, 6, 7.5), l.limb(hip + Vector2(1, 4), Vector2(foot_x, g - 2), 3.4, 2.2), l.ellipse(foot_x + 2, g - 1, 4.5, 1.8)], color)
	_toes(l, foot_x + 2, g, [1, 3, 5])


# --- Small bipeds: velociraptor, pachycephalosaurus, gallimimus, parasaurolophus -------------
# The same body; the head changes (info.head) and a long neck lifts it (info.neck).

static func _small(l: Layers, sp: Dictionary, info: Dictionary, f: Array, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var accent: Color = sp.color2
	var belly: Color = skin.lightened(0.45)
	var g := l.design.y - 1
	var sleep := pose == "sleep"
	var roar := pose == "roar"
	var kind: String = info.head
	var neck: float = info.get("neck", 0)
	var striped := "stripes" in f
	if direction == "side":
		var y := 6 if sleep else bob
		var sw: int = [0, 3, 0, -3][frame]
		if not sleep:
			_small_leg(l, Vector2(18, 16 + y), 18 + sw, g, skin.darkened(0.2), kind == "raptor")
		l.part([l.limb(Vector2(14, 13 + y), Vector2(0, 8 + y), 3.5, 1)], skin)
		if striped:
			for x in [2, 5, 8]:
				l.dot(x, 8 + y + x / 4.0, accent)
		l.part([l.ellipse(18, 14 + y, 8, 5.5)], skin)
		l.part([l.ellipse(19, 17 + y, 5, 2)], belly, 0, 1, false)
		if striped:
			for x in [14, 17, 20]:
				l.part([l.limb(Vector2(x, 9 + y), Vector2(x - 1, 12 + y), 0.8, 0.5)], accent, 0, 0, false)
		var h := Vector2(0, y - neck)
		l.part([l.limb(Vector2(22, 12 + y), Vector2(27, 7) + h, 3.2, 2.6)], skin)
		_small_head_side(l, kind, h, skin, accent, roar, sleep)
		l.part([l.limb(Vector2(22, 15 + y), Vector2(26, 18 + y), 1.4, 1)], skin)
		l.dot(27, 19 + y, HORN)
		if not sleep:
			_small_leg(l, Vector2(16, 16 + y), 16 - sw, g, skin, kind == "raptor")
		return
	# From the front and the back: the head turned a little to the right, with its snout, and the
	# stiff tail held up on the left.
	var cx := l.design.x / 2.0
	var y := bob
	var lift: int = [0, 1, 0, 0][frame]
	var lift2: int = [0, 0, 0, 1][frame]
	var front := direction == "down"
	l.part([l.limb(Vector2(cx - 2, 16 + y), Vector2(cx - 13, 9 + y), 2.6, 0.9)], skin.darkened(0.1))
	if striped:
		for x in [-11, -8, -5]:
			l.dot(cx + x, 10 + y - x / 4.0, accent)
	for side in [-1, 1]:
		var foot_y: int = g - (lift if side < 0 else lift2)
		l.part([l.ellipse(cx + side * 3.5, 18 + y, 3, 4), l.limb(Vector2(cx + side * 3.5, 20 + y), Vector2(cx + side * 3.5, foot_y - 1), 1.8, 1.4), l.ellipse(cx + side * 3.5, foot_y - 0.5, 2.5, 1.2)], skin)
		if front:
			l.dot(cx + side * 3.5 - 1, foot_y, HORN)
			l.dot(cx + side * 3.5 + 1, foot_y, HORN)
			if kind == "raptor":
				# The big sickle claw, raised.
				l.dot(cx + side * 3.5 + side * 2, foot_y - 2, HORN)
	l.part([l.ellipse(cx, 15 + y, 6, 5)], skin)
	if front:
		l.part([l.ellipse(cx + 1, 17 + y, 3.5, 2.5)], belly, 0, 1, false)
	if striped:
		for row in [12, 15]:
			l.part([l.limb(Vector2(cx - 4, row + y), Vector2(cx - 2, row + y + 1), 0.6, 0.5)], accent, 0, 0, false)
	for x in [-5, 5]:
		l.part([l.limb(Vector2(cx + x, 14 + y), Vector2(cx + x + 1, 18 + y), 1.2, 0.9)], skin)
		l.dot(cx + x + 1, 19 + y, HORN)
	var h := Vector2(cx - 15, y - neck)
	l.part([l.limb(Vector2(cx, 12 + y), Vector2(16, 8) + h, 2.6, 2.4)], skin)
	_small_head_front(l, kind, h, skin, accent, front, roar, sleep)


# The heads seen from the side, facing right; `h` moves them.
static func _small_head_side(l: Layers, kind: String, h: Vector2, skin: Color, accent: Color, roar: bool, sleep: bool) -> void:
	var at := func(points: Array) -> Array:
		return points.map(func(p: Vector2) -> Vector2: return p + h)
	match kind:
		"raptor":
			l.part([l.poly(at.call([Vector2(24, 3), Vector2(33, 3), Vector2(39, 7), Vector2(37, 10), Vector2(28, 11), Vector2(24, 8)]))], skin)
			# A little crest of feathers on the head.
			l.part([l.poly(at.call([Vector2(23, 4), Vector2(27, 1), Vector2(28, 4)]))], accent, 0, 0)
			if roar:
				l.part([l.poly(at.call([Vector2(29, 8), Vector2(38, 9), Vector2(36, 13), Vector2(29, 11)]))], MOUTH, 0, 0)
			else:
				for x in range(30, 37):
					l.dot(x + h.x, 8 + h.y, skin.darkened(0.72))
			_eye(l, 30 + h.x, 4 + h.y, sleep)
		"dome":
			l.part([l.poly(at.call([Vector2(25, 5), Vector2(33, 4), Vector2(37, 8), Vector2(35, 11), Vector2(27, 11), Vector2(24, 8)]))], skin)
			l.part([l.ellipse(28.5 + h.x, 3.5 + h.y, 5, 4)], accent, 1, 1)
			for p in [Vector2(24, 5), Vector2(25, 2), Vector2(28, 0)]:
				l.dot(p.x + h.x, p.y + h.y, HORN)
			if roar:
				l.part([l.poly(at.call([Vector2(31, 9), Vector2(37, 9), Vector2(35, 12)]))], MOUTH, 0, 0)
			else:
				for x in range(32, 36):
					l.dot(x + h.x, 9 + h.y, skin.darkened(0.72))
			_eye(l, 31 + h.x, 6 + h.y, sleep)
		"beak":
			l.part([l.poly(at.call([Vector2(24, 4), Vector2(30, 3), Vector2(33, 6), Vector2(30, 9), Vector2(25, 8)]))], skin)
			l.part([l.poly(at.call([Vector2(31, 5), Vector2(38, 7), Vector2(31, 8)]))], BEAK if not roar else MOUTH, 0, 1)
			_eye(l, 27 + h.x, 4 + h.y, sleep)
		"duck", "bill", "helmet":
			# A duck bill; the parasaurolophus has a long tube on the head, the corythosaurus
			# a round helmet, the maiasaura nothing.
			if kind == "duck":
				l.part([l.limb(Vector2(27, 4) + h, Vector2(15, -2) + h, 2, 1.6)], accent, 1, 1)
			elif kind == "helmet":
				l.part([l.ellipse(27 + h.x, 1 + h.y, 4.5, 4)], accent, 1, 1)
			l.part([l.poly(at.call([Vector2(24, 4), Vector2(31, 3), Vector2(38, 6), Vector2(39, 9), Vector2(30, 10), Vector2(25, 9)]))], skin)
			l.part([l.poly(at.call([Vector2(34, 6), Vector2(40, 7), Vector2(40, 10), Vector2(34, 10)]))], BEAK if not roar else MOUTH, 0, 1)
			_eye(l, 29 + h.x, 5 + h.y, sleep)


static func _small_head_front(l: Layers, kind: String, h: Vector2, skin: Color, accent: Color, front: bool, roar: bool, sleep: bool) -> void:
	var cx := 15.0 + h.x
	var y := h.y
	match kind:
		"raptor":
			if front:
				if roar:
					l.part([l.poly([Vector2(cx + 1, 7 + y), Vector2(cx + 11, 7 + y), Vector2(cx + 10, 11 + y), Vector2(cx + 1, 10 + y)])], MOUTH, 0, 0)
				l.part([l.ellipse(cx, 5.5 + y, 4.5, 3.8), l.poly([Vector2(cx, 3 + y), Vector2(cx + 9, 4.5 + y), Vector2(cx + 11, 7 + y), Vector2(cx + 1, 8.5 + y)])], skin)
				if not roar:
					for x in range(2, 11):
						l.dot(cx + x, 7 + y, skin.darkened(0.72))
					for x in [4, 7]:
						l.dot(cx + x, 8 + y, Color.WHITE)
				_eye(l, cx + 1, 4 + y, sleep)
				l.dot(cx - 3, 5 + y, EYE)
			else:
				l.part([l.poly([Vector2(cx + 2, 3.5 + y), Vector2(cx + 10, 5 + y), Vector2(cx + 11, 7 + y), Vector2(cx + 2, 8.5 + y)])], skin.darkened(0.08))
				l.part([l.ellipse(cx, 5.5 + y, 4.5, 3.8)], skin)
			l.part([l.poly([Vector2(cx - 4, 3 + y), Vector2(cx - 2, y), Vector2(cx + 1, 2 + y)])], accent, 0, 0)
		"dome":
			# A big round face, the dome sitting on top of it, rimmed with little knobs.
			l.part([l.ellipse(cx + 1, 8 + y, 5.5, 4.5), l.poly([Vector2(cx + 2, 6.5 + y), Vector2(cx + 9, 8 + y), Vector2(cx + 8.5, 11 + y), Vector2(cx + 1, 12 + y)])], skin)
			l.part([l.ellipse(cx, 3.5 + y, 4.5, 3)], accent.lightened(0.1), 1, 1)
			for dx in [-5, -2.5, 2.5, 5]:
				l.dot(cx + dx, 5.5 + y - absf(dx) * 0.2, HORN)
			if front:
				_eye(l, cx + 2, 7 + y, sleep)
				l.dot(cx - 3, 8 + y, EYE)
				l.dot(cx + 8, 8.5 + y, skin.darkened(0.6))
				if roar:
					l.part([l.ellipse(cx + 6, 10.5 + y, 2, 1.2)], MOUTH, 0, 0)
				else:
					for x in range(3, 9):
						l.dot(cx + x, 10.5 + y, skin.darkened(0.72))
		"beak":
			l.part([l.ellipse(cx, 5 + y, 3.5, 3)], skin)
			l.part([l.poly([Vector2(cx + 2, 4 + y), Vector2(cx + 9, 6 + y), Vector2(cx + 2, 7.5 + y)])], BEAK if not roar else MOUTH, 0, 1)
			if front:
				_eye(l, cx, 4 + y, sleep)
				l.dot(cx - 3, 5 + y, EYE)
		"duck", "bill", "helmet":
			if kind == "duck":
				l.part([l.limb(Vector2(cx - 1, 3 + y), Vector2(cx - 9, -3 + y), 2, 1.6)], accent, 1, 1)
			elif kind == "helmet":
				l.part([l.ellipse(cx - 1, 1.5 + y, 4.5, 3.5)], accent, 1, 1)
			l.part([l.ellipse(cx, 6 + y, 4.5, 4), l.poly([Vector2(cx + 1, 4 + y), Vector2(cx + 8, 6 + y), Vector2(cx + 8, 9 + y), Vector2(cx, 10 + y)])], skin)
			l.part([l.poly([Vector2(cx + 4, 6 + y), Vector2(cx + 10, 7 + y), Vector2(cx + 10, 10 + y), Vector2(cx + 4, 10 + y)])], BEAK if not roar else MOUTH, 0, 1)
			if front:
				_eye(l, cx + 1, 5 + y, sleep)
				l.dot(cx - 3, 6 + y, EYE)


static func _small_leg(l: Layers, hip: Vector2, foot_x: float, g: int, color: Color, sickle: bool) -> void:
	l.part([l.ellipse(hip.x, hip.y, 3.5, 4.5), l.limb(hip + Vector2(1, 3), Vector2(foot_x, g - 1), 2, 1.3), l.ellipse(foot_x + 1.5, g - 0.5, 2.8, 1.2)], color)
	if sickle:
		# The big sickle claw.
		l.dot(foot_x + 1, g - 2, HORN)
	l.dot(foot_x + 3, g, HORN)


# --- Sauropods: diplodocus (long low neck, whip tail), brachiosaurus (neck up high) ----------

static func _sauropod(l: Layers, sp: Dictionary, info: Dictionary, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var spots: Color = sp.color2
	var belly: Color = skin.lightened(0.4)
	var g := l.design.y - 1
	var tall: bool = info.get("tall", false)
	var sleep := pose == "sleep"
	var roar := pose == "roar"
	if direction == "side":
		var y := 10 if sleep else bob
		var sw: int = [0, 3, 0, -3][frame]
		var shoulder := 26.0 if tall else 30.0
		if not sleep:
			l.part([_pillar(l, Vector2(41, 34 + y), 41 + sw, g, 4.4), _pillar(l, Vector2(64, shoulder + 4 + y), 64 - sw, g, 4.4)], skin.darkened(0.2))
		l.part([l.limb(Vector2(40, 30 + y), Vector2(12, 38 + y), 7, 2.5), l.limb(Vector2(12, 38 + y), Vector2(0, 41 + y), 2.5, 0.8)], skin)
		l.part([l.ellipse(51, 31 + y, 18, 12)] + ([l.ellipse(61, 27 + y, 10, 10)] if tall else []), skin)
		l.part([l.ellipse(53, 39 + y, 13, 3)], belly, 0, 1, false)
		for p in [Vector2(42, 23), Vector2(48, 21), Vector2(55, 22), Vector2(45, 28), Vector2(52, 27)]:
			l.part([l.ellipse(p.x, p.y + y, 1.6, 1.2)], spots, 0, 0, false)
		if not sleep:
			l.part([_pillar(l, Vector2(38, 34 + y), 38 - sw, g, 4.4)], skin)
		var neck_end := Vector2(76, 6) if tall else Vector2(86, 12)
		if sleep:
			neck_end = Vector2(88, 38)
		l.part([l.limb(Vector2(64, 27 + y), neck_end + Vector2(0, y), 7, 3.2)], skin)
		var head := neck_end + Vector2(3, y - 1)
		if tall:
			l.part([l.ellipse(head.x - 1, head.y - 3, 3, 2.5)], skin)
		l.part([l.ellipse(head.x, head.y, 5, 3.5), l.poly([head + Vector2(0, -2), head + Vector2(8, 1), head + Vector2(7, 3), head + Vector2(0, 3)])], skin)
		if roar:
			l.part([l.poly([head + Vector2(2, 2), head + Vector2(8, 2), head + Vector2(6, 6)])], MOUTH, 0, 0)
		else:
			for x in range(3, 8):
				l.dot(head.x + x, head.y + 2, skin.darkened(0.72))
		_eye(l, head.x, head.y - 2, sleep)
		if not sleep:
			l.part([_pillar(l, Vector2(62, shoulder + 4 + y), 62 + sw, g, 4.4)], skin)
			_toes(l, 38 - sw, g - 1, [-2, 0, 2, 4])
			_toes(l, 62 + sw, g - 1, [-2, 0, 2, 4])
		return
	var cx := l.design.x / 2.0
	var y := bob
	var lift: int = [0, 1, 0, 0][frame]
	var lift2: int = [0, 0, 0, 1][frame]
	var front := direction == "down"
	if not front:
		l.part([l.limb(Vector2(cx, 38 + y), Vector2(cx - 12, g - 2), 6, 2)], skin)
	for side in [-1, 1]:
		var up: int = lift if side < 0 else lift2
		l.part([l.box(cx + side * 10 - 4.5, 36 + y, 9, g - 36 - y - up + 1)], skin)
		if front:
			_toes(l, cx + side * 10 - 3, g - up, [0, 2, 4, 6])
	l.part([l.ellipse(cx, 34 + y, 15, 11)], skin)
	if front:
		l.part([l.ellipse(cx, 38 + y, 9, 5)], belly, 0, 1, false)
	else:
		for p in [Vector2(-6, 28), Vector2(0, 26), Vector2(6, 28), Vector2(-3, 32), Vector2(4, 32)]:
			l.part([l.ellipse(cx + p.x, p.y + y, 1.6, 1.2)], spots, 0, 0, false)
	var top := 6.0 if tall else 12.0
	l.part([l.limb(Vector2(cx, 30 + y), Vector2(cx + 3, top + y), 6, 3.4)], skin)
	var head := Vector2(cx + 4, top - 3 + y)
	if tall:
		l.part([l.ellipse(head.x - 1, head.y - 3, 3, 2.5)], skin)
	l.part([l.ellipse(head.x, head.y, 5, 4), l.poly([head + Vector2(0, -2), head + Vector2(8, 1), head + Vector2(7, 3), head + Vector2(0, 3)])], skin)
	if front:
		if roar:
			l.part([l.poly([head + Vector2(2, 2), head + Vector2(8, 2), head + Vector2(6, 6)])], MOUTH, 0, 0)
		_eye(l, head.x + 1, head.y - 2, sleep)
		l.dot(head.x - 3, head.y - 1, EYE)


# --- Flyers, seen from below with their wings spread -------------------------------------------

static func _flyer(l: Layers, sp: Dictionary, info: Dictionary, frame: int, pose: String) -> void:
	var skin: Color = sp.color
	var wing: Color = sp.color2
	var crest: String = info.crest
	var tip: float = [-6, 0, 5, 0][frame]
	var sleep := pose == "sleep"
	for side in [-1, 1]:
		var at := func(x: float, y: float) -> Vector2:
			return Vector2(22 + side * (x - 22), y)
		var tip_y := 11 + tip
		l.part([l.poly([at.call(23, 11), at.call(3, tip_y), at.call(1, tip_y + 2), at.call(10, 16 + tip * 0.3), at.call(22, 18)])], wing, 1, 1)
		l.part([l.limb(at.call(23, 11), at.call(2, tip_y), 1, 0.6)], skin, 1, 0)
	l.part([l.ellipse(22, 14, 3.5, 6)], skin)
	l.part([l.ellipse(22, 16, 2, 3)], skin.lightened(0.35), 0, 1, false)
	l.dot(20, 21, HORN)
	l.dot(24, 21, HORN)
	# The head turned to the right, with its beak and crest.
	match crest:
		"long":
			l.part([l.poly([Vector2(21, 5), Vector2(10, 1), Vector2(21, 8)])], wing, 1, 1)
		"short":
			l.part([l.poly([Vector2(21, 5), Vector2(15, 2), Vector2(21, 7)])], wing, 1, 1)
		"sail":
			l.part([l.poly([Vector2(20, 6), Vector2(19, 0), Vector2(27, 1), Vector2(25, 6)])], wing, 1, 1)
	l.part([l.ellipse(23, 6, 3.5, 3)], skin)
	var beak := [Vector2(24, 5), Vector2(35, 8), Vector2(24, 8)]
	if crest == "none":
		beak = [Vector2(24, 4), Vector2(31, 6), Vector2(30, 9), Vector2(24, 9)]
	if pose == "roar":
		l.part([l.poly(beak)], MOUTH, 0, 0)
		l.part([l.poly([beak[0] - Vector2(0, 1), beak[1] - Vector2(0, 2), beak[0] + Vector2(0, 1)])], HORN.darkened(0.15), 0, 0)
	else:
		l.part([l.poly(beak)], HORN.darkened(0.15) if crest != "none" else wing, 0, 1)
	_eye(l, 23, 5, sleep)


# --- Swimmers, seen from the side ----------------------------------------------------------

static func _mosasaur(l: Layers, sp: Dictionary, frame: int, pose: String) -> void:
	var skin: Color = sp.color
	var belly: Color = sp.color2
	var wave: float = [0, 2, 0, -2][frame]
	var paddle: float = [0, 1, 2, 1][frame]
	l.part([l.limb(Vector2(56, 17), Vector2(60, 22 + paddle), 2, 1.2), l.limb(Vector2(36, 17), Vector2(39, 22 - paddle), 1.8, 1)], skin.darkened(0.2))
	l.part([l.poly([Vector2(9, 13 + wave), Vector2(1, 3 + wave), Vector2(5, 13 + wave), Vector2(1, 23 + wave)])], skin)
	l.part([l.limb(Vector2(32, 13), Vector2(8, 13 + wave), 5.5, 2)], skin)
	l.part([l.ellipse(46, 13, 20, 7)], skin)
	l.part([l.ellipse(48, 17, 15, 2.5)], belly, 0, 1, false)
	for x in range(28, 64, 6):
		l.dot(x, 7 + absf(x - 46) * 0.06, skin.darkened(0.3))
	var roar := pose == "roar"
	if roar:
		l.part([l.poly([Vector2(64, 13), Vector2(89, 17), Vector2(84, 23), Vector2(64, 18)])], skin.darkened(0.1))
		l.part([l.poly([Vector2(65, 13), Vector2(88, 13), Vector2(85, 19), Vector2(66, 17)])], MOUTH, 0, 0, false)
	var head := [Vector2(60, 8), Vector2(78, 8), Vector2(89, 11), Vector2(88, 14), Vector2(78, 16), Vector2(62, 18)]
	if roar:
		head = head.map(func(p: Vector2) -> Vector2: return p + Vector2(0, -2))
	l.part([l.poly(head)], skin)
	if not roar:
		for x in range(66, 88):
			l.dot(x, 14, skin.darkened(0.72))
		for x in range(68, 88, 3):
			l.dot(x, 15, Color.WHITE)
	_eye(l, 70, 8 if roar else 10, pose == "sleep")
	l.part([l.limb(Vector2(58, 17), Vector2(63, 23 - paddle), 2.2, 1.3), l.limb(Vector2(38, 17), Vector2(42, 22 + paddle), 2, 1.1)], skin)


static func _plesio(l: Layers, sp: Dictionary, frame: int, pose: String) -> void:
	var skin: Color = sp.color
	var belly: Color = sp.color2
	var paddle: float = [0, 2, 0, -2][frame]
	l.part([l.limb(Vector2(26, 23), Vector2(31, 28 - paddle), 2, 1), l.limb(Vector2(13, 23), Vector2(17, 28 + paddle), 2, 1)], skin.darkened(0.2))
	l.part([l.limb(Vector2(10, 21), Vector2(0, 24), 3.5, 1)], skin)
	l.part([l.ellipse(20, 21, 12, 7)], skin)
	l.part([l.ellipse(21, 25, 8, 2.5)], belly, 0, 1, false)
	l.part([l.limb(Vector2(28, 18), Vector2(39, 6), 3.6, 2.4)], skin)
	l.part([l.ellipse(41, 5, 4, 3), l.poly([Vector2(41, 3), Vector2(47, 6), Vector2(41, 8)])], skin)
	if pose == "roar":
		l.part([l.poly([Vector2(42, 6), Vector2(47, 7), Vector2(43, 10)])], MOUTH, 0, 0)
	else:
		for x in range(42, 47):
			l.dot(x, 6, skin.darkened(0.72))
	_eye(l, 40, 3, pose == "sleep")
	l.part([l.limb(Vector2(24, 24), Vector2(29, 29 + paddle), 2.2, 1.1), l.limb(Vector2(11, 24), Vector2(15, 29 - paddle), 2.2, 1.1)], skin)

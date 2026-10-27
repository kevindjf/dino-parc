extends RefCounted

# Dinosaurs drawn by hand, part by part (see layers.gd), seen from the side (facing right), from
# the front ("down") and from the back ("up"), with 4 walking frames, a roar and a sleep.
# Sizes are fixed in pixels, chosen so that none is smaller than the explorer (25 pixels high).
# The species not listed in SPECIES are still drawn by dino_art.gd.

const Layers := preload("res://scripts/layers.gd")

# side: canvas seen from the side; front: canvas seen from the front or the back; feet: the x of
# the middle of the feet on the side canvas, where the dinosaur stands.
# Colors not in the catalog: the frill, horns, claws.
const SPECIES := {
	"triceratops": {"side": Vector2i(52, 34), "front": Vector2i(32, 34), "feet": 24, "frill": Color("e8a040")},
	"trex": {"side": Vector2i(66, 46), "front": Vector2i(46, 46), "feet": 31},
	"velociraptor": {"side": Vector2i(40, 29), "front": Vector2i(30, 29), "feet": 18},
}
const HORN := Color("f2e8cc")
const BEAK := Color("6e6256")
const EYE := Color("1e1612")
const MOUTH := Color("7a1c1c")


static func has(id: String) -> bool:
	return SPECIES.has(id)


# pose: "walk" (frames 0 to 3), "roar" or "sleep". direction: "side", "down" or "up".
static func draw(id: String, sp: Dictionary, direction: String, frame: int, pose := "walk") -> Image:
	var info: Dictionary = SPECIES[id]
	var layers := Layers.new(info.side if direction == "side" else info.front)
	var bob := -1 if frame % 2 == 1 else 0
	match id:
		"triceratops":
			_triceratops(layers, sp, info, direction, frame, pose, bob)
		"trex":
			_trex(layers, sp, direction, frame, pose, bob)
		"velociraptor":
			_raptor(layers, sp, direction, frame, pose, bob)
	return layers.image


static func _eye(l: Layers, x: float, y: float, closed: bool) -> void:
	if closed:
		l.dot(x, y + 1, EYE)
		l.dot(x + 1, y + 1, EYE)
	else:
		l.dot(x, y, Color.WHITE)
		l.dot(x + 1, y, EYE)
		l.dot(x, y + 1, Color.WHITE)
		l.dot(x + 1, y + 1, EYE)


static func _toes(l: Layers, x: float, y: float, steps: Array) -> void:
	for dx in steps:
		l.dot(x + dx, y, HORN)


# --- Triceratops: a heavy quadruped with a frill and three horns ------------------------------

static func _triceratops(l: Layers, sp: Dictionary, info: Dictionary, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var belly: Color = skin.lightened(0.5)
	var frill: Color = info.frill
	var g := l.size.y - 1
	var lift: int = [0, 1, 0, 0][frame] if direction != "side" else 0
	var lift2: int = [0, 0, 0, 1][frame] if direction != "side" else 0
	if direction == "side":
		var sleep := pose == "sleep"
		var y := 7 if sleep else bob
		var sw: int = [0, 2, 0, -2][frame]
		if not sleep:
			l.part([_pillar(l, Vector2(18, 22 + y), 18 + sw, g), _pillar(l, Vector2(34, 22 + y), 34 - sw, g)], skin.darkened(0.2))
		l.part([l.poly([Vector2(0, 25 + y), Vector2(13, 13 + y), Vector2(17, 22 + y), Vector2(6, 25 + y)])], skin)
		l.part([l.ellipse(23, 17 + y, 14, 9)], skin)
		l.part([l.ellipse(24, 23.5 + y, 10, 2.6)], belly, 0, 1, false)
		if not sleep:
			l.part([_pillar(l, Vector2(15, 22 + y), 15 - sw, g)], skin)
		l.part([l.ellipse(34, 9 + y, 6.5, 9)], frill, 1, 1)
		for spot in [Vector2(32, 4), Vector2(31, 8), Vector2(32, 12), Vector2(34, 6), Vector2(34, 10)]:
			l.dot(spot.x, spot.y + y, frill.darkened(0.25))
		l.part([l.poly([Vector2(35, 10 + y), Vector2(42, 9 + y), Vector2(48, 14 + y), Vector2(47, 20 + y), Vector2(39, 21 + y), Vector2(35, 18 + y)])], skin)
		l.part([l.poly([Vector2(46, 13 + y), Vector2(51, 17 + y), Vector2(47, 21 + y), Vector2(45, 19 + y)])], BEAK, 0, 1)
		if pose == "roar":
			l.part([l.poly([Vector2(40, 19 + y), Vector2(48, 19 + y), Vector2(46, 24 + y), Vector2(40, 22 + y)])], MOUTH, 0, 1)
		l.part([l.limb(Vector2(40, 10 + y), Vector2(49, 3 + y), 1.5, 0.5)], HORN, 0, 1)
		l.part([l.limb(Vector2(46, 13 + y), Vector2(47, 10 + y), 1.1, 0.4)], HORN, 0, 1)
		_eye(l, 39, 12 + y, sleep)
		if pose != "roar":
			for x in range(42, 46):
				l.dot(x, 18 + y, skin.darkened(0.72))
		if not sleep:
			l.part([_pillar(l, Vector2(32, 22 + y), 32 + sw, g)], skin)
			_toes(l, 15 - sw, g - 1, [-1, 1, 3])
			_toes(l, 32 + sw, g - 1, [-1, 1, 3])
		return
	var cx := l.size.x / 2.0
	var y := bob
	if direction == "down":
		l.part([l.ellipse(cx, 20 + y, 11, 7)], skin)
		l.part([l.box(int(cx) - 10, 22 + y, 7, g - 22 - y - lift + 1)], skin)
		l.part([l.box(int(cx) + 3, 22 + y, 7, g - 22 - y - lift2 + 1)], skin)
		_toes(l, cx - 9, g - lift, [0, 2, 4])
		_toes(l, cx + 4, g - lift2, [0, 2, 4])
		l.part([l.ellipse(cx, 9 + y, 15, 8.5)], frill, 1, 1)
		for dx in [-9, -4, 0, 4, 9]:
			l.dot(cx + dx, 4 + y, frill.darkened(0.25))
		l.part([l.ellipse(cx, 15 + y, 6.5, 7.5)], skin)
		l.part([l.poly([Vector2(cx - 3, 19 + y), Vector2(cx + 3, 19 + y), Vector2(cx + 1.5, 25 + y), Vector2(cx - 1.5, 25 + y)])], BEAK, 0, 1)
		l.part([l.limb(Vector2(cx - 4, 11 + y), Vector2(cx - 7, 2 + y), 1.4, 0.5), l.limb(Vector2(cx + 4, 11 + y), Vector2(cx + 7, 2 + y), 1.4, 0.5)], HORN, 0, 1)
		l.part([l.limb(Vector2(cx, 19 + y), Vector2(cx, 16 + y), 1.1, 0.4)], HORN, 0, 1)
		if pose == "roar":
			l.part([l.ellipse(cx, 24 + y, 2.5, 1.5)], MOUTH, 0, 0)
		for x in [cx - 4, cx + 3]:
			l.dot(x, 13 + y, Color.WHITE if pose != "sleep" else skin)
			l.dot(x, 14 + y, EYE)
	else:
		l.part([l.box(int(cx) - 10, 22 + y, 7, g - 22 - y - lift + 1)], skin)
		l.part([l.box(int(cx) + 3, 22 + y, 7, g - 22 - y - lift2 + 1)], skin)
		l.part([l.ellipse(cx, 18 + y, 12, 8.5)], skin)
		l.part([l.ellipse(cx, 8 + y, 15, 8)], frill, 1, 1)
		l.part([l.ellipse(cx, 9 + y, 12, 5.5)], frill.darkened(0.25), 0, 0, false)
		l.part([l.limb(Vector2(cx, 21 + y), Vector2(cx, g - 1), 3.5, 1.6)], skin)


# A straight heavy leg from the shoulder or the hip down to a round foot on the ground.
static func _pillar(l: Layers, top: Vector2, foot_x: float, ground: int) -> PackedByteArray:
	var leg := l.limb(top, Vector2(foot_x, ground - 3), 3.4, 2.9)
	var foot := l.ellipse(foot_x + 0.5, ground - 1.2, 4.0, 1.8)
	for i in leg.size():
		leg[i] = leg[i] | foot[i]
	return leg


# --- T-Rex: a huge head, tiny arms, strong legs -----------------------------------------------

static func _trex(l: Layers, sp: Dictionary, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var stripes: Color = sp.color2
	var belly: Color = skin.lightened(0.45)
	var g := l.size.y - 1
	var roar := pose == "roar"
	var sleep := pose == "sleep"
	if direction == "side":
		var y := 9 if sleep else bob
		var sw: int = [0, 4, 0, -4][frame]
		if not sleep:
			_trex_leg(l, Vector2(31, 28 + y), 31 + sw, g, skin.darkened(0.2))
		l.part([l.limb(Vector2(26, 22 + y), Vector2(1, 15 + y), 8, 1.2)], skin)
		l.part([l.ellipse(31, 23 + y, 13, 10)], skin)
		l.part([l.ellipse(35, 29 + y, 9, 3.5)], belly, 0, 1, false)
		for x in [20, 25, 30, 12]:
			l.part([l.limb(Vector2(x, 14 + y + (2 if x < 16 else 0)), Vector2(x - 2, 19 + y), 1.0, 0.5)], stripes, 0, 0, false)
		l.part([l.limb(Vector2(38, 18 + y), Vector2(44, 12 + y), 6, 5)], skin)
		if roar:
			l.part([l.poly([Vector2(44, 17 + y), Vector2(61, 21 + y), Vector2(58, 27 + y), Vector2(46, 24 + y)])], skin.darkened(0.12))
			l.part([l.poly([Vector2(45, 16 + y), Vector2(62, 15 + y), Vector2(59, 22 + y), Vector2(46, 21 + y)])], MOUTH, 0, 0, false)
			for x in [48, 52, 56]:
				l.dot(x, 22 + y, Color.WHITE)
		var head := [Vector2(40, 7 + y), Vector2(55, 5 + y), Vector2(64, 9 + y), Vector2(64, 15 + y), Vector2(56, 17 + y), Vector2(44, 19 + y), Vector2(39, 14 + y)]
		if roar:
			for i in head.size():
				head[i] += Vector2(0, -2)
		l.part([l.poly(head)], skin)
		if not roar:
			l.part([l.poly([Vector2(44, 16 + y), Vector2(62, 15 + y), Vector2(60, 20 + y), Vector2(46, 21 + y)])], skin.darkened(0.08))
			for x in range(46, 62):
				l.dot(x, 16 + y, skin.darkened(0.72))
			for x in [48, 52, 56, 60]:
				l.dot(x, 17 + y, Color.WHITE)
		var up := -2 if roar else 0
		l.part([l.limb(Vector2(46, 8 + y + up), Vector2(52, 7 + y + up), 1.2, 1.0)], skin.darkened(0.25), 0, 0, false)
		_eye(l, 49, 9 + y + up, sleep)
		l.dot(62, 9 + y + up, skin.darkened(0.6))
		l.part([l.limb(Vector2(42, 25 + y), Vector2(46, 29 + y), 1.6, 1.1)], skin)
		l.dot(47, 30 + y, HORN)
		if not sleep:
			_trex_leg(l, Vector2(28, 28 + y), 28 - sw, g, skin)
		return
	# From the front and the back, the head is turned a little to the right (three-quarters), so
	# the long snout full of teeth shows; the tail sticks out on the left.
	var cx := l.size.x / 2.0
	var y := bob
	var lift: int = [0, 2, 0, 0][frame]
	var lift2: int = [0, 0, 0, 2][frame]
	var dark := skin.darkened(0.72)
	var front := direction == "down"
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
	# Tiny arms with two claws.
	for x in [-6, 6]:
		l.part([l.limb(Vector2(cx + x, 24 + y), Vector2(cx + x + 2, 28 + y), 1.6, 1.1)], skin)
		l.dot(cx + x + 2, 29 + y, HORN)
		l.dot(cx + x + 3, 29 + y, HORN)
	l.part([l.ellipse(cx, 18 + y, 7, 6)], skin)
	var open := 4 if roar else 0
	if front:
		# The lower jaw, then the head with its long snout.
		l.part([l.poly([Vector2(cx - 5, 15 + y), Vector2(cx + 15, 16 + y + open), Vector2(cx + 13, 21 + y + open), Vector2(cx - 3, 21 + y)])], skin.darkened(0.1))
		if roar:
			l.part([l.poly([Vector2(cx - 3, 15 + y), Vector2(cx + 15, 14 + y), Vector2(cx + 14, 17 + y + open), Vector2(cx - 2, 18 + y)])], MOUTH, 0, 0, false)
		l.part([l.ellipse(cx - 1, 10 + y, 9, 7.5), l.poly([Vector2(cx - 2, 5 + y), Vector2(cx + 13, 9 + y), Vector2(cx + 16, 13 + y), Vector2(cx + 15, 16 + y), Vector2(cx - 5, 16 + y)])], skin)
		for x in range(-4, 16):
			l.dot(cx + x, 16 + y, dark)
		for x in [-1, 3, 7, 11]:
			l.dot(cx + x, 17 + y + (open if roar else 0), Color.WHITE)
			l.dot(cx + x + 1, 15 + y, Color.WHITE)
		# Brow ridge and eyes: the near one big, the far one just a dot.
		l.part([l.limb(Vector2(cx, 6 + y), Vector2(cx + 5, 6 + y), 1.1, 0.9)], skin.darkened(0.25), 0, 0, false)
		_eye(l, cx + 2, 7 + y, sleep)
		l.dot(cx - 7, 8 + y, EYE)
		l.dot(cx + 14, 10 + y, skin.darkened(0.6))
	else:
		l.part([l.poly([Vector2(cx + 4, 7 + y), Vector2(cx + 15, 10 + y), Vector2(cx + 15, 15 + y), Vector2(cx + 4, 16 + y)])], skin.darkened(0.08))
		l.part([l.ellipse(cx - 1, 10 + y, 9, 7.5)], skin)
		for x in [-5, -1, 3]:
			l.part([l.limb(Vector2(cx + x, 5 + y), Vector2(cx + x + 1, 8 + y), 0.6, 0.5)], stripes, 0, 0, false)


static func _trex_leg(l: Layers, hip: Vector2, foot_x: float, g: int, color: Color) -> void:
	l.part([l.ellipse(hip.x, hip.y, 6, 7.5), l.limb(hip + Vector2(1, 4), Vector2(foot_x, g - 2), 3.4, 2.2), l.ellipse(foot_x + 2, g - 1, 4.5, 1.8)], color)
	_toes(l, foot_x + 2, g, [1, 3, 5])


# --- Velociraptor: small, fast, feathered, with a long stiff tail -----------------------------

static func _raptor(l: Layers, sp: Dictionary, direction: String, frame: int, pose: String, bob: int) -> void:
	var skin: Color = sp.color
	var stripes: Color = sp.color2
	var belly: Color = skin.lightened(0.45)
	var g := l.size.y - 1
	var sleep := pose == "sleep"
	var roar := pose == "roar"
	if direction == "side":
		var y := 6 if sleep else bob
		var sw: int = [0, 3, 0, -3][frame]
		if not sleep:
			_raptor_leg(l, Vector2(18, 16 + y), 18 + sw, g, skin.darkened(0.2))
		l.part([l.limb(Vector2(14, 13 + y), Vector2(0, 8 + y), 3.5, 1)], skin)
		for x in [2, 5, 8]:
			l.dot(x, 8 + y + x / 4, stripes)
		l.part([l.ellipse(18, 14 + y, 8, 5.5)], skin)
		l.part([l.ellipse(19, 17 + y, 5, 2)], belly, 0, 1, false)
		for x in [14, 17, 20]:
			l.part([l.limb(Vector2(x, 9 + y), Vector2(x - 1, 12 + y), 0.8, 0.5)], stripes, 0, 0, false)
		l.part([l.limb(Vector2(22, 12 + y), Vector2(27, 7 + y), 3.2, 2.6)], skin)
		l.part([l.poly([Vector2(24, 3 + y), Vector2(33, 3 + y), Vector2(39, 7 + y), Vector2(37, 10 + y), Vector2(28, 11 + y), Vector2(24, 8 + y)])], skin)
		# A little crest of feathers on the head.
		l.part([l.poly([Vector2(23, 4 + y), Vector2(27, 1 + y), Vector2(28, 4 + y)])], stripes, 0, 0)
		if roar:
			l.part([l.poly([Vector2(29, 8 + y), Vector2(38, 9 + y), Vector2(36, 13 + y), Vector2(29, 11 + y)])], MOUTH, 0, 0)
			l.dot(32, 9 + y, Color.WHITE)
			l.dot(35, 9 + y, Color.WHITE)
		else:
			for x in range(30, 37):
				l.dot(x, 8 + y, skin.darkened(0.72))
		_eye(l, 30, 4 + y, sleep)
		l.part([l.limb(Vector2(22, 15 + y), Vector2(26, 18 + y), 1.4, 1)], skin)
		l.dot(27, 19 + y, HORN)
		if not sleep:
			_raptor_leg(l, Vector2(16, 16 + y), 16 - sw, g, skin)
		return
	# From the front and the back: the head turned a little to the right, with its long snout, and
	# the stiff tail held up on the left.
	var cx := l.size.x / 2.0
	var y := bob
	var lift: int = [0, 1, 0, 0][frame]
	var lift2: int = [0, 0, 0, 1][frame]
	var front := direction == "down"
	l.part([l.limb(Vector2(cx - 2, 16 + y), Vector2(cx - 13, 9 + y), 2.6, 0.9)], skin.darkened(0.1))
	for x in [-11, -8, -5]:
		l.dot(cx + x, 10 + y - x / 4, stripes)
	for side in [-1, 1]:
		var foot_y: int = g - (lift if side < 0 else lift2)
		l.part([l.ellipse(cx + side * 3.5, 18 + y, 3, 4), l.limb(Vector2(cx + side * 3.5, 20 + y), Vector2(cx + side * 3.5, foot_y - 1), 1.8, 1.4), l.ellipse(cx + side * 3.5, foot_y - 0.5, 2.5, 1.2)], skin)
		if front:
			l.dot(cx + side * 3.5 - 1, foot_y, HORN)
			l.dot(cx + side * 3.5 + 1, foot_y, HORN)
			# The big sickle claw, raised.
			l.dot(cx + side * 3.5 + side * 2, foot_y - 2, HORN)
	l.part([l.ellipse(cx, 15 + y, 6, 5)], skin)
	if front:
		l.part([l.ellipse(cx + 1, 17 + y, 3.5, 2.5)], belly, 0, 1, false)
	for row in [12, 15]:
		l.part([l.limb(Vector2(cx - 4, row + y), Vector2(cx - 2, row + y + 1), 0.6, 0.5)], stripes, 0, 0, false)
	for x in [-5, 5]:
		l.part([l.limb(Vector2(cx + x, 14 + y), Vector2(cx + x + 1, 18 + y), 1.2, 0.9)], skin)
		l.dot(cx + x + 1, 19 + y, HORN)
	l.part([l.limb(Vector2(cx, 12 + y), Vector2(cx + 1, 8 + y), 2.6, 2.4)], skin)
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
	# A little crest of feathers on the head.
	l.part([l.poly([Vector2(cx - 4, 3 + y), Vector2(cx - 2, 0), Vector2(cx + 1, 2 + y)])], stripes, 0, 0)


static func _raptor_leg(l: Layers, hip: Vector2, foot_x: float, g: int, color: Color) -> void:
	l.part([l.ellipse(hip.x, hip.y, 3.5, 4.5), l.limb(hip + Vector2(1, 3), Vector2(foot_x, g - 1), 2, 1.3), l.ellipse(foot_x + 1.5, g - 0.5, 2.8, 1.2)], color)
	# The big sickle claw.
	l.dot(foot_x + 1, g - 2, HORN)
	l.dot(foot_x + 3, g, HORN)

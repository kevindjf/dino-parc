extends RefCounted

# Pixel sprites for every species, drawn from its catalog entry. Land dinosaurs and swimmers are
# seen from the side, facing right; flyers are seen from the front with their wings spread.
# Units: y goes down, the ground is at y = 0 (flyers and swimmers are centered on their body).
# Each species gets two walking frames, a roaring frame and a sleeping frame, sized from its real
# length (one cell = 16 pixels = 3 m).

const Painter := preload("res://scripts/painter.gd")
const Catalog := preload("res://scripts/catalog.gd")
const Hand := preload("res://scripts/dino_hand.gd")
const T := 16
const METERS_PER_CELL := 3.0
const HORN := Color("fff1d0")
const MOUTH := Color("7a1c1c")
const EYE := Color("181818")
const POSES := [{"step": 0}, {"step": 1}, {"step": 0, "roar": true}, {"sleep": true}]

static var _cache := {}


# Real length in meters -> length in cells. Giants are squeezed a little so they still fit in a park.
static func target_length(meters: float) -> float:
	var cells := meters / METERS_PER_CELL
	return cells if cells <= 4.0 else 4.0 + (cells - 4.0) * 0.6


# Returns {walk: [Texture2D, ...], roar, sleep, origin: pixel of the feet, size, height}.
# Hand-drawn species (dino_hand.gd) also have "down" and "up" (4 frames each) and front_origin.
static func frames(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var sp: Dictionary = Catalog.DINOS[id]
	if Hand.has(id):
		_cache[id] = _hand_frames(id, sp)
		return _cache[id]
	var painter := Painter.new()
	painter.measure()
	for pose in POSES:
		_draw(painter, sp, pose)
	var bounds := painter.bounds
	var length := maxf(target_length(sp.length) * T, 10.0)
	var scale := length / bounds.size.x
	# Long-necked dinosaurs would otherwise tower over the park: keep them lower than they are long.
	if sp.habitat == "land":
		scale = minf(scale, length * 0.75 / -bounds.position.y)
	var size := Vector2i((bounds.size * scale).ceil()) + Vector2i(4, 4)
	var origin := (-bounds.position * scale + Vector2(2, 2)).floor()
	var textures: Array[Texture2D] = []
	for pose in POSES:
		painter.start(size, scale, origin)
		_draw(painter, sp, pose)
		textures.append(_scales(painter.finish()))
	var result := {
		"walk": [textures[0], textures[1]], "roar": textures[2], "sleep": textures[3],
		"origin": origin, "size": size, "height": origin.y,
	}
	_cache[id] = result
	return result


static func _hand_frames(id: String, sp: Dictionary) -> Dictionary:
	var tex := func(direction: String, frame: int, pose := "walk") -> Texture2D:
		return ImageTexture.create_from_image(Hand.draw(id, sp, direction, frame, pose))
	var info: Dictionary = Hand.SPECIES[id]
	var result := {
		"walk": [], "down": [], "up": [],
		"roar": tex.call("side", 0, "roar"), "sleep": tex.call("side", 0, "sleep"),
		"origin": Vector2(info.feet, info.side.y), "size": info.side, "height": info.side.y,
		"front_origin": Vector2(info.front.x / 2, info.front.y),
	}
	for frame in 4:
		for direction in ["side", "down", "up"]:
			result["walk" if direction == "side" else direction].append(tex.call(direction, frame))
	return result


# Little scales all over the skin: a few darker and lighter pixels in a regular pattern, so the
# dinosaurs look hand drawn like the rest of the world. The outline, eyes and teeth are kept.
static func _scales(texture: ImageTexture) -> ImageTexture:
	var image := texture.get_image()
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5 or c.get_luminance() < 0.15 or c.get_luminance() > 0.9 or c.s < 0.12:
				continue
			if (x * 7 + y * 13) % 11 == 0:
				image.set_pixel(x, y, c.darkened(0.16))
			elif (x * 5 + y * 3) % 17 == 0:
				image.set_pixel(x, y, c.lightened(0.12))
	return ImageTexture.create_from_image(image)


static func _draw(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	match sp.plan:
		"quad":
			_quad(p, sp, pose)
		"sauropod":
			_sauropod(p, sp, pose)
		"flyer":
			_flyer(p, sp, pose)
		"mosasaur":
			_mosasaur(p, sp, pose)
		"plesio":
			_plesio(p, sp, pose)
		_:
			_biped(p, sp, pose)


static func _v2(v) -> Vector2:
	return Vector2(v.x, v.y)


# --- Shared pieces ----------------------------------------------------------

static func _eye(p: Painter, at: Vector2, head_height: float, closed: bool) -> void:
	var size := clampi(int(round(head_height * p.scale * 0.2)), 1, 3)
	if closed:
		p.line(at - Vector2(size * 0.6, 0) / p.scale, at + Vector2(size * 0.6, 0) / p.scale, EYE)
	elif size == 1:
		p.dot(at, EYE)
	else:
		p.dot(at, Color.WHITE, size)
		p.dot(at + Vector2(0.5, 0.5) / p.scale, EYE, size - 1)


# A head facing right, centered on `at`, with an open jaw when roaring.
static func _head(p: Painter, at: Vector2, size: Vector2, color: Color, carnivore: bool, pose: Dictionary) -> void:
	var roar: bool = pose.get("roar", false)
	var back := at - Vector2(size.x * 0.22, 0)
	var snout := at + Vector2(size.x * 0.24, size.y * 0.04)
	if roar:
		var jaw_to := at + Vector2(size.x * 0.45, size.y * 0.7)
		p.polygon(PackedVector2Array([at + Vector2(-size.x * 0.2, size.y * 0.05), at + Vector2(size.x * 0.55, -size.y * 0.05), jaw_to]), MOUTH)
		p.limb(at + Vector2(-size.x * 0.18, size.y * 0.22), jaw_to, size.y * 0.2, size.y * 0.12, color.darkened(0.12), true)
		snout.y -= size.y * 0.14
	p.limb(back, snout, size.y * 0.5, size.y * 0.34, color)
	if roar and carnivore:
		for i in 3:
			p.dot(at + Vector2(size.x * (0.05 + 0.16 * i), size.y * 0.26), Color.WHITE)
	elif not roar:
		p.line(at + Vector2(size.x * 0.02, size.y * 0.24), at + Vector2(size.x * 0.48, size.y * 0.2), color.darkened(0.55))
	_eye(p, at + Vector2(size.x * 0.02, -size.y * 0.16), size.y, pose.get("sleep", false))


# A two-part leg from the hip to a foot on the ground at x = foot_x.
static func _leg(p: Painter, hip: Vector2, foot_x: float, length: float, thick: float, color: Color, outlined: bool) -> void:
	var foot := Vector2(foot_x, 0)
	var knee := Vector2((hip.x + foot.x) / 2.0 + length * 0.14, hip.y + (foot.y - hip.y) * 0.45)
	var ankle := Vector2(foot.x - length * 0.06, -length * 0.14)
	p.limb(hip, knee, thick * 0.36, thick * 0.2, color, outlined)
	p.limb(knee, ankle, thick * 0.18, thick * 0.13, color, outlined)
	p.limb(ankle, foot + Vector2(length * 0.2, -0.01), thick * 0.13, thick * 0.08, color, outlined)


# A straight column leg for heavy quadrupeds.
static func _pillar(p: Painter, top: Vector2, foot_x: float, width: float, color: Color, outlined: bool) -> void:
	p.limb(top, Vector2(foot_x, -width * 0.45), width * 0.55, width * 0.45, color, outlined)
	p.ellipse(Vector2(foot_x + width * 0.08, -width * 0.25), Vector2(width * 0.55, width * 0.28), color, outlined)


# --- Bipeds -----------------------------------------------------------------

static func _biped(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	var s: Dictionary = sp.get("shape", {})
	var features: Array = sp.get("features", [])
	var c: Color = sp.color
	var c2: Color = sp.color2
	var far := c.darkened(0.22)
	var leg: float = s.get("leg", 0.55)
	var body := _v2(s.get("body", Vector3(0.8, 0.55, 0.5)))
	var head := _v2(s.get("head", Vector3(0.55, 0.32, 0.4)))
	var neck: float = s.get("neck", 0.0)
	var tail: float = s.get("tail", 1.0)
	var tilt := deg_to_rad(s.get("tilt", 15.0))
	var arm: float = s.get("arm", 0.22)
	var sleeping: bool = pose.get("sleep", false)
	var roar: bool = pose.get("roar", false)
	var step := leg * (0.16 if pose.get("step", 0) == 0 else -0.16)
	var stand := body.y * 0.12 if sleeping else leg
	if sleeping:
		tilt = 0.0

	var center := Vector2(0, -(stand + body.y * 0.35))
	var hip := center + Vector2(-body.x * 0.08, body.y * 0.12)
	var shoulder := center + Vector2(body.x * 0.36, -body.y * 0.2 - sin(tilt) * body.x * 0.3)
	var head_pos := shoulder + Vector2(head.x * 0.4 + neck * 0.4, -(head.y * 0.25 + neck))
	if sleeping:
		head_pos = Vector2(shoulder.x + head.x * 0.55, -head.y * 0.5)
	var arm_root := center + Vector2(body.x * 0.36, body.y * 0.05)

	if not sleeping:
		_leg(p, hip, hip.x - step, leg, body.y, far, false)
	p.limb(arm_root, arm_root + Vector2(arm * 0.75, arm * 0.55), body.y * 0.1, body.y * 0.07, far)
	if "sail" in features:
		var base_y := center.y - body.y * 0.3
		p.polygon(PackedVector2Array([
			Vector2(-body.x * 0.45, base_y), Vector2(-body.x * 0.3, base_y - body.y * 0.75),
			Vector2(0, base_y - body.y * 1.2), Vector2(body.x * 0.3, base_y - body.y * 0.8),
			Vector2(body.x * 0.45, base_y)]), c2, true)
	if "frill" in features and roar:
		p.ellipse(head_pos + Vector2(-head.x * 0.3, 0), Vector2(head.y * 0.5, head.y * 1.1), c2, true)
	var tail_root := center + Vector2(-body.x * 0.38, 0)
	var tail_end := tail_root + Vector2(-tail, body.y * 0.3)
	tail_end.y = minf(tail_end.y, -0.03)
	p.limb(tail_root, tail_end, body.y * 0.36, body.y * 0.05, c)
	p.ellipse(center, body / 2.0, c, false, -tilt)
	p.limb(shoulder, head_pos, body.y * 0.25, head.y * 0.32, c)
	_head(p, head_pos, head, c, sp.diet == "carn", pose)

	for feature in features:
		match feature:
			"crest_tube":
				p.limb(head_pos + Vector2(-head.x * 0.05, -head.y * 0.3), head_pos + Vector2(-head.x * 1.1, -head.y * 1.1), head.y * 0.2, head.y * 0.17, c2, true)
			"dome":
				p.ellipse(head_pos + Vector2(-head.x * 0.12, -head.y * 0.32), Vector2(head.x * 0.36, head.y * 0.42), c2, true)
			"horns":
				p.polygon(PackedVector2Array([head_pos + Vector2(-head.x * 0.15, -head.y * 0.35),
					head_pos + Vector2(0.0, -head.y * 0.95), head_pos + Vector2(head.x * 0.1, -head.y * 0.35)]), c2, true)
			"double_crest":
				p.limb(head_pos + Vector2(-head.x * 0.2, -head.y * 0.45), head_pos + Vector2(head.x * 0.3, -head.y * 0.5), head.y * 0.22, head.y * 0.1, c2, true)
			"feathers":
				p.ellipse(head_pos + Vector2(-head.x * 0.25, -head.y * 0.4), Vector2(head.y * 0.3, head.y * 0.22), c2)
				for i in 3:
					p.ellipse(center + Vector2(-body.x * 0.3 + i * body.x * 0.25, -body.y * 0.42), Vector2(body.x * 0.12, body.y * 0.12), c2)
				p.ellipse(tail_end + Vector2(tail * 0.08, 0), Vector2(tail * 0.12, body.y * 0.1), c2)
			"stripes":
				for i in 3:
					var x := -body.x * 0.25 + i * body.x * 0.2
					p.limb(center + Vector2(x, -body.y * 0.42), center + Vector2(x - body.x * 0.05, -body.y * 0.05), body.y * 0.05, body.y * 0.03, c2)

	p.limb(arm_root, arm_root + Vector2(arm * 0.85, arm * 0.5), body.y * 0.11, body.y * 0.07, c, true)
	if sleeping:
		p.ellipse(hip + Vector2(body.x * 0.05, body.y * 0.1), Vector2(body.x * 0.22, body.y * 0.3), c, true)
	else:
		_leg(p, hip + Vector2(body.x * 0.04, 0), hip.x + step, leg, body.y, c, true)


# --- Quadrupeds ---------------------------------------------------------------

static func _quad(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	var s: Dictionary = sp.get("shape", {})
	var features: Array = sp.get("features", [])
	var c: Color = sp.color
	var c2: Color = sp.color2
	var far := c.darkened(0.22)
	var leg: float = s.get("leg", 0.32)
	var body := _v2(s.get("body", Vector3(1.0, 0.5, 0.62)))
	var head := _v2(s.get("head", Vector3(0.42, 0.32, 0.36)))
	var tail: float = s.get("tail", 0.6)
	var head_up: float = s.get("head_up", 0.0)
	var sleeping: bool = pose.get("sleep", false)
	var step := leg * (0.25 if pose.get("step", 0) == 0 else -0.25)
	var stand := 0.02 if sleeping else leg
	var center := Vector2(0, -(stand + body.y * 0.5))
	var head_pos := center + Vector2(body.x * 0.5 + head.x * 0.3, -head_up)
	if sleeping:
		head_pos.y = maxf(head_pos.y, -head.y * 0.5)
	var width := maxf(body.y * 0.42, 0.14)
	var front := body.x * 0.3
	var back := -body.x * 0.3
	var leg_top := center.y + body.y * 0.1

	if not sleeping:
		_pillar(p, Vector2(back + width * 0.2, leg_top), back - step, width, far, false)
		_pillar(p, Vector2(front + width * 0.2, leg_top), front + step, width, far, false)
	if "plates" in features:
		for i in 6:
			var x := lerpf(-body.x * 0.42, body.x * 0.3, i / 5.0)
			var size := body.y * (0.35 + 0.35 * sin(PI * i / 5.0))
			var top := center.y - body.y * 0.42
			p.polygon(PackedVector2Array([Vector2(x - size * 0.5, top + size * 0.3), Vector2(x, top - size),
				Vector2(x + size * 0.5, top + size * 0.3)]), c2 if i % 2 == 0 else c2.darkened(0.15), true)
	var tail_root := center + Vector2(-body.x * 0.42, -body.y * 0.05)
	var tail_end := tail_root + Vector2(-tail, body.y * 0.25)
	tail_end.y = minf(tail_end.y, -0.04)
	p.limb(tail_root, tail_end, body.y * 0.3, body.y * 0.07, c)
	if "frill" in features:
		p.ellipse(head_pos + Vector2(-head.x * 0.45, -head.y * 0.45), Vector2(head.x * 0.3, head.y * 0.95), c2, true, -0.35)
	p.ellipse(center, body / 2.0, c)
	p.ellipse(head_pos + Vector2(head.x * 0.38, head.y * 0.12), Vector2(head.x * 0.18, head.y * 0.24), c.darkened(0.3))
	_head(p, head_pos, head, c, false, pose)

	for feature in features:
		match feature:
			"three_horns":
				p.limb(head_pos + Vector2(-head.x * 0.05, -head.y * 0.3), head_pos + Vector2(head.x * 0.7, -head.y * 1.1), head.y * 0.14, 0.01, HORN, true)
				p.limb(head_pos + Vector2(head.x * 0.4, -head.y * 0.15), head_pos + Vector2(head.x * 0.55, -head.y * 0.55), head.y * 0.1, 0.01, HORN, true)
			"nose_boss":
				p.ellipse(head_pos + Vector2(head.x * 0.25, -head.y * 0.42), Vector2(head.x * 0.2, head.y * 0.17), c2, true)
				p.limb(head_pos + Vector2(-head.x * 0.55, -head.y * 1.0), head_pos + Vector2(-head.x * 0.4, -head.y * 1.5), 0.04, 0.01, HORN, true)
			"armor":
				for i in 4:
					for j in 2:
						p.ellipse(center + Vector2(-body.x * 0.33 + i * body.x * 0.22 + j * body.x * 0.1, -body.y * (0.36 - j * 0.22)),
							Vector2(body.x * 0.05, body.y * 0.07), c2)
				for i in 4:
					var x := -body.x * 0.33 + i * body.x * 0.22
					p.polygon(PackedVector2Array([Vector2(x - 0.05, center.y + body.y * 0.25), Vector2(x, center.y + body.y * 0.48),
						Vector2(x + 0.05, center.y + body.y * 0.25)]), HORN, true)
			"club":
				p.ellipse(tail_end + Vector2(-0.04, 0), Vector2(body.y * 0.28, body.y * 0.22), c2, true)
			"tail_spikes":
				for dx in [0.0, 0.14]:
					p.limb(tail_end + Vector2(dx + 0.06, 0), tail_end + Vector2(dx - 0.08, -body.y * 0.55), 0.035, 0.01, HORN, true)

	if not sleeping:
		_pillar(p, Vector2(back, leg_top), back + step, width, c, true)
		_pillar(p, Vector2(front, leg_top), front - step, width, c, true)


# --- Long-necked giants -------------------------------------------------------

static func _sauropod(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	var s: Dictionary = sp.get("shape", {})
	var c: Color = sp.color
	var c2: Color = sp.color2
	var far := c.darkened(0.22)
	var sleeping: bool = pose.get("sleep", false)
	var leg: float = s.get("leg", 0.48)
	var leg_front: float = s.get("leg_front", leg)
	var body := _v2(s.get("body", Vector3(1.0, 0.55, 0.6)))
	var neck_len: float = s.get("neck_len", 1.0)
	var neck_angle := deg_to_rad(s.get("neck_angle", 35.0))
	var head := _v2(s.get("head", Vector3(0.36, 0.2, 0.24)))
	var tail: float = s.get("tail", 1.3)
	var step := leg * (0.18 if pose.get("step", 0) == 0 else -0.18)
	if sleeping:
		leg = 0.02
		leg_front = 0.02
		neck_angle = deg_to_rad(78.0)

	var center := Vector2(0, -((leg + leg_front) / 2.0 + body.y * 0.45))
	var tilt := atan2(leg_front - leg, body.x * 0.6)
	var width := body.y * 0.36
	var back := -body.x * 0.3
	var front := body.x * 0.3
	var back_top := Vector2(back, -leg - body.y * 0.1)
	var front_top := Vector2(front, -leg_front - body.y * 0.1)
	var shoulder := center + Vector2(body.x * 0.4, -body.y * 0.25 - (leg_front - leg) * 0.4)
	var neck_end := shoulder + Vector2(sin(neck_angle), -cos(neck_angle)) * neck_len
	var head_pos := neck_end + Vector2(head.x * 0.3, 0)
	if sleeping:
		head_pos.y = -head.y * 0.5

	if not sleeping:
		_pillar(p, back_top + Vector2(width * 0.3, 0), back - step, width, far, false)
		_pillar(p, front_top + Vector2(width * 0.3, 0), front + step, width, far, false)
	var tail_root := center + Vector2(-body.x * 0.42, 0)
	var tail_mid := tail_root + Vector2(-tail * 0.5, body.y * 0.25)
	var tail_end := tail_mid + Vector2(-tail * 0.5, body.y * 0.2)
	tail_end.y = minf(tail_end.y, -0.04)
	p.limb(tail_root, tail_mid, body.y * 0.3, body.y * 0.14, c)
	p.limb(tail_mid, tail_end, body.y * 0.14, 0.015, c)
	p.limb(shoulder, neck_end, body.y * 0.26, head.y * 0.32, c)
	p.ellipse(center, body / 2.0, c, false, -tilt)
	for spot in [Vector2(-0.25, -0.3), Vector2(0.05, -0.36), Vector2(0.25, -0.22), Vector2(-0.05, -0.1)]:
		p.ellipse(center + spot * body, Vector2(body.x * 0.07, body.y * 0.08), c2)
	_head(p, head_pos, head, c, false, pose)
	if not sleeping:
		_pillar(p, back_top, back + step, width, c, true)
		_pillar(p, front_top, front - step, width, c, true)


# --- Flyers (front view, wings spread) ----------------------------------------------

static func _flyer(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	var s: Dictionary = sp.get("shape", {})
	var features: Array = sp.get("features", [])
	var c: Color = sp.color
	var c2: Color = sp.color2
	var beak: float = s.get("beak", 0.3)
	var up: bool = pose.get("step", 0) == 0
	var wing := c2.darkened(0.12)
	for side in [-1.0, 1.0]:
		var tip := Vector2(side * 0.5, -0.28 if up else 0.18)
		var elbow := Vector2(side * 0.24, -0.12 if up else 0.02)
		p.polygon(PackedVector2Array([Vector2(side * 0.05, -0.08), elbow, tip,
			Vector2(side * 0.3, 0.08 if up else 0.14), Vector2(side * 0.06, 0.1)]), wing, true)
		p.limb(Vector2(side * 0.05, -0.08), elbow, 0.025, 0.02, c)
		p.limb(elbow, tip, 0.02, 0.008, c)
	p.limb(Vector2(-0.03, 0.12), Vector2(-0.05, 0.22), 0.015, 0.01, c.darkened(0.2))
	p.limb(Vector2(0.03, 0.12), Vector2(0.05, 0.22), 0.015, 0.01, c.darkened(0.2))
	p.ellipse(Vector2(0, 0.02), Vector2(0.07, 0.13), c)
	var head_pos := Vector2(0.01, -0.15)
	for feature in features:
		match feature:
			"crest":
				p.limb(head_pos, head_pos + Vector2(-0.2, -0.12), 0.035, 0.012, c2, true)
			"sail_crest":
				p.polygon(PackedVector2Array([head_pos + Vector2(-0.05, -0.02), head_pos + Vector2(-0.08, -0.22),
					head_pos + Vector2(0.06, -0.2), head_pos + Vector2(0.04, -0.02)]), c2, true)
	var open := 0.035 if pose.get("roar", false) else 0.0
	p.limb(head_pos + Vector2(0.03, -0.005 - open), head_pos + Vector2(0.06 + beak, -open), 0.03, 0.006, Color("ffcc80"))
	p.limb(head_pos + Vector2(0.03, 0.01 + open), head_pos + Vector2(0.03 + beak * 0.9, 0.015 + open), 0.02, 0.005, Color("f0b060"))
	p.ellipse(head_pos, Vector2(0.06, 0.05), c)
	_eye(p, head_pos + Vector2(0.02, -0.01), 0.1, false)


# --- Swimmers ----------------------------------------------------------------

static func _mosasaur(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	var c: Color = sp.color
	var c2: Color = sp.color2
	var wave := 0.06 if pose.get("step", 0) == 0 else -0.06
	for x in [-0.35, 0.3]:
		p.polygon(PackedVector2Array([Vector2(x - 0.12, 0.08), Vector2(x - 0.22, 0.24 + wave), Vector2(x + 0.06, 0.1)]), c.darkened(0.3))
	p.limb(Vector2(-0.5, 0), Vector2(-1.0, wave), 0.15, 0.05, c)
	p.polygon(PackedVector2Array([Vector2(-0.95, wave), Vector2(-1.18, wave - 0.24), Vector2(-1.1, wave), Vector2(-1.2, wave + 0.16)]), c2.darkened(0.2), true)
	p.ellipse(Vector2(0, 0), Vector2(0.6, 0.17), c)
	p.ellipse(Vector2(0.05, 0.09), Vector2(0.5, 0.06), c2)
	_head(p, Vector2(0.72, -0.02), Vector2(0.55, 0.22), c, true, pose)
	for x in [-0.25, 0.2]:
		p.polygon(PackedVector2Array([Vector2(x - 0.1, 0.06), Vector2(x - 0.2, 0.26 - wave), Vector2(x + 0.08, 0.08)]), c.darkened(0.1), true)


static func _plesio(p: Painter, sp: Dictionary, pose: Dictionary) -> void:
	var c: Color = sp.color
	var c2: Color = sp.color2
	var wave := 0.05 if pose.get("step", 0) == 0 else -0.05
	p.polygon(PackedVector2Array([Vector2(-0.25, 0.08), Vector2(-0.45, 0.28 + wave), Vector2(-0.1, 0.1)]), c.darkened(0.3))
	p.limb(Vector2(-0.3, 0), Vector2(-0.75, 0.06), 0.14, 0.02, c)
	p.limb(Vector2(0.3, -0.05), Vector2(0.8, -0.85), 0.1, 0.06, c)
	p.ellipse(Vector2(0, 0), Vector2(0.45, 0.19), c)
	p.ellipse(Vector2(0.03, 0.1), Vector2(0.38, 0.07), c2)
	_head(p, Vector2(0.9, -0.88), Vector2(0.3, 0.13), c, true, pose)
	p.polygon(PackedVector2Array([Vector2(0.15, 0.08), Vector2(0.0, 0.3 - wave), Vector2(0.3, 0.1)]), c.darkened(0.1), true)

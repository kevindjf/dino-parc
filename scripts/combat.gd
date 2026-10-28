extends Node2D

# Shooting, catching and feeding in the adventure. Picks the wild dinosaur being aimed at (the
# one touched on the screen or clicked, otherwise the nearest one in front of the player), shows a target over it with its energy bar, and, with a capsule
# in hand, a coloured dot telling the chance of catching it: green, orange or red.
# Pebbles, arrows, darts, bolas and capsules fly through the air and always reach their target.

const Art := preload("res://scripts/art.gd")
const Items := preload("res://scripts/items.gd")
const T := 16
const WOBBLES := 3  # a caught dinosaur shakes the capsule three times before giving up

var park: Node2D
var weapon := ""  # what the player holds, when it can be shot or thrown
var target: Node2D = null
var chosen: Node2D = null  # touched or clicked: stays the target while it is in reach
var time := 0.0
var ready_at := 0.0
var hint_at := 0.0


func setup(owner_park: Node2D) -> void:
	park = owner_park
	z_index = 50


func _process(delta: float) -> void:
	time += delta
	var holding: String = park.inventory.current()
	var usable: bool = park.away == null and park.player.mount == null and (park.player.vehicle == "" or Items.sails(park.player.vehicle)) and not park.builder.active
	weapon = holding if usable and Items.WEAPONS.has(holding) else ""
	if chosen != null and not (weapon != "" and is_instance_valid(chosen) and _can_aim(chosen) and _in_reach(chosen, 1.25)):
		chosen = null
	if weapon == "":
		target = null
	else:
		target = chosen if chosen != null else _find_target()
	queue_redraw()


# Touching a dinosaur (or clicking it) aims at it and shoots. The joystick and the buttons
# keep their touches for themselves, so only touches on the land arrive here.
func _unhandled_input(event: InputEvent) -> void:
	if weapon == "" or not event is InputEventScreenTouch or not event.pressed:
		return
	var at: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
	var touched := _dino_at(at)
	if touched == null:
		return
	get_viewport().set_input_as_handled()
	var player: Node2D = park.player
	var hint := ""
	if not _can_aim(touched):
		hint = park.food_refused(touched, weapon) if is_food(weapon) else "Pas celui-là !"
	elif not _in_reach(touched, 1.0):
		hint = "Trop loin ! Approche-toi."
	if hint != "":
		park.float_text(touched.position, hint, Color("e0e0e0"))
		return
	chosen = touched
	target = touched
	var to_dino: Vector2 = touched.position - player.position
	if absf(to_dino.x) > absf(to_dino.y):
		player.facing = Vector2i.RIGHT if to_dino.x > 0.0 else Vector2i.LEFT
	else:
		player.facing = Vector2i.DOWN if to_dino.y > 0.0 else Vector2i.UP
	fire()


# The dinosaur drawn under this point of the land, if any.
func _dino_at(at: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for dino in park.dinos:
		if (dino.habitat != "land" and not dino.wild) or dino.captured or dino.ridden:
			continue
		var half := Vector2(maxf(dino.frames.size.x * 0.5, 10.0), maxf(dino.frames.height * 0.6, 10.0))
		var offset: Vector2 = (at - _aim_point(dino)).abs()
		if offset.x <= half.x and offset.y <= half.y:
			var distance := at.distance_to(_aim_point(dino))
			if distance < best_distance:
				best_distance = distance
				best = dino
	return best


static func is_capsule(id: String) -> bool:
	return Items.WEAPONS.has(id) and Items.WEAPONS[id].has("capture")


static func is_food(id: String) -> bool:
	return Items.WEAPONS.has(id) and Items.WEAPONS[id].has("feed")


# From 0 to 1: a tired or sleeping dinosaur is easy to catch, a capsule too small almost never holds.
static func catch_chance(dino: Node2D, capsule: String) -> float:
	var weak: float = 1.0 if dino.state == "sleep" else 1.0 - dino.energy / dino.max_energy()
	var chance := 0.1 + 0.85 * weak
	if dino.species.strength > Items.WEAPONS[capsule].capture:
		chance *= 0.15
	return chance


static func chance_color(chance: float) -> Color:
	if chance >= 0.7:
		return Color("43c04a")
	if chance >= 0.35:
		return Color("f0a020")
	return Color("e53935")


# Whether what the player holds can be used on this dinosaur.
func _can_aim(dino: Node2D) -> bool:
	if dino.captured or dino.ridden or dino.following != null:
		return false
	# Flyers and swimmers of the wild can be aimed at; those of the park live in their homes.
	if dino.habitat != "land" and not dino.wild:
		return false
	if is_food(weapon):
		# Berries go to any herbivore, wild or of the park, that is awake; meat to any carnivore.
		return dino.species.diet == Items.WEAPONS[weapon].feed and dino.state != "sleep"
	# Capsules are for wild dinosaurs; an escaped one of the park can be put to sleep.
	if not (dino.wild or (dino.escaped and not is_capsule(weapon))):
		return false
	return dino.state != "sleep" or is_capsule(weapon)


func _in_reach(dino: Node2D, margin: float) -> bool:
	return park.player.position.distance_to(dino.position) <= Items.WEAPONS[weapon].range * T * margin


func _find_target() -> Node2D:
	var player: Node2D = park.player
	var aim := Vector2(player.facing)
	var best: Node2D = null
	var best_score := INF
	for dino in park.dinos:
		if not _can_aim(dino) or not _in_reach(dino, 1.0):
			continue
		var to_dino: Vector2 = dino.position - player.position
		var distance := to_dino.length()
		var facing := to_dino.normalized().dot(aim) if distance > 0.0 else 1.0
		if distance > 1.5 * T and facing < 0.35:
			continue
		var score := distance * (1.5 - facing)
		if score < best_score:
			best_score = score
			best = dino
	return best


func fire() -> void:
	if weapon == "" or time < ready_at:
		return
	var stats: Dictionary = Items.WEAPONS[weapon]
	var player: Node2D = park.player
	# Nothing is wasted shooting at nothing (children keep the button pressed).
	if target == null or (is_food(weapon) and park.food_refused(target, weapon) != ""):
		if time > hint_at:
			hint_at = time + 2.0
			var hint := "Tourne-toi vers un dinosaure sauvage !"
			if is_food(weapon):
				hint = "Tourne-toi vers un dinosaure %s !" % ("herbivore" if stats.feed == "herb" else "carnivore")
			if target != null:
				hint = park.food_refused(target, weapon)
			park.float_text(player.position, hint, Color("e0e0e0"))
		return
	if stats.ammo != "":
		if park.inventory.count(stats.ammo) <= 0:
			park.float_text(player.position, "Plus de %s !" % Items.name_of(stats.ammo).to_lower(), Color("ffab91"))
			return
		park.inventory.remove(stats.ammo)
	ready_at = time + stats.every
	var kind := weapon
	var shot := target
	var from: Vector2 = player.position + Vector2(0, -8)
	var aimed: WeakRef = weakref(shot)
	_fly(kind, from, shot, func() -> void:
		if aimed.get_ref() != null:
			_land(kind, aimed.get_ref()))


# Where a shot aims on a dinosaur: the middle of its body.
func _aim_point(dino: Node2D) -> Vector2:
	if dino.habitat != "land":
		return dino.position + dino.sprite.position
	return dino.position + Vector2(0, -dino.frames.height * 0.45)


func _fly(kind: String, from: Vector2, shot: Node2D, done: Callable) -> void:
	var stats: Dictionary = Items.WEAPONS[kind]
	var sprite := Sprite2D.new()
	sprite.texture = Art.projectile(kind)
	sprite.position = from
	add_child(sprite)
	var goal: Vector2 = _aim_point(shot)
	var distance := from.distance_to(goal)
	var duration := clampf(distance / stats.speed, 0.15, 0.9)
	var tween := sprite.create_tween()
	tween.tween_method(_move_shot.bind(sprite, from, shot, goal, stats.flight), 0.0, 1.0, duration)
	tween.tween_callback(func() -> void:
		sprite.queue_free()
		done.call())


# A shot on its way, `t` from 0 (just shot) to 1 (arrived). It follows the dinosaur if it moves.
# shot: the dinosaur aimed at, maybe gone meanwhile (caught or tamed by an earlier shot).
func _move_shot(t: float, sprite: Sprite2D, from: Vector2, shot: Variant, goal: Vector2, flight: String) -> void:
	var to: Vector2 = _aim_point(shot) if is_instance_valid(shot) and not shot.captured else goal
	var height := 0.0 if flight == "straight" else sin(PI * t) * minf(from.distance_to(goal) * 0.3, 28.0)
	sprite.position = from.lerp(to, t) - Vector2(0, height)
	match flight:
		"straight":
			sprite.rotation = (to - from).angle()
		"spin":
			sprite.rotation = t * TAU * 3.0
		"arc":
			sprite.rotation = t * TAU


func _land(kind: String, shot: Node2D) -> void:
	if not is_instance_valid(shot) or shot.captured:
		return
	if is_capsule(kind):
		_catch(kind, shot)
		return
	if is_food(kind):
		park.float_text(shot.position, "Miam !", Color("ff80ab"))
		park.feed(shot, kind)
		return
	var stats: Dictionary = Items.WEAPONS[kind]
	if not shot.wild:
		# An escaped dinosaur of the park: put to sleep, it is brought back home.
		shot.sleep(6.0)
		park.float_text(shot.position, "Zzz…", Color("b3e5fc"))
		return
	if shot.species.strength > stats.get("biggest", 5):
		park.float_text(shot.position, "Trop gros pour ça !", Color("ffab91"))
		return
	var power := shot_power(kind, shot)
	shot.hurt(stats.tire * power, stats.get("stun", 0.0), stats.get("quiet", false))
	if shot.state == "sleep":
		park.float_text(shot.position, "Épuisé ! Lance une capsule !", Color("b3e5fc"))
	elif stats.has("stun"):
		park.float_text(shot.position, "Coincé !", Color("d7ccc8"))
	elif armored(shot) and not stats.get("pierce", false):
		park.float_text(shot.position, "Ça rebondit sur sa carapace !", Color("d7ccc8"))
	elif power < 0.3:
		park.float_text(shot.position, "Ça le chatouille… Prends une arme plus forte !", Color("d7ccc8"))
	else:
		park.float_text(shot.position, "Paf !" if power < 1.2 else "Super coup !", Color("fff59d"))


# The ankylosaurus has an armour and the stegosaurus its plates.
static func armored(dino: Node2D) -> bool:
	var features: Array = dino.species.get("features", [])
	return "armor" in features or "plates" in features


# How much of its `tire` a weapon takes from this dinosaur: some are made for the small ones,
# others for the giants, and only some go through an armour.
static func shot_power(kind: String, dino: Node2D) -> float:
	var stats: Dictionary = Items.WEAPONS[kind]
	var strength := clampi(int(dino.species.strength), 1, 5)
	var power: float = stats.power[strength - 1] if stats.has("power") else 1.0
	if armored(dino) and not stats.get("pierce", false):
		power *= 0.3
	return power


# The dinosaur goes into the capsule, which shakes on the ground: it holds, or it opens.
func _catch(kind: String, dino: Node2D) -> void:
	var chance := catch_chance(dino, kind)
	# Three shakes, each one a chance to escape: together they make `chance`.
	var holds := randf() < chance
	var shakes := WOBBLES if holds else randi_range(0, WOBBLES - 1)
	dino.captured = true
	dino.route.clear()
	dino.mood_text.visible = false
	var capsule := Sprite2D.new()
	capsule.texture = Art.projectile(kind)
	capsule.position = dino.position + Vector2(0, -5)
	add_child(capsule)
	var tween := create_tween()
	tween.tween_property(dino.sprite, "modulate", Color(4, 4, 4), 0.15)
	tween.tween_property(dino.sprite, "scale", Vector2(0.05, 0.05), 0.3)
	tween.parallel().tween_property(dino.shadow, "scale", Vector2(0.05, 0.05), 0.3)
	for i in shakes:
		tween.tween_interval(0.35)
		tween.tween_property(capsule, "rotation", 0.5, 0.1)
		tween.tween_property(capsule, "rotation", -0.5, 0.15)
		tween.tween_property(capsule, "rotation", 0.0, 0.1)
	tween.tween_interval(0.4)
	if holds:
		tween.tween_callback(func() -> void:
			park.float_text(capsule.position, "Attrapé !", Color("fff59d"))
			park.catch_dino(dino))
		tween.tween_property(capsule, "modulate:a", 0.0, 0.5)
		tween.tween_callback(capsule.queue_free)
	else:
		tween.tween_callback(func() -> void:
			capsule.queue_free()
			dino.sprite.modulate = Color.WHITE
			dino.mood_text.visible = true
			park.float_text(dino.position, "Oh non, il s'est échappé !", Color("ffab91")))
		tween.tween_property(dino.sprite, "scale", Vector2.ONE, 0.25)
		tween.parallel().tween_property(dino.shadow, "scale", Vector2.ONE, 0.25)
		tween.tween_callback(func() -> void:
			dino.captured = false
			# Out of the capsule, it is awake and has got a bit of energy back.
			if dino.state == "sleep":
				dino.sleep_time = 0.0
			dino.energy = minf(dino.energy + dino.max_energy() * 0.3, dino.max_energy())
			dino.last_hit = dino.time
			if dino.temper() == "fierce":
				dino.angry_time = 6.0
			else:
				dino.flee_time = 4.0)


func _draw() -> void:
	_escape_arrows()
	_goal_arrow()
	for dino in park.dinos:
		if dino.stun_time > 0.0:
			# Bolas wrapped around its legs.
			var bolas := Art.projectile("bolas")
			draw_texture(bolas, dino.position - bolas.get_size() / 2.0 + Vector2(0, -2))
		if dino.wild and not dino.captured and dino != target and dino.time - dino.last_hit < 5.0:
			_energy_bar(dino)
	if target == null or not is_instance_valid(target):
		return
	if weapon == "sniper":
		# The red line of the scope, from the gun to the dinosaur.
		var from: Vector2 = park.player.position + Vector2(0, -8)
		draw_dashed_line(from, _aim_point(target), Color(1, 0.2, 0.15, 0.55), 1.0, 4.0)
	var size: Vector2 = target.frames.size
	var height: float = target.frames.height
	var center := _aim_point(target)
	var half := Vector2(maxf(size.x * 0.45, 10.0), maxf(height * 0.6, 10.0))
	var color := Color("ff5a4a")
	if is_food(weapon):
		color = Color("ff80ab")
	elif is_capsule(weapon):
		color = chance_color(catch_chance(target, weapon))
	# Corners of a frame around the dinosaur, gently pulsing.
	half *= 1.0 + 0.06 * sin(time * 6.0)
	var arm := 5.0
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var p: Vector2 = center + half * corner
		draw_line(p, p - Vector2(corner.x * arm, 0), color, 1.5)
		draw_line(p, p - Vector2(0, corner.y * arm), color, 1.5)
	if target.wild and not is_food(weapon):
		_energy_bar(target)
	if is_capsule(weapon):
		var dot := center + Vector2(half.x + 7.0, -half.y)
		draw_circle(dot, 5.0, Color("1a1a24"))
		draw_circle(dot, 4.0, color)


# A yellow arrow shows where to go for the goal of the level: over the thing when it is on the
# screen, at the edge of the screen pointing to it when it is further.
func _goal_arrow() -> void:
	if park.away != null or park.player == null or park.hud.menu_open():
		return
	var goal = park.goal_target()
	if goal == null:
		return
	var scale := get_canvas_transform().get_scale().x
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	var size := 10.0 / scale
	var tip: Vector2
	var dir: Vector2
	if view.has_point(goal):
		dir = Vector2.DOWN
		tip = goal + Vector2(0, -22 - absf(sin(time * 5.0)) * 6.0)
	else:
		var inner := view.grow(-40.0 / scale)
		var center := inner.get_center()
		var to: Vector2 = goal - center
		var scale_to_edge := minf(absf(inner.size.x / 2.0 / to.x) if to.x != 0.0 else INF, absf(inner.size.y / 2.0 / to.y) if to.y != 0.0 else INF)
		tip = center + to * scale_to_edge
		dir = to.normalized()
	var points := PackedVector2Array([tip, tip - dir * size * 1.6 + dir.orthogonal() * size, tip - dir * size * 1.6 - dir.orthogonal() * size])
	draw_colored_polygon(points, Color("ffd740"))
	draw_polyline(points + PackedVector2Array([tip]), Color("3a2a00"), 1.5 / scale)


# A red arrow at the edge of the screen points to each escaped dinosaur out of sight.
func _escape_arrows() -> void:
	if park.away != null:
		return
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	var inner := view.grow(-28.0 / get_canvas_transform().get_scale().x)
	for dino in park.dinos:
		if not dino.escaped or dino.wild or view.has_point(dino.position):
			continue
		var center := inner.get_center()
		var to: Vector2 = dino.position - center
		var scale_to_edge := minf(absf(inner.size.x / 2.0 / to.x) if to.x != 0.0 else INF, absf(inner.size.y / 2.0 / to.y) if to.y != 0.0 else INF)
		var tip: Vector2 = center + to * scale_to_edge
		var size := 10.0 / get_canvas_transform().get_scale().x
		var dir := to.normalized()
		var points := PackedVector2Array([tip, tip - dir * size * 1.6 + dir.orthogonal() * size, tip - dir * size * 1.6 - dir.orthogonal() * size])
		draw_colored_polygon(points, Color("e53935"))
		draw_polyline(points + PackedVector2Array([tip]), Color("2a1010"), 1.5 / get_canvas_transform().get_scale().x)


func _energy_bar(dino: Node2D) -> void:
	var ratio: float = dino.energy / dino.max_energy() if dino.state != "sleep" else 0.0
	var top: Vector2 = dino.position + Vector2(-12, -dino.frames.height - 7)
	if dino.habitat != "land":
		top = _aim_point(dino) + Vector2(-12, -dino.frames.size.y * 0.5 - 7)
	draw_rect(Rect2(top - Vector2(1, 1), Vector2(26, 5)), Color("1a1a24"))
	draw_rect(Rect2(top, Vector2(24, 3)), Color("5a5a66"))
	var fill := Color("43c04a") if ratio > 0.5 else (Color("f0c020") if ratio > 0.2 else Color("e53935"))
	draw_rect(Rect2(top, Vector2(24.0 * ratio, 3)), fill)

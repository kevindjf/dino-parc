extends Node2D

const Catalog := preload("res://scripts/catalog.gd")
const DinoArt := preload("res://scripts/dino_art.gd")
const Art := preload("res://scripts/art.gd")
const WorldText := preload("res://scripts/world_text.gd")
const T := 16
const NONE := Vector2i(-1, -1)
const UNDERWATER := Color(0.45, 0.6, 1.0, 0.55)

var park: Node2D
var species_id := ""
var species: Dictionary
var habitat := "land"
var frames: Dictionary
var sprite: Sprite2D
var shadow: Sprite2D
var hunger := 100.0
var time := 0.0
var walk_phase := 0.0

# Land dinosaurs walk from cell to cell inside their region.
var region := -1
var cell := Vector2i.ZERO
var home_cell := Vector2i.ZERO
var escaped := false
var state := "idle"  # idle, walk, eat, sleep
var route: Array[Vector2i] = []
var wait := 1.0
var feeder = null
var attack_cell := NONE
var escape_timer := 0.0
var sleep_time := 0.0
var offset := Vector2.ZERO

# Flyers and swimmers circle inside their aviary or lagoon.
var home_building = null
var orbit_center := Vector2.ZERO
var orbit_radius := Vector2.ONE
var altitude := 0.0
var angle := 0.0
var jump_time := 0.0
var next_jump := 10.0
var surface_time := 0.0

# Wild dinosaurs of the adventure: they wander around home, can be tamed with berries
# (then they follow the player), and wild carnivores charge the player.
const TRUST_NEEDED := 3
var wild := false
var trust := 0
var following: Node2D = null
var chase_cool := 3.0

# Fights with wild dinosaurs: nobody gets hurt. Shots take energy away; out of energy, the
# dinosaur falls asleep and can be caught. How it reacts to a shot depends on its temper:
# carnivores and big herbivores charge back, small herbivores run away.
const TIRED_SLEEP := 20.0
const REST_DELAY := 8.0  # seconds without being shot before energy comes back
var energy := 0.0
var last_hit := -100.0
var angry_time := 0.0
var flee_time := 0.0
var stun_time := 0.0
var flash_time := 0.0
var captured := false  # being sucked into a capsule

# Friendship with the park's dinosaurs (0 to 100, 20 per heart): brushing and feeding by hand
# make it grow. With five hearts and a saddle, a big enough dinosaur can be ridden.
const HEART := 20
const RIDE_MIN_LENGTH := 6.0  # meters: from the gallimimus up (a raptor is too small to carry a child)
const SEAT := {"biped": 0.55, "quad": 0.78, "sauropod": 0.5}
var friendship := 0
var saddled := false
var saddle_sprite: Sprite2D
var ridden := false
var ride_moving := false
var next_brush := 0.0
var next_treat := 0.0

var roar_time := 0.0
var next_roar := 0.0
var roar_text: Node2D
var mood_text: Node2D
var mood := ""


func setup(owner_park: Node2D, id: String, start: Vector2i, building) -> void:
	park = owner_park
	species_id = id
	species = Catalog.DINOS[id]
	habitat = species.habitat
	frames = DinoArt.frames(id)
	cell = start
	home_cell = start
	home_building = building
	hunger = randf_range(70.0, 100.0)
	energy = max_energy()
	next_roar = randf_range(5.0, 15.0)
	escape_timer = randf_range(20.0, 40.0)
	offset = Vector2(randf_range(-4, 4), randf_range(-4, 4))

	shadow = Art.sprite(Art.shadow(int(frames.size.x * (0.4 if habitat == "air" else 0.7))))
	shadow.centered = true
	shadow.offset = Vector2.ZERO
	shadow.z_as_relative = false
	shadow.z_index = -1
	add_child(shadow)
	sprite = Art.sprite(frames.walk[0], frames.origin)
	add_child(sprite)

	if habitat == "land":
		position = park.cell_center(start) + offset
		sprite.flip_h = randf() < 0.5
	else:
		var size := Vector2(building.size) * T
		orbit_center = Vector2(building.origin) * T + size / 2.0
		if habitat == "air":
			orbit_radius.x = randf_range(14.0, size.x * 0.32)
			orbit_radius.y = orbit_radius.x * 0.6
			altitude = randf_range(22.0, 40.0)
		else:
			orbit_radius = Vector2(randf_range(16.0, size.x * 0.3), randf_range(10.0, size.y * 0.26))
			shadow.visible = false
			sprite.modulate = UNDERWATER
		angle = randf() * TAU
		next_jump = randf_range(6.0, 15.0)
	saddle_sprite = Art.sprite(Art.resource("saddle"), Vector2(8, 12))
	saddle_sprite.position = Vector2(0, -seat_height() + 5)
	saddle_sprite.visible = false
	sprite.add_child(saddle_sprite)
	var top: float = frames.height + altitude
	mood_text = WorldText.make(self, Vector2(0, -top - 2), "", "bubble")
	roar_text = WorldText.make(self, Vector2(0, -top - 16), species.sound, "shout")
	roar_text.set_shown(false)


func max_energy() -> float:
	return 20.0 + 20.0 * species.strength


# "fierce" charges back, "shy" runs away.
func temper() -> String:
	return "fierce" if species.diet == "carn" or species.strength >= 3 else "shy"


func hurt(amount: float, stun: float) -> void:
	if state == "sleep" or captured:
		return
	last_hit = time
	flash_time = 0.15
	energy = maxf(energy - amount, 0.0)
	stun_time = maxf(stun_time, stun)
	following = null
	if energy <= 0.0:
		stun_time = 0.0
		angry_time = 0.0
		flee_time = 0.0
		sleep(TIRED_SLEEP)
		return
	if temper() == "fierce":
		angry_time = 10.0
		chase_cool = 0.0
	else:
		flee_time = 4.0
	roar()


func hearts() -> int:
	return clampi(friendship / HEART, 0, 5)


func hearts_text() -> String:
	return "♥".repeat(hearts()) + "♡".repeat(5 - hearts())


func can_be_ridden() -> bool:
	return habitat == "land" and species.length >= RIDE_MIN_LENGTH and species.plan in SEAT


# Height of the saddle above the ground, in pixels.
func seat_height() -> float:
	return frames.height * SEAT.get(species.plan, 0.6)


func set_saddled(value: bool) -> void:
	saddled = value
	saddle_sprite.visible = value
	# The sprite is drawn facing right; the saddle follows when it is flipped.
	saddle_sprite.position.x = 0.0


func roar() -> void:
	if roar_time <= 0.0 and state != "sleep":
		roar_time = 1.2


func sleep(duration: float) -> void:
	state = "sleep"
	sleep_time = duration
	route.clear()


func set_region(new_region: int, enclosed: bool) -> void:
	var was_escaped := escaped
	region = new_region
	# Ridden or walking behind the player: it is not escaping.
	if ridden or (following != null and not wild):
		escaped = false
		return
	if wild and enclosed:
		# Someone closed a fence around this wild dinosaur: it now lives in the park.
		park.adopt(self)
		return
	escaped = not enclosed and not wild
	route.clear()
	if state == "walk":
		state = "idle"
	if escaped and not was_escaped:
		park.on_dino_escaped(self)


func teleport(to: Vector2i) -> void:
	cell = to
	home_cell = to
	position = park.cell_center(to) + offset
	route.clear()


# How many treats a wild dinosaur needs to follow us: carnivores trust slower.
func trust_needed() -> int:
	return TRUST_NEEDED + 2 if species.diet == "carn" else TRUST_NEEDED


func set_mood(text: String, color: Color) -> void:
	if ridden:
		text = ""
	elif state == "sleep":
		text = "Zzz"
		color = Color("3070b0")
	elif stun_time > 0.0:
		text = "Coincé !"
		color = Color("8d6e63")
	elif following != null:
		text = "Je te suis !"
		color = Color("c0306a")
	elif wild and trust > 0:
		text = "Miam ! %d/%d" % [trust, trust_needed()]
		color = Color("c0306a")
	if text != mood:
		mood = text
		mood_text.set_text(text, color)


func _process(delta: float) -> void:
	time += delta
	hunger = maxf(hunger - delta * 0.8, 0.0)
	roar_time = maxf(roar_time - delta, 0.0)
	next_roar -= delta
	if next_roar <= 0.0:
		roar()
		next_roar = randf_range(6.0, 12.0) if escaped else randf_range(10.0, 25.0)
	roar_text.set_shown(roar_time > 0.0)
	if captured:
		return
	if habitat == "land":
		flash_time = maxf(flash_time - delta, 0.0)
		sprite.modulate = Color(3, 3, 3) if flash_time > 0.0 else Color.WHITE
	if wild and state != "sleep" and time - last_hit > REST_DELAY:
		energy = minf(energy + max_energy() * 0.05 * delta, max_energy())
	if wild:
		set_mood("", Color.WHITE)

	var moving := false
	match habitat:
		"land":
			moving = ride_moving if ridden else _process_land(delta)
		"air":
			moving = _process_air(delta)
		"sea":
			moving = _process_sea(delta)
	_animate(delta, moving)


func _animate(delta: float, moving: bool) -> void:
	# Keep the body in place when the sprite turns around (the tail makes it lopsided).
	sprite.offset.x = -(frames.size.x - frames.origin.x) if sprite.flip_h else -frames.origin.x
	if state == "sleep":
		sprite.texture = frames.sleep
		return
	if roar_time > 0.0:
		sprite.texture = frames.roar
		return
	if moving:
		var speed: float = species.speed
		walk_phase += delta * (3.0 + 3.0 * speed) * (2.0 if habitat == "air" else 1.0)
	sprite.texture = frames.walk[int(walk_phase) % 2]


# --- Land --------------------------------------------------------------

func _process_land(delta: float) -> bool:
	if state == "sleep":
		sleep_time -= delta
		if sleep_time <= 0.0 and wild:
			# A wild dinosaur wakes up rested, where it fell asleep.
			state = "idle"
			wait = 1.0
			energy = max_energy()
		elif sleep_time <= 0.0:
			if park.return_dino(self):
				state = "idle"
				wait = 1.0
			else:
				sleep_time = 5.0
		return false

	if stun_time > 0.0:
		stun_time -= delta
		return false
	if following != null:
		return _follow(delta)
	chase_cool -= delta
	angry_time -= delta
	if flee_time > 0.0 and park.player != null:
		flee_time -= delta
		return _flee(delta)
	if wild and park.player != null and park.away == null and not park.player.flying() and chase_cool <= 0.0 \
		and not _player_rides_stronger():
		var distance: float = position.distance_to(park.player.position)
		if (species.diet == "carn" and distance < 4.0 * T) or (angry_time > 0.0 and distance < 12.0 * T):
			return _chase(delta)
	escape_timer -= delta
	match state:
		"idle":
			wait -= delta
			if wait <= 0.0:
				_choose_goal()
		"eat":
			wait -= delta
			if wait <= 0.0:
				hunger = 100.0
				state = "idle"
				wait = randf_range(1.0, 3.0)
		"walk":
			return _follow_route(delta)
	return false


func _choose_goal() -> void:
	feeder = null
	attack_cell = NONE
	var target := NONE
	if hunger < 50.0 and not escaped:
		feeder = park.find_feeder(self)
		if feeder != null:
			target = feeder.origin
	if target == NONE and escape_timer <= 0.0:
		escape_timer = randf_range(20.0, 40.0)
		attack_cell = park.fence_to_attack(self)
		if attack_cell != NONE:
			target = park.cell_next_to(attack_cell, region)
	if target == NONE and wild:
		target = park.random_cell_near(home_cell, 6, region)
	if target == NONE:
		target = park.random_cell_in_region(region)
	if target == NONE:
		wait = 2.0
		return
	route = park.find_route(cell, target, region)
	if route.is_empty():
		_arrive()
	else:
		state = "walk"


func _follow_route(delta: float) -> bool:
	if route.is_empty():
		_arrive()
		return false
	var next := route[0]
	if not park.is_walkable_for_dino(next, region):
		route.clear()
		state = "idle"
		wait = 0.5
		return false
	var goal: Vector2 = park.cell_center(next) + offset
	var to_goal := goal - position
	var speed: float = species.speed * T * (1.6 if escaped else 1.0)
	if to_goal.length() < 0.8:
		cell = next
		route.pop_front()
		if route.is_empty():
			_arrive()
		return true
	position += to_goal.normalized() * minf(speed * delta, to_goal.length())
	if absf(to_goal.x) > 0.3:
		sprite.flip_h = to_goal.x < 0.0
	return true


func _arrive() -> void:
	state = "idle"
	wait = randf_range(1.0, 4.0)
	if feeder != null and park.consume_feeder(feeder, self):
		state = "eat"
		wait = 3.0
	elif attack_cell != NONE:
		park.break_fence(attack_cell, self)
		roar()
	feeder = null
	attack_cell = NONE


# A wild carnivore does not dare charge someone riding a dinosaur at least as strong as itself.
func _player_rides_stronger() -> bool:
	var mount = park.player.mount
	return mount != null and mount.species.strength >= species.strength


# Walks right behind the player, through gates and fences, like a pet.
func _follow(delta: float) -> bool:
	# While the player is away from the park (a mine, the village), it waits there.
	if park.away != null:
		return false
	var to_player: Vector2 = following.position - position
	cell = Vector2i((position / T).floor())
	if to_player.length() < 18.0:
		return false
	var speed := maxf(species.speed * T * 1.6, 56.0)
	position += to_player.normalized() * minf(speed * delta, to_player.length() - 16.0)
	if absf(to_player.x) > 2.0:
		sprite.flip_h = to_player.x < 0.0
	return true


# Runs straight at the player, but fences still stop it.
func _chase(delta: float) -> bool:
	route.clear()
	state = "idle"
	var to_player: Vector2 = park.player.position - position
	if to_player.length() < 10.0:
		chase_cool = 2.5
		roar()
		park.player_hit(self)
		return false
	var step := to_player.normalized() * maxf(species.speed * T * 1.5, 40.0) * delta
	var next_cell := Vector2i(((position + step) / T).floor())
	if next_cell != cell and not park.is_walkable_for_dino(next_cell, region):
		return false
	position += step
	cell = next_cell
	sprite.flip_h = step.x < 0.0
	if roar_time <= 0.0 and randf() < delta:
		roar()
	return true


# Runs away from the player, a bit faster than walking.
func _flee(delta: float) -> bool:
	route.clear()
	state = "idle"
	var away: Vector2 = (position - park.player.position).normalized()
	var step := away * maxf(species.speed * T * 1.8, 40.0) * delta
	var next_cell := Vector2i(((position + step) / T).floor())
	if next_cell != cell and not park.is_walkable_for_dino(next_cell, region):
		# Cornered: try sideways.
		step = step.rotated(PI / 2.0)
		next_cell = Vector2i(((position + step) / T).floor())
		if next_cell != cell and not park.is_walkable_for_dino(next_cell, region):
			return false
	position += step
	cell = next_cell
	sprite.flip_h = step.x < 0.0
	return true


# --- Air and sea --------------------------------------------------------

func _orbit(delta: float) -> void:
	var speed: float = species.speed * T
	angle += speed / orbit_radius.x * delta
	position = orbit_center + Vector2(cos(angle), sin(angle)) * orbit_radius
	sprite.flip_h = sin(angle) > 0.0


func _process_air(delta: float) -> bool:
	_eat_fish()
	_orbit(delta)
	if randf() < delta * 0.1:
		altitude = clampf(altitude + randf_range(-6.0, 6.0), 20.0, 42.0)
	sprite.position.y = -altitude + sin(time * 2.0) * 2.0
	return true


func _process_sea(delta: float) -> bool:
	_eat_fish()
	_orbit(delta)
	next_jump -= delta
	if next_jump <= 0.0 and jump_time <= 0.0:
		next_jump = randf_range(12.0, 25.0)
		if species_id == "mosasaurus":
			jump_time = 1.6
			roar()
		else:
			surface_time = 4.0
	surface_time = maxf(surface_time - delta, 0.0)
	if jump_time > 0.0:
		jump_time -= delta
		var t := 1.0 - jump_time / 1.6
		sprite.position.y = -sin(PI * t) * 40.0
		sprite.rotation = lerpf(-0.6, 0.6, t) * (-1.0 if sprite.flip_h else 1.0)
		sprite.modulate = Color.WHITE
		if jump_time <= 0.0:
			park.splash(position)
	else:
		sprite.position.y = 0.0
		sprite.rotation = 0.0
		sprite.modulate = Color.WHITE if surface_time > 0.0 else UNDERWATER
	return true


func _eat_fish() -> void:
	if hunger < 30.0:
		hunger = 100.0
		park.feed_fish(self)

extends Node2D

# Dinosaur races in the park: riding a dinosaur in front of the race flag, Action starts a race
# against three other riders. Flags around the start show the way (the yellow arrow points to the
# next one); the first one back at the start wins. A friend dinosaur runs faster (player.gd).

const Catalog := preload("res://scripts/catalog.gd")
const DinoArt := preload("res://scripts/dino_art.gd")
const Dino := preload("res://scripts/dino.gd")
const Art := preload("res://scripts/art.gd")
const T := 16

const COUNTDOWN := 3.0
const GIVE_UP := 150.0  # seconds: a race this long is over
const RIVAL_PACE := [0.8, 0.9, 1.0]  # the speed of the rivals, against the player's dinosaur
const PRIZES := [150, 80, 40, 10]  # coins for the 1st, 2nd, 3rd and 4th place
const MEDALS := ["or", "argent", "bronze"]
const RIDER_SHIRTS := [Color("e53935"), Color("1e88e5"), Color("8e24aa")]

var park: Node2D
var running := false
var countdown := 0.0
var shown_count := 0
var clock := 0.0
var points: Array[Vector2] = []  # the flags to pass, in order; the last one is the finish
var next := 0
var rivals: Array[Dictionary] = []  # {node, sprite, frames, target, speed, done}
var ahead := 0  # rivals already at the finish

# Kept with the game.
var races := 0
var medals := {"or": 0, "argent": 0, "bronze": 0}
var best := 0.0  # the best time, in seconds


func setup(owner_park: Node2D) -> void:
	park = owner_park


func to_dict() -> Dictionary:
	return {"races": races, "medals": medals, "best": best}


func from_dict(data: Dictionary) -> void:
	races = int(data.get("races", 0))
	var saved: Dictionary = data.get("medals", {})
	for medal in MEDALS:
		medals[medal] = int(saved.get(medal, 0))
	best = float(data.get("best", 0.0))


# The race flag the player, riding, is in front of, or null.
func flag_near() -> Variant:
	if park.player == null or park.player.mount == null:
		return null
	for building in park.buildings:
		if building.id == "race_flag" and park.cell_center(building.origin).distance_to(park.player.position) < 1.8 * T:
			return building
	return null


func start(flag: Dictionary) -> void:
	var center: Vector2i = flag.origin
	points.clear()
	for i in 6:
		var angle := TAU * i / 6.0 + PI / 2.0
		for radius in [10, 11, 9, 12, 8, 7]:
			var cell := center + Vector2i(roundi(cos(angle) * radius), roundi(sin(angle) * radius * 0.8))
			if park.in_grid(cell) and not park.player_blocked(cell) and not park.is_water(cell):
				points.append(park.cell_center(cell))
				break
	if points.size() < 4:
		park.hud.flash("Il faut plus de place libre autour du drapeau pour la course !", 3.0)
		return
	points.append(park.player.position)
	next = 0
	ahead = 0
	clock = 0.0
	countdown = COUNTDOWN
	shown_count = 0
	running = true
	_add_rivals()
	park.hud.flash("Course de dinos !\nPasse par tous les drapeaux et reviens au départ.", 2.5)


func _add_rivals() -> void:
	var choices := []
	for id in Catalog.DINOS:
		var species: Dictionary = Catalog.DINOS[id]
		if species.habitat == "land" and species.length >= Dino.RIDE_MIN_LENGTH and Dino.SEAT.has(species.plan) and id != park.player.mount.species_id:
			choices.append(id)
	choices.shuffle()
	var mount: Node2D = park.player.mount
	var base: float = mount.species.speed * T * 3.0 + 30.0
	for i in 3:
		var id: String = choices[i]
		var frames: Dictionary = DinoArt.frames(id)
		var node := Node2D.new()
		node.position = park.player.position + Vector2((i + 1) * 14.0 * (1 if i % 2 == 0 else -1), (i + 1) * 6.0)
		park.world.add_child(node)
		var sprite := Art.sprite(frames.walk[0], frames.origin)
		node.add_child(sprite)
		var rider := Art.sprite(Art.person("side", 0, {"skin": Color("e0ac69"), "hair": Color("3a2a1a"),
			"shirt": RIDER_SHIRTS[i], "pants": Color("37474f"), "hat": RIDER_SHIRTS[i].darkened(0.3)}))
		rider.position = Vector2(0, -frames.height * Dino.SEAT[Catalog.DINOS[id].plan] + 8)
		sprite.add_child(rider)
		rivals.append({"node": node, "sprite": sprite, "frames": frames, "target": 0, "done": false,
			"speed": base * RIVAL_PACE[i] * randf_range(0.95, 1.05), "phase": randf() * 4.0, "rider": rider})


func stop() -> void:
	running = false
	for rival in rivals:
		if is_instance_valid(rival.node):
			rival.node.queue_free()
	rivals.clear()
	points.clear()


# Where the yellow arrow points during a race, or null.
func arrow_target() -> Variant:
	return points[next] if running and countdown <= 0.0 and next < points.size() else null


func _process(delta: float) -> void:
	queue_redraw()
	if not running:
		return
	if park.player == null or park.player.mount == null or park.zone != park.Wild.BASE or park.away != null:
		park.hud.flash("Course abandonnée.", 2.0)
		stop()
		return
	if countdown > 0.0:
		countdown -= delta
		var count := ceili(countdown)
		if count != shown_count:
			shown_count = count
			park.hud.flash(str(count) if count > 0 else "Partez !", 0.8)
		return
	clock += delta
	if clock > GIVE_UP:
		park.hud.flash("La course est finie : trop long !", 2.5)
		stop()
		return
	for rival in rivals:
		_move_rival(rival, delta)
	if park.player.position.distance_to(points[next]) < 1.4 * T:
		next += 1
		if next >= points.size():
			_finish()
			return
		park.float_text(points[next - 1] + Vector2(0, -18), "%d / %d" % [next, points.size() - 1], Color("fff59d"))


func _move_rival(rival: Dictionary, delta: float) -> void:
	var node: Node2D = rival.node
	if rival.done:
		return
	var target: Vector2 = points[rival.target]
	var step: Vector2 = target - node.position
	var move: float = rival.speed * delta
	if step.length() <= move:
		node.position = target
		rival.target += 1
		if rival.target >= points.size():
			rival.done = true
			ahead += 1
		return
	node.position += step.normalized() * move
	var frames: Dictionary = rival.frames
	var sprite: Sprite2D = rival.sprite
	if absf(step.x) > 1.0:
		sprite.flip_h = step.x < 0.0
		rival.rider.flip_h = sprite.flip_h
	sprite.offset.x = -(frames.size.x - frames.origin.x) if sprite.flip_h else -frames.origin.x
	rival.phase += delta * 10.0
	sprite.texture = frames.walk[int(rival.phase) % frames.walk.size()]


func _finish() -> void:
	var place := ahead + 1
	var time := clock
	races += 1
	var prize: int = PRIZES[place - 1]
	park.money += prize
	var text := "%de place !" % place if place > 1 else "1re place ! Tu as gagné !"
	if place <= MEDALS.size():
		medals[MEDALS[place - 1]] += 1
		text += "\nMédaille %s !" % ["d'or", "d'argent", "de bronze"][place - 1]
	text += "\nTemps : %d s   +%d pièces" % [int(time), prize]
	if best == 0.0 or time < best:
		if best > 0.0:
			text += "\nNouveau record !"
		best = time
	if place > 1:
		text += "\nBrosse et nourris ton dino : un dino ami court plus vite !"
	park.hud.flash(text, 5.0)
	stop()


func _draw() -> void:
	if not running:
		return
	for i in points.size():
		var at := points[i]
		var current := i == next
		if i == points.size() - 1:
			if current:
				_ring(at, Color("ffffff"))
			continue
		var color := Color("ffd740") if current else (Color(1, 1, 1, 0.35) if i < next else Color("ff7043"))
		if current:
			_ring(at, color)
		draw_line(at, at + Vector2(0, -16), Color("6a4a2a"), 1.5)
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -16), at + Vector2(8, -13), at + Vector2(0, -10)]), color)


func _ring(at: Vector2, color: Color) -> void:
	var size := 1.3 * T * (1.0 + 0.1 * sin(clock * 6.0))
	draw_arc(at, size, 0.0, TAU, 32, Color(color, 0.8), 2.0)

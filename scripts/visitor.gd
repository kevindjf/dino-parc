extends Node2D

const Art := preload("res://scripts/art.gd")
const WorldText := preload("res://scripts/world_text.gd")
const T := 16
const SKIN_TONES := [Color("f1c27d"), Color("e0ac69"), Color("c68642"), Color("8d5524"), Color("ffdbac")]
const HAIR := [Color("2a1a10"), Color("5a3a1a"), Color("a0602a"), Color("e0c060"), Color("202020"), Color("c04020")]

var park: Node2D
var cell := Vector2i.ZERO
var prev_cell := Vector2i.ZERO
var next_cell := Vector2i.ZERO
var progress := 0.0
var speed := 1.5
var steps_left := 30
var leaving := false
var scared := false
var bought := {}  # shop id -> true
var offset := Vector2.ZERO
var time := 0.0
var danger_timer := 0.0
var colors := {}
var sprite: Sprite2D
var ice_cream: Sprite2D
var facing := "down"
var think_timer := 0.0
var role := ""  # "" for a visitor, "vip" for the journalist; "keeper", "worker" or "ranger" for the staff of the park


# outfit: the colours of the staff's uniform, over random ones.
func setup(owner_park: Node2D, start: Vector2i, job := "", outfit := {}) -> void:
	park = owner_park
	role = job
	cell = start
	prev_cell = start
	offset = Vector2(randf_range(-4, 4), randf_range(-3, 3))
	speed = randf_range(1.2, 2.0)
	steps_left = randi_range(40, 100)
	colors = {"hair": HAIR.pick_random(), "skin": SKIN_TONES.pick_random(),
		"shirt": Color.from_hsv(randf(), 0.65, 0.95), "pants": [Color("37474f"), Color("3a5a9a"), Color("6d5a3a")].pick_random()}
	if randf() < 0.3:
		colors.hat = Color.from_hsv(randf(), 0.7, 0.85)
	colors.merge(outfit, true)
	if role != "":
		speed = 1.3 if role == "vip" else 1.6
	var shadow := Art.sprite(Art.shadow(11))
	shadow.centered = true
	shadow.offset = Vector2.ZERO
	add_child(shadow)
	sprite = Art.sprite(Art.person("down", 0, colors))
	add_child(sprite)
	ice_cream = Art.sprite(Art.ice_cream(), Vector2(2, 6))
	ice_cream.position = Vector2(5, -6)
	ice_cream.visible = false
	add_child(ice_cream)
	_choose_next()
	position = park.cell_center(cell) + offset
	think_timer = randf_range(3.0, 12.0)


# Visitors and the journalist walk around, buy and think; the staff works.
func is_guest() -> bool:
	return role == "" or role == "vip"


func buy(shop_id: String) -> void:
	bought[shop_id] = true
	if shop_id == "icecream":
		ice_cream.visible = true


func _process(delta: float) -> void:
	time += delta
	# The path under our feet was bulldozed: go home.
	if not park.is_path(cell) or not park.is_path(next_cell):
		queue_free()
		return

	think_timer -= delta
	if think_timer <= 0.0 and is_guest():
		think_timer = randf_range(5.0, 9.0) if role == "vip" else randf_range(8.0, 16.0)
		_think()
	danger_timer -= delta
	if danger_timer <= 0.0 and is_guest():
		danger_timer = 0.5
		if not scared and park.danger_near(position):
			scared = true
			leaving = true
			speed = 3.5

	progress += delta * speed
	if progress >= 1.0:
		progress = 0.0
		prev_cell = cell
		cell = next_cell
		if is_guest():
			park.on_visitor_step(self)
			steps_left -= 1
		if steps_left <= 0:
			leaving = true
		if leaving and park.distance_to_entrance(cell) == 0:
			queue_free()
			return
		_choose_next()

	position = park.cell_center(cell).lerp(park.cell_center(next_cell), progress) + offset
	sprite.position.y = -absf(sin(time * 16.0)) * 2.0 if scared else 0.0
	var direction := next_cell - cell
	if direction.x != 0:
		facing = "side"
		sprite.flip_h = direction.x < 0
	elif direction.y != 0:
		facing = "down" if direction.y > 0 else "up"
		sprite.flip_h = false
	var frame := int(time * 5.0 * speed) % 2 if direction != Vector2i.ZERO else 0
	sprite.texture = Art.person(facing, frame, colors)
	ice_cream.visible = bought.has("icecream") and facing != "up"


func _choose_next() -> void:
	var options: Array = park.path_neighbors(cell)
	if options.is_empty():
		next_cell = cell
		leaving = true
		return
	if leaving:
		# Walk back toward the entrance.
		var best := cell
		var best_distance: int = park.distance_to_entrance(cell)
		for option in options:
			var d: int = park.distance_to_entrance(option)
			if d < best_distance:
				best = option
				best_distance = d
		next_cell = best
		return
	if options.size() > 1:
		options.erase(prev_cell)
	next_cell = options.pick_random()


# Now and then, a visitor says what they think in a bubble, a few at a time on the screen.
func _think() -> void:
	if scared or (role == "" and get_tree().get_nodes_in_group("thoughts").size() >= 3):
		return
	var text: String = park.events.vip_thought(self) if role == "vip" else park.visitor_thought(self)
	if text == "":
		return
	var bubble := WorldText.make(self, Vector2(0, -26), text, "bubble")
	bubble.add_to_group("thoughts")
	var tween := bubble.create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(bubble.queue_free)

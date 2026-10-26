extends Node2D

# A gyrosphere rolling inside an enclosure, or a jeep driving along the roads, with visitors on board.

const Art := preload("res://scripts/art.gd")
const T := 16

var park: Node2D
var kind := "gyro"
var station: Dictionary
var sprite: Sprite2D
var cell := Vector2i.ZERO
var prev_cell := Vector2i.ZERO
var route: Array[Vector2i] = []
var wait := 0.5
var steps := 0
var speed := 1.4
var travelled := 0.0


func setup(owner_park: Node2D, vehicle_kind: String, start: Vector2i, owner_station: Dictionary) -> void:
	park = owner_park
	kind = vehicle_kind
	station = owner_station
	cell = start
	prev_cell = start
	if kind == "gyro":
		sprite = Art.sprite(Art.gyro(0), Vector2(10, 19))
	else:
		sprite = Art.sprite(Art.jeep(0), Vector2(15, 19))
	add_child(sprite)
	speed = (1.4 if kind == "gyro" else 2.2) * T
	position = park.cell_center(start)
	wait = randf_range(0.2, 2.0)


func _process(delta: float) -> void:
	if route.is_empty():
		wait -= delta
		if wait <= 0.0:
			_plan()
		return
	var next := route[0]
	var to_goal: Vector2 = park.cell_center(next) - position
	if to_goal.length() < 0.8:
		prev_cell = cell
		cell = next
		route.pop_front()
		if route.is_empty():
			_arrived()
		return
	var step := to_goal.normalized() * minf(speed * delta, to_goal.length())
	position += step
	travelled += step.length()
	if absf(step.x) > 0.01:
		sprite.flip_h = step.x < 0.0
	var frame := int(travelled / 3.0)
	sprite.texture = Art.gyro(frame % 4) if kind == "gyro" else Art.jeep(frame % 4)


func _plan() -> void:
	if kind == "gyro":
		var region: int = park.region_at(cell)
		var target: Vector2i = park.random_cell_in_region(region)
		route = park.find_route(cell, target, region)
		if route.is_empty():
			wait = 1.0
	else:
		# Jeeps wander the road network, avoiding U-turns.
		var options: Array = park.road_neighbors(cell)
		if options.is_empty():
			wait = 1.0
			return
		if options.size() > 1:
			options.erase(prev_cell)
		route.append(options.pick_random())


func _arrived() -> void:
	if kind == "gyro":
		wait = randf_range(1.0, 2.5)
		if station.open:
			park.earn(15, position)
	else:
		steps += 1
		wait = 0.0
		if steps % 15 == 0 and station.open:
			park.earn(20, position)

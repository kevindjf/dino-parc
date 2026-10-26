extends Node2D

# The heliport's helicopter: takes off, flies visitors over a few spots of the park, lands, and starts again.
# The node stays on the ground point under the helicopter; the sprite is lifted by its altitude.

const Art := preload("res://scripts/art.gd")
const CRUISE_HEIGHT := 70.0
const SPEED := 90.0
const ANCHOR := Vector2(18, 20)

var park: Node2D
var station: Dictionary
var sprite: Sprite2D
var shadow: Sprite2D
var pad := Vector2.ZERO
var waypoints: Array[Vector2] = []
var state := "parked"  # parked, climb, cruise, descend
var wait := 3.0
var altitude := 0.0
var rotor_speed := 0.0
var rotor_angle := 0.0


func setup(owner_park: Node2D, owner_station: Dictionary) -> void:
	park = owner_park
	station = owner_station
	shadow = Art.sprite(Art.shadow(26))
	shadow.centered = true
	shadow.offset = Vector2.ZERO
	shadow.z_as_relative = false
	shadow.z_index = -1
	add_child(shadow)
	sprite = Art.sprite(Art.helicopter(0), ANCHOR)
	add_child(sprite)
	pad = (Vector2(station.origin) + Vector2(1.5, 1.8)) * park.T
	position = pad
	wait = randf_range(2.0, 5.0)


func _process(delta: float) -> void:
	match state:
		"parked":
			rotor_speed = move_toward(rotor_speed, 0.0, delta * 8.0)
			wait -= delta
			if wait <= 0.0:
				_plan_tour()
				state = "climb"
		"climb":
			rotor_speed = move_toward(rotor_speed, 25.0, delta * 15.0)
			if rotor_speed > 20.0:
				altitude = move_toward(altitude, CRUISE_HEIGHT, delta * 25.0)
				if altitude >= CRUISE_HEIGHT:
					state = "cruise"
		"cruise":
			if _fly_to(waypoints[0], delta):
				waypoints.pop_front()
				if waypoints.is_empty():
					state = "descend"
		"descend":
			altitude = move_toward(altitude, 0.0, delta * 20.0)
			if altitude <= 0.0:
				state = "parked"
				wait = randf_range(4.0, 7.0)
				if station.open:
					park.earn(60, position)
	rotor_angle += rotor_speed * delta
	sprite.texture = Art.helicopter(int(rotor_angle) % 2)
	sprite.position.y = -altitude
	shadow.scale = Vector2.ONE * clampf(1.0 - altitude / 160.0, 0.5, 1.0)
	# High up, it flies over everything.
	z_index = 1 if altitude > 6.0 else 0


# Visits a few random spots, then comes back above the pad.
func _plan_tour() -> void:
	waypoints.clear()
	for i in 3:
		waypoints.append(park.random_ground_point())
	waypoints.append(pad)


func _fly_to(target: Vector2, delta: float) -> bool:
	var to_target := target - position
	if to_target.length() < 2.0:
		return true
	position += to_target.normalized() * minf(SPEED * delta, to_target.length())
	if absf(to_target.x) > 1.0:
		sprite.flip_h = to_target.x < 0.0
	return false

extends Node2D

# Day and night, and storms, in the adventure. A day lasts DAY seconds: the land gets blue and
# dark at night (never too dark for children), the campfires glow and a lamp lights around the
# player. Now and then a storm comes: rain, lightning, and the dinosaurs of the park get scared
# and push their fences (only fences at least one step stronger than them hold; electric ones
# hold everything). Mines and houses have their own light: there, nothing changes.

const DAY := 600.0  # seconds for a whole day and night
const NIGHT_COLOR := Color(0.42, 0.46, 0.72)
const STORM_COLOR := Color(0.62, 0.64, 0.72)
const STORM_TIME := 50.0

var park: Node2D
var time := DAY * 0.3  # the game starts in the morning
var tint: CanvasModulate
var lamp: PointLight2D
var rain: CPUParticles2D
var flash: ColorRect
var storm_left := 0.0
var next_storm := 0.0
var next_lightning := 0.0
var was_night := false


func setup(owner_park: Node2D) -> void:
	park = owner_park
	next_storm = randf_range(240.0, 480.0)
	tint = CanvasModulate.new()
	add_child(tint)
	lamp = PointLight2D.new()
	lamp.texture = glow(256)
	lamp.texture_scale = 0.8
	lamp.energy = 0.0
	add_child(lamp)
	rain = CPUParticles2D.new()
	rain.amount = 260
	rain.lifetime = 0.7
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.direction = Vector2(0.25, 1)
	rain.spread = 4.0
	rain.gravity = Vector2.ZERO
	rain.initial_velocity_min = 380.0
	rain.initial_velocity_max = 460.0
	rain.scale_amount_min = 1.0
	rain.scale_amount_max = 1.5
	# Drops are short streaks along their fall.
	var drop := Image.create(1, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		drop.set_pixel(0, y, Color(1, 1, 1, 0.3 + 0.1 * y))
	rain.texture = ImageTexture.create_from_image(drop)
	rain.particle_flag_align_y = true
	rain.color = Color(0.75, 0.82, 1.0, 0.6)
	rain.z_index = 40
	rain.emitting = false
	add_child(rain)
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)


# A round light, bright in the middle: for the player's lamp and the campfires.
static func glow(size: int) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.88, 0.65, 1))
	gradient.set_color(1, Color(1, 0.85, 0.6, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = size
	texture.height = size
	return texture


# 1 in full day, 0 in the middle of the night, in between at dusk and dawn.
func daylight() -> float:
	var t := time / DAY
	if t < 0.65:
		return 1.0
	if t < 0.72:
		return 1.0 - (t - 0.65) / 0.07
	if t < 0.93:
		return 0.0
	return (t - 0.93) / 0.07


func is_night() -> bool:
	return daylight() < 0.5


func storming() -> bool:
	return storm_left > 0.0


func _process(delta: float) -> void:
	if park.player == null:
		return
	time = fmod(time + delta, DAY)
	var light := daylight()
	var outside: bool = park.mine == null and park.house == null
	var color := NIGHT_COLOR.lerp(Color.WHITE, light)
	if storming():
		color = color * STORM_COLOR
		color.a = 1.0
	tint.color = color
	tint.visible = outside
	lamp.position = park.player.global_position + Vector2(0, -8)
	# The light adds to the dark tint: around the lamp, things look about as in the day.
	lamp.energy = (1.0 - light) * 0.55 if outside else 0.0
	for fire in get_tree().get_nodes_in_group("fire_lights"):
		fire.energy = (1.0 - light) * 0.6 + (0.2 if storming() else 0.0)
	if is_night() != was_night:
		was_night = is_night()
		park.hud.flash("La nuit tombe…\nLes feux de camp éclairent autour d'eux." if was_night else "Le jour se lève !", 3.0)
	_process_storm(delta, outside)


func _process_storm(delta: float, outside: bool) -> void:
	var camera: Camera2D = park.camera
	var view: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	rain.position = camera.get_screen_center_position() - Vector2(0, view.y * 0.6)
	rain.emission_rect_extents = Vector2(view.x * 0.65, 10)
	if not storming():
		next_storm -= delta
		rain.emitting = false
		if next_storm <= 0.0 and park.away == null:
			start_storm()
		return
	storm_left -= delta
	rain.emitting = outside
	next_lightning -= delta
	if next_lightning <= 0.0 and outside:
		next_lightning = randf_range(4.0, 9.0)
		flash.color.a = 0.7
		create_tween().tween_property(flash, "color:a", 0.0, 0.5)
		park.float_text(park.player.position + Vector2(randf_range(-80, 80), -60), "BOUM !", Color("fff59d"))
	if storm_left <= 0.0:
		next_storm = randf_range(300.0, 600.0)
		park.storm_ended()


func start_storm() -> void:
	storm_left = STORM_TIME
	next_lightning = 2.0
	park.storm_started()

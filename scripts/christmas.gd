extends Node2D

# Christmas in the adventure, from December 1st to January 6th (by the date of the device):
#   - snow falls outside;
#   - the T-Rex of Christmas, in a red hat, walks along the paths of the park: going to see him
#     gives the present of the day (an Advent calendar, and a golden dinosaur on December 25th);
#   - in each zone of the Wild Lands, a present is hidden once a day;
#   - the shop sells a Christmas tree and a snowman (Market.BUY, "season": "noel").

const Catalog := preload("res://scripts/catalog.gd")
const DinoArt := preload("res://scripts/dino_art.gd")
const Art := preload("res://scripts/art.gd")
const Items := preload("res://scripts/items.gd")
const T := 16
const SANTA := "trex"

# The present of each day of December, from the 1st to the 24th.
const ADVENT := [
	{"coins": 50}, {"berries": 10}, {"capsule_copper": 3}, {"flowers": 5}, {"meat": 5}, {"coins": 100},
	{"xmas_tree": 1}, {"capsule_iron": 2}, {"bench": 2}, {"fossil": 2}, {"snowman": 1}, {"coins": 150},
	{"lamp": 2}, {"amber": 1}, {"capsule_gold": 1}, {"crystal": 2}, {"coins": 200}, {"gold": 3},
	{"statue": 1}, {"race_flag": 1}, {"capsule_gold": 1}, {"fountain": 1}, {"coins": 300}, {"capsule_gold": 3},
]
const CHRISTMAS_DAY := "dino:trex:dore"
const AFTER := {"coins": 100}  # every day after Christmas, until January 6th
const GIFTS := [{"coins": 60}, {"capsule_iron": 1}, {"berries": 8}, {"meat": 4}, {"amber": 1}, {"fossil": 1}, {"capsule_gold": 1}]

static var force := false  # for tests: Christmas whatever the date

var park: Node2D
var time := 0.0

# Kept with the game.
var opened := {}  # "2026-12-03" -> true: the days the present of the T-Rex was given
var found := {}  # zone key -> the day its present was found

var snow: CPUParticles2D
var santa: Node2D = null
var santa_sprite: Sprite2D
var hat: Node2D
var head := Vector2.ZERO  # the top of the head of the T-Rex, from its feet, facing right
var cell := Vector2i.ZERO
var next_cell := Vector2i.ZERO
var progress := 0.0
var phase := 0.0
var bubble_timer := 3.0
var gift_at := Vector2.ZERO  # the present of the zone the player is in, or ZERO
var welcomed := false


static func active() -> bool:
	var date := Time.get_date_dict_from_system()
	return force or date.month == 12 or (date.month == 1 and date.day <= 6)


static func today() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]


func setup(owner_park: Node2D) -> void:
	park = owner_park
	snow = CPUParticles2D.new()
	snow.amount = 140
	snow.lifetime = 6.0
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.direction = Vector2(0.15, 1)
	snow.spread = 20.0
	snow.gravity = Vector2.ZERO
	snow.initial_velocity_min = 18.0
	snow.initial_velocity_max = 32.0
	snow.scale_amount_min = 1.0
	snow.scale_amount_max = 2.0
	var flake := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	flake.fill(Color(1, 1, 1, 0.9))
	snow.texture = ImageTexture.create_from_image(flake)
	snow.z_index = 40
	snow.emitting = false
	add_child(snow)


func to_dict() -> Dictionary:
	return {"opened": opened.keys(), "found": found}


func from_dict(data: Dictionary) -> void:
	opened = {}
	for day in data.get("opened", []):
		opened[day] = true
	found = data.get("found", {})


func _outside() -> bool:
	return park.player != null and park.mine == null and park.house == null and park.village == null


func _process(delta: float) -> void:
	time += delta
	queue_redraw()
	if park == null or park.mode != "adventure" or park.player == null or not active():
		snow.emitting = false
		return
	if not welcomed and not park.loading:
		welcomed = true
		park.hud.flash("Joyeux Noël !\nLe T-Rex de Noël se promène dans ton parc :\nva le voir chaque jour pour ton cadeau !", 5.0)
	# Snow over the screen, outside, but not in the rain of a storm.
	var camera: Camera2D = park.camera
	var view: Vector2 = get_viewport().get_visible_rect().size / camera.zoom
	snow.position = camera.get_screen_center_position() - Vector2(0, view.y * 0.6)
	snow.emission_rect_extents = Vector2(view.x * 0.7, 8)
	snow.lifetime = view.y * 1.3 / 25.0
	snow.emitting = _outside() and not (park.weather != null and park.weather.storming())
	var in_park: bool = park.zone == park.Wild.BASE and park.away == null and not park.loading
	_process_santa(delta, in_park)
	if not in_park and park.away == null and gift_at != Vector2.ZERO and park.player.position.distance_to(gift_at) < 0.9 * T:
		_open_gift()


# --- The T-Rex of Christmas ---------------------------------------------------------

func _process_santa(delta: float, in_park: bool) -> void:
	if santa == null:
		if not in_park:
			return
		_add_santa()
	santa.visible = in_park
	if not in_park:
		return
	if not park.is_path(cell) or not park.is_path(next_cell):
		cell = park.ENTRANCE
		next_cell = cell
	progress += delta * 0.9
	if progress >= 1.0:
		progress = 0.0
		var options: Array = park.path_neighbors(next_cell)
		var came := cell
		cell = next_cell
		if options.size() > 1:
			options.erase(came)
		next_cell = options.pick_random() if not options.is_empty() else cell
	var from: Vector2 = park.cell_center(cell)
	var to: Vector2 = park.cell_center(next_cell)
	santa.position = from.lerp(to, progress) + Vector2(0, 4)
	var frames: Dictionary = DinoArt.frames(SANTA)
	if absf(to.x - from.x) > 1.0:
		santa_sprite.flip_h = to.x < from.x
	santa_sprite.offset.x = -(frames.size.x - frames.origin.x) if santa_sprite.flip_h else -frames.origin.x
	if to != from:
		phase += delta * 6.0
	santa_sprite.texture = frames.walk[int(phase) % frames.walk.size()]
	hat.queue_redraw()
	bubble_timer -= delta
	var near: bool = park.player.position.distance_to(santa.position) < 2.0 * T
	if near and not opened.has(today()):
		_give_present()
	elif bubble_timer <= 0.0:
		bubble_timer = 7.0
		park.float_text(santa.position + Vector2(0, -frames.height - 10), "Ho ho ho !" if opened.has(today()) else "Viens chercher ton cadeau !", Color("ffcdd2"))


func _add_santa() -> void:
	santa = Node2D.new()
	park.world.add_child(santa)
	var frames: Dictionary = DinoArt.frames(SANTA)
	santa_sprite = Art.sprite(frames.walk[0], frames.origin)
	santa.add_child(santa_sprite)
	hat = Node2D.new()
	santa.add_child(hat)
	hat.draw.connect(_draw_hat)
	cell = park.ENTRANCE
	next_cell = cell
	# The top of the head: the highest pixel of the front third of the drawing.
	var image: Image = frames.walk[0].get_image()
	var best := Vector2i(image.get_width() - 1, image.get_height())
	for x in range(image.get_width() * 2 / 3, image.get_width()):
		for y in image.get_height():
			if image.get_pixel(x, y).a > 0.5:
				if y < best.y:
					best = Vector2i(x, y)
				break
	head = Vector2(best) - frames.origin + Vector2(-1, 1)


# A red hat with white fur and a white pompom, on the head of the T-Rex.
func _draw_hat() -> void:
	var side := -1.0 if santa_sprite.flip_h else 1.0
	var top := Vector2(head.x * side, head.y)
	hat.draw_colored_polygon(PackedVector2Array([top + Vector2(-5, 0), top + Vector2(5, 0), top + Vector2(-2 * side, -9)]), Color("e53935"))
	hat.draw_rect(Rect2(top + Vector2(-6, -1), Vector2(12, 3)), Color("f4f4f4"))
	hat.draw_circle(top + Vector2(-3 * side, -9), 2.0, Color("f4f4f4"))


func _give_present() -> void:
	opened[today()] = true
	var date := Time.get_date_dict_from_system()
	var text: String
	if date.month == 12 and date.day == 25:
		park.inventory.add(CHRISTMAS_DAY)
		park.rares[Items.dino_species(CHRISTMAS_DAY) + ":" + Items.dino_variant(CHRISTMAS_DAY)] = true
		text = "JOYEUX NOËL !\nLe T-Rex de Noël t'offre un %s !\nIl est dans « Mes dinos »." % Catalog.dino_name("trex", "dore")
	else:
		var present: Dictionary = ADVENT[date.day - 1] if date.month == 12 and date.day <= 24 else AFTER
		_give(present)
		text = "Le T-Rex de Noël t'offre : %s !" % _describe(present)
		if date.month == 12 and date.day < 25:
			text += "\nReviens demain pour un autre cadeau !\nLe 25 décembre : une surprise rare…"
	park.float_text(santa.position + Vector2(0, -40), "♥", Color("ff80ab"))
	park.hud.flash(text, 6.0)
	park.save_game()


func _give(present: Dictionary) -> void:
	for id in present:
		if id == "coins":
			park.money += present.coins
		else:
			park.inventory.add(id, present[id])


func _describe(present: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in present:
		parts.append("%d pièces" % present.coins if id == "coins" else "%s ×%d" % [Items.name_of(id), present[id]])
	return ", ".join(parts)


# --- Presents hidden in the Wild Lands ----------------------------------------------

# Called when the player arrives in a wild zone: hides its present of the day. Returns a line to
# say, or "".
func on_zone() -> String:
	gift_at = Vector2.ZERO
	if not active() or park.zone == park.Wild.BASE:
		return ""
	var key: String = park.Wild.key(park.zone)
	if found.get(key, "") == today():
		return ""
	for attempt in 60:
		var spot := Vector2i(randi_range(3, park.GRID.x - 4), randi_range(3, park.GRID.y - 4))
		if park.player != null and Vector2(spot - park.player.cell()).length() < 12.0:
			continue
		if park.occupied.has(spot) or park.is_water(spot) or park.player_blocked(spot):
			continue
		gift_at = park.cell_center(spot)
		return "Un cadeau de Noël est caché dans cette zone !"
	return ""


func _open_gift() -> void:
	found[park.Wild.key(park.zone)] = today()
	gift_at = Vector2.ZERO
	var present: Dictionary = GIFTS.pick_random()
	_give(present)
	park.hud.flash("Un cadeau de Noël ! Dedans : %s" % _describe(present), 4.0)


func _draw() -> void:
	if gift_at == Vector2.ZERO or park == null or park.zone == park.Wild.BASE or park.away != null:
		return
	var texture: Texture2D = Art.decor("gift")
	var bob := absf(sin(time * 3.0)) * 2.0
	draw_texture(texture, gift_at - Vector2(texture.get_width() / 2.0, texture.get_height() + bob - 4))
	var glow := 0.5 + 0.5 * sin(time * 6.0)
	var star := gift_at + Vector2(7, -16 - bob)
	draw_line(star - Vector2(3, 0), star + Vector2(3, 0), Color(1, 1, 0.7, glow), 1.0)
	draw_line(star - Vector2(0, 3), star + Vector2(0, 3), Color(1, 1, 0.7, glow), 1.0)

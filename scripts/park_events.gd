extends Node2D

# Things that happen in the park now and then, to give it life:
#   - babies: two happy dinosaurs of the same species in an enclosure have a baby;
#   - the journalist of the "Dino Journal" visits the park, then gives it stars in the paper;
#   - a little visitor lost a plush dinosaur in the park: the player finds it (adventure only);
#   - a party with fireworks when the park welcomes 100, 250, 500... visitors.
# Events only happen while the player is in the park (the park does not live while away).

const Catalog := preload("res://scripts/catalog.gd")
const DinoArt := preload("res://scripts/dino_art.gd")
const Visitor := preload("res://scripts/visitor.gd")
const WorldText := preload("res://scripts/world_text.gd")
const T := 16

const BIRTH_EVERY := 20.0  # seconds between two looks for parents
const BIRTH_CHANCE := 0.1  # for each pair of happy parents, at each look
const MAX_OWN_DINOS := 80
const DOUDOU_TIME := 300.0  # seconds before somebody else finds the plush
const PARTY_TIME := 40.0
const BOOST_TIME := 90.0  # after the journalist's article or a party, visitors come twice as fast
const MILESTONES := [100, 250, 500, 1000, 2000, 3500, 5000, 7500, 10000]
const VIP_OUTFIT := {"shirt": Color("2e2e44"), "pants": Color("2e2e44"), "hat": Color("c62828")}
const VIP_THOUGHTS := ["Hmm… je prends des notes.", "Intéressant…", "Je note, je note…", "Voyons voir ce parc…"]
# What the article says is missing, for each line of park.rating_lines().
const MISSING := {"Dinos montrés aux visiteurs": "plus de dinos à regarder", "Dinos heureux": "des dinos plus heureux",
	"À manger": "des glaces et des burgers", "Souvenirs": "une boutique souvenirs",
	"Décoration": "des fleurs, des bancs et des poubelles", "Attractions": "une attraction"}
const FIREWORK_COLORS := [Color("ff5252"), Color("ffd740"), Color("69f0ae"), Color("40c4ff"), Color("e040fb"), Color("ffffff")]

var park: Node2D
var current := ""  # the event going on: "", "vip", "doudou" or "party"
var next_event := 60.0
var birth_timer := BIRTH_EVERY
var boost_until := 0.0
var calm_until := 0.0  # a few seconds between two events, to read the message of the first one
var time := 0.0

# Kept with the game.
var born := 0  # babies born in the enclosures
var vip_visits := 0
var doudous := 0  # plushes found
var party_index := -1  # the last milestone celebrated, -1 for none

var vip: Node2D = null
var vip_scared := false
var doudou := Vector2.ZERO
var doudou_left := 0.0
var party_left := 0.0
var rocket_timer := 0.0
var rockets: Array[Dictionary] = []  # {pos, vel, color, fuse}
var sparks: Array[Dictionary] = []  # {pos, vel, color, life}


func setup(owner_park: Node2D) -> void:
	park = owner_park
	z_index = 100


func to_dict() -> Dictionary:
	return {"born": born, "vip": vip_visits, "doudous": doudous, "party": party_index}


func from_dict(data: Dictionary) -> void:
	born = int(data.get("born", 0))
	vip_visits = int(data.get("vip", 0))
	doudous = int(data.get("doudous", 0))
	if data.has("party"):
		party_index = int(data.party)
	else:
		# A game from before the parties: the milestones already passed are not celebrated.
		party_index = -1
		while party_index + 1 < MILESTONES.size() and park.total_visitors >= MILESTONES[party_index + 1]:
			party_index += 1


# Visitors come faster for a while after an article or a party.
func visitor_boost() -> float:
	return 0.5 if park.clock < boost_until else 1.0


func in_park() -> bool:
	return park.mode in ["creative", "adventure"] and park.zone == park.Wild.BASE and park.away == null and not park.loading


func _process(delta: float) -> void:
	time += delta
	_move_fireworks(delta)
	queue_redraw()
	if park == null:
		return
	if current == "vip":
		_follow_vip()
	if not in_park():
		return
	birth_timer -= delta
	if birth_timer <= 0.0:
		birth_timer = BIRTH_EVERY
		_births()
	match current:
		"doudou":
			_look_for_doudou(delta)
		"party":
			_party(delta)
		"":
			if park.clock < calm_until:
				return
			if _party_due():
				_start_party()
				return
			next_event -= delta
			if next_event <= 0.0:
				next_event = 20.0  # nothing could start: try again soon
				_start_event()


func _end_event() -> void:
	current = ""
	calm_until = park.clock + 10.0
	next_event = randf_range(120.0, 200.0)


func _start_event() -> void:
	var can := []
	if park.attraction > 0 and not park.get_tree().get_nodes_in_group("visitors").is_empty():
		can.append("vip")
		if park.mode == "adventure" and park.player != null:
			can.append("doudou")
	if can.is_empty():
		return
	# The event a goal of the level is waiting for comes first.
	var wanted: Array = can.filter(func(id: String) -> bool: return park.mode == "adventure" and \
		park.goals_left().any(func(goal: Array) -> bool: return goal[0] == id))
	var id: String = (wanted if not wanted.is_empty() else can).pick_random()
	if id == "vip":
		_start_vip()
	else:
		_start_doudou()


# --- Babies -------------------------------------------------------------------

func _births() -> void:
	var own: Array = park.dinos.filter(func(d) -> bool: return not d.wild)
	if own.size() >= MAX_OWN_DINOS:
		return
	var groups := {}  # region -> species -> happy grown-ups
	var crowd := {}  # region -> dinosaurs living there
	for dino in own:
		if dino.habitat != "land" or dino.escaped or dino.ridden or dino.following != null or dino.region < 0:
			continue
		crowd[dino.region] = crowd.get(dino.region, 0) + 1
		if dino.need != "" or dino.age < 1.0:
			continue
		var by_species: Dictionary = groups.get_or_add(dino.region, {})
		by_species.get_or_add(dino.species_id, []).append(dino)
	for region in groups:
		if region >= park.regions.size() or not park.regions[region].enclosed:
			continue
		for species_id in groups[region]:
			var parents: Array = groups[region][species_id]
			if parents.size() < 2:
				continue
			# Only when the baby has room to grow up.
			if park.regions[region].cells.size() / (crowd[region] + 1) < Catalog.DINOS[species_id].space:
				continue
			if randf() < BIRTH_CHANCE:
				_birth(species_id, parents[0], parents[1], region)
				return


func _birth(species_id: String, mother: Node2D, father: Node2D, region: int) -> void:
	var cell: Vector2i = park.random_cell_near(mother.cell, 2, region)
	if cell == park.NONE:
		return
	var baby: Node2D = park._place_dino(species_id, cell, true)
	if baby == null:
		return
	baby.age = 0.0
	born += 1
	if park.mode == "adventure":
		park._mark_caught(species_id)
	for parent in [mother, father]:
		park.float_text(parent.position + Vector2(0, -parent.frames.height), "♥", Color("ff80ab"))
	park.float_text(baby.position + Vector2(0, -20), "Bébé !", Color("ffccdd"))
	park.hud.flash("Un bébé %s est né dans ton parc !\nSes parents sont heureux ensemble." % Catalog.DINOS[species_id].name, 4.0)


# --- The journalist -------------------------------------------------------------

func _start_vip() -> void:
	vip = Visitor.new()
	vip.add_to_group("visitors")
	park.world.add_child(vip)
	vip.setup(park, park.ENTRANCE, "vip", VIP_OUTFIT)
	vip.steps_left = 70
	vip_scared = false
	WorldText.make(vip, Vector2(0, -36), "Dino Journal", "sign")
	current = "vip"
	park.hud.flash("Le journaliste du Dino Journal visite ton parc !\nIl va écrire un article : montre-lui un beau parc.", 4.5)


func vip_thought(_visitor: Node2D) -> String:
	var ideas: Array = VIP_THOUGHTS.duplicate()
	var line := _worst_line()
	if not line.is_empty():
		ideas.append("Il manque quelque chose ici…")
	if park.rating >= 60:
		ideas.append("Oh, magnifique !")
	return ideas.pick_random()


# The journalist walks until he leaves (or runs away from an escaped dinosaur), then writes.
func _follow_vip() -> void:
	if is_instance_valid(vip) and not vip.is_queued_for_deletion():
		vip_scared = vip_scared or vip.scared
		return
	vip = null
	vip_visits += 1
	var article: String
	var stars: int
	if vip_scared:
		stars = 1
		article = "« Un dino échappé m'a fait très peur ! »"
	else:
		stars = clampi(park.rating / 20 + 1, 1, 5)
		var line := _worst_line()
		article = "« Un parc parfait ! »" if line.is_empty() else "« Bien, mais il manque %s. »" % MISSING.get(line[0], "quelque chose")
	var gift: int = 50 + 4 * park.rating if not vip_scared else 20
	park.money += gift
	boost_until = park.clock + BOOST_TIME
	park.hud.flash("Le Dino Journal donne %s à ton parc !\n%s\n+%d pièces, et plein de visiteurs lisent l'article !" % [
		"★".repeat(stars) + "☆".repeat(5 - stars), article, gift], 7.0)
	_end_event()


# The part of the mark of the park that misses the most points, from park.rating_lines().
func _worst_line() -> Array:
	var worst := []
	var gap := 2
	for line in park.rating_lines():
		if line[2] - line[1] > gap:
			worst = line
			gap = line[2] - line[1]
	return worst


# --- The lost plush ----------------------------------------------------------------

func _start_doudou() -> void:
	var spots := []
	for building in park.buildings:
		if building.kind == "path" and park.distance.get(building.origin, 0) >= 6:
			spots.append(building.origin)
	if spots.is_empty():
		return
	var cell: Vector2i = spots.pick_random()
	# Dropped in the grass next to the path when there is room.
	for dir in park.DIRS:
		var side: Vector2i = cell + dir
		if park.in_grid(side) and not park.occupied.has(side) and not park.is_water(side):
			cell = side
			break
	doudou = park.cell_center(cell)
	doudou_left = DOUDOU_TIME
	current = "doudou"
	var visitors: Array = park.get_tree().get_nodes_in_group("visitors")
	if not visitors.is_empty():
		var crying: Node2D = visitors.pick_random()
		var bubble := WorldText.make(crying, Vector2(0, -26), "Mon doudou… snif !", "bubble")
		var tween := bubble.create_tween()
		tween.tween_interval(4.0)
		tween.tween_callback(bubble.queue_free)
	park.hud.flash("Un petit visiteur a perdu son doudou dino !\nRetrouve-le dans le parc : suis la flèche jaune.", 4.5)


func _look_for_doudou(delta: float) -> void:
	doudou_left -= delta
	if doudou_left <= 0.0:
		park.hud.flash("Un visiteur a retrouvé le doudou à ta place.", 3.0)
		_end_event()
		return
	if park.player.position.distance_to(doudou) > 0.9 * T:
		return
	doudous += 1
	var gift: int = 60 + 30 * park.stars
	park.money += gift
	park.float_text(doudou + Vector2(0, -16), "Doudou !", Color("ffccdd"))
	park.hud.flash("Tu as retrouvé le doudou ! Le petit visiteur est tout content.\n+%d pièces" % gift, 4.0)
	_end_event()


# Where the yellow arrow points while a plush is lost, or null.
func arrow_target():
	return doudou if current == "doudou" and in_park() else null


# --- Parties ---------------------------------------------------------------------

func _party_due() -> bool:
	return party_index + 1 < MILESTONES.size() and park.total_visitors >= MILESTONES[party_index + 1]


func _start_party() -> void:
	party_index += 1
	var count: int = MILESTONES[party_index]
	current = "party"
	party_left = PARTY_TIME
	rocket_timer = 0.0
	boost_until = park.clock + BOOST_TIME
	park.money += count
	park.hud.flash("C'est la fête ! Ton parc a accueilli %d visiteurs !\nFeu d'artifice ! +%d pièces" % [count, count], 5.0)


func _party(delta: float) -> void:
	party_left -= delta
	if party_left <= 0.0:
		_end_event()
		return
	rocket_timer -= delta
	if rocket_timer <= 0.0:
		rocket_timer = randf_range(0.3, 0.9)
		_launch_rocket()


func _launch_rocket() -> void:
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()
	var from := Vector2(randf_range(view.position.x + view.size.x * 0.15, view.end.x - view.size.x * 0.15), view.end.y)
	var height := randf_range(view.size.y * 0.4, view.size.y * 0.7)
	rockets.append({"pos": from, "vel": Vector2(randf_range(-20.0, 20.0), -height / 0.8),
		"color": FIREWORK_COLORS.pick_random(), "fuse": 0.8, "size": view.size.y / 160.0})


func _move_fireworks(delta: float) -> void:
	for rocket in rockets:
		rocket.pos += rocket.vel * delta
		rocket.fuse -= delta
		if rocket.fuse <= 0.0:
			var count := 36
			var size: float = rocket.size
			for i in count:
				var angle := TAU * i / count + randf_range(-0.1, 0.1)
				sparks.append({"pos": rocket.pos, "vel": Vector2.from_angle(angle) * randf_range(25.0, 40.0) * size,
					"color": rocket.color, "life": randf_range(1.0, 1.6), "size": size})
	rockets = rockets.filter(func(r: Dictionary) -> bool: return r.fuse > 0.0)
	for spark in sparks:
		spark.vel.y += 8.0 * spark.size * delta
		spark.vel *= 1.0 - 1.5 * delta
		spark.pos += spark.vel * delta
		spark.life -= delta
	sparks = sparks.filter(func(s: Dictionary) -> bool: return s.life > 0.0)


func _draw() -> void:
	for rocket in rockets:
		var size: float = rocket.size
		draw_rect(Rect2(rocket.pos - Vector2(size, size), Vector2(size * 2.0, size * 3.0)), Color("fff3c0"))
		draw_line(rocket.pos, rocket.pos - rocket.vel * 0.05, Color(1, 0.85, 0.5, 0.6), size)
	for spark in sparks:
		var color: Color = spark.color
		color.a = clampf(spark.life, 0.0, 1.0)
		var size: float = spark.size * 1.5
		draw_line(spark.pos, spark.pos - spark.vel * 0.06, Color(color, color.a * 0.5), size * 0.7)
		draw_rect(Rect2(spark.pos - Vector2(size, size) / 2.0, Vector2(size, size)), color)
	if current == "doudou" and in_park():
		_draw_doudou()


# A pink plush triceratops lying in the grass, with a little sparkle to be seen.
func _draw_doudou() -> void:
	var frames: Dictionary = DinoArt.frames("triceratops")
	var texture: Texture2D = frames.walk[0]
	var scale := 0.4
	var bob := absf(sin(time * 3.0)) * 2.0
	draw_circle(doudou + Vector2(0, 1), 6.0, Color(0, 0, 0, 0.25))
	draw_set_transform(doudou + Vector2(0, -bob), 0.0, Vector2(scale, scale))
	draw_texture(texture, -frames.origin, Color(1.0, 0.72, 0.86))
	draw_set_transform(Vector2.ZERO)
	var glow := 0.5 + 0.5 * sin(time * 6.0)
	var star := doudou + Vector2(6, -14 - bob)
	draw_line(star - Vector2(3, 0), star + Vector2(3, 0), Color(1, 1, 0.7, glow), 1.0)
	draw_line(star - Vector2(0, 3), star + Vector2(0, 3), Color(1, 1, 0.7, glow), 1.0)

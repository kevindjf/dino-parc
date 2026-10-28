extends Node2D

const Catalog := preload("res://scripts/catalog.gd")
const Art := preload("res://scripts/art.gd")
const Ground := preload("res://scripts/ground.gd")
const Dino := preload("res://scripts/dino.gd")
const Visitor := preload("res://scripts/visitor.gd")
const Vehicle := preload("res://scripts/vehicle.gd")
const PlayerVehicle := preload("res://scripts/player_vehicle.gd")
const Helicopter := preload("res://scripts/helicopter.gd")
const Hud := preload("res://scripts/hud.gd")
const ParkCamera := preload("res://scripts/park_camera.gd")
const WorldText := preload("res://scripts/world_text.gd")
const FlipBook := preload("res://scripts/flip_book.gd")
const Items := preload("res://scripts/items.gd")
const Inventory := preload("res://scripts/inventory.gd")
const Player := preload("res://scripts/player.gd")
const AdventureHud := preload("res://scripts/adventure_hud.gd")
const Title := preload("res://scripts/title.gd")
const Creator := preload("res://scripts/creator.gd")
const SaveGame := preload("res://scripts/save_game.gd")
const Worlds := preload("res://scripts/worlds.gd")
const Combat := preload("res://scripts/combat.gd")
const Builder := preload("res://scripts/builder.gd")
const WorldGen := preload("res://scripts/world_gen.gd")
const Mine := preload("res://scripts/mine.gd")
const Village := preload("res://scripts/village.gd")
const House := preload("res://scripts/house.gd")
const Market := preload("res://scripts/market.gd")
const Wild := preload("res://scripts/wild.gd")

const T := 16
const GRID := Vector2i(128, 96)
const ENTRANCE := Vector2i(0, 48)
const OLD_GRID := Vector2i(64, 48)  # size of the map in the first versions
const TICKET_PRICE := 10
const MAX_VISITORS := 120
const DART_PRICE := 50
const FISH_PRICE := 10
const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const NONE := Vector2i(-1, -1)
const NOT_CONNECTED := 99999
# Land dinosaurs cannot walk through these.
const DINO_BLOCKERS := ["aviary", "lagoon", "shop", "gyro_station", "garage", "heliport", "campfire"]
const VEHICLE_BLOCKERS := ["aviary", "lagoon", "shop", "gyro_station", "garage", "feeder", "heliport", "campfire"]
# What can be built in the Wild Lands: enclosures are made in the park.
# Trunks stop the dinosaurs; they walk through bushes and ferns, which are low.
const DINO_TREES := ["tree", "pine", "palm", "cactus"]
const RIDE_HEARTS := 3  # friendship needed to put a saddle on a dinosaur and ride it
const WILD_BUILDS := ["campfire", "bridge", "path", "sapling", "bush"]
const MAX_MOUNTAIN_LEVEL := 5
const BORDER := 3  # rows of forest drawn around the park
const BERRY_REGROW := 25.0
const AUTOSAVE := 20.0
const WILD_TARGET := 30  # wild dinosaurs roaming the adventure land
const MAX_HEARTS := 5
const HEAL_EVERY := 6.0  # seconds to get a heart back, once nobody has hit us for a while

const ADVENTURE_GOALS := [
	{"id": "wood", "text": "Frappe un arbre pour récolter 5 bois (bouton Action ou Espace)"},
	{"id": "axe", "text": "Ouvre ton sac et fabrique une hache"},
	{"id": "pickaxe", "text": "Fabrique une pioche"},
	{"id": "stone", "text": "Casse un rocher avec la pioche pour avoir de la pierre"},
	{"id": "berries", "text": "Cueille des baies sur un buisson"},
	{"id": "pen", "text": "Fabrique des barrières et ferme un enclos (garde Action appuyé en marchant)"},
	{"id": "feeder", "text": "Fabrique un portail pour entrer dans ton enclos, puis pose une mangeoire dedans"},
	{"id": "path", "text": "Fais un chemin depuis l'entrée jusqu'à ton enclos"},
	{"id": "tame", "text": "Trouve un dinosaure herbivore sauvage et lance-lui 3 baies : il ira dans « Mes dinos »"},
	{"id": "adopt", "text": "Ouvre « Mes dinos », touche « Relâcher » et pose ton dinosaure dans ton enclos"},
	{"id": "cage", "text": "Fabrique un lance-pierre et une cage. Fatigue un petit dinosaure de loin, puis mets-le en cage"},
	{"id": "release", "text": "Relâche le dinosaure attrapé dans un enclos"},
	{"id": "brush", "text": "Fabrique une brosse et brosse un dinosaure de ton parc"},
	{"id": "friend", "text": "Gagne 3 cœurs d'amitié d'un gros dino de ton parc, comme un Tricératops (brosse-le, donne-lui à manger)"},
	{"id": "ride", "text": "Fabrique une selle, prends-la en main et appuie sur Action devant lui : tu montes sur son dos !"},
	{"id": "mine", "text": "Trouve une grotte dans les montagnes et descends dans la mine"},
	{"id": "ore", "text": "Creuse les murs de la mine pour trouver du fer et du cuivre"},
	{"id": "electric", "text": "Fabrique une barrière électrique : la seule qui retient un T-Rex !"},
	{"id": "dex5", "text": "Attrape 5 espèces différentes (bouton Dinodex)"},
	{"id": "dex10", "text": "Attrape 10 espèces différentes"},
]
const GOALS := [
	{"id": "pen", "text": "Ferme un enclos avec des barrières et mets-y un dinosaure"},
	{"id": "visible", "text": "Fais passer un chemin le long de la barrière pour que les visiteurs voient l'enclos"},
	{"id": "feeder", "text": "Pose une mangeoire dans l'enclos pour nourrir tes dinosaures"},
	{"id": "visitors", "text": "Accueille 50 visiteurs"},
	{"id": "aviary", "text": "Construis une volière et mets-y un dinosaure volant"},
	{"id": "gyro", "text": "Construis une station de gyrosphères contre un enclos"},
	{"id": "species", "text": "Présente 8 espèces de dinosaures"},
	{"id": "lagoon", "text": "Construis un lagon avec un Mosasaure"},
	{"id": "rich", "text": "Amasse 30000 pièces"},
]

var mode := ""  # "", then "creative" or "adventure"
var world_info := {}  # the world being played: id, name, mode, settings (see worlds.gd)
var money := 8000
var total_visitors := 0
var attraction := 0
var tool := "path"
var buildings: Array[Dictionary] = []
var occupied := {}  # Vector2i -> building Dictionary
var biomes: Array[String] = []  # one per cell
var distance := {}  # Vector2i -> steps from the entrance, along paths
var region_map := PackedInt32Array()  # region id per cell, -1 on walls
var regions: Array[Dictionary] = []
var dinos: Array[Node2D] = []
var hover := NONE
var painting := false
var erasing := false
var spawn_timer := 0.0
var attraction_timer := 0.0
var goal_index := 0
var hud: CanvasLayer
var ground: Node2D
var water := PackedByteArray()  # 1 where the cell is water (sea, river, lake)
var floor_layer: Node2D  # flat things lying on the ground: lagoons, heliport pads
var world: Node2D  # everything standing on the ground, drawn from back to front
var camera: Camera2D
var driving: Node2D = null
var ghost: Node2D
var ghost_rect := Rect2()
var ghost_color := Color.TRANSPARENT
var ghost_cells: Array[Dictionary] = []  # {cell, ok}: an enclosure being drawn in the sandbox
# Sandbox drawing helpers: whole enclosures from corner to corner, and undo.
var pen := false
var pen_start := NONE
var stroke_log: Array[Dictionary] = []  # {origin, id, cost}: what the current press has built
var undo_log: Array = []  # the last strokes, newest last
# Adventure mode.
var player: Node2D = null
var inventory: RefCounted = null
var look := {}
var loading := false  # while a park is being loaded or generated, slow refreshes wait for the end
var natural_target := 0
var nature_timer := 0.0
var save_timer := AUTOSAVE
var clock := 0.0
var caught := {}  # species id -> true: the Dinodex
var away: Node2D = null  # the zone the player is in away from the park (a mine or the village), or null
var surface_spot := Vector2.ZERO  # where the player comes back to the park
var mine: Node2D = null  # the mine the player is in, or null
var mine_states := {}  # entrance "x,y" -> {"seed", "dug"}, saved with the game
var village: Node2D = null  # the village, while the player is in it
var village_state := {}  # the chests already opened and the presents given, saved with the game
var house: Node2D = null  # the inside of a village house, while the player is in it
# Doors and ladders are taken just by walking into them. Right after arriving somewhere, they
# wait until the player stops or changes direction, so holding the stick does not go back at once.
var door_wait := false
var door_wait_dir := Vector2i.ZERO
var world_bounds := Rect2()
var combat: Node2D = null
var builder: Node2D = null
var hearts := MAX_HEARTS
var safe_until := 0.0  # after a hit, a short time when nothing can hit us again
var heal_timer := 0.0
var gate_warned := 0.0
var zone := Wild.BASE  # the zone of the Wild Lands the player is in (see wild.gd)
var world_seed := 0  # makes the same wild zones every time in this world
var base_land := {}  # the park, saved while the player is in a wild zone
var left_base_at := 0.0  # when the player left the park, to pay the visitors who came meanwhile
var zone_states := {}  # zone key -> what the player changed there, saved with the game
var base_exits := {}  # "up" / "down" / "left" / "right" -> where the trails out of the park are
var border_nodes: Array[Node] = []  # the forest around the zone and the signs of its trails
var respawn := {}  # {"zone", "x", "y"}: the last campfire the player rested by, where they wake up


func _ready() -> void:
	biomes.resize(GRID.x * GRID.y)
	biomes.fill("prairie")
	region_map.resize(GRID.x * GRID.y)
	water.resize(GRID.x * GRID.y)
	var text_layer := CanvasLayer.new()
	text_layer.layer = 1
	add_child(text_layer)
	WorldText.layer = text_layer
	_build_world()
	_add_building("path", ENTRANCE, true)
	_refresh()
	if "--demo" in OS.get_cmdline_user_args():
		start_creative(true)
		return
	Worlds.migrate_old_saves()
	var title := Title.new()
	title.chosen.connect(_on_world_chosen)
	add_child(title)


func _on_world_chosen(info: Dictionary) -> void:
	world_info = info
	if info.mode == "creative":
		start_creative(false)
	elif SaveGame.exists(info.id):
		start_adventure(SaveGame.load_data(info.id))
	else:
		var creator := Creator.new()
		creator.done.connect(func(new_look: Dictionary) -> void:
			look = new_look
			start_adventure({}))
		add_child(creator)


# A setting of the world being played (see Worlds.SETTINGS).
func setting(key: String) -> Variant:
	return Worlds.setting(world_info, key)


func start_creative(demo: bool) -> void:
	mode = "creative"
	hud = Hud.new()
	add_child(hud)
	hud.tool_selected.connect(_on_tool_selected)
	hud.zoom_requested.connect(camera.zoom_step)
	camera.remember("creative", 2)
	hud.exit_vehicle.connect(stop_driving)
	hud.menu_requested.connect(back_to_menu)
	hud.pen_toggled.connect(func(on: bool) -> void: pen = on)
	hud.undo_requested.connect(_undo_stroke)
	if demo:
		_build_demo()
		mode = "demo"
	elif SaveGame.exists(world_info.id):
		_load_park(SaveGame.load_data(world_info.id))
	_refresh()
	_on_tool_selected("path")
	hud.flash("Molette : zoomer   Flèches ou ZQSD : se déplacer", 4.0)


# data: a saved game, or {} for a new adventure (then `look` was set by the creation screen).
func start_adventure(data: Dictionary) -> void:
	mode = "adventure"
	money = 0
	inventory = Inventory.new()
	var start := cell_center(ENTRANCE + Vector2i(3, 0))
	world_seed = int(data.get("seed", randi() % 1000000000))
	zone_states = data.get("zones", {})
	respawn = data.get("respawn", {})
	base_exits = data.get("exits", {})
	if data.is_empty():
		loading = true
		WorldGen.generate(self, randi())
		_finish_loading()
	else:
		var offset := _load_park(data)
		var saved: Dictionary = data.get("player", {})
		look = SaveGame.look_from(saved.get("look", {}))
		inventory.from_dict(saved.get("inventory", {}))
		start = Vector2(saved.get("x", start.x), saved.get("y", start.y)) + Vector2(offset * T)
		mine_states = data.get("mines", {})
		village_state = data.get("village", {})
	_carve_base_exits()
	_build_border()
	natural_target = _count_nature()
	caught = {}
	for id in data.get("caught", []):
		caught[id] = true
	_spawn_wild_dinos(WILD_TARGET)
	hud = AdventureHud.new()
	add_child(hud)
	hud.setup(self, inventory, look.get("name", ""))
	player = Player.new()
	world.add_child(player)
	player.setup(self, Creator.colors_of(look), start)
	combat = Combat.new()
	add_child(combat)
	combat.setup(self)
	builder = Builder.new()
	add_child(builder)
	builder.setup(self)
	hud.setup_builder(builder)
	hud.set_hearts(hearts, MAX_HEARTS)
	# A sign by the park gate shows the road to the village.
	camera.position = start
	camera.remember("adventure", 1)
	camera.follow(player)
	_refresh()
	var saved_zone := Wild.from_key(str(data.get("zone", Wild.key(Wild.BASE))))
	if saved_zone != Wild.BASE and Wild.in_world(saved_zone):
		travel(saved_zone, start)
	if data.is_empty():
		hud.flash("Bienvenue %s !\nVa frapper un arbre pour récolter du bois." % look.name, 4.0)
		save_game()


# Saves, then starts the game over on the title screen.
func back_to_menu() -> void:
	save_game()
	get_tree().reload_current_scene()


func save_game() -> void:
	if (mode == "creative" or mode == "adventure") and world_info.has("id"):
		SaveGame.save(self)


func _notification(what: int) -> void:
	# On the web and on tablets the game is rarely closed: save when it goes to the background too.
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		save_game()


# Returns how far everything was moved: a park saved on the first, smaller map is placed
# by the entrance of the big one, and new wild land is made all around it.
func _load_park(data: Dictionary) -> Vector2i:
	loading = true
	money = int(data.get("money", money))
	total_visitors = int(data.get("total_visitors", total_visitors))
	goal_index = int(data.get("goal_index", goal_index))
	var saved_size := Vector2i(int(data.grid[0]), int(data.grid[1])) if data.has("grid") else OLD_GRID
	var offset := Vector2i.ZERO
	if saved_size != GRID:
		offset = Vector2i(0, ENTRANCE.y - saved_size.y / 2)
		if mode == "adventure":
			WorldGen.generate(self, randi())
		for y in range(-1, saved_size.y + 1):
			for x in range(0, saved_size.x + 1):
				var cell := Vector2i(x, y) + offset
				if in_grid(cell):
					remove_natural(cell)
					set_water(cell, false)
	elif data.has("water"):
		var saved_water := Marshalls.base64_to_raw(data.water)
		if saved_water.size() == water.size():
			water = saved_water
	var saved_biomes: Array = data.get("biomes", [])
	if saved_biomes.size() == saved_size.x * saved_size.y:
		for i in saved_biomes.size():
			var cell := Vector2i(i % saved_size.x, i / saved_size.x) + offset
			if in_grid(cell):
				biomes[_index(cell)] = saved_biomes[i] if Catalog.BIOMES.has(saved_biomes[i]) else "prairie"
	for entry in data.get("buildings", []):
		if not Catalog.ITEMS.has(entry.id):
			continue
		var origin := Vector2i(int(entry.x), int(entry.y)) + offset
		if not _is_free(origin, Catalog.size_of(Catalog.ITEMS[entry.id])):
			continue
		var building := _add_building(entry.id, origin)
		building.stock = int(entry.get("stock", building.stock))
		if not entry.get("ready", true):
			_empty_bush(building)
	_finish_loading()
	for entry in data.get("dinos", []):
		if not Catalog.DINOS.has(entry.id):
			continue
		var cell := Vector2i(int(entry.x), int(entry.y)) + offset
		if entry.get("wild", false):
			if in_grid(cell) and region_map[_index(cell)] >= 0:
				_spawn_wild(entry.id, cell, int(entry.get("trust", 0)))
			continue
		if entry.has("home"):
			cell = Vector2i(int(entry.home[0]), int(entry.home[1])) + offset
		var dino := _place_dino(entry.id, cell, true)
		if dino:
			dino.friendship = int(entry.get("friendship", 0))
			dino.set_saddled(entry.get("saddled", false))
	return offset


# After a load or a generation: shape the mountains, link the fences and repaint the whole ground.
func _finish_loading() -> void:
	loading = false
	for building in buildings:
		match building.kind:
			"mountain":
				building.level = _mountain_level(building.origin)
			"fence":
				_rebuild_fences_around(building.origin)
	ground.refresh(GRID / 2, maxi(GRID.x, GRID.y))
	_refresh()


func _process(delta: float) -> void:
	if mode == "":
		return
	clock += delta
	if mode == "adventure":
		_process_adventure(delta)
	elif driving:
		ghost.visible = false
		_update_gates(driving.position if driving.kind == "walk" else Vector2(-999, -999))
	else:
		var cell := _mouse_cell()
		if cell != hover:
			hover = cell
			if painting and _drag_allowed() and not _pen_active():
				_apply(cell)
			_update_hover_info()
		_update_ghost()
	if mode == "creative":
		save_timer -= delta
		if save_timer <= 0.0:
			save_timer = AUTOSAVE
			save_game()

	var on_site := get_tree().get_nodes_in_group("visitors").size()
	if attraction > 0 and on_site < MAX_VISITORS:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_timer = clamp(60.0 / attraction, 0.3, 5.0)
			_spawn_visitor()
	attraction_timer -= delta
	if attraction_timer <= 0.0:
		attraction_timer = 0.5
		_update_attraction()
	_check_goal()
	hud.update_stats(money, on_site, total_visitors, attraction)


# --- Input -------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if mode == "adventure" or mode == "":
		return
	if driving:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			stop_driving()
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			painting = event.pressed
			erasing = event.button_index == MOUSE_BUTTON_RIGHT or tool == "bulldozer"
			if _pen_active():
				# Enclosure: nothing is built before the finger or the button is released.
				if event.pressed:
					pen_start = _mouse_cell()
				elif pen_start != NONE:
					for step in _pen_plan(pen_start, _mouse_cell()):
						if step.ok:
							_build(step.id, step.cell)
					pen_start = NONE
					ghost_cells.clear()
					_finish_stroke()
				return
			if event.pressed:
				_apply(_mouse_cell())
			else:
				_finish_stroke()


func _on_tool_selected(id: String) -> void:
	tool = id
	if driving:
		stop_driving()
	_update_hover_info()


func _drag_allowed() -> bool:
	if erasing or tool.begins_with("biome:"):
		return true
	return Catalog.ITEMS.has(tool) and Catalog.size_of(Catalog.ITEMS[tool]) == Vector2i.ONE


func _apply(cell: Vector2i) -> void:
	if not in_grid(cell):
		return
	if erasing:
		_demolish(cell)
	elif tool.begins_with("biome:"):
		_paint_biome(cell, tool.substr(6))
	elif tool.begins_with("dino:"):
		_place_dino(tool.substr(5), cell)
	elif tool.begins_with("drive:"):
		start_driving(tool.substr(6), cell)
	elif tool == "dart":
		_shoot_dart(cell)
	else:
		_build(tool, cell)


func _spend(cost: int) -> bool:
	if money < cost:
		hud.flash("Pas assez de pièces !")
		return false
	money -= cost
	return true


# --- Building ----------------------------------------------------------

func _build(id: String, cell: Vector2i) -> void:
	var item: Dictionary = Catalog.ITEMS[id]
	var size := Catalog.size_of(item)
	var origin := cell - size / 2
	if not _is_free(origin, size):
		return
	if not _spend(item.cost):
		return
	_add_building(id, origin)
	stroke_log.append({"origin": origin, "id": id, "cost": item.cost})
	_refresh()


# --- Sandbox: enclosures and undo ------------------------------------------------

func _pen_active() -> bool:
	return pen and Catalog.ITEMS.has(tool) and Catalog.ITEMS[tool].kind == "fence" and tool != "gate_wood" and not erasing


# The fences of an enclosure from corner `a` to corner `b`, with a gate in the middle of the bottom.
func _pen_plan(a: Vector2i, b: Vector2i) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var low := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var high := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	var gate := Vector2i((low.x + high.x) / 2, high.y) if (high - low).x >= 2 and (high - low).y >= 2 else NONE
	var left := money
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			if x != low.x and x != high.x and y != low.y and y != high.y:
				continue
			var cell := Vector2i(x, y)
			var id := "gate_wood" if cell == gate else tool
			var cost: int = Catalog.ITEMS[id].cost
			var ok := in_grid(cell) and _is_free(cell, Vector2i.ONE) and left >= cost
			if ok:
				left -= cost
			plan.append({"cell": cell, "id": id, "ok": ok})
	return plan


func _finish_stroke() -> void:
	if not stroke_log.is_empty():
		undo_log.append(stroke_log)
		stroke_log = []
		if undo_log.size() > 30:
			undo_log.pop_front()


# Takes back what the last stroke built, and gives all its coins back.
func _undo_stroke() -> void:
	if undo_log.is_empty():
		hud.flash("Rien à annuler")
		return
	var stroke: Array = undo_log.pop_back()
	var refund := 0
	for entry in stroke:
		var building = occupied.get(entry.origin)
		if building != null and building.id == entry.id and building.origin == entry.origin:
			_remove_building(building)
			refund += entry.cost
	money += refund
	hud.flash("Annulé (+%d pièces)" % refund)
	_refresh()


func _add_building(id: String, origin: Vector2i, fixed := false) -> Dictionary:
	var item: Dictionary = Catalog.ITEMS[id]
	var size := Catalog.size_of(item)
	var building := {
		"id": id, "kind": item.kind, "origin": origin, "size": size, "fixed": fixed, "open": false,
		"root": null, "label": null, "nodes": [], "dinos": [], "stock": item.get("stock", 0),
		"region_cell": NONE, "level": 0, "hits": 0, "ready": true,
	}
	for c in _cells(origin, size):
		occupied[c] = building
	buildings.append(building)
	# Standing things are anchored at the bottom center of their cells.
	var foot := Vector2((origin.x + size.x / 2.0) * T, (origin.y + size.y) * T - 1)

	match item.kind:
		"path", "road":
			if not loading:
				ground.refresh(origin)
		"fence":
			building.root = Art.sprite(Art.fence(item.style, []), Art.FENCE_ANCHOR)
			building.root.position = cell_center(origin)
			world.add_child(building.root)
			if not loading:
				_rebuild_fences_around(origin)
		"feeder", "shop", "decor", "aviary", "gyro_station", "garage":
			building.root = Art.sprite(Art.item(id))
			building.root.position = foot
			Art.ground_shadow(building.root, int(building.root.texture.get_width() * 0.8))
			world.add_child(building.root)
			match item.kind:
				"feeder":
					building.label = WorldText.make(building.root, Vector2(0, -24), "Vide !", "bubble", Color("d03030"))
					building.label.set_shown(false)
				"gyro_station":
					building.label = WorldText.make(building.root, Vector2(0, -44), "Colle-moi contre la barrière d'un enclos !", "bubble", Color("d03030"))
				"garage":
					building.label = WorldText.make(building.root, Vector2(0, -40), "Il faut une route à côté !", "bubble", Color("d03030"))
			if item.get("style", "") == "volcano":
				_add_smoke(building.root)
		"lagoon":
			var water := FlipBook.new()
			var frames: Array[Texture2D] = []
			for i in 6:
				frames.append(Art.lagoon(size, i))
			water.setup(frames, 3.0)
			water.position = Vector2(origin * T)
			floor_layer.add_child(water)
			building.root = water
		"mountain":
			if not loading:
				_reshape_mountains_around(origin)
		"mine":
			building.root = Art.sprite(Art.mine_entrance())
			building.root.position = foot
			world.add_child(building.root)
		"campfire":
			building.lit = true
			_draw_fire(building)
		"heliport":
			building.root = Art.sprite(Art.heliport(), Vector2.ZERO)
			building.root.position = Vector2(origin * T)
			floor_layer.add_child(building.root)
			var helicopter := Helicopter.new()
			world.add_child(helicopter)
			helicopter.setup(self, building)
			building.nodes.append(helicopter)
	return building


func _add_smoke(volcano: Node2D) -> void:
	var smoke := CPUParticles2D.new()
	smoke.position = Vector2(0, -36)
	smoke.amount = 14
	smoke.lifetime = 3.0
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 15.0
	smoke.gravity = Vector2(4, -6)
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 4.0
	var fade := Gradient.new()
	fade.set_color(0, Color(0.45, 0.42, 0.42, 0.8))
	fade.set_color(1, Color(0.7, 0.7, 0.7, 0.0))
	smoke.color_ramp = fade
	volcano.add_child(smoke)


func _demolish(cell: Vector2i) -> void:
	var building = occupied.get(cell)
	if building == null:
		var dino := _dino_near(cell_center(cell), 14.0)
		if dino:
			var refund: int = dino.species.cost / 2
			money += refund
			_float_text(dino.position, "+%d" % refund, Color("ffe082"))
			_remove_dino(dino)
		return
	if building.fixed:
		return
	var refund: int = Catalog.ITEMS[building.id].cost / 2
	money += refund
	_float_text(cell_center(cell), "+%d" % refund, Color("ffe082"))
	_remove_building(building)


func _remove_building(building: Dictionary) -> void:
	for c in _cells(building.origin, building.size):
		occupied.erase(c)
	if building.root != null:
		building.root.queue_free()
	for node in building.nodes:
		if is_instance_valid(node):
			node.queue_free()
	for dino in building.dinos.duplicate():
		_remove_dino(dino)
	buildings.erase(building)
	match building.kind:
		"fence":
			_rebuild_fences_around(building.origin)
		"mountain":
			_reshape_mountains_around(building.origin)
		"path", "road":
			ground.refresh(building.origin)
	_refresh()


func _rebuild_fences_around(cell: Vector2i) -> void:
	for c in [cell, cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN]:
		if not _is_fence(c):
			continue
		var building: Dictionary = occupied[c]
		var links := []
		for dir in DIRS:
			if _is_fence(c + dir):
				links.append(dir)
		var style: String = Catalog.ITEMS[building.id].style
		building.links = links
		building.root.texture = Art.fence(style, links, style == "electric" and (c.x + c.y) % 5 == 0, building.get("gate_open", false))


# Gates open by themselves when someone walks up to them.
func _update_gates(walker: Vector2) -> void:
	for building in buildings:
		if building.id != "gate_wood":
			continue
		var near := cell_center(building.origin).distance_to(walker) < T * 1.6
		if near != building.get("gate_open", false):
			building.gate_open = near
			building.root.texture = Art.fence("gate", building.get("links", []), false, near)


func _paint_biome(cell: Vector2i, biome: String) -> void:
	var i := _index(cell)
	if biomes[i] == biome:
		return
	if not _spend(Catalog.BIOME_COST):
		return
	var region := region_map[i]
	if region >= 0:
		var counts: Dictionary = regions[region].biomes
		counts[biomes[i]] = counts.get(biomes[i], 0) - 1
		counts[biome] = counts.get(biome, 0) + 1
	biomes[i] = biome
	ground.refresh(cell, 0)


# --- Dinosaurs ---------------------------------------------------------

func _place_dino(id: String, cell: Vector2i, free := false) -> Node2D:
	var species: Dictionary = Catalog.DINOS[id]
	var home = _dino_home_at(species, cell)
	if home is String:
		if not free:
			hud.flash(home, 2.5)
		return null
	if not free and not _spend(species.cost):
		return null
	var dino := Dino.new()
	world.add_child(dino)
	dino.setup(self, id, cell, home)
	dinos.append(dino)
	if home != null:
		home.dinos.append(dino)
	else:
		var region := region_map[_index(cell)]
		dino.set_region(region, regions[region].enclosed)
	if not free:
		_float_text(cell_center(cell), species.name + " !", Color("a5f0a8"))
	_update_attraction()
	return dino


# Returns the aviary/lagoon for flyers and swimmers, null for land dinosaurs,
# or a message explaining why the dinosaur cannot go there.
func _dino_home_at(species: Dictionary, cell: Vector2i):
	var building = occupied.get(cell)
	match species.habitat:
		"air", "sea":
			var kind := "aviary" if species.habitat == "air" else "lagoon"
			if building == null or building.kind != kind:
				return "Les dinosaures volants vont dans une volière !" if kind == "aviary" else "Les reptiles marins vont dans un lagon !"
			if building.dinos.size() >= Catalog.ITEMS[building.id].capacity:
				return "C'est plein ici !"
			return building
	var region := region_map[_index(cell)]
	if region < 0 or not is_walkable_for_dino(cell, region):
		return "Choisis une case libre dans un enclos."
	if not regions[region].enclosed:
		return "Mets-le dans un enclos fermé par des barrières !"
	return null


func _remove_dino(dino: Node2D) -> void:
	dinos.erase(dino)
	if dino.home_building != null:
		dino.home_building.dinos.erase(dino)
	dino.queue_free()
	_update_attraction()


func _dino_near(at: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := radius
	for dino in dinos:
		if dino.habitat != "land":
			continue
		var d := dino.position.distance_to(at)
		if d < best_distance:
			best = dino
			best_distance = d
	return best


func _shoot_dart(cell: Vector2i) -> void:
	var dino := _dino_near(cell_center(cell), 29.0)
	if dino == null:
		hud.flash("Vise un dinosaure !")
		return
	if not _spend(DART_PRICE):
		return
	dino.sleep(4.0)
	_float_text(dino.position, "Zzz…", Color("b3e5fc"))


# Called when a darted dinosaur wakes up. Returns false if it has nowhere safe to go yet.
func return_dino(dino: Node2D) -> bool:
	if not dino.escaped:
		return true
	var target := -1
	var home := region_map[_index(dino.home_cell)]
	if home >= 0 and regions[home].enclosed:
		target = home
	else:
		for region in regions:
			if region.enclosed:
				target = region.id
				break
	if target < 0:
		hud.flash("Construis un enclos fermé pour %s !" % dino.species.name, 2.5)
		return false
	var cell := random_cell_in_region(target)
	if cell == NONE:
		return false
	dino.teleport(cell)
	dino.set_region(target, true)
	hud.flash("%s est de retour dans son enclos !" % dino.species.name, 2.5)
	return true


func on_dino_escaped(dino: Node2D) -> void:
	var how := "ton lance-pierre ou tes fléchettes" if mode == "adventure" else "la fléchette (onglet Outils)"
	hud.flash("Alerte ! %s s'est échappé !\nEndors-le avec %s." % [dino.species.name, how], 3.5)


func find_feeder(dino: Node2D):
	var best = null
	var best_distance := 1e9
	for building in buildings:
		if building.kind != "feeder" or building.stock <= 0 or building.get("build_left", 0.0) > 0.0:
			continue
		if Catalog.ITEMS[building.id].diet != dino.species.diet:
			continue
		if region_map[_index(building.origin)] != dino.region:
			continue
		var d := Vector2(building.origin - dino.cell).length()
		if d < best_distance:
			best = building
			best_distance = d
	return best


func consume_feeder(feeder: Dictionary, dino: Node2D) -> bool:
	if not buildings.has(feeder) or feeder.stock <= 0:
		return false
	feeder.stock -= 1
	if feeder.stock == 0:
		var item: Dictionary = Catalog.ITEMS[feeder.id]
		if money >= item.refill:
			money -= item.refill
			feeder.stock = item.stock
			_float_text(cell_center(feeder.origin), "-%d" % item.refill, Color("ef9a9a"))
		else:
			feeder.label.set_shown(true)
	return true


func feed_fish(dino: Node2D) -> void:
	money = max(money - FISH_PRICE, 0)
	_float_text(dino.position, "Poisson !", Color("81d4fa"))


func fence_to_attack(dino: Node2D) -> Vector2i:
	var region: Dictionary = regions[dino.region]
	if not region.enclosed:
		return NONE
	var weakest := NONE
	var weakest_strength := 99
	var weakest_distance := 1e9
	for f in region.fences:
		var strength: int = Catalog.ITEMS[occupied[f].id].strength
		var d := Vector2(f - dino.cell).length()
		if strength < weakest_strength or (strength == weakest_strength and d < weakest_distance):
			weakest = f
			weakest_strength = strength
			weakest_distance = d
	if weakest_strength >= dino.species.strength:
		return NONE
	var chance := 0.5 if dino.hunger < 30.0 else 0.2
	return weakest if randf() < chance else NONE


func cell_next_to(fence: Vector2i, region: int) -> Vector2i:
	for dir in DIRS:
		if is_walkable_for_dino(fence + dir, region):
			return fence + dir
	return NONE


func break_fence(cell: Vector2i, dino: Node2D) -> void:
	if not _is_fence(cell):
		return
	var name: String = Catalog.ITEMS[occupied[cell].id].name
	_float_text(cell_center(cell), "CRAC !", Color("ff7043"))
	hud.flash("%s a cassé une barrière en %s !\nIl lui faut une barrière %s." % [
		dino.species.name, name, Catalog.fence_for_strength(dino.species.strength)], 3.5)
	_remove_building(occupied[cell])


func splash(at: Vector2) -> void:
	_float_text(at, "SPLASH !", Color("81d4fa"))


func danger_near(at: Vector2) -> bool:
	for dino in dinos:
		if dino.escaped and dino.species.diet == "carn" and dino.state != "sleep" and dino.position.distance_to(at) < 5.0 * T:
			return true
	return false


func on_vehicle_moved(at: Vector2) -> void:
	for dino in dinos:
		if dino.position.distance_to(at) < 2.5 * T:
			dino.roar()


# --- Regions (enclosures) ------------------------------------------------

# Recomputes the path network, the enclosures and what is open to visitors.
func _refresh() -> void:
	var was_connected := distance.duplicate()
	_compute_paths()
	_compute_regions()
	for building in buildings:
		match building.kind:
			"path", "road", "fence", "mountain":
				building.open = true
			_:
				building.open = _touches_connected_path(building)
		# Paths cut off from the entrance turn grey.
		if building.kind == "path" and was_connected.has(building.origin) != distance.has(building.origin):
			ground.refresh(building.origin, 0)
	_update_stations()
	for dino in dinos:
		if dino.habitat != "land" or dino.ridden or dino.following != null:
			continue
		var i := _index(dino.cell)
		if region_map[i] < 0:
			# A wall was built where the dinosaur stood: step aside.
			for dir in DIRS:
				if in_grid(dino.cell + dir) and region_map[_index(dino.cell + dir)] >= 0:
					dino.teleport(dino.cell + dir)
					break
		var region := region_map[_index(dino.cell)]
		if region >= 0 and (region != dino.region or regions[region].enclosed == dino.escaped):
			dino.set_region(region, regions[region].enclosed)
	_update_attraction()
	_update_hover_info()


func _compute_paths() -> void:
	distance = {ENTRANCE: 0}
	var queue: Array[Vector2i] = [ENTRANCE]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for neighbor in path_neighbors(cell):
			if not distance.has(neighbor):
				distance[neighbor] = distance[cell] + 1
				queue.append(neighbor)


# Every group of cells surrounded by walls, without touching the map border, is an enclosure.
func _compute_regions() -> void:
	region_map.fill(-1)
	regions.clear()
	for y in GRID.y:
		for x in GRID.x:
			var start := Vector2i(x, y)
			if region_map[_index(start)] != -1 or _is_wall(start):
				continue
			var region := {"id": regions.size(), "cells": [], "enclosed": true, "visible": false, "fences": {}, "biomes": {}}
			region_map[_index(start)] = region.id
			var stack: Array[Vector2i] = [start]
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				region.cells.append(c)
				var biome := biomes[_index(c)]
				region.biomes[biome] = region.biomes.get(biome, 0) + 1
				if c.x == 0 or c.y == 0 or c.x == GRID.x - 1 or c.y == GRID.y - 1:
					region.enclosed = false
				for dir in DIRS:
					var n: Vector2i = c + dir
					if not in_grid(n):
						continue
					if _is_wall(n):
						if _is_fence(n):
							region.fences[n] = true
					elif region_map[_index(n)] == -1:
						region_map[_index(n)] = region.id
						stack.append(n)
			for f in region.fences:
				for dir in DIRS:
					if distance.has(f + dir):
						region.visible = true
			regions.append(region)


func _update_stations() -> void:
	for building in buildings:
		if building.kind != "gyro_station" and building.kind != "garage":
			continue
		building.nodes = building.nodes.filter(func(n) -> bool: return is_instance_valid(n) and not n.is_queued_for_deletion())
		var start := _station_region_cell(building) if building.kind == "gyro_station" else _garage_road_cell(building)
		building.region_cell = start
		building.label.set_shown(start == NONE)
		if start == NONE:
			continue
		if building.kind == "gyro_station" and building.open:
			regions[region_map[_index(start)]].visible = true
		if building.nodes.is_empty():
			for i in (3 if building.kind == "gyro_station" else 2):
				var vehicle := Vehicle.new()
				world.add_child(vehicle)
				vehicle.setup(self, "gyro" if building.kind == "gyro_station" else "jeep", start, building)
				building.nodes.append(vehicle)


func _station_region_cell(building: Dictionary) -> Vector2i:
	for c in _cells(building.origin, building.size):
		for dir in DIRS:
			var fence: Vector2i = c + dir
			var inside: Vector2i = fence + dir
			if _is_fence(fence) and in_grid(inside):
				var region := region_map[_index(inside)]
				if region >= 0 and regions[region].enclosed and is_walkable_for_dino(inside, region):
					return inside
	return NONE


func _garage_road_cell(building: Dictionary) -> Vector2i:
	for c in _cells(building.origin, building.size):
		for dir in DIRS:
			if is_road(c + dir):
				return c + dir
	return NONE


func _touches_connected_path(building: Dictionary) -> bool:
	for c in _cells(building.origin, building.size):
		for dir in DIRS:
			if distance.has(c + dir) and occupied.get(c + dir) != building:
				return true
	return false


func region_at(cell: Vector2i) -> int:
	return region_map[_index(cell)] if in_grid(cell) else -1


func is_walkable_for_dino(cell: Vector2i, region: int) -> bool:
	if not in_grid(cell) or region_map[_index(cell)] != region:
		return false
	var building = occupied.get(cell)
	if building == null:
		return true
	return not (building.kind in DINO_BLOCKERS or building.id in DINO_TREES or Catalog.ITEMS[building.id].get("solid", false))


func random_cell_in_region(region: int) -> Vector2i:
	if region < 0 or region >= regions.size():
		return NONE
	var cells: Array = regions[region].cells
	for attempt in 12:
		var cell: Vector2i = cells.pick_random()
		if is_walkable_for_dino(cell, region):
			return cell
	return NONE


func find_route(from: Vector2i, to: Vector2i, region: int) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	if from == to or to == NONE:
		return route
	var came := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		if cell == to:
			break
		for dir in DIRS:
			var next: Vector2i = cell + dir
			if not came.has(next) and is_walkable_for_dino(next, region):
				came[next] = cell
				queue.append(next)
	if not came.has(to):
		return route
	var cell := to
	while cell != from:
		route.push_front(cell)
		cell = came[cell]
	return route


func is_blocked_for_vehicle(kind: String, cell: Vector2i) -> bool:
	if not in_grid(cell):
		return true
	var building = occupied.get(cell)
	if building == null:
		return water[_index(cell)] == 1
	if building.kind in VEHICLE_BLOCKERS or building.kind in ["mountain", "mine"] or Catalog.ITEMS[building.id].get("solid", false):
		return true
	# Someone on foot goes through gates.
	if kind == "walk" and building.id == "gate_wood":
		return false
	# The gyrosphere rolls through fences; the jeep and people on foot do not.
	return kind != "gyro" and building.kind in ["fence", "decor"]


# --- Attraction, visitors, goals -------------------------------------------

func _update_attraction() -> void:
	var total := 0
	var per_region := {}
	for dino in dinos:
		if dino.habitat == "land" and not dino.escaped and not dino.wild and dino.region >= 0:
			per_region[dino.region] = per_region.get(dino.region, 0) + 1
	for dino in dinos:
		var species: Dictionary = dino.species
		if dino.wild or dino.ridden or dino.following != null:
			dino.set_mood("", Color.WHITE)
			continue
		if dino.habitat != "land":
			dino.set_mood("", Color.WHITE)
			if dino.home_building.open:
				total += species.attraction
			continue
		if dino.escaped or dino.region < 0 or dino.region >= regions.size():
			dino.set_mood("ÉCHAPPÉ !", Color("d03030"))
			total -= 15
			continue
		var region: Dictionary = regions[dino.region]
		var needs := []
		if dino.hunger < 30.0:
			needs.append("Faim !")
		if float(region.biomes.get(species.biome, 0)) / region.cells.size() < 0.5:
			needs.append(Catalog.BIOMES[species.biome].want)
		if region.cells.size() / per_region.get(dino.region, 1) < species.space:
			needs.append("Trop serré !")
		dino.set_mood(needs[0] if not needs.is_empty() else "", Color("a05010"))
		if region.visible:
			total += int(species.attraction * (1.0 - 0.2 * needs.size()))
	for building in buildings:
		if building.open:
			total += Catalog.ITEMS[building.id].get("attraction", 0)
	attraction = max(total, 0)


func _spawn_visitor() -> void:
	var visitor := Visitor.new()
	visitor.add_to_group("visitors")
	world.add_child(visitor)
	visitor.setup(self, ENTRANCE)
	money += TICKET_PRICE
	total_visitors += 1
	_float_text(cell_center(ENTRANCE), "+%d" % TICKET_PRICE, Color("ffe082"))


func on_visitor_step(visitor: Node2D) -> void:
	if visitor.scared:
		return
	for dir in DIRS:
		var building = occupied.get(visitor.cell + dir)
		if building == null or building.kind != "shop" or not building.open or visitor.bought.has(building.id):
			continue
		if randf() < 0.35:
			var price: int = Catalog.ITEMS[building.id].price
			money += price
			visitor.buy(building.id)
			_float_text(cell_center(visitor.cell), "+%d" % price, Catalog.ITEMS[building.id].color.lightened(0.3))
			return


func earn(amount: int, at: Vector2) -> void:
	money += amount
	_float_text(at, "+%d" % amount, Color("ffe082"))


func _check_goal() -> void:
	var goals: Array = ADVENTURE_GOALS if mode == "adventure" else GOALS
	if goal_index >= goals.size():
		if mode == "adventure":
			hud.set_goal("Bravo ! Bientôt : partir attraper ton premier dinosaure.")
		else:
			hud.set_goal("Bravo, ton parc est génial ! Continue à l'agrandir.")
		return
	if _goal_done(goals[goal_index].id):
		goal_index += 1
		hud.flash("Objectif réussi !")
	if goal_index < goals.size():
		hud.set_goal("Objectif %d/%d : %s" % [goal_index + 1, goals.size(), goals[goal_index].text])


func _goal_done(id: String) -> bool:
	if mode == "adventure":
		match id:
			"wood":
				return inventory.count("wood") >= 5 or inventory.count("axe") > 0
			"axe", "pickaxe", "stone", "berries":
				return inventory.count(id) > 0
			"pen":
				return regions.any(func(r) -> bool: return r.enclosed and r.cells.size() >= 4)
			"feeder":
				return buildings.any(func(b) -> bool: return b.kind == "feeder" and region_map[_index(b.origin)] >= 0 \
					and regions[region_map[_index(b.origin)]].enclosed)
			"path":
				return regions.any(func(r) -> bool: return r.enclosed and r.visible)
			"tame":
				return dinos.any(func(d) -> bool: return d.following != null) or not caught.is_empty()
			"adopt":
				return dinos.any(func(d) -> bool: return d.habitat == "land" and not d.wild and not d.escaped)
			"cage":
				return inventory.counts.keys().any(func(k) -> bool: return k.begins_with("dino:")) or goal_index > ADVENTURE_GOALS.size()
			"release":
				return dinos.filter(func(d) -> bool: return not d.wild and not d.escaped).size() >= 2
			"brush":
				return inventory.count("brush") > 0 and dinos.any(func(d) -> bool: return not d.wild and d.friendship >= 40)
			"friend":
				return dinos.any(func(d) -> bool: return not d.wild and d.hearts() >= RIDE_HEARTS and d.can_be_ridden())
			"ride":
				return player.mount != null
			"mine":
				return mine != null or not mine_states.is_empty()
			"ore":
				return inventory.count("iron") > 0 and inventory.count("copper") > 0
			"electric":
				return inventory.count("fence_electric") > 0 or buildings.any(func(b) -> bool: return b.id == "fence_electric")
			"dex5":
				return caught.size() >= 5
			"dex10":
				return caught.size() >= 10
		return false
	match id:
		"pen":
			return dinos.any(func(d) -> bool: return d.habitat == "land" and not d.escaped)
		"visible":
			return dinos.any(func(d) -> bool: return d.habitat == "land" and not d.escaped and regions[d.region].visible)
		"feeder":
			return buildings.any(func(b) -> bool: return b.kind == "feeder" and region_map[_index(b.origin)] >= 0 \
				and regions[region_map[_index(b.origin)]].enclosed)
		"visitors":
			return total_visitors >= 50
		"aviary":
			return buildings.any(func(b) -> bool: return b.kind == "aviary" and not b.dinos.is_empty())
		"gyro":
			return buildings.any(func(b) -> bool: return b.kind == "gyro_station" and b.region_cell != NONE)
		"species":
			var species := {}
			for dino in dinos:
				species[dino.species_id] = true
			return species.size() >= 8
		"lagoon":
			return dinos.any(func(d) -> bool: return d.species_id == "mosasaurus")
		"rich":
			return money >= 30000
	return false


# --- Driving -------------------------------------------------------------

func start_driving(kind: String, cell: Vector2i) -> void:
	var start := cell_center(cell)
	if kind == "heli":
		var building = occupied.get(cell)
		if building == null or building.kind != "heliport":
			hud.flash("Clique sur un héliport pour décoller.\n(onglet Transports)", 2.5)
			return
		start = (Vector2(building.origin) + Vector2(1.5, 1.8)) * T
	elif is_blocked_for_vehicle(kind, cell):
		hud.flash("Choisis un endroit libre.")
		return
	painting = false
	driving = PlayerVehicle.new()
	world.add_child(driving)
	driving.setup(self, kind, start)
	camera.follow(driving)
	hud.set_driving(true)
	match kind:
		"heli":
			hud.flash("Espace : monter   Maj : descendre\nFlèches ou ZQSD pour voler, Échap pour descendre", 4.0)
		"walk":
			hud.flash("Flèches ou ZQSD pour marcher\nÉchap pour arrêter", 3.5)
		_:
			hud.flash("Flèches ou ZQSD pour conduire\nÉchap pour descendre", 3.5)


func stop_driving() -> void:
	if driving == null:
		return
	camera.unfollow()
	driving.queue_free()
	driving = null
	hud.set_driving(false)


# --- Adventure: harvesting and building with your own hands ----------------------

func _process_adventure(delta: float) -> void:
	if door_wait and player.pushing != door_wait_dir:
		door_wait = false
	if away != null:
		if mine != null:
			_process_mine()
		elif house != null:
			_process_house()
		else:
			_process_village()
		save_timer -= delta
		if save_timer <= 0.0:
			save_timer = AUTOSAVE
			save_game()
		return
	# The road out of the park gate leads to the village.
	if zone == Wild.BASE and player.position.x < -1.5 * T and absi(player.cell().y - ENTRANCE.y) <= 1:
		enter_village()
		return
	# Off the edge of the zone: the next zone of the Wild Lands.
	var edge := _edge_crossed()
	if edge != Vector2i.ZERO:
		_cross_edge(edge)
		return
	# Walking up into a mine entrance goes down.
	var entrance = occupied.get(player.cell() + Vector2i.UP) if player.pushing == Vector2i.UP else null
	if entrance != null and entrance.kind == "mine" and _door_ready():
		if player.vehicle == "" and player.mount == null:
			enter_mine(entrance)
			return
		if clock > gate_warned:
			gate_warned = clock + 3.0
			_float_text(player.position, "Descends pour entrer dans la mine", Color("ffab91"))
	_update_gates(player.position)
	# A tamed dinosaur that followed us into an enclosure stays there.
	for dino in dinos:
		if dino.following != null and in_grid(dino.cell):
			var region := region_map[_index(dino.cell)]
			if region >= 0 and regions[region].enclosed:
				dino.region = region
				adopt(dino)
	if hearts < MAX_HEARTS:
		heal_timer -= delta
		if heal_timer <= 0.0:
			heal_timer = HEAL_EVERY
			hearts += 1
			hud.set_hearts(hearts, MAX_HEARTS)
	# The cell in front of the character is highlighted (not when aiming at dinosaurs).
	var target: Vector2i = player.front()
	var holding: String = inventory.current()
	if Items.WEAPONS.has(holding) or builder.active:
		ghost.visible = false
	elif in_grid(target):
		var ok := true
		if Items.kind_of(holding) == "build" or Items.kind_of(holding) == "dino":
			ok = _can_place(target, holding)
		else:
			ok = occupied.has(target)
		_show_ghost(target, Vector2i.ONE, Color.WHITE if ok else Color("90a0b0"))
	else:
		ghost.visible = false
	nature_timer -= delta
	if nature_timer <= 0.0:
		nature_timer = 1.0
		_grow_nature()
	save_timer -= delta
	if save_timer <= 0.0:
		save_timer = AUTOSAVE
		save_game()


# Uses what the character holds on the cell in front of it.
func player_action(cell: Vector2i) -> void:
	if mine != null:
		_mine_action(cell)
		return
	if house != null:
		_house_action(cell)
		return
	if village != null:
		if village.kind_at(cell) == "" and Items.kind_of(inventory.current()) == "vehicle":
			board_vehicle(inventory.current())
		else:
			_village_action(cell)
		return
	if not in_grid(cell):
		return
	var entrance = occupied.get(cell)
	if entrance != null and entrance.kind == "mine":
		enter_mine(entrance)
		return
	var holding: String = inventory.current()
	if entrance != null and entrance.kind == "campfire" and not (holding in ["axe", "pickaxe", "pickaxe_iron"] and not entrance.get("found", false)):
		use_campfire(entrance)
		return
	var kind := Items.kind_of(holding)
	if kind == "vehicle":
		board_vehicle(holding)
		return
	if kind == "dino":
		_release(holding, cell)
		return
	if Items.WEAPONS.has(holding):
		combat.fire()
		return
	var dino := _dino_near(cell_center(cell), 14.0)
	if dino != null:
		_touch_dino(dino, holding)
		return
	var building = occupied.get(cell)
	if kind == "build" and building == null:
		place_item(holding, cell)
	elif building != null:
		_hit(building, holding)


# --- Adventure: mines ----------------------------------------------------------------

func player_blocked(cell: Vector2i) -> bool:
	if away != null:
		return away.is_solid(cell)
	if not in_grid(cell) and mode == "adventure":
		var dir := _edge_of(cell)
		if dir != Vector2i.ZERO and _edge_open(dir, cell):
			if player.mount != null:
				if clock > gate_warned:
					gate_warned = clock + 3.0
					_float_text(player.position, "Descends de ton dinosaure pour partir à l'aventure", Color("ffab91"))
				return true
			return false
	# Out of the park gate, the road goes on to the village.
	if zone == Wild.BASE and cell.x < 0 and cell.x >= -BORDER and cell.y == ENTRANCE.y:
		if player.mount != null:
			if clock > gate_warned:
				gate_warned = clock + 3.0
				_float_text(player.position, "Descends de ton dinosaure pour aller au village", Color("ffab91"))
			return true
		return false
	return is_blocked_for_vehicle("walk", cell)


# Where the player can go: the park, or the zone they are in.
func player_area() -> Rect2:
	if away != null:
		return away.bounds()
	# One cell more on each side, so that the helicopter can fly to the next zone.
	return Rect2(-Vector2.ONE * T, Vector2(GRID * T) + Vector2.ONE * T * 2)


# Where the player is in the park (where they will come back while away).
func player_surface_position() -> Vector2:
	return surface_spot if away != null else player.position


func enter_mine(entrance: Dictionary) -> void:
	if player.mount != null:
		_float_text(player.position, "Descends de ton dinosaure pour entrer dans la mine", Color("ffab91"))
		return
	var key := "%d,%d" % [entrance.origin.x, entrance.origin.y]
	if zone != Wild.BASE:
		key = "%s:%s" % [Wild.key(zone), key]
	if not mine_states.has(key):
		mine_states[key] = {"seed": randi() % 1000000, "dug": {}}
	surface_spot = cell_center(entrance.origin + Vector2i.DOWN)
	_leave_surface()
	_open_mine(key, 1, true)
	player.add_child(mine.make_light())
	hud.flash("Tu descends dans la mine…\nCreuse les murs avec ta pioche !", 3.0)


func exit_mine() -> void:
	for child in player.get_children():
		if child is PointLight2D:
			child.queue_free()
	mine.queue_free()
	mine = null
	_back_to_surface()
	hud.flash("De retour à la surface !", 1.5)


# Hides the park while the player is in another zone (the park keeps living meanwhile).
func _leave_surface() -> void:
	ghost.visible = false
	world.visible = false
	ground.visible = false
	floor_layer.visible = false


func _back_to_surface() -> void:
	away = null
	player.get_parent().remove_child(player)
	world.add_child(player)
	world.visible = true
	ground.visible = true
	floor_layer.visible = true
	player.position = surface_spot
	player.velocity = Vector2.ZERO
	camera.bounds = world_bounds
	camera.position = player.position
	hud.refresh_build()
	_arrived()


# Builds a level of the mine and puts the player by the ladder it came from.
func _open_mine(key: String, level: int, from_above: bool) -> void:
	player.get_parent().remove_child(player)
	if mine != null:
		mine.queue_free()
	mine = Mine.new()
	away = mine
	add_child(mine)
	mine.setup(key, mine_states[key], level)
	mine.add_child(player)
	var ladder: Vector2i = mine.up_cell if from_above else mine.down_cell
	var spot := ladder
	for dir in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		if not mine.is_solid(ladder + dir) and mine.kind_at(ladder + dir) == "floor":
			spot = ladder + dir
			break
	player.position = mine.cell_center(spot)
	player.velocity = Vector2.ZERO
	camera.bounds = mine.bounds()
	camera.position = player.position
	hud.refresh_build()
	_arrived()


func _mine_action(cell: Vector2i) -> void:
	match mine.kind_at(cell):
		"up":
			if mine.level == 1:
				exit_mine()
			else:
				_open_mine(mine.key, mine.level - 1, false)
				hud.flash("Niveau %d de la mine" % mine.level, 1.5)
			return
		"down":
			_open_mine(mine.key, mine.level + 1, true)
			hud.flash("Niveau %d de la mine\nLes pierres sont plus rares ici !" % mine.level, 2.5)
			return
	var result: Dictionary = mine.dig(cell, inventory.current())
	var at: Vector2 = mine.cell_center(cell)
	if result.has("message"):
		_float_text(at, result.message, Color("ffab91"))
	elif result.has("gives"):
		var gained := PackedStringArray()
		for id in result.gives:
			inventory.add(id, result.gives[id])
			gained.append("+%d %s" % [result.gives[id], Items.name_of(id)])
		if not gained.is_empty():
			_float_text(at, "  ".join(gained), Color("fff59d"))


func _process_mine() -> void:
	# Stepping on a ladder climbs it.
	if mine.kind_at(player.cell()) in ["up", "down"] and player.pushing != Vector2i.ZERO and _door_ready():
		_mine_action(player.cell())
		return
	var target: Vector2i = player.front()
	var kind: String = mine.kind_at(target)
	_show_ghost(target, Vector2i.ONE, Color.WHITE if kind != "floor" else Color("90a0b0"))


# --- Adventure: the village and its shop ---------------------------------------------

func enter_village() -> void:
	surface_spot = cell_center(ENTRANCE)
	_leave_surface()
	village = Village.new()
	away = village
	add_child(village)
	village.setup(village_state)
	player.get_parent().remove_child(player)
	village.add_child(player)
	village.player = player
	player.position = village.arrival()
	player.velocity = Vector2.ZERO
	player.facing = Vector2i.LEFT
	camera.bounds = village.bounds()
	camera.position = player.position
	hud.refresh_build()
	_arrived()
	hud.flash("Bienvenue au village !\nVa voir la boutique sur la place.", 3.0)


func exit_village() -> void:
	village.queue_free()
	village = null
	_back_to_surface()
	player.facing = Vector2i.RIGHT
	hud.close_shop()
	hud.flash("De retour au parc !", 1.5)


func _process_village() -> void:
	if village.is_exit(player.cell()):
		exit_village()
		return
	# Walking up into the door of a house goes in.
	var door: int = village.house_door_below(player.cell()) if player.pushing == Vector2i.UP else -1
	if door >= 0 and _door_ready():
		if player.vehicle == "":
			enter_house(door)
			return
		if clock > gate_warned:
			gate_warned = clock + 3.0
			_float_text(player.position, "Descends du véhicule pour entrer", Color("ffab91"))
	village.show_shop_hint(village.near_shop(player.position) and not hud.shop.visible)
	var target: Vector2i = player.front()
	var kind: String = village.kind_at(target)
	if kind in ["shop", "chest", "house"]:
		_show_ghost(target, Vector2i.ONE, Color.WHITE)
	else:
		ghost.visible = false


func _village_action(cell: Vector2i) -> void:
	var at: Vector2 = village.cell_center(cell)
	match village.kind_at(cell):
		"shop":
			hud.open_shop()
		"house":
			enter_house(village.house_at(cell))
		"chest":
			var found: Dictionary = village.open_chest(cell)
			if found.is_empty():
				_float_text(at, "Le coffre est vide.", Color("c0c0c8"))
				return
			var gained := PackedStringArray()
			for id in found:
				if id == "coins":
					money += found[id]
					gained.append("+%d pièces" % found[id])
				else:
					inventory.add(id, found[id])
					gained.append("+%d %s" % [found[id], Items.name_of(id)])
			hud.flash("Un trésor !\n" + "  ".join(gained), 3.0)
			save_game()


func enter_house(index: int) -> void:
	player.get_parent().remove_child(player)
	village.player = null
	village.visible = false
	village.process_mode = Node.PROCESS_MODE_DISABLED
	house = House.new()
	away = house
	add_child(house)
	house.setup(index, Village.HOUSES[index][1], village_state)
	house.add_child(player)
	house.player = player
	player.position = house.arrival()
	player.velocity = Vector2.ZERO
	player.facing = Vector2i.UP
	camera.bounds = house.bounds()
	camera.position = player.position
	_arrived()
	hud.flash("Toc toc ! Tu entres chez %s." % house.resident.name, 2.5)


func exit_house() -> void:
	var door: Vector2 = village.house_door(house.index)
	player.get_parent().remove_child(player)
	house.queue_free()
	house = null
	away = village
	village.visible = true
	village.process_mode = Node.PROCESS_MODE_INHERIT
	village.add_child(player)
	village.player = player
	player.position = door
	player.velocity = Vector2.ZERO
	player.facing = Vector2i.DOWN
	camera.bounds = village.bounds()
	camera.position = player.position
	_arrived()


func _arrived() -> void:
	door_wait = true
	door_wait_dir = player.pushing


func _door_ready() -> bool:
	return not door_wait


func _process_house() -> void:
	if house.is_exit(player.cell()):
		exit_house()
		return
	var target: Vector2i = player.front()
	if house.kind_at(target) == "resident":
		_show_ghost(target, Vector2i.ONE, Color.WHITE)
	else:
		ghost.visible = false


func _house_action(cell: Vector2i) -> void:
	if house.kind_at(cell) != "resident":
		return
	var gift: Dictionary = house.talk()
	if gift.is_empty():
		return
	var gained := PackedStringArray()
	for id in gift:
		if id == "coins":
			money += gift[id]
			gained.append("+%d pièces" % gift[id])
		else:
			inventory.add(id, gift[id])
			gained.append("+%d %s" % [gift[id], Items.name_of(id)])
	_float_text(player.position + Vector2(0, -16), "  ".join(gained), Color("fff59d"))
	save_game()


# Buys a line of Market.BUY. Returns false when there are not enough coins.
func buy(entry: Dictionary) -> bool:
	if money < entry.price:
		return false
	money -= entry.price
	inventory.add(entry.id, entry.count)
	return true


# Sells `amount` of a thing to the merchant and returns the coins earned.
func sell(id: String, amount: int) -> int:
	amount = mini(amount, inventory.count(id))
	if amount <= 0 or not Market.SELL.has(id) or not inventory.remove(id, amount):
		return 0
	money += amount * Market.SELL[id]
	return amount * Market.SELL[id]


# --- Adventure: catching dinosaurs -----------------------------------------------

func _touch_dino(dino: Node2D, holding: String) -> void:
	var at: Vector2 = dino.position + Vector2(0, -12)
	if holding == "cage" and dino.wild:
		if dino.species.strength > Items.CAGE_STRENGTH:
			_float_text(at, "Trop gros pour la cage ! Il faut une capsule.", Color("ffab91"))
			return
		if dino.state != "sleep":
			_float_text(at, "Fatigue-le d'abord avec ton lance-pierre !", Color("ffab91"))
			return
		inventory.remove("cage")
		_float_text(at, "%s est dans la cage !" % dino.species.name, Color("fff59d"))
		catch_dino(dino)
		return
	if dino.wild and holding == "saddle":
		_float_text(at, "La selle, c'est pour les dinos de ton parc : apprivoise-le ou attrape-le d'abord !", Color("ffab91"))
		return
	if dino.wild:
		var hint := "Donne-lui des baies, ou fatigue-le et lance une capsule !" if dino.species.diet == "herb" \
			else "Attention, il mord ! Fatigue-le de loin, puis lance une capsule."
		_float_text(at, hint, Color("e0e0e0"))
		return
	if dino.state == "sleep":
		return
	_befriend(dino, holding)


# --- Adventure: friendship and riding ------------------------------------------------

func _befriend(dino: Node2D, holding: String) -> void:
	var at: Vector2 = dino.position + Vector2(0, -12)
	var shy: bool = dino.species.diet == "carn"  # carnivores trust half as fast
	match holding:
		"brush":
			if clock < dino.next_brush:
				_float_text(at, "Il a déjà été brossé, reviens plus tard", Color("e0e0e0"))
				return
			dino.next_brush = clock + 20.0
			_gain_friendship(dino, 10 if shy else 20)
		"saddle":
			if not dino.can_be_ridden():
				_float_text(at, "Trop petit pour une selle ! Essaie un %s" % _rideable_names(), Color("ffab91"))
			elif dino.saddled:
				_try_mount(dino)
			elif dino.hearts() < RIDE_HEARTS:
				_float_text(at, "Il doit d'abord t'aimer : %d cœurs (il a %s).\nBrosse-le et donne-lui à manger !" % [RIDE_HEARTS, dino.hearts_text()], Color("ffab91"))
			else:
				inventory.remove("saddle")
				dino.set_saddled(true)
				_try_mount(dino)
		"":
			_try_mount(dino)
		_:
			_float_text(at, "Amitié : %s" % dino.hearts_text(), Color("ff80ab"))


# Berries and meat are thrown from afar, like shots (see combat.gd). Why this dinosaur would not
# take this food now, or "" if it would.
func food_refused(dino: Node2D, food: String) -> String:
	if dino.species.diet != Items.WEAPONS[food].feed:
		return "Il ne mange pas de baies !" if Items.WEAPONS[food].feed == "herb" else "Il ne mange pas de viande !"
	if dino.wild:
		return "Il te suit déjà !" if dino.following != null else ""
	if clock < dino.next_treat:
		return "Il n'a plus faim, reviens plus tard"
	return ""


# The food reached the dinosaur: a wild one trusts us a bit more (3 times and it follows us,
# 5 for a carnivore, which also stops charging for a while), one of the park becomes a better friend.
func feed(dino: Node2D, food := "") -> void:
	var worth: int = Items.WEAPONS.get(food, {}).get("worth", 1)
	dino.roar_time = 0.0
	dino.chase_cool = 12.0
	dino.angry_time = 0.0
	if not dino.wild:
		dino.next_treat = clock + 20.0
		dino.hunger = 100.0
		_gain_friendship(dino, 20 * worth)
		return
	dino.trust += worth
	dino.set_mood("", Color.WHITE)
	if dino.trust < dino.trust_needed():
		return
	# Tamed: it jumps to us and into "Mes dinos", no capsule needed.
	dino.captured = true
	dino.mood_text.visible = false
	var tween := dino.create_tween().set_parallel()
	tween.tween_property(dino, "position", player.position, 0.45)
	tween.tween_property(dino.sprite, "scale", Vector2(0.05, 0.05), 0.45)
	tween.tween_property(dino.shadow, "scale", Vector2(0.05, 0.05), 0.45)
	tween.chain().tween_callback(func() -> void:
		_float_text(player.position, "Ami !", Color("ff80ab"))
		catch_dino(dino))


func _gain_friendship(dino: Node2D, amount: int) -> void:
	var before: int = dino.hearts()
	dino.friendship = mini(dino.friendship + amount, 100)
	_float_text(dino.position + Vector2(0, -12), dino.hearts_text(), Color("ff80ab"))
	if dino.hearts() > before and dino.hearts() == 5:
		hud.flash("%s t'adore ! %s" % [dino.species.name,
			"Pose-lui une selle pour le monter." if not dino.saddled and dino.can_be_ridden() else ""], 3.0)


func _try_mount(dino: Node2D) -> void:
	var at: Vector2 = dino.position + Vector2(0, -12)
	if not dino.can_be_ridden():
		_float_text(at, "Trop petit pour être monté. Amitié : %s" % dino.hearts_text(), Color("ff80ab"))
	elif not dino.saddled:
		_float_text(at, "Il lui faut une selle ! Prends-la en main et appuie sur Action devant lui.", Color("ffab91"))
	else:
		player.mount_on(dino)
		hud.set_riding(true)
		hud.flash("En selle sur %s !\nUtilise le joystick pour avancer.\nBouton Action pour descendre." % dino.species.name, 3.0)


# Some of the dinosaurs big enough to carry a saddle, to tell which ones.
func _rideable_names() -> String:
	return "Tricératops, un Gallimimus ou un Diplodocus."


# Gets on the bike, the moto, the car or the helicopter held in hand.
func board_vehicle(id: String) -> void:
	if id == "heli" and away != null:
		_float_text(player.position, "Pas de place pour décoller ici !", Color("ffab91"))
		return
	player.board(id)
	hud.set_riding(true)
	var hint := "L'hélicoptère décolle !\nBouton Action pour atterrir." if id == "heli" else "En route !\nBouton Action pour descendre."
	hud.flash(hint, 2.5)


# Off the vehicle: it goes back in the bag.
func player_leave_vehicle() -> void:
	player.leave_vehicle()
	hud.set_riding(false)


func player_dismount() -> void:
	var dino: Node2D = player.mount
	# Get off on a free cell next to the dinosaur.
	var spot: Vector2 = player.position
	for dir in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		var cell: Vector2i = player.cell() + dir * 2
		if in_grid(cell) and not is_blocked_for_vehicle("walk", cell):
			spot = cell_center(cell)
			break
	player.get_off(spot)
	hud.set_riding(false)
	var region := region_map[_index(dino.cell)] if in_grid(dino.cell) else -1
	if region >= 0 and regions[region].enclosed:
		dino.home_cell = dino.cell
		dino.set_region(region, true)
	else:
		# Outside its enclosure, it waits for us and follows us home.
		dino.following = player
		hud.flash("%s te suit. Ramène-le dans un enclos !" % dino.species.name, 2.5)


# A wild dinosaur caught in a cage or a capsule goes in the bag.
func catch_dino(dino: Node2D) -> void:
	inventory.add("dino:" + dino.species_id)
	_mark_caught(dino.species_id)
	hud.flash("%s est dans « Mes dinos » !\nRelâche-le dans un enclos quand tu veux." % dino.species.name, 3.0)
	_remove_dino(dino)
	_check_goal()


func _release(item: String, cell: Vector2i) -> void:
	var id := item.substr(5)
	var home = _dino_home_at(Catalog.DINOS[id], cell)
	if home is String:
		_float_text(cell_center(cell), home, Color("ffab91"))
		return
	inventory.remove(item)
	_place_dino(id, cell, true)
	_float_text(cell_center(cell), Catalog.DINOS[id].name + " !", Color("a5f0a8"))
	_refresh()


# A wild or tamed dinosaur ends up inside an enclosure: it now belongs to the park.
func adopt(dino: Node2D) -> void:
	var was_wild: bool = dino.wild
	dino.wild = false
	dino.following = null
	if was_wild:
		# Tamed with berries or meat: it already likes us a little.
		dino.friendship = dino.HEART if dino.trust >= dino.trust_needed() else 0
	dino.trust = 0
	dino.home_cell = dino.cell
	_mark_caught(dino.species_id)
	if was_wild:
		hud.flash("Bravo ! %s habite maintenant dans ton enclos." % dino.species.name, 3.0)
	else:
		hud.flash("%s est rentré dans son enclos." % dino.species.name, 2.0)
	var region := region_map[_index(dino.cell)]
	dino.set_region(region, region >= 0 and regions[region].enclosed)
	_update_attraction()


func _mark_caught(species_id: String) -> void:
	if not caught.has(species_id):
		caught[species_id] = true
		_float_text(player.position + Vector2(0, -20), "Nouveau dans le Dinodex !", Color("80d8ff"))


# A wild dinosaur bumped into us: we lose a heart and are pushed back.
func player_hit(dino: Node2D) -> void:
	if clock < safe_until or player.mount != null or player.vehicle != "":
		return
	hearts -= 1
	safe_until = clock + 1.5
	heal_timer = HEAL_EVERY * 2.0
	player.velocity = (player.position - dino.position).normalized() * 260.0
	player.blink(1.5)
	_float_text(player.position, "Aïe !", Color("ff8a80"))
	if hearts <= 0:
		hearts = MAX_HEARTS
		player_scared(dino)
	hud.set_hearts(hearts, MAX_HEARTS)


func float_text(at: Vector2, text: String, color: Color) -> void:
	_float_text(at, text, color)


func player_scared(dino: Node2D) -> void:
	if not respawn.is_empty() or zone != Wild.BASE:
		# The player runs back to the last campfire they rested by, or to the park.
		hud.flash("%s t'a fait très peur !\nTu cours te réfugier %s." % [dino.species.name, "près de ton feu de camp" if not respawn.is_empty() else "au parc"], 3.0)
		call_deferred("go_to_respawn")
		return
	player.position = cell_center(ENTRANCE + Vector2i(2, 0))
	player.velocity = Vector2.ZERO
	camera.position = player.position
	hud.flash("%s t'a fait très peur !\nTu cours te réfugier à l'entrée." % dino.species.name, 3.0)


func _spawn_wild(id: String, cell: Vector2i, trust := 0) -> Node2D:
	var dino := Dino.new()
	world.add_child(dino)
	dino.setup(self, id, cell, null)
	dino.wild = true
	dino.trust = trust
	dinos.append(dino)
	var region := region_map[_index(cell)]
	dino.set_region(region, false)
	return dino


# Keeps the land populated: wild dinosaurs appear far from the player, in the biome they like.
func _spawn_wild_dinos(limit: int) -> void:
	var wild_count := dinos.filter(func(d) -> bool: return d.wild).size()
	var tries := 0
	while wild_count < WILD_TARGET and limit > 0 and tries < 200:
		tries += 1
		var cell := Vector2i(randi_range(1, GRID.x - 2), randi_range(1, GRID.y - 2))
		if Vector2(cell - ENTRANCE).length() < 14.0:
			continue
		if player != null and Vector2(cell - player.cell()).length() < 9.0:
			continue
		var region := region_map[_index(cell)]
		if region < 0 or regions[region].enclosed or not is_walkable_for_dino(cell, region):
			continue
		var id := _wild_species(biome_at(cell))
		if id == "":
			continue
		_spawn_wild(id, cell)
		wild_count += 1
		limit -= 1


# Small and common species come more often than giants.
func _wild_species(biome: String) -> String:
	var choices := []
	var total := 0.0
	for id in Catalog.DINOS:
		var species: Dictionary = Catalog.DINOS[id]
		if species.habitat == "land" and species.biome == biome:
			choices.append(id)
			total += _wild_weight(species)
	var roll := randf() * total
	for id in choices:
		roll -= _wild_weight(Catalog.DINOS[id])
		if roll <= 0.0:
			return id
	return ""


# Far from the park, the big and rare dinosaurs come much more often.
func _wild_weight(species: Dictionary) -> float:
	return 1000.0 / species.cost * (1.0 + Wild.level(zone) * (species.strength - 1) * 0.6)


func random_cell_near(center: Vector2i, radius: int, region: int) -> Vector2i:
	for attempt in 10:
		var cell := center + Vector2i(randi_range(-radius, radius), randi_range(-radius, radius))
		if is_walkable_for_dino(cell, region):
			return cell
	return NONE


func _can_place(cell: Vector2i, item := "") -> bool:
	if not in_grid(cell) or occupied.has(cell) or cell == player.cell():
		return false
	# Bridges go on water, everything else on land.
	if is_water(cell) != (item == "bridge"):
		return false
	return _dino_near(cell_center(cell), 10.0) == null


# --- Adventure: the building mode (see builder.gd) ------------------------------------

# Why this bag item cannot be laid on this cell, or "" if it can.
func build_refused(cell: Vector2i, id: String) -> String:
	if not in_grid(cell):
		return "Hors de la carte"
	if zone != Wild.BASE and not Items.ITEMS[id].get("place", "") in WILD_BUILDS:
		return "Ici, seulement des feux de camp, des ponts et des chemins. Les enclos, c'est dans ton parc !"
	var building = occupied.get(cell)
	if building != null:
		match building.id:
			"tree", "pine", "palm", "cactus":
				return "Il y a un arbre : coupe-le avec la hache"
			"rock":
				return "Il y a un rocher : casse-le avec la pioche"
			"bush":
				return "Il y a un buisson : déterre-le avec la gomme"
		return "Il y a déjà quelque chose ici"
	if is_water(cell) != (id == "bridge"):
		return "Pas sur l'eau !" if is_water(cell) else "Le pont se pose sur l'eau"
	if cell == player.cell():
		return "Ton personnage est là"
	if _dino_near(cell_center(cell), 10.0) != null:
		return "Un dinosaure est là"
	return ""


func build_at(cell: Vector2i, id: String) -> Dictionary:
	inventory.remove(id)
	return _add_building(Items.ITEMS[id].place, cell)


# Undoes a placement: the thing goes back into the bag.
func take_back_at(cell: Vector2i, id: String) -> void:
	var building = occupied.get(cell)
	if building != null and building.id == Items.ITEMS[id].place:
		inventory.add(id)
		_remove_building(building)


# The eraser: what was built goes back into the bag, a berry bush is dug up to be planted elsewhere.
func erase_at(cell: Vector2i) -> void:
	var building = occupied.get(cell)
	if building == null:
		return
	var item := Items.item_for_building(building.id)
	inventory.add(item)
	_float_text(cell_center(cell), "+1 %s" % Items.name_of(item), Color("fff59d"))
	_remove_building(building)


func refresh_after_building() -> void:
	_refresh()
	_check_goal()


func shake(node: Node2D) -> void:
	_shake(node)


func place_item(id: String, cell: Vector2i) -> void:
	if not _can_place(cell, id):
		return
	var refused := build_refused(cell, id)
	if refused != "":
		_float_text(player.position, refused, Color("ffab91"))
		return
	if inventory.count(id) <= 0:
		_float_text(player.position, "Plus de %s !" % Items.name_of(id), Color("ffab91"))
		return
	inventory.remove(id)
	_add_building(Items.ITEMS[id].place, cell)
	_refresh()


func _hit(building: Dictionary, tool: String) -> void:
	var harvest: Dictionary = Items.HARVEST.get(building.id, {})
	var at := cell_center(building.origin)
	if harvest.is_empty():
		_take_back(building, tool)
		return
	if harvest.needs != "" and tool != harvest.needs and not (harvest.needs == "pickaxe" and tool == "pickaxe_iron"):
		_float_text(at, "Il faut une %s !" % Items.name_of(harvest.needs).to_lower(), Color("ffab91"))
		return
	if building.id == "bush" and not building.ready:
		_float_text(at, "Les baies repoussent…", Color("c8e6c9"))
		return
	building.hits += 1
	_shake(building.root)
	var needed: int = harvest.hits
	if tool != "" and tool == harvest.fast:
		needed = maxi(1, ceili(needed / 2.0))
	if building.hits < needed:
		return
	building.hits = 0
	var gained := PackedStringArray()
	for id in harvest.gives:
		inventory.add(id, harvest.gives[id])
		gained.append("+%d %s" % [harvest.gives[id], Items.name_of(id)])
	if harvest.has("bonus") and randf() < 0.3:
		inventory.add(harvest.bonus)
		gained.append("+1 %s" % Items.name_of(harvest.bonus))
	if not gained.is_empty():
		_float_text(at, "  ".join(gained), Color("fff59d"))
	if building.id == "bush":
		_empty_bush(building)
	else:
		_remove_building(building)


# Takes a fence, a path or a feeder back into the bag (with a tool, so little hands do not undo by accident).
func _take_back(building: Dictionary, tool: String) -> void:
	var item := Items.item_for_building(building.id)
	if item == "" or building.fixed:
		return
	if tool != "axe" and tool != "pickaxe":
		_float_text(cell_center(building.origin), "Prends la hache ou la pioche pour démonter", Color("e0e0e0"))
		return
	building.hits += 1
	_shake(building.root)
	if building.hits < 2:
		return
	inventory.add(item)
	_float_text(cell_center(building.origin), "+1 %s" % Items.name_of(item), Color("fff59d"))
	_remove_building(building)


func _shake(node: Node2D) -> void:
	if node == null:
		return
	var base := node.position
	var tween := node.create_tween()
	tween.tween_property(node, "position", base + Vector2(1.5, 0), 0.04)
	tween.tween_property(node, "position", base - Vector2(1.5, 0), 0.06)
	tween.tween_property(node, "position", base, 0.04)


func _empty_bush(building: Dictionary) -> void:
	building.ready = false
	building.regrow_at = clock + BERRY_REGROW
	building.root.texture = Art.decor("bush_empty")


# Natural things placed for free, while generating the land or when nature grows back.
func add_natural(id: String, cell: Vector2i) -> void:
	_add_building(id, cell)


func _count_nature() -> int:
	return buildings.filter(func(b) -> bool: return Items.HARVEST.has(b.id)).size()


# Berries ripen again, and now and then a tree or a rock grows back somewhere, so the land never runs out.
func _grow_nature() -> void:
	for building in buildings:
		if building.id == "bush" and not building.ready and clock >= building.get("regrow_at", 0.0):
			building.ready = true
			building.root.texture = Art.decor("bush")
	if randf() < 0.03:
		_spawn_wild_dinos(1)
	if randf() > 0.12 or _count_nature() >= natural_target:
		return
	var cell := Vector2i(randi_range(0, GRID.x - 1), randi_range(0, GRID.y - 1))
	if occupied.has(cell) or is_water(cell) or Vector2(cell - player.cell()).length() < 6.0 or _dino_near(cell_center(cell), 16.0):
		return
	if region_map[_index(cell)] >= 0 and regions[region_map[_index(cell)]].enclosed:
		return
	var id := WorldGen.pick(biome_at(cell), RandomNumberGenerator.new())
	if id != "" and id != "mountain":
		_add_building(id, cell)
		_refresh()


# --- The Wild Lands -------------------------------------------------------

const TRAIL_NAMES := {Vector2i.UP: "up", Vector2i.DOWN: "down", Vector2i.LEFT: "left", Vector2i.RIGHT: "right"}


# The cell `along` the side `dir` of the zone, `depth` cells in from its edge.
func _edge_cell(dir: Vector2i, along: int, depth: int) -> Vector2i:
	match dir:
		Vector2i.UP:
			return Vector2i(along, depth)
		Vector2i.DOWN:
			return Vector2i(along, GRID.y - 1 - depth)
		Vector2i.LEFT:
			return Vector2i(depth, along)
	return Vector2i(GRID.x - 1 - depth, along)


func _along(dir: Vector2i, cell: Vector2i) -> int:
	return cell.x if dir.y != 0 else cell.y


# Where the trails out of the park are on this side.
func _trails(dir: Vector2i) -> Array:
	var saved = base_exits.get(TRAIL_NAMES[dir], [])
	return (saved if saved is Array else [saved]).map(func(at) -> int: return int(at))


func _on_trail(dir: Vector2i, along: int) -> bool:
	return _trails(dir).any(func(at: int) -> bool: return absi(along - at) <= 1)


func _nearest_trail(dir: Vector2i, along: int) -> int:
	var best := along
	var best_distance := 1000000
	for at: int in _trails(dir):
		if absi(at - along) < best_distance:
			best_distance = absi(at - along)
			best = at
	return best


# Opens the trails out of the park, where they cross the least: a park made before the Wild
# Lands may have trees, rocks or water there, never what the player built. On the right, the
# trail is a causeway of sand across the sea.
func _carve_base_exits() -> void:
	for dir: Vector2i in Wild.BASE_TRAILS:
		var trails := _trails(dir)
		var count: int = Wild.BASE_TRAILS[dir]
		var length := GRID.x if dir.y != 0 else GRID.y
		var depth := 16 if dir == Vector2i.RIGHT else 5
		for i in count:
			var from := length * i / count + 6
			var to := length * (i + 1) / count - 6
			if trails.any(func(at: int) -> bool: return at >= from and at < to):
				continue
			var best := (from + to) / 2
			var best_cost := INF
			for along in range(from, to):
				if dir == Vector2i.LEFT and absi(along - ENTRANCE.y) <= 8:
					continue
				var cost := absf(along - (from + to) / 2.0) * 0.05
				for d in depth:
					for side in range(-1, 2):
						var cell := _edge_cell(dir, along + side, d)
						var building = occupied.get(cell)
						if building != null and not Items.HARVEST.has(building.id):
							cost += 20.0
						elif building != null:
							cost += 1.0
						elif is_water(cell) and dir != Vector2i.RIGHT:
							cost += 20.0
				if cost < best_cost:
					best_cost = cost
					best = along
			trails.append(best)
		base_exits[TRAIL_NAMES[dir]] = trails
		for at: int in trails:
			for d in depth:
				for side in range(-1, 2):
					var cell := _edge_cell(dir, at + side, d)
					if not in_grid(cell):
						continue
					var building = occupied.get(cell)
					if building != null and Items.HARVEST.has(building.id):
						remove_natural(cell)
					if (building == null or Items.HARVEST.has(building.id)) and is_water(cell):
						set_water(cell, false)
						biomes[_index(cell)] = "desert"
	ground.refresh(GRID / 2, maxi(GRID.x, GRID.y))


# The side of the zone a cell outside of it is on, or ZERO.
func _edge_of(cell: Vector2i) -> Vector2i:
	if cell.y < 0:
		return Vector2i.UP
	if cell.y >= GRID.y:
		return Vector2i.DOWN
	if cell.x < 0:
		return Vector2i.LEFT
	if cell.x >= GRID.x:
		return Vector2i.RIGHT
	return Vector2i.ZERO


# Whether the player can go out of the zone there: on the trails of the park on foot, anywhere
# on an open side of a wild zone, or anywhere by helicopter.
func _edge_open(dir: Vector2i, cell: Vector2i) -> bool:
	if not Wild.open_edge(zone, dir):
		return false
	if zone == Wild.BASE and player.vehicle != "heli":
		return _on_trail(dir, _along(dir, cell))
	return true


func _edge_crossed() -> Vector2i:
	var cell := Vector2i((player.position / T).floor())
	var dir := _edge_of(cell)
	if dir == Vector2i.ZERO or not _edge_open(dir, cell):
		return Vector2i.ZERO
	return dir


# What the camera may show: the zone and its forest, but not past a side open on the next zone,
# where there is nothing to see.
func _zone_bounds() -> Rect2:
	var rect := Rect2(Vector2.ZERO, Vector2(GRID * T))
	for dir: Vector2i in DIRS:
		if zone == Wild.BASE or not Wild.open_edge(zone, dir):
			rect = rect.grow_side([SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM][DIRS.find(dir)], BORDER * T)
	return rect


# Goes into the next zone, at the same place on its opposite side.
func _cross_edge(dir: Vector2i) -> void:
	var at := player.position
	var size := Vector2(GRID * T)
	if dir.x != 0:
		at.x = 0.5 * T if dir.x > 0 else size.x - 0.5 * T
	else:
		at.y = 0.5 * T if dir.y > 0 else size.y - 0.5 * T
	var next := zone + dir
	if next == Wild.BASE and player.vehicle != "heli":
		# Into the park by the nearest trail.
		var cell := Vector2i((at / T).floor())
		var trail := _nearest_trail(-dir, _along(-dir, cell))
		if dir.y != 0:
			at.x = (trail + 0.5) * T
		else:
			at.y = (trail + 0.5) * T
	travel(next, at)


# Leaves the zone the player is in and builds another one: the park comes back as it was left,
# a wild zone is made again from its seed. at: where the player arrives, in pixels.
func travel(to: Vector2i, at: Vector2) -> void:
	if to == zone:
		player.position = at
		camera.position = at
		return
	if zone == Wild.BASE:
		base_land = SaveGame.land(self)
		left_base_at = clock
	else:
		remember_zone()
	_clear_land()
	zone = to
	loading = true
	if zone == Wild.BASE:
		_add_building("path", ENTRANCE, true)
		_load_park(base_land)
		base_land = {}
	else:
		WorldGen.generate_zone(self, zone, world_seed)
		_rebuild_zone()
		_finish_loading()
	_build_border()
	world_bounds = _zone_bounds()
	camera.bounds = world_bounds
	natural_target = _count_nature()
	var cell := _arrival_cell(Vector2i((at / T).floor()))
	player.position = cell_center(cell) if not in_grid(Vector2i((at / T).floor())) or player_blocked(Vector2i((at / T).floor())) else at
	player.velocity = Vector2.ZERO
	camera.position = player.position
	_spawn_wild_dinos(WILD_TARGET)
	_refresh()
	hud.refresh_build()
	if zone == Wild.BASE:
		_pay_visitors_while_away()
	else:
		var stars := "★".repeat(Wild.level(zone))
		hud.flash("%s  %s" % [Wild.name_of(zone), stars], 2.5)


# The park kept living while the player was away: the visitors paid their ticket.
func _pay_visitors_while_away() -> void:
	_update_attraction()
	var minutes := (clock - left_base_at) / 60.0
	var count := mini(int(minutes * attraction), 2000)
	if count <= 0:
		hud.flash("De retour au parc !", 2.0)
		return
	money += count * TICKET_PRICE
	total_visitors += count
	hud.flash("De retour au parc !\n%d visiteurs sont venus : +%d pièces" % [count, count * TICKET_PRICE], 3.5)


# The nearest free cell to arrive on, cleared of what grows on it.
func _arrival_cell(wanted: Vector2i) -> Vector2i:
	wanted = wanted.clamp(Vector2i.ZERO, GRID - Vector2i.ONE)
	for radius in 12:
		for y in range(wanted.y - radius, wanted.y + radius + 1):
			for x in range(wanted.x - radius, wanted.x + radius + 1):
				var cell := Vector2i(x, y)
				if not in_grid(cell) or maxi(absi(x - wanted.x), absi(y - wanted.y)) != radius or is_water(cell):
					continue
				var building = occupied.get(cell)
				if building == null:
					return cell
				if Items.HARVEST.has(building.id) and building.id != "rock":
					remove_natural(cell)
					return cell
	return wanted


# What the player changed in the wild zone they are in: what they built there and the fires
# they lit. Kept in zone_states, saved with the game. A zone is in it once visited.
func remember_zone() -> void:
	if zone == Wild.BASE:
		return
	var built := []
	var fires := []
	for building in buildings:
		if building.get("found", false):
			if building.lit:
				fires.append([building.origin.x, building.origin.y])
		elif Items.item_for_building(building.id) != "" and not Items.HARVEST.has(building.id):
			built.append([building.id, building.origin.x, building.origin.y])
	zone_states[Wild.key(zone)] = {"built": built, "fires": fires}


# Puts back what the player built in this zone and lights again the fires they lit.
func _rebuild_zone() -> void:
	var state: Dictionary = zone_states.get(Wild.key(zone), {})
	zone_states[Wild.key(zone)] = state
	for entry in state.get("built", []):
		var cell := Vector2i(int(entry[1]), int(entry[2]))
		if not Catalog.ITEMS.has(entry[0]) or not in_grid(cell):
			continue
		remove_natural(cell)
		if entry[0] == "bridge":
			set_water(cell, true)
		elif entry[0] != "path":
			set_water(cell, false)
		_add_building(entry[0], cell)
	var lit: Array = state.get("fires", []).map(func(at: Array) -> Vector2i: return Vector2i(int(at[0]), int(at[1])))
	for building in buildings:
		if building.get("found", false):
			_set_fire(building, building.origin in lit)


# A campfire found in the wild, out until the player lights it.
func add_camp(cell: Vector2i) -> void:
	remove_natural(cell)
	set_water(cell, false)
	var building := _add_building("campfire", cell)
	building.found = true
	_set_fire(building, false)


func _set_fire(building: Dictionary, lit: bool) -> void:
	building.lit = lit
	_draw_fire(building)


func _draw_fire(building: Dictionary) -> void:
	if building.root != null:
		building.root.queue_free()
	var foot := Vector2((building.origin.x + 0.5) * T, (building.origin.y + 1) * T - 1)
	if building.lit:
		var flames := FlipBook.new()
		var frames: Array[Texture2D] = [Art.campfire(true, 0), Art.campfire(true, 1), Art.campfire(true, 2)]
		flames.setup(frames, 6.0)
		flames.position = foot - Vector2(9, 20)
		building.root = flames
	else:
		building.root = Art.sprite(Art.campfire(false, 0))
		building.root.position = foot
	world.add_child(building.root)


# Action in front of a campfire: lights it, or opens its menu (rest, cook, travel).
func use_campfire(building: Dictionary) -> void:
	if not building.lit:
		_set_fire(building, true)
		remember_zone()
		_set_respawn(building)
		hud.flash("Tu as allumé le feu de camp !\nTu pourras y revenir depuis la carte.", 3.0)
		return
	_set_respawn(building)
	hud.open_campfire()


func _set_respawn(building: Dictionary) -> void:
	respawn = {"zone": Wild.key(zone), "x": building.origin.x, "y": building.origin.y + 1}


func rest() -> void:
	hearts = MAX_HEARTS
	hud.set_hearts(hearts, MAX_HEARTS)
	hud.flash("Tu te reposes près du feu…\nTu es en pleine forme !", 2.5)


# Grills one meat, or bakes a pie with 2 berries. Returns false if there is not enough.
func cook(what: String) -> bool:
	var needs := {"meat": 1} if what == "meat_cooked" else {"berries": 2}
	if not inventory.has_all(needs):
		return false
	for id in needs:
		inventory.remove(id, needs[id])
	inventory.add(what)
	return true


# The fires lit in each zone, for the map: zone key -> cells.
func lit_fires() -> Dictionary:
	if zone != Wild.BASE:
		remember_zone()
	var fires := {}
	for key in zone_states:
		var cells: Array = zone_states[key].get("fires", [])
		cells = cells + zone_states[key].get("built", []).filter(func(entry: Array) -> bool: return entry[0] == "campfire").map(func(entry: Array) -> Array: return [entry[1], entry[2]])
		if not cells.is_empty():
			fires[key] = cells
	return fires


func visited(target: Vector2i) -> bool:
	return target == Wild.BASE or zone_states.has(Wild.key(target))


# From the map: to the park, or next to a lit campfire of a zone. Not from a mine or the village.
func travel_by_map(target: Vector2i) -> String:
	if away != null:
		return "Sors d'abord de la mine ou du village !"
	if player.mount != null:
		return "Descends de ton dinosaure pour voyager"
	if player.vehicle != "":
		player_leave_vehicle()
	if target == Wild.BASE:
		travel(Wild.BASE, cell_center(ENTRANCE + Vector2i(3, 0)))
		return ""
	var fires: Array = lit_fires().get(Wild.key(target), [])
	if fires.is_empty():
		return "Allume d'abord un feu de camp dans cette zone"
	travel(target, cell_center(Vector2i(int(fires[0][0]), int(fires[0][1]) + 1)))
	return ""


func go_to_respawn() -> void:
	if respawn.is_empty():
		travel(Wild.BASE, cell_center(ENTRANCE + Vector2i(2, 0)))
		return
	travel(Wild.from_key(respawn.zone), cell_center(Vector2i(int(respawn.x), int(respawn.y))))
	hearts = MAX_HEARTS
	hud.set_hearts(hearts, MAX_HEARTS)


# Empties the land: every building, dinosaur and visitor goes, the ground is blank again.
func _clear_land() -> void:
	for building in buildings:
		if building.root != null:
			building.root.queue_free()
		for node in building.nodes:
			if is_instance_valid(node):
				node.queue_free()
	buildings.clear()
	occupied.clear()
	for dino in dinos:
		dino.queue_free()
	dinos.clear()
	for visitor in get_tree().get_nodes_in_group("visitors"):
		visitor.queue_free()
	biomes.fill("prairie")
	water.fill(0)
	distance.clear()
	if combat != null:
		combat.target = null
		combat.chosen = null


# --- Helpers -----------------------------------------------------------

func is_path(cell: Vector2i) -> bool:
	var building = occupied.get(cell)
	return building != null and building.kind == "path"


func is_road(cell: Vector2i) -> bool:
	var building = occupied.get(cell)
	return building != null and building.kind == "road"


func biome_at(cell: Vector2i) -> String:
	return biomes[_index(cell)]


func _is_fence(cell: Vector2i) -> bool:
	var building = occupied.get(cell)
	return building != null and building.kind == "fence"


# Fences, mountains and water all close an enclosure (a bridge crosses the water).
func _is_wall(cell: Vector2i) -> bool:
	var building = occupied.get(cell)
	if building == null:
		return water[_index(cell)] == 1
	return building.kind in ["fence", "mountain", "mine"]


func is_water(cell: Vector2i) -> bool:
	return in_grid(cell) and water[_index(cell)] == 1


func set_water(cell: Vector2i, value: bool) -> void:
	water[_index(cell)] = 1 if value else 0


# Removes a natural thing while the land is being generated.
func remove_natural(cell: Vector2i) -> void:
	var building = occupied.get(cell)
	if building == null:
		return
	occupied.erase(cell)
	buildings.erase(building)
	if building.root != null:
		building.root.queue_free()


func _is_mountain(cell: Vector2i) -> bool:
	var building = occupied.get(cell)
	return building != null and building.kind == "mountain"


func mountain_level(cell: Vector2i) -> int:
	if _is_mountain(cell):
		return occupied[cell].level
	var building = occupied.get(cell)
	return 0 if building != null and building.kind == "mine" else -1


# The deeper a mountain cell is inside its range, the higher it rises.
func _reshape_mountains_around(center: Vector2i) -> void:
	var reach := MAX_MOUNTAIN_LEVEL + 1
	for y in range(center.y - reach, center.y + reach + 1):
		for x in range(center.x - reach, center.x + reach + 1):
			var cell := Vector2i(x, y)
			if _is_mountain(cell):
				occupied[cell].level = _mountain_level(cell)
	ground.refresh(center, reach + 1)


func _mountain_level(cell: Vector2i) -> int:
	for ring in range(1, MAX_MOUNTAIN_LEVEL + 1):
		for y in range(cell.y - ring, cell.y + ring + 1):
			for x in range(cell.x - ring, cell.x + ring + 1):
				if maxi(absi(x - cell.x), absi(y - cell.y)) == ring and not _is_mountain(Vector2i(x, y)):
					return ring - 1
	return MAX_MOUNTAIN_LEVEL


# Height of the ground under the helicopter, in pixels.
func ground_height(at: Vector2) -> float:
	var cell := Vector2i((at / T).floor())
	return (mountain_level(cell) + 1) * 6.0 if _is_mountain(cell) else 0.0


func random_ground_point() -> Vector2:
	return Vector2(randf_range(4.0, GRID.x - 4.0), randf_range(4.0, GRID.y - 4.0)) * T


func path_neighbors(cell: Vector2i) -> Array:
	var result := []
	for dir in DIRS:
		if is_path(cell + dir):
			result.append(cell + dir)
	return result


func road_neighbors(cell: Vector2i) -> Array:
	var result := []
	for dir in DIRS:
		if is_road(cell + dir):
			result.append(cell + dir)
	return result


func distance_to_entrance(cell: Vector2i) -> int:
	return distance.get(cell, NOT_CONNECTED)


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * T


func _index(cell: Vector2i) -> int:
	return cell.y * GRID.x + cell.x


func index_of(cell: Vector2i) -> int:
	return _index(cell)


func _mouse_cell() -> Vector2i:
	return Vector2i((get_global_mouse_position() / T).floor())


func in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID.x and cell.y < GRID.y


func _cells(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in size.x:
		for y in size.y:
			result.append(origin + Vector2i(x, y))
	return result


func _is_free(origin: Vector2i, size: Vector2i) -> bool:
	for c in _cells(origin, size):
		if not in_grid(c) or occupied.has(c):
			return false
	return true


func _float_text(at: Vector2, text: String, color: Color) -> void:
	var node := WorldText.make(world, at + Vector2(0, -14), text, "float", color)
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "position:y", node.position.y - 16.0, 1.2)
	tween.tween_property(node, "modulate:a", 0.0, 1.2)
	tween.chain().tween_callback(node.queue_free)


func _update_hover_info() -> void:
	if hud == null or mode == "adventure":
		return
	var info := Catalog.tool_info(tool)
	var text: String = info.name + " : " + info.info
	if in_grid(hover):
		var detail := _describe_cell(hover)
		if detail != "":
			text += "\n\n" + detail
	hud.set_info(text)


func _describe_cell(cell: Vector2i) -> String:
	var building = occupied.get(cell)
	if building != null:
		var item: Dictionary = Catalog.ITEMS[building.id]
		match building.kind:
			"aviary", "lagoon":
				var names := PackedStringArray(building.dinos.map(func(d) -> String: return d.species.name))
				return "%s : %d / %d — %s" % [item.name, building.dinos.size(), item.capacity, ", ".join(names) if not names.is_empty() else "vide"]
			"feeder":
				return "%s : %d / %d portions" % [item.name, building.stock, item.stock]
			"fence":
				return "Barrière %s : force %d" % [item.name, item.strength]
	var region := region_map[_index(cell)]
	if region < 0 or not regions[region].enclosed:
		return ""
	var data: Dictionary = regions[region]
	var main_biome := ""
	var main_count := 0
	for biome in data.biomes:
		if data.biomes[biome] > main_count:
			main_biome = biome
			main_count = data.biomes[biome]
	var weakest := 99
	for f in data.fences:
		weakest = mini(weakest, Catalog.ITEMS[occupied[f].id].strength)
	var counts := {}
	for dino in dinos:
		if dino.habitat == "land" and dino.region == region and not dino.escaped:
			counts[dino.species.name] = counts.get(dino.species.name, 0) + 1
	var residents := []
	for name in counts:
		residents.append("%d %s" % [counts[name], name])
	var fence_text := "barrière la plus faible : force %d" % weakest if weakest < 99 else "fermé par des montagnes"
	return "Enclos de %d cases — surtout %s (%d %%) — %s\nDinosaures : %s\n%s" % [
		data.cells.size(), Catalog.BIOMES[main_biome].name, main_count * 100 / data.cells.size(), fence_text,
		", ".join(PackedStringArray(residents)) if not residents.is_empty() else "aucun",
		"Les visiteurs le voient." if data.visible else "Personne ne le voit : fais passer un chemin le long de la barrière."]


# --- Preview of what will be built -----------------------------------------

func _update_ghost() -> void:
	ghost.visible = false
	if _pen_active() and pen_start != NONE and painting:
		ghost_cells = _pen_plan(pen_start, hover)
		ghost.visible = true
		ghost.queue_redraw()
		var count := ghost_cells.filter(func(step: Dictionary) -> bool: return step.ok).size()
		hud.set_info("Enclos : %d barrières sur %d cases" % [count, ghost_cells.size()])
		return
	ghost_cells.clear()
	if not in_grid(hover):
		return
	if tool == "bulldozer":
		var building = occupied.get(hover)
		if building != null and not building.fixed:
			_show_ghost(building.origin, building.size, Color("e53935"))
		return
	var size := Vector2i.ONE
	var origin := hover
	var ok := true
	if tool.begins_with("biome:"):
		_show_ghost(origin, size, Catalog.BIOMES[tool.substr(6)].color)
		return
	if tool.begins_with("dino:"):
		ok = not (_dino_home_at(Catalog.DINOS[tool.substr(5)], hover) is String)
	elif tool == "drive:heli":
		var building = occupied.get(hover)
		ok = building != null and building.kind == "heliport"
	elif tool.begins_with("drive:"):
		ok = not is_blocked_for_vehicle(tool.substr(6), hover)
	elif Catalog.ITEMS.has(tool):
		var item: Dictionary = Catalog.ITEMS[tool]
		size = Catalog.size_of(item)
		origin = hover - size / 2
		ok = _is_free(origin, size) and money >= item.cost
	_show_ghost(origin, size, Color("66bb6a") if ok else Color("e53935"))


func _show_ghost(origin: Vector2i, size: Vector2i, color: Color) -> void:
	var rect := Rect2(Vector2(origin * T), Vector2(size * T))
	ghost.visible = true
	if rect != ghost_rect or color != ghost_color:
		ghost_rect = rect
		ghost_color = color
		ghost.queue_redraw()


func _draw_ghost() -> void:
	if mode == "adventure":
		# Just the corners, like a target, so we still see what is in the cell.
		var r := ghost_rect
		for corner in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
			var inward: Vector2 = (r.get_center() - corner).sign()
			ghost.draw_line(corner, corner + Vector2(inward.x * 5, 0), ghost_color, 1.5)
			ghost.draw_line(corner, corner + Vector2(0, inward.y * 5), ghost_color, 1.5)
		return
	if not ghost_cells.is_empty():
		for step in ghost_cells:
			var rect := Rect2(Vector2(step.cell * T), Vector2(T, T))
			var color := Color("66bb6a") if step.ok else Color("e53935")
			ghost.draw_rect(rect, Color(color, 0.4))
			ghost.draw_rect(rect, Color(color.darkened(0.3), 0.9), false, 1.0)
		return
	ghost.draw_rect(ghost_rect, Color(ghost_color, 0.35))
	ghost.draw_rect(ghost_rect, Color(ghost_color.darkened(0.3), 0.9), false, 1.0)


# --- World -------------------------------------------------------------

func _build_world() -> void:
	var size := Vector2(GRID * T)
	RenderingServer.set_default_clear_color(Color("3f8a4c"))

	ground = Ground.new()
	ground.z_index = -10
	add_child(ground)
	ground.setup(self)

	floor_layer = Node2D.new()
	floor_layer.z_index = -5
	add_child(floor_layer)

	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)

	_build_border()

	camera = ParkCamera.new()
	add_child(camera)
	world_bounds = Rect2(-Vector2.ONE * BORDER * T, size + Vector2.ONE * BORDER * T * 2)
	camera.setup(cell_center(ENTRANCE + Vector2i(14, 0)), world_bounds)
	camera.make_current()
	camera.zoomed.connect(func(level: int) -> void:
		if hud != null:
			hud.flash("Zoom ×%d" % level))

	ghost = Node2D.new()
	ghost.z_index = 20
	ghost.draw.connect(_draw_ghost)
	add_child(ghost)


# A thick forest all around the zone, like in the old handheld games. The park has its gate on
# the left and trails out on every side; a wild zone is open on its sides that lead to another zone.
func _build_border() -> void:
	for node in border_nodes:
		node.queue_free()
	border_nodes.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42 + zone.x * 13 + zone.y * 7
	var base := zone == Wild.BASE
	var trails := base and mode == "adventure"
	for ring in BORDER:
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN]:
			if not base and Wild.open_edge(zone, dir):
				continue
			var y := -1 - ring if dir == Vector2i.UP else GRID.y + ring
			for x in range(-BORDER, GRID.x + BORDER):
				if not (trails and _on_trail(dir, x)):
					_border_tree(Vector2i(x, y), rng)
		for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			if not base and Wild.open_edge(zone, dir):
				continue
			var x := -1 - ring if dir == Vector2i.LEFT else GRID.x + ring
			for y in range(-BORDER + ring, GRID.y + BORDER - ring):
				if base and x < 0 and absi(y - ENTRANCE.y) <= 2:
					continue
				if not (trails and _on_trail(dir, y)):
					_border_tree(Vector2i(x, y), rng)
	if not base:
		return
	if mode == "adventure":
		var village_sign := Art.sprite(Art.signpost())
		village_sign.position = Vector2(-1.5 * T, ENTRANCE.y * T - 1)
		village_sign.flip_h = true
		_add_border(village_sign)
		WorldText.make(village_sign, Vector2(0, -24), "← Village", "sign")
	var gate := Art.sprite(Art.gate())
	gate.position = Vector2(-0.5 * T, (ENTRANCE.y + 3) * T)
	_add_border(gate)
	_add_trail(Rect2(-BORDER * T, ENTRANCE.y * T, BORDER * T, T))
	if not trails:
		return
	var arrows := {Vector2i.UP: "↑", Vector2i.DOWN: "↓", Vector2i.LEFT: "←", Vector2i.RIGHT: "→"}
	for dir: Vector2i in Wild.BASE_TRAILS:
		for at: int in _trails(dir):
			# A dirt trail through the forest, and a sign by it.
			var sign := Art.sprite(Art.signpost())
			match dir:
				Vector2i.UP:
					_add_trail(Rect2((at - 1) * T, -BORDER * T, 3 * T, BORDER * T))
					sign.position = Vector2((at + 2.5) * T, T - 1)
				Vector2i.DOWN:
					_add_trail(Rect2((at - 1) * T, GRID.y * T, 3 * T, BORDER * T))
					sign.position = Vector2((at + 2.5) * T, (GRID.y - 1) * T - 1)
				Vector2i.LEFT:
					_add_trail(Rect2(-BORDER * T, (at - 1) * T, BORDER * T, 3 * T))
					sign.position = Vector2(1.5 * T, (at - 1) * T - 1)
				Vector2i.RIGHT:
					_add_trail(Rect2(GRID.x * T, (at - 1) * T, BORDER * T, 3 * T))
					sign.position = Vector2((GRID.x - 1.5) * T, (at - 1) * T - 1)
			_add_border(sign)
			WorldText.make(sign, Vector2(0, -24), "%s Terres sauvages" % arrows[dir], "sign")


# A strip of dirt under the forest, for a road or a trail.
func _add_trail(rect: Rect2) -> void:
	var trail := ColorRect.new()
	trail.color = Color("e8d4a0")
	trail.position = rect.position
	trail.size = rect.size
	trail.z_index = -9
	add_child(trail)
	border_nodes.append(trail)


func _add_border(node: Node2D) -> void:
	world.add_child(node)
	border_nodes.append(node)


func _border_tree(cell: Vector2i, rng: RandomNumberGenerator) -> void:
	var tree := Art.sprite(Art.border_tree(rng.randi() % 3))
	tree.position = Vector2((cell.x + 0.5) * T + rng.randi_range(-2, 2), (cell.y + 1) * T + 4)
	Art.ground_shadow(tree, 28)
	_add_border(tree)


# --- Demo park (godot --path . -- --demo) ------------------------------------

func _build_demo() -> void:
	# (Laid out for the first, smaller map: it sits around the entrance row.)
	money = 999999
	for x in range(1, 51):
		_build("path", Vector2i(x, 48))
	for y in range(8, 24):
		_build("path", Vector2i(20, y + 24))
	for y in range(25, 41):
		_build("path", Vector2i(20, y + 24))
	for y in range(14, 24):
		_build("path", Vector2i(35, y + 24))
	for x in range(36, 47):
		_build("path", Vector2i(x, 38))
	for y in range(2, 14):
		_build("path", Vector2i(46, y + 24))
	_demo_pen(Rect2i(22, 36, 11, 12), "fence_electric", "prairie")
	_demo_pen(Rect2i(8, 36, 11, 12), "fence_stone", "jungle")
	_demo_pen(Rect2i(8, 49, 12, 12), "fence_glass", "prairie")
	_demo_pen(Rect2i(36, 28, 10, 10), "fence_concrete", "desert")
	# A brachiosaurus valley closed on the right by mountains.
	for x in range(58, 64):
		for y in range(0, 12):
			_build("mountain", Vector2i(x, y + 24))
	_demo_pen(Rect2i(47, 25, 12, 10), "fence_concrete", "jungle")
	_place_dino("brachiosaurus", Vector2i(52, 29))
	_build("feeder_plants", Vector2i(50, 27))
	_place_dino("trex", Vector2i(27, 41))
	_build("feeder_meat", Vector2i(25, 39))
	for cell in [Vector2i(12, 40), Vector2i(14, 42), Vector2i(11, 43)]:
		_place_dino("velociraptor", cell)
	_build("feeder_meat", Vector2i(10, 38))
	_place_dino("triceratops", Vector2i(12, 53))
	_place_dino("triceratops", Vector2i(15, 55))
	_place_dino("stegosaurus", Vector2i(11, 57))
	_build("feeder_plants", Vector2i(16, 52))
	_place_dino("ankylosaurus", Vector2i(40, 32))
	_place_dino("gallimimus", Vector2i(42, 34))
	_build("feeder_plants", Vector2i(39, 30))
	_build("aviary", Vector2i(40, 53))
	for id in ["pteranodon", "quetzalcoatlus", "dimorphodon", "tapejara"]:
		_place_dino(id, Vector2i(40, 53))
	_build("lagoon", Vector2i(28, 53))
	_place_dino("mosasaurus", Vector2i(28, 53))
	_place_dino("plesiosaurus", Vector2i(27, 52))
	_build("gyro_station", Vector2i(34, 40))
	_build("heliport", Vector2i(48, 50))
	for x in range(6, 45):
		_build("road", Vector2i(x, 65))
	_build("jeep_garage", Vector2i(22, 64))
	_build("icecream", Vector2i(19, 47))
	_build("burger", Vector2i(21, 46))
	_build("souvenir", Vector2i(3, 47))
	_build("volcano", Vector2i(52, 39))
	# Snowy mountains in the south-east.
	for x in range(52, 63):
		for y in range(31, 46):
			_paint_biome(Vector2i(x, y + 24), "neige")
			if x > 54 and y > 33 and (x - 54) + (y - 33) > 3:
				_build("mountain", Vector2i(x, y + 24))
	for cell in [Vector2i(5, 44), Vector2i(6, 52), Vector2i(48, 45), Vector2i(50, 60), Vector2i(17, 64), Vector2i(3, 51), Vector2i(30, 61)]:
		_build("tree", cell)
	for cell in [Vector2i(53, 56), Vector2i(53, 62), Vector2i(54, 66)]:
		_build("pine", cell)
	for cell in [Vector2i(9, 39), Vector2i(16, 45), Vector2i(13, 37)]:
		_build("fern", cell)
	for cell in [Vector2i(38, 35), Vector2i(43, 30)]:
		_build("cactus", cell)
	money = 8000


func _demo_pen(rect: Rect2i, fence: String, biome: String) -> void:
	for x in range(rect.position.x + 1, rect.end.x - 1):
		for y in range(rect.position.y + 1, rect.end.y - 1):
			_paint_biome(Vector2i(x, y), biome)
	for x in range(rect.position.x, rect.end.x):
		_build(fence, Vector2i(x, rect.position.y))
		_build(fence, Vector2i(x, rect.end.y - 1))
	for y in range(rect.position.y + 1, rect.end.y - 1):
		_build(fence, Vector2i(rect.position.x, y))
		_build(fence, Vector2i(rect.end.x - 1, y))

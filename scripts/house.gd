extends Node2D

# The inside of a house of the village: one room with its furniture and the dinosaur who lives
# there. Each one has something to say, and a present for the first visit.
#
# A zone like the village and the mines (same functions), entered with the action button in
# front of a house. The village waits, hidden, while the player is inside.

const Art := preload("res://scripts/art.gd")
const WorldText := preload("res://scripts/world_text.gd")
const T := 16
const SIZE := Vector2i(12, 9)
const DOOR := [Vector2i(5, 8), Vector2i(6, 8)]  # the doorway in the bottom wall, back to the village
# Who lives in each house, in the order of Village.HOUSES ("coins" are pièces).
const RESIDENTS := [
	{"name": "Mamie Rose", "gift": {"berries": 8},
		"first": "Bonjour mon petit ! Tiens, des baies de mon jardin.",
		"talk": ["Les herbivores adorent les baies !", "Reviens me voir quand tu veux."],
		"kind": "trike", "colors": {"skin": Color("b8a890"), "shirt": Color("c060a0"), "crest": Color("e0a0c0")}},
	{"name": "Marcel le boucher", "gift": {"meat": 5},
		"first": "Les carnivores adorent ma viande ! Prends-en un peu.",
		"talk": ["Lance de la viande à un carnivore sauvage : 5 fois, et il te suit !",
			"Tu trouveras de la viande à la boutique."],
		"kind": "rex", "colors": {"skin": Color("c05030"), "shirt": Color("f0f0f0"), "apron": true}},
	{"name": "Léa l'exploratrice", "gift": {"arrow": 10},
		"first": "J'ai vu un T-Rex près des montagnes ! Prends ces flèches.",
		"talk": ["Les dinos sauvages vivent loin du parc.", "Une capsule en or attrape même un T-Rex !"],
		"kind": "raptor", "colors": {"skin": Color("6a9a50"), "shirt": Color("4f7a2a"), "crest": Color("e8902a")}},
	{"name": "Papi Jules", "gift": {"coins": 30},
		"first": "Quand j'étais petit, il n'y avait pas de parc ici ! Tiens, une pièce pour toi… ou trente !",
		"talk": ["Ah, les dinosaures… quelle aventure !", "Les fossiles valent cher chez le marchand."],
		"kind": "trike", "colors": {"skin": Color("8a8a7a"), "shirt": Color("8a5a2a"), "crest": Color("6a6a5a")}},
	{"name": "Zoé la mineuse", "gift": {"capsule_copper": 2},
		"first": "Les mines cachent du cristal et de l'or. Voici deux capsules !",
		"talk": ["Une pioche en fer creuse plus vite.", "Plus tu descends dans la mine, plus c'est précieux !"],
		"kind": "raptor", "colors": {"skin": Color("9a70b0"), "shirt": Color("e86a2a"), "crest": Color("f0c830"), "apron": true}},
	{"name": "Docteur Paul", "gift": {"brush": 1},
		"first": "Je soigne les dinosaures. Une brosse les rend heureux, tiens !",
		"talk": ["Brosse tes dinos : ils deviennent tes amis.", "Un dino qui a faim cherche sa mangeoire."],
		"kind": "rex", "colors": {"skin": Color("d07050"), "shirt": Color("e8f0f8")}},
	{"name": "Nina la fermière", "gift": {"bush": 2},
		"first": "Plante ces buissons près de chez toi : ils donnent des baies !",
		"talk": ["Les buissons repoussent tout seuls.", "Une mangeoire nourrit tes dinos quand tu n'es pas là."],
		"kind": "ptero", "colors": {"skin": Color("d0b060"), "shirt": Color("6a9a40"), "crest": Color("e05050")}},
	{"name": "Tom le pilote", "gift": {"bolas": 2},
		"first": "Un jour, j'aurai un hélicoptère ! En attendant, prends ces bolas.",
		"talk": ["L'hélicoptère vole au-dessus de tout !", "Le vélo, c'est bien. La moto, c'est mieux !"],
		"kind": "ptero", "colors": {"skin": Color("4a8ab0"), "shirt": Color("2860c0"), "crest": Color("c0503a")}},
]

var index := 0
var resident: Dictionary
var state: Dictionary  # the village state: "gifts" lists the houses whose present was given
var solid := {}  # Vector2i -> "wall", "bed", "table", "cupboard", "plant", "stove" or "resident"
var player: Node2D = null  # set by the park while the player is here
var resident_cell := Vector2i(6, 3)
var resident_sprite: Sprite2D
var bubble: Node2D
var said := 0.0


func setup(house_index: int, look: int, village_state: Dictionary) -> void:
	index = house_index
	resident = RESIDENTS[index % RESIDENTS.size()]
	state = village_state
	state.gifts = state.get("gifts", []).map(func(i) -> int: return int(i))
	y_sort_enabled = true
	_lay_out()
	var image := Image.create(SIZE.x * T, SIZE.y * T, false, Image.FORMAT_RGBA8)
	for y in SIZE.y:
		for x in SIZE.x:
			_paint(image, Vector2i(x, y), look)
	# Darkness around the room, when the screen is bigger than it.
	var dark := ColorRect.new()
	dark.color = Color("14100c")
	dark.position = Vector2(-2000, -2000)
	dark.size = Vector2(SIZE * T) + Vector2(4000, 4000)
	dark.z_index = -11
	add_child(dark)
	var ground := Sprite2D.new()
	ground.centered = false
	ground.texture = ImageTexture.create_from_image(image)
	ground.z_index = -10
	add_child(ground)
	_place_sprites(look)


func bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(SIZE * T))


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * T


func is_solid(cell: Vector2i) -> bool:
	return not Rect2i(Vector2i.ZERO, SIZE).has_point(cell) or solid.has(cell)


func kind_at(cell: Vector2i) -> String:
	return solid.get(cell, "")


# Where the player stands when coming in.
func arrival() -> Vector2:
	return cell_center(DOOR[0] + Vector2i.UP) + Vector2(T / 2.0, 0)


func is_exit(cell: Vector2i) -> bool:
	return cell in DOOR


# The resident talks: the present on the first visit, then a few words.
# Returns the present ({} once given).
func talk() -> Dictionary:
	said = 4.0
	if not index in state.gifts:
		state.gifts.append(index)
		bubble.set_text(resident.first)
		return resident.gift
	bubble.set_text(resident.talk.pick_random())
	return {}


func _process(delta: float) -> void:
	if said > 0.0:
		said -= delta
		if said <= 0.0:
			bubble.set_text("")
	# The resident looks at the player.
	if player != null:
		var to_player: Vector2 = player.position - resident_sprite.position
		var direction := "down"
		if absf(to_player.x) > absf(to_player.y):
			direction = "side"
		elif to_player.y < 0.0:
			direction = "up"
		resident_sprite.texture = Art.dino_folk(resident.kind, direction, 0, resident.colors)
		resident_sprite.flip_h = direction == "side" and to_player.x < 0.0
		if said <= 0.0 and player.position.distance_to(resident_sprite.position) < 26.0:
			bubble.set_text("Appuie sur Action pour parler !")
		elif said <= 0.0:
			bubble.set_text("")


func _lay_out() -> void:
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if (y < 2 or x == 0 or x == SIZE.x - 1 or y == SIZE.y - 1) and not cell in DOOR:
				solid[cell] = "wall"
	for cell in [Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3), Vector2i(2, 3)]:
		solid[cell] = "bed"
	for cell in [Vector2i(8, 4), Vector2i(9, 4)]:
		solid[cell] = "table"
	solid[Vector2i(10, 2)] = "cupboard"
	solid[Vector2i(4, 2)] = "stove"
	solid[Vector2i(1, 7)] = "plant"
	solid[Vector2i(10, 7)] = "plant"
	solid[resident_cell] = "resident"


func _paint(image: Image, cell: Vector2i, look: int) -> void:
	var at := cell * T
	var rect := Rect2i(at, Vector2i(T, T))
	if cell.y < 2 and cell.x > 0 and cell.x < SIZE.x - 1:
		# The back wall, seen from the front: logs like outside, or planks, and a skirting board.
		for y in T:
			for x in T:
				image.set_pixel(at.x + x, at.y + y, Art._log_wall(x, y) if look % 3 != 0 else Art._plank_wall(x, y))
		if cell.y == 1:
			image.fill_rect(Rect2i(at + Vector2i(0, T - 4), Vector2i(T, 4)), Color("8a5a30"))
		return
	if solid.get(cell, "") == "wall":
		image.fill_rect(rect, Color("5a3a20"))
		image.fill_rect(Rect2i(at + Vector2i(2, 2), Vector2i(T - 4, T - 4)), Color("6a4a2a"))
		return
	# A floor of clean planks, a rug in the middle and a doormat by the door.
	var base := Color("b8875a")
	image.fill_rect(rect, base)
	for y in range(3, T, 4):
		image.fill_rect(Rect2i(at + Vector2i(0, y), Vector2i(T, 1)), base.darkened(0.2))
	image.fill_rect(Rect2i(at + Vector2i((cell.y * 7) % T, 0), Vector2i(1, 3)), base.darkened(0.2))
	var rug := Rect2i(4, 4, 4, 3)
	if rug.has_point(cell):
		var color: Color = [Color("c0503a"), Color("4a78b8"), Color("6a9a40")][look % 3]
		image.fill_rect(rect, color)
		image.fill_rect(Rect2i(at + Vector2i(2, 2), Vector2i(T - 4, T - 4)), color.lightened(0.15))
	if cell + Vector2i.DOWN in DOOR:
		image.fill_rect(Rect2i(at + Vector2i(0, 6), Vector2i(T, 8)), Color("8a7a4a"))


func _place_sprites(look: int) -> void:
	_stand(Art.furniture("bed", look), Vector2i(1, 2), Vector2i(2, 2))
	_stand(Art.furniture("table", look), Vector2i(8, 4), Vector2i(2, 1))
	_stand(Art.furniture("chair", look), Vector2i(8, 5), Vector2i.ONE)
	_stand(Art.furniture("chair", look), Vector2i(9, 5), Vector2i.ONE)
	_stand(Art.furniture("cupboard", look), Vector2i(10, 2), Vector2i.ONE)
	_stand(Art.furniture("stove", look), Vector2i(4, 2), Vector2i.ONE)
	_stand(Art.furniture("plant", look), Vector2i(1, 7), Vector2i.ONE)
	_stand(Art.furniture("plant", look), Vector2i(10, 7), Vector2i.ONE)
	for x in [2, 8]:
		var window := _stand(Art.furniture("window", look), Vector2i(x, 0), Vector2i(2, 1))
		window.z_index = -5
	var shadow := Art.sprite(Art.shadow(12))
	shadow.centered = true
	shadow.offset = Vector2.ZERO
	shadow.position = cell_center(resident_cell) + Vector2(0, T / 2.0 - 1)
	add_child(shadow)
	resident_sprite = Art.sprite(Art.dino_folk(resident.kind, "down", 0, resident.colors))
	resident_sprite.position = cell_center(resident_cell) + Vector2(0, T / 2.0 - 1)
	add_child(resident_sprite)
	WorldText.make(resident_sprite, Vector2(0, 6), resident.name, "bubble", Color("6a4a2a"))
	bubble = WorldText.make(resident_sprite, Vector2(0, -27), "", "bubble")


# A standing sprite, its bottom center at the bottom middle of its cells.
func _stand(texture: Texture2D, origin: Vector2i, size: Vector2i) -> Sprite2D:
	var node := Art.sprite(texture)
	node.position = Vector2((origin.x + size.x / 2.0) * T, (origin.y + size.y) * T - 1)
	add_child(node)
	return node

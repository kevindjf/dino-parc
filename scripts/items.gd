extends RefCounted

const Catalog := preload("res://scripts/catalog.gd")

# Everything you can carry in your bag, what you can make with it, and what nature gives you.
# kind: resource, food, tool, weapon, ammo, catch, gear (worn as soon as it is in the bag),
# vehicle (held, the action button gets on it), or build (a build item places
# Catalog.ITEMS[place] in the park).

const ITEMS := {
	"wood": {"name": "Bois", "kind": "resource"},
	"stone": {"name": "Pierre", "kind": "resource"},
	"copper": {"name": "Cuivre", "kind": "resource"},
	"iron": {"name": "Fer", "kind": "resource"},
	"crystal": {"name": "Cristal", "kind": "resource"},
	"gold": {"name": "Or", "kind": "resource"},
	"amber": {"name": "Ambre", "kind": "resource"},
	"fossil": {"name": "Fossile", "kind": "resource"},
	"berries": {"name": "Baies", "kind": "food"},
	"meat": {"name": "Viande", "kind": "food"},
	"axe": {"name": "Hache", "kind": "tool"},
	"pickaxe": {"name": "Pioche", "kind": "tool"},
	"pickaxe_iron": {"name": "Pioche en fer", "kind": "tool"},
	"sapling": {"name": "Pousse d'arbre", "kind": "build", "place": "tree"},
	"bush": {"name": "Buisson à baies", "kind": "build", "place": "bush"},
	"path": {"name": "Chemin", "kind": "build", "place": "path"},
	"fence_bamboo": {"name": "Barrière en bambou", "kind": "build", "place": "fence_bamboo"},
	"fence_wood": {"name": "Barrière en bois", "kind": "build", "place": "fence_wood"},
	"fence_stone": {"name": "Barrière en pierre", "kind": "build", "place": "fence_stone"},
	"gate_wood": {"name": "Portail", "kind": "build", "place": "gate_wood"},
	"fence_electric": {"name": "Barrière électrique", "kind": "build", "place": "fence_electric"},
	"bridge": {"name": "Pont", "kind": "build", "place": "bridge"},
	"feeder_plants": {"name": "Mangeoire à plantes", "kind": "build", "place": "feeder_plants"},
	"feeder_meat": {"name": "Mangeoire à viande", "kind": "build", "place": "feeder_meat"},
	"slingshot": {"name": "Lance-pierre", "kind": "weapon"},
	"bow": {"name": "Arc", "kind": "weapon"},
	"arrow": {"name": "Flèches", "kind": "ammo"},
	"dart": {"name": "Fléchettes endormantes", "kind": "catch"},
	"bolas": {"name": "Bolas", "kind": "catch"},
	"cage": {"name": "Cage", "kind": "catch"},
	"capsule_copper": {"name": "Capsule en cuivre", "kind": "catch"},
	"capsule_iron": {"name": "Capsule en fer", "kind": "catch"},
	"capsule_gold": {"name": "Capsule en or", "kind": "catch"},
	"brush": {"name": "Brosse", "kind": "tool"},
	"saddle": {"name": "Selle", "kind": "catch"},
	"boots": {"name": "Bottes", "kind": "gear"},
	"boots_fast": {"name": "Bottes de course", "kind": "gear"},
	"bike": {"name": "Vélo", "kind": "vehicle"},
	"moto": {"name": "Moto", "kind": "vehicle"},
	"car": {"name": "Voiture", "kind": "vehicle"},
	"heli": {"name": "Hélicoptère", "kind": "vehicle"},
}

# Boots make the character walk faster (the best pair in the bag counts).
const GEAR_SPEED := {"boots": 1.25, "boots_fast": 1.5}
# What the character can drive, in cells per second (walking is 4). The helicopter flies over
# everything; the others go where the character can walk.
const VEHICLES := {
	"bike": {"speed": 8.0},
	"moto": {"speed": 11.0},
	"car": {"speed": 14.0},
	"heli": {"speed": 16.0, "flies": true},
}
# A caught dinosaur travels in the bag as "dino:<species>" (kind "dino").

# What can be shot or thrown at a wild dinosaur, from afar. Nobody gets hurt: a dinosaur hit
# loses energy, and once out of energy it falls asleep, ready to be caught.
#   ammo: what each shot uses up (itself for things thrown by hand)
#   tire: energy taken, stun: seconds it cannot move, range: in cells, every: seconds between shots
#   flight: how it flies (straight, arc or spin), capture: biggest strength a capsule can hold,
#   feed: thrown to make friends with the dinosaurs of that diet (berries for herbivores,
#   meat for carnivores)
const WEAPONS := {
	"slingshot": {"ammo": "stone", "tire": 8, "range": 6.0, "every": 0.45, "flight": "arc", "speed": 220.0},
	"bow": {"ammo": "arrow", "tire": 16, "range": 8.0, "every": 0.6, "flight": "straight", "speed": 300.0},
	"dart": {"ammo": "dart", "tire": 30, "range": 6.0, "every": 0.8, "flight": "straight", "speed": 260.0},
	"bolas": {"ammo": "bolas", "tire": 4, "stun": 4.0, "range": 5.0, "every": 0.8, "flight": "spin", "speed": 180.0},
	"berries": {"ammo": "berries", "feed": "herb", "range": 5.0, "every": 0.6, "flight": "arc", "speed": 160.0},
	"meat": {"ammo": "meat", "feed": "carn", "range": 5.0, "every": 0.6, "flight": "arc", "speed": 160.0},
	"capsule_copper": {"ammo": "capsule_copper", "capture": 3, "range": 5.0, "every": 1.0, "flight": "arc", "speed": 170.0},
	"capsule_iron": {"ammo": "capsule_iron", "capture": 4, "range": 5.0, "every": 1.0, "flight": "arc", "speed": 170.0},
	"capsule_gold": {"ammo": "capsule_gold", "capture": 5, "range": 5.0, "every": 1.0, "flight": "arc", "speed": 170.0},
}
# The cage is put by hand on a sleeping dinosaur, and only small ones fit in.
const CAGE_STRENGTH := 2

const RECIPES := [
	{"make": "axe", "count": 1, "needs": {"wood": 3}},
	{"make": "pickaxe", "count": 1, "needs": {"wood": 4}},
	{"make": "pickaxe_iron", "count": 1, "needs": {"iron": 3, "wood": 2}},
	{"make": "fence_bamboo", "count": 2, "needs": {"wood": 1}},
	{"make": "fence_wood", "count": 2, "needs": {"wood": 2}},
	{"make": "fence_stone", "count": 2, "needs": {"stone": 2}},
	{"make": "gate_wood", "count": 1, "needs": {"wood": 3}},
	{"make": "fence_electric", "count": 2, "needs": {"iron": 2, "copper": 1}},
	{"make": "bridge", "count": 2, "needs": {"wood": 3}},
	{"make": "path", "count": 4, "needs": {"stone": 1}},
	{"make": "feeder_plants", "count": 1, "needs": {"wood": 4, "berries": 3}},
	{"make": "feeder_meat", "count": 1, "needs": {"wood": 4, "meat": 3}},
	{"make": "slingshot", "count": 1, "needs": {"wood": 3}},
	{"make": "bow", "count": 1, "needs": {"wood": 5}},
	{"make": "arrow", "count": 5, "needs": {"wood": 1, "stone": 1}},
	{"make": "dart", "count": 3, "needs": {"wood": 1, "berries": 2}},
	{"make": "bolas", "count": 2, "needs": {"stone": 2, "wood": 1}},
	{"make": "cage", "count": 1, "needs": {"wood": 4, "stone": 2}},
	{"make": "capsule_copper", "count": 2, "needs": {"copper": 2, "stone": 1}},
	{"make": "capsule_iron", "count": 2, "needs": {"iron": 2, "copper": 1}},
	{"make": "capsule_gold", "count": 1, "needs": {"gold": 1, "iron": 1, "crystal": 1}},
	{"make": "brush", "count": 1, "needs": {"wood": 2, "berries": 1}},
	{"make": "saddle", "count": 1, "needs": {"wood": 4, "stone": 2, "berries": 2}},
]

# What each natural thing gives, how many hits it takes with bare hands, the tool that goes
# twice as fast, and the tool without which nothing happens.
const HARVEST := {
	"tree": {"gives": {"wood": 2}, "bonus": "sapling", "hits": 4, "fast": "axe", "needs": ""},
	"pine": {"gives": {"wood": 2}, "bonus": "sapling", "hits": 4, "fast": "axe", "needs": ""},
	"palm": {"gives": {"wood": 2}, "bonus": "sapling", "hits": 4, "fast": "axe", "needs": ""},
	"cactus": {"gives": {"wood": 1}, "hits": 2, "fast": "axe", "needs": ""},
	"fern": {"gives": {}, "hits": 1, "fast": "", "needs": ""},
	"bush": {"gives": {"berries": 3}, "hits": 1, "fast": "", "needs": ""},
	"rock": {"gives": {"stone": 2}, "hits": 3, "fast": "pickaxe", "needs": "pickaxe"},
}


static func name_of(id: String) -> String:
	if id.begins_with("dino:"):
		return "Capturé : " + Catalog.DINOS[id.substr(5)].name
	return ITEMS[id].name if ITEMS.has(id) else "Mains"


static func kind_of(id: String) -> String:
	if id.begins_with("dino:"):
		return "dino"
	return ITEMS[id].kind if ITEMS.has(id) else ""


static func exists(id: String) -> bool:
	return ITEMS.has(id) or (id.begins_with("dino:") and Catalog.DINOS.has(id.substr(5)))


# The bag item that builds this park building, or "" if it cannot be carried.
static func item_for_building(building_id: String) -> String:
	for id in ITEMS:
		if ITEMS[id].get("place", "") == building_id:
			return id
	return ""


static func describe_needs(needs: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in needs:
		parts.append("%d %s" % [needs[id], ITEMS[id].name])
	return " + ".join(parts)

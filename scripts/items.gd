extends RefCounted

const Catalog := preload("res://scripts/catalog.gd")

# Everything you can carry in your bag, what you can make with it, and what nature gives you.
# kind: resource, food, tool, or build (a build item places Catalog.ITEMS[place] in the park).

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
	"axe": {"name": "Hache", "kind": "tool"},
	"pickaxe": {"name": "Pioche", "kind": "tool"},
	"pickaxe_iron": {"name": "Pioche en fer", "kind": "tool"},
	"sapling": {"name": "Pousse d'arbre", "kind": "build", "place": "tree"},
	"path": {"name": "Chemin", "kind": "build", "place": "path"},
	"fence_bamboo": {"name": "Barrière en bambou", "kind": "build", "place": "fence_bamboo"},
	"fence_wood": {"name": "Barrière en bois", "kind": "build", "place": "fence_wood"},
	"fence_stone": {"name": "Barrière en pierre", "kind": "build", "place": "fence_stone"},
	"gate_wood": {"name": "Portail", "kind": "build", "place": "gate_wood"},
	"fence_electric": {"name": "Barrière électrique", "kind": "build", "place": "fence_electric"},
	"bridge": {"name": "Pont", "kind": "build", "place": "bridge"},
	"feeder_plants": {"name": "Mangeoire à plantes", "kind": "build", "place": "feeder_plants"},
	"dart": {"name": "Fléchettes", "kind": "catch"},
	"cage": {"name": "Cage", "kind": "catch"},
	"brush": {"name": "Brosse", "kind": "tool"},
	"saddle": {"name": "Selle", "kind": "catch"},
}
# A caught dinosaur travels in the bag as "dino:<species>" (kind "dino").

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
	{"make": "dart", "count": 3, "needs": {"wood": 1, "stone": 1}},
	{"make": "cage", "count": 1, "needs": {"wood": 4, "stone": 2}},
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
		return "Cage : " + Catalog.DINOS[id.substr(5)].name
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

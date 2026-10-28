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
	"egg": {"name": "Œuf de dino", "kind": "resource"},
	"berries": {"name": "Baies", "kind": "food"},
	"meat": {"name": "Viande", "kind": "food"},
	"meat_cooked": {"name": "Viande grillée", "kind": "food"},
	"fish": {"name": "Poisson", "kind": "food"},
	"fish_cooked": {"name": "Poisson grillé", "kind": "food"},
	"rod": {"name": "Canne à pêche", "kind": "tool"},
	"aviary": {"name": "Volière", "kind": "build", "place": "aviary"},
	"lagoon": {"name": "Lagon", "kind": "build", "place": "lagoon"},
	"pie": {"name": "Tarte aux baies", "kind": "food"},
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
	"campfire": {"name": "Feu de camp", "kind": "build", "place": "campfire"},
	"lab": {"name": "Laboratoire", "kind": "build", "place": "lab"},
	"feeder_plants": {"name": "Mangeoire à plantes", "kind": "build", "place": "feeder_plants"},
	"feeder_meat": {"name": "Mangeoire à viande", "kind": "build", "place": "feeder_meat"},
	"slingshot": {"name": "Lance-pierre", "kind": "weapon"},
	"bow": {"name": "Arc", "kind": "weapon"},
	"arrow": {"name": "Flèches", "kind": "ammo"},
	"spear": {"name": "Lance", "kind": "weapon"},
	"blowpipe": {"name": "Sarbacane", "kind": "weapon"},
	"sniper": {"name": "Fusil à lunette", "kind": "weapon"},
	"syringe": {"name": "Seringues", "kind": "ammo"},
	"net": {"name": "Filet", "kind": "catch"},
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
	"boat": {"name": "Barque", "kind": "vehicle"},
	"sailboat": {"name": "Voilier", "kind": "vehicle"},
	"speedboat": {"name": "Hors-bord", "kind": "vehicle"},
	"submarine": {"name": "Sous-marin", "kind": "vehicle"},
}

# The bag, the workbench and the shop sort things in these tabs (see tab_of()).
const TABS := [
	{"id": "tools", "name": "Outils", "icon": "axe"},
	{"id": "hunt", "name": "Chasse", "icon": "bow"},
	{"id": "food", "name": "Nourriture", "icon": "berries"},
	{"id": "build", "name": "Construire", "icon": "fence_wood"},
	{"id": "treasure", "name": "Trésors", "icon": "crystal"},
	{"id": "travel", "name": "Voyage", "icon": "bike"},
]
const TAB_OF_KIND := {
	"tool": "tools", "weapon": "hunt", "ammo": "hunt", "catch": "hunt", "food": "food",
	"build": "build", "resource": "treasure", "gear": "travel", "vehicle": "travel",
}

# What to do with a thing, told when the player takes it in hand from the bag.
const TIPS := {
	"saddle": "La selle : 1. Fais-toi aimer d'un gros dino de ton parc (3 cœurs) : brosse-le, donne-lui à manger.\n2. Selle en main, Action devant lui : hop, tu montes !\n3. Ensuite, Action devant lui (mains vides ou selle en main) pour remonter.",
	"brush": "La brosse : Action devant un dino de ton parc pour gagner son amitié. Une fois toutes les 20 secondes.",
	"sniper": "Le fusil à lunette tire de très loin. Parfait pour les gros dinos !",
	"campfire": "Pose le feu de camp où tu veux : tu pourras y revenir depuis la carte.",
	"lab": "Pose le laboratoire dans ton parc. Devant lui, Action : avec des fossiles et de l'ambre, il fait naître des bébés dinos !",
	"rod": "La canne à pêche : mets-toi face à l'eau et appuie sur Action. Les dinos volants et marins adorent les poissons !",
	"boat": "La barque : face à l'eau, Action pour monter dedans. Action face à la rive pour descendre. La mer est tout à l'est du monde !",
	"sailboat": "Le voilier va plus vite que la barque. Face à l'eau, Action pour monter dedans.",
	"speedboat": "Le hors-bord file sur la mer ! Face à l'eau, Action pour monter dedans.",
	"submarine": "Le sous-marin navigue sous l'eau : tu vois les reptiles marins en couleurs, et les épaves englouties ! Action au-dessus d'une épave pour la fouiller.",
	"aviary": "Pose la volière dans ton parc (8 × 8 cases), puis relâche-y tes dinos volants.",
	"lagoon": "Pose le lagon dans ton parc (12 × 8 cases), puis relâche-y tes reptiles marins.",
	"egg": "Un œuf trouvé dans la nature ! Porte-le au laboratoire de ton parc pour le faire éclore.",
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
	"boat": {"speed": 7.0, "sails": true},
	"sailboat": {"speed": 10.0, "sails": true},
	"speedboat": {"speed": 14.0, "sails": true},
	"submarine": {"speed": 9.0, "sails": true, "dives": true},
}
# A caught dinosaur travels in the bag as "dino:<species>" (kind "dino").

# What can be shot or thrown at a wild dinosaur, from afar. Nobody gets hurt: a dinosaur hit
# loses energy, and once out of energy it falls asleep, ready to be caught.
#   ammo: what each shot uses up (itself for things thrown by hand, "" for nothing)
#   tire: energy taken, stun: seconds it cannot move, range: in cells, every: seconds between shots
#   power: how much of `tire` it takes from a dinosaur of strength 1 to 5 (1 for all if absent):
#     a pebble bothers a small one but only tickles a T-Rex
#   pierce: goes through the armour of the ankylosaurus and the plates of the stegosaurus,
#     which other shots bounce off; quiet: the dinosaur neither runs away nor charges;
#   biggest: the strongest dinosaur it works on
#   flight: how it flies (straight, arc or spin), capture: biggest strength a capsule can hold,
#   feed: thrown to make friends with the dinosaurs of that diet (berries for herbivores,
#   meat for carnivores); worth: how many times plain food it counts (cooked food counts double)
const WEAPONS := {
	"slingshot": {"ammo": "stone", "tire": 10, "power": [1.5, 1.0, 0.5, 0.25, 0.1], "range": 6.0, "every": 0.45, "flight": "arc", "speed": 220.0},
	"bow": {"ammo": "arrow", "tire": 16, "power": [1.0, 1.0, 1.0, 0.75, 0.5], "range": 8.0, "every": 0.6, "flight": "straight", "speed": 300.0},
	"spear": {"ammo": "", "tire": 30, "pierce": true, "range": 2.5, "every": 0.7, "flight": "straight", "speed": 240.0},
	"blowpipe": {"ammo": "dart", "tire": 14, "power": [1.2, 1.0, 0.8, 0.6, 0.4], "quiet": true, "range": 7.0, "every": 0.9, "flight": "straight", "speed": 280.0},
	"dart": {"ammo": "dart", "tire": 30, "pierce": true, "range": 6.0, "every": 0.8, "flight": "straight", "speed": 260.0},
	"sniper": {"ammo": "syringe", "tire": 40, "power": [0.5, 0.7, 0.9, 1.0, 1.0], "pierce": true, "range": 20.0, "every": 1.5, "flight": "straight", "speed": 900.0},
	"bolas": {"ammo": "bolas", "tire": 4, "stun": 4.0, "range": 5.0, "every": 0.8, "flight": "spin", "speed": 180.0},
	"net": {"ammo": "net", "tire": 0, "stun": 7.0, "biggest": 3, "range": 4.0, "every": 1.0, "flight": "spin", "speed": 160.0},
	"berries": {"ammo": "berries", "feed": "herb", "range": 5.0, "every": 0.6, "flight": "arc", "speed": 160.0},
	"meat": {"ammo": "meat", "feed": "carn", "range": 5.0, "every": 0.6, "flight": "arc", "speed": 160.0},
	"pie": {"ammo": "pie", "feed": "herb", "worth": 2, "range": 5.0, "every": 0.6, "flight": "arc", "speed": 160.0},
	"meat_cooked": {"ammo": "meat_cooked", "feed": "carn", "worth": 2, "range": 5.0, "every": 0.6, "flight": "arc", "speed": 160.0},
	"fish": {"ammo": "fish", "feed": "fish", "range": 6.0, "every": 0.6, "flight": "arc", "speed": 170.0},
	"fish_cooked": {"ammo": "fish_cooked", "feed": "fish", "worth": 2, "range": 6.0, "every": 0.6, "flight": "arc", "speed": 170.0},
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
	{"make": "campfire", "count": 1, "needs": {"wood": 3, "stone": 3}},
	{"make": "lab", "count": 1, "needs": {"wood": 10, "stone": 8, "iron": 2, "crystal": 1}},
	{"make": "rod", "count": 1, "needs": {"wood": 2, "berries": 1}},
	{"make": "boat", "count": 1, "needs": {"wood": 15}},
	{"make": "sailboat", "count": 1, "needs": {"wood": 25, "iron": 3}},
	{"make": "speedboat", "count": 1, "needs": {"iron": 10, "copper": 6, "gold": 2}},
	{"make": "submarine", "count": 1, "needs": {"iron": 15, "crystal": 6, "gold": 3}},
	{"make": "aviary", "count": 1, "needs": {"wood": 20, "iron": 8}},
	{"make": "lagoon", "count": 1, "needs": {"stone": 25, "crystal": 4}},
	{"make": "path", "count": 4, "needs": {"stone": 1}},
	{"make": "feeder_plants", "count": 1, "needs": {"wood": 4, "berries": 3}},
	{"make": "feeder_meat", "count": 1, "needs": {"wood": 4, "meat": 3}},
	{"make": "slingshot", "count": 1, "needs": {"wood": 3}},
	{"make": "bow", "count": 1, "needs": {"wood": 5}},
	{"make": "arrow", "count": 5, "needs": {"wood": 1, "stone": 1}},
	{"make": "dart", "count": 3, "needs": {"wood": 1, "berries": 2}},
	{"make": "bolas", "count": 2, "needs": {"stone": 2, "wood": 1}},
	{"make": "spear", "count": 1, "needs": {"wood": 3, "stone": 2}},
	{"make": "blowpipe", "count": 1, "needs": {"wood": 4}},
	{"make": "net", "count": 2, "needs": {"wood": 2, "berries": 2}},
	{"make": "sniper", "count": 1, "needs": {"iron": 4, "crystal": 2, "wood": 2}},
	{"make": "syringe", "count": 3, "needs": {"iron": 1, "berries": 2}},
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


# The tab of the bag where this thing goes. The saddle is used on the dinosaurs of the park,
# like the brush: it goes with the tools.
static func tab_of(id: String) -> String:
	if id == "saddle":
		return "tools"
	return TAB_OF_KIND.get(kind_of(id), "")


# A vehicle that goes on water (boats and the submarine).
static func sails(id: String) -> bool:
	return VEHICLES.get(id, {}).get("sails", false)


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

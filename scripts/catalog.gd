extends RefCounted

# Everything you can build or buy in the park.
# Want a new dinosaur? Copy an entry in DINOS, change it, and add its id to a category below.

const BIOMES := {
	"prairie": {"name": "Prairie", "color": Color("6aa84f"), "want": "Je veux de la prairie"},
	"jungle": {"name": "Jungle", "color": Color("2e7d32"), "want": "Je veux de la jungle"},
	"desert": {"name": "Désert", "color": Color("e3c47d"), "want": "Je veux du désert"},
	"marais": {"name": "Marais", "color": Color("5f6f3a"), "want": "Je veux du marais"},
	"neige": {"name": "Neige", "color": Color("eef2f5"), "want": "Je veux de la neige"},
}
const BIOME_COST := 5

const ITEMS := {
	"path": {"name": "Chemin", "kind": "path", "cost": 10, "color": Color("e3cf9b"),
		"info": "Les visiteurs marchent sur les chemins. Un enclos se voit si un chemin longe sa barrière."},
	"road": {"name": "Route", "kind": "road", "cost": 20, "color": Color("5d5d5d"),
		"info": "Les jeeps roulent sur les routes."},
	"bridge": {"name": "Pont", "kind": "path", "cost": 20, "color": Color("c8a060"),
		"info": "Un pont en bois pour traverser l'eau. Les visiteurs marchent dessus comme sur un chemin."},
	"mine_entrance": {"name": "Entrée de mine", "kind": "mine", "cost": 0, "solid": true, "color": Color("2a2018"),
		"info": "Une grotte dans la montagne. Mets-toi devant et appuie sur Action pour descendre."},

	# A dinosaur breaks any fence weaker than its strength.
	"fence_bamboo": {"name": "Bambou", "kind": "fence", "cost": 10, "strength": 1, "style": "bamboo", "color": Color("c5b358")},
	"fence_wood": {"name": "Bois", "kind": "fence", "cost": 20, "strength": 2, "style": "wood", "color": Color("8d6e63")},
	"fence_stone": {"name": "Pierre", "kind": "fence", "cost": 40, "strength": 3, "style": "stone", "color": Color("9e9e9e")},
	"fence_glass": {"name": "Vitre", "kind": "fence", "cost": 60, "strength": 3, "style": "glass", "color": Color("81d4fa")},
	"fence_concrete": {"name": "Béton", "kind": "fence", "cost": 80, "strength": 4, "style": "concrete", "color": Color("cfd8dc")},
	"gate_wood": {"name": "Portail", "kind": "fence", "cost": 30, "strength": 2, "style": "gate", "color": Color("a0703c")},
	"fence_electric": {"name": "Électrique", "kind": "fence", "cost": 120, "strength": 5, "style": "electric", "color": Color("fdd835")},

	"feeder_plants": {"name": "Mangeoire à plantes", "kind": "feeder", "diet": "herb", "cost": 100, "stock": 6, "refill": 20,
		"color": Color("c0ca33"), "info": "Pour les herbivores. À poser dans l'enclos. Se remplit tout seul (20 pièces)."},
	"feeder_meat": {"name": "Mangeoire à viande", "kind": "feeder", "diet": "carn", "cost": 150, "stock": 4, "refill": 40,
		"color": Color("c62828"), "info": "Pour les carnivores. À poser dans l'enclos. Se remplit tout seul (40 pièces)."},

	"aviary": {"name": "Volière", "kind": "aviary", "cost": 1500, "size": Vector2i(8, 8), "capacity": 6, "color": Color("90a4ae"),
		"info": "Une grande cage pour les dinosaures volants (6 maximum). Doit toucher un chemin."},
	"lagoon": {"name": "Lagon", "kind": "lagoon", "cost": 2000, "size": Vector2i(12, 8), "capacity": 2, "color": Color("0288d1"),
		"info": "Un bassin pour les reptiles marins (2 maximum). Doit toucher un chemin."},

	"gyro_station": {"name": "Station gyrosphères", "kind": "gyro_station", "cost": 800, "size": Vector2i(2, 2), "attraction": 25,
		"color": Color("4fc3f7"), "info": "À coller contre la barrière d'un enclos et au bord d'un chemin. Les boules roulent au milieu des dinos."},
	"jeep_garage": {"name": "Garage à jeeps", "kind": "garage", "cost": 600, "size": Vector2i(2, 2), "attraction": 15,
		"color": Color("8d6e63"), "info": "À poser à côté d'une route et d'un chemin. Les jeeps font le tour du parc."},

	"mountain": {"name": "Montagne", "kind": "mountain", "cost": 30, "color": Color("8d8478"), "solid": true,
		"info": "Fais glisser pour dessiner un massif : plus il est large, plus il monte haut, avec de la neige au sommet. Les montagnes servent aussi de murs pour les enclos."},
	"heliport": {"name": "Héliport", "kind": "heliport", "cost": 1500, "size": Vector2i(3, 3), "attraction": 30,
		"color": Color("e53935"), "info": "Son hélicoptère emmène les visiteurs survoler le parc. Doit toucher un chemin. On peut aussi le piloter !"},

	"icecream": {"name": "Glaces", "kind": "shop", "style": "icecream", "cost": 150, "price": 5, "attraction": 5, "color": Color("f48fb1")},
	"burger": {"name": "Burgers", "kind": "shop", "style": "burger", "cost": 250, "price": 8, "attraction": 5, "color": Color("ff8f00")},
	"souvenir": {"name": "Souvenirs", "kind": "shop", "style": "souvenir", "cost": 400, "price": 12, "attraction": 8, "color": Color("7e57c2")},
	"campfire": {"name": "Feu de camp", "kind": "campfire", "cost": 30, "color": Color("f07818")},
	"lab": {"name": "Laboratoire", "kind": "lab", "cost": 1500, "size": Vector2i(2, 2), "color": Color("9ad8e8")},
	"nest": {"name": "Nid", "kind": "nest", "cost": 0, "color": Color("d8b060")},
	"tree": {"name": "Arbre", "kind": "decor", "style": "tree", "cost": 20, "attraction": 1, "color": Color("388e3c")},
	"pine": {"name": "Sapin", "kind": "decor", "style": "pine", "cost": 20, "attraction": 1, "color": Color("1b5e20")},
	"palm": {"name": "Palmier", "kind": "decor", "style": "palm", "cost": 30, "attraction": 1, "color": Color("7cb342")},
	"fern": {"name": "Fougère", "kind": "decor", "style": "fern", "cost": 10, "attraction": 1, "color": Color("43a047")},
	"bush": {"name": "Buisson à baies", "kind": "decor", "style": "bush", "cost": 15, "attraction": 1, "color": Color("3f9a44")},
	"cactus": {"name": "Cactus", "kind": "decor", "style": "cactus", "cost": 15, "attraction": 1, "color": Color("558b2f")},
	"rock": {"name": "Rocher", "kind": "decor", "style": "rock", "cost": 15, "attraction": 1, "color": Color("8d8d8d"), "solid": true},
	"volcano": {"name": "Volcan", "kind": "decor", "style": "volcano", "cost": 1000, "size": Vector2i(3, 3), "attraction": 15,
		"color": Color("6d4c41"), "solid": true},
}

# length: real length in meters (wingspan for flyers); the sprite is resized to match, one cell being 3 m.
# shape: body proportions used by dino_art.gd (x = length, y = height). space: number of cells each dinosaur needs.
const DINOS := {
	"triceratops": {"name": "Tricératops", "diet": "herb", "habitat": "land", "biome": "prairie", "strength": 3, "cost": 300,
		"attraction": 20, "space": 24, "speed": 0.6, "plan": "quad", "length": 9.0, "color": Color("43a047"), "color2": Color("c5e1a5"),
		"features": ["frill", "three_horns"], "sound": "MEUUUH !"},
	"stegosaurus": {"name": "Stégosaure", "diet": "herb", "habitat": "land", "biome": "jungle", "strength": 2, "cost": 350,
		"attraction": 22, "space": 24, "speed": 0.5, "plan": "quad", "length": 9.0, "color": Color("8d9440"), "color2": Color("e65100"),
		"features": ["plates", "tail_spikes"], "sound": "HMMMOOO !",
		"shape": {"leg": 0.38, "body": Vector3(1.1, 0.55, 0.55), "head": Vector3(0.3, 0.2, 0.22), "head_up": -0.2, "tail": 0.8}},
	"ankylosaurus": {"name": "Ankylosaure", "diet": "herb", "habitat": "land", "biome": "desert", "strength": 3, "cost": 350,
		"attraction": 20, "space": 16, "speed": 0.4, "plan": "quad", "length": 7.0, "color": Color("a1887f"), "color2": Color("5d4037"),
		"features": ["armor", "club"], "sound": "GROUMF !",
		"shape": {"leg": 0.22, "body": Vector3(1.1, 0.38, 0.75), "head": Vector3(0.36, 0.26, 0.4), "tail": 0.7}},
	"pachyrhinosaurus": {"name": "Pachyrhinosaure", "diet": "herb", "habitat": "land", "biome": "neige", "strength": 3, "cost": 300,
		"attraction": 18, "space": 16, "speed": 0.55, "plan": "quad", "length": 6.0, "color": Color("8d6e63"), "color2": Color("eeeeee"),
		"features": ["frill", "nose_boss"], "sound": "BRRROOO !"},
	"parasaurolophus": {"name": "Parasaurolophus", "diet": "herb", "habitat": "land", "biome": "marais", "strength": 1, "cost": 250,
		"attraction": 15, "space": 14, "speed": 0.7, "plan": "biped", "length": 9.5, "color": Color("4db6ac"), "color2": Color("e64a19"),
		"features": ["crest_tube"], "sound": "TOUUUT !",
		"shape": {"leg": 0.6, "neck": 0.25, "head": Vector3(0.42, 0.2, 0.22), "arm": 0.28, "tilt": 8.0}},
	"pachycephalosaurus": {"name": "Pachycéphalosaure", "diet": "herb", "habitat": "land", "biome": "prairie", "strength": 2, "cost": 200,
		"attraction": 14, "space": 10, "speed": 0.8, "plan": "biped", "length": 4.5, "color": Color("c08552"), "color2": Color("6d4c41"),
		"features": ["dome"], "sound": "BONK !",
		"shape": {"leg": 0.5, "neck": 0.12, "head": Vector3(0.32, 0.26, 0.26), "tilt": 5.0}},
	"gallimimus": {"name": "Gallimimus", "diet": "herb", "habitat": "land", "biome": "desert", "strength": 1, "cost": 150,
		"attraction": 12, "space": 10, "speed": 1.3, "plan": "biped", "length": 6.0, "color": Color("d7ccc8"), "color2": Color("8d6e63"),
		"features": ["feathers"], "sound": "PIOU PIOU !",
		"shape": {"leg": 0.75, "body": Vector3(0.6, 0.4, 0.35), "neck": 0.45, "head": Vector3(0.24, 0.14, 0.14), "tail": 0.9, "arm": 0.25}},
	"diplodocus": {"name": "Diplodocus", "diet": "herb", "habitat": "land", "biome": "prairie", "strength": 3, "cost": 500,
		"attraction": 28, "space": 70, "speed": 0.4, "plan": "sauropod", "length": 26.0, "color": Color("5c8fd6"), "color2": Color("3f6fb0"),
		"sound": "HOOOOMMM !", "shape": {"neck_len": 1.1, "neck_angle": 40.0, "tail": 1.5}},
	"brachiosaurus": {"name": "Brachiosaure", "diet": "herb", "habitat": "land", "biome": "jungle", "strength": 4, "cost": 700,
		"attraction": 32, "space": 70, "speed": 0.35, "plan": "sauropod", "length": 22.0, "color": Color("7d8a5c"), "color2": Color("5b6640"),
		"sound": "HOOOOMMM !", "shape": {"leg": 0.5, "leg_front": 0.75, "neck_len": 1.25, "neck_angle": 14.0, "tail": 0.9}},
	"velociraptor": {"name": "Vélociraptor", "diet": "carn", "habitat": "land", "biome": "jungle", "strength": 3, "cost": 400,
		"attraction": 22, "space": 10, "speed": 1.5, "plan": "biped", "length": 3.5, "color": Color("a1887f"), "color2": Color("4e342e"),
		"features": ["stripes", "feathers"], "sound": "KRIIII !",
		"shape": {"leg": 0.45, "body": Vector3(0.6, 0.35, 0.3), "head": Vector3(0.42, 0.2, 0.22), "neck": 0.15, "tail": 1.0, "arm": 0.3}},
	"dilophosaurus": {"name": "Dilophosaure", "diet": "carn", "habitat": "land", "biome": "jungle", "strength": 2, "cost": 350,
		"attraction": 20, "space": 12, "speed": 0.9, "plan": "biped", "length": 6.0, "color": Color("7cb342"), "color2": Color("ffca28"),
		"features": ["double_crest", "frill"], "sound": "KHHHH !",
		"shape": {"leg": 0.5, "body": Vector3(0.7, 0.42, 0.38), "head": Vector3(0.42, 0.24, 0.26), "neck": 0.2}},
	"carnotaurus": {"name": "Carnotaure", "diet": "carn", "habitat": "land", "biome": "desert", "strength": 4, "cost": 600,
		"attraction": 26, "space": 24, "speed": 1.0, "plan": "biped", "length": 8.0, "color": Color("b71c1c"), "color2": Color("3e2723"),
		"features": ["horns"], "sound": "GRAAAH !", "shape": {"head": Vector3(0.42, 0.32, 0.36), "arm": 0.12}},
	"spinosaurus": {"name": "Spinosaure", "diet": "carn", "habitat": "land", "biome": "marais", "strength": 5, "cost": 900,
		"attraction": 36, "space": 45, "speed": 0.8, "plan": "biped", "length": 15.0, "color": Color("607d8b"), "color2": Color("d84315"),
		"features": ["sail"], "sound": "ROOOAAR !", "shape": {"head": Vector3(0.75, 0.22, 0.26), "body": Vector3(0.95, 0.5, 0.48), "arm": 0.3}},
	"trex": {"name": "T-Rex", "diet": "carn", "habitat": "land", "biome": "prairie", "strength": 5, "cost": 1000,
		"attraction": 40, "space": 45, "speed": 0.9, "plan": "biped", "length": 12.0, "color": Color("c0504d"), "color2": Color("7b2b2a"),
		"sound": "ROAAAR !", "shape": {"head": Vector3(0.6, 0.36, 0.44)}},
	"yutyrannus": {"name": "Yutyrannus", "diet": "carn", "habitat": "land", "biome": "neige", "strength": 4, "cost": 650,
		"attraction": 26, "space": 24, "speed": 0.9, "plan": "biped", "length": 9.0, "color": Color("b0bec5"), "color2": Color("fafafa"),
		"features": ["feathers"], "sound": "GRAOOO !"},

	"pteranodon": {"name": "Ptéranodon", "diet": "fish", "habitat": "air", "strength": 1, "cost": 400, "attraction": 18,
		"speed": 1.4, "plan": "flyer", "length": 6.0, "color": Color("8d6e63"), "color2": Color("ff7043"),
		"features": ["crest"], "sound": "KRAAA !"},
	"quetzalcoatlus": {"name": "Quetzalcoatlus", "diet": "fish", "habitat": "air", "strength": 2, "cost": 700, "attraction": 25,
		"speed": 1.1, "plan": "flyer", "length": 10.0, "color": Color("eceff1"), "color2": Color("e53935"),
		"features": ["crest"], "sound": "KRAAAA !"},
	"dimorphodon": {"name": "Dimorphodon", "diet": "fish", "habitat": "air", "strength": 1, "cost": 250, "attraction": 12,
		"speed": 1.8, "plan": "flyer", "length": 2.2, "color": Color("263238"), "color2": Color("fdd835"),
		"sound": "KIII !", "shape": {"beak": 0.2}},
	"tapejara": {"name": "Tapejara", "diet": "fish", "habitat": "air", "strength": 1, "cost": 350, "attraction": 15,
		"speed": 1.4, "plan": "flyer", "length": 3.5, "color": Color("6d4c41"), "color2": Color("e91e63"),
		"features": ["sail_crest"], "sound": "KRIII !"},

	"mosasaurus": {"name": "Mosasaure", "diet": "fish", "habitat": "sea", "strength": 5, "cost": 2500, "attraction": 60,
		"speed": 1.2, "plan": "mosasaur", "length": 17.0, "color": Color("455a64"), "color2": Color("cfd8dc"), "sound": "SPLAAASH !"},
	"plesiosaurus": {"name": "Plésiosaure", "diet": "fish", "habitat": "sea", "strength": 3, "cost": 1200, "attraction": 35,
		"speed": 0.9, "plan": "plesio", "length": 8.0, "color": Color("26a69a"), "color2": Color("b2dfdb"), "sound": "BLOUP !"},
}

const CATEGORIES := [
	{"name": "Chemins", "tools": ["path", "road"]},
	{"name": "Terrain", "tools": ["biome:prairie", "biome:jungle", "biome:desert", "biome:marais", "biome:neige", "mountain"]},
	{"name": "Barrières", "tools": ["fence_bamboo", "fence_wood", "fence_stone", "fence_glass", "fence_concrete", "fence_electric", "gate_wood"]},
	{"name": "Herbivores", "tools": ["dino:gallimimus", "dino:pachycephalosaurus", "dino:parasaurolophus", "dino:triceratops",
		"dino:pachyrhinosaurus", "dino:stegosaurus", "dino:ankylosaurus", "dino:diplodocus", "dino:brachiosaurus"]},
	{"name": "Carnivores", "tools": ["dino:dilophosaurus", "dino:velociraptor", "dino:carnotaurus", "dino:yutyrannus",
		"dino:spinosaurus", "dino:trex"]},
	{"name": "Volants", "tools": ["aviary", "dino:dimorphodon", "dino:tapejara", "dino:pteranodon", "dino:quetzalcoatlus"]},
	{"name": "Marins", "tools": ["lagoon", "dino:plesiosaurus", "dino:mosasaurus"]},
	{"name": "Nourriture", "tools": ["feeder_plants", "feeder_meat"]},
	{"name": "Transports", "tools": ["drive:walk", "gyro_station", "jeep_garage", "heliport", "drive:gyro", "drive:jeep", "drive:heli"]},
	{"name": "Boutiques", "tools": ["icecream", "burger", "souvenir"]},
	{"name": "Décor", "tools": ["tree", "pine", "palm", "fern", "bush", "cactus", "rock", "volcano"]},
	{"name": "Outils", "tools": ["bulldozer", "dart"]},
]

const SPECIAL_TOOLS := {
	"bulldozer": {"name": "Bulldozer", "cost": 0, "color": Color("f9a825"),
		"info": "Détruit ce qui est sous la souris (ou vend un dinosaure). Rembourse la moitié du prix. Clic droit marche aussi."},
	"dart": {"name": "Fléchette", "cost": 50, "color": Color("ab47bc"),
		"info": "Endort un dinosaure échappé et le ramène dans son enclos."},
	"drive:walk": {"name": "Se promener", "cost": 0, "color": Color("c8b070"),
		"info": "Clique sur le terrain pour te promener dans le parc avec le gardien. Flèches ou ZQSD pour marcher."},
	"drive:gyro": {"name": "Piloter gyrosphère", "cost": 0, "color": Color("4fc3f7"),
		"info": "Clique sur le terrain pour monter dans une gyrosphère. Elle passe à travers les barrières !"},
	"drive:jeep": {"name": "Conduire jeep", "cost": 0, "color": Color("6d8f3a"),
		"info": "Clique sur le terrain pour monter dans une jeep."},
	"drive:heli": {"name": "Piloter hélicoptère", "cost": 0, "color": Color("e53935"),
		"info": "Clique sur un héliport pour décoller. Espace pour monter, Maj pour descendre."},
}


static func size_of(item: Dictionary) -> Vector2i:
	return item.get("size", Vector2i.ONE)


static func tool_info(id: String) -> Dictionary:
	if id.begins_with("biome:"):
		var biome: Dictionary = BIOMES[id.substr(6)]
		return {"name": biome.name, "cost": BIOME_COST, "color": biome.color,
			"info": "Peins le sol en %s. Chaque dinosaure a son biome préféré." % biome.name}
	if id.begins_with("dino:"):
		var dino: Dictionary = DINOS[id.substr(5)]
		return {"name": dino.name, "cost": dino.cost, "color": dino.color, "info": describe_dino(dino)}
	if SPECIAL_TOOLS.has(id):
		return SPECIAL_TOOLS[id]
	var item: Dictionary = ITEMS[id]
	var info: String = item.get("info", "")
	if item.kind == "fence" and item.style == "gate":
		info = "Un portail dans la barrière : toi tu passes, les dinosaures non (force %d)." % item.strength
	elif item.kind == "fence":
		info = "Barrière de force %d. Un dinosaure plus fort la casse." % item.strength
	elif item.kind == "shop":
		info = "Les visiteurs qui passent devant achètent (%d pièces)." % item.price
	elif item.kind == "decor" and info == "":
		info = "Pour décorer le parc. Rapporte un peu d'attractivité au bord d'un chemin."
	return {"name": item.name, "cost": item.cost, "color": item.color, "info": info}


static func describe_dino(dino: Dictionary) -> String:
	match dino.habitat:
		"air":
			return "Dinosaure volant : à mettre dans une volière. Mange du poisson (automatique)."
		"sea":
			return "Reptile marin : à mettre dans un lagon. Mange du poisson (automatique)."
	var diet := "Carnivore (mangeoire à viande)" if dino.diet == "carn" else "Herbivore (mangeoire à plantes)"
	return "%s. Aime : %s. Il faut une barrière %s ou plus solide. Place pour %d cases." % [
		diet, BIOMES[dino.biome].name, fence_for_strength(dino.strength), dino.space]


static func fence_for_strength(strength: int) -> String:
	var best_name := ""
	var best_strength := 99
	for id in ITEMS:
		var item: Dictionary = ITEMS[id]
		if item.kind == "fence" and item.strength >= strength and item.strength < best_strength:
			best_name = item.name
			best_strength = item.strength
	return best_name

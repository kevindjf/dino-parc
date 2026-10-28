extends RefCounted

# What the people of the village ask for, once they have given their first present: three
# quests each, harder and harder, in the order of House.RESIDENTS. Talking to them gives the
# reward when the quest is done, then tells the next one. The "Quêtes" tab of the Carnet lists them.
#
#   ask: what they say, need: what has to be done, reward: what they give ("coins" are pièces),
#   thanks: what they say when it is done.
# need, one of:
#   {"bring": {item: count}}  things given to them (taken from the bag)
#   {"show": species}         that species shown to the visitors in the park
#   {"shown": count}          that many species shown to the visitors
#   {"dex": count}            that many species in the Dinodex
#   {"far": level}            a zone of the Wild Lands that far visited (1 to 3 stars)
#   {"zones": count}          that many zones of the Wild Lands visited
#   {"fires": count}          that many campfires lit in the Wild Lands
#   {"hatch": count}          that many babies born in the laboratory
#   {"stars": count}          the stars of the park
#   {"hearts": 5}             a dinosaur of the park with that many hearts
#   {"ride": "any" or "carn"} ridden a dinosaur (a carnivore for "carn")

const QUESTS := [
	[  # Mamie Rose
		{"ask": "Ramène-moi 20 baies pour mes confitures !", "need": {"bring": {"berries": 20}},
			"reward": {"coins": 100, "pie": 2}, "thanks": "Merci ! Tiens, deux tartes toutes chaudes."},
		{"ask": "J'aimerais tant voir un Parasaurolophus dans ton parc…", "need": {"show": "parasaurolophus"},
			"reward": {"coins": 300}, "thanks": "Quel joli chant il a ! Merci mon petit."},
		{"ask": "Fais-moi 5 tartes aux baies au feu de camp, pour la fête du village !", "need": {"bring": {"pie": 5}},
			"reward": {"capsule_gold": 1, "coins": 200}, "thanks": "La fête sera magnifique ! Voici ma capsule en or."},
	],
	[  # Marcel le boucher
		{"ask": "Grille-moi 5 viandes au feu de camp, je veux goûter !", "need": {"bring": {"meat_cooked": 5}},
			"reward": {"coins": 150, "meat": 10}, "thanks": "Délicieux ! Prends 10 viandes pour tes carnivores."},
		{"ask": "Montre-moi un Carnotaure dans ton parc. Avec ses cornes, il me fait rire !", "need": {"show": "carnotaurus"},
			"reward": {"coins": 400}, "thanks": "Ha ha, quelles cornes ! Bravo !"},
		{"ask": "Le plus grand de tous : je veux voir un T-Rex dans ton parc !", "need": {"show": "trex"},
			"reward": {"coins": 1000, "capsule_gold": 2}, "thanks": "LE ROI DES DINOS ! Tu es incroyable !"},
	],
	[  # Léa l'exploratrice
		{"ask": "Explore une zone des Terres sauvages à 2 étoiles !", "need": {"far": 2},
			"reward": {"coins": 200, "arrow": 20}, "thanks": "Bravo, aventurier ! Voici des flèches."},
		{"ask": "Remplis ton Dinodex : 12 espèces différentes !", "need": {"dex": 12},
			"reward": {"coins": 300, "syringe": 10}, "thanks": "Quelle collection ! Ces seringues t'aideront pour les géants."},
		{"ask": "Allume 5 feux de camp dans les Terres sauvages.", "need": {"fires": 5},
			"reward": {"coins": 1000}, "thanks": "Tu connais le monde mieux que moi !"},
	],
	[  # Papi Jules
		{"ask": "Apporte-moi 3 fossiles, comme dans ma jeunesse !", "need": {"bring": {"fossil": 3}},
			"reward": {"coins": 200}, "thanks": "Ah, ça me rappelle des souvenirs…"},
		{"ask": "Fais naître un bébé dino au laboratoire. Je veux le voir !", "need": {"hatch": 1},
			"reward": {"coins": 300, "amber": 2}, "thanks": "Un bébé ! Tiens, de l'ambre pour le suivant."},
		{"ask": "Je rêve d'un parc à 4 étoiles avant d'être trop vieux…", "need": {"stars": 4},
			"reward": {"coins": 1500}, "thanks": "Mon rêve est réalisé. Merci !"},
	],
	[  # Zoé la mineuse
		{"ask": "Ramène-moi 10 fers de la mine.", "need": {"bring": {"iron": 10}},
			"reward": {"coins": 150, "crystal": 2}, "thanks": "Du beau fer ! Voici du cristal."},
		{"ask": "Il me faut 5 pépites d'or, du fond de la mine.", "need": {"bring": {"gold": 5}},
			"reward": {"coins": 500}, "thanks": "De l'or ! Tu es un vrai mineur !"},
		{"ask": "Le grand défi : 10 cristaux et 3 ambres !", "need": {"bring": {"crystal": 10, "amber": 3}},
			"reward": {"coins": 800, "capsule_gold": 3}, "thanks": "Incroyable ! Trois capsules en or pour toi."},
	],
	[  # Docteur Paul
		{"ask": "Rends un dino de ton parc très heureux : 5 cœurs d'amitié !", "need": {"hearts": 5},
			"reward": {"coins": 200}, "thanks": "Un dino heureux, c'est un dino en bonne santé !"},
		{"ask": "Monte sur le dos d'un dino avec une selle.", "need": {"ride": "any"},
			"reward": {"coins": 300, "saddle": 1}, "thanks": "Bravo, cavalier ! Voici une autre selle."},
		{"ask": "Le plus courageux : monte sur un carnivore !", "need": {"ride": "carn"},
			"reward": {"coins": 800}, "thanks": "Quel courage ! Même moi, je n'ose pas."},
	],
	[  # Nina la fermière
		{"ask": "Il me faut 30 bois pour ma nouvelle grange.", "need": {"bring": {"wood": 30}},
			"reward": {"coins": 150, "bush": 3}, "thanks": "Merci ! Plante ces buissons chez toi."},
		{"ask": "Montre 5 espèces de dinos aux visiteurs de ton parc.", "need": {"shown": 5},
			"reward": {"coins": 400}, "thanks": "Les visiteurs doivent adorer !"},
		{"ask": "Et maintenant, 10 espèces montrées aux visiteurs !", "need": {"shown": 10},
			"reward": {"coins": 1200}, "thanks": "Ton parc est le plus beau du monde !"},
	],
	[  # Tom le pilote
		{"ask": "Ramène-moi 10 cuivres pour réparer mon avion.", "need": {"bring": {"copper": 10}},
			"reward": {"coins": 200}, "thanks": "Mon avion va peut-être voler !"},
		{"ask": "Visite 15 zones des Terres sauvages.", "need": {"zones": 15},
			"reward": {"coins": 500}, "thanks": "Raconte-moi tout ce que tu as vu !"},
		{"ask": "Le tour du monde : visite 30 zones des Terres sauvages !", "need": {"zones": 30},
			"reward": {"coins": 2000}, "thanks": "Le tour du monde ! Tu es le plus grand explorateur !"},
	],
]


static func current(resident: int, step: int) -> Dictionary:
	var list: Array = QUESTS[resident % QUESTS.size()]
	return list[step] if step < list.size() else {}

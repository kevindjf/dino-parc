extends RefCounted

# The levels of the adventure: each level is a list of goals, done in any order. When they are
# all done, the player goes up one level and gets a present. The note at the top left shows the
# level and the next goal; touching it opens the "Carnet" with the whole list.
# A goal id is checked by main.gd, _goal_done(); a goal done stays done.
#
#   title: the name of the level, goals: [id, text], reward: {"coins": n, item id: count}

const LEVELS := [
	{"title": "Premiers pas", "reward": {"coins": 50, "capsule_copper": 2}, "goals": [
		["wood", "Frappe un arbre pour récolter 5 bois (bouton Action)"],
		["axe", "Ouvre ton Sac et fabrique une hache"],
		["berries", "Cueille des baies sur un buisson"],
		["tame", "Lance 3 baies à un dino herbivore sauvage : il devient ton ami ! (suis la flèche jaune)"],
	]},
	{"title": "Un enclos pour ton dino", "reward": {"coins": 100, "icecream": 1}, "goals": [
		["pickaxe", "Fabrique une pioche"],
		["stone", "Casse un rocher avec la pioche pour avoir de la pierre"],
		["pen", "Fabrique des barrières et ferme un enclos (bouton Construire, outil Enclos)"],
		["adopt", "Ouvre « Mes dinos », touche « Relâcher » et pose ton dino dans l'enclos"],
		["feeder", "Pose une mangeoire à plantes dans l'enclos"],
	]},
	{"title": "Les premiers visiteurs", "reward": {"coins": 200, "bench": 2, "flowers": 5}, "goals": [
		["path", "Trace un chemin depuis l'entrée jusqu'à la barrière de ton enclos"],
		["food_shop", "Pose ton stand de glaces au bord du chemin (Sac, onglet Parc)"],
		["decor3", "Décore le long du chemin : 3 fleurs, bancs ou poubelles"],
		["visitors10", "Accueille 10 visiteurs"],
		["doudou", "Un petit visiteur a perdu son doudou : retrouve-le (suis la flèche jaune)"],
	]},
	{"title": "Chasseur de dinos", "reward": {"coins": 300, "saddle": 1}, "goals": [
		["cage", "Fabrique un lance-pierre et une cage. Fatigue un petit dino, puis mets-le en cage"],
		["release", "Relâche le dino attrapé dans un enclos"],
		["dex3", "Attrape 3 espèces différentes (bouton Dinodex)"],
		["campfire", "Sors du parc par un sentier et allume un feu de camp dans les Terres sauvages"],
	]},
	{"title": "Ami des dinos", "reward": {"coins": 400, "pickaxe_iron": 1}, "goals": [
		["brush", "Fabrique une brosse et brosse un dino de ton parc"],
		["friend", "Gagne 3 cœurs d'amitié d'un gros dino de ton parc (brosse-le, nourris-le)"],
		["ride", "Fabrique une selle, prends-la en main et appuie sur Action devant lui : tu montes !"],
		["happy", "Rends un dino heureux : le bon sol (Sac, onglet Parc), de la place et à manger"],
	]},
	{"title": "Le mineur", "reward": {"coins": 500, "capsule_gold": 1}, "goals": [
		["mine", "Trouve une grotte dans les montagnes et descends dans la mine"],
		["ore", "Creuse les murs de la mine pour trouver du fer et du cuivre"],
		["electric", "Fabrique une barrière électrique : la seule qui retient un T-Rex !"],
		["quest1", "Aide un habitant du village : finis une quête (bouton Carnet)"],
	]},
	{"title": "Un parc étoilé", "reward": {"coins": 800, "fountain": 1}, "goals": [
		["stars2", "Fais monter ton parc à 2 étoiles"],
		["rating30", "Atteins une note de parc de 30 / 100 (bouton Carnet, onglet Parc)"],
		["dex5", "Attrape 5 espèces différentes"],
		["souvenir", "Ouvre une boutique souvenirs au bord d'un chemin"],
		["staff", "Embauche un employé : pose la cabane du soigneur, l'atelier de l'ouvrier ou le poste du garde"],
		["vip", "Reçois le journaliste du Dino Journal et lis son article sur ton parc"],
	]},
	{"title": "Grand explorateur", "reward": {"coins": 1000, "statue": 1}, "goals": [
		["dex10", "Attrape 10 espèces différentes"],
		["far", "Explore une zone à 3 étoiles, tout au bord du monde"],
		["sea", "Va jusqu'à la mer, tout à l'est du monde"],
		["lab", "Construis un laboratoire et fais naître un bébé dino"],
		["baby_park", "Mets 2 dinos de la même espèce, heureux, dans un grand enclos : un bébé va naître !"],
	]},
	{"title": "Le parc de rêve", "reward": {"coins": 1500, "capsule_gold": 2}, "goals": [
		["stars3", "Fais monter ton parc à 3 étoiles"],
		["rating50", "Atteins une note de parc de 50 / 100"],
		["ride_attraction", "Ouvre une attraction : gyrosphères, jeeps ou héliport"],
		["dex15", "Attrape 15 espèces différentes"],
		["quest5", "Finis 5 quêtes du village"],
	]},
	{"title": "Le parc légendaire", "reward": {"coins": 2000, "volcano": 1}, "goals": [
		["stars4", "Fais monter ton parc à 4 étoiles"],
		["rating70", "Atteins une note de parc de 70 / 100"],
		["dex25", "Attrape 25 espèces différentes"],
		["fires5", "Allume 5 feux de camp dans les Terres sauvages"],
	]},
	{"title": "Légende des dinos", "reward": {"coins": 5000}, "goals": [
		["stars5", "Fais de ton parc un parc 5 étoiles !"],
		["rating90", "Atteins une note de parc de 90 / 100"],
		["quest24", "Finis toutes les quêtes du village"],
		["dexall", "Attrape les 44 espèces du Dinodex !"],
	]},
]

# The goals of the first versions, in their order: a saved game with goal_index n had the first
# n of them done.
const OLD_GOALS := ["wood", "axe", "pickaxe", "stone", "berries", "pen", "feeder", "path", "tame", "adopt", "cage",
	"release", "brush", "friend", "ride", "mine", "ore", "electric", "dex5", "dex10", "stars2", "lab", "far", "stars3",
	"dex15", "stars5"]


static func count() -> int:
	return LEVELS.size()


# The present of a level, told in words: "100 pièces, Stand de glaces".
static func describe_reward(reward: Dictionary, name_of: Callable) -> String:
	var parts := PackedStringArray()
	for id in reward:
		if id == "coins":
			parts.append("%d pièces" % reward.coins)
		else:
			parts.append("%s%s" % [name_of.call(id), " ×%d" % reward[id] if reward[id] > 1 else ""])
	return ", ".join(parts)

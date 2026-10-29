extends RefCounted

# What's new in the game, written for children: short sentences, one picture each.
# The first entry is the current version of the game. Before publishing a new version,
# add an entry on top with the next number: the title screen shows it once on every device,
# and the "Nouveautés" button shows them all again.
# Pictures: any id of items.gd ("wood", "pickaxe_iron", ...) or "dino:<species>".

const ENTRIES := [
	{
		"version": 9,
		"title": "Il se passe des choses dans ton parc !",
		"items": [
			["dino:triceratops", "Deux dinos de la même espèce, heureux dans un grand enclos, peuvent avoir un bébé !"],
			["souvenir", "Le journaliste du Dino Journal visite ton parc. Il lui donne des étoiles dans son article !"],
			["berries", "Un petit visiteur a perdu son doudou : suis la flèche jaune pour le retrouver."],
			["capsule_gold", "À 100, 250, 500 visiteurs… c'est la fête, avec un feu d'artifice !"],
		],
	},
	{
		"version": 8,
		"title": "Un vrai parc, et des niveaux !",
		"items": [
			["capsule_gold", "Le jeu a maintenant 11 niveaux. Chacun a sa liste d'objectifs, et un cadeau quand tout est fait !"],
			["pie", "Touche la petite feuille en haut à gauche, ou le bouton Carnet : ta liste, tes quêtes et la note de ton parc."],
			["berries", "Une flèche jaune te montre où aller : un arbre, un buisson, un dino à apprivoiser, une grotte…"],
			["icecream", "Ouvre des stands de glaces, de burgers et de souvenirs : les visiteurs achètent !"],
			["gyro_station", "Gyrosphères, jeeps et héliport arrivent dans l'aventure."],
			["fountain", "Décore ton parc : fleurs, bancs, poubelles, lampadaires, statue et fontaine."],
			["ground_neige", "Change le sol de tes enclos avec des graines ou des sacs de sable, de boue ou de neige."],
			["dino:triceratops", "Les visiteurs parlent ! Ils te disent ce qu'ils aiment et ce qui manque."],
			["bench", "Ton parc a une note sur 100. Plus elle est haute, plus tu gagnes d'étoiles."],
			["keeper_hut", "Embauche un soigneur, un ouvrier et un garde : ils t'aident à t'occuper du parc."],
		],
	},
	{
		"version": 7,
		"title": "Des barrières plus solides !",
		"items": [
			["fence_stone", "Une barrière assez forte pour ton dino tient toujours, même pendant l'orage !"],
			["dino:trex", "Une barrière trop faible tient 3 coups : quand tu vois « BOUM ! », mets vite une barrière plus forte."],
		],
	},
	{
		"version": 6,
		"title": "Les Terres sauvages, la mer et le laboratoire !",
		"items": [
			["heli", "Ton parc est au milieu d'un monde immense ! Sors par les sentiers tout autour du parc."],
			["campfire", "Allume les feux de camp : repose-toi, fais griller ta viande, et reviens-y avec la Carte."],
			["dino:argentinosaurus", "23 nouveaux dinos : 44 espèces à attraper ! Les plus gros vivent loin du parc."],
			["sniper", "Nouvelles armes : la lance, la sarbacane, le filet et le fusil à lunette qui tire de très loin."],
			["saddle", "La selle, c'est plus simple : à 3 cœurs, selle en main, Action, et tu montes !"],
			["egg", "Construis un laboratoire : avec des fossiles et de l'ambre, fais naître des bébés dinos !"],
			["boat", "Tout à l'est, la mer ! Barque, voilier, hors-bord et sous-marin pour l'explorer."],
			["fish", "Pêche des poissons pour apprivoiser les dinos volants et les reptiles marins."],
			["submarine", "En sous-marin, cherche les épaves englouties : elles cachent des trésors !"],
			["capsule_gold", "Ton parc gagne des étoiles : chacune ouvre de nouvelles choses à la boutique."],
			["pie", "Les habitants du village te demandent de l'aide : regarde le bouton Quêtes."],
			["bolas", "Attention aux orages : tes dinos ont peur et poussent les barrières ! La nuit, tout devient bleu."],
			["wood", "Ton sac est rangé en onglets : outils, chasse, nourriture, construction…"],
			["dino:triceratops", "Les habitants et les meubles sont redessinés, et les dinos ne traversent plus les arbres."],
		],
	},
	{
		"version": 5,
		"title": "Les maisons et la viande !",
		"items": [
			["dino:triceratops", "Ton personnage devient un explorateur, avec son chapeau ! Les filles ont une queue de cheval."],
			["wood", "Tout le monde a changé de look : maisons en rondins et en chaume, arbres, puits, boutiques…"],
			["dino:velociraptor", "Les habitants du village sont des dinosaures habillés ! Va leur dire bonjour."],
			["dino:triceratops", "Entre dans les maisons du village : marche vers la porte, et tu es dedans !"],
			["capsule_copper", "Chaque habitant te fait un cadeau à ta première visite. Va tous les voir !"],
			["meat", "La boutique vend de la viande pour les carnivores."],
			["dino:velociraptor", "Lance 5 viandes à un carnivore sauvage : il devient ton ami et te suit !"],
			["feeder_meat", "Achète une mangeoire à viande pour les carnivores de ton parc."],
			["pickaxe", "Plus besoin du bouton pour les portes et les échelles des mines : il suffit d'avancer."],
			["car", "En vélo, en moto, en voiture ou en hélico, ton personnage se tourne dans le sens où il roule !"],
			["dino:trex", "Tous les dinosaures sont redessinés à la main ! Tu les vois de face quand ils viennent vers toi."],
			["bush", "Les arbres sont plus grands, la forêt plus touffue, et l'herbe plus douce."],
			["meat", "La boutique du village est toute neuve, avec son marchand derrière le comptoir."],
			["wood", "Nouveaux boutons en bois et fenêtres en parchemin. Tu vois mieux le jeu !"],
			["dino:brachiosaurus", "Le jeu retient ton zoom : règle-le avec les boutons − et + en haut à droite."],
		],
	},
	{
		"version": 4,
		"title": "Le village, la boutique et les véhicules !",
		"items": [
			["dino:triceratops", "Sors du parc par le portail, à gauche : la route mène au village !"],
			["capsule_gold", "À la boutique, tes pièces achètent des capsules, des flèches, une selle, de l'or…"],
			["boots_fast", "Achète des bottes : tu marches plus vite. Les bottes de course, encore plus vite !"],
			["bike", "Achète un vélo, une moto ou une voiture. Prends-le en main et appuie sur Action pour monter !"],
			["heli", "L'hélicoptère vole au-dessus de tout ! Appuie sur Action pour atterrir."],
			["wood", "Tu as trop de bois ou de pierres ? Vends-les au marchand !"],
			["fossil", "Les fossiles valent cher : 30 pièces chacun."],
			["capsule_iron", "Quatre maisons abandonnées cachent un coffre au trésor. Trouve-les toutes !"],
		],
	},
	{
		"version": 3,
		"title": "Construis avec ton doigt !",
		"items": [
			["hammer", "Touche le bouton orange « Construire » : tu poses tout avec ton doigt."],
			["fence_wood", "Dessine tes barrières et tes chemins au doigt. Vert : ça marche. Rouge : pas possible."],
			["gate_wood", "« Enclos » : tire d'un coin à l'autre, et tout l'enclos se construit, avec son portail !"],
			["bush", "La gomme déterre les buissons à baies. Replante-les près de chez toi !"],
			["feeder_plants", "Les grands bâtiments ont un chantier : tape dessus pour aider à construire."],
			["dino:triceratops", "En Bac à sable aussi : les boutons Enclos, Gomme et Annuler !"],
		],
	},
	{
		"version": 2,
		"title": "Le combat et les capsules !",
		"items": [
			["slingshot", "Fabrique un lance-pierre ou un arc et vise les dinos sauvages de loin."],
			["arrow", "Chaque tir fatigue le dino. Quand il est épuisé, il s'endort. Personne n'est blessé !"],
			["capsule_copper", "Lance une capsule sur un dino épuisé pour l'attraper. Il va dans ton sac !"],
			["capsule_gold", "Pastille verte : ça va marcher. Rouge : il va s'échapper ! Pour le T-Rex, il faut une capsule en or."],
			["bolas", "Les bolas bloquent un dino qui fonce sur toi. Attention à tes cœurs !"],
			["berries", "Lance 3 baies à un herbivore : il devient ton ami et saute dans « Mes dinos » !"],
			["dino:diplodocus", "« Mes dinos » garde tous tes dinos. Touche « Relâcher » pour en poser un dans un enclos."],
			["dino:velociraptor", "Touche un dino avec ton doigt pour le viser et tirer dessus !"],
		],
	},
	{
		"version": 1,
		"title": "Les mondes !",
		"items": [
			["dino:trex", "Tu peux créer plusieurs mondes, comme dans Minecraft. Donne un nom à chacun !"],
			["dino:triceratops", "Choisis ton mode : Aventure pour explorer, ou Bac à sable pour construire ton parc."],
			["pickaxe_iron", "Va dans les mines des montagnes et creuse pour trouver du fer, de l'or et des cristaux."],
			["saddle", "Fais-toi un ami dino, mets-lui une selle et monte sur son dos !"],
			["dino:pteranodon", "Le jeu se met à jour tout seul quand il y a des nouveautés."],
		],
	},
]
const SEEN_FILE := "user://news.json"


static func version() -> int:
	return ENTRIES[0].version


# The entries not seen yet on this device, the newest first.
static func unseen() -> Array:
	var seen := 0
	var data = JSON.parse_string(FileAccess.get_file_as_string(SEEN_FILE)) if FileAccess.file_exists(SEEN_FILE) else null
	if data is Dictionary:
		seen = int(data.get("seen", 0))
	return ENTRIES.filter(func(entry: Dictionary) -> bool: return entry.version > seen)


static func mark_seen() -> void:
	var file := FileAccess.open(SEEN_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"seen": version()}))

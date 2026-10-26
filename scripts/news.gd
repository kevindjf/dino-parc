extends RefCounted

# What's new in the game, written for children: short sentences, one picture each.
# The first entry is the current version of the game. Before publishing a new version,
# add an entry on top with the next number: the title screen shows it once on every device,
# and the "Nouveautés" button shows them all again.
# Pictures: any id of items.gd ("wood", "pickaxe_iron", ...) or "dino:<species>".

const ENTRIES := [
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

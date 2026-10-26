extends RefCounted

# The player's worlds, like in Minecraft: each one has a name, a mode (adventure or sandbox),
# its own settings and its own save. A world lives in its own folder:
#   user://worlds/<id>/world.json      name, mode, settings, dates
#   user://worlds/<id>/save.json       the park itself (see save_game.gd), and save.bak.json

const ROOT := "user://worlds"
const MODES := {"adventure": "Aventure", "creative": "Bac à sable"}
# Options chosen when a world is created. Each line is shown on the creation screen for the
# modes it lists, saved with the world, and read in the game with park.setting("key").
# Types: "bool" (a yes/no switch) or "choice" (with "options": [[value, label], ...]).
# Example:
#   {"key": "wild_attack", "label": "Dinos sauvages agressifs", "type": "bool",
#    "default": true, "modes": ["adventure", "creative"]},
const SETTINGS := []


static func folder(id: String) -> String:
	return "%s/%s" % [ROOT, id]


# All worlds, the last played first.
static func list() -> Array:
	var worlds := []
	var dir := DirAccess.open(ROOT)
	if dir == null:
		return worlds
	for id in dir.get_directories():
		var info := load_info(id)
		if not info.is_empty():
			worlds.append(info)
	worlds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.last_played > b.last_played)
	return worlds


static func load_info(id: String) -> Dictionary:
	var file := FileAccess.open(folder(id) + "/world.json", FileAccess.READ)
	if file == null:
		return {}
	var info = JSON.parse_string(file.get_as_text())
	if not info is Dictionary or not MODES.has(info.get("mode", "")):
		return {}
	info.id = id
	info.name = str(info.get("name", "Monde"))
	info.last_played = float(info.get("last_played", 0))
	# Settings added after the world was made take their default value.
	var settings: Dictionary = defaults(info.mode)
	settings.merge(info.get("settings", {}), true)
	info.settings = settings
	return info


static func create(world_name: String, mode: String, settings: Dictionary) -> Dictionary:
	var id := "%d_%04d" % [int(Time.get_unix_time_from_system()), randi() % 10000]
	DirAccess.make_dir_recursive_absolute(folder(id))
	var now := Time.get_unix_time_from_system()
	var info := {"id": id, "name": world_name, "mode": mode, "settings": settings, "created": now, "last_played": now}
	save_info(info)
	return info


static func save_info(info: Dictionary) -> void:
	var file := FileAccess.open(folder(info.id) + "/world.json", FileAccess.WRITE)
	if file == null:
		return
	var data := info.duplicate()
	data.erase("id")
	file.store_string(JSON.stringify(data))


static func touch(info: Dictionary) -> void:
	info.last_played = Time.get_unix_time_from_system()
	save_info(info)


static func delete(id: String) -> void:
	var path := folder(id)
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(path)


static func defaults(mode: String) -> Dictionary:
	var settings := {}
	for setting in SETTINGS:
		if mode in setting.modes:
			settings[setting.key] = setting.default
	return settings


static func setting(info: Dictionary, key: String) -> Variant:
	if info.get("settings", {}).has(key):
		return info.settings[key]
	for entry in SETTINGS:
		if entry.key == key:
			return entry.default
	return null


# "Mon monde", or "Mon monde 2" if that name is taken.
static func unique_name(wanted: String) -> String:
	var taken := {}
	for info in list():
		taken[info.name] = true
	var candidate := wanted
	var n := 2
	while taken.has(candidate):
		candidate = "%s %d" % [wanted, n]
		n += 1
	return candidate


# "Joué aujourd'hui", "Joué hier" or "Joué le 24/10".
static func played_text(info: Dictionary) -> String:
	var bias := int(Time.get_time_zone_from_system().bias) * 60
	var day := int((info.last_played + bias) / 86400.0)
	var today := int((Time.get_unix_time_from_system() + bias) / 86400.0)
	if day == today:
		return "Joué aujourd'hui"
	if day == today - 1:
		return "Joué hier"
	var date := Time.get_date_dict_from_unix_time(int(info.last_played) + bias)
	return "Joué le %02d/%02d" % [date.day, date.month]


# Games saved before worlds existed (one adventure and one creative park) become worlds.
# The old files are kept, renamed, in case something goes wrong.
static func migrate_old_saves() -> void:
	for mode in MODES:
		var old := ["user://%s.json" % mode, "user://%s.bak.json" % mode]
		if not FileAccess.file_exists(old[0]) and not FileAccess.file_exists(old[1]):
			continue
		var source: String = old[0] if FileAccess.file_exists(old[0]) else old[1]
		var world_name := "Mon parc"
		var data = JSON.parse_string(FileAccess.get_file_as_string(source))
		if mode == "adventure":
			var player_name := ""
			if data is Dictionary:
				player_name = str(data.get("player", {}).get("look", {}).get("name", ""))
			# "Explorateur" is the name given when none was typed.
			world_name = "Monde de " + player_name if player_name not in ["", "Explorateur"] else "Mon aventure"
		var info := create(unique_name(world_name), mode, defaults(mode))
		info.last_played = float(FileAccess.get_modified_time(source))
		save_info(info)
		var dir := DirAccess.open("user://")
		for i in old.size():
			if FileAccess.file_exists(old[i]):
				dir.copy(old[i], folder(info.id) + ["/save.json", "/save.bak.json"][i])
				dir.rename(old[i], old[i].replace(".json", ".old.json"))

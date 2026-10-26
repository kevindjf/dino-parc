extends RefCounted

# Saves and loads a park as a JSON file in the folder of its world (see worlds.gd).

const Worlds := preload("res://scripts/worlds.gd")
const VERSION := 1


static func path_for(world_id: String) -> String:
	return Worlds.folder(world_id) + "/save.json"


static func backup_for(world_id: String) -> String:
	return Worlds.folder(world_id) + "/save.bak.json"


static func exists(world_id: String) -> bool:
	return FileAccess.file_exists(path_for(world_id)) or FileAccess.file_exists(backup_for(world_id))


static func save(park: Node2D) -> void:
	var buildings := []
	for building in park.buildings:
		if building.fixed:
			continue
		buildings.append({"id": building.id, "x": building.origin.x, "y": building.origin.y,
			"stock": building.stock, "ready": building.get("ready", true)})
	var dinos := []
	for dino in park.dinos:
		var entry := {"id": dino.species_id, "x": dino.cell.x, "y": dino.cell.y, "wild": dino.wild, "trust": dino.trust,
			"friendship": dino.friendship, "saddled": dino.saddled}
		# Out with the player (ridden or following): it is saved back home.
		if not dino.wild and (dino.ridden or dino.following != null):
			entry.x = dino.home_cell.x
			entry.y = dino.home_cell.y
		if dino.home_building != null:
			entry.home = [dino.home_building.origin.x, dino.home_building.origin.y]
		dinos.append(entry)
	var data := {
		"version": VERSION, "money": park.money, "total_visitors": park.total_visitors, "goal_index": park.goal_index,
		"grid": [park.GRID.x, park.GRID.y], "water": Marshalls.raw_to_base64(park.water),
		"biomes": Array(park.biomes), "buildings": buildings, "dinos": dinos, "caught": park.caught.keys(),
	}
	if park.player != null:
		var look := {}
		for key in park.look:
			look[key] = park.look[key].to_html() if park.look[key] is Color else park.look[key]
		var at: Vector2 = park.player_surface_position()
		data.player = {"look": look, "x": at.x, "y": at.y, "inventory": park.inventory.to_dict()}
		data.mines = park.mine_states
		data.village = park.village_state
	# Write to a temporary file first, keep the previous save as a backup, then swap:
	# a crash in the middle of writing never loses the game.
	var path := path_for(park.world_info.id)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var dir := DirAccess.open(Worlds.folder(park.world_info.id))
	if FileAccess.file_exists(path):
		dir.rename(path.get_file(), backup_for(park.world_info.id).get_file())
	dir.rename((path + ".tmp").get_file(), path.get_file())
	Worlds.touch(park.world_info)


# Reads the save, or the backup if the save is missing or damaged.
static func load_data(world_id: String) -> Dictionary:
	for path in [path_for(world_id), backup_for(world_id)]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var data = JSON.parse_string(file.get_as_text())
		if data is Dictionary and data.has("biomes"):
			return data
	return {}


# Colours of the character come back from JSON as text.
static func look_from(data: Dictionary) -> Dictionary:
	var look := {}
	for key in data:
		look[key] = data[key] if key in ["name", "style"] else Color(data[key])
	return look

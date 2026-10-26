extends RefCounted

# The bag (how many of each item) and the tool bar: a few slots always at hand, one of them in use.
# An empty slot means bare hands.

signal changed

const Items := preload("res://scripts/items.gd")
const SLOTS := 8

var counts := {}
var hotbar: Array[String] = []
var selected := 0
var held_before := ""  # what was in the slot before a dinosaur was taken out of "Mes dinos"


func _init() -> void:
	hotbar.resize(SLOTS)
	hotbar.fill("")


func count(id: String) -> int:
	return counts.get(id, 0)


func current() -> String:
	return hotbar[selected]


func add(id: String, amount := 1) -> void:
	var is_new := count(id) == 0 and not id in hotbar
	counts[id] = count(id) + amount
	# New things go straight to a free slot of the tool bar, so they are ready to use.
	# (Caught dinosaurs wait in "Mes dinos" instead.)
	if is_new and not Items.kind_of(id) in ["resource", "ammo", "dino"]:
		var free := hotbar.find("")
		if free >= 0:
			hotbar[free] = id
	changed.emit()


func remove(id: String, amount := 1) -> bool:
	if count(id) < amount:
		return false
	counts[id] = count(id) - amount
	if counts[id] == 0:
		counts.erase(id)
		# Once the last one is released, the slot gets back what it held before.
		if Items.kind_of(id) == "dino" and id in hotbar:
			hotbar[hotbar.find(id)] = held_before if held_before == "" or count(held_before) > 0 else ""
			held_before = ""
	changed.emit()
	return true


func has_all(needs: Dictionary) -> bool:
	for id in needs:
		if count(id) < needs[id]:
			return false
	return true


func craft(recipe: Dictionary) -> bool:
	if not has_all(recipe.needs):
		return false
	for id in recipe.needs:
		remove(id, recipe.needs[id])
	add(recipe.make, recipe.count)
	return true


func select(slot: int) -> void:
	selected = clampi(slot, 0, SLOTS - 1)
	changed.emit()


# Puts an item of the bag in the selected slot (it leaves the slot it was in).
func assign(id: String) -> void:
	var previous := hotbar.find(id)
	if previous >= 0:
		hotbar[previous] = hotbar[selected]
	hotbar[selected] = id
	changed.emit()


# Takes a dinosaur out of "Mes dinos" and puts it in hand, to release it.
func hold(id: String) -> void:
	var current := hotbar[selected]
	if Items.kind_of(current) != "dino":
		held_before = current
	var previous := hotbar.find(id)
	if previous >= 0 and previous != selected:
		hotbar[previous] = ""
	hotbar[selected] = id
	changed.emit()


# The caught dinosaurs, species id -> how many.
func dinos() -> Dictionary:
	var found := {}
	for id in counts:
		if id.begins_with("dino:"):
			found[id.substr(5)] = counts[id]
	return found


func to_dict() -> Dictionary:
	return {"counts": counts.duplicate(), "hotbar": Array(hotbar), "selected": selected}


func from_dict(data: Dictionary) -> void:
	counts = {}
	for id in data.get("counts", {}):
		if Items.exists(id):
			counts[id] = int(data.counts[id])
	var slots: Array = data.get("hotbar", [])
	for i in SLOTS:
		hotbar[i] = slots[i] if i < slots.size() and (slots[i] == "" or Items.exists(slots[i])) else ""
	selected = int(data.get("selected", 0))
	changed.emit()

extends RefCounted

# The shop of the village: what the merchant sells for coins, and what he buys back.
# Coins come from the park visitors, from the chests of the abandoned houses and from selling here.
# To add something to the shop, add a line to BUY: any id of items.gd, how many, the price.

const BUY := [
	{"id": "boots", "count": 1, "price": 80},
	{"id": "boots_fast", "count": 1, "price": 250},
	{"id": "bike", "count": 1, "price": 150},
	{"id": "moto", "count": 1, "price": 400},
	{"id": "car", "count": 1, "price": 800},
	{"id": "heli", "count": 1, "price": 1500},
	{"id": "capsule_copper", "count": 2, "price": 40},
	{"id": "capsule_iron", "count": 2, "price": 90},
	{"id": "capsule_gold", "count": 1, "price": 250},
	{"id": "arrow", "count": 10, "price": 30},
	{"id": "bolas", "count": 2, "price": 40},
	{"id": "dart", "count": 3, "price": 45},
	{"id": "spear", "count": 1, "price": 40},
	{"id": "blowpipe", "count": 1, "price": 60},
	{"id": "net", "count": 2, "price": 50},
	{"id": "sniper", "count": 1, "price": 900},
	{"id": "lab", "count": 1, "price": 600},
	{"id": "syringe", "count": 5, "price": 80},
	{"id": "meat", "count": 5, "price": 25},
	{"id": "feeder_meat", "count": 1, "price": 120},
	{"id": "saddle", "count": 1, "price": 120},
	{"id": "brush", "count": 1, "price": 20},
	{"id": "pickaxe_iron", "count": 1, "price": 150},
	{"id": "bush", "count": 1, "price": 25},
	{"id": "feeder_plants", "count": 1, "price": 60},
	{"id": "fence_electric", "count": 4, "price": 200},
	{"id": "iron", "count": 2, "price": 50},
	{"id": "crystal", "count": 1, "price": 100},
	{"id": "gold", "count": 1, "price": 120},
]

# What the merchant gives for one of each thing.
const SELL := {
	"wood": 1, "stone": 1, "berries": 1, "copper": 3, "iron": 5,
	"crystal": 15, "gold": 20, "amber": 25, "fossil": 30, "meat_cooked": 8, "pie": 4,
}

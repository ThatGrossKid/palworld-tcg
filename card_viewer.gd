extends Node2D

var cards: Array = []
var cards_by_number: Dictionary = {}
@onready var card_manager = $CardManager

func _ready() -> void:
	# Load card data
	var file = FileAccess.open("res://cards/cards.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	cards = json.get_data()
	file.close()

	for card in cards:
		cards_by_number[card["CardNumber"]] = card

	# Display first 6 cards
	var card_numbers = ["ETD01-001", "ETD01-002", "ETD01-003", "ETD01-004", "ETD01-005", "ETD01-006"]
	var card_scene = load("res://cards/pal_card.tscn") as PackedScene


	for i in range(card_numbers.size()):
		var card_data = cards_by_number[card_numbers[i]]
		var card = card_scene.instantiate()
		var image = card.get_node("Card") as Sprite2D
		image.texture = load("res://textures/cards/%s.png" % card_data["CardNumber"])
		card_manager.add_child(card)

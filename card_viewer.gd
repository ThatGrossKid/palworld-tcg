extends Node2D

var cards: Array = []
var cards_by_number: Dictionary = {}

func _ready() -> void:
	# Load card data
	var file = FileAccess.open("res://cards.json", FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	cards = json.get_data()
	file.close()

	for card in cards:
		cards_by_number[card["CardNumber"]] = card

	# Display first 6 cards
	var card_numbers = ["ETD01-001", "ETD01-002", "ETD01-003", "ETD01-004", "ETD01-005", "ETD01-006"]
	var card_scene = load("res://pal_card.tscn") as PackedScene

	# Scale to fit 6 cards across 1920 width with some padding
	var card_scale = 0.15  # 1118 * 0.15 ≈ 168px wide
	var card_width = 1118 * card_scale
	var card_height = 1560 * card_scale
	var padding = 20.0
	var total_width = (card_width * 6) + (padding * 5)
	var start_x = (1920 - total_width) / 2

	for i in range(card_numbers.size()):
		var card_data = cards_by_number[card_numbers[i]]
		var card = card_scene.instantiate()
		var image = card.get_node("CardImage") as TextureRect
		image.texture = load("res://textures/cards/%s.png" % card_data["CardNumber"])
		card.scale = Vector2(card_scale, card_scale)
		card.position = Vector2(start_x + i * (card_width + padding), (1080 - card_height) / 2)
		add_child(card)

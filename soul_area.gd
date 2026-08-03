extends Node2D

@export var num_of_souls: int = 0   # How many souls are already on the field


func _ready() -> void:
	# Listen for the request to draw soul cards
	EventBus.connect("draw_soul_cards", _handle_draw_soul_cards)


func _handle_draw_soul_cards(cards: int) -> void:
	# Load the scene once – we’ll instantiate a new copy for every card
	var soul_scene: PackedScene = load("res://cards/soul_card.tscn")

	for i in range(cards):
		# Create a fresh instance each time
		var soul_card = soul_scene.instantiate()

		# Find the target child node where this card should appear
		# (the first free slot after `num_of_souls` children)
		if num_of_souls >= get_child_count():
			push_warning("No more slots available for soul cards.")
			return

		var target_slot: Node = get_child(num_of_souls)

		# Add it to that slot (or directly under this node if you prefer)
		target_slot.add_child(soul_card)

		# Move on to the next free slot
		num_of_souls += 1

extends Node2D
class_name PlayersHand

const HAND_COUNT = 2
const PAL_CARD_SCENE_PATH = "res://cards/pal_card.tscn"
const GEAR_CARD_SCENE_PATH = "res://cards/gear_card.tscn"
const EVENT_CARD_SCENE_PATH = "res://cards/event_card.tscn"

# Where new card nodes get added — point this at your hand container in the Inspector.
@export var hand_container: Node

func _ready() -> void:
	EventBus.connect("draw_card", _handle_draw_card)
	if hand_container == null:
		hand_container = self  # fallback so it doesn't crash if unset

func _handle_draw_card(card_id: String) -> void:
	var card_data = _find_card_data(card_id)
	print("drawing")
	if card_data == null:
		push_warning("PlayersHand: card '%s' not found in CardDatabase" % card_id)
		return

	var scene_path = _get_scene_path_for(card_data.get("CardType"))
	if scene_path == "":
		push_warning("PlayersHand: no scene mapped for CardType '%s'" % str(card_data.get("CardType")))
		return

	var card_scene: PackedScene = load(scene_path)
	var new_card = card_scene.instantiate()

	if new_card.has_method("set_card_data"):
		new_card.set_card_data(card_data)
	else:
		push_warning("PlayersHand: %s has no set_card_data() method" % scene_path)

	hand_container.add_child(new_card)

func _get_scene_path_for(card_type) -> String:
	match card_type:
		"Pal":
			return PAL_CARD_SCENE_PATH
		"Gear":
			return GEAR_CARD_SCENE_PATH
		"Event":
			return EVENT_CARD_SCENE_PATH
		_:
			return ""

func _find_card_data(card_number: String):
	for card in GlobalCardData.cards:
		if card.get("CardNumber") == card_number:
			return card
	return null

func _process(delta: float) -> void:
	pass

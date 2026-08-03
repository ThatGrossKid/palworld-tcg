extends Node2D

var current_card:Card = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("view_card", _handle_view_card)

func _update_card_description()-> void:
	pass

func _handle_view_card(card_number:String) -> void:
	var card:Dictionary
	var found = false
	for card_info:Dictionary in GlobalCardData.cards:
		if card_info.CardNumber == card_number:
			card = card_info
			found = true
	if not found:
		printerr("Card Doesn't exist")
	var card_name
	var card_rarity
	var card_type
	var card_subtype
	

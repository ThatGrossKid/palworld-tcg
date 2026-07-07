extends Node2D
class_name MainDeck

@onready var _cards: Array = []

func _ready() -> void:
	test_deck()

func get_cards()-> Array:
	return _cards

func draw_card()-> void:
	var temp_card_id = dequeue()
	EventBus.request_draw_card(temp_card_id)

func test_deck()-> void:
	for i in range(2, 25):
		var id = "ETD02-%03d" % i
		_cards.append(id)
		_cards.append(id)

func enqueue(card_id:String):
	_cards.push_back(card_id)

func dequeue():
	if not _cards.is_empty():
		return _cards.pop_front()
	else:
		return EventBus.request_deck_is_empty()
	return null

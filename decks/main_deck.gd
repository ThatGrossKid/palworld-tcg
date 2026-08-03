extends Node2D
class_name MainDeck

@onready var _cards: Array = []
@onready var _main_deck_tooltip_data: Control = $DeckToolTip
@onready var _main_deck_hover_area: Area2D = $MainDeckHoverArea

# CardNumber -> quantity in this deck. Override/set in the Inspector per deck instance.
@export var decklist: Dictionary = {
	"ETD02-012": 1,
	"ETD02-002": 4,
	"ETD02-003": 4,
	"ETD02-004": 3,
	"ETD02-005": 2,
	"ETD02-006": 1,
	"ETD02-007": 1,
	"ETD02-008": 2,
	"ETD02-009": 1,
	"ETD02-010": 1,
	"ETD02-011": 2,
	"ETD02-023": 2,
	"ETD02-024": 2,
}

func _ready() -> void:
	_set_deck()
	_shuffle()
	EventBus.connect("change_phase", _handle_phase_change)

	_main_deck_tooltip_data.visible = false
	_main_deck_hover_area.mouse_entered.connect(_on_mouse_entered)
	_main_deck_hover_area.mouse_exited.connect(_on_mouse_exited)

func _set_deck() -> void:
	_cards.clear()
	for card_number in decklist.keys():
		var qty: int = decklist[card_number]
		var card_data = _find_card_data(card_number)
		if card_data == null:
			push_warning("MainDeck: '%s' not found in CardDatabase — skipping" % card_number)
			continue
		for i in range(qty):
			_cards.append(card_number)

func _find_card_data(card_number: String):
	for card in GlobalCardData.cards:
		if card.get("CardNumber") == card_number:
			return card
	return null

func _shuffle() -> void:
	_cards.shuffle()

func _on_mouse_entered() -> void:
	_main_deck_tooltip_data.visible = true
func _on_mouse_exited() -> void:
	_main_deck_tooltip_data.visible = false
func get_cards() -> Array:
	return _cards
func draw_card() -> void:
	var temp_card_id = dequeue()
	EventBus.request_draw_card(temp_card_id)
func enqueue(card_id: String) -> void:
	_cards.push_back(card_id)
func dequeue():
	if not _cards.is_empty():
		return _cards.pop_front()
	else:
		return EventBus.request_deck_is_empty()
func _handle_phase_change(phase: PlayersField.Phase) -> void:
	if phase == PlayersField.Phase.DRAW:
		print("Draw card")
		draw_card()

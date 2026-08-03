extends MainDeck
class_name SoulDeck

var cards_in_deck: int = 10
@onready var number_of_cards: Label = $SoulDeckToolTip/ToolTipLabel/NumCards
@onready var _tooltip_data: Control = $SoulDeckToolTip
@onready var hover_area: Area2D = $SoulDeckHoverArea

func _ready() -> void:
	number_of_cards.text = "# of Cards: " + str(cards_in_deck)
	_tooltip_data.visible = false

	EventBus.connect("change_phase", _handle_phase_change)
	EventBus.connect("draw_soul_cards", _handle_draw_soul_cards)

	hover_area.mouse_entered.connect(_on_mouse_entered)
	hover_area.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_tooltip_data.visible = true

func _on_mouse_exited() -> void:
	_tooltip_data.visible = false

func _handle_phase_change(phase: PlayersField.Phase) -> void:
	if phase == PlayersField.Phase.SOUL:
		var to_draw = clamp(cards_in_deck, 1, 2)
		if to_draw > 0:
			_draw_cards(to_draw)
			print("DRAW %d SOUL card(s)" % to_draw)

func _handle_draw_soul_cards(cards: int) -> void:
	cards_in_deck -= cards
	number_of_cards.text = "# of Cards: " + str(cards_in_deck)

func _draw_cards(cards: int) -> void:
	EventBus.request_draw_soul_cards(cards)

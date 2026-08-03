extends Card
class_name PalCard

# ------------------------------------------------------------------
#   Private fields
# ------------------------------------------------------------------
var _lucky: bool = false
var _cost: int = 0
var _power: int = 0
var _strike: int = 0
var _subtype          # inferred type, e.g. String or enum
var _color            # inferred type, e.g. Color or int
var _element          # inferred type, e.g. String or enum
var _flavor           # inferred type, e.g. String
var _work_suitability # inferred type, e.g. bool

# ------------------------------------------------------------------
#   Getters (read‑only access)
# ------------------------------------------------------------------
func is_lucky() -> bool:
	return _lucky

func get_cost() -> int:
	return _cost

func get_power() -> int:
	return _power

func get_strike() -> int:
	return _strike

func get_subtype():
	return _subtype

func get_color():
	return _color

func get_element():
	return _element

func get_flavor() -> String:
	return _flavor

func is_work_suitable() -> bool:
	return _work_suitability


# ------------------------------------------------------------------
#   Scene entry point
# ------------------------------------------------------------------
func _ready() -> void:
	super._ready()
	card_type = Card.CardType.PAL

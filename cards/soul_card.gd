extends Card

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	description = "During your turn, you may rest 3 souls once during the main phase to draw 1 card"
	super._ready()
	card_type= Card.CardType.SOUL

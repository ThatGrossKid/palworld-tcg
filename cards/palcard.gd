extends Card

var lucky:bool = false
var cost:int = 0
var power:int = 0
var strike:int = 0
var subtype
var color
var element
var flavor
var work_suitability

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	card_type= Card.CardType.PAL

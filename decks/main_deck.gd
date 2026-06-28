extends Node2D
class_name MainDeck

@onready var _cards: Array = []

func _ready() -> void:
	pass # Replace with function body.

func get_cards()-> Array:
	return _cards

extends Node2D

@onready var _life_points:int = 10
@onready var _deck:MainDeck
@onready var _cards_in_hand:Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func get_life_points()-> int:
	return _life_points
	
func get_deck() -> MainDeck:
	return _deck
	
func get_cards_in_hand() -> Array:
	return _cards_in_hand

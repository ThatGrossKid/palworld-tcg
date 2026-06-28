extends Node2D
class_name Card

enum CardType {PAL, STRUCTURE, SOUL}
enum Rarity {TD}

@onready var resting:bool = false
@onready var card_type:CardType
@onready var description:String = ""
@onready var rarity:Rarity
@onready var card_number:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func unrest_card() -> void:
	resting = false

func rest_card() -> void:
	resting = true

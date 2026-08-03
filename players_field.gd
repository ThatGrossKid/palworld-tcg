extends Node2D
class_name PlayersField

enum Phase{
	STAND,
	DRAW,
	SOUL,
	MAIN
}

@onready var _life_points:int = 10
@onready var _deck:MainDeck
@onready var _cards_in_hand:Array = []

@onready var stand_phase_button:Button = %StandPhaseButton
@onready var draw_phase_button:Button = %DrawPhaseButton
@onready var soul_phase_button:Button = %SoulPhaseButton
@onready var main_phase_button:Button = %MainPhaseButton

var cards: Array = []
var cards_by_number: Dictionary = {}
var players_turn: bool = true
var players_phase:Phase = Phase.STAND


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stand_phase_button.visible=true
	draw_phase_button.visible=false
	soul_phase_button.visible=false
	main_phase_button.visible=false
	stand_phase_button.connect("button_up",change_phase)
	draw_phase_button.connect("button_up",change_phase)
	soul_phase_button.connect("button_up",change_phase)
	main_phase_button.connect("button_up",change_phase)
	
func get_life_points()-> int:
	return _life_points
	
func get_deck() -> MainDeck:
	return _deck
	
func get_cards_in_hand() -> Array:
	return _cards_in_hand
	
		
func _on_change_turn()-> void:
	if players_turn:
		players_turn = false
	else:
		players_turn = true
		players_phase=Phase.STAND
		
		
func change_phase()-> void:
	#check to see if anything happens on phase change
	if players_phase ==Phase.STAND:
		print("Ending stand phase")
		if players_turn:
			stand_phase_button.visible=false
			draw_phase_button.visible=true
			players_phase= Phase.DRAW
	elif players_phase==Phase.DRAW:
		print("Ending draw phase")
		if players_turn:
			draw_phase_button.visible=false
			soul_phase_button.visible=true
			players_phase= Phase.SOUL
	elif players_phase ==Phase.SOUL:
		print("Ending soul phase")
		if players_turn:
			soul_phase_button.visible=false
			main_phase_button.visible=true
			players_phase= Phase.MAIN
	elif players_phase==Phase.MAIN:
		print("Ending main phase")
		if players_turn:
			main_phase_button.visible=false
			change_turn()
	EventBus.request_change_phase(players_phase)

func change_turn()-> void:
	EventBus.request_change_turn()
	

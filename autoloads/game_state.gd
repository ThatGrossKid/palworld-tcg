extends Node

# Store whatever your game needs — scores, turn, phase, etc.
var scores: Dictionary = {}       # peer_id → score
var current_turn: int = 0
var game_phase: String = "lobby"  # "lobby", "playing", "results"

signal state_changed()
signal game_started()
signal game_ended(results: Dictionary)


func reset() -> void:
	scores.clear()
	current_turn = 0
	game_phase = "lobby"


# Called by server to start the game
@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	game_phase = "playing"
	game_started.emit()


# Called by server to update a score
@rpc("authority", "call_local", "reliable")
func update_score(peer_id: int, new_score: int) -> void:
	scores[peer_id] = new_score
	state_changed.emit()


# Called by server to end the game
@rpc("authority", "call_local", "reliable")
func end_game(results: Dictionary) -> void:
	game_phase = "results"
	game_ended.emit(results)
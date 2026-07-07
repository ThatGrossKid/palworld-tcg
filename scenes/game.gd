extends Node


func _ready() -> void:
	GameState.state_changed.connect(_on_state_changed)
	GameState.game_ended.connect(_on_game_ended)
	_refresh_ui()


func _refresh_ui() -> void:
	# Update your UI to reflect GameState.scores, etc.
	pass


# ─────────────────────────────────────────
#  Example Game Logic: Player presses an action button
# ─────────────────────────────────────────

func _on_action_button_pressed() -> void:
	# Send the action to the server; server validates and updates state
	submit_action.rpc_id(1, Network.my_id, "my_action_data")


# Client → Server: submit an action
@rpc("any_peer", "reliable")
func submit_action(peer_id: int, _action: String) -> void:
	if not multiplayer.is_server():
		return
	# Server validates action, updates GameState, then tells all clients
	var new_score = GameState.scores.get(peer_id, 0) + 1
	GameState.update_score.rpc(peer_id, new_score)


# ─────────────────────────────────────────
#  React to state changes and game end
# ─────────────────────────────────────────

func _on_state_changed() -> void:
	_refresh_ui()


func _on_game_ended(results: Dictionary) -> void:
	# Show results screen or change scene
	print("Game over! Results: ", results)

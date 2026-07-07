extends Node

func _ready() -> void:
	print("[Server] Starting server...")
	Network.host_server()
	Network.player_joined.connect(_on_player_joined)
	Network.player_left.connect(_on_player_left)
	print("[Server] Ready. Listening on port %d" % Network.PORT)


func _on_player_joined(id: int, data: Dictionary) -> void:
	print("[Server] Player joined lobby %s: %d (%s)" % [
		data.get("lobby_code", "?"),
		id,
		data.get("username", "?")
	])


func _on_player_left(id: int, lobby_code: String) -> void:
	print("[Server] Player %d left lobby %s" % [id, lobby_code])
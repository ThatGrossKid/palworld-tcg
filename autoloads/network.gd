extends Node

# --- Config ---
const PORT = 7777  # UDP port the server listens on
const MAX_CLIENTS = 64  # Max amount of clients connected to your server, not a single lobby
const MAX_USERNAME_LENGTH = 32
const LOBBY_CODE_LENGTH = 4

# --- State ---
var players: Dictionary = {}  # peer_id → { username, lobby_code }
var my_id: int = 0
var my_username: String = ""
var my_lobby_code: String = ""
var my_lobby_max_players: int  # Client-side copy of the lobby's max_players setting

# Server-only: all active lobbies
# lobby_code → { "players": [peer_ids], "ready": {peer_id: bool}, "phase": "lobby"/"playing", "host": peer_id, "max_players": int, "banned": [peer_ids] }
var lobbies: Dictionary = {}

# Client-side ready state mirror: peer_id → bool
var lobby_ready_states: Dictionary = {}

# --- Signals ---
signal player_joined(id: int, data: Dictionary)
signal player_left(id: int, lobby_code: String)
signal connection_succeeded()
signal connection_failed()
signal server_disconnected()
signal lobby_created(code: String)
signal lobby_joined(code: String)
signal lobby_join_failed(reason: String)
signal ready_state_changed(peer_id: int, is_ready: bool)
signal all_ready_changed(all_ready: bool)
signal host_changed(new_host_id: int)
signal kicked_from_lobby()
signal banned_from_lobby()


# ─────────────────────────────────────────
#  HOSTING / CONNECTING
# ─────────────────────────────────────────

func host_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to create server: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	my_id = 1
	_connect_signals()


func join_server(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	_connect_signals()


func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	players.clear()
	lobby_ready_states.clear()
	my_id = 0
	my_lobby_code = ""
	my_lobby_max_players = 8


# ─────────────────────────────────────────
#  LOBBY MANAGEMENT (called by the client)
# ─────────────────────────────────────────

func request_create_lobby() -> void:
	_rpc_create_lobby.rpc_id(1, my_username)


func request_join_lobby(code: String) -> void:
	_rpc_join_lobby.rpc_id(1, code.to_upper(), my_username)


func request_leave_lobby() -> void:
	_rpc_leave_lobby.rpc_id(1)


func request_kick_player(target_id: int) -> void:
	_rpc_kick_player.rpc_id(1, target_id)


func request_ban_player(target_id: int) -> void:
	_rpc_ban_player.rpc_id(1, target_id)


var _my_host_id: int = 0


func get_lobby_host() -> int:
	return _my_host_id


func is_local_player_host() -> bool:
	return my_id == _my_host_id


# Called by CreateLobbyDialog after the host configures settings.
func request_create_lobby_with_settings(max_players: int) -> void:
	_rpc_create_lobby_with_settings.rpc_id(1, my_username, max_players)


# ─────────────────────────────────────────
#  LOBBY RPCs — Client → Server
# ─────────────────────────────────────────

@rpc("any_peer", "reliable")
func _rpc_create_lobby(username: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var code = _generate_lobby_code()
	lobbies[code] = {
		"players": [sender_id],
		"ready": {},
		"phase": "lobby",
		"host": sender_id,
		"max_players": 8,
		"banned": [],
	}
	players[sender_id] = { "username": username, "lobby_code": code }
	print("[Server] Lobby %s created by player %d (%s) | Active lobbies: %d" % [code, sender_id, username, lobbies.size()])
	_rpc_on_lobby_created.rpc_id(sender_id, code, sender_id, 8)
	_send_player_info.rpc_id(sender_id, sender_id, players[sender_id])
	player_joined.emit(sender_id, players[sender_id])


@rpc("any_peer", "reliable")
func _rpc_join_lobby(code: String, username: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()

	if not lobbies.has(code):
		_rpc_on_lobby_join_failed.rpc_id(sender_id, "Lobby not found.")
		return
	if lobbies[code]["phase"] != "lobby":
		_rpc_on_lobby_join_failed.rpc_id(sender_id, "Game already in progress.")
		return
	if sender_id in lobbies[code]["banned"]:
		_rpc_on_lobby_join_failed.rpc_id(sender_id, "You are banned from this lobby.")
		return

	var max_players: int = lobbies[code].get("max_players", 8)
	if lobbies[code]["players"].size() >= max_players:
		_rpc_on_lobby_join_failed.rpc_id(sender_id, "Lobby is full.")
		return

	lobbies[code]["players"].append(sender_id)
	players[sender_id] = { "username": username, "lobby_code": code }
	print("[Server] Player %d (%s) joined lobby %s | Players in lobby: %d" % [sender_id, username, code, lobbies[code]["players"].size()])

	var host_id: int = lobbies[code]["host"]

	# Tell the joiner they succeeded, then send them the existing player list + ready states
	_rpc_on_lobby_joined.rpc_id(sender_id, code, host_id, max_players)
	for existing_id: int in lobbies[code]["players"]:
		if existing_id != sender_id:
			_send_player_info.rpc_id(sender_id, existing_id, players[existing_id])
			# Sync ready states for existing players
			var is_ready: bool = lobbies[code]["ready"].get(existing_id, false)
			if is_ready:
				_rpc_sync_ready_state.rpc_id(sender_id, existing_id, true)

	# Tell everyone already in the lobby about the new player
	for existing_id: int in lobbies[code]["players"]:
		if existing_id != sender_id:
			_send_player_info.rpc_id(existing_id, sender_id, players[sender_id])

	# A new (not-ready) player joined, so all_ready is now false — notify the host
	_rpc_sync_all_ready.rpc_id(lobbies[code]["host"], false)

	player_joined.emit(sender_id, players[sender_id])


# Client → Server: toggle ready state
@rpc("any_peer", "reliable")
func rpc_set_ready(peer_id: int, lobby_code: String, is_ready: bool) -> void:
	if not multiplayer.is_server():
		return
	if not lobbies.has(lobby_code):
		return
	var lobby: Dictionary = lobbies[lobby_code]
	if not peer_id in lobby["players"]:
		return

	lobby["ready"][peer_id] = is_ready
	print("[Server] Player %d ready=%s in lobby %s" % [peer_id, is_ready, lobby_code])

	# Broadcast the new ready state to everyone in this lobby
	for pid: int in lobby["players"]:
		if _is_peer_connected(pid):
			_rpc_sync_ready_state.rpc_id(pid, peer_id, is_ready)

	# Notify the host whether all players are now ready (so they can enable Start)
	var everyone_ready: bool = _all_ready(lobby)
	if _is_peer_connected(lobby["host"]):
		_rpc_sync_all_ready.rpc_id(lobby["host"], everyone_ready)


# Client → Server: host requests the game to start
@rpc("any_peer", "reliable")
func rpc_request_start_game(lobby_code: String) -> void:
	if not multiplayer.is_server():
		return
	if not lobbies.has(lobby_code):
		return
	var lobby: Dictionary = lobbies[lobby_code]
	var sender_id: int = multiplayer.get_remote_sender_id()

	# Only the host may start the game
	if sender_id != lobby["host"]:
		push_warning("[Server] Non-host peer %d tried to start game in lobby %s" % [sender_id, lobby_code])
		return

	if not _all_ready(lobby):
		push_warning("[Server] Host tried to start but not all players are ready in lobby %s" % lobby_code)
		return

	lobby["phase"] = "playing"
	print("[Server] Host started game in lobby %s" % lobby_code)

	for pid: int in lobby["players"]:
		if _is_peer_connected(pid):
			_rpc_start_game.rpc_id(pid)
	GameState.start_game.call()


# Client → Server: host requests to transfer host to another player
@rpc("any_peer", "reliable")
func rpc_request_transfer_host(lobby_code: String, new_host_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not lobbies.has(lobby_code):
		return
	if sender_id != lobbies[lobby_code]["host"]:
		push_warning("[Server] Non-host peer %d tried to transfer host in lobby %s" % [sender_id, lobby_code])
		return
	transfer_host(lobby_code, new_host_id)


# Client → Server: voluntarily leave the lobby
@rpc("any_peer", "reliable")
func _rpc_leave_lobby() -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	_remove_player_from_lobby(sender_id, false, false)


# Client → Server (host only): kick a player from the lobby
@rpc("any_peer", "reliable")
func _rpc_kick_player(target_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var code: String = players.get(sender_id, {}).get("lobby_code", "")
	if code == "" or not lobbies.has(code):
		return
	if lobbies[code]["host"] != sender_id:
		push_warning("[Server] Non-host peer %d tried to kick peer %d" % [sender_id, target_id])
		return
	if target_id == sender_id:
		return  # host can't kick themselves
	if not target_id in lobbies[code]["players"]:
		return
	print("[Server] Host %d kicked player %d from lobby %s" % [sender_id, target_id, code])
	if _is_peer_connected(target_id):
		_rpc_on_kicked.rpc_id(target_id)
	_remove_player_from_lobby(target_id, true, false)


# Client → Server (host only): ban a player from the lobby
@rpc("any_peer", "reliable")
func _rpc_ban_player(target_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	var code: String = players.get(sender_id, {}).get("lobby_code", "")
	if code == "" or not lobbies.has(code):
		return
	if lobbies[code]["host"] != sender_id:
		push_warning("[Server] Non-host peer %d tried to ban peer %d" % [sender_id, target_id])
		return
	if target_id == sender_id:
		return  # host can't ban themselves
	if not target_id in lobbies[code]["players"]:
		return
	print("[Server] Host %d banned player %d from lobby %s" % [sender_id, target_id, code])
	lobbies[code]["banned"].append(target_id)
	if _is_peer_connected(target_id):
		_rpc_on_banned.rpc_id(target_id)
	_remove_player_from_lobby(target_id, true, false)


# ─────────────────────────────────────────
#  HOST TRANSFER  (Server-side)
# ─────────────────────────────────────────

func transfer_host(lobby_code: String, new_host_id: int) -> void:
	if not multiplayer.is_server():
		push_warning("[Network] transfer_host must be called on the server.")
		return
	if not lobbies.has(lobby_code):
		push_warning("[Network] transfer_host: lobby %s not found." % lobby_code)
		return
	if not new_host_id in lobbies[lobby_code]["players"]:
		push_warning("[Network] transfer_host: peer %d is not in lobby %s." % [new_host_id, lobby_code])
		return

	lobbies[lobby_code]["host"] = new_host_id
	print("[Server] Host of lobby %s transferred to peer %d" % [lobby_code, new_host_id])

	for pid: int in lobbies[lobby_code]["players"]:
		if _is_peer_connected(pid):
			_rpc_on_host_changed.rpc_id(pid, new_host_id)

	if _is_peer_connected(new_host_id):
		_rpc_sync_all_ready.rpc_id(new_host_id, _all_ready(lobbies[lobby_code]))


@rpc("any_peer", "reliable")
func _rpc_create_lobby_with_settings(username: String, max_players: int) -> void:
	if not multiplayer.is_server():
		return

	var sender_id := multiplayer.get_remote_sender_id()

	# Clamp to sane bounds in case a malicious client sends garbage
	max_players = clampi(max_players, 2, 16)

	var code := _generate_lobby_code()
	lobbies[code] = {
		"players":     [sender_id],
		"ready":       {},
		"phase":       "lobby",
		"host":        sender_id,
		"max_players": max_players,
		"banned":      [],
	}
	players[sender_id] = { "username": username, "lobby_code": code }

	print("[Server] Lobby %s created by %d (%s) | max_players=%d | Active lobbies: %d" % [
		code, sender_id, username, max_players, lobbies.size()
	])

	_rpc_on_lobby_created.rpc_id(sender_id, code, sender_id, max_players)
	_send_player_info.rpc_id(sender_id, sender_id, players[sender_id])
	player_joined.emit(sender_id, players[sender_id])


# ─────────────────────────────────────────
#  LOBBY RPCs — Server → Client
# ─────────────────────────────────────────

@rpc("authority", "reliable")
func _rpc_on_lobby_created(code: String, host_id: int, max_players: int) -> void:
	my_lobby_code = code
	_my_host_id = host_id
	my_lobby_max_players = max_players
	players[my_id] = { "username": my_username, "lobby_code": code }
	lobby_created.emit(code)


@rpc("authority", "reliable")
func _rpc_on_lobby_joined(code: String, host_id: int, max_players: int) -> void:
	my_lobby_code = code
	_my_host_id = host_id
	my_lobby_max_players = max_players
	players[my_id] = { "username": my_username, "lobby_code": code }
	lobby_joined.emit(code)


@rpc("authority", "reliable")
func _rpc_on_lobby_join_failed(reason: String) -> void:
	lobby_join_failed.emit(reason)


# Server → all lobby members: a player's ready state changed
@rpc("authority", "reliable")
func _rpc_sync_ready_state(peer_id: int, is_ready: bool) -> void:
	lobby_ready_states[peer_id] = is_ready
	ready_state_changed.emit(peer_id, is_ready)


# Server → host only: whether all players are ready (drives Start button)
@rpc("authority", "reliable")
func _rpc_sync_all_ready(everyone_ready: bool) -> void:
	all_ready_changed.emit(everyone_ready)


# Server → all lobby members: host has changed
@rpc("authority", "reliable")
func _rpc_on_host_changed(new_host_id: int) -> void:
	_my_host_id = new_host_id
	host_changed.emit(new_host_id)


# Server → Client: game is starting
@rpc("authority", "reliable")
func _rpc_start_game() -> void:
	GameState.game_started.emit()


# Server → Clients: info about a player
@rpc("authority", "reliable")
func _send_player_info(id: int, data: Dictionary) -> void:
	if multiplayer.is_server():
		return
	players[id] = data
	player_joined.emit(id, data)


# Server → remaining lobby members: a peer has left the lobby
@rpc("authority", "reliable")
func _rpc_notify_player_left(id: int) -> void:
	var code: String = players.get(id, {}).get("lobby_code", "")
	players.erase(id)
	lobby_ready_states.erase(id)
	player_left.emit(id, code)


# Server → kicked client
@rpc("authority", "reliable")
func _rpc_on_kicked() -> void:
	kicked_from_lobby.emit()


# Server → banned client
@rpc("authority", "reliable")
func _rpc_on_banned() -> void:
	banned_from_lobby.emit()


# ─────────────────────────────────────────
#  SERVER HELPERS (misc)
# ─────────────────────────────────────────

func _is_peer_connected(peer_id: int) -> bool:
	if not multiplayer.is_server():
		return false
	var enet_peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet_peer == null:
		return false
	return enet_peer.get_peer(peer_id) != null


func _generate_lobby_code() -> String:
	const CHARS = "123456789"
	var code := ""
	while code == "" or lobbies.has(code):
		code = ""
		for i in range(LOBBY_CODE_LENGTH):
			code += CHARS[randi() % CHARS.length()]
	return code


func get_lobby_players(code: String) -> Array:
	if lobbies.has(code):
		return lobbies[code]["players"]
	return []

func _all_ready(lobby: Dictionary) -> bool:
	var non_host_players = lobby["players"].filter(func(pid): return pid != lobby["host"])
	if non_host_players.size() < 1:
		return false
	for pid: int in non_host_players:
		if not lobby["ready"].get(pid, false):
			return false
	return true

# Shared server-side helper: remove a peer from their lobby and clean up.
# skip_notify_self: true when we already sent a kick/ban RPC to the peer.
# is_disconnect: true when called from _on_peer_disconnected (peer already gone).
func _remove_player_from_lobby(peer_id: int, skip_notify_self: bool, is_disconnect: bool) -> void:
	if not players.has(peer_id):
		return
	var code: String = players[peer_id].get("lobby_code", "")
	players.erase(peer_id)
	if code == "" or not lobbies.has(code):
		return

	lobbies[code]["players"].erase(peer_id)
	lobbies[code]["ready"].erase(peer_id)

	print("[Server] Player %d left lobby %s | Players remaining: %d" % [
		peer_id, code, lobbies[code]["players"].size()
	])

	# Notify remaining members
	for pid: int in lobbies[code]["players"]:
		if _is_peer_connected(pid):
			_rpc_notify_player_left.rpc_id(pid, peer_id)

	# Notify the leaving player themselves (not needed for kicks/bans/disconnects)
	if not skip_notify_self and not is_disconnect and _is_peer_connected(peer_id):
		_rpc_notify_player_left.rpc_id(peer_id, peer_id)

	if lobbies[code]["host"] == peer_id and not lobbies[code]["players"].is_empty():
		transfer_host(code, lobbies[code]["players"][0])

	if lobbies[code]["players"].is_empty():
		# Ban list is per-lobby and cleared when the lobby closes
		lobbies.erase(code)
		print("[Server] Lobby %s closed (empty) | Active lobbies: %d" % [code, lobbies.size()])

	player_left.emit(peer_id, code)


# ─────────────────────────────────────────
#  INTERNAL SIGNAL WIRING
# ─────────────────────────────────────────

func _connect_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(id: int) -> void:
	print("[Network] Player connected: %d" % id)


func _on_peer_disconnected(id: int) -> void:
	print("[Network] Player disconnected: %d" % id)
	_remove_player_from_lobby(id, true, true)


func _on_connected_to_server() -> void:
	my_id = multiplayer.get_unique_id()
	print("[Network] Connected! My ID: %d" % my_id)
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	print("[Network] Connection failed.")
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("[Network] Server disconnected.")
	players.clear()
	lobby_ready_states.clear()
	my_lobby_code = ""
	my_lobby_max_players = 8
	_my_host_id = 0
	server_disconnected.emit()
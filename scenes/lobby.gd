extends Control


@onready var lobby_code_label: Label       = %LobbyCodeLabel
@onready var player_list: VBoxContainer    = %PlayerList
@onready var ready_button: Button          = %ReadyButton
@onready var start_game_button: Button     = %StartGameButton
@onready var status_label: Label           = %StatusLabel
@onready var leave_button: Button          = %LeaveButton

const PLAYER_CARD_SCENE: PackedScene = preload("res://scenes/ui/player_card.tscn")

var _am_ready: bool = false
# Ordered list of peer IDs occupying each slot. 0 means the slot is empty.
var _slots: Array[int] = []


func _ready() -> void:
	Network.player_joined.connect(_on_player_joined)
	Network.player_left.connect(_on_player_left)
	Network.ready_state_changed.connect(_on_ready_state_changed)
	Network.all_ready_changed.connect(_on_all_ready_changed)
	Network.host_changed.connect(_on_host_changed)
	Network.kicked_from_lobby.connect(_on_kicked_from_lobby)
	Network.banned_from_lobby.connect(_on_banned_from_lobby)
	GameState.game_started.connect(_on_game_started)

	lobby_code_label.text = "Lobby Code: %s" % Network.my_lobby_code
	ready_button.text = "Ready"

	_refresh_host_buttons()

	_build_slots()


# ─────────────────────────────────────────
#  Host / Ready Button Visibility
# ─────────────────────────────────────────

func _refresh_host_buttons() -> void:
	var is_host = Network.is_local_player_host()
	ready_button.visible = not is_host
	start_game_button.visible = is_host
	start_game_button.disabled = true


# Create exactly max_players card nodes once; update their content as players join/leave.
func _build_slots() -> void:
	var max_players: int = Network.my_lobby_max_players

	# Clear any lingering children (e.g. on scene reload)
	for child in player_list.get_children():
		child.queue_free()

	_slots.clear()

	for i in range(max_players):
		var card: Node = PLAYER_CARD_SCENE.instantiate()
		card.name = "Slot_%d" % i
		player_list.add_child(card)
		_slots.append(0)  # 0 = empty

	# Populate slots with players already known at scene-load time
	# The local player is always present; others arrive via _send_player_info before lobby_joined
	for id: int in Network.players:
		if Network.players[id].get("lobby_code", "") == Network.my_lobby_code:
			_assign_slot(id)

	_refresh_all_cards()


# Find the first empty slot and assign peer_id to it.
func _assign_slot(id: int) -> void:
	# Don't double-assign
	if id in _slots:
		return
	var empty_idx: int = _slots.find(0)
	if empty_idx == -1:
		push_warning("[Lobby] No empty slot for peer %d — lobby may be over capacity." % id)
		return
	_slots[empty_idx] = id


# Remove peer_id from slots and compact: all filled slots bubble to the top,
# empty slots sink to the bottom. Then refresh every card.
func _release_slot(id: int) -> void:
	var idx: int = _slots.find(id)
	if idx == -1:
		return
	_slots.remove_at(idx)
	_slots.append(0)
	_refresh_all_cards()


# ─────────────────────────────────────────
#  Card Access and Refresh
# ─────────────────────────────────────────

func _get_card(slot_idx: int) -> Node:
	return player_list.get_node_or_null("Slot_%d" % slot_idx)


func _refresh_card(slot_idx: int) -> void:
	var card := _get_card(slot_idx)
	if card == null:
		return
	var id: int = _slots[slot_idx]
	if id == 0:
		card.clear()
		return
	var data: Dictionary = Network.players.get(id, {})
	var is_ready: bool  = Network.lobby_ready_states.get(id, false)
	var is_host: bool   = (id == Network.get_lobby_host())
	var is_you: bool    = (id == Network.my_id)
	card.setup(id, data, is_ready, is_host, is_you)

	if card.has_signal("transfer_host_requested"):
		if card.transfer_host_requested.is_connected(_on_transfer_host_requested):
			card.transfer_host_requested.disconnect(_on_transfer_host_requested)
		card.transfer_host_requested.connect(_on_transfer_host_requested)

	if card.has_signal("kick_requested"):
		if card.kick_requested.is_connected(_on_kick_requested):
			card.kick_requested.disconnect(_on_kick_requested)
		card.kick_requested.connect(_on_kick_requested)

	if card.has_signal("ban_requested"):
		if card.ban_requested.is_connected(_on_ban_requested):
			card.ban_requested.disconnect(_on_ban_requested)
		card.ban_requested.connect(_on_ban_requested)


func _refresh_all_cards() -> void:
	for i in range(_slots.size()):
		_refresh_card(i)


func _refresh_card_for_peer(id: int) -> void:
	var idx: int = _slots.find(id)
	if idx != -1:
		_refresh_card(idx)


# ─────────────────────────────────────────
#  Signal Handlers
# ─────────────────────────────────────────

func _on_player_joined(id: int, data: Dictionary) -> void:
	if data.get("lobby_code", "") != Network.my_lobby_code:
		return
	_assign_slot(id)
	_refresh_card_for_peer(id)


func _on_player_left(id: int, _lobby_code: String) -> void:
	_release_slot(id)


func _on_ready_state_changed(peer_id: int, _is_ready: bool) -> void:
	_refresh_card_for_peer(peer_id)
	_update_status_label()


func _on_all_ready_changed(everyone_ready: bool) -> void:
	start_game_button.disabled = not everyone_ready


func _on_host_changed(_new_host_id: int) -> void:
	_refresh_host_buttons()
	# If the local player just became host, clear their ready state locally and on the server
	if Network.is_local_player_host() and _am_ready:
		_am_ready = false
		ready_button.text = "Ready"
		Network.lobby_ready_states[Network.my_id] = false
		Network.rpc_set_ready.rpc_id(1, Network.my_id, Network.my_lobby_code, false)
	_refresh_all_cards()


func _on_ready_button_pressed() -> void:
	_am_ready = not _am_ready
	ready_button.text = "Unready" if _am_ready else "Ready"
	Network.lobby_ready_states[Network.my_id] = _am_ready
	_refresh_card_for_peer(Network.my_id)
	_update_status_label()
	Network.rpc_set_ready.rpc_id(1, Network.my_id, Network.my_lobby_code, _am_ready)


func _update_status_label() -> void:
	status_label.text = "Waiting for others..." if _am_ready else ""


func _on_start_game_button_pressed() -> void:
	Network.rpc_request_start_game.rpc_id(1, Network.my_lobby_code)
	start_game_button.disabled = true


func _on_transfer_host_requested(target_peer_id: int) -> void:
	if not Network.is_local_player_host():
		return
	Network.rpc_request_transfer_host.rpc_id(1, Network.my_lobby_code, target_peer_id)


func _on_leave_button_pressed() -> void:
	Network.request_leave_lobby()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_kick_requested(target_peer_id: int) -> void:
	if not Network.is_local_player_host():
		return
	Network.request_kick_player(target_peer_id)


func _on_ban_requested(target_peer_id: int) -> void:
	if not Network.is_local_player_host():
		return
	Network.request_ban_player(target_peer_id)


func _on_kicked_from_lobby() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_banned_from_lobby() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# ─────────────────────────────────────────
#  Game Start
# ─────────────────────────────────────────

func _on_game_started() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

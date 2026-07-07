extends PanelContainer


@onready var username_label: Label    = %UsernameLabel
@onready var make_host_button: Button = %MakeHostButton
@onready var kick_button: Button      = %KickButton
@onready var ban_button: Button       = %BanButton

signal transfer_host_requested(peer_id: int)
signal kick_requested(peer_id: int)
signal ban_requested(peer_id: int)

var _peer_id: int = 0


# Fill this slot with a connected player.
func setup(peer_id: int, data: Dictionary, is_ready: bool, is_host: bool, is_you: bool) -> void:
	_peer_id = peer_id

	var username: String = data.get("username", "Unknown")
	username_label.text = username
	username_label.modulate = Color.WHITE

	if is_host:
		username_label.modulate = Color(1, 0.8, 0)  # gold for host
	elif is_ready:
		username_label.modulate = Color(0.5, 1, 0.5) # light green for ready

	var is_local_host = Network.is_local_player_host()
	
	make_host_button.visible = is_local_host and not is_host
	kick_button.visible = is_local_host and not is_you
	ban_button.visible  = is_local_host and not is_you


# Reset this slot to an "empty slot" state.
func clear() -> void:
	_peer_id = 0
	username_label.text  = "Empty Slot"
	username_label.modulate = Color(1, 1, 1, 0.4)
	make_host_button.visible = false
	kick_button.visible = false
	ban_button.visible  = false


func _on_make_host_button_pressed() -> void:
	transfer_host_requested.emit(_peer_id)


func _on_kick_button_pressed() -> void:
	kick_requested.emit(_peer_id)


func _on_ban_button_pressed() -> void:
	ban_requested.emit(_peer_id)

extends Control


@onready var status_label: Label         = %StatusLabel
@onready var username_input: LineEdit    = %UsernameInput
@onready var create_lobby_button: Button = %CreateLobbyButton
@onready var join_lobby_button: Button   = %JoinLobbyButton
@onready var error_label: Label          = %ErrorLabel

const CREATE_LOBBY_DIALOG = preload("res://scenes/ui/create_lobby_dialog.tscn")
const JOIN_LOBBY_DIALOG   = preload("res://scenes/ui/join_lobby_dialog.tscn")

# Track open dialogs so we never open two at once.
var _active_dialog: Control = null


func _ready() -> void:
	#username_input.max_length = Network.MAX_USERNAME_LENGTH
#
	#Network.lobby_created.connect(_on_lobby_created)
	#Network.lobby_joined.connect(_on_lobby_joined)
	#Network.lobby_join_failed.connect(_on_lobby_join_failed)
	#Network.server_disconnected.connect(_on_server_disconnected)

	error_label.text = ""

	if multiplayer.multiplayer_peer and \
			multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		status_label.text = "Connected to server."
	else:
		status_label.text = "Not connected to server."
		create_lobby_button.disabled = true
		join_lobby_button.disabled   = true


# ─────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────

func _get_username() -> String:
	return username_input.text.strip_edges()


func _validate_username() -> bool:
	var username := _get_username()
	if username.is_empty():
		error_label.text = "Enter a username first."
		return false
	error_label.text = ""
	return true


func _open_dialog(scene: PackedScene) -> Control:
	# Prevent stacking multiple dialogs
	if _active_dialog and is_instance_valid(_active_dialog):
		return null

	var dialog: Control = scene.instantiate()
	dialog.setup(_get_username())

	# Dialogs free themselves on cancel/success; clean up the reference when they do.
	dialog.tree_exited.connect(func() -> void: _active_dialog = null)

	add_child(dialog)
	_active_dialog = dialog
	return dialog


# ─────────────────────────────────────────
#  Signal Handlers
# ─────────────────────────────────────────

func _on_create_lobby_button_pressed() -> void:
	if not _validate_username():
		return
	_open_dialog(CREATE_LOBBY_DIALOG)


func _on_join_lobby_button_pressed() -> void:
	if not _validate_username():
		return
	_open_dialog(JOIN_LOBBY_DIALOG)


func _on_lobby_created(_code: String) -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_lobby_joined(_code: String) -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_lobby_join_failed(reason: String) -> void:
	# The dialog shows this inline; also surface it on the menu for safety.
	error_label.text = reason


func _on_server_disconnected() -> void:
	status_label.text = "Lost connection to server."
	create_lobby_button.disabled = true
	join_lobby_button.disabled   = true

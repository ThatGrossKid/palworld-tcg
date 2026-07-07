extends Control


@onready var lobby_code_input: LineEdit   = %LobbyCodeInput
@onready var join_button: Button          = %JoinButton
@onready var cancel_button: Button        = %CancelButton
@onready var error_label: Label           = %ErrorLabel
@onready var backdrop: ColorRect          = %Backdrop

var _username: String = ""


func _ready() -> void:
	error_label.text = ""
	error_label.visible = false

	lobby_code_input.max_length = Network.LOBBY_CODE_LENGTH

	Network.lobby_joined.connect(_on_lobby_joined)
	Network.lobby_join_failed.connect(_on_lobby_join_failed)

	# Focus the input immediately so the player can start typing
	lobby_code_input.grab_focus()


# Called by main_menu.gd before adding to the scene tree.
func setup(username: String) -> void:
	_username = username


# ─────────────────────────────────────────
#  Internal Helpers
# ─────────────────────────────────────────

func _set_busy(busy: bool) -> void:
	join_button.disabled = busy
	cancel_button.disabled = busy
	lobby_code_input.editable = not busy


func _get_code() -> String:
	return lobby_code_input.text.strip_edges().to_upper()


# ─────────────────────────────────────────
#  Signal Handlers
# ─────────────────────────────────────────

func _on_lobby_code_changed(new_text: String) -> void:
	# Auto-uppercase as the player types
	var upper := new_text.to_upper()
	if upper != new_text:
		lobby_code_input.text = upper
		lobby_code_input.caret_column = upper.length()

	# Clear stale error when the player edits
	error_label.visible = false


func _on_text_submitted(_text: String) -> void:
	_on_join_button_pressed()


func _on_join_button_pressed() -> void:
	error_label.visible = false

	var code := _get_code()
	if code.length() != Network.LOBBY_CODE_LENGTH:
		error_label.text = "Code must be %d characters." % Network.LOBBY_CODE_LENGTH
		error_label.visible = true
		return

	_set_busy(true)
	Network.my_username = _username
	Network.request_join_lobby(code)


func _on_cancel_button_pressed() -> void:
	queue_free()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_cancel_button_pressed()


func _on_lobby_joined(_code: String) -> void:
	queue_free()


func _on_lobby_join_failed(reason: String) -> void:
	error_label.text = reason
	error_label.visible = true
	_set_busy(false)

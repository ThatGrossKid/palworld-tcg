extends Control


@onready var backdrop: ColorRect          = %Backdrop
@onready var max_players_slider: HSlider  = %MaxPlayersSlider
@onready var max_players_value: Label     = %MaxPlayersValue
@onready var create_button: Button        = %CreateButton
@onready var cancel_button: Button        = %CancelButton
@onready var error_label: Label           = %ErrorLabel

# The username is passed in from the main menu (already validated there).
var _username: String = ""


func _ready() -> void:
	error_label.text = ""
	error_label.visible = false

	_on_max_players_slider_value_changed(max_players_slider.value)

	Network.lobby_created.connect(_on_lobby_created)
	Network.lobby_join_failed.connect(_on_lobby_join_failed)


# Called by main_menu.gd before adding to the scene tree.
func setup(username: String) -> void:
	_username = username


# ─────────────────────────────────────────
#  Internal Helpers
# ─────────────────────────────────────────

func _set_busy(busy: bool) -> void:
	create_button.disabled = busy
	cancel_button.disabled = busy
	max_players_slider.editable = not busy


# ─────────────────────────────────────────
#  Signal Handlers
# ─────────────────────────────────────────

func _on_max_players_slider_value_changed(value: float) -> void:
	max_players_value.text = str(int(value))


func _on_create_button_pressed() -> void:
	error_label.visible = false
	_set_busy(true)

	Network.my_username = _username

	# Store settings so the server / GameState can use them later.
	# For now we send them alongside the create request via a dedicated RPC
	# that accepts lobby options. If your Network singleton only has
	# request_create_lobby() with no args, extend it as shown below OR
	# call the extended version directly.
	var max_players: int = int(max_players_slider.value)
	Network.request_create_lobby_with_settings(max_players)


func _on_cancel_button_pressed() -> void:
	queue_free()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_cancel_button_pressed()


func _on_lobby_created(_code: String) -> void:
	# The main menu's own lobby_created handler will change scene;
	# free this dialog so it doesn't linger.
	queue_free()


func _on_lobby_join_failed(reason: String) -> void:
	error_label.text = reason
	error_label.visible = true
	_set_busy(false)

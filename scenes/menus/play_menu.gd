extends Node2D
class_name PlayMenu

@onready var solo_button = $SoloButton
@onready var pvp_button = $PvPButton

var solo:bool = false
var pvp:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("play_button_clicked",_handle_PlayButtonClicked)
	

# Handler connected to SoloButton's "pressed" signal (defined in play_menu.tscn).
func _on_solo_button_pressed() -> void:
	print("Playing Solo Mode")
	EventBus.request_enter_solo_menu()

# Handler connected to PvPButton's "pressed" signal (defined in play_menu.tscn).
func _on_pvp_button_pressed() -> void:
	print("Playing PvP Mode")
	EventBus.request_enter_pvp_menu()


# Existing handler — kept unchanged.
func _handle_PlayButtonClicked() -> void:
	visible = true

# Input handler for backspace/escape to return to main menu.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event.keycode == KEY_BACKSPACE or event.keycode == KEY_ESCAPE):
		print("Returning to Main Menu")
		self.visible=false
		EventBus.request_return_to_main_menu()
		
		# Hide play_menu itself and show PlayMenu in parent TitleScreen.
		visible = false

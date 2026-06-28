extends Node2D
class_name SettingsMenu
signal settings_button_clicked
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("settings_button_clicked",_handle_show_settings)
	settings_button_clicked.connect(_handle_show_settings)

func _handle_show_settings()-> void:
	print("Came through")
	visible = true

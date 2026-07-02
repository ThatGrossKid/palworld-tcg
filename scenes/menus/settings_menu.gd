extends Node2D
class_name SettingsMenu

signal settings_button_clicked
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("settings_button_clicked",_handle_show_settings)
	EventBus.connect("close_settings_menu",_handle_CloseSettingsMenu)
	settings_button_clicked.connect(_handle_show_settings)

func _handle_show_settings()-> void:
	visible = true

func _handle_CloseSettingsMenu()-> void:
	visible=false

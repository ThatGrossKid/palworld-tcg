extends Node2D

signal settings_button_clicked
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.connect("settings_button_clicked",_handle_show_settings)
	settings_button_clicked.connect(_handle_show_settings)

func _handle_show_settings()-> void:
	print("Came through")
	self.visible = true

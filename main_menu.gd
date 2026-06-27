extends Node2D

signal settings_button_clicked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/PlayButton.connect("button_up",_handle_play_button)
	$VBoxContainer/ExitButton.connect("button_up",_handle_exit_button)
	$VBoxContainer/DuelRoomsButton.connect("button_up",_handle_duelroom_button)
	$VBoxContainer/SettingsButton.connect("button_up",_handle_settings_button)
	$VBoxContainer/TutorialButton.connect("button_up",_handle_tutorial_button)
func _exit_tree() -> void:
	pass

func _handle_play_button() -> void:
	pass
	
func _handle_duelroom_button() -> void:
	pass
	
func _handle_tutorial_button() -> void:
	pass
	
func _handle_settings_button() -> void:
	settings_button_clicked.emit()
	
func _handle_exit_button() -> void:
	get_tree().quit()

extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/PlayButton.connect("button_up",_handle_play_button)
	$VBoxContainer/ExitButton.connect("button_up",_handle_exit_button)
	$VBoxContainer/DuelRoomsButton.connect("button_up",_handle_duelroom_button)
	$VBoxContainer/SettingsButton.connect("button_up",_handle_settings_button)
	$VBoxContainer/TutorialButton.connect("button_up",_handle_tutorial_button)
	#get_viewport().size_changed.connect(_update_position)
	_update_position()
	EventBus.connect("return_to_main_menu",_handle_return_to_main_menu)
func _exit_tree() -> void:
	pass

func _handle_return_to_main_menu()-> void:
	self.visible=true

func _handle_play_button() -> void:
	EventBus.request_play_game()
	self.visible = false
	
func _handle_duelroom_button() -> void:
	EventBus.request_duel_rooms()
	
func _handle_tutorial_button() -> void:
	EventBus.request_tutorial()
	
func _handle_settings_button() -> void:
	EventBus.request_settings_menu()
	
func _handle_exit_button() -> void:
	get_tree().quit()
func _update_position() -> void:
	pass
	#var viewport_size = get_viewport_rect().size
	#position = Vector2(viewport_size.x / 2, viewport_size.y)

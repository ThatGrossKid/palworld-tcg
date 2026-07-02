extends Node2D
class_name PlayMenu

@onready var solo_button = $SoloButton
@onready var pvp_button = $PvPButton

var solo:bool = false
var pvp:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.connect("play_button_clicked",_handle_PlayButtonClicked)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
 
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if solo:
				print("Playing Solo Mode")
				#TODO: Switch to Solo Mode
			elif pvp:
				print("Playing PvP Mode")
				#TODO: Switch to PvP Mode

func _handle_PlayButtonClicked() -> void:
	visible = true

func _on_solo_area_button_mouse_entered() -> void:
	solo = true

func _on_solo_area_button_mouse_exited() -> void:
	solo = false

func _on_pvp_area_button_mouse_entered() -> void:
	pvp = true

func _on_pvp_area_button_mouse_exited() -> void:
	pvp = false

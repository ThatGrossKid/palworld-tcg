extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	EventBus.request_hover_over_card(self)


func _on_area_2d_mouse_exited() -> void:
	EventBus.request_stop_hovering_over_card(self)

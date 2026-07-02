extends Node2D
class_name CardManager

var screen_size
var card_being_dragged
var card_is_dragging = false
const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport().size
	EventBus.connect("hovering_over_card", _handle_Hovering)
	EventBus.connect("stop_hovering_over_card", _handle_StopHovering)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),clamp(mouse_pos.y, 0,screen_size.y))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card = raycast_check_for_card()
			if card:
				card_being_dragged=card
				start_drag(card)
		else:
			finish_drag()

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = 1
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null
		
func _handle_Hovering(card)-> void:
	if not card_is_dragging:
		card.scale = Vector2(.25,.25)
		card.z_index= 2
	
func _handle_StopHovering(card)-> void:
	if not card_is_dragging:
		card.scale = Vector2(.2,.2)
		card.z_index= 1
	
func start_drag(card)-> void:
	card.scale = Vector2(.25,.25)
	card_being_dragged = card
	
	
func finish_drag()-> void:
	if not card_being_dragged == null:
		card_being_dragged.scale = Vector2(.2,.2)
	card_being_dragged = null
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
	
func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

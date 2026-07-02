extends Node2D

@export var num_of_souls = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_soul(soul_card)-> void:
	if num_of_souls < 10:
		soul_card.position = self.get_child(num_of_souls).position
		num_of_souls +=1

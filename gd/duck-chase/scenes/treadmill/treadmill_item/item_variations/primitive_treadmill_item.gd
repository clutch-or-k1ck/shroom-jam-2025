extends TreadmillItem


class_name PrimitiveTreadmillItem


@onready var godot_icon := $godot


func get_bounding_rect() -> Rect2:
	return godot_icon.get_rect()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

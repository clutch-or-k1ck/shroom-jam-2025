extends Node2D


class_name TreadmillItem


## override this to return bounding rect of the treadmill item, in local coordinates
func get_bounding_rect() -> Rect2:
	return Rect2()


## spawning other items is not allowed in the vicinity (rect2 in local coordinates)
func get_no_spawn_area() -> Rect2:
	return Rect2()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

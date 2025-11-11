extends TreadmillItem


class_name PrimitiveTreadmillItem

@export var no_spawn_buffer := 0

@onready var treadmill_item_sprite_ := $treadmill_item_sprite


## the primitive treadmill item returns its sprite's bounding rect with scaling applied
func get_bounding_rect() -> Rect2:
	var sprite_rect := treadmill_item_sprite_.get_rect() as Rect2
	return Rect2(Vector2(0., 0.), Vector2(sprite_rect.size.x * self.global_scale.x, sprite_rect.size.y * self.global_scale.y))


## the primitive treadmill item returns its no_spawn_buffer as no_spawn_area
func get_no_spawn_area() -> int:
	return no_spawn_buffer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

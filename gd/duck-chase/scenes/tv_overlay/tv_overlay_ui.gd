extends NinePatchRect

## the duck chase scene
var duck_chase_scene := preload("res://scenes/chase_scene/chase_scene.tscn")
@onready var subviewport := $SubViewport

		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# instantiate the chase scene into the subviewport...
	# var duck_chase_scene_instance := duck_chase_scene.instantiate()
	# subviewport.add_child(duck_chase_scene_instance)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

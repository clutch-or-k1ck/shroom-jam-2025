@tool
extends Node2D

class_name Treadmill


## array of elements that this treadmill is able to spawn
@export var item_types: Array[PackedScene]
## the speed with which treadmill elements are moving to the left
@export var speed: int 

enum eTreadmillSpawnMethod {FillViewport, Random}
@export var spawn_method: eTreadmillSpawnMethod

## how frequently new elements will be spawned on this treadmill (only applies if spawn_method == Random)
@export var random_spawn_rate: float


## here we keep track of all treadmill items currently present on the treadmill
var items: Array[TreadmillItem] = []

## moves all the elements that are currently on the treadmill
func move_treadmill(delta: float) -> void:
	for item in items:
		item.position += Vector2(-1.*speed*delta, 0.)


## despawn elements that have passed beyound the left screen border
func despawn_out_of_bounds_elements() -> void:
	while items.size() > 0 and items[0].position.x + items[0].get_bounding_rect().end.x < 0.:
		remove_child(items[0]) # CAUTION does this truly free the child?
		print('delete an out-of-bounds-item')
		print(items[0].get_bounding_rect().size)
		items.remove_at(0)


## spawns a new treadmill item immediately following the last one, or at the beginning if the treadmill is empty
func stack_new_treadmill_item():
	print('stacking new treadmill item')
	var spawn_at := Vector2(0., 0.) if get_children().size() == 0 else \
		Vector2(items[-1].position.x + items[-1].get_bounding_rect().end.x, 0.)
		
	if get_children().size() > 0:
		print(items[-1].get_bounding_rect().size)
		print(items[-1].get_bounding_rect().end)
		print(items[-1].get_bounding_rect().position)
	
	var new_treadmill_item := item_types[0].instantiate() # TODO how do we select which one to instantiate?
	add_child(new_treadmill_item)
	items.append(new_treadmill_item)
	new_treadmill_item.position = spawn_at


## a function that spawns treadmill elements in accordance with spawn method, called every frame
## for random spawning, spawn with a very low probability every frame
func spawn_treadmill_items(delta: float) -> void:
	if spawn_method == eTreadmillSpawnMethod.FillViewport:
		if items.size() == 0 or \
				items[-1].position.x + items[-1].get_bounding_rect().end.x <= get_viewport_rect().size.x:
			stack_new_treadmill_item()
	else:
		pass # not implemented yet


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# NOTE display one child for visual reference, otherwise modeling is tough
	if Engine.is_editor_hint():
		if self.get_child_count() == 0:
			stack_new_treadmill_item()
	else:
		despawn_out_of_bounds_elements()
		spawn_treadmill_items(delta)
		move_treadmill(delta)

@tool
extends Node2D

class_name Treadmill


## array of elements that this treadmill is able to spawn
@export var item_types: Array[PackedScene]
## the speed with which treadmill elements are moving to the left
@export var global_speed_multiplier: float = 1.

enum eTreadmillSpawnMethod {FillViewport, Random}
@export var spawn_method: eTreadmillSpawnMethod

## probability to spawn a random element (this ticks once per second and only applies if spawn_method == Random)
@export var spawn_probability: float

## this is the node that will contain treadmill items of this treadmill as children
@export var container_node: Node2D = self

## here we keep track of all treadmill items currently present on the treadmill
var items: Array[TreadmillItem] = []

## this is a single item displayed in the editor to get an idea about sizes and scales
var editor_item: TreadmillItem

## moves all the elements that are currently on the treadmill
func move_treadmill(delta: float) -> void:
	for item in items:
		item.position += Vector2(-1. * Globals.get_global_world_speed() * global_speed_multiplier * delta, 0.)


## despawn elements that have passed beyound the left screen border
func despawn_out_of_bounds_elements() -> void:
	## TODO scaling factor will affect get_bounding_rect value in global space...
	while items.size() > 0 and items[0].position.x + items[0].get_bounding_rect().end.x < 0.:
		container_node.remove_child(items[0]) # CAUTION does this truly free the child?
		items.remove_at(0)


## picks a new treadmill item at a given index, instantiates it, adds to children
func create_new_treadmill_item(idx: int) -> TreadmillItem:
	if idx >= item_types.size():
		push_error('no treadmill item type at idx=' + str(idx))
		return null
	
	var new_treadmill_item := item_types[idx].instantiate()
	container_node.add_child(new_treadmill_item)
	items.append(new_treadmill_item)
	return new_treadmill_item


## spawns a new treadmill item immediately following the last one, or at the beginning if the treadmill is empty
func stack_new_treadmill_item() -> TreadmillItem:
	# when stacking, we always only take the first possible type: stacking different types makes no sense
	var new_treadmill_item := create_new_treadmill_item(0)
	# TODO same stuff, scaling
	if new_treadmill_item:
		var spawn_at := Vector2(0., 0.) if items.size() == 1 else \
			Vector2(items[-2].position.x + items[-2].get_bounding_rect().end.x, items[-2].position.y)
		new_treadmill_item.position = spawn_at
		
	return new_treadmill_item


## select a random treadmill item type from collection 
func select_random_treadmill_item_type() -> int:
	return randi_range(0, item_types.size() - 1)


## spawns a treadmill item outside the screen boundaries
func spawn_outside_screen_boundaries() -> void:
	# NOTE spawn a bit further that the screen actually ends
	var spawn_at := Vector2(get_viewport_rect().size.x * 1.1, 0.)

	# is there a treadmill item that prohibits spawning due to its no-spawn area?
	if not items.is_empty():
		if spawn_at.x <= items[-1].position.x + items[-1].get_bounding_rect().end.x + items[-1].get_no_spawn_area():
			return

	var new_treadmill_item := create_new_treadmill_item(select_random_treadmill_item_type())
	new_treadmill_item.position = spawn_at

## a function that spawns treadmill elements in accordance with spawn method, called every frame
## for random spawning, spawn with a very low probability every frame
func fill_with_treadmill_items() -> void:
	if items.size() == 0 or \
			items[-1].position.x + items[-1].get_bounding_rect().end.x <= get_viewport_rect().size.x:
		stack_new_treadmill_item()


## spawn something or not (ticks every second)
func spawn_loop() -> void:
	while true:
		await get_tree().create_timer(1.).timeout
		if randf() < spawn_probability:
			spawn_outside_screen_boundaries()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint() and spawn_method == eTreadmillSpawnMethod.Random:
		spawn_loop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# NOTE display one child for visual reference, otherwise modeling is tough
	if Engine.is_editor_hint():
		if editor_item == null and self.item_types.size() > 0 and self.item_types[0] != null:
			editor_item = stack_new_treadmill_item()
	else:
		despawn_out_of_bounds_elements()
		if spawn_method == eTreadmillSpawnMethod.FillViewport:
			fill_with_treadmill_items()
		move_treadmill(delta)

@tool
extends Node2D

class_name Treadmill


@export_category('General')
## array of elements that this treadmill is able to spawn
@export var item_types: Array[PackedScene]
## the speed with which treadmill elements are moving to the left
@export var global_speed_multiplier: float = 1.

enum eTreadmillSpawnMethod {FillViewport, Random}
@export var spawn_method: eTreadmillSpawnMethod

## probability to spawn a random element (this ticks once per second and only applies if spawn_method == Random)
@export var spawn_probability: float

## randomization (random displacement and scaling)
@export_category('Randomization')

## whether to apply random scaling or not
@export var apply_random_scaling := false
## min scaling when applying random scaling to elements spawned
@export var random_scale_min := 1.
## max scaling when applying random scaling to elements spawned
@export var random_scale_max := 1.

## whether to apply random displacement or not
@export var apply_random_displacement := false
## minimum x and minimum y for the random displacement
@export var random_displacement_min: Vector2
## maximum x and maximum y for the random displacement
@export var random_displacement_max: Vector2

## pre-spawn will perform some spawning in the _on_ready
@export_category('Prespawn')
@export var enable_prespawn := false
## the probability whether to spawn or not will be sampled this many times
@export var prespawn_samples := 20
## probability on each random toss
@export var prespawn_probability := 0.05

## here we keep track of all treadmill items currently present on the treadmill
var items: Array[TreadmillItem] = []

## this is a single item displayed in the editor to get an idea about sizes and scales
var editor_item: TreadmillItem

## treadmill will be spawning items only if this is true
var active := true

## moves all the elements that are currently on the treadmill
func move_treadmill(delta: float) -> void:
	for item in items:
		item.position += Vector2(-1. * Globals.get_global_world_speed() * global_speed_multiplier * delta, 0.)


## despawn elements that have passed beyound the left screen border
func despawn_out_of_bounds_elements() -> void:
	## TODO scaling factor will affect get_bounding_rect value in global space...
	while items.size() > 0 and items[0].position.x + items[0].get_bounding_rect().end.x < 0.:
		self.remove_child(items[0]) # CAUTION does this truly free the child?
		items.remove_at(0)


## picks a new treadmill item at a given index, instantiates it, adds to children
func create_new_treadmill_item(idx: int) -> TreadmillItem:
	if idx >= item_types.size():
		push_error('no treadmill item type at idx=' + str(idx))
		return null
	
	var new_treadmill_item := item_types[idx].instantiate()
	self.add_child(new_treadmill_item)
	items.append(new_treadmill_item)
	
	# apply random scaling if required
	if apply_random_scaling:
		var random_scaling_factor: float
		if is_equal_approx(random_scale_min, random_scale_max):
			random_scaling_factor = random_scale_min
		else:
			random_scaling_factor = randf_range(random_scale_min, random_scale_max)
			
		(new_treadmill_item as TreadmillItem).scale *= random_scaling_factor
		
	return new_treadmill_item


enum eTargetPositionResolutionMethod {SnapToLast, OutsideScreenBoundaries, FixedPosition}
## finds a position for a new treamill item following the spawn method and applying randomization
## returns true if no no-spawn-area was overlapped (only valid if check_no_spawn_overlaps == true)
func resolve_position(method: eTargetPositionResolutionMethod, fixed_position: Vector2 = Vector2(0., 0.)) -> Vector2:
	var spawn_at: Vector2
	match method:
		eTargetPositionResolutionMethod.SnapToLast:
			# NOTE snap to last item if present, otherwise spawn at root
			spawn_at = Vector2(0., 0.) if items.size() == 1 else \
				Vector2(items[-2].position.x + items[-2].get_bounding_rect().end.x, items[-2].position.y)
		eTargetPositionResolutionMethod.OutsideScreenBoundaries:
			# NOTE spawn a bit further than the screen boundary
			spawn_at = Vector2(get_viewport_rect().size.x * 1.1, 0.)
		eTargetPositionResolutionMethod.FixedPosition:
			spawn_at = fixed_position
			
	# apply random displacement next
	var random_x := random_displacement_min.x if is_equal_approx(
			random_displacement_min.x, random_displacement_max.x
		) else randf_range(random_displacement_min.x, random_displacement_max.x)
	var random_y := random_displacement_min.y if is_equal_approx(
			random_displacement_min.y, random_displacement_max.y
		) else randf_range(random_displacement_min.y, random_displacement_max.y)
		
	return spawn_at + Vector2(random_x, random_y)


## spawns a new treadmill item immediately following the last one, or at the beginning if the treadmill is empty
func stack_new_treadmill_item() -> TreadmillItem:
	# when stacking, we always only take the first possible type: stacking different types makes no sense
	var new_treadmill_item := create_new_treadmill_item(0)
	if new_treadmill_item:
		new_treadmill_item.position = resolve_position(eTargetPositionResolutionMethod.SnapToLast)
	return new_treadmill_item


## select a random treadmill item type from collection 
func select_random_treadmill_item_type() -> int:
	return randi_range(0, item_types.size() - 1) # TODO more interesting selection methods?


func is_overlapping_no_spawn_areas(position: Vector2) -> bool:
	# is there a treadmill item that prohibits spawning due to its no-spawn area?
	if not items.is_empty():
		if position.x <= items[-1].position.x + items[-1].get_bounding_rect().end.x + items[-1].get_no_spawn_area():
			return true
	return false


## spawns a treadmill item outside the screen boundaries
func spawn_outside_screen_boundaries() -> void:
	var spawn_at := resolve_position(eTargetPositionResolutionMethod.OutsideScreenBoundaries)
	if is_overlapping_no_spawn_areas(spawn_at):
		return
	var new_treadmill_item := create_new_treadmill_item(select_random_treadmill_item_type())
	new_treadmill_item.position = spawn_at


## performs one-time spawning of items accross the screen space
func prespawn() -> void:
	for i in range(prespawn_samples):
		var do_spawn := randf() <= prespawn_probability
		if not do_spawn:
			continue
			
		# the x-coordinate for the spawn is found as fraction of the screen x for this sample
		var x_coord := get_viewport_rect().size.x * (i * 1.) / prespawn_samples
		
		var spawn_at := resolve_position(
			eTargetPositionResolutionMethod.FixedPosition,
			Vector2(x_coord, 0.)
		)
		
		if is_overlapping_no_spawn_areas(spawn_at):
			continue
		
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
		if randf() < spawn_probability and active:
			spawn_outside_screen_boundaries()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint() and spawn_method == eTreadmillSpawnMethod.Random:
		spawn_loop()
		
	if not Engine.is_editor_hint() and enable_prespawn:
		prespawn()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# NOTE display one child for visual reference, otherwise modeling is tough
	if Engine.is_editor_hint():
		if editor_item == null and self.item_types.size() > 0 and self.item_types[0] != null:
			editor_item = stack_new_treadmill_item()
	else:
		despawn_out_of_bounds_elements()
		if spawn_method == eTreadmillSpawnMethod.FillViewport and active:
			fill_with_treadmill_items()
		move_treadmill(delta)

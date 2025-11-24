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

## treadmills belonging to one group act as one when it comes to no-spawn areas
@export var treadmill_group := -1

## if this treadmill spawns something or is 'sleeping' when it enters the node tree
@export var start_active := true

# CAUTION this is not implemented for FillWorld spawn type, only random spawn
## if true, this treadmill does not rely on world speed and lives its own life instead
@export var use_own_speed := false

## if using its own speed, than what speed
@export var own_speed: float

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

@export_category('Spawn')
## items will be spawned this many pixels BEFORE the screen boundary
@export var spawn_buffer := 300.
## items will be despawned this many pixels AFTER the screen boundary
@export var despawn_buffer := 500.

## pre-spawn will perform some spawning in the _on_ready
@export_category('Prespawn')
@export var enable_prespawn := false
## the probability whether to spawn or not will be sampled this many times
@export var prespawn_samples := 20
## probability on each random toss
@export var prespawn_probability := 0.05

## called on per-frame basis, defines if this treadmill should be active or not
# NOTE this is checked AFTER active is checked: so, if active is false, activation condition is not even called
var activation_condition: Callable = Callable()


# this is a helper class that defines a infinite subsection of 2d space, defined by a line and a normal vector
class HalfPlane2D:
	var distance: Vector2
	var normal: Vector2
	
	func _init(arbitrary_point: Vector2, normal: Vector2):
		distance = arbitrary_point
		self.normal = normal
		
	func contains(point: Vector2) -> bool:
		return (point - distance).dot(normal) >= 0
		
	func encloses(rect: Rect2) -> bool:
		return contains(rect.position) and contains(rect.end)


enum eTreadmillDirection {LEFT, RIGHT} # TODO UP and DOWN must be added in future


func get_treadmill_direction() -> eTreadmillDirection:
	if use_own_speed:
		return eTreadmillDirection.RIGHT if own_speed >= 0. else eTreadmillDirection.LEFT
	else:
		return eTreadmillDirection.RIGHT if Globals.get_global_world_speed() < 0. else eTreadmillDirection.LEFT # TODO we create a hard dependency on Globals of this particular project - that is wrong


#region Adding item types at runtime!

## you should use this dictionary to push item types to spawn at runtime
var _dynamic_item_types: Dictionary[String, PackedScene]

func start_spawning(id: String, scene: PackedScene) -> void:
	_dynamic_item_types[id] = scene


func stop_spawning(id: String) -> void:
	_dynamic_item_types.erase(id)


## this returns both editor-defined treadmill item types and item types added at runtime
func get_item_types_for_spawn() -> Array[PackedScene]:
	var return_value: Array[PackedScene] = []
	return_value.append_array(item_types)
	for key in _dynamic_item_types:
		return_value.append(_dynamic_item_types[key])
	return return_value


#endregion

## here we keep track of all treadmill items currently present on the treadmill
var items: Array[TreadmillItem] = []

## this is a single item displayed in the editor to get an idea about sizes and scales
var editor_item: TreadmillItem

## treadmill will be spawning items only if this is true
var active: bool

## moves all the elements that are currently on the treadmill
func move_treadmill(delta: float) -> void:
	for item in items:
		if use_own_speed:
			item.position += Vector2(own_speed * delta, 0.)
		else:
			item.position += Vector2(-1. * Globals.get_global_world_speed() * global_speed_multiplier * delta, 0.)


## returns the kill zone as rectangle
func get_kill_zone() -> HalfPlane2D:
	if get_treadmill_direction() == eTreadmillDirection.RIGHT:
		return HalfPlane2D.new(
			Vector2(get_viewport_rect().size.x + despawn_buffer, 0.),
			Vector2(1., 0.)
		)
	else:
		return HalfPlane2D.new(
			Vector2(-despawn_buffer, 0.),
			Vector2(-1., 0.)
		)


## return global bounds of the treadmill item
func get_global_bounds(item: TreadmillItem) -> Rect2:
	var local_bounds := item.get_bounding_rect()
	var item_scale := item.global_scale
	var global_bounds := Rect2(
		Vector2(
			local_bounds.position.x * item_scale.x,
			local_bounds.position.y * item_scale.y
		),
		Vector2(
			local_bounds.size.x * item_scale.x,
			local_bounds.size.y * item_scale.y
		)
	)
	
	# finally, add item's position making this a positioned rect
	return Rect2(
		global_bounds.position + item.position,
		global_bounds.size
	)


## for a given item, returns whether this should be despawned
func should_despawn(item: TreadmillItem) -> bool:
	return get_kill_zone().encloses(get_global_bounds(item))


## despawn elements that have passed beyound the left screen border
func despawn_out_of_bounds_elements() -> void:
	while items.size() > 0 and should_despawn(items[0]):
		self.remove_child(items[0])
		items.remove_at(0)


## removes all the items currently present on this treadmill
func clear() -> void:
	while self.get_children().size() > 0:
		self.remove_child(self.get_children()[0])


## picks a new treadmill item at a given index, instantiates it, adds to children
func create_new_treadmill_item(idx: int) -> TreadmillItem:
	var _all_item_types := get_item_types_for_spawn()
	
	if idx >= _all_item_types.size():
		push_error('no treadmill item type at idx=' + str(idx))
		return null
	
	var new_treadmill_item := _all_item_types[idx].instantiate()
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


func get_out_of_screen_boundaries_spawn_point() -> Vector2:
	if get_treadmill_direction() == eTreadmillDirection.RIGHT:
		return Vector2(-spawn_buffer, 0.)
	else:
		return Vector2(get_viewport_rect().size.x + spawn_buffer, 0.)


enum eTargetPositionResolutionMethod {SnapToLast, OutsideScreenBoundaries, FixedPosition}
## finds a position for a new treamill item following the spawn method and applying randomization
## returns true if no no-spawn-area was overlapped (only valid if check_no_spawn_overlaps == true)
func resolve_position(method: eTargetPositionResolutionMethod, fixed_position: Vector2 = Vector2(0., 0.)) -> Vector2:
	var spawn_at: Vector2
	match method:
		eTargetPositionResolutionMethod.SnapToLast:
			# NOTE snap to last item if present, otherwise spawn at root
			spawn_at = Vector2(0., 0.) if items.size() == 1 else \
				Vector2(get_global_bounds(items[-2]).end.x, items[-2].position.y)
		eTargetPositionResolutionMethod.OutsideScreenBoundaries:
			spawn_at = get_out_of_screen_boundaries_spawn_point()
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
	return randi_range(0, get_item_types_for_spawn().size() - 1) # TODO more interesting selection methods?


## returns the area which will result in spawn conflicts/overlaps if spawned within or null if no such area exists
func get_spawn_conflict_zone(treadmill: Treadmill) -> HalfPlane2D:
	if treadmill.items.is_empty():
		return null
		
	var treadmill_newest := treadmill.items[-1]
	if get_treadmill_direction() == eTreadmillDirection.RIGHT: # moving RIGHT, no-spawn buffer extends to the LEFT, spawn conflicts arise to the RIGHT
		return HalfPlane2D.new(
			Vector2(get_global_bounds(treadmill_newest).position.x - treadmill_newest.get_no_spawn_area(), 0.),
			Vector2(1., 0) # spawning conflicts to the right of the line
		)
	else: # moving LEFT, no-spawn buffer extends to the RIGHT, spawn conflicts arise to the LEFT
		return HalfPlane2D.new(
			Vector2(get_global_bounds(treadmill_newest).end.x + treadmill_newest.get_no_spawn_area(), 0.),
			Vector2(-1., 0.)
		)


func is_overlapping_no_spawn_areas(position: Vector2) -> bool:
	# is there a treadmill item that prohibits spawning due to its no-spawn area?
	# NOTE we check this for all treadmills in the group
	var treadmills_to_check := Globals.get_all_treadmills_in_group(treadmill_group) if \
		treadmill_group != -1 else [self]
		
	for treadmill in treadmills_to_check:
		var spawn_conflict_zone := get_spawn_conflict_zone(treadmill)
		if spawn_conflict_zone != null and spawn_conflict_zone.contains(position):
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
			get_global_bounds(items[-1]).end.x <= get_viewport_rect().size.x:
		stack_new_treadmill_item()


## we test if to randomly spawn every frame with this function
func per_frame_outside_screen_boundaries_random_spawn(delta: float) -> void:
	var per_frame_probability := spawn_probability * delta # NOTE this is incorrect from probability theory standpoint but maybe?
	if randf() < per_frame_probability:
		spawn_outside_screen_boundaries()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not Engine.is_editor_hint() and enable_prespawn:
		prespawn()
	if not Engine.is_editor_hint() and treadmill_group != -1:
		Globals.add_treadmill_to_group(self, treadmill_group)
	if not Engine.is_editor_hint():
		active = self.start_active


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# NOTE display one child for visual reference, otherwise modeling is tough
	if Engine.is_editor_hint():
		if editor_item == null and self.item_types.size() > 0 and self.item_types[0] != null:
			editor_item = stack_new_treadmill_item()
	else:
		despawn_out_of_bounds_elements()
			
		if active and (activation_condition.is_null() or activation_condition.call() == true): # spawn items
			if spawn_method == eTreadmillSpawnMethod.FillViewport:
				fill_with_treadmill_items()
			else:
				per_frame_outside_screen_boundaries_random_spawn(delta)
		move_treadmill(delta)

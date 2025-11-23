extends Node


var _global_world_speed: float

# NOTE treadmills belonging to one grou act as one when it comes to checking no-spawn areas
# this can be useful when two different treadmill groups at different locations should not spawn overlapping items
var _treadmill_groups: Dictionary[int, Array]


enum eGamePhase {Menu, GameLoop}
var game_phase: eGamePhase


func add_treadmill_to_group(treadmill: Treadmill, group: int) -> void:
	if group not in _treadmill_groups:
		_treadmill_groups[group] = []
	_treadmill_groups[group].append(treadmill)


func get_all_treadmills_in_group(group: int) -> Array:
	return _treadmill_groups[group] if group in _treadmill_groups else []


func set_global_world_speed(new_speed: float) -> void:
	_global_world_speed = new_speed


func get_global_world_speed() -> float:
	return _global_world_speed


func get_chase_scene() -> ChaseScene:
	return get_tree().root.find_child('chase_scene_root', true, false) as ChaseScene

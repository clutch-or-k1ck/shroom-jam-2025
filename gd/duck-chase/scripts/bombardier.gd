extends Node2D
class_name Bombardier

"""
NOTE bomb throwing pattern is just a dictionary that defines when and where to spawn bombs
its keys are times (starts at 0.) when to spawn the bombs
each key is an array of positions where to spawn bombs, as ratios of screen width
the bomb spawner first spawns the shadow of the bomb (if available), then it spawns the bomb with delay
the bomb is always spawned right outside the screen boundary
"""

## this bomb will be spawned by the bombardier
@export var bomb_spawnable: PackedScene

## this thing will be spawned as shadow for the falling bomb
@export var shadow_spawnable: PackedScene

## bombs will be spawned this many seconds after the shadow had spawned
@export var bomb_spawn_delay: float

## bombs will be spawned at this initial velocity, then normal gravity will be applied
@export var initial_bomb_velocity: float

## this sfx will be played when the new bombing starts
@export var sfx: Resource


## when bombardment is finished
signal bombardment_finished


var _elapsed_bombing_time := 0.
var _active_pattern: Dictionary = {}


func do_spawn(locations: Array) -> void:
	for location_ratio in locations:
		var global_loc = get_viewport_rect().size.x * location_ratio
		print('spawning shadows at location: ' + str(location_ratio) + ', elapsed time is ' + str(_elapsed_bombing_time))
	
	await get_tree().create_timer(bomb_spawn_delay).timeout	
	for location_ratio in locations:
		print('spawning bombs at locations ' + str(location_ratio) + ', elapsed time is ' + str(_elapsed_bombing_time))


## every tick, check if there are bombs to throw
func _process(delta: float) -> void:
	if not _active_pattern.is_empty():
		for throwing_instant in _active_pattern:
			if _elapsed_bombing_time >= throwing_instant:
				do_spawn(_active_pattern[throwing_instant])
				_active_pattern.erase(throwing_instant)
		if _active_pattern.is_empty(): # NOTE means we just finished bombing
			bombardment_finished.emit()

	_elapsed_bombing_time += delta

## throw bombs following a pattern
func throw_bombs(pattern: Dictionary, initial_delay: float = 0.) -> void:
	_elapsed_bombing_time = -initial_delay
	_active_pattern = pattern

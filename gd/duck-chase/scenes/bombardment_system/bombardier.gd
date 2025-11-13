extends Node2D
class_name Bombardier

"""
NOTE bomb throwing pattern is just a dictionary that defines when and where to spawn bombs
its keys are times (starts at 0.) when to spawn the bombs
each key is an array of positions where to spawn bombs, as ratios of screen width
the bomb spawner first spawns the shadow of the bomb (if available), then it spawns the bomb with delay
the bomb is always spawned right outside the screen boundary
"""

## this sfx will be played when the new bombing starts
@export var sfx: Resource


## when bombardment is finished
signal bombardment_finished


var _elapsed_bombing_time := 0.
var _active_pattern: Dictionary = {}

@onready var bomb_drop_scene := preload('res://scenes/bombardment_system/bomb_drop.tscn')


func do_spawn(locations: Array) -> void:
	for location_ratio in locations:
		var global_loc_x = get_viewport_rect().size.x * location_ratio
		var new_bomb_drop := bomb_drop_scene.instantiate()
		add_child(new_bomb_drop)
		new_bomb_drop.position = Vector2(global_loc_x, 0.)


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

extends Node2D
class_name BombDrop

'''
this class represents a location where a bomb will be dropped
it renders a growing shadow and then drops the bomb
'''

## within this period, the shadow will grow. after elapsed, the bomb will drop
## this is NOT allowed to be zero, we always have a delay
@export var drop_delay := 1.

## bombs will be spawned right above the screen with this impulse applied
@export var initial_vertical_impulse := -100.

@onready var shadow_sprite := $shadow_sprite

@onready var bomb_scene := preload('res://scenes/bombardment_system/bomb.tscn')

## of the drop delay, how much had already elapsed
var drop_delay_time_elapsed := 0.

# HACK keep track of the sprite scale set via editor
var reference_scale: Vector2

## destroy self when child bomb exploded
func handle_child_bomb_explosion() -> void:
	shadow_sprite.visible = false
	
	# NOTE we free the bomb drop with a delay to let all vfs play to end
	await get_tree().create_timer(1.5).timeout
	self.queue_free()


## spawns the bomb outside screen y-boundaries
func drop_bomb() -> void:
	# spawn a new bomb outside screen y-boundaries
	var bomb := bomb_scene.instantiate() as RigidBody2D
	add_child(bomb)
	bomb.global_position = Vector2(self.position.x, -30.)
	
	# connect to 'exploded' signal of the bomb
	bomb.exploded.connect(self.handle_child_bomb_explosion)
	
	# apply initial impulse to speed it up
	# bomb.apply_impulse(Vector2(0, initial_vertical_impulse))
	bomb.linear_velocity = Vector2(0, initial_vertical_impulse)


func _process(delta: float) -> void:
	if drop_delay_time_elapsed < drop_delay:
		drop_delay_time_elapsed += delta
		# grow the shadow
		var scale_interp := drop_delay_time_elapsed / drop_delay
		shadow_sprite.scale = Vector2(reference_scale.x * scale_interp, reference_scale.y * scale_interp)
		
		if drop_delay_time_elapsed > drop_delay:
			drop_bomb()

func _ready() -> void:
	reference_scale = shadow_sprite.scale
	shadow_sprite.scale = Vector2(0., 0.)

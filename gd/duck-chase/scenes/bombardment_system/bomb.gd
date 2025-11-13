extends RigidBody2D
class_name Bomb


signal exploded


@onready var explosion_anim := $explosion_anim
@onready var bomb_sprite := $bomb_sprite


func _ready() -> void:
	explosion_anim.visible = false


## explosion vfx + hiding visible bomb body
func do_explode() -> void:
	bomb_sprite.visible = false
	explosion_anim.visible = true
	explosion_anim.play('explosion3')


func _on_body_entered(body: Node) -> void:
	if body is MrDuck:
		body.lose_life()
	do_explode()
	exploded.emit()

## when the explosion vfs finishes, we can simply destroy the whole thing
func _on_explosion_anim_animation_finished() -> void:
	self.queue_free()

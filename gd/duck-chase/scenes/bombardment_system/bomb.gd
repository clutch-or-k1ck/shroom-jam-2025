extends RigidBody2D
class_name Bomb


signal exploded


@onready var explosion_anim := $explosion_anim
@onready var bomb_sprite := $bomb_sprite
@onready var explosion_sfx := $explosion_sfx
@onready var hit_box := $hit_box

func _ready() -> void:
	explosion_anim.visible = false


## explosion vfx + hiding visible bomb body
func do_explode() -> void:
	# hide bomb body and deactivate the whole rigid body including collision
	bomb_sprite.visible = false
	hit_box.set_deferred('disabled', true)
	set_deferred('freeze', true)
	
	# play vfx and sfx, destroy when sfx finishes
	explosion_anim.visible = true
	explosion_anim.play('explosion3')
	explosion_sfx.play()
	explosion_sfx.finished.connect(queue_free)


func _on_body_entered(body: Node) -> void:
	if body is Bomb: # HACK this probably should be done via collision layers: do not collide with other bombs
		return
	if body is MrDuck:
		body.lose_life()
	do_explode()
	exploded.emit()


func _on_explosion_anim_animation_finished() -> void:
	explosion_anim.visible = false

@tool
extends TreadmillItem
class_name TreadmillComposite


@onready var hit_vfx = preload('res://assets/explosions/hit_vfx.tscn')

## one charge allows to deal damage (or restore HP) once
## this is mainly for avoiding situations where several hit areas of a single obstacle deal extra damage
var charges := 1

## number of pixels where no additional items are allowed to spawn
@export var no_spawn_buffer: int

## whether this composite group deals damage when mr duck collides
@export var deals_damage := false

## number of lives this group takes if duck collides with it
@export var damage_dealt: int

## if this item can heal the duck
@export var restores_life := false


# --------------

@onready var hitbox := $hitbox


## returns boundaries of this treadmill item in local coordinates
func get_bounding_rect() -> Rect2:
	return Rect2($bbox_start.position, $bbox_end.position - $bbox_start.position)


func get_no_spawn_area() -> int:
	return no_spawn_buffer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if deals_damage or restores_life:
		hitbox.monitoring = true
	else:
		hitbox.monitoring = false


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		self.queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint():
		# an improved preview rect
		var preview_rect := Rect2($bbox_start.position, $bbox_end.position - $bbox_start.position)
		draw_rect(preview_rect, Color(0., 1., 0.), false)


## deal damage if this composite group is supposed to deal damage
func _on_hitbox_body_entered(body: Node2D) -> void:
	if deals_damage and body is MrDuck:
		(body as MrDuck).lose_life() # TODO lose as many lives as damage dealt by the thing
	if restores_life and body is MrDuck:
		(body as MrDuck).get_life()
		self.visible = false


func _on_hitbox_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	# only do something if we have charges
	if charges <= 0:
		return
		
	if body is MrDuck:
		charges -= 1
		if deals_damage and not body.is_invincible():
			body.lose_life()
			
			# TODO spawn the hit vfx at the hit location
			var shape_owner_id = body.shape_find_owner(body_shape_index)
			var shape_owner = body.shape_owner_get_owner(shape_owner_id)
			shape_owner.add_child(hit_vfx.instantiate())
		elif restores_life:
			body.get_life()
			self.visible = false # we usually want to hide power-up items that restore health

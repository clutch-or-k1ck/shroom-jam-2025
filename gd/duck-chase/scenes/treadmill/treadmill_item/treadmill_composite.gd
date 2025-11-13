@tool
extends TreadmillItem
class_name TreadmillComposite

var bounds_: Vector2
## define bounds of this treadmill group (used to define the group's bbox in global coords)
@export var bounds: Vector2:
	set(vec):
		bounds_ = vec
		queue_redraw()
	get:
		return bounds_

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


## returns the bounding rectangle defined by bounds in local coordinates
func get_bounding_rect_local() -> Rect2:
	return Rect2(Vector2(0., 0.), Vector2(bounds_.x, -bounds.y))


## returns the bounding rectangle defined by bounds in global coordinates
func get_bounding_rect() -> Rect2:
	var bounding_rect_local = get_bounding_rect_local()
	var bounding_rect_global = Rect2(
		Vector2(0., 0.),
		Vector2(
			bounding_rect_local.size.x * self.global_scale.x,
			bounding_rect_local.size.y * self.global_scale.y
		)
	)
	return bounding_rect_global


func get_no_spawn_area() -> int:
	return no_spawn_buffer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if deals_damage or restores_life:
		hitbox.monitoring = true
	else:
		hitbox.monitoring = false


func _draw() -> void:
	if Engine.is_editor_hint():
		var preview_rect := Rect2(Vector2(0., 0.), Vector2(bounds_.x, -bounds_.y))
		draw_rect(preview_rect, Color(1., 0., 0.), false)


## deal damage if this composite group is supposed to deal damage
func _on_hitbox_body_entered(body: Node2D) -> void:
	if deals_damage and body is MrDuck:
		(body as MrDuck).lose_life() # TODO lose as many lives as damage dealt by the thing
	if restores_life and body is MrDuck:
		(body as MrDuck).get_life()
		self.visible = false

extends PrimitiveTreadmillItem


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_damage_box_body_entered(body: Node2D) -> void:
	if body is MrDuck:
		body.lose_life()

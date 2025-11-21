extends AnimatedSprite2D

func _ready() -> void:
	play('explosion2', 4.)


func _on_animation_finished() -> void:
	self.queue_free()

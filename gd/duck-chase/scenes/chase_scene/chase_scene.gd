extends Node2D


@onready var running_text := $ui/running_text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	running_text.add_new_running_text_line()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

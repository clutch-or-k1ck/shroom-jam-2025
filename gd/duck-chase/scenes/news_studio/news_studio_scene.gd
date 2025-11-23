extends CanvasLayer
class_name NewsIntro


signal any_input_pressed

@onready var running_text := $runningTextRoot
@onready var press_anything_label := $label_container


func _ready() -> void:
	running_text.add_new_running_text_line()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(press_anything_label, 'scale', Vector2(1.07, 1.07), 0.3)
	tween.tween_property(press_anything_label, 'scale', Vector2(1., 1.), 0.3)
	tween.set_loops()


func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		any_input_pressed.emit()

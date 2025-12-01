extends CanvasLayer
class_name NewsIntro


signal any_input_pressed

@onready var running_text := $runningTextRoot
@onready var press_anything_label := $label_container


func _ready() -> void:
	running_text.add_new_running_text_line()
	press_anything_label.visible = false
	
	# play the breaking news intro immediately
	$breaking_news_intro_music.play()
	
	# play the game loop after breaking news intro is close to its end
	var timer := get_tree().create_timer(4.5)
	timer.timeout.connect(play_news_background_loop)
	timer.timeout.connect(show_press_anything_label)


func show_press_anything_label():
	press_anything_label.visible = true
	
	# animation of 'Press Anything to Start' label
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(press_anything_label, 'scale', Vector2(1.07, 1.07), 0.3)
	tween.tween_property(press_anything_label, 'scale', Vector2(1., 1.), 0.3)
	tween.set_loops()


func play_news_background_loop():
	$news_background_loop.volume_linear = 0.
	$news_background_loop.play()
	
	var sound_fade_in_tween := create_tween()
	sound_fade_in_tween.tween_property($news_background_loop, 'volume_linear', 0.25, 2.5)


func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		any_input_pressed.emit()

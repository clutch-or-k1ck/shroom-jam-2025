extends Control
class_name GameScoreWidget


@onready var left_star := $vertical_layout/score_widget/left_star_anchor/star_left
@onready var right_star := $vertical_layout/score_widget/right_star_anchor/star_right
@onready var best_score_label := $vertical_layout/best_score_label_anchor/best_score_label
@onready var score_label := $vertical_layout/score_widget/score_text

## whether the score displayed is the best game score so far
var _is_best_result := false
var is_best_result: bool:
	set(val):
		if val:
			best_score_label.visible = true
		else:
			best_score_label.visible = false
		_is_best_result = val
	get:
		return _is_best_result
		
const shake_distance := 4.
const shake_freq := 0.05

## should the widget shake or not
var _shake := false
var shake: bool:
	set(val):
		if val != _shake:
			if val:
				_shake_loop()
			else:
				_stop_shake()
		_shake = val
	get:
		return _shake

var _score := 0
var score: int:
	set(val):
		_score = val
		score_label.text = str(_score)
	get:
		return _score
		
var shaking_tweens := [null, null, null]


## shake a certain node once and return the tween associated with the shake
func _shake_once(node: Node) -> Tween:
	var tween := node.create_tween()
	for i in range(20):
		tween.tween_property(
			node, 'position',
			Vector2(
				randf_range(-shake_distance, shake_distance),
				randf_range(-shake_distance, shake_distance)
			), shake_freq
		)
	return tween


## widget shake
func _shake_loop() -> void:
	shaking_tweens[0] = _shake_once(left_star)
	shaking_tweens[1] = _shake_once(right_star)
	shaking_tweens[2] = _shake_once(best_score_label)
	
	shaking_tweens[0].finished.connect(_shake_loop)


func _stop_shake() -> void:
	for i in range(shaking_tweens.size()):
		var shaking_tween := shaking_tweens[i] as Tween
		if shaking_tween != null and shaking_tween.is_valid():
			shaking_tween.kill()
		shaking_tweens[i] = null


func _ready() -> void:
	is_best_result = false

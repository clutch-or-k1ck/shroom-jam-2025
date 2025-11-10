extends NinePatchRect

## the duck chase scene
var duck_chase_scene := preload("res://scenes/chase_scene/chase_scene.tscn")
@onready var subviewport := $SubViewport


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# instantiate the chase scene into the subviewport...
	# var duck_chase_scene_instance := duck_chase_scene.instantiate()
	# subviewport.add_child(duck_chase_scene_instance)
	pass


func draw_vertical_line(at: int) -> void:
	draw_line(Vector2(at, -10000), Vector2(at, 10000), Color(1., 0., 0.))


func draw_horizontal_line(at: int) -> void:
	draw_line(Vector2(-10000, at), Vector2(10000, at), Color(1., 0., 0.))


func _draw() -> void:
	# specify the thickness of the tvset panels
	const top_width := 130
	const bottom_width := 120
	const left_width := 150
	const right_width := 550
	
	# how much the GUI is downscaled due to stretching
	var stretch_factor := get_window().get_stretch_transform().get_scale()[0]
	
	var left_v := left_width * stretch_factor
	var right_v := get_viewport_rect().size[0] - right_width * stretch_factor
	var top_h := top_width * stretch_factor
	var bottom_h := get_viewport_rect().size[1] - bottom_width * stretch_factor
	
	draw_vertical_line(left_v)
	draw_vertical_line(right_v)
	draw_horizontal_line(top_h)
	draw_horizontal_line(bottom_h)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(get_window().get_stretch_transform().get_scale())

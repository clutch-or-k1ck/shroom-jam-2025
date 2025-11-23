extends NinePatchRect

'''
this is the game root, containing the tv box and shaders
it is also responsible for switching scenes
'''

var news_scene := preload('res://scenes/news_studio/news_studio_scene.tscn')
var chase_scene := preload('res://scenes/chase_scene/chase_scene.tscn')
@onready var subviewport := $SubViewportContainer/SubViewport


func load_chase_scene() -> void:
	subviewport.remove_child(subviewport.get_children()[0])
	subviewport.add_child(chase_scene.instantiate())


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var news_intro := news_scene.instantiate() as NewsIntro
	subviewport.add_child(news_intro)
	news_intro.any_input_pressed.connect(load_chase_scene)

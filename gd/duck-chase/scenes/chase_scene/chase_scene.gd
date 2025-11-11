extends Node2D


@onready var running_text := $ui/running_text
@onready var duck := $duck_character
@onready var stam_bar := $ui/top_left_widget/stam_bar
@onready var hearts_box := $ui/top_right_widget/hearts
@export var starting_world_speed := 300


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	running_text.add_new_running_text_line()
	Globals.set_global_world_speed(starting_world_speed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## update the stamina progress bar
func _on_duck_character_stamina_updated() -> void:
	stam_bar.value = duck.stamina / duck.max_stamina


## update UI when duck HP changes
func _on_duck_character_lives_updated() -> void:
	var normal_texture := preload('res://assets/2d/UI_Heart.png')
	var empty_texture := preload('res://assets/2d/UI_Heart_Empty.png')
	
	for i in range(duck.max_lives):
		var heart := hearts_box.get_child(i) as TextureRect
		if duck.lives - 1 >= i:
			heart.texture = normal_texture
		else:
			heart.texture = empty_texture

extends Node2D


@onready var running_text := $ui/running_text
@onready var duck := $duck_character
@onready var stam_bar := $ui/top_left_widget/stam_bar
@onready var hearts_box := $ui/top_right_widget/hearts
@export var starting_world_speed := 300

## can optionally ignore death (for testing purposes)
@export var death_ends_game := true

enum eGameResult {Victory, Defeat}
signal game_end(game_result: eGameResult)

@onready var bombardier := $bombardier


#region Game scenario

@onready var obstacles_line := $road/obstacles

var bombing_overrides := {}

## wait n seconds
func secs(time: float) -> void:
	await get_tree().create_timer(time).timeout


## this will play through game events, speed up treadmills, send game life-cycle events etc.
func reproduce_game_scenario() -> void:
	# phase 1: lower speed, scarce object spawn
	obstacles_line.spawn_probability = 0.5
	Globals.set_global_world_speed(1200)
	
	# increase spawn rate slightly
	await secs(15)
	obstacles_line.spawn_probability = 0.7
	
#endregion


## throws bombs every n seconds
func barrage(sec: float) -> void:
	while true:
		bombardier.throw_bombs(bombardier.Patterns.new().get_random_pattern())
		await get_tree().create_timer(sec).timeout


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	running_text.add_new_running_text_line() # initialize the running text immediately (otherwise text is spawned in next frame)
	reproduce_game_scenario()
	
	# TODO debugging only, have to delete later
	barrage(15.)

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


func _on_duck_character_dead() -> void:
	if death_ends_game:
		Globals.set_global_world_speed(0.)
		(duck.sprite as SpineSprite).get_animation_state().set_animation('death', false, 0)
		await get_tree().create_timer(2.).timeout
		game_end.emit(eGameResult.Defeat)

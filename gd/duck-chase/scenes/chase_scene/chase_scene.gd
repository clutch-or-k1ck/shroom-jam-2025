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
@onready var music_player := $music_player
@onready var character_spawn := $character_spawn
@onready var main_menu := $ui/game_menu
@onready var obstacles_treadmill := $road/obstacles
@onready var policemen_treadmill := $road/policemen
@onready var heal_items_treadmill := $road/heal_items_treadmill


#region Game scenario

@onready var obstacles_line := $road/obstacles

var bombing_overrides := {}

## wait n seconds
func secs(time: float) -> void:
	await get_tree().create_timer(time).timeout


## this will play through game events, speed up treadmills, send game life-cycle events etc.
func reproduce_game_scenario() -> void:
	# start playing the music and reset the character position and stats
	music_player.play()
	duck.position = character_spawn.position
	duck.lives = duck.max_lives
	duck.stamina = duck.max_stamina
	
	# set the game phase
	Globals.game_phase = Globals.eGamePhase.GameLoop
	
	# launch the world
	Globals.set_global_world_speed(1200.)
	obstacles_treadmill.active = true
	
	# launch simple obstacles
	obstacles_treadmill.spawn_probability = 0.5
	
	# start spawning heals at low probability
	await secs(15)
	print('start spawning heal items')
	heal_items_treadmill.active = true
	
	# increase the object spawn probability slightly
	await secs(15)
	print('spawn probability increased')
	obstacles_treadmill.spawn_probability = 0.9
	
	# start spawning heals at low probability
	await secs(5)
	print('start spawning heal items')
	heal_items_treadmill.active = true
	
	# launch the police cars treadmill and speed up everything
	await secs(15)
	print('start launching police cars')
	# TODO create the police car
	# TODO create the police car treadmill
	
#endregion


## throws bombs every n seconds
func barrage(sec: float) -> void:
	while true:
		bombardier.throw_bombs(bombardier.Patterns.new().get_random_pattern())
		await get_tree().create_timer(sec).timeout


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu.visible = true
	running_text.add_new_running_text_line() # initialize the running text immediately (otherwise text is spawned in next frame)
	# we start in the main game menu when this scene begins play - nothing happens on the treadmill so far
	Globals.game_phase = Globals.eGamePhase.Menu

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


func _on_game_menu_begin_game_pressed() -> void:
	main_menu.visible = false
	reproduce_game_scenario()


func _on_game_menu_exit_game_pressed() -> void:
	get_tree().quit()

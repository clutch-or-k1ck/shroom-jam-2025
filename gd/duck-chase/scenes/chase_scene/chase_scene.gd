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
@onready var police_cars_treadmill := $road/police_cars_treadmill


#region Game scenario

@onready var obstacles_line := $road/obstacles

var bombing_overrides := {}
var barraging_random_interval: Array
var max_world_speed := 2000.
var do_gradual_world_speed_up := false

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
	police_cars_treadmill.active = true
	Globals.set_global_world_speed(1500.)
	(duck.sprite.get_animation_state() as SpineAnimationState).set_time_scale(1.15)
	
	
	# policemen start appearing shortly after (but redcue obstacle spawn slightly)
	await secs(15)
	obstacles_treadmill.spawn_probability = 0.5
	policemen_treadmill.active = true
	
	# start barraging, speed up the world
	await secs(30)
	barraging_random_interval = [5., 15.]
	barrage()
	
	# barraging intensified, world speed up
	await secs(15)
	barraging_random_interval = [2., 10.]
	Globals.set_global_world_speed(1700.)
	duck.sprite.get_animation_state().set_time_scale(1.25)
	
	# start targeting the character and speed up the world and the character gradually
	# TODO
	do_gradual_world_speed_up = true
	
	
#endregion


## throws bombs every n seconds
func barrage() -> void:
	while true:
		bombardier.throw_bombs(bombardier.Patterns.new().get_random_pattern())
		await get_tree().create_timer(randf_range(barraging_random_interval[0], barraging_random_interval[1])).timeout


func start_game():
	death_screen.visible = false
	main_menu.visible = true
	main_menu.play_btn.grab_focus()
	# we start in the main game menu when this scene begins play - nothing happens on the treadmill so far
	Globals.game_phase = Globals.eGamePhase.Menu
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	running_text.add_new_running_text_line() # initialize the running text immediately (otherwise text is spawned in next frame)
	start_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if do_gradual_world_speed_up:
		# speed up 5 units per second
		var new_world_speed = min(max_world_speed, Globals.get_global_world_speed() + delta * 20.)
		Globals.set_global_world_speed(new_world_speed)


## update the stamina progress bar
func _on_duck_character_stamina_updated() -> void:
	stam_bar.value = duck.stamina / duck.max_stamina


## update UI when duck HP changes
func _on_duck_character_lives_updated(delta: int) -> void:
	var normal_texture := preload('res://assets/2d/UI_Heart.png')
	var empty_texture := preload('res://assets/2d/UI_Heart_Empty.png')
	
	for i in range(duck.max_lives):
		var heart := hearts_box.get_child(i) as TextureRect
		if duck.lives - 1 >= i:
			heart.texture = normal_texture
		else:
			heart.texture = empty_texture


@onready var death_screen := $ui/death_screen
func _on_duck_character_dead() -> void:
	# plays the death sequence
	if death_ends_game:
		Globals.set_global_world_speed(0.)
		(duck.sprite as SpineSprite).get_animation_state().set_animation('death', false, 0)
		await get_tree().create_timer(1.).timeout
		death_screen.visible = true
		
		# restart game after 2 seconds of showing the screen
		await get_tree().create_timer(2.).timeout
		get_tree().reload_current_scene()


func _on_game_menu_begin_game_pressed() -> void:
	main_menu.visible = false
	reproduce_game_scenario()


func _on_game_menu_exit_game_pressed() -> void:
	get_tree().quit()


func _on_death_screen_full_game_reset() -> void:
	# when the user presses anything on the death screen, we send them back to main menu
	death_screen.visible = false
	start_game()

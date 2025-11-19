extends Node2D
class_name ChaseScene


@onready var hud := $hud
@onready var ui_container := $ui
@onready var running_text := $running_text/running_text
@onready var stam_bar := $hud/top_left_widget/stam_bar
@onready var hearts_box := $hud/top_right_widget/hearts

## can optionally ignore death (for testing purposes)
@export var death_ends_game := true

enum eGameResult {Victory, Defeat}
signal game_end(game_result: eGameResult)

@onready var bombardier := $bombardier
@onready var music_player := $music_player
@onready var character_spawn := $character_spawn
@onready var obstacles_treadmill := $road/obstacles
@onready var policemen_treadmill := $road/policemen
@onready var heal_items_treadmill := $road/heal_items_treadmill
@onready var police_cars_treadmill := $road/police_cars_treadmill

var main_game_menu_scene := preload('res://ui/game_menu_start.tscn')
var pause_menu_scene := preload('res://ui/pause_menu.tscn')
var main_char_scene := preload('res://scenes/duck_character/duck_character.tscn')
var duck_char: MrDuck


#region Game loop

@export var starting_world_speed := 1200
## each new game loop, the world speed will increase by this much pixels
@export var world_speed_increase_rate := 200
## each new game loop, the duck animation speed will increase by this much units
@export var duck_anim_speed_increase_rate := 0.1
## each new game loop, the running text speed will increase by this much pixels
@export var running_text_speed_increase_rate := 100

@onready var obstacles_line := $road/obstacles

var bombing_overrides := {}
var barraging_random_interval: Array = [5., 15.]
var max_world_speed := 2000.
var game_loop_timer: SceneTreeTimer # a reference to the timer of the next game loop action

## a reference to the game loop manager (responsible for playing the game loop events)
var game_loop_manager: GameLoopManager


## wait n seconds
func secs(time: float) -> void:
	await get_tree().create_timer(time).timeout


## respawns the main character and sets its stats
func respawn_main_character():
	var main_char := main_char_scene.instantiate() as MrDuck
	main_char.z_index = 7
	main_char.position = character_spawn.position
	add_child(main_char)
	duck_char = main_char # keeps reference to the main char


## this happens only once at the very beginning of the chase
func init_game():
	# reset treadmills
	heal_items_treadmill.active = false
	policemen_treadmill.active = false
	obstacles_treadmill.active = true
	obstacles_treadmill.spawn_probability = 0.5
	Globals.set_global_world_speed(starting_world_speed)
	music_player.play()


func speed_up():
	# # speeds up the world and the duck
	Globals.set_global_world_speed(Globals.get_global_world_speed() + world_speed_increase_rate)
	duck_char.sprite.get_animation_state().set_time_scale(
		duck_char.sprite.get_animation_state().get_time_scale() + duck_anim_speed_increase_rate
	)
	
	# # slows down the police car so that we start catching up with them visually
	# TODO
	
	# # speeds up the running text line, just for fun
	# TODO


func launch_obstacles():
	obstacles_treadmill.active = true


func launch_police_cars():
	police_cars_treadmill.active = true


func launch_policemen():
	policemen_treadmill.active = true


func launch_heal_items():
	heal_items_treadmill.active = true


func stop_policemen_spawn():
	policemen_treadmill.active = false


func stop_obstacles_spawn():
	obstacles_treadmill.active = false


func init_hud():
	hud.visible = true

var _do_barrage := false

## throws bombs every n seconds
func barrage() -> void:
	_do_barrage = true
	while _do_barrage:
		bombardier.throw_bombs(bombardier.Patterns.new().get_random_pattern())
		await get_tree().create_timer(randf_range(barraging_random_interval[0], barraging_random_interval[1])).timeout


func stop_barraging() -> void:
	_do_barrage = false


func create_game_loop() -> GameLoopManager:
	var game_loop_manager := GameLoopManager.new(
		{
			0.1: self.launch_obstacles,
			15.: self.launch_heal_items,
			30.: [self.launch_police_cars, self.launch_policemen],
			60.: [self.stop_policemen_spawn, self.stop_obstacles_spawn, self.barrage],
			80.: self.stop_barraging,
			90.: self.speed_up
		}
	)
	add_child(game_loop_manager)
	return game_loop_manager


## this will play through game events, speed up treadmills, send game life-cycle events etc.
func restart_game_loop() -> void:
	remove_ui() # removes whatever menu ui is currently in ui overlay
	init_game()
	init_hud()
	respawn_main_character()
	
	if game_loop_manager == null:
		game_loop_manager = create_game_loop()
	game_loop_manager.playing = true
	
	
#endregion

#region UI utils
enum eUITypes {MainMenu, PauseMenu, DeathScreen}

func show_ui(type: eUITypes) -> GameMenuBase:
	var scene: PackedScene
	match type:
		eUITypes.MainMenu:
			scene = main_game_menu_scene
		eUITypes.PauseMenu:
			scene = pause_menu_scene
		eUITypes.DeathScreen:
			scene = null
			
	if scene != null:
		var ui := scene.instantiate()
		ui_container.add_child(ui)
		Globals.game_phase = Globals.eGamePhase.Menu
		return ui as GameMenuBase
	
	return null


func remove_ui() -> void:
	ui_container.remove_child(ui_container.get_child(0))
	Globals.game_phase = Globals.eGamePhase.GameLoop

#endregion


func pause() -> void:
	get_tree().paused = true
	show_ui(eUITypes.PauseMenu)


func unpause() -> void:
	get_tree().paused = false
	remove_ui()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show_ui(eUITypes.MainMenu)
	hud.visible = false
	Globals.set_global_world_speed(1000) # while we are basically inside the menu


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed('game_menu'):
		pause()


#region Updates of lives bar and stam bar
## update the stamina progress bar
func _on_duck_character_stamina_updated() -> void:
	stam_bar.value = duck_char.stamina / duck_char.max_stamina


## update UI when duck HP changes
func _on_duck_character_lives_updated(delta: int) -> void:
	var normal_texture := preload('res://assets/2d/UI_Heart.png')
	var empty_texture := preload('res://assets/2d/UI_Heart_Empty.png')
	
	for i in range(duck_char.max_lives):
		var heart := hearts_box.get_child(i) as TextureRect
		if duck_char.lives - 1 >= i:
			heart.texture = normal_texture
		else:
			heart.texture = empty_texture
#endregion


func _on_duck_character_dead() -> void:
	# plays the death sequence
	if death_ends_game:
		Globals.set_global_world_speed(0.)
		(duck_char.sprite as SpineSprite).get_animation_state().set_animation('death', false, 0)
		await get_tree().create_timer(1.).timeout
		show_ui(eUITypes.DeathScreen)
		
		# restart game after 2 seconds of showing the screen
		await get_tree().create_timer(2.).timeout
		get_tree().reload_current_scene()

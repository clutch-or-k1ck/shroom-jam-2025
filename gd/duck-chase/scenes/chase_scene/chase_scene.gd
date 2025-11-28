extends Node2D
class_name ChaseScene


@onready var hud := $hud
@onready var ui_container := $ui
@onready var running_text := $running_text/running_text
@onready var stam_bar := $hud/top_left_widget/stam_bar
@onready var hearts_box := $hud/top_right_widget/hearts

enum eGameResult {Victory, Defeat}
signal game_end(game_result: eGameResult)

@onready var bombardier: Bombardier = $bombardier
@onready var music_player := $music_player
@onready var end_of_game_sfx := $end_of_game_sfx
@onready var character_spawn := $character_spawn
@onready var obstacles_treadmill := $road/obstacles
@onready var policemen_treadmill := $road/policemen
@onready var heal_items_treadmill := $road/heal_items_treadmill
@onready var police_cars_treadmill := $road/police_cars_treadmill
@onready var road_collision := $road/road_collision
@onready var score_widget: GameScoreWidget = $hud/game_score_widget

var main_game_menu_scene := preload('res://ui/game_menu_start.tscn')
var pause_menu_scene := preload('res://ui/pause_menu.tscn')
var death_screen_scene := preload('res://ui/death_screen.tscn')
var main_char_scene := preload('res://scenes/duck_character/duck_character.tscn')
var duck_char: MrDuck


#region Game loop
@onready var obstacles_line := $road/obstacles

## time elapsed since the start of the chase
var time_elapsed: float

## if we are playing the game (duck is alive and chase is ongoing)
var playing := false

var bombing_overrides := {}
var barraging_random_interval: Array = [0.5, 3.]
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
	
	# position and z-index
	main_char.z_index = 7
	main_char.position = character_spawn.position
	
	# the duck needs a ground reference for jumping
	main_char.ground_reference = road_collision
	
	# connect life, death, and stamina signals of the duck
	main_char.stamina_updated.connect(self._on_duck_character_stamina_updated)
	main_char.lives_updated.connect(self._on_duck_character_lives_updated)
	main_char.dead.connect(self._on_duck_character_dead)
	
	add_child(main_char)
	duck_char = main_char # keeps reference to the main char
	
	# HACK fake lives_updated and stamina_updated signals to update UI
	main_char.lives_updated.emit(1)
	main_char.stamina_updated.emit()


## cleans up all that should NOT get into the next session from the previous session
func clean_up_previous_session():
	# despawn the duck
	if duck_char != null:
		remove_child(duck_char)
	
	# delete any obstacles, heal items, and police cars that are currently on the screen
	(policemen_treadmill as Treadmill).clear()
	(obstacles_treadmill as Treadmill).clear()
	(police_cars_treadmill as Treadmill).clear()
	(heal_items_treadmill as Treadmill).clear()
	
	# stop events in the game loop manager and reset it
	if game_loop_manager != null:
		game_loop_manager.playing = false
		game_loop_manager.reset()


## this happens only once at the very beginning of the chase
func start_chase():
	# reset treadmills
	heal_items_treadmill.active = false
	policemen_treadmill.active = false
	obstacles_treadmill.active = true
	obstacles_treadmill.spawn_probability = 0.5
	playing = true
	time_elapsed = start_at_elapsed_time
	music_player.play()


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
	
	# reset the game score widget
	score_widget.shake = false
	score_widget.is_best_result = false

var _do_barrage := false

## throws bombs every n seconds
func barrage() -> void:
	_do_barrage = true
	while _do_barrage:
		var duck_horizontal_location_ratio := duck_char.position.x / get_viewport_rect().size.x
		var bombardment_param_overrides = {'focus.location': duck_horizontal_location_ratio}
		
		bombardier.throw_bombs(bombardier.Patterns.new().get_random_pattern(bombardment_param_overrides))
		await bombardier.bombardment_finished
		await get_tree().create_timer(randf_range(barraging_random_interval[0], barraging_random_interval[1])).timeout


func stop_barraging() -> void:
	_do_barrage = false


func create_game_loop() -> GameLoopManager:
	var normal_game_loop := {
		0.1: self.launch_obstacles,
		15.: self.launch_heal_items,
		30.: [self.launch_police_cars, self.launch_policemen],
		60.: [self.stop_policemen_spawn, self.stop_obstacles_spawn, self.barrage],
		85.: self.stop_barraging
	}
	
	# NOTE this is for debugging purposes only to throw bombs non-stop
	var bomb_only_game_loop := {
		0.1: self.barrage
	}
	
	var game_loop_manager := GameLoopManager.new(normal_game_loop)
	game_loop_manager.looping = true
	
	add_child(game_loop_manager)
	return game_loop_manager


## events that happen when the game is lost
func finish_chase() -> void:
	playing = false
	game_loop_manager.playing = false
	(music_player as AudioStreamPlayer).playing = false
	Globals.set_global_world_speed(0.)
	
	end_of_game_sfx.play()
	
	# TODO this should be handled via GUI
	GameScore.accumulating = false
	var phrase := 'Your score is: ' + str(GameScore.get_current_score()) + '. '
	if GameScore.is_PR():
		phrase += 'This is your highest score!'
	if GameScore.is_PR():
		GameScore.persist()


## this will play through game events, speed up treadmills, send game life-cycle events etc.
func restart_game_loop() -> void:
	GameScore.reset()
	GameScore.accumulating = true
	remove_ui() # removes whatever menu ui is currently in ui overlay
	clean_up_previous_session()
	start_chase()
	init_hud()
	respawn_main_character()
	modulate_global_speeds()
	
	# bind heal items treadmill to duck's health
	heal_items_treadmill.activation_condition = func deactivate_on_full_health():
		return duck_char.lives < duck_char.max_lives
	
	if game_loop_manager == null:
		game_loop_manager = create_game_loop()
	game_loop_manager.playing = true
	
	
#endregion

#region world speed

@export_category('World speed')

## the world will start moving at this speed
@export var world_speed_base: float

## the world speed increase will converge at this value
@export var world_speed_max: float

## the world speed will equal 'world_speed_calibration_speed' at this point in elapsed time
@export var world_speed_calibration_time: float

## the world speed will equal this value at 'world_speed_calibration_time'
@export var world_speed_calibration_speed: float

## when the game starts, it will pretend this much time had already elapsed, for debugging purposes only
@export var start_at_elapsed_time := 0.

## speed up the world or not, use for debugging purposes
@export var do_speed_up := true

## this is a non-linear function with limit of its first derivative equal to zero
## NOTE reference formulas:
## y = StartSpeed + m/k * (1 - exp(-kx))
## m = k * (MaxSpeed - StartSpeed) NOTE this is the first calibration coefficient
## k = - 1/calibration_time * (ln(1 - (calibration_speed - StartSpeed)/(MaxSpeed - StartSpeed))) NOTE this is the second calibration coefficient
func get_target_world_speed(elapsed_time: float):
	var k = -1. / world_speed_calibration_time * log(
		1. - (world_speed_calibration_speed - world_speed_base) / (world_speed_max - world_speed_base)
	)
	var m = k * (world_speed_max - world_speed_base)
	print('target world speed is %d' % (world_speed_base + m / k * (1. - exp(-k * elapsed_time))))
	return world_speed_base + m / k * (1. - exp(-k * elapsed_time))


## every property will converge to its 'target_high' which is acieved when the world speed reaches its reference high
@onready var global_world_speed_property_modulators = [
	{
		'method': (func set_anim_scale(val):
			if duck_char != null:
				duck_char.sprite.get_animation_state().set_time_scale(val)),
		'base': 1.3,
		'target_high': 2.
	},
	{
		'target': 'music_player.pitch_scale',
		'base': 0.8,
		'target_high': 1.2
	},
	{
		'target': 'running_text.running_text_speed',
		'base': -250.,
		'target_high': -1000.
	},
	{
		'target': 'duck_char.jump_velocity',
		'base': -2400.,
		'target_high': -3800.
	},
	{
		'target': 'duck_char.fall_constant_speed',
		'base': 1600.,
		'target_high': 2800.
	},
	{
		'target': 'duck_char.air_dash_zone',
		'base': 0.1,
		'target_high': 0.5
	},
	{
		'target': 'duck_char.zero_g_grace_period',
		'base': 0.1,
		'target_high': 0.01
	}
]


## modulates the object properties that depend on the global world speed! called per-frame or periodically
func modulate_global_world_speed_properties():
	var world_speed_overage := Globals.get_global_world_speed() - world_speed_base
	
	for property_modulator in global_world_speed_property_modulators:
		var base: float = property_modulator['base']
		var target_high: float = property_modulator['target_high']
		# interpolate using the current world speed overage
		var target_value = base + world_speed_overage * (
			(target_high - base) / (world_speed_max - world_speed_base)
		)
		
		if 'method' in property_modulator:
			print('calling a property modulator method with value %f' % target_value)
			property_modulator['method'].call(target_value)
		elif 'target' in property_modulator:
			var target_object = null # the object on which to set the property
			var target_property: String # the name of the property to set
			
			var target_path := (property_modulator['target'] as String).split('.')
			if target_path.size() == 1:
				target_object = self
				target_property = target_path[0]
			elif target_path.size() == 2:
				target_object = self.get(target_path[0])
				target_property = target_path[1]
			elif target_path.size() > 2:
				target_object = self
				for i in range(1, target_path.size()):
					target_object = target_object.get(target_path[i])
				target_property = target_path[-1]
				
			print('setting property %s to its target value %f' % [property_modulator['target'], target_value])
			target_object.set(target_property, target_value)


## sets speed of the world, animations, vfx and sfx depending on time elapsed
func modulate_global_speeds() -> void:
	Globals.set_global_world_speed(get_target_world_speed(time_elapsed))
	modulate_global_world_speed_properties()


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
			scene = death_screen_scene
			
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
	GameScore.score_changed.connect(self._on_game_score_changed)
	show_ui(eUITypes.MainMenu)
	hud.visible = false
	Globals.set_global_world_speed(1000) # while we are basically inside the menu
	running_text.add_new_running_text_line()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed('game_menu'):
		pause()
	if playing:
		time_elapsed += delta
		if do_speed_up:
			modulate_global_speeds()


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
	finish_chase()
	await get_tree().create_timer(3.).timeout
	show_ui(eUITypes.DeathScreen)


func _on_game_score_changed(new_score: int) -> void:
	score_widget.score = new_score
	if GameScore.is_PR():
		GameScore.persist()
		score_widget.is_best_result = true
		score_widget.shake = true

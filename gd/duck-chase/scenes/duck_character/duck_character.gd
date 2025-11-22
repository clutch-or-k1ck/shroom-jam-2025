extends CharacterBody2D


class_name MrDuck

@export_category('Character')
@export var max_lives := 4
@export var max_stamina: float = 100.
## while flying, the rate at which stamina is depleting per second
@export var stamine_flying_cost := 50.
## while not flying, the rate at which stamina is regenerating per second
@export var stamina_regeneration_rate := 10.
@export var jumping_stamina_cost := 25.
@export var can_regenerate_stamina_in_free_fall := true
## mainly for testing and debugging, can 'switch off' the character death
@export var can_die := true

@export_category('Movement')
## initial velocity of the jump (will converge to zero at maximum jump height)
@export var jump_velocity := -400
## non-linear jump calibration coefficient, should be a value < 1., this will make the jump faster in the beginning and slow down faster at the end
@export var jump_velocity_calibration_coef := 0.3
## when jump upward velocity is this close to zero, we are in the zero g zone
@export var zero_g_velocity_tolerance := 0.03
## peak jump height
@export var jump_height := 300
## this is percentage of maximum jump height where dashing and flight are allowed if character is in the air
@export var air_dash_zone := 0.05

enum eFallVelocityCalculationMethod {Constant, Gravity}
## if constant, the duck falls at a constant speed, if gravity, gravity is applied every frame
@export var fall_velocity_method: eFallVelocityCalculationMethod

## gravity magnifier applied when the character is falling (only if fall velocity method is Gravity)
@export var fall_gravity_scale_factor := 2.

## constant fall velocity speed, used only when fall velocity method is Constant
@export var fall_constant_speed := 1200.

## horizontal character speed
@export var speed = 300
## the amount of time in seconds the duck is allowed to 'freeze' in the air at the top of the jump
@export var zero_g_grace_period := 0.3
## to alleviate the illusion of slow movement, apply scale to movement speed when moving left
@export var left_strafe_speed_scale_factor := 1.5
## horizontal speed will be adjusted by this factor when duck is in the air
@export var free_fall_hspeed_scale_factor := 0.
## how much distance is covered with a dash
@export var dashing_distance := 50.
## dashing velocity
@export var dashing_velocity := 400.
## ground reference allows to specify where the 'ground' is for precise jump height math
@export var ground_reference: Node2D

@onready var sprite := $duck_sprite
@onready var standing_collision := $duck_collision_standing
@onready var duck_hurt_sfx := $duck_hurt_sfx
@onready var punch_sfx := $punch_sfx
@onready var health_obtained := $health_obtained
@onready var banknotes_particles := $banknotes_particles
@onready var dust_particles := $dust_particles
@onready var feather_particles := $feather_particles

var stamina := max_stamina
var lives := max_lives
var is_dead := false
var _time_elapsed_in_zero_g := 0.
var _distance_covered_in_dash := 0.

signal lives_updated(delta: int)
signal stamina_updated
signal dead
signal character_movement_state_updated(old: eCharacterMovementState, new: eCharacterMovementState)


## whether the duck is flying, free-falling, or is on the ground
enum eCharacterMovementState {Running, RunningDucked, Jumping, ZeroG, Flying, Falling, Dashing, Dying}
var character_movement_state := eCharacterMovementState.Falling

var animation_map := {
	eCharacterMovementState.Running: 'run',
	eCharacterMovementState.Jumping: 'jump',
	eCharacterMovementState.ZeroG: 'fall',
	eCharacterMovementState.Falling: 'fall',
	eCharacterMovementState.Dashing: 'dash',
	eCharacterMovementState.Flying: 'fly',
	eCharacterMovementState.Dying: 'death'
}

func set_character_movement_state(new_state: eCharacterMovementState):
	var previous := character_movement_state
	character_movement_state = new_state
	character_movement_state_updated.emit(previous, new_state)


## one-time decrease to stamina
func drain_stamina(amount: float) -> void:
	stamina = max(0., stamina - amount)
	stamina_updated.emit()


## one-time increase to stamina
func add_stamina(amount: float) -> void:
	stamina = min(max_stamina, stamina + amount)
	stamina_updated.emit()


func has_stamina() -> bool:
	return stamina > 0.


## per-frame stamina depletion
func _deplete_stamina(delta: float) -> void:
	drain_stamina(stamine_flying_cost * delta)


## per-frame stamina regeneration
func _regenerate_stamina(delta: float) -> void:
	add_stamina(stamina_regeneration_rate * delta)


## depending on the character state, regenerate or deplete stamina
func _tick_stamina(delta: float) -> void:
	match character_movement_state:
		eCharacterMovementState.Running:
			_regenerate_stamina(delta)
		eCharacterMovementState.Falling:
			if can_regenerate_stamina_in_free_fall:
				_regenerate_stamina(delta)
		eCharacterMovementState.Flying:
			_deplete_stamina(delta)


func _die() -> void:
	is_dead = true
	dead.emit()
	# TODO play death sfx, the rest should be handled via the anim machine


## invincibility frames (only in the beginning of the dash - end of the dash is NOT protected)
func is_invincible() -> bool:
	return character_movement_state == eCharacterMovementState.Dashing and \
		(_distance_covered_in_dash / dashing_distance) < 0.7


## takes one heart from duck's HP
func lose_life() -> void:
	lives = max(0, lives - 1)
	lives_updated.emit(-1)
	if lives == 0 and can_die:
		_die()


## adds one heart to duck's HP
func get_life() -> void:
	if is_dead:
		return
	lives = min(4, lives + 1)
	lives_updated.emit(1)


## whether we are past the period that we are allowed to 'freeze' in the air
func is_zero_g_grace_period_elapsed(delta: float) -> bool:
	_time_elapsed_in_zero_g += delta
	return _time_elapsed_in_zero_g > zero_g_grace_period


## whether we covered the dash distance since the dash has started
func is_dash_distance_covered(delta: float) -> bool:
	_distance_covered_in_dash += delta * dashing_velocity
	return _distance_covered_in_dash > dashing_distance


## character is currently at a height where he's allowed to dash or fly
func is_in_air_dash_range() -> bool:
	return get_jump_height_ratio() >= (1. - air_dash_zone)


## decides which state the character is in
## this is based on a number of factors such as user input, velocity, previous state etc
func run_state_machine(delta: float) -> void:
	match character_movement_state:
		eCharacterMovementState.Running:
			if is_dead:
				set_character_movement_state(eCharacterMovementState.Dying)
			# NOTE when running, we can duck, jump, or dash. Jump and dash have higher priority than duck
			elif Input.is_action_just_pressed('jump'):
				set_character_movement_state(eCharacterMovementState.Jumping)
			elif Input.is_action_just_pressed('dash'): # TODO add action
				set_character_movement_state(eCharacterMovementState.Dashing)
			elif Input.is_action_pressed('duck'): # TODO add action
				set_character_movement_state(eCharacterMovementState.RunningDucked)
				
		eCharacterMovementState.RunningDucked:
			if is_dead:
				set_character_movement_state(eCharacterMovementState.Dying)
			# NOTE when running ducked, we can continue running ducked, or instead jump/dash
			if Input.is_action_just_pressed('jump'):
				set_character_movement_state(eCharacterMovementState.Jumping)
			elif Input.is_action_just_pressed('dash'): # TODO add action
				set_character_movement_state(eCharacterMovementState.Dashing)
			elif not Input.is_action_pressed('duck'):
				set_character_movement_state(eCharacterMovementState.Running)
				
		eCharacterMovementState.Jumping:
			# NOTE if we died middle-jump, start falling immediately
			if is_dead:
				set_character_movement_state(eCharacterMovementState.Falling)
			# NOTE when jumping (character moves up), we allowed dashing/jumping close to the top
			elif Input.is_action_just_pressed('jump') and has_stamina() and is_in_air_dash_range():
				set_character_movement_state(eCharacterMovementState.Flying)
			elif Input.is_action_just_pressed('dash') and has_stamina() and is_in_air_dash_range(): # TODO specify how much stamina
				set_character_movement_state(eCharacterMovementState.Dashing)
			elif velocity.y < 0.: # NOTE keep this state until the charcter is moving up
				pass # CAUTION we are still jumping, but have to update velocity properly to avoid getting stuck here
			elif is_equal_approx(velocity.y, 0.): # TODO add some tolerance?
				set_character_movement_state(eCharacterMovementState.ZeroG)
			
		eCharacterMovementState.ZeroG:
			# NOTE dying in zero_g -> fall immediately
			if is_dead:
				set_character_movement_state(eCharacterMovementState.Falling)
				return
			
			# NOTE from zero_g, we can either start flying, or dash, or go to the ground without waiting the grace period
			if is_zero_g_grace_period_elapsed(delta):
				set_character_movement_state(eCharacterMovementState.Falling)
				return
			
			if Input.is_action_just_pressed('jump') and has_stamina():
				set_character_movement_state(eCharacterMovementState.Flying)
			elif Input.is_action_just_pressed('dash') and has_stamina(): # TODO specify how much stamina
				set_character_movement_state(eCharacterMovementState.Dashing)
			
		eCharacterMovementState.Falling:
			# NOTE when we are falling, no further inputs are processed
			if is_on_floor(): # CAUTION don't fail to update the velocity accordingly
				if is_dead:
					set_character_movement_state(eCharacterMovementState.Dying)
				else:
					set_character_movement_state(eCharacterMovementState.Running)
			
		eCharacterMovementState.Flying:
			# NOTE when we are flying, we can keep flying if there is enough stamina and input is pressed
			if not (Input.is_action_pressed('jump') and has_stamina()) or is_dead:
				set_character_movement_state(eCharacterMovementState.Falling)
			
		eCharacterMovementState.Dashing:
			# NOTE dying during dash could happen in the air or on the floor
			if is_dead:
				if is_on_floor():
					set_character_movement_state(eCharacterMovementState.Dying)
				else:
					set_character_movement_state(eCharacterMovementState.Falling)
				return
				
			# NOTE the dash goes on until the dash distance is covered, then we either run or fall
			if not is_dash_distance_covered(delta):
				return
				
			if is_on_floor():
				set_character_movement_state(eCharacterMovementState.Running)
			else:
				set_character_movement_state(eCharacterMovementState.Falling)


# returns the percentage of duck's max jump height that we are at
func get_jump_height_ratio() -> float:
	var ground_height := ground_reference.global_position.y
	var duck_height := self.position.y
	var absolute_jump_height := (duck_height - ground_height) * -1.
	return absolute_jump_height / jump_height


## interpolates the velocity depending on the character's height in relation to max jump height
func interp_jump_velocity() -> float:
	var covered_ratio := get_jump_height_ratio()
	var remaining_ratio := max(1. - covered_ratio, 0.) as float
	var velocity_downscale_factor := remaining_ratio ** jump_velocity_calibration_coef
	
	# the closer to the target jump height, the more we downscale duck's velocity
	var target_velocity := jump_velocity * velocity_downscale_factor
	
	# the downscaling never really leads to a true zero - check with tolerance
	if abs(target_velocity - 0.) < zero_g_velocity_tolerance:
		return 0.
		
	# larger the ratio, the more we should diminish jump velocity
	return target_velocity


## interpolates the velocity of falling (maginfy the gravity etc.)
func interp_fall_velocity(delta: float) -> float:
	if fall_velocity_method == eFallVelocityCalculationMethod.Constant:
		return fall_constant_speed
	else:
		return velocity.y + get_gravity().y * delta * fall_gravity_scale_factor


## sets vertical velocity depending on the character movement state
func set_vvelocity(delta: float) -> void:
	if character_movement_state == eCharacterMovementState.Jumping:
		velocity.y = interp_jump_velocity()
	elif character_movement_state == eCharacterMovementState.Falling:
		velocity.y = interp_fall_velocity(delta)
	else:
		# NOTE if the character is not jumping or falling, its vertical velocity should be 0
		velocity.y = 0.


## sets horizontal velocity depending on the character movement state and inputs
func set_hvelocity() -> void:
	if is_dead:
		velocity.x = 0.
		return
		
	if character_movement_state == eCharacterMovementState.Dashing:
		# NOTE when the character is dashing, we don't listen to inputs and enforce a velocity
		velocity.x = dashing_velocity
	elif character_movement_state in [
		eCharacterMovementState.Running, eCharacterMovementState.Flying, eCharacterMovementState.RunningDucked
	]:
		# NOTE if running or flying, normal speed is applied if input is pressed
		var direction := Input.get_axis('move_left', 'move_right')
		if direction > 0.:
			velocity.x = direction * speed
		elif direction < 0.: 
			velocity.x = direction * speed * left_strafe_speed_scale_factor
		else:
			velocity.x = 0.
	elif character_movement_state in [
		eCharacterMovementState.Jumping,
		eCharacterMovementState.ZeroG,
		eCharacterMovementState.Falling
	]:
		# NOTE if the character is in the air (falling/jumping/zero g) - move but apply downscaling
		var direction := Input.get_axis('move_left', 'move_right')
		if direction > 0.:
			velocity.x = direction * speed * free_fall_hspeed_scale_factor
		elif direction < 0.:
			velocity.x = direction * speed * left_strafe_speed_scale_factor * free_fall_hspeed_scale_factor
		else:
			velocity.x = 0.
	else:
		velocity.x = 0.


## plays duck animation and reduces the hitbox
func duck() -> void:
	var anim_state := sprite.get_animation_state() as SpineAnimationState
	anim_state.set_animation('crowl', true, 1)
	standing_collision.set_deferred('disabled', true)


## stop playing duck animation and enlarges the hitbox
func unduck() -> void:
	var anim_state := sprite.get_animation_state() as SpineAnimationState
	anim_state.set_empty_animation(1, 0.1)
	standing_collision.set_deferred('disabled', false)


## loose banknotes!
func loose_banknotes_cycle() -> void:
	banknotes_particles.emitting = true
	pass


func _ready() -> void:
	update_animation(character_movement_state, character_movement_state)
	loose_banknotes_cycle()


func _process(delta: float) -> void:
	## we ever want to do something on tick-by-tick if the game phase is GameLoop
	if Globals.game_phase == Globals.eGamePhase.GameLoop:
		_tick_stamina(delta)


func _physics_process(delta: float) -> void:
	## we ever want to do something on tick-by-tick if the game phase is GameLoop
	if not Globals.game_phase == Globals.eGamePhase.GameLoop:
		return
		
	run_state_machine(delta) # this defines which state the character is in
	set_hvelocity()
	set_vvelocity(delta)
	move_and_slide()


## in 'delta' seconds, if the character is in the specified movement state, update the animation to the specified one
## NOTE this is useful for postponed animation updates or animation transition tricks
func schedule_animation_update_if_character_movement_state_matches(
	in_seconds: float,
	match_state: eCharacterMovementState,
	anim_name: String
) -> void:
	await get_tree().create_timer(in_seconds).timeout
	if character_movement_state == match_state:
		var anim_state := sprite.get_animation_state() as SpineAnimationState
		anim_state.set_animation(anim_name)


func update_animation(old_state: eCharacterMovementState, new_state: eCharacterMovementState):
	# NOTE ducked animation is handled in the duck/unduck functions
	if new_state == eCharacterMovementState.RunningDucked:
		return
	
	# we want to transition into falling pose almost immediately after the jump started (it looks so the duck tucks its legs)
	if new_state == eCharacterMovementState.Jumping:
		schedule_animation_update_if_character_movement_state_matches(
			0.1, eCharacterMovementState.Jumping, 'fall'
		)
	
	# HACK when exiting out of dashing, keep the dashing pose for a short instant of time, do not set another anim immediately
	# this is done to let the player contemplate the dashing pose - otherwise it just changes too quickly
	if old_state == eCharacterMovementState.Dashing:
		var next_target_anim_name := animation_map[new_state] as String
		# instead of changing to the anim immediately, transition in a short while if the animation state still matches then
		schedule_animation_update_if_character_movement_state_matches(
			0.1, new_state, next_target_anim_name
		)
		# NOTE if then the state does not match this means the animation has already been updated anyways to another state
	else:
		var anim_state := sprite.get_animation_state() as SpineAnimationState
		anim_state.set_animation(animation_map[new_state], false if new_state == eCharacterMovementState.Dying else true)

func _on_character_movement_state_updated(old: MrDuck.eCharacterMovementState, new: MrDuck.eCharacterMovementState) -> void:
	if new == old:
		return
	
	# dust emission
	if new in [eCharacterMovementState.Running, eCharacterMovementState.RunningDucked]:
		dust_particles.emitting = true
	else:
		dust_particles.emitting = false
		
	# NOTE sometimes a clean-up is needed when a state is removed
	match old:
		eCharacterMovementState.RunningDucked:
			unduck()
			
	match new:
		eCharacterMovementState.Dashing:
			_distance_covered_in_dash = 0.
		eCharacterMovementState.ZeroG:
			_time_elapsed_in_zero_g = 0.
		eCharacterMovementState.RunningDucked:
			duck()
			
	update_animation(old, new)


## duck handling its own damage received event - play animation etc.
func _on_lives_updated(delta: int) -> void:
	if delta < 0: # damage taken
		var anim_state := sprite.get_animation_state() as SpineAnimationState
		anim_state.set_animation('hit', false, 0)
		punch_sfx.play()
		feather_particles.emitting = true
		
		await get_tree().create_timer(0.1).timeout
		duck_hurt_sfx.play()
	else:
		health_obtained.play()


## we want to set animation back to character's movement state after getting hit, this is similar to playing an anim montage in UE
func _on_duck_sprite_animation_completed(spine_sprite: Object, animation_state: Object, track_entry: Object) -> void:
	if (track_entry as SpineTrackEntry).get_animation().get_name() == 'hit':
		update_animation(character_movement_state, character_movement_state)

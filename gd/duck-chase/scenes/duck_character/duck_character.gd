extends CharacterBody2D


class_name MrDuck


@export var max_lives := 4
@export var jump_velocity := -400
## velocity with which the duck will go up while Flying input is pressed
@export var flying_vertical_velocity := 100
@export var speed = 300
@export var max_stamina: float = 100.
## while flying, the rate at which stamina is depleting per second
@export var stamine_flying_cost := 50.
## while not flying, the rate at which stamina is regenerating per second
@export var stamina_regeneration_rate := 10.
@export var jumping_stamina_cost := 25.
@export var can_regenerate_stamina_in_free_fall := true

var stamina := max_stamina
var lives := max_lives

signal lives_updated
signal stamina_updated
signal dead


## whether the duck is flying, free-falling, or is on the ground
enum eCharacterSpatialState {OnTheGround, Flying, FreeFalling}
var character_spatial_state: eCharacterSpatialState


## one-time decrease to stamina
func drain_stamina(amount: float) -> void:
	stamina = max(0., stamina - amount)
	stamina_updated.emit()


## one-time increase to stamina
func get_stamina(amount: float) -> void:
	stamina = min(max_stamina, stamina + amount)
	stamina_updated.emit()


func has_stamina() -> bool:
	return stamina > 0.


## per-frame stamina depletion
func _deplete_stamina(delta: float) -> void:
	drain_stamina(stamine_flying_cost * delta)


## per-frame stamina regeneration
func _regenerate_stamina(delta: float) -> void:
	get_stamina(stamina_regeneration_rate * delta)


## depending on the character state, regenerate or deplete stamina
func _tick_stamina(delta: float) -> void:
	match character_spatial_state:
		eCharacterSpatialState.OnTheGround:
			_regenerate_stamina(delta)
		eCharacterSpatialState.FreeFalling:
			if can_regenerate_stamina_in_free_fall:
				_regenerate_stamina(delta)
		eCharacterSpatialState.Flying:
			_deplete_stamina(delta)


func lose_life():
	lives = max(0, lives - 1)
	lives_updated.emit()
	if lives == 0:
		dead.emit()


func get_life():
	lives = min(3, lives + 1)
	lives_updated.emit()


func _process(delta: float) -> void:
	_tick_stamina(delta)


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if Input.is_action_pressed('jump') and has_stamina():
			character_spatial_state = eCharacterSpatialState.Flying
			velocity.y -= flying_vertical_velocity * delta
		else:
			character_spatial_state = eCharacterSpatialState.FreeFalling
			velocity += get_gravity() * delta * 2.
	else:
		character_spatial_state = eCharacterSpatialState.OnTheGround

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

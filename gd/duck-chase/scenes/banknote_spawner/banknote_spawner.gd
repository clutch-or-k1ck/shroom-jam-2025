extends Node2D
class_name BanknoteSpawner

var _active: bool
var active := false:
	set(val):
		if _active == val:
			return
		_active = val
		if _active:
			spawn_loop()
	get:
		return _active


var time_interval := [3., 5.]
var banknote_velocity := 1000.

var banknote_texture_1 := preload('res://assets/2d/Money_Particle_1.png')
var banknote_texture_2 := preload('res://assets/2d/Money_Particle_2.png')
var banknote_texture_3 := preload('res://assets/2d/Money_Particle_3.png')
var banknote_texture_4 := preload('res://assets/2d/Money_Particle_4.png')

var banknote_textures := [
	banknote_texture_1,
	banknote_texture_2,
	banknote_texture_3,
	banknote_texture_4
]


func configure(emitter: CPUParticles2D, number: int = 1) -> void:
	emitter.texture = banknote_textures[randi_range(0, 3)]
	emitter.lifetime = 5.
	emitter.one_shot = true
	emitter.amount = number
	emitter.direction = Vector2(-1., -0.4)
	emitter.spread = 5.
	emitter.initial_velocity_min = banknote_velocity
	emitter.initial_velocity_max = banknote_velocity
	emitter.gravity = Vector2(0., 300.)
	emitter.angular_velocity_min = -300.
	emitter.angular_velocity_max = 300.
	emitter.scale_amount_min = 0.4
	emitter.scale_amount_max = 0.4
	emitter.finished.connect(emitter.queue_free)
	emitter.explosiveness = 1.
	emitter.emitting = true


func spawn_once(number: int = 1):
	var emitter := CPUParticles2D.new()
	configure(emitter, number)
	add_child(emitter)


func spawn_loop() -> void:
	while active:
		spawn_once()
		await get_tree().create_timer(randf_range(time_interval[0], time_interval[1])).timeout

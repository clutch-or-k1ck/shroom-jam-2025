extends TreadmillComposite

var beacon_radius_min := 20.
var beacon_radius_max := 120.
var beacon_alpha_min := 0.2
var beacon_alpha_max := 0.3
var beacon_frequency := 0.2


## the phase of the red beacon (brightness/size)
var _red_beacon_phase: float
var red_beacon_phase: float:
	set(val):
		_red_beacon_phase = val
		queue_redraw()
	get:
		return _red_beacon_phase
		
## the phase of the blue beacon (brightness/size)
var _blue_beacon_phase: float
var blue_beacon_phase: float:
	set(val):
		_blue_beacon_phase = val
		queue_redraw()
	get:
		return _blue_beacon_phase


func _process(delta: float) -> void:
	print(z_index)


func _ready() -> void:
	# tween the red beacon
	var red_beacon_tween := create_tween()
	red_beacon_tween.tween_property(self, 'red_beacon_phase', 1., beacon_frequency)
	red_beacon_tween.tween_property(self, 'red_beacon_phase', 0., beacon_frequency)
	red_beacon_tween.set_loops()
	red_beacon_tween.set_trans(Tween.TRANS_SINE)
	
	# tween the blue beacon
	var blue_beacon_tween := create_tween()
	blue_beacon_tween.tween_property(self, 'blue_beacon_phase', 0., beacon_frequency)
	blue_beacon_tween.tween_property(self, 'blue_beacon_phase', 1., beacon_frequency)
	blue_beacon_tween.set_loops()
	blue_beacon_tween.set_trans(Tween.TRANS_SINE)

func _draw() -> void:
	super()
	
	# red beacon!
	draw_circle(
		to_local($beacons/red_beacon.global_position), 
		(beacon_radius_max - beacon_radius_min) * red_beacon_phase + beacon_radius_min,
		Color(1., 0., 0., beacon_alpha_min + (beacon_alpha_max - beacon_alpha_min) * red_beacon_phase)
	)
	
	# blue beacon!
	draw_circle(
		to_local($beacons/blue_beacon.global_position), 
		(beacon_radius_max - beacon_radius_min) * blue_beacon_phase + beacon_radius_min,
		Color(0., 0., 1., beacon_alpha_min + (beacon_alpha_max - beacon_alpha_min) * blue_beacon_phase)
	)

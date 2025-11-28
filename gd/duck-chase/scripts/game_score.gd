extends Node


## score accumulation rate per second NOTE we use a value like 7.3 so that the score accumulation doesn't look boring
const _accumulation_rate := 3
# NOTE the score itself is a float but an integer value should be showed in the gui
var _current_score := 0.
## if true, we accumulate the score every frame
var accumulating: bool

signal score_changed(new_score: int)

## returns the highest persisted score
func get_highest_score() -> int:
	if FileAccess.file_exists('user://highest_score.dat'):
		var file = FileAccess.open('user://highest_score.dat', FileAccess.READ)
		var txt := file.get_line()
		if txt.strip_edges() != '' and txt.strip_edges().is_valid_int(): # TODO and parseable int
			return int(txt.strip_edges())
		else:
			return 0
	else:
		return 0


## whether the current score is a personal record
func is_PR() -> bool:
	return get_current_score() >= get_highest_score()


## persists the current score on disc
func persist() -> void:
	var save_score_file := FileAccess.open('user://highest_score.dat', FileAccess.WRITE)
	save_score_file.store_string(str(get_current_score()))


func get_current_score() -> int:
	return round(_current_score)


func set_score(score: float) -> void:
	var old := _current_score
	var new := score
	
	_current_score = new
	if floor(old) < floor(new):
		score_changed.emit(get_current_score())


func reset() -> void:
	set_score(0.)


func _process(delta: float) -> void:
	if accumulating:
		set_score(_current_score + _accumulation_rate*delta)

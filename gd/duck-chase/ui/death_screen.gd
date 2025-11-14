extends TextureRect


## force-display death screen during this time period
var mandatory_display_time := 2.
var elapsed_time := 0.


signal full_game_reset


# displays the death screen
func reset() -> void:
	elapsed_time = 0.

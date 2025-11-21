extends GameMenuBase


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_restart_btn_pressed() -> void:
	Globals.get_chase_scene().restart_game_loop()


func _ready() -> void:
	super()
	header.text = 'score: [color=turquoise]' + str(GameScore.get_current_score()) + '[/color]' + \
		(' (this is your best score so far!)' if GameScore.is_PR() else '')

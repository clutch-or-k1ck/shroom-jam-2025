extends GameMenuBase


func _on_play_btn_pressed() -> void:
	Globals.get_chase_scene().restart_game_loop()


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_controls_btn_focus_entered() -> void:
	pass # TODO set container text to display controls info


func _on_controls_btn_focus_exited() -> void:
	pass # TODO clear container


func _on_credits_btn_focus_entered() -> void:
	pass # TODO set container text to display credits


func _on_credits_btn_focus_exited() -> void:
	pass # TODO clear container

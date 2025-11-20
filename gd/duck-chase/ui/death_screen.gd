extends GameMenuBase


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_restart_btn_pressed() -> void:
	Globals.get_chase_scene().restart_game_loop()

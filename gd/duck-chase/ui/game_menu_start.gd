extends GameMenuBase


var controls_description := preload('res://ui/controls2.tscn')
var credits := preload('res://ui/credits.tscn')


func _on_play_btn_pressed() -> void:
	Globals.get_chase_scene().restart_game_loop()


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func clear_content_container() -> void:
	while content_container.get_children().size() > 0:
		content_container.remove_child(
			content_container.get_child(0)
		)


func _on_controls_btn_focus_entered() -> void:
	content_container.add_child(controls_description.instantiate())


func _on_controls_btn_focus_exited() -> void:
	clear_content_container()


func _on_credits_btn_focus_entered() -> void:
	content_container.add_child(credits.instantiate())


func _on_credits_btn_focus_exited() -> void:
	clear_content_container()

extends GameMenuBase


var controls_scene := preload('res://ui/controls2.tscn')


func _on_resume_btn_pressed() -> void:
	get_tree().paused = false
	Globals.get_chase_scene().remove_ui()


func _on_controls_btn_focus_entered() -> void:
	content_container.add_child(controls_scene.instantiate())


func _on_controls_btn_focus_exited() -> void:
	clear_content_container()


func _on_exit_btn_pressed() -> void:
	get_tree().quit()

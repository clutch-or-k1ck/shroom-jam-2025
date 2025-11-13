extends TextureRect

@onready var play_btn := $global_margins/vertical_layout/main_panel/buttons_section/margins/buttons/play_btn
@onready var exit_btn := $global_margins/vertical_layout/main_panel/buttons_section/margins/buttons/exit_btn

signal begin_game_pressed
signal exit_game_pressed


func toggle_focused_button() -> void:
	if play_btn.has_focus():
		exit_btn.grab_focus()
	elif exit_btn.has_focus():
		play_btn.grab_focus()


func _ready() -> void:
	play_btn.grab_focus()


## handle input
func _process(delta: float) -> void:
	if Input.is_anything_pressed():
		print('pressed')
		
	if Input.is_action_just_pressed('menu_down') or \
			Input.is_action_just_pressed('menu_up') or \
			Input.is_action_just_pressed('menu_right') or \
			Input.is_action_just_pressed('menu_left'):
		toggle_focused_button()
	elif Input.is_action_just_pressed('menu_select'):
		if play_btn.has_focus():
			begin_game_pressed.emit()
		elif exit_btn.has_focus():
			exit_game_pressed.emit()

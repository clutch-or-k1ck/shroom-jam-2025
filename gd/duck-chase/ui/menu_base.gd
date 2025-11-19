extends ColorRect
class_name GameMenuBase


var buttons: Array[Button]
var active_button_idx: int

@onready var buttons_widget := $vbox_layout/hbox_layout/buttons_margins/buttons
@onready var content_container := $vbox_layout/hbox_layout/content_margins/content_container
@onready var header := $vbox_layout/header_margins/header


## collect the buttons from the 'buttons' section of this menu
func collect_buttons() -> Array[Button]:
	var btns: Array[Button] = []
	for child in buttons_widget.get_children():
		if child is Button:
			var btn := child as Button
			btns.append(child as Button)
	return btns


## increment active button index, will loop to the first button if overflows
func increment_active_btn_index() -> void:
	if active_button_idx >= buttons.size() - 1:
		set_active_btn_idx(0)
	else:
		set_active_btn_idx(active_button_idx + 1)


## decrement active button index, will loop to the last button if overflows
func decrement_active_btn_index() -> void:
	if active_button_idx == 0:
		set_active_btn_idx(buttons.size() - 1)
	else:
		set_active_btn_idx(active_button_idx - 1)


## set active button index and change focus
func set_active_btn_idx(idx: int) -> void:
	active_button_idx = idx
	_on_active_btn_idx_changed()


## make a button at a given index grab focus
func _on_active_btn_idx_changed() -> void:
	if active_button_idx < buttons.size():
		buttons[active_button_idx].grab_focus()


## make the button that currently has focus emit its 'pressed' signal
func press_active_button() -> void:
	if active_button_idx < buttons.size():
		buttons[active_button_idx].pressed.emit()


func _ready() -> void:
	buttons = collect_buttons()
	set_active_btn_idx(0)


## listen to menu navigation inputs
func _process(delta: float) -> void:
	if Input.is_action_just_pressed('menu_down'):
		increment_active_btn_index()
	elif Input.is_action_just_pressed('menu_up'):
		decrement_active_btn_index()
	elif Input.is_action_just_pressed('menu_select'):
		press_active_button()

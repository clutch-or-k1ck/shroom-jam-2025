extends Control

## an array of strings that will become news in the running text
@export var breaking_news: Array[String]
## speed of the running text (pixels per second)
@export var running_text_speed: int
## font size in the running text line
@export var running_text_font_size: int = 30


## to keep track of the rich text labels in the running text (need to spwan/despawn)
var running_text_labels: Array[RichTextLabel]
const breaking_news_separator := '   [char=2022]   [color=orange]BREAKING NEWS[/color]   [char=2022]   '

## combines the breaking news items into one long line of rich text
## imagine that 20 separate news will become a single line separated with '***' or similar
func build_long_running_text() -> String:
	return breaking_news_separator.join(breaking_news) + breaking_news_separator


## creates a long rich text label containing all of the breaking news items, separated with a special char
func create_running_text_line() -> RichTextLabel:
	var rich_text_label := RichTextLabel.new()
	rich_text_label.text = build_long_running_text()
	
	# NOTE this will make the rich text label adjust to the font size
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	rich_text_label.fit_content = true

	# font and background (black)
	rich_text_label.add_theme_font_size_override('normal_font_size', running_text_font_size)
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color()
	stylebox.border_width_top = 10.
	stylebox.border_width_bottom = 10.
	stylebox.border_color = Color(1., 0., 0.)
	rich_text_label.add_theme_stylebox_override('normal', stylebox)
	
	rich_text_label.z_index = -1 # NOTE render BEHIND the tv frame
	
	# respect BBCode
	rich_text_label.bbcode_enabled = true
	
	return rich_text_label


func move_running_text(delta: float) -> void:
	for label in running_text_labels:
		label.position += Vector2(running_text_speed, 0) * delta


func is_out_of_bounds(control: Control) -> bool:
	return control.position[0] + control.size[0] < 0


func add_new_running_text_line() -> RichTextLabel:
	var new_rich_text_label := create_running_text_line()
	
	# spawn at the beginning if no labels so far
	if running_text_labels.size() == 0:
		pass
	else:
		new_rich_text_label.position = Vector2(
			running_text_labels[-1].position[0] + running_text_labels[-1].size[0], 0.
		)
		
	running_text_labels.append(new_rich_text_label)
	add_child(new_rich_text_label)
	
	return new_rich_text_label


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_running_text(delta)
	
	if running_text_labels.size() > 0:
		# despawn out-of-bounds labels
		if is_out_of_bounds(running_text_labels[0]):
			remove_child(running_text_labels[0])
			running_text_labels.remove_at(0)
			
		# we always want to have exactly two labels in the news line
		if running_text_labels.size() < 2:
			var next_running_text_label = create_running_text_line()
			var existing_running_text_label = running_text_labels[0]
			
			running_text_labels.append(next_running_text_label)
			add_child(next_running_text_label)
			next_running_text_label.position = existing_running_text_label.position + \
				Vector2(existing_running_text_label.size[0], 0)

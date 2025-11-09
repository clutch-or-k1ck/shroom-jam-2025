extends NinePatchRect

@export var breaking_news: Array[String]
@export var running_text_speed: int

@onready var running_text := $running_text

var breaking_news_idx := 0 # the index of the breaking news we are currently showing


## this will add the next breaking news to the running text
func add_next_breaking_news() -> void:
	# no news to show
	if breaking_news.size() == 0:
		return
		
	# if we scrolled through all the breaking news, go the beginning
	if breaking_news_idx >= breaking_news.size():
		breaking_news_idx = 0
		
	# retrieve position of the very last breaking news line
	var last_breaking_news_corner: int
	if running_text.get_child_count() == 0:
		last_breaking_news_corner = get_viewport_rect().size[0]
		pass # simply add behind the screen
	else:
		var last_breaking_news_label := running_text.get_children()[-1] as Label
		last_breaking_news_corner = last_breaking_news_label.position[0] + last_breaking_news_label.size[0]
	
	# spawn at the last breaking news corner
	var new_breaking_news_label := Label.new()
	new_breaking_news_label.text = breaking_news[breaking_news_idx].to_upper()
	running_text.add_child(new_breaking_news_label)
	new_breaking_news_label.position = Vector2(last_breaking_news_corner, 0.)
	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# keep adding breaking news until at least five are enqueued
	if running_text.get_child_count() < 5:
		add_next_breaking_news()
		
	# adjust children positions accordingly
	for child in running_text.get_children():
		child.position += Vector2(-1.*running_text_speed, 0) * delta

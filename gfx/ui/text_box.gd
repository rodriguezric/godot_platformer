extends MarginContainer

@onready var label: Label = $MarginContainer/Label
@onready var timer: Timer = $Timer

const MAX_WIDTH = 256
var text := ""
var idx := 0

var letter_time := 0.03
var space_time := 0.06
var punctuation_time := 0.2

signal finished_displaying()

func display(text_: String):
	text = text_
	label.text = text
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		# need to await twice to account for x and y
		await resized
		await resized
		
		custom_minimum_size.y = size.y
	global_position.x -= size.x / 2
	global_position.y -= size.y + 24
	label.text = ""
	
	_display_letter()

func _display_letter():
	if idx >= text.length():
		finished_displaying.emit()
		return
		
	label.text += text[idx]
	idx += 1
	
	if idx >= text.length():
		finished_displaying.emit()
		return
	
	match text[idx]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)


func _on_timer_timeout() -> void:
	_display_letter()

func text_remaining() -> int:
	return text.length() - label.text.length()

func fill() -> void:
	label.text = text
	idx = text.length()

extends Node


@onready var text_box_scene = preload("res://gfx/ui/text_box.tscn")

var text_lines: Array[String] = []
var text_lines_idx := 0

var text_box
var text_box_pos: Vector2

var dialog_active := false
var can_advance := false

func start_dialog(pos: Vector2, lines: Array[String]):
    if dialog_active:
        return

    text_lines = lines
    text_box_pos = pos
    _show_text_box()

    dialog_active = true

func _show_text_box():
    text_box = text_box_scene.instantiate()
    text_box.finished_displaying.connect(_on_text_box_finished_displaying)
    get_tree().root.add_child(text_box)
    text_box.global_position = text_box_pos
    text_box.display(text_lines[text_lines_idx])

func _on_text_box_finished_displaying():
    can_advance = true

func _unhandled_input(event: InputEvent) -> void:
    if (
        event.is_action_pressed("advance_text") &&
        dialog_active &&
        can_advance
    ):
        if text_box.text_remaining() > 0:
            text_box.fill()
        else:
            text_box.queue_free()

            text_lines_idx += 1
            if text_lines_idx >= text_lines.size():
                dialog_active = false
                text_lines_idx = 0
                return

            _show_text_box()

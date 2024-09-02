extends Area2D

# This is used for a `"interactable" in area` check 
var interactable

@export var lines: Array[String]
 
func interact():
	DialogManager.start_dialog(global_position, lines)

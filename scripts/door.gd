extends Area2D

@export var target_level :PackedScene
var interactable

func interact():
	get_tree().change_scene_to_packed(target_level)

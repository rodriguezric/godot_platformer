extends Area2D

var touchable
@export var coord : Vector2
@onready var ap: AnimationPlayer = $AnimationPlayer
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	ap.play("idle")

func touch(other):
	sfx.play()
	other.position.x = coord.x
	other.position.y = coord.y

extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@export var damage := 1
var player_ref = null

func _physics_process(delta: float) -> void:
    # Add the gravity.
    if not is_on_floor():
        velocity += get_gravity() * delta

    if player_ref and player_ref.iframes <= 0:
        player_ref.hurt(damage)
        print("HURTING")
    move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
    if "player" in body:
        player_ref = body


func _on_hitbox_body_exited(body: Node2D) -> void:
    if "player" in body:
            player_ref = null

extends CharacterBody2D

# Interface properties
# Use these for testing `"x" in other`
var player

@export var HP = 3
@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var gravity = 1000
@export var IFRAMES = 60
const HURTFRAMES = 8

@onready var ap = $AnimationPlayer
@onready var gfx = $gfx
@onready var sfx: AudioStreamPlayer = $sfx
@onready var interact_gfx: Sprite2D = $interact_gfx
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var height = collision_shape.shape.get_rect().size[1]
@onready var melee_hitbox: Area2D = $melee_hitbox

const JUMP_SFX = preload("res://sfx/jump.ogg")
const DASH_SFX = preload("res://sfx/dash.ogg")
const SLASH_SFX = preload("res://sfx/slash.wav")
const HURT_SFX = preload("res://sfx/hurt.ogg")

var iframes := 0
var hurtframes := 0
var airframes := 0
var dashframes := 0
var walljumpframes := 0
var attackframes := 0
var can_climb := false
var ladder = null
var ladder_top_shape = null
var is_on_ladder_top := false

var direction: global.Direction = global.Direction.RIGHT

const COYOTE_FRAMES = 3
const STANDING_FALLSPEED = 5
const WALLCLING_FRICTION = 0.2
var MAX_FALLSPEED = -JUMP_VELOCITY

enum states {
    IDLE,
    WALKING,
    JUMPING,
    FALLING,
    DASHING,
    WALLCLING,
    WALLJUMP,
    CLIMBING,
    CLIMBING_IDLE,
    ATTACKING,
    WALKING_ATTACKING,
    HURTING,
}
var state = states.IDLE

# Manage collided interactable objs. We only interact with the first obj touched.
var interactables = []

func hurt(damage):
    self.HP -= damage
    self.iframes = IFRAMES
    enter_state(states.HURTING)

func enter_state(_state):
    if _state not in [states.ATTACKING, states.WALKING_ATTACKING]:
        melee_hitbox.monitorable = false
        melee_hitbox.monitoring = false
        melee_hitbox.visible = false

    match _state:
        states.HURTING:
            iframes = IFRAMES
            hurtframes = HURTFRAMES
            ap.play("hurt")
            sfx.stream = HURT_SFX
            sfx.play()
            velocity.x = -direction * SPEED / 2
            velocity.y = JUMP_VELOCITY / 2

        states.ATTACKING:
            attackframes = 8
            ap.play("attack")
            sfx.stream = SLASH_SFX
            sfx.play()

        states.IDLE:
            airframes = 0
            ap.play("idle")

        states.WALKING:
            airframes = 0
            ap.play("walk")

        states.JUMPING:
            ap.play("jump")

        states.FALLING:
            ap.play("fall")

        states.DASHING:
            dashframes = 8
            ap.play("dash")
            velocity.x = 2 * SPEED * direction
            sfx.stream = DASH_SFX
            sfx.play()

        states.WALLCLING:
            ap.play("wallcling")
            velocity.y *= WALLCLING_FRICTION

        states.WALLJUMP:
            walljumpframes = 16
            ap.play("dash")
            direction *= -1
            scale.x = -1
            velocity.x = SPEED * direction

        states.CLIMBING_IDLE:
            position.x = ladder.global_position.x
            ap.play("climbing_idle")

        states.CLIMBING:
            ap.play("climbing")

    state = _state

func _gravity(delta, friction=1):
    if not is_on_floor():
        velocity.y += gravity * delta * friction
        velocity.y = min(MAX_FALLSPEED * friction, velocity.y)
    else:
        velocity.y = STANDING_FALLSPEED

func _movement_input():
    var direction = Input.get_axis("ui_left", "ui_right")
    if direction:
        velocity.x = lerp(velocity.x, direction * SPEED, 0.5)
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

func _attack_input():
    if Input.is_action_just_pressed("platformer_attack"):
        enter_state(states.ATTACKING)

func _interact_input():
    if interactables:
        if Input.is_action_just_pressed("ui_up"):
            interactables[0].interact()

func _ladder_input():
    if can_climb:
        if Input.is_action_just_pressed("ui_up"):
            velocity.x = 0
            enter_state(states.CLIMBING_IDLE)

        if Input.is_action_just_pressed("ui_down"):
            velocity.x = 0
            position.y += 8
            enter_state(states.CLIMBING_IDLE)

func _climb_input():
    var direction = Input.get_axis("ui_up", "ui_down")
    if direction:
        velocity.y = lerp(velocity.x, direction * SPEED / 2, 0.5)
    else:
        velocity.y = 0

func _jump_input():
    if Input.is_action_just_pressed("platformer_jump") and airframes < COYOTE_FRAMES:
        velocity.y = JUMP_VELOCITY
        sfx.stream = JUMP_SFX
        sfx.play()

func _ladder_release_input():
    if Input.is_action_just_pressed("platformer_jump"):
        enter_state(states.FALLING)

func _walljump_input():
    if Input.is_action_just_pressed("platformer_jump"):
        velocity.y = JUMP_VELOCITY
        sfx.stream = JUMP_SFX
        sfx.play()
        enter_state(states.WALLJUMP)

func _dash_input():
    return Input.is_action_just_pressed("platformer_dash")

func _flip_logic():
    if state == states.HURTING:
        return

    if velocity.x < 0:
        if direction != global.Direction.LEFT:
            scale.x = -1
        direction = global.Direction.LEFT

    if velocity.x > 0:
        if direction != global.Direction.RIGHT:
            scale.x = -1

        direction = global.Direction.RIGHT


func _interact_gfx_logic():
    """
    Displays or hides the interact arrow above the player if the player is touching any
    interactable objects.
    """
    interact_gfx.visible = false
    if interactables:
        interact_gfx.visible = true

func move_on_top(shape):
    """
    This is a bit of a hack to pop to the top of the ladder when climbing up
    We do the following:
      1. Move 1 pixel above the top of the ladder
      2. Set our velocity down so we don't have a frame in the air
      3. Call `move_and_slide` to collide with the top of the ladder
    """
    position.y = shape.global_position.y - 1
    velocity.y = STANDING_FALLSPEED
    move_and_slide()

func _ready():
    enter_state(states.IDLE)

func _physics_process(delta):
    if iframes > 0:
        iframes -= 1

    match state:
        states.HURTING:
            _gravity(delta)

            if iframes % 4 == 0:
                gfx.visible = not gfx.visible

            if hurtframes == 0:
                gfx.visible = true
                velocity.x = 0
                enter_state(states.IDLE)

            hurtframes -= 1

        states.ATTACKING:
            _movement_input()
            _gravity(delta)

            attackframes -= 1
            if attackframes <= 0:
                enter_state(states.IDLE)

        states.IDLE:
            _gravity(delta)
            _movement_input()
            _jump_input()
            _interact_input()
            _ladder_input()
            _attack_input()

            if velocity.y >  STANDING_FALLSPEED:
                enter_state(states.FALLING)

            if velocity.y < 0:
                enter_state(states.JUMPING)

            if velocity.x != 0:
                enter_state(states.WALKING)

            if _dash_input():
                enter_state(states.DASHING)

        states.WALKING:
            _gravity(delta)
            _movement_input()
            _jump_input()
            _interact_input()
            _ladder_input()
            _attack_input()

            if velocity.y > STANDING_FALLSPEED:
                enter_state(states.FALLING)

            if velocity.y < 0:
                enter_state(states.JUMPING)

            if velocity.x == 0:
                enter_state(states.IDLE)

            if _dash_input():
                enter_state(states.DASHING)

        states.JUMPING:
            _gravity(delta)
            _movement_input()
            _jump_input()
            _ladder_input()
            _attack_input()

            airframes += 1

            if velocity.y == STANDING_FALLSPEED:
                enter_state(states.IDLE)

            if velocity.y > 0:
                enter_state(states.FALLING)

            if is_on_wall():
                enter_state(states.WALLCLING)

        states.FALLING:
            _gravity(delta)
            _movement_input()
            _jump_input()
            _ladder_input()
            _attack_input()

            airframes += 1

            if velocity.y == STANDING_FALLSPEED:
                enter_state(states.IDLE)

            if velocity.y < 0:
                enter_state(states.JUMPING)

            if is_on_wall():
                enter_state(states.WALLCLING)

        states.DASHING:
            _gravity(delta)
            _jump_input()

            if dashframes <= 0:
                enter_state(states.IDLE)

            if not is_on_floor():
                airframes += 1

            dashframes -= 1

        states.WALLCLING:
            _gravity(delta, WALLCLING_FRICTION)
            _movement_input()
            _walljump_input()

            airframes += 1

            if velocity.y == STANDING_FALLSPEED:
                enter_state(states.IDLE)

            if not is_on_wall():
                enter_state(states.FALLING)

        states.WALLJUMP:
            _gravity(delta)

            walljumpframes -= 1
            airframes += 1

            if walljumpframes <= 0:
                enter_state(states.JUMPING)

            if velocity.y == STANDING_FALLSPEED:
                enter_state(states.IDLE)

            if velocity.y > 0:
                enter_state(states.FALLING)

            if is_on_wall():
                enter_state(states.WALLCLING)

        states.CLIMBING_IDLE:
            _climb_input()
            _ladder_release_input()

            if velocity.y != 0:
                enter_state(states.CLIMBING)

        states.CLIMBING:
            _climb_input()
            _ladder_release_input()

            if is_on_floor():
                enter_state(states.IDLE)
                return

            if not can_climb:
                enter_state(states.IDLE)
                return

            if velocity.y == 0:
                enter_state(states.CLIMBING_IDLE)

            if velocity.y < 0 and is_on_ladder_top:
                move_on_top(ladder_top_shape)
                enter_state(states.IDLE)

    _flip_logic()
    _interact_gfx_logic()
    move_and_slide()

func _on_area_2d_area_entered(area: Area2D) -> void:
    if "interactable" in area:
        interactables.append(area)

    if "touchable" in area:
        area.touch(self)

    if "ladder" in area:
        can_climb = true
        ladder = area

func _on_area_2d_area_exited(area: Area2D) -> void:
    if "interactable" in area:
        var idx = interactables.find(area)
        if idx >= 0:
            interactables.remove_at(idx)

    if "ladder" in area:
        can_climb = false
        ladder = null

func _on_area_2d_body_entered(body: Node2D) -> void:
    if "ladder_top" in body:
        is_on_ladder_top = true
        ladder_top_shape = body.collision_shape

func _on_area_2d_body_exited(body: Node2D) -> void:
    if "ladder_top" in body:
        is_on_ladder_top = false
        ladder_top_shape = null

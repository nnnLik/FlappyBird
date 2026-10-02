extends Node2D

const GRAVITY: float = 350.0
const FLY_FORCE: float = -250.0

const ROTATION_UP: float = -35.0
const ROTATION_DOWN: float = 35.0
const ROTATION_LERP_SPEED: float = 10.0

const FLAP_VELOCITY_THRESHOLD: float = 50.0
const START_POSITION_DIVISOR: float = 4.0
const GROUND_MARGIN: float = 4.0

const DOWNFLAP_FRAME: Texture2D = preload("res://assets/Game Objects/yellowbird-downflap.png")
const MIDFLAP_FRAME: Texture2D = preload("res://assets/Game Objects/yellowbird-midflap.png")
const UPFLAP_FRAME: Texture2D = preload("res://assets/Game Objects/yellowbird-upflap.png")

signal started
signal flapped
signal died(ground_hit: bool)

@export var velocity: float = 0.0
@export var is_started: bool = false

var is_dead: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("bird")
	reset_to_ready()
	_hitbox.area_entered.connect(_on_hitbox_area_entered)

func reset_to_ready() -> void:
	is_dead = false
	is_started = false
	velocity = 0.0
	global_position = get_viewport_rect().size / START_POSITION_DIVISOR
	_sprite.texture = MIDFLAP_FRAME
	_sprite.rotation_degrees = 0.0

func _handle_start() -> void:
	if is_dead or is_started:
		return
	if Input.is_action_just_released("jump"):
		is_started = true
		velocity = FLY_FORCE
		started.emit()

func _handle_texture_render() -> void:
	if velocity > FLAP_VELOCITY_THRESHOLD:
		_sprite.texture = DOWNFLAP_FRAME
	elif velocity < FLAP_VELOCITY_THRESHOLD:
		_sprite.texture = UPFLAP_FRAME
	else:
		_sprite.texture = MIDFLAP_FRAME

func _handle_rotation(delta: float) -> void:
	var target_rotation: float
	if velocity < 0.0:
		target_rotation = ROTATION_UP
	else:
		target_rotation = ROTATION_DOWN

	_sprite.rotation_degrees = lerp(
		_sprite.rotation_degrees,
		target_rotation,
		ROTATION_LERP_SPEED * delta
	)

func _check_bounds() -> void:
	var vh := get_viewport_rect().size.y
	if global_position.y <= GROUND_MARGIN or global_position.y >= vh - GROUND_MARGIN:
		__die(true)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead or not is_started:
		return
	if area.is_in_group("pipe_hitbox"):
		__die(false)

func __die(ground_hit: bool) -> void:
	if is_dead:
		return
	is_dead = true
	died.emit(ground_hit)

func _process(delta: float) -> void:
	if is_dead:
		return

	_handle_start()

	if not is_started:
		return

	velocity += GRAVITY * delta
	position.y += velocity * delta

	if Input.is_action_just_released("jump"):
		velocity = FLY_FORCE
		flapped.emit()

	_handle_rotation(delta)
	_handle_texture_render()
	_check_pipe_collision()
	_check_bounds()

func _check_pipe_collision() -> void:
	for area in _hitbox.get_overlapping_areas():
		if area.is_in_group("pipe_hitbox"):
			__die(false)
			return

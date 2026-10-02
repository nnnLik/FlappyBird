extends Node2D

const GRAVITY: float = 350.0
const FLY_FORCE: float = -250.0

const ROTATION_UP: float = -35.0
const ROTATION_DOWN: float = 35.0
const ROTATION_LERP_SPEED: float = 10.0

const FLAP_VELOCITY_THRESHOLD: float = 50.0
const START_POSITION_DIVISOR: float = 4.0

const HIT_RADIUS: float = 8.0
const CEILING_Y: float = 8.0
const FLOOR_Y: float = 468.0

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

func _ready() -> void:
	add_to_group("bird")
	reset_to_ready()

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
	var center := _sprite.global_position
	if center.y <= CEILING_Y or center.y >= FLOOR_Y:
		__die(true)

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
	var center := _sprite.global_position

	for pipe in get_tree().get_nodes_in_group("pipes"):
		if not pipe.is_processing():
			continue
		for rect in pipe.get_damage_rects_global():
			if __circle_intersects_rect(center, HIT_RADIUS, rect):
				__die(false)
				return

func __circle_intersects_rect(center: Vector2, radius: float, rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(center.x, rect.position.x, rect.end.x),
		clampf(center.y, rect.position.y, rect.end.y)
	)
	return center.distance_squared_to(closest) <= radius * radius

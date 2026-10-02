extends Node2D

signal scored

enum PipeType { BOTH, TOP, BOTTOM }

const PIPE_SPEED: int = 100

const GAP_SIZE: int = 150
const PIPE_WIDTH: int = 52
const DESPAWN_MARGIN: int = 20

const GAP_CENTER_MARGIN: int = 80
const SINGLE_PIPE_MIN_LENGTH: int = 120

@onready var top_pipe: Sprite2D = $TopPipeSprite
@onready var bottom_pipe: Sprite2D = $BottomPipeSprite
@onready var top_hitbox: Area2D = $TopHitbox
@onready var bottom_hitbox: Area2D = $BottomHitbox

var gap_center_y: float = 0.0
var pipe_type: PipeType = PipeType.BOTH
var _scored: bool = false

func _ready() -> void:
	top_hitbox.add_to_group("pipe_hitbox")
	bottom_hitbox.add_to_group("pipe_hitbox")
	pipe_type = __pick_type()
	gap_center_y = __random_gap_center()
	__setup_pipes()
	__place_at_spawn_if_needed()

func __place_at_spawn_if_needed() -> void:
	if not is_zero_approx(position.x):
		return
	var vw := get_viewport_rect().size.x
	position.x = vw + PIPE_WIDTH * 0.5

func __pick_type() -> PipeType:
	match randi_range(0, 2):
		0:
			return PipeType.BOTH
		1:
			return PipeType.TOP
		_:
			return PipeType.BOTTOM

func __random_gap_center() -> float:
	var vh := get_viewport_rect().size.y
	var half_gap := GAP_SIZE * 0.5

	match pipe_type:
		PipeType.BOTH:
			return randf_range(
				half_gap + GAP_CENTER_MARGIN,
				vh - half_gap - GAP_CENTER_MARGIN
			)
		PipeType.TOP:
			return randf_range(
				float(SINGLE_PIPE_MIN_LENGTH),
				vh - GAP_CENTER_MARGIN
			)
		PipeType.BOTTOM:
			return randf_range(
				GAP_CENTER_MARGIN,
				vh - SINGLE_PIPE_MIN_LENGTH
			)
		_:
			return vh * 0.5

func __setup_pipes() -> void:
	top_pipe.visible = false
	bottom_pipe.visible = false
	top_hitbox.monitorable = false
	bottom_hitbox.monitorable = false

	var vh := get_viewport_rect().size.y

	match pipe_type:
		PipeType.BOTH:
			top_pipe.visible = true
			bottom_pipe.visible = true
			_fit_pipe(top_pipe, top_hitbox, 0.0, gap_center_y - GAP_SIZE * 0.5, true)
			_fit_pipe(bottom_pipe, bottom_hitbox, gap_center_y + GAP_SIZE * 0.5, vh, false)

		PipeType.TOP:
			top_pipe.visible = true
			_fit_pipe(top_pipe, top_hitbox, 0.0, gap_center_y, true)

		PipeType.BOTTOM:
			bottom_pipe.visible = true
			_fit_pipe(bottom_pipe, bottom_hitbox, gap_center_y, vh, false)

func _fit_pipe(
	pipe: Sprite2D,
	hitbox: Area2D,
	top_y: float,
	bottom_y: float,
	hangs_from_ceiling: bool
) -> void:
	var h := maxf(bottom_y - top_y, 1.0)
	var tex_h := float(pipe.texture.get_height())
	var scale_y := h / tex_h

	pipe.flip_v = false
	pipe.scale = Vector2(1.0, -scale_y if hangs_from_ceiling else scale_y)
	pipe.position = Vector2(0.0, top_y + h * 0.5)

	hitbox.position = pipe.position
	hitbox.monitorable = true
	var shape_node := hitbox.get_node("CollisionShape2D") as CollisionShape2D
	var rect := shape_node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		shape_node.shape = rect
	rect.size = Vector2(PIPE_WIDTH, h)

func _visual_right_edge_x() -> float:
	var half_w := PIPE_WIDTH * 0.5
	var edge := position.x - half_w
	for pipe in [top_pipe, bottom_pipe]:
		if pipe.visible:
			edge = maxf(edge, position.x + pipe.position.x + half_w)
	return edge

func __try_score() -> void:
	if _scored:
		return
	var bird_node := get_tree().get_first_node_in_group("bird")
	if bird_node == null or not bird_node.is_started or bird_node.is_dead:
		return
	if bird_node.global_position.x > global_position.x:
		_scored = true
		scored.emit()

func _process(delta: float) -> void:
	position.x -= PIPE_SPEED * delta
	__try_score()

	if _visual_right_edge_x() < -DESPAWN_MARGIN:
		queue_free()

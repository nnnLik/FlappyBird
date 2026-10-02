extends Node2D

signal scored

enum PipeType { BOTH, TOP, BOTTOM }

const PIPE_TEXTURE: Texture2D = preload("res://assets/Game Objects/pipe-green.png")

const PIPE_SPEED: int = 100
const GAP_SIZE: int = 150
const PIPE_WIDTH: int = 52
const DESPAWN_MARGIN: int = 20

const GAP_CENTER_MARGIN: int = 80
const SINGLE_PIPE_MIN_LENGTH: int = 120

const CAP_HEIGHT: int = 26
const BODY_TILE_HEIGHT: int = 26
# Линия щели / геймплея (совпадает с bird.FLOOR_Y)
const PLAYFIELD_FLOOR_Y: float = 468.0

@onready var top_column: Node2D = $TopColumn
@onready var bottom_column: Node2D = $BottomColumn

var gap_center_y: float = 0.0
var pipe_type: PipeType = PipeType.BOTH
var _scored: bool = false

func _ready() -> void:
	add_to_group("pipes")
	pipe_type = __pick_type()
	gap_center_y = __random_gap_center()
	__setup_pipes()
	__place_at_spawn_if_needed()

func get_damage_rects_global() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for column in [top_column, bottom_column]:
		if not column.visible:
			continue
		for child in column.get_children():
			if child is Sprite2D:
				rects.append(__sprite_global_rect(child as Sprite2D))
	return rects

func __sprite_global_rect(sprite: Sprite2D) -> Rect2:
	return sprite.global_transform * sprite.get_rect()

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
	var half_gap := GAP_SIZE * 0.5

	match pipe_type:
		PipeType.BOTH:
			return randf_range(
				half_gap + GAP_CENTER_MARGIN,
				PLAYFIELD_FLOOR_Y - half_gap - GAP_CENTER_MARGIN
			)
		PipeType.TOP:
			return randf_range(
				float(SINGLE_PIPE_MIN_LENGTH),
				PLAYFIELD_FLOOR_Y - GAP_CENTER_MARGIN
			)
		PipeType.BOTTOM:
			return randf_range(
				GAP_CENTER_MARGIN,
				PLAYFIELD_FLOOR_Y - SINGLE_PIPE_MIN_LENGTH
			)
		_:
			return PLAYFIELD_FLOOR_Y * 0.5

func __pipe_visual_bottom_y() -> float:
	return get_viewport_rect().size.y

func __setup_pipes() -> void:
	top_column.visible = false
	bottom_column.visible = false

	match pipe_type:
		PipeType.BOTH:
			top_column.visible = true
			bottom_column.visible = true
			__build_column(top_column, 0.0, gap_center_y - GAP_SIZE * 0.5, true)
			__build_column(
				bottom_column,
				gap_center_y + GAP_SIZE * 0.5,
				__pipe_visual_bottom_y(),
				false
			)

		PipeType.TOP:
			top_column.visible = true
			__build_column(top_column, 0.0, gap_center_y, true)

		PipeType.BOTTOM:
			bottom_column.visible = true
			__build_column(bottom_column, gap_center_y, __pipe_visual_bottom_y(), false)

func __clear_column(column: Node2D) -> void:
	for child in column.get_children():
		column.remove_child(child)
		child.free()

func __build_column(
	column: Node2D,
	top_y: float,
	bottom_y: float,
	cap_at_bottom: bool
) -> void:
	__clear_column(column)

	var segment_h := maxf(bottom_y - top_y, float(CAP_HEIGHT))
	var body_h := maxf(segment_h - float(CAP_HEIGHT), 0.0)

	if cap_at_bottom:
		__fill_body_tiles(column, top_y, body_h)
		__add_cap_sprite(column, bottom_y - float(CAP_HEIGHT) * 0.5, true)
	else:
		__add_cap_sprite(column, top_y + float(CAP_HEIGHT) * 0.5, false)
		__fill_body_tiles(column, top_y + float(CAP_HEIGHT), body_h)

func __add_cap_sprite(column: Node2D, center_y: float, flip_cap: bool) -> void:
	var cap := Sprite2D.new()
	cap.texture = PIPE_TEXTURE
	cap.region_enabled = true
	cap.region_rect = Rect2(0.0, 0.0, float(PIPE_WIDTH), float(CAP_HEIGHT))
	cap.centered = true
	cap.flip_v = flip_cap
	cap.position = Vector2(0.0, center_y)
	column.add_child(cap)

func __fill_body_tiles(column: Node2D, start_y: float, height: float) -> void:
	if height <= 0.0:
		return

	var y := start_y
	var remaining := height
	var tex_h := PIPE_TEXTURE.get_height()
	var body_source_h := maxf(float(tex_h - CAP_HEIGHT), float(BODY_TILE_HEIGHT))

	while remaining > 0.0:
		var tile_h := minf(float(BODY_TILE_HEIGHT), remaining)
		var src_h := minf(body_source_h, tile_h)
		var body := Sprite2D.new()
		body.texture = PIPE_TEXTURE
		body.region_enabled = true
		body.region_rect = Rect2(0.0, float(CAP_HEIGHT), float(PIPE_WIDTH), src_h)
		body.centered = true
		body.position = Vector2(0.0, y + tile_h * 0.5)
		column.add_child(body)
		y += tile_h
		remaining -= tile_h

func _visual_right_edge_x() -> float:
	return position.x + PIPE_WIDTH * 0.5

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

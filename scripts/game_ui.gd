extends CanvasLayer

const DIGIT_TEXTURES: Array[Texture2D] = [
	preload("res://assets/UI/Numbers/0.png"),
	preload("res://assets/UI/Numbers/1.png"),
	preload("res://assets/UI/Numbers/2.png"),
	preload("res://assets/UI/Numbers/3.png"),
	preload("res://assets/UI/Numbers/4.png"),
	preload("res://assets/UI/Numbers/5.png"),
	preload("res://assets/UI/Numbers/6.png"),
	preload("res://assets/UI/Numbers/7.png"),
	preload("res://assets/UI/Numbers/8.png"),
	preload("res://assets/UI/Numbers/9.png"),
]

const DIGIT_SPACING: float = 24.0

@onready var _message: Sprite2D = $Message
@onready var _game_over: Sprite2D = $GameOver
@onready var _score_root: Node2D = $Score

func _ready() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	_message.position = center + Vector2(0.0, -70.0)
	_game_over.position = center + Vector2(0.0, 20.0)
	_score_root.position = Vector2(center.x, 48.0)
	set_score(0, false)

func show_ready() -> void:
	_message.visible = true
	_game_over.visible = false
	set_score(0, false)

func hide_message() -> void:
	_message.visible = false
	set_score(0, true)

func show_game_over() -> void:
	_message.visible = false
	_game_over.visible = true

func set_score(value: int, visible: bool = true) -> void:
	for child in _score_root.get_children():
		child.queue_free()

	_score_root.visible = visible
	if not visible:
		return

	var text := str(maxi(value, 0))
	var total_width := float(text.length()) * DIGIT_SPACING
	var start_x := -total_width * 0.5 + DIGIT_SPACING * 0.5

	for i in text.length():
		var digit := int(text[i])
		var sprite := Sprite2D.new()
		sprite.texture = DIGIT_TEXTURES[digit]
		sprite.position = Vector2(start_x + float(i) * DIGIT_SPACING, 0.0)
		_score_root.add_child(sprite)

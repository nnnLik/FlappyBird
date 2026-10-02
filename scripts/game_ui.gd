extends CanvasLayer

@onready var _message: Sprite2D = $Message
@onready var _game_over: Sprite2D = $GameOver

func _ready() -> void:
	var center := get_viewport().get_visible_rect().size * 0.5
	_message.position = center + Vector2(0.0, -70.0)
	_game_over.position = center + Vector2(0.0, 20.0)

func show_ready() -> void:
	_message.visible = true
	_game_over.visible = false

func hide_message() -> void:
	_message.visible = false

func show_game_over() -> void:
	_message.visible = false
	_game_over.visible = true

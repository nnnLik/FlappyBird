extends Node2D

enum GameState { READY, PLAYING, DEAD }

const PIPE_SCENE: PackedScene = preload("res://scn/pipe.tscn")
const SPAWN_INTERVAL: float = 2.25

const SFX_WING: AudioStream = preload("res://assets/Sound Efects/wing.wav")
const SFX_POINT: AudioStream = preload("res://assets/Sound Efects/point.wav")
const SFX_HIT: AudioStream = preload("res://assets/Sound Efects/hit.wav")
const SFX_DIE: AudioStream = preload("res://assets/Sound Efects/die.wav")
const SFX_SWOOSH: AudioStream = preload("res://assets/Sound Efects/swoosh.wav")

@onready var bird = $Bird
@onready var pipes_root: Node2D = $Pipes
@onready var game_ui: CanvasLayer = $GameUI
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

var _state: GameState = GameState.READY
var _spawn_timer: float = 0.0
var _score: int = 0

func _ready() -> void:
	_spawn_timer = SPAWN_INTERVAL * 0.5
	bird.started.connect(_on_bird_started)
	bird.flapped.connect(_on_bird_flapped)
	bird.died.connect(_on_bird_died)
	game_ui.show_ready()

func _process(delta: float) -> void:
	if _state == GameState.DEAD:
		if Input.is_action_just_released("jump"):
			__reset_to_initial()
		return

	if _state != GameState.PLAYING:
		return

	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return

	_spawn_timer = SPAWN_INTERVAL
	__spawn_pipe()

func _on_bird_started() -> void:
	if _state != GameState.READY:
		return
	_state = GameState.PLAYING
	game_ui.hide_message()
	__play_sfx(SFX_SWOOSH)

func _on_bird_flapped() -> void:
	if _state == GameState.PLAYING:
		__play_sfx(SFX_WING)

func _on_bird_died(ground_hit: bool) -> void:
	if _state != GameState.PLAYING:
		return
	_state = GameState.DEAD
	game_ui.show_game_over()
	__play_sfx(SFX_DIE if ground_hit else SFX_HIT)
	__stop_gameplay()

func _on_pipe_scored() -> void:
	if _state != GameState.PLAYING:
		return
	_score += 1
	game_ui.set_score(_score)
	__play_sfx(SFX_POINT)

func __spawn_pipe() -> void:
	var pipe: Node2D = PIPE_SCENE.instantiate()
	pipe.scored.connect(_on_pipe_scored)
	pipes_root.add_child(pipe)

func __stop_gameplay() -> void:
	for child in pipes_root.get_children():
		child.set_process(false)
	bird.set_process(false)

func __reset_to_initial() -> void:
	for child in pipes_root.get_children():
		child.queue_free()
	bird.reset_to_ready()
	bird.set_process(true)
	_score = 0
	_state = GameState.READY
	_spawn_timer = SPAWN_INTERVAL * 0.5
	game_ui.show_ready()

func __play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()

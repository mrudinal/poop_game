extends CharacterBody2D

const SPEED := 250.0
const JUMP_VELOCITY := -500.0
const QUAKE_DURATION := 4.0  # each quake lasts 4 seconds after its start

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

@export var out_margin: float = 50.0
@export var ball_scene: PackedScene
@export var spawn_offset_y: float = 24.0
@onready var spawn_point: Node2D = $player_image/PoopSpawnPoint
@onready var player: Node2D = $player_image

# Terremoto (using Variables.quake_start_times)
@export var quake_speed_mult: float = 1.6      # multiplicador de velocidad durante el terremoto
var _elapsed: float = 0.0
var _quake_active: bool = false

var _cam: Camera2D
var _half_h: float = 0.0

func _enter_tree() -> void:
	global_position = Vector2(Variables.start_pos_x, Variables.start_pos_y)  # snap before first frame
	velocity = Vector2.ZERO
	reset_physics_interpolation()

func _ready() -> void:
	_cam = get_viewport().get_camera_2d()
	_half_h = float(get_viewport_rect().size.y) * 0.5

func _physics_process(delta):
	# acumular tiempo
	_elapsed += delta

	if not is_on_floor():
		velocity.y += gravity * delta * 1.5

	# salto y spawn de "poop"
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up"):
		velocity.y = JUMP_VELOCITY
		if ball_scene and spawn_point:
			var ball := ball_scene.instantiate()
			ball.global_position = spawn_point.global_position
			get_parent().add_child(ball)
			print("character is at ", player.global_position)
			print("spawned poop at ", ball.global_position)

	# --- velocidad según ventanas de terremoto (usando Variables.quake_start_times) ---
	var any_quake_active := false
	if Variables and Variables.quake_start_times.size() > 0:
		for t in Variables.quake_start_times:
			if _elapsed >= t and _elapsed <= t + QUAKE_DURATION:
				any_quake_active = true
				break

	# logs al entrar/salir de cualquier ventana
	if any_quake_active and not _quake_active:
		_quake_active = true
		print("Quake START at ", snapped(_elapsed, 0.01), "s (speed x", quake_speed_mult, ")")
	elif not any_quake_active and _quake_active:
		_quake_active = false
		print("Quake END at ", snapped(_elapsed, 0.01), "s (speed normal)")

	var speed_now := SPEED * (quake_speed_mult if any_quake_active else 1.0)
	velocity.x = speed_now

	move_and_slide()

	# perder si sale de la vista vertical
	if _cam:
		var top_y    := _cam.global_position.y - _half_h - out_margin
		var bottom_y := _cam.global_position.y + _half_h + out_margin
		if global_position.y < top_y or global_position.y > bottom_y:
			get_tree().reload_current_scene()

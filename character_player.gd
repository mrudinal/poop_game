extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var out_margin: float = 50.0
@export var ball_scene: PackedScene
@export var spawn_offset_y: float = 24.0
@onready var spawn_point: Node2D = $player_image/PoopSpawnPoint
@onready var player: Node2D = $player_image

# --- NUEVO: control de "terremoto" ---
@export var quake_start_s: float = 19.6     # segundo en el que inicia el terremoto
@export var quake_end_s: float = 23.4        # segundo en el que termina el terremoto
@export var quake_speed_mult: float = 1.6   # multiplicador de velocidad durante el terremoto
var _elapsed: float = 0.0                   # tiempo transcurrido desde que cargó la escena
var _quake_active: bool = false             # estado actual (para prints de depuración)

var _cam: Camera2D
var _half_h: float = 0.0

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

	# --- velocidad según ventana de terremoto ---
	var in_quake_window := (_elapsed >= quake_start_s and _elapsed <= quake_end_s)
	if in_quake_window and not _quake_active:
		_quake_active = true
		print("Quake START at ", _elapsed, "s (speed x", quake_speed_mult, ")")
	elif not in_quake_window and _quake_active:
		_quake_active = false
		print("Quake END at ", _elapsed, "s (speed normal)")

	var speed_now := SPEED * (quake_speed_mult if in_quake_window else 1.0)
	velocity.x = speed_now

	move_and_slide()

	# perder si sale de la vista vertical
	if _cam:
		var top_y    := _cam.global_position.y - _half_h - out_margin
		var bottom_y := _cam.global_position.y + _half_h + out_margin
		if global_position.y < top_y or global_position.y > bottom_y:
			get_tree().reload_current_scene()

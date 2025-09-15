extends Area2D

@export var trigger_distance_x: float = 150.0  # trigger when player is this close on the LEFT
@export var drop_amount: float = 350.0          # pixels to drop (down is +Y)
@export var drop_speed: float = 2000.0          # pixels/sec
@export var player_path: NodePath              # optional; otherwise we find by group "player"

var _player: Node2D
var _dropping := false
var _armed := true           # NEW: only allow one drop
var _initial_y := 0.0
var _target_y := 0.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Player hit the toilet!")
		#get_tree().reload_current_scene()

func _ready() -> void:
	_initial_y = global_position.y
	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")

func _process(delta: float) -> void:
	if _player == null:
		return

	# Distance: positive if player is to the LEFT of this toilet
	var dx := global_position.x - _player.global_position.x

	# Start drop ONCE when armed and within band on the left
	if _armed and not _dropping and dx >= 0.0 and dx <= trigger_distance_x:
		_dropping = true
		_target_y = _initial_y + drop_amount

	# Perform the drop toward target
	if _dropping:
		global_position.y = min(global_position.y + drop_speed * delta, _target_y)
		if global_position.y >= _target_y:
			_dropping = false
			_armed = false   # disarm so it won't trigger again

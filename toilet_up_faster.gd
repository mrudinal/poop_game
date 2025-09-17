extends Area2D

@export var trigger_distance_x: float = 200.0  # trigger when player is this close on the LEFT
@export var up_amount: float = 350.0          # pixels to drop (down is +Y)
@export var up_speed: float = 3000.0          # pixels/sec
@export var player_path: NodePath              # optional; otherwise we find by group "player"

var _player: Node2D
var _upping := false
var _armed := true           # NEW: only allow one drop
var _initial_y := 0.0
var _target_y := 0.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Player hit the toilet!")
		Variables.reset()
	
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
	if _armed and not _upping and dx >= 0.0 and dx <= trigger_distance_x:
		_upping = true
		_target_y = _initial_y - up_amount

	# Perform the drop toward target
	if _upping:
		global_position.y = max(global_position.y - up_speed * delta, _target_y)
		if global_position.y <= _target_y:
			_upping = false
			_armed = false   # disarm so it won't trigger again

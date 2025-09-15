extends Camera2D

@export var target: NodePath        # drag your character_player here
@export var fixed_y: float = 360.0  # Y center for 1280x720

var _t: Node2D                      # will hold the actual node reference

func _ready() -> void:
	enabled = true
	set_as_top_level(true)          # prevent inheriting parent's transform
	_t = get_node_or_null(target)   # resolve the NodePath into a node
	if _t == null:
		push_error("Camera target not found: assign 'character_player' to target in Inspector.")

func _physics_process(delta: float) -> void:
	if _t:
		global_position.x = _t.global_position.x + 300
		global_position.y = fixed_y

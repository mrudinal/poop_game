extends Camera2D

# @export places the variable in Inspector
@export var target: NodePath
var fixed_y: float = 360.0  # Y center for 1280x720
@export var character_player: Node2D                      # will hold the actual node reference

func _ready() -> void:
	enabled = true
	set_as_top_level(true)          # prevent inheriting parent's transform
	character_player = get_node_or_null(target)   # resolve the NodePath into a node
	make_current()   
	if character_player == null:
		push_error("Camera target not found: assign 'character_player' to target in Inspector.")
	# --- SNAP camera X immediately so first frame is correct ---
	if character_player != null:
		global_position.x = character_player.global_position.x + 200  # same offset as in _physics_process
		global_position.y = fixed_y
		
func _physics_process(delta: float) -> void:
	if character_player:
		global_position.x = character_player.global_position.x + 200
		global_position.y = fixed_y

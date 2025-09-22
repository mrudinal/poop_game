extends Camera2D

@export var target: NodePath
@export var character_player: Node2D
var fixed_y: float = 360.0

func _ready() -> void:
	enabled = true
	set_as_top_level(true)
	character_player = get_node_or_null(target)
	make_current()   
	# Camera moves with character player
	if character_player != null:
		global_position.x = character_player.global_position.x + 200
		global_position.y = fixed_y
		
func _physics_process(delta: float) -> void:
	if character_player:
		global_position.x = character_player.global_position.x + 200
		global_position.y = fixed_y

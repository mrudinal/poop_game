extends Node2D

# Background variables
@export var speed: float = 0.0
@export var image_width: float = 1280.0

# Earthquakes variables
var quake_duration: float = 4.0           
var quake_amplitude: float = 150.0
var quake_hz: float = 2.0
var quake_fade_s: float = 1.0             
@export var shake_with_me: Array[NodePath] = []

# Background moving speed ratio
@export var parallax_ratio: float = 0.15  # 0 = world-fixed, 1 = locks to camera (foreground)

# Everything moves with the background:
var sprites: Array[Node2D] = []
var _shake_nodes: Array[Node2D] = []
var _shake_bases: Array[float] = []

# Aditional variables
var _cam: Camera2D
var _view_w: float
var _elapsed: float = 0.0
var _base_x: float = 0.0
var _cam_last_x: float = 0.0

func _ready() -> void:
	_base_x = position.x

	# Children that move with the background
	for c in get_children():
		if c is Node2D:
			sprites.append(c as Node2D)
	sprites.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	_cam = get_viewport().get_camera_2d()
	_cam_last_x = _cam.global_position.x
	_view_w = float(get_viewport_rect().size.x)

	# Resolve extra nodes to shake with background
	for p in shake_with_me:
		var n := get_node_or_null(p)
		if n is Node2D:
			_shake_nodes.append(n)
			_shake_bases.append(n.position.x)
			
func _process(delta: float) -> void:
	_elapsed += delta
	if _cam == null:
		return
	
	# camera-based parallax (slower BG than player)
	var cam_x := _cam.global_position.x
	var cam_dx := cam_x - _cam_last_x
	_cam_last_x = cam_x

	# shift BG tiles opposite to camera motion by a fraction
	if parallax_ratio != 0.0:
		for s in sprites:
			s.global_position.x += cam_dx * parallax_ratio


	# Additional variables needed for earthquake
	var quake_offset := 0.0
	var best_factor := 0.0
	var best_t_since_start := 0.0

	# Setting earthquake functionality
	for start_time in Variables.quake_start_times:
		if _elapsed >= start_time:
			var end_time := start_time + quake_duration
			var fade_start := end_time - quake_fade_s
			var fade_end := end_time + quake_fade_s
			var factor := 0.0
			if _elapsed <= fade_start:
				factor = 1.0
			elif _elapsed < fade_end:
				var u := (_elapsed - fade_start) / (2.0 * quake_fade_s) # 0..1
				factor = clamp(1.0 - u, 0.0, 1.0)
			if factor > best_factor:
				best_factor = factor
				best_t_since_start = _elapsed - start_time
	# If any earthquake is active, compute its sine offset using the winning window
	if best_factor > 0.0:
		quake_offset = sin(best_t_since_start * TAU * quake_hz) * quake_amplitude * best_factor
	else:
		quake_offset = 0.0
	# Apply quake to this background
	position.x = _base_x + quake_offset
	# ALSO apply quake to any extra nodes 
	for i in _shake_nodes.size():
		_shake_nodes[i].position.x = _shake_bases[i] + quake_offset
	# Time-based scroll for BG tiles
	if speed != 0.0:
		for s in sprites:
			s.position.x -= speed * delta

	# Wrapping logic (BG tiles only)
	var cam_left := _cam.global_position.x - _view_w * 0.5
	var rightmost_x: float = -INF
	for r in sprites:
		rightmost_x = max(rightmost_x, r.global_position.x)
	for s in sprites:
		if s.global_position.x + image_width <= cam_left:
			s.global_position.x = rightmost_x + image_width
			rightmost_x = s.global_position.x

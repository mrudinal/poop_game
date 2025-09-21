extends Node2D

@export var stage_variables_path: NodePath
# --- Blink (blackout) settings ---
@export var blink_duration: float = 4.0
@export var blink_hz: float = 2.0  # blinks per second

# --- Final Focus (spotlight) settings ---
@export var focus_duration: float = 4.0              # seconds per focus window
@export var focus_radius_px: float = 160.0           # fallback radius if no marker
@export var focus_softness_px: float = 32.0          # feather width (px) at hole edge
@export var focus_fade_in_s: float = 0.5             # fade-in duration BEFORE window start
@export var focus_fade_out_s: float = 0.5            # fade-out duration AFTER window end
@export var player_path: NodePath                    # drag character_player here
@export var focus_marker_path: NodePath              # drag the CollisionShape2D here
@export var music_player_path: NodePath

# Optional: use your own full-screen black ColorRect if you want
@export var blink_overlay_path: NodePath

var _elapsed: float = 0.0
var _overlay: CanvasItem = null
var _overlay_layer: CanvasLayer = null
var _player: Node2D = null
var _focus_marker: CollisionShape2D = null
var _focus_mat: ShaderMaterial = null
var _music_player: Node = null   # will be AudioStreamPlayer or AudioStreamPlayer2D

func _enter_tree() -> void:
	var sv := get_node_or_null(stage_variables_path)
	if sv:
		# Copy scene-edited values into the autoload singleton
		Variables.environment = sv.environment
		Variables.start_pos_x = sv.start_pos_x
		Variables.start_pos_y = sv.start_pos_y
		Variables.pixels_by_music_second = sv.pixels_by_music_second

		# Recompute derived values using the just-copied bases
		Variables.music_starts = (Variables.start_pos_x - 330.0) / Variables.pixels_by_music_second
		Variables.quake_start_times = [19.6 - Variables.music_starts, 66.4 - Variables.music_starts]
		Variables.blink_start_times = [23.6 - Variables.music_starts, 70.4 - Variables.music_starts]
		Variables.final_focus = [31.6 - Variables.music_starts, 78.4 - Variables.music_starts]

func _ready() -> void:
	# Try to use provided overlay
	if blink_overlay_path != NodePath():
		var n := get_node_or_null(blink_overlay_path)
		if n is CanvasItem:
			_overlay = n

	# Player reference
	if player_path != NodePath():
		_player = get_node_or_null(player_path)

	# Focus marker (CollisionShape2D with CircleShape2D, can be scaled to oval)
	if focus_marker_path != NodePath():
		_focus_marker = get_node_or_null(focus_marker_path) as CollisionShape2D

	# Otherwise create a guaranteed, topmost overlay
	if _overlay == null:
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.layer = 1000  # very on top
		add_child(_overlay_layer)

		var rect := ColorRect.new()
		rect.color = Color(0, 0, 0, 1)  # opaque black
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_overlay_layer.add_child(rect)
		_overlay = rect

	# Start off (not black)
	_overlay.visible = false
	
	# Music control: resolve player and start at Variables.music_starts seconds
	if music_player_path != NodePath():
		_music_player = get_node_or_null(music_player_path)
		if _music_player:
			# Make sure Autoplay is OFF on the node in the Inspector
			if _music_player is AudioStreamPlayer:
				var p := _music_player as AudioStreamPlayer
				p.stop()
				p.play(Variables.music_starts)         # start from that position
			elif _music_player is AudioStreamPlayer2D:
				var p2 := _music_player as AudioStreamPlayer2D
				p2.stop()
				p2.play(Variables.music_starts)

	# Spotlight shader (elliptical hole). 'intensity' multiplies the outside darkness (for fades).
	var sh := Shader.new()
	sh.code = """shader_type canvas_item;
uniform vec2  focus_uv = vec2(0.5, 0.5);          // center in UV (0..1)
uniform vec2  radius_px = vec2(160.0, 160.0);      // ellipse radii in px (rx, ry)
uniform float softness_px = 32.0;                  // feather width in px
uniform float intensity = 1.0;                     // 0..1, multiplies darkness outside the hole

void fragment(){
	// Convert to pixels
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p  = UV * screen_size;
	vec2 fc = focus_uv * screen_size;

	// Elliptical distance (1.0 at ellipse boundary)
	vec2 d = abs(p - fc) / max(radius_px, vec2(1.0));
	float r = length(d);

	// Convert softness from px to normalized feather around r=1
	float rmax = max(radius_px.x, radius_px.y);
	float s = softness_px / max(rmax, 1.0);

	// m=0 inside, m=1 outside (with soft edge)
	float m = smoothstep(1.0 - s, 1.0 + s, r);

	// Black overlay with alpha=m*intensity (transparent inside the “hole”)
	COLOR = vec4(0.0, 0.0, 0.0, m * clamp(intensity, 0.0, 1.0));
}"""
	_focus_mat = ShaderMaterial.new()
	_focus_mat.shader = sh

func _process(delta: float) -> void:
	_elapsed += delta

	# ---------- FINAL FOCUS (with fades; takes priority over blink) ----------
	var best_factor := 0.0
	var chosen_time := -1.0

	if Variables and Variables.final_focus.size() > 0:
		for t in Variables.final_focus:
			var start := t
			var end := t + focus_duration
			var fade_in_start := start - focus_fade_in_s
			var fade_out_end := end + focus_fade_out_s

			var factor := 0.0
			if _elapsed >= fade_in_start and _elapsed <= start and focus_fade_in_s > 0.0:
				var u := (_elapsed - fade_in_start) / focus_fade_in_s   # 0..1
				factor = clamp(u, 0.0, 1.0)
			elif _elapsed > start and _elapsed < end:
				factor = 1.0
			elif _elapsed >= end and _elapsed <= fade_out_end and focus_fade_out_s > 0.0:
				var u2 := (_elapsed - end) / focus_fade_out_s           # 0..1
				factor = clamp(1.0 - u2, 0.0, 1.0)
			# else factor stays 0

			if factor > best_factor:
				best_factor = factor
				chosen_time = t

	if best_factor > 0.0 and _player:
		# Determine center (marker wins if present; else player position)
		var center_world := _player.global_position
		var rx := focus_radius_px
		var ry := focus_radius_px

		if _focus_marker and _focus_marker.shape is CircleShape2D:
			var circle := _focus_marker.shape as CircleShape2D
			center_world = _focus_marker.global_position
			# Non-uniform scale on the marker gives an ellipse (rx, ry)
			rx = circle.radius * _focus_marker.global_scale.x
			ry = circle.radius * _focus_marker.global_scale.y

		# Convert world → screen coords
		var view_size := get_viewport_rect().size
		var cam := get_viewport().get_camera_2d()
		var screen_pos: Vector2 = center_world
		if cam:
			screen_pos = Vector2(
				center_world.x - cam.global_position.x + view_size.x * 0.5,
				center_world.y - cam.global_position.y + view_size.y * 0.5
			)
		var focus_uv := screen_pos / view_size

		_overlay.material = _focus_mat
		_focus_mat.set_shader_parameter("focus_uv", focus_uv)
		_focus_mat.set_shader_parameter("radius_px", Vector2(rx, ry))
		_focus_mat.set_shader_parameter("softness_px", focus_softness_px)
		_focus_mat.set_shader_parameter("intensity", best_factor)   # <<< fade control
		_overlay.visible = true
		return
	else:
		# Not in focus window: remove spotlight material so blink can use plain overlay
		if _overlay.material != null:
			_overlay.material = null

	# ---------- BLINK (fallback when focus factor is 0) ----------
	var blink_active := false
	var t0 := 0.0
	if Variables and Variables.blink_start_times.size() > 0:
		for s in Variables.blink_start_times:
			if _elapsed >= s and _elapsed < s + blink_duration:
				blink_active = true
				t0 = s
				break

	if not blink_active:
		_overlay.visible = false
	else:
		var toggles_per_sec := blink_hz * 2.0
		var t_since := _elapsed - t0
		var k := int(floor(t_since * toggles_per_sec))
		_overlay.visible = (k % 2) == 0

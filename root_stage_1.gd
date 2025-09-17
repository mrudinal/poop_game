extends Node2D

# --- Blink (blackout) settings ---
@export var blink_duration: float = 4.0             
@export var blink_hz: float = 2.0	#blinks per second            

# Optional: use your own full-screen black ColorRect if you want
@export var blink_overlay_path: NodePath

var _elapsed: float = 0.0
var _overlay: CanvasItem = null
var _overlay_layer: CanvasLayer = null

func _ready() -> void:
	# Try to use provided overlay
	if blink_overlay_path != NodePath():
		var n := get_node_or_null(blink_overlay_path)
		if n is CanvasItem:
			_overlay = n

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

func _process(delta: float) -> void:
	_elapsed += delta

	# Find if we are inside any blink window
	var active := false
	var t0 := 0.0
	for s in Variables.blink_start_times:
		if _elapsed >= s and _elapsed < s + blink_duration:
			active = true
			t0 = s
			break

	if not active:
		_overlay.visible = false
		return

	# Blink: toggle black <-> normal at blink_hz (2 states per cycle)
	var toggles_per_sec := blink_hz * 2.0
	var t_since := _elapsed - t0
	var k := int(floor(t_since * toggles_per_sec))
	_overlay.visible = (k % 2) == 0

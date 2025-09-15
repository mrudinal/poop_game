extends Node2D

@export var speed: float = 300.0  # pixels/sec downward

func _process(delta: float) -> void:
	# down is +Y in Godot
	global_position.y += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

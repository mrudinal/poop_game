extends Node2D

@export var speed: float = 300.0

func _process(delta: float) -> void:
	# Poop should go down
	global_position.y += speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

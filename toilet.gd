extends Area2D

# test script
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Player hit the toilet!")
		#get_tree().reload_current_scene()  # simple game over: reload scene

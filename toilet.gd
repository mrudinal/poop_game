extends Area2D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("Player hit the toilet!")
		Variables.reset()
	

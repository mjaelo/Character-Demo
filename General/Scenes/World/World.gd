extends Node3D

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player:
		print("\n\nResetting Game\n\n")
		get_tree().reload_current_scene()

extends StaticBody3D

func _ready() -> void:
	pass

func _on_area_3d_body_entered(_body: Node3D) -> void:
	if _body.is_in_group("Player"):
		print("Touching the gold ore")

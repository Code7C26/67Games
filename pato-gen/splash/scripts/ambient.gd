extends Node2D
func _ready() -> void:
	for child in get_children():
		if child is AnimatedSprite2D:
			child.frame = int(absf(global_position.x*3.0+global_position.y*7.0)) % child.sprite_frames.get_frame_count("default")
			child.play("default")

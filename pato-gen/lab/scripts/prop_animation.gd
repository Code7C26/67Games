extends Node2D
## Keeps identical apparatus out of phase without per-frame scripts.
@export_range(0,7,1) var animation_offset := 0
func _ready() -> void:
	var sprite := get_node_or_null("TexturaAnimada") as AnimatedSprite2D
	if sprite:
		sprite.play("default")
		sprite.frame = animation_offset % sprite.sprite_frames.get_frame_count("default")

extends Node2D
## Short, deterministic pixel-art accent. Purely visual, no gameplay effects.
var elapsed := 0.0
var reduced_motion := false
var tint := Color("78eee0")

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed > 0.65:
		queue_free()

func _draw() -> void:
	var progress := minf(elapsed / 0.65, 1.0)
	var color := Color(tint, (1.0 - progress) * 0.8)
	var radius := lerpf(10, 66, progress) if not reduced_motion else 22.0
	for i in range(24):
		var angle := TAU * i / 24.0
		var point := (Vector2(cos(angle), sin(angle)) * radius).snapped(Vector2(2, 2))
		draw_rect(Rect2(point, Vector2(3, 3)), color)
	if not reduced_motion:
		for i in range(12):
			var angle := TAU * i / 12.0 + 0.2
			var point := (Vector2(cos(angle), sin(angle)) * radius * 0.7).snapped(Vector2(2, 2))
			draw_rect(Rect2(point, Vector2(2, 2)), color)

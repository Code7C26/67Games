extends Node
## Dedicated temporary camera: does not animate or reconfigure the gameplay camera.
var source: Camera2D
var camera: Camera2D
var travel: Tween
var initial_position := Vector2.ZERO
var initial_zoom := Vector2.ONE
var reduced_motion := false
var shake_left := 0.0
var shake_duration := 0.24
var clock := 0.0

func take_over(from: Camera2D) -> void:
	source = from
	if not is_instance_valid(source):
		return
	initial_position = source.get_screen_center_position()
	initial_zoom = source.zoom
	camera = Camera2D.new()
	camera.name = "PatogenCinematicCamera"
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(camera)
	camera.global_position = initial_position
	camera.zoom = initial_zoom
	camera.ignore_rotation = source.ignore_rotation
	camera.global_rotation = source.global_rotation
	camera.anchor_mode = source.anchor_mode
	camera.make_current()
	camera.reset_smoothing()
	camera.force_update_scroll()

func frame_point(point: Vector2, factor: float, seconds: float) -> void:
	if not is_instance_valid(camera):
		return
	if travel:
		travel.kill()
	if reduced_motion:
		return
	travel = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(camera, "global_position", point, seconds)
	travel.tween_property(camera, "zoom", initial_zoom * clampf(factor, 1.0, 1.85), seconds)

func return_to_overview(seconds: float = 1.1) -> void:
	frame_point(initial_position, 1.0, seconds)

func shake() -> void:
	if not reduced_motion:
		shake_left = shake_duration

func _process(delta: float) -> void:
	clock += delta
	if not is_instance_valid(camera):
		return
	shake_left = maxf(0, shake_left - delta)
	var strength := 2.5 * shake_left / shake_duration
	camera.offset = Vector2(roundf(sin(clock * 83.0) * strength), roundf(cos(clock * 71.0) * strength))

func restore() -> void:
	if travel:
		travel.kill()
	shake_left = 0
	if is_instance_valid(camera):
		# Do not steal priority if another system has taken the camera meanwhile.
		if camera.is_current() and is_instance_valid(source) and source.is_inside_tree() and source.enabled:
			source.make_current()
			source.force_update_scroll()
		camera.enabled = false
		camera.queue_free()
		camera = null

func _exit_tree() -> void:
	restore()

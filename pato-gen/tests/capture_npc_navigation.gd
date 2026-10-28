extends SceneTree
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if root.use_hdr_2d:
		img.convert(Image.FORMAT_RGBA8)
		img.linear_to_srgb()
	var path := ProjectSettings.globalize_path("res://../map-captures/" + label + ".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	img.save_png(path)
	print("CAPTURE ", label)
func run() -> void:
	root.size = Vector2i(1920,1080)
	var args := OS.get_cmdline_user_args()
	var map_name := args[0] if not args.is_empty() else "PatoSplash"
	seed(729)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var host = load("res://scenes/" + map_name + ".tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if not host.map_is_ready: await host.map_ready
	host.timer_inicio.stop()
	for i in 60: await physics_frame
	host._on_timer_inicio_timeout()
	for frame in 2700:
		await physics_frame
		if frame in [110, 360, 2400]: await capture(map_name + "_npc_%04d" % frame)
	print("EVACUATED ", host.ambient_evacuation.evacuated if map_name == "PatoSplash" else 0)
	host.queue_free()
	await process_frame
	quit()

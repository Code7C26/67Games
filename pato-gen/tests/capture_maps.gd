extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var map_name := args[0] if not args.is_empty() else "Shopping"
	var suffix := args[1] if args.size() > 1 else "after"
	# Re-render a historical visual phase without changing the working project.
	for argument in args:
		if argument.begins_with("--finish-source="):
			var source_path := argument.trim_prefix("--finish-source=")
			assert(source_path.begins_with("res://tests/visual_artifacts/"))
			var finish_script: GDScript = load("res://scripts/scenery_finish.gd")
			finish_script.source_code = FileAccess.get_file_as_string(source_path)
			assert(finish_script.reload() == OK)
	root.size = Vector2i(1920, 1080)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	root.get_node("PatogenOnboarding").profile.data.reduced_motion = "reduced" in args
	seed(20261028)
	var host = load("res://scenes/" + map_name + ".tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if host.has_method("contar_infecciones"):
		host.timer_inicio.stop()
		if host.has_signal("map_ready") and not host.map_is_ready:
			await host.map_ready
		host.timer_inicio.stop()
		for bot in get_nodes_in_group("bots"):
			bot.set_physics_process(false)
			bot.get_node("TimerCambioRumbo").stop()
		for duck in get_nodes_in_group("patos"): duck.set_physics_process(false)
	for i in 20: await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if root.use_hdr_2d:
		img.convert(Image.FORMAT_RGBA8)
		img.linear_to_srgb()
	var output := ProjectSettings.globalize_path("res://tests/visual_artifacts/captures") if "visual" in args else ProjectSettings.globalize_path("res://../map-captures")
	DirAccess.make_dir_recursive_absolute(output)
	var error := img.save_png(output + "/" + map_name + "_" + suffix + ".png")
	print("CAPTURE ", map_name, " ", error)
	host.queue_free()
	await process_frame
	await process_frame
	quit(error)

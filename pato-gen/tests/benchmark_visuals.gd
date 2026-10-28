extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var map_name := args[0] if not args.is_empty() else "Shopping"
	var phase := args[1] if args.size() > 1 else "baseline"
	root.size = Vector2i(1920,1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	DisplayServer.window_move_to_foreground()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	root.get_node("PatogenOnboarding").profile.data.reduced_motion = "reduced" in args
	seed(20261028)
	var host = load("res://scenes/" + map_name + ".tscn").instantiate() if map_name != "Empty" else Node2D.new()
	root.add_child(host)
	current_scene = host
	if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
	if map_name != "Empty": host.timer_inicio.stop()
	for i in 100: await process_frame
	DisplayServer.window_move_to_foreground()
	var start := Time.get_ticks_usec()
	var previous := start
	var samples: Array[float] = []
	var draws := 0
	var gpu_times: Array[float] = []
	var cpu_times: Array[float] = []
	for i in 360:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
		draws = maxi(draws, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		cpu_times.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
	var seconds := (Time.get_ticks_usec() - start) / 1000000.0
	samples.sort()
	gpu_times.sort()
	cpu_times.sort()
	var result := {"map": map_name, "phase": phase, "reduced_motion": "reduced" in args, "bots": get_nodes_in_group("bots").size(), "viewport": root.size, "renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(), "average_fps": 360.0 / seconds, "p50_ms": samples[180], "p95_ms": samples[342], "max_ms": samples[-1], "max_draw_calls": draws}
	var dir := "res://tests/visual_artifacts/benchmarks"
	result["gpu_p95_ms"] = gpu_times[342]
	result["render_cpu_p95_ms"] = cpu_times[342]
	DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(dir + "/" + map_name + "_" + phase + ("_reduced" if "reduced" in args else "") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	print("VISUAL_BENCHMARK ", JSON.stringify(result))
	host.queue_free()
	await process_frame
	quit()

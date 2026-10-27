extends Node
## Real-time rendered benchmark at 1920x1080, with the normal 1/60 physics step.
var failures: Array[String] = []
var report: Dictionary = {}
var demo: Node2D
var ambience: Node2D
var render_view: SubViewport
var signatures: Dictionary = {}
var frame_cache: Dictionary = {}
var penetrations := 0
var floating_escapes := 0
var max_attracted := 0
var impacts: Array[float] = []

func check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func collision_signature(node: Node, result: Dictionary, prefix: String = "") -> void:
	var key := prefix + "/" + node.name
	if node is CollisionShape2D and node.get_parent() is StaticBody2D:
		result[key] = [node.global_transform, node.disabled, node.shape.size if node.shape is RectangleShape2D else Vector2.ZERO]
	for child in node.get_children(): collision_signature(child, result, key)

func filter_check(node: Node) -> int:
	var count := 0
	if node is Sprite2D or node is AnimatedSprite2D or node is TileMapLayer:
		count += 1
		var current: Node = node
		while current and (not current is CanvasItem or current.texture_filter == CanvasItem.TEXTURE_FILTER_PARENT_NODE):
			current = current.get_parent()
		check(current == null or current.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Unexpected texture filter: " + str(node.get_path()))
	for child in node.get_children(): count += filter_check(child)
	return count

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var original_cap := Engine.max_fps
	var original_vsync := DisplayServer.window_get_vsync_mode()
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	render_view = SubViewport.new()
	render_view.size = Vector2i(1920, 1080)
	render_view.world_2d = World2D.new()
	render_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render_view)
	demo = load("res://demo/PatoSplashDemo.tscn").instantiate()
	render_view.add_child(demo)
	var display := TextureRect.new()
	display.texture = render_view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.size = get_viewport().get_visible_rect().size
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	demo.map.audio_enabled = false; demo.ambient.stop(); demo.shake_enabled = false
	ambience = demo.map.get_node("08_Ambiente")
	demo.map.splash_impact.connect(func(_strength: float): impacts.append(demo.total_time))
	check(render_view.size == Vector2i(1920, 1080), "Benchmark viewport must be 1920x1080")
	check(demo.camera.zoom == Vector2.ONE and demo.camera.position == Vector2(960, 540), "Fixed camera changed")
	check(demo.map.get_node("07_Caminos").tile_set.tile_size == Vector2i(32, 32), "32px tiles changed")
	check(get_tree().get_nodes_in_group("splash_visitors").size() == 54, "Expected 54 current NPCs")
	check(ambience.palms.size() == 10 and ambience.flags.size() == 4, "Missing palm or flag registration")
	check(ambience.fans.size() == 2 and ambience.umbrellas.size() == 5, "Missing fan or umbrella registration")
	check(ambience.floats.size() == 6, "Expected five rings plus the giant floating duck")
	check(ambience.water_materials.size() == 4 and ambience.leaf_pool.size() == 2, "Effect pool budget changed")
	check(ambience.fountain != null and ambience.bubbles != null and ambience.sign_sprite != null, "Missing fountain or ice-cream sign")
	check(ambience.sign_sprite.sprite_frames.get_frame_count("default") == 4, "Sign states missing")
	for visual in ambience.flags: check(visual.sprite_frames.get_frame_count("default") == 4, "Flag must have four wave poses")
	var cloud: ColorRect = ambience.get_node("SombrasNubes")
	check(Rect2(cloud.position, cloud.size) == Rect2(32, 112, 1856, 860), "Cloud shadows overlap the HUD")
	check(ambience.cloud_intensity <= 0.35, "Shadows exceed the supported opacity limit")
	for pool in demo.map.get_node("02_Piletas").get_children():
		var overlay: ColorRect = pool.get_node("DestellosAmbiente")
		var border: Sprite2D = pool.get_node("Borde")
		check(Rect2(Vector2.ZERO, border.texture.get_size()).grow(-8).encloses(Rect2(overlay.position, overlay.size)), "Water glints leave the pool")
	collision_signature(demo.map, signatures)
	for source in ["destellos_agua", "sombras_nubes", "fuente_pulso"]:
		check(not FileAccess.get_file_as_string("res://splash/shaders/" + source + ".gdshader").contains("TIME"), "Unpausable shader clock")
	for prefix in ["water", "cloud", "palm", "leaf", "flag", "fan", "float", "fountain", "umbrella", "sign"]:
		var properties: Dictionary = {}
		for property in ambience.get_property_list(): properties[property.name] = property.usage
		for suffix in ["speed", "intensity"]:
			var key: String = prefix + "_" + suffix
			check(properties.has(key) and (int(properties[key]) & PROPERTY_USAGE_EDITOR) != 0, "Effect parameter is not exported: " + key)
	for entry in ambience.floats:
		var visual: AnimatedSprite2D = entry.sprite
		var boxes: Array[Rect2] = []
		for i in 8:
			var texture: AtlasTexture = visual.sprite_frames.get_frame_texture("default", i)
			var image: Image = texture.atlas.get_image().get_region(texture.region)
			var used := Rect2(image.get_used_rect())
			boxes.append(Rect2(used.position - texture.region.size * 0.5, used.size))
		frame_cache[visual.get_instance_id()] = boxes
	report.nearest_nodes_checked = filter_check(demo)
	# Compare rendering with ambience off/on; normal gameplay and physics keep running.
	ambience.enabled = false; ambience.apply_effects()
	await get_tree().create_timer(3.0).timeout
	report.baseline = await measure(8.0, false)
	ambience.enabled = true
	await get_tree().create_timer(3.0).timeout
	print("PART3_BENCHMARK_STARTED: 54 NPC, 1920x1080, all effects, uncapped rendering, fixed 60Hz physics")
	report.ambient = await measure(50.0, true)
	check(render_view.size == Vector2i(1920, 1080), "Operating system resized the benchmark render target")
	# Check shared pause clock, including shaders and the falling leaf pool.
	get_tree().paused = true
	var frozen: float = ambience.elapsed
	var frozen_frame: int = ambience.fountain.frame
	await get_tree().create_timer(0.2, true).timeout
	check(ambience.elapsed == frozen and ambience.fountain.frame == frozen_frame, "Ambient effects continue while paused")
	get_tree().paused = false
	# A disabled visual controller restores the original sprite positions.
	ambience.enabled = false; ambience.apply_effects()
	for entry in ambience.floats: check(entry.sprite.position == entry.base, "Disabling drift leaves a displaced prop")
	check(float(ambience.cloud_material.get_shader_parameter("intensity")) == 0.0, "Cloud intensity zero is not respected")
	ambience.enabled = true; ambience.apply_effects()
	var after: Dictionary = {}; collision_signature(demo.map, after)
	check(signatures == after, "Ambient animations changed collision geometry")
	check(floating_escapes == 0, "Floating toys left their pool")
	check(penetrations == 0, "A visitor penetrated static geometry")
	check(ambience.spawned_leaves >= 2 and ambience.max_active_leaves <= 2, "Falling leaves are absent or over budget")
	check(impacts.size() >= 1 and max_attracted <= 10, "Neutral event changed")
	var min_travel := INF
	var trips := 0
	for actor in get_tree().get_nodes_in_group("splash_visitors"):
		min_travel = minf(min_travel, actor.travel); trips += actor.trips
		check(actor.travel > 1500, "A visitor remained stuck")
	check(float(report.ambient.mean_fps) >= 60.0 and float(report.ambient.p99_frame_ms) <= 16.667, "Rendered frame budget exceeds 60 FPS at the 99th percentile")
	report.actors = 54; report.render_size = [1920, 1080]; report.physics_hz = Engine.physics_ticks_per_second
	report.native_subviewport = true
	report.collision_geometry_unchanged = signatures == after
	report.water_overlays = 4; report.palms = 10; report.flags = 4; report.fans = 2; report.floats = 6; report.umbrellas = 5
	report.spawned_leaves = ambience.spawned_leaves; report.max_active_leaves = ambience.max_active_leaves
	report.floating_escapes = floating_escapes; report.penetration_samples = penetrations
	report.minimum_npc_travel = min_travel; report.completed_trips = trips; report.max_attracted = max_attracted; report.impact_times = impacts
	report.pause_checked = true; report.exported_effect_controls = 20
	report.gpu = RenderingServer.get_video_adapter_name(); report.godot = Engine.get_version_info().string
	report.passed = failures.is_empty(); report.failures = failures
	var file := FileAccess.open("res://tests/part3_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t")); file.close()
	print("PART3_VALIDATION ", JSON.stringify(report))
	Engine.max_fps = original_cap; DisplayServer.window_set_vsync_mode(original_vsync)
	await get_tree().create_timer(5.0).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

func measure(seconds: float, inspect_motion: bool) -> Dictionary:
	var timings: Array[float] = []
	var cpu: Array[float] = []
	var beginning := Time.get_ticks_usec()
	var previous := beginning
	var last_inspection := 0.0
	var max_draw_calls := 0
	while float(Time.get_ticks_usec() - beginning) / 1000000.0 < seconds:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		timings.append(float(now - previous) / 1000.0); previous = now
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		max_draw_calls = maxi(max_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		var age := float(now - beginning) / 1000000.0
		if inspect_motion and age - last_inspection >= 0.5:
			last_inspection = age
			for entry in ambience.floats:
				var visual: AnimatedSprite2D = entry.sprite
				var boxes: Array = frame_cache[visual.get_instance_id()]
				var box: Rect2 = visual.global_transform * boxes[visual.frame]
				var pool: Rect2 = entry.pool
				if not pool.grow(1.0).encloses(box): floating_escapes += 1
			var attracted := 0
			for actor in get_tree().get_nodes_in_group("splash_visitors"):
				if actor.attraction_left > 0.0: attracted += 1
				for obstacle in demo.routes.obstacles:
					var point: Vector2 = actor.global_position
					var dx := maxf(0, maxf(obstacle.position.x - point.x, point.x - obstacle.end.x))
					var dy := maxf(0, maxf(obstacle.position.y - (point.y + 4.5), (point.y - 4.5) - obstacle.end.y))
					if Vector2(dx, dy).length() < 11.15: penetrations += 1
			max_attracted = maxi(max_attracted, attracted)
	var total := 0.0
	var missed := 0
	for timing in timings:
		total += timing
		if timing > 16.667: missed += 1
	timings.sort(); cpu.sort()
	var p99: float = timings[mini(timings.size() - 1, int(timings.size() * 0.99))]
	return {"seconds": total / 1000.0, "frames": timings.size(), "mean_fps": 1000.0 * timings.size() / total,
		"median_frame_ms": timings[int(timings.size() * 0.5)], "p95_frame_ms": timings[int(timings.size() * 0.95)],
		"p99_frame_ms": p99, "one_percent_low_fps": 1000.0 / p99, "max_frame_ms": timings[-1],
		"frames_over_16_667_ms": missed, "cpu_p99_ms": cpu[int(cpu.size() * 0.99)], "max_draw_calls": max_draw_calls}

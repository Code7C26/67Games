extends SceneTree
var host: Node
var passed := 0
var failures := 0
const FRAMES = preload("res://resources/animations/capullo.tres")

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func shot(label: String, point: Vector2) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 400)
	viewport.use_hdr_2d = root.use_hdr_2d
	viewport.world_2d = host.get_world_2d()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var camera := Camera2D.new()
	camera.position = point
	camera.zoom = Vector2(4, 4)
	viewport.add_child(camera)
	await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://tests/run_data/capullo")
	var captured := viewport.get_texture().get_image()
	if viewport.use_hdr_2d:
		# HDR readbacks are linear; PNG viewers expect sRGB.
		var display_image := Image.create(captured.get_width(), captured.get_height(), false, Image.FORMAT_RGBA8)
		for y in captured.get_height():
			for x in captured.get_width():
				display_image.set_pixel(x, y, captured.get_pixel(x, y).linear_to_srgb())
		captured = display_image
	captured.save_png("res://tests/run_data/capullo/" + label + ".png")
	viewport.queue_free()

func run() -> void:
	var valid := FRAMES.get_animation_names().size() == 5
	var total := 0
	for animation in FRAMES.get_animation_names():
		for i in FRAMES.get_frame_count(animation):
			total += 1
			valid = valid and FRAMES.get_frame_texture(animation, i).get_size() == Vector2(32, 32)
	check(valid and total == 24, "24 complete 32x32 frames in five animations")
	for map_name in ["Shopping", "Laboratorio", "PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		host = load("res://scenes/" + map_name + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready:
			await host.map_ready
		host.timer_inicio.stop()
		var deadline := Time.get_ticks_msec() + 30000
		while not host.capullos_colocados and Time.get_ticks_msec() < deadline:
			await physics_frame
		check(host.capullos_colocados, map_name + " placed cocoons on real navigation")
		if not host.capullos_colocados:
			host.queue_free()
			await process_frame
			continue
		for bot in get_nodes_in_group("bots"):
			bot.set_physics_process(false)
			bot.get_node("TimerCambioRumbo").stop()
		for duck in get_nodes_in_group("patos"):
			duck.set_physics_process(false)
		host.estado_actual = host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(120)
		var cyan = host.capullos[0]
		var magenta = host.capullos[1]
		var cyan_point: Vector2 = cyan.global_position
		var magenta_point: Vector2 = magenta.global_position
		check(cyan.visible and cyan.aspecto.is_playing() and cyan.aspecto.animation == &"reposo", map_name + " visible breathing sprite")
		check(cyan.aspecto.material != magenta.aspecto.material and cyan.aspecto.material.get_shader_parameter("vena") != magenta.aspecto.material.get_shader_parameter("vena"), map_name + " independent muted team colours")
		check(not host.invertir_simbionte(1) and cyan.aspecto.animation == &"reposo", map_name + " rejected payment does not pulse")
		await shot(map_name + "_reposo", cyan_point)
		await shot(map_name + "_magenta", magenta_point)
		host.adn_cian = 60
		check(host.invertir_simbionte(1) and cyan.aspecto.animation == &"inversion" and host.adn_cian == 55, map_name + " accepted payment immediately pulses and charges once")
		check(not host.invertir_simbionte(1) and host.adn_cian == 55, map_name + " animation does not bypass cooldown")
		host.timer_juego.paused = true
		cyan.aspecto._process(0)
		var frame: int = cyan.aspecto.frame
		var progress: float = cyan.aspecto.frame_progress
		await create_timer(0.2).timeout
		check(cyan.aspecto.frame == frame and is_equal_approx(cyan.aspecto.frame_progress, progress), map_name + " tutorial-held clock freezes pulse")
		host.timer_juego.paused = false
		await create_timer(0.8).timeout
		check(cyan.aspecto.animation == &"reposo", map_name + " pulse recovers into breathing")
		for i in 8:
			host._physics_process(host.COOLDOWN_SIMBIONTE)
			host.invertir_simbionte(1)
		await create_timer(0.8).timeout
		check(host.inversion_simbionte[0] == 45 and cyan.aspecto.animation == &"inquieto", map_name + " mature cocoon becomes restless at 45 ADN")
		await shot(map_name + "_maduro", cyan_point)
		for i in 3:
			host._physics_process(host.COOLDOWN_SIMBIONTE)
			host.invertir_simbionte(1)
		check(host.ganador_simbionte == 1 and host.adn_cian == 0 and is_instance_valid(host.simbionte), map_name + " final payment creates traveller immediately")
		var remnants := get_nodes_in_group("restos_capullo")
		check(remnants.size() == 2, map_name + " winner and rival each create a final animation")
		if remnants.size() == 2:
			check(remnants[0].animation == &"eclosion" and remnants[0].global_position == cyan_point and remnants[1].animation == &"marchitar" and remnants[1].global_position == magenta_point, map_name + " finals use their own original locations")
			paused = true
			frame = remnants[0].frame
			await create_timer(0.15, true).timeout
			check(remnants[0].frame == frame, map_name + " global pause freezes opening")
			paused = false
			await create_timer(0.25).timeout
			await shot(map_name + "_eclosion", cyan_point)
			await shot(map_name + "_marchitar", magenta_point)
		await create_timer(1.0).timeout
		check(get_nodes_in_group("restos_capullo").is_empty() and host.get_node("Simbiontes").get_child_count() == 0, map_name + " completed shells free themselves")
		host.queue_free()
		await process_frame
		await physics_frame
		check(get_nodes_in_group("restos_capullo").is_empty() and get_nodes_in_group("simbiontes").is_empty(), map_name + " leaving map cleans up actors")
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	print("CAPULLO RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

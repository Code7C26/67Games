extends SceneTree
## Rendered production-map evidence of the approved two states and team outlines.
var host: Node2D
var output := ""
var errors := 0

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	if is_instance_valid(host.interfaz): host.interfaz.sync(host.contar_infecciones())
	for _i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	if image.save_png(output.path_join(name + ".png")) != OK:
		errors += 1
		push_error("FAIL Camaleon capture " + name)
	else:
		print("CAMALEON CAPTURE ", name)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/camaleon-integracion-nov06/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	var maps := ["Shopping", "Laboratorio", "PatoSplash"]
	var selected := OS.get_environment("CAMALEON_CAPTURE_MAP")
	if selected in maps: maps = [selected]
	for map_name in maps:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		root.set_meta("patogen_cepas", {1: "camaleon", 2: "camaleon"})
		host = load("res://scenes/" + map_name + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host.set_process(false)
		host.set_physics_process(false)
		host.evento_coloso.set_physics_process(false)
		host.evento_alfa.set_physics_process(false)
		for duck in get_nodes_in_group("patos"):
			duck.convertirse_en_fantasma()
			duck.set_physics_process(false)
		var bots := get_nodes_in_group("bots")
		for bot in bots:
			bot.set_physics_process(false)
			bot.get_node("TimerCambioRumbo").stop()
			bot.timer_contagio.stop()
			bot.timer_curacion.stop()
		var navigation: Node2D = host.navegacion_simbionte
		var deadline := Time.get_ticks_msec() + 15000
		while not navigation.lista and Time.get_ticks_msec() < deadline: await physics_frame
		host.estado_actual = host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(100.0)
		var sources: Array[Node2D] = [bots[0], bots[1]]
		var points: Array[Vector2] = []
		points.assign(navigation.posiciones_capullos)
		var view: Rect2 = host.get_meta("view_bounds", Rect2(0, 80, 2128, 960))
		var center := view.get_center()
		points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(center) < b.distance_squared_to(center))
		var position := Vector2.INF
		for point in points:
			var other_point := point + Vector2(110, 0)
			if not navigation.segmento_libre(point, other_point): continue
			var clear := true
			for bot in bots:
				if bot in sources: continue
				if bot.global_position.distance_squared_to(point) < 55.0 * 55.0 or bot.global_position.distance_squared_to(other_point) < 55.0 * 55.0:
					clear = false
					break
			if clear:
				position = point
				break
		if not position.is_finite():
			errors += 1
			push_error("FAIL no clear Camaleon capture area " + map_name)
			host.queue_free()
			await process_frame
			await process_frame
			continue
		for i in 2:
			var source: Node2D = sources[i]
			source.global_position = position + Vector2(i * 110, 0)
			source.activar_infeccion(Color.CYAN if i == 0 else Color.MAGENTA, i + 1, false)
			source.incubacion_contagio = 0.0
			source.feedback_restante = 0.0
			source.timer_contagio.stop()
			source.timer_curacion.stop()
			source.camaleon.actualizar(0.35)
			source.actualizar_animacion(Vector2.DOWN)
			if not source.camaleon.camuflado:
				errors += 1
				push_error("FAIL capture host is not camouflaged " + map_name + " P" + str(i + 1))
		var camera: Camera2D = host.get_node("Camera2D")
		camera.position_smoothing_enabled = false
		camera.global_position = position + Vector2(55, 0)
		camera.zoom = Vector2(2.4, 2.4)
		camera.force_update_scroll()
		await shot(map_name + "_01_camuflados_ambos_equipos")
		for source in sources:
			source.camaleon.revelar("captura")
			source.camaleon.actualizar(0.35)
			source.actualizar_animacion(Vector2.DOWN)
		await shot(map_name + "_02_revelados_ambos_equipos")
		host.queue_free()
		await process_frame
		await process_frame
	load("res://scripts/camaleon_arte.gd").limpiar_cache()
	load("res://scripts/npc_readability.gd").textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	print("CAMALEON CAPTURE RESULT ", errors, " errors")
	quit(0 if errors == 0 else 1)

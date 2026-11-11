extends SceneTree
## Real gameplay captures: production maps, Bot, Garfio phases and team shaders.
const G = preload("res://scripts/garfio.gd")
var host: Node2D
var output := ""
var errors := 0

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	if is_instance_valid(host) and is_instance_valid(host.interfaz):
		host.interfaz.sync(host.contar_infecciones())
	for _i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	var result := image.save_png(output.path_join(name + ".png"))
	if result != OK:
		errors += 1
		push_error("FAIL capture " + name)
	else: print("GARFIO CAPTURE ", name)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/garfio-ajuste-nov05/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	var maps := ["Shopping", "Laboratorio", "PatoSplash"]
	var selected := OS.get_environment("GARFIO_CAPTURE_MAP")
	if selected in maps: maps = [selected]
	for map_name in maps:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		root.set_meta("patogen_cepas", {1: "garfio", 2: "garfio"})
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
		var source: Node2D = bots[0]
		var target: Node2D = bots[1]
		source.activar_infeccion(Color.CYAN, 1, false)
		source.incubacion_contagio = 0.0
		source.feedback_restante = 0.0
		source.timer_contagio.stop()
		source.timer_curacion.stop()
		var ability: Node2D = source.garfio
		ability.hasta_busqueda = 1000.0
		var points: Array[Vector2] = []
		points.assign(navigation.posiciones_capullos)
		var center: Vector2 = host.get_meta("view_bounds", Rect2(0, 80, 2128, 960)).get_center()
		points.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(center) < b.distance_squared_to(center))
		var started := false
		for point in points:
			var prey_point := point + Vector2(0, 136)
			if not navigation.segmento_libre(point, prey_point): continue
			source.global_position = point
			target.global_position = prey_point
			await physics_frame
			ability.recarga_restante = 0.0
			if ability.intentar_enganche(target):
				started = true
				break
		if not started:
			push_error("FAIL no clear capture span " + map_name)
			errors += 1
			host.queue_free()
			await process_frame
			continue
		var camera: Camera2D = host.get_node("Camera2D")
		camera.position_smoothing_enabled = false
		camera.global_position = source.global_position.lerp(target.global_position, 0.5)
		camera.zoom = Vector2(2.4, 2.4)
		camera.force_update_scroll()
		source.actualizar_animacion(Vector2.ZERO)
		await shot(map_name + "_01_preparacion")
		ability.actualizar(ability.parametros.preparacion)
		ability.actualizar(0.17)
		source.actualizar_animacion(Vector2.ZERO)
		await shot(map_name + "_02_extension")
		for _i in 20:
			if ability.estado != G.Estado.EXTENDIENDO: break
			ability.actualizar(0.025)
		if ability.estado == G.Estado.ARRASTRANDO:
			ability.arrastrar_objetivo(target, 0.15)
			ability.actualizar(0.15)
			source.actualizar_animacion(Vector2.ZERO)
			await shot(map_name + "_03_arrastre")
		else:
			push_error("FAIL capture did not reach pull " + map_name)
			errors += 1
		host.queue_free()
		await process_frame
		await process_frame
	root.get_node("AudioManager").detener_musica()
	print("GARFIO CAPTURE RESULT ", errors, " errors")
	quit(0 if errors == 0 else 1)

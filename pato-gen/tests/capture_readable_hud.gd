extends SceneTree
## Reproducible readability fixtures; game rules are exercised by the gameplay tests.
const Equipos = preload("res://scripts/equipos_infeccion.gd")
var host: Node2D
var output := ""

func _initialize() -> void:
	run.call_deferred()

func shot(filename: String) -> void:
	for _i in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if root.use_hdr_2d:
		img.convert(Image.FORMAT_RGBA8)
		img.linear_to_srgb()
	var result := img.save_png(output.path_join(filename + ".png"))
	if result != OK:
		push_error("FAIL capture " + filename)
		quit(1)
	print("CAPTURE ", filename)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/jugabilidad-nov04/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	root.set_meta("patogen_cepas", {1: "area", 2: "atletico"})
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	host.evento_alfa.set_physics_process(false)
	var evento = host.evento_coloso
	evento.set_physics_process(false)
	var deadline := Time.get_ticks_msec() + 10000
	while evento.posiciones.is_empty() and Time.get_ticks_msec() < deadline:
		await physics_frame
	for bot in get_nodes_in_group("bots"):
		bot.set_physics_process(false)
		bot.get_node("TimerCambioRumbo").stop()
		bot.timer_contagio.stop()
		bot.timer_curacion.stop()
	for duck in get_nodes_in_group("patos"):
		duck.set_physics_process(false)
	host.interfaz.sync(host.contar_infecciones())
	await shot("01_preparacion_legible")
	for duck in get_nodes_in_group("patos"):
		duck.convertirse_en_fantasma()
	var bots := get_nodes_in_group("bots")
	for i in range(bots.size()):
		if i % 3 != 0:
			var team := 1 if i % 2 == 0 else 2
			bots[i].activar_infeccion(Equipos.COLOR_AZUL if team == 1 else Equipos.COLOR_MAGENTA, team, false)
		# Most infections are established; two examples show the short new-infection cue.
		bots[i].feedback_restante = 0.55 if i in [5, 14] else 0.0
		bots[i].queue_redraw()
		bots[i].timer_contagio.stop()
		bots[i].timer_curacion.stop()
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(84.0)
	host.timer_juego.paused = true
	host.adn_cian = 12
	host.adn_magenta = 8
	# The fixture puts the neutral event in the connected central aisle.
	var centre: Vector2 = host.interfaz.world_rect.get_center()
	var point := centre
	var distance := INF
	for candidate in evento.posiciones:
		if candidate.distance_squared_to(centre) < distance:
			distance = candidate.distance_squared_to(centre)
			point = candidate
	evento.posicion_aviso = point
	evento.aviso_restante = 4.0
	evento.estado = evento.Estado.AVISO
	evento.queue_redraw()
	host.interfaz.sync(host.contar_infecciones())
	await shot("02_aviso_coloso_global")
	var actor = load("res://scenes/coloso_antiviral.tscn").instantiate()
	actor.evento = evento
	actor.position = host.to_local(point)
	host.add_child(actor)
	evento.coloso = actor
	evento.estado = evento.Estado.ACTIVO
	evento.activo_restante = 18.0
	evento.poblacion = host.contar_infecciones()
	evento.queue_redraw()
	actor.curaciones = 3
	actor.pulso_visual = 0.65
	actor.queue_redraw()
	host.interfaz.sync(host.contar_infecciones())
	await shot("03_coloso_visible")
	# The global cue explains neutral green even when the Alfa is off screen.
	evento.estado = evento.Estado.ESPERA
	actor.queue_free()
	evento.coloso = null
	host.interfaz.sync(host.contar_infecciones())
	host.interfaz._coloso_departure_time = 0.0
	host.evento_alfa.estado = host.evento_alfa.Estado.ACTIVO
	host.evento_alfa.tiempo_activo = 18.0
	host.interfaz.sync(host.contar_infecciones())
	await shot("04_explicacion_verde_neutral")
	host.queue_free()
	await process_frame
	await process_frame
	quit()

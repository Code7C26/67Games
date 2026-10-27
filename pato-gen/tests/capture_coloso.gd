extends SceneTree
var output := ""
var host: Node

func _initialize() -> void:
	run.call_deferred()

func shot(nombre: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output + "/" + nombre + ".png")
	if error != OK:
		push_error("Capture could not save " + nombre)
		quit(1)
		return
	print("CAPTURE ", nombre)

func run() -> void:
	output = ProjectSettings.globalize_path("res://").path_join("../work/coloso-antiviral/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	var evento: Node2D = host.evento_coloso
	evento.set_physics_process(false)
	await create_timer(1.0).timeout
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(80.0)
	var bots := get_nodes_in_group("bots")
	for i in range(bots.size()):
		var bot: Node2D = bots[i]
		bot.set_physics_process(false)
		bot.get_node("TimerCambioRumbo").stop()
		if i > 5:
			var equipo := 1 if i % 2 == 0 else 2
			bot.activar_infeccion(Color.CYAN if equipo == 1 else Color.MAGENTA, equipo, false)
		bot.timer_contagio.stop()
		bot.timer_curacion.stop()
	for pato in get_nodes_in_group("patos"):
		pato.convertirse_en_fantasma()
		pato.set_physics_process(false)
	var limite := Time.get_ticks_msec() + 5000
	while not evento.navegacion.lista and Time.get_ticks_msec() < limite:
		await physics_frame
	evento.tiempo_partida = 30.0
	evento.chance_primera = 1.0 # Fixture visual: no modifica el valor de la escena.
	evento.azar_espacial.seed = 274
	evento.avanzar(5.0, host.contar_infecciones())
	if evento.estado != evento.Estado.AVISO:
		push_error("Capture could not begin real warning")
		quit(1)
		return
	await shot("01_aviso")
	evento.avanzar(3.0, host.contar_infecciones())
	if evento.coloso == null:
		push_error("Capture could not spawn real coloso")
		quit(1)
		return
	await shot("02_intervencion")
	var actor: Node2D = evento.coloso
	actor.pulso_visual = 0.4
	actor.queue_redraw()
	var curado: Node2D
	for bot in bots:
		if bot.is_infected and actor.global_position.distance_to(bot.global_position) < 140.0:
			curado = bot
			break
	if curado != null:
		curado.curar_por_coloso(1.0, 3.0, evento.azar_curacion)
	await shot("03_pulso")
	# Detalle aislado para revisar silueta y texto, sin cambiar cámara de la escena.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 480)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var detail: Node2D = load("res://scenes/coloso_antiviral.tscn").instantiate()
	detail.evento = evento
	detail.position = Vector2(320, 260)
	detail.scale = Vector2(1.5, 1.5)
	viewport.add_child(detail)
	await process_frame
	await RenderingServer.frame_post_draw
	if viewport.get_texture().get_image().save_png(output + "/04_detalle.png") != OK:
		quit(1)
		return
	print("CAPTURE 04_detalle")
	viewport.queue_free()
	host.queue_free()
	await process_frame
	await process_frame
	quit()

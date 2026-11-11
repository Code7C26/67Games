extends SceneTree
## Presentation fixture only: both live team scenes on the actual map.
const TEAMS = preload("res://scripts/equipos_infeccion.gd")
var host: Node2D
var output := ""
var failures := 0

func _initialize() -> void: run.call_deferred()

func save_view(viewport: Viewport, name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	if viewport.use_hdr_2d:
		picture.convert(Image.FORMAT_RGBA8)
		picture.linear_to_srgb()
	var error := picture.save_png(output.path_join(name + ".png"))
	if error != OK:
		failures += 1
		push_error("Cannot save symbiont review capture " + name)
	print("CAPTURE SIMBIONTE READABILITY ", name, " error=", error)

func freeze_bot(bot: Node2D) -> void:
	bot.set_physics_process(false)
	bot.timer_direccion.stop()
	bot.timer_contagio.stop()
	bot.timer_curacion.stop()
	bot.animated_sprite.stop()
	bot.feedback_restante = 0.0
	bot.queue_redraw()

func make_target(point: Vector2, team: int) -> Node2D:
	var bot = load("res://scenes/Bot.tscn").instantiate()
	host.get_node("Bots").add_child(bot)
	bot.global_position = point
	bot.activar_infeccion(TEAMS.color_equipo(team), team, false)
	freeze_bot(bot)
	return bot

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/jugabilidad-nov04/simbionte/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	seed(20261104)
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	var deadline := Time.get_ticks_msec() + 15000
	while not host.capullos_colocados and Time.get_ticks_msec() < deadline:
		await physics_frame
	if not host.capullos_colocados:
		push_error("Capture cannot place the real symbiont eggs")
		quit(1)
		return
	host._on_timer_inicio_timeout()
	while host.estado_actual == host.EstadoJuego.FASE_PATOS:
		await process_frame
	host.set_process(false)
	host.set_physics_process(false)
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)
	for bot in get_nodes_in_group("bots"): freeze_bot(bot)
	for duck in get_nodes_in_group("patos"):
		duck.set_physics_process(false)
		duck.animated_sprite.stop()
	host.adn_cian = 60
	host.adn_magenta = 60
	host.inversion_simbionte[0] = 30
	host.inversion_simbionte[1] = 45
	for egg in host.capullos:
		egg.set_process(false)
		egg.aspecto.set_process(false)
		egg.aspecto.play("inquieto" if egg.equipo == 2 else "reposo")
		egg.aspecto.set_frame_and_progress(0, 0.0)
		egg.aspecto.speed_scale = 0.0
		egg.queue_redraw()
	host.interfaz.sync(host.contar_infecciones())
	await save_view(root, "01_huevos_en_partida")

	# A real navigation candidate nearest an edge reviews the alternate label positions.
	var bounds: Rect2 = host.get_meta("bounds")
	var edge_point: Vector2 = host.capullos[0].global_position
	var most_exposed := -INF
	for point in host.navegacion_simbionte.posiciones_capullos:
		var exposure := maxf(bounds.position.x + 100.0 - point.x, maxf(point.x + 100.0 - bounds.end.x, bounds.position.y + 80.0 - point.y))
		if exposure > most_exposed:
			most_exposed = exposure
			edge_point = point
	host.capullos[0].global_position = edge_point
	host.capullos[0].queue_redraw()
	print("CAPTURE EDGE CASE bounds=", bounds, " egg=", edge_point, " unclamped_overflow=", most_exposed)
	await save_view(root, "02_huevo_en_borde")

	# Move only the visual fixtures into one real plaza for a readable side-by-side detail.
	for bot in get_nodes_in_group("bots"): bot.hide()
	for duck in get_nodes_in_group("patos"): duck.hide()
	var points := [Vector2(848, 592), Vector2(1072, 592)]
	for index in 2:
		host.capullos[index].global_position = points[index]
		host.capullos[index].queue_redraw()
	var detail := SubViewport.new()
	detail.size = Vector2i(1152, 560)
	detail.use_hdr_2d = root.use_hdr_2d
	detail.world_2d = host.get_world_2d()
	detail.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(detail)
	var camera := Camera2D.new()
	camera.position = Vector2(960, 580)
	camera.zoom = Vector2(2.5, 2.5)
	detail.add_child(camera)
	await save_view(detail, "03_huevos_ambos_equipos_detalle")
	for egg in host.capullos: egg.hide()
	var travelers: Array[Node2D] = []
	var targets: Array[Node2D] = []
	for index in 2:
		var traveler = load("res://scenes/simbionte.tscn").instantiate()
		traveler.equipo = index + 1
		traveler.mundo = host
		traveler.navegacion = host.navegacion_simbionte
		traveler.position = points[index]
		host.add_child(traveler)
		traveler.set_physics_process(false)
		traveler.aspecto.en_transicion = false
		traveler.aspecto.actualizar(Vector2.ZERO)
		traveler.aspecto.set_frame_and_progress(0, 0.0)
		traveler.aspecto.speed_scale = 0.0
		travelers.append(traveler)
		var target := make_target(points[index] + Vector2(0, 100), index + 1)
		target.hide()
		targets.append(target)
		if index == 0: traveler.objetivo = target
		traveler.queue_redraw()
	await save_view(detail, "04_viajeros_ambos_equipos_detalle")
	# The same smaller host transformation remains available for direct comparison.
	for index in 2:
		travelers[index].queue_free()
		targets[index].global_position = points[index]
		targets[index].show()
		var old_scale: Vector2 = targets[index].animated_sprite.scale
		targets[index].aplicar_simbionte(host, index + 1)
		var effect = targets[index].efecto_simbionte
		effect.set_physics_process(false)
		effect.aspecto.en_transicion = false
		effect.aspecto.actualizar(Vector2.ZERO)
		effect.aspecto.set_frame_and_progress(0, 0.0)
		effect.aspecto.speed_scale = 0.0
		if effect.aspecto.scale != old_scale:
			failures += 1
			push_error("Capture detected a changed fused-host scale")
	await save_view(detail, "05_fusionados_escala_conservada")
	detail.queue_free()
	host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	print("CAPTURE SIMBIONTE READABILITY RESULT ", failures, " failures")
	quit(0 if failures == 0 else 1)

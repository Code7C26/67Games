extends SceneTree
## Real HUD fixtures: existing possession buttons become manual hook actions.
var host: Node2D
var output := ""
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func shot(filename: String) -> void:
	host.interfaz.sync(host.contar_infecciones())
	host.interfaz.tick = 1.0
	host.interfaz._process(0.1)
	for _frame in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	check(image.save_png(output.path_join(filename + ".png")) == OK, "capture " + filename)

func check_headers(dimensions: Vector2i) -> void:
	var hud: CanvasLayer = host.interfaz
	var bounds := Rect2(Vector2.ZERO, Vector2(dimensions) / hud.ui_scale).grow(1.0)
	var boxes: Array = hud.top_boxes + [hud.clock_box, hud.event_box, hud.population_box]
	var clear := true
	for i in boxes.size():
		var rect: Rect2 = boxes[i].get_global_rect()
		clear = clear and bounds.encloses(rect)
		for j in range(i):
			clear = clear and not rect.intersects(boxes[j].get_global_rect())
	check(clear, "HUD headers fit without overlaps " + str(dimensions))

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/garfio-ajuste-nov05/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	root.set_meta("patogen_cepas", {1: "garfio", 2: "garfio"})
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if host.has_signal("map_ready") and not host.map_is_ready:
		await host.map_ready
	host.set_process(false)
	host.set_physics_process(false)
	host.timer_inicio.stop()
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(100.0)
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)
	var bots := get_nodes_in_group("bots")
	for bot in bots:
		bot.set_physics_process(false)
		bot.get_node("TimerCambioRumbo").stop()
		bot.timer_contagio.stop()
		bot.timer_curacion.stop()
	var ducks := get_nodes_in_group("patos")
	for duck in ducks:
		duck.convertirse_en_fantasma()
		duck.set_physics_process(false)
		var source: Node2D = bots[duck.player_id - 1]
		source.activar_infeccion(duck.color_jugador, duck.player_id, false)
		source.incubacion_contagio = 0.0
		source.feedback_restante = 0.0
		source.timer_contagio.stop()
		source.timer_curacion.stop()
		duck.iniciar_posesion(source)
		source.garfio.recarga_restante = 0.0
	host.interfaz.tick = 1.0
	host.interfaz._process(0.1)
	for team in 2:
		check(host.interfaz.ability_buttons[team].size() == 4, "four original ability slots team " + str(team + 1))
		var button: Button = host.interfaz.ability_buttons[team][3]
		check(button.text.begins_with("X Enganchar" if team == 0 else "J Enganchar") and not button.disabled, "manual hook action ready team " + str(team + 1))
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1024, 768)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		for _frame in 8:
			await process_frame
		check_headers(dimensions)
		await shot("hud_manual_listo_%dx%d" % [dimensions.x, dimensions.y])
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	for duck in ducks:
		duck.bot_poseido.garfio.recarga_restante = 5.8
	host.interfaz.tick = 1.0
	host.interfaz._process(0.1)
	for team in 2:
		var button: Button = host.interfaz.ability_buttons[team][3]
		check(button.disabled and button.text.contains("5.8s"), "hook cooldown visible team " + str(team + 1))
	await shot("hud_manual_recarga_1920x1080")
	host.free()
	root.get_node("AudioManager").detener_musica()
	await process_frame
	print("GARFIO_MANUAL_HUD ", checks, " checks / ", failures, " failures")
	quit(1 if failures else 0)

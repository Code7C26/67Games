extends SceneTree
const TEAMS = preload("res://scripts/equipos_infeccion.gd")
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var output := ProjectSettings.globalize_path("res://../work/reciclaje-nov05/capturas")
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	root.set_meta("patogen_cepas", {1: "exponencial", 2: "exponencial"})
	for map_name in ["Shopping", "Laboratorio", "PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		var host = load("res://scenes/%s.tscn" % map_name).instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready:
			await host.map_ready
		host.timer_inicio.stop()
		host.set_process(false)
		host.evento_coloso.set_physics_process(false)
		host.evento_alfa.set_physics_process(false)
		await create_timer(0.5).timeout
		host.estado_actual = host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(150)
		host.mutaciones_p1.assign(["reciclaje"])
		host.mutaciones_p2.assign(["reciclaje", "biomasa", "renacimiento"])
		for duck in get_nodes_in_group("patos"):
			duck.convertirse_en_fantasma()
			duck.set_physics_process(false)
		var bots: Array = host.get_node("Bots").get_children()
		for bot in bots:
			bot.process_mode = Node.PROCESS_MODE_DISABLED
		for i in range(20):
			var team := 1 if i < 10 else 2
			bots[i].activar_infeccion(TEAMS.color_equipo(team), team, false)
		for i in [0, 1, 10, 11, 12]:
			bots[i].curar(false)
		host.adn_cian = 14
		host.adn_magenta = 8
		host.interfaz.sync(host.contar_infecciones())
		host.interfaz.show_branch(1, 2)
		host.interfaz.show_branch(2, 2)
		if DisplayServer.get_name() != "headless":
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join(map_name + ".png"))
		bots[13]._contagiar_objetivo(bots[10])
		if host.replicas_magenta == 1 and host.biomasa_reciclaje[1] == 0:
			print("MAP_RECICLAJE PASS ", map_name)
		else:
			failures += 1
			push_error("MAP_RECICLAJE FAIL " + map_name)
		host.queue_free()
		await process_frame
		await process_frame
	print("CAPTURE RECICLAJE RESULT ", failures, " failed")
	quit(0 if failures == 0 else 1)

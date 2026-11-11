extends SceneTree
var output := ""

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/parasito-alfa/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var mapas := ["Shopping", "Laboratorio", "PatoSplash"]
	var elegido := OS.get_environment("ALFA_CAPTURE_MAP")
	if elegido in mapas:
		mapas = [elegido]
	for nombre in mapas:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		var host: Node2D = load("res://scenes/" + nombre + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host.evento_coloso.set_physics_process(false)
		var evento: Node2D = host.evento_alfa
		evento.set_physics_process(false)
		var deadline := Time.get_ticks_msec() + 10000
		while evento.posiciones.is_empty() and Time.get_ticks_msec() < deadline: await physics_frame
		host.estado_actual = host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(85.0)
		for pato in get_nodes_in_group("patos"):
			pato.convertirse_en_fantasma()
			pato.set_physics_process(false)
		evento.probabilidad = 1.0
		evento.azar_espacial.seed = 923
		evento.avanzar(35.0)
		for i in 30:
			if is_instance_valid(evento.alfa): break
			evento.avanzar(1.0)
		if not is_instance_valid(evento.alfa):
			push_error("FAIL capture spawn " + nombre)
			quit(1)
			return
		for bot in get_nodes_in_group("bots"):
			bot.set_physics_process(false)
			bot.get_node("TimerCambioRumbo").stop()
			bot.timer_contagio.stop()
			bot.timer_curacion.stop()
		evento.alfa.pulso = 0.5
		for i in 12: await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(output + "/" + nombre + ".png") != OK:
			quit(1)
			return
		print("CAPTURE ", nombre)
		if nombre == "Shopping":
			var viewport := SubViewport.new()
			viewport.size = Vector2i(800, 480)
			viewport.world_2d = World2D.new()
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var fondo := ColorRect.new()
			fondo.size = Vector2(800, 480)
			fondo.color = Color("13251f")
			viewport.add_child(fondo)
			var actor: Node2D = load("res://scenes/parasito_alfa.tscn").instantiate()
			actor.position = Vector2(400, 235)
			actor.scale = Vector2(3, 3)
			viewport.add_child(actor)
			actor.pulso = 0.4
			for punto in [Vector2(190, 340), Vector2(400, 385), Vector2(610, 340)]:
				var bot: Node2D = load("res://scenes/Bot.tscn").instantiate()
				bot.position = punto
				bot.scale = Vector2(2, 2)
				viewport.add_child(bot)
				bot.activar_infeccion(Color("7dff45"), 3, false)
				bot.set_physics_process(false)
				bot.timer_contagio.stop()
				bot.timer_curacion.stop()
				bot.get_node("TimerCambioRumbo").stop()
			await process_frame
			await RenderingServer.frame_post_draw
			if viewport.get_texture().get_image().save_png(output + "/detalle.png") != OK:
				quit(1)
				return
			print("CAPTURE detalle")
			viewport.queue_free()
		host.queue_free()
		await process_frame
		await process_frame
	quit()

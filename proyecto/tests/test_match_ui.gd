extends SceneTree
## Execute with --script res://tests/test_match_ui.gd -- --onboarding-test
var host: Node
var failures: Array[String] = []
var passes := 0
var transfers: Dictionary = {}
var output_dir := "res://tests/run_data/ui_oct22"

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		passes += 1
		print("PASS ", message)
	else:
		failures.append(message)
		push_error("FAIL " + message)

func shot(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir + "/" + filename + ".png")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	await create_timer(0.2).timeout
	var hud = host.interfaz
	check(host.get_node("PasosEntreExtremos/PasoNorte").destination.name == "LlegadaSur", "north links to south")
	check(host.get_node("PasosEntreExtremos/PasoSur").destination.name == "LlegadaNorte", "south links to north")
	var duck = host.get_node("Patos/Pato")
	var frames_seen: Array[int] = []
	duck.animated_sprite.frame_changed.connect(func():
		if duck.animated_sprite.animation == &"desaparecer":
			frames_seen.append(duck.animated_sprite.frame))
	host._on_timer_inicio_timeout()
	check(duck.esta_desapareciendo and not duck.modo_fantasma, "transition starts before ghost state")
	check(host.timer_juego.is_stopped(), "match clock waits for transition")
	for n in range(4):
		await create_timer(0.32).timeout
		duck.actualizar_animacion(Vector2.RIGHT)
		duck.infectar_y_desaparecer()
		check(duck.animated_sprite.animation == &"desaparecer", "movement/repeated request cannot interrupt transition %d" % n)
		await shot("transition_%d" % n)
	await create_timer(0.3).timeout
	check(duck.modo_fantasma and not duck.esta_desapareciendo, "ghost state completes")
	check(frames_seen.has(12) and frames_seen.size() >= 12, "all thirteen transition frames displayed")
	check(host.estado_actual == 1 and not host.timer_juego.is_stopped(), "infection phase starts after both ducks")
	check(duck.collision_layer == 0 and duck.animated_sprite.is_playing(), "ghost has no collision and continues animating")
	var scale_before: Vector2 = duck.grupo_visual_pato.scale
	var count_before: int = host.contagios_cian + host.contagios_magenta
	duck.infectar_y_desaparecer()
	duck.convertirse_en_fantasma()
	check(duck.grupo_visual_pato.scale == scale_before and host.contagios_cian + host.contagios_magenta == count_before, "transition is idempotent")
	host.timer_juego.paused = true
	# Keep gameplay NPCs away from the controlled portal cases.
	for bot in host.get_node("Bots").get_children():
		bot.process_mode = Node.PROCESS_MODE_DISABLED
		bot.collision_layer = 0
		bot.global_position = Vector2(-5000, -5000)
	await physics_frame
	await physics_frame
	for portal_name in ["PasoNorte", "PasoSur", "PasoOeste", "PasoEste"]:
		await test_portal(portal_name)
	# Actual mouse and keyboard delivery, plus all three strains and costs.
	host.adn_cian = 30
	host.adn_magenta = 30
	await process_frame
	var before: int = host.adn_cian
	var button: Button = hud.panels[0].get_node("VBoxContainer/BtnFiebre")
	var point := button.get_global_transform_with_canvas() * (button.size * 0.5)
	var mouse := InputEventMouseButton.new()
	mouse.position = point
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await process_frame
	mouse.pressed = false
	Input.parse_input_event(mouse)
	await process_frame
	check(host.adn_cian == before - 5 and host.mutaciones_p1.size() == 1, "mouse buys mutation and debits ADN exactly once")
	await process_frame
	check(hud.adn_labels[0].text == "%d ADN" % host.adn_cian, "displayed ADN matches model")
	check(hud.dna_sprites[0].is_playing(), "Aseprite ADN feedback plays after debit")
	for strain in ["atletico", "area", "exponencial"]:
		host.cepa_magenta = strain
		host.mutaciones_p2.clear()
		host.adn_magenta = 30
		await process_frame
		for level in range(host.obtener_ramas_jugador(2)[0].size()):
			var cost: int = host.obtener_costo_mutacion(host.obtener_ramas_jugador(2)[0][0], host.mutaciones_p2)
			var old: int = host.adn_magenta
			key(KEY_8)
			await process_frame
			check(host.adn_magenta == old - cost, "%s keyboard mutation level %d charges %d" % [strain, level, cost])
		check(hud.panels[1].get_node("VBoxContainer/BtnFiebre").disabled, "%s completed branch disabled" % strain)
	host.adn_cian = 0
	await process_frame
	check(button.disabled, "unaffordable mutation disabled")
	var layout_before: int = hud.layout_updates
	var mutation_before: int = hud.mutation_updates
	await create_timer(0.2).timeout
	check(hud.layout_updates == layout_before and hud.mutation_updates == mutation_before, "stable HUD performs no layout or mutation rebuild")
	key(KEY_E)
	await process_frame
	check(not hud.panels[0].visible, "E closes mutation dock")
	key(KEY_E)
	await process_frame
	check(hud.panels[0].visible, "E reopens mutation dock")
	for size in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(1366,768),Vector2i(1024,768),Vector2i(2560,1080),Vector2i(960,540)]:
		root.content_scale_size = size
		root.size = size
		await create_timer(0.15).timeout
		for panel in hud.panels:
			var rect: Rect2 = panel.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, panel.size)
			check(not rect.intersects(hud.map_screen_rect), "dock outside map at %s" % size)
			check(Rect2(Vector2.ZERO, Vector2(size)).encloses(rect), "dock inside viewport at %s" % size)
		var top_outside := true
		for status in hud.top_boxes + [hud.clock_box]:
			var status_rect: Rect2 = status.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, status.size)
			top_outside = top_outside and not status_rect.intersects(hud.map_screen_rect)
		check(top_outside, "status bars outside map at %s" % size)
		var help: Button = host.get_node("PatogenIntroduction").ui.help
		var help_rect := help.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, help.size)
		var help_clear := not help_rect.intersects(hud.map_screen_rect)
		for panel in hud.panels:
			var panel_rect: Rect2 = panel.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, panel.size)
			help_clear = help_clear and not help_rect.intersects(panel_rect)
		check(help_clear, "tutorial help stays clear of map and mutation docks at %s" % size)
		check(Rect2(Vector2.ZERO, Vector2(size)).encloses(help_rect), "tutorial help inside viewport at %s" % size)
		var motion := InputEventMouseMotion.new()
		motion.position = hud.map_screen_rect.get_center()
		Input.parse_input_event(motion)
		await process_frame
		check(root.gui_get_hovered_control() == null, "map centre receives mouse at %s" % size)
		await shot("hud_%dx%d" % [size.x,size.y])
	# Restore population for a representative capture, using original scene placement.
	root.content_scale_size = Vector2i(1920,1080)
	root.size = Vector2i(1920,1080)
	await process_frame
	var scene = load("res://scenes/Shopping.tscn").instantiate()
	var original_bots = scene.get_node("Bots").get_children()
	var live_bots = host.get_node("Bots").get_children()
	for i in range(original_bots.size()):
		live_bots[i].position = original_bots[i].position
	scene.free()
	host.adn_cian = 12
	host.adn_magenta = 8
	await create_timer(0.2).timeout
	await shot("hud_final")
	var result := {"passes":passes, "failures":failures}
	var file := FileAccess.open(output_dir + "/results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print("RESULT ", JSON.stringify(result))
	host.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func test_portal(portal_name: String) -> void:
	var portal = host.get_node("PasosEntreExtremos/" + portal_name)
	var actors: Array = []
	for i in range(4 if portal_name in ["PasoNorte", "PasoSur"] else 1):
		var bot = load("res://scenes/Bot.tscn").instantiate()
		host.add_child(bot)
		var sideways: Vector2 = Vector2.RIGHT if portal_name in ["PasoNorte", "PasoSur"] else Vector2.ZERO
		bot.global_position = portal.global_position + sideways * (float(i) - 1.5) * 24.0
		bot.controlado_por_jugador = true
		# Wait for a free landing, then continue inward under the actual bot controller.
		bot.direccion_control_jugador = Vector2.ZERO
		bot.set_meta("case_transfers", 0)
		actors.append(bot)
	var handler = func(body, _arrival):
		if body in actors:
			body.set_meta("case_transfers", int(body.get_meta("case_transfers")) + 1)
			body.direccion_control_jugador = portal.exit_direction
	portal.transferred.connect(handler)
	await create_timer(3.4).timeout
	for bot in actors:
		print("PORTAL ", portal_name, " count=", bot.get_meta("case_transfers"), " pos=", bot.global_position, " landing=", portal.destination.global_position)
		check(bot.get_meta("case_transfers") == 1, "%s multi-bot transfers once" % portal_name)
		check(bot.get_meta("case_transfers") == 1 and bot.global_position.distance_to(portal.destination.global_position) > 34, "%s bot continues after arrival" % portal_name)
	portal.transferred.disconnect(handler)
	for bot in actors:
		bot.queue_free()
	await physics_frame
	await physics_frame

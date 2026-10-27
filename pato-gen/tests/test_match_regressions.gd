extends SceneTree
var host: Node
var failures := 0
var passed := 0
func _initialize():
	run.call_deferred()
func check(ok: bool, message: String):
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)
func run():
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	for bot in host.get_node("Bots").get_children():
		bot.queue_free()
	await physics_frame
	await physics_frame
	for portal_name in ["PasoNorte", "PasoSur"]:
		var portal = host.get_node("PasosEntreExtremos/" + portal_name)
		var blocker := StaticBody2D.new()
		blocker.position = portal.destination.global_position
		var collision := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 24
		collision.shape = circle
		blocker.add_child(collision)
		host.add_child(blocker)
		var bot = load("res://scenes/Bot.tscn").instantiate()
		host.add_child(bot)
		bot.global_position = portal.global_position
		bot.set_physics_process(false)
		bot.get_node("TimerCambioRumbo").stop()
		var counts := [0]
		var handler = func(body, _arrival):
			if body == bot: counts[0] += 1
		portal.transferred.connect(handler)
		await create_timer(0.4).timeout
		check(counts[0] == 0 and bot.global_position == portal.global_position, portal_name + " waits at an occupied landing")
		blocker.queue_free()
		await create_timer(0.4).timeout
		check(counts[0] == 1 and bot.global_position == portal.destination.global_position, portal_name + " retries after landing is clear")
		await create_timer(1.2).timeout
		check(counts[0] == 1, portal_name + " idle arrival cannot bounce after cooldown")
		bot.set_physics_process(true)
		await create_timer(0.4).timeout
		check(bot.global_position.distance_to(portal.destination.global_position) > 20, portal_name + " autonomous AI resumes")
		check(not bot.controlado_por_jugador and not bot.is_infected, portal_name + " preserves AI and infection state")
		portal.transferred.disconnect(handler)
		bot.queue_free()
		await physics_frame
		await physics_frame
		check(not portal.is_physics_processing(), portal_name + " disables polling when empty")
	# Both players' abilities still spend the same amounts and show cooldowns.
	host._on_timer_inicio_timeout()
	await create_timer(1.6).timeout
	host.adn_cian = 30
	host.adn_magenta = 30
	for team in range(2):
		var before: int = host.adn_cian if team == 0 else host.adn_magenta
		host.interfaz._ability(team, 1)
		await process_frame
		var after: int = host.adn_cian if team == 0 else host.adn_magenta
		check(before - after == host.COSTO_ZONA_TEMPERATURA, "zone charges correct ADN team %d" % team)
		await create_timer(0.12).timeout
		check(host.interfaz.ability_buttons[team][1].disabled and "s" in host.interfaz.ability_buttons[team][1].text, "zone cooldown shown team %d" % team)
	# The clock advances, then game-over pauses gameplay as before.
	var before_time: float = host.timer_juego.time_left
	await create_timer(1.1).timeout
	check(host.timer_juego.time_left < before_time - 0.9, "real match timer advances")
	var seconds := ceili(host.timer_juego.time_left)
	check(host.interfaz.clock_label.text == "%02d:%02d" % [floori(seconds / 60.0), seconds % 60], "display matches actual timer")
	check(host.interfaz.mutation_icons.size() == 23, "all 23 mutation icons loaded")
	host._on_timer_juego_timeout()
	check(paused and host.game_over_screen.visible, "game-over still displays result and pauses")
	paused = false
	host.queue_free()
	await process_frame
	await process_frame
	# Historical scenes sharing Mapa.gd remain loadable, source scenes unchanged.
	for path in ["res://scenes/PatogenMall_Editable.tscn", "res://scenes/mapaviejo.tscn", "res://scenes/Mapa.tscn"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		host = load(path).instantiate()
		root.add_child(host)
		current_scene = host
		await process_frame
		await process_frame
		check(host.interfaz.has_method("sync") and is_instance_valid(host.panel_cian), "shared controller compatible with " + path.get_file())
		host.queue_free()
		await process_frame
		await process_frame
	print("REGRESSION RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

extends SceneTree
const APARIENCIA = preload("res://scripts/aspecto_simbionte.gd")
const CUADROS = preload("res://resources/animations/simbionte.tres")
var passed := 0
var failures := 0
var host: Node

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func bot_at(point: Vector2, team: int) -> Node2D:
	var bot = load("res://scenes/Bot.tscn").instantiate()
	host.get_node("Bots").add_child(bot)
	bot.position = point
	bot.set_physics_process(false)
	bot.get_node("TimerCambioRumbo").stop()
	bot.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	bot.timer_contagio.stop()
	bot.timer_curacion.stop()
	return bot

func run() -> void:
	check(CUADROS.get_animation_names().size() == 10, "ten animations exported from Aseprite")
	for name in CUADROS.get_animation_names():
		var correct := true
		for i in range(CUADROS.get_frame_count(name)):
			correct = correct and CUADROS.get_frame_texture(name, i).get_size() == Vector2(32, 32)
		check(correct, String(name) + " uses complete untrimmed 32x32 frames")
	var art = APARIENCIA.new()
	root.add_child(art)
	art.configurar_equipo(1)
	var dirs := {"Abajo": Vector2.DOWN, "Arriba": Vector2.UP, "Derecha": Vector2.RIGHT, "Izquierda": Vector2.LEFT}
	for dir: String in dirs:
		art.actualizar(dirs[dir] * 150)
		check(art.animation == StringName("caminar_" + dir), "movement faces " + dir)
		art.actualizar(Vector2.ZERO)
		check(art.animation == StringName("reposo_" + dir) and art.is_playing(), "breathing retains " + dir)
	art.actualizar(Vector2.RIGHT * 150)
	await create_timer(0.21).timeout
	check(art.frame > 0, "walk actually advances through poses")
	art.actualizar(Vector2.RIGHT * 150, false)
	var frozen_frame: int = art.frame
	var frozen_progress: float = art.frame_progress
	await create_timer(0.2).timeout
	check(art.frame == frozen_frame and is_equal_approx(art.frame_progress, frozen_progress), "held match clock freezes animation")
	art.actualizar(Vector2.ZERO)
	art.transicionar(&"eclosion")
	await create_timer(0.8).timeout
	check(not art.en_transicion and art.animation == &"reposo_Derecha", "hatching completes into directional idle")
	art.queue_free()
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	host.set_process(false)
	for bot in host.get_node("Bots").get_children():
		bot.queue_free()
	for duck in get_nodes_in_group("patos"):
		duck.set_physics_process(false)
	await physics_frame
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(120)
	var cyan := bot_at(Vector2(720, 592), 1)
	var magenta := bot_at(Vector2(816, 592), 2)
	check(cyan.aplicar_simbionte(host, 1) and magenta.aplicar_simbionte(host, 2), "both teams acquire the visible transformation")
	var effect = cyan.efecto_simbionte
	check(not cyan.animated_sprite.visible and effect.aspecto.visible, "symbiont body replaces the host sprite")
	check(effect.aspecto.animation == &"fusion" and effect.aspecto.en_transicion, "liquid coating starts on actual fusion")
	check(effect.aspecto.material != magenta.efecto_simbionte.aspecto.material, "each team owns its recolor material")
	check(effect.aspecto.material.get_shader_parameter("color_vena") != magenta.efecto_simbionte.aspecto.material.get_shader_parameter("color_vena"), "cyan and magenta have different veins")
	await create_timer(0.7).timeout
	cyan.velocity = Vector2.LEFT * 150
	effect._physics_process(0.0)
	check(effect.aspecto.animation == &"caminar_Izquierda", "fused body follows host movement")
	cyan.velocity = Vector2.ZERO
	effect._physics_process(0.0)
	check(effect.aspecto.animation == &"reposo_Izquierda", "fused body breathes while stopped")
	if DisplayServer.get_name() != "headless":
		# Deterministic real-map render, isolated from normal play.
		var traveler = load("res://scenes/simbionte.tscn").instantiate()
		traveler.mundo = host
		traveler.navegacion = host.navegacion_simbionte
		traveler.position = Vector2(624, 592)
		host.add_child(traveler)
		traveler.set_physics_process(false)
		traveler.aspecto.en_transicion = false
		traveler.aspecto.actualizar(Vector2.ZERO)
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://tests/run_data/simbionte_sprite")
		root.get_texture().get_image().save_png("res://tests/run_data/simbionte_sprite/in_game.png")
		# Render a close view from the same real map, without resampling sprites.
		var close_view := SubViewport.new()
		close_view.size = Vector2i(768, 320)
		close_view.world_2d = host.get_world_2d()
		close_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(close_view)
		var camera := Camera2D.new()
		camera.position = Vector2(720, 567)
		camera.zoom = Vector2(3, 3)
		close_view.add_child(camera)
		await process_frame
		await RenderingServer.frame_post_draw
		close_view.get_texture().get_image().save_png("res://tests/run_data/simbionte_sprite/closeup.png")
		close_view.queue_free()
		print("CAPTURE real map with traveller and both fused teams")
	host.timer_juego.paused = true
	effect._physics_process(0.0)
	check(effect.aspecto.speed_scale == 0.0, "tutorial pause reaches fused animation")
	host.timer_juego.paused = false
	effect.avanzar(20)
	check(cyan.animated_sprite.visible and cyan.efecto_simbionte == null, "expiry immediately restores original visibility")
	magenta.curar(false)
	check(magenta.animated_sprite.visible and magenta.animated_sprite.sprite_frames == magenta.sprite_frames_sano, "healing restores healthy skin")
	cyan.animated_sprite.hide()
	cyan.aplicar_simbionte(host, 1)
	cyan.quitar_simbionte()
	check(not cyan.animated_sprite.visible, "cleanup preserves pre-existing hidden state")
	cyan.animated_sprite.show()
	cyan.aplicar_simbionte(host, 1)
	cyan.efecto_simbionte.queue_free()
	await process_frame
	check(cyan.animated_sprite.visible and cyan.efecto_simbionte == null, "external removal also restores host")
	host.queue_free()
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	print("SIMBIONTE SPRITE RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

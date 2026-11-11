extends SceneTree
const TEAMS = preload("res://scripts/equipos_infeccion.gd")

func _initialize() -> void: run.call_deferred()

func text_at(value: String, point: Vector2, size: int, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = value
	label.position = point
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)

func run() -> void:
	root.size = Vector2i(1120, 450)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var background := ColorRect.new()
	background.color = Color("15202f")
	background.size = Vector2(1120, 450)
	root.add_child(background)
	text_at("Infectados: misma altura y colores de equipo", Vector2(36, 20), 28)
	text_at("Detalle ampliado x4. Pies alineados; colisiones originales.", Vector2(36, 61), 18, Color("a3b5cd"))
	var strains := ["atletico", "area", "exponencial"]
	var names := ["ATLÉTICO", "DE ÁREA", "EXPONENCIAL"]
	for index in strains.size():
		var center := 190.0 + index * 370.0
		text_at(names[index], Vector2(center - 75, 105), 21)
		var ground := ColorRect.new()
		ground.position = Vector2(center - 163, 310)
		ground.size = Vector2(326, 2)
		ground.color = Color("40516c")
		root.add_child(ground)
		for team in [1, 2]:
			var bot = load("res://scenes/Bot.tscn").instantiate()
			bot.position = Vector2(center - 80 if team == 1 else center + 80, 250)
			bot.scale = Vector2(4, 4)
			root.add_child(bot)
			bot.set_physics_process(false)
			bot.timer_direccion.stop()
			bot.cepa = strains[index]
			bot.activar_infeccion(TEAMS.COLOR_AZUL if team == 1 else TEAMS.COLOR_MAGENTA, team, false)
			bot.timer_contagio.stop()
			bot.timer_curacion.stop()
			bot.feedback_restante = 0.0
			bot.animated_sprite.play("Abajo")
			bot.animated_sprite.stop()
			bot.animated_sprite.frame = 0
			bot.queue_redraw()
			text_at("AZUL" if team == 1 else "MAGENTA", Vector2(bot.position.x - 40, 335), 18, TEAMS.COLOR_AZUL if team == 1 else TEAMS.COLOR_MAGENTA)
	text_at("La animación conserva su movimiento natural sin cambiar de escala entre fotogramas.", Vector2(36, 403), 18, Color("a3b5cd"))
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if root.use_hdr_2d:
		picture.convert(Image.FORMAT_RGBA8)
		picture.linear_to_srgb()
	var folder := ProjectSettings.globalize_path("res://../work/jugabilidad-nov04/capturas")
	DirAccess.make_dir_recursive_absolute(folder)
	var error := picture.save_png(folder.path_join("infectados-altura.png"))
	print("CAPTURE BOT READABILITY ", error, " ", folder)
	for bot in get_nodes_in_group("bots"): bot.queue_free()
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	quit(error)

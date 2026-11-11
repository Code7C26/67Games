extends "res://tests/test_camaleon.gd"
## Contact sheet rendered by Godot from production Bot sprites and materials.
const DIRECTIONS := {"Abajo": Vector2.DOWN, "Arriba": Vector2.UP, "Derecha": Vector2.RIGHT, "Izquierda": Vector2.LEFT}
const CAPTURE_FONT = preload("res://Fuentes/press-start-2p.ttf")
var previews: Array[Node2D] = []
var output := ""
var status: Label

func label(parent: Node, text: String, at: Vector2, size: int, color: Color = Color("f3eee0")) -> Label:
	var result := Label.new()
	result.text = text
	result.position = at
	result.add_theme_font_override("font", CAPTURE_FONT)
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	parent.add_child(result)
	return result

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/balances-visuales-nov06/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	await preparar()
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	var background := ColorRect.new()
	background.color = Color("09181e")
	background.size = Vector2(1920, 1080)
	overlay.add_child(background)
	var board := Node2D.new()
	overlay.add_child(board)
	label(board, "CAMALEÓN · CICLO DE MARCHA", Vector2(45, 25), 20)
	label(board, "Sprites y shader del Bot real · cuatro direcciones · ambos equipos y pieles", Vector2(45, 76), 20, Color("a8bec2"))
	status = label(board, "4 CUADROS · 8 FPS · MARCHA / REPOSO", Vector2(45, 117), 20, Color("a8bec2"))
	var directions := DIRECTIONS.keys()
	for column in directions.size(): label(board, directions[column].to_upper(), Vector2(450 + column * 350, 150), 20)
	for row in 4:
		var team := 1 if row < 2 else 2
		var concealed := row % 2 == 1
		var accent := Color("58d8d8") if team == 1 else Color("ed88b9")
		label(board, "AZUL" if team == 1 else "MAGENTA", Vector2(45, 238 + row * 200), 20, accent)
		label(board, "Camuflado" if concealed else "Revelado", Vector2(45, 277 + row * 200), 20)
		for column in directions.size():
			var source := actor(ORIGIN + Vector2(column * 100, row * 100), team)
			var ability: Node2D = source.camaleon
			ability.camuflado = concealed
			ability.mezcla_visual = 1.0 if concealed else 0.0
			source.actualizar_animacion(DIRECTIONS[directions[column]])
			var sprite: AnimatedSprite2D = source.animated_sprite
			sprite.reparent(board)
			sprite.position = Vector2(525 + column * 350, 290 + row * 200)
			sprite.scale = Vector2(6, 6)
			sprite.pause()
			previews.append(source)
	for frame in 4:
		for source in previews: source.animated_sprite.frame = frame
		await shot("camaleon_marcha_cuadro_%d" % (frame + 1))
	for source in previews: source.actualizar_animacion(Vector2.ZERO)
	await shot("camaleon_reposo_cuatro_direcciones")
	for source in previews: source.animated_sprite.queue_free()
	previews.clear()
	if is_instance_valid(host): host.queue_free()
	overlay.queue_free()
	await process_frame
	await process_frame
	load("res://scripts/camaleon_arte.gd").limpiar_cache()
	READABILITY.textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	print("CAMALEON ANIMATION CAPTURE RESULT ", failures, " failures")
	quit(0 if failures == 0 else 1)

func shot(file_name: String) -> void:
	# Let the explicit font atlas finish uploading before the screenshot readback.
	await create_timer(0.35).timeout
	for _i in 12: await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image()
	if root.use_hdr_2d:
		result.convert(Image.FORMAT_RGBA8)
		result.linear_to_srgb()
	check(result.save_png(output.path_join(file_name + ".png")) == OK, "rendered contact sheet " + file_name)

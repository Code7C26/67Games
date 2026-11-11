extends SceneTree
## GPU review of the actual map actor; source artwork is never modified.
var output := ""
var failures := 0

func _initialize() -> void: run.call_deferred()

func snapshot(viewport: Viewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	if viewport.use_hdr_2d:
		picture.convert(Image.FORMAT_RGBA8)
		picture.linear_to_srgb()
	return picture

func different_pixels(a: Image, b: Image, first_y: int, last_y: int) -> int:
	var count := 0
	for y in range(first_y, last_y):
		for x in a.get_width():
			if a.get_pixel(x,y) != b.get_pixel(x,y): count += 1
	return count

func freeze_bot(bot: Node2D) -> void:
	bot.set_physics_process(false)
	bot.timer_direccion.stop()
	bot.timer_contagio.stop()
	bot.timer_curacion.stop()
	bot.animated_sprite.stop()
	bot.feedback_restante = 0.0
	bot.queue_redraw()

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/jugabilidad-nov04/alfa").simplify_path()
	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	root.size = Vector2i(1920,1080)
	var boot := root.get_node("PatogenOnboarding")
	boot.requested_mode = "direct"
	var old_reduced: bool = boot.profile.data.reduced_motion
	boot.profile.data.reduced_motion = false
	var host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	host.evento_coloso.set_physics_process(false)
	var event = host.evento_alfa
	event.set_physics_process(false)
	var deadline := Time.get_ticks_msec() + 15000
	while event.posiciones.is_empty() and Time.get_ticks_msec() < deadline: await physics_frame
	for bot in get_nodes_in_group("bots"): freeze_bot(bot)
	event.generado.connect(freeze_bot)
	for duck in get_nodes_in_group("patos"):
		duck.convertirse_en_fantasma()
		duck.set_physics_process(false)
		duck.animated_sprite.stop()
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	host.timer_juego.start(85.0)
	event.probabilidad = 1.0
	event.azar_espacial.seed = 482
	event.avanzar(35.0)
	for i in 20:
		if is_instance_valid(event.alfa): break
		event.avanzar(1.0)
	if not is_instance_valid(event.alfa):
		push_error("GPU review could not spawn the real Alfa")
		quit(1)
		return
	var actor = event.alfa
	event.avanzar(0.7)
	host.set_process(false)
	host.set_physics_process(false)
	host.interfaz.sync(host.contar_infecciones())
	var full: Image = await snapshot(root)
	full.save_png(output.path_join("alfa_en_partida.png"))
	var detail := SubViewport.new()
	detail.size = Vector2i(720,480)
	detail.use_hdr_2d = root.use_hdr_2d
	detail.world_2d = host.get_world_2d()
	detail.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(detail)
	var camera := Camera2D.new()
	camera.position = actor.global_position + Vector2(0,-10)
	camera.zoom = Vector2(4,4)
	detail.add_child(camera)
	# One isolated copy of the real material makes a precise 64 px comparison,
	# unaffected by animated scenery, map lighting or GUI overlays.
	var pixels := SubViewport.new()
	pixels.size = Vector2i(64,64)
	pixels.use_hdr_2d = root.use_hdr_2d
	pixels.transparent_bg = true
	pixels.world_2d = World2D.new()
	pixels.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(pixels)
	var sprite := Sprite2D.new()
	sprite.position = Vector2(32,32)
	sprite.texture = actor.aspecto.texture
	sprite.hframes = 8
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material = actor.material_reposo
	pixels.add_child(sprite)
	var baseline: Image = await snapshot(pixels)
	for frame in 12:
		event.avanzar(0.2)
		var rendered: Image = await snapshot(detail)
		rendered.save_png(output.path_join("frames/alfa_%03d.png" % frame))
	var changed: Image = await snapshot(pixels)
	var torso_changes := different_pixels(baseline, changed, 0, 49)
	var root_changes := different_pixels(baseline, changed, 49, 64)
	# A different phase inside the same breathing cycle must visibly change pixels.
	event.avanzar(0.6)
	var second: Image = await snapshot(pixels)
	torso_changes = maxi(torso_changes, different_pixels(baseline, second, 0, 49))
	root_changes = maxi(root_changes, different_pixels(baseline, second, 49, 64))
	host.timer_juego.paused = true
	var held: Image = await snapshot(pixels)
	event.avanzar(2.0)
	var held_after: Image = await snapshot(pixels)
	var held_changes := different_pixels(held, held_after, 0, 64)
	host.timer_juego.paused = false
	boot.profile.data.reduced_motion = true
	event.avanzar(0.1)
	var reduced: Image = await snapshot(pixels)
	event.avanzar(0.8)
	var reduced_after: Image = await snapshot(pixels)
	var reduced_changes := different_pixels(reduced, reduced_after, 0, 64)
	boot.profile.data.reduced_motion = false
	event.avanzar(9.66 - event.tiempo_activo)
	event.avanzar(0.34)
	var born: Image = await snapshot(detail)
	born.save_png(output.path_join("nacimiento_sincronizado.png"))
	var report := {"renderer":RenderingServer.get_current_rendering_method(), "rest_png_frames":12, "frame_duration_ms":200, "upper_body_pixels_changed":torso_changes, "root_pixels_changed":root_changes, "held_clock_pixels_changed":held_changes, "reduced_motion_pixels_changed":reduced_changes, "actual_generated_bots":event.generados, "birth_sprite_frame":actor.aspecto.frame}
	if torso_changes < 10 or root_changes != 0 or held_changes != 0 or reduced_changes != 0 or event.generados != 4 or actor.aspecto.frame != 3:
		failures += 1
		push_error("GPU rest review did not preserve its visible motion, roots or actual birth")
	report["failures"] = failures
	var file := FileAccess.open(output.path_join("render_check.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("ALFA GPU REST ", JSON.stringify(report))
	boot.profile.data.reduced_motion = old_reduced
	detail.queue_free()
	pixels.queue_free()
	host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	print("ALFA GPU REST RESULT ", failures, " failures")
	quit(0 if failures == 0 else 1)

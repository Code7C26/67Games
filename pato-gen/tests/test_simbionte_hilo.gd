extends "res://tests/test_simbionte.gd"
const EQUIPOS = preload("res://scripts/equipos_infeccion.gd")

func run() -> void:
	for team in [1, 2]:
		await _thread_for_team(team)
	if DisplayServer.get_name() != "headless":
		await _capture_threads()
	print("SIMBIONTE HILO RESULT ", passed, " passed; ", failures, " failed")
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await process_frame
	quit(0 if failures == 0 else 1)

func _thread_for_team(team: int) -> void:
	await fresh()
	var traveler := walker_at(Vector2(656, 568), team)
	traveler.set_physics_process(false)
	var thread: Line2D = traveler.hilo_objetivo
	check(not thread.visible and thread.points.is_empty(), "no target leaves no orphan thread")
	var rival := bot_at(Vector2(676, 568), 3 - team)
	var healthy := bot_at(Vector2(696, 568), 0)
	var target := bot_at(Vector2(816, 568), team)
	var fallback := bot_at(Vector2(896, 568), team)
	traveler.buscar_objetivo()
	check(traveler.objetivo == target and thread.visible, "thread identifies the nearest infected ally, ignoring rivals and healthy bots")
	check(thread.default_color.is_equal_approx(Color(EQUIPOS.color_equipo(team), 0.8)), "thread uses the traveler's actual team color")
	check(thread.points[0].is_equal_approx(Vector2(0, -10)) and thread.points[-1].is_equal_approx(traveler.to_local(target.global_position) + Vector2(0, -10)), "thread endpoints attach to the traveler and selected host")
	target.global_position += Vector2(35, 12)
	traveler._physics_process(0.1)
	check(thread.points[-1].is_equal_approx(traveler.to_local(target.global_position) + Vector2(0, -10)), "thread follows target and traveler movement")
	var phase: float = traveler.fase_hilo
	var points := thread.points
	host.timer_juego.paused = true
	traveler._physics_process(2.0)
	check(traveler.fase_hilo == phase and thread.points == points, "held match clock freezes thread animation")
	host.timer_juego.paused = false
	var profile = root.get_node("PatogenOnboarding").profile
	var previous_reduced: bool = bool(profile.data.get("reduced_motion", false))
	profile.data["reduced_motion"] = true
	traveler._actualizar_hilo()
	var direction: Vector2 = thread.points[-1] - thread.points[0]
	var straight := true
	for point in thread.points:
		straight = straight and absf(direction.normalized().cross(point - thread.points[0])) < 0.001
	check(straight and thread.visible, "reduced motion retains a static thread without oscillation")
	profile.data["reduced_motion"] = previous_reduced
	target.curar(false)
	traveler._physics_process(0.0)
	check(traveler.objetivo == fallback and thread.points[-1].is_equal_approx(traveler.to_local(fallback.global_position) + Vector2(0, -10)), "healed target retargets the thread to another valid ally")
	fallback.curar(false)
	fallback.activar_infeccion(EQUIPOS.color_equipo(3 - team), 3 - team, false)
	freeze_bot(fallback)
	traveler._physics_process(0.0)
	check(traveler.objetivo == null and not thread.visible and thread.points.is_empty(), "ownership change clears a thread with no valid replacement")
	target.activar_infeccion(EQUIPOS.color_equipo(team), team, false)
	freeze_bot(target)
	traveler.buscar_objetivo()
	target.queue_free()
	traveler._actualizar_hilo()
	check(not thread.visible, "queued target deletion hides its thread immediately")
	await process_frame
	traveler._physics_process(0.0)
	check(traveler.objetivo == null and not thread.visible, "freed target leaves no invalid thread reference")
	var contact := bot_at(Vector2(816, 568), team)
	traveler.global_position = contact.global_position
	traveler.buscar_objetivo()
	var contact_deadline := Time.get_ticks_msec() + 1000
	while not traveler.contacto.overlaps_body(contact) and Time.get_ticks_msec() < contact_deadline:
		await physics_frame
	check(traveler.contacto.overlaps_body(contact), "contact fixture synchronizes its newly inserted target")
	check(traveler.intentar_fusion() and not thread.visible, "physical fusion hides the target thread immediately")
	await process_frame
	check(not is_instance_valid(thread) and not is_instance_valid(traveler), "fusion frees thread with its traveler")
	rival.queue_free()
	healthy.queue_free()

func _capture_threads() -> void:
	await fresh()
	for egg in host.capullos: egg.hide()
	for duck in get_nodes_in_group("patos"): duck.hide()
	for team in [1, 2]:
		var y := 558.0 if team == 1 else 600.0
		var traveler := walker_at(Vector2(692, y), team)
		traveler.set_physics_process(false)
		bot_at(Vector2(1088, y), team)
		traveler.buscar_objetivo()
		traveler.aspecto.en_transicion = false
		traveler.aspecto.actualizar(Vector2.ZERO)
	var detail := SubViewport.new()
	detail.size = Vector2i(1280, 520)
	detail.use_hdr_2d = root.use_hdr_2d
	detail.world_2d = host.get_world_2d()
	detail.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(detail)
	var camera := Camera2D.new()
	camera.position = Vector2(890, 568)
	camera.zoom = Vector2(2.0, 2.0)
	detail.add_child(camera)
	await create_timer(0.5).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := detail.get_texture().get_image()
	if detail.use_hdr_2d:
		picture.convert(Image.FORMAT_RGBA8)
		picture.linear_to_srgb()
	var output := ProjectSettings.globalize_path("res://../work/simbionte-segundo-huesped-nov07/hilo_ambos_equipos.png").simplify_path()
	check(picture.save_png(output) == OK, "real renderer captures both team threads")
	print("CAPTURE ", output)
	detail.queue_free()

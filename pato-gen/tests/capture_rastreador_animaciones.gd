extends "res://tests/test_rastreador.gd"
## Actual Mobile/Vulkan viewport frames, two real possessed bodies and native playback.
var capture_output := ""
var captured: Array[Dictionary] = []
var capture_errors := 0
var capture_rect := Rect2i()
var sources: Array[Node2D] = []

func guardar_frame(phase: String) -> void:
	await RenderingServer.frame_post_draw
	# Pause only the staged recording while PNG readback/encoding runs. This
	# keeps a slow disk from adding uncaptured movement between video frames.
	paused = true
	var image := root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	var filename := "%03d_%s.png" % [captured.size(), phase]
	if image.save_png(capture_output.path_join(filename)) != OK:
		capture_errors += 1
		push_error("Could not save animation viewport frame " + filename)
	else:
		var actors: Array[Dictionary] = []
		for source in sources:
			actors.append({"animation": String(source.animated_sprite.animation), "frame": source.animated_sprite.frame, "position": [source.global_position.x, source.global_position.y]})
		captured.append({"file": filename, "phase": phase, "actors": actors})
	await process_frame
	paused = false

func segmento(phase: String, direction: Vector2, count: int) -> void:
	var start_position: Vector2 = sources[0].global_position
	var start_physics: int = Engine.get_physics_frames()
	for source in sources: source.direccion_control_jugador = direction
	for i in count:
		# Count actual simulation ticks. A wall-clock timer may expire in the
		# first frame after slow PNG readback, before any body has moved.
		for tick in (7 if i % 2 == 0 else 8): await physics_frame
		await guardar_frame(phase)
	print("CAPTURE ", phase, " displacement=", sources[0].global_position - start_position, " physics_frames=", Engine.get_physics_frames() - start_physics, " direction=", sources[0].direccion_control_jugador, " actual_velocity=", sources[0].get_real_velocity(), " controlled=", sources[0].controlado_por_jugador, " speed=", sources[0].speed)

func registrado(phase: String, prefix: String, actor_index: int) -> bool:
	for record in captured:
		if record.phase == phase and String(record.actors[actor_index].animation).begins_with(prefix): return true
	return false

func run() -> void:
	capture_output = ProjectSettings.globalize_path("res://../work/rastreador-animaciones-nov06/capturas/frames").simplify_path()
	DirAccess.make_dir_recursive_absolute(capture_output)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	await preparar()
	# Keep the staged walk in its corridor; ordinary portal transfers are tested
	# separately and would move the showcase bodies outside this close-up.
	for area in host.find_children("*", "Area2D", true, false):
		if area.has_signal("transferred"):
			area.set_physics_process(false)
			area.set_deferred("monitoring", false)
	var profile: Node = root.get_node("PatogenOnboarding")
	var old_motion: bool = bool(profile.profile.data.reduced_motion)
	profile.profile.data.reduced_motion = false
	var first := actor(ORIGIN, 1)
	await nav_lista(first)
	var navigation: Node2D = first.rastreador.navegacion
	var points: PackedVector2Array = navigation.posiciones_transitables(ORIGIN, 19.0)
	var point := Vector2.INF
	for candidate in points:
		if navigation.segmento_libre(candidate - Vector2(70, 0), candidate + Vector2(250, 0)):
			point = candidate
			break
	check(point.is_finite(), "capture has a real clear walking corridor")
	if not point.is_finite():
		capture_errors += 1
		await terminar()
		quit(1)
		return
	first.global_position = point
	var second := actor(point + Vector2(120, 0), 2)
	sources.assign([first, second])
	for capullo in host.get_node("Simbiontes").get_children(): capullo.visible = false
	for i in 2:
		var source: Node2D = sources[i]
		source.activar_control_jugador(i + 1)
		source.indicador_area_infeccion.visible = false
		source.indicador_aura_posesion.visible = false
		source.direccion_control_jugador = Vector2.ZERO
		source.set_physics_process(true)
	var camera: Camera2D = host.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.global_position = point + Vector2(60, 10)
	camera.zoom = Vector2(3.0, 3.0)
	camera.force_update_scroll()
	for i in 5: await process_frame
	var canvas_a: Vector2 = first.animated_sprite.get_global_transform_with_canvas().origin
	var canvas_b: Vector2 = second.animated_sprite.get_global_transform_with_canvas().origin
	var left := maxi(0, floori(minf(canvas_a.x, canvas_b.x) - 90.0))
	var top := maxi(0, floori(minf(canvas_a.y, canvas_b.y) - 95.0))
	var right := mini(1920, ceili(maxf(canvas_a.x, canvas_b.x) + 75.0 * 3.0 + 90.0))
	var bottom := mini(1080, ceili(maxf(canvas_a.y, canvas_b.y) + 110.0))
	capture_rect = Rect2i(left, top, right - left, bottom - top)
	await segmento("idle", Vector2.ZERO, 16)
	var before_a := first.global_position
	var before_b := second.global_position
	await segmento("caminar_derecha", Vector2.RIGHT, 8)
	check(first.global_position.distance_to(before_a) > 35.0 and second.global_position.distance_to(before_b) > 35.0, "both actual character bodies move while the walk animation plays")
	check(registrado("caminar_derecha", "caminar_derecha", 0) and registrado("caminar_derecha", "caminar_derecha", 1), "both team sprites show walking in the recorded viewport")
	await segmento("caminar_izquierda", Vector2.LEFT, 8)
	for source in sources:
		source.direccion_control_jugador = Vector2.ZERO
		source.actualizar_animacion(Vector2.DOWN)
	actor(first.global_position - Vector2(65, 0), 0)
	actor(second.global_position + Vector2(65, 0), 0)
	for source in sources: source.rastreador.revision_restante = 0.0
	await segmento("detectar", Vector2.ZERO, 8)
	check(registrado("detectar", "detectar_", 0) and registrado("detectar", "detectar_", 1), "both team sensors trigger the recorded detection gesture")
	check(captured.size() == 40, "forty real viewport frames recorded")
	var metadata: Dictionary = {"rect": [capture_rect.position.x, capture_rect.position.y, capture_rect.size.x, capture_rect.size.y], "duration_ms": 125, "frames": captured, "renderer": "project Mobile/Vulkan", "notes": "Staged camera and possessed hosts; unrelated portal transfers and possession auras disabled. Recording pauses during PNG encoding. Each PNG is an unmodified viewport export."}
	var file := FileAccess.open(capture_output.path_join("captura_animacion.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "  "))
	file.close()
	for source in sources: source.set_physics_process(false)
	profile.profile.data.reduced_motion = old_motion
	print("RASTREADOR ANIMATION CAPTURE RESULT ", captured.size(), " frames; ", capture_errors, " errors; ", failures, " failed checks")
	await terminar()
	quit(0 if capture_errors == 0 and failures == 0 else 1)

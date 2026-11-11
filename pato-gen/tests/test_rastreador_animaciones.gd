extends "res://tests/test_rastreador.gd"
## Real AnimatedSprite2D playback: repeated Bot updates must not reset the clock.
const ARTE = preload("res://scripts/rastreador_arte.gd")
const DIRECCIONES := {"abajo": Vector2.DOWN, "arriba": Vector2.UP, "derecha": Vector2.RIGHT, "izquierda": Vector2.LEFT}
var motion_before := false

func run() -> void:
	await preparar()
	var profile: Node = root.get_node("PatogenOnboarding")
	motion_before = bool(profile.profile.data.reduced_motion)
	profile.profile.data.reduced_motion = false
	comprobar_hoja()
	for team in [1, 2]:
		var source := actor(ORIGIN, team)
		await comprobar_reproduccion(source, team)
		await comprobar_deteccion(source, team)
		await limpiar()
	var source := actor(ORIGIN, 1)
	await comprobar_pausa(source)
	await comprobar_movimiento_reducido(source)
	await comprobar_pared(source)
	host._on_timer_juego_timeout()
	var sprite: AnimatedSprite2D = source.animated_sprite
	var phase := float(sprite.frame) + sprite.frame_progress
	await create_timer(0.25).timeout
	check(is_equal_approx(phase, float(sprite.frame) + sprite.frame_progress), "FIN freezes the animation clock with the paused result screen")
	paused = false
	profile.profile.data.reduced_motion = motion_before
	print("RASTREADOR ANIMATION RESULT ", passed, " passed; ", failures, " failed")
	await terminar()
	quit(0 if failures == 0 else 1)

func comprobar_hoja() -> void:
	var frames: SpriteFrames = ARTE.frames()
	check(ResourceLoader.exists("res://assets/rastreador/rastreador_animaciones.png"), "animated atlas is an explicit project resource")
	var approved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rastreador/poses_fuente.json"))
	var palette: Dictionary = {}
	for value in approved.palette.values(): palette[Color(value).to_rgba32()] = true
	for facing in DIRECCIONES:
		for kind in ["idle", "caminar", "detectar"]:
			var name: String = kind + "_" + facing
			check(frames.has_animation(name) and frames.get_frame_count(name) == 4, name + " has four authored frames")
			if not frames.has_animation(name): continue
			check(frames.get_animation_loop(name) == (kind != "detectar"), name + " has the intended loop policy")
			check(is_equal_approx(frames.get_animation_speed(name), 4.0 if kind == "idle" else (8.0 if kind == "caminar" else 10.0)), name + " keeps the agreed cadence")
			var unique: Dictionary = {}
			var pixel_safe := true
			for index in frames.get_frame_count(name):
				var texture: Texture2D = frames.get_frame_texture(name, index)
				var image := texture.get_image()
				image.convert(Image.FORMAT_RGBA8)
				pixel_safe = pixel_safe and image.get_size() == Vector2i(32, 32)
				unique[hash(image.get_data())] = true
				for y in image.get_height():
					for x in image.get_width():
						var color := image.get_pixel(x, y)
						if is_zero_approx(color.a): continue
						pixel_safe = pixel_safe and is_equal_approx(color.a, 1.0) and palette.has(color.to_rgba32())
			check(unique.size() == 4, name + " contains four distinct drawings")
			check(pixel_safe, name + " keeps native resolution, binary alpha and approved palette")
	for facing in ["Abajo", "Arriba", "Derecha", "Izquierda", "Detectar"]:
		check(frames.has_animation(facing), "approved static alias remains available: " + facing)
	for file in ["rastreador_abajo.png", "rastreador_arriba.png", "rastreador_derecha.png", "rastreador_izquierda.png", "rastreador_detectar.png", "poses_fuente.json"]:
		check(FileAccess.get_sha256("res://assets/rastreador/" + file) == FileAccess.get_sha256("res://../work/rastreador-concepto-v02/" + file), "approved source remains untouched: " + file)
	check(FileAccess.get_sha256("res://assets/rastreador/rastreador.aseprite") == FileAccess.get_sha256("res://../work/rastreador-concepto-v02/rastreador_base.aseprite"), "original layered Aseprite remains intact beside the new animated source")

func observar(source: Node2D, direction: Vector2, detect: bool, seconds: float) -> Dictionary:
	var seen: Dictionary = {}
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		source.rastreador.pose_restante = 1.0 if detect else 0.0
		source.actualizar_animacion(direction)
		var animation := String(source.animated_sprite.animation)
		if not seen.has(animation): seen[animation] = {}
		seen[animation][source.animated_sprite.frame] = true
		await process_frame
	return seen

func comprobar_reproduccion(source: Node2D, team: int) -> void:
	var sprite: AnimatedSprite2D = source.animated_sprite
	var scale_before := sprite.scale
	var team_color: Color = source.material_borde_infeccion.get_shader_parameter("color_borde")
	for facing in DIRECCIONES:
		var walk: String = "caminar_" + facing
		var idle: String = "idle_" + facing
		var seen := await observar(source, DIRECCIONES[facing], false, 0.62)
		check(seen.has(walk) and seen[walk].size() >= 3 and sprite.is_playing(), "repeated movement updates advance the real walk clock " + facing + " P%d" % team)
		seen = await observar(source, Vector2.ZERO, false, 0.62)
		check(String(sprite.animation) == idle and seen.has(idle) and seen[idle].size() >= 2, "stopping keeps orientation and visibly breathes " + facing + " P%d" % team)
		check(sprite.sprite_frames.get_frame_texture(idle, 0).get_size() == Vector2(36, 36) and sprite.scale == scale_before, "padding and body scale stay stable across playback " + facing + " P%d" % team)
	check(source.material_borde_infeccion.get_shader_parameter("borde_activo") and source.material_borde_infeccion.get_shader_parameter("color_borde") == team_color, "animation keeps the individual team outline P%d" % team)

func comprobar_deteccion(source: Node2D, team: int) -> void:
	var finishes := [0]
	var on_finished := func() -> void:
		if String(source.animated_sprite.animation).begins_with("detectar_"): finishes[0] += 1
	source.animated_sprite.animation_finished.connect(on_finished)
	for facing in DIRECCIONES:
		await observar(source, DIRECCIONES[facing], false, 0.05)
		var before: int = finishes[0]
		var seen := await observar(source, DIRECCIONES[facing], true, 0.9)
		var detect: String = "detectar_" + facing
		check(seen.has(detect) and seen[detect].size() >= 3, "directional detection actually advances " + facing + " P%d" % team)
		check(finishes[0] == before + 1 and String(source.animated_sprite.animation) == "caminar_" + facing, "held detection flag plays one gesture then resumes movement " + facing + " P%d" % team)
	var before: int = finishes[0]
	await observar(source, Vector2.ZERO, true, 0.4)
	check(finishes[0] == before, "a continuing detection event does not restart after completion P%d" % team)
	await observar(source, Vector2.ZERO, false, 0.05)
	await observar(source, Vector2.ZERO, true, 0.65)
	check(finishes[0] == before + 1 and String(source.animated_sprite.animation) == "idle_izquierda", "a new detection edge can play again and return to the oriented idle P%d" % team)
	source.animated_sprite.animation_finished.disconnect(on_finished)

func comprobar_pausa(source: Node2D) -> void:
	await observar(source, Vector2.RIGHT, false, 0.2)
	var sprite: AnimatedSprite2D = source.animated_sprite
	paused = true
	var phase := float(sprite.frame) + sprite.frame_progress
	await create_timer(0.3).timeout
	check(is_equal_approx(phase, float(sprite.frame) + sprite.frame_progress), "global pause freezes the actual sprite playback")
	paused = false
	await observar(source, Vector2.RIGHT, false, 0.25)
	check(not is_equal_approx(phase, float(sprite.frame) + sprite.frame_progress), "unpausing resumes the real animation clock")

func comprobar_movimiento_reducido(source: Node2D) -> void:
	var profile: Node = root.get_node("PatogenOnboarding")
	profile.profile.data.reduced_motion = true
	await observar(source, Vector2.UP, false, 0.1)
	var seen := await observar(source, Vector2.ZERO, false, 0.5)
	check(String(source.animated_sprite.animation) == "idle_arriba" and not source.animated_sprite.is_playing() and source.animated_sprite.frame == 0, "reduced motion suppresses ambient idle movement")
	seen = await observar(source, Vector2.RIGHT, true, 0.6)
	check(not seen.has("detectar_derecha") and seen.has("caminar_derecha") and seen.caminar_derecha.size() >= 3, "reduced motion skips detection gesture but preserves readable walking")
	profile.profile.data.reduced_motion = false

func comprobar_pared(source: Node2D) -> void:
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(14, 120)
	collision.shape = rectangle
	wall.add_child(collision)
	wall.position = source.global_position + Vector2(20, 0)
	host.add_child(wall)
	await physics_frame
	await physics_frame
	source.rastreador.pose_restante = 0.0
	source.activar_control_jugador(1)
	source.direccion_control_jugador = Vector2.RIGHT
	for i in 20:
		source._physics_process(1.0 / 60.0)
		await physics_frame
	check(source.get_real_velocity().length_squared() < 0.01 and String(source.animated_sprite.animation).begins_with("idle_"), "a possessed host pressed against a wall stops walking its feet")
	source.desactivar_control_jugador()
	wall.queue_free()
	await physics_frame

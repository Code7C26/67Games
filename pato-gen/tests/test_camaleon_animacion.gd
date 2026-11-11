extends "res://tests/test_camaleon.gd"
## Walk playback, paired camouflage silhouettes and production movement/stop behavior.
const CAM_ART = preload("res://scripts/camaleon_arte.gd")
const DIRECTIONS := {"Abajo": Vector2.DOWN, "Arriba": Vector2.UP, "Derecha": Vector2.RIGHT, "Izquierda": Vector2.LEFT}

func run() -> void:
	seed(937)
	await preparar()
	verificar_assets()
	verificar_parejas()
	for team in [1, 2]:
		await limpiar()
		await reproduccion(team)
	await limpiar()
	await movimiento_real()
	print("CAMALEON ANIMATION RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	CAM_ART.limpiar_cache()
	READABILITY.textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func matching_alpha(first: Image, second: Image) -> bool:
	if first.get_size() != second.get_size(): return false
	for y in first.get_height():
		for x in first.get_width():
			if first.get_pixel(x, y).a != second.get_pixel(x, y).a: return false
	return true

func matching_visible_pixels(first: Image, second: Image) -> bool:
	if first.get_size() != second.get_size(): return false
	for y in first.get_height():
		for x in first.get_width():
			var one := first.get_pixel(x, y)
			var two := second.get_pixel(x, y)
			# Transparent RGB does not contribute to the approved pose.
			if one.a != two.a or (one.a > 0.0 and one != two):
				print("IDLE PIXEL DIFFERENCE ", x, ",", y, " ", one, " / ", two)
				return false
	return true

func verificar_parejas() -> void:
	var frames: SpriteFrames = READABILITY.padded(CAM_ART.frames())
	for direction: String in DIRECTIONS:
		var unique: Dictionary = {}
		for index in frames.get_frame_count(direction):
			var normal: Image = frames.get_frame_texture(direction, index).get_image()
			var camouflaged: Image = CAM_ART.piel_camuflada(direction, index).get_image()
			check(matching_alpha(normal, camouflaged), "normal/camouflaged silhouettes align at every pixel: %s frame %d" % [direction, index])
			unique[normal.get_data().hex_encode()] = true
		check(unique.size() == 4, "four visibly different walk poses in " + direction)
		var idle: String = "idle_" + direction.to_lower()
		var idle_normal: Image = frames.get_frame_texture(idle, 0).get_image()
		var idle_camouflaged: Image = CAM_ART.piel_camuflada(direction).get_image()
		check(matching_alpha(idle_normal, idle_camouflaged), "idle silhouettes align in " + direction)
		var approved: Image = CAM_ART.TEXTURAS[direction].get_image()
		approved.convert(Image.FORMAT_RGBA8)
		check(matching_visible_pixels(idle_normal.get_region(Rect2i(2, 2, 32, 32)), approved), "idle restores the approved original pose in " + direction)

func reproduccion(team: int) -> void:
	var source := actor(ORIGIN, team)
	var sprite: AnimatedSprite2D = source.animated_sprite
	var ability: Node2D = source.camaleon
	var team_color: Color = source.material_borde_infeccion.get_shader_parameter("color_borde")
	for direction: String in DIRECTIONS:
		source.actualizar_animacion(DIRECTIONS[direction])
		check(sprite.animation == direction and sprite.is_playing(), "movement starts directional walking %s P%d" % [direction, team])
		check(source.material_borde_infeccion.get_shader_parameter("piel_camuflada") == CAM_ART.piel_camuflada(direction, sprite.frame), "turning updates camouflage to the new direction immediately %s P%d" % [direction, team])
		var observed: Dictionary = {}
		for _sample in 7:
			await create_timer(0.09).timeout
			observed[sprite.frame] = true
			var skin: Texture2D = source.material_borde_infeccion.get_shader_parameter("piel_camuflada")
			check(skin == CAM_ART.piel_camuflada(direction, sprite.frame), "automatic playback keeps shader on the current walk pose %s P%d" % [direction, team])
		check(observed.size() >= 3, "walking advances through distinct frames over time %s P%d" % [direction, team])
		for index in 4:
			sprite.frame = index
			var skin: Texture2D = source.material_borde_infeccion.get_shader_parameter("piel_camuflada")
			check(skin == CAM_ART.piel_camuflada(direction, index), "frame changes synchronize camouflage immediately %s/%d P%d" % [direction, index, team])
		source.actualizar_animacion(Vector2.ZERO)
		check(sprite.animation == "idle_" + direction.to_lower() and not sprite.is_playing(), "stopping preserves facing and restores idle %s P%d" % [direction, team])
		check(source.material_borde_infeccion.get_shader_parameter("piel_camuflada") == CAM_ART.piel_camuflada(direction), "stopping restores the paired camouflage idle %s P%d" % [direction, team])
	check(source.material_borde_infeccion.get_shader_parameter("color_borde") == team_color and source.material_borde_infeccion.get_shader_parameter("borde_activo"), "walking preserves each team's outline P%d" % team)
	source.activar_control_jugador(team)
	ability.revelar("animation test")
	ability.actualizar(0.3)
	source.actualizar_animacion(Vector2.RIGHT)
	check(sprite.is_playing() and not ability.camuflado, "possessed revealed host keeps walking P%d" % team)
	ability.recarga_restante = 0.0
	check(ability.activar_manual(), "possessed host can conceal during walking P%d" % team)
	ability.actualizar(0.3)
	check(sprite.is_playing() and ability.camuflado, "concealing does not stop walking P%d" % team)
	paused = true
	var frozen_frame := sprite.frame
	var frozen_progress := sprite.frame_progress
	await create_timer(0.25, true).timeout
	check(sprite.frame == frozen_frame and is_equal_approx(sprite.frame_progress, frozen_progress), "pause freezes the walk frame and its progress P%d" % team)
	paused = false
	source.curar(false)
	await process_frame
	check(not source.is_infected and source.animated_sprite.sprite_frames == source.sprite_frames_sano, "cure restores the healthy animation set P%d" % team)

func movimiento_real() -> void:
	var source := actor(ORIGIN, 1)
	source.activar_control_jugador(1)
	source.direccion_control_jugador = Vector2.RIGHT
	var wall := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 120)
	collision.shape = shape
	wall.add_child(collision)
	host.add_child(wall)
	wall.global_position = ORIGIN + Vector2(60, 0)
	await physics_frame
	source.set_physics_process(true)
	await create_timer(0.15).timeout
	check(source.global_position.x > ORIGIN.x + 2 and source.animated_sprite.is_playing(), "production physics starts walking while the body really moves")
	await create_timer(1.0).timeout
	check(source.get_real_velocity().length_squared() < 0.1 and source.animated_sprite.animation == "idle_derecha" and not source.animated_sprite.is_playing(), "a wall stops the gait when input remains held but the body cannot move")
	source.direccion_control_jugador = Vector2.ZERO
	source.set_physics_process(false)
	wall.queue_free()

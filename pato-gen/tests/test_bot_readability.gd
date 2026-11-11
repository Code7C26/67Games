extends "res://tests/test_simbionte.gd"

const READABILITY = preload("res://scripts/npc_readability.gd")
const TEAMS = preload("res://scripts/equipos_infeccion.gd")

func run() -> void:
	await fresh()
	var source := bot_at(Vector2(976, 592), 0)
	var body_radius: float = source.get_node("CollisionShape2D").shape.radius
	var infection_radius: float = source.get_node("AreaInfeccion/CollisionShape2D").shape.radius
	var heights: Array[float] = []
	var healthy_scale: Vector2 = source.animated_sprite.scale
	for strain in ["atletico", "area", "exponencial"]:
		host.cepa_cian = strain
		source.activar_infeccion(Color.CYAN, 1, false)
		freeze_bot(source)
		var metrics: Vector2 = READABILITY.body_metrics(source.animated_sprite.sprite_frames)
		heights.append(metrics.x * source.animated_sprite.scale.y)
		check(is_equal_approx(source.animated_sprite.scale.x, source.animated_sprite.scale.y), strain + " grows uniformly without stretching")
		check(is_equal_approx(source.animated_sprite.position.y + metrics.y * source.animated_sprite.scale.y, 15.0), strain + " feet stay on the same ground line")
		check(source.color_infeccion == TEAMS.COLOR_AZUL, strain + " legacy cyan input resolves to the blue team palette")
		check(source.feedback_restante > 0.0 and not source.feedback_curacion, strain + " infection has a brief visible state signal")
		source.curar(false)
		check(source.feedback_restante > 0.0 and source.feedback_curacion and source.feedback_color == Color("b6ef75"), strain + " healing shows a green cross signal")
		check(source.animated_sprite.scale == healthy_scale, strain + " healing restores healthy artwork scale")
	check(absf(heights[0] - heights[1]) < 0.1 and absf(heights[1] - heights[2]) < 0.1, "all three infected strains have equal average painted height")
	check(source.get_node("CollisionShape2D").shape.radius == body_radius and source.get_node("AreaInfeccion/CollisionShape2D").shape.radius == infection_radius, "visual enlargement preserves collision and infection radii")

	host.cepa_cian = "atletico"
	source.activar_infeccion(TEAMS.COLOR_AZUL, 1, false)
	freeze_bot(source)
	source.speed = 0.0
	source.probabilidad_contagio = 100.0
	var targets: Array[Node2D] = []
	for i in 8:
		var point := source.global_position + Vector2(20, 0).rotated(TAU * float(i) / 8.0)
		targets.append(bot_at(point, 0))
	await physics_frame
	await physics_frame
	source._intentar_contagio_area()
	check(count_infected(targets) == 0, "a fresh infection cannot immediately start another contagious wave")
	source._physics_process(source.INCUBACION_CONTAGIO)
	seed(718)
	source._intentar_contagio_area()
	check(count_infected(targets) == 1, "ordinary contact converts at most one nearby human per pulse")
	for target in targets:
		if target.is_infected:
			target._intentar_contagio_area()
	check(count_infected(targets) == 1, "newly infected neighbours cannot cascade during the same pulse")
	for target in targets:
		if target.is_infected: target.curar(false)
	source.curar(false)
	host.cepa_cian = "area"
	source.activar_infeccion(TEAMS.COLOR_AZUL, 1, false)
	freeze_bot(source)
	source.speed = 0.0
	source.probabilidad_contagio = 100.0
	source._physics_process(source.INCUBACION_CONTAGIO)
	seed(718)
	source._intentar_contagio_area()
	check(count_infected(targets) == 2, "area strain keeps a two-target group advantage with a bounded pulse")
	var random := RandomNumberGenerator.new()
	random.seed = 4
	check(source.curar_por_coloso(1.0, 6.0, random), "coloso healing still uses the shared healing contract")
	source.infectar(TEAMS.COLOR_MAGENTA, 2)
	check(not source.is_infected and source.proteccion_coloso == 6.0 and source.feedback_curacion, "coloso protection preserves the visible recovery instead of immediate reinfection")
	print("BOT READABILITY RESULT ", passed, " passed; ", failures, " failed")
	host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)

func count_infected(targets: Array[Node2D]) -> int:
	var count := 0
	for target in targets:
		if target.is_infected: count += 1
	return count

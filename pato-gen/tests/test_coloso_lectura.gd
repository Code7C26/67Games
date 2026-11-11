extends "res://tests/test_coloso_antiviral.gd"
## Alcance, protección y animación del Coloso sobre la partida real.

func run() -> void:
	await fresh_coloso()
	await preparar_aparicion()
	var actor: Node2D = evento.coloso
	var objetivo: Node2D = get_nodes_in_group("bots")[0]
	var destino := Vector2.ZERO
	for direccion in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var punto: Vector2 = centro + direccion * 160.0
		if RADIAL.linea_libre(actor, punto):
			destino = punto
			break
	check(destino != Vector2.ZERO, "real arena has a visible recipient beyond the previous 140-unit range")
	objetivo.global_position = destino
	for bot in get_nodes_in_group("bots"):
		if bot != objetivo:
			actor.tratados[bot.get_instance_id()] = true
	evento.velocidad = 0.0
	evento.chance_curacion = 1.0
	evento.avanzar(1.0, host.contar_infecciones())
	check(not objetivo.is_infected and actor.curaciones == 1, "pulse reaches a real infection 160 units away")
	check(actor.objetivo_visual == objetivo and actor.pulso_visual > 0.0, "healing feedback identifies the actual cured recipient")
	check(objetivo.proteccion_coloso == 6.0, "healed recipient receives six gameplay seconds of protection")
	objetivo._physics_process(5.0)
	objetivo.activar_infeccion(Color.MAGENTA, 2, false)
	check(not objetivo.is_infected, "cure cannot disappear into reinfection after five seconds")
	objetivo._physics_process(1.0)
	objetivo.activar_infeccion(Color.MAGENTA, 2, false)
	check(objetivo.is_infected, "recipient can be infected normally after protection expires")
	check(actor.get_node("CollisionShape2D").shape.radius == 20.0, "larger articulated artwork preserves the navigable body footprint")
	actor.velocity = Vector2(80, 0)
	actor._animar(0.1)
	var cuerpo: Sprite2D = actor.get_node("Aspecto/Cuerpo")
	var pie_izquierdo: Sprite2D = actor.get_node("Aspecto/PieIzquierdo")
	var pie_derecho: Sprite2D = actor.get_node("Aspecto/PieDerecho")
	check(not is_equal_approx(pie_izquierdo.position.y, pie_derecho.position.y), "walking lifts the feet on alternate steps")
	check(actor.get_node("Aspecto").scale.x == 1.75 and not is_zero_approx(cuerpo.rotation), "coloso has a larger animated silhouette")
	var reloj: float = actor.tiempo_visual
	var pulso: float = actor.pulso_visual
	host.timer_juego.paused = true
	evento.avanzar(1.0, host.contar_infecciones())
	check(actor.tiempo_visual == reloj and actor.pulso_visual == pulso, "tutorial pause freezes animation and cure feedback together")
	host.timer_juego.paused = false
	var profile = root.get_node("PatogenOnboarding").profile
	var motion_before: bool = profile.data.get("reduced_motion", false)
	profile.data["reduced_motion"] = true
	actor._animar(0.1)
	check(cuerpo.scale.y == 1.0, "reduced motion removes breathing deformation")
	profile.data["reduced_motion"] = motion_before
	host.queue_free()
	await process_frame
	print("COLOSO READABILITY RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

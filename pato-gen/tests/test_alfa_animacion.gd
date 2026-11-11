extends "res://tests/test_parasito_alfa.gd"

func run() -> void:
	await preparar()
	await aparecer()
	var actor: Node2D = alfa_evento.alfa
	var aspecto: Sprite2D = actor.get_node("Aspecto")
	var origen := actor.global_transform
	check(aspecto.hframes == 8 and aspecto.texture.get_width() == 512 and aspecto.texture.get_height() == 64, "approved 64-pixel creature replaces nest with eight source frames")
	check(aspecto.frame == 3 and host.contar_infecciones().total == 3, "initial release opens torso and creates exactly three real bots")
	var imagen := aspecto.texture.get_image()
	var anclaje_fijo := true
	for frame in range(1, 8):
		for y in range(49, 64):
			for x in 64:
				var base := imagen.get_pixel(x, y)
				var pixel := imagen.get_pixel(frame * 64 + x, y)
				# El importador puede extender RGB debajo de píxeles transparentes.
				anclaje_fijo = anclaje_fijo and base.a == pixel.a and (base.a == 0.0 or base == pixel)
	check(anclaje_fijo, "all root and ground pixels stay fixed and contain no baked demonstration bot")
	alfa_evento.avanzar(0.7)
	check(aspecto.frame == 0 and actor.tiempo_animacion < 0.0, "release animation returns to resting pose without looping")
	alfa_evento.avanzar(8.94)
	check(aspecto.frame == 0 and alfa_evento.generados == 3, "resting creature does not emit extra entities between intervals")
	alfa_evento.avanzar(0.02)
	check(aspecto.frame == 1 and alfa_evento.generados == 3, "contraction starts 340 milliseconds before next actual birth")
	alfa_evento.avanzar(0.16)
	check(aspecto.frame == 2 and alfa_evento.generados == 3, "charged pose precedes generation rather than delaying the ten-second cadence")
	var tiempo: float = actor.tiempo_animacion
	host.timer_juego.paused = true
	alfa_evento.avanzar(2.0)
	check(aspecto.frame == 2 and actor.tiempo_animacion == tiempo, "tutorial clock hold freezes animation and spawn clock together")
	host.timer_juego.paused = false
	paused = true
	alfa_evento.avanzar(2.0)
	check(actor.tiempo_animacion == tiempo, "global pause freezes creature even when event update is called")
	paused = false
	alfa_evento.avanzar(0.179)
	check(aspecto.frame == 2 and alfa_evento.generados == 3, "no premature bot during anticipation")
	alfa_evento.avanzar(0.001)
	check(aspecto.frame == 3 and alfa_evento.generados == 4 and host.contar_infecciones().total == 4, "ten-second birth and open torso happen in same physics update with no duplicate")
	alfa_evento.avanzar(0.3)
	check(aspecto.frame > 3, "recovery uses the approved post-release poses")
	alfa_evento.avanzar(0.4)
	check(aspecto.frame == 0 and actor.global_transform == origen, "creature settles with its position, size and roots unchanged")
	# Late frames still make only one real guest, and finish resets pose.
	alfa_evento.avanzar(9.3)
	check(aspecto.frame == 3 and alfa_evento.generados == 5, "large delta opens release frame once rather than queuing visual or population bursts")
	host._on_timer_juego_timeout()
	check(alfa_evento.alfa == null and alfa_evento.estado == alfa_evento.Estado.FINALIZADO, "game over during release removes actor and its animation state immediately")
	host.game_over_screen._on_reiniciar_button_pressed()
	await process_frame
	await process_frame
	host = current_scene
	check(host.evento_alfa.generados == 0 and host.contar_infecciones().total == 65 and get_nodes_in_group("parasitos_alfa").is_empty(), "restart clears partial animation and restores normal starting population")
	host.queue_free()
	await process_frame
	print("ALFA ANIMATION RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

extends "res://tests/test_coloso_antiviral.gd"
## The final pulse can remove the actor between two HUD updates.

func run() -> void:
	await fresh_coloso()
	await preparar_aparicion()
	var hud = host.interfaz
	var actor = evento.coloso
	actor.curaciones = 11
	hud.sync(host.contar_infecciones())
	check(hud.event_caption.text.begins_with("11 curados"), "active HUD observes eleven treatments before the final physics tick")
	actor.curaciones = 12
	evento.avanzar(1.0 / 60.0, stats())
	check(evento.coloso == null and evento.curaciones_ultima_aparicion == 12, "budget retirement persists all twelve treatments before releasing the actor")
	hud.sync(host.contar_infecciones())
	check(hud.event_label.text == "COLOSO RETIRADO" and hud.event_caption.text == "12 humanos curados", "departure HUD includes the final treatment missed between frames")
	await physics_frame
	hud.sync(host.contar_infecciones())
	check(hud.event_caption.text == "12 humanos curados", "summary remains accurate after the retired actor has been freed")
	await preparar_aparicion()
	check(evento.curaciones_ultima_aparicion == 0 and evento.coloso.curaciones == 0, "new materialization resets the previous appearance summary")
	actor = evento.coloso
	actor.curaciones = 4
	hud.sync(host.contar_infecciones())
	evento.finalizar()
	hud.sync(host.contar_infecciones())
	check(evento.curaciones_ultima_aparicion == 4 and hud.event_caption.text == "4 humanos curados", "match finalization also persists the current appearance summary")
	evento.finalizar()
	check(evento.curaciones_ultima_aparicion == 4, "repeated finalization preserves the recorded treatment total")
	host.queue_free()
	await process_frame
	await process_frame
	print("COLOSO HUD SUMMARY RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

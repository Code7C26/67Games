extends "res://tests/test_rastreador.gd"
## Unfrozen production populations: both teams chase, infect and navigate.

func run() -> void:
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		seed(6717)
		root.get_node("PatogenOnboarding").requested_mode="direct"
		root.set_meta("patogen_cepas",{1:"rastreador",2:"rastreador"})
		host=load("res://scenes/"+map_name+".tscn").instantiate()
		root.add_child(host)
		current_scene=host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host._on_timer_inicio_timeout()
		await create_timer(1.6).timeout
		for duck in get_nodes_in_group("patos"): duck.set_physics_process(false)
		var bots:=host.get_node("Bots").get_children()
		for i in bots.size():
			if i<12 and not bots[i].is_infected: bots[i].activar_infeccion(Color.CYAN if i%2==0 else Color.MAGENTA,1 if i%2==0 else 2,false)
			bots[i].probabilidad_curacion=0.0
		var snapshots: Dictionary={}
		var impossible_updates:=0
		var pursuits:=0
		var outside:=0
		var bounds: Rect2=host.get_meta("bounds",Rect2(0,80,2128,960))
		for frame in 600:
			await physics_frame
			for bot in host.get_node("Bots").get_children():
				if not bounds.grow(16).has_point(bot.global_position): outside+=1
				if not is_instance_valid(bot.rastreador): continue
				var tracker: Node2D=bot.rastreador
				var prey: Node2D=tracker.objetivo_actual()
				if prey==null: continue
				pursuits+=1
				var id: int=bot.get_instance_id()
				var previous: Dictionary=snapshots.get(id,{})
				if not previous.is_empty() and not tracker.presa_visible and not previous.visible and previous.prey==prey.get_instance_id() and tracker.ultima_posicion_conocida!=previous.point: impossible_updates+=1
				snapshots[id]={"prey":prey.get_instance_id(),"point":tracker.ultima_posicion_conocida,"visible":tracker.presa_visible}
		var infected: Dictionary=host.contar_infecciones()
		check(host.estado_actual==host.EstadoJuego.FASE_INFECCION and host.timer_juego.time_left<149.0,map_name+" real match runs for ten autonomous seconds")
		check(pursuits>0,map_name+" live AI actually pursues healthy guests")
		check(impossible_updates==0,map_name+" hidden targets never update remembered coordinates")
		check(outside==0,map_name+" population remains inside physical map bounds")
		check(host.obtener_contagios_jugador(1)+host.obtener_contagios_jugador(2)>0,map_name+" ordinary contact timers produce live infections")
		print("RASTREADOR LIVE ",map_name," pursuits=",pursuits," hidden_updates=",impossible_updates," outside_samples=",outside," population=",infected)
		host._on_timer_juego_timeout()
		var clean:=true
		for bot in host.get_node("Bots").get_children():
			if is_instance_valid(bot.rastreador) and bot.rastreador.posicion_persecucion().is_finite(): clean=false
		check(paused and clean,map_name+" natural controller finish clears all traces")
		paused=false
		host.queue_free()
		await process_frame
		await process_frame
		host=null
	print("RASTREADOR LIVE RESULT ",passed," passed; ",failures," failed")
	await terminar()
	quit(0 if failures==0 else 1)

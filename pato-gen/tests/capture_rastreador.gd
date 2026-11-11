extends "res://tests/capture_camaleon.gd"
## Render the exact approved v02 artwork and both teams in each production map.

func run() -> void:
	output=ProjectSettings.globalize_path("res://../work/rastreador-integracion-nov06/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1920,1080)
	root.content_scale_size=Vector2i(1920,1080)
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode="direct"
		root.set_meta("patogen_cepas",{1:"rastreador",2:"rastreador"})
		host=load("res://scenes/"+map_name+".tscn").instantiate()
		root.add_child(host)
		current_scene=host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host.set_process(false)
		host.set_physics_process(false)
		host.evento_coloso.set_physics_process(false)
		host.evento_alfa.set_physics_process(false)
		# Staged close-up: suppress unrelated capullo billboards in this capture.
		for capullo in host.get_node("Simbiontes").get_children(): capullo.visible=false
		for duck in get_nodes_in_group("patos"):
			duck.convertirse_en_fantasma()
			duck.set_physics_process(false)
		var bots:=host.get_node("Bots").get_children()
		for i in bots.size():
			var bot: Node2D=bots[i]
			bot.set_physics_process(false)
			bot.get_node("TimerCambioRumbo").stop()
			bot.timer_contagio.stop()
			bot.timer_curacion.stop()
			if i>=4: bot.proteccion_sano_ofensiva=999.0
		var navigation: Node2D=host.navegacion_simbionte
		while not navigation.lista: await physics_frame
		host.estado_actual=host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(100.0)
		bots[0].activar_infeccion(Color.CYAN,1,false)
		bots[0].timer_contagio.stop()
		bots[0].timer_curacion.stop()
		while not bots[0].rastreador.navegacion.lista: await physics_frame
		var body_navigation: Node2D=bots[0].rastreador.navegacion
		for capullo in host.get_node("Simbiontes").get_children(): capullo.visible=false
		var separation:=96.0 if map_name=="Shopping" else 130.0
		var prey_offsets: Array=[Vector2(-65,0),Vector2(separation+65,0)] if map_name=="Shopping" else [Vector2(0,75),Vector2(separation,75)]
		var points: Array[Vector2]=[]
		points.assign(navigation.posiciones_capullos)
		if not points.is_empty(): points.append_array(body_navigation.posiciones_transitables(points[0],19.0))
		var center: Vector2=host.get_meta("view_bounds",Rect2(0,80,2128,960)).get_center()
		points.sort_custom(func(a:Vector2,b:Vector2)->bool: return a.distance_squared_to(center)<b.distance_squared_to(center))
		var point:=Vector2.INF
		for candidate in points:
			var site:=candidate+Vector2(0,56)
			var clear:=true
			for offset in [Vector2(separation,0),prey_offsets[0],prey_offsets[1]]:
				if not body_navigation.segmento_libre(site,site+offset): clear=false; break
			if not clear: continue
			for i in range(4,bots.size()):
				if bots[i].global_position.distance_squared_to(site)<50.0*50.0 or bots[i].global_position.distance_squared_to(site+Vector2(separation,0))<50.0*50.0: clear=false; break
			if clear: point=site; break
		if not point.is_finite():
			push_error("No clear Rastreador capture area "+map_name)
			errors+=1
			host.queue_free()
			await process_frame
			continue
		host.estado_actual=host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(100.0)
		for i in 2:
			bots[i].global_position=point+Vector2(i*separation,0)
			bots[i+2].global_position=point+prey_offsets[i]
			bots[i].activar_infeccion(Color.CYAN if i==0 else Color.MAGENTA,i+1,false)
			bots[i].incubacion_contagio=0.0
			bots[i].feedback_restante=0.0
			bots[i].timer_contagio.stop()
			bots[i].timer_curacion.stop()
		while not bots[0].rastreador.navegacion.lista: await physics_frame
		for i in 2:
			bots[i].rastreador.revision_restante=0.0
			bots[i].rastreador.actualizar(0.01)
			bots[i].actualizar_animacion(Vector2.DOWN)
			if bots[i].rastreador.objetivo_actual()!=bots[i+2]:
				errors+=1
				push_error("Capture failed to fix real nearby prey "+map_name+" P"+str(i+1))
		var camera: Camera2D=host.get_node("Camera2D")
		camera.position_smoothing_enabled=false
		camera.global_position=point+Vector2(separation*0.5,30)
		camera.zoom=Vector2(2.7,2.7)
		camera.force_update_scroll()
		await shot(map_name+"_01_fijar_ambos_equipos")
		for i in 2: bots[i+2].global_position+=Vector2(0,700)
		for i in 2:
			bots[i].rastreador.observacion_restante=0.0
			bots[i].rastreador.actualizar(0.7)
			bots[i].rastreador.pose_restante=0.0
			bots[i].actualizar_animacion(Vector2.DOWN)
		await shot(map_name+"_02_ultimo_rastro")
		var ducks:=host.get_node("Patos").get_children()
		for i in 2:
			ducks[i].bot_poseido=bots[i]
			ducks[i].tiempo_posesion=10.0
			bots[i].activar_control_jugador(i+1)
		host.interfaz.sync(host.contar_infecciones())
		if not "RASTREO PASIVO" in host.interfaz.footer.text:
			errors+=1
			push_error("Passive possession hint missing "+map_name)
		await shot(map_name+"_03_posesion_pasiva")
		host.queue_free()
		await process_frame
		await process_frame
	load("res://scripts/rastreador_arte.gd").limpiar_cache()
	load("res://scripts/npc_readability.gd").textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	print("RASTREADOR CAPTURE RESULT ",errors," errors")
	quit(0 if errors==0 else 1)

extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
	else: print("PASS ",message)
func run() -> void:
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		root.set_meta("patogen_cepas",{1:"exponencial",2:"area"})
		var host = load("res://scenes/"+map_name+".tscn").instantiate()
		root.add_child(host)
		current_scene=host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		for i in 50: await physics_frame
		var bots := get_nodes_in_group("bots")
		check(bots.size()==65,map_name+" production population")
		check(get_nodes_in_group("patos").size()==2,map_name+" two real players")
		check(host.interfaz.world_rect==host.get_meta("view_bounds",host.interfaz.MAP_RECT),map_name+" HUD respects map bounds")
		check(host.capullos_colocados,map_name+" reachable symbiote anchors")
		check(host.evento_coloso.poblacion_inicial==65 and not host.evento_coloso.posiciones.is_empty(),map_name+" Coloso uses real population and geometry")
		var bot=bots[0]
		var mate=bots[1]
		check(bot.material_borde_infeccion!=mate.material_borde_infeccion,map_name+" independent outlines")
		check(is_equal_approx(bot.get_node("ContactShadow").color.a,0.38),map_name+" contact shadow")
		var img: Image=bot.animated_sprite.sprite_frames.get_frame_texture("Abajo",0).get_image()
		var padded:=true
		for x in img.get_width():
			padded=padded and img.get_pixel(x,0).a==0 and img.get_pixel(x,img.get_height()-1).a==0
		for y in img.get_height():
			padded=padded and img.get_pixel(0,y).a==0 and img.get_pixel(img.get_width()-1,y).a==0
		check(padded,map_name+" transparent frame margins")
		if host.has_signal("map_ready"):
			var navigation: Node2D=host.npc_navigation
			var reachable:=true
			for marker in host.get_node("Environment/06_Marcadores").get_children():
				if marker.is_in_group("patogen_destination"):
					# A few art markers sit near props: validate their nearest clear cell.
					var cell: Vector2i=navigation._celda_accesible(marker.global_position)
					if cell.x>=0:
						reachable=reachable and not navigation.ruta(host.get_node("Patos/Pato").position,navigation.cuadricula.get_point_position(cell)).is_empty()
			check(reachable,map_name+" connected destinations")
			var initial: Array[Vector2]=[]
			for actor in bots: initial.append(actor.position)
			var previous := initial.duplicate()
			var distance := PackedFloat32Array()
			distance.resize(bots.size())
			for frame in 600:
				await physics_frame
				if frame % 10 == 0:
					for i in bots.size():
						distance[i] += bots[i].position.distance_to(previous[i])
						previous[i] = bots[i].position
			var moved:=0
			for i in bots.size():
				if distance[i]>48: moved+=1
				else: print("STUCK ",map_name," ",bots[i].name," pos ",bots[i].position," travel ",distance[i]," route ",bots[i].map_route," evasion ",bots[i].tiempo_evasion)
			check(moved==65,map_name+" autonomous navigation: "+str(moved)+"/65 moved")
			check(get_nodes_in_group("splash_visitors").is_empty(),map_name+" no demo population")
		for actor in bots:
			actor.set_physics_process(false)
			actor.get_node("TimerCambioRumbo").stop()
		bot.activar_infeccion(Color.CYAN,1,false)
		mate.activar_infeccion(Color.MAGENTA,2,false)
		check(bot.material_borde_infeccion.get_shader_parameter("borde_activo") and mate.material_borde_infeccion.get_shader_parameter("borde_activo"),map_name+" infection outline activates")
		check(bot.material_borde_infeccion.get_shader_parameter("color_borde")==Color.CYAN and mate.material_borde_infeccion.get_shader_parameter("color_borde")==Color.MAGENTA,map_name+" team colours stay separate")
		bot.curar_por_robot()
		check(not bot.is_infected and not bot.material_borde_infeccion.get_shader_parameter("borde_activo"),map_name+" cure restores healthy outline")
		host._on_timer_inicio_timeout()
		for frame in 100: await physics_frame
		check(host.estado_actual==host.EstadoJuego.FASE_INFECCION and not host.timer_juego.is_stopped(),map_name+" real infection phase")
		host.adn_cian=80
		check(host.invertir_simbionte(1),map_name+" symbiote investment")
		bot.curar_por_robot()
		bot.activar_infeccion(Color.CYAN,1,false)
		if host.has_signal("map_ready"):
			bot.position=host.npc_destinations[int(host.npc_destinations.size()/2)]
		check(host.crear_replicado(bot),map_name+" replication uses real Bot")
		var replica=host.get_node("Bots").get_child(-1)
		check(replica.has_node("ContactShadow") and replica.material_borde_infeccion!=bot.material_borde_infeccion,map_name+" replicated visual isolation")
		if host.has_signal("map_ready"):
			check(replica.skins==host.get_meta("npc_skins"),map_name+" replica inherits map skin")
		host._on_timer_juego_timeout()
		check(paused and host.game_over_screen.visible and host.estado_actual==host.EstadoJuego.FIN,map_name+" result and pause")
		paused=false
		host.queue_free()
		await process_frame
		await physics_frame
		check(get_nodes_in_group("bots").is_empty(),map_name+" no actors leak across maps")
	# Selection is shared by mouse and keyboard, and preserves strains.
	var selector=load("res://scenes/map_select.tscn").instantiate()
	root.add_child(selector)
	selector._select(2)
	check(root.get_meta("patogen_map")=="splash", "map selection persists")
	check(root.get_meta("patogen_cepas")[1]=="exponencial", "map selection preserves strains")
	selector.queue_free()
	await process_frame
	print("MAP_TESTS ", checks," checks, ",failures," failures")
	quit(1 if failures else 0)

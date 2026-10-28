extends "res://scripts/Mapa.gd"
## Environment packages use the production match controller, actors and HUD.
signal map_ready
@export_enum("lab", "splash") var map_id := "lab"
var map_is_ready := false
var npc_navigation: Node2D
var npc_destinations := PackedVector2Array()

func _enter_tree() -> void:
	add_to_group("mapa")
	set_meta("view_bounds",get_meta("bounds"))
	var healthy: Array[SpriteFrames] = []
	var roles := ["cientifico"] if map_id == "lab" else ["banador", "salvavidas", "staff"]
	for role in roles:
		for i in range(1,4): healthy.append(load("res://%s/assets/%s_%d.tres" % [map_id,role,i]))
	set_meta("npc_skins", healthy)
	var park_life := get_node_or_null("Environment/10_VidaParque")
	if park_life:
		park_life.enabled = false
		park_life.sunset_enabled = false
	if map_id == "splash": $Environment.enabled = false
	if map_id == "lab":
		get_node("Environment/01_Pisos").z_index = -20
		get_node("Environment/02_Senaletica_y_luces").z_index = -10
		get_node("Environment/02_Oclusion_Paredes").z_index = -5
		get_node("Environment/04_Objetos").z_index = 1
		get_node("Environment/05_Rotulos").z_index = 2
	$Bots.y_sort_enabled = true
	$Bots.z_index = 1
	$Patos.y_sort_enabled = true
	$Patos.z_index = 1
	for i in 2:
		var point: Vector2 = get_node("Environment/06_Marcadores/InicioPato_" + ("A" if i==0 else "B")).position
		get_node("Patos/" + ("Pato" if i==0 else "Pato2")).position = point
		get_node("Simbiontes/" + ("CapulloCian" if i==0 else "CapulloMagenta")).position = point

func _ready() -> void:
	for duck in $Patos.get_children(): duck.set_physics_process(false)
	npc_navigation = NavegacionSimbionte.new()
	npc_navigation.name = "NpcNavigation"
	npc_navigation.limites = get_meta("bounds")
	npc_navigation.radio_cuerpo = 19.0
	add_child(npc_navigation)
	await npc_navigation.preparada
	npc_destinations = npc_navigation.posiciones_transitables($Patos/Pato.position, 19.0)
	if npc_destinations.size() < 65:
		push_error("El mapa no tiene 65 posiciones transitables para la partida.")
		return
	var candidates: Array[Vector2] = []
	candidates.assign(npc_destinations)
	candidates.shuffle()
	var occupied: Array[Vector2] = [$Patos/Pato.position, $Patos/Pato2.position]
	var count := 0
	for point in candidates:
		var clear := true
		for other in occupied:
			if point.distance_squared_to(other) < 40.0*40.0:
				clear = false
				break
		if not clear: continue
		var bot := ESCENA_BOT.instantiate()
		bot.name = "Bot%d" % (count+1)
		bot.position = point
		$Bots.add_child(bot)
		occupied.append(point)
		count += 1
		if count == 65: break
	map_is_ready = true
	if map_id == "splash":
		var life := get_node("Environment/10_VidaParque")
		life.configure_navigation(ambient_route)
		life.infection_reader = func(actor: Node): return actor.is_infected if actor.is_in_group("bots") else false
		life.enabled = true
	super._ready()
	for duck in $Patos.get_children(): duck.set_physics_process(true)
	timer_inicio.start()
	var onboarding := get_node_or_null("/root/PatogenOnboarding")
	if onboarding: onboarding.prepare_scene(self)
	if map_id == "splash": $Environment.infection_effect = 0
	map_ready.emit()

func _process(delta: float) -> void:
	if map_is_ready:
		super._process(delta)
		if map_id == "splash": $Environment.enabled = simbionte_en_juego()
		if map_id == "splash":
			get_node("Environment/10_VidaParque").enabled = estado_actual != EstadoJuego.FIN and not get_tree().root.get_meta("patogen_intro_managed",false)

func _physics_process(delta: float) -> void:
	if map_is_ready: super._physics_process(delta)

func safe_replica_position(origin: Vector2) -> Vector2:
	npc_navigation.actualizar_exclusiones()
	var angle := randf()*TAU
	for i in 8:
		var point := origin+Vector2.RIGHT.rotated(angle+i*TAU/8.0)*32.0
		if npc_navigation.limites.has_point(point) and npc_navigation.segmento_libre(origin,point): return point
	return Vector2.INF

func ambient_route(from: Vector2, to: Vector2) -> PackedVector2Array:
	# Service markers can be inside a counter/chair. Project their ground
	# endpoints onto reachable floor; only the authored docking segment enters it.
	var endpoints: Array[Vector2]=[]
	for point in [from,to]:
		var nearest: Vector2=npc_destinations[0]
		var best:=INF
		for candidate in npc_destinations:
			var distance: float=candidate.distance_squared_to(point)
			if distance<best: best=distance;nearest=candidate
		endpoints.append(nearest)
	var path: PackedVector2Array=npc_navigation.ruta(endpoints[0],endpoints[1])
	if not path.is_empty(): path.insert(0,endpoints[0])
	return path

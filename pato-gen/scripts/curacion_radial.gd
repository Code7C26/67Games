extends RefCounted
## Shared robot/symbiont pulse. Healing and resistance belong to Bot.gd.
static func aplicar(origen: Node2D, radio: float, chance: float, equipo_excluido: int = 0) -> void:
	for bot in candidatos(origen, radio, equipo_excluido):
		if bot.has_method("curar_por_robot"):
			bot.curar_por_robot(chance)

static func candidatos(origen: Node2D, radio: float, equipo_excluido: int = 0) -> Array[Node2D]:
	var resultado: Array[Node2D] = []
	var mundo: Node = origen.get_tree().current_scene
	if not is_instance_valid(mundo):
		return resultado
	for bot in origen.get_tree().get_nodes_in_group("bots"):
		if not is_instance_valid(bot) or bot.is_queued_for_deletion() or not mundo.is_ancestor_of(bot):
			continue
		if not bot.is_infected or (equipo_excluido != 0 and bot.player_duenio == equipo_excluido):
			continue
		if origen.global_position.distance_squared_to(bot.global_position) > radio * radio:
			continue
		resultado.append(bot)
	return resultado

static func candidatos_coloso(origen: Node2D, radio: float, tratados: Dictionary) -> Array[Node2D]:
	var resultado: Array[Node2D] = []
	var mundo: Node = origen.get_tree().current_scene
	if not is_instance_valid(mundo) or not mundo.has_method("contar_infecciones"):
		return resultado
	# Recuento vivo: las estadísticas del cuadro anterior no protegen al último bot.
	var stats: Dictionary = mundo.contar_infecciones()
	for bot in candidatos(origen, radio):
		var cantidad: int = stats.blue if bot.player_duenio == 1 else stats.magenta
		if cantidad > 1 and not tratados.has(bot.get_instance_id()):
			resultado.append(bot)
	return resultado

static func linea_libre(origen: Node2D, destino: Vector2, desde: Variant = null) -> bool:
	var inicio: Vector2 = origen.global_position if desde == null else desde
	var consulta := PhysicsRayQueryParameters2D.create(inicio, destino, 1)
	var excluidos: Array[RID] = []
	for grupo in ["bots", "patos", "robots_curadores", "simbiontes", "colosos_antivirales"]:
		for cuerpo in origen.get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(cuerpo) and cuerpo is CollisionObject2D:
				excluidos.append(cuerpo.get_rid())
	consulta.exclude = excluidos
	consulta.collide_with_areas = false
	consulta.hit_from_inside = true
	return origen.get_world_2d().direct_space_state.intersect_ray(consulta).is_empty()

static func aplicar_coloso(origen: Node2D, radio: float, chance: float, tratados: Dictionary, azar: RandomNumberGenerator, proteccion: float) -> Node2D:
	var posibles: Array[Node2D] = []
	for bot in candidatos_coloso(origen, radio, tratados):
		if linea_libre(origen, bot.global_position):
			posibles.append(bot)
	if posibles.is_empty():
		return null
	# Selección uniforme: ni el color ni el orden de nodos deciden el objetivo.
	var objetivo := posibles[azar.randi_range(0, posibles.size() - 1)]
	if objetivo.curar_por_coloso(chance, proteccion, azar):
		tratados[objetivo.get_instance_id()] = true
		return objetivo
	return null

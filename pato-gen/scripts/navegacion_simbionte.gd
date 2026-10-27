extends Node2D
## Private, runtime grid from existing physics. Does not change map/navigation nodes.
signal preparada
const CELDA := 16.0
const RADIO := 8.0
var radio_cuerpo: float = RADIO
const RADIO_CAPULLO := 32.0
const SEPARACION_CAPULLOS := 400.0
var limites := Rect2(0, 80, 2128, 960)
var cuadricula := AStarGrid2D.new()
var lista := false
var cursor := 0
var excluidos: Array[RID] = []
var prueba := PhysicsShapeQueryParameters2D.new()
var circulo := CircleShape2D.new()
var caja := RectangleShape2D.new()
var posiciones_capullos := PackedVector2Array()
var azar_capullos := RandomNumberGenerator.new()

func _ready() -> void:
	azar_capullos.randomize()
	cuadricula.region = Rect2i(Vector2i.ZERO, Vector2i(ceili(limites.size.x / CELDA), ceili(limites.size.y / CELDA)))
	cuadricula.cell_size = Vector2.ONE * CELDA
	cuadricula.offset = limites.position + Vector2.ONE * CELDA * 0.5
	cuadricula.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	cuadricula.update()
	circulo.radius = radio_cuerpo
	# Reserve the whole cell plus the body radius: grid edges cannot cut walls.
	caja.size = Vector2.ONE * (CELDA + radio_cuerpo * 2.0)
	prueba.collision_mask = 1
	prueba.collide_with_areas = false
	prueba.margin = 0.2

func actualizar_exclusiones() -> void:
	excluidos.clear()
	for grupo in ["bots", "patos", "robots_curadores", "simbiontes", "colosos_antivirales"]:
		for cuerpo in get_tree().get_nodes_in_group(grupo):
			if is_instance_valid(cuerpo) and cuerpo is CollisionObject2D:
				excluidos.append(cuerpo.get_rid())
	prueba.exclude = excluidos

func _physics_process(_delta: float) -> void:
	# Budget generation over several physics ticks; physics has synchronized here.
	actualizar_exclusiones()
	prueba.shape = caja
	prueba.motion = Vector2.ZERO
	var ancho: int = cuadricula.region.size.x
	var total: int = ancho * cuadricula.region.size.y
	var espacio := get_world_2d().direct_space_state
	for _i in range(512):
		if cursor >= total:
			lista = true
			set_physics_process(false)
			preparada.emit()
			return
		var celda := Vector2i(cursor % ancho, cursor / ancho)
		prueba.transform = Transform2D(0.0, cuadricula.get_point_position(celda))
		cuadricula.set_point_solid(celda, not espacio.intersect_shape(prueba, 1).is_empty())
		cursor += 1

func preparar_posiciones_capullos(origen: Vector2) -> void:
	posiciones_capullos = posiciones_transitables(origen)

func posiciones_transitables(origen: Vector2, radio_espacio: float = RADIO_CAPULLO) -> PackedVector2Array:
	var posiciones := PackedVector2Array()
	if not lista:
		return posiciones
	actualizar_exclusiones()
	var inicio := _celda_accesible(origen)
	if inicio.x < 0:
		return posiciones
	# Flood-fill only the playable component. Free space outside the mall is invalid.
	var pendientes: Array[Vector2i] = [inicio]
	var visitados: Dictionary = {inicio: true}
	var indice := 0
	var huella := CircleShape2D.new()
	huella.radius = radio_espacio
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = huella
	consulta.collision_mask = 1
	consulta.collide_with_areas = false
	consulta.exclude = excluidos
	consulta.margin = 0.2
	var espacio := get_world_2d().direct_space_state
	while indice < pendientes.size():
		var celda := pendientes[indice]
		indice += 1
		var punto := cuadricula.get_point_position(celda)
		consulta.transform = Transform2D(0.0, punto)
		# Leave room for the egg and its labels at the edge of the map.
		if limites.grow(-64.0).has_point(punto) and espacio.intersect_shape(consulta, 1).is_empty():
			posiciones.append(punto)
		for direccion in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var vecina: Vector2i = celda + direccion
			if not visitados.has(vecina) and cuadricula.is_in_boundsv(vecina) and not cuadricula.is_point_solid(vecina):
				visitados[vecina] = true
				pendientes.append(vecina)
	return posiciones

func sortear_posiciones_capullos() -> PackedVector2Array:
	if posiciones_capullos.size() < 2:
		return PackedVector2Array()
	var inicio := azar_capullos.randi_range(0, posiciones_capullos.size() - 1)
	# Bounded search also handles maps with too little room without an infinite loop.
	for desplazamiento in range(posiciones_capullos.size()):
		var primera := posiciones_capullos[(inicio + desplazamiento) % posiciones_capullos.size()]
		var distantes := PackedVector2Array()
		for punto in posiciones_capullos:
			if primera.distance_squared_to(punto) >= SEPARACION_CAPULLOS * SEPARACION_CAPULLOS:
				distantes.append(punto)
		if not distantes.is_empty():
			return PackedVector2Array([primera, distantes[azar_capullos.randi_range(0, distantes.size() - 1)]])
	return PackedVector2Array()

func segmento_libre(desde: Vector2, hasta: Vector2) -> bool:
	prueba.shape = circulo
	prueba.transform = Transform2D(0.0, desde)
	prueba.motion = Vector2.ZERO
	var espacio := get_world_2d().direct_space_state
	if not espacio.intersect_shape(prueba, 1).is_empty():
		return false
	prueba.motion = hasta - desde
	var resultado := espacio.cast_motion(prueba)
	return resultado.size() == 2 and resultado[0] >= 1.0

func _celda_accesible(posicion: Vector2) -> Vector2i:
	var base := Vector2i(((posicion - cuadricula.offset) / CELDA).round())
	var mejor := Vector2i(-1, -1)
	var distancia := INF
	# Endpoints can be next to a wall although their nearest grid cell is solid.
	for y in range(base.y - 3, base.y + 4):
		for x in range(base.x - 3, base.x + 4):
			var id := Vector2i(x, y)
			if not cuadricula.is_in_boundsv(id) or cuadricula.is_point_solid(id):
				continue
			var punto := cuadricula.get_point_position(id)
			var d := posicion.distance_squared_to(punto)
			if d < distancia and segmento_libre(posicion, punto):
				distancia = d
				mejor = id
	return mejor

func ruta(desde: Vector2, hasta: Vector2) -> PackedVector2Array:
	actualizar_exclusiones()
	if segmento_libre(desde, hasta):
		return PackedVector2Array([hasta])
	if not lista:
		return PackedVector2Array()
	var inicio := _celda_accesible(desde)
	var fin := _celda_accesible(hasta)
	if inicio.x < 0 or fin.x < 0:
		return PackedVector2Array()
	var puntos := cuadricula.get_point_path(inicio, fin)
	if not puntos.is_empty():
		puntos.append(hasta)
	return puntos

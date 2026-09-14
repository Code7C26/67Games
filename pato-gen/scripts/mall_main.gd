
extends Node2D

## PATOGEN MALL V5 — fuente principal de la geometría del mapa.
## El diseño visual, las colisiones y las zonas usan las mismas posiciones.

# Carga el archivo que contiene las posiciones y tamaños del mapa
const Layout = preload("res://scripts/mall_layout.gd")

# Obtiene las dimensiones y configuraciones principales del mapa
const MAP_WIDTH := Layout.MAP_WIDTH
const MAP_HEIGHT := Layout.MAP_HEIGHT
const WALL_THICKNESS := Layout.WALL_THICKNESS
const PLAYER_LAYER := Layout.PLAYER_LAYER

# Referencias al jugador y a su cámara
var camera: Camera2D
var player: CharacterBody2D

# Obtiene las tiendas y zonas definidas en el archivo Layout
var stores: Array = Layout.STORES
var mezzanine: Rect2 = Layout.MEZZANINE
var stair_left: Rect2 = Layout.STAIR_LEFT
var stair_right: Rect2 = Layout.STAIR_RIGHT
var condition_zones: Array = Layout.HOT_COLD_ZONES


func _ready() -> void:
	# Busca al jugador y su cámara
	player = get_node_or_null("Player") as CharacterBody2D
	if player != null:
		camera = player.get_node_or_null("Camera2D") as Camera2D

	# Configura los límites, colisiones y zonas del mapa
	_apply_camera_limits()
	_create_mall_collision()
	_create_condition_zones()
	_create_navigation_markers()

	# Coloca al jugador en una posición segura al comenzar
	if player != null:
		player.position = Layout.PLAYER_SPAWN
		player.collision_layer = PLAYER_LAYER
		player.collision_mask = PLAYER_LAYER


# Establece los límites que puede recorrer la cámara
func _apply_camera_limits() -> void:
	if camera == null:
		return

	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_WIDTH)
	camera.limit_bottom = int(MAP_HEIGHT)
	camera.reset_smoothing()


# Crea todas las colisiones principales del centro comercial
func _create_mall_collision() -> void:
	var root := StaticBody2D.new()
	root.name = "MallCollision"
	root.set_meta("layout_source", "res://scripts/mall_layout.gd")
	root.collision_layer = PLAYER_LAYER
	root.collision_mask = PLAYER_LAYER
	add_child(root)

	# Crea las diferentes partes de las colisiones
	_create_outer_walls(root)
	_create_store_walls(root)
	_create_mezzanine_walls(root)
	_create_atrium_collisions(root)
	_create_public_furniture_collisions(root)


# Crea una pared rectangular con colisión
func _add_wall(body: StaticBody2D, center: Vector2, size: Vector2, wall_name: String) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size

	var collision := CollisionShape2D.new()
	collision.name = wall_name
	collision.position = center
	collision.shape = shape
	body.add_child(collision)


# Crea las paredes exteriores del centro comercial
func _create_outer_walls(body: StaticBody2D) -> void:
	const LEFT := 205.0
	const RIGHT := 2995.0
	const TOP := 125.0
	const BOTTOM := 2175.0

	# Crea las paredes superiores e inferiores dejando entradas
	for y in [TOP, BOTTOM]:
		_add_wall(
			body,
			Vector2((LEFT + 620.0) * 0.5, y),
			Vector2(620.0 - LEFT, WALL_THICKNESS),
			"Outer_Left_" + str(y)
		)

		_add_wall(
			body,
			Vector2((760.0 + 1420.0) * 0.5, y),
			Vector2(660.0, WALL_THICKNESS),
			"Outer_Centre_" + str(y)
		)

		_add_wall(
			body,
			Vector2((1560.0 + 2460.0) * 0.5, y),
			Vector2(900.0, WALL_THICKNESS),
			"Outer_Right_" + str(y)
		)

		_add_wall(
			body,
			Vector2((2580.0 + RIGHT) * 0.5, y),
			Vector2(RIGHT - 2580.0, WALL_THICKNESS),
			"Outer_FarRight_" + str(y)
		)

	# Crea las paredes laterales dejando entradas hacia el atrio
	for x in [LEFT, RIGHT]:
		_add_wall(
			body,
			Vector2(x, (TOP + 1040.0) * 0.5),
			Vector2(WALL_THICKNESS, 1040.0 - TOP),
			"Outer_SideTop_" + str(x)
		)

		_add_wall(
			body,
			Vector2(x, (1200.0 + BOTTOM) * 0.5),
			Vector2(WALL_THICKNESS, BOTTOM - 1200.0),
			"Outer_SideBottom_" + str(x)
		)


# Crea las paredes de cada tienda
func _create_store_walls(body: StaticBody2D) -> void:
	for store in stores:
		var r: Rect2 = store["rect"]
		var side := str(store["side"])
		var prefix := str(store["name"]).replace(" ", "_")
		var door_width := float(store["door_width"])

		# Según el lado de la tienda se colocan las paredes
		match side:
			"south":
				_add_wall(
					body,
					Vector2(r.position.x + r.size.x * 0.5, r.position.y),
					Vector2(r.size.x, WALL_THICKNESS),
					prefix + "_Back"
				)

				_add_wall(
					body,
					Vector2(r.position.x, r.position.y + r.size.y * 0.5),
					Vector2(WALL_THICKNESS, r.size.y),
					prefix + "_Left"
				)

				_add_wall(
					body,
					Vector2(r.end.x, r.position.y + r.size.y * 0.5),
					Vector2(WALL_THICKNESS, r.size.y),
					prefix + "_Right"
				)

				_add_store_front_with_door(
					body,
					r,
					side,
					prefix + "_Front",
					door_width
				)

			"north":
				_add_wall(
					body,
					Vector2(r.position.x + r.size.x * 0.5, r.end.y),
					Vector2(r.size.x, WALL_THICKNESS),
					prefix + "_Back"
				)

				_add_wall(
					body,
					Vector2(r.position.x, r.position.y + r.size.y * 0.5),
					Vector2(WALL_THICKNESS, r.size.y),
					prefix + "_Left"
				)

				_add_wall(
					body,
					Vector2(r.end.x, r.position.y + r.size.y * 0.5),
					Vector2(WALL_THICKNESS, r.size.y),
					prefix + "_Right"
				)

				_add_store_front_with_door(
					body,
					r,
					side,
					prefix + "_Front",
					door_width
				)

			"east":
				# La tienda está al oeste y la entrada apunta hacia el este
				_add_wall(
					body,
					Vector2(r.position.x, r.position.y + r.size.y * 0.5),
					Vector2(WALL_THICKNESS, r.size.y),
					prefix + "_Back"
				)

				_add_wall(
					body,
					Vector2(r.position.x + r.size.x * 0.5, r.position.y),
					Vector2(r.size.x, WALL_THICKNESS),
					prefix + "_Top"
				)

				_add_wall(
					body,
					Vector2(r.position.x + r.size.x * 0.5, r.end.y),
					Vector2(r.size.x, WALL_THICKNESS),
					prefix + "_Bottom"
				)

				_add_store_front_with_door(
					body,
					r,
					side,
					prefix + "_Front",
					door_width
				)

			"west":
				# La tienda está al este y la entrada apunta hacia el oeste
				_add_wall(
					body,
					Vector2(r.end.x, r.position.y + r.size.y * 0.5),
					Vector2(WALL_THICKNESS, r.size.y),
					prefix + "_Back"
				)

				_add_wall(
					body,
					Vector2(r.position.x + r.size.x * 0.5, r.position.y),
					Vector2(r.size.x, WALL_THICKNESS),
					prefix + "_Top"
				)

				_add_wall(
					body,
					Vector2(r.position.x + r.size.x * 0.5, r.end.y),
					Vector2(r.size.x, WALL_THICKNESS),
					prefix + "_Bottom"
				)

				_add_store_front_with_door(
					body,
					r,
					side,
					prefix + "_Front",
					door_width
				)


# Crea la pared frontal de una tienda dejando espacio para la puerta
func _add_store_front_with_door(
	body: StaticBody2D,
	r: Rect2,
	side: String,
	prefix: String,
	door_width: float
) -> void:
	# Calcula la mitad del ancho de la puerta
	var half := door_width * 0.5

	# Crea la pared dependiendo de la orientación de la tienda
	match side:
		"south", "north":
			var y := r.end.y if side == "south" else r.position.y
			var left_len := maxf(12.0, r.size.x * 0.5 - half)
			var right_len := maxf(12.0, r.size.x * 0.5 - half)

			_add_wall(
				body,
				Vector2(r.position.x + left_len * 0.5, y),
				Vector2(left_len, WALL_THICKNESS),
				prefix + "_L"
			)

			_add_wall(
				body,
				Vector2(r.end.x - right_len * 0.5, y),
				Vector2(right_len, WALL_THICKNESS),
				prefix + "_R"
			)

		"east", "west":
			var x := r.end.x if side == "east" else r.position.x
			var top_len := maxf(12.0, r.size.y * 0.5 - half)
			var bottom_len := maxf(12.0, r.size.y * 0.5 - half)

			_add_wall(
				body,
				Vector2(x, r.position.y + top_len * 0.5),
				Vector2(WALL_THICKNESS, top_len),
				prefix + "_T"
			)

			_add_wall(
				body,
				Vector2(x, r.end.y - bottom_len * 0.5),
				Vector2(WALL_THICKNESS, bottom_len),
				prefix + "_B"
			)


# Crea las colisiones de la zona superior o mezzanine
func _create_mezzanine_walls(body: StaticBody2D) -> void:
	# La mezzanine permite caminar, pero sus barandas tienen colisión
	var r := mezzanine

	_add_wall(
		body,
		Vector2(r.position.x, r.position.y + r.size.y * 0.5),
		Vector2(18, r.size.y),
		"Mezzanine_LeftRail"
	)

	_add_wall(
		body,
		Vector2(r.end.x, r.position.y + r.size.y * 0.5),
		Vector2(18, r.size.y),
		"Mezzanine_RightRail"
	)

	_add_wall(
		body,
		Vector2(r.position.x + r.size.x * 0.5, r.position.y),
		Vector2(r.size.x, 18),
		"Mezzanine_BackRail"
	)

	# La parte frontal deja libres las zonas de las escaleras
	_add_wall(
		body,
		Vector2((stair_left.end.x + stair_right.position.x) * 0.5, r.end.y),
		Vector2(stair_right.position.x - stair_left.end.x, 18),
		"Mezzanine_FrontCentre"
	)


# Crea las colisiones de la zona central del atrio
func _create_atrium_collisions(body: StaticBody2D) -> void:
	# Crea la fuente como un obstáculo circular
	var fountain := CircleShape2D.new()
	fountain.radius = 62.0

	var fountain_collision := CollisionShape2D.new()
	fountain_collision.name = "AtriumFountain"
	fountain_collision.position = Vector2(1600, 1140)
	fountain_collision.shape = fountain
	body.add_child(fountain_collision)

	# Agrega colisiones a los bancos del atrio
	var bench_positions: Array = Layout.ATRIUM_BENCHES
	for i in range(bench_positions.size()):
		_add_wall(
			body,
			bench_positions[i],
			Vector2(100, 24),
			"AtriumBench_" + str(i)
		)


# Crea las colisiones de los objetos públicos
func _create_public_furniture_collisions(body: StaticBody2D) -> void:
	# Colisiones de los bancos
	var benches: Array = Layout.PUBLIC_BENCHES
	for i in range(benches.size()):
		_add_wall(
			body,
			benches[i],
			Vector2(100, 24),
			"PublicBench_" + str(i)
		)

	# Colisiones de los canteros
	var planters: Array = Layout.PLANTERS
	for i in range(planters.size()):
		_add_wall(
			body,
			planters[i],
			Vector2(40, 34),
			"Planter_" + str(i)
		)

	# Colisiones de los kioscos
	for i in range(Layout.KIOSKS.size()):
		var p: Vector2 = Layout.KIOSKS[i]
		_add_wall(
			body,
			p,
			Vector2(70, 46),
			"Kiosk_" + str(i)
		)


# Crea las zonas de temperatura del mapa
func _create_condition_zones() -> void:
	var root := Node2D.new()
	root.name = "GameplayZones"
	add_child(root)

	# Indica que estas zonas sirven para detectar condiciones del juego
	root.set_meta(
		"purpose",
		"Patogen hot/cold zones; collisionless detection layer"
	)

	# Crea un Area2D para cada zona
	for def in condition_zones:
		var area := Area2D.new()
		area.name = str(def["id"])
		area.collision_layer = 0
		area.collision_mask = PLAYER_LAYER
		area.monitoring = true
		area.monitorable = true
		area.add_to_group("patogen_condition_zone")

		# Guarda información de la zona
		area.set_meta("zone_id", str(def["id"]))
		area.set_meta("zone_type", str(def["type"]))
		area.set_meta("intensity", float(def["intensity"]))

		# Crea la forma rectangular del área
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = def["rect"].size
		shape.shape = rect_shape
		shape.position = def["rect"].size * 0.5
		area.add_child(shape)

		# Coloca la zona en su posición correspondiente
		area.position = def["rect"].position
		root.add_child(area)


# Crea puntos de referencia para facilitar la navegación de los bots
func _create_navigation_markers() -> void:
	# Los marcadores permiten identificar lugares importantes del mapa
	var root := Node2D.new()
	root.name = "NavigationMarkers"
	add_child(root)

	# Posiciones de los puntos importantes
	var points := {
		"Spawn": Vector2(1600, 1180),
		"NorthHub": Vector2(1600, 780),
		"SouthHub": Vector2(1600, 1660),
		"WestHub": Vector2(820, 1140),
		"EastHub": Vector2(2380, 1140),
		"MezzanineLeft": Vector2(1240, 725),
		"MezzanineRight": Vector2(1960, 725),
		"CinemaDoor": Vector2(2520, 935),
		"ArcadeDoor": Vector2(2450, 1400),
		"MarketDoor": Vector2(2390, 1835),
		"CafeDoor": Vector2(780, 1490),
		"SportsDoor": Vector2(640, 1740)
	}

	# Crea un marcador para cada punto
	for key in points:
		var marker := Marker2D.new()
		marker.name = key
		marker.position = points[key]
		root.add_child(marker)

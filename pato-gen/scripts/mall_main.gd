extends Node2D
## PATOGEN MALL V5 — gameplay-first map source of truth.
## The visual layout, collision layout and gameplay zones share one canonical geometry file.

const Layout = preload("res://scripts/mall_layout.gd")

const MAP_WIDTH := Layout.MAP_WIDTH
const MAP_HEIGHT := Layout.MAP_HEIGHT
const WALL_THICKNESS := Layout.WALL_THICKNESS
const PLAYER_LAYER := Layout.PLAYER_LAYER

var camera: Camera2D
var player: CharacterBody2D

var stores: Array = Layout.STORES
var mezzanine: Rect2 = Layout.MEZZANINE
var stair_left: Rect2 = Layout.STAIR_LEFT
var stair_right: Rect2 = Layout.STAIR_RIGHT
var condition_zones: Array = Layout.HOT_COLD_ZONES


func _ready() -> void:
	player = get_node_or_null("Player") as CharacterBody2D
	if player != null:
		camera = player.get_node_or_null("Camera2D") as Camera2D

	_apply_camera_limits()
	_create_mall_collision()
	_create_condition_zones()
	_create_navigation_markers()

	# Safe spawn: clear of fountain, stairs, furniture and store walls.
	if player != null:
		player.position = Layout.PLAYER_SPAWN
		player.collision_layer = PLAYER_LAYER
		player.collision_mask = PLAYER_LAYER


func _apply_camera_limits() -> void:
	if camera == null:
		return

	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(MAP_WIDTH)
	camera.limit_bottom = int(MAP_HEIGHT)
	camera.reset_smoothing()


func _create_mall_collision() -> void:
	var root := StaticBody2D.new()
	root.name = "MallCollision"
	root.set_meta("layout_source", "res://scripts/mall_layout.gd")
	root.collision_layer = PLAYER_LAYER
	root.collision_mask = PLAYER_LAYER
	add_child(root)

	_create_outer_walls(root)
	_create_store_walls(root)
	_create_mezzanine_walls(root)
	_create_atrium_collisions(root)
	_create_public_furniture_collisions(root)


func _add_wall(body: StaticBody2D, center: Vector2, size: Vector2, wall_name: String) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size

	var collision := CollisionShape2D.new()
	collision.name = wall_name
	collision.position = center
	collision.shape = shape
	body.add_child(collision)


func _create_outer_walls(body: StaticBody2D) -> void:
	const LEFT := 205.0
	const RIGHT := 2995.0
	const TOP := 125.0
	const BOTTOM := 2175.0

	# 3 north entrances + 3 south entrances.
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

	# West/East side entries line up with the main atrium lanes.
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


func _create_store_walls(body: StaticBody2D) -> void:
	for store in stores:
		var r: Rect2 = store["rect"]
		var side := str(store["side"])
		var prefix := str(store["name"]).replace(" ", "_")
		var door_width := float(store["door_width"])

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
				# Store is on the WEST side; entrance faces EAST.
				# Back wall stays on the LEFT; front wall/door is on the RIGHT.
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
				# Store is on the EAST side; entrance faces WEST.
				# Back wall stays on the RIGHT; front wall/door is on the LEFT.
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


func _add_store_front_with_door(
	body: StaticBody2D,
	r: Rect2,
	side: String,
	prefix: String,
	door_width: float
) -> void:
	# The gap is centered on the exact visual doorway and is intentionally 12px
	# wider than the player radius on each side to prevent snagging.
	var half := door_width * 0.5

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


func _create_mezzanine_walls(body: StaticBody2D) -> void:
	# The mezzanine is a walkable upper gallery. Only its guard rails collide;
	# the stair rectangles remain free so the player can enter the upper level.
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

	# Front rail leaves the two stair landings completely open.
	_add_wall(
		body,
		Vector2((stair_left.end.x + stair_right.position.x) * 0.5, r.end.y),
		Vector2(stair_right.position.x - stair_left.end.x, 18),
		"Mezzanine_FrontCentre"
	)


func _create_atrium_collisions(body: StaticBody2D) -> void:
	# Fountain: central obstacle with generous circulation ring.
	var fountain := CircleShape2D.new()
	fountain.radius = 62.0

	var fountain_collision := CollisionShape2D.new()
	fountain_collision.name = "AtriumFountain"
	fountain_collision.position = Vector2(1600, 1140)
	fountain_collision.shape = fountain
	body.add_child(fountain_collision)

	# Decorative benches around the fountain.
	var bench_positions: Array = Layout.ATRIUM_BENCHES
	for i in range(bench_positions.size()):
		_add_wall(
			body,
			bench_positions[i],
			Vector2(100, 24),
			"AtriumBench_" + str(i)
		)


func _create_public_furniture_collisions(body: StaticBody2D) -> void:
	var benches: Array = Layout.PUBLIC_BENCHES
	for i in range(benches.size()):
		_add_wall(
			body,
			benches[i],
			Vector2(100, 24),
			"PublicBench_" + str(i)
		)

	var planters: Array = Layout.PLANTERS
	for i in range(planters.size()):
		_add_wall(
			body,
			planters[i],
			Vector2(40, 34),
			"Planter_" + str(i)
		)

	# Kiosks are placed beside, never inside, primary door approaches.
	for i in range(Layout.KIOSKS.size()):
		var p: Vector2 = Layout.KIOSKS[i]
		_add_wall(
			body,
			p,
			Vector2(70, 46),
			"Kiosk_" + str(i)
		)


func _create_condition_zones() -> void:
	var root := Node2D.new()
	root.name = "GameplayZones"
	add_child(root)
	root.set_meta(
		"purpose",
		"Patogen hot/cold zones; collisionless detection layer"
	)

	for def in condition_zones:
		var area := Area2D.new()
		area.name = str(def["id"])
		area.collision_layer = 0
		area.collision_mask = PLAYER_LAYER
		area.monitoring = true
		area.monitorable = true
		area.add_to_group("patogen_condition_zone")
		area.set_meta("zone_id", str(def["id"]))
		area.set_meta("zone_type", str(def["type"]))
		area.set_meta("intensity", float(def["intensity"]))

		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = def["rect"].size
		shape.shape = rect_shape
		shape.position = def["rect"].size * 0.5
		area.add_child(shape)

		area.position = def["rect"].position
		root.add_child(area)


func _create_navigation_markers() -> void:
	# Integration-friendly marker nodes. Teammates can build/replace their AI nav
	# graph around these stable IDs without having to reverse-engineer the map.
	var root := Node2D.new()
	root.name = "NavigationMarkers"
	add_child(root)

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

	for key in points:
		var marker := Marker2D.new()
		marker.name = key
		marker.position = points[key]
		root.add_child(marker)

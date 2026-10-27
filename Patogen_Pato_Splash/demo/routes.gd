extends RefCounted
## Test navigation only. The delivered map doesn't replace Patogen's Bot.gd.
var grid := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var goals: Array[Vector2] = []
var free_cells: Array[Vector2i] = []
var bounds := Rect2(32,112,1856,860)
var excluded_isolated_cells := 0

func setup(map: Node2D, radius: float = 19.0, reserved: Array[Rect2] = []) -> void:
	obstacles.clear()
	_collect(map)
	obstacles.append_array(reserved)
	grid.region = Rect2i(0,0,120,68)
	grid.cell_size = Vector2(16,16)
	grid.offset = Vector2(8,8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var promenade: TileMapLayer=map.get_node_or_null("07_Caminos")
	free_cells.clear()
	for y in range(68):
		for x in range(120):
			var id := Vector2i(x,y)
			var pos := grid.get_point_position(id)
			var solid := not bounds.grow(-radius).has_point(pos)
			if not solid:
				for r in obstacles:
					if r.grow(radius).has_point(pos):
						solid = true
						break
			grid.set_point_solid(id,solid)
			if promenade and not solid:
				var paving:=promenade.local_to_map(promenade.to_local(pos))
				grid.set_point_weight_scale(id,.72 if promenade.get_cell_source_id(paving)>=0 else 1.0)
			if not solid: free_cells.append(id)
	# Spawn only in the public circulation component. Narrow decorative pockets
	# behind a facade may fit a grid point but have no walkable entrance.
	var entry_cell:=nearest_cell(map.get_node("06_Marcadores/InicioPato_A").global_position)
	var queue: Array[Vector2i]=[entry_cell]
	var reached: Dictionary={entry_cell:true}
	var cursor:=0
	while cursor<queue.size():
		var cell: Vector2i=queue[cursor];cursor+=1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor: Vector2i=cell+offset
			if grid.is_in_boundsv(neighbor) and not grid.is_point_solid(neighbor) and not reached.has(neighbor):
				reached[neighbor]=true;queue.append(neighbor)
	excluded_isolated_cells=0
	for cell in free_cells:
		if not reached.has(cell):grid.set_point_solid(cell,true);excluded_isolated_cells+=1
	free_cells=queue
	goals.clear()
	for marker in map.get_node("06_Marcadores").get_children():
		if marker.is_in_group("patogen_destination"):
			goals.append(nearest_point(marker.global_position))

func _collect(n: Node) -> void:
	if n is CollisionShape2D and n.get_parent() is StaticBody2D and n.shape is RectangleShape2D and not n.disabled:
		var r := Rect2(-n.shape.size * 0.5, n.shape.size)
		obstacles.append(n.global_transform * r)
	for c in n.get_children(): _collect(c)

func nearest_cell(pos: Vector2) -> Vector2i:
	var direct := Vector2i(floori(pos.x/16),floori(pos.y/16))
	if grid.is_in_boundsv(direct) and not grid.is_point_solid(direct): return direct
	var best := Vector2i(-1,-1)
	var score := INF
	for id in free_cells:
		var d := grid.get_point_position(id).distance_squared_to(pos)
		if d < score:
			score = d
			best = id
	return best

func nearest_point(pos: Vector2) -> Vector2:
	return grid.get_point_position(nearest_cell(pos))

func path(start: Vector2, finish: Vector2) -> PackedVector2Array:
	return grid.get_point_path(nearest_cell(start),nearest_cell(finish))

func clear_segment(a: Vector2, b: Vector2, clearance: float = 17.0) -> bool:
	var steps := maxi(1,ceili(a.distance_to(b) / 6.0))
	for i in range(steps + 1):
		var p := a.lerp(b,float(i)/steps)
		for r in obstacles:
			if r.grow(clearance).has_point(p): return false
	return true

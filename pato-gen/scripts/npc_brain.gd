extends RefCounted
## Route planning and local steering for the production guests in imported maps.
## No ownership, infection, collision layers or player input are changed here.
const SENSE_RADIUS := 240.0
const REPLAN_SECONDS := 0.65
var route := PackedVector2Array()
var mode := "wander"
var target: WeakRef
var goal := Vector2.INF
var decision_left := 0.0
var route_left := 0.0
var progress_time := 0.0
var progress_origin := Vector2.INF
var recoveries := 0
var recovery_left := 0.0
var neighbours: Array[Node2D] = []
var threats: Array[Node2D] = []
var steer_left := 0.0
var steering := Vector2.ZERO
var last_infected := false
var recent_sectors: Array[Vector2i] = []
var flee_left := 0.0
var roam_sector := Vector2i(-1, -1)
var roam_left := 0.0
var avoid_left := 0.0
var escape_route := PackedVector2Array()
var escape_left := 0.0

func reset() -> void:
	route.clear()
	target = null
	goal = Vector2.INF
	decision_left = 0.0
	route_left = 0.0
	progress_origin = Vector2.INF
	progress_time = 0.0
	steer_left = 0.0
	recovery_left = 0.0
	flee_left = 0.0
	avoid_left = 0.0
	escape_route.clear()
	escape_left = 0.0
	steering = Vector2.ZERO
	mode = "wander"
	neighbours.clear()
	threats.clear()

func direction(actor: CharacterBody2D, host: Node2D, delta: float, fallback: Vector2) -> Vector2:
	if actor.controlado_por_jugador or actor._passage_egress_left > 0.0:
		reset()
		return fallback
	if last_infected != actor.is_infected:
		reset()
		last_infected = actor.is_infected
	decision_left -= delta
	route_left -= delta
	recovery_left = maxf(0.0, recovery_left - delta)
	flee_left = maxf(0.0, flee_left - delta)
	avoid_left = maxf(0.0, avoid_left - delta)
	escape_left = maxf(0.0, escape_left - delta)
	var sector: Vector2i = host.npc_sector(actor.global_position)
	if recent_sectors.is_empty() or recent_sectors.back() != sector:
		recent_sectors.append(sector)
		if recent_sectors.size() > 6: recent_sectors.pop_front()
	if mode == "wander" and sector == roam_sector:
		roam_left = maxf(0.0, roam_left - delta)
	# Close contact must not wait for the staggered long-range sensing tick.
	# Hidden threats also leave the cache as soon as their camouflage recovers.
	if not actor.is_infected:
		for threat in threats.duplicate():
			if is_instance_valid(threat) and threat.cepa == "camaleon" and not actor.percibe_infectado(threat, SENSE_RADIUS):
				threats.erase(threat)
				decision_left = 0.0
		if actor.amenaza_camaleon_inmediata() != null:
			decision_left = 0.0
			recovery_left = 0.0
	if decision_left <= 0.0:
		# Stagger by population order, independent of unrelated visual allocations.
		decision_left = 0.20 + float(actor.get_index() % 7) * 0.013
		_sense(actor, host)
		_decide(actor, host)
	var was_escaping := not escape_route.is_empty()
	while escape_route.size() > 1 and actor.global_position.distance_squared_to(escape_route[0]) < 9.0:
		escape_route.remove_at(0)
		steer_left = 0.0
	if escape_route.size() == 1 and actor.global_position.distance_squared_to(escape_route[0]) < 1.0 and _connected_floor_cell(host, actor.global_position).x >= 0:
		escape_route.clear()
	if was_escaping and escape_route.is_empty():
		# Finish the physical exit before resuming the main path. A stale
		# waypoint must not steer us straight back into the same corner.
		route.clear()
		route_left = 0.0
		steer_left = 0.0
	# At a remembered point, search locally instead of reading the hidden body
	# or triggering the generic stuck-recovery walk away from the last trace.
	var pack_trace: Vector2 = actor.posicion_manada()
	if pack_trace.is_finite() and actor.global_position.distance_squared_to(pack_trace) < 144.0:
		progress_time = 0.0
		progress_origin = actor.global_position
		return Vector2.ZERO
	if not pack_trace.is_finite() and actor.is_infected and actor.cepa == "rastreador" and is_instance_valid(actor.rastreador):
		var trace: Vector2 = actor.rastreador.posicion_persecucion()
		if trace.is_finite() and not actor.rastreador.presa_visible and actor.global_position.distance_squared_to(trace) < 144.0:
			progress_time = 0.0
			progress_origin = actor.global_position
			return Vector2.ZERO
	_update_progress(actor, delta)
	if progress_time >= 0.9:
		var travelled := actor.global_position.distance_to(progress_origin)
		progress_time = 0.0
		progress_origin = actor.global_position
		# Arrivals already reset this window. A pursuer pressed against its prey
		# must still yield, even when it is close to its intended destination.
		if travelled < 14.0:
			recoveries += 1
			recovery_left = 2.8
			_choose_floor(actor, host, true)
	# Static floor routes remain valid until arrival or a real blockage. Restarting
	# the grid path every 0.65 s can put its first cell behind a moving guest.
	if route_left <= 0.0:
		var needs_route := route.is_empty() or mode in ["chase", "distortion"]
		if not needs_route:
			needs_route = not host.npc_navigation.segmento_libre(actor.global_position, route[0])
		if needs_route and goal.is_finite(): route = host.npc_navigation.ruta(actor.global_position, goal)
		route_left = REPLAN_SECONDS + float(actor.get_index() % 9) * 0.025
		if route.is_empty() and host.npc_navigation.segmento_libre(actor.global_position, actor.global_position):
			_choose_floor(actor, host, true)
	while not route.is_empty() and actor.global_position.distance_squared_to(route[0]) < 49.0:
		route.remove_at(0)
	# Skip only corners that the complete body can safely clear.
	while route.size() > 1 and host.npc_navigation.segmento_libre(actor.global_position, route[1]):
		route.remove_at(0)
	var desired := actor.global_position.direction_to(route[0]) if not route.is_empty() else fallback
	steer_left -= delta
	if steer_left <= 0.0:
		steer_left = 0.10
		steering = _steer(actor, host, desired)
	return steering

func _update_progress(actor: Node2D, delta: float) -> void:
	if not progress_origin.is_finite(): progress_origin = actor.global_position
	progress_time += delta

func _sense(actor: Node2D, host: Node2D) -> void:
	neighbours.clear()
	threats.clear()
	var tracking: bool = actor.posicion_manada().is_finite() or (actor.is_infected and actor.cepa == "rastreador" and is_instance_valid(actor.rastreador))
	var closest: Node2D
	var best := INF
	for other in host.get_node("Bots").get_children():
		if other == actor or not is_instance_valid(other): continue
		var distance: float = actor.global_position.distance_squared_to(other.global_position)
		# A guest pressed against scenery still needs to yield to touching bodies;
		# its conservative navigation circle may already overlap that scenery.
		if distance < 110.0 * 110.0 and (distance < 48.0 * 48.0 or host.npc_navigation.segmento_libre(actor.global_position, other.global_position)): neighbours.append(other)
		if tracking: continue
		if distance > SENSE_RADIUS * SENSE_RADIUS: continue
		if other.is_infected == actor.is_infected: continue
		# Walls and pools block perception; guests do not react through them.
		if not host.npc_navigation.segmento_libre(actor.global_position, other.global_position): continue
		if not actor.is_infected:
			if actor.percibe_infectado(other, SENSE_RADIUS): threats.append(other)
		elif distance < best:
			best = distance
			closest = other
	if tracking:
		target = null
		return
	if actor.is_infected:
		var previous: Node2D = target.get_ref() if target != null else null
		# Retain a nearby prey instead of switching back and forth every tick.
		if is_instance_valid(previous) and not previous.is_infected and actor.global_position.distance_squared_to(previous.global_position) < 420.0 * 420.0:
			if closest == null or best > actor.global_position.distance_squared_to(previous.global_position) * 0.55:
				closest = previous
		if closest == null and actor.tiene_mutacion("mente_colmena"):
			closest = actor._objetivo_compartido()
		target = weakref(closest) if closest != null else null

func _decide(actor: Node2D, host: Node2D) -> void:
	var pack_trace: Vector2 = actor.posicion_manada()
	if pack_trace.is_finite():
		target = null
		if recovery_left > 0.0: return
		mode = "chase"
		if not goal.is_finite() or goal.distance_squared_to(pack_trace) > 24.0 * 24.0:
			goal = pack_trace
			route_left = 0.0
		return
	if actor.is_infected and actor.cepa == "rastreador" and is_instance_valid(actor.rastreador):
		target = null
		var trace: Vector2 = actor.rastreador.posicion_persecucion()
		if trace.is_finite():
			if recovery_left > 0.0: return
			mode = "chase"
			if not goal.is_finite() or goal.distance_squared_to(trace) > 24.0 * 24.0:
				goal = trace
				route_left = 0.0
			return
		if mode == "chase":
			mode = "wander"
			goal = Vector2.INF
			route.clear()
			route_left = 0.0
	if recovery_left > 0.0: return
	var prey: Node2D = target.get_ref() if target != null else null
	if actor.is_infected and is_instance_valid(prey) and not prey.is_infected:
		mode = "chase"
		if not goal.is_finite() or goal.distance_squared_to(prey.global_position) > 24.0 * 24.0:
			goal = prey.global_position
			route_left = 0.0
		return
	if not actor.is_infected and not threats.is_empty():
		var unsafe_goal := false
		for threat in threats:
			if is_instance_valid(threat) and goal.distance_squared_to(threat.global_position) < 120.0 * 120.0:
				unsafe_goal = true
		if mode != "flee" or route.is_empty() or actor.global_position.distance_squared_to(goal) < 24.0 * 24.0 or (flee_left <= 0.0 and unsafe_goal):
			_choose_floor(actor, host, false)
			flee_left = 1.5
		mode = "flee"
		return
	# The active distortion still attracts healthy guests, now along clear floor.
	if not actor.is_infected:
		for zone in actor.get_tree().get_nodes_in_group("zonas_temperatura"):
			if zone.get("tipo") == 0 and actor in zone.cuerpos_dentro:
				if actor.global_position.distance_squared_to(zone.global_position) > 22.0 * 22.0:
					if mode != "distortion" or goal != zone.global_position: route_left = 0.0
					mode = "distortion"
					goal = zone.global_position
					return
	if mode != "wander" or not goal.is_finite() or actor.global_position.distance_squared_to(goal) < 24.0 * 24.0:
		mode = "wander"
		_choose_floor(actor, host, false)

func _choose_floor(actor: Node2D, host: Node2D, recovery: bool) -> void:
	if not recovery and threats.is_empty() and _choose_roam_goal(actor, host): return
	var points: PackedVector2Array = host.npc_destinations
	if points.is_empty(): return
	var best := -INF
	var chosen := Vector2.INF
	var chosen_route := PackedVector2Array()
	# Sample independently per guest: destinations never collapse into one herd.
	for i in 22:
		var point := points[randi() % points.size()]
		var distance := actor.global_position.distance_to(point)
		if distance < 64.0 or distance > (300.0 if recovery else 520.0): continue
		var score := randf_range(0.0, 35.0) - distance * 0.06
		for threat in threats:
			if is_instance_valid(threat):
				score += minf(500.0, point.distance_to(threat.global_position)) * 0.9 / maxf(1.0, threats.size())
		for other in neighbours:
			if is_instance_valid(other): score -= maxf(0.0, 85.0 - point.distance_to(other.global_position))
		if score <= best: continue
		var candidate: PackedVector2Array = host.npc_navigation.ruta(actor.global_position, point)
		if candidate.is_empty(): continue
		if recovery:
			var heading := actor.global_position.direction_to(candidate[mini(2, candidate.size() - 1)])
			for other in neighbours:
				if not is_instance_valid(other): continue
				var offset: Vector2 = other.global_position - actor.global_position
				var distance_to_other := offset.length()
				if distance_to_other > 0.1:
					score -= heading.dot(offset / distance_to_other) * maxf(0.0, 100.0 - distance_to_other) * 1.5
		if not threats.is_empty():
			var heading := actor.global_position.direction_to(candidate[mini(2, candidate.size() - 1)])
			var away := Vector2.ZERO
			for threat in threats:
				if is_instance_valid(threat): away += threat.global_position.direction_to(actor.global_position)
			if not away.is_zero_approx(): score += heading.dot(away.normalized()) * 125.0
		if score > best:
			best = score
			chosen = point
			chosen_route = candidate
	if chosen.is_finite():
		_follow_route(actor, chosen, chosen_route)

func _follow_route(actor: Node2D, point: Vector2, path: PackedVector2Array) -> void:
	goal = point
	route = path
	route_left = REPLAN_SECONDS
	steer_left = 0.0
	avoid_left = 0.0
	# A planned turn or arrival starts a new progress window; it is not a jam.
	progress_origin = actor.global_position
	progress_time = 0.0

func _choose_roam_goal(actor: Node2D, host: Node2D) -> bool:
	# Spend a few seconds walking inside a visited sector before setting off
	# again. Otherwise every room visit immediately feeds the main corridor.
	if roam_left > 0.0 and host.npc_sector(actor.global_position) == roam_sector:
		var local_points: PackedVector2Array = host.npc_roam_sectors[roam_sector]
		for i in 10:
			var point := local_points[randi() % local_points.size()]
			if actor.global_position.distance_squared_to(point) < 64.0 * 64.0: continue
			var path: PackedVector2Array = host.npc_navigation.ruta(actor.global_position, point)
			if path.is_empty(): continue
			_follow_route(actor, point, path)
			return true
	# Equal chances per sector let small side rooms compete with the wide central
	# corridor. Count both occupants and incoming guests before reserving a goal.
	var loads := {}
	for other in host.get_node("Bots").get_children():
		if other == actor or not is_instance_valid(other): continue
		var sector: Vector2i = host.npc_sector(other.global_position)
		loads[sector] = float(loads.get(sector, 0.0)) + 1.0
		if other.npc_brain.mode == "wander" and other.npc_brain.goal.is_finite():
			var incoming: Vector2i = host.npc_sector(other.npc_brain.goal)
			loads[incoming] = float(loads.get(incoming, 0.0)) + 0.75
	var candidates: Array[Dictionary] = []
	for sector in host.npc_roam_sectors:
		var points: PackedVector2Array = host.npc_roam_sectors[sector]
		var point := points[randi() % points.size()]
		var distance := actor.global_position.distance_to(point)
		if distance < 128.0: continue
		var score := randf_range(0.0, 30.0) - float(loads.get(sector, 0.0)) * 9.0 - distance * 0.008
		for i in recent_sectors.size():
			if recent_sectors[i] == sector: score -= (i + 1) * 7.0
		candidates.append({"point": point, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
	for candidate in candidates:
		var path: PackedVector2Array = host.npc_navigation.ruta(actor.global_position, candidate.point)
		if path.is_empty(): continue
		_follow_route(actor, candidate.point, path)
		roam_sector = host.npc_sector(goal)
		roam_left = randf_range(6.0, 10.0)
		return true
	return false

func _steer(actor: CharacterBody2D, host: Node2D, desired: Vector2) -> Vector2:
	# Sliding past another body can leave a guest closer to scenery than the
	# conservative grid radius. Walk back to clear floor with the real body;
	# a circle cast starting inside that margin cannot plan its own escape.
	var needs_exit: bool = not escape_route.is_empty() or not host.npc_navigation.segmento_libre(actor.global_position, actor.global_position)
	if not needs_exit and route.is_empty(): needs_exit = _connected_floor_cell(host, actor.global_position).x < 0
	if needs_exit:
		var exit_direction := _clearance_escape(actor, host, desired)
		if not exit_direction.is_zero_approx(): return exit_direction
		escape_route.clear()
		# Another guest may leave less than one search step of room. Keep
		# yielding with the real body instead of waiting for eight free pixels.
		return _steer_body(actor, host, desired if not desired.is_zero_approx() else actor.move_direction)
	if desired.is_zero_approx(): return Vector2.ZERO
	return _steer_body(actor, host, desired)

func _steer_body(actor: CharacterBody2D, host: Node2D, desired: Vector2) -> Vector2:
	if desired.is_zero_approx(): return Vector2.ZERO
	# Commit briefly to a safe detour instead of undoing it at the next tick.
	if avoid_left > 0.0 and not steering.is_zero_approx() and not actor.test_move(actor.global_transform, steering * 12.0):
		return steering
	var separation := Vector2.ZERO
	for other in neighbours:
		if not is_instance_valid(other): continue
		# Passing-side avoidance cannot reveal a hidden Camaleón before perception.
		# Physical body collisions still apply unchanged.
		if not actor.is_infected and other.is_infected and not actor.percibe_infectado(other, SENSE_RADIUS): continue
		var offset: Vector2 = actor.global_position - other.global_position
		var distance := offset.length()
		if distance < 40.0 and distance > 0.1:
			separation += offset / distance * (1.0 - distance / 40.0)
		# Common passing side makes two approaching guests yield consistently.
		if distance < 64.0 and distance > 0.1 and desired.dot(-offset / distance) > 0.65 and other.velocity.dot(desired) < 0.0:
			separation += desired.orthogonal() * 0.65
	var preferred := (desired + separation * (2.0 if recovery_left > 0.0 else 1.4)).normalized()
	# A full lookahead can be occupied while a short step is safe. Allow guests
	# to advance out of a dense doorway instead of all waiting for 12 free pixels.
	var candidates := PackedVector2Array()
	for angle in [0.0, 0.45, -0.45, 0.9, -0.9, 1.5, -1.5, 2.2, -2.2, PI]:
		candidates.append(preferred.rotated(angle))
	if recovery_left > 0.0 or route.is_empty():
		# Tight gaps can require an exact wall tangent. Rotations of the goal
		# direction alone may miss that tangent and reject every physical step.
		for i in 8: candidates.append(Vector2.RIGHT.rotated(float(i) * TAU / 8.0))
	# Prefer a complete safe detour over repeatedly pushing a tiny distance
	# toward an occupied goal. Short steps are only the final escape option.
	for lookahead in [12.0, 4.0, 1.5]:
		var best := -INF
		var result := Vector2.ZERO
		for candidate in candidates:
			var motion: Vector2 = candidate * lookahead
			if not host.npc_navigation.limites.grow(-20.0).has_point(actor.global_position + motion): continue
			if actor.test_move(actor.global_transform, motion): continue
			# Preserve heading gently, without vetoing the backward step that
			# lets a guest clear a crowded doorway or release another body.
			var score := candidate.dot(desired) + candidate.dot(preferred) * 0.65 + candidate.dot(steering) * (0.0 if recovery_left > 0.0 else 0.25)
			if score > best:
				best = score
				result = candidate
		if not result.is_zero_approx():
			if result.dot(desired) < 0.1: avoid_left = 0.35
			return result
	return Vector2.ZERO

func _clearance_escape(actor: CharacterBody2D, host: Node2D, desired: Vector2) -> Vector2:
	if escape_left <= 0.0:
		escape_left = 0.4
		if escape_route.is_empty() or actor.test_move(actor.global_transform, escape_route[0] - actor.global_position):
			escape_route = _find_clearance_exit(actor, host, desired)
	if escape_route.is_empty(): return Vector2.ZERO
	var motion := escape_route[0] - actor.global_position
	if actor.test_move(actor.global_transform, motion): return Vector2.ZERO
	var interval_distance: float = actor.speed * actor.multiplicador_velocidad_temp * actor.obtener_multiplicador_velocidad() * 0.12
	return motion.normalized() * minf(1.0, motion.length() / maxf(1.0, interval_distance))

func _connected_floor_cell(host: Node2D, point: Vector2) -> Vector2i:
	if host.npc_navigation.segmento_libre(point, point):
		var cell: Vector2i = host.npc_navigation._celda_accesible(point)
		if cell.x >= 0 and host.npc_destinations.has(host.npc_navigation.cuadricula.get_point_position(cell)):
			return cell
	return Vector2i(-1, -1)

func _find_clearance_exit(actor: CharacterBody2D, host: Node2D, desired: Vector2) -> PackedVector2Array:
	# A short physical search can turn around a furniture corner; a single ray
	# to open floor cannot. These are queries, never position changes.
	var pending: Array[Vector2i] = [Vector2i.ZERO]
	var parents := {Vector2i.ZERO: Vector2i.ZERO}
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
	directions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).dot(desired) > Vector2(b).dot(desired))
	var index := 0
	while index < pending.size() and index < 1024:
		var cell := pending[index]
		index += 1
		var point := actor.global_position + Vector2(cell) * 8.0
		var grid_cell := _connected_floor_cell(host, point) if cell != Vector2i.ZERO else Vector2i(-1, -1)
		var endpoint: Vector2 = host.npc_navigation.cuadricula.get_point_position(grid_cell) if grid_cell.x >= 0 else Vector2.INF
		var transform := actor.global_transform
		transform.origin = point
		if endpoint.is_finite() and not actor.test_move(transform, endpoint - point):
			var path := PackedVector2Array()
			while cell != Vector2i.ZERO:
				path.insert(0, actor.global_position + Vector2(cell) * 8.0)
				cell = parents[cell]
			# Finish at the centre of connected floor, rather than a marginal
			# point that can project back onto an isolated cell after rounding.
			path.append(endpoint)
			return path
		for offset in directions:
			var next := cell + offset
			if parents.has(next) or absi(next.x) > 32 or absi(next.y) > 32: continue
			var next_point := actor.global_position + Vector2(next) * 8.0
			if not host.npc_navigation.limites.grow(-20.0).has_point(next_point): continue
			if actor.test_move(transform, Vector2(offset) * 8.0): continue
			parents[next] = cell
			pending.append(next)
	return PackedVector2Array()

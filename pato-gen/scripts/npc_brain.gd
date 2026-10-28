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
	if decision_left <= 0.0:
		decision_left = 0.20 + float(actor.get_instance_id() % 7) * 0.013
		_sense(actor, host)
		_decide(actor, host)
	_update_progress(actor, delta)
	if progress_time >= 0.9:
		var travelled := actor.global_position.distance_to(progress_origin)
		progress_time = 0.0
		progress_origin = actor.global_position
		if travelled < 14.0:
			recoveries += 1
			recovery_left = 2.8
			_choose_floor(actor, host, true)
	if route.is_empty() or route_left <= 0.0:
		if goal.is_finite(): route = host.npc_navigation.ruta(actor.global_position, goal)
		route_left = REPLAN_SECONDS + float(actor.get_instance_id() % 9) * 0.025
		if route.is_empty():
			_choose_floor(actor, host, true)
			if goal.is_finite(): route = host.npc_navigation.ruta(actor.global_position, goal)
	while not route.is_empty() and actor.global_position.distance_squared_to(route[0]) < 49.0:
		route.remove_at(0)
	# Skip only corners that the complete body can safely clear.
	if route.size() > 1 and host.npc_navigation.segmento_libre(actor.global_position, route[1]):
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
	var closest: Node2D
	var best := INF
	for other in host.get_node("Bots").get_children():
		if other == actor or not is_instance_valid(other): continue
		var distance: float = actor.global_position.distance_squared_to(other.global_position)
		if distance < 110.0 * 110.0: neighbours.append(other)
		if distance > SENSE_RADIUS * SENSE_RADIUS: continue
		if other.is_infected == actor.is_infected: continue
		# Walls and pools block perception; guests do not react through them.
		if not host.npc_navigation.segmento_libre(actor.global_position, other.global_position): continue
		if not actor.is_infected: threats.append(other)
		elif distance < best:
			best = distance
			closest = other
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
	if recovery_left > 0.0: return
	var prey: Node2D = target.get_ref() if target != null else null
	if actor.is_infected and is_instance_valid(prey) and not prey.is_infected:
		mode = "chase"
		if not goal.is_finite() or goal.distance_squared_to(prey.global_position) > 24.0 * 24.0:
			goal = prey.global_position
			route_left = 0.0
		return
	if not actor.is_infected and not threats.is_empty():
		if mode != "flee" or route_left <= 0.0 or route.is_empty():
			_choose_floor(actor, host, false)
		mode = "flee"
		return
	# The active distortion still attracts healthy guests, now along clear floor.
	if not actor.is_infected:
		for zone in actor.get_tree().get_nodes_in_group("zonas_temperatura"):
			if zone.get("tipo") == 0 and actor in zone.cuerpos_dentro:
				if actor.global_position.distance_squared_to(zone.global_position) > 22.0 * 22.0:
					mode = "distortion"
					goal = zone.global_position
					return
	if mode != "wander" or not goal.is_finite() or actor.global_position.distance_squared_to(goal) < 24.0 * 24.0:
		mode = "wander"
		_choose_floor(actor, host, false)

func _choose_floor(actor: Node2D, host: Node2D, recovery: bool) -> void:
	var points: PackedVector2Array = host.npc_destinations
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
		goal = chosen
		route = chosen_route
		route_left = REPLAN_SECONDS

func _steer(actor: CharacterBody2D, host: Node2D, desired: Vector2) -> Vector2:
	if desired.is_zero_approx(): return Vector2.ZERO
	var separation := Vector2.ZERO
	for other in neighbours:
		if not is_instance_valid(other): continue
		var offset: Vector2 = actor.global_position - other.global_position
		var distance := offset.length()
		if distance < 40.0 and distance > 0.1:
			separation += offset / distance * (1.0 - distance / 40.0)
		# Common passing side makes two approaching guests yield consistently.
		if distance < 70.0 and distance > 0.1 and desired.dot(-offset / distance) > 0.65:
			separation += desired.orthogonal() * 0.65
	var preferred := (desired + separation * (2.0 if recovery_left > 0.0 else 1.4)).normalized()
	# A full lookahead can be occupied while a short step is safe. Allow guests
	# to advance out of a dense doorway instead of all waiting for 12 free pixels.
	for lookahead in [12.0, 4.0, 1.5]:
		var best := -INF
		var result := Vector2.ZERO
		for angle in [0.0, 0.45, -0.45, 0.9, -0.9, 1.5, -1.5, 2.2, -2.2, PI]:
			var candidate := preferred.rotated(angle)
			var motion: Vector2 = candidate * lookahead
			if not host.npc_navigation.limites.grow(-20.0).has_point(actor.global_position + motion): continue
			if actor.test_move(actor.global_transform, motion): continue
			var score := candidate.dot(desired) + candidate.dot(preferred) * 0.65
			if score > best:
				best = score
				result = candidate
		if not result.is_zero_approx(): return result
	return Vector2.ZERO

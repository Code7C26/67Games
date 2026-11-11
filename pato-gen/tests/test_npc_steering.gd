extends SceneTree
## Regression: a body sliding outside the grid margin must walk back out.
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS " if ok else "FAIL ", message)
	if not ok: failures += 1

func run() -> void:
	seed(128)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var host = load("res://scenes/Laboratorio.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if not host.map_is_ready: await host.map_ready
	host.timer_inicio.stop()
	var actor = host.get_node("Bots").get_child(0)
	actor.set_physics_process(false)
	for other in host.get_node("Bots").get_children():
		if other != actor: other.queue_free()
	await physics_frame
	await physics_frame
	# These positions came from real collision slides at lab furniture corners.
	var corners := [Vector2(1682.292, 572.9662), Vector2(927.2822, 390.6407), Vector2(273.5885, 382.9531), Vector2(1589.65, 745.0718), Vector2(1471.331, 768.7168), Vector2(65.44906, 715.0492), Vector2(59.06656, 575.0242), Vector2(1223.689, 723.6977), Vector2(200.8126, 575.4782), Vector2(165.5675, 830.7805), Vector2(59.05843, 574.5374)]
	for point in corners:
		actor.position = point
		actor.npc_brain.reset()
		actor.velocity = Vector2.ZERO
		host.npc_navigation.actualizar_exclusiones()
		check(not host.npc_navigation.segmento_libre(point, point), "fixture begins outside the conservative navigation margin " + str(point))
		actor.set_physics_process(true)
		var previous: Vector2 = actor.position
		var continuous := true
		for frame in 180:
			await physics_frame
			continuous = continuous and actor.position.distance_to(previous) < 3.0
			previous = actor.position
		actor.set_physics_process(false)
		if actor.position.distance_to(point) <= 40.0:
			print("CORNER_DIAGNOSTIC position ", actor.position, " legacy ", actor.move_direction, " escape ", actor.npc_brain.escape_route, " goal ", actor.npc_brain.goal)
			for i in 16:
				var motion := Vector2.RIGHT.rotated(float(i) * TAU / 16.0) * 1.5
				var collision := KinematicCollision2D.new()
				var blocked: bool = actor.test_move(actor.global_transform, motion, collision)
				print("CORNER_MOTION ", motion, " blocked ", blocked, " collider ", collision.get_collider() if blocked else null)
		check(actor.position.distance_to(point) > 40.0, "guest walks away from the furniture corner " + str(point))
		check(continuous, "corner recovery is physical and continuous " + str(point))
		check(host.npc_navigation.segmento_libre(actor.position, actor.position), "guest returns to navigable floor " + str(point))
	actor.controlado_por_jugador = true
	var input := Vector2(0.3, -0.8)
	check(actor._map_direction(1.0 / 60.0, input) == input, "possession preserves the player's exact input")
	check(actor._map_direction(1.0 / 60.0, Vector2.ZERO) == Vector2.ZERO, "a possessed guest stays still without input")
	actor.controlado_por_jugador = false
	actor.set_physics_process(true)
	await physics_frame
	paused = true
	var paused_position: Vector2 = actor.position
	for frame in 4: await process_frame
	check(actor.position == paused_position, "navigation respects pause")
	paused = false
	host.queue_free()
	await process_frame
	await physics_frame
	print("NPC_STEERING ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)

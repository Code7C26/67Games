extends SceneTree
## Run headless with --script res://tests/test_duck_map_bounds.gd -- --onboarding-test
var passed := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func within(point: Vector2, bounds: Rect2) -> bool:
	return point.x >= bounds.position.x - 0.01 and point.y >= bounds.position.y - 0.01 and point.x <= bounds.end.x + 0.01 and point.y <= bounds.end.y + 0.01

func press(code: Key, held: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = held
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	for map_name in ["Shopping", "Laboratorio", "PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		var host = load("res://scenes/" + map_name + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready:
			await host.map_ready
		host.timer_inicio.stop()
		host.set_process(false)
		host.set_physics_process(false)
		for bot in get_nodes_in_group("bots"):
			bot.set_physics_process(false)
			bot.get_node("TimerCambioRumbo").stop()
		host.timer_juego.stop()
		var bounds: Rect2 = host.get_meta("bounds")
		var outside := [bounds.position - Vector2(1000, 1000), bounds.end + Vector2(1000, 1000), Vector2(bounds.position.x - 1000, bounds.end.y + 1000), Vector2(bounds.end.x + 1000, bounds.position.y - 1000)]
		for duck in get_nodes_in_group("patos"):
			duck.set_physics_process(false)
			for ghost in [false, true]:
				if ghost:
					duck.convertirse_en_fantasma()
				var label := "%s team %d %s" % [map_name, duck.player_id, "ghost" if ghost else "alive"]
				var margin: float = duck.MARGEN_MAPA_FANTASMA if ghost else duck.MARGEN_MAPA_VIVO
				var safe := bounds.grow(-margin)
				var all_inside := true
				for point in outside:
					duck.global_position = host.to_global(point)
					duck.velocity = Vector2(300, 300)
					duck._physics_process(1.0 / 60.0)
					all_inside = all_inside and within(host.to_local(duck.global_position), safe)
				check(all_inside, label + " recovers all four escaped corners with sprite margin")
				var keys := [KEY_A, KEY_D, KEY_W, KEY_S] if duck.player_id == 1 else [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
				var directions := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
				all_inside = true
				var input_matches := true
				for i in 4:
					duck.global_position = host.to_global(safe.get_center() + directions[i] * safe.size * 0.5)
					duck.velocity = Vector2.ZERO
					press(keys[i], true)
					input_matches = input_matches and duck.obtener_input_jugador().is_equal_approx(directions[i])
					for tick in 30:
						duck._physics_process(1.0 / 60.0)
						all_inside = all_inside and within(host.to_local(duck.global_position), safe)
					press(keys[i], false)
				check(all_inside, label + " held movement cannot cross any outer edge")
				check(input_matches, label + " exercises the real directional key state")
				if ghost:
					duck.global_position = host.to_global(bounds.get_center())
					duck.velocity = Vector2.ZERO
					duck._physics_process(1.0 / 60.0)
					check(duck.collision_layer == 0 and duck.collision_mask == 0 and duck.global_position.is_equal_approx(host.to_global(bounds.get_center())), label + " keeps free movement through the interior")
			duck.global_position = host.to_global(outside[0])
			duck.visible = false
			duck.finalizar_posesion()
			check(duck.visible and within(host.to_local(duck.global_position), bounds.grow(-duck.MARGEN_MAPA_FANTASMA)), map_name + " released ghost returns inside immediately for team " + str(duck.player_id))
		host.queue_free()
		await process_frame
		await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	print("DUCK MAP BOUNDS RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)

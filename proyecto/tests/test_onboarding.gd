extends SceneTree
const Profile = preload("res://patogen_onboarding/profile.gd")
const GenericBridge = preload("res://patogen_onboarding/bridge.gd")
const Director = preload("res://patogen_onboarding/director.gd")
const Rig = preload("res://patogen_onboarding/cinematic_camera.gd")
var checks: Array[Dictionary] = []
var failures := 0
var boot: Node
var host: Node
var director: Node
var camera_home_position: Vector2
var camera_home_zoom: Vector2

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, name: String) -> void:
	checks.append({"test": name, "passed": condition})
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + name)

func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout

func wait_state(wanted: String, limit: float = 8.0) -> bool:
	var started := Time.get_ticks_msec()
	while director.state != wanted and Time.get_ticks_msec() - started < limit * 1000:
		await process_frame
	return director.state == wanted

func fresh_profile(name: String) -> RefCounted:
	var profile := Profile.new()
	profile.path = "res://tests/run_data/%s.cfg" % name
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(profile.path + suffix):
			DirAccess.remove_absolute(profile.path + suffix)
	return profile

func new_match(mode: String = "tutorial") -> void:
	if is_instance_valid(host):
		host.free()
		await process_frame
	paused = false
	boot.requested_mode = mode
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	await process_frame
	await process_frame
	director = host.get_node("PatogenIntroduction")
	director.presentation_speed = 25
	camera_home_position = host.get_node("Camera2D").position
	camera_home_zoom = host.get_node("Camera2D").zoom

func restored(label: String) -> void:
	var camera: Camera2D = host.get_node("Camera2D")
	check(camera.is_current() and camera.position == camera_home_position and camera.zoom == camera_home_zoom, label + ": gameplay camera restored")
	check(not host.get_node("TimerInicio").paused and not host.get_node("TimerJuego").paused, label + ": clocks restored")
	check(host.is_processing_unhandled_input() and host.get_node("Patos/Pato").is_physics_processing(), label + ": inputs restored")
	check(host.get_node("HUD").visible and host.get_node("HUD_ADN").visible and not director.ui.blocker.visible, label + ": HUD and overlay restored")
	check(not root.has_meta("patogen_intro_managed"), label + ": no stale global lock")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/run_data")
	boot = root.get_node("PatogenOnboarding")
	boot.profile = fresh_profile("first_visit")
	check(boot.profile.is_new(), "1 first launch is detected")
	await new_match("auto")
	check(director.state == "overview", "1 first launch starts introduction")
	check(not host.get_node("Patos/Pato").is_physics_processing(), "cinematic blocks polled movement")
	director.skip()
	director.skip()
	await process_frame
	restored("3 early skip")
	check(boot.profile.data.last_result == "skipped", "3 skipping saved")
	await new_match("auto")
	check(director.state == "idle", "4 second match goes directly to gameplay")
	restored("4 normal match")
	director.replay()
	check(director.state == "move", "5 voluntary replay works in a running match")
	director.skip()
	await new_match("tutorial")
	check(await wait_state("explosion"), "cinematic reaches actual duck animation")
	director.skip()
	await process_frame
	check(host.get_node("Patos/Pato").esta_desapareciendo, "3 mid-explosion skip preserves animation")
	await wait_seconds(1.6)
	check(host.estado_actual == 1, "3 mid-explosion skip completes infection after animation")
	var total: int = host.contagios_cian + host.contagios_magenta
	for duck in host.get_node("Patos").get_children():
		duck.infectar_y_desaparecer()
	check(host.contagios_cian + host.contagios_magenta == total, "9 repeated explosion does not duplicate infections")
	restored("3 mid-explosion skip")
	await new_match("tutorial")
	# Close before tutorial_started records the initial panel state.
	host.panel_cian.hide()
	check(await wait_state("move"), "2 cinematic completes into interactive tutorial")
	check(host.contagios_cian >= 1 and host.contagios_magenta >= 1, "2 both players infected real NPCs")
	check(host.get_node("Camera2D").is_current(), "8 overview restored before interactive actions")
	# Exercise the actual input path, not a synthetic tutorial-success event.
	var movement := InputEventKey.new()
	movement.keycode = KEY_D
	movement.physical_keycode = KEY_D
	movement.pressed = true
	Input.parse_input_event(movement)
	await wait_seconds(0.25)
	movement.pressed = false
	Input.parse_input_event(movement)
	check(await wait_state("open", 1), "2 movement is verified from real player displacement")
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	check(await wait_state("buy", 1), "2 E opens real mutations panel")
	# Fixture earns ADN through the real infection function; production never grants ADN.
	for bot in host.get_node("Bots").get_children():
		if host.adn_cian >= 7:
			break
		if not bot.is_infected:
			bot.infectar(Color.CYAN, 1)
	var balance: int = host.adn_cian
	var base: String = host.obtener_ramas_jugador(1)[0][0]
	var price: int = host.obtener_costo_mutacion(base, host.mutaciones_p1)
	host._comprar_rama(1, 0)
	check(host.adn_cian == balance - price, "2 actual purchase spends actual ADN")
	check(await wait_state("observe", 2), "2 successful purchase and application are observed")
	for bot in host.get_node("Bots").get_children():
		if not bot.is_infected:
			bot.infectar(Color.CYAN, 1)
			break
	check(await wait_state("controls", 2), "2 later real infection advances observation")
	director._next()
	check(boot.profile.data.tutorial_completed and boot.profile.data.last_result == "completed", "2 completion saved only after successful actions")
	restored("2 completed")
	var persisted := Profile.new()
	persisted.path = boot.profile.path
	persisted.load_profile()
	check(persisted.data.tutorial_completed and not persisted.is_new(), "2 completion survives profile reload")
	# Crash recovery is written when starting, without relying on a quit callback.
	var interrupted := fresh_profile("crash")
	interrupted.begin()
	var recovered := Profile.new()
	recovered.path = interrupted.path
	recovered.load_profile()
	check(recovered.data.last_result == "interrupted" and not recovered.is_new(), "6 abrupt close is recovered without automatic tutorial loop")
	# Truncated preference recovery uses last known good backup.
	interrupted.finish("skipped")
	var corrupt := FileAccess.open(interrupted.path, FileAccess.WRITE)
	corrupt.store_string("[unterminated")
	corrupt.close()
	recovered.load_profile()
	check(not recovered.is_new(), "6 corrupted preferences recover from backup")
	# External pause belongs to the host, not to the onboarding module.
	director.replay()
	paused = true
	director.skip()
	check(paused, "9 skipping preserves external pause ownership")
	paused = false
	await new_match("tutorial")
	director.ui.motion.set_pressed(true)
	check(director.rig.reduced_motion and host.get_node("Camera2D").is_current(), "reduced motion immediately restores overview")
	director.skip()
	boot.profile.data.reduced_motion = false
	# Generic host with no characters, camera, economy or game state.
	host.free()
	await process_frame
	host = Node2D.new()
	root.add_child(host)
	current_scene = host
	var adapter := GenericBridge.new()
	host.add_child(adapter)
	director = Director.new()
	host.add_child(director)
	director.configure(adapter, fresh_profile("empty_host"))
	director.presentation_speed = 50
	director.start("tutorial")
	check(await wait_state("controls", 3), "7 absent mechanics do not block the tutorial")
	director._next()
	check(director.profile.data.last_result == "partial", "7 absent mechanics are not reported as learned")
	# A declared capability that never emits a result also has a bounded fallback.
	adapter.capabilities = {"movement": true}
	director.replay()
	director.elapsed = 41
	await process_frame
	check(director.state == "controls", "7 missing action event has a finite fallback")
	director.skip()
	# Camera rig preserves custom camera properties and respects camera ownership.
	var camera := Camera2D.new()
	host.add_child(camera)
	camera.position = Vector2(83, 91)
	camera.zoom = Vector2(0.7, 0.8)
	camera.offset = Vector2(7, 9)
	camera.position_smoothing_enabled = true
	camera.make_current()
	await process_frame
	var rig := Rig.new()
	host.add_child(rig)
	rig.take_over(camera)
	rig.frame_point(Vector2(1000, 1000), 5, 1)
	rig.shake()
	rig.restore()
	check(camera.position == Vector2(83, 91) and camera.zoom == Vector2(0.7, 0.8) and camera.offset == Vector2(7, 9) and camera.position_smoothing_enabled and camera.is_current(), "8 custom camera configuration unchanged")
	rig.take_over(camera)
	var other := Camera2D.new()
	host.add_child(other)
	other.make_current()
	rig.restore()
	check(other.is_current(), "8 does not steal camera from another system")
	# Scene teardown cleans active controllers and global state.
	await new_match("tutorial")
	host.free()
	await process_frame
	check(not root.has_meta("patogen_intro_managed"), "9 scene change removes global cinematic lock")
	var report := {"engine": Engine.get_version_info().string, "checks": checks, "total": checks.size(), "failures": failures}
	var output := FileAccess.open("res://tests/results.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	output.close()
	print("RESULT: %d checks / %d failures" % [checks.size(), failures])
	quit(1 if failures else 0)

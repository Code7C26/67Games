extends SceneTree
var boot: Node
var host: Node
var director: Node
var output_dir := ""

func _initialize() -> void:
	_run.call_deferred()

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir + "/" + name + ".png")

func wait_state(wanted: String) -> void:
	var start := Time.get_ticks_msec()
	while director.state != wanted and Time.get_ticks_msec() - start < 15000:
		await process_frame

func _run() -> void:
	output_dir = ProjectSettings.globalize_path("res://").path_join("../previews").simplify_path()
	DirAccess.make_dir_recursive_absolute(output_dir)
	boot = root.get_node("PatogenOnboarding")
	boot.profile.data = {"intro_seen": false, "tutorial_completed": false, "last_result": "new", "last_step": "", "reduced_motion": false}
	host = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	await create_timer(0.5).timeout
	await shot("01_menu")
	host.free()
	boot.requested_mode = "tutorial"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	await process_frame
	await process_frame
	director = host.get_node("PatogenIntroduction")
	await create_timer(1.0).timeout
	await shot("02_shopping")
	await wait_state("anticipation")
	await create_timer(0.35).timeout
	await shot("03_paciente_cero")
	await wait_state("explosion")
	await create_timer(0.2).timeout
	await shot("04_explosion")
	await wait_state("infection")
	await create_timer(1).timeout
	await shot("05_primera_infeccion")
	await wait_state("move")
	await create_timer(0.3).timeout
	await shot("06_control")
	var movement := InputEventKey.new()
	movement.keycode = KEY_D
	movement.pressed = true
	Input.parse_input_event(movement)
	await create_timer(0.3).timeout
	movement.pressed = false
	Input.parse_input_event(movement)
	await wait_state("open")
	await create_timer(0.3).timeout
	await shot("07_menu_mutaciones")
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key.pressed = false
	Input.parse_input_event(key)
	await wait_state("buy")
	await create_timer(0.3).timeout
	await shot("08_mutacion_real")
	# Actual logical canvas sizes exercise layout beyond window stretching.
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	await create_timer(0.3).timeout
	await shot("09_960x540")
	root.content_scale_size = Vector2i(1024, 768)
	root.size = Vector2i(1024, 768)
	await create_timer(0.3).timeout
	await shot("10_1024x768")
	director.skip()
	await create_timer(0.2).timeout
	await shot("11_partida")
	host.free()
	quit()

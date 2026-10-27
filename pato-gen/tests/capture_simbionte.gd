extends SceneTree
## Visual fixture only. Grants test resources here, never in production scripts.
var host: Node
const OUTPUT := "res://tests/run_data/simbionte"

func _initialize() -> void:
	run.call_deferred()

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	await create_timer(0.6).timeout
	await shot("capullos_preparacion")
	host._on_timer_inicio_timeout()
	await create_timer(1.8).timeout
	host.adn_cian = 80
	host.adn_magenta = 80
	for _i in range(7):
		host.invertir_simbionte(1)
		host.invertir_simbionte(2)
		host._physics_process(3.0)
	await shot("capullos_inversion")
	for _i in range(5):
		host.invertir_simbionte(1)
		host._physics_process(3.0)
	await shot("eclosion")
	var deadline := Time.get_ticks_msec() + 12000
	var fused: Node2D
	while Time.get_ticks_msec() < deadline and not is_instance_valid(fused):
		for bot in get_nodes_in_group("bots"):
			if is_instance_valid(bot.efecto_simbionte):
				fused = bot
		await physics_frame
	if is_instance_valid(fused):
		await shot("fusion")
		host.get_node("Patos/Pato").iniciar_posesion(fused)
		await create_timer(0.2).timeout
		await shot("fusion_poseida")
		print("CAPTURE fusion and possession rendered")
	else:
		push_error("Capture: no fusion during the observation window")
	paused = false
	host.queue_free()
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer:
			player.stop()
	await process_frame
	await process_frame
	quit()

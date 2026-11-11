extends SceneTree
## Rendered selector fixtures at desktop, compact and 4:3 sizes.
var output := ""
var host: Control

func _initialize() -> void:
	run.call_deferred()

func shot(filename: String) -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	var error := image.save_png(output.path_join(filename + ".png"))
	if error != OK:
		push_error("FAIL capture " + filename)
		quit(1)
	print("CAPTURE ", filename)

func resize_view(dimensions: Vector2i) -> void:
	root.content_scale_size = dimensions
	root.size = dimensions
	for _frame in 6:
		await process_frame

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/character-menu-nov05/previews").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var boot: Node = root.get_node("PatogenOnboarding")
	var old_motion: bool = bool(boot.profile.data.reduced_motion)
	boot.profile.data.reduced_motion = true
	await resize_view(Vector2i(1920, 1080))
	root.set_meta("patogen_cepas", {1: "atletico", 2: "atletico"})
	host = load("res://scenes/character_select.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	await shot("01_selector_atletico_1920x1080")
	host._choose(1, 1)
	host._choose(2, 2)
	await shot("02_selector_area_exponencial_1920x1080")
	await resize_view(Vector2i(1280, 720))
	await shot("03_selector_1280x720")
	await resize_view(Vector2i(960, 540))
	await shot("04_selector_960x540")
	await resize_view(Vector2i(1024, 768))
	await shot("05_selector_1024x768")
	boot.profile.data.reduced_motion = old_motion
	host.free()
	root.get_node("AudioManager").detener_musica()
	await process_frame
	quit()

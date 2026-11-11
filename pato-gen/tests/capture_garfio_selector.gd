extends SceneTree
## Actual rendered Garfio selector and compact layout fixtures.
var output := ""
var host: Control
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + message)
	else:
		print("PASS ", message)

func shot(filename: String) -> void:
	for _frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	check(image.save_png(output.path_join(filename + ".png")) == OK, "capture " + filename)

func resize_view(dimensions: Vector2i) -> void:
	root.content_scale_size = dimensions
	root.size = dimensions
	for _frame in 8:
		await process_frame

func check_layout(dimensions: Vector2i) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0)
	var fit := bounds.encloses(host.continue_button.get_global_rect()) and bounds.encloses(host.back_button.get_global_rect())
	var text_fits := true
	var details_clear := true
	for card in host.cards:
		var card_rect: Rect2 = card.root.get_global_rect().grow(1.0)
		fit = fit and bounds.encloses(card.root.get_global_rect())
		for control in [card.portrait, card.title, card.role, card.advantage, card.challenge] + card.tabs:
			fit = fit and card_rect.encloses(control.get_global_rect())
		for tab in card.tabs:
			text_fits = text_fits and tab.get_combined_minimum_size().x <= tab.size.x + 1
		details_clear = details_clear and card.challenge.get_global_rect().end.y + 4 <= card.tabs_row.get_global_rect().position.y
		check(card.tabs.size() == 6 and card.tabs[3].button_pressed, "Garfio selected in six-tab card " + str(dimensions))
	check(fit, "selector content fits " + str(dimensions))
	check(text_fits, "selector tab labels fit " + str(dimensions))
	check(details_clear, "wrapped details clear strain tabs " + str(dimensions))

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/garfio-ajuste-nov05/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var boot: Node = root.get_node("PatogenOnboarding")
	var old_motion: bool = bool(boot.profile.data.reduced_motion)
	boot.profile.data.reduced_motion = true
	root.set_meta("patogen_cepas", {1: "garfio", 2: "garfio"})
	await resize_view(Vector2i(1920, 1080))
	host = load("res://scenes/character_select.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1024, 768)]:
		await resize_view(dimensions)
		check_layout(dimensions)
		await shot("selector_garfio_%dx%d" % [dimensions.x, dimensions.y])
	var hud_script = load("res://scripts/match_hud.gd")
	var hud: CanvasLayer = hud_script.new()
	var icons := Image.create(216, 24, false, Image.FORMAT_RGBA8)
	icons.fill(Color.TRANSPARENT)
	for i in 9:
		var icon: Texture2D = hud._garfio_icon(int(i / 3.0), i % 3 + 1)
		icons.blit_rect(icon.get_image(), Rect2i(0, 0, 24, 24), Vector2i(i * 24, 0))
	icons.save_png(output.path_join("iconos_garfio.png"))
	hud.free()
	boot.profile.data.reduced_motion = old_motion
	host.free()
	root.get_node("AudioManager").detener_musica()
	await process_frame
	print("GARFIO_SELECTOR ", checks, " checks / ", failures, " failures")
	quit(1 if failures else 0)

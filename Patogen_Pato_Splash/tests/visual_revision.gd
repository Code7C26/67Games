extends Node
## Render comparisons isolate the cloud shader from every other moving element.
var failures: Array[String] = []
var report: Dictionary = {}
var render_view: SubViewport

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func snapshot() -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return render_view.get_texture().get_image()

func font_check(node: Node) -> int:
	var count := 0
	if node is Label or node is Button:
		count = 1
		var font: Font = node.get_theme_font("font")
		check(font.get_font_name() == "Press Start 2P", "Wrong font: " + str(node.get_path()))
		check(font is FontFile and font.antialiasing == TextServer.FONT_ANTIALIASING_NONE, "Font smoothing: " + str(node.get_path()))
		var font_size: int = node.get_theme_font_size("font_size")
		check(font_size % 8 == 0, "Non-integer pixel font scale")
		var width := font.get_string_size(node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		check(width <= node.size.x + 1, "Text clipped: " + node.text)
		check(node.global_position.x + width <= 1912, "Text outside the viewport: " + node.text)
	for child in node.get_children(): count += font_check(child)
	return count

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	render_view = SubViewport.new()
	render_view.size = Vector2i(1920, 1080)
	render_view.world_2d = World2D.new()
	render_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render_view)
	var demo: Node2D = load("res://demo/PatoSplashDemo.tscn").instantiate()
	render_view.add_child(demo)
	demo.map.audio_enabled = false; demo.ambient.stop(); demo.shake_enabled = false
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
	demo.set_process(false)
	var ambience: Node2D = demo.map.get_node("08_Ambiente")
	ambience.elapsed = 0.0; ambience.apply_effects()
	var cloud: ShaderMaterial = ambience.cloud_material
	cloud.set_shader_parameter("intensity", 0.0)
	var clear := await snapshot()
	cloud.set_shader_parameter("intensity", ambience.cloud_intensity)
	var shaded := await snapshot()
	shaded.save_png("res://captures/revision_visual_1920x1080.png")
	clear.save_png("res://captures/revision_nubes_sin.png")
	cloud.set_shader_parameter("ambient_time", 24.0)
	var shifted := await snapshot()
	shifted.save_png("res://captures/revision_nubes_24s.png")
	var visible := 0
	var moved := 0
	var hud_changes := 0
	var max_darkening := 0.0
	for y in 1080:
		for x in 1920:
			var a := clear.get_pixel(x,y)
			var b := shaded.get_pixel(x,y)
			var c := shifted.get_pixel(x,y)
			var darkening := (a.r+a.g+a.b-b.r-b.g-b.b)/3.0
			max_darkening = maxf(max_darkening, darkening)
			if darkening > 0.05: visible += 1
			if absf(b.r-c.r)+absf(b.g-c.g)+absf(b.b-c.b) > 0.12: moved += 1
			if (y < 96 or y >= 992) and a != b: hud_changes += 1
	check(visible > 100000, "Cloud shadows are not clearly visible")
	check(moved > 100000, "Cloud shadows are not moving visibly")
	check(hud_changes == 0, "Cloud shadows affect the HUD")
	check(max_darkening > 0.12, "Cloud shadow contrast is too low")
	report.text_nodes_checked = font_check(demo)
	get_tree().paused = false
	for phase in ["calma", "aviso", "chapuzon", "reposo"]:
		demo._phase(phase, 30.0)
		var event_width: float = demo.font.get_string_size(demo.event_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		check(demo.event_label.position.x + event_width < 1350.0, "Event text overlaps buttons")
		var subtitle_width: float = demo.font.get_string_size(demo.subtitle.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		check(demo.subtitle.position.x + subtitle_width < 1892.0, "Subtitle leaves the viewport")
	report.font = demo.font.get_font_name()
	report.cloud_visible_pixels = visible
	report.cloud_moving_pixels_24s = moved
	report.cloud_max_darkening = max_darkening
	report.hud_pixels_affected = hud_changes
	report.cloud_opacity = ambience.cloud_intensity
	report.render_size = [1920,1080]
	report.passed = failures.is_empty(); report.failures = failures
	var file := FileAccess.open("res://tests/visual_revision_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t")); file.close()
	print("VISUAL_REVISION_VALIDATION ", JSON.stringify(report))
	get_tree().paused = false
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

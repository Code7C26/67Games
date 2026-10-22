extends SceneTree
const Loading = preload("res://patogen_onboarding/loading_screen.gd")
var checks: Array[Dictionary] = []
var failures := 0
var boot: Node
var menu: Control

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, name: String) -> void:
	checks.append({"test": name, "passed": condition})
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + name)

func wait_loading() -> void:
	var start := Time.get_ticks_msec()
	while is_instance_valid(boot.loading_screen) and Time.get_ticks_msec() - start < 15000:
		await process_frame

func _run() -> void:
	boot = root.get_node("PatogenOnboarding")
	menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	check(menu.play.has_focus(), "menu begins with keyboard focus on Play")
	check(menu.play.get_theme_font("font") is FontVariation, "new readable typography applied to menu")
	check(menu.title.text == "PATOGEN", "new menu retains game identity")
	menu._show_guide()
	await process_frame
	check(is_instance_valid(menu.guide_overlay), "View tutorial opens quick guide without starting a match")
	menu._close_guide()
	await process_frame
	check(menu.guide.has_focus(), "closing guide restores keyboard focus")
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1024, 768)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await process_frame
		await process_frame
		var in_bounds := true
		for button in menu.buttons:
			if not Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()):
				in_bounds = false
		check(in_bounds, "menu buttons fit %sx%s" % [dimensions.x, dimensions.y])
		check(menu.exit_button.get_global_rect().end.y + 8 < menu.footer.position.y, "menu content clears footer %sx%s" % [dimensions.x, dimensions.y])
	var old_setting: bool = boot.profile.data.reduced_motion
	menu.motion.button_pressed = not old_setting
	check(bool(boot.profile.data.reduced_motion) != old_setting, "motion preference changes from menu")
	menu.motion.button_pressed = old_setting
	# A missing scene must offer an exit instead of leaving an indefinite overlay.
	var missing := Loading.new()
	root.add_child(missing)
	missing.load_scene("res://missing_scene_for_test.tscn")
	check(not missing.busy and not missing.cancel_button.disabled, "missing scene returns an actionable loading error")
	missing.cancel()
	await process_frame
	check(not is_instance_valid(missing), "loading error can be dismissed")
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	# Exercise threaded loading through the real menu and character selector.
	boot.open_character_selection("tutorial")
	var first: CanvasLayer = boot.loading_screen
	boot.open_character_selection("auto")
	check(boot.loading_screen == first and boot.requested_mode == "tutorial", "double click cannot replace pending tutorial request")
	await wait_loading()
	check(is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("character_select.tscn"), "real loading enters character selection")
	current_scene.indice_cian = 2
	current_scene.indice_magenta = 1
	current_scene._on_comenzar_pressed()
	await wait_loading()
	check(current_scene.scene_file_path.ends_with("Shopping.tscn"), "real loading enters shopping")
	check(current_scene.cepa_cian == "exponencial" and current_scene.cepa_magenta == "area", "loading preserves both strain selections")
	var director: Node = current_scene.get_node("PatogenIntroduction")
	check(director.state != "idle", "tutorial choice survives both transitions")
	director.skip()
	current_scene.estado_actual = 2
	director.replay()
	check(director.state == "idle", "tutorial cannot restart after match end")
	current_scene.estado_actual = 1
	paused = true
	director.replay()
	check(director.state == "idle" and paused, "tutorial cannot interrupt an external pause")
	paused = false
	current_scene.free()
	await process_frame
	var report := {"engine": Engine.get_version_info().string, "checks": checks, "total": checks.size(), "failures": failures}
	var file := FileAccess.open("res://tests/menu_results.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("RESULT: %d checks / %d failures" % [checks.size(), failures])
	root.get_node("AudioManager").detener_musica()
	await create_timer(0.1).timeout
	quit(1 if failures else 0)

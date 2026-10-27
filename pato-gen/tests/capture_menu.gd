extends SceneTree
var folder := ""

func _initialize() -> void:
	_run.call_deferred()

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

func _run() -> void:
	folder = ProjectSettings.globalize_path("res://").path_join("../previews").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(0.5).timeout
	await shot("12_menu_final")
	menu._show_guide()
	await process_frame
	await shot("13_guia_rapida")
	menu._close_guide()
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	await create_timer(0.3).timeout
	await shot("14_menu_960x540")
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	var loading := preload("res://patogen_onboarding/loading_screen.gd").new()
	root.add_child(loading)
	loading.progress.value = 50
	# Layout preview only; functional tests exercise actual ResourceLoader progress.
	await shot("15_diseno_carga")
	loading.cancel()
	menu.free()
	root.get_node("AudioManager").detener_musica()
	await create_timer(0.1).timeout
	quit()

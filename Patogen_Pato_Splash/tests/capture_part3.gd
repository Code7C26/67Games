extends Node
func _ready() -> void:
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var frame_dir := "res://captures/parte3_frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frame_dir))
	var render_view := SubViewport.new()
	render_view.size = Vector2i(1920, 1080)
	render_view.world_2d = World2D.new()
	render_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(render_view)
	var demo: Node2D = load("res://demo/PatoSplashDemo.tscn").instantiate()
	render_view.add_child(demo)
	demo.map.audio_enabled = false; demo.ambient.stop(); demo.shake_enabled = false
	var ambience: Node2D = demo.map.get_node("08_Ambiente")
	for i in 80:
		for tick in 6: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var image := render_view.get_texture().get_image()
		if i == 10: image.save_png("res://captures/parte3_1920x1080.png")
		if i == 45: image.save_png("res://captures/parte3_ambiente.png")
		image.resize(960, 540, Image.INTERPOLATE_NEAREST)
		image.save_png(frame_dir + "/%03d.png" % i)
	# Native comparison of two widely separated cloud positions, same map contents.
	ambience.elapsed = 48.0; ambience.apply_effects()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	render_view.get_texture().get_image().save_png("res://captures/parte3_nubes_48s.png")
	print("PART3_CAPTURE_OK: 80 native frames, 1920x1080 stills, all ambient effects")
	get_tree().quit()

extends Node
func _ready() -> void:
	Engine.max_fps = 60
	var render_view := SubViewport.new(); render_view.size = Vector2i(1920,1080); render_view.world_2d = World2D.new()
	render_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(render_view)
	var demo: Node2D = load("res://demo/PatoSplashDemo.tscn").instantiate(); render_view.add_child(demo)
	demo.map.audio_enabled=false;demo.ambient.stop();demo.shake_enabled=false
	var frame_dir := "res://captures/giro360_frames"; DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frame_dir))
	await get_tree().create_timer(0.6).timeout
	demo._preview_event()
	for i in 90:
		for tick in 6: await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var image := render_view.get_texture().get_image()
		if i==9: image.save_png("res://captures/giro360_aviso.png")
		if i==19: image.save_png("res://captures/giro360_disparo.png")
		if i==28: image.save_png("res://captures/giro360_impacto.png")
		if i==43: image.save_png("res://captures/giro360_charcos.png")
		image.resize(960,540,Image.INTERPOLATE_NEAREST); image.save_png(frame_dir+"/%03d.png"%i)
	print("GIRO360_CAPTURE_OK: ",demo.map.cannon.landing_count," impacts; soaked NPCs: ",demo.map.hit_this_cycle.size())
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

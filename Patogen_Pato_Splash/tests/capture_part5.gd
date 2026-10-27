extends Node
func _ready() -> void:
	Engine.max_fps=60
	var view:=SubViewport.new();view.size=Vector2i(1920,1080);view.world_2d=World2D.new();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	var demo:Node2D=load("res://demo/PatoSplashDemo.tscn").instantiate();view.add_child(demo)
	demo.map.audio_enabled=false;demo.ambient.stop();demo.shake_enabled=false
	DirAccess.make_dir_recursive_absolute("res://captures/parte5_frames")
	for i in 120:
		for tick in 6:await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var im:=view.get_texture().get_image()
		if i==28:im.save_png("res://captures/parte5_parque.png")
		if i==70:im.save_png("res://captures/parte5_servicios.png")
		im.resize(960,540,Image.INTERPOLATE_NEAREST);im.save_png("res://captures/parte5_frames/%03d.png"%i)
	demo.queue_free();await get_tree().process_frame
	var showcase:Node2D=load("res://scenes/asset_showcase.tscn").instantiate();view.add_child(showcase)
	await get_tree().create_timer(0.4).timeout;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://captures/parte5_showcase.png")
	print("PART5_CAPTURE_OK");get_tree().quit()

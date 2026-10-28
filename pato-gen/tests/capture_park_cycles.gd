extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.get_node("PatogenOnboarding").requested_mode="direct"
	var host=load("res://scenes/PatoSplash.tscn").instantiate()
	root.add_child(host);current_scene=host
	await host.map_ready
	host.timer_inicio.stop();host.set_process(false)
	host.get_node("HUD_ADN").hide();host.get_node("HUD").hide()
	for actor in get_nodes_in_group("bots")+get_nodes_in_group("patos"):
		actor.set_physics_process(false)
	var camera:Camera2D=host.get_node("Camera2D")
	camera.position=Vector2(365,322);camera.zoom=Vector2(2,2);camera.force_update_scroll()
	var life=host.get_node("Environment/10_VidaParque")
	life.set_process(false)
	var out:=ProjectSettings.globalize_path("res://../map-captures")
	DirAccess.make_dir_recursive_absolute(out)
	var times: Array[float]=[0,3.18,3.22,5.0,8.0,15.0,life.sliders[0].cycle_duration-0.02,life.sliders[0].cycle_duration+0.02]
	for i in times.size():
		life.clock=times[i];life._slides()
		await process_frame;await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image()
		if root.use_hdr_2d: img.convert(Image.FORMAT_RGBA8);img.linear_to_srgb()
		img.save_png(out+"/slide_%02d.png"%i)
		print("SLIDE_CAPTURE ",i," at ",times[i])
	host.queue_free();await process_frame;quit()

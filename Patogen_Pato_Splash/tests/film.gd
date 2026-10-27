extends Node
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://captures/frames"))
	var view:=SubViewport.new();view.size=Vector2i(1920,1080);view.world_2d=World2D.new();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	var demo=load("res://demo/PatoSplashDemo.tscn").instantiate();view.add_child(demo)
	demo.map.audio_enabled=false;demo.ambient.stop()
	# Real simulation, 15 fps capture; preview invokes the ordinary 8-second warning.
	for i in 210:
		if i==15:demo._preview_event()
		for f in 4:await get_tree().physics_frame
		await RenderingServer.frame_post_draw
		var img:=view.get_texture().get_image()
		if i==14:img.save_png("res://captures/01_pato_splash.png")
		if i==143:img.save_png("res://captures/02_chapuzon.png")
		img.resize(960,540,Image.INTERPOLATE_NEAREST);img.save_png("res://captures/frames/%04d.png"%i)
	demo.hud.hide()
	for actor in get_tree().get_nodes_in_group("splash_visitors"):actor.hide()
	for actor in demo.explorers:actor.hide()
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://captures/05_mapa_limpio.png")
	print("FILM_OK 210 frames")
	get_tree().quit()

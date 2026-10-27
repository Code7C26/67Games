extends Node
func _ready() -> void:
	var view:=SubViewport.new();view.size=Vector2i(1920,1080);view.world_2d=World2D.new();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	var scene=load("res://demo/PatoSplashDemo.tscn").instantiate();view.add_child(scene)
	for i in 80:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://captures/01_pato_splash.png")
	scene.map.phase="chapuzon";scene.map.elapsed=.6;scene.map.paused=true;scene.map._update_effects();scene._phase("chapuzon",1.4)
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://captures/02_chapuzon.png")
	scene.map.phase="calma";scene.map.elapsed=0;scene.map._update_effects();scene.hud.hide()
	for actor in get_tree().get_nodes_in_group("splash_visitors"):actor.hide()
	for actor in scene.explorers:actor.hide()
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_png("res://captures/05_mapa_limpio.png")
	print("CAPTURE_OK 3 frames 1920x1080")
	get_tree().quit()

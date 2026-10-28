extends SceneTree
var failures:=0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message:String) -> void:
	if not ok: failures+=1;push_error(message)
	else: print("PASS ",message)
func loaded() -> void:
	var boot=root.get_node("PatogenOnboarding")
	var deadline:=Time.get_ticks_msec()+15000
	while is_instance_valid(boot.loading_screen) and Time.get_ticks_msec()<deadline: await process_frame
	check(not is_instance_valid(boot.loading_screen),"Loading finishes")
func run() -> void:
	var boot=root.get_node("PatogenOnboarding")
	root.set_meta("patogen_cepas",{1:"area",2:"exponencial"})
	for index in 3:
		boot.requested_mode="direct"
		change_scene_to_file("res://scenes/map_select.tscn")
		await scene_changed
		var selector=current_scene
		selector._select(index)
		var expected: String=selector.MAPS[index].scene
		selector._launch()
		await loaded()
		check(current_scene.scene_file_path.ends_with(expected+".tscn"),"Selector launches "+expected)
		check(current_scene.cepa_cian=="area" and current_scene.cepa_magenta=="exponencial","Strains reach "+expected)
		current_scene.timer_inicio.stop()
		check(current_scene.contar_infecciones().total==65,"Full population before reveal in "+expected)
		current_scene._on_timer_juego_timeout()
		boot.requested_mode="direct"
		current_scene.game_over_screen._on_reiniciar_button_pressed()
		await scene_changed
		if current_scene.has_signal("map_ready") and not current_scene.map_is_ready: await current_scene.map_ready
		current_scene.timer_inicio.stop()
		check(not paused and current_scene.scene_file_path.ends_with(expected+".tscn"),"Restart retains "+expected)
		check(current_scene.contar_infecciones().total==65 and current_scene.adn_cian==0,"Restart resets population and economy")
		current_scene.game_over_screen._on_menu_button_pressed()
		await scene_changed
		check(current_scene.scene_file_path.ends_with("main_menu.tscn") and get_nodes_in_group("bots").is_empty(),"Menu releases "+expected)
	print("MAP_FLOW 3 selector launches + 3 restarts + 3 menu returns / ",failures," failures")
	quit(1 if failures else 0)

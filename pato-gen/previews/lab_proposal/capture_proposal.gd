extends SceneTree
var failures:=0
func verify(ok: bool,message: String) -> void:
	if not ok: failures+=1;push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1920,1080)
	root.get_node("PatogenOnboarding").requested_mode="direct"
	root.get_node("PatogenOnboarding").profile.data.reduced_motion="reduced" in OS.get_cmdline_user_args()
	seed(20261028)
	var host=load("res://previews/lab_proposal/LabProposal.tscn").instantiate()
	root.add_child(host)
	current_scene=host
	if not host.map_is_ready: await host.map_ready
	host.timer_inicio.stop()
	for actor in get_nodes_in_group("bots"):
		actor.set_physics_process(false)
		actor.timer_direccion.stop()
	for actor in get_nodes_in_group("patos"): actor.set_physics_process(false)
	for i in 20: await process_frame
	var environment=host.get_node("Environment")
	verify(environment.fixtures.size()==28,"All twenty-eight annotation marks have a ceiling light")
	var reference_points: Array[Vector2]=[
		Vector2(331,164),Vector2(598,159.5),Vector2(778,230),Vector2(951,233),
		Vector2(326,283),Vector2(596,282),Vector2(1250,263),Vector2(1470,271),
		Vector2(346,405),Vector2(532.5,402),Vector2(689,402),Vector2(865,399),
		Vector2(1057,399),Vector2(1229,400),Vector2(1411,396),Vector2(1595,397),
		Vector2(440,563.5),Vector2(739.5,569),Vector2(935.5,578),Vector2(1221.5,575),Vector2(1525.5,570),
		Vector2(349.5,757),Vector2(490,755),Vector2(701,760),Vector2(934,760),
		Vector2(1131,757),Vector2(1514,753.5),Vector2(1304,766)]
	var maximum_mark_error:=0.0
	for index in mini(reference_points.size(),environment.fixtures.size()):
		var light: PointLight2D=environment.fixtures[index].light
		var actual: Vector2=light.get_global_transform_with_canvas().origin
		maximum_mark_error=maxf(maximum_mark_error,actual.distance_to(reference_points[index]))
		verify(light.shadow_enabled and light.shadow_item_cull_mask==4,"Marked ceiling lights retain wall occlusion")
	verify(maximum_mark_error<1.5,"Light centers match the marked screenshot")
	verify(environment.ceiling_wall_occluders==36,"All thirty-six original and new wall volumes block the ceiling lights")
	verify(host.timer_inicio.wait_time==3 and host.timer_juego.wait_time==120,"Match timings stay unchanged")
	var new_floor_positions:=0
	for point in host.npc_destinations:
		if point.y>880: new_floor_positions+=1
	verify(new_floor_positions>0,"The new floor must connect to the playable map")
	var connected_doors:=0
	for x in [368.0,816.0,1288.0,1696.0]:
		var destination:=Vector2(x,1032)
		verify(host.npc_navigation.segmento_libre(destination,destination),"NPCs have space behind the equipment at x="+str(x))
		var path: PackedVector2Array=host.npc_navigation.ruta(Vector2(x,816),destination)
		verify(not path.is_empty(),"Lower room must connect through door at x="+str(x))
		if not path.is_empty(): connected_doors+=1
	verify(not host.npc_navigation.segmento_libre(Vector2(464,916),Vector2(560,916)),"New room walls block bodies")
	var incubator_lights:=0
	for light in environment.equipment_lights:
		if "Incubadora" in str(light.name):
			verify(light.color.b>=light.color.r and light.color.r>=light.color.g,"Incubators must emit white/UV, never green")
			incubator_lights+=1
	verify(incubator_lights==3,"Three incubators emit white/UV")
	if "reduced" in OS.get_cmdline_user_args():
		for sprite in environment.preview_incubators: verify(not sprite.is_playing(),"Reduced motion freezes incubator animation")
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if root.use_hdr_2d:
		image.convert(Image.FORMAT_RGBA8)
		image.linear_to_srgb()
	var output:="res://previews/lab_proposal/renders/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var suffix:="reduced" if "reduced" in OS.get_cmdline_user_args() else "full"
	var error:=image.save_png(output+"Laboratorio_propuesta_"+suffix+".png")
	print("CAPTURE PROPOSAL ",error," bots=",get_nodes_in_group("bots").size()," bounds=",host.get_meta("bounds")," lights=",environment.fixtures.size()," mark_error_px=",maximum_mark_error," wall_occluders=",environment.ceiling_wall_occluders," UV_incubators=",incubator_lights," reachable_extension_cells=",new_floor_positions," connected_doors=",connected_doors," failures=",failures)
	if "benchmark" in OS.get_cmdline_user_args():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps=0
		for actor in get_nodes_in_group("bots"):
			actor.set_physics_process(true)
			actor.timer_direccion.start()
		for i in 100: await process_frame
		var begin:=Time.get_ticks_usec()
		var previous:=begin
		var frame_times: Array[float]=[]
		for i in 360:
			await process_frame
			var now:=Time.get_ticks_usec()
			frame_times.append((now-previous)/1000.0)
			previous=now
		var seconds: float=(Time.get_ticks_usec()-begin)/1000000.0
		frame_times.sort()
		print("CAPTURE BENCHMARK active_bots=",get_nodes_in_group("bots").size()," average_fps=",360.0/seconds," p95_ms=",frame_times[342]," maximum_ms=",frame_times[-1])
	host.queue_free()
	for i in 3: await process_frame
	quit(error if error else (1 if failures else 0))

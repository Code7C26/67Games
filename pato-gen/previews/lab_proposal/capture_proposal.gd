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
	verify(environment.fixtures.size()==16,"Sixteen ceiling lights")
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
	print("CAPTURE PROPOSAL ",error," bots=",get_nodes_in_group("bots").size()," bounds=",host.get_meta("bounds")," lights=",environment.fixtures.size()," UV_incubators=",incubator_lights," reachable_extension_cells=",new_floor_positions," connected_doors=",connected_doors," failures=",failures)
	host.queue_free()
	for i in 3: await process_frame
	quit(error if error else (1 if failures else 0))

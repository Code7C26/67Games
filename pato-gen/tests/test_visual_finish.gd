extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
	else: print("PASS ",message)
func run() -> void:
	root.size = Vector2i(1920,1080)
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		for reduced in [false,true]:
			var boot := root.get_node("PatogenOnboarding")
			boot.requested_mode = "direct"
			boot.profile.data.reduced_motion = reduced
			seed(20261028)
			var host = load("res://scenes/"+map_name+".tscn").instantiate()
			root.add_child(host)
			current_scene = host
			if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
			host.timer_inicio.stop()
			for actor in get_nodes_in_group("bots"):
				actor.set_physics_process(false)
				actor.timer_direccion.stop()
			for actor in get_nodes_in_group("patos"): actor.set_physics_process(false)
			for i in 4: await process_frame
			var finish = host.find_child("SceneryFinish",true,false)
			check(finish != null,map_name+" visual finish is attached")
			check(get_nodes_in_group("bots").size()==65,map_name+" population unchanged")
			check(host.timer_inicio.wait_time==3.0 and host.timer_juego.wait_time==120.0,map_name+" match durations unchanged")
			if map_name=="PatoSplash":
				check(finish.reflection_count>0 and finish.glare_count>0 and finish.water_count==4,map_name+" outdoor water reflections preserved")
			else:
				check(finish.reflection_count==0 and finish.glare_count==0,map_name+" no unmotivated prop reflections or glass sweeps")
			check(finish.occluder_count>0 and finish.occluder_count<=finish.max_occluders,map_name+" bounded static light occluders")
			check(finish.find_children("*","CollisionObject2D",true,false).is_empty(),map_name+" effects create no physics bodies")
			var lighting_safe := true
			for light in finish.local_lights: lighting_safe = lighting_safe and light.range_item_cull_mask==2
			check(lighting_safe,map_name+" lights only target scenery mask")
			var actors_safe := true
			for actor in get_nodes_in_group("bots"):
				actors_safe = actors_safe and actor.animated_sprite.modulate==Color.WHITE and actor.animated_sprite.light_mask==(5 if map_name=="Laboratorio" else 1)
				actors_safe = actors_safe and actor.material_borde_infeccion.shader.resource_path=="res://shaders/npc_outline.gdshader"
				actors_safe = actors_safe and actor.animated_sprite.sprite_frames.get_meta("outline_padding",false)
				actors_safe = actors_safe and is_equal_approx(actor.get_node("ContactShadow").color.a,0.38)
			check(actors_safe,map_name+" NPC outlines, padding, colors and contact shadows preserved")
			var modulates_safe := true
			for node in host.find_children("*","CanvasModulate",true,false): modulates_safe = modulates_safe and node.color==Color.WHITE
			check(modulates_safe,map_name+" no global darkening")
			var before: float = finish.effect_time
			var count_before := get_node_count()
			for i in 30: await process_frame
			check((finish.effect_time==before) if reduced else (finish.effect_time>before),map_name+" reduced motion="+str(reduced)+" controls shader clocks")
			check(get_node_count()==count_before,map_name+" no per-frame node allocation")
			boot.profile.data.reduced_motion = true
			for i in 3: await process_frame
			before = finish.effect_time
			for i in 6: await process_frame
			check(finish.effect_time==before,map_name+" preference toggle freezes new effects")
			boot.profile.data.reduced_motion = false
			for i in 6: await process_frame
			check(finish.effect_time>before,map_name+" preference toggle resumes new effects")
			host.queue_free()
			for i in 4: await process_frame
			check(get_nodes_in_group("bots").is_empty(),map_name+" actors released on map exit")
	print("VISUAL_TESTS ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

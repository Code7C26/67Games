extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS ",message)
	else: failures+=1;push_error(message)
func run() -> void:
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode="direct"
		root.get_node("PatogenOnboarding").profile.data.reduced_motion=false
		seed(20261028)
		var host=load("res://scenes/"+map_name+".tscn").instantiate()
		root.add_child(host)
		current_scene=host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		for i in 4: await process_frame
		var finish=host.find_child("SceneryFinish",true,false)
		check(get_nodes_in_group("bots").size()==65,map_name+" retains 65 guests")
		check(host.timer_inicio.wait_time==3 and host.timer_juego.wait_time==120,map_name+" retains phase durations")
		var particles=finish.get_node("AmbientParticles")
		check(particles.emitters.size()>=3 and particles.emitters.size()<=4,map_name+" bounded ambient emitter pool")
		var count:=get_node_count()
		for i in 10: await process_frame
		check(get_node_count()==count,map_name+" no particle node allocations per frame")
		root.get_node("PatogenOnboarding").profile.data.reduced_motion=true
		for i in 3: await process_frame
		var quiet:=true
		for emitter in particles.emitters: quiet=quiet and emitter.speed_scale==0 and not emitter.visible
		check(quiet,map_name+" reduced motion freezes ambient particles")
		if map_name=="Shopping":
			var image:Image=finish.sunlight_mask.get_image()
			var forbidden:=0
			var common:=0
			for layer in host.get_node("Pisos").get_children():
				if not layer is TileMapLayer or str(layer.name)=="DesgasteDiscreto":continue
				var allowed:bool=str(layer.name) in ["Pasillos","Accesos","Atrio"]
				for cell in layer.get_used_cells():
					var point:Vector2=host.to_local(layer.to_global(layer.map_to_local(cell)))
					var pixel:=Vector2i((point/32.0).floor())
					if pixel.x<0 or pixel.y<0 or pixel.x>=image.get_width() or pixel.y>=image.get_height():continue
					if image.get_pixelv(pixel).r>0.5:
						if allowed:common+=1
						else:forbidden+=1
			check(common>100,"Shopping sunlight reaches real corridors and atrium")
			check(forbidden==0,"Shopping sunlight never enters shops or cinema")
			check(finish.reflection_count==0 and finish.glare_count==0,"Shopping arcade and display glare removed")
		elif map_name=="Laboratorio":
			var lab=host.get_node("Environment")
			check(lab.fixtures.size()==lab.ceiling_points.size(),"Lab authored artificial ceiling positions")
			var concealed:=true
			for fixture in lab.fixtures: concealed=concealed and not fixture.visual.visible and fixture.light.enabled
			check(concealed,"Lab ceiling sources are invisible while their illumination stays active")
			check(lab.equipment_lights.size()>6,"Lab visible equipment faces cast local light")
			check(lab.rear_equipment.size()>=6,"Lab southern equipment uses authored rear views")
			var unlit_rears:=true
			for prop in lab.rear_equipment:
				unlit_rears=unlit_rears and not prop.has_node("EmisionSelectiva") and prop.get_meta("visual_facing")=="away_from_camera"
			check(unlit_rears,"Lab rear casings have no front-screen emission")
			var no_sun:=true
			for material in finish.floor_materials: no_sun=no_sun and material.get_shader_parameter("sheen_intensity")==0.0
			check(no_sun and not finish.has_node("FloorLightBeams"),"Lab contains no sunlight sweeps")
			check(lab.fixture_factor(0,0.01,false)<1.0 and lab.fixture_factor(0,2.0,false)==1.0,"Lab flicker is brief, followed by steady illumination")
			check(lab.fixture_factor(0,0.01,true)==1.0,"Lab reduced motion suppresses flicker")
		host.queue_free()
		for i in 3: await process_frame
	print("VISUAL_COHERENCE ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

extends Node
var failures:Array[String]=[]
var demo:Node2D
var life:Node2D
var view:SubViewport
func check(ok:bool,message:String) -> void:
	if not ok:failures.append(message);push_error(message)
func stats(values:Array[float]) -> Dictionary:
	values.sort();var total:=0.0;var slow:=0
	for value in values:total+=value;slow+=1 if value>16.667 else 0
	return {"frames":values.size(),"mean_fps":1000.0*values.size()/total,"p99_ms":values[int(values.size()*.99)],"max_ms":values[-1],"over_16_667_ms":slow}
func geometry(node:Node,result:Dictionary) -> void:
	if node is CollisionShape2D and node.get_parent() is StaticBody2D:result[str(node.get_path())]=[node.global_transform,node.disabled,node.shape.size if node.shape is RectangleShape2D else Vector2.ZERO]
	for child in node.get_children():geometry(child,result)
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	view=SubViewport.new();view.size=Vector2i(1920,1080);view.world_2d=World2D.new();view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	demo=load("res://demo/PatoSplashDemo.tscn").instantiate();view.add_child(demo);life=demo.park_life;demo.map.audio_enabled=false;demo.ambient.stop()
	var display:=TextureRect.new();display.texture=view.get_texture();display.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;display.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;display.size=get_viewport().get_visible_rect().size;add_child(display)
	check(life.actors.size()==10,"Stationary actors missing")
	check(get_tree().get_nodes_in_group("splash_visitors").size()==54,"Original roaming population changed")
	check(life.customers.size()==2 and life.changing.size()==2 and life.sliders.size()==2,"Service or slide actors missing")
	check(demo.map.get_node("07_Caminos").tile_set.tile_size==Vector2i(32,32),"Tile size changed")
	check(demo.camera.position==Vector2(960,540),"Camera framing changed")
	check(life.footprint_pool.size()==96,"Footprint pool unbounded")
	var baseline:Dictionary={};geometry(demo.map,baseline)
	# Ratio and distance contract on an isolated actor, using the same public adapter.
	var probe:Node2D=load("res://splash/scenes/actores/npc_limpieza.tscn").instantiate();probe.position=Vector2(3000,3000);life.get_node("Actores").add_child(probe);probe.controller=life;life.actors.append(probe)
	probe.infected_fraction=0.5;probe.infection_radius=100;probe.minimum_infected=1
	var sources:Array[Node2D]=[]
	for i in 4:
		var source:=Node2D.new();source.position=Vector2(3000+i*10,3000);life.add_child(source);sources.append(source);life.set_infection_state(source,false)
	life._poll();check(probe.reacted==0,"Healthy population triggers infection reaction")
	life.set_infection_state(sources[0],true);life._poll();check(probe.reacted==0,"Below-threshold fraction triggers reaction")
	life.set_infection_state(sources[1],true);life._poll();check(probe.reacted==1 and probe.state=="cubrirse","Local fraction threshold does not trigger")
	life._poll();check(probe.reacted==1,"Reaction repeats during cooldown")
	probe._resume();probe.cooldown=0;probe.threshold_mode=0
	for source in sources:source.position+=Vector2(500,0)
	life._poll();check(probe.reacted==1,"Distant infection triggers local reaction")
	sources[0].position=Vector2(3020,3000);life._poll();check(probe.reacted==2,"Distance threshold ignores nearby infection")
	life.actors.erase(probe);probe.queue_free()
	for source in sources:source.queue_free()
	await get_tree().process_frame;life._poll();check(life.registered.is_empty(),"Freed infection sources leak")
	# Running visitors/player bodies cause a guard response, with cooldown.
	var runner:=CharacterBody2D.new();runner.position=Vector2(620,470);runner.velocity=Vector2(120,0);life.add_child(runner);runner.add_to_group("park_watch_targets")
	life.next_whistle=0;life._poll();check(life.whistle_count>0,"Guard does not whistle at running actor")
	var whistles:int=life.whistle_count;life._poll();check(life.whistle_count==whistles,"Guard whistle cooldown ignored");runner.queue_free()
	# Actual mounted actor reactions: run away, cover and warn.
	var selected:Array=[life.actors[2],life.actors[3],life.actors[0]]
	for stationary in selected:
		stationary.threshold_mode=0
		var source:=Node2D.new();source.position=stationary.position;life.add_child(source);life.set_infection_state(source,true);sources.append(source)
	life._poll()
	check(selected[0].state=="huida" and not selected[0].waypoints.is_empty(),"Flee variant has no navigable escape route")
	check(selected[1].state=="cubrirse" and selected[2].state=="avisar","Cover/warn variants missing")
	var first_position:Vector2=selected[0].position
	await get_tree().create_timer(0.6).timeout;check(selected[0].position.distance_to(first_position)>20,"Fleeing actor stays stationary")
	await RenderingServer.frame_post_draw;view.get_texture().get_image().save_png("res://captures/parte5_reaccion.png")
	for entry in life.registered.values():
		var source:Node=entry.ref.get_ref()
		if is_instance_valid(source):source.queue_free()
	await get_tree().process_frame;life._poll()
	# Pausing freezes actions, paths, particle event, footsteps and daylight.
	demo._preview_event();await get_tree().create_timer(2.0).timeout
	get_tree().paused=true
	var frozen:Array=[life.clock,life.actors[0].age,life.sliders[0].follower.progress,life.actors[2].position,demo.map.cannon.state_age]
	await get_tree().create_timer(.25,true).timeout
	check(frozen==[life.clock,life.actors[0].age,life.sliders[0].follower.progress,life.actors[2].position,demo.map.cannon.state_age],"Pause does not freeze every activity")
	get_tree().paused=false
	await get_tree().create_timer(3.0).timeout;demo.map.calm_seconds=5.0
	var times:Array[float]=[];var last:=Time.get_ticks_usec();var begin:=last;var sample:=0.0;var progress_min:=[1.0,1.0];var progress_max:=[0.0,0.0];var door_frames:Dictionary={};var sign_states:Dictionary={};var max_footprints:=0;var bad_segments:=0
	print("PART5_BENCHMARK_STARTED: 70 NPCs + 2 players / all activities / 1920x1080")
	while Time.get_ticks_usec()-begin<40000000:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec();times.append(float(now-last)/1000.0);last=now
		for i in 2:
			var progress:float=life.sliders[i].follower.progress_ratio;progress_min[i]=minf(progress_min[i],progress);progress_max[i]=maxf(progress_max[i],progress)
		door_frames[life.changing[0].door.frame]=true;sign_states[life.get_node("CartelTemporal").visible]=true
		if life.clock-sample>0.5:
			sample=life.clock;var current:Dictionary={};geometry(demo.map,current);check(current==baseline,"Activity moves solid geometry")
			var live:=0
			for entry in life.footprint_pool:live+=1 if entry.age>=0 else 0
			max_footprints=maxi(max_footprints,live)
			for stationary in life.actors:
				if stationary.state in ["huida","volver"] and stationary.target_index>1 and stationary.target_index<stationary.waypoints.size()-1:
					if not demo.routes.clear_segment(stationary.position,stationary.waypoints[stationary.target_index],0.0):bad_segments+=1
	check(bad_segments==0,"Escape route crosses geometry")
	for i in 2:check(progress_min[i]<0.1 and progress_max[i]>.99,"Slide PathFollow does not traverse full curve")
	check(door_frames.size()==5,"Cabin does not animate all opening poses")
	check(sign_states.size()==2,"Cleaner sign does not appear and expire")
	check(life.served_count>=4 and life.door_count>=4 and life.slide_count>=6 and life.photo_count>=2,"Ambient service loops do not repeat")
	check(life.footprint_count>10 and max_footprints<=96,"Wet footprints missing or pool overflow")
	check(life.reaction_counts.has("huida") and life.reaction_counts.has("cubrirse") and life.reaction_counts.has("avisar"),"Three reaction variants not exercised")
	for stationary in selected:check(stationary.state=="rutina" and stationary.position.distance_to(stationary.home)<1,"Stationary actor fails to recover home")
	var event_report:Dictionary=stats(times);check(event_report.p99_ms<16.667,"99th percentile below 60 FPS target")
	# Decals must expire on their own, independent from pool reuse.
	var marker_index:int=life.print_cursor;life.emit_footprint(Vector2(-200,-200));life.set_process(false)
	for entry in life.footprint_pool:entry.age=life.footprint_seconds-.01 if entry.age>=0 else -1
	life.cached_participants.clear();life._extras(.05)
	check(life.footprint_pool[marker_index].age<0 and not life.footprint_pool[marker_index].sprite.visible,"Footprints never dry")
	life.sunset_seconds=60;life.clock=60;life._extras(0)
	check(life.get_node("Atardecer").color.a<=0.2 and life.get_node("Atardecer").color.a>0,"Subtle sunset missing")
	demo.queue_free();await get_tree().process_frame
	var catalogue:Node2D=load("res://scenes/asset_showcase.tscn").instantiate();view.add_child(catalogue)
	var listed:Dictionary={}
	for card in catalogue.get_node("Catalogo").get_children():
		if card.has_meta("source"):
			listed[card.name]=true;check(card.has_node("Vista"),"Catalogue card has no copyable sprite")
	var total_sources:=0
	for filename in DirAccess.get_files_at("res://splash/assets"):
		if filename.ends_with(".aseprite"):total_sources+=1;check(listed.has(filename.get_basename()),"Catalogue omits "+filename)
	check(total_sources==75 and listed.size()==75,"Catalogue asset count differs from sources")
	await get_tree().create_timer(0.2).timeout;await RenderingServer.frame_post_draw;view.get_texture().get_image().save_png("res://captures/parte5_showcase.png")
	var report:Dictionary={"passed":failures.is_empty(),"failures":failures,"render_size":[1920,1080],"roaming_npcs":54,"stationary_npcs":10,"service_and_slide_npcs":6,"total_npcs":70,"gpu":RenderingServer.get_video_adapter_name(),"physics_hz":Engine.physics_ticks_per_second,"performance":event_report,"infection_thresholds_checked":["healthy","below_fraction","fraction","distance","outside_radius","cooldown","despawn"],"reaction_variants":["huida","cubrirse","avisar"],"return_home_checked":true,"pause_checked":true,"showcase_assets":listed.size(),"footprints_peak":max_footprints,"footprints_dry_checked":true,"door_poses":door_frames.size(),"escape_bad_segments":bad_segments}
	var file:=FileAccess.open("res://tests/part5_validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));print("PART5_VALIDATION ",JSON.stringify(report));get_tree().quit(0 if failures.is_empty() else 1)

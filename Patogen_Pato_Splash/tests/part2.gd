extends Node
var failures: Array[String]=[]
var report: Dictionary={}
func check(value: bool,message: String) -> void:
	if not value:failures.append(message);push_error(message)
func path_length(path: PackedVector2Array) -> float:
	var distance:=0.0
	for i in range(1,path.size()):distance+=path[i-1].distance_to(path[i])
	return distance
func nearest_filter(node: CanvasItem) -> bool:
	var current: Node=node
	while current:
		if current is CanvasItem and current.texture_filter!=CanvasItem.TEXTURE_FILTER_PARENT_NODE:return current.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST
		current=current.get_parent()
	return ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")==0
func filters(node: Node) -> int:
	var count:=0
	if node is AnimatedSprite2D or node is Sprite2D or node is TileMapLayer:
		count+=1;check(nearest_filter(node),"Non-Nearest visual: "+str(node.get_path()))
	for child in node.get_children():count+=filters(child)
	return count
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var demo=load("res://demo/PatoSplashDemo.tscn").instantiate();add_child(demo)
	demo.map.audio_enabled=false;demo.ambient.stop();demo.shake_enabled=false
	for frame in 20:await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://captures/parte2_1920x1080.png")
	var map: Node2D=demo.map;var objects: Node2D=map.get_node("04_Objetos")
	check(map.get_node("01_Pisos").tile_set.tile_size==Vector2i(32,32),"Original tile size changed")
	check(demo.camera.zoom==Vector2.ONE and demo.camera.position==Vector2(960,540),"Whole-map fixed camera changed")
	var path_layer: TileMapLayer=map.get_node("07_Caminos")
	check(path_layer.tile_set.tile_size==Vector2i(32,32),"Promenade tiles are not 32px")
	check(path_layer.tile_set.get_terrain_sets_count()==1,"Missing native terrain set")
	check(path_layer.tile_set.get_terrain_set_mode(0)==TileSet.TERRAIN_MODE_MATCH_SIDES,"Wrong autotile mode")
	var paved:=path_layer.get_used_cells();check(paved.size()>180,"Promenade is incomplete")
	var seen: Dictionary={paved[0]:true};var queue: Array[Vector2i]=[paved[0]];var cursor:=0
	while cursor<queue.size():
		var id: Vector2i=queue[cursor];cursor+=1
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Vector2i=id+direction
			if path_layer.get_cell_source_id(next)>=0 and not seen.has(next):seen[next]=true;queue.append(next)
	check(seen.size()==paved.size(),"Disconnected promenade segment")
	report.connected_promende_tiles=paved.size();report.native_terrain=true
	var planter_count:=0;var sign_count:=0
	for child in objects.get_children():
		if child.name.begins_with("CanteroPalmera_"):
			planter_count+=1
			check(child.get_node("Colision/Shape").shape.size==Vector2(64,64),"Planter footprint must be 2x2 tiles")
			check(child.get_node("Palmera").position==Vector2(0,12),"Palm is not centered in its soil square")
			check(child.get_node("Palmera/Colision/Shape").disabled,"Palm trunk duplicates planter collision")
			check(int(child.position.x)%32==0 and int(child.position.y)%32==0,"Planter does not align with the tile grid")
			check(Rect2(32,112,1856,860).encloses(Rect2(child.position-Vector2(32,32),Vector2(64,64))),"Planter outside map bounds")
		if child.name.begins_with("Aviso_"):sign_count+=1
	check(planter_count==10,"Some palms have no planter")
	check(sign_count==8,"Missing wet-floor / do-not-step signs")
	report.planters=planter_count;report.signs=sign_count
	var routes=demo.routes;var connected:=0
	for a in routes.goals:
		for b in routes.goals:
			check(not routes.path(a,b).is_empty(),"NPC destination pair disconnected");connected+=1
	report.connected_destination_pairs=connected
	var broad=load("res://demo/routes.gd").new();broad.setup(map,36);var broad_pairs:=0
	for a in broad.goals:
		for b in broad.goals:check(not broad.path(a,b).is_empty(),"No 72px alternative route");broad_pairs+=1
	report.connected_pairs_radius36=broad_pairs
	var markers: Node=map.get_node("06_Marcadores");var farthest:=0.0
	for marker in markers.get_children():
		for obstacle in routes.obstacles:check(not obstacle.grow(16).has_point(marker.position),"Destination overlaps furniture: "+marker.name)
		var nearest:=INF
		for cell in paved:nearest=minf(nearest,(path_layer.map_to_local(cell)-marker.position).length())
		farthest=maxf(farthest,nearest)
	check(farthest<=96,"A destination is too far from the promenade")
	report.max_destination_distance_to_promenade=farthest
	var event: Vector2=markers.get_node("ChapuzonCentro").position
	var a:=path_length(routes.path(markers.get_node("InicioPato_A").position,event));var b:=path_length(routes.path(markers.get_node("InicioPato_B").position,event));report.spawn_path_to_event=[a,b];check(absf(a-b)<=32,"Initial access to the event is asymmetric")
	# Preserve the part-1 visual bug corrections.
	var endpoints: Array=[Vector2(317,380),Vector2(387,383)]
	for i in 2:
		var marker: Node2D=objects.get_node("ToboganesDobles/"+("SalidaIzquierda" if i==0 else "SalidaDerecha"))
		check(marker.global_position==endpoints[i],"Slide outlet moved away from the real tip")
		check(marker.get_node("CaidaAgua").is_playing(),"Independent slide water stopped")
	var pool_names: Array=["PiletaToboganes","PiletaCentral","PiletaCentral","PiletaInfantil"]
	for i in 4:
		var ladder: Sprite2D=objects.get_node("escalera_%d/Textura"%(10+i));var top: Vector2=ladder.to_global(ladder.get_rect().position);var pool: Node2D=map.get_node("02_Piletas/"+pool_names[i]);check(top.y==pool.position.y-8,"Ladder slipped inside the pool")
	for player in demo.explorers:check(player.sprite.sprite_frames.get_frame_count("Abajo")==8,"New park duck has missing frames")
	report.nearest_nodes_checked=filters(demo)
	# Run 120 simulated seconds at the original 1/60 physics delta.
	Engine.physics_ticks_per_second=240;Engine.max_physics_steps_per_frame=16;Engine.time_scale=4
	var impacts: Array[float]=[];demo.map.splash_impact.connect(func(_strength):impacts.append(demo.total_time))
	var penetrations:=0;var max_attracted:=0
	for tick in 7200:
		await get_tree().physics_frame
		if tick%120==0:
			var attracted:=0
			for actor in get_tree().get_nodes_in_group("splash_visitors"):
				if actor.attraction_left>0:attracted+=1
				for obstacle in routes.obstacles:
					var p: Vector2=actor.global_position
					var dx:=maxf(0,maxf(obstacle.position.x-p.x,p.x-obstacle.end.x));var dy:=maxf(0,maxf(obstacle.position.y-(p.y+4.5),(p.y-4.5)-obstacle.end.y))
					if Vector2(dx,dy).length()<11.15:penetrations+=1
			max_attracted=maxi(max_attracted,attracted)
	var min_travel:=INF;var trips:=0;var recoveries:=0;var max_stuck:=0.0
	for actor in get_tree().get_nodes_in_group("splash_visitors"):
		min_travel=minf(min_travel,actor.travel);trips+=actor.trips;recoveries+=actor.recoveries;max_stuck=maxf(max_stuck,actor.max_stuck);check(actor.travel>1000,"A visitor is stuck")
	check(penetrations==0,"A visitor penetrated an obstacle")
	check(impacts.size()==2,"Expected two ordinary event cycles")
	check(max_attracted<=10,"Attraction exceeds its neutral visitor limit")
	report.simulated_seconds=120;report.actors=54;report.min_travel=min_travel;report.completed_trips=trips;report.recoveries=recoveries;report.max_stuck_seconds=max_stuck;report.penetration_samples=penetrations;report.impact_times=impacts;report.max_attracted=max_attracted
	Engine.time_scale=1;Engine.physics_ticks_per_second=60;Engine.max_physics_steps_per_frame=8
	report.passed=failures.is_empty();report.failures=failures
	var file:=FileAccess.open("res://tests/part2_validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PART2_VALIDATION ",JSON.stringify(report))
	await get_tree().create_timer(12).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

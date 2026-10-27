extends SceneTree
var failures: Array[String]=[]
var report: Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(condition: bool,message: String) -> void:
	if not condition:failures.append(message);push_error(message)
func path_length(path: PackedVector2Array) -> float:
	var total:=0.0
	for i in range(1,path.size()):total+=path[i-1].distance_to(path[i])
	return total
func run() -> void:
	var demo=load("res://demo/PatoSplashDemo.tscn").instantiate();root.add_child(demo)
	demo.map.audio_enabled=false;demo.ambient.stop()
	await physics_frame
	var routes=demo.routes
	check(demo.map.get_node("04_Objetos/Balde/Colision/Shape").disabled,"Bucket decoration must not collide")
	check(demo.map.get_node("04_Objetos/Balde/Textura").position==Vector2.ZERO,"Bucket pivot override was not saved")
	check(not demo.map.get_node("04_Objetos/ToboganesDobles/Colision/Shape").disabled,"Slide structure must collide")
	var connected:=0
	for a in routes.goals:
		for b in routes.goals:
			check(not routes.path(a,b).is_empty(),"Disconnected destination pair")
			connected+=1
	report.connected_destination_pairs=connected
	report.excluded_isolated_spawn_cells=routes.excluded_isolated_cells
	var markers=demo.map.get_node("06_Marcadores")
	for m in markers.get_children():
		for r in routes.obstacles:check(not r.grow(16).has_point(m.global_position),"Marker inside inflated obstacle: "+m.name)
		check(routes.nearest_point(m.global_position).distance_to(m.global_position)<=12,"Destination silently projected outside its location: "+m.name)
	var a: Vector2=markers.get_node("InicioPato_A").global_position
	var b: Vector2=markers.get_node("InicioPato_B").global_position
	var event: Vector2=markers.get_node("ChapuzonCentro").global_position
	var da:=path_length(routes.path(a,event));var db:=path_length(routes.path(b,event))
	report.spawn_path_to_event=[da,db]
	check(absf(da-db)<=32,"Unequal initial path to main event")
	var broad=load("res://demo/routes.gd").new();broad.setup(demo.map,36)
	var broad_pairs:=0
	for p in broad.goals:
		for q in broad.goals:
			check(not broad.path(p,q).is_empty(),"Disconnected 72px-clearance destination pair")
			broad_pairs+=1
	report.connected_pairs_radius36=broad_pairs
	var original_obstacles: Array=routes.obstacles.duplicate()
	var impacts: Array[float]=[]
	demo.map.splash_impact.connect(func(_strength):impacts.append(demo.total_time))
	var max_attracted:=0
	var penetrations:=0
	# Two complete 50-second event cycles and ordinary circulation.
	for tick in 7200:
		await physics_frame
		if tick%120==0:
			var count:=0
			for actor in get_nodes_in_group("splash_visitors"):
				if actor.attraction_left>0:count+=1
				# Exact capsule-vs-rectangle distance: radius 11.5, center segment 9 px.
				for obstacle in routes.obstacles:
					var pos: Vector2=actor.global_position
					var dx:=maxf(0,maxf(obstacle.position.x-pos.x,pos.x-obstacle.end.x))
					var dy:=maxf(0,maxf(obstacle.position.y-(pos.y+4.5),(pos.y-4.5)-obstacle.end.y))
					if Vector2(dx,dy).length()<11.15:penetrations+=1
			max_attracted=maxi(max_attracted,count)
	var travel: Array[float]=[];var max_stuck:=0.0;var trips:=0;var recoveries:=0
	for actor in get_nodes_in_group("splash_visitors"):
		travel.append(actor.travel);max_stuck=maxf(max_stuck,actor.max_stuck);trips+=actor.trips;recoveries+=actor.recoveries
		check(actor.travel>1000,"An NPC is not circulating")
	report.simulated_seconds=120;report.actors=travel.size();report.min_travel=travel.min();report.completed_trips=trips;report.max_stuck_seconds=max_stuck;report.recoveries=recoveries;report.penetration_samples=penetrations;report.max_attracted=max_attracted;report.impact_times=impacts
	check(max_attracted<=10 and max_attracted>0,"Visitor attraction exceeds cap or never fired")
	check(impacts.size()==2,"Expected two impacts in 120 seconds")
	if impacts.size()==2:check(absf(impacts[1]-impacts[0]-50)<.1,"Event cycle is not stable")
	check(penetrations==0,"NPC penetrates static geometry")
	var final_routes=load("res://demo/routes.gd").new();final_routes.setup(demo.map)
	check(original_obstacles==final_routes.obstacles,"Event changed static geometry")
	var phase_before: String=demo.map.phase;var elapsed_before: float=demo.map.elapsed
	demo._toggle_pause()
	for i in 20:await process_frame
	check(demo.map.phase==phase_before and demo.map.elapsed==elapsed_before,"Event advances while paused")
	demo._toggle_pause()
	demo.shake_enabled=false;demo._impact(1);demo._process(.016);check(demo.camera.offset==Vector2.ZERO,"Reduced camera motion ignored")
	for role in ["banador","salvavidas","staff"]:
		for n in range(1,4):
			var sf: SpriteFrames=load("res://splash/assets/%s_%d.tres"%[role,n])
			for dir in ["Abajo","Arriba","Derecha","Izquierda"]:check(sf.has_animation(dir),"Missing NPC direction")
	report.failures=failures;report.passed=failures.is_empty()
	var file:=FileAccess.open("res://tests/validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print(JSON.stringify(report))
	demo.queue_free();await process_frame
	quit(0 if failures.is_empty() else 1)

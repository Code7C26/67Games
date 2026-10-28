extends SceneTree
var failures: Array[String]=[]
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message): failures.append(message);push_error(message)
func run() -> void:
	root.get_node("PatogenOnboarding").requested_mode="direct"
	var host=load("res://scenes/PatoSplash.tscn").instantiate()
	root.add_child(host);current_scene=host
	await host.map_ready
	host.timer_inicio.stop()
	host.set_process(false)
	for actor in get_nodes_in_group("bots"):
		actor.set_physics_process(false);actor.get_node("TimerCambioRumbo").stop()
	for duck in get_nodes_in_group("patos"): duck.set_physics_process(false)
	var life=host.get_node("Environment/10_VidaParque")
	life.set_process(false);life.enabled=true
	for actor in life.actors: actor.set_process(false)
	check(life.actors.size()==10 and life.sliders.size()==2 and life.customers.size()==2 and life.changing.size()==2,"All sixteen ambient NPCs exist")
	for entry in life.sliders:
		check(not entry.return_path.is_empty(),"Slide return route connects exit and staircase")
		for i in range(1,maxi(1,entry.return_path.size()-3)):
			check(host.npc_navigation.segmento_libre(entry.return_path[i-1],entry.return_path[i]),"Slide walking route avoids pool and props")
	var previous: Array[Vector2]=[]
	for i in 6: previous.append(Vector2.INF)
	var handoffs: Array[int]=[0,0]
	var was_sliding: Array[bool]=[false,false]
	var max_jump:=0.0
	for frame in 60*120:
		life._process(1.0/60.0)
		for i in 2:
			var entry:Dictionary=life.sliders[i]
			check(entry.sprite.visible!=entry.swimmer.visible,"Slide always has exactly one visible rider")
			var point: Vector2=entry.sprite.global_position if entry.sprite.visible else entry.swimmer.global_position
			if previous[i].is_finite():
				var jump:=point.distance_to(previous[i]);max_jump=maxf(max_jump,jump)
				check(jump<5.0,"Slide handoffs and repeat cycles never teleport")
			previous[i]=point
			if was_sliding[i] and not entry.sprite.visible: handoffs[i]+=1
			was_sliding[i]=entry.sprite.visible
			var customer:AnimatedSprite2D=life.customers[i].sprite
			check(customer.visible,"Ice-cream customers never disappear in the open")
			if previous[2+i].is_finite(): check(customer.global_position.distance_to(previous[2+i])<5.0,"Ice-cream loop is spatially continuous")
			previous[2+i]=customer.global_position
			var changing:AnimatedSprite2D=life.changing[i].sprite
			check(changing.visible,"Changing-room visitor is occluded by doorway, not despawned")
			if changing.modulate.a==0: check(changing.position.y<=252.1,"Changing-room invisibility occurs only inside cabin")
			if previous[4+i].is_finite(): check(changing.global_position.distance_to(previous[4+i])<5.0,"Changing-room loop never teleports")
			previous[4+i]=changing.global_position
		for actor in life.actors:
			actor._process(1.0/60.0)
			check(actor.visible and actor.visual.visible,"Stationary actors stay visible")
			check(actor.visual.frame<actor.visual.sprite_frames.get_frame_count(actor.visual.animation),"Stationary action frames stay in range")
	for count in handoffs: check(count>=3,"Each slide repeats complete round trips")
	check(life.served_count>=12 and life.door_count>=12,"Both service and cabin cycles repeat")
	# Every stationary role reacts, then returns to its own station.
	for actor in life.actors:
		actor.cooldown=0;actor.trigger_reaction(actor.global_position+Vector2(32,0))
	for frame in 60*120:
		for actor in life.actors:
			var old:Vector2=actor.position
			actor._process(1.0/60.0)
			check(actor.position.distance_to(old)<=actor.flee_speed/60.0+0.1,"Stationary escape and return never teleport")
	for actor in life.actors:
		check(actor.state=="rutina" and actor.position.distance_to(actor.home)<1.0,"Stationary actor returns home: "+actor.name)
		check(not actor.indicator.visible and not actor.cover.visible,"Stationary reaction overlays clear: "+actor.name)
	life.set_process(true)
	paused=true
	var before:float=life.clock
	await create_timer(0.2,true).timeout
	check(life.clock==before,"Pause freezes ambient routines")
	paused=false
	print("PARK_LIFE: 16 NPCs / 120s routine + 120s reactions / max slide step ",max_jump," / ",failures.size()," failures")
	host.queue_free();await process_frame;await process_frame
	quit(1 if not failures.is_empty() else 0)

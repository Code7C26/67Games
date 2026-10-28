extends Node2D
## Ambient layer. The production game owns infection; this only reads reported states.
signal stationary_reacted(actor: Node2D, reaction: String, focus: Vector2)
signal slide_landed(lane: int, point: Vector2)
signal ice_cream_served(customer: Node2D)
@export var enabled := true
@export_group("Actividad / segundos")
@export_range(0.1,2.0,0.05) var infection_poll_seconds := 0.3
@export_range(80.0,240.0,5.0) var guard_watch_radius := 160.0
@export_range(70.0,180.0,5.0) var running_speed_threshold := 90.0
@export_range(2.0,20.0,0.5) var whistle_cooldown := 6.0
@export_range(4.0,30.0,1.0) var photo_interval := 13.0
@export_range(8.0,40.0,1.0) var service_cycle := 18.0
@export_range(8.0,40.0,1.0) var changing_cycle := 17.0
@export_range(4.0,30.0,0.5) var slide_interval := 10.0
@export_range(1.5,6.0,0.1) var slide_duration := 3.2
@export_group("Ambiente adicional")
@export var sunset_enabled := true
@export_range(60.0,1800.0,30.0) var sunset_seconds := 360.0
@export_range(0.0,0.2,0.01) var sunset_intensity := 0.10
@export_range(0.0,0.3,0.01) var logo_pulse_intensity := 0.12
@export_range(1.0,12.0,0.5) var footprint_seconds := 5.0
@export var insects_enabled := true
var navigation: Callable
var infection_reader: Callable
var clock := 0.0
var poll_left := 0.0
var next_whistle := 0.0
var registered: Dictionary = {}
var actors: Array[Node2D] = []
var sliders: Array[Dictionary] = []
var customers: Array[Dictionary] = []
var changing: Array[Dictionary] = []
var footprint_pool: Array[Dictionary] = []
var print_cursor := 0
var footprint_count := 0
var whistle_count := 0
var photo_count := 0
var served_count := 0
var door_count := 0
var slide_count := 0
var reaction_counts: Dictionary = {}
var map_root: Node2D
var logo: Label
var logo_color := Color.WHITE
var vest_visual: AnimatedSprite2D
var cached_participants: Array[Node] = []
var next_photo := 3.0
var wet_tracks: Dictionary = {}
var reservations: Array[Rect2] = [Rect2(148,898,40,40),Rect2(248,898,40,40),Rect2(1712,586,48,48),Rect2(1148,156,40,40)]

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	map_root=get_parent()
	for child in $Actores.get_children():child.controller=self;actors.append(child)
	if map_root.has_node("04_Objetos/Vestuarios/Textura"):
		vest_visual=map_root.get_node("04_Objetos/Vestuarios/Textura");vest_visual.stop();vest_visual.frame=0
	for item in map_root.get_node("03_Senales_y_perimetro").get_children():
		if item is Label and item.text=="PATO SPLASH":logo=item;logo_color=item.modulate
	for i in 2:
		var path: Path2D=get_node("Tobogan%d"%i)
		var follower: PathFollow2D=path.get_node("Pasajero")
		sliders.append({"follower":follower,"sprite":follower.get_node("Visual"),"splash":get_node("Llegada%d"%i),"swimmer":get_node("SalidaNadador%d"%i),"cycle":-1,"age":0.0,"last_print":-1.0,"return_path":PackedVector2Array(),"cycle_duration":slide_interval})
		customers.append({"sprite":get_node("ClienteHelado%d"%i),"ice":get_node("ClienteHelado%d/Helado"%i),"path":PackedVector2Array(),"cycle":-1,"served":false})
		customers[i].sprite.position=Vector2(1656+i*36,852)
		changing.append({"sprite":get_node("ClienteVestuario%d"%i),"door":get_node("Puerta%d"%i),"cycle":-1,"entries":0})
		for sprite in [sliders[i].sprite,sliders[i].swimmer,customers[i].sprite,changing[i].sprite]:
			if ResourceLoader.exists("res://scripts/npc_readability.gd"):
				var readability=load("res://scripts/npc_readability.gd")
				sprite.sprite_frames=readability.padded(sprite.sprite_frames)
				var outline:=ShaderMaterial.new()
				outline.shader=load("res://shaders/npc_outline.gdshader")
				sprite.material=outline
	for i in 96:
		var s:=Sprite2D.new();s.texture=load("res://splash/assets/huella_mojada.tres").get_frame_texture("default",i%2);s.z_index=0;s.hide();add_child(s);footprint_pool.append({"sprite":s,"age":-1.0})
	# Pause is inherited from the map; no wall-clock timers or unbounded allocations.
	_services();_changing();_slides()

func configure_navigation(provider: Callable) -> void:
	navigation=provider
	for i in customers.size():
		var origin := Vector2(1656+i*36,852)
		customers[i].sprite.position=origin
		customers[i].path=route(origin,Vector2(1640,816))
		if not customers[i].path.is_empty(): customers[i].sprite.position=customers[i].path[0]
	for i in sliders.size():
		var entry: Dictionary=sliders[i]
		var foot := Vector2(216,344)
		var path := route(Vector2(560,344),foot)
		if not path.is_empty():
			# Only the last segment climbs the drawn staircase; guests never
			# cut through the pool to reset at the start of the slide.
			path.append(Vector2(272,344))
			path.append(Vector2(272,227))
			path.append(entry.follower.get_parent().curve.get_point_position(0)+entry.sprite.position)
		entry.return_path=path
		entry.cycle_duration=maxf(slide_interval,slide_duration+_length(_swim_path(i))/65.0+_length(path)/75.0+1.0)
	_slides()

func _length(points: PackedVector2Array) -> float:
	var distance:=0.0
	for i in range(1,points.size()): distance+=points[i-1].distance_to(points[i])
	return distance

func _swim_path(lane: int) -> PackedVector2Array:
	var entry: Dictionary=sliders[lane]
	var curve: Curve2D=entry.follower.get_parent().curve
	var impact: Vector2=curve.get_point_position(curve.point_count-1)+entry.sprite.position
	var exit_point: Vector2=entry.return_path[0] if not entry.return_path.is_empty() else Vector2(560,344)
	return PackedVector2Array([impact,Vector2(488,440),Vector2(488,368),Vector2(536,350),exit_point])

func _pose(sprite: AnimatedSprite2D, points: PackedVector2Array, ratio: float) -> void:
	var point:=_along(points,ratio)
	var ahead:=_along(points,minf(1.0,ratio+0.005))
	var direction:=ahead-point
	if direction.length_squared()<0.01: direction=point-_along(points,maxf(0,ratio-0.005))
	sprite.position=point
	sprite.animation=("Derecha" if direction.x>=0 else "Izquierda") if absf(direction.x)>absf(direction.y) else ("Abajo" if direction.y>=0 else "Arriba")
	sprite.frame=int(clock*7)%sprite.sprite_frames.get_frame_count(sprite.animation) if ratio>0.0 and ratio<1.0 else 0

func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	if navigation.is_valid():return navigation.call(from,to)
	return PackedVector2Array() # Stationary safety fallback until a host supplies navigation.

func escape_path(from: Vector2, focus: Vector2) -> PackedVector2Array:
	var best:=from;var score:=-INF
	for exit_point in [Vector2(192,600),Vector2(1728,600),Vector2(960,928)]:
		var candidate:=route(from,exit_point)
		if candidate.is_empty():continue
		var distance:float=exit_point.distance_squared_to(focus)
		if distance>score:score=distance;best=exit_point
	return route(from,best)

func set_infection_state(actor: Node2D, infected: bool) -> void:
	# Call when the actual infection system changes state. Weak refs tolerate despawn.
	registered[actor.get_instance_id()]={"ref":weakref(actor),"infected":infected}

func is_infected(actor: Node2D) -> bool:
	if infection_reader.is_valid():return bool(infection_reader.call(actor))
	return registered.has(actor.get_instance_id()) and registered[actor.get_instance_id()].infected

func _poll() -> void:
	cached_participants=get_tree().get_nodes_in_group("splash_visitors")
	for actor in get_tree().get_nodes_in_group("park_watch_targets"):
		if not cached_participants.has(actor):cached_participants.append(actor)
	for key in registered.keys():
		var subject: Node=registered[key].ref.get_ref()
		if not is_instance_valid(subject):registered.erase(key)
		elif not cached_participants.has(subject):cached_participants.append(subject)
	for stationary in actors:
		var nearby:=0;var infected:=0;var focus:=Vector2.ZERO
		for actor in cached_participants:
			if stationary.global_position.distance_to(actor.global_position)<=stationary.infection_radius:
				nearby+=1
				if is_infected(actor):infected+=1;focus+=actor.global_position
		var ratio:=float(infected)/maxi(1,nearby)
		if infected>=stationary.minimum_infected and (stationary.threshold_mode==0 or ratio>=stationary.infected_fraction):
			var previous:int=stationary.reacted;stationary.trigger_reaction(focus/infected)
			if stationary.reacted>previous:
				reaction_counts[stationary.state]=int(reaction_counts.get(stationary.state,0))+1
				stationary_reacted.emit(stationary,stationary.state,focus/infected)
		if stationary.action_asset=="npc_guardia" and clock>=next_whistle:
			for actor in cached_participants:
				if actor is CharacterBody2D and actor.velocity.length()>running_speed_threshold and stationary.global_position.distance_to(actor.global_position)<guard_watch_radius:
					stationary.whistle();whistle_count+=1;next_whistle=clock+whistle_cooldown
					if map_root.audio_enabled:$Silbato.play()
					break

func _process(delta: float) -> void:
	if not enabled:return
	clock+=delta;poll_left-=delta
	if poll_left<=0:poll_left=infection_poll_seconds;_poll()
	if vest_visual:vest_visual.stop();vest_visual.frame=0
	_ball();_services();_changing();_slides();_extras(delta)

func _ball() -> void:
	var a:Node2D=$Actores/NinoA;var b:Node2D=$Actores/NinoB
	$Pelota.visible=a.state=="rutina" and b.state=="rutina"
	var u:=fposmod(clock,2.0)/2.0;var blend:=u*2.0 if u<0.5 else (1.0-u)*2.0
	$Pelota.position=a.position.lerp(b.position,blend)+Vector2(0,-20.0-32.0*sin(blend*PI))
	$Pelota.frame=int(clock*8.0)%8
	$CartelTemporal.visible=fposmod(clock,12.0)>5.0 and $Actores/Limpieza.state=="rutina"
	$ZonaTrapeada.visible=$CartelTemporal.visible;$ZonaTrapeada.modulate.a=0.15
	$Flash.visible=clock>=next_photo and clock<next_photo+0.28 and $Actores/Fotografo.state=="rutina"
	if $Flash.visible:$Flash.frame=mini(3,int((clock-next_photo)/0.07))
	if clock>=next_photo+0.28:next_photo+=photo_interval;photo_count+=1

func _along(points: PackedVector2Array, fraction: float) -> Vector2:
	if points.is_empty():return Vector2.ZERO
	var total:=0.0
	for i in range(1,points.size()):total+=points[i-1].distance_to(points[i])
	var remaining:=clampf(fraction,0,1)*total
	for i in range(1,points.size()):
		var distance:=points[i-1].distance_to(points[i])
		if remaining<=distance:return points[i-1].lerp(points[i],remaining/maxf(0.001,distance))
		remaining-=distance
	return points[-1]

func _services() -> void:
	for i in customers.size():
		var entry:Dictionary=customers[i]
		var cycle_time:=maxf(service_cycle,16.0)
		var age:=fposmod(clock+i*cycle_time*0.5,cycle_time)
		var cycle:=int((clock+i*cycle_time*0.5)/cycle_time)
		if entry.cycle!=cycle: entry.cycle=cycle;entry.served=false
		entry.sprite.show()
		if entry.path.is_empty(): entry.ice.hide();continue
		var ratio:=clampf(age/5.0,0,1) if age<8.0 else 1.0-clampf((age-8.0)/6.0,0,1)
		var points: PackedVector2Array=entry.path
		if age>=8.0:
			points=points.duplicate();points.reverse();ratio=1.0-ratio
		_pose(entry.sprite,points,ratio)
		entry.ice.visible=age>=7.0 and age<16.0
		entry.ice.modulate.a=1.0-clampf((age-14.0)/2.0,0,1)
		if age>=7.0 and not entry.served:
			entry.served=true;served_count+=1;ice_cream_served.emit(entry.sprite)
		entry.ice.frame=int(clock*4)%4

func _changing() -> void:
	for i in changing.size():
		var entry:Dictionary=changing[i];var cycle_time:=maxf(changing_cycle,16.0);var age:=fposmod(clock+i*cycle_time*0.5,cycle_time);var cycle:=int((clock+i*cycle_time*0.5)/cycle_time)
		if entry.cycle!=cycle:entry.cycle=cycle;entry.entries=0
		var x:=1430.0+i*212.0
		var open_amount:=0.0
		for window in [Vector2(3.3,6.0),Vector2(9.8,12.5)]:
			if age>window.x and age<window.y:open_amount=minf(clampf((age-window.x)/0.5,0,1),clampf((window.y-age)/0.5,0,1))
		entry.door.frame=roundi(open_amount*4.0)
		if age<5.0:
			entry.sprite.visible=true;entry.sprite.position=Vector2(x,330).lerp(Vector2(x,252),clampf(age/5.0,0,1));entry.sprite.animation="Arriba"
		elif age<11.0:entry.sprite.position=Vector2(x,252)
		else:
			entry.sprite.visible=true;entry.sprite.position=Vector2(x,252).lerp(Vector2(x,330),clampf((age-11.0)/4.0,0,1));entry.sprite.animation="Abajo"
		# Fade only behind the open door threshold, never in open circulation.
		entry.sprite.visible=true
		entry.sprite.modulate.a=smoothstep(252.0,273.0,entry.sprite.position.y)
		entry.sprite.frame=int(clock*6)%entry.sprite.sprite_frames.get_frame_count(entry.sprite.animation) if age<5.0 or (age>=11.0 and age<15.0) else 0
		if age>=5.0 and entry.entries==0:entry.entries=1;door_count+=1
		# Door threshold is a visual transition; facade collision remains intact.
		entry.sprite.z_index=2 if entry.sprite.position.y>273 else 1

func _slides() -> void:
	for i in sliders.size():
		var entry:Dictionary=sliders[i]
		var cycle_time:float=entry.cycle_duration
		var age:=fposmod(clock+i*cycle_time*0.5,cycle_time)
		var cycle:=int((clock+i*cycle_time*0.5)/cycle_time)
		entry.age=age
		if entry.return_path.is_empty():
			age=minf(clock+i*cycle_time*0.5,slide_duration+_length(_swim_path(i))/65.0)
			cycle=0
		entry.sprite.visible=age<slide_duration
		entry.follower.progress_ratio=clampf(age/slide_duration,0,1)
		entry.sprite.frame=int(clock*7)%entry.sprite.sprite_frames.get_frame_count("default")
		var impact_age:=age-slide_duration
		var swim:=_swim_path(i)
		entry.splash.position=swim[0]
		entry.splash.visible=impact_age>=0 and impact_age<0.48
		if entry.splash.visible: entry.splash.frame=mini(3,int(impact_age/0.12))
		if impact_age>=0 and entry.cycle!=cycle:
			entry.cycle=cycle;slide_count+=1;slide_landed.emit(i,entry.splash.position)
		# Exact hand-off: one visible rider at the SAME position on either side
		# of the slide/swim boundary. No 0.4s hole and no 4.5s despawn.
		entry.swimmer.visible=not entry.sprite.visible
		if not entry.swimmer.visible: continue
		var swim_duration:=_length(swim)/65.0
		if impact_age<swim_duration:
			_pose(entry.swimmer,swim,clampf(impact_age/swim_duration,0,1))
		elif not entry.return_path.is_empty():
			_pose(entry.swimmer,entry.return_path,clampf((impact_age-swim_duration)/maxf(0.1,_length(entry.return_path)/75.0),0,1))
		else:
			# No provider/route: remain at the exit instead of vanishing.
			_pose(entry.swimmer,swim,1.0)
		if entry.swimmer.position.x>526 and clock-entry.last_print>0.3 and impact_age<swim_duration+2.0:
			entry.last_print=clock;emit_footprint(entry.swimmer.position+Vector2(0,12))

func emit_footprint(point: Vector2) -> void:
	var entry:Dictionary=footprint_pool[print_cursor];print_cursor=(print_cursor+1)%footprint_pool.size()
	entry.age=0.0;entry.sprite.position=point;entry.sprite.show();footprint_count+=1

func _extras(delta: float) -> void:
	$Atardecer.color=Color(0.82,0.40,0.16,sunset_intensity*clampf(clock/sunset_seconds,0,1)) if sunset_enabled else Color.TRANSPARENT
	if logo:logo.modulate=logo_color*(1.0+logo_pulse_intensity*(0.5+0.5*sin(clock*0.8)))
	for i in 3:
		var bug:AnimatedSprite2D=get_node("Libelula%d"%i);bug.visible=insects_enabled;bug.frame=int(clock*10+i)%4
		bug.position=Vector2([664,1240,1832][i],205)+Vector2(sin(clock*0.7+i)*35,cos(clock*0.9+i)*18)
	for entry in footprint_pool:
		if entry.age<0:continue
		entry.age+=delta;entry.sprite.modulate.a=0.28*(1.0-clampf(entry.age/footprint_seconds,0,1))
		if entry.age>=footprint_seconds:entry.age=-1;entry.sprite.hide()
	for actor in cached_participants:
		if not is_instance_valid(actor):continue
		if actor is CharacterBody2D and actor.get("wet_left")!=null and actor.wet_left>0 and actor.velocity.length()>25:
			var key:=actor.get_instance_id()
			if clock-float(wet_tracks.get(key,-10.0))>0.42:
				wet_tracks[key]=clock;emit_footprint(actor.global_position+Vector2(0,12))

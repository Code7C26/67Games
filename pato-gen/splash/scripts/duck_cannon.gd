extends Node2D
## One upright turn. Equal impact budgets per park sector, with bounded water FX.
@export_group("Camara")
@export_range(0.0, 18.0, 0.5) var shake_intensity := 9.0
@export_range(0.05, 2.0, 0.05) var shake_duration := 0.6
@export_range(0.0, 5.0, 0.1) var stream_shake_intensity := 1.4
@export_group("Giro completo / agua moderada")
@export_range(24, 160, 1) var particle_amount := 96
@export_range(200.0, 1000.0, 10.0) var water_gravity := 600.0
@export_range(0.5, 1.0, 0.05) var droplet_lifetime := 0.8
@export_range(1, 4, 1) var impacts_per_sector := 3
@export_group("Impactos / parque")
@export_range(1.0, 30.0, 0.5) var puddle_dry_seconds := 10.0
@export_range(16.0, 100.0, 1.0) var wet_radius := 52.0
@export_range(0.1, 0.7, 0.01) var puddle_opacity := 0.24
const POOL_SIZE := 64
const PLAY_AREA := Rect2(64, 136, 1792, 800)
const SECTORS := 8
var jet: CPUParticles2D
var geyser: CPUParticles2D
var bubbles: CPUParticles2D
var wet_area: Area2D
var duck: AnimatedSprite2D
var original_frames: SpriteFrames
var original_scale: Vector2
var cannon_frames: SpriteFrames
var spin_frames: SpriteFrames
var spin_anchors: Array = []
var ambience: Node2D
var state := "calma"
var state_age := 0.0
var phase_length := 1.5
var fan_angle := 0.0
var fan_tween: Tween
var turn_progress := 0.0
var next_packet := 0
var target_plan: Array[Dictionary] = []
var floor_candidates: Array[Vector2] = []
var solid_rects: Array[Rect2] = []
var sector_landings: Array[int] = [0,0,0,0,0,0,0,0]
var emitted_this_turn := 0
var completed_turns := 0
var packets: Array[Dictionary] = []
var decals: Array[Dictionary] = []
var splash_pool: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var landing_count := 0
var max_live_decals := 0
var max_live_splashes := 0
var rejected_landings := 0
var active_time := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 419072
	jet = get_node("ChorroPico"); geyser = get_node("GeiserCabeza"); bubbles = get_node("BurbujasAviso")
	wet_area = get_node("ParqueMojado")
	duck = get_parent().get_node("04_Objetos/PatoGigante/Textura")
	original_frames = duck.sprite_frames; original_scale = duck.scale
	cannon_frames = load("res://splash/assets/pato_canon.tres")
	spin_frames = load("res://splash/assets/pato_giro.tres")
	spin_anchors = JSON.parse_string(FileAccess.get_file_as_string("res://splash/assets/pato_giro_anchors.json"))
	ambience = get_parent().get_node("08_Ambiente")
	var splash_frames: SpriteFrames = load("res://splash/assets/splash_corona.tres")
	var puddle_frames: SpriteFrames = load("res://splash/assets/charco_deck.tres")
	for i in POOL_SIZE:
		var decal := Sprite2D.new(); decal.name = "Charco%02d" % i
		decal.texture = puddle_frames.get_frame_texture("default", i % 3)
		decal.z_index = 0; decal.hide(); add_child(decal)
		decals.append({"sprite":decal, "age":-1.0})
		var splash := Sprite2D.new(); splash.name = "Impacto%02d" % i
		splash.z_index = 3; splash.hide(); add_child(splash)
		splash_pool.append({"sprite":splash, "age":-1.0, "frames":splash_frames})
	_update_origins()
	_collect_solids(get_parent())
	_cache_floor()
	_prepare_plan()

func _collect_solids(node: Node) -> void:
	if node is CollisionShape2D and node.get_parent() is StaticBody2D and not node.disabled and node.shape is RectangleShape2D:
		solid_rects.append(node.global_transform * Rect2(-node.shape.size*0.5,node.shape.size))
	for child in node.get_children(): _collect_solids(child)

func _floor_clear(point: Vector2) -> bool:
	if not PLAY_AREA.grow(-32.0).has_point(point): return false
	for rect in solid_rects:
		if rect.grow(30.0).has_point(point): return false
	return true

func _cache_floor() -> void:
	for y in range(168,905,24):
		for x in range(96,1825,24):
			var point := Vector2(x,y)
			if _floor_clear(point): floor_candidates.append(point)

func sector_of(point: Vector2) -> int:
	var normalized := (point-PLAY_AREA.get_center())/(PLAY_AREA.size*0.5)
	return int(fposmod(normalized.angle(),TAU)/(TAU/SECTORS)) % SECTORS

func _prepare_plan() -> void:
	target_plan.clear()
	var count := SECTORS*impacts_per_sector
	for i in count:
		var angle := (float(i)+0.5)/count*TAU
		var direction := Vector2.from_angle(angle)
		var band := lerpf(0.50,0.92,float(i%impacts_per_sector)/maxf(1.0,impacts_per_sector-1.0))
		var normalized := direction*(band/maxf(absf(direction.x),absf(direction.y)))
		var ideal := PLAY_AREA.get_center()+normalized*PLAY_AREA.size*0.5
		var sector := int(float(i)/impacts_per_sector)
		var best := Vector2.INF; var score := INF
		for candidate in floor_candidates:
			if sector_of(candidate)!=sector: continue
			var nearby := false
			for existing in target_plan:
				if candidate.distance_squared_to(existing.point)<72.0*72.0: nearby=true;break
			if nearby: continue
			var distance := candidate.distance_squared_to(ideal)
			if distance<score:score=distance;best=candidate
		assert(best.is_finite(),"No free splash site in park sector")
		target_plan.append({"point":best,"sector":sector,"heading":angle})

func _exit_tree() -> void:
	if fan_tween and fan_tween.is_valid(): fan_tween.kill()

func _update_origins() -> void:
	if state=="chapuzon" and duck.sprite_frames==spin_frames:
		var anchors: Dictionary = spin_anchors[duck.frame]
		jet.global_position = duck.to_global(Vector2(anchors.mouth[0],anchors.mouth[1])-Vector2(80,72)).round()
		geyser.global_position = duck.to_global(Vector2(anchors.head[0],anchors.head[1])-Vector2(80,72)).round()
	else:
		jet.global_position = duck.to_global(Vector2(67, 1)).round()
		geyser.global_position = duck.to_global(Vector2(17, -49)).round()
	bubbles.global_position = duck.to_global(Vector2(0, 46)).round()

func begin_warning(seconds: float) -> void:
	state = "aviso"; state_age = 0.0; phase_length = maxf(0.2, seconds)
	duck.set_meta("cannon_active", true); duck.stop(); duck.sprite_frames = cannon_frames; duck.frame = 1
	bubbles.emitting = true

func begin_fire(seconds: float) -> void:
	state = "chapuzon"; state_age = 0.0; phase_length = maxf(0.2, seconds); next_packet = 0; emitted_this_turn = 0
	if target_plan.size()!=SECTORS*impacts_per_sector: _prepare_plan()
	bubbles.emitting = false; duck.sprite_frames = spin_frames; duck.frame = 0
	jet.amount = particle_amount; jet.lifetime = droplet_lifetime
	jet.gravity = Vector2(0, water_gravity)
	_set_turn(0.0)
	jet.restart(); jet.emitting = true; geyser.restart(); geyser.emitting = true
	if fan_tween and fan_tween.is_valid(): fan_tween.kill()
	fan_tween = create_tween()
	fan_tween.tween_method(_set_turn, 0.0, 1.0, phase_length)

func _set_turn(progress: float) -> void:
	turn_progress = progress; fan_angle = progress*TAU
	duck.frame = int(progress*16.0+0.5)%16
	_update_origins()
	var index := mini(target_plan.size()-1,int(progress*target_plan.size()))
	var target: Vector2 = target_plan[index].point
	var velocity := (target-jet.global_position-Vector2(0,0.5*water_gravity*pow(droplet_lifetime,2.0)))/droplet_lifetime
	jet.direction = velocity.normalized()
	jet.initial_velocity_min = velocity.length()*0.985
	jet.initial_velocity_max = velocity.length()*1.015

func end_fire(seconds: float) -> void:
	while next_packet<target_plan.size(): _queue_packet(next_packet); next_packet+=1
	_set_turn(1.0); completed_turns+=1
	if fan_tween and fan_tween.is_valid(): fan_tween.kill()
	state = "reposo"; state_age = 0.0; phase_length = maxf(0.2, seconds)
	jet.emitting = false; geyser.emitting = false; duck.sprite_frames = cannon_frames; duck.frame = 0

func finish_event() -> void:
	state = "calma"; state_age = 0.0
	duck.sprite_frames = original_frames; duck.frame = 0; duck.scale = original_scale
	duck.set_meta("cannon_active", false); ambience.cannon_wave_boost = 1.0
	jet.emitting = false; geyser.emitting = false; bubbles.emitting = false

func _process(delta: float) -> void:
	state_age += delta; active_time += delta
	if state == "aviso":
		var charge := clampf(state_age / phase_length, 0.0, 1.0)
		var pulse := sin(charge * TAU * 2.0) * 0.035
		duck.scale = original_scale * Vector2(1.0 + charge * 0.07 + pulse, 1.0 + charge * 0.04 - pulse)
		ambience.cannon_wave_boost = 1.0 + charge * 2.5
	elif state == "chapuzon":
		duck.scale = original_scale * Vector2(1.03 + sin(state_age * 29.0) * 0.014, 0.99)
		ambience.cannon_wave_boost = 2.6
		if state_age > 0.30: geyser.emitting = false
		while next_packet<target_plan.size() and float(next_packet)/target_plan.size()<=state_age/phase_length:
			_queue_packet(next_packet); next_packet+=1
	elif state == "reposo":
		duck.scale = duck.scale.lerp(original_scale, minf(1.0, delta * 8.0))
		ambience.cannon_wave_boost = lerpf(ambience.cannon_wave_boost, 1.0, minf(1.0, delta * 5.0))
	_update_origins()
	for i in range(packets.size()-1, -1, -1):
		packets[i].age += delta
		if packets[i].age >= droplet_lifetime:
			_land(packets[i].point,packets[i].sector); packets.remove_at(i)
	_update_pools(delta)

func _queue_packet(index: int) -> void:
	var entry: Dictionary = target_plan[index]
	packets.append({"age":0.0, "point":entry.point, "sector":entry.sector})
	emitted_this_turn+=1

func _land(point: Vector2, sector: int = -1) -> void:
	if not _floor_clear(point): rejected_landings += 1; return
	var query := PhysicsPointQueryParameters2D.new(); query.position = point; query.collision_mask = 1
	query.collide_with_areas = false
	if not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty(): rejected_landings += 1; return
	landing_count += 1
	sector_landings[sector if sector>=0 else sector_of(point)] += 1
	var free_decal := _slot(decals)
	free_decal.age = 0.0; free_decal.sprite.global_position = point; free_decal.sprite.modulate.a = puddle_opacity; free_decal.sprite.show()
	var free_splash := _slot(splash_pool)
	free_splash.age = 0.0; free_splash.sprite.global_position = point + Vector2(0,-16); free_splash.sprite.show()
	for actor in wet_area.get_overlapping_bodies():
		if actor.is_in_group("splash_visitors") and actor.global_position.distance_to(point) <= wet_radius:
			get_parent().wet_visitor(actor)

func _slot(pool: Array[Dictionary]) -> Dictionary:
	for entry in pool:
		if entry.age < 0.0: return entry
	var oldest: Dictionary = pool[0]
	for entry in pool:
		if entry.age > oldest.age: oldest = entry
	return oldest

func _update_pools(delta: float) -> void:
	var live_decals := 0; var live_splashes := 0
	for entry in decals:
		if entry.age < 0.0: continue
		entry.age += delta
		if entry.age >= puddle_dry_seconds:
			entry.age = -1.0; entry.sprite.hide(); continue
		live_decals += 1
		entry.sprite.modulate.a = puddle_opacity * (1.0 - smoothstep(0.2, 1.0, entry.age / puddle_dry_seconds))
	for entry in splash_pool:
		if entry.age < 0.0: continue
		entry.age += delta
		if entry.age >= 0.48:
			entry.age = -1.0; entry.sprite.hide(); continue
		live_splashes += 1
		entry.sprite.texture = entry.frames.get_frame_texture("default", mini(3, int(entry.age / 0.12)))
	max_live_decals = maxi(max_live_decals, live_decals); max_live_splashes = maxi(max_live_splashes, live_splashes)

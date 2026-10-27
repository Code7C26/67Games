extends CharacterBody2D
## Reversible demonstration actor, with the current Bot capsule (r=11.5, h=32).
var routes: RefCounted
var serial := 0
var speed := 65.0
var sprite: AnimatedSprite2D
var path := PackedVector2Array()
var target_index := 0
var wait_left := 0.0
var travel := 0.0
var trips := 0
var stuck_for := 0.0
var max_stuck := 0.0
var recoveries := 0
var last_goal := -1
var paused := false
var role := "banador"
var attraction_left := 0.0
var attraction_goal := Vector2.ZERO
var attraction_visits := 0
var wet_left := 0.0
var wet_duration := 6.0
var reaction_left := 0.0
var wet_reaction := ""
var soaked_count := 0
var droplets: AnimatedSprite2D
var cover: Sprite2D

func _ready() -> void:
	collision_layer = 2
	# Soft separation between demo actors; solid collisions against the actual environment.
	# The production game's Bot.gd and character-to-character physics are not replaced.
	collision_mask = 1
	safe_margin = 0.08
	max_slides = 6
	add_to_group("splash_visitors")
	var sh := CapsuleShape2D.new()
	sh.radius = 11.5
	sh.height = 32.0
	var c := CollisionShape2D.new()
	c.shape = sh
	add_child(c)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://splash/assets/%s_%d.tres" % [role,serial%3+1])
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.animation = "Abajo"
	add_child(sprite)
	droplets = AnimatedSprite2D.new()
	droplets.sprite_frames = load("res://splash/assets/npc_empapado.tres")
	droplets.position.y = 2; droplets.hide(); add_child(droplets)
	cover = Sprite2D.new(); cover.texture = load("res://splash/assets/npc_cubrirse.png")
	cover.position.y = -3; cover.hide(); add_child(cover)
	speed = 58.0 + float(serial%7)*3.0
	wait_left = float(serial%5)*.12
	_new_trip()

func _new_trip() -> void:
	if attraction_left > 0:
		path = routes.path(global_position,attraction_goal)
		target_index = 0
		stuck_for = 0
		return
	var goal: int = (serial*3 + trips*5 + 1) % routes.goals.size()
	if goal == last_goal: goal = (goal+1)%routes.goals.size()
	last_goal = goal
	path = routes.path(global_position,routes.goals[goal])
	target_index = 0
	stuck_for = 0.0

func _physics_process(delta: float) -> void:
	if paused: return
	_update_soaked(delta)
	if reaction_left > 0.0 and wet_reaction == "cubrirse":
		velocity = Vector2.ZERO; sprite.stop(); return
	if attraction_left>0:
		attraction_left=maxf(0,attraction_left-delta)
		if attraction_left==0:
			wait_left=0
			_new_trip()
	if wait_left > 0.0:
		wait_left -= delta
		sprite.stop()
		return
	if target_index >= path.size():
		if attraction_left>0:
			velocity=Vector2.ZERO
			sprite.stop()
			return
		trips += 1
		wait_left = .5 + float(serial%4)*.15
		_new_trip()
		return
	# Skip only segments whose complete swept corridor is clear of static geometry.
	if target_index+1<path.size() and routes.clear_segment(global_position,path[target_index+1]):
		target_index += 1
	var next: Vector2 = path[target_index]
	var dir := global_position.direction_to(next)
	var distance_to_next := global_position.distance_to(next)
	var arrival := 22.0 if target_index==path.size()-1 else 9.0
	if distance_to_next<arrival:
		target_index += 1
		return
	var avoidance := Vector2.ZERO
	var passing := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("splash_visitors"):
		if other == self: continue
		var difference: Vector2 = global_position-other.global_position
		var distance := difference.length()
		if distance<36.0 and distance>0.01:
			avoidance += difference.normalized()*(36.0-distance)/36.0
		if distance<64.0 and distance>0.01 and dir.dot(-difference.normalized())>.45:
			# Both opposing streams keep to their right, avoiding symmetric head-on stalls.
			if other.velocity.dot(dir)<0.0:
				passing += dir.orthogonal()*(64.0-distance)/48.0
	var approach_weight := clampf(distance_to_next/40.0,.15,1.0)
	var run_multiplier := 1.65 if reaction_left > 0.0 and wet_reaction == "correr" else 1.0
	velocity = (dir+(avoidance*.65+passing)*approach_weight).normalized()*speed*run_multiplier
	var before := global_position
	move_and_slide()
	var moved := global_position.distance_to(before)
	travel += moved
	if moved < speed*delta*.15:
		stuck_for += delta
		max_stuck = maxf(max_stuck,stuck_for)
	else: stuck_for = maxf(0.0,stuck_for-delta*2.0)
	if stuck_for>1.8:
		recoveries += 1
		trips += 1
		_new_trip()
		wait_left = .15*float(serial%4)
	var anim := "Derecha" if velocity.x>0 else "Izquierda"
	if absf(velocity.y)>absf(velocity.x):anim = "Abajo" if velocity.y>0 else "Arriba"
	sprite.play(anim)

func attend_event(point: Vector2,duration: float) -> void:
	attraction_goal=routes.nearest_point(point)
	attraction_left=duration
	attraction_visits+=1
	wait_left=0
	_new_trip()

func leave_event() -> void:
	if attraction_left<=0: return
	attraction_left=0
	wait_left=0
	_new_trip()

func become_soaked(duration: float) -> void:
	wet_left = duration; wet_duration = duration; reaction_left = 1.5; soaked_count += 1
	wet_reaction = "correr" if serial % 2 == 0 else "cubrirse"
	leave_event(); wait_left = 0.0
	if wet_reaction == "correr":
		var away := Vector2(-180 if global_position.x < 1024 else 180, 72)
		path = routes.path(global_position, routes.nearest_point(global_position + away)); target_index = 0
	else: sprite.animation = "Abajo"
	_update_soaked(0.0)

func _update_soaked(delta: float) -> void:
	wet_left = maxf(0.0, wet_left-delta); reaction_left = maxf(0.0, reaction_left-delta)
	var strength := minf(1.0, wet_left)
	sprite.modulate = Color.WHITE.lerp(Color(0.60,0.72,0.82), strength)
	droplets.visible = wet_left > 0.0
	if droplets.visible:
		droplets.frame = int((wet_duration-wet_left)*8.0) % 4
		droplets.modulate.a = strength
	cover.visible = reaction_left > 0.0 and wet_reaction == "cubrirse"

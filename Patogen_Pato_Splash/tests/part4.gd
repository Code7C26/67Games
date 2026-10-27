extends Node
var failures: Array[String] = []
var report: Dictionary = {}
var demo: Node2D
var cannon: Node2D
var hooks: Array[int] = []
var natural_hits := 0
var reactions: Dictionary = {}
var phases: Dictionary = {}
var baseline_geometry: Dictionary = {}
var max_shake := 0.0
var peak_wave := 0.0
var peak_scale := 0.0
var max_pool_nodes := 0
var min_fan := 0.0
var max_fan := 0.0
var saw_geyser := false
var saw_bubbles := false
var warning_colours: Dictionary = {}
var event_times: Array[float] = []
var all_times: Array[float] = []
var geometry_samples := 0

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)

func signature(node: Node, result: Dictionary) -> void:
	if node is CollisionShape2D and node.get_parent() is StaticBody2D:
		result[str(node.get_path())] = [node.global_transform, node.disabled, node.shape.size if node.shape is RectangleShape2D else Vector2.ZERO]
	for child in node.get_children(): signature(child, result)

func stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate(); sorted.sort()
	var total := 0.0; var slow := 0
	for value in sorted: total += value; slow += 1 if value > 16.667 else 0
	return {"frames":sorted.size(),"mean_fps":1000.0*sorted.size()/total,"p99_ms":sorted[mini(sorted.size()-1,int(sorted.size()*0.99))],"max_ms":sorted[-1],"frames_over_16_667_ms":slow}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 0; DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var render_view := SubViewport.new(); render_view.size = Vector2i(1920,1080); render_view.world_2d = World2D.new()
	render_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(render_view)
	demo = load("res://demo/PatoSplashDemo.tscn").instantiate(); render_view.add_child(demo)
	var display := TextureRect.new(); display.texture = render_view.get_texture(); display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; display.size = get_viewport().get_visible_rect().size; add_child(display)
	demo.map.audio_enabled=false; demo.ambient.stop(); cannon=demo.map.cannon
	var actors := get_tree().get_nodes_in_group("splash_visitors")
	check(actors.size()==54,"NPC count changed")
	check(demo.camera.position==Vector2(960,540) and demo.camera.zoom==Vector2.ONE,"Fixed camera framing changed")
	check(demo.map.get_node("07_Caminos").tile_set.tile_size==Vector2i(32,32),"Tile size changed")
	check(cannon.jet is CPUParticles2D and cannon.geyser is CPUParticles2D,"Native CPU emitters missing")
	check(demo.map.get_node("05_Efectos").get_child_count()==0,"Legacy bucket splash remains")
	check(demo.map.warning_seconds==1.5 and demo.map.splash_seconds==1.5 and demo.map.settle_seconds==1.0,"Default event must total four seconds")
	check(demo.map.chime.stream is AudioStreamWAV and demo.map.chime.stream.get_length()>0.4,"Guard whistle missing")
	signature(demo.map,baseline_geometry)
	demo.map.infection_effect_requested.connect(func(_actor: Node,mode: int,_exposure: float):hooks.append(mode))
	demo.map.wet_visitor(actors[0]); demo.map.wet_visitor(actors[0]); check(hooks.is_empty(),"Neutral policy changes infection")
	for mode in [1,2]:
		demo.map.hit_this_cycle.clear(); demo.map.infection_effect=mode
		demo.map.wet_visitor(actors[0]); demo.map.wet_visitor(actors[0])
	check(hooks==[1,2],"Infection hook must emit once per actor/cycle with chosen policy")
	demo.map.infection_effect=0; demo.map.hit_this_cycle.clear()
	demo.map.npc_splashed.connect(func(actor: Node):natural_hits+=1;reactions[actor.wet_reaction]=true)
	# Warm up particles and audio imports once before collecting timings.
	demo._preview_event(); await get_tree().create_timer(4.5).timeout
	# Pause every subsystem in the middle of a real jet, including its Tween.
	demo._preview_event(); await get_tree().create_timer(1.85).timeout
	get_tree().paused=true
	var before := [cannon.state_age,cannon.fan_angle,cannon.active_time,demo.map.elapsed,cannon.packets.size(),actors[0].wet_left]
	await get_tree().create_timer(0.25,true).timeout
	check(before==[cannon.state_age,cannon.fan_angle,cannon.active_time,demo.map.elapsed,cannon.packets.size(),actors[0].wet_left],"Pause leaves event timers or Tween running")
	get_tree().paused=false
	await get_tree().create_timer(2.5).timeout
	demo.map.calm_seconds=4.0
	var beginning := Time.get_ticks_usec(); var previous := beginning; var last_sample := 0.0
	print("PART4_BENCHMARK_STARTED: 54 NPC, 1920x1080, repeated cannon events, real 60Hz physics")
	while float(Time.get_ticks_usec()-beginning)/1000000.0<40.0:
		await get_tree().process_frame
		var now := Time.get_ticks_usec(); var duration := float(now-previous)/1000.0; previous=now
		all_times.append(duration)
		if demo.map.phase!="calma":event_times.append(duration)
		phases[demo.map.phase]=true
		max_shake=maxf(max_shake,maxf(absf(demo.camera.offset.x),absf(demo.camera.offset.y)))
		peak_wave=maxf(peak_wave,cannon.ambience.cannon_wave_boost);peak_scale=maxf(peak_scale,cannon.duck.scale.x/cannon.original_scale.x)
		if cannon.state=="chapuzon":min_fan=minf(min_fan,cannon.fan_angle);max_fan=maxf(max_fan,cannon.fan_angle)
		saw_geyser=saw_geyser or cannon.geyser.emitting;saw_bubbles=saw_bubbles or cannon.bubbles.emitting
		if demo.map.phase=="aviso":warning_colours[demo.header_panel.color.to_html()]=true
		var age := float(now-beginning)/1000000.0
		if age-last_sample>0.5:
			last_sample=age;geometry_samples+=1
			var current: Dictionary={};signature(demo.map,current);check(current==baseline_geometry,"Event moves solid geometry")
			max_pool_nodes=maxi(max_pool_nodes,cannon.get_child_count())
			for entry in cannon.decals:
				if entry.age>=0.0:check(cannon.DECK.has_point(entry.sprite.global_position),"Puddle outside terrace")
	# Let the last event and every wet effect expire, keeping the full NPC simulation alive.
	demo.map.calm_seconds=120.0
	await get_tree().create_timer(15.0).timeout
	check(cannon.state=="calma" and cannon.packets.is_empty(),"Event fails to return to idle")
	check(cannon.duck.sprite_frames==cannon.original_frames and cannon.duck.scale==cannon.original_scale,"Duck never returns to its normal sprite/scale")
	check(demo.camera.offset==Vector2.ZERO,"Camera shake persists after firing")
	for entry in cannon.decals:check(entry.age<0.0 and not entry.sprite.visible,"Puddle does not dry")
	for actor in actors:
		check(actor.wet_left==0.0 and actor.sprite.modulate==Color.WHITE and not actor.cover.visible and not actor.droplets.visible,"NPC stays wet or covered")
	check(natural_hits>=2 and reactions.has("correr") and reactions.has("cubrirse"),"Missing actual impact reactions")
	check(cannon.landing_count>=50,"Too few water impacts")
	check(min_fan<-.50 and max_fan>.50,"Fan does not sweep left to right")
	check(peak_wave>3.0 and peak_scale>1.05 and saw_geyser and saw_bubbles,"Charge or water effects missing")
	check(warning_colours.size()==2,"HUD does not flash red during warning")
	check(max_shake>=8.0 and max_shake<=11.0,"Camera kick is not strong or exceeds its limit")
	check(cannon.max_live_decals<=64 and cannon.max_live_splashes<=64 and max_pool_nodes==132,"Effect pools grow without bound")
	report.event=stats(event_times);report.full_run=stats(all_times)
	check(report.event.mean_fps>=60.0 and report.event.p99_ms<16.667,"Event misses 60 FPS at p99")
	check(hooks==[1,2],"Default gameplay unexpectedly emits an infection effect")
	report.actors=54;report.render_size=[1920,1080];report.physics_hz=Engine.physics_ticks_per_second
	report.natural_hits=natural_hits;report.reactions=reactions.keys();report.impacts=cannon.landing_count
	report.max_live_decals=cannon.max_live_decals;report.max_live_splashes=cannon.max_live_splashes
	report.max_shake_px=max_shake;report.fan_degrees=[rad_to_deg(min_fan),rad_to_deg(max_fan)]
	report.pause_checked=true;report.dry_and_recovery_checked=true;report.infection_modes_checked=hooks
	report.geometry_samples=geometry_samples;report.phases=phases.keys();report.gpu=RenderingServer.get_video_adapter_name()
	report.passed=failures.is_empty();report.failures=failures
	var file := FileAccess.open("res://tests/part4_validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PART4_VALIDATION ",JSON.stringify(report))
	await get_tree().create_timer(3.0).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

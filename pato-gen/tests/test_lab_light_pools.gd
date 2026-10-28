extends SceneTree
## Real rendered tests: a wall must block light, NPC bodies must receive it,
## outlines/HUD must stay readable, and late-spawned guests must be configured.
var checks := 0
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
	else: print("PASS ",message)
func shot() -> Image:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func brightness(image: Image, item: CanvasItem, point: Vector2) -> float:
	var pixel := Vector2i(item.get_global_transform_with_canvas()*point)
	var sum := 0.0
	for y in range(-2,3):
		for x in range(-2,3):
			var color := image.get_pixelv(pixel+Vector2i(x,y))
			sum+=color.get_luminance()
	return sum/25.0
func run() -> void:
	root.size = Vector2i(1920,1080)
	var boot := root.get_node("PatogenOnboarding")
	boot.requested_mode = "direct"
	boot.profile.data.reduced_motion = true
	seed(20261028)
	var host = load("res://scenes/Laboratorio.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	if not host.map_is_ready: await host.map_ready
	host.timer_inicio.stop()
	var lab = host.get_node("Environment")
	var finish = lab.get_node("SceneryFinish")
	check(lab.fixtures.size()==12,"Lab uses twelve larger ceiling light pools")
	check(lab.fixture_diameter>280.0 and lab.light_energy<1.25,"Lab larger pools have reduced intensity")
	var shadows := true
	for light in lab.get_node("08_Luces").get_children():
		if light is PointLight2D:
			shadows=shadows and light.shadow_enabled and light.shadow_color.a==1.0 and light.shadow_item_cull_mask==2 and light.range_item_cull_mask==3
	check(shadows,"Every ceiling and equipment light blocks at scenery occluders")
	var origins_clear := true
	for fixture in lab.fixtures:
		for occluder in finish.get_node("SceneryOcclusion").get_children():
			if Geometry2D.is_point_in_polygon(occluder.to_local(fixture.light.global_position),occluder.occluder.polygon): origins_clear=false
	check(origins_clear,"Ceiling lights are outside solid wall and equipment footprints")
	check(lab.polished_props>=35,"Lab applies polished variants throughout its equipment")
	for actor in get_nodes_in_group("bots"):
		actor.set_physics_process(false)
		actor.timer_direccion.stop()
		actor.animated_sprite.stop()
	var actor = get_nodes_in_group("bots")[0]
	var body: AnimatedSprite2D = actor.animated_sprite
	check(body.material.get_shader_parameter("local_light_response")==lab.npc_light_response,"NPC body opts into local lighting")
	check(body.sprite_frames.get_meta("outline_padding",false),"NPC atlas padding is preserved")
	var replica = load("res://scenes/Bot.tscn").instantiate()
	host.get_node("Bots").add_child(replica)
	for i in 3: await process_frame
	check(replica.material_borde_infeccion.get_shader_parameter("environment_ambient")==lab.npc_ambient,"Late-spawned NPCs receive the same lighting settings")
	replica.queue_free()
	for i in 3: await process_frame
	# Freeze animations/timers; native lighting continues rendering normally.
	host.process_mode = Node.PROCESS_MODE_DISABLED
	for light in lab.get_node("08_Luces").get_children():
		if light is Light2D: light.enabled=false
	var wall: CollisionShape2D
	for shape in lab.get_node("03_Paredes_y_colisiones").find_children("*","CollisionShape2D",true,false):
		var rect: Rect2 = shape.shape.get_rect()
		if rect.size.x>120 and rect.size.y<40 and shape.global_position.y>390 and shape.global_position.y<440 and shape.global_position.x>300 and shape.global_position.x<400:
			wall=shape; break
	check(wall!=null,"Rendered occlusion test uses an actual corridor wall")
	if wall:
		var rect: Rect2 = wall.shape.get_rect()
		var center: Vector2 = lab.to_local(wall.global_position)
		var light: PointLight2D = lab.fixtures[0].light
		light.position=center+Vector2(0,80)
		light.enabled=true
		light.energy=1.0
		# Small lit swatches isolate the renderer from authored floor colors/props.
		var swatches: Array[ColorRect] = []
		# The second swatch sits below the real corridor bench, not inside it.
		for offset in [-35.0,55.0]:
			var swatch:=ColorRect.new()
			swatch.position=center+Vector2(-8,offset-8)
			swatch.size=Vector2(16,16)
			swatch.color=Color(0.35,0.35,0.35)
			swatch.light_mask=2
			swatch.z_index=30
			lab.add_child(swatch)
			swatches.append(swatch)
		var shadowed: Image = await shot()
		light.shadow_enabled=false
		var leaking: Image = await shot()
		light.enabled=false
		var dark: Image = await shot()
		var blocked := brightness(shadowed,swatches[0],Vector2(8,8))
		var unblocked := brightness(leaking,swatches[0],Vector2(8,8))
		var ambient := brightness(dark,swatches[0],Vector2(8,8))
		print("LAB_WALL_PIXELS blocked=",blocked," no_shadow=",unblocked," ambient=",ambient)
		check(unblocked>ambient+0.01,"The control light would cross the real wall with shadows disabled")
		check(absf(blocked-ambient)<0.003,"The real wall prevents light leaking into the next room")
		check(brightness(shadowed,swatches[1],Vector2(8,8))>brightness(dark,swatches[1],Vector2(8,8))+0.01,"The same light illuminates its own room")
		var hud_before := shadowed.get_region(Rect2i(16,12,250,32))
		var hud_after := dark.get_region(Rect2i(16,12,250,32))
		check(hud_before.get_data()==hud_after.get_data(),"Local lights leave the HUD pixels unchanged")
	check(lab.fixture_factor(0,0.01,true)==1.0,"Reduced motion disables ceiling flicker")
	host.queue_free()
	for i in 4: await process_frame
	print("LAB_LIGHT_POOLS ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)

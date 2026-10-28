extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func difference(a: Color, b: Color) -> float:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))
func shot() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func run() -> void:
	root.size = Vector2i(1920,1080)
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		root.get_node("PatogenOnboarding").profile.data.reduced_motion = true
		seed(20261028)
		var host = load("res://scenes/"+map_name+".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		for actor in get_nodes_in_group("bots"):
			actor.set_physics_process(false)
			actor.timer_direccion.stop()
			actor.animated_sprite.stop()
		for actor in get_nodes_in_group("patos"):
			actor.set_physics_process(false)
			actor.animated_sprite.stop()
		for i in 5: await process_frame
		# Freeze scenery actors as well, so a walking guest cannot cross a sample.
		host.process_mode = Node.PROCESS_MODE_DISABLED
		for i in 2: await process_frame
		var before: Image = await shot()
		var samples: Array[Vector2i] = []
		for actor in get_nodes_in_group("bots")+get_nodes_in_group("patos"):
			var sprite: AnimatedSprite2D = actor.animated_sprite
			var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
			var image := texture.get_image()
			var origin: Vector2 = sprite.offset-(texture.get_size()*0.5 if sprite.centered else Vector2.ZERO)
			for y in range(6,image.get_height()-6,3):
				for x in range(6,image.get_width()-6,3):
					var source := image.get_pixel(x,y)
					if source.a<0.99: continue
					var pixel := Vector2i((sprite.get_global_transform_with_canvas()*(origin+Vector2(x+0.5,y+0.5))).floor())
					if pixel.x<0 or pixel.y<0 or pixel.x>=before.get_width() or pixel.y>=before.get_height(): continue
					var visible := before.get_pixelv(pixel)
					# Skip pixels hidden by authored props or existing floating labels.
					if minf(difference(visible,source),difference(visible,source.srgb_to_linear()))<0.025: samples.append(pixel)
		for light in host.find_children("*","Light2D",true,false): light.enabled = false
		for i in 3: await process_frame
		var after: Image = await shot()
		var changed := 0
		var maximum := 0.0
		for pixel in samples:
			var delta := difference(before.get_pixelv(pixel),after.get_pixelv(pixel))
			maximum = maxf(maximum,delta)
			if delta>0.01: changed+=1
		var ok := samples.size()>300 and changed==0
		if not ok: failures+=1
		print("VISUAL_ACTOR_PIXELS ",map_name," samples=",samples.size()," changed=",changed," maximum_delta=",maximum," ","PASS" if ok else "FAIL")
		host.queue_free()
		for i in 4: await process_frame
	print("VISUAL_ACTOR_RESULT ",failures," failures")
	quit(1 if failures else 0)

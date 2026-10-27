extends Node
var failures: Array[String]=[]
var report: Dictionary={}
func check(ok: bool,message: String) -> void:
	if not ok:failures.append(message);push_error(message)
func shapes(node: Node, top: Node, result: Array) -> void:
	if node is CollisionShape2D and node.get_parent() is StaticBody2D and not node.disabled:
		result.append({"path":str(top.get_path_to(node)),"x":node.global_position.x,"y":node.global_position.y,"w":node.shape.size.x,"h":node.shape.size.y,"disabled":false})
	for child in node.get_children():shapes(child,top,result)
func nearest_in_tree(node: CanvasItem) -> bool:
	var parent: Node=node
	while parent!=null:
		if parent is CanvasItem and parent.texture_filter!=CanvasItem.TEXTURE_FILTER_PARENT_NODE:
			return parent.texture_filter==CanvasItem.TEXTURE_FILTER_NEAREST
		parent=parent.get_parent()
	return ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")==0
func check_filters(node: Node) -> int:
	var count:=0
	if node is Sprite2D or node is AnimatedSprite2D or node is TileMapLayer:
		check(nearest_in_tree(node),"Texture uses a filter other than Nearest: "+str(node.get_path()))
		count+=1
	for child in node.get_children():count+=check_filters(child)
	return count
func _ready() -> void:
	var view:=SubViewport.new();view.size=Vector2i(1920,1080);view.world_2d=World2D.new();view.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;add_child(view)
	var demo=load("res://demo/PatoSplashDemo.tscn").instantiate();view.add_child(demo)
	demo.map.audio_enabled=false;demo.ambient.stop();demo.shake_enabled=false
	for f in 12:await get_tree().physics_frame
	check(demo.camera.zoom==Vector2.ONE,"Camera must show the entire map at zoom 1")
	check(demo.camera.position==Vector2(960,540),"Camera is no longer fixed at map center")
	check(view.size==Vector2i(1920,1080),"Viewport resolution is not 1920x1080")
	check(demo.map.get_node("01_Pisos").tile_set.tile_size==Vector2i(32,32),"Tile size changed")
	var physics_before: Array=JSON.parse_string(FileAccess.get_file_as_string("res://tests/part1_baseline_geometry.json"))
	physics_before=physics_before.filter(func(item):return not item.disabled)
	var physics_after: Array=[];shapes(demo.map,demo.map,physics_after)
	check(physics_before==physics_after,"Active map collisions changed during visual bug fixes")
	report.active_collisions_unchanged=physics_before==physics_after
	var objects: Node=demo.map.get_node("04_Objetos")
	var actual_streams: Array=[]
	for marker_name in ["SalidaIzquierda","SalidaDerecha"]:
		var marker: Node2D=objects.get_node("ToboganesDobles/"+marker_name)
		var stream: AnimatedSprite2D=marker.get_node("CaidaAgua")
		actual_streams.append(marker.global_position)
		check(stream.sprite_frames.get_frame_count("default")==8,"Missing outlet animation frames")
		check(stream.sprite_frames.get_animation_speed("default")==10,"Wrong outlet flow timing")
		check(stream.is_playing(),"Outlet water is not animated")
		for f in 8:
			var image: Image=stream.sprite_frames.get_frame_texture("default",f).get_image()
			check(image.get_pixel(24,0).a>0,"Water starts away from the outlet")
	check(actual_streams==[Vector2(317,380),Vector2(387,383)],"Water is not anchored at the two real slide outlets")
	report.outlets=actual_streams.map(func(pos):return [pos.x,pos.y])
	var ladder_pools:={"escalera_10":"PiletaToboganes","escalera_11":"PiletaCentral","escalera_12":"PiletaCentral","escalera_13":"PiletaInfantil"}
	var ladder_report: Array=[]
	for ladder_name in ladder_pools:
		var ladder: Node2D=objects.get_node(ladder_name)
		var texture: Sprite2D=ladder.get_node("Textura")
		var top: Vector2=texture.to_global(texture.get_rect().position)
		var pool: Node2D=demo.map.get_node("02_Piletas/"+ladder_pools[ladder_name])
		check(is_equal_approx(top.y,pool.global_position.y-8),"Ladder not mounted on the coping: "+ladder_name)
		check(ladder.get_node("Colision/Shape").disabled,"Ladder is blocking a walkway")
		ladder_report.append({"name":ladder_name,"top":[top.x,top.y],"pool_edge_y":pool.global_position.y})
	report.ladders=ladder_report
	for explorer in demo.explorers:
		check(explorer.sprite.scale==Vector2(2,2),"Player duck is still too small")
		check(explorer.sprite.sprite_frames.get_frame_texture("Abajo",0).get_size()==Vector2(32,32),"Original duck frames changed")
		for child in explorer.get_children():
			if child is CollisionShape2D:check(is_equal_approx(child.shape.radius,15.6),"Player collision radius changed")
	report.player_frame_screen_size=[64,64]
	var giant: AnimatedSprite2D=objects.get_node("PatoGigante/Textura")
	check(giant.scale==Vector2(1.5,1.5),"Inflatable duck visual scaling was not saved")
	report.inflatable_frame_screen_size=[240,216]
	report.nearest_nodes_checked=check_filters(demo)
	# Move the first duck through an open lane; rendered scale must not enlarge physics.
	var start: Vector2=demo.explorers[0].position
	var press:=InputEventKey.new();press.physical_keycode=KEY_D;press.pressed=true;Input.parse_input_event(press)
	for f in 24:await get_tree().physics_frame
	press=InputEventKey.new();press.physical_keycode=KEY_D;press.pressed=false;Input.parse_input_event(press)
	check(demo.explorers[0].position.x>start.x+50,"Scaled duck cannot move through its original lane")
	demo.explorers[0].position=start
	await get_tree().process_frame;await RenderingServer.frame_post_draw
	check(view.get_texture().get_image().save_png("res://captures/parte1_1920x1080.png")==OK,"Cannot save native screenshot")
	# Freeze the crowd, retain real independent outlet animation for the detail sequence.
	for actor in get_tree().get_nodes_in_group("splash_visitors"):actor.set_physics_process(false)
	for frame_index in 8:
		for marker_name in ["SalidaIzquierda","SalidaDerecha"]:
			var stream: AnimatedSprite2D=objects.get_node("ToboganesDobles/"+marker_name+"/CaidaAgua")
			stream.pause();stream.frame=(frame_index+(4 if marker_name=="SalidaDerecha" else 0))%8
		await get_tree().process_frame;await RenderingServer.frame_post_draw
		view.get_texture().get_image().get_region(Rect2i(200,338,336,110)).save_png("res://captures/parte1_salida_%02d.png"%frame_index)
	report.passed=failures.is_empty();report.failures=failures
	var file:=FileAccess.open("res://tests/part1_validation.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PART1_VALIDATION ",JSON.stringify(report))
	view.render_target_update_mode=SubViewport.UPDATE_DISABLED
	# Keep debug output available for the MCP caller to inspect, then exit.
	await get_tree().create_timer(12).timeout
	get_tree().quit(0 if failures.is_empty() else 1)

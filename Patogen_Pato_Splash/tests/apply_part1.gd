extends Node
## Applies only part 1 fixes using native Godot scene/resource APIs.
func _ready() -> void:
	call_deferred("apply_fixes")
func own_children(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner=scene_root
		own_children(child,scene_root)
func save_scene(resource: PackedScene, instance: Node, path: String) -> void:
	assert(resource.pack(instance)==OK)
	assert(ResourceSaver.save(resource,path)==OK)
	instance.free()
func apply_fixes() -> void:
	var baseline: Node=load("res://splash/scenes/PatoSplash.tscn").instantiate()
	var shapes: Array=[];collect_shapes(baseline,baseline,shapes)
	if not FileAccess.file_exists("res://tests/part1_baseline_geometry.json"):
		var baseline_file:=FileAccess.open("res://tests/part1_baseline_geometry.json",FileAccess.WRITE);baseline_file.store_string(JSON.stringify(shapes,"\t"));baseline_file.close()
	baseline.free()
	var slide_path:="res://splash/scenes/objetos/toboganes.tscn"
	var slide_resource: PackedScene=load(slide_path)
	var slides:=slide_resource.instantiate()
	var water:=SpriteFrames.new();water.set_animation_speed("default",10)
	var texture: Texture2D=load("res://splash/assets/salida_tobogan.png")
	assert(texture!=null)
	for f in 8:
		var atlas:=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2(f*48,0,48,56);water.add_frame("default",atlas)
	var locations: Array[Vector2]=[Vector2(-51,-20),Vector2(19,-17)]
	for i in 2:
		var marker_name:="SalidaIzquierda" if i==0 else "SalidaDerecha"
		var old:=slides.get_node_or_null(marker_name)
		if old:slides.remove_child(old);old.free()
		var marker:=Marker2D.new();marker.name=marker_name;marker.position=locations[i];slides.add_child(marker)
		var stream:=AnimatedSprite2D.new();stream.name="CaidaAgua";stream.position=Vector2(-24,0);stream.centered=false;stream.sprite_frames=water;stream.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;stream.autoplay="default";stream.frame=i*4;marker.add_child(stream)
	own_children(slides,slides);save_scene(slide_resource,slides,slide_path)
	var duck_path:="res://splash/scenes/objetos/pato_gigante.tscn"
	var duck_resource: PackedScene=load(duck_path);var duck:=duck_resource.instantiate()
	duck.get_node("Textura").scale=Vector2(1.5,1.5)
	save_scene(duck_resource,duck,duck_path)
	var map_path:="res://splash/scenes/PatoSplash.tscn"
	var map_resource: PackedScene=load(map_path);var map:=map_resource.instantiate()
	var positions:={"escalera_10":Vector2(472,360),"escalera_11":Vector2(732,440),"escalera_12":Vector2(1136,440),"escalera_13":Vector2(1664,360)}
	for object_name in positions:
		var item: Node2D=map.get_node("04_Objetos/"+object_name)
		item.position=positions[object_name]+Vector2(16,48)
		assert(item.get_node("Colision/Shape").disabled)
	save_scene(map_resource,map,map_path)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/layout.json"))
	var index:=10
	for prop in data.props:
		if prop.asset=="escalera":
			var pos: Vector2=positions["escalera_"+str(index)];prop.x=pos.x;prop.y=pos.y;index+=1
	var file:=FileAccess.open("res://tools/layout.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"  "));file.close()
	print("PART1_APPLIED: two independent streams, 4 edge ladders, visual-only duck scales")
	get_tree().quit()
func collect_shapes(node: Node, top: Node, result: Array) -> void:
	if node is CollisionShape2D:
		result.append({"path":str(top.get_path_to(node)),"x":node.global_position.x,"y":node.global_position.y,"w":node.shape.size.x,"h":node.shape.size.y,"disabled":node.disabled})
	for child in node.get_children():collect_shapes(child,top,result)

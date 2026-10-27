extends RefCounted
## Native, repeatable authoring pass. Preserves part-1 outlets, ladders and physics.
var root: Node2D
var objects: Node2D
func own(node: Node, owner_root: Node) -> void:
	for child in node.get_children():
		child.owner=owner_root
		if child.scene_file_path.is_empty():own(child,owner_root)
func save(node: Node,path: String) -> void:
	own(node,node)
	var resource:=PackedScene.new();assert(resource.pack(node)==OK);assert(ResourceSaver.save(resource,path)==OK)
func remove_old(parent: Node,node_name: String) -> void:
	var previous:=parent.get_node_or_null(node_name)
	if previous:parent.remove_child(previous);previous.free()
func sprite_frames(asset: String,w: int,h: int,count: int,speed: float) -> SpriteFrames:
	var result:=SpriteFrames.new();result.set_animation_speed("default",speed)
	var image: Texture2D=load("res://splash/assets/"+asset+".png")
	for f in count:
		var atlas:=AtlasTexture.new();atlas.atlas=image;atlas.region=Rect2(f*w,0,w,h);result.add_frame("default",atlas)
	return result
func solid(parent: Node,rect: Rect2) -> void:
	var body:=StaticBody2D.new();body.name="Colision";body.collision_layer=1;body.collision_mask=0;parent.add_child(body)
	var shape:=CollisionShape2D.new();shape.name="Shape";var box:=RectangleShape2D.new();box.size=rect.size;shape.shape=box;shape.position=rect.get_center();body.add_child(shape)
func create_prefab(asset: String,size_: Vector2,foot: Rect2) -> void:
	var node:=Node2D.new();node.name=asset.to_pascal_case();node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var texture:=Sprite2D.new();texture.name="Textura";texture.texture=load("res://splash/assets/"+asset+".png");texture.position=Vector2(0,-size_.y*.5);node.add_child(texture)
	if foot.has_area():solid(node,Rect2(foot.position-Vector2(size_.x*.5,size_.y),foot.size))
	save(node,"res://splash/scenes/objetos/"+asset+".tscn");node.free()
func create_planter() -> void:
	var node:=Node2D.new();node.name="PalmeraCantero";node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var base:=Sprite2D.new();base.name="TierraYLadrillos";base.texture=load("res://splash/assets/cantero_palmera.png");node.add_child(base)
	var palm: Node2D=load("res://splash/scenes/objetos/palmera.tscn").instantiate();palm.name="Palmera";palm.position=Vector2(0,12);node.add_child(palm);palm.owner=node;node.set_editable_instance(palm,true);palm.get_node("Colision/Shape").disabled=true
	solid(node,Rect2(-32,-32,64,64));node.set_meta("tile_footprint",Vector2i(2,2));save(node,"res://splash/scenes/objetos/palmera_cantero.tscn");node.free()
func place(asset: String,node_name: String,top_left: Vector2,size_: Vector2) -> Node2D:
	remove_old(objects,node_name)
	var item: Node2D=load("res://splash/scenes/objetos/"+asset+".tscn").instantiate();item.name=node_name;item.position=top_left+Vector2(size_.x*.5,size_.y);objects.add_child(item);item.owner=root;return item
func duck_frames() -> void:
	var frames:=SpriteFrames.new();frames.remove_animation("default");var texture: Texture2D=load("res://splash/assets/pato_parque.png")
	for d in 4:
		var label_: String=["Abajo","Arriba","Derecha","Izquierda"][d];frames.add_animation(label_);frames.set_animation_speed(label_,8)
		for f in 8:
			var atlas:=AtlasTexture.new();atlas.atlas=texture;atlas.region=Rect2((d*8+f)*32,0,32,32);frames.add_frame(label_,atlas)
	assert(ResourceSaver.save(frames,"res://splash/assets/pato_parque.tres")==OK)
func collect_obstacles(node: Node,result: Array[Rect2]) -> void:
	if node is CollisionShape2D and node.get_parent() is StaticBody2D and not node.disabled:
		var shape: RectangleShape2D=node.shape;result.append(node.global_transform*Rect2(-shape.size*.5,shape.size))
	for child in node.get_children():collect_obstacles(child,result)
func roads() -> void:
	remove_old(root,"07_Caminos")
	var tiles:=TileSet.new();tiles.tile_size=Vector2i(32,32);tiles.add_terrain_set(0);tiles.set_terrain_set_mode(0,TileSet.TERRAIN_MODE_MATCH_SIDES);tiles.add_terrain(0,0);tiles.set_terrain_name(0,0,"Paseo del parque");tiles.set_terrain_color(0,0,Color("c9d9dc"))
	var atlas:=TileSetAtlasSource.new();atlas.texture=load("res://splash/assets/caminos_32.png");atlas.texture_region_size=Vector2i(32,32)
	var peers: Array=[TileSet.CELL_NEIGHBOR_TOP_SIDE,TileSet.CELL_NEIGHBOR_RIGHT_SIDE,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,TileSet.CELL_NEIGHBOR_LEFT_SIDE]
	for mask in 16:
		atlas.create_tile(Vector2i(mask,0));var tile:=atlas.get_tile_data(Vector2i(mask,0),0);tile.terrain_set=0;tile.terrain=0
		for bit in 4:tile.set_terrain_peering_bit(peers[bit],0 if mask&(1<<bit) else -1)
	tiles.add_source(atlas,0);assert(ResourceSaver.save(tiles,"res://splash/assets/caminos_32.tres")==OK)
	var layer:=TileMapLayer.new();layer.name="07_Caminos";layer.tile_set=tiles;layer.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;root.add_child(layer);root.move_child(layer,1);layer.owner=root
	var obstacles: Array[Rect2]=[];collect_obstacles(root,obstacles)
	var strips: Array[Rect2]=[
		Rect2(576,288,96,544),Rect2(1248,288,96,544),Rect2(544,336,832,96),Rect2(128,704,1664,96),Rect2(880,752,160,176),
		Rect2(144,560,480,64),Rect2(1296,560,480,64),Rect2(1296,296,480,64),
		Rect2(128,624,496,64),Rect2(496,656,64,224),Rect2(400,848,224,64),Rect2(400,864,64,64),
		Rect2(1296,800,352,64),Rect2(1536,824,96,104)]
	var cells: Dictionary={}
	for y in range(4,30):
		for x in range(2,58):
			var point:=Vector2(x*32+16,y*32+16);var inside:=false
			for strip in strips:
				if strip.has_point(point):inside=true;break
			if not inside:continue
			for obstacle in obstacles:
				if obstacle.grow(18).has_point(point):inside=false;break
			if inside:cells[Vector2i(x,y)]=true
	# Keep the whole promenade in one connected component; no decorative dead islands.
	var entry:=Vector2i(30,27);var reached: Dictionary={entry:true};var queue: Array[Vector2i]=[entry];var cursor:=0
	while cursor<queue.size():
		var id: Vector2i=queue[cursor];cursor+=1
		for direction in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var neighbor: Vector2i=id+direction
			if cells.has(neighbor) and not reached.has(neighbor):reached[neighbor]=true;queue.append(neighbor)
	for id in queue:
		var mask:=0
		for bit in 4:
			var direction: Vector2i=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT][bit]
			if reached.has(id+direction):mask|=1<<bit
		layer.set_cell(id,0,Vector2i(mask,0))
	layer.set_meta("connected_cells",queue.size());layer.set_meta("route_width_px",96)
func apply(map_root: Node2D,data: Dictionary) -> void:
	root=map_root;objects=root.get_node("04_Objetos")
	create_prefab("cartel_piso_mojado",Vector2(32,48),Rect2());create_prefab("cartel_no_pisar",Vector2(32,48),Rect2())
	create_prefab("toallero",Vector2(64,64),Rect2(8,18,48,40));create_prefab("entrada_tickets",Vector2(48,64),Rect2(8,48,32,12));create_planter();duck_frames()
	var count:=0
	for prop in data.props:
		if prop.asset!="palmera":continue
		count+=1;remove_old(objects,prop.name)
		var center:=Vector2(roundf((prop.x+48)/32.0)*32,roundf((prop.y+114)/32.0)*32)
		center.x=clampf(center.x,96,1824);center.y=clampf(center.y,160,928)
		var name_:="CanteroPalmera_%02d"%count;remove_old(objects,name_)
		var palm: Node2D=load("res://splash/scenes/objetos/palmera_cantero.tscn").instantiate();palm.name=name_;palm.position=center;objects.add_child(palm);palm.owner=root
	var signs: Array=[Vector2(528,384),Vector2(680,640),Vector2(1232,640),Vector2(1736,384),Vector2(1136,280),Vector2(160,320),Vector2(1312,504),Vector2(512,504)]
	for i in signs.size():place("cartel_no_pisar" if i%3==2 else "cartel_piso_mojado","Aviso_%02d"%i,signs[i],Vector2(32,48))
	place("toallero","ToallasReposeras",Vector2(80,736),Vector2(64,64))
	place("entrada_tickets","TicketsOeste",Vector2(736,896),Vector2(48,64));place("entrada_tickets","TicketsEste",Vector2(1136,896),Vector2(48,64))
	place("duchas","DuchasToboganes",Vector2(528,160),Vector2(128,96))
	place("banco","BancoPaseoOeste",Vector2(80,320),Vector2(64,32));place("banco","BancoPaseoEste",Vector2(1776,320),Vector2(64,32))
	roads();root.set_meta("art_revision","parte2");root.set_meta("planter_count",count)

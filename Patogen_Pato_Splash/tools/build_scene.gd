extends SceneTree
var data: Dictionary
var map_root: Node2D
var objects: Node2D
var font: Font
func _initialize() -> void: call_deferred("build")
func own_tree(n: Node, own: Node) -> void:
	for c in n.get_children():
		c.owner=own
		if c.scene_file_path.is_empty(): own_tree(c,own)
func pack(n: Node, path: String) -> void:
	own_tree(n,n)
	var ps:=PackedScene.new()
	assert(ps.pack(n)==OK)
	assert(ResourceSaver.save(ps,path)==OK)
func group(n: String,parent: Node) -> Node2D:
	var g:=Node2D.new();g.name=n;parent.add_child(g);return g
func rect(parent: Node,r: Rect2,c: Color,n: String="Detail") -> Polygon2D:
	var p:=Polygon2D.new();p.name=n;p.polygon=PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)]);p.color=c;parent.add_child(p);return p
func label(parent: Node,txt: String,pos: Vector2,size_: int,c: Color) -> Label:
	var l:=Label.new();l.text=txt;l.position=pos;l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.add_theme_font_override("font",font);l.add_theme_font_size_override("font_size",size_);l.add_theme_color_override("font_color",c);parent.add_child(l);return l
func collision(parent: Node,r: Rect2) -> void:
	var b:=StaticBody2D.new();b.name="Colision";b.collision_layer=1;b.collision_mask=0;parent.add_child(b)
	var c:=CollisionShape2D.new();c.name="Shape";var sh:=RectangleShape2D.new();sh.size=r.size;c.shape=sh;c.position=r.get_center();b.add_child(c)
func atlas(tex: Texture2D,r: Rect2) -> AtlasTexture:
	var a:=AtlasTexture.new();a.atlas=tex;a.region=r;return a
func frames(asset: String,w: int,h: int,count: int,fps: float) -> SpriteFrames:
	var sf:=SpriteFrames.new();sf.set_animation_speed("default",fps)
	var tex=load("res://splash/assets/"+asset+".png")
	for i in count: sf.add_frame("default",atlas(tex,Rect2(i*w,0,w,h)))
	return sf
func footprint(asset: String,w: float,h: float) -> Rect2:
	match asset:
		"palmera": return Rect2(35,97,26,23)
		"sombrilla": return Rect2(8,16,80,55)
		"reposera": return Rect2(3,11,35,61)
		"silla_salvavidas": return Rect2(8,39,48,57)
		"banco": return Rect2(3,5,58,23)
		"mesa": return Rect2(4,7,56,28)
		"vestuarios": return Rect2(8,20,400,120)
	return Rect2(4,12,w-8,h-18)
func build_props() -> void:
	for asset in data.assets:
		var a: Array=data.assets[asset];var n:=Node2D.new();n.name=asset.to_pascal_case();n.set_script(load("res://splash/scripts/ambient.gd"))
		if a[2]>1:
			var sp:=AnimatedSprite2D.new();sp.name="Textura";sp.sprite_frames=frames(asset,a[0],a[1],a[2],1.0/a[3]);sp.position=Vector2(0,-a[1]*.5);sp.autoplay="default";n.add_child(sp)
		else:
			var sp:=Sprite2D.new();sp.name="Textura";sp.texture=load("res://splash/assets/"+asset+".png");sp.position=Vector2(0,-a[1]*.5);n.add_child(sp)
		n.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		if asset=="pato_gigante":n.get_node("Textura").scale=Vector2(1.5,1.5)
		if asset=="toboganes":build_slide_outlets(n)
		if asset=="balde":n.get_node("Textura").position=Vector2.ZERO
		var foot:=footprint(asset,a[0],a[1]);collision(n,Rect2(foot.position-Vector2(a[0]*.5,a[1]),foot.size))
		n.set_meta("footprint",foot)
		pack(n,"res://splash/scenes/objetos/"+asset+".tscn");n.free()
func build_slide_outlets(parent: Node2D) -> void:
	var water_frames:=frames("salida_tobogan",48,56,8,10)
	var outlets: Array=[Vector2(-51,-20),Vector2(19,-17)]
	for i in 2:
		var outlet:=Marker2D.new();outlet.name="SalidaIzquierda" if i==0 else "SalidaDerecha";outlet.position=outlets[i];parent.add_child(outlet)
		var water:=AnimatedSprite2D.new();water.name="CaidaAgua";water.centered=false;water.position=Vector2(-24,0);water.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;water.sprite_frames=water_frames;water.autoplay="default";water.frame=i*4;outlet.add_child(water)
func build_npcs() -> void:
	for role in ["banador","salvavidas","staff"]:
		for i in range(1,4):
			var n: String=role+"_"+str(i);var sf:=SpriteFrames.new();sf.remove_animation("default");var tex=load("res://splash/assets/"+n+".png")
			var dirs: Array=["Abajo","Arriba","Derecha","Izquierda"];var starts: Array=[0,2,4,8];var counts: Array=[2,2,4,4]
			for d in 4:
				sf.add_animation(dirs[d]);sf.set_animation_speed(dirs[d],5)
				for f in counts[d]: sf.add_frame(dirs[d],atlas(tex,Rect2((starts[d]+f)*32,0,32,32)))
			ResourceSaver.save(sf,"res://splash/assets/"+n+".tres")
func build_floor() -> void:
	var tiles:=TileSet.new();tiles.tile_size=Vector2i(32,32);var source:=TileSetAtlasSource.new();source.texture=load("res://splash/assets/tiles_parque.png");source.texture_region_size=Vector2i(32,32)
	for y in 3:
		for x in 8: source.create_tile(Vector2i(x,y))
	tiles.add_source(source,0);ResourceSaver.save(tiles,"res://splash/assets/tiles_parque.tres")
	var floor_: = TileMapLayer.new();floor_.name="01_Pisos";floor_.tile_set=tiles;map_root.add_child(floor_)
	for y in range(3,31):
		for x in range(0,60):
			var pos:=Vector2(x*32+16,y*32+16);var mat:=0
			if x<2 or x>57 or y<4 or y>29: mat=3
			if Rect2(96,672,448,224).has_point(pos) or Rect2(1392,608,384,352).has_point(pos): mat=2
			if Rect2(1360,160,384,144).has_point(pos): mat=1
			if Rect2(784,336,352,64).has_point(pos): mat=4
			if Rect2(704,800,512,128).has_point(pos): mat=1
			var variant:=1 if (x*7+y*11)%11==0 else (2 if (x*13+y*5)%29==0 else 0)
			floor_.set_cell(Vector2i(x,y),0,Vector2i(mat,variant))
func build_pools() -> void:
	var pools:=group("02_Piletas",map_root)
	var wf:=frames("agua_celeste",128,128,12,1.0/.18)
	for pool in data.pools:
		var a: Array=pool.rect;var n:=group(pool.name,pools);n.position=Vector2(a[0],a[1]);n.set_script(load("res://splash/scripts/ambient.gd"))
		var sp:=Sprite2D.new();sp.name="Borde";sp.texture=load("res://splash/assets/"+pool.asset+".png");sp.centered=false;n.add_child(sp)
		for y in range(18,int(a[3])-26,128):
			for x in range(16,int(a[2])-22,128):
				var water:=AnimatedSprite2D.new();water.name="Agua";water.sprite_frames=wf;water.centered=false;water.position=Vector2(x,y);water.autoplay="default"
				var tw:=mini(128,int(a[2])-22-x);var th:=mini(128,int(a[3])-26-y)
				if tw<128 or th<128:
					var clipped:=SpriteFrames.new();clipped.set_animation_speed("default",1.0/.18)
					for f in 12:clipped.add_frame("default",atlas(load("res://splash/assets/agua_celeste.png"),Rect2(f*128,0,tw,th)))
					water.sprite_frames=clipped
				n.add_child(water)
		collision(n,Rect2(0,0,a[2]-6,a[3]-7))
func build_details() -> void:
	var detail:=group("03_Senales_y_perimetro",map_root)
	# Stable perimeter. Central entry is visually marked but physically closed for this map.
	for r in [Rect2(32,112,1856,12),Rect2(32,960,1856,12),Rect2(32,124,12,836),Rect2(1876,124,12,836)]:
		rect(detail,r,Color("456e75"),"Valla");collision(detail,r)
	for x in range(48,1880,32):
		for y in [112,960]: rect(detail,Rect2(x,y-4,4,20),Color("e9dfbf"),"Poste")
	for y in range(128,950,32):
		for x in [32,1876]: rect(detail,Rect2(x-4,y,20,4),Color("e9dfbf"),"Poste")
	# Insets and drains give surfaces scale without distracting from the characters.
	for y in [644,928]:
		for x in range(80,1840,48):
			if y==644 and x>680 and x<1230:continue
			rect(detail,Rect2(x,y,24,3),Color("bdb49a"),"Junta")
	for x in [672,1232]:
		for y in range(440,720,16): rect(detail,Rect2(x,y,3,9),Color("95b5bd"),"Rejilla")
	for x in range(816,1110,16): rect(detail,Rect2(x,409,7,3),Color("b38c73"),"BordeMirador")
	label(detail,"01 / TOBOGANES",Vector2(248,554),16,Color("48788d"))
	label(detail,"02 / GRAN CHAPUZON",Vector2(817,327),16,Color("986a55"))
	label(detail,"03 / MINI SPLASH",Vector2(1415,554),16,Color("48788d"))
	label(detail,"REPOSERAS",Vector2(200,872),16,Color("79644f"))
	label(detail,"HELADOS & LIMONADA",Vector2(1486,610),16,Color("79644f"))
	label(detail,"VESTUARIOS / LOCKERS",Vector2(1432,296),15,Color("48788d"))
	label(detail,"PATO SPLASH",Vector2(806,846),36,Color("487b91"))
	label(detail,"UN BUEN DIA PARA UN CHAPUZON",Vector2(808,891),14,Color("7593a0"))
	label(detail,"1.20 m",Vector2(930,716),14,Color("5f8da1"))
	label(detail,"AGUA / 24 C",Vector2(908,426),14,Color("5f8da1"))
	# Animated ripples originate in the basin, never in the walkways.
	var fx:=group("05_Efectos",map_root);fx.z_index=8
	var jet:=AnimatedSprite2D.new();jet.name="Chorro";jet.sprite_frames=frames("chorro_balde",192,128,12,6);jet.position=Vector2(960,252);fx.add_child(jet)
	fx.visible=false
func build() -> void:
	data=JSON.parse_string(FileAccess.get_file_as_string("res://tools/layout.json"));font=load("res://splash/assets/Pixel-Regular.ttf")
	build_props();build_npcs()
	map_root=load("res://splash/scenes/PatoSplash.tscn").instantiate()
	# The starting scene was created by Godot MCP. Rebuild contents for reproducibility.
	for c in map_root.get_children():map_root.remove_child(c);c.free()
	map_root.name="PatoSplash";map_root.set_script(load("res://splash/scripts/splash_event.gd"));map_root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	map_root.set_meta("play_rect",Rect2(32,112,1856,860));map_root.set_meta("stable_geometry",true)
	build_floor();build_pools();build_details()
	objects=group("04_Objetos",map_root);objects.y_sort_enabled=true
	for p in data.props:
		var a: Array=data.assets[p.asset];var n=load("res://splash/scenes/objetos/"+p.asset+".tscn").instantiate();n.name=p.name;n.position=Vector2(p.x+a[0]*.5,p.y+a[1]);objects.add_child(n)
		n.owner=map_root;map_root.set_editable_instance(n,true)
		if not p.solid:n.get_node("Colision/Shape").disabled=true
		if p.asset=="balde":n.get_node("Textura").position=Vector2.ZERO;n.position=Vector2(960,190)
	var m:=group("06_Marcadores",map_root)
	for a in data.markers:
		var marker:=Marker2D.new();marker.name=a[0];marker.position=Vector2(a[1],a[2]);marker.add_to_group(a[3],true);m.add_child(marker)
	if FileAccess.file_exists("res://tools/part2_builder.gd"):
		load("res://tools/part2_builder.gd").new().apply(map_root,data)
	if FileAccess.file_exists("res://tools/part3_builder.gd"):
		load("res://tools/part3_builder.gd").new().apply(map_root)
	if FileAccess.file_exists("res://tools/visual_revision.gd"):
		load("res://tools/visual_revision.gd").new().apply(map_root)
	if FileAccess.file_exists("res://tools/part4_builder.gd"):
		load("res://tools/part4_builder.gd").new().apply(map_root)
	if FileAccess.file_exists("res://tools/part5_builder.gd"):
		var life_builder:RefCounted=load("res://tools/part5_builder.gd").new();life_builder.apply(map_root);life_builder.showcase()
	pack(map_root,"res://splash/scenes/PatoSplash.tscn");map_root.free()
	print("BUILD_OK: editable map, ",data.props.size()," prop instances, 9 animated NPC skins")
	quit()


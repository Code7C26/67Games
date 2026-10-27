extends RefCounted
var helper: RefCounted = load("res://tools/part3_builder.gd").new()
func own(node: Node, root: Node) -> void:
	for child in node.get_children():child.owner=root;own(child,root)
func save_scene(root: Node,destination: String) -> void:
	own(root,root);var packed:=PackedScene.new();assert(packed.pack(root)==OK);assert(ResourceSaver.save(packed,destination)==OK)
func sprite(name_: String,asset: String,position_: Vector2,parent: Node,layer: int=2) -> AnimatedSprite2D:
	var n:=AnimatedSprite2D.new();n.name=name_;n.position=position_
	if ResourceLoader.exists("res://splash/assets/"+asset+".tres"):n.sprite_frames=load("res://splash/assets/"+asset+".tres")
	else:
		n.sprite_frames=SpriteFrames.new();n.sprite_frames.add_frame("default",load("res://splash/assets/"+asset+".png"))
	n.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;n.z_index=layer;parent.add_child(n);return n
func skin(name_: String,asset: String,pos: Vector2,parent: Node) -> AnimatedSprite2D:
	var n:=sprite(name_,asset,pos,parent);n.animation="Abajo";return n
func actor(name_: String,asset: String,pos: Vector2,reaction: int,offset: Vector2,skin_: String,parent: Node) -> Node2D:
	var n:=Node2D.new();n.name=name_;n.set_script(load("res://splash/scripts/stationary_npc.gd"));n.action_asset=asset;n.position=pos;n.reaction_kind=reaction;n.exit_offset=offset;n.walking_skin=skin_;n.phase_offset=float(parent.get_child_count())*.73;n.z_index=2
	var visual:=sprite("Visual",asset,Vector2.ZERO,n,0);visual.autoplay="default"
	var icon:=sprite("Alerta","reaccion_alerta",Vector2(0,-34),n,0);icon.visible=false
	var cover:=sprite("Cubrir","reaccion_cubrir",Vector2.ZERO,n,0);cover.visible=false
	parent.add_child(n)
	var prefab:=n.duplicate();prefab.position=Vector2.ZERO;save_scene(prefab,"res://splash/scenes/actores/"+asset+".tscn");prefab.free()
	return n
func path(name_: String,points: Array,parent: Node,asset: String) -> Path2D:
	var n:=Path2D.new();n.name=name_;n.curve=Curve2D.new();n.curve.bake_interval=2.0
	for point in points:n.curve.add_point(point)
	var follow:=PathFollow2D.new();follow.name="Pasajero";follow.rotates=false;follow.loop=false;n.add_child(follow)
	sprite("Visual",asset,Vector2(0,-10),follow,3);parent.add_child(n);return n
func build_life() -> void:
	DirAccess.make_dir_recursive_absolute("res://splash/scenes/actores")
	var audit: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/part5_art.json"))
	for item in audit.assets:helper.frames(item.name,Vector2(item.width,item.height),item.frames,item.fps)
	var root:=Node2D.new();root.name="VidaParque";root.set_script(load("res://splash/scripts/park_life.gd"));root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var actors:=Node2D.new();actors.name="Actores";root.add_child(actors)
	actor("GuardiaOeste","npc_guardia",Vector2(586,470),2,Vector2(40,90),"salvavidas_1",actors)
	actor("GuardiaEste","npc_guardia",Vector2(1334,470),2,Vector2(-40,90),"salvavidas_2",actors)
	actor("DescansoGiro","npc_reposera_giro",Vector2(174,814),0,Vector2(-38,50),"banador_1",actors)
	actor("DescansoProtector","npc_reposera_protector",Vector2(286,814),1,Vector2(-24,50),"banador_2",actors)
	actor("DescansoLibro","npc_reposera_lectura",Vector2(398,814),0,Vector2(-24,50),"banador_3",actors)
	actor("NinoA","npc_pelota",Vector2(168,918),0,Vector2(0,-10),"banador_3",actors)
	actor("NinoB","npc_pelota",Vector2(268,918),1,Vector2(0,-10),"banador_2",actors)
	actor("Limpieza","npc_limpieza",Vector2(1736,610),1,Vector2(-32,0),"staff_2",actors)
	actor("Fotografo","npc_fotografo",Vector2(1168,176),0,Vector2(0,32),"staff_3",actors)
	actor("Heladero","npc_heladero",Vector2(1646,722),2,Vector2(0,80),"staff_1",actors)
	sprite("Pelota","pelota_playa",Vector2.ZERO,root)
	sprite("CartelTemporal","cartel_piso_mojado",Vector2(1702,630),root)
	sprite("ZonaTrapeada","charco_deck",Vector2(1740,637),root,0)
	sprite("Flash","flash_camara",Vector2(1164,168),root,3)
	for i in 2:
		var s:=skin("ClienteHelado%d"%i,"banador_%d"%(i+1),Vector2.ZERO,root)
		sprite("Helado","helado_mano",Vector2(13,0),s,0)
		skin("ClienteVestuario%d"%i,"banador_%d"%(i+2),Vector2.ZERO,root)
		sprite("Puerta%d"%i,"puerta_cabina",Vector2(1430+i*212,231),root,2)
	var a:Array=[Vector2(302,237),Vector2(343,260),Vector2(403,261),Vector2(443,286),Vector2(437,309),Vector2(390,327),Vector2(342,333),Vector2(311,357),Vector2(317,397),Vector2(320,422)]
	var b:Array=[Vector2(344,237),Vector2(384,245),Vector2(435,252),Vector2(474,278),Vector2(474,311),Vector2(446,338),Vector2(398,359),Vector2(387,397),Vector2(390,428)]
	for i in 2:
		path("Tobogan%d"%i,a if i==0 else b,root,"npc_tobogan")
		sprite("Llegada%d"%i,"splash_corona",Vector2(320 if i==0 else 390,412),root,3)
		var swimmer:=skin("SalidaNadador%d"%i,"banador_%d"%(i+1),Vector2.ZERO,root);swimmer.z_index=2
	for i in 3:sprite("Libelula%d"%i,"libelula",Vector2.ZERO,root,4)
	var tint:=ColorRect.new();tint.name="Atardecer";tint.position=Vector2(32,112);tint.size=Vector2(1856,860);tint.color=Color.TRANSPARENT;tint.mouse_filter=Control.MOUSE_FILTER_IGNORE;tint.z_index=7;root.add_child(tint)
	var whistle:=AudioStreamPlayer.new();whistle.name="Silbato";whistle.stream=load("res://splash/assets/silbato_guardavidas.wav");whistle.volume_db=-24;root.add_child(whistle)
	save_scene(root,"res://splash/scenes/VidaParque.tscn");root.free()

func apply(map_root: Node2D) -> void:
	build_life()
	var previous:=map_root.get_node_or_null("10_VidaParque")
	if previous:map_root.remove_child(previous);previous.free()
	var instance:Node2D=load("res://splash/scenes/VidaParque.tscn").instantiate();instance.name="10_VidaParque";map_root.add_child(instance);instance.owner=map_root
	map_root.set_meta("park_life_revision","parte5")

func label(parent: Node,text_: String,position_: Vector2,size_: int,color_: Color) -> Label:
	var l:=Label.new();l.text=text_;l.position=position_;l.add_theme_font_override("font",load("res://splash/assets/press_start_2p.tres"));l.add_theme_font_size_override("font_size",size_);l.add_theme_color_override("font_color",color_);parent.add_child(l);return l
func category(asset: String) -> int:
	if asset in ["npc_guardia","npc_silbato","npc_reposera_giro","npc_reposera_protector","npc_reposera_lectura","npc_pelota","npc_limpieza","npc_fotografo","npc_heladero","npc_tobogan","puerta_cabina","pelota_playa","helado_mano","flash_camara","reaccion_alerta","reaccion_cubrir","huella_mojada","libelula"]:return 0
	if asset.begins_with("pato"):return 1
	if asset.begins_with("banador") or asset.begins_with("salvavidas") or asset.begins_with("staff") or asset.begins_with("npc"):return 2
	if "agua" in asset or "splash" in asset or "pileta" in asset or "gota" in asset or "burbuja" in asset or "charco" in asset or "chorro" in asset or "fuente" in asset or "destellos" in asset or "salida_tobogan"==asset:return 3
	if "tiles" in asset or "caminos" in asset:return 5
	return 4
func showcase() -> void:
	DirAccess.make_dir_recursive_absolute("res://scenes")
	var root:=Node2D.new();root.name="AssetShowcase";root.set_script(load("res://splash/scripts/asset_showcase.gd"));root.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var content:=Node2D.new();content.name="Catalogo";root.add_child(content)
	var camera:=Camera2D.new();camera.name="Camera2D";camera.position=Vector2(960,540);root.add_child(camera)
	var names:Array[String]=[]
	for file in DirAccess.get_files_at("res://splash/assets"):
		if file.ends_with(".aseprite"):names.append(file.get_basename())
	names.sort_custom(func(a:String,b:String):return category(a)<category(b) if category(a)!=category(b) else a<b)
	var current:=-1;var y:=170.0;var col:=0;var manifest:Array=[]
	for asset in names:
		var group:=category(asset)
		if group!=current:
			if col>0:y+=210;col=0
			y+=64;current=group
			label(content,["01 / VIDA DEL PARQUE - PARTE 5","02 / PATOS Y GRAN CHAPUZON","03 / BANISTAS, GUARDAVIDAS Y STAFF","04 / AGUA, PILETAS Y EFECTOS","05 / MOBILIARIO, EDIFICIOS Y VEGETACION","06 / PISOS Y CAMINOS"][group],Vector2(48,y-40),16,Color("ffe99b"))
		var card:=Node2D.new();card.name=asset;card.position=Vector2(48+col*304,y);content.add_child(card)
		var bg:=Polygon2D.new();bg.polygon=PackedVector2Array([Vector2.ZERO,Vector2(288,0),Vector2(288,192),Vector2(0,192)]);bg.color=Color("203c49");card.add_child(bg)
		var frames:SpriteFrames
		var resource_path:="res://splash/assets/"+asset+".tres"
		if ResourceLoader.exists(resource_path):frames=load(resource_path) as SpriteFrames
		if frames==null:
			frames=SpriteFrames.new()
			var sheet:Texture2D=load("res://splash/assets/"+asset+".png")
			var data_path:="res://splash/assets/"+asset+".json"
			if FileAccess.file_exists(data_path):
				var metadata:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data_path))
				var cells:Array=metadata.frames if metadata.frames is Array else metadata.frames.values()
				for cell in cells:
					var region:Dictionary=cell.frame;var atlas:=AtlasTexture.new();atlas.atlas=sheet;atlas.region=Rect2(region.x,region.y,region.w,region.h);frames.add_frame("default",atlas)
				if not cells.is_empty():frames.set_animation_speed("default",1000.0/maxf(1,cells[0].get("duration",200)))
			else:frames.add_frame("default",sheet)
		var first:=frames.get_animation_names()[0];var texture:=frames.get_frame_texture(first,0)
		var visual:=AnimatedSprite2D.new();visual.name="Vista";visual.sprite_frames=frames;visual.animation=first;visual.autoplay=first;visual.position=Vector2(144,85);visual.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		var factor:=1.0
		if texture.get_width()>272 or texture.get_height()>138:factor=0.5
		if texture.get_width()<=64 and texture.get_height()<=64:factor=2.0
		if texture.get_width()*factor>272:factor=0.25
		visual.scale=Vector2.ONE*factor;card.add_child(visual)
		label(card,asset,Vector2(12,157),8,Color("fff6de"));label(card,"ASEPRITE + PNG / "+str(frames.get_frame_count(first))+" CUADROS",Vector2(12,175),8,Color("a7c8bf"))
		card.set_meta("source","res://splash/assets/"+asset+".aseprite");card.set_meta("export", "res://splash/assets/"+asset+".png")
		if FileAccess.file_exists("res://splash/scenes/actores/"+asset+".tscn"):card.set_meta("prefab","res://splash/scenes/actores/"+asset+".tscn")
		elif FileAccess.file_exists("res://splash/scenes/objetos/"+asset+".tscn"):card.set_meta("prefab","res://splash/scenes/objetos/"+asset+".tscn")
		manifest.append({"name":asset,"category":group,"position":[card.position.x,card.position.y],"source":card.get_meta("source")})
		col+=1
		if col==6:col=0;y+=210
	root.content_height=y+420
	var hud:=CanvasLayer.new();hud.name="Ayuda";root.add_child(hud)
	var panel:=ColorRect.new();panel.size=Vector2(1920,154);panel.color=Color("142e3c");hud.add_child(panel)
	label(hud,"PATO SPLASH / ARCHIVO DE ASSETS",Vector2(48,25),24,Color("fff6de"))
	label(hud,str(names.size())+" FUENTES / PARTES 1-5 / NODOS EDITABLES Y COPIABLES",Vector2(48,68),16,Color("ffe99b"))
	label(hud,"Rueda o WASD: recorrer   Boton central: arrastrar   - / +: zoom   Inicio: volver arriba",Vector2(48,112),8,Color("a7c8bf"))
	save_scene(root,"res://scenes/asset_showcase.tscn");root.free()
	var file:=FileAccess.open("res://tests/showcase_manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"))

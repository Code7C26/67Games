extends "res://scripts/integrated_map.gd"
## Isolated proposal. The production map/selector/physics resources are not saved.
@export var lower_extension := 224.0
const ASSETS := "res://previews/lab_proposal/assets/"

func _enter_tree() -> void:
	_expand_lower_sector()
	super._enter_tree()

func _expand_lower_sector() -> void:
	var environment := get_node("Environment")
	environment.position = Vector2.ZERO
	var floor_layer: TileMapLayer = environment.get_node("01_Pisos")
	var extra_rows := roundi(lower_extension/32.0)
	for y in range(24,25+extra_rows):
		for x in range(1,58):
			var from := Vector2i(x,21)
			floor_layer.set_cell(Vector2i(x,y),floor_layer.get_cell_source_id(from),floor_layer.get_cell_atlas_coords(from),floor_layer.get_cell_alternative_tile(from))
	var walls := environment.get_node("03_Paredes_y_colisiones")
	walls.get_node("Pared_001").position.y += lower_extension
	for side in ["Pared_002","Pared_003"]:
		var wall := walls.get_node(side)
		var last: Sprite2D=null
		for visual in wall.get_children():
			if visual is Sprite2D and (last==null or visual.position.y>last.position.y): last=visual
		for index in extra_rows:
			var visual := last.duplicate() as Sprite2D
			visual.position.y = last.position.y+32.0*(index+1)
			wall.add_child(visual)
		var collision: CollisionShape2D = wall.get_node("Colision/Shape")
		collision.shape=collision.shape.duplicate()
		collision.shape.size.y+=lower_extension
		collision.position.y+=lower_extension*0.5
	for visual in environment.get_node("02_Oclusion_Paredes").get_children():
		if visual is Polygon2D:
			var minimum := INF
			for point in visual.polygon: minimum=minf(minimum,point.y)
			if minimum>=832: visual.position.y+=lower_extension
	# New row: realistic wet benches and reagent storage, with clear walkways.
	_prop(environment,"MesadaLavado", "sink_bench",Vector2(264,992),Vector2(192,88))
	_prop(environment,"MesadaPreparacion", "wet_bench",Vector2(784,992),Vector2(192,80))
	_prop(environment,"MesadaReactivos", "wet_bench",Vector2(1280,992),Vector2(192,80))
	_prop(environment,"EstantesInsumos", "supply_shelf",Vector2(1728,1000),Vector2(128,112))
	_complete_lower_rooms(environment)

func _complete_lower_rooms(environment: Node) -> void:
	var props:=environment.get_node("04_Objetos")
	# The former southern equipment row must not become a barricade in front
	# of the new doors. All of these changes belong to this preview instance.
	props.get_node("Sintesis_Cinta").position=Vector2(1288,672)
	props.get_node("Sintesis_Tanque_A").position.y=840
	props.get_node("Sintesis_Tanque_B").position.y=840
	props.get_node("Logistica_Pallets").position.x=1584
	props.get_node("Logistica_Estantes").position.x=1808
	var walls:=environment.get_node("03_Paredes_y_colisiones")
	for segment in [Vector2(48,320),Vector2(416,752),Vector2(880,1224),Vector2(1352,1648),Vector2(1744,1872)]:
		_wall(walls,Vector2(segment.x,848),Vector2(segment.y-segment.x,32))
	for x in [496.0,1072.0,1488.0]: _wall(walls,Vector2(x,880),Vector2(32,lower_extension-32))
	for doorway in [Vector3(320,416,368),Vector3(752,880,816),Vector3(1224,1352,1288),Vector3(1648,1744,1696)]:
		_threshold(environment,doorway)
	var labels:=environment.get_node("05_Rotulos")
	for entry in [[Vector2(64,855),"08 / LAVADO"],[Vector2(544,855),"09 / PREPARACION"],[Vector2(1360,855),"10 / REACTIVOS"],[Vector2(1528,855),"11 / INSUMOS"]]:
		var label:=Label.new()
		label.position=entry[0]
		label.text=entry[1]
		label.add_theme_font_override("font",load("res://lab/assets/Pixel-Regular.ttf"))
		label.add_theme_font_size_override("font_size",13)
		label.modulate=Color(0.76,0.88,0.87)
		labels.add_child(label)
	# Small perimeter fixtures complete the rooms without occupying the doors.
	_existing_prop(props,"tacho_biohazard",Vector2(88,1016))
	_existing_prop(props,"carro_muestras",Vector2(440,1016))
	_existing_prop(props,"rack_petri",Vector2(1016,1016))
	_existing_prop(props,"lavaojos",Vector2(1448,984))
	_existing_prop(props,"carrito_carga",Vector2(1584,1016))

func _existing_prop(parent: Node,id: String,point: Vector2) -> void:
	var prop: Node2D=load("res://lab/scenes/objetos/"+id+".tscn").instantiate()
	prop.name="Preview_"+id
	prop.position=point
	parent.add_child(prop)

func _wall(parent: Node,point: Vector2,size: Vector2) -> void:
	var wall:=Node2D.new()
	wall.name="PreviewPartition"
	wall.position=point
	var vertical:=size.y>size.x
	var reference:=parent.get_node("Pared_004" if vertical else "Pared_013")
	var tiles: Array[Sprite2D]=[]
	for child in reference.get_children():
		if child is Sprite2D: tiles.append(child)
	var count:=roundi(maxf(size.x,size.y)/32.0)
	for index in count:
		var source: Sprite2D=tiles[0 if index==0 else (tiles.size()-1 if index==count-1 else mini(1,tiles.size()-1))]
		var tile:=source.duplicate() as Sprite2D
		tile.position=Vector2(16,16+32*index) if vertical else Vector2(16+32*index,16)
		# A final half-tile closes non-32-wide doorway boundaries exactly.
		if not vertical and (index+1)*32>size.x:
			var visible_width:=size.x-index*32
			var texture:=source.texture.duplicate() as AtlasTexture
			texture.region.position.x+=32-visible_width
			texture.region.size.x=visible_width
			tile.texture=texture
			tile.position.x=index*32+visible_width*0.5
		wall.add_child(tile)
	var body:=StaticBody2D.new()
	body.name="Colision"
	body.collision_mask=0
	var collision:=CollisionShape2D.new()
	collision.name="Shape"
	collision.shape=RectangleShape2D.new()
	collision.shape.size=size
	collision.position=size*0.5
	body.add_child(collision)
	wall.add_child(body)
	parent.add_child(wall)

func _threshold(environment: Node,door: Vector3) -> void:
	var frame:=Node2D.new()
	frame.name="PreviewDoorThreshold"
	var geometry:=environment.get_node("02_Senaletica_y_luces")
	geometry.add_child(frame)
	_rectangle(frame,Rect2(door.x,860,door.y-door.x,12),Color("415e69"))
	_rectangle(frame,Rect2(door.x+4,864,door.y-door.x-8,2),Color("9fc4ca"))
	for x in [door.x-4,door.y]:
		_rectangle(frame,Rect2(x,848,4,32),Color("7b9da8"))
		_rectangle(frame,Rect2(x,852,4,5),Color("c5e6ed"))
	for y in [884,898,912]: _rectangle(frame,Rect2(door.z-7,y,14,2),Color("7aafb5"))

func _rectangle(parent: Node,rect: Rect2,tint: Color) -> void:
	var shape:=Polygon2D.new()
	shape.color=tint
	shape.polygon=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	parent.add_child(shape)

func _prop(environment: Node, node_name: String, id: String, point: Vector2, size: Vector2) -> void:
	var prop:=Node2D.new()
	prop.name=node_name
	prop.position=point
	prop.set_meta("asset_id",id)
	prop.set_meta("size",size)
	prop.set_meta("footprint",Rect2(Vector2(5,size.y-34),Vector2(size.x-10,30)))
	var sprite:=Sprite2D.new()
	sprite.name="Textura"
	sprite.texture=load(ASSETS+id+".png")
	sprite.centered=false
	sprite.position=Vector2(-size.x*0.5,-size.y)
	prop.add_child(sprite)
	var body:=StaticBody2D.new()
	body.name="Colision"
	body.collision_mask=0
	var shape:=CollisionShape2D.new()
	shape.name="Shape"
	shape.shape=RectangleShape2D.new()
	shape.shape.size=Vector2(size.x-10,34)
	shape.position=Vector2(0,-17)
	body.add_child(shape)
	prop.add_child(body)
	environment.get_node("04_Objetos").add_child(prop)

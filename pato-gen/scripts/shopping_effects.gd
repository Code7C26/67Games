extends Node2D
## Only scenery is graded. The NPC shader and HUD keep their own values.
func _ready() -> void:
	_setup.call_deferred()

func _setup() -> void:
	var host := get_parent()
	var dim := CanvasModulate.new()
	dim.name = "MapContrast"
	dim.color = Color(0.82,0.82,0.82,1)
	add_child(dim)
	var floor_material := ShaderMaterial.new()
	floor_material.shader = preload("res://lab/shaders/floor_readability.gdshader")
	for node_name in ["Pisos","BaseInterior","DesgasteSuelos"]:
		var floor_node := host.get_node_or_null(node_name)
		if floor_node: _grade(floor_node,floor_material)
	var grade := ShaderMaterial.new()
	grade.shader = preload("res://lab/shaders/scenery_grade.gdshader")
	for node_name in ["Decoracion","Paredes","ParedesCine"]:
		var scenery := host.get_node_or_null(node_name)
		if scenery: _grade(scenery,grade)
	for node_name in ["Paredes","ParedesCine"]:
		var wall: TileMapLayer=host.get_node_or_null(node_name)
		if not wall: continue
		var shadow := wall.duplicate() as TileMapLayer
		shadow.name=node_name+"ContactShadow"
		shadow.collision_enabled=false
		shadow.navigation_enabled=false
		shadow.position.y+=3
		shadow.modulate=Color(0.02,0.03,0.05,0.35)
		shadow.material=null
		host.add_child(shadow)
		host.move_child(shadow,wall.get_index())
	var vignette := Polygon2D.new()
	vignette.polygon=PackedVector2Array([Vector2(0,80),Vector2(2144,80),Vector2(2144,1040),Vector2(0,1040)])
	var mat := ShaderMaterial.new()
	mat.shader=preload("res://shaders/map_vignette.gdshader")
	vignette.material=mat
	host.add_child(vignette)
	host.move_child(vignette,host.get_node("Decoracion").get_index())

func _grade(node: Node, material: ShaderMaterial) -> void:
	if node is Sprite2D or node is AnimatedSprite2D or node is TileMapLayer or node is Polygon2D:
		if node.material == null: node.material=material
	for child in node.get_children(): _grade(child,material)

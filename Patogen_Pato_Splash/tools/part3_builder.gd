extends RefCounted
## Native authoring pass. Only adds visual nodes/resources; never changes collision.
func own(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		if child.scene_file_path.is_empty(): own(child, scene_root)

func frames(asset: String, size: Vector2, count: int, fps: float) -> SpriteFrames:
	var result := SpriteFrames.new()
	result.set_animation_speed("default", fps)
	var image: Texture2D = load("res://splash/assets/" + asset + ".png")
	for i in count:
		var texture := AtlasTexture.new()
		texture.atlas = image
		texture.region = Rect2(Vector2(i * size.x, 0), size)
		result.add_frame("default", texture)
	assert(ResourceSaver.save(result, "res://splash/assets/" + asset + ".tres") == OK)
	return result

func remove_existing(parent: Node, node_name: String) -> void:
	var previous: Node = parent.get_node_or_null(NodePath(node_name))
	if previous:
		parent.remove_child(previous)
		previous.free()

func apply(map_root: Node2D) -> void:
	remove_existing(map_root, "08_Ambiente")
	var controller := Node2D.new()
	controller.name = "08_Ambiente"
	controller.set_script(load("res://splash/scripts/park_ambience.gd"))
	controller.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_root.add_child(controller)
	var cloud := ColorRect.new()
	cloud.name = "SombrasNubes"
	cloud.position = Vector2(32, 112)
	cloud.size = Vector2(1856, 860)
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud.z_index = 4
	var cloud_material := ShaderMaterial.new()
	cloud_material.shader = load("res://splash/shaders/sombras_nubes.gdshader")
	cloud_material.set_shader_parameter("area_size", cloud.size)
	cloud.material = cloud_material
	controller.add_child(cloud)
	for pool in map_root.get_node("02_Piletas").get_children():
		remove_existing(pool, "DestellosAmbiente")
		var border: Sprite2D = pool.get_node("Borde")
		var light := ColorRect.new()
		light.name = "DestellosAmbiente"
		light.position = Vector2(16, 18)
		light.size = border.texture.get_size() - Vector2(38, 44)
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var material := ShaderMaterial.new()
		material.shader = load("res://splash/shaders/destellos_agua.gdshader")
		material.set_shader_parameter("basin_size", light.size)
		material.set_shader_parameter("glints", load("res://splash/assets/destellos_agua.png"))
		material.set_shader_parameter("phase", fposmod(pool.position.x / 32.0, 4.0))
		light.material = material
		pool.add_child(light)
	var objects: Node2D = map_root.get_node("04_Objetos")
	var kiosk: Node2D = objects.get_node("KioscoHelados")
	remove_existing(kiosk, "LetreroAmbiente")
	var sign_visual := AnimatedSprite2D.new()
	sign_visual.name = "LetreroAmbiente"
	sign_visual.sprite_frames = frames("letrero_helados", Vector2(80, 26), 4, 4)
	sign_visual.centered = false
	sign_visual.position = Vector2(-38, -160)
	sign_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	kiosk.add_child(sign_visual)
	sign_visual.owner = map_root
	var fountain: Node2D = objects.get_node("FuenteInfantil")
	remove_existing(fountain, "BurbujasAmbiente")
	var bubbles := AnimatedSprite2D.new()
	bubbles.name = "BurbujasAmbiente"
	bubbles.sprite_frames = frames("fuente_burbujas", Vector2(48, 32), 8, 8)
	bubbles.position = Vector2(0, -24)
	bubbles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fountain.add_child(bubbles)
	bubbles.owner = map_root
	frames("bandera_viento", Vector2(48, 96), 4, 4)
	frames("hoja_palmera", Vector2(24, 16), 4, 4)
	map_root.set_meta("ambience_revision", "parte3")
	own(map_root, map_root)

extends Node2D
## Visual-only nodes, cached materials and frame signals. No physics or AI writes.
@export_range(0.0,0.5,0.01) var reflection_alpha := 0.26
@export_range(0.1,0.8,0.01) var reflection_squash := 0.34
@export_range(0.0,0.5,0.01) var floor_sheen := 0.18
@export_range(0.0,0.8,0.01) var glare_alpha := 0.32
@export_range(0.0,5.0,0.1) var water_ripple_pixels := 2.0
@export_range(0.0,0.5,0.01) var water_caustics := 0.16
@export_range(0.0,0.7,0.01) var water_depth := 0.24
@export_range(0.0,1.0,0.01) var water_foam := 0.50
@export_range(1,60,1) var max_reflections := 28
@export_range(1,80,1) var max_glass := 36
@export_group("Light and volume")
@export_range(0.0,2.0,0.05) var local_light_energy := 0.8
@export_range(0.0,0.7,0.01) var contact_ao_alpha := 0.30
@export_range(4.0,40.0,1.0) var contact_ao_height := 18.0
@export_range(0.0,0.8,0.01) var cast_shadow_alpha := 0.32
@export_range(0.0,8.0,0.25) var shadow_softness := 2.0
@export_range(8,128,1) var max_occluders := 72
@export_range(0.0,0.5,0.01) var beam_alpha := 0.13
@export_range(0.0,2.0,0.05) var sunlight_drift := 0.5
@export var sunbeam_color := Color(1.0,0.92,0.72)
@export_range(0.0,1.0,0.01) var sunlight_energy := 0.20
@export var cyan_light := Color(0.24,0.84,1.0)
@export var green_light := Color(0.40,0.95,0.57)
@export var amber_light := Color(1.0,0.65,0.30)
@export var magenta_light := Color(0.86,0.34,0.90)
@export var sunlight_color := Color(1.0,0.84,0.61)
@export_range(-180.0,180.0,1.0) var sunlight_angle := -32.0
@export var beam_rect := Rect2(48,112,1824,896)
@export var lab_light_points: Array[Vector3] = [Vector3(745,795,360),Vector3(1000,795,300),Vector3(735,345,310),Vector3(990,345,240),Vector3(1098,445,250),Vector3(1460,290,420)]
@export var shopping_light_points: Array[Vector3] = [Vector3(185,835,310),Vector3(430,820,290),Vector3(620,840,300),Vector3(1830,160,340),Vector3(1490,720,400),Vector3(1010,500,280)]
@export var kiosk_light_point := Vector3(1630,790,350)
const Preferences = preload("res://scripts/visual_preferences.gd")
const Reflection = preload("res://shaders/prop_reflection.gdshader")
const Glass = preload("res://shaders/glass_glare.gdshader")
var host: Node2D
var map_id := ""
var effect_time := 0.0
var materials: Array[ShaderMaterial] = []
var floor_materials: Array[ShaderMaterial] = []
var reflection_count := 0
var glare_count := 0
var water_count := 0
var layer: Node2D
var occluder_count := 0
var local_lights: Array[Light2D] = []
var ao_material: ShaderMaterial
var sunlight_mask: ImageTexture

func configure(environment: Node2D, kind: String) -> void:
	host = environment
	map_id = kind
	name = "SceneryFinish"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer = Node2D.new()
	layer.name = "FloorReflections"
	layer.z_index = -10
	add_child(layer)
	if kind == "shopping": sunlight_mask = preload("res://scripts/shopping_sunlight.gd").build(host)
	var floor_names := ["Pisos","BaseInterior","DesgasteSuelos"] if kind == "shopping" else (["01_Pisos"] if kind == "lab" else ["01_Pisos","07_Caminos"])
	for node_name in floor_names:
		var floor_node := host.get_node_or_null(node_name)
		if floor_node:
			floor_node.z_index = -20 if node_name != "DesgasteSuelos" else -19
			_register_floor(floor_node)
	if kind == "shopping":
		host.get_node("Fondo").z_index = -22
		host.get_node("BaseInterior").z_index = -21
	var props := host.get_node("Decoracion" if kind == "shopping" else "04_Objetos")
	# Cache the list before adding reflection/glare children.
	var visuals: Array[CanvasItem] = []
	_collect(props, visuals)
	for visual in visuals if kind == "splash" else []:
		var tag := (str(visual.get_parent().name)+" "+visual.get_parent().scene_file_path+" "+str(visual.get_parent().get_meta("asset_id",""))).to_lower()
		if _matches(tag,["kiosco"]):
			if glare_count < max_glass: _glare(visual, tag)
	if kind == "splash": _water(visuals)
	_volume()
	var particles := preload("res://scripts/ambient_particles.gd").new()
	add_child(particles)
	particles.configure(host,kind)

func _matches(tag: String, terms: Array) -> bool:
	for term in terms:
		if term in tag: return true
	return false

func _collect(node: Node, result: Array[CanvasItem]) -> void:
	if (node is Sprite2D or node is AnimatedSprite2D) and not str(node.name).begins_with("Emision"):
		result.append(node)
	for child in node.get_children(): _collect(child, result)

func _texture(visual: CanvasItem) -> Texture2D:
	if visual is AnimatedSprite2D: return visual.sprite_frames.get_frame_texture(visual.animation,visual.frame)
	return visual.texture

func _rect(visual: CanvasItem) -> Rect2:
	if visual is Sprite2D: return visual.get_rect()
	var size := _texture(visual).get_size()
	return Rect2(visual.offset-size*0.5 if visual.centered else visual.offset, size)

func _set_frame(copy: Sprite2D, visual: CanvasItem, material: ShaderMaterial) -> void:
	var texture := _texture(visual)
	copy.texture = texture
	material.set_shader_parameter("frame_size", texture.get_size())
	if material.shader == Reflection:
		var bounds := Vector4(0,0,1,1)
		if texture is AtlasTexture:
			var size: Vector2 = texture.atlas.get_size()
			bounds = Vector4(texture.region.position.x/size.x,texture.region.position.y/size.y,texture.region.end.x/size.x,texture.region.end.y/size.y)
		material.set_shader_parameter("atlas_bounds",bounds)

func _reflection(visual: CanvasItem, clip: Rect2 = Rect2(), plane: Vector2 = Vector2.INF) -> void:
	var rect := _rect(visual)
	var sprite := Sprite2D.new()
	sprite.name = "PropReflection%d" % reflection_count
	sprite.centered = false
	var material := ShaderMaterial.new()
	material.shader = Reflection
	material.set_shader_parameter("reflection_tint",Color(0.55,0.78,0.88,reflection_alpha if not clip.has_area() else reflection_alpha*0.85))
	material.set_shader_parameter("ripple_pixels",water_ripple_pixels if clip.has_area() else 0.6)
	if clip.has_area():
		material.set_shader_parameter("water_clip",true)
		material.set_shader_parameter("clip_rect",Vector4(clip.position.x,clip.position.y,clip.size.x,clip.size.y))
	sprite.material = material
	layer.add_child(sprite)
	_set_frame(sprite,visual,material)
	var top: Vector2 = visual.to_global(rect.position)
	var base: Vector2 = visual.to_global(Vector2(rect.position.x,rect.end.y))
	var squash := reflection_squash
	if plane.is_finite():
		base = plane
		top.x = plane.x
		squash = minf(squash,clip.size.y/rect.size.y*0.65)
	sprite.position = host.to_local(Vector2(top.x,base.y+rect.size.y*squash))
	sprite.scale = Vector2(1,-squash)
	if visual is AnimatedSprite2D:
		visual.frame_changed.connect(func(): _set_frame(sprite,visual,material))
	materials.append(material)
	reflection_count += 1

func _glare(visual: CanvasItem, tag: String) -> void:
	var rect := _rect(visual)
	var sprite := Sprite2D.new()
	sprite.name = "GlassGlare"
	sprite.centered = false
	sprite.transform = visual.transform
	sprite.position = visual.position + rect.position
	var material := ShaderMaterial.new()
	material.shader = Glass
	var inset := Vector2(8,10)
	var size := rect.size-Vector2(16,22)
	if "capsula" in tag:
		inset = Vector2(20,32)
		size = Vector2(rect.size.x-40,rect.size.y*0.50)
	elif "kiosco" in tag:
		inset = Vector2(24,rect.size.y*0.47)
		size = Vector2(rect.size.x-48,rect.size.y*0.25)
	material.set_shader_parameter("glass_rect",Vector4(inset.x,inset.y,maxf(4,size.x),maxf(4,size.y)))
	material.set_shader_parameter("glare_color",Color(0.6,0.85,1.0,glare_alpha))
	material.set_shader_parameter("phase",0.45+float(glare_count%5)*0.13)
	sprite.material = material
	visual.get_parent().add_child(sprite)
	_set_frame(sprite,visual,material)
	if visual is AnimatedSprite2D:
		visual.frame_changed.connect(func(): _set_frame(sprite,visual,material))
	materials.append(material)
	glare_count += 1

func _register_floor(node: Node) -> void:
	if node is CanvasItem and node.material is ShaderMaterial:
		if node.material.shader.resource_path.ends_with("floor_readability.gdshader") or node.material.shader.resource_path.ends_with("scenery_grade.gdshader"):
			node.material = node.material.duplicate()
			node.material.set_shader_parameter("sheen_intensity",floor_sheen if map_id != "lab" else 0.0)
			if map_id == "shopping":
				node.material.set_shader_parameter("sunlight_restricted",true)
				node.material.set_shader_parameter("sunlight_mask",sunlight_mask)
				node.material.set_shader_parameter("sunlight_grid",Vector2(host.get_meta("grid")))
				node.material.set_shader_parameter("sheen_color",Vector3(sunbeam_color.r,sunbeam_color.g,sunbeam_color.b))
				node.material.set_shader_parameter("sheen_speed",sunlight_drift)
			floor_materials.append(node.material)
	for child in node.get_children(): _register_floor(child)

func _water(visuals: Array[CanvasItem]) -> void:
	var pools := host.get_node("02_Piletas")
	pools.z_index = -9
	layer.z_index = -7
	for pool in pools.get_children():
		var surface: ColorRect = pool.get_node("DestellosAmbiente")
		var basin := Rect2(pool.position+surface.position,surface.size)
		var depth := ColorRect.new()
		depth.name = "WaterDepthCausticsFoam"
		depth.position = surface.position
		depth.size = surface.size
		depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = preload("res://splash/shaders/water_depth.gdshader")
		material.set_shader_parameter("basin_size",surface.size)
		material.set_shader_parameter("caustic_intensity",water_caustics)
		material.set_shader_parameter("depth_intensity",water_depth)
		material.set_shader_parameter("foam_intensity",water_foam)
		depth.material = material
		pool.add_child(depth)
		materials.append(material)
		water_count += 1
		var types: Dictionary = {}
		for visual in visuals:
			var tag := str(visual.get_parent().name).to_lower()
			if _matches(tag,["palmera","tobogan","patogigante"]):
				var kind := "palm" if "palmera" in tag else ("slide" if "tobogan" in tag else "duck")
				if types.has(kind): continue
				if visual.global_position.distance_to(basin.get_center()) > 510: continue
				var rect := _rect(visual)
				var x := clampf(visual.global_position.x-rect.size.x*0.3,basin.position.x-rect.size.x*0.25,basin.end.x-rect.size.x*0.65)
				_reflection(visual,basin,Vector2(x,basin.position.y+5))
				types[kind] = true
				if types.size() == 3: break

func _process(delta: float) -> void:
	if not is_instance_valid(host): return
	if not Preferences.reduced_motion(self): effect_time += delta
	for material in materials: material.set_shader_parameter("effect_time",effect_time)
	for material in floor_materials: material.set_shader_parameter("effect_time",effect_time)

func _volume() -> void:
	var shadows := Node2D.new()
	shadows.name = "SceneryOcclusion"
	add_child(shadows)
	var ao := Node2D.new()
	ao.name = "ContactOcclusion"
	ao.z_index = -6
	add_child(ao)
	ao_material = ShaderMaterial.new()
	ao_material.shader = preload("res://shaders/scenery_ao.gdshader")
	ao_material.set_shader_parameter("shadow_color",Color(0.025,0.045,0.065,contact_ao_alpha))
	var shapes: Array[Node] = host.find_children("*","CollisionShape2D",true,false)
	for shape_node in shapes:
		if occluder_count >= max_occluders: break
		if not shape_node.get_parent() is StaticBody2D or shape_node.disabled: continue
		if not shape_node.shape is RectangleShape2D: continue
		var rect: Rect2 = shape_node.shape.get_rect()
		if rect.size.x < 24 or rect.size.y < 20: continue
		var polygon := PackedVector2Array()
		for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
			polygon.append(host.to_local(shape_node.to_global(point)))
		var occluder := LightOccluder2D.new()
		occluder.name = "SceneryOccluder%d" % occluder_count
		occluder.occluder_light_mask = 2
		occluder.occluder = OccluderPolygon2D.new()
		occluder.occluder.polygon = polygon
		shadows.add_child(occluder)
		var base: Vector2 = polygon[3]
		var patch := ColorRect.new()
		patch.name = "BaseAO%d" % occluder_count
		patch.position = base-Vector2(6,2)
		patch.size = Vector2(rect.size.x+12,contact_ao_height)
		patch.material = ao_material
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ao.add_child(patch)
		occluder_count += 1
	if map_id == "lab":
		pass # Ceiling fixtures and directional equipment emission belong to Lab.
	elif map_id == "shopping":
		var colors := [magenta_light,cyan_light,cyan_light,magenta_light,amber_light,cyan_light]
		for i in shopping_light_points.size():
			var point := shopping_light_points[i]
			_point(Vector2(point.x,point.y),colors[i%colors.size()],point.z,i in [0,2,3])
		_beams()
	else:
		_point(Vector2(kiosk_light_point.x,kiosk_light_point.y),amber_light,kiosk_light_point.z,true)
		var sun := DirectionalLight2D.new()
		sun.name = "WarmSunlight"
		sun.color = sunlight_color
		sun.energy = sunlight_energy
		sun.rotation_degrees = sunlight_angle
		sun.range_item_cull_mask = 2
		add_child(sun)
		local_lights.append(sun)

func _point(point: Vector2, color: Color, diameter: float, shadows: bool) -> void:
	var light := PointLight2D.new()
	light.name = "SceneryLight%d" % local_lights.size()
	light.position = point
	light.color = color
	light.energy = local_light_energy
	light.range_item_cull_mask = 2
	light.shadow_item_cull_mask = 2
	light.shadow_enabled = shadows
	light.shadow_color = Color(0.02,0.04,0.06,cast_shadow_alpha)
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = shadow_softness
	light.height = 28.0
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE,Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(0.5,1.0)
	light.texture = texture
	light.texture_scale = diameter/128.0
	add_child(light)
	local_lights.append(light)

func _beams() -> void:
	var beam := ColorRect.new()
	beam.name = "FloorLightBeams"
	beam.position = beam_rect.position
	beam.size = beam_rect.size
	beam.z_index = -8
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/floor_light_beams.gdshader")
	material.set_shader_parameter("area_size",beam.size)
	material.set_shader_parameter("beam_color",Color(sunbeam_color,beam_alpha))
	material.set_shader_parameter("beam_speed",sunlight_drift)
	material.set_shader_parameter("sunlight_restricted",true)
	material.set_shader_parameter("sunlight_mask",sunlight_mask)
	material.set_shader_parameter("sunlight_grid",Vector2(host.get_meta("grid")))
	beam.material = material
	add_child(beam)
	materials.append(material)

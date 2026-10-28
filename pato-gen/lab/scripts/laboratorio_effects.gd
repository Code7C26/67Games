extends Node2D
## Environment-only treatment. NPCs are unshaded; UI lives above Canvas max layer 0.
@export_range(0.4,1.0,0.01) var scenery_ambient := 0.50
@export_range(0.0,0.6,0.01) var vignette_strength := 0.38
@export_range(0.0,1.5,0.01) var glow_intensity := 0.52
@export_range(0.8,2.0,0.01) var glow_threshold := 1.05
@export_range(1.0,4.0,0.05) var emission_energy := 1.85
@export_range(0.0,2.0,0.01) var light_energy := 0.30
@export_range(0.0,0.35,0.005) var flicker_amount := 0.18
@export var fixture_start := Vector2(176,208)
@export var fixture_spacing := Vector2(288,192)
@export var fixture_columns := 6
@export var fixture_rows := 4
@export var fixture_diameter := 370.0
@export var fixture_color := Color(0.78,0.88,0.91)
@export var fixture_emission := Color(1.25,1.35,1.32)
@export var show_ceiling_fixtures := false
@export var flicker_period := 24.0
@export var flicker_duration := 0.35
@export var equipment_light_energy := 0.42
@export var equipment_light_reach := 176.0
@export var south_back_view_start_y := 780.0
@export var back_view_directory := "res://visuals/lighting_coherence/lab_backviews/"
@export var finish_scene: PackedScene = preload("res://scenes/visual/SceneryFinish.tscn")
const Preferences = preload("res://scripts/visual_preferences.gd")
var clock_time := 0.0
var dust_nodes: Array[CPUParticles2D] = []
var fixtures: Array[Dictionary] = []
var equipment_lights: Array[PointLight2D] = []
var rear_equipment: Array[Node2D] = []
var equipment_texture: Texture2D
func _ready() -> void:
	# CanvasModulate belongs to the entire canvas, even when placed under scenery.
	get_node("Ambiente").color = Color.WHITE
	var grade := ShaderMaterial.new()
	grade.shader = preload("res://lab/shaders/scenery_grade.gdshader")
	grade.set_shader_parameter("ambient", scenery_ambient)
	for node_name in ["02_Oclusion_Paredes", "03_Paredes", "04_Objetos"]:
		var scenery := get_node_or_null(node_name)
		if scenery: _grade(scenery, grade)
	get_node("01_Pisos").material.set_shader_parameter("ambient", scenery_ambient)
	get_node("01_Pisos").light_mask = 2
	var environment_node := WorldEnvironment.new()
	environment_node.name="WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode=Environment.BG_CANVAS
	environment.background_canvas_max_layer=0
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled=true
	environment.glow_intensity=glow_intensity
	environment.glow_strength=0.65
	environment.glow_bloom=0.0
	environment.glow_hdr_threshold=glow_threshold
	environment.glow_hdr_scale=1.0
	environment.glow_blend_mode=Environment.GLOW_BLEND_MODE_ADDITIVE
	for i in range(7): environment.set_glow_level(i,0.65 if i==0 else (0.2 if i==1 else 0.0))
	environment_node.environment=environment
	add_child(environment_node)
	var lights := Node2D.new()
	lights.name="08_Luces"
	add_child(lights)
	equipment_texture = _cone()
	_ceiling_grid(lights)
	var vignette := Polygon2D.new()
	vignette.name="VinetaBordes"
	vignette.polygon=PackedVector2Array([Vector2(16,80),Vector2(1904,80),Vector2(1904,880),Vector2(16,880)])
	vignette.uv=PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
	var vmat:=ShaderMaterial.new()
	vmat.shader=preload("res://lab/shaders/vignette.gdshader")
	vmat.set_shader_parameter("strength", vignette_strength)
	vignette.material=vmat
	add_child(vignette)
	move_child(vignette,get_node("04_Objetos").get_index())
	for prop in get_node("04_Objetos").get_children():
		if prop.has_meta("asset_id"): _equipment(prop)
	# Wall-only sparse dust. The central walking lane receives no particles.
	for pos in [Vector2(1400,166),Vector2(1170,734)]:
		var dust:=CPUParticles2D.new()
		dust.name="PolvoEnHaz"
		dust.position=pos
		dust.amount=8
		dust.emitting = not Preferences.reduced_motion(self)
		dust_nodes.append(dust)
		dust.lifetime=8.0
		dust.preprocess=4.0
		dust.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		dust.emission_rect_extents=Vector2(45,20)
		dust.direction=Vector2(1,-0.3)
		dust.spread=15
		dust.gravity=Vector2.ZERO
		dust.initial_velocity_min=1.0
		dust.initial_velocity_max=2.0
		dust.color=Color(0.8,0.88,0.85,0.12)
		var image:=Image.create(1,1,false,Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		dust.texture=ImageTexture.create_from_image(image)
		add_child(dust)
		move_child(dust,get_node("04_Objetos").get_index())
	var finish := finish_scene.instantiate()
	add_child(finish)
	finish.configure(self,"lab")
func _light(parent:Node,pos:Vector2,tint:Color,energy:float,diameter:float,source_texture:Texture2D=null) -> PointLight2D:
	var light:=PointLight2D.new()
	light.position=pos
	light.color=tint
	light.energy=energy
	light.blend_mode=Light2D.BLEND_MODE_ADD
	light.range_item_cull_mask = 2
	light.shadow_item_cull_mask = 2
	light.height=48.0
	light.shadow_enabled=false
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0)])
	var texture:=GradientTexture2D.new()
	texture.gradient=gradient
	texture.width=128
	texture.height=128
	texture.fill=GradientTexture2D.FILL_RADIAL
	texture.fill_from=Vector2(0.5,0.5)
	texture.fill_to=Vector2(0.5,1.0)
	light.texture=texture if source_texture==null else source_texture
	light.texture_scale=diameter/128.0
	parent.add_child(light)
	return light
func _equipment(prop:Node2D) -> void:
	var id: String=prop.get_meta("asset_id")
	var original: Node2D=prop.get_node_or_null("Textura")
	if original==null: original=prop.get_node_or_null("TexturaAnimada")
	if original==null: return
	var grade:=ShaderMaterial.new()
	grade.shader=preload("res://lab/shaders/scenery_grade.gdshader")
	grade.set_shader_parameter("ambient", scenery_ambient)
	original.material=grade
	var back_path := back_view_directory+id+"_back.png"
	if prop.position.y>=south_back_view_start_y and ResourceLoader.exists(back_path):
		var texture := load(back_path) as Texture2D
		if original is AnimatedSprite2D:
			var frames := SpriteFrames.new()
			frames.add_frame("default",texture)
			original.sprite_frames = frames
			original.animation = "default"
			original.stop()
		else: original.texture = texture
		prop.set_meta("visual_facing","away_from_camera")
		rear_equipment.append(prop)
		return
	prop.set_meta("visual_facing","toward_camera")
	var regions: Dictionary={
		"capsula_pato":Vector4(22,35,3,65),"capsula_vacia":Vector4(22,35,3,65),"capsula_rota":Vector4(22,35,3,65),
		"biorreactor":Vector4(20,84,56,12),"muro_monitores":Vector4(12,12,165,45),
		"consola_control":Vector4(12,10,136,44),"tanque_sintesis":Vector4(22,36,3,46),
		"consola_capsulas":Vector4(8,10,78,27),"rack_servidores":Vector4(42,10,12,70)}
	if not regions.has(id): return
	var emission=original.duplicate()
	emission.name="EmisionSelectiva"
	var material:=ShaderMaterial.new()
	material.shader=preload("res://lab/shaders/emission.gdshader")
	material.set_shader_parameter("frame_size",prop.get_meta("size"))
	material.set_shader_parameter("emission_rect",regions[id])
	material.set_shader_parameter("emission_energy",emission_energy)
	emission.material=material
	prop.add_child(emission)
	if original is AnimatedSprite2D:
		emission.stop()
		original.frame_changed.connect(func(): emission.frame=original.frame)
		emission.frame=original.frame
	var color := Color(0.40,0.92,0.67) if id=="biorreactor" else Color(0.38,0.79,0.92)
	var light := _light(get_node("08_Luces"),prop.position+Vector2(0,equipment_light_reach*0.48),color,equipment_light_energy,equipment_light_reach,equipment_texture)
	light.name = "ScreenLight_"+str(prop.name)
	equipment_lights.append(light)
func _process(delta:float) -> void:
	var reduced := Preferences.reduced_motion(self)
	if not reduced: clock_time+=delta
	for dust in dust_nodes: dust.speed_scale = 0.0 if reduced else 1.0
	for i in fixtures.size():
		var factor := fixture_factor(i,clock_time,reduced)
		fixtures[i].light.energy = light_energy*factor
		fixtures[i].visual.self_modulate = fixture_emission*Color(factor,factor,factor,1)

func fixture_factor(index: int, time: float, reduced: bool) -> float:
	if reduced: return 1.0
	var age := fposmod(time+index*7.137,flicker_period+float(index%5)*1.7)
	if age>=flicker_duration: return 1.0
	var t := age/flicker_duration
	var dip := 1.0 if t<0.22 else (0.55 if t>0.52 and t<0.72 else 0.0)
	return 1.0-flicker_amount*dip

func _ceiling_grid(lights: Node2D) -> void:
	var texture := load("res://visuals/lighting_coherence/ceiling_fixture.png") as Texture2D
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for row in fixture_rows:
		for column in fixture_columns:
			var point := fixture_start+Vector2(column,row)*fixture_spacing
			var light := _light(lights,point,fixture_color,light_energy,fixture_diameter)
			light.name = "CeilingLight_%d_%d" % [column,row]
			light.shadow_enabled = row==0 and column in [0,3,5]
			light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
			light.shadow_color = Color(0.02,0.035,0.045,0.24)
			var visual := Sprite2D.new()
			visual.name = "CeilingFixture_%d_%d" % [column,row]
			visual.texture = texture
			visual.position = point
			visual.z_index = -4
			visual.material = unlit
			visual.self_modulate = fixture_emission
			visual.visible = show_ceiling_fixtures
			lights.add_child(visual)
			fixtures.append({"light":light,"visual":visual})

func _cone() -> Texture2D:
	var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var t := float(y)/127.0
			var width := lerpf(0.20,0.90,t)
			var side := absf((x-63.5)/64.0)/width
			var alpha := (1.0-smoothstep(0.55,1.0,side))*pow(1.0-t,1.6)*smoothstep(0,0.08,t)
			image.set_pixel(x,y,Color(1,1,1,alpha))
	return ImageTexture.create_from_image(image)

func _grade(node: Node, material: ShaderMaterial) -> void:
	if node is CanvasItem: node.light_mask = 2
	if node is Sprite2D or node is AnimatedSprite2D or node is TileMapLayer:
		if node.material == null: node.material = material
	for child in node.get_children(): _grade(child, material)

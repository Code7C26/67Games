extends Node2D
## Environment-only treatment. NPCs are unshaded; UI lives above Canvas max layer 0.
var fluorescent: PointLight2D
var clock_time := 0.0
func _ready() -> void:
	var environment_node := WorldEnvironment.new()
	environment_node.name="WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode=Environment.BG_CANVAS
	environment.background_canvas_max_layer=0
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled=true
	environment.glow_intensity=0.18
	environment.glow_strength=0.65
	environment.glow_bloom=0.0
	environment.glow_hdr_threshold=1.05
	environment.glow_hdr_scale=1.0
	environment.glow_blend_mode=Environment.GLOW_BLEND_MODE_ADDITIVE
	for i in range(7): environment.set_glow_level(i,0.65 if i==0 else (0.2 if i==1 else 0.0))
	environment_node.environment=environment
	add_child(environment_node)
	var lights := Node2D.new()
	lights.name="08_Luces"
	add_child(lights)
	_light(lights,Vector2(1400,220),Color("a1e2df"),0.13,380)
	_light(lights,Vector2(670,780),Color("a5d7e3"),0.12,260)
	_light(lights,Vector2(1000,780),Color("a5d7e3"),0.11,240)
	_light(lights,Vector2(1170,770),Color("e4c993"),0.13,220)
	_light(lights,Vector2(1410,770),Color("e4c993"),0.13,220)
	fluorescent=_light(lights,Vector2(1110,442),Color("d8e1d6"),0.055,200)
	var vignette := Polygon2D.new()
	vignette.name="VinetaBordes"
	vignette.polygon=PackedVector2Array([Vector2(16,80),Vector2(1904,80),Vector2(1904,880),Vector2(16,880)])
	vignette.uv=PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)])
	var vmat:=ShaderMaterial.new()
	vmat.shader=preload("res://lab/shaders/vignette.gdshader")
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
func _light(parent:Node,pos:Vector2,tint:Color,energy:float,diameter:float) -> PointLight2D:
	var light:=PointLight2D.new()
	light.position=pos
	light.color=tint
	light.energy=energy
	light.blend_mode=Light2D.BLEND_MODE_ADD
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
	light.texture=texture
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
	original.material=grade
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
	material.set_shader_parameter("emission_energy",1.25 if id.begins_with("capsula") else 1.4)
	emission.material=material
	prop.add_child(emission)
	if original is AnimatedSprite2D:
		emission.stop()
		original.frame_changed.connect(func(): emission.frame=original.frame)
		emission.frame=original.frame
func _process(delta:float) -> void:
	clock_time+=delta
	if fluorescent:
		fluorescent.energy=0.055*(1.0+0.025*sin(clock_time*5.1)+0.015*sin(clock_time*17.3))

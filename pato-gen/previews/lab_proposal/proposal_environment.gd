extends "res://lab/scripts/laboratorio_effects.gd"
## Only attached to the sample scene. No production lights/materials are edited.
@export_range(0.0,3.0,0.05) var source_glow_energy := 2.15
@export_range(0.0,1.0,0.01) var source_glow_opacity := 0.58
@export var incubator_light_color := Color(0.86,0.83,1.0)
@export_range(0.0,2.0,0.01) var marked_light_energy := 0.78
@export_range(128.0,512.0,1.0) var marked_light_diameter := 280.0
## Screenshot marks converted through the shared 1920x1080 gameplay camera.
@export var ceiling_points: Array[Vector2] = [
	Vector2(145,204),Vector2(491,199),Vector2(724,290),Vector2(948,294),
	Vector2(138,359),Vector2(488,357),Vector2(1336,333),Vector2(1621,343),
	Vector2(164,517),Vector2(406,513),Vector2(609,513),Vector2(837,509),
	Vector2(1086,509),Vector2(1309,510),Vector2(1545,505),Vector2(1783,506),
	Vector2(286,722),Vector2(674,729),Vector2(928,741),Vector2(1299,737),Vector2(1693,731),
	Vector2(169,973),Vector2(351,970),Vector2(624,977),Vector2(926,977),
	Vector2(1182,973),Vector2(1678,969),Vector2(1406,985)]
var preview_incubators: Array[AnimatedSprite2D] = []
var motion_was_reduced := false
var ceiling_wall_occluders := 0

func _ready() -> void:
	glow_intensity=0.65
	glow_threshold=0.90
	light_energy=marked_light_energy
	fixture_diameter=marked_light_diameter
	finish_scene=preload("res://previews/lab_proposal/PreviewFinish.tscn")
	super._ready()
	_tag_ceiling_occluders()
	var vignette := get_node("VinetaBordes") as Polygon2D
	var bounds: Rect2=get_parent().get_meta("bounds")
	vignette.polygon=PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])

func _ceiling_grid(lights: Node2D) -> void:
	for index in ceiling_points.size():
		var point:=ceiling_points[index]
		var light:=_light(lights,point,fixture_color,light_energy,fixture_diameter,ceiling_texture)
		light.name="MarkedCeilingLight_%02d" % (index+1)
		# A ceiling source can sit over a bench. Walls block it; a bench must
		# not swallow the entire light merely because its 2D footprint contains it.
		light.shadow_item_cull_mask=4
		var visual:=Sprite2D.new()
		visual.name="CeilingFixture_%02d" % (index+1)
		visual.texture=preload("res://visuals/lighting_coherence/ceiling_fixture.png")
		visual.position=point
		visual.visible=show_ceiling_fixtures
		lights.add_child(visual)
		fixtures.append({"light":light,"visual":visual})

func _tag_ceiling_occluders() -> void:
	var wall_rects: Array[Rect2]=[]
	for shape in get_node("03_Paredes_y_colisiones").find_children("*","CollisionShape2D",true,false):
		if not shape.shape is RectangleShape2D: continue
		var rect: Rect2=shape.shape.get_rect()
		wall_rects.append(Rect2(to_local(shape.to_global(rect.position)),rect.size))
	for occluder in get_node("SceneryFinish/SceneryOcclusion").get_children():
		var polygon: PackedVector2Array=occluder.occluder.polygon
		var bounds:=Rect2(polygon[0],Vector2.ZERO)
		for point in polygon: bounds=bounds.expand(point)
		for wall in wall_rects:
			if bounds.is_equal_approx(wall):
				occluder.occluder_light_mask|=4
				ceiling_wall_occluders+=1
				break

func _equipment(prop: Node2D) -> void:
	super._equipment(prop)
	var id: String=prop.get_meta("asset_id")
	var original: Node2D=prop.get_node_or_null("Textura")
	if original==null: original=prop.get_node_or_null("TexturaAnimada")
	if original==null: return
	if id=="biorreactor":
		AssetFinish.apply(original,"incubator","res://previews/lab_proposal/assets/")
		preview_incubators.append(original as AnimatedSprite2D)
		equipment_lights[-1].color=incubator_light_color
	elif id in ["wet_bench","sink_bench","supply_shelf","prep_bench","reagent_bench","sink_bench_detailed"]:
		return
	if str(prop.name)=="Preview_carrito_carga":
		AssetFinish.apply(original,"sealed_transport","res://previews/lab_proposal/assets/")
	if not prop.has_node("EmisionSelectiva"): return
	var emission: Node2D=prop.get_node("EmisionSelectiva")
	if original is AnimatedSprite2D:
		emission.sprite_frames=original.sprite_frames
		emission.frame=original.frame
	var material:=ShaderMaterial.new()
	material.shader=preload("res://previews/lab_proposal/source_glow.gdshader")
	material.set_shader_parameter("frame_size",prop.get_meta("size"))
	var regions: Dictionary={
		"biorreactor":Vector4(30,21,48,70),"capsula_pato":Vector4(20,30,5,72),
		"capsula_vacia":Vector4(20,30,5,72),"capsula_rota":Vector4(20,30,5,72),
		"muro_monitores":Vector4(12,12,165,45),"consola_control":Vector4(12,10,136,44),
		"tanque_sintesis":Vector4(22,36,52,46),"consola_capsulas":Vector4(8,10,78,27),
		"rack_servidores":Vector4(42,10,12,70),"mesa_secuenciador":Vector4(12,10,52,32),
		"escritorio_operadores":Vector4(8,4,42,25),"cabina_cultivo":Vector4(12,32,106,35),"expendedora":Vector4(12,10,20,40)}
	material.set_shader_parameter("emission_rect",regions.get(id,Vector4.ZERO))
	material.set_shader_parameter("emission_energy",source_glow_energy)
	material.set_shader_parameter("emission_opacity",source_glow_opacity)
	if id=="biorreactor":
		material.set_shader_parameter("secondary_rect",Vector4(10,17,14,36))
		material.set_shader_parameter("secondary_strength",0.70)
		material.set_shader_parameter("use_emission_tint",true)
		material.set_shader_parameter("include_neutral_pixels",true)
		material.set_shader_parameter("emission_tint",incubator_light_color)
	elif id.begins_with("capsula_"):
		material.set_shader_parameter("secondary_rect",Vector4(70,30,5,72))
		material.set_shader_parameter("secondary_strength",0.70)
	emission.material=material

func _process(delta: float) -> void:
	super._process(delta)
	var reduced := Preferences.reduced_motion(self)
	if reduced!=motion_was_reduced:
		for sprite in preview_incubators:
			if reduced: sprite.pause()
			else: sprite.play()
		motion_was_reduced=reduced

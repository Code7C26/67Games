extends "res://lab/scripts/laboratorio_effects.gd"
## Only attached to the sample scene. No production lights/materials are edited.
@export_range(0.0,3.0,0.05) var source_glow_energy := 2.15
@export_range(0.0,1.0,0.01) var source_glow_opacity := 0.58
@export var incubator_light_color := Color(0.86,0.83,1.0)
var preview_incubators: Array[AnimatedSprite2D] = []
var motion_was_reduced := false

func _ready() -> void:
	glow_intensity=0.65
	glow_threshold=0.90
	fixture_rows=4
	finish_scene=preload("res://previews/lab_proposal/PreviewFinish.tscn")
	super._ready()
	var vignette := get_node("VinetaBordes") as Polygon2D
	var bounds: Rect2=get_parent().get_meta("bounds")
	vignette.polygon=PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])

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
	elif id in ["wet_bench","sink_bench","supply_shelf"]:
		return
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

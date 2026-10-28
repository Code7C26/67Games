extends Node2D
## Fixed emitters; particles are recycled by CPUParticles2D, never spawned as nodes.
@export_range(0.0,1.0,0.01) var opacity := 0.30
@export_range(1,24,1) var particles_per_emitter := 10
@export_range(1.0,16.0,0.5) var drift_speed := 5.0
@export_range(2.0,20.0,0.5) var lifetime := 9.0
const Preferences = preload("res://scripts/visual_preferences.gd")
var emitters: Array[CPUParticles2D] = []
var reduced_last := false

func configure(_host: Node2D, kind: String) -> void:
	name = "AmbientParticles"
	z_index = -2
	var positions: Array[Vector2] = []
	var extents := Vector2(80,35)
	var tint := Color(0.95,0.90,0.74,opacity)
	if kind == "shopping":
		positions = [Vector2(955,480),Vector2(1060,770),Vector2(700,480),Vector2(1460,480)]
	elif kind == "lab":
		positions = [Vector2(462,430),Vector2(1036,450),Vector2(1490,430)]
		tint = Color(0.72,0.88,0.90,opacity*0.65)
	else:
		positions = [Vector2(1240,264),Vector2(532,516),Vector2(1360,500),Vector2(700,840)]
		tint = Color(0.96,0.91,0.72,opacity*0.85)
		extents = Vector2(68,22)
	var texture := load("res://visuals/lighting_coherence/ambient_mote.png") as Texture2D
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for point in positions:
		var particles := CPUParticles2D.new()
		particles.name = "AmbientMotes%d" % emitters.size()
		particles.position = point
		particles.amount = particles_per_emitter
		particles.lifetime = lifetime
		particles.preprocess = lifetime
		particles.texture = texture
		particles.material = unlit
		particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = extents
		particles.direction = Vector2(0.6,-0.5)
		particles.spread = 35.0
		particles.gravity = Vector2.ZERO
		particles.initial_velocity_min = drift_speed*0.45
		particles.initial_velocity_max = drift_speed
		particles.scale_amount_min = 0.5
		particles.scale_amount_max = 0.9
		particles.color = tint
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0,0.18,0.75,1.0])
		gradient.colors = PackedColorArray([Color(1,1,1,0),Color.WHITE,Color.WHITE,Color(1,1,1,0)])
		particles.color_ramp = gradient
		add_child(particles)
		emitters.append(particles)
	_apply_preference()

func _apply_preference() -> void:
	reduced_last = Preferences.reduced_motion(self)
	for particles in emitters:
		particles.speed_scale = 0.0 if reduced_last else 1.0
		particles.visible = not reduced_last

func _process(_delta: float) -> void:
	if reduced_last != Preferences.reduced_motion(self): _apply_preference()

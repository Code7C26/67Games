extends Node2D
## Visual ambience only. One clock, no timers/tweens per object, no physics changes.
## Shader clocks deliberately avoid TIME, so pause freezes every ambient effect.
@export var enabled := true
@export_group("Agua / destellos de 32 px")
@export_range(0.0, 4.0, 0.05) var water_speed := 1.0
@export_range(0.0, 1.0, 0.05) var water_intensity := 0.65
@export_group("Nubes / px por segundo y opacidad")
@export_range(0.0, 40.0, 0.5) var cloud_speed := 18.0
@export_range(0.0, 0.35, 0.01) var cloud_intensity := 0.28
@export_range(0.5, 1.0, 0.01) var scenery_ambient := 0.92
@export var finish_scene: PackedScene = preload("res://scenes/visual/SceneryFinish.tscn")
const Preferences = preload("res://scripts/visual_preferences.gd")
var scenery_material: ShaderMaterial
@export_group("Palmeras / ciclos por segundo y desplazamiento en px")
@export_range(0.0, 0.8, 0.01) var palm_speed := 0.18
@export_range(0.0, 2.0, 0.1) var palm_intensity := 2.0
@export_group("Hojas / px por segundo y hojas por minuto en todo el mapa")
@export_range(0.0, 50.0, 1.0) var leaf_speed := 20.0
@export_range(0.0, 12.0, 0.5) var leaf_intensity := 4.0
@export_group("Banderas / ciclos por segundo y amplitud")
@export_range(0.0, 2.0, 0.05) var flag_speed := 0.65
@export_range(0.0, 1.0, 0.05) var flag_intensity := 1.0
@export_group("Ventiladores / cuadros por segundo y fraccion activa")
@export_range(0.0, 24.0, 0.5) var fan_speed := 10.0
## Intensity is duty cycle: 1 spins continuously, 0 is stationary.
@export_range(0.0, 1.0, 0.05) var fan_intensity := 1.0
@export_group("Flotantes / ciclos por segundo y amplitud en px")
@export_range(0.0, 0.2, 0.005) var float_speed := 0.035
@export_range(0.0, 12.0, 0.5) var float_intensity := 7.0
@export_range(0.0, 3.0, 0.1) var float_bob_intensity := 1.5
@export_group("Fuente / pulsos por segundo e intensidad del agua")
@export_range(0.0, 0.5, 0.01) var fountain_speed := 0.16
@export_range(0.0, 1.0, 0.05) var fountain_intensity := 1.0
@export_group("Sombrillas / ciclos por segundo y desplazamiento en px")
@export_range(0.0, 0.5, 0.01) var umbrella_speed := 0.14
@export_range(0.0, 1.0, 0.1) var umbrella_intensity := 1.0
@export_group("Letrero / ciclos por segundo e intensidad del parpadeo")
@export_range(0.0, 0.5, 0.01) var sign_speed := 0.14
@export_range(0.0, 1.0, 0.05) var sign_intensity := 1.0

var elapsed := 0.0
var central_water_clock := 0.0
var cannon_wave_boost := 1.0
var water_sprites: Array[AnimatedSprite2D] = []
var water_materials: Array[ShaderMaterial] = []
var palms: Array[AnimatedSprite2D] = []
var flags: Array[AnimatedSprite2D] = []
var fans: Array[AnimatedSprite2D] = []
var umbrellas: Array[AnimatedSprite2D] = []
var floats: Array[Dictionary] = []
var leaf_pool: Array[Dictionary] = []
var basins: Array[Rect2] = []
var fountain: AnimatedSprite2D
var bubbles: AnimatedSprite2D
var sign_sprite: AnimatedSprite2D
var fountain_material: ShaderMaterial
var cloud_material: ShaderMaterial
var leaf_frames: SpriteFrames
var rng := RandomNumberGenerator.new()
var leaf_timer := 2.0
var spawned_leaves := 0
var max_active_leaves := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 307105
	var map_root: Node2D = get_parent()
	cloud_material = get_node("SombrasNubes").material
	# The old cloud rectangle was above the guests. Apply its shade to scenery.
	get_node("SombrasNubes").hide()
	scenery_material = ShaderMaterial.new()
	scenery_material.shader = preload("res://lab/shaders/scenery_grade.gdshader")
	scenery_material.set_shader_parameter("ambient", scenery_ambient)
	scenery_material.set_shader_parameter("saturation", 1.03)
	scenery_material.set_shader_parameter("shadow_tint", Vector3(-0.015,0.008,0.015))
	scenery_material.set_shader_parameter("highlight_tint", Vector3(0.018,0.012,-0.006))
	scenery_material.set_shader_parameter("clouds", true)
	for branch in ["01_Pisos","07_Caminos","02_Piletas","03_Senales_y_perimetro","04_Objetos"]:
		_grade(map_root.get_node(branch))
	for pool in map_root.get_node("02_Piletas").get_children():
		var surface: ColorRect = pool.get_node("DestellosAmbiente")
		basins.append(Rect2(pool.position + surface.position, surface.size))
		water_materials.append(surface.material)
		for child in pool.get_children():
			if child is AnimatedSprite2D:
				child.stop()
				water_sprites.append(child)
	var flag_frames: SpriteFrames = load("res://splash/assets/bandera_viento.tres")
	for item in map_root.get_node("04_Objetos").get_children():
		var visual: AnimatedSprite2D = item.get_node_or_null("Textura") as AnimatedSprite2D
		if item.name.begins_with("CanteroPalmera_"):
			var canopy: AnimatedSprite2D = item.get_node("Palmera/Textura")
			canopy.stop()
			palms.append(canopy)
		elif visual:
			if item.name.begins_with("banderin_"):
				visual.stop(); visual.sprite_frames = flag_frames; flags.append(visual)
			elif item.name.begins_with("filtro_"):
				visual.stop(); fans.append(visual)
			elif item.name.begins_with("sombrilla_"):
				visual.stop(); umbrellas.append(visual)
			elif item.name.begins_with("flotador_") or item.name == "PatoGigante":
				visual.stop()
				_register_float(visual, item.name == "PatoGigante")
			elif item.name == "FuenteInfantil":
				visual.stop(); fountain = visual
				fountain_material = ShaderMaterial.new()
				fountain_material.shader = load("res://splash/shaders/fuente_pulso.gdshader")
				fountain.material = fountain_material
				bubbles = item.get_node("BurbujasAmbiente")
				bubbles.stop()
			elif item.name == "KioscoHelados":
				sign_sprite = item.get_node("LetreroAmbiente")
				sign_sprite.stop()
	leaf_frames = load("res://splash/assets/hoja_palmera.tres")
	for i in 2:
		var leaf := Sprite2D.new()
		leaf.name = "Hoja_%d" % i
		leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		leaf.z_index = 2
		leaf.visible = false
		add_child(leaf)
		leaf_pool.append({"sprite": leaf, "age": -1.0, "start": Vector2.ZERO, "end": Vector2.ZERO, "phase": 0.0})
	apply_effects()
	_setup_finish.call_deferred(map_root)

func _setup_finish(map_root: Node2D) -> void:
	var finish := finish_scene.instantiate()
	map_root.add_child(finish)
	finish.configure(map_root,"splash")

func _phase(sprite: Node2D) -> float:
	return fposmod(sprite.global_position.x * 0.0143 + sprite.global_position.y * 0.0067, TAU)

func _register_float(visual: AnimatedSprite2D, large: bool) -> void:
	var frame: AtlasTexture = visual.sprite_frames.get_frame_texture("default", 0)
	var sheet: Image = frame.atlas.get_image()
	var pixels := Rect2()
	for i in visual.sprite_frames.get_frame_count("default"):
		var pose: AtlasTexture = visual.sprite_frames.get_frame_texture("default", i)
		var used := Rect2(sheet.get_region(pose.region).get_used_rect())
		pixels = pixels.merge(used) if pixels.has_area() else used
	var local_rect := Rect2(pixels.position - frame.region.size * 0.5, pixels.size)
	var opaque_rect: Rect2 = visual.global_transform * local_rect
	var pool_rect := Rect2()
	for basin in basins:
		if basin.has_point(opaque_rect.get_center()):
			pool_rect = basin.grow(-3.0)
			break
	assert(pool_rect.has_area(), "Floating prop is not inside a pool")
	floats.append({"sprite": visual, "base": visual.position, "bounds": opaque_rect,
		"pool": pool_rect, "phase": _phase(visual), "large": large})

func _process(delta: float) -> void:
	if enabled and not Preferences.reduced_motion(self):
		elapsed += delta
		central_water_clock += delta * cannon_wave_boost
	_update_leaves(delta if enabled and not Preferences.reduced_motion(self) else 0.0)
	apply_effects()

func apply_effects() -> void:
	if scenery_material:
		scenery_material.set_shader_parameter("effect_time", elapsed)
		scenery_material.set_shader_parameter("cloud_intensity", cloud_intensity)
	var active := 1.0 if enabled else 0.0
	for i in water_materials.size():
		var water_material: ShaderMaterial = water_materials[i]
		water_material.set_shader_parameter("ambient_time", central_water_clock if i == 0 else elapsed)
		water_material.set_shader_parameter("speed", water_speed * active)
		water_material.set_shader_parameter("intensity", water_intensity * active)
	for visual in water_sprites:
		var clock_value := central_water_clock if visual.get_parent().name == "PiletaCentral" else elapsed
		visual.frame = int(clock_value * 5.55556 * water_speed * active + _phase(visual)) % 12 if enabled else 0
	cloud_material.set_shader_parameter("ambient_time", elapsed)
	cloud_material.set_shader_parameter("speed", cloud_speed * active)
	cloud_material.set_shader_parameter("intensity", cloud_intensity * active)
	for visual in palms:
		var step := roundi(sin(elapsed * palm_speed * TAU + _phase(visual)) * palm_intensity * active)
		visual.frame = posmod(step, 8)
	for visual in umbrellas:
		var step := roundi(sin(elapsed * umbrella_speed * TAU + _phase(visual)) * umbrella_intensity * active)
		visual.frame = 2 if step > 0 else (6 if step < 0 else 0)
	for visual in flags:
		var frame := int(elapsed * flag_speed * 4.0 + _phase(visual)) % 4
		visual.frame = frame if flag_intensity * active >= 0.65 else (frame % 2 if flag_intensity * active > 0.0 else 0)
	for visual in fans:
		if not enabled or fan_intensity <= 0.0:
			visual.frame = 0
		elif fposmod(elapsed * 0.125 + _phase(visual) / TAU, 1.0) < fan_intensity:
			visual.frame = int(elapsed * fan_speed + _phase(visual)) % 8
	for entry in floats:
		var visual: AnimatedSprite2D = entry.sprite
		if visual.get_meta("cannon_active", false): continue
		var phase: float = entry.phase
		var angle := elapsed * float_speed * TAU
		var intensity := float_intensity * (0.5 if entry.large else 1.0) * active
		var drift := Vector2(sin(angle + phase), sin(angle * 0.73 + phase * 1.7)) * intensity
		drift.y += sin(angle * 5.0 + phase) * float_bob_intensity * active
		var rect: Rect2 = entry.bounds
		var basin: Rect2 = entry.pool
		drift.x = clampf(drift.x, basin.position.x - rect.position.x, basin.end.x - rect.end.x)
		drift.y = clampf(drift.y, basin.position.y - rect.position.y, basin.end.y - rect.end.y)
		visual.position = entry.base + (drift.round() if enabled else Vector2.ZERO)
		visual.frame = int(elapsed * float_speed * 32.0 + phase) % 8 if enabled and float_intensity > 0.0 else 0
	if fountain:
		var pulse := 0.5 - 0.5 * cos(elapsed * fountain_speed * TAU)
		var flow := (0.45 + 0.55 * smoothstep(0.12, 0.85, pulse)) * fountain_intensity * active
		fountain.frame = int(elapsed * fountain_speed * 48.0) % 8 if enabled else 0
		fountain_material.set_shader_parameter("flow", flow)
		bubbles.frame = int(elapsed * fountain_speed * 48.0 + 3.0) % 8 if enabled else 0
		bubbles.modulate.a = flow
	if sign_sprite:
		var cycle := fposmod(elapsed * sign_speed + 0.2, 1.0)
		var state := 0
		if enabled and sign_intensity > 0.0:
			if cycle >= 0.86 and cycle < 0.89: state = 2 if sign_intensity > 0.6 else 1
			elif cycle >= 0.89 and cycle < 0.93: state = 1
			elif cycle >= 0.93 and cycle < 0.96: state = 3
		sign_sprite.frame = state

func _spawn_leaf() -> void:
	if palms.is_empty(): return
	for entry in leaf_pool:
		if entry.age >= 0.0: continue
		var palm: AnimatedSprite2D = palms[rng.randi_range(0, palms.size() - 1)]
		var start := palm.global_position + Vector2(rng.randf_range(-18.0, 18.0), -24.0)
		var finish := palm.global_position + Vector2(rng.randf_range(-12.0, 12.0), 52.0)
		entry.age = 0.0; entry.start = start; entry.end = finish; entry.phase = rng.randf_range(0.0, TAU)
		spawned_leaves += 1
		return

func _update_leaves(delta: float) -> void:
	if enabled and leaf_intensity > 0.0:
		leaf_timer -= delta * leaf_intensity / 4.0
		if leaf_timer <= 0.0:
			_spawn_leaf()
			leaf_timer = rng.randf_range(11.0, 19.0)
	var active_count := 0
	for entry in leaf_pool:
		var sprite: Sprite2D = entry.sprite
		if not enabled or leaf_intensity <= 0.0:
			sprite.hide(); entry.age = -1.0; continue
		if entry.age < 0.0: continue
		entry.age += delta * leaf_speed / 20.0
		var age: float = entry.age
		if age >= 4.5:
			sprite.hide(); entry.age = -1.0; continue
		active_count += 1
		var position_world: Vector2 = entry.start.lerp(entry.end, minf(1.0, age / 4.0))
		position_world.x += sin(age * 2.0 + float(entry.phase)) * 7.0
		sprite.position = to_local(position_world.round())
		sprite.texture = leaf_frames.get_frame_texture("default", int(age * 3.0) % 4)
		sprite.modulate.a = clampf((4.5 - age) * 2.0, 0.0, 1.0)
		sprite.show()
	max_active_leaves = maxi(max_active_leaves, active_count)

func _grade(node: Node) -> void:
	if node is CanvasItem: node.light_mask = 2
	if node is Sprite2D or node is AnimatedSprite2D or node is TileMapLayer:
		if node.material == null: node.material = scenery_material
	for child in node.get_children(): _grade(child)

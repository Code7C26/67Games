extends RefCounted
func apply(map_root: Node2D) -> void:
	var builder: RefCounted = load("res://tools/part3_builder.gd").new()
	for asset in [["pato_canon",160,144,3,6.0],["splash_deck",48,28,4,10.0],["charco_deck",64,24,3,1.0],["npc_empapado",32,40,4,8.0]]:
		builder.frames(asset[0], Vector2(asset[1],asset[2]), asset[3], asset[4])
	builder.frames("pato_giro",Vector2(160,144),16,10.0)
	builder.frames("splash_corona",Vector2(64,48),4,1.0/0.12)
	var previous := map_root.get_node_or_null("09_GranChapuzon")
	if previous: map_root.remove_child(previous); previous.free()
	var root := Node2D.new(); root.name = "09_GranChapuzon"
	root.set_script(load("res://splash/scripts/duck_cannon.gd")); map_root.add_child(root)
	var drop: Texture2D = load("res://splash/assets/gota_canon.png")
	for item in [["ChorroPico",96,0.8,450.0,490.0,600.0],["GeiserCabeza",24,0.58,130.0,190.0,600.0],["BurbujasAviso",16,0.85,12.0,30.0,-25.0]]:
		var emitter := CPUParticles2D.new(); emitter.name = item[0]
		emitter.emitting = false; emitter.texture = drop; emitter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		emitter.amount = item[1]; emitter.lifetime = item[2]; emitter.direction = Vector2.UP
		emitter.initial_velocity_min = item[3]; emitter.initial_velocity_max = item[4]
		emitter.gravity = Vector2(0, item[5]); emitter.spread = 1.5; emitter.z_index = 3; emitter.local_coords = false
		emitter.scale_amount_min = 0.8; emitter.scale_amount_max = 1.4; emitter.fixed_fps = 60
		if emitter.name == "BurbujasAviso":
			emitter.texture = load("res://splash/assets/burbuja_canon.png")
			emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			emitter.emission_rect_extents = Vector2(94,10); emitter.spread = 45
			var gradient := Gradient.new(); gradient.set_color(0, Color(1,1,1,0)); gradient.set_color(1,Color(1,1,1,0)); gradient.add_point(0.2,Color.WHITE)
			emitter.color_ramp = gradient
		root.add_child(emitter)
	var area := Area2D.new(); area.name = "ParqueMojado"; area.position = Vector2(960,536)
	area.collision_layer = 0; area.collision_mask = 2; area.monitorable = false
	var shape := CollisionShape2D.new(); var rectangle := RectangleShape2D.new(); rectangle.size = Vector2(1792,800)
	shape.shape = rectangle; area.add_child(shape); root.add_child(area)
	builder.own(root, map_root); root.owner = map_root
	# Decals render above tiles and below props/actors; all solid geometry stays put.
	map_root.get_node("04_Objetos").z_index = 1
	map_root.get_node("06_Marcadores/ChapuzonOeste").position = Vector2(800,776)
	map_root.get_node("06_Marcadores/ChapuzonCentro").position = Vector2(992,776)
	map_root.get_node("06_Marcadores/ChapuzonEste").position = Vector2(1200,776)
	for label_node in map_root.get_node("03_Senales_y_perimetro").get_children():
		if not label_node is Label: continue
		if label_node.text == "02 / GRAN CHAPUZON": label_node.text = "02 / PILETA FAMILIAR"
		elif label_node.text == "AGUA / 24 C": label_node.text = "CANON / GRAN CHAPUZON"
		else: continue
		var width: float = label_node.get_theme_font("font").get_string_size(label_node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
		label_node.position.x = 960 - width*0.5
	var legacy: Node2D = map_root.get_node("05_Efectos")
	for child in legacy.get_children(): legacy.remove_child(child); child.free()
	legacy.hide()
	map_root.warning_seconds = 1.5; map_root.splash_seconds = 1.5; map_root.settle_seconds = 1.0
	map_root.max_attracted_visitors = 0
	map_root.set_meta("attraction_revision", "giro360_corona")
	make_whistle()

func make_whistle() -> void:
	var audio := AudioStreamWAV.new(); audio.format = AudioStreamWAV.FORMAT_16_BITS; audio.mix_rate = 22050
	var data := PackedByteArray(); var samples := int(0.45*22050); data.resize(samples*2)
	for i in samples:
		var t := float(i)/22050.0
		var pulse := fposmod(t,0.23)
		var envelope := clampf(pulse/0.012,0.0,1.0)*clampf((0.18-pulse)/0.035,0.0,1.0)
		var wave := sin(TAU*2650.0*t + 0.6*sin(TAU*25.0*t))*0.65 + sin(TAU*3980.0*t)*0.16
		data.encode_s16(i*2,int(wave*envelope*24000.0))
	audio.data = data
	assert(audio.save_to_wav("res://splash/assets/silbato_guardavidas.wav") == OK)

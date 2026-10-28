extends Node2D
## One-way evacuation of the 16 scenery actors. Proxies are visuals, never hosts.
const Readability = preload("res://scripts/npc_readability.gd")
var host: Node2D
var life: Node2D
var started := false
var age := 0.0
var entries: Array[Dictionary] = []
var evacuated := 0
var notice: PanelContainer
var portals := [Vector2(960, 928), Vector2(1416, 328), Vector2(1640, 328)]
var thresholds := [Vector2(960, 956), Vector2(1430, 252), Vector2(1642, 252)]

func configure(map_host: Node2D, park: Node2D) -> void:
	host = map_host
	life = park
	z_index = 5
	y_sort_enabled = true
	host.fase_infeccion_iniciada.connect(begin)
	set_process(false)

func begin() -> void:
	if started: return
	started = true
	# Snapshot each actor before stopping its routine; no actor jumps to a spawn.
	for actor in life.actors:
		var prefix := PackedVector2Array([actor.global_position, actor.to_global(actor.exit_offset)])
		_add(actor.visual, actor.walking_frames, prefix)
	for entry in life.customers:
		_add(entry.sprite, entry.sprite.sprite_frames, PackedVector2Array([entry.sprite.global_position]))
	for i in life.changing.size():
		var sprite: AnimatedSprite2D = life.changing[i].sprite
		_add(sprite, sprite.sprite_frames, PackedVector2Array([sprite.global_position, Vector2(1430 + i * 212, 330)]))
		var door := AnimatedSprite2D.new()
		door.name = "ShelterDoor%d" % i
		door.position = life.changing[i].door.global_position
		door.sprite_frames = life.changing[i].door.sprite_frames
		door.frame = 4
		add_child(door)
	for i in life.sliders.size():
		var entry: Dictionary = life.sliders[i]
		var swim: PackedVector2Array = life._swim_path(i)
		var prefix := PackedVector2Array()
		var source: AnimatedSprite2D = entry.sprite if entry.sprite.visible else entry.swimmer
		var rider_end := 0
		if entry.sprite.visible:
			prefix.append(source.global_position)
			var curve: Curve2D = entry.follower.get_parent().curve
			for sample in range(1, 25):
				var ratio := lerpf(entry.follower.progress_ratio, 1.0, sample / 24.0)
				prefix.append(curve.sample_baked(ratio * curve.get_baked_length()) + entry.sprite.position)
			rider_end = prefix.size()
			prefix.append_array(swim)
		elif source.position.x < 550 and source.position.y > 345 and source.position.y < 535:
			prefix = _remaining(swim, source.global_position)
		else:
			prefix.append(source.global_position)
		_add(source, entry.swimmer.sprite_frames, prefix, rider_end)
	life.enabled = false
	life.process_mode = Node.PROCESS_MODE_DISABLED
	life.hide()
	_show_notice()
	set_process(true)

func _remaining(path: PackedVector2Array, point: Vector2) -> PackedVector2Array:
	var nearest := INF
	var index := 0
	for i in range(1, path.size()):
		var projected := Geometry2D.get_closest_point_to_segment(point, path[i - 1], path[i])
		var distance := projected.distance_squared_to(point)
		if distance < nearest:
			nearest = distance
			index = i
	var result := PackedVector2Array([point])
	for i in range(index, path.size()): result.append(path[i])
	return result

func _add(source: AnimatedSprite2D, frames: SpriteFrames, prefix: PackedVector2Array, rider_end: int = 0) -> void:
	var proxy := Node2D.new()
	proxy.name = "AmbientEvacuee%d" % entries.size()
	proxy.add_to_group("ambient_evacuating")
	proxy.set_meta("infectable", false)
	add_child(proxy)
	proxy.global_position = source.global_position
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Visual"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = source.sprite_frames if rider_end > 0 else frames
	sprite.animation = source.animation if rider_end > 0 else "Abajo"
	sprite.material = source.material
	sprite.modulate.a = source.modulate.a
	proxy.add_child(sprite)
	Readability.shadow(proxy)
	var badge := Label.new()
	badge.name = "AmbientBadge"
	badge.text = "SALIDA"
	badge.position = Vector2(-30, -37)
	badge.add_theme_font_size_override("font_size", 12)
	badge.add_theme_color_override("font_color", Color("d6edb7"))
	badge.add_theme_color_override("font_outline_color", Color("18282b"))
	badge.add_theme_constant_override("outline_size", 4)
	proxy.add_child(badge)
	# Authored first legs leave chairs, counters, the slide and changing rooms.
	var departure := prefix[-1]
	var nearest := host.npc_destinations[0] as Vector2
	var best := INF
	for point in host.npc_destinations:
		var distance: float = departure.distance_squared_to(point)
		if distance < best:
			nearest = point
			best = distance
	var path := PackedVector2Array()
	var portal := -1
	best = INF
	for i in portals.size():
		var candidate: PackedVector2Array = host.npc_navigation.ruta(nearest, portals[i])
		if candidate.is_empty(): continue
		var distance: float = life._length(candidate)
		if distance < best:
			path = candidate
			portal = i
			best = distance
	var shelter := path.is_empty()
	if not shelter:
		prefix.append(nearest)
		prefix.append_array(path)
		prefix.append(thresholds[portal])
	else:
		badge.text = "A RESGUARDO"
	entries.append({"node": proxy, "sprite": sprite, "frames": frames, "path": prefix,
		"index": 1, "rider_end": rider_end, "delay": 0.25 + entries.size() * 0.12,
		"finished": false, "shelter": shelter, "fade": 0.0, "start": source.global_position,
		"initial_alpha": source.modulate.a})

func _show_notice() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	var layout := Control.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(layout)
	notice = PanelContainer.new()
	notice.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	notice.position = Vector2(-290, 80)
	notice.size = Vector2(580, 64)
	notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18282bef")
	style.border_color = Color("92b776")
	style.set_border_width_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	notice.add_theme_stylebox_override("panel", style)
	layout.add_child(notice)
	var text := Label.new()
	text.text = "EVACUACIÓN DEL PARQUE\nLos personajes de ambiente no se infectan: salen a resguardo."
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 17)
	text.add_theme_color_override("font_color", Color("d6edb7"))
	notice.add_child(text)

func _process(delta: float) -> void:
	age += delta
	if is_instance_valid(notice): notice.modulate.a = 1.0 - clampf((age - 6.5) / 1.0, 0, 1)
	for entry in entries:
		if entry.finished or age < entry.delay: continue
		var actor: Node2D = entry.node
		var sprite: AnimatedSprite2D = entry.sprite
		var path: PackedVector2Array = entry.path
		var remaining := delta * (135.0 if entry.index < entry.rider_end else 110.0)
		var old := actor.position
		while remaining > 0 and entry.index < path.size():
			var distance := actor.position.distance_to(path[entry.index])
			var reached := distance <= remaining
			actor.position = actor.position.move_toward(path[entry.index], remaining)
			remaining -= distance
			if reached: entry.index += 1
			else: break
		if entry.index >= entry.rider_end:
			sprite.sprite_frames = entry.frames
			var direction := actor.position - old
			sprite.animation = ("Derecha" if direction.x >= 0 else "Izquierda") if absf(direction.x) > absf(direction.y) else ("Abajo" if direction.y >= 0 else "Arriba")
		sprite.frame = int(age * 8.0) % sprite.sprite_frames.get_frame_count(sprite.animation)
		# A visitor already behind a changing-room door emerges through it.
		sprite.modulate.a = lerpf(entry.initial_alpha, 1.0, clampf(actor.position.distance_to(entry.start) / 32.0, 0, 1))
		if entry.index >= path.size() or (entry.shelter and age > 8.0):
			entry.fade += delta
			actor.modulate.a = 1.0 - clampf(entry.fade / 0.5, 0, 1)
			if entry.fade >= 0.5:
				entry.finished = true
				actor.hide()
				evacuated += 1
	if evacuated == entries.size():
		for i in life.changing.size(): get_node("ShelterDoor%d" % i).frame = 0

extends RefCounted
## Pixel-preserving padding. Cached textures are shared; team materials are not.
const OUTLINE_PADDING := 2
static var textures: Dictionary = {}
static func padded(source: SpriteFrames) -> SpriteFrames:
	if source == null or source.get_meta("outline_padding", false): return source
	if source.has_meta("readable_frames"): return source.get_meta("readable_frames")
	var result := SpriteFrames.new()
	result.remove_animation(&"default")
	for animation in source.get_animation_names():
		result.add_animation(animation)
		result.set_animation_speed(animation, source.get_animation_speed(animation))
		result.set_animation_loop(animation, source.get_animation_loop(animation))
		for index in source.get_frame_count(animation):
			var texture := source.get_frame_texture(animation, index)
			if texture == null: continue
			var key := texture.resource_path
			if texture is AtlasTexture:
				key = texture.atlas.resource_path + str(texture.region) + str(texture.margin)
			if key.is_empty(): key = str(texture.get_instance_id())
			if not textures.has(key):
				var original := texture.get_image()
				original.convert(Image.FORMAT_RGBA8)
				var image := Image.create(original.get_width()+OUTLINE_PADDING*2, original.get_height()+OUTLINE_PADDING*2, false, Image.FORMAT_RGBA8)
				image.fill(Color.TRANSPARENT)
				image.blit_rect(original, Rect2i(Vector2i.ZERO, original.get_size()), Vector2i(OUTLINE_PADDING, OUTLINE_PADDING))
				textures[key] = ImageTexture.create_from_image(image)
			result.add_frame(animation, textures[key], source.get_frame_duration(animation,index))
	result.set_meta("outline_padding", true)
	source.set_meta("readable_frames", result)
	return result

static func body_metrics(frames: SpriteFrames) -> Vector2:
	# Measure the painted body, not the transparent 32 px canvas or outline padding.
	# One stable scale for the entire walk avoids size flicker between frames.
	if frames.has_meta("body_metrics"): return frames.get_meta("body_metrics")
	var height := 0.0
	var feet := 0.0
	var count := 0
	for animation in frames.get_animation_names():
		for index in frames.get_frame_count(animation):
			var texture := frames.get_frame_texture(animation, index)
			if texture == null: continue
			var bounds := texture.get_image().get_used_rect()
			if bounds.size.y == 0: continue
			height += bounds.size.y
			feet = maxf(feet, bounds.end.y - texture.get_height() * 0.5)
			count += 1
	var result := Vector2(height / maxf(count, 1.0), feet)
	frames.set_meta("body_metrics", result)
	return result

static func shadow(actor: Node2D) -> void:
	var ellipse := Polygon2D.new()
	ellipse.name = "ContactShadow"
	var points := PackedVector2Array()
	for i in 20:
		var angle := TAU * float(i)/20.0
		points.append(Vector2(cos(angle)*10.0, sin(angle)*3.0))
	ellipse.polygon = points
	ellipse.position = Vector2(0,13)
	ellipse.color = Color(0.015,0.025,0.04,0.38)
	ellipse.show_behind_parent = true
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	ellipse.material = material
	actor.add_child(ellipse)

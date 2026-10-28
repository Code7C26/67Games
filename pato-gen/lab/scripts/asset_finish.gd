extends RefCounted
## Cached replacement textures preserve frame regions, timing and collision data.
static var sheets: Dictionary = {}
static var frames_cache: Dictionary = {}

static func apply(visual: Node2D, id: String, directory: String) -> bool:
	var path := directory+id+".png"
	if not ResourceLoader.exists(path): return false
	if not sheets.has(path): sheets[path] = load(path)
	var sheet: Texture2D = sheets[path]
	if visual is AnimatedSprite2D:
		var original: SpriteFrames = visual.sprite_frames
		var key := original.resource_path+path
		if not frames_cache.has(key):
			var frames: SpriteFrames = original.duplicate()
			for animation in original.get_animation_names():
				for index in original.get_frame_count(animation):
					var source := original.get_frame_texture(animation,index)
					var texture: Texture2D = sheet
					if source is AtlasTexture:
						var atlas: AtlasTexture = source.duplicate()
						atlas.atlas = sheet
						texture = atlas
					frames.set_frame(animation,index,texture,original.get_frame_duration(animation,index))
			frames_cache[key] = frames
		var animation: StringName = visual.animation
		var frame: int = visual.frame
		var progress: float = visual.frame_progress
		visual.sprite_frames = frames_cache[key]
		visual.animation = animation
		visual.set_frame_and_progress(frame,progress)
	else:
		if visual.texture is CanvasTexture:
			var surface: CanvasTexture = visual.texture.duplicate()
			surface.diffuse_texture = sheet
			visual.texture = surface
		else: visual.texture = sheet
	return true

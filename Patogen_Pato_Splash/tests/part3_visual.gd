extends Node
func _ready() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(128, 128)
	view.world_2d = World2D.new()
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	var texture := AtlasTexture.new()
	texture.atlas = load("res://splash/assets/fuente_hongo.png")
	texture.region = Rect2(0, 0, 128, 128)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var flow_material := ShaderMaterial.new()
	flow_material.shader = load("res://splash/shaders/fuente_pulso.gdshader")
	sprite.material = flow_material
	view.add_child(sprite)
	flow_material.set_shader_parameter("flow", 1.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var full := view.get_texture().get_image()
	flow_material.set_shader_parameter("flow", 0.0)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var stopped := view.get_texture().get_image()
	var protected_changes := 0
	var water_changes := 0
	for y in 128:
		for x in 128:
			var changed := full.get_pixel(x, y) != stopped.get_pixel(x, y)
			var protected_pixel := y < 54 or y >= 100 or (x >= 55 and x < 75)
			if changed:
				if protected_pixel: protected_changes += 1
				else: water_changes += 1
	var result := {"passed": protected_changes == 0 and water_changes > 100,
		"structural_pixels_changed": protected_changes, "water_pixels_pulsed": water_changes}
	var file := FileAccess.open("res://tests/part3_visual_validation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t")); file.close()
	print("PART3_VISUAL ", JSON.stringify(result))
	assert(result.passed, "Fountain pulse changed cap, column or basin")
	get_tree().quit()

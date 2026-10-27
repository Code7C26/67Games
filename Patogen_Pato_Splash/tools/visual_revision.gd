extends RefCounted
func apply(map_root: Node2D) -> void:
	var pixel_font: FontFile = load("res://splash/assets/PressStart2P.ttf")
	pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	pixel_font.hinting = TextServer.HINTING_NONE
	pixel_font.oversampling = 1.0
	pixel_font.generate_mipmaps = false
	pixel_font.multichannel_signed_distance_field = false
	assert(ResourceSaver.save(pixel_font, "res://splash/assets/press_start_2p.tres") == OK)
	pixel_font = load("res://splash/assets/press_start_2p.tres")
	var centers := {"01 / TOBOGANES":368.0, "02 / GRAN CHAPUZON":960.0,
		"03 / MINI SPLASH":1552.0, "REPOSERAS":320.0, "HELADOS & LIMONADA":1608.0,
		"VESTUARIOS / LOCKERS":1568.0, "PATO SPLASH":960.0,
		"UN BUEN DIA PARA UN CHAPUZON":960.0, "1.20 m":960.0, "AGUA / 24 C":960.0}
	for label_node in map_root.get_node("03_Senales_y_perimetro").get_children():
		if not label_node is Label: continue
		var font_size := 24 if label_node.text == "PATO SPLASH" else 8
		label_node.add_theme_font_override("font", pixel_font)
		label_node.add_theme_font_size_override("font_size", font_size)
		label_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if centers.has(label_node.text):
			var width := pixel_font.get_string_size(label_node.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			label_node.position.x = roundf(float(centers[label_node.text]) - width * 0.5)
		label_node.reset_size()
	map_root.set_meta("visual_revision", "press_start_clouds_central_duck")

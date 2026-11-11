extends "res://tests/capture_garfio_selector.gd"
## Rendered approved Rastreador portrait, sixth card choice and responsive labels.

func check_layout(dimensions: Vector2i) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0)
	var fit := bounds.encloses(host.continue_button.get_global_rect()) and bounds.encloses(host.back_button.get_global_rect())
	var text_fits := true
	var details_clear := true
	for card in host.cards:
		var card_rect: Rect2 = card.root.get_global_rect().grow(1.0)
		fit = fit and bounds.encloses(card.root.get_global_rect())
		for control in [card.portrait, card.title, card.role, card.advantage, card.challenge] + card.tabs:
			fit = fit and card_rect.encloses(control.get_global_rect())
		for tab in card.tabs:
			text_fits = text_fits and tab.get_combined_minimum_size().x <= tab.size.x + 1
		details_clear = details_clear and card.challenge.get_global_rect().end.y + 4 <= card.tabs_row.get_global_rect().position.y
		check(card.tabs.size() == 6 and card.tabs[5].button_pressed, "Rastreador selected in six-tab card " + str(dimensions))
		check(card.portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "approved Rastreador art stays pixel sharp " + str(dimensions))
	check(fit, "Rastreador selector content fits " + str(dimensions))
	check(text_fits, "six strain tab labels fit " + str(dimensions))
	check(details_clear, "wrapped Rastreador details clear tabs " + str(dimensions))

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/rastreador-integracion-nov06/capturas").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var boot: Node = root.get_node("PatogenOnboarding")
	var old_motion: bool = bool(boot.profile.data.reduced_motion)
	boot.profile.data.reduced_motion = true
	root.set_meta("patogen_cepas", {1: "rastreador", 2: "rastreador"})
	await resize_view(Vector2i(1920, 1080))
	host = load("res://scenes/character_select.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1024, 768)]:
		await resize_view(dimensions)
		check_layout(dimensions)
		await shot("selector_rastreador_%dx%d" % [dimensions.x, dimensions.y])
	boot.profile.data.reduced_motion = old_motion
	host.free()
	root.get_node("AudioManager").detener_musica()
	await process_frame
	print("RASTREADOR_SELECTOR ", checks, " checks / ", failures, " failures")
	quit(1 if failures else 0)

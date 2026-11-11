extends SceneTree
## Character selection state, input, responsive layout and the real map handoff.
var checks := 0
var failures := 0
var results: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	results.append({"test": message, "passed": ok})
	if ok:
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func settle() -> void:
	for _frame in 6:
		await process_frame

func selector_scene() -> Control:
	if is_instance_valid(current_scene):
		current_scene.free()
	var selector: Control = load("res://scenes/character_select.tscn").instantiate()
	root.add_child(selector)
	current_scene = selector
	await settle()
	return selector

func press(selector: Control, code: Key, echo: bool = false, down: bool = true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	event.echo = echo
	selector._unhandled_key_input(event)

func delivered_press(code: Key, repeat: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.echo = repeat
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func wait_loading() -> void:
	var boot: Node = root.get_node("PatogenOnboarding")
	var deadline := Time.get_ticks_msec() + 15000
	while is_instance_valid(boot.loading_screen) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not is_instance_valid(boot.loading_screen), "scene transition completes")
	await settle()

func run() -> void:
	var boot: Node = root.get_node("PatogenOnboarding")
	var old_motion: bool = bool(boot.profile.data.reduced_motion)
	boot.profile.data.reduced_motion = true
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	if root.has_meta("patogen_cepas"):
		root.remove_meta("patogen_cepas")
	var selector: Control = await selector_scene()
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "both players default to Atletico")
	check(selector.cards.size() == 2, "both players have their own selection card")
	check(selector.STRAINS.size() == 6 and selector.cards[0].tabs.size() == 6 and selector.cards[1].tabs.size() == 6, "six strains are available to both players")
	check(root.gui_get_focus_owner() != null, "selector starts with keyboard focus")
	root.set_meta("patogen_cepas", {1: "unknown", 2: ""})
	selector = await selector_scene()
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "unknown remembered strains fall back safely")
	root.set_meta("patogen_cepas", {1: "area", 2: "exponencial"})
	selector = await selector_scene()
	check(selector.indice_cian == 1 and selector.indice_magenta == 2, "remembered choices restore independently")
	check(selector.cards[0].tabs[1].button_pressed and selector.cards[1].tabs[2].button_pressed, "remembered choices agree with the selected tabs")
	selector._choose(1, 2)
	check(selector.indice_cian == 2 and selector.indice_magenta == 2, "blue selection does not change magenta")
	selector._choose(2, 1)
	check(selector.indice_cian == 2 and selector.indice_magenta == 1, "magenta selection does not change blue")
	selector._choose(1, selector.STRAINS.size() - 1)
	selector._cycle(1, 1)
	check(selector.indice_cian == 0 and selector.indice_magenta == 1, "next strain wraps from the last to the first")
	selector._choose(2, 0)
	selector._cycle(2, -1)
	check(selector.indice_magenta == selector.STRAINS.size() - 1 and selector.indice_cian == 0, "previous strain wraps from the first to the last")
	root.set_meta("patogen_cepas", {1: "garfio", 2: "garfio"})
	selector = await selector_scene()
	check(selector.indice_cian == 3 and selector.indice_magenta == 3 and selector.cards[0].tabs[3].button_pressed and selector.cards[1].tabs[3].button_pressed, "Garfio restores independently as the fourth strain")
	press(selector, KEY_D)
	press(selector, KEY_RIGHT)
	check(selector.indice_cian == 4 and selector.indice_magenta == 4, "both keyboard controls cycle from Garfio to Camaleon")
	check(selector.cards[0].portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and selector.cards[1].portrait.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Camaleon approved pixel art keeps nearest filtering for both teams")
	selector._save_choices()
	selector = await selector_scene()
	check(selector.indice_cian == 4 and selector.indice_magenta == 4 and selector.cards[0].tabs[4].button_pressed and selector.cards[1].tabs[4].button_pressed, "Camaleon restores independently as the fifth strain")
	press(selector, KEY_D)
	press(selector, KEY_RIGHT)
	check(selector.indice_cian == 5 and selector.indice_magenta == 5, "both keyboard controls reach Rastreador as the sixth strain")
	selector._save_choices()
	check(root.get_meta("patogen_cepas", {}) == {1: "rastreador", 2: "rastreador"}, "Rastreador saves its real identifier for both teams")
	selector = await selector_scene()
	check(selector.indice_cian == 5 and selector.indice_magenta == 5 and selector.cards[0].tabs[5].button_pressed and selector.cards[1].tabs[5].button_pressed, "Rastreador restores independently for both teams")
	selector.cards[0].tabs[1].pressed.emit()
	selector.cards[1].tabs[0].pressed.emit()
	check(selector.indice_cian == 1 and selector.indice_magenta == 0, "strain tabs select the correct player and strain")
	var accessible := true
	for card in selector.cards:
		for tab in card.tabs:
			accessible = accessible and tab.focus_mode == Control.FOCUS_ALL
			tab.grab_focus()
			accessible = accessible and tab.has_focus()
	check(accessible, "all strain tabs can receive keyboard focus")
	var exclusive := true
	for team in 2:
		var selected_tabs := 0
		for tab in selector.cards[team].tabs:
			if tab.button_pressed:
				selected_tabs += 1
		exclusive = exclusive and selected_tabs == 1
	check(exclusive, "each player always has exactly one selected tab")
	selector.cards[0].tabs[0].grab_focus()
	selector._choose(1, 2)
	check(selector.cards[0].tabs[2].has_focus(), "changing a strain moves focus to the selected tab within the same player")
	selector._choose(1, 0)
	selector._choose(2, 0)
	press(selector, KEY_D)
	check(selector.indice_cian == 1 and selector.indice_magenta == 0, "D cycles only the blue player")
	press(selector, KEY_A)
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "A cycles blue backwards")
	press(selector, KEY_RIGHT)
	check(selector.indice_cian == 0 and selector.indice_magenta == 1, "right arrow cycles only magenta")
	press(selector, KEY_LEFT)
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "left arrow cycles magenta backwards")
	press(selector, KEY_D, true)
	press(selector, KEY_RIGHT, false, false)
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "held key repeats and key releases do not cycle strains")
	await settle()
	selector.cards[0].tabs[0].grab_focus()
	await delivered_press(KEY_D)
	check(selector.indice_cian == 1 and selector.indice_magenta == 0, "viewport input delivers D exactly once with a tab focused")
	check(selector.cards[0].tabs[1].has_focus(), "D keeps focus on the selected blue strain")
	await delivered_press(KEY_A)
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "viewport input delivers A exactly once with a tab focused")
	check(selector.cards[0].tabs[0].has_focus(), "A keeps focus on the selected blue strain")
	await delivered_press(KEY_RIGHT)
	check(selector.indice_cian == 0 and selector.indice_magenta == 1, "viewport right arrow changes magenta before GUI focus consumes it")
	check(selector.cards[1].tabs[1].has_focus(), "right arrow moves focus to the selected magenta strain")
	await delivered_press(KEY_RIGHT, true)
	check(selector.indice_cian == 0 and selector.indice_magenta == 1 and selector.cards[1].tabs[1].has_focus(), "repeated right arrow preserves selection and focus instead of navigating GUI tabs")
	await delivered_press(KEY_LEFT)
	check(selector.indice_cian == 0 and selector.indice_magenta == 0, "viewport left arrow changes magenta before GUI focus consumes it")
	check(selector.cards[1].tabs[0].has_focus(), "left arrow keeps focus on the selected magenta strain")
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540), Vector2i(1024, 768)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		selector._choose(1, 4)
		selector._choose(2, 4)
		await settle()
		var bounds := Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0)
		var controls_fit := bounds.encloses(selector.continue_button.get_global_rect()) and bounds.encloses(selector.back_button.get_global_rect())
		var contents_fit := true
		var actions_clear := true
		for card in selector.cards:
			var card_rect: Rect2 = card.root.get_global_rect()
			controls_fit = controls_fit and bounds.encloses(card_rect)
			for item in [card.previous, card.next, card.portrait, card.title] + card.tabs:
				contents_fit = contents_fit and card_rect.grow(1.0).encloses(item.get_global_rect())
			for tab in card.tabs:
				contents_fit = contents_fit and tab.get_combined_minimum_size().x <= tab.size.x + 1
			actions_clear = actions_clear and not card_rect.intersects(selector.continue_button.get_global_rect()) and not card_rect.intersects(selector.back_button.get_global_rect())
		check(controls_fit, "cards and actions fit %sx%s" % [dimensions.x, dimensions.y])
		check(contents_fit, "portrait, title and selectors fit their card %sx%s" % [dimensions.x, dimensions.y])
		check(actions_clear and not selector.cards[0].root.get_global_rect().intersects(selector.cards[1].root.get_global_rect()), "cards and footer do not overlap %sx%s" % [dimensions.x, dimensions.y])
		for strain_index in [3, 5]:
			selector._choose(1, strain_index)
			selector._choose(2, strain_index)
			await settle()
			var details_fit := true
			for card in selector.cards:
				var card_rect: Rect2 = card.root.get_global_rect().grow(1.0)
				var tabs_rect: Rect2 = card.tabs_row.get_global_rect()
				for copy in [card.advantage, card.challenge]:
					var text_rect: Rect2 = copy.get_global_rect()
					details_fit = details_fit and card_rect.encloses(text_rect) and not text_rect.intersects(tabs_rect)
			check(details_fit, "%s new tactical copy fits above selectors %sx%s" % [selector.STRAINS[strain_index].id, dimensions.x, dimensions.y])
	root.content_scale_size = Vector2i(1920, 1080)
	root.size = Vector2i(1920, 1080)
	await settle()
	selector._choose(1, 1)
	selector._choose(2, 2)
	boot.transition_to("res://scenes/character_select.tscn")
	var inbound: Node = boot.loading_screen
	selector._on_comenzar_pressed()
	check(not selector.launching and not selector.continue_button.disabled and boot.loading_screen == inbound, "an existing loading overlay does not lock the selector on an ignored transition")
	inbound.cancel()
	await settle()
	check(not is_instance_valid(boot.loading_screen) and current_scene == selector, "canceling the existing overlay leaves character selection available")
	boot.requested_mode = "tutorial"
	selector._on_comenzar_pressed()
	check(root.get_meta("patogen_cepas", {}) == {1: "area", 2: "exponencial"}, "continue stores both chosen strain identifiers")
	var pending: Node = boot.loading_screen
	selector._on_comenzar_pressed()
	check(selector.launching and is_instance_valid(pending) and boot.loading_screen == pending, "repeated continue keeps a single pending transition")
	pending.cancel()
	await settle()
	check(not selector.launching and not selector.continue_button.disabled and not selector.back_button.disabled, "canceling a pending map load restores both action buttons")
	boot.requested_mode = "tutorial"
	selector._on_comenzar_pressed()
	check(selector.launching and is_instance_valid(boot.loading_screen), "continue can retry after loading cancellation")
	await wait_loading()
	check(is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("map_select.tscn"), "continue opens the actual map selector")
	check(boot.requested_mode == "tutorial", "map selection preserves the requested tutorial mode")
	if is_instance_valid(current_scene) and current_scene.has_method("_back"):
		current_scene._back()
		await settle()
	check(is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("character_select.tscn"), "map back returns to character selection")
	if is_instance_valid(current_scene) and current_scene.scene_file_path.ends_with("character_select.tscn"):
		check(current_scene.indice_cian == 1 and current_scene.indice_magenta == 2, "map return retains both independent selections")
	boot.profile.data.reduced_motion = old_motion
	var output := ProjectSettings.globalize_path("res://../work/garfio-rastreador-mutaciones-nov07").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	var report := FileAccess.open(output.path_join("test_character_select_results.json"), FileAccess.WRITE)
	if report:
		report.store_string(JSON.stringify({"checks": results, "total": checks, "failures": failures}, "  "))
		report.close()
	if is_instance_valid(current_scene):
		current_scene.free()
	root.get_node("AudioManager").detener_musica()
	await process_frame
	print("CHARACTER_SELECT ", checks, " checks / ", failures, " failures")
	quit(1 if failures else 0)

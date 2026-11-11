extends Control

const Design = preload("res://patogen_onboarding/ui_theme.gd")
const PIXEL_FONT = preload("res://Fuentes/press-start-2p.ttf")
const CYAN := Color("58d8d8")
const MAGENTA := Color("ed88b9")
const CREAM := Color("f3eee0")
const MUTED := Color("a8bec2")
const STRAINS := [
	{
		"id": "atletico", "title": "ATLÉTICO", "role": "Persecución y presión constante",
		"advantage": "Alta velocidad para alcanzar huéspedes.",
		"challenge": "Menos contagio; los humanos se curan antes.",
		"art": preload("res://assets/atletico abajo.png"),
		"frame": Rect2i(0, 0, 32, 32)
	},
	{
		"id": "area", "title": "DE ÁREA", "role": "Contagios en cadena y control de zonas",
		"advantage": "Más contagio y curaciones más lentas.",
		"challenge": "Menor velocidad al perseguir.",
		"art": preload("res://assets/area abajo.png"),
		"frame": Rect2i(0, 0, 32, 32)
	},
	{
		"id": "exponencial", "title": "EXPONENCIAL", "role": "Adaptación, reproducción y crecimiento",
		"advantage": "Mejora con el tiempo y multiplica infectados.",
		"challenge": "Inicio débil; los humanos se curan antes.",
		"art": preload("res://assets/exponencial abajo.png"),
		"frame": Rect2i(0, 0, 32, 32)
	},
	{
		"id": "garfio", "title": "GARFIO", "role": "Secuestro biológico y control de presas",
		"advantage": "Captura y arrastra. Mutaciones: vulnerabilidad, doble tendón y reenganche.",
		"challenge": "Exige línea libre; contagio sin garantía. Poseído: X / J para enganchar.",
		"art": preload("res://assets/garfio/retrato.png")
	},
	{
		"id": "camaleon", "title": "CAMALEÓN", "role": "Infiltración y emboscadas",
		"advantage": "Acecha sin activar la huida a distancia. Poseído: X / J para camuflar.",
		"challenge": "Se revela al contagiar o acercarse mucho; debe esperar para ocultarse.",
		"art": preload("res://assets/camaleon/retrato.png")
	},
	{
		"id": "rastreador", "title": "RASTREADOR", "role": "Líder táctico y cacería colectiva",
		"advantage": "Detecta y recuerda presas. Mutaciones: llamado, cerco y marca biológica.",
		"challenge": "Pierde rastros sin visión; necesita aliados. Coordinación automática al poseerlo.",
		"art": preload("res://assets/rastreador/retrato.png")
	}
]

# Indices and metadata stay compatible with the existing map flow.
var indice_cian: int = 0
var indice_magenta: int = 0
var launching := false
var cards: Array[Dictionary] = []
var portraits: Array[Texture2D] = []
var continue_button: Button
var back_button: Button
var eyebrow: Label
var heading: Label
var subtitle: Label
var steps: Label
var footer: Label
var versus: Label
var entrance: Tween
var changes: Array[Tween] = []

func _ready() -> void:
	AudioManager.reproducir_menu()
	theme = Design.make_theme()
	_build_background()
	eyebrow = _label(self, "PATOGEN  /  DOS JUGADORES", 14, Color("78d9c3"), true)
	heading = _label(self, "ELEGÍ TU CEPA", 32, CREAM, true)
	subtitle = _label(self, "Elegí cómo se propaga tu brote. Cada jugador, su estrategia.", 22, MUTED)
	steps = _label(self, "01  CEPAS    /    02  MAPA", 14, MUTED, true)
	steps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for strain in STRAINS:
		# Use the front frame of gameplay sheets, then trim transparent canvas.
		var image: Image = strain.art.get_image()
		var source: Rect2i = strain.get("frame", Rect2i(Vector2i.ZERO, image.get_size()))
		var atlas := AtlasTexture.new()
		atlas.atlas = strain.art
		var bounds := image.get_region(source).get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, source.size))
		atlas.region = Rect2(Rect2i(source.position + bounds.position, bounds.size))
		portraits.append(atlas)
	_build_card(1, CYAN, "JUGADOR AZUL", "A / D")
	_build_card(2, MAGENTA, "JUGADOR MAGENTA", "← / →")
	versus = _label(self, "VS", 14, MUTED, true)
	versus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back_button = _button(self, "VOLVER AL MENÚ", Color("78d9c3"))
	back_button.pressed.connect(_back)
	continue_button = _button(self, "ELEGIR MAPA  →", Color("78d9c3"), true)
	continue_button.name = "Comenzar"
	continue_button.pressed.connect(_on_comenzar_pressed)
	footer = _label(self, "Elegí con A / D y ← / →, o hacé clic en una cepa.", 17, MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var chosen: Dictionary = get_tree().root.get_meta("patogen_cepas", {})
	var ids: Array[String] = []
	for strain in STRAINS: ids.append(strain.id)
	indice_cian = maxi(0, ids.find(chosen.get(1, "atletico")))
	indice_magenta = maxi(0, ids.find(chosen.get(2, "atletico")))
	actualizar_visualizacion()
	resized.connect(_layout)
	_layout()
	cards[0].tabs[indice_cian].grab_focus()
	if not _reduced_motion():
		for card in cards: card.root.modulate.a = 0.0
		entrance = create_tween().set_parallel(true)
		for card in cards: entrance.tween_property(card.root, "modulate:a", 1.0, 0.25)

func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color("09181e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var texture := TextureRect.new()
	texture.texture = preload("res://assets/Fondo seleccion.jpg")
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture.modulate = Color(0.58, 0.72, 0.74, 0.18)
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(texture)

func _build_card(team: int, accent: Color, player_name: String, keys: String) -> void:
	var panel := PanelContainer.new()
	panel.name = "Player%d" % team
	var style := Design.button_style(Color("10252e"), accent.darkened(0.52))
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var content := Control.new()
	panel.add_child(content)
	var stripe := ColorRect.new()
	stripe.color = accent
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(stripe)
	var player := _label(content, player_name, 16, accent, true)
	var controls := _label(content, keys, 18, MUTED)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var divider := ColorRect.new()
	divider.color = Color(accent, 0.18)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(divider)
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(stage)
	var halo := TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(accent, 0.13))
	gradient.set_color(1, Color(accent, 0.0))
	var glow := GradientTexture2D.new()
	glow.gradient = gradient
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(0.5, 0.0)
	glow.width = 256
	glow.height = 256
	halo.texture = glow
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(halo)
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(portrait)
	var previous := _button(stage, "‹", accent)
	previous.pressed.connect(_cycle.bind(team, -1))
	previous.tooltip_text = "Cepa anterior · " + ("A" if team == 1 else "Flecha izquierda")
	var next := _button(stage, "›", accent)
	next.pressed.connect(_cycle.bind(team, 1))
	next.tooltip_text = "Cepa siguiente · " + ("D" if team == 1 else "Flecha derecha")
	for arrow in [previous, next]:
		arrow.add_theme_font_override("font", Design.bold_font())
		for state in ["normal", "hover", "pressed"]:
			var box := arrow.get_theme_stylebox(state) as StyleBoxFlat
			box.set_content_margin_all(0)
	var title := _label(content, "", 24, CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var role := _label(content, "", 21, MUTED)
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	content.add_child(details)
	var advantage := _detail(details, "VENTAJA", accent)
	var challenge := _detail(details, "DESAFÍO", Color("a8bec2"))
	var tabs := GridContainer.new()
	tabs.columns = 3
	tabs.add_theme_constant_override("h_separation", 8)
	tabs.add_theme_constant_override("v_separation", 8)
	content.add_child(tabs)
	var choices: Array[Button] = []
	for i in STRAINS.size():
		var tab := _button(tabs, STRAINS[i].title, accent)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.toggle_mode = true
		tab.pressed.connect(_choose.bind(team, i))
		choices.append(tab)
	cards.append({"root": panel, "content": content, "stripe": stripe, "player": player,
		"controls": controls, "divider": divider, "stage": stage, "portrait": portrait,
		"previous": previous, "next": next, "title": title, "role": role, "details": details,
		"advantage": advantage, "challenge": challenge, "tabs_row": tabs, "tabs": choices})
	changes.append(null)

func _detail(parent: Node, caption: String, color: Color) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := _label(row, caption, 15, color)
	label.add_theme_font_override("font", Design.bold_font())
	label.name = "Caption"
	var copy := _label(row, "", 20, CREAM)
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return copy

func _label(parent: Node, value: String, font_size: int, color: Color, pixel: bool = false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if pixel: label.add_theme_font_override("font", PIXEL_FONT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, accent: Color, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", PIXEL_FONT)
	button.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := Color("152f38")
		var border := accent.darkened(0.5)
		if state == "hover":
			fill = Color("22424a")
			border = accent
		elif state == "pressed":
			fill = accent.darkened(0.65)
			border = accent
		if primary:
			fill = accent.lightened(0.15) if state == "hover" else accent
			if state == "pressed": fill = accent.darkened(0.2)
			border = fill
		var style := Design.button_style(fill, border)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		button.add_theme_stylebox_override(state, style)
	var focus := Design.button_style(Color.TRANSPARENT, Color("f2d296"))
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	if primary:
		for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(key, Color("102b30"))
	parent.add_child(button)
	return button

func _place(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(width, height)

func _layout() -> void:
	if cards.size() != 2: return
	var unit := clampf(size.y / 1080.0, 0.5, 1.2)
	var margin := maxf(24, 64 * unit)
	var gap := maxf(28, 72 * unit)
	var card_width := (size.x - 2 * margin - gap) / 2
	var top := 214 * unit
	var action_y := size.y - 108 * unit
	var action_height := maxf(42, 64 * unit)
	var card_height := action_y - 28 * unit - top
	_place(eyebrow, margin, 40 * unit, size.x - 2 * margin, 24 * unit)
	eyebrow.add_theme_font_size_override("font_size", maxi(10, int(14 * unit)))
	_place(heading, margin, 82 * unit, size.x - 2 * margin, 46 * unit)
	heading.add_theme_font_size_override("font_size", maxi(20, int(32 * unit)))
	_place(subtitle, margin, 146 * unit, size.x - 2 * margin, 34 * unit)
	subtitle.add_theme_font_size_override("font_size", maxi(14, int(22 * unit)))
	steps.visible = size.x >= 1280
	_place(steps, size.x - margin - 530 * unit, 92 * unit, 530 * unit, 28 * unit)
	steps.add_theme_font_size_override("font_size", maxi(10, int(14 * unit)))
	for i in cards.size():
		_layout_card(cards[i], Vector2(margin + i * (card_width + gap), top), Vector2(card_width, card_height), unit)
	_place(versus, margin + card_width, top + card_height * 0.43, gap, 40 * unit)
	versus.add_theme_font_size_override("font_size", maxi(10, int(14 * unit)))
	var back_width := maxf(220, 330 * unit)
	var next_width := maxf(240, 390 * unit)
	_place(back_button, margin, action_y, back_width, action_height)
	_place(continue_button, size.x - margin - next_width, action_y, next_width, action_height)
	for button in [back_button, continue_button]:
		button.add_theme_font_size_override("font_size", maxi(11, int(16 * unit)))
	footer.visible = size.x >= 1450
	_place(footer, margin + back_width + 16, action_y, size.x - 2 * margin - back_width - next_width - 32, action_height)
	footer.add_theme_font_size_override("font_size", maxi(13, int(17 * unit)))
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _layout_card(card: Dictionary, origin: Vector2, dimensions: Vector2, unit: float) -> void:
	_place(card.root, origin.x, origin.y, dimensions.x, dimensions.y)
	var pad := maxf(14, 28 * unit)
	var inner := dimensions.x - 2 * pad
	var tab_height := maxf(34, 46 * unit)
	var tab_gap := maxf(4, 8 * unit)
	var tabs_height := tab_height * 2 + tab_gap
	var tab_y := dimensions.y - pad - tabs_height
	# Two wrapped detail rows still need room on narrow 4:3 cards.
	var detail_height := maxf(92, 144 * unit)
	var detail_y := tab_y - detail_height
	var role_y := detail_y - maxf(26, 38 * unit)
	var title_y := role_y - maxf(28, 42 * unit)
	var stage_y := pad + 48 * unit
	var stage_height := title_y - stage_y - 12 * unit
	_place(card.stripe, 0, 0, dimensions.x, 4 * unit)
	_place(card.player, pad, pad, inner - 110 * unit, 28 * unit)
	_place(card.controls, dimensions.x - pad - 100 * unit, pad, 100 * unit, 28 * unit)
	card.player.add_theme_font_size_override("font_size", maxi(10, int(16 * unit)))
	card.controls.add_theme_font_size_override("font_size", maxi(13, int(18 * unit)))
	_place(card.divider, pad, pad + 36 * unit, inner, 1)
	_place(card.stage, pad, stage_y, inner, stage_height)
	var arrow_size := maxf(32, 50 * unit)
	_place(card.portrait, arrow_size + 12 * unit, 0, inner - 2 * arrow_size - 24 * unit, stage_height)
	_place(card.previous, 0, (stage_height - arrow_size) / 2, arrow_size, arrow_size)
	_place(card.next, inner - arrow_size, (stage_height - arrow_size) / 2, arrow_size, arrow_size)
	for arrow in [card.previous, card.next]: arrow.add_theme_font_size_override("font_size", maxi(26, int(38 * unit)))
	_place(card.title, pad, title_y, inner, maxf(22, 32 * unit))
	card.title.add_theme_font_size_override("font_size", maxi(14, int(24 * unit)))
	_place(card.role, pad, role_y, inner, maxf(20, 30 * unit))
	card.role.add_theme_font_size_override("font_size", maxi(13, int(21 * unit)))
	_place(card.details, pad, detail_y, inner, detail_height - 12 * unit)
	card.details.add_theme_constant_override("separation", maxi(4, int(8 * unit)))
	for copy in [card.advantage, card.challenge]:
		copy.add_theme_font_size_override("font_size", maxi(13, int(20 * unit)))
		var caption: Label = copy.get_parent().get_node("Caption")
		caption.custom_minimum_size.x = maxf(62, 92 * unit)
		caption.add_theme_font_size_override("font_size", maxi(11, int(15 * unit)))
	_place(card.tabs_row, pad, tab_y, inner, tabs_height)
	card.tabs_row.add_theme_constant_override("h_separation", int(tab_gap))
	card.tabs_row.add_theme_constant_override("v_separation", int(tab_gap))
	for tab in card.tabs:
		tab.add_theme_font_size_override("font_size", maxi(9, int(14 * unit)))
		tab.custom_minimum_size.y = tab_height

func _choose(team: int, index: int) -> void:
	if launching: return
	var previous := indice_cian if team == 1 else indice_magenta
	if team == 1: indice_cian = wrapi(index, 0, STRAINS.size())
	else: indice_magenta = wrapi(index, 0, STRAINS.size())
	actualizar_visualizacion()
	var current := indice_cian if team == 1 else indice_magenta
	if cards[team - 1].tabs.has(get_viewport().gui_get_focus_owner()):
		cards[team - 1].tabs[current].grab_focus()
	if previous != current:
		AudioManager.efecto("seleccion_cepa", -14.0)
		if is_instance_valid(changes[team - 1]): changes[team - 1].kill()
		var portrait: TextureRect = cards[team - 1].portrait
		portrait.modulate.a = 1.0
		if not _reduced_motion():
			portrait.modulate.a = 0.45
			changes[team - 1] = create_tween()
			changes[team - 1].tween_property(portrait, "modulate:a", 1.0, 0.16)

func _cycle(team: int, step: int) -> void:
	_choose(team, (indice_cian if team == 1 else indice_magenta) + step)

func actualizar_visualizacion() -> void:
	indice_cian = wrapi(indice_cian, 0, STRAINS.size())
	indice_magenta = wrapi(indice_magenta, 0, STRAINS.size())
	for i in cards.size():
		var index := indice_cian if i == 0 else indice_magenta
		var card := cards[i]
		card.portrait.texture = portraits[index]
		card.portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		card.title.text = STRAINS[index].title
		card.role.text = STRAINS[index].role
		card.advantage.text = STRAINS[index].advantage
		card.challenge.text = STRAINS[index].challenge
		for j in card.tabs.size(): card.tabs[j].set_pressed_no_signal(j == index)

func _save_choices() -> void:
	get_tree().root.set_meta("patogen_cepas", {
		1: STRAINS[indice_cian].id,
		2: STRAINS[indice_magenta].id
	})

func _on_comenzar_pressed() -> void:
	if launching: return
	_save_choices()
	_transition("res://scenes/map_select.tscn")

func _back() -> void:
	if launching: return
	_save_choices()
	_transition("res://scenes/main_menu.tscn")

func _transition(path: String) -> void:
	var onboarding := get_node_or_null("/root/PatogenOnboarding")
	# An incoming loading overlay may still be fading after this scene is ready.
	if onboarding and is_instance_valid(onboarding.loading_screen): return
	launching = true
	_set_buttons_disabled(true)
	AudioManager.efecto("click")
	if onboarding:
		onboarding.transition_to(path)
		if is_instance_valid(onboarding.loading_screen):
			onboarding.loading_screen.finished.connect(func(success: bool):
				if not success:
					launching = false
					_set_buttons_disabled(false)
					continue_button.grab_focus())
	else:
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			launching = false
			_set_buttons_disabled(false)

func _set_buttons_disabled(value: bool) -> void:
	continue_button.disabled = value
	back_button.disabled = value
	for card in cards:
		card.previous.disabled = value
		card.next.disabled = value
		for tab in card.tabs: tab.disabled = value

func _reduced_motion() -> bool:
	var service := get_node_or_null("/root/PatogenOnboarding")
	return service != null and bool(service.profile.data.reduced_motion)

func _input(event: InputEvent) -> void:
	# Handle the second player's arrows before GUI focus navigation consumes them.
	_unhandled_key_input(event)

func _unhandled_key_input(event: InputEvent) -> void:
	if launching or not event is InputEventKey or not event.pressed: return
	if event.keycode not in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_ESCAPE]: return
	get_viewport().set_input_as_handled()
	# Repeats must not fall through to Godot's default GUI arrow navigation.
	if event.echo: return
	match event.keycode:
		KEY_A: _cycle(1, -1)
		KEY_D: _cycle(1, 1)
		KEY_LEFT: _cycle(2, -1)
		KEY_RIGHT: _cycle(2, 1)
		KEY_ESCAPE:
			_back()
			return
	var team := 1 if event.keycode in [KEY_A, KEY_D] else 2
	cards[team - 1].tabs[indice_cian if team == 1 else indice_magenta].grab_focus()

# Existing entry points remain available to scene-flow callers.
func _on_button_pressed() -> void: _cycle(1, 1)
func _on_button_2_pressed() -> void: _cycle(1, -1)
func _on_button_3_pressed() -> void: _cycle(2, 1)
func _on_button_4_pressed() -> void: _cycle(2, -1)

extends Control
const Design = preload("res://patogen_onboarding/ui_theme.gd")
var service: Node
var art: TextureRect
var vignette: TextureRect
var backdrop: ColorRect
var column: VBoxContainer
var eyebrow: Label
var title: Label
var description: Label
var status: Label
var footer: Label
var art_caption: Label
var motion: CheckButton
var play: Button
var guide: Button
var tutorial: Button
var exit_button: Button
var buttons: Array[Button] = []
var entrance: Tween
var guide_overlay: Control
var intro_space: Control

func _ready() -> void:
	service = get_node_or_null("/root/PatogenOnboarding")
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("reproducir_menu"):
		audio.call("reproducir_menu")
	theme = Design.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop = ColorRect.new()
	backdrop.color = Color("09181e")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	art = TextureRect.new()
	var original: Texture2D = load("res://assets/Fondo menu.jpg")
	var crop := AtlasTexture.new()
	crop.atlas = original
	var dimensions := original.get_size()
	# In-engine framing of existing artwork; the baked-in old title stays outside view.
	crop.region = Rect2(dimensions * Vector2(0.08, 0.22), dimensions * Vector2(0.84, 0.69))
	art.texture = crop
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.modulate = Color(0.7, 0.8, 0.8)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	vignette = TextureRect.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color("09181e"))
	gradient.set_color(1, Color(0.035, 0.094, 0.118, 0.03))
	gradient.add_point(0.45, Color(0.035, 0.094, 0.118, 0.82))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.RIGHT
	texture.width = 256
	texture.height = 8
	vignette.texture = texture
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	eyebrow = _label("67GAMES   /   ESTRATEGIA Y CONTAGIO", 15, Color("78d9c3"))
	title = _label("PATOGEN", 76, Color("f3eee0"))
	title.add_theme_font_override("font", Design.bold_font())
	description = _label("Un pato. Todo un brote.\nEvolucioná tu cepa y dominá el shopping.", 23, Color("abbec2"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_space = Control.new()
	intro_space.custom_minimum_size.y = 16
	column.add_child(intro_space)
	play = _button("Jugar", true)
	tutorial = _button("Nueva partida con tutorial")
	guide = _button("Ver tutorial")
	play.pressed.connect(func(): _launch("auto"))
	tutorial.pressed.connect(func(): _launch("tutorial"))
	guide.pressed.connect(_show_guide)
	status = _label("", 17, Color("b4c6c7"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if service:
		if service.profile.is_new():
			status.text = "Primera visita: Jugar incluye una introducción breve que podés omitir."
		elif service.profile.data.last_result == "interrupted":
			status.text = "Tu guía quedó pendiente. Podés repetirla o jugar directamente."
		else:
			status.text = "¿Querés repasar? La guía también está disponible con F1 durante la partida."
	motion = CheckButton.new()
	motion.text = "Movimiento reducido"
	motion.add_theme_font_size_override("font_size", 18)
	motion.set_pressed_no_signal(bool(service.profile.data.reduced_motion) if service else false)
	motion.toggled.connect(func(value: bool):
		if service:
			service.profile.data.reduced_motion = value
			service.profile.save_profile())
	column.add_child(motion)
	exit_button = _button("Salir")
	exit_button.pressed.connect(_exit_game)
	footer = Label.new()
	footer.text = "2 JUGADORES LOCALES    ·    UNA SOLA PANTALLA"
	footer.add_theme_font_size_override("font_size", 14)
	footer.add_theme_color_override("font_color", Color("77999d"))
	add_child(footer)
	art_caption = Label.new()
	art_caption.text = "PACIENTE CERO\nEl brote empieza con vos."
	art_caption.add_theme_font_size_override("font_size", 22)
	art_caption.add_theme_color_override("font_color", Color("f3eee0"))
	art_caption.add_theme_constant_override("outline_size", 6)
	art_caption.add_theme_color_override("font_outline_color", Color("09181e"))
	add_child(art_caption)
	resized.connect(_layout)
	_layout()
	play.grab_focus()
	if not motion.button_pressed:
		column.modulate.a = 0
		entrance = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		entrance.tween_property(column, "modulate:a", 1.0, 0.4)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	column.add_child(label)
	return label

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = 64
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_font_override("font", Design.bold_font())
	button.add_theme_stylebox_override("normal", Design.button_style(Color("78d9c3") if primary else Color("10282f"), Color("78d9c3") if primary else Color("31525a")))
	button.add_theme_stylebox_override("hover", Design.button_style(Color("a1efdc") if primary else Color("1b3c43"), Color("94e9d4")))
	button.add_theme_stylebox_override("pressed", Design.button_style(Color("4fa993") if primary else Color("0b1c23"), Color("78d9c3")))
	var focus := Design.button_style(Color.TRANSPARENT, Color("f2d296"))
	focus.set_border_width_all(3)
	button.add_theme_stylebox_override("focus", focus)
	if primary:
		for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(key, Color("102b30"))
	column.add_child(button)
	buttons.append(button)
	return button

func _layout() -> void:
	if not is_instance_valid(column):
		return
	var unit := clampf(size.y / 1080.0, 0.5, 1.2)
	var left := maxf(30, 76 * unit)
	var width := clampf(size.x * 0.31, 340, 610)
	column.position = Vector2(left, 100 * unit)
	column.size.x = width
	column.add_theme_constant_override("separation", int(18 * unit))
	title.add_theme_font_size_override("font_size", int(76 * unit))
	eyebrow.add_theme_font_size_override("font_size", maxi(12, int(15 * unit)))
	description.add_theme_font_size_override("font_size", maxi(16, int(23 * unit)))
	status.add_theme_font_size_override("font_size", maxi(14, int(17 * unit)))
	motion.add_theme_font_size_override("font_size", maxi(14, int(18 * unit)))
	description.visible = size.y >= 760
	intro_space.visible = size.y >= 760
	for button in buttons:
		button.custom_minimum_size.y = maxf(40, 64 * unit)
		button.add_theme_font_size_override("font_size", maxi(17, int(23 * unit)))
		for style_name in ["normal", "hover", "pressed"]:
			var style := button.get_theme_stylebox(style_name) as StyleBoxFlat
			style.content_margin_top = maxf(6, 12 * unit)
			style.content_margin_bottom = maxf(6, 12 * unit)
	art.position = Vector2(size.x * 0.36, 0)
	art.size = Vector2(size.x * 0.64, size.y)
	vignette.position = Vector2(size.x * 0.33, 0)
	vignette.size = Vector2(size.x * 0.48, size.y)
	footer.position = Vector2(left, size.y - 48 * unit)
	footer.add_theme_font_size_override("font_size", maxi(11, int(14 * unit)))
	art_caption.position = Vector2(size.x * 0.72, size.y - 106 * unit)
	art_caption.add_theme_font_size_override("font_size", maxi(14, int(22 * unit)))
	art_caption.visible = size.x >= 1100

func _launch(mode: String) -> void:
	_click()
	if service:
		service.open_character_selection(mode)
	else:
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _show_guide() -> void:
	if is_instance_valid(guide_overlay):
		return
	_click()
	guide_overlay = Control.new()
	guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(guide_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.06, 0.08, 0.94)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(640, size.x - 60)
	panel.add_theme_stylebox_override("panel", Design.button_style(Color("10282f"), Color("78d9c3")))
	center.add_child(panel)
	var items := VBoxContainer.new()
	items.add_theme_constant_override("separation", 16)
	panel.add_child(items)
	var label := Label.new()
	label.text = "Cómo jugar a PATOGEN"
	label.add_theme_font_override("font", Design.bold_font())
	label.add_theme_font_size_override("font_size", 28)
	items.add_child(label)
	var text := Label.new()
	text.text = "1. El pato inicia el brote y se convierte en fantasma.\n2. Los contagios suman ADN para evolucionar tu cepa.\n3. Al terminar el tiempo, gana quien tenga más infectados.\n\nCIAN: WASD · mutaciones E · posesión X\nMAGENTA: flechas · mutaciones O · posesión J\n\nConsultá cada mutación con el cursor antes de comprar."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 19)
	items.add_child(text)
	var practice := Button.new()
	practice.text = "Practicar con el tutorial interactivo"
	practice.custom_minimum_size.y = 48
	practice.pressed.connect(func(): _launch("tutorial"))
	items.add_child(practice)
	var back := Button.new()
	back.text = "Volver al menú · Esc"
	back.custom_minimum_size.y = 44
	back.pressed.connect(_close_guide)
	items.add_child(back)
	practice.grab_focus()

func _close_guide() -> void:
	_click()
	if is_instance_valid(guide_overlay):
		guide_overlay.queue_free()
		guide_overlay = null
	guide.grab_focus()

func _click() -> void:
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("efecto"):
		audio.call("efecto", "click")

func _exit_game() -> void:
	exit_button.disabled = true
	var audio := get_node_or_null("/root/AudioManager")
	if audio and audio.has_method("detener_musica"):
		audio.call("detener_musica")
		await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(guide_overlay) and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_guide()
		get_viewport().set_input_as_handled()

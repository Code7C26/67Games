extends CanvasLayer
const UI_THEME = preload("res://resources/gameplay_theme.tres")
signal next_requested
signal skip_requested
signal help_requested
signal motion_changed(enabled: bool)
var root: Control
var blocker: Control
var fade: ColorRect
var top_bar: ColorRect
var bottom_bar: ColorRect
var panel: PanelContainer
var kicker: Label
var heading: Label
var body: Label
var hint: Label
var action: Button
var skip: Button
var help: Button
var motion: CheckButton
var progress: ProgressBar
var ring: ReferenceRect
var pointer: Label
var target: Node
var ui_tween: Tween
var fade_tween: Tween
var reduced_motion := false
var active := false
var cinematic := false
var pulse_time := 0.0
var world_focus := Vector2.ZERO
var font: Font
var protected_controls: Array[Control] = []

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme = UI_THEME
	font = UI_THEME.default_font
	blocker = Control.new()
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(blocker)
	fade = ColorRect.new()
	fade.color = Color("091318")
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	top_bar = _bar()
	bottom_bar = _bar()
	ring = ReferenceRect.new()
	ring.editor_only = false
	ring.border_color = Color("7af0dc")
	ring.border_width = 3
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ring)
	pointer = Label.new()
	pointer.text = "▼"
	pointer.add_theme_color_override("font_color", Color("7af0dc"))
	pointer.add_theme_font_size_override("font_size", 28)
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pointer)
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f29")
	style.border_color = Color("74e6cf")
	style.set_border_width_all(2)
	style.border_width_top = 4
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	kicker = _label(column, 12, Color("7be5ce"))
	heading = _label(column, 20, Color("f6edda"))
	if font:
		heading.add_theme_font_override("font", font)
		kicker.add_theme_font_override("font", font)
	body = _label(column, 14, Color("e1e9ec"))
	hint = _label(column, 12, Color("afc1ca"))
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 4
	progress.show_percentage = false
	progress.max_value = 8
	column.add_child(progress)
	action = _button("Continuar", column)
	action.pressed.connect(func(): next_requested.emit())
	skip = _button("Omitir · Esc", root)
	skip.pressed.connect(func(): skip_requested.emit())
	help = _button("Ver tutorial · F1", root)
	help.custom_minimum_size.y = 22
	help.add_theme_font_size_override("font_size", 10)
	help.pressed.connect(func(): help_requested.emit())
	motion = CheckButton.new()
	motion.text = "Movimiento reducido"
	motion.add_theme_font_size_override("font_size", 12)
	root.add_child(motion)
	motion.toggled.connect(func(value: bool):
		reduced_motion = value
		motion_changed.emit(value))
	root.resized.connect(_layout)
	set_idle()
	_layout()

func _bar() -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color("091318")
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bar)
	return bar

func _label(parent: Node, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(text: String, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.add_theme_font_size_override("font_size", 12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("213d49")
	style.border_color = Color("5b8f9b")
	style.set_border_width_all(2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("315c65")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	parent.add_child(button)
	return button

func start(is_cinematic: bool) -> void:
	active = true
	cinematic = is_cinematic
	help.hide()
	skip.show()
	motion.show()
	blocker.visible = cinematic
	top_bar.visible = cinematic
	bottom_bar.visible = cinematic
	fade.visible = cinematic
	fade.modulate.a = 1 if cinematic else 0
	if fade_tween:
		fade_tween.kill()
	if cinematic:
		fade_tween = create_tween()
		fade_tween.tween_property(fade, "modulate:a", 0.0, 0.7 if not reduced_motion else 0.15)
	_layout()

func show_card(tag: String, title: String, description: String, instruction: String = "", button_text: String = "", step: int = 0) -> void:
	if ui_tween:
		ui_tween.kill()
	kicker.text = tag
	heading.text = title
	body.text = description
	hint.text = instruction
	hint.visible = not instruction.is_empty()
	action.text = button_text
	action.visible = not button_text.is_empty()
	progress.value = step
	progress.visible = step > 0
	panel.show()
	panel.modulate.a = 0
	panel.reset_size()
	_layout()
	ui_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ui_tween.tween_property(panel, "modulate:a", 1.0, 0.2 if not reduced_motion else 0.05)
	if action.visible:
		action.grab_focus()

func hide_card() -> void:
	if ui_tween:
		ui_tween.kill()
	ui_tween = create_tween()
	ui_tween.tween_property(panel, "modulate:a", 0.0, 0.15 if not reduced_motion else 0.05)
	ui_tween.tween_callback(panel.hide)

func highlight(node: Node) -> void:
	target = node
	_update_target()

func handoff() -> void:
	cinematic = false
	blocker.hide()
	top_bar.hide()
	bottom_bar.hide()
	fade.hide()
	_layout()

func set_idle() -> void:
	active = false
	cinematic = false
	if ui_tween:
		ui_tween.kill()
	if fade_tween:
		fade_tween.kill()
	for item in [blocker, fade, top_bar, bottom_bar, panel, skip, motion, ring, pointer]:
		item.hide()
	target = null
	help.show()
	_layout()

func _layout() -> void:
	if not is_instance_valid(panel):
		return
	var size := root.size
	var margin := 22.0
	var width := minf(560, size.x - margin * 2)
	panel.size.x = width
	var height := panel.get_combined_minimum_size().y
	# Wrapped text can become shorter after a card or viewport change.
	panel.size.y = height
	# Bottom middle leaves the original left/right mutation panels accessible.
	var x := (size.x - width) / 2
	var y := size.y - height - 70
	for control in protected_controls:
		if not is_instance_valid(control) or not control.is_visible_in_tree() or cinematic:
			continue
		var bounds: Rect2 = control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
		if Rect2(Vector2(x, y), Vector2(width, height)).intersects(bounds.grow(14)):
			if size.x - bounds.end.x - margin * 2 >= width:
				x = bounds.end.x + margin
			elif bounds.position.x - margin * 2 >= width:
				x = bounds.position.x - width - margin
	if is_instance_valid(target) and target is Node2D:
		var screen: Vector2 = target.get_global_transform_with_canvas().origin
		if Rect2(Vector2(x, y), Vector2(width, height)).grow(30).has_point(screen):
			y = 100
	panel.position = Vector2(x, maxf(y, 80))
	var buttons_y := margin if cinematic else size.y - 50
	skip.position = Vector2(maxf(margin, size.x - 210), buttons_y)
	skip.size = Vector2(188, 42)
	motion.position = Vector2(margin, buttons_y)
	motion.size = Vector2(300, 42)
	var help_scale := minf(1.0, minf(size.x / 1920.0, size.y / 1080.0))
	help.scale = Vector2.ONE * help_scale
	help.position = Vector2(size.x - 224 * help_scale, size.y - 25 * help_scale)
	help.size = Vector2(210, 22)
	top_bar.size = Vector2(size.x, 72)
	bottom_bar.position = Vector2(0, size.y - 46)
	bottom_bar.size = Vector2(size.x, 46)

func _process(delta: float) -> void:
	pulse_time += delta
	if active:
		_update_target()
		_layout()

func _update_target() -> void:
	if not is_instance_valid(target):
		ring.hide()
		pointer.hide()
		return
	var bounds: Rect2
	if target is Control:
		if not target.is_visible_in_tree():
			ring.hide()
			pointer.hide()
			return
		var transform: Transform2D = target.get_global_transform_with_canvas()
		bounds = transform * Rect2(Vector2.ZERO, target.size)
	elif target is Node2D:
		bounds = Rect2(target.get_global_transform_with_canvas().origin - Vector2(28, 32), Vector2(56, 64))
	else:
		return
	if not Rect2(Vector2.ZERO, root.size).intersects(bounds):
		ring.hide()
		pointer.hide()
		return
	ring.show()
	pointer.show()
	ring.position = bounds.position - Vector2(6, 6)
	ring.size = bounds.size + Vector2(12, 12)
	ring.modulate.a = 1 if reduced_motion else 0.75 + 0.25 * sin(pulse_time * 4)
	pointer.position = Vector2(clampf(bounds.get_center().x - 10, 8, root.size.x - 28), maxf(72, bounds.position.y - 36))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if active and event.keycode == KEY_ESCAPE:
			skip_requested.emit()
			get_viewport().set_input_as_handled()
		elif not active and event.keycode == KEY_F1:
			help_requested.emit()
			get_viewport().set_input_as_handled()
		elif cinematic:
			get_viewport().set_input_as_handled()

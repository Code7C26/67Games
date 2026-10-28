extends CanvasLayer
## A reserved top bar and bottom docks share their bounds with the gameplay camera.
## Everything between those bands is mouse-transparent. No floating tooltips.
const CYAN := Color("58d8d8")
const MAGENTA := Color("e489ce")
const INK := Color("151e2b")
const PAPER := Color("edf0df")
const MUTED := Color("a5b6bc")
const MAP_RECT := Rect2(0, 80, 2128, 960)
const FONT = preload("res://Fuentes/press-start-2p.ttf")
const UI_THEME = preload("res://resources/gameplay_theme.tres")
const DNA = preload("res://assets/ui/hud_adn.png")
const ICONS = preload("res://assets/ui/mutaciones.png")
const ICON_NAMES := ["fiebre", "rabia", "parasito", "colonia", "mente_colmena", "caparazon", "regeneracion", "infeccion_inmortal", "contagio_cadena", "ultimo_aliento", "explosion_infecciosa", "esporas", "nube_toxica", "epidemia_ambiental", "sobrecarga", "pulso_viral", "tormenta_infecciosa", "adaptacion", "evolucion_rapida", "supercepa", "division_celular", "replicacion", "brote_masivo"]
var mutation_icons: Dictionary = {}
var world: Node
var panels: Array[Panel] = []
var headings: Array[Label] = []
var adn_labels: Array[Label] = []
var infected_labels: Array[Label] = []
var descriptions: Array[Label] = []
var description_scrolls: Array[ScrollContainer] = []
var dna_sprites: Array[AnimatedSprite2D] = []
var ability_buttons: Array = []
var ducks: Array = [null, null]
var toggles: Array[Button] = []
var top_boxes: Array[Panel] = []
var clock_box: Panel
var clock_label: Label
var phase_label: Label
var time_bar: ProgressBar
var footer: Label
var signature: Array = []
var last_adn: Array = [-1, -1]
var last_second := -1
var tick := 0.0
var ui_scale := 1.0
var map_screen_rect := Rect2()
var world_rect := MAP_RECT
var layout_updates := 0
var mutation_updates := 0
var _feedback_tweens: Dictionary = {}
var _selected_branches := [-1, -1]

func _ready() -> void:
	for i in range(ICON_NAMES.size()):
		var icon := AtlasTexture.new()
		icon.atlas = ICONS
		icon.region = Rect2(i * 24, 0, 24, 24)
		mutation_icons[ICON_NAMES[i]] = icon
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"gain")
	frames.set_animation_loop(&"gain", false)
	frames.set_animation_speed(&"gain", 12.5)
	for i in range(8):
		var atlas := AtlasTexture.new()
		atlas.atlas = DNA
		atlas.region = Rect2(i * 24, 0, 24, 24)
		frames.add_frame(&"gain", atlas)
	for team in range(2):
		_build_team(team, frames)
	clock_box = _panel("Clock", Color("829ca6"))
	phase_label = _label(clock_box, "FASE DE INFECCIÓN", 12, MUTED)
	clock_label = _label(clock_box, "02:00", 22, PAPER)
	time_bar = ProgressBar.new()
	time_bar.show_percentage = false
	time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_bar.add_theme_stylebox_override("background", _style(Color("263644"), Color("263644"), 0))
	time_bar.add_theme_stylebox_override("fill", _style(Color("c5cba2"), Color("c5cba2"), 0))
	clock_box.add_child(time_bar)
	footer = _label(self, "WASD · CIAN     |     FLECHAS · MAGENTA", 12, MUTED)
	get_viewport().size_changed.connect(_layout)
	_layout()

func setup(host: Node) -> void:
	world = host
	# The older editable maps also use Mapa.gd. Preserve their world extents.
	if host.has_node("01_Pisos_y_Pasillos"):
		world_rect = Rect2(0, 0, 3200, 2300)
	# Shopping also has "Paredes", but it is a TileMapLayer, not the old arena.
	elif host.get_node_or_null("Paredes") is StaticBody2D:
		world_rect = Rect2(-32, -200, 1220, 1040)
	world_rect = host.get_meta("view_bounds", world_rect)
	world.get_node("HUD/LabelContador").hide()
	for duck in get_tree().get_nodes_in_group("patos"):
		if host.is_ancestor_of(duck):
			ducks[duck.player_id - 1] = duck
	_layout()
	_refresh_mutations()
	sync(host.contar_infecciones())

func _style(bg: Color, border: Color, thickness: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(thickness)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style

func _panel(node_name: String, accent: Color) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.theme = UI_THEME
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(INK, accent.darkened(0.4)))
	add_child(panel)
	return panel

func _label(parent: Node, value: String, font_size: int, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_font_override("font", FONT)
	parent.add_child(label)
	return label

func _button(parent: Node, node_name: String, accent: Color, purchase: bool = false) -> Button:
	var button := Button.new()
	button.name = node_name
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_disabled_color", Color("84959e"))
	button.add_theme_stylebox_override("normal", _style(Color("253343"), Color("536875")))
	button.add_theme_stylebox_override("hover", _style(Color("344958"), accent))
	button.add_theme_stylebox_override("pressed", _style(accent.darkened(0.65), accent))
	button.add_theme_stylebox_override("disabled", _style(Color("1c2935"), Color("354653")))
	button.add_theme_stylebox_override("focus", _style(Color(0,0,0,0), Color("eee4b9")))
	# Enabled purchases use the team colour; the existing disabled state covers
	# insufficient ADN, cooldowns, completed branches and the preparation phase.
	if purchase:
		button.add_theme_color_override("font_color", accent.lerp(Color.WHITE, 0.65))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _style(accent.darkened(0.65), accent))
		button.add_theme_stylebox_override("hover", _style(accent.darkened(0.48), accent.lightened(0.2)))
		button.add_theme_stylebox_override("pressed", _style(accent.darkened(0.72), accent))
	parent.add_child(button)
	return button

func _build_team(team: int, frames: SpriteFrames) -> void:
	var accent := CYAN if team == 0 else MAGENTA
	var suffix := "Cian" if team == 0 else "Magenta"
	var top := _panel("Status" + suffix, accent)
	top_boxes.append(top)
	var team_label := _label(top, "P%d %s" % [team + 1, suffix.to_upper()], 16, accent)
	team_label.position = Vector2(16, 17)
	var score := _label(top, "0", 22, PAPER)
	_place(score, Rect2(178, 2, 108, 34))
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	infected_labels.append(score)
	var score_caption := _label(top, "INFECTADOS", 10, accent)
	_place(score_caption, Rect2(178, 35, 108, 17))
	score_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var adn := _label(self, "0 ADN", 20, PAPER)
	adn.name = "LabelADN_" + suffix
	adn.z_index = 1 # Draw above the dock background while preserving its node path.
	adn_labels.append(adn)
	var dna := AnimatedSprite2D.new()
	dna.z_index = 1
	dna.sprite_frames = frames
	dna.animation = &"gain"
	dna.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	dna.scale = Vector2(1.5, 1.5)
	dna.modulate = accent
	add_child(dna)
	dna_sprites.append(dna)
	var toggle := _button(top, "Toggle", accent)
	toggle.text = "E MUTACIONES" if team == 0 else "O MUTACIONES"
	toggle.add_theme_font_size_override("font_size", 10)
	toggle.pressed.connect(func(): panels[team].visible = not panels[team].visible)
	toggles.append(toggle)
	var panel := _panel("Panel" + suffix, accent)
	panels.append(panel)
	# Keep the ADN labels at their controller-compatible paths, while making
	# their visibility follow the mutation dock they now belong to visually.
	panel.visibility_changed.connect(func():
		adn.visible = panel.visible
		dna.visible = panel.visible)
	var title := _label(panel, "MUTACIONES / " + suffix.to_upper(), 12, accent)
	title.position = Vector2(12, 13)
	headings.append(title)
	# Retain the three button paths used by the tutorial adapter.
	var row := HBoxContainer.new()
	row.name = "VBoxContainer"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	for branch in range(3):
		var button := _button(row, ["BtnFiebre", "BtnCadena", "BtnInfeccion"][branch], accent, true)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.expand_icon = true
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_constant_override("icon_max_width", 32)
		button.mouse_entered.connect(show_branch.bind(team + 1, branch))
		button.focus_entered.connect(show_branch.bind(team + 1, branch))
		button.pressed.connect(func(): _flash(button, accent))
	var abilities := HBoxContainer.new()
	abilities.name = "Abilities"
	abilities.mouse_filter = Control.MOUSE_FILTER_IGNORE
	abilities.add_theme_constant_override("separation", 8)
	panel.add_child(abilities)
	var buttons: Array[Button] = []
	for ability in range(4):
		var button := _button(abilities, "Ability%d" % ability, accent, true)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.pressed.connect(_ability.bind(team, ability))
		buttons.append(button)
	ability_buttons.append(buttons)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(scroll)
	description_scrolls.append(scroll)
	var description := _label(scroll, "Apuntá a un icono o usá Shift + su tecla para consultar. Rueda: leer más.", 12, MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	descriptions.append(description)

func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position.round()
	control.size = rect.size.round()

func _layout() -> void:
	layout_updates += 1
	var viewport := get_viewport().get_visible_rect().size
	ui_scale = minf(1.0, minf(viewport.x / 1920.0, viewport.y / 1080.0))
	transform = Transform2D.IDENTITY.scaled(Vector2.ONE * ui_scale)
	var size := viewport / ui_scale
	var half := (size.x - 36) * 0.5
	for team in range(2):
		var x := 12.0 if team == 0 else size.x - half - 12
		var dock_y := size.y - 210
		_place(panels[team], Rect2(x, dock_y, half, 182))
		_place(panels[team].get_node("VBoxContainer"), Rect2(12, 45, half - 24, 44))
		_place(panels[team].get_node("Abilities"), Rect2(12, 93, half - 24, 44))
		_place(description_scrolls[team], Rect2(12, 142, half - 24, 34))
		_place(adn_labels[team], Rect2(x + half - 192, dock_y + 7, 180, 34))
		dna_sprites[team].position = Vector2(x + half - 222, dock_y + 24)
		var top_x := 12.0 if team == 0 else size.x - 522
		_place(top_boxes[team], Rect2(top_x, 6, 510, 54))
		_place(toggles[team], Rect2(350, 8, 146, 38))
	_place(clock_box, Rect2(size.x * 0.5 - 200, 6, 400, 54))
	_place(phase_label, Rect2(16, 7, 240, 22))
	_place(clock_label, Rect2(270, 4, 126, 42))
	_place(time_bar, Rect2(16, 35, 230, 6))
	_place(footer, Rect2(16, size.y - 24, 650, 22))
	var available := Rect2(Vector2(12, 68) * ui_scale, Vector2(size.x - 24, size.y - 290) * ui_scale)
	if is_instance_valid(world):
		var camera := world.get_node("Camera2D") as Camera2D
		var zoom := minf(available.size.x / world_rect.size.x, available.size.y / world_rect.size.y)
		camera.zoom = Vector2.ONE * zoom
		# Camera centres the world in the free rectangle, not the whole screen.
		camera.position = world_rect.get_center() + (viewport * 0.5 - available.get_center()) / zoom
		camera.position_smoothing_enabled = false
		camera.force_update_scroll()
		map_screen_rect = Rect2(available.get_center() - world_rect.size * zoom * 0.5, world_rect.size * zoom)

func sync(stats: Dictionary) -> void:
	if not is_instance_valid(world):
		return
	var next_signature := [world.adn_cian, world.adn_magenta, world.estado_actual, world.mutaciones_p1.size(), world.mutaciones_p2.size(), world.cepa_cian, world.cepa_magenta]
	if next_signature != signature:
		signature = next_signature
		_refresh_mutations()
	for team in range(2):
		var count: int = world.adn_cian if team == 0 else world.adn_magenta
		if count != last_adn[team]:
			adn_labels[team].text = "%d ADN" % count
			if last_adn[team] >= 0:
				dna_sprites[team].stop()
				dna_sprites[team].play(&"gain")
				_flash(adn_labels[team], CYAN if team == 0 else MAGENTA)
			last_adn[team] = count
		var infected: int = stats.blue if team == 0 else stats.magenta
		var value := str(infected)
		if infected_labels[team].text != value:
			infected_labels[team].text = value
	var timer: Timer = world.timer_inicio if world.estado_actual == 0 else world.timer_juego
	var second := maxi(0, ceili(timer.time_left))
	if second != last_second:
		last_second = second
		clock_label.text = "%02d:%02d" % [floori(second / 60.0), second % 60]
		time_bar.value = 100.0 * timer.time_left / timer.wait_time
		clock_label.modulate = Color("f1ba83") if second <= 10 and world.estado_actual == 1 else Color.WHITE
	var phase := "BUSCÁ TU HUÉSPED" if world.estado_actual == 0 else "TIEMPO RESTANTE"
	if world._transicion_iniciada and world.estado_actual == 0:
		phase = "TRANSFORMACIÓN"
	if phase_label.text != phase:
		phase_label.text = phase

func _process(delta: float) -> void:
	if not is_instance_valid(world):
		return
	tick += delta
	if tick < 0.1:
		return
	tick = 0.0
	for team in range(2):
		if not panels[team].visible or not is_instance_valid(ducks[team]):
			continue
		var duck = ducks[team]
		var cooldowns := [duck.cooldown_robot, duck.cooldown_zona_frio, duck.cooldown_zona_calor, duck.cooldown_posesion]
		var costs := [world.COSTO_ROBOT, world.COSTO_ZONA_TEMPERATURA, world.COSTO_ZONA_TEMPERATURA, 0]
		var keys := ["Z", "C", "V", "X"] if team == 0 else ["H", "K", "L", "J"]
		var names := ["Robot", "Distorsión", "Calor", "Poseer"]
		var money: int = world.adn_cian if team == 0 else world.adn_magenta
		for ability in range(4):
			var button: Button = ability_buttons[team][ability]
			var seconds := ceili(float(cooldowns[ability]))
			var value := "%s %s\n%s" % [keys[ability], names[ability], ("%ds" % seconds) if seconds > 0 else ("%d ADN" % costs[ability] if costs[ability] > 0 else "Gratis")]
			if button.text != value:
				button.text = value
			button.disabled = not duck.modo_fantasma or world.estado_actual != 1 or money < int(costs[ability]) or seconds > 0 or (ability == 3 and is_instance_valid(duck.bot_poseido))

func _refresh_mutations() -> void:
	if not is_instance_valid(world):
		return
	mutation_updates += 1
	world.actualizar_menu_mutaciones()
	for team in range(2):
		headings[team].text = "P%d / %s  ·  MUTACIONES" % [team + 1, world._nombre_cepa(world.obtener_cepa_jugador(team + 1))]
		var row := panels[team].get_node("VBoxContainer")
		for branch in range(3):
			var button := row.get_child(branch) as Button
			var key: String = ["1", "2", "3"][branch] if team == 0 else ["8", "9", "0"][branch]
			button.text = key + " · " + button.text
			var branches: Array = world.obtener_ramas_jugador(team + 1)
			button.icon = null
			if branch < branches.size():
				var mutations: Array[String] = world.mutaciones_p1 if team == 0 else world.mutaciones_p2
				var next: String = world.obtener_siguiente_evolucion(branches[branch][0], mutations)
				if next.is_empty():
					next = branches[branch].back()
				button.icon = mutation_icons.get(next)
			_fit_mutation_font(button)
		if _selected_branches[team] >= 0:
			show_branch(team + 1, _selected_branches[team])

func _fit_mutation_font(button: Button) -> void:
	# Leave room for the icon and padding, including the longest evolutions.
	var available := (panels[0].size.x - 40.0) / 3.0 - 60.0
	var font_size := 12
	for line in button.text.split("\n"):
		while font_size > 10 and FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available:
			font_size -= 1
	button.add_theme_font_size_override("font_size", font_size)

func show_branch(player: int, branch: int) -> void:
	if not is_instance_valid(world):
		return
	var team := player - 1
	_selected_branches[team] = branch
	panels[team].show()
	var branches: Array = world.obtener_ramas_jugador(player)
	if branch >= branches.size():
		descriptions[team].text = "Esta cepa tiene dos ramas disponibles."
		return
	var mutations: Array[String] = world.mutaciones_p1 if team == 0 else world.mutaciones_p2
	var next: String = world.obtener_siguiente_evolucion(branches[branch][0], mutations)
	if next.is_empty():
		descriptions[team].text = "Rama completa. Todas sus evoluciones están activas."
	else:
		descriptions[team].text = str(world._descripcion_mutacion(next)).split("\n", true, 1)[1]
	description_scrolls[team].scroll_vertical = 0

func _ability(team: int, ability: int) -> void:
	if not is_instance_valid(ducks[team]):
		return
	var duck = ducks[team]
	match ability:
		0: duck.invocar_robot()
		1: duck.colocar_zona_temperatura("frio")
		2: duck.colocar_zona_temperatura("calor")
		3: duck.intentar_poseer_infectado()
	tick = 1.0

func _flash(item: CanvasItem, accent: Color) -> void:
	if _feedback_tweens.has(item) and _feedback_tweens[item].is_valid():
		_feedback_tweens[item].kill()
	item.modulate = accent.lerp(Color.WHITE, 0.65)
	var tween := create_tween()
	tween.tween_property(item, "modulate", Color.WHITE, 0.3)
	_feedback_tweens[item] = tween

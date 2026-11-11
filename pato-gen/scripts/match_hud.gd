extends CanvasLayer
## A reserved top bar and bottom docks share their bounds with the gameplay camera.
## Everything between those bands is mouse-transparent. No floating tooltips.
const BLUE := Color("6e9fff")
const MAGENTA := Color("ef84d1")
const INK := Color("111c2c")
const PAPER := Color("f4f5e9")
const MUTED := Color("c0ccd5")
const HEALING := Color("b6ef75")
const MAP_RECT := Rect2(0, 80, 2128, 960)
const FONT = preload("res://Fuentes/press-start-2p.ttf")
const UI_THEME = preload("res://resources/gameplay_theme.tres")
const DNA = preload("res://assets/ui/hud_adn.png")
const ICONS = preload("res://assets/ui/mutaciones.png")
const RECICLAJE_ICONS = preload("res://assets/ui/mutaciones_reciclaje.png")
const RECICLAJE_ICON_NAMES := ["reciclaje", "biomasa", "renacimiento"]
const GARFIO_ICON_NAMES := ["tendon_reforzado", "ligamentos_elasticos", "alcance_predador", "arrastre_brutal", "anclaje_tenaz", "traccion_brutal", "gancho_virulento", "inoculo_dirigido", "garra_patogena"]
const CAMALEON_ICON_NAMES := ["pigmentacion_avanzada", "mimetismo", "cromatoforos", "desvanecimiento", "retorno_sigiloso", "adaptacion_fugaz", "ataque_sorpresa", "emboscada_viral", "golpe_furtivo"]
const RASTREADOR_ICON_NAMES := ["olfato_reforzado", "olfato_agudo", "olfato_superior", "fijacion_presa", "memoria_persistente", "rastro_tenaz", "instinto_manada", "rastro_compartido", "caza_coordinada"]
const ICON_NAMES := ["fiebre", "rabia", "parasito", "colonia", "mente_colmena", "caparazon", "regeneracion", "infeccion_inmortal", "contagio_cadena", "ultimo_aliento", "explosion_infecciosa", "esporas", "nube_toxica", "epidemia_ambiental", "sobrecarga", "pulso_viral", "tormenta_infecciosa", "adaptacion", "evolucion_rapida", "supercepa", "division_celular", "replicacion", "brote_masivo"]
var mutation_icons: Dictionary = {}
var world: Node
var panels: Array[Panel] = []
var headings: Array[Label] = []
var adn_labels: Array[Label] = []
var infected_labels: Array[Label] = []
var biomass_labels: Array[Label] = []
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
var event_box: Panel
var event_label: Label
var event_caption: Label
var population_box: Panel
var healthy_label: Label
var population_caption: Label
var _event_key := ""
var _last_coloso_cures := 0
var _coloso_departure_time := 0.0
var _coloso_was_active := false
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

func _garfio_icon(family: int, level: int) -> Texture2D:
	# Three pixel symbols share Garfio's materials; bars mark evolution level.
	var glyphs := [
		["......KKK.......", ".....KLLMK......", "....KLLMMSK.....", "...KLLMSK.......", "..KLLMSK........", ".KLLMSK.........", ".KLMSK..........", ".KMSK....KK.....", "..KSK...KCICK...", "..KSK...KIKIK...", "..KSK...KIK.K...", "..KCK..KCICK....", "..KICCKCICK.....", "...KICCICK......", "....KCCCK.......", ".....KKK........"],
		["......KKKK......", ".....KICICK.....", "....KICKCIK.....", "....KIK.KIK.....", "..KKKIK.KIK.....", ".KLLCIK.KIK.....", "KLLCCIK.KIK.....", "KLMCCIKKCICK....", "KLMMCCIICICK....", ".KMMMCCCCCK.....", "..KMMMMMCK......", "...KKMMMK.......", "..KK.KMSK.......", ".KLLKKMSK.......", "..KLLLMSK.......", "...KKKKK........"],
		["........KKK.....", "......KKCICK....", ".....KCICKCIK...", ".....KCIK.KIK...", ".....KIK..KIK...", ".....KIK..KIK...", "..KK.KIK..KIK...", ".KVVKKIK.KCIK...", "KVVVVKICKCICK...", "KVIVVKICICCK....", ".KVVVKCCCCK.....", "..KVVKKKKK......", "...KK...........", "..........KK....", ".........KVVK...", "..........KK...."]
	]
	var palette := {"K": Color("24343e"), "S": Color("456965"), "M": Color("638881"), "L": Color("89a099"), "C": Color("c6bc99"), "I": Color("ded9cd"), "V": Color("9e6c7b")}
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var glyph: Array = glyphs[clampi(family, 0, 2)]
	for y in range(glyph.size()):
		var row: String = glyph[y]
		for x in range(row.length()):
			var symbol := row.substr(x, 1)
			if palette.has(symbol):
				image.set_pixel(x + 4, y + 2, palette[symbol])
	for step in range(clampi(level, 1, 3)):
		image.fill_rect(Rect2i(7 + step * 4, 21, 3, 2), Color("a9d5c4"))
	return ImageTexture.create_from_image(image)


func _camaleon_icon(family: int, level: int) -> Texture2D:
	# Scales, fading plates and an ambush strike share the approved body's palette.
	var glyphs := [
		[".....KKKKKK.....", "...KKLLLMMMK....", "..KLLLPPMMMSK...", ".KLLPPPPMSSSK...", ".KLPPQQMMSSSK...", "KLLPPQMMSSSSSK..", "KLLLMMMSSPPSSK..", "KMLLMMSSPPQSSK..", "KMMLMSSSPQQSSK..", ".KMMLSSSSSSSK...", ".KMMMLSSSSSK....", "..KMMMLSSSK.....", "...KKMMMKK......", ".....KKK........", "................", "................"],
		["...KKKKKKKK.....", "...KLLLLLLK.....", "....KLLMMK......", ".....KMMK.......", "......KK........", ".....KSSK.......", "....KSMMSK......", "...KSMMMMSK.....", "...KKKKKKKK.....", "................", "....KQQQQK......", ".....KQQK.......", "......KK........", "................", ".....K..K.......", "................"],
		[".....KK.........", "....KLLK........", "...KLLLLK.......", "...KLLMMK...KK..", "....KMMK...KQK..", "....KMMK..KQQK..", "...KMMMK.KQK.K..", "..KMMMMMKQK.....", ".KMMMLLLKK......", ".KMMKLLK........", "..KK.KK.........", ".........K......", "......K.KQK.K...", ".......KQQQK....", "......K.KQK.K...", ".........K......"]
	]
	var palette := {"K": Color("2e2938"), "S": Color("526354"), "M": Color("76846a"), "L": Color("9fa78a"), "P": Color("56525f"), "Q": Color("a1b2b0")}
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var glyph: Array = glyphs[clampi(family, 0, 2)]
	for y in glyph.size():
		var row: String = glyph[y]
		for x in row.length():
			var symbol := row.substr(x, 1)
			if palette.has(symbol): image.set_pixel(x + 4, y + 2, palette[symbol])
	for step in range(clampi(level, 1, 3)):
		image.fill_rect(Rect2i(7 + step * 4, 21, 3, 2), Color("b0bfba"))
	return ImageTexture.create_from_image(image)


func _rastreador_icon(family: int, level: int) -> Texture2D:
	var glyphs := [
		["..P...P..", "...PPP...", "PPPPKPPPP", "...PPP...", "..P.P.P.."],
		["..KKKKK..", ".KLLLLLK.", "KLLLKLLLK", "KLLLKLLLK", "KLLLKKLLK", ".KLLLLLK.", "..KKKKK.."],
		["..KK.KK..", ".KLLKLLK.", "..KK.KK..", ".KLLKLLK.", "....K....", "...KLK...", "....K....", "...KLK..."]
	]
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var palette := {"K": Color("2e2938"), "P": Color("b87572"), "L": Color("9fa7a0")}
	var glyph: Array = glyphs[clampi(family, 0, 2)]
	for y in glyph.size():
		var row: String = glyph[y]
		for x in row.length():
			var symbol := row.substr(x, 1)
			if palette.has(symbol): image.set_pixel(x + 7, y + 5, palette[symbol])
	for step in clampi(level, 1, 3): image.fill_rect(Rect2i(7 + step * 4, 21, 3, 2), Color("d9a28a"))
	return ImageTexture.create_from_image(image)


func _ready() -> void:
	for i in range(ICON_NAMES.size()):
		var icon := AtlasTexture.new()
		icon.atlas = ICONS
		icon.region = Rect2(i * 24, 0, 24, 24)
		mutation_icons[ICON_NAMES[i]] = icon
	for i in range(RECICLAJE_ICON_NAMES.size()):
		var icon := AtlasTexture.new()
		icon.atlas = RECICLAJE_ICONS
		icon.region = Rect2(i * 24, 0, 24, 24)
		mutation_icons[RECICLAJE_ICON_NAMES[i]] = icon
	for i in range(GARFIO_ICON_NAMES.size()):
		# Reutiliza los símbolos de presa, tendón y gancho para las nuevas ramas.
		mutation_icons[GARFIO_ICON_NAMES[i]] = _garfio_icon([2, 1, 0][int(i / 3.0)], i % 3 + 1)
	for i in range(CAMALEON_ICON_NAMES.size()):
		mutation_icons[CAMALEON_ICON_NAMES[i]] = _camaleon_icon(int(i / 3.0), i % 3 + 1)
	for i in range(RASTREADOR_ICON_NAMES.size()):
		# Manada, aproximación y duración conservan el lenguaje visual existente.
		mutation_icons[RASTREADOR_ICON_NAMES[i]] = _rastreador_icon([2, 0, 1][int(i / 3.0)], i % 3 + 1)
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
	phase_label = _label(clock_box, "FASE DE INFECCIÓN", 13, MUTED)
	clock_label = _label(clock_box, "02:30", 24, PAPER)
	time_bar = ProgressBar.new()
	time_bar.show_percentage = false
	time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_bar.add_theme_stylebox_override("background", _style(Color("263644"), Color("263644"), 0))
	time_bar.add_theme_stylebox_override("fill", _style(Color("c5cba2"), Color("c5cba2"), 0))
	clock_box.add_child(time_bar)
	event_box = _panel("MatchEvent", MUTED)
	event_label = _label(event_box, "PREPARACIÓN", 13, PAPER)
	event_caption = _label(event_box, "Elegí tu huésped", 10, MUTED)
	population_box = _panel("Population", HEALING)
	healthy_label = _label(population_box, "0 SANOS", 16, HEALING)
	population_caption = _label(population_box, "HUMANOS SIN INFECTAR", 10, MUTED)
	for label in [event_label, event_caption, healthy_label, population_caption]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer = _label(self, "WASD · AZUL     |     FLECHAS · MAGENTA", 13, MUTED)
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
	button.add_theme_font_size_override("font_size", 13)
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
	var accent := BLUE if team == 0 else MAGENTA
	# These internal paths are used by Mapa.gd and the tutorial adapter.
	var suffix := "Cian" if team == 0 else "Magenta"
	var top := _panel("Status" + suffix, accent)
	top_boxes.append(top)
	var team_label := _label(top, "P%d %s" % [team + 1, "AZUL" if team == 0 else "MAGENTA"], 18, accent)
	team_label.position = Vector2(14, 17)
	var biomass := _label(top, "", 10, MUTED)
	_place(biomass, Rect2(14, 37, 174, 15))
	biomass.hide()
	biomass_labels.append(biomass)
	var score := _label(top, "0", 26, PAPER)
	_place(score, Rect2(196, 0, 132, 36))
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	infected_labels.append(score)
	var score_caption := _label(top, "INFECTADOS", 12, accent)
	_place(score_caption, Rect2(196, 35, 132, 17))
	score_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var adn := _label(self, "0 ADN", 22, PAPER)
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
	toggle.add_theme_font_size_override("font_size", 11)
	toggle.pressed.connect(func(): panels[team].visible = not panels[team].visible)
	toggles.append(toggle)
	var panel := _panel("Panel" + suffix, accent)
	panels.append(panel)
	# Keep the ADN labels at their controller-compatible paths, while making
	# their visibility follow the mutation dock they now belong to visually.
	panel.visibility_changed.connect(func():
		adn.visible = panel.visible
		dna.visible = panel.visible)
	var title := _label(panel, "MUTACIONES / " + ("AZUL" if team == 0 else "MAGENTA"), 14, accent)
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
		if ability == 3:
			button.tooltip_text = "Poseé al aliado infectado más cercano. Sin aliados, contagiá al sano más cercano; si no hay sanos, robá el rival más cercano."
		button.pressed.connect(_ability.bind(team, ability))
		buttons.append(button)
	ability_buttons.append(buttons)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(scroll)
	description_scrolls.append(scroll)
	var description := _label(scroll, "Apuntá a una mutación para conocer su efecto. Shift + tecla: consultar.", 13, MUTED)
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
		var dock_y := size.y - 196
		_place(panels[team], Rect2(x, dock_y, half, 168))
		_place(panels[team].get_node("VBoxContainer"), Rect2(12, 40, half - 24, 42))
		_place(panels[team].get_node("Abilities"), Rect2(12, 86, half - 24, 42))
		_place(description_scrolls[team], Rect2(12, 133, half - 24, 30))
		_place(adn_labels[team], Rect2(x + half - 198, dock_y + 5, 186, 34))
		dna_sprites[team].position = Vector2(x + half - 226, dock_y + 22)
		var top_x := 12.0 if team == 0 else size.x - 522
		_place(top_boxes[team], Rect2(top_x, 6, 510, 54))
		_place(toggles[team], Rect2(338, 8, 158, 38))
	_place(clock_box, Rect2(size.x * 0.5 - 200, 6, 400, 54))
	_place(phase_label, Rect2(14, 7, 246, 22))
	_place(clock_label, Rect2(270, 4, 126, 42))
	_place(time_bar, Rect2(16, 35, 230, 6))
	_place(event_box, Rect2(size.x * 0.5 - 428, 6, 216, 54))
	_place(event_label, Rect2(6, 7, 204, 22))
	_place(event_caption, Rect2(6, 33, 204, 16))
	_place(population_box, Rect2(size.x * 0.5 + 212, 6, 216, 54))
	_place(healthy_label, Rect2(6, 7, 204, 23))
	_place(population_caption, Rect2(6, 34, 204, 16))
	_place(footer, Rect2(16, size.y - 24, size.x - 256, 22))
	var available := Rect2(Vector2(12, 66) * ui_scale, Vector2(size.x - 24, size.y - 270) * ui_scale)
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
				_flash(adn_labels[team], BLUE if team == 0 else MAGENTA)
			last_adn[team] = count
		var infected: int = stats.blue if team == 0 else stats.magenta
		var value := str(infected)
		if infected_labels[team].text != value:
			infected_labels[team].text = value
		var biomass_target: int = world.obtener_meta_biomasa(team + 1)
		biomass_labels[team].visible = biomass_target > 0
		if biomass_target > 0:
			var biomass: int = world.biomasa_reciclaje[team]
			var replicas: int = world.replicas_cian if team == 0 else world.replicas_magenta
			biomass_labels[team].text = "BIOMASA %d/%d" % [biomass, biomass_target]
			if replicas >= world.MAX_REPLICAS_POR_JUGADOR:
				biomass_labels[team].text = "CUPO COMPLETO"
			elif biomass >= biomass_target:
				biomass_labels[team].text = "RÉPLICA LISTA"
			biomass_labels[team].modulate = HEALING if biomass >= biomass_target else Color.WHITE
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
	_sync_match_context(stats)

func _sync_match_context(stats: Dictionary) -> void:
	healthy_label.text = "%d SANOS" % int(stats.get("sanos", 0))
	var title := "BROTE EN CURSO"
	var caption := "Contagiá y mutá"
	var accent := MUTED
	var key := "normal"
	var evento = world.get_node_or_null("EventoColosoAntiviral")
	var coloso_active: bool = is_instance_valid(evento) and evento.estado == evento.Estado.ACTIVO
	if _coloso_was_active and not coloso_active:
		_last_coloso_cures = evento.curaciones_ultima_aparicion if is_instance_valid(evento) else _last_coloso_cures
		_coloso_departure_time = 4.0
	_coloso_was_active = coloso_active
	if world.estado_actual == 0:
		title = "PREPARACIÓN"
		caption = "Elegí tu huésped"
		key = "preparation"
	elif is_instance_valid(evento) and evento.estado == evento.Estado.AVISO:
		title = "COLOSO EN %ds" % ceili(evento.aviso_restante)
		caption = "Se acerca un sanador"
		accent = HEALING
		key = "warning"
	elif coloso_active:
		if is_instance_valid(evento.coloso):
			_last_coloso_cures = evento.coloso.curaciones
		title = "COLOSO ACTIVO"
		caption = "%d curados · %ds" % [_last_coloso_cures, ceili(evento.activo_restante)]
		accent = HEALING
		key = "healing"
	elif _coloso_departure_time > 0.0:
		title = "COLOSO RETIRADO"
		caption = "%d humanos curados" % _last_coloso_cures
		accent = HEALING
		key = "departure"
	else:
		var alfa = world.get_node_or_null("EventoParasitoAlfa")
		if is_instance_valid(alfa) and alfa.estado == alfa.Estado.ACTIVO:
			title = "ALFA ACTIVO"
			caption = "VERDE: NEUTRAL · %ds" % ceili(maxf(0.0, alfa.duracion - alfa.tiempo_activo))
			accent = Color("c5ef8b")
			key = "alfa"
	event_label.text = title
	event_caption.text = caption
	if key != _event_key:
		_event_key = key
		event_label.add_theme_color_override("font_color", accent)
		event_box.add_theme_stylebox_override("panel", _style(INK, accent.darkened(0.25)))
		if key in ["warning", "healing", "departure", "alfa"]:
			_flash(event_box, accent)
	var hints: Array[String] = []
	for team in range(2):
		var hint := "AZUL: WASD" if team == 0 else "MAGENTA: FLECHAS"
		if world.estado_actual == 0:
			hint += " · BUSCÁ UN HUMANO"
		elif is_instance_valid(ducks[team]):
			var key_poseer := "X" if team == 0 else "J"
			if is_instance_valid(ducks[team].bot_poseido):
				hint += " · POSESIÓN %ds" % ceili(ducks[team].tiempo_posesion)
				if is_instance_valid(_garfio_poseido(ducks[team])):
					hint += " · %s ENGANCHAR" % key_poseer
				elif is_instance_valid(_camaleon_poseido(ducks[team])):
					hint += " · %s CAMUFLAR" % key_poseer
				elif ducks[team].bot_poseido.cepa == "rastreador":
					hint += " · RASTREO PASIVO"
			else:
				hint += " · %s POSEER" % key_poseer
		hints.append(hint)
	footer.text = "   |   ".join(hints) + ("   ·   E / O: MUTACIONES" if world.estado_actual == 1 else "")

func _process(delta: float) -> void:
	_coloso_departure_time = maxf(0.0, _coloso_departure_time - delta)
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
		var captura: Node2D = _garfio_poseido(duck)
		var sigilo: Node2D = _camaleon_poseido(duck)
		for ability in range(4):
			var button: Button = ability_buttons[team][ability]
			if ability == 3 and is_instance_valid(sigilo):
				var remaining: float = maxf(0.0, sigilo.recarga_restante)
				var reason: String = sigilo.motivo_bloqueo()
				var status := "Camuflado" if sigilo.camuflado else (("CD %.1fs" % remaining) if remaining > 0.0 else ("Listo" if reason.is_empty() else reason))
				button.text = "%s Camuflar\n%s" % [keys[3], status]
				button.tooltip_text = "Pulsá %s o este botón para recuperar el camuflaje cuando esté listo y lejos de humanos sanos. Contagiar, acercarse demasiado o usar zonas y robot revela al huésped." % keys[3]
				button.disabled = not duck.modo_fantasma or not world.simbionte_en_juego() or sigilo.camuflado or not sigilo.puede_camuflarse()
				continue
			if ability == 3 and is_instance_valid(captura):
				var remaining: float = maxf(0.0, captura.recarga_restante)
				var busy: bool = captura.bloquea_movimiento()
				var incubating: bool = float(captura.anfitrion.incubacion_contagio) > 0.0
				var status := ("CD %.1fs" % remaining) if remaining > 0.0 else ("En curso" if busy else ("Incubando" if incubating else "Listo"))
				button.text = "%s Enganchar\n%s" % [keys[3], status]
				button.tooltip_text = "Apuntá con el movimiento y pulsá %s o este botón para lanzar el gancho. Con Doble tendón, el mismo ataque puede capturar hasta dos presas. No dispara automáticamente mientras lo poseés." % keys[3]
				button.disabled = not duck.modo_fantasma or not world.simbionte_en_juego() or remaining > 0.0 or busy or incubating
				continue
			var seconds := ceili(float(cooldowns[ability]))
			var value := "%s %s\n%s" % [keys[ability], names[ability], ("%ds" % seconds) if seconds > 0 else ("%d ADN" % costs[ability] if costs[ability] > 0 else "Gratis")]
			if button.text != value:
				button.text = value
			if ability == 3:
				button.tooltip_text = "Poseé al aliado infectado más cercano. Sin aliados, contagiá al sano más cercano; si no hay sanos, robá el rival más cercano."
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
	var font_size := 14
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
		descriptions[team].text = "Esta rama no está disponible."
		return
	var mutations: Array[String] = world.mutaciones_p1 if team == 0 else world.mutaciones_p2
	var next: String = world.obtener_siguiente_evolucion(branches[branch][0], mutations)
	if next.is_empty():
		descriptions[team].text = "Rama completa. Todas sus evoluciones están activas."
	else:
		descriptions[team].text = str(world._descripcion_mutacion(next)).split("\n", true, 1)[1]
	description_scrolls[team].scroll_vertical = 0

func _garfio_poseido(duck: Node) -> Node2D:
	if not is_instance_valid(duck) or not is_instance_valid(duck.bot_poseido):
		return null
	var bot: Node2D = duck.bot_poseido
	if bot.is_queued_for_deletion() or not bot.is_infected or bot.cepa != "garfio" or bot.player_duenio != duck.player_id:
		return null
	if not bot.controlado_por_jugador or bot.jugador_controlador != duck.player_id or not is_instance_valid(bot.garfio):
		return null
	return bot.garfio


func _camaleon_poseido(duck: Node) -> Node2D:
	if not is_instance_valid(duck) or not is_instance_valid(duck.bot_poseido):
		return null
	var bot: Node2D = duck.bot_poseido
	if bot.is_queued_for_deletion() or not bot.is_infected or bot.cepa != "camaleon" or bot.player_duenio != duck.player_id:
		return null
	if not bot.controlado_por_jugador or bot.jugador_controlador != duck.player_id or not is_instance_valid(bot.camaleon):
		return null
	return bot.camaleon


func _ability(team: int, ability: int) -> void:
	if not is_instance_valid(ducks[team]):
		return
	var duck = ducks[team]
	match ability:
		0: duck.invocar_robot()
		1: duck.colocar_zona_temperatura("frio")
		2: duck.colocar_zona_temperatura("calor")
		3:
			if is_instance_valid(_garfio_poseido(duck)):
				duck.activar_garfio_poseido()
			elif is_instance_valid(_camaleon_poseido(duck)):
				duck.activar_camaleon_poseido()
			else:
				duck.intentar_poseer_infectado()
	tick = 1.0

func _flash(item: CanvasItem, accent: Color) -> void:
	if _feedback_tweens.has(item) and _feedback_tweens[item].is_valid():
		_feedback_tweens[item].kill()
	item.modulate = accent.lerp(Color.WHITE, 0.65)
	var tween := create_tween()
	tween.tween_property(item, "modulate", Color.WHITE, 0.3)
	_feedback_tweens[item] = tween

extends Control
const MAPS := [
	{"id":"shopping", "title":"SHOPPING", "scene":"Shopping", "detail":"Locales, cine y pasajes entre extremos."},
	{"id":"lab", "title":"LABORATORIO AV-07", "scene":"Laboratorio", "detail":"Siete salas conectadas por el pasillo central."},
	{"id":"splash", "title":"PATO SPLASH", "scene":"PatoSplash", "detail":"Piscinas, paseos y el gran chapuzón."}
]
const FONT = preload("res://Fuentes/press-start-2p.ttf")
var selected := 0
var buttons: Array[Button] = []
var launching := false

func _ready() -> void:
	AudioManager.reproducir_menu()
	var background := ColorRect.new()
	background.color = Color("101b29")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","top","right","bottom"]: margin.add_theme_constant_override("margin_"+side,64)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",32)
	margin.add_child(column)
	_label(column,"ELEGÍ EL MAPA",32,Color("edf0df"))
	_label(column,"Las cepas elegidas se mantienen · Dos jugadores · 65 huéspedes",16,Color("a5b6bc"))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation",24)
	column.add_child(row)
	var remembered: String = get_tree().root.get_meta("patogen_map","shopping")
	for i in MAPS.size():
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_constant_override("separation",24)
		row.add_child(card)
		var preview := TextureRect.new()
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var path: String = "res://assets/ui/maps/"+MAPS[i].id+".png"
		if ResourceLoader.exists(path):
			var atlas:=AtlasTexture.new()
			atlas.atlas=load(path)
			atlas.region=Rect2(0,68,1920,790)
			preview.texture=atlas
		card.add_child(preview)
		var button := _button(card,MAPS[i].title)
		button.toggle_mode = true
		button.pressed.connect(_select.bind(i))
		buttons.append(button)
		_label(card,MAPS[i].detail,14,Color("a5b6bc"))
		if MAPS[i].id == remembered: selected=i
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",24)
	column.add_child(actions)
	_button(actions,"VOLVER A CEPAS").pressed.connect(_back)
	_button(actions,"COMENZAR PARTIDA").pressed.connect(_launch)
	_select(selected)
	buttons[selected].grab_focus()

func _label(parent: Node, value: String, size_: int, color: Color) -> void:
	var label := Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",size_)
	label.add_theme_color_override("font_color",color)
	if size_==14: label.custom_minimum_size.y=48
	parent.add_child(label)

func _button(parent: Node, value: String) -> Button:
	var button := Button.new()
	button.text=value
	button.custom_minimum_size.y=72
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font",FONT)
	button.add_theme_font_size_override("font_size",18)
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color=Color("29414d") if state=="pressed" else Color("1c2c3b")
		style.border_color=Color("58d8d8") if state!="normal" else Color("536875")
		style.set_border_width_all(2)
		button.add_theme_stylebox_override(state,style)
	parent.add_child(button)
	return button

func _select(index: int) -> void:
	selected=index
	for i in buttons.size(): buttons[i].set_pressed_no_signal(i==selected)
	get_tree().root.set_meta("patogen_map",MAPS[selected].id)

func _launch() -> void:
	if launching: return
	launching=true
	AudioManager.efecto("click")
	var path: String="res://scenes/"+MAPS[selected].scene+".tscn"
	var onboarding := get_node_or_null("/root/PatogenOnboarding")
	if onboarding:
		onboarding.transition_to(path)
		if is_instance_valid(onboarding.loading_screen):
			onboarding.loading_screen.finished.connect(func(success: bool):
				if not success: launching=false)
	else: get_tree().change_scene_to_file(path)

func _back() -> void:
	if not launching: get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): _back()

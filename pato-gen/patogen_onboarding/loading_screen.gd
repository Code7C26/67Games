extends CanvasLayer
signal finished(success: bool)
const Design = preload("res://patogen_onboarding/ui_theme.gd")
var path := ""
var canvas: Control
var progress: ProgressBar
var message: Label
var cancel_button: Button
var elapsed := 0.0
var busy := false
var committing := false
var fade: Tween

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.theme = Design.make_theme()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(canvas)
	var background := ColorRect.new()
	background.color = Color("09181e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 540
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title := Label.new()
	title.text = "PATOGEN"
	title.add_theme_font_override("font", Design.bold_font())
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("f3eee0"))
	column.add_child(title)
	message = Label.new()
	message.text = "Preparando el shopping…"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message)
	progress = ProgressBar.new()
	progress.show_percentage = true
	progress.custom_minimum_size.y = 18
	progress.add_theme_stylebox_override("background", Design.button_style(Color("10282f"), Color("31525a")))
	progress.add_theme_stylebox_override("fill", Design.button_style(Color("78d9c3"), Color("78d9c3")))
	column.add_child(progress)
	var tip := Label.new()
	tip.text = "Cada contagio suma ADN. Cada mutación abre una posibilidad."
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 18)
	tip.add_theme_color_override("font_color", Color("9ab4b7"))
	column.add_child(tip)
	cancel_button = Button.new()
	cancel_button.text = "Volver"
	cancel_button.custom_minimum_size.y = 44
	cancel_button.pressed.connect(cancel)
	column.add_child(cancel_button)
	canvas.resized.connect(func(): column.custom_minimum_size.x = minf(540, canvas.size.x - 60))

func load_scene(scene_path: String) -> void:
	if busy:
		return
	path = scene_path
	var names := {"Shopping":"el shopping", "Laboratorio":"el laboratorio AV-07", "PatoSplash":"Pato Splash", "map_select":"la selección de mapas", "character_select":"la selección de cepas"}
	message.text = "Preparando %s…" % names.get(path.get_file().get_basename(),"la partida")
	if not ResourceLoader.exists(path):
		_fail("No se encontró esta escena. Podés volver al menú e intentarlo de nuevo.")
		return
	var error := ResourceLoader.load_threaded_request(path, "PackedScene")
	if error != OK:
		_fail("No se pudo comenzar la carga. Volvé al menú para reintentar.")
		return
	busy = true
	elapsed = 0

func _process(delta: float) -> void:
	if not busy or committing:
		return
	elapsed += delta
	var value: Array = []
	var state := ResourceLoader.load_threaded_get_status(path, value)
	if not value.is_empty():
		progress.value = float(value[0]) * 100
	if state == ResourceLoader.THREAD_LOAD_LOADED and elapsed >= 0.25:
		var scene := ResourceLoader.load_threaded_get(path) as PackedScene
		if not scene:
			_fail("La escena no está disponible. Volvé al menú para continuar.")
			return
		committing = true
		cancel_button.disabled = true
		var error := get_tree().change_scene_to_packed(scene)
		if error != OK:
			_fail("No se pudo abrir la escena. Volvé al menú para continuar.")
			return
		progress.value = 100
		await get_tree().scene_changed
		var host := get_tree().current_scene
		if host != null and host.has_signal("map_ready") and not host.map_is_ready:
			await host.map_ready
		fade = create_tween()
		fade.tween_interval(0.1)
		fade.tween_property(canvas, "modulate:a", 0.0, 0.25)
		fade.tween_callback(func():
			finished.emit(true)
			queue_free())
	elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or elapsed >= 20:
		_fail("La carga no terminó. Podés volver al menú e intentarlo de nuevo.")

func _fail(text: String) -> void:
	busy = false
	committing = false
	message.text = text
	cancel_button.disabled = false
	cancel_button.grab_focus()

func cancel() -> void:
	if committing:
		return
	busy = false
	finished.emit(false)
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel()
		get_viewport().set_input_as_handled()

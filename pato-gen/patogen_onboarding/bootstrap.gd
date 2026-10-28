extends Node
## Register once as PatogenOnboarding. Only prepare_scene() is required in Mapa.
const Profile = preload("res://patogen_onboarding/profile.gd")
const Adapter = preload("res://patogen_onboarding/adapters/patogen_67games.gd")
const Director = preload("res://patogen_onboarding/director.gd")
const Loading = preload("res://patogen_onboarding/loading_screen.gd")
var profile := Profile.new()
var requested_mode := "auto"
var active_director: Node
var prepared: Dictionary = {}
var loading_screen: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Isolated test profiles never touch a player's preference file.
	for argument in OS.get_cmdline_user_args():
		if argument == "--onboarding-test":
			DirAccess.make_dir_recursive_absolute("res://tests/run_data")
			profile.path = "res://tests/run_data/session.cfg"
		if argument.begins_with("--onboarding-profile="):
			profile.path = "user://" + argument.trim_prefix("--onboarding-profile=").get_file()
	profile.load_profile()
	get_tree().node_added.connect(_node_added)

func prepare_scene(host: Node) -> void:
	if prepared.has(host.get_instance_id()):
		return
	var mode := requested_mode
	requested_mode = "auto"
	if mode == "auto":
		mode = "intro" if profile.is_new() else "direct"
	prepared[host.get_instance_id()] = mode
	if mode != "direct":
		get_tree().root.set_meta("patogen_intro_managed", true)
	if host.is_node_ready():
		_attach.call_deferred(host, mode)
	else:
		host.ready.connect(func(): _attach.call_deferred(host, mode), CONNECT_ONE_SHOT)
	host.tree_exiting.connect(func():
		if is_instance_valid(active_director) and host.is_ancestor_of(active_director):
			active_director.interrupt()
		prepared.erase(host.get_instance_id())
		get_tree().root.remove_meta("patogen_intro_managed"), CONNECT_ONE_SHOT)

func _attach(host: Node, mode: String) -> void:
	if not is_instance_valid(host) or not host.is_inside_tree():
		return
	var adapter := Adapter.new()
	adapter.name = "PatogenTutorialAdapter"
	host.add_child(adapter)
	adapter.setup(host)
	var director := Director.new()
	director.name = "PatogenIntroduction"
	host.add_child(director)
	director.configure(adapter, profile)
	active_director = director
	director.finished.connect(func(_result: String): get_tree().root.remove_meta("patogen_intro_managed"))
	if mode != "direct":
		director.start("tutorial" if mode == "tutorial" else "auto")

func request_tutorial() -> void:
	open_character_selection("tutorial")

func open_character_selection(mode: String = "auto") -> void:
	if is_instance_valid(loading_screen):
		return
	requested_mode = mode
	transition_to("res://scenes/character_select.tscn")

func transition_to(path: String) -> void:
	if is_instance_valid(loading_screen):
		return
	loading_screen = Loading.new()
	add_child(loading_screen)
	loading_screen.finished.connect(func(success: bool):
		if not success:
			requested_mode = "auto"
		loading_screen = null)
	loading_screen.load_scene(path)

func _node_added(node: Node) -> void:
	if node is Control and node.has_method("_on_jugar_pressed"):
		_decorate_menu.call_deferred(node)

func _decorate_menu(menu: Control) -> void:
	if not is_instance_valid(menu) or menu.has_meta("patogen_guide_menu"):
		return
	var column := menu.get_node_or_null("MarginContainer/VBoxContainer") as VBoxContainer
	if not column:
		return
	menu.set_meta("patogen_guide_menu", true)
	var play := column.get_node_or_null("Jugar") as Button
	if not play:
		return
	play.text = "JUGAR"
	var tutorial := Button.new()
	tutorial.text = "NUEVA PARTIDA CON TUTORIAL"
	tutorial.name = "NuevaPartidaTutorial"
	tutorial.theme = play.theme
	tutorial.add_theme_font_size_override("font_size", 20)
	tutorial.add_theme_font_override("font", play.get_theme_font("font"))
	for item in ["normal", "hover", "pressed", "focus"]:
		tutorial.add_theme_stylebox_override(item, play.get_theme_stylebox(item))
	column.add_child(tutorial)
	column.move_child(tutorial, 1)
	tutorial.pressed.connect(request_tutorial)
	var options := column.get_node_or_null("Opciones") as Button
	if options:
		# This snapshot's Options callback is empty. In a newer menu, add a separate button.
		options.text = "VER TUTORIAL"
		options.pressed.connect(request_tutorial)
	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_override("font", play.get_theme_font("font"))
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color("bce7dd"))
	note.text = "Primera visita: Jugar incluye una introducción que podés omitir." if profile.is_new() else "Podés volver a la guía cuando quieras. Durante la partida: F1."
	if profile.data.last_result == "interrupted":
		note.text = "Tu guía quedó pendiente. Podés repetirla o jugar directamente."
	column.add_child(note)
	var container := column.get_parent() as MarginContainer
	container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	container.offset_left = -275
	container.offset_right = 275
	container.offset_top = -70
	container.offset_bottom = 280

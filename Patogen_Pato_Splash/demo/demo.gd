extends Node2D
const VISITOR=preload("res://demo/visitor.gd")
const ROUTES=preload("res://demo/routes.gd")
var map: Node2D
var routes: RefCounted
var world: Node2D
var camera: Camera2D
var hud: CanvasLayer
var event_label: Label
var subtitle: Label
var progress: ProgressBar
var gallery: Control
var ambient: AudioStreamPlayer
var shake_enabled := true
var shake_left := 0.0
var total_time := 0.0
var selected_last := 0
var font: Font
var ui_font: Font
var header_panel: ColorRect
var explorers: Array[Node2D]=[]
var park_life: Node2D
var infection_preview := false

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	font=load("res://splash/assets/press_start_2p.tres")
	ui_font=font
	world=Node2D.new();world.name="World";world.process_mode=Node.PROCESS_MODE_PAUSABLE;add_child(world)
	map=load("res://splash/scenes/PatoSplash.tscn").instantiate();world.add_child(map)
	park_life=map.get_node_or_null("10_VidaParque")
	routes=ROUTES.new();routes.setup(map,19.0,park_life.reservations if park_life else [])
	if park_life:park_life.configure_navigation(routes.path)
	map.attraction_requested.connect(_attract)
	map.attraction_finished.connect(_release)
	map.splash_impact.connect(_impact)
	map.phase_changed.connect(_phase)
	var parent: Node=map.get_node("04_Objetos")
	for i in 54:
		var actor=CharacterBody2D.new();actor.set_script(VISITOR);actor.name="Visitante%02d"%i;actor.routes=routes;actor.serial=i
		actor.role="banador" if i<36 else ("salvavidas" if i<45 else "staff")
		var idx: int=(i*67+53)%routes.free_cells.size()
		actor.position=routes.grid.get_point_position(routes.free_cells[idx]);parent.add_child(actor)
	for i in 2:
		var explorer:=CharacterBody2D.new();explorer.set_script(preload("res://demo/explorer.gd"));explorer.player=i+1;explorer.position=map.get_node("06_Marcadores/InicioPato_"+("A" if i==0 else "B")).position;parent.add_child(explorer);explorers.append(explorer)
		explorer.add_to_group("park_watch_targets")
	camera=Camera2D.new();camera.position=Vector2(960,540);camera.position_smoothing_enabled=false;world.add_child(camera);camera.make_current()
	_make_ui()
	ambient=AudioStreamPlayer.new();ambient.stream=preload("res://splash/assets/agua_ambiente.wav");ambient.volume_db=-9;ambient.finished.connect(ambient.play);world.add_child(ambient);ambient.play()
	_phase("calma",30)

func _panel(parent: Node,r: Rect2,c: Color) -> ColorRect:
	var p:=ColorRect.new();p.position=r.position;p.size=r.size;p.color=c;p.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(p);return p
func _text(parent: Node,s: String,pos: Vector2,size_: int,c: Color,pixel: bool=false) -> Label:
	var crisp_size:=8 if size_<16 else (16 if size_<24 else (24 if size_<32 else 32))
	var l:=Label.new();l.text=s;l.position=pos;l.add_theme_font_override("font",font if pixel else ui_font);l.add_theme_font_size_override("font_size",crisp_size);l.add_theme_color_override("font_color",c);l.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(l);return l
func _button(parent: Node,text_: String,r: Rect2,callback: Callable) -> Button:
	var b:=Button.new();b.text=text_;b.position=r.position;b.size=r.size;b.add_theme_font_override("font",font);b.add_theme_font_size_override("font_size",8);b.pressed.connect(callback);parent.add_child(b);return b
func _make_ui() -> void:
	hud=CanvasLayer.new();hud.layer=20;add_child(hud)
	header_panel=_panel(hud,Rect2(0,0,1920,96),Color("142e3c"));_panel(hud,Rect2(0,92,1920,4),Color("eac46c"))
	_text(hud,"PATOGEN",Vector2(28,13),15,Color("86b8c9"),true)
	_text(hud,"PATO SPLASH",Vector2(27,32),35,Color("fff0cc"),true)
	_text(hud,"PARQUE ACUATICO / VISTA EXPLORABLE",Vector2(420,49),8,Color("a9c7cd"))
	_text(hud,"PROXIMA ATRACCION",Vector2(840,12),13,Color("8cb5c5"))
	event_label=_text(hud,"",Vector2(840,30),23,Color("fff0cc"))
	progress=ProgressBar.new();progress.position=Vector2(840,66);progress.size=Vector2(444,8);progress.show_percentage=false;hud.add_child(progress)
	_button(hud,"Ver chapuzon [E]",Rect2(1360,27,190,42),_preview_event)
	_button(hud,"Ver NPCs [Tab]",Rect2(1572,27,226,42),_toggle_gallery)
	_button(hud,"Pausa",Rect2(1810,27,84,42),_toggle_pause)
	_panel(hud,Rect2(0,992,1920,88),Color("142e3c"));_panel(hud,Rect2(0,992,1920,3),Color("487e91"))
	subtitle=_text(hud,"",Vector2(28,1004),19,Color("e9dfc3"))
	_text(hud,"WASD / FLECHAS mover   ESPACIO pausa   E chapuzon   I prueba infeccion   R vibracion   M sonido   H interfaz   F11 pantalla",Vector2(28,1041),8,Color("97bcc8"))
	gallery=Control.new();gallery.visible=false;hud.add_child(gallery)
	_panel(gallery,Rect2(0,0,1920,1080),Color(.035,.07,.1,.97))
	_text(gallery,"PERSONAJES DE PATO SPLASH",Vector2(36,24),28,Color("fff0cc"),true)
	_text(gallery,"9 variantes / 4 direcciones / fuentes Aseprite editables",Vector2(36,69),19,Color("a9c7cd"))
	_button(gallery,"Cerrar [Tab]",Rect2(1690,24,190,44),_toggle_gallery)
	var row_names: Array=["BANADORES","SALVAVIDAS","STAFF"]
	for r in 3:
		_text(gallery,row_names[r],Vector2(50,137+r*250),24,Color("f0ce78"),true)
		for n in 3:
			for d in 4:
				var s:=AnimatedSprite2D.new();s.sprite_frames=load("res://splash/assets/%s_%d.tres"%[["banador","salvavidas","staff"][r],n+1]);s.position=Vector2(338+n*498+d*108,200+r*250);s.scale=Vector2(3,3);s.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;s.play(["Abajo","Arriba","Derecha","Izquierda"][d]);gallery.add_child(s)
	_text(gallery,"Texturas, agua, mobiliario y animaciones: carpeta splash/assets",Vector2(50,940),20,Color("a9c7cd"))
	_text(gallery,"El parque queda pausado mientras revisas los personajes.",Vector2(50,978),18,Color("a9c7cd"))

func _phase(phase_: String,left: float) -> void:
	if not is_instance_valid(event_label):return
	match phase_:
		"calma":event_label.text="Gran chapuzon en %02d s"%ceili(left+map.warning_seconds);subtitle.text="54 visitantes + 16 personajes de ambiente  /  P1 cian · P2 magenta"
		"aviso":event_label.text="¡SILBATO!  %.1f s"%left;subtitle.text="¡Atencion al parque! El pato prepara su giro completo..."
		"chapuzon":event_label.text="¡GRAN CHAPUZON!";subtitle.text="¡Giro de 360 grados! Gotas por todo el parque; visitantes corriendo o cubriendose."
		"reposo":event_label.text="El pato toma aire";subtitle.text="Las ultimas gotas caen; los charcos se secan y los visitantes retoman su paseo."
	progress.max_value=map.phase_duration();progress.value=map.phase_duration()-left
	if infection_preview:subtitle.text="PRUEBA: infeccion simulada activa / I limpia el foco / Huir, cubrirse y avisar"
	if get_tree().paused:subtitle.text="PAUSA  /  Espacio para continuar"

func _attract(points: Array[Vector2],limit: int,duration: float) -> void:
	# Up to five nearby visitors from each side. Never inspect a team or infection.
	var sides: Array=[[],[]]
	for actor in get_tree().get_nodes_in_group("splash_visitors"):
		if actor.role=="banador":
			var path: PackedVector2Array=routes.path(actor.global_position,points[1])
			var distance:=0.0
			for k in range(1,path.size()):distance+=path[k-1].distance_to(path[k])
			actor.set_meta("event_distance",distance)
			if distance/actor.speed<=map.warning_seconds+1:sides[0 if actor.global_position.x<960 else 1].append(actor)
	selected_last=0
	for side in 2:
		var candidates: Array=sides[side]
		candidates.sort_custom(func(a,b):return a.get_meta("event_distance")<b.get_meta("event_distance"))
		for i in mini(floori(float(limit)/2.0),candidates.size()):
			var target: Vector2=points[(side*2+i)%points.size()]+Vector2((i%3-1)*24,floori(float(i)/3.0)*24)
			candidates[i].attend_event(target,duration);selected_last+=1

func _release() -> void:
	for actor in get_tree().get_nodes_in_group("splash_visitors"): actor.leave_event()
func _impact(strength: float) -> void:
	if shake_enabled:shake_left=map.cannon.shake_duration*strength
func _process(delta: float) -> void:
	if get_tree().paused:return
	total_time+=delta
	shake_left=maxf(0,shake_left-delta)
	var decay:=pow(clampf(shake_left/maxf(0.05,map.cannon.shake_duration),0.0,1.0),2.0)
	var amplitude:float=map.cannon.shake_intensity*decay
	if map.phase=="chapuzon":amplitude+=map.cannon.stream_shake_intensity
	if is_instance_valid(camera):camera.offset=(Vector2(sin(total_time*91),cos(total_time*73))*amplitude).round() if shake_enabled else Vector2.ZERO
	header_panel.color=Color("652f3c") if map.phase=="aviso" and int(total_time*5.0)%2==0 else Color("142e3c")
func _preview_event() -> void:
	map.request_attraction()
func _toggle_pause() -> void:
	get_tree().paused=not get_tree().paused
	if is_instance_valid(ambient):ambient.stream_paused=get_tree().paused
	_phase(map.phase,map.phase_duration()-map.elapsed)
var gallery_was_paused := false
func _toggle_gallery() -> void:
	if not gallery.visible:
		gallery_was_paused=get_tree().paused;get_tree().paused=true;ambient.stream_paused=true;gallery.show()
	else:
		gallery.hide();get_tree().paused=gallery_was_paused;ambient.stream_paused=get_tree().paused
func _unhandled_key_input(e: InputEvent) -> void:
	if not e is InputEventKey or not e.pressed or e.echo:return
	match e.physical_keycode:
		KEY_SPACE:_toggle_pause()
		KEY_E:_preview_event()
		KEY_TAB:_toggle_gallery()
		KEY_R:shake_enabled=not shake_enabled;camera.offset=Vector2.ZERO
		KEY_M:
			map.audio_enabled=not map.audio_enabled;ambient.volume_db=-9 if map.audio_enabled else -80
			if not map.audio_enabled:map.chime.stop();map.impact_sound.stop()
		KEY_H:hud.visible=not hud.visible
		KEY_I:_preview_infection()
		KEY_F11:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_ESCAPE:
			if gallery.visible:_toggle_gallery()
			elif DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN:DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _preview_infection() -> void:
	if not park_life:return
	infection_preview=not infection_preview
	# Explicit demo input only; no automatic infection or changes to production actors.
	for actor in get_tree().get_nodes_in_group("splash_visitors"):
		park_life.set_infection_state(actor,infection_preview)
		actor.set_meta("demo_infected",infection_preview)
		var badge:Sprite2D=actor.get_node_or_null("InfeccionDemo")
		if not badge:
			badge=Sprite2D.new();badge.name="InfeccionDemo";badge.texture=load("res://splash/assets/reaccion_alerta.tres").get_frame_texture("default",0);badge.position=Vector2(0,-25);badge.scale=Vector2.ONE*0.5;actor.add_child(badge)
		badge.visible=infection_preview
	subtitle.text="PRUEBA DE REACCIONES: infeccion simulada activa [I para limpiar]" if infection_preview else "Prueba de infeccion desactivada; los visitantes se recuperan."

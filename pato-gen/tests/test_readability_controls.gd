extends SceneTree
const Equipos = preload("res://scripts/equipos_infeccion.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS ", message)
	else:
		failures += 1
		push_error("FAIL " + message)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var host = load("res://scenes/Shopping.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	host.timer_inicio.stop()
	var duck = host.get_node("Patos/Pato")
	var other = host.get_node("Patos/Pato2")
	duck.set_physics_process(false)
	other.set_physics_process(false)
	check(duck.color_jugador == Equipos.COLOR_AZUL and other.color_jugador == Equipos.COLOR_MAGENTA, "both players use the shared blue and magenta palette")
	check(duck.grupo_visual_pato.scale.x > 1.0, "player has a larger visual silhouette")
	duck.convertirse_en_fantasma()
	var original_scale: Vector2 = duck.grupo_visual_pato.scale
	duck.convertirse_en_fantasma()
	check(duck.grupo_visual_pato.scale == original_scale, "repeated ghost conversion does not enlarge the player again")
	key(KEY_D, true)
	duck._physics_process(1.0 / 60.0)
	check(duck.velocity.x > 0.0 and duck.velocity.x < duck.speed, "movement starts immediately with a smooth acceleration")
	for i in 12:
		duck._physics_process(1.0 / 60.0)
	check(is_equal_approx(duck.velocity.length(), duck.speed), "player reaches full speed promptly without overshoot")
	key(KEY_W, true)
	for i in 12:
		duck._physics_process(1.0 / 60.0)
	check(is_equal_approx(duck.velocity.length(), duck.speed), "diagonal movement preserves the same maximum speed")
	key(KEY_W, false)
	key(KEY_D, false)
	for i in 8:
		duck._physics_process(1.0 / 60.0)
	check(duck.velocity.is_zero_approx(), "releasing movement stops promptly without prolonged sliding")
	check("AZUL" in host.interfaz.footer.text and not "CIAN" in host.interfaz.footer.text, "match instructions name the blue team correctly")
	var target = get_nodes_in_group("bots")[0]
	target.activar_infeccion(Equipos.COLOR_AZUL, Equipos.AZUL, false)
	host.estado_actual = host.EstadoJuego.FASE_INFECCION
	duck.iniciar_posesion(target)
	duck.tiempo_posesion = 7.5
	host.interfaz.sync(host.contar_infecciones())
	check("POSESIÓN 8s" in host.interfaz.footer.text and not "SOLTAR" in host.interfaz.footer.text, "possession hint shows remaining control time and supported actions")
	host._on_timer_juego_timeout()
	check("AZUL" in host.label_contador.text and not "CIAN" in host.label_contador.text, "blue victory uses the correct visible team name")
	paused = false
	host.queue_free()
	await process_frame
	await process_frame
	print("READABILITY CONTROLS RESULT ", checks, " checks; ", failures, " failures")
	quit(1 if failures else 0)

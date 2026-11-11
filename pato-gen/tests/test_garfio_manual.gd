extends "res://tests/test_garfio.gd"
## Real Pato input edges and the existing contextual possession button.

func run() -> void:
	await preparar()
	for team in [1, 2]:
		await controles(team)
	print("GARFIO MANUAL RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	READABILITY.textures.clear()
	var bot_script: Script = load("res://scripts/Bot.gd")
	bot_script.frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func input_key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func refresh_hud() -> void:
	host.interfaz.sync(host.contar_infecciones())
	host.interfaz.tick = 1.0
	host.interfaz._process(0.1)

func controles(team: int) -> void:
	await limpiar()
	var source := actor(ORIGIN, team)
	var target := actor(ORIGIN + Vector2(130, 0), 0)
	var ability: Node2D = source.garfio
	var duck: Node2D = host.get_node("Patos/" + ("Pato" if team == 1 else "Pato2"))
	var attack: Key = KEY_X if team == 1 else KEY_J
	var movement: Key = KEY_D if team == 1 else KEY_RIGHT
	input_key(attack, false)
	input_key(movement, false)
	duck.finalizar_posesion()
	duck.cooldown_posesion = 0.0
	duck.global_position = ORIGIN
	duck._physics_process(0.016)
	check(not duck.activar_garfio_poseido(), "manual action requires possession P%d" % team)
	input_key(movement, true)
	input_key(attack, true)
	duck._physics_process(0.016)
	check(duck.bot_poseido == source and source.controlado_por_jugador, "X/J still starts ordinary possession P%d" % team)
	check(ability.estado == G.Estado.LISTO and target.captor_garfio == null, "key held while entering possession does not launch a hook P%d" % team)
	duck._physics_process(0.016)
	ability.hasta_busqueda = 0.0
	ability.actualizar(0.5)
	check(ability.estado == G.Estado.LISTO and target.captor_garfio == null, "held possession key and automatic search cannot fire possessed Garfio P%d" % team)
	refresh_hud()
	var button: Button = host.interfaz.ability_buttons[team - 1][3]
	check("enganchar" in button.text.to_lower() and "listo" in button.text.to_lower() and not button.disabled, "existing possession button shows the ready manual hook P%d" % team)
	input_key(attack, false)
	duck._physics_process(0.016)
	input_key(attack, true)
	duck._physics_process(0.016)
	check(ability.estado == G.Estado.PREPARANDO and target.captor_garfio == ability, "a new X/J press launches one manually aimed hook P%d" % team)
	var current_target: Node2D = ability.objetivo
	duck._physics_process(0.016)
	check(ability.objetivo == current_target and not duck.activar_garfio_poseido(), "held input cannot restart an active attack P%d" % team)
	refresh_hud()
	check(button.disabled and "curso" in button.text.to_lower(), "HUD disables the contextual button during the attack P%d" % team)
	ability.cancelar()
	refresh_hud()
	check(button.disabled and "cd" in button.text.to_lower() and not duck.activar_garfio_poseido(), "cooldown disables both HUD and manual method P%d" % team)
	ability.recarga_restante = 0.0
	ability.hasta_busqueda = 1000.0
	refresh_hud()
	button.pressed.emit()
	check(ability.estado == G.Estado.PREPARANDO and target.captor_garfio == ability, "the existing HUD button activates the same manual hook P%d" % team)
	ability.cancelar()
	ability.recarga_restante = 0.0
	input_key(attack, false)
	duck._physics_process(0.016)
	var real_owner: int = source.player_duenio
	source.player_duenio = 3 - team
	check(not duck.activar_garfio_poseido(), "player cannot manually fire a rival host P%d" % team)
	source.player_duenio = real_owner
	host.timer_juego.paused = true
	check(not duck.activar_garfio_poseido(), "manual hook is blocked while the tutorial holds the clock P%d" % team)
	host.timer_juego.paused = false
	paused = true
	check(not duck.activar_garfio_poseido(), "manual hook is blocked while the tree is paused P%d" % team)
	paused = false
	source.incubacion_contagio = 0.5
	refresh_hud()
	check(button.disabled and "incub" in button.text.to_lower() and not duck.activar_garfio_poseido(), "incubation appears on the button and prevents firing P%d" % team)
	source.incubacion_contagio = 0.0
	check(duck.activar_garfio_poseido(), "valid owner can fire again after the explicit cooldown reset P%d" % team)
	source.curar_por_robot(1.0)
	duck._physics_process(0.016)
	refresh_hud()
	check(duck.bot_poseido == null and target.captor_garfio == null and not duck.activar_garfio_poseido(), "curing the possessed captor releases possession and target P%d" % team)
	check("poseer" in button.text.to_lower() and not "enganchar" in button.text.to_lower(), "button returns to its ordinary possession action P%d" % team)
	# Ordinary infected hosts keep the original controls and contextual action.
	source.activar_infeccion(Color.CYAN if team == 1 else Color.MAGENTA, team, false)
	var empty_mutations: Array[String] = []
	source.aplicar_mutaciones(empty_mutations, "atletico")
	freeze_bot(source)
	duck.iniciar_posesion(source)
	refresh_hud()
	check(not duck.activar_garfio_poseido() and source.cepa == "atletico" and "poseer" in button.text.to_lower(), "another strain cannot use the hook or lose its ordinary possession action P%d" % team)
	duck.finalizar_posesion()
	input_key(attack, false)
	input_key(movement, false)
	duck._physics_process(0.016)

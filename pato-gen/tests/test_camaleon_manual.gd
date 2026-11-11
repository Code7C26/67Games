extends "res://tests/test_simbionte.gd"
## Production X/J edges and the same fourth contextual HUD button for both teams.
const ORIGIN := Vector2(656, 568)
const READABILITY = preload("res://scripts/npc_readability.gd")

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

func clear_bots() -> void:
	for bot in get_nodes_in_group("bots"): bot.queue_free()
	await physics_frame
	await physics_frame

func run() -> void:
	root.set_meta("patogen_cepas", {1: "camaleon", 2: "camaleon"})
	await fresh()
	host.evento_coloso.set_physics_process(false)
	host.evento_alfa.set_physics_process(false)
	for team in [1, 2]: await controles(team)
	print("CAMALEON MANUAL RESULT ", passed, " passed; ", failures, " failed")
	paused = false
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	READABILITY.textures.clear()
	var bot_script: Script = load("res://scripts/Bot.gd")
	bot_script.frames_infectados_cache.clear()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)

func controles(team: int) -> void:
	await clear_bots()
	var source := bot_at(ORIGIN, team)
	freeze_bot(source)
	source.incubacion_contagio = 0.0
	var ability: Node2D = source.camaleon
	check(is_instance_valid(ability), "Camaleon component exists P%d" % team)
	if not is_instance_valid(ability): return
	var duck: Node2D = host.get_node("Patos/" + ("Pato" if team == 1 else "Pato2"))
	var action: Key = KEY_X if team == 1 else KEY_J
	input_key(action, false)
	duck.finalizar_posesion()
	duck.cooldown_posesion = 0.0
	duck.global_position = ORIGIN
	duck._physics_process(0.016)
	source.revelar_camaleon("prueba")
	ability.recarga_restante = 0.0
	check(not duck.activar_camaleon_poseido(), "camouflage action requires possession P%d" % team)
	input_key(action, true)
	duck._physics_process(0.016)
	check(duck.bot_poseido == source and source.controlado_por_jugador, "X/J retains ordinary possession entry P%d" % team)
	check(not ability.camuflado, "possession press does not also camouflage on entry P%d" % team)
	duck._physics_process(0.016)
	check(not ability.camuflado, "holding X/J does not activate a possessed skill P%d" % team)
	refresh_hud()
	var button: Button = host.interfaz.ability_buttons[team - 1][3]
	check("camuflar" in button.text.to_lower() and "listo" in button.text.to_lower() and not button.disabled, "fourth button exposes ready camouflage P%d" % team)
	input_key(action, false)
	duck._physics_process(0.016)
	input_key(action, true)
	duck._physics_process(0.016)
	check(ability.camuflado, "a new X/J press activates camouflage P%d" % team)
	refresh_hud()
	check(button.disabled and "camuflado" in button.text.to_lower(), "HUD clearly shows the active camouflage state P%d" % team)
	source.revelar_camaleon("prueba")
	refresh_hud()
	check(button.disabled and "cd" in button.text.to_lower() and not duck.activar_camaleon_poseido(), "cooldown blocks both action and HUD P%d" % team)
	ability.recarga_restante = 0.0
	var near := bot_at(ORIGIN + Vector2(30, 0), 0)
	await physics_frame
	await physics_frame
	refresh_hud()
	check(button.disabled and "humano" in button.text.to_lower(), "close healthy human explains the activation block P%d" % team)
	check(not duck.activar_camaleon_poseido() and not ability.camuflado, "point-blank humans prevent manual concealment P%d" % team)
	near.queue_free()
	await physics_frame
	await physics_frame
	refresh_hud()
	button.pressed.emit()
	check(ability.camuflado, "existing HUD button invokes the same ready skill P%d" % team)
	source.revelar_camaleon("prueba")
	ability.recarga_restante = 0.0
	var real_owner: int = source.player_duenio
	source.player_duenio = 3 - team
	check(not duck.activar_camaleon_poseido(), "rival host cannot be concealed P%d" % team)
	source.player_duenio = real_owner
	host.timer_juego.paused = true
	check(not duck.activar_camaleon_poseido(), "tutorial-held clock blocks camouflage activation P%d" % team)
	host.timer_juego.paused = false
	paused = true
	check(not duck.activar_camaleon_poseido(), "tree pause blocks camouflage activation P%d" % team)
	paused = false
	source.incubacion_contagio = 0.5
	refresh_hud()
	check(button.disabled and "incub" in button.text.to_lower() and not duck.activar_camaleon_poseido(), "incubation prevents manual concealment P%d" % team)
	source.incubacion_contagio = 0.0
	check(duck.activar_camaleon_poseido(), "valid possessed host can camouflage again when ready P%d" % team)
	if team == 1: host.adn_cian = 40
	else: host.adn_magenta = 40
	duck.cooldown_zona_calor = 0.0
	duck.colocar_zona_temperatura("calor")
	check(not ability.camuflado and ability.recarga_restante > 0.0, "successful zone action reveals its possessed host P%d" % team)
	ability.recarga_restante = 0.0
	check(duck.activar_camaleon_poseido(), "zone cooldown does not replace the camouflage cooldown P%d" % team)
	duck.cooldown_robot = 0.0
	duck.invocar_robot()
	check(not ability.camuflado and ability.recarga_restante > 0.0, "successful robot action reveals its possessed host P%d" % team)
	source.curar_por_robot(1.0)
	duck._physics_process(0.016)
	refresh_hud()
	check(duck.bot_poseido == null and not duck.activar_camaleon_poseido(), "curing the host releases possession and camouflage P%d" % team)
	check("poseer" in button.text.to_lower() and not "camuflar" in button.text.to_lower(), "HUD restores ordinary possession after cure P%d" % team)
	input_key(action, false)
	duck._physics_process(0.016)

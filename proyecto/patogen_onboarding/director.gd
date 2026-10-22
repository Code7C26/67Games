extends Node
signal finished(result: String)
signal step_changed(step: String)
const Overlay = preload("res://patogen_onboarding/overlay.gd")
const Rig = preload("res://patogen_onboarding/cinematic_camera.gd")
const Burst = preload("res://patogen_onboarding/pixel_burst.gd")
var bridge: Node
var profile: RefCounted
var ui: CanvasLayer
var rig: Node
var state := "idle"
var elapsed := 0.0
var deadline := 0.0
var facts: Dictionary = {}
var missed_steps: Array[String] = []
var forced_tutorial := false
var ending := false
var tutorial_active := false
var fx: Array[Node] = []
# Test harness can accelerate only cinematic presentation, never game time.
var presentation_speed := 1.0

func configure(adapter: Node, preferences: RefCounted) -> void:
	bridge = adapter
	profile = preferences
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui = Overlay.new()
	add_child(ui)
	ui.protected_controls = bridge.protected_controls()
	rig = Rig.new()
	add_child(rig)
	ui.reduced_motion = bool(profile.data.reduced_motion)
	ui.motion.set_pressed_no_signal(ui.reduced_motion)
	rig.reduced_motion = ui.reduced_motion
	ui.next_requested.connect(_next)
	ui.skip_requested.connect(skip)
	ui.help_requested.connect(replay)
	ui.motion_changed.connect(func(value: bool):
		rig.reduced_motion = value
		if value:
			rig.restore()
		profile.data.reduced_motion = value
		profile.save_profile())
	bridge.fact.connect(_fact)

func start(mode: String = "auto") -> void:
	if state != "idle":
		return
	ending = false
	tutorial_active = false
	facts.clear()
	missed_steps.clear()
	forced_tutorial = mode == "tutorial"
	profile.begin()
	bridge.begin_cinematic()
	rig.take_over(bridge.gameplay_camera)
	ui.start(true)
	_enter("overview", 2.1)
	ui.show_card("67GAMES / PATOGEN", "Un día cualquiera.", "El shopping abre sus puertas. Nadie espera lo que viene.")

func replay() -> void:
	if state != "idle" or not bridge.can_tutorial_start():
		return
	ending = false
	facts.clear()
	missed_steps.clear()
	profile.begin()
	ui.start(false)
	_begin_tutorial()

func _enter(step: String, timeout: float = 0) -> void:
	state = step
	elapsed = 0
	deadline = timeout
	profile.data.last_step = step
	profile.save_profile()
	step_changed.emit(step)

func _process(delta: float) -> void:
	if state == "idle" or ending:
		if is_instance_valid(ui) and is_instance_valid(bridge):
			ui.help.visible = bridge.can_tutorial_start()
		return
	# Respect an external pause; Escape still works through the always-processing UI.
	if get_tree().paused:
		if is_instance_valid(bridge.world) and bridge.world.get("estado_actual") == 2:
			_finish("interrupted")
		return
	if not is_instance_valid(bridge) or (bridge.world != null and not is_instance_valid(bridge.world)):
		_finish("interrupted")
		return
	var cinematic_step := state in ["overview", "approach", "anticipation", "infection", "return"]
	elapsed += delta * (presentation_speed if cinematic_step else 1.0)
	if state == "move" and facts.has("moved"):
		_open_step()
	elif state == "open" and facts.has("mutations_opened"):
		_buy_step()
	elif state == "buy" and facts.has("mutation_purchased"):
		_apply_step()
	elif state == "apply" and facts.has("mutation_applied") and elapsed >= 1.4:
		_observe_step()
	elif state == "observe" and facts.has("spread_observed_after_purchase") and elapsed >= 1.5:
		_controls_step()
	elif deadline > 0 and elapsed >= deadline:
		_timeout()

func _timeout() -> void:
	match state:
		"overview":
			_enter("approach", 1.7)
			ui.hide_card()
			if is_instance_valid(bridge.duck):
				rig.frame_point(bridge.duck.global_position, 1.8, 1.6 / presentation_speed)
				ui.highlight(bridge.duck)
		"approach":
			_enter("anticipation", 0.7)
			ui.show_card("ORIGEN / PACIENTE CERO", "Un pato. Un brote.", "Todo está por cambiar.")
		"anticipation":
			_enter("explosion", 4.0)
			if bridge.supports("outbreak"):
				bridge.play_outbreak()
			else:
				_infection_step()
		"explosion": _infection_step()
		"infection":
			_enter("return", 1.2)
			ui.hide_card()
			ui.highlight(null)
			rig.return_to_overview(1.1 / presentation_speed)
		"return":
			rig.restore()
			bridge.release_cinematic()
			ui.handoff()
			if forced_tutorial:
				_begin_tutorial()
			else:
				_enter("offer", 60)
				ui.show_card("EL BROTE HA COMENZADO", "Tu decisión cambia la partida.", bridge.objective_text(), "Podés aprender jugando o entrar directamente con Omitir.", "Aprender jugando")
		"offer": _finish("skipped")
		"move", "open", "buy", "apply", "observe":
			missed_steps.append(state)
			_controls_step(true)
		"controls": _finish("partial" if not missed_steps.is_empty() else "completed")

func _infection_step() -> void:
	if state != "explosion":
		return
	_enter("infection", 2.8)
	if is_instance_valid(bridge.focus_infected):
		rig.frame_point(bridge.focus_infected.global_position, 1.65, 0.65 / presentation_speed)
		ui.highlight(bridge.focus_infected)
		ui.show_card("01 / PROPAGACIÓN", "El brote ha comenzado.", "El primer humano ya está infectado. Ahora puede transmitir el patógeno a otros.")
	else:
		ui.show_card("01 / PROPAGACIÓN", "Todo empieza con un contagio.", "Cuando haya un humano infectado, podrá transmitir el patógeno a otros.")

func _begin_tutorial() -> void:
	tutorial_active = true
	bridge.tutorial_started()
	if bridge.supports("movement"):
		_enter("move", 40)
		ui.highlight(bridge.duck)
		ui.show_card("02 / TOMÁ EL CONTROL", "Movete por el shopping.", "Tu pato sigue presente como fantasma después del brote.", "Jugador cian: usá WASD para desplazarte.", "", 2)
	else:
		missed_steps.append("movement_unavailable")
		_open_step()

func _open_step() -> void:
	if not bridge.supports("mutations"):
		missed_steps.append("mutations_unavailable")
		_controls_step(true)
		return
	_enter("open", 45)
	ui.highlight(bridge.highlight_target("mutation_menu"))
	ui.show_card("03 / EVOLUCIÓN", "Abrí tus mutaciones.", "Cada contagio aporta ADN. Lo podés invertir en las evoluciones de tu cepa.", "Jugador cian: presioná E para abrir el menú.", "", 3)

func _buy_step() -> void:
	var info: Dictionary = bridge.mutation_info()
	if info.is_empty():
		missed_steps.append("no_mutation_available")
		_controls_step(true)
		return
	_enter("buy", 65)
	ui.highlight(bridge.highlight_target("mutation_choice"))
	var description: String = str(info.description)
	if "\n" in description:
		description = description.substr(description.find("\n") + 1)
	ui.show_card("04 / ELEGÍ UNA MUTACIÓN", str(info.name), description, "Cuesta %s ADN. Si te falta, esperá nuevos contagios.\nElegí una opción con clic o teclas %s. Shift + tecla consulta sin comprar." % [info.cost, info.get("keys", "1 / 2 / 3")], "", 4)

func _apply_step() -> void:
	_enter("apply", 12)
	var purchase: Dictionary = facts.get("mutation_purchased", {})
	ui.highlight(bridge.highlight_target("infection"))
	ui.show_card("05 / EVOLUCIÓN ADQUIRIDA", "Tu cepa acaba de cambiar.", str(purchase.get("description", "La mutación fue comprada.")), "Esperando que un infectado propio reciba la mutación.", "", 5)
	if not bridge.supports("effects"):
		missed_steps.append("effects_unavailable")
		_controls_step(true)

func _observe_step() -> void:
	_enter("observe", 25)
	ui.highlight(bridge.highlight_target("infection"))
	ui.show_card("06 / OBSERVÁ EL BROTE", "La mutación ya está activa.", "El infectado señalado recibió la mejora. Observá cómo continúa la propagación.", "Un nuevo contagio confirmará que el brote sigue avanzando. La compra no garantiza un contagio inmediato.", "", 6)

func _controls_step(fallback: bool = false) -> void:
	_enter("controls", 35)
	ui.highlight(null)
	var message: String = bridge.controls_text()
	if fallback:
		message = "Podés continuar la partida y volver a la guía cuando quieras.\n\n" + message
	ui.show_card("07 / EL SHOPPING ES TUYO", "Ya tenés el control.", message, bridge.objective_text(), "Continuar partida", 7)

func _next() -> void:
	match state:
		"offer": _begin_tutorial()
		"controls": _finish("partial" if not missed_steps.is_empty() else "completed")

func _fact(event: String, payload: Dictionary) -> void:
	if state == "idle" or ending:
		return
	if payload.has("player_id") and int(payload.player_id) != 1:
		return
	facts[event] = payload
	if event == "spread_observed" and facts.has("mutation_purchased"):
		facts["spread_observed_after_purchase"] = payload
	if event == "outbreak_started":
		rig.shake()
		if is_instance_valid(bridge.duck):
			var burst := Burst.new()
			burst.reduced_motion = rig.reduced_motion
			add_child(burst)
			burst.global_position = bridge.duck.global_position
			burst.z_index = 100
			fx.append(burst)
	elif event == "outbreak_finished" and state == "explosion":
		_infection_step()
	elif event == "match_ended":
		_finish("interrupted")

func skip() -> void:
	if state != "idle":
		_finish("skipped")

func interrupt() -> void:
	if state != "idle":
		_finish("interrupted")

func _finish(result: String) -> void:
	if ending or state == "idle":
		return
	ending = true
	state = "idle"
	deadline = 0
	rig.restore()
	if result == "interrupted":
		bridge.cancel()
	else:
		bridge.cleanup()
	for effect in fx:
		if is_instance_valid(effect):
			effect.queue_free()
	fx.clear()
	ui.set_idle()
	profile.finish(result)
	ending = false
	finished.emit(result)

func _exit_tree() -> void:
	if state != "idle":
		_finish("interrupted")

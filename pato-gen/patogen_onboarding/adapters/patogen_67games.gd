extends "res://patogen_onboarding/bridge.gd"
## Adapter for the inspected 67Games snapshots (2026-10-19 and 2026-10-21).
## No currency grants, forced purchases, infection probabilities or duplicate AI.
var player_id := 1
var ducks: Array[Node] = []
var timers: Dictionary = {}
var visibility: Dictionary = {}
var physics_flags: Dictionary = {}
var sprite_states: Dictionary = {}
var map_input_enabled := true
var cinematic_active := false
var explosion_pending := false
var explosion_elapsed := 0.0
var explosion_timeout := 0.0
var outbreak_committed := false
var observing := false
var poll_time := 0.0
var old_mutations: Array = []
var old_panel_open := false
var old_infected: Dictionary = {}
var origin := Vector2.ZERO
var movement_reported := false
var last_purchase := ""
var effect_reported := false
var last_contagios := 0
var closed := false

func setup(host: Node) -> void:
	world = host
	gameplay_camera = host.get_node_or_null("Camera2D") as Camera2D
	var duck_parent := host.get_node_or_null("Patos")
	if duck_parent:
		for child in duck_parent.get_children():
			if child.has_method("infectar_y_desaparecer"):
				ducks.append(child)
				if int(child.get("player_id")) == player_id:
					duck = child
	capabilities = {
		"outbreak": not ducks.is_empty() and host.has_method("_on_timer_inicio_timeout") and _has_property(host, "estado_actual"),
		"infection": host.has_method("contar_infecciones"),
		"movement": is_instance_valid(duck),
		"mutations": host.has_method("comprar_mutacion") and host.has_method("obtener_ramas_jugador") and host.get_node_or_null("HUD_ADN/PanelCian") != null,
		"effects": host.has_method("actualizar_mutaciones_existentes")
	}
	for method in ["obtener_siguiente_evolucion", "obtener_costo_mutacion", "_nombre_mutacion", "_descripcion_mutacion"]:
		if not host.has_method(method):
			capabilities.mutations = false
	for property in ["mutaciones_p1", "adn_cian", "estado_actual"]:
		if not _has_property(host, property):
			capabilities.mutations = false
	if supports("mutations"):
		old_mutations = host.get("mutaciones_p1").duplicate()
	last_contagios = int(host.get("contagios_cian")) if _has_property(host, "contagios_cian") else 0

func begin_cinematic() -> void:
	if not is_instance_valid(world):
		return
	cinematic_active = true
	closed = false
	for name in ["TimerInicio", "TimerJuego"]:
		var timer := world.get_node_or_null(name) as Timer
		if timer:
			timers[timer] = timer.paused
			timer.paused = true
	for name in ["HUD", "HUD_ADN"]:
		var hud := world.get_node_or_null(name) as CanvasLayer
		if hud:
			visibility[hud] = hud.visible
			hud.hide()
	map_input_enabled = world.is_processing_unhandled_input()
	world.set_process_unhandled_input(false)
	for actor in ducks:
		physics_flags[actor] = actor.is_physics_processing()
		actor.set_physics_process(false)
		var sprite := _sprite(actor)
		if sprite:
			sprite_states[sprite] = {"animation": sprite.animation, "frame": sprite.frame, "playing": sprite.is_playing(), "modulate": sprite.modulate}
			if sprite.sprite_frames.has_animation("Abajo"):
				sprite.play("Abajo")

func play_outbreak() -> void:
	if not supports("outbreak") or outbreak_committed or explosion_pending:
		return
	if int(world.get("estado_actual")) != 0:
		notify("outbreak_finished")
		return
	explosion_pending = true
	world.fase_infeccion_iniciada.connect(_commit_outbreak, CONNECT_ONE_SHOT)
	world.call("_on_timer_inicio_timeout")
	notify("outbreak_started", {"target": duck})


func _animation_done() -> void:
	# Kept for cleanup compatibility; completion is owned by the actor.
	pass


func _commit_outbreak() -> void:
	if outbreak_committed or not is_instance_valid(world):
		return
	outbreak_committed = true
	explosion_pending = false
	_poll_infections()
	notify("outbreak_finished")


func release_cinematic() -> void:
	if not cinematic_active:
		return
	# If skipped mid-explosion, finish the same real event exactly once.
	cinematic_active = false
	for actor in physics_flags:
		if is_instance_valid(actor):
			actor.set_physics_process(physics_flags[actor])
	physics_flags.clear()
	for sprite in sprite_states:
		if is_instance_valid(sprite) and not outbreak_committed and not explosion_pending:
			var value: Dictionary = sprite_states[sprite]
			sprite.modulate = value.modulate
			sprite.animation = value.animation
			sprite.frame = value.frame
			if value.playing:
				sprite.play()
			else:
				sprite.pause()
	sprite_states.clear()
	for hud in visibility:
		if is_instance_valid(hud):
			hud.visible = visibility[hud]
	visibility.clear()
	if is_instance_valid(world):
		world.set_process_unhandled_input(map_input_enabled)
	# TimerInicio resumes if skipped early. TimerJuego stays held through the offer.
	var timer := world.get_node_or_null("TimerInicio") as Timer if is_instance_valid(world) else null
	if timer and timers.has(timer):
		timer.paused = timers[timer]
		timers.erase(timer)

func tutorial_started() -> void:
	closed = false
	observing = true
	if is_instance_valid(duck):
		origin = duck.global_position
	movement_reported = false
	var timer := world.get_node_or_null("TimerJuego") as Timer if is_instance_valid(world) else null
	if timer and not timers.has(timer):
		timers[timer] = timer.paused
		timer.paused = true
	# Record current facts so repeated tutorials can recognize an already open panel.
	old_panel_open = false
	_poll()

func _process(delta: float) -> void:
	if closed or not is_instance_valid(world):
		return
	if not observing and not cinematic_active:
		return
	poll_time += delta
	if poll_time >= 0.1:
		poll_time = 0
		_poll()

func _poll() -> void:
	if _has_property(world, "estado_actual") and int(world.get("estado_actual")) == 2:
		notify("match_ended")
		return
	_poll_infections()
	if observing and is_instance_valid(duck) and not movement_reported and duck.global_position.distance_to(origin) >= 24:
		movement_reported = true
		notify("moved", {"player_id": player_id})
	if supports("mutations"):
		var panel := world.get_node_or_null("HUD_ADN/PanelCian") as Control
		if panel:
			var opened := panel.is_visible_in_tree()
			if opened and not old_panel_open:
				notify("mutations_opened", {"player_id": player_id})
			old_panel_open = opened
		var current: Array = world.get("mutaciones_p1")
		for mutation in current:
			if mutation not in old_mutations:
				last_purchase = str(mutation)
				effect_reported = false
				notify("mutation_purchased", {"player_id": player_id, "id": mutation, "description": world.call("_descripcion_mutacion", mutation)})
		old_mutations = current.duplicate()
		if not last_purchase.is_empty() and not effect_reported:
			for bot in _bots():
				if bool(bot.get("is_infected")) and int(bot.get("player_duenio")) == player_id and bot.has_method("tiene_mutacion") and bot.call("tiene_mutacion", last_purchase):
					effect_reported = true
					focus_infected = bot
					notify("mutation_applied", {"target": bot, "id": last_purchase})
					break
	if _has_property(world, "contagios_cian"):
		var count := int(world.get("contagios_cian"))
		if count > last_contagios:
			notify("spread_observed", {"count": count, "player_id": player_id})
		last_contagios = count

func _poll_infections() -> void:
	for bot in _bots():
		if not _has_property(bot, "is_infected"):
			continue
		var id := bot.get_instance_id()
		var infected := bool(bot.get("is_infected"))
		if infected and not bool(old_infected.get(id, false)) and int(bot.get("player_duenio")) == player_id:
			focus_infected = bot
			notify("infection", {"target": bot, "player_id": player_id})
		old_infected[id] = infected

func _bots() -> Array[Node]:
	var result: Array[Node] = []
	for bot in get_tree().get_nodes_in_group("bots"):
		if is_instance_valid(world) and world.is_ancestor_of(bot):
			result.append(bot)
	return result

func mutation_info() -> Dictionary:
	if not supports("mutations") or not is_instance_valid(world):
		return {}
	var mutations: Array[String] = world.get("mutaciones_p1")
	var branches: Array = world.call("obtener_ramas_jugador", player_id)
	for index in range(branches.size()):
		var branch: Array = branches[index]
		var base := str(branch[0])
		var next := str(world.call("obtener_siguiente_evolucion", base, mutations))
		if not next.is_empty():
			return {"id": next, "base": base, "name": world.call("_nombre_mutacion", next), "description": world.call("_descripcion_mutacion", next), "cost": world.call("obtener_costo_mutacion", base, mutations), "adn": world.get("adn_cian"), "branch_index": index, "keys": "1 / 2" if branches.size() == 2 else "1 / 2 / 3"}
	return {}

func highlight_target(key: String) -> Node:
	if not is_instance_valid(world):
		return null
	match key:
		"mutation_menu": return world.get_node_or_null("HUD_ADN/LabelADN_Cian")
		"mutation_choice":
			var info: Dictionary = mutation_info()
			var names := ["BtnFiebre", "BtnCadena", "BtnInfeccion"]
			return world.get_node_or_null("HUD_ADN/PanelCian/VBoxContainer/" + names[clampi(int(info.get("branch_index", 0)), 0, 2)])
		"infection": return focus_infected
		"duck": return duck
	return null

func controls_text() -> String:
	return "CIAN: WASD para moverte · E para mutaciones · X para poseer.\nMAGENTA: flechas · O para mutaciones · J para poseer.\nPasá el cursor sobre una mutación para conocer su efecto y costo."

func can_tutorial_start() -> bool:
	if not is_instance_valid(world) or get_tree().paused:
		return false
	return not _has_property(world, "estado_actual") or int(world.get("estado_actual")) != 2

func protected_controls() -> Array[Control]:
	var result: Array[Control] = []
	if is_instance_valid(world):
		for path in ["HUD_ADN/PanelCian", "HUD_ADN/PanelMagenta"]:
			var control := world.get_node_or_null(path) as Control
			if control:
				result.append(control)
	return result

func objective_text() -> String:
	return "Al terminar el tiempo, gana quien tenga más infectados. Los contagios dan ADN: usalo para evolucionar tu cepa."

func cleanup() -> void:
	if closed:
		return
	release_cinematic()
	for timer in timers:
		if is_instance_valid(timer):
			timer.paused = timers[timer]
	timers.clear()
	for actor in ducks:
		if is_instance_valid(actor):
			var sprite := _sprite(actor)
			if sprite and sprite.animation_finished.is_connected(_animation_done):
				sprite.animation_finished.disconnect(_animation_done)
	observing = false
	closed = true

func cancel() -> void:
	# Scene changes must release resources without triggering a new gameplay event.
	if explosion_pending:
		explosion_pending = false
		for actor in ducks:
			if is_instance_valid(actor):
				actor.set("esta_desapareciendo", false)
	cleanup()

func _exit_tree() -> void:
	cancel()

func _has_property(object: Object, key: String) -> bool:
	for property in object.get_property_list():
		if property.name == key:
			return true
	return false

func _sprite(actor: Node) -> AnimatedSprite2D:
	# The current duck reparents its sprite into a CanvasGroup for the team outline.
	if _has_property(actor, "animated_sprite"):
		return actor.get("animated_sprite") as AnimatedSprite2D
	return actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
